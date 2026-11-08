

# DQL in PostgreSQL: reading data with `SELECT`

**DQL** stands for **Data Query Language**. In PostgreSQL it is one command, `SELECT`, which reads rows from tables, views, and functions and returns them as a result set. A `SELECT` never changes anything stored in the database. That makes it the safest command to experiment with, and the one you will write more than all the others combined.

The part that surprises most people is that `SELECT` is made of many optional clauses (`WHERE`, `JOIN`, `GROUP BY`, `ORDER BY`, and more), and PostgreSQL does **not** run them in the order you write them. Once you know the real execution order, most of the confusing errors stop being confusing. So this lesson is built around that order: we start with a plain query, then add one clause at a time, in the order PostgreSQL processes them.

---

## 1. Sample data

Run this in a scratch database (like `dummy`). It reuses the `clients` and `orders` tables from the DDL and DML lessons. If you still have rows from the DML lesson, clear them first.

```sql
TRUNCATE clients, orders RESTART IDENTITY CASCADE;

INSERT INTO clients (name, email, status) VALUES
    ('Ali Khan',  'ali@example.com',  'active'),    -- id 1
    ('Sara Lee',  'sara@example.com', 'active'),    -- id 2
    ('Tom Wu',    'tom@example.com',  'inactive'),  -- id 3
    ('Mia Costa', 'mia@example.com',  'active'),    -- id 4
    ('Leo Park',  'leo@example.com',  'vip'),       -- id 5
    ('Zoe Ng',    'zoe@example.com',  'active');    -- id 6

INSERT INTO orders (client_id, total, placed_at) VALUES
    (1, 120.00, '2026-10-01'),   -- order 1
    (1,  80.00, '2026-10-15'),   -- order 2
    (2,  45.50, '2026-10-03'),   -- order 3
    (2, 200.00, '2026-10-20'),   -- order 4
    (2,  19.99, '2026-11-02'),   -- order 5
    (4,  60.00, '2026-10-28'),   -- order 6
    (5, 500.00, '2026-11-05');   -- order 7
```

`TRUNCATE ... RESTART IDENTITY CASCADE` is DDL from our earlier lesson: it empties both tables and resets the id counters, so the ids in the comments are correct. Notice that Tom (3) and Zoe (6) have no orders. That is on purpose, because it makes joins interesting.

---

## 2. Written order vs execution order

You write `SELECT` first, but PostgreSQL logically processes it last.

|Step|Clause|What happens|
|---|---|---|
|1|`FROM` / `JOIN`|Pick the tables and combine them into one set of rows|
|2|`WHERE`|Throw away rows that don't match|
|3|`GROUP BY`|Collapse rows into groups|
|4|`HAVING`|Throw away groups that don't match|
|5|`SELECT`|Compute the output columns (and their aliases)|
|6|`DISTINCT`|Remove duplicate output rows|
|7|`ORDER BY`|Sort|
|8|`LIMIT` / `OFFSET`|Cut the result down|

The biggest consequence: **`WHERE` runs before `SELECT`, so it can't see aliases created in the `SELECT` list.**

```sql
SELECT total * 2 AS doubled FROM orders WHERE doubled > 100;
```

```
ERROR: column "doubled" does not exist
```

Repeat the expression instead: `WHERE total * 2 > 100`. But `ORDER BY` runs _after_ `SELECT`, so `ORDER BY doubled` works fine. Keep this table in mind. We will refer back to it.

---

## 3. `SELECT` and `FROM`: choosing columns

The simplest query names a table and the columns you want:

```sql
SELECT id, name, status FROM clients;
```

|id|name|status|
|---|---|---|
|1|Ali Khan|active|
|2|Sara Lee|active|
|3|Tom Wu|inactive|
|4|Mia Costa|active|
|5|Leo Park|vip|
|6|Zoe Ng|active|

`SELECT *` means "every column." It is handy for exploring in pgAdmin, but avoid it in application code. If someone adds a column later, your query silently returns more data, and any code that depends on column order can break.

### Expressions and aliases

The `SELECT` list can hold calculations, function calls, and text joining, and `AS` gives each result a name:

```sql
SELECT name || ' <' || email || '>' AS contact,
       upper(status)                AS status_label,
       created_at::date             AS joined_on
FROM clients
WHERE id = 1;
```

|contact|status_label|joined_on|
|---|---|---|
|Ali Khan [ali@example.com](mailto:ali@example.com)|ACTIVE|2026-11-08|

- `||` joins text. If any part is `NULL`, the whole result becomes `NULL`.
- `::date` is the cast operator from our earlier lesson. It turns the full timestamp into a date.
- Without `AS`, PostgreSQL names the column after the expression, which is usually ugly. Always alias calculated columns.

### `CASE`: if/else inside a query

```sql
SELECT name,
       CASE status
           WHEN 'vip'    THEN 'gold'
           WHEN 'active' THEN 'standard'
           ELSE 'none'
       END AS tier
FROM clients;
```

|name|tier|
|---|---|
|Ali Khan|standard|
|Sara Lee|standard|
|Tom Wu|none|
|Mia Costa|standard|
|Leo Park|gold|
|Zoe Ng|standard|

`CASE` goes through the `WHEN` branches in order and returns the first match. If nothing matches and there is no `ELSE`, you get `NULL`. There is also a searched form for conditions: `CASE WHEN total > 100 THEN 'big' ELSE 'small' END`.

### `COALESCE` and `NULLIF`: handling `NULL`

- `coalesce(a, b, c)` returns the first value that is not `NULL`. Use it to supply defaults: `coalesce(phone, 'n/a')`.
- `nullif(a, b)` returns `NULL` if `a = b`, otherwise `a`. Its classic use is avoiding division by zero: `total / nullif(item_count, 0)`.

---

## 4. `WHERE`: filtering rows

`WHERE` keeps only the rows for which its condition is true.

```sql
SELECT id, name FROM clients WHERE status = 'active' AND id > 2;
```

|id|name|
|---|---|
|4|Mia Costa|
|6|Zoe Ng|

### The operators you will use

|Operator|Meaning|Example|
|---|---|---|
|`=`, `<>` (or `!=`), `<`, `<=`, `>`, `>=`|Comparison|`total >= 100`|
|`AND`, `OR`, `NOT`|Combine conditions|`a AND b`|
|`IN (...)`|Matches any value in a list|`status IN ('vip', 'inactive')`|
|`BETWEEN x AND y`|Range, **both ends included**|`total BETWEEN 50 AND 200`|
|`LIKE` / `ILIKE`|Pattern match (`ILIKE` ignores case)|`name LIKE 'S%'`|
|`IS NULL` / `IS NOT NULL`|Test for missing values|`phone IS NULL`|

Results on our data:

- `status IN ('vip', 'inactive')` returns Tom (3) and Leo (5).
- `total BETWEEN 50 AND 200` on `orders` returns orders 1, 2, 4, and 6 (totals 120, 80, 200, 60). Both 50 and 200 would count if they existed.
- `name LIKE 'S%'` returns Sara Lee. In patterns, `%` means any number of characters and `_` means exactly one. `name ILIKE '%LEE%'` also finds Sara, because it ignores case.

### `AND` binds tighter than `OR`

```sql
-- Reads as: vip, OR (active AND id < 3)
SELECT id FROM clients WHERE status = 'vip' OR status = 'active' AND id < 3;     -- 1, 2, 5

-- With parentheses: (vip OR active) AND id < 3
SELECT id FROM clients WHERE (status = 'vip' OR status = 'active') AND id < 3;   -- 1, 2
```

Same words, different results. When you mix `AND` and `OR`, always add parentheses.

### `NULL` is "unknown," not a value

This connects to what you saw in the DML lesson. Any comparison with `NULL` gives `NULL` (unknown), and `WHERE` only keeps rows that are _true_:

```sql
SELECT NULL = NULL;       -- NULL (not true!)
SELECT NULL IS NULL;      -- true
```

So `WHERE phone = NULL` never matches anything. Use `IS NULL`. A nastier version hits `NOT IN`:

```sql
SELECT 'row' WHERE 5 NOT IN (1, NULL);     -- returns no rows
```

Because one item in the list is `NULL`, the answer to "is 5 not in this list?" becomes unknown, so the row is dropped. If a subquery can return `NULL`, prefer `NOT EXISTS` (section 9).

### Date ranges: don't wrap the column

```sql
-- Good: can use an index on placed_at
SELECT id FROM orders
WHERE placed_at >= '2026-10-01' AND placed_at < '2026-11-01';     -- 1, 2, 3, 4, 6

-- Avoid: casts every row, so a normal index can't help
SELECT id FROM orders WHERE placed_at::date BETWEEN '2026-10-01' AND '2026-10-31';
```

This is the cast-in-`WHERE` warning from the `::` lesson. Use "greater than or equal to the start, less than the next start" for date and timestamp ranges. It also avoids the `BETWEEN` edge case where a value at exactly midnight on the last day gets included or excluded unexpectedly.

### Pattern matching and indexes

A `LIKE` that starts with a wildcard (`'%lee'`) can't use a normal B-tree index, so it scans the whole table. For fuzzy search on big tables, the `pg_trgm` extension (from the extensions lesson) or full-text search with `tsvector` are the tools.

---

## 5. `GROUP BY`, aggregates, and `HAVING`: summarizing rows

An **aggregate function** reads many rows and returns one value. `GROUP BY` splits the rows into groups first, so you get one result per group.

|Aggregate|Returns|
|---|---|
|`count(*)`|Number of rows|
|`count(col)`|Number of rows where `col` is **not** `NULL`|
|`count(DISTINCT col)`|Number of different non-null values|
|`sum(col)`, `avg(col)`|Total, average (both skip `NULL`s)|
|`min(col)`, `max(col)`|Smallest, largest|
|`string_agg(col, ', ')`|Values joined into one text|
|`array_agg(col)`|Values collected into an array|

```sql
SELECT status, count(*) AS n
FROM clients
GROUP BY status
ORDER BY n DESC, status;
```

|status|n|
|---|---|
|active|4|
|inactive|1|
|vip|1|

Line by line: `FROM` reads six rows, `GROUP BY status` puts them into three groups, `SELECT` counts each group, and `ORDER BY n DESC` sorts by that count. Notice `ORDER BY` can use the alias `n`, because it runs after `SELECT`.

### The `GROUP BY` rule

Every column in the `SELECT` list must either appear in `GROUP BY` or be wrapped in an aggregate. Otherwise:

```sql
SELECT status, name, count(*) FROM clients GROUP BY status;
```

```
ERROR: column "clients.name" must appear in the GROUP BY clause or be used in an aggregate function
```

PostgreSQL can't decide which `name` to show for a group of four clients. You either group by it too, or aggregate it: `string_agg(name, ', ')`. One exception: if you group by a table's primary key (`GROUP BY c.id`), you may select that table's other columns freely.

### `WHERE` vs `HAVING`

`WHERE` filters rows _before_ grouping. `HAVING` filters groups _after_, so it is the only place you can test an aggregate.

```sql
SELECT client_id, count(*) AS orders, sum(total) AS spent
FROM orders
GROUP BY client_id
HAVING sum(total) > 100
ORDER BY spent DESC;
```

|client_id|orders|spent|
|---|---|---|
|5|1|500.00|
|2|3|265.49|
|1|2|200.00|

Client 4 (60.00 total) was dropped by `HAVING`. Putting an aggregate in `WHERE` gives `ERROR: aggregate functions are not allowed in WHERE`.

### `FILTER`: conditional counting in one pass

```sql
SELECT count(*)                                  AS all_clients,
       count(*) FILTER (WHERE status = 'active') AS active_clients
FROM clients;
```

|all_clients|active_clients|
|---|---|
|6|4|

`FILTER` limits which rows feed one particular aggregate, so you can compute several different counts in a single scan.

---

## 6. `JOIN`: combining tables

A join pairs rows from two tables using a condition, usually "this foreign key equals that primary key."

### `INNER JOIN` (or just `JOIN`): only rows that match

```sql
SELECT c.name, o.id AS order_id, o.total
FROM clients c
JOIN orders o ON o.client_id = c.id
ORDER BY o.id;
```

|name|order_id|total|
|---|---|---|
|Ali Khan|1|120.00|
|Ali Khan|2|80.00|
|Sara Lee|3|45.50|
|Sara Lee|4|200.00|
|Sara Lee|5|19.99|
|Mia Costa|6|60.00|
|Leo Park|7|500.00|

Seven orders, seven rows. Tom and Zoe are missing because they have no matching order. `c` and `o` are table aliases. Using them is standard practice, and they are required when both tables have a column with the same name. Without them you get `ERROR: column reference "id" is ambiguous`.

### `LEFT JOIN`: keep every row from the left table

```sql
SELECT c.name, o.id AS order_id
FROM clients c
LEFT JOIN orders o ON o.client_id = c.id
WHERE o.id IS NULL;
```

|name|order_id|
|---|---|
|Tom Wu|NULL|
|Zoe Ng|NULL|

A `LEFT JOIN` returns every client. Where no order matches, the order columns are filled with `NULL`. Filtering on `o.id IS NULL` then finds exactly the clients with no orders. This is called an _anti-join_, and it is a very common pattern.

### A trap: `WHERE` can silently undo a `LEFT JOIN`

```sql
-- Looks like a left join, behaves like an inner join
SELECT c.name, o.total
FROM clients c LEFT JOIN orders o ON o.client_id = c.id
WHERE o.total > 100;

-- Keeps all clients; only big orders are attached
SELECT c.name, o.total
FROM clients c LEFT JOIN orders o ON o.client_id = c.id AND o.total > 100;
```

In the first query, clients with no orders have `o.total = NULL`, and `NULL > 100` is unknown, so `WHERE` drops them. Remember the execution order: the join finishes first, then `WHERE` runs. To filter the _right_ table while keeping unmatched left rows, put the condition in `ON`.

### The other join types

|Join|Keeps|
|---|---|
|`INNER JOIN`|Only pairs that match|
|`LEFT JOIN`|All left rows, plus matches (else `NULL`s)|
|`RIGHT JOIN`|All right rows, plus matches. Same as a left join with the tables swapped, so most people just use `LEFT`|
|`FULL JOIN`|All rows from both sides|
|`CROSS JOIN`|Every left row paired with every right row (no condition). 6 clients × 7 orders = 42 rows|

If both tables use the same column name for the join, `USING (client_id)` is a shorter form of `ON a.client_id = b.client_id`. A table can also join itself (a _self join_), which is how you query things like employee-to-manager relationships stored in one table.

### Joining and aggregating together

```sql
SELECT c.name,
       count(o.id)               AS orders,
       coalesce(sum(o.total), 0) AS spent
FROM clients c
LEFT JOIN orders o ON o.client_id = c.id
GROUP BY c.id, c.name
ORDER BY spent DESC, c.name;
```

|name|orders|spent|
|---|---|---|
|Leo Park|1|500.00|
|Sara Lee|3|265.49|
|Ali Khan|2|200.00|
|Mia Costa|1|60.00|
|Tom Wu|0|0|
|Zoe Ng|0|0|

Two details matter here. `count(o.id)` counts only real orders, so Tom shows 0. `count(*)` would count the single `NULL`-filled row and wrongly show 1. And `sum` returns `NULL` when there are no rows to add, so `coalesce(..., 0)` turns that into a clean zero.

---

## 7. `DISTINCT` and `DISTINCT ON`

`DISTINCT` removes duplicate rows from the result:

```sql
SELECT DISTINCT status FROM clients;     -- active, inactive, vip
```

`DISTINCT ON` is a PostgreSQL feature that keeps the **first row per group**, where "first" is decided by `ORDER BY`. Here is the latest order for each client:

```sql
SELECT DISTINCT ON (client_id) client_id, id AS order_id, total, placed_at
FROM orders
ORDER BY client_id, placed_at DESC;
```

|client_id|order_id|total|placed_at|
|---|---|---|---|
|1|2|80.00|2026-10-15|
|2|5|19.99|2026-11-02|
|4|6|60.00|2026-10-28|
|5|7|500.00|2026-11-05|

The `ORDER BY` must start with the `DISTINCT ON` columns, or you get `SELECT DISTINCT ON expressions must match initial ORDER BY expressions`.

---

## 8. `ORDER BY`, `LIMIT`, and `OFFSET`

```sql
SELECT name, status FROM clients ORDER BY status DESC, name ASC;
```

|name|status|
|---|---|
|Leo Park|vip|
|Tom Wu|inactive|
|Ali Khan|active|
|Mia Costa|active|
|Sara Lee|active|
|Zoe Ng|active|

It sorts by the first column, and uses the next one only to break ties. `ASC` is the default.

- **`NULL`s:** in ascending order, `NULL`s sort last. Control it with `ORDER BY col NULLS FIRST` or `NULLS LAST`.
- **Shortcuts:** you can sort by an alias, an expression, or a column position (`ORDER BY 2`), though positions make code harder to read.
- **Text sorting** follows the database's collation (see the collations section of the pgAdmin lesson), so capital letters and accents may sort differently on different servers.

### Limiting results

```sql
SELECT id, total FROM orders ORDER BY total DESC LIMIT 3;
```

|id|total|
|---|---|
|7|500.00|
|4|200.00|
|1|120.00|

The standard-SQL spelling is `FETCH FIRST 3 ROWS ONLY`. Always pair `LIMIT` with `ORDER BY`. Without one, PostgreSQL returns _any_ three rows, and which ones can change between runs.

### Pagination, and why `OFFSET` gets slow

```sql
SELECT id, total FROM orders ORDER BY id LIMIT 3 OFFSET 3;    -- page 2: ids 4, 5, 6
```

`OFFSET 3` skips three rows, but PostgreSQL still has to read and discard them. On page 5000 of a big table, it discards 100,000 rows each time. The faster approach, called **keyset pagination**, remembers where the last page ended:

```sql
SELECT id, total FROM orders WHERE id > 3 ORDER BY id LIMIT 3;    -- ids 4, 5, 6
```

With an index on `id`, this jumps straight to the right place, however deep you are. The cost is that you can only go "next," not jump to page 5000.

---

## 9. Subqueries, `IN`, and `EXISTS`

A **subquery** is a `SELECT` inside another statement. It can appear in several places.

**A single value** (a _scalar_ subquery), compared in `WHERE`:

```sql
SELECT id, total FROM orders
WHERE total > (SELECT avg(total) FROM orders);
```

|id|total|
|---|---|
|4|200.00|
|7|500.00|

The average is about 146.50, so only two orders are above it. The subquery must return exactly one row and one column. Otherwise: `ERROR: more than one row returned by a subquery used as an expression`.

**A list of values**, with `IN`:

```sql
SELECT name FROM clients
WHERE id IN (SELECT client_id FROM orders WHERE total > 100)
ORDER BY name;
```

**A yes/no question per row**, with `EXISTS`:

```sql
SELECT name FROM clients c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.client_id = c.id AND o.total > 100)
ORDER BY name;
```

|name|
|---|
|Ali Khan|
|Leo Park|
|Sara Lee|

Both return the same rows here. The `EXISTS` version is _correlated_: the inner query refers to `c.id` from the outer query, and it runs conceptually once per client. `SELECT 1` is a convention, because `EXISTS` only cares whether any row comes back, not what it contains.

The difference shows up with negation. `NOT EXISTS` is safe even if the inner query contains `NULL`s, while `NOT IN` breaks (the trap from section 4). When in doubt, use `EXISTS` and `NOT EXISTS`.

---

## 10. CTEs: naming a subquery with `WITH`

A **CTE** (common table expression) gives a subquery a name, so a long query reads top to bottom:

```sql
WITH spend AS (
    SELECT client_id, sum(total) AS spent
    FROM orders
    GROUP BY client_id
)
SELECT c.name, s.spent
FROM clients c
JOIN spend s ON s.client_id = c.id
WHERE s.spent > 150
ORDER BY s.spent DESC;
```

|name|spent|
|---|---|
|Leo Park|500.00|
|Sara Lee|265.49|
|Ali Khan|200.00|

`spend` behaves like a temporary table that exists only for this one statement. You can chain several: `WITH a AS (...), b AS (...) SELECT ...`. Since PostgreSQL 12, a simple CTE is merged into the main query by default, so it is not a performance barrier. You can force the old behavior with `WITH spend AS MATERIALIZED (...)`.

In the DML lesson, you also saw a CTE that wraps a `DELETE ... RETURNING` and feeds an `INSERT`. It is the same `WITH` syntax. CTEs can also be recursive, which is how you walk through trees and hierarchies, but that deserves its own lesson.

---

## 11. Window functions: calculations across related rows

A window function works like an aggregate, but it **does not collapse rows**. Every row stays, and each gets an extra computed value based on its "window" of related rows. The window is written with `OVER (...)`.

```sql
SELECT client_id,
       id AS order_id,
       total,
       rank() OVER (PARTITION BY client_id ORDER BY total DESC) AS rnk,
       sum(total) OVER (PARTITION BY client_id ORDER BY placed_at) AS running
FROM orders
ORDER BY client_id, placed_at;
```

|client_id|order_id|total|rnk|running|
|---|---|---|---|---|
|1|1|120.00|1|120.00|
|1|2|80.00|2|200.00|
|2|3|45.50|2|45.50|
|2|4|200.00|1|245.50|
|2|5|19.99|3|265.49|
|4|6|60.00|1|60.00|
|5|7|500.00|1|500.00|

Reading the two window expressions:

- `PARTITION BY client_id` splits the rows into one window per client, similar to `GROUP BY`, but without collapsing.
- `rank() ... ORDER BY total DESC` numbers each order within its client, biggest first.
- `sum(total) ... ORDER BY placed_at` adds a **running total**: each row sums everything from the start of its window up to itself, in date order.

Other window functions worth knowing: `row_number()` (unique numbering, even for ties), `lag(col)` and `lead(col)` (the previous and next row's value), and `avg(...) OVER (...)`. Window functions run after `WHERE` and `GROUP BY`, so you can't filter on them directly (`ERROR: window functions are not allowed in WHERE`). Wrap the query in a CTE and filter outside:

```sql
WITH ranked AS (
    SELECT id, client_id, total,
           row_number() OVER (PARTITION BY client_id ORDER BY total DESC) AS rn
    FROM orders
)
SELECT * FROM ranked WHERE rn = 1;     -- the biggest order of each client
```

---

## 12. Set operations: stacking result sets

These combine the results of two queries that have the same number of columns and compatible types.

|Operator|Result|
|---|---|
|`UNION`|Rows from both, duplicates removed|
|`UNION ALL`|Rows from both, duplicates kept (faster)|
|`INTERSECT`|Rows present in both|
|`EXCEPT`|Rows in the first but not the second|

```sql
SELECT id FROM clients
EXCEPT
SELECT client_id FROM orders;       -- 3, 6  (Tom and Zoe again)
```

Prefer `UNION ALL` unless you really need duplicates removed, because `UNION` has to sort or hash everything to find them. A mismatch gives `ERROR: each UNION query must have the same number of columns`.

---

## 13. PostgreSQL's special operators are just `SELECT`

Every special type from the first lesson is queried with an ordinary `SELECT` and a special operator in `WHERE` or `ORDER BY`:

|Earlier topic|Query|
|---|---|
|`inet` / `cidr`|`SELECT * FROM login_attempts WHERE ip << '203.0.113.0/24'`|
|Range types|`SELECT * FROM bookings WHERE stay @> DATE '2026-11-02'`|
|Geometric types|`SELECT name FROM shops ORDER BY pos <-> point '(0,0)' LIMIT 1`|
|`tsvector`|`SELECT * FROM articles WHERE search @@ websearch_to_tsquery('english', 'spring')`|
|Arrays|`SELECT * FROM clients WHERE id = ANY(ARRAY[1, 3, 5])`|

A saved `SELECT` is also what a **view** is, and a **materialized view** stores a `SELECT`'s result (both from the DDL lesson). If you manage views with Flyway, a repeatable migration (`R__...sql`) with `CREATE OR REPLACE VIEW` is the natural fit.

---

## 14. Seeing how PostgreSQL runs your query: `EXPLAIN`

```sql
EXPLAIN SELECT * FROM orders WHERE client_id = 2;
EXPLAIN ANALYZE SELECT * FROM orders WHERE client_id = 2;
```

`EXPLAIN` shows the plan PostgreSQL chose, without running the query. `EXPLAIN ANALYZE` actually **runs** it and adds real timings and row counts. If you use it on an `UPDATE` or `DELETE`, the change really happens, so wrap it in `BEGIN; ... ROLLBACK;`.

The first thing to look at in the output is the scan type on each table:

|Plan node|Meaning|
|---|---|
|`Seq Scan`|Reads every row of the table. Fine for small tables, a warning sign for big ones|
|`Index Scan` / `Index Only Scan`|Uses an index to jump to the rows|
|`Bitmap Heap Scan`|Uses an index to collect many matching rows, then reads them in bulk|
|`Hash Join` / `Nested Loop` / `Merge Join`|The way two tables are being joined|

On your tiny sample tables you will see `Seq Scan`, and that is the right choice, because scanning seven rows is cheaper than using an index. Plans only become interesting on large tables. In pgAdmin, the Query Tool has an **Explain** button (F7) that draws the plan graphically. The fix for a slow `Seq Scan` is usually the `CREATE INDEX` command from the DDL lesson, on the column used in `WHERE`, `JOIN`, or `ORDER BY`.

---

## 15. Errors you will meet

|Error|Cause|Fix|
|---|---|---|
|`column "x" does not exist`|Alias used in `WHERE`, a typo, or double quotes around a text value|Repeat the expression, check spelling, use single quotes for text|
|`relation "clients" does not exist`|Wrong database or schema, or the table was created with quoted mixed-case (`"Clients"`)|Check `search_path`, use `schema.table`, match the exact case|
|`column "c.name" must appear in the GROUP BY clause or be used in an aggregate function`|Selecting an ungrouped column|Add it to `GROUP BY` or aggregate it|
|`column reference "id" is ambiguous`|Two joined tables share a column name|Qualify it: `c.id`|
|`missing FROM-clause entry for table "o"`|Alias used but table not in `FROM`|Add the join|
|`aggregate functions are not allowed in WHERE`|Aggregate in `WHERE`|Use `HAVING`|
|`window functions are not allowed in WHERE`|Same, with `OVER`|Wrap in a CTE or subquery|
|`more than one row returned by a subquery used as an expression`|Scalar subquery returned several rows|Add `LIMIT 1`, an aggregate, or use `IN`|
|`operator does not exist: integer = text`|Comparing different types|Cast with `::`|
|`division by zero`|Dividing by 0|`x / nullif(y, 0)`|
|`syntax error at or near "FROM"`|Often a trailing comma at the end of the `SELECT` list|Remove it|
|`for SELECT DISTINCT, ORDER BY expressions must appear in select list`|Sorting by a column you didn't select|Select it, or use `DISTINCT ON`|

---

## 16. `SELECT` in Spring Boot

Every Spring Data read method turns into one of the queries above.

|In Java|SQL it produces|
|---|---|
|`findById(5L)`|`SELECT ... FROM clients WHERE id = 5`|
|`findByStatus("active")`|`... WHERE status = 'active'`|
|`findByStatusOrderByNameAsc("active")`|`... WHERE status = ? ORDER BY name ASC`|
|`existsByEmail(e)`|A `SELECT` that stops at the first match|
|`findAll(PageRequest.of(0, 20))`|`... LIMIT 20` (plus `OFFSET`, plus a separate `SELECT count(*)`)|
|`@Query("select ...")`|Your own JPQL|
|`@Query(nativeQuery = true)`|Your own SQL, for window functions, `DISTINCT ON`, special operators|

A projection returns only the columns you need, instead of loading the whole entity (the Java version of avoiding `SELECT *`):

```java
public interface ClientSummary {
    String getName();
    long getOrders();
}

public interface ClientRepository extends JpaRepository<Client, Long> {

    List<Client> findByStatusOrderByNameAsc(String status);

    @Query(value = """
        SELECT c.name AS name, count(o.id) AS orders
        FROM clients c
        LEFT JOIN orders o ON o.client_id = c.id
        GROUP BY c.id, c.name
        ORDER BY orders DESC, c.name
        """, nativeQuery = true)
    List<ClientSummary> summaries();
}
```

Line by line: the interface lists the getters you want, the `AS name` and `AS orders` aliases must match them, and Spring fills in implementations of `ClientSummary` from each result row. This is the same `LEFT JOIN` plus `count(o.id)` query from section 6.

**The N+1 problem.** If a `Client` entity has a lazy `orders` list, loading 100 clients and then touching `client.getOrders()` in a loop runs 1 query for the clients plus 100 more, one per client. Fix it by fetching them together:

```java
@Query("select distinct c from Client c join fetch c.orders")
List<Client> findAllWithOrders();
```

Or use `@EntityGraph(attributePaths = "orders")` on the repository method. If you ever see your logs fill with repeating `select ... from orders where client_id=?`, this is the cause. You can see the SQL with `spring.jpa.show-sql=true`.

---

## Related concepts, in short

- **Views and materialized views:** a named, saved `SELECT`. Covered in the DDL and pgAdmin lessons.
- **Recursive CTEs:** `WITH RECURSIVE` queries that repeat until done, used for trees such as categories or org charts.
- **`SELECT ... FOR UPDATE`:** reads rows and locks them until the transaction ends. With `SKIP LOCKED`, it is a common way to build a job queue.
- **Transaction snapshots:** a `SELECT` sees a consistent snapshot of the data. What exactly it sees while others are writing depends on the _isolation level_, a good topic for a future lesson.
- **`LATERAL` joins:** a join where the right side can refer to columns of the left row, handy for "top 3 orders per client."

---

## Quick cheat sheet

```sql
SELECT DISTINCT a, b + 1 AS c, count(*) FILTER (WHERE ...)    -- 5, 6: output columns
FROM t1 x
JOIN t2 y ON y.t1_id = x.id                                    -- 1: tables and joins
LEFT JOIN t3 z ON z.id = y.z_id                                -- 1
WHERE x.status = 'active' AND y.total >= 10                    -- 2: filter rows
GROUP BY a, b                                                  -- 3: make groups
HAVING count(*) > 1                                            -- 4: filter groups
ORDER BY c DESC NULLS LAST                                     -- 7: sort
LIMIT 20 OFFSET 40;                                            -- 8: cut

WITH name AS (SELECT ...) SELECT ... FROM name;                -- CTE
SELECT f(x) OVER (PARTITION BY a ORDER BY b) FROM t;           -- window function
SELECT ... UNION ALL SELECT ...;                               -- stack results
EXPLAIN ANALYZE SELECT ...;                                    -- see the plan
```




[[PostgreSQL]]