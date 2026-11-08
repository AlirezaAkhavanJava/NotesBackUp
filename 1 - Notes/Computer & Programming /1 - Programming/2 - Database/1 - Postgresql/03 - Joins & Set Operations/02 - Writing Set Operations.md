

Set operations stack the results of two or more queries into one result. Where a join widens rows with more columns, a set operation keeps the same columns and adds, merges, or removes _rows_. There are only three ideas (`UNION`, `INTERSECT`, `EXCEPT`) and each has an `ALL` variant, so the syntax is small. The interesting part is how they behave with duplicates and `NULL`s, and how they combine with the advanced tools from the join tutorial.

This one covers how to write each operation with counting formulas you can check by hand, then recursive, literal, window, filtering and pushdown, algorithm, foreign data, and materialized uses. The join tutorial's mention of "window joins" had no real keyword behind it, and neither do set operations, so that section covers the actual techniques.

---

## The grammar

```sql
query1
{ UNION | INTERSECT | EXCEPT } [ ALL | DISTINCT ]
query2
[ ORDER BY ... ] [ LIMIT ... ]
```

`DISTINCT` is the default, so plain `UNION` means `UNION DISTINCT`. You can chain as many queries as you like. The rules that must hold:

- Every query returns the **same number of columns**.
- Columns in the same position need **compatible types**. Postgres resolves one common type per column, the same way `CASE` does, and fails if it can't (`SELECT 1 UNION SELECT 'a'` errors, because `'a'` can't become an integer). Add explicit casts when types differ.
- Output **column names come from the first query**.
- **`ORDER BY` and `LIMIT` at the end** apply to the whole result and may use only output names or positions. To order or limit one branch, wrap it in parentheses.

**Precedence:** `INTERSECT` binds tighter than `UNION` and `EXCEPT`, and those two evaluate left to right. Parenthesize anything mixed.

## The six operations, with counts you can verify

Take these two lists, with duplicates on purpose:

```sql
WITH a(x) AS (VALUES (1),(1),(2),(2),(3)),
     b(x) AS (VALUES (2),(2),(2),(3),(3),(4))
SELECT x FROM a UNION ALL SELECT x FROM b;     -- swap the operator to try each
```

Write `a_v` and `b_v` for how many times value `v` appears in each list (a: 1×2, 2×2, 3×1; b: 2×3, 3×2, 4×1).

|Operation|Formula for the row count|Result here|
|---|---|---|
|`UNION ALL`|\|A\| + \|B\||5 + 6 = **11**|
|`UNION`|number of distinct values across both|{1,2,3,4} = **4**|
|`INTERSECT ALL`|Σ min(a_v, b_v)|min(2,3) + min(1,2) = **3**|
|`INTERSECT`|values present in both|{2,3} = **2**|
|`EXCEPT ALL`|Σ max(a_v − b_v, 0)|2 + 0 + 0 = **2** (the two 1s)|
|`EXCEPT`|distinct values in A that are absent from B|{1} = **1**|

Two things follow from the formulas. `EXCEPT` is **not symmetric** (`B EXCEPT A` gives {4}, a different answer), and the `ALL` versions count duplicates, so `EXCEPT ALL` can "use up" one copy per match instead of deleting every copy.

**NULLs are equal here.** In a join `NULL = NULL` fails, but set operations treat `NULL`s as the same value, exactly like `DISTINCT`. So `NULL` rows match each other in `INTERSECT` and cancel in `EXCEPT`.

The same operators work inside `INSERT ... SELECT`, `CREATE TABLE AS`, subqueries, and CTEs.

---

## Recursive sets

A recursive CTE is itself a set operation: an anchor query, then `UNION [ALL]`, then a recursive query that reads the previous round. The choice between `UNION` and `UNION ALL` matters:

```sql
WITH RECURSIVE reach(node) AS (
    SELECT 1                                   -- anchor: start here
    UNION                                      -- discards rows already seen
    SELECT e.dst FROM edges e JOIN reach r ON e.src = r.node
)
SELECT node FROM reach;
```

With `UNION`, a row that was already produced is dropped, so a graph with cycles still terminates. The catch is that it compares **whole rows**: if you also carry a changing column such as `depth`, no row ever repeats and the cycle runs forever. With `UNION ALL` you must prevent loops yourself (the `CYCLE` clause in PG 14+, or a visited-array check). One restriction: the recursive reference cannot appear inside an `INTERSECT` or `EXCEPT`.

## Literal sets

`VALUES` is a full query, so it works as a branch or on its own:

```sql
VALUES (1, 'new'), (2, 'open')
UNION ALL
SELECT id, status FROM tickets WHERE closed;

SELECT * FROM (VALUES (1,'a'), (2,'b')) AS v(id, label);   -- name the columns
```

Typing literals into a branch is also how you add a **tag column** (`SELECT 'crm' AS source, email ...`), which later sections rely on. Arrays work too: `SELECT unnest(ARRAY[1,2,3]) EXCEPT SELECT id FROM used_ids` finds the unused ids from a list you pass in.

---

## "Window" techniques with sets

**Window functions over a union.** The window runs after the stacking, so wrap the union in a subquery:

```sql
SELECT day, amount,
       sum(amount) OVER (ORDER BY day) AS running_total
FROM (
    SELECT day, amount FROM sales_online
    UNION ALL
    SELECT day, amount FROM sales_store
) s;
```

**Union with a preferred source.** When the same key appears in several sources and one should win, tag each branch with a priority and keep the best row per key:

```sql
SELECT DISTINCT ON (email) email, source
FROM (
    SELECT email, 1 AS prio, 'crm' AS source FROM crm_contacts
    UNION ALL
    SELECT email, 2, 'newsletter' FROM subscribers
) u
ORDER BY email, prio;
```

**Latest N across several tables.** Limit inside each branch first, then again outside. This is far cheaper than sorting everything:

```sql
(SELECT * FROM events_2025 ORDER BY ts DESC LIMIT 5)
UNION ALL
(SELECT * FROM events_2026 ORDER BY ts DESC LIMIT 5)
ORDER BY ts DESC LIMIT 5;
```

---

## Filtering and predicate pushdown

For a `UNION ALL` used as a subquery or view, Postgres flattens the branches and pushes outer `WHERE` conditions down into each one, so each branch can use its own index:

```sql
SELECT * FROM (
    SELECT id, total FROM orders_2025
    UNION ALL
    SELECT id, total FROM orders_2026
) o
WHERE id = 7;            -- becomes an index lookup inside every branch
```

Pushdown is also attempted for `UNION`, `INTERSECT` and `EXCEPT`, but it stops at barriers: a branch with `LIMIT`/`OFFSET`, volatile functions, or a window function (only conditions on the partition columns can pass). A cast that Postgres adds to reconcile mismatched branch types can also stop an index from being used on that column, so make branch types match explicitly.

A handy trick is a **literal tag plus a filter on it**. When the pushed condition becomes constant-false for a branch, the plan shows `One-Time Filter: false` and that branch is never executed:

```sql
SELECT * FROM (
    SELECT 'a' AS src, id FROM big_a
    UNION ALL
    SELECT 'b', id FROM big_b
) u
WHERE src = 'a';         -- big_b is skipped entirely
```

Also remember the cheaper choice: if the same filter applies before stacking, write it in each branch yourself rather than relying on the planner, and prefer `UNION ALL` to avoid the dedupe step.

## How Postgres executes them

|Operation|Typical plan|
|---|---|
|`UNION ALL`|`Append` (can run in parallel); `Merge Append` if branches are sorted and the result is ordered|
|`UNION`|`Append`, then `HashAggregate`, or `Sort` + `Unique`|
|`INTERSECT` / `EXCEPT`|`Append` of both inputs, then `HashSetOp` (or `Sort` + `SetOp`)|

The last row explains how they work: both inputs are appended with a flag saying which side each row came from, then rows are grouped and the per-side counts are compared against the formulas above. That means they need to see all rows (no early `LIMIT` benefit), and the distinct rows must fit in memory, governed by `work_mem`, or the plan falls back to sorting and may spill to disk.

For key-based questions ("customers without an order") `NOT EXISTS` usually beats `EXCEPT`, because it can use an index and stop at the first match. `EXCEPT` earns its place when comparing **whole rows**, `NULL`s included.

---

## Foreign data

Each branch of a `UNION ALL` over foreign tables becomes its own `Foreign Scan`, with that branch's filters shipped to the remote server. The stacking happens locally:

```sql
SELECT id, total FROM orders_local
UNION ALL
SELECT id, total FROM remote.orders_archive
WHERE total > 100;
```

On PG 14+ you can mark `postgres_fdw` servers or tables with `async_capable 'true'` so several remote branches fetch concurrently instead of one after another. For a permanent layout, attach remote tables as partitions of one logical table, which gives you pruning on top of the stacking:

```sql
CREATE TABLE orders (id bigint, placed date, total numeric)
    PARTITION BY RANGE (placed);

CREATE FOREIGN TABLE orders_2023 PARTITION OF orders
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01')
    SERVER archive_srv;
```

Queries filtered on `placed` only touch the relevant partitions. The limitation is that you can't create indexes on foreign tables, so the parent can't have a unique constraint spanning them. (Server and user-mapping setup is the same as in the join tutorial.)

## Materialized sets

A stacked result that many queries need can be stored once:

```sql
CREATE MATERIALIZED VIEW all_contacts AS
SELECT email, 'crm' AS source FROM crm_contacts
UNION ALL
SELECT email, 'newsletter' FROM subscribers;

CREATE UNIQUE INDEX ON all_contacts (email, source);
REFRESH MATERIALIZED VIEW CONCURRENTLY all_contacts;
```

`CONCURRENTLY` needs a unique index covering every row, which is why the tag column is useful: it makes rows from different sources distinguishable. If one source could still contain exact duplicates, include its key in the index or use plain `UNION` to dedupe. As always, the refresh recomputes the whole query, and the view is only as fresh as its last refresh.

---

## Two patterns worth keeping

**Diffing two tables** (symmetric difference), whole rows, `NULL`s included:

```sql
(SELECT * FROM live     EXCEPT SELECT * FROM snapshot)    -- new or changed rows
UNION ALL
(SELECT * FROM snapshot EXCEPT SELECT * FROM live)        -- removed or old versions
```

If this returns zero rows, the tables are identical (as sets). Use `EXCEPT ALL` to also catch differing duplicate counts.

**Choosing between tools:**

|You want|Use|
|---|---|
|Extra columns about each row|a join|
|More rows of the same shape|`UNION ALL`|
|Rows of A with no key match in B|`NOT EXISTS`|
|Rows of A not present in B, whole-row|`EXCEPT`|
|Rows present in both, whole-row|`INTERSECT`|




[[PostgreSQL]]