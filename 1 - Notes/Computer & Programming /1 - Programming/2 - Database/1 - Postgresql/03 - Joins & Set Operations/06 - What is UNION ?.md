
# UNION: Stacking Query Results on Top of Each Other

A **join** combines tables _side by side_, adding columns. `UNION` does the opposite: it takes the results of two or more queries and **stacks them vertically** into one result set, adding rows. If joins are about widening your data, `UNION` is about lengthening it.

Picture two class rosters on separate sheets of paper, one for the morning class and one for the evening class. You want a single list of everyone enrolled. You'd put the sheets together and, if you didn't want a student who attends both listed twice, cross out the duplicates. That's `UNION`. Keeping the duplicates is `UNION ALL`. Let's see why you'd need this and how to use it well.

## Why we need UNION

Real data is often split across tables that describe the same kind of thing:

- `customers` and `suppliers`, both of which are "contacts" you want in one mailing list.
- `orders_2025` and `orders_2026`, partitioned by year by hand.
- `active_users` and `archived_users`, needing one combined report.
- Two different questions whose answers you want in one list, like "customers who ordered recently" plus "customers who signed up recently."

A join can't do this, because there's no relationship to match on. You simply want the rows from both.

## Our sample tables

```sql
CREATE TABLE customers (id INT, name TEXT, email TEXT);
CREATE TABLE suppliers (id INT, name TEXT, email TEXT);

INSERT INTO customers VALUES (1,'Alice','alice@mail.com'), (2,'Bob','bob@mail.com');
INSERT INTO suppliers VALUES (1,'Bob','bob@mail.com'), (2,'Carol','carol@mail.com');
```

Note that Bob appears in both tables.

## UNION: combine and remove duplicates

```sql
SELECT name, email FROM customers
UNION
SELECT name, email FROM suppliers;
```

Result:

|name|email|
|---|---|
|Alice|alice@mail.com|
|Bob|bob@mail.com|
|Carol|carol@mail.com|

Bob appears once, even though he was in both tables. `UNION` compares **entire rows** and keeps only distinct ones. That includes duplicates _within_ a single query, not just across the two.

## UNION ALL: combine and keep everything

```sql
SELECT name, email FROM customers
UNION ALL
SELECT name, email FROM suppliers;
```

Now Bob appears twice. `UNION ALL` simply appends the rows without checking for duplicates.

This difference matters for speed. To remove duplicates, `UNION` has to sort or hash the entire combined result, which costs time and memory. `UNION ALL` just streams the rows through. So:

- Use **`UNION ALL`** when duplicates are impossible, harmless, or wanted. It's the faster default.
- Use **`UNION`** only when you genuinely need distinct rows.

A common mistake is writing `UNION` out of habit when the two queries can't overlap anyway, paying for a pointless de-duplication step.

## The rules: what the queries must have in common

For `UNION` to work, the queries must be compatible:

1. **Same number of columns** in every query.
2. **Compatible data types** in matching positions (the first column with the first, the second with the second, and so on).
3. **Column names come from the first query.** The later queries' names are ignored.

Columns are matched by **position, not by name**. This catches people out:

```sql
SELECT name, email FROM customers
UNION ALL
SELECT email, name FROM suppliers;   -- compiles, but the data is scrambled!
```

PostgreSQL happily stacks emails under the name column because both are text. Always double check that the column order lines up.

If the types differ, you can cast to make them agree:

```sql
SELECT id, name FROM customers
UNION ALL
SELECT code::int, title FROM products;
```

PostgreSQL does resolve some mixes automatically (like integer and bigint), but it errors on genuine mismatches, such as `integer` with `text`.

## Handling columns that exist on only one side

Say customers have a `phone` but suppliers don't. Pad the missing column with `NULL` so the shapes match:

```sql
SELECT name, email, phone FROM customers
UNION ALL
SELECT name, email, NULL::text FROM suppliers;
```

The `::text` cast helps PostgreSQL work out the column's type, since a bare `NULL` has no type of its own.

A very handy trick is adding a **label column** so you can tell where each row came from:

```sql
SELECT name, email, 'customer' AS source FROM customers
UNION ALL
SELECT name, email, 'supplier' AS source FROM suppliers;
```

This also changes how `UNION` removes duplicates: Bob now differs between the two rows (`customer` versus `supplier`), so even plain `UNION` would keep both.

## Sorting, limiting, and where clauses

An `ORDER BY` placed at the very end applies to the **entire** combined result:

```sql
SELECT name, email FROM customers
UNION ALL
SELECT name, email FROM suppliers
ORDER BY name;
```

If you want to sort or limit an individual part, wrap it in parentheses:

```sql
(SELECT name, email FROM customers ORDER BY name LIMIT 5)
UNION ALL
(SELECT name, email FROM suppliers ORDER BY name LIMIT 5);
```

Each query can have its own `WHERE`, `JOIN`, and `GROUP BY`. They're completely independent until the moment their results are stacked:

```sql
SELECT customer_id AS contact_id, 'order' AS reason
FROM orders
WHERE ordered_at > now() - interval '30 days'
UNION
SELECT id, 'signup'
FROM customers
WHERE created_at > now() - interval '30 days';
```

## The set-operation family

`UNION` has two siblings, and you met one of them in the anti-join lesson:

|Operator|Returns|
|---|---|
|`UNION`|Rows in either query (duplicates removed)|
|`INTERSECT`|Rows in **both** queries|
|`EXCEPT`|Rows in the first query but **not** the second|

Each has an `ALL` version that keeps duplicates (`UNION ALL`, `INTERSECT ALL`, `EXCEPT ALL`). All of them compare whole rows and treat two `NULL`s as equal, which is different from how `=` behaves.

```sql
SELECT email FROM customers
INTERSECT
SELECT email FROM suppliers;   -- emails that appear in both
```

When you combine several, `INTERSECT` binds tighter than `UNION` and `EXCEPT`. Use parentheses to make your intent explicit.

## UNION and NULLs

For duplicate removal, `UNION` considers two `NULL`s to be the **same** value. So these two rows collapse into one:

```sql
SELECT NULL::int
UNION
SELECT NULL::int;
-- returns a single row
```

This is the opposite of `NULL = NULL`, which is never true. Set operations use "not distinct from" semantics.

## Performance notes

- **Prefer `UNION ALL`** whenever you can. De-duplication means a hash aggregate or sort over the full combined result, visible in `EXPLAIN` as `HashAggregate` or `Unique` sitting above an `Append` node.
- **Filter inside each branch**, not after. This lets each part use its own indexes:

```sql
-- Good: each branch filters on its own indexes
SELECT id FROM orders_2025 WHERE customer_id = 7
UNION ALL
SELECT id FROM orders_2026 WHERE customer_id = 7;
```

- **Replace `OR` with `UNION` when it helps.** A query with `WHERE a = 1 OR b = 2` sometimes can't use indexes well, while two separate indexed queries combined with `UNION` can be faster. Test both with `EXPLAIN ANALYZE`.
- For big, long-lived data split by year or region, look into PostgreSQL's **declarative partitioning**, which gives you the effect of a `UNION ALL` over many tables automatically and lets the planner skip irrelevant ones.

## Handy patterns

**A combined, de-duplicated contact list:**

```sql
SELECT email FROM customers
UNION
SELECT email FROM suppliers;
```

**A view that presents split tables as one:**

```sql
CREATE VIEW all_orders AS
SELECT id, customer_id, total_cents, 2025 AS yr FROM orders_2025
UNION ALL
SELECT id, customer_id, total_cents, 2026 AS yr FROM orders_2026;
```

**Generating a report with a totals row:**

```sql
SELECT region, SUM(sales) AS total FROM sales GROUP BY region
UNION ALL
SELECT 'ALL REGIONS', SUM(sales) FROM sales;
```

(For subtotals like this, `GROUP BY ROLLUP` is often a tidier alternative.)

## Habits worth keeping

- **Default to `UNION ALL`**, and reach for `UNION` only when you truly need distinct rows.
- **Check column order and types** in every branch, since matching is positional.
- **Add a label column** when you need to know which query a row came from.
- **Use parentheses** when mixing `UNION`, `INTERSECT`, and `EXCEPT`, or when sorting and limiting individual branches.
- **Cast `NULL` placeholders**, such as `NULL::text`, so types resolve cleanly.

## Quick recap

`UNION` stacks the results of multiple queries into one, matching columns by position and removing duplicate rows. `UNION ALL` does the same without de-duplicating, so it's faster and usually the right default. Together with `INTERSECT` and `EXCEPT`, it forms the set-operation family for treating query results as mathematical sets.




[[PostgreSQL]]