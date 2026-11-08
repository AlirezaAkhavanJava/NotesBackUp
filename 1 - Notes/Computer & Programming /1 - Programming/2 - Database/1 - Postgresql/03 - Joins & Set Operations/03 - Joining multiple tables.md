

A **join** combines rows from two or more tables into a single result, matching them up by a shared value, usually a foreign key. Joining _multiple_ tables simply means chaining joins together, so one query can pull a customer's name, their orders, and the products inside those orders all at once.

Think of it like assembling a puzzle from separate boxes. Each box (table) holds one kind of piece, and the matching edges (keys) tell you how they connect. Let's see why we split data up in the first place, and how to put it back together.

## Why data lives in many tables

Good database design avoids repeating information. Instead of storing the customer's name and address on every order row, you store the customer once and have each order point to them with `customer_id`. This is called **normalization**, and it keeps data consistent: change an address in one place, and every order reflects it.

The price is that a question like "which products did Alice order?" spans several tables. Joins are how you answer it.

## Our sample schema

We'll use a small shop throughout:

```sql
CREATE TABLE customers (
    id    BIGSERIAL PRIMARY KEY,
    name  TEXT NOT NULL
);

CREATE TABLE products (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    price_cents INT  NOT NULL
);

CREATE TABLE orders (
    id          BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    ordered_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    order_id   BIGINT NOT NULL REFERENCES orders(id),
    product_id BIGINT NOT NULL REFERENCES products(id),
    quantity   INT    NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```

Notice `order_items` is a **junction table**: it connects orders and products in a many-to-many relationship (an order has many products, and a product appears in many orders).

## A single join first

```sql
SELECT c.name, o.id AS order_id, o.ordered_at
FROM customers c
JOIN orders o ON o.customer_id = c.id;
```

The pieces to notice:

- `c` and `o` are **aliases**, short nicknames that keep the query readable.
- `ON` states the matching rule: an order belongs to the customer whose `id` equals its `customer_id`.
- `JOIN` by itself means `INNER JOIN`: only rows with a match on both sides appear. A customer with no orders disappears from the result.

## Chaining: joining three or more tables

To join more tables, just keep adding `JOIN ... ON ...` clauses. Each one attaches a new table to what you've built so far:

```sql
SELECT c.name       AS customer,
       o.id         AS order_id,
       p.name       AS product,
       oi.quantity,
       p.price_cents * oi.quantity AS line_total_cents
FROM customers c
JOIN orders o       ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id   = o.id
JOIN products p     ON p.id          = oi.product_id
WHERE c.name = 'Alice'
ORDER BY o.ordered_at;
```

Read it like a path: customer, then their orders, then each order's items, then each item's product. Each `ON` clause links the new table to one that's already in the chain.

## The join types, and when each one fits

|Join|What you get|
|---|---|
|**INNER JOIN**|Only rows that match on both sides.|
|**LEFT JOIN**|All rows from the left table, plus matches from the right (or `NULL` if none).|
|**RIGHT JOIN**|The mirror image of LEFT; rarely needed, since you can swap table order.|
|**FULL JOIN**|All rows from both sides, matched where possible, `NULL` elsewhere.|
|**CROSS JOIN**|Every row paired with every row (a Cartesian product).|

The most useful one after `INNER` is `LEFT JOIN`. Say you want **all customers, including those who never ordered**:

```sql
SELECT c.name, o.id AS order_id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id;
```

Customers without orders appear with `order_id` as `NULL`. A handy trick: find the customers who _never_ ordered by filtering on that `NULL`:

```sql
SELECT c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;
```

## Mixing join types: the order-of-operations trap

When you chain several joins, a `LEFT JOIN` followed by an `INNER JOIN` can silently undo the left join. Suppose you want every customer, with their order items if any:

```sql
-- Looks right, but behaves like an INNER JOIN!
SELECT c.name, oi.product_id
FROM customers c
LEFT JOIN orders o       ON o.customer_id = c.id
JOIN order_items oi      ON oi.order_id = o.id;
```

For a customer with no orders, `o.id` is `NULL`, so the plain `JOIN` to `order_items` finds no match and drops that customer. The fix is to keep using `LEFT JOIN` for everything downstream:

```sql
SELECT c.name, oi.product_id
FROM customers c
LEFT JOIN orders o       ON o.customer_id = c.id
LEFT JOIN order_items oi ON oi.order_id = o.id;
```

Similarly, a `WHERE` condition on a right-side table (like `WHERE o.total > 100`) also removes the `NULL` rows. If you want to filter the right table _without_ losing unmatched left rows, put the condition in the `ON` clause instead:

```sql
LEFT JOIN orders o ON o.customer_id = c.id AND o.ordered_at > now() - interval '30 days'
```

## Joining and aggregating: the row-multiplication surprise

Joins multiply rows. One order with three items produces three result rows, so the order's data repeats three times. That's fine for listing, but it can wreck totals:

```sql
-- Revenue per customer
SELECT c.name,
       SUM(p.price_cents * oi.quantity) AS revenue_cents
FROM customers c
JOIN orders o       ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id   = o.id
JOIN products p     ON p.id          = oi.product_id
GROUP BY c.id, c.name
ORDER BY revenue_cents DESC;
```

This is correct because the sum is over the _finest-grained_ rows (order items). The danger appears when you sum a column from a "higher" table, like an order-level shipping fee, after joining down to items: the fee gets counted once per item. Whenever totals look too big, suspect row multiplication. Count the rows before aggregating, or aggregate in a subquery first and join the result.

## Other handy forms

**`USING`** is shorthand when both columns share a name:

```sql
SELECT * FROM order_items JOIN orders USING (order_id);  -- only if both columns are named order_id
```

**Self-join**: joining a table to itself, useful for hierarchies like employees and managers:

```sql
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id;
```

**`LATERAL`**: lets a joined subquery refer to columns from tables before it, great for "latest N per group":

```sql
SELECT c.name, last_orders.id, last_orders.ordered_at
FROM customers c
LEFT JOIN LATERAL (
    SELECT o.id, o.ordered_at
    FROM orders o
    WHERE o.customer_id = c.id
    ORDER BY o.ordered_at DESC
    LIMIT 3
) last_orders ON true;
```

## Performance: making joins fast

- **Index your foreign keys.** PostgreSQL does _not_ automatically index the referencing column (`orders.customer_id`), and joins on unindexed columns get slow as tables grow:

```sql
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
```

(Primary keys are indexed automatically; `order_items` is covered for `order_id` by its composite primary key.)

- **Use `EXPLAIN ANALYZE`** to see how PostgreSQL actually runs your query. You'll see join strategies with names like _nested loop_, _hash join_, and _merge join_, which the planner picks based on table sizes and indexes.
- **Select only the columns you need** rather than `SELECT *`, especially across many joined tables where column names collide.
- **Filter early.** Conditions in `WHERE` let PostgreSQL shrink the data before or during the join.

## Habits worth keeping

- **Always write the `ON` clause.** Forgetting it (or using the old comma syntax and forgetting `WHERE`) creates an accidental cross join and a result millions of rows long.
- **Use meaningful aliases** (`c`, `o`, `oi`, `p`) and qualify every column with its alias.
- **Build the query incrementally**: start with two tables, check the result, then add the next join.
- **Watch for `NULL`s** after outer joins, and remember `NULL = NULL` is never true.

## Quick recap

Joining multiple tables means chaining `JOIN ... ON ...` clauses so each new table attaches to the ones before it. Use `INNER JOIN` for matches only, `LEFT JOIN` to keep unmatched rows, stay consistent with outer joins downstream, beware row multiplication when aggregating, and index your foreign keys for speed.





[[PostgreSQL]]