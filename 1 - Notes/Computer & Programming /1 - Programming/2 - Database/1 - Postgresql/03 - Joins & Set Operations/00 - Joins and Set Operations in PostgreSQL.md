

Two tools combine data from more than one query, and they work in different directions. A **join** puts tables _side by side_: it matches rows on a condition and widens each row with columns from both tables. A **set operation** (`UNION`, `INTERSECT`, `EXCEPT`) _stacks_ results on top of each other, so the output has the same columns but more or fewer rows. Once you see them as "sideways vs. vertical," picking the right one gets much easier.

I'm reading "SET" as set operations, since that's what pairs with `JOIN`. At the end there's a short section on `UPDATE ... SET` with a join, in case that's what you meant.

---

## Joins, with data you can follow by eye

Here are two tiny tables. Notice that Cleo has no orders, and order 13 points to a customer who doesn't exist:

```sql
customers                orders
 id | name                id | customer_id | amount
----+------               ----+-------------+--------
  1 | Ana                 10 |           1 |     50
  2 | Bob                 11 |           1 |     20
  3 | Cleo                12 |           2 |     70
                          13 |           4 |      5
```

Every join type answers a different question about those mismatches.

**INNER JOIN** keeps only rows that match on both sides:

```sql
SELECT c.name, o.id AS order_id, o.amount
FROM customers c
JOIN orders o ON o.customer_id = c.id;
```

```
 name | order_id | amount
 Ana  |       10 |     50
 Ana  |       11 |     20
 Bob  |       12 |     70
```

Cleo and order 13 are both gone. Ana appears twice because she has two orders: a join produces one output row per matching pair.

**LEFT JOIN** keeps every row from the left table, filling in `NULL`s when there's no match:

```sql
FROM customers c LEFT JOIN orders o ON o.customer_id = c.id
```

This returns the three rows above plus `Cleo | NULL | NULL`.

**RIGHT JOIN** is the mirror image (keeps all orders, including 13 with a `NULL` name). Most people just swap the table order and use `LEFT JOIN`, which reads more naturally.

**FULL JOIN** keeps unmatched rows from both sides: Cleo _and_ order 13 appear, each padded with `NULL`s. It's the tool for reconciliation, such as "what's in A but not B, and what's in B but not A."

**CROSS JOIN** pairs every row with every row (3 × 4 = 12 rows here), with no condition. It's rarely what you want by accident, and very useful on purpose, like generating every combination of two lists.

### Finding what _doesn't_ match (anti-join)

"Customers with no orders" is one of the most common questions in SQL. There are two good ways:

```sql
-- LEFT JOIN, then keep only the unmatched rows
SELECT c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;

-- NOT EXISTS (usually the clearest)
SELECT c.name
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

Both give Cleo, and Postgres plans them as the same kind of anti-join. In the first version, always test a column that's `NOT NULL` in the right table (like its primary key), so a legitimately null value can't be mistaken for "no match."

### ON, USING, and NATURAL

When the join columns share a name, `USING` is shorter and also merges the column into one in the output:

```sql
FROM orders JOIN order_items USING (order_id)
```

Avoid `NATURAL JOIN`. It joins on _every_ identically named column automatically, so adding an innocent `created_at` column to one table later silently changes the query's meaning.

One reminder from the `WHERE` tutorial: for an outer join, a filter on the optional side belongs in `ON`. In `WHERE`, it throws away the `NULL`-padded rows and turns your `LEFT JOIN` into an inner join.

### Joins that aren't just `=`

The `ON` condition can be any boolean expression:

```sql
-- Which price band does each product fall into?
FROM products p
JOIN price_bands b ON p.price >= b.min_price AND p.price < b.max_price
```

**Self joins** join a table to itself, using two aliases, for hierarchies like employee and manager:

```sql
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id;
```

**`LATERAL`** lets the right side refer to the current left row, like a loop. It's the neat way to get "top N per group":

```sql
SELECT c.name, recent.id, recent.amount
FROM customers c
CROSS JOIN LATERAL (
    SELECT id, amount FROM orders o
    WHERE o.customer_id = c.id
    ORDER BY o.id DESC
    LIMIT 2
) AS recent;
```

Use `LEFT JOIN LATERAL (...) ON true` if customers with no orders should still appear.

### The fan-out trap

Ana's two orders become two rows. That's correct, but if you also join each order's items, anything you sum from the `orders` table gets repeated once per item and totals inflate. The fix is to aggregate each many-side table in a subquery first, and join the already-summarized results.

### How Postgres runs a join

`EXPLAIN` will show one of three strategies, and it picks by cost:

- **Nested Loop:** for each left row, look up matches on the right. Great when the left side is small and the right side has an index on the join column.
- **Hash Join:** builds an in-memory hash table of one side, then probes it. The usual choice for large, unsorted inputs with `=` conditions.
- **Merge Join:** walks two inputs that are both sorted on the join key. Efficient for big, already-ordered data.

The practical takeaway: **index the foreign key columns** you join on (Postgres does _not_ create them automatically for foreign keys), and keep statistics fresh with `ANALYZE`, because the planner's choice depends on its row estimates.

---

## Set operations: stacking results

Set operations take two complete queries and combine their rows:

```sql
SELECT email FROM customers
UNION
SELECT email FROM newsletter_subscribers;
```

|Operation|Returns|Duplicates|
|---|---|---|
|`UNION`|rows in either query|removed|
|`UNION ALL`|rows in either query|kept|
|`INTERSECT`|rows in both|removed|
|`EXCEPT`|rows in the first but not the second|removed|

`INTERSECT ALL` and `EXCEPT ALL` also exist and count duplicates instead of removing them. `UNION ALL` is the cheapest, because it skips the dedupe step, so use it unless you truly need duplicates gone.

The rules are simple: both queries need the **same number of columns**, with **compatible types** in matching positions, and the output column names come from the **first** query.

```sql
-- Everyone who bought something but never subscribed
SELECT customer_id FROM orders
EXCEPT
SELECT customer_id FROM subscriptions;
```

### A difference worth knowing: NULLs

In a join, `NULL = NULL` is not true, so two `NULL` keys never match. In set operations, `NULL`s are treated as **equal** (just like in `DISTINCT`). So `EXCEPT` and `INTERSECT` will happily match rows with `NULL`s, which is often convenient, and which is why `EXCEPT` is a handy way to diff two tables whole-row.

### Precedence and ordering

`INTERSECT` binds tighter than `UNION` and `EXCEPT`, so mixed chains can surprise you. Use parentheses:

```sql
(SELECT id FROM a UNION SELECT id FROM b)
INTERSECT
SELECT id FROM c;
```

A single `ORDER BY` (and `LIMIT`) at the very end applies to the combined result, and can only use output column names or positions. To sort or limit one branch separately, wrap that branch in parentheses.

---

## Choosing between them

- Need more **columns** about each row (customer name next to an order)? Use a **join**.
- Need more **rows** of the same shape (two tables with identical structure)? Use **`UNION ALL`**.
- "Rows in A that have no match in B" based on a key? **`NOT EXISTS`** (or an anti-join).
- "Rows in A that don't appear in B" comparing whole rows, `NULL`s included? **`EXCEPT`**.
- "Rows that exist in both" on a key? An **inner join** or `EXISTS`. For whole rows, `INTERSECT`.

---

## Bonus: SET in UPDATE, with a join

If you meant the `SET` in `UPDATE`, Postgres lets you join other tables into an update with `FROM`, and into a delete with `USING`:

```sql
UPDATE orders o
SET    status = 'vip'
FROM   customers c
WHERE  c.id = o.customer_id
  AND  c.tier = 'gold';

DELETE FROM orders o
USING customers c
WHERE c.id = o.customer_id AND c.is_banned;
```

One gotcha: if a target row matches **several** joined rows, Postgres updates it only once, using values from one of the matches, and it's unspecified which. Make the join one-to-one (or aggregate first) when the values differ. And as with any `UPDATE`, test the `WHERE` as a `SELECT` first.

---





[[PostgreSQL]]