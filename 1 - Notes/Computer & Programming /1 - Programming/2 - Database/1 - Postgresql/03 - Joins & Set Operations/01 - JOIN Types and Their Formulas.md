
---

## Part 1: The syntax for every join type

```sql
SELECT c.name, o.amount
FROM customers c                          -- alias keeps it short
[INNER] JOIN orders o ON o.customer_id = c.id;
```

Swap the join keyword and the rest stays the same:

```sql
FROM a JOIN b ON a.id = b.a_id            -- inner: matches only
FROM a LEFT JOIN b ON a.id = b.a_id       -- keep all of a
FROM a RIGHT JOIN b ON a.id = b.a_id      -- keep all of b
FROM a FULL JOIN b ON a.id = b.a_id       -- keep all of both
FROM a CROSS JOIN b                       -- every pair, no condition
FROM a JOIN b USING (id)                  -- same column name, merged in output
```

`OUTER` is optional (`LEFT OUTER JOIN` equals `LEFT JOIN`). To join more than two tables, chain them, and each `ON` can refer to anything above it:

```sql
FROM orders o
JOIN customers c   ON c.id = o.customer_id
LEFT JOIN coupons k ON k.id = o.coupon_id
JOIN order_items i ON i.order_id = o.id
```

Two habits: write the join condition in `ON` and the filters in `WHERE`, and avoid the old comma style (`FROM a, b WHERE ...`) and `NATURAL JOIN`, which silently joins on every same-named column.

---

## Part 2: Recursive joins

Some data is a tree of unknown depth: employees and managers, categories and subcategories, folders. A normal join can climb one level. A **recursive CTE** joins a result back to the table repeatedly until nothing new appears:

```sql
WITH RECURSIVE org AS (
    -- 1. anchor: where to start
    SELECT id, name, manager_id, 1 AS depth
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- 2. recursive step: join the previous round to the table
    SELECT e.id, e.name, e.manager_id, org.depth + 1
    FROM employees e
    JOIN org ON e.manager_id = org.id
)
SELECT * FROM org ORDER BY depth;
```

It runs in rounds: the anchor produces round one, then the recursive part joins _only the newest rows_ to the table to produce the next round, and it stops when a round returns zero rows.

To walk upward instead (an employee's chain of bosses), flip the anchor and the join condition. Two safety points matter in practice:

- **Cycles.** If the data loops (A manages B manages A), the query never ends. Postgres 14+ has built-in detection: add `CYCLE id SET is_cycle USING path` after the CTE. On older versions, carry an array of visited ids and test `NOT (e.id = ANY(path))`.
- **Ordering.** PG 14+ also supports `SEARCH DEPTH FIRST BY id SET ordercol` (or `BREADTH FIRST`) for tree-ordered output.

Use `UNION ALL` unless you need duplicate elimination, and index the join column (`manager_id`), because it's probed once per round.

---

## Part 3: Literal joins (VALUES) and LATERAL joins

**Joining a literal list.** `VALUES` builds a tiny table inline, which is great for lookups and for passing in a batch of keys:

```sql
SELECT p.id, p.name, v.label
FROM products p
JOIN (VALUES (1, 'featured'), (7, 'clearance')) AS v(id, label)
  ON v.id = p.id;
```

For an array parameter, `unnest` does the same job, and `WITH ORDINALITY` keeps the original position:

```sql
SELECT p.*, k.pos
FROM unnest(ARRAY[7, 3, 9]) WITH ORDINALITY AS k(id, pos)
JOIN products p ON p.id = k.id
ORDER BY k.pos;                       -- returns rows in the order you listed ids
```

**LATERAL** lets the right side refer to columns of the left side, like a per-row loop. The classic use is "top N per group":

```sql
SELECT c.name, recent.id, recent.amount
FROM customers c
LEFT JOIN LATERAL (
    SELECT o.id, o.amount
    FROM orders o
    WHERE o.customer_id = c.id          -- refers to the outer row
    ORDER BY o.created_at DESC
    LIMIT 3
) AS recent ON true                     -- ON true because the matching is inside
```

Use `LEFT JOIN LATERAL ... ON true` to keep customers who have no orders, or `CROSS JOIN LATERAL` to drop them. A set-returning function in `FROM` (like `unnest(c.tags)`) is implicitly lateral. With an index on `orders (customer_id, created_at DESC)`, this runs as a fast per-customer index lookup.

---

## Part 4: "Window joins"

Three real patterns go by this name.

**1. A window function over joined rows.** The join happens first, then the window runs on its result:

```sql
SELECT c.name, o.id, o.amount,
       sum(o.amount) OVER (PARTITION BY c.id ORDER BY o.created_at) AS running_spend
FROM customers c
JOIN orders o ON o.customer_id = c.id;
```

**2. Join to a windowed subquery** (for example, each customer's latest order). Window results can't be used in `WHERE` directly, so wrap them:

```sql
SELECT *
FROM (
    SELECT c.name, o.id, o.amount,
           row_number() OVER (PARTITION BY c.id ORDER BY o.created_at DESC) AS rn
    FROM customers c
    JOIN orders o ON o.customer_id = c.id
) t
WHERE rn = 1;
```

**3. A time-window ("as-of") join:** match each event to the most recent reference row at that moment, like the exchange rate in effect when a trade happened. Postgres has no `ASOF JOIN`, but `LATERAL` does it cleanly:

```sql
SELECT t.id, t.amount, r.rate
FROM trades t
LEFT JOIN LATERAL (
    SELECT rate
    FROM rates r
    WHERE r.currency = t.currency
      AND r.valid_from <= t.traded_at
    ORDER BY r.valid_from DESC
    LIMIT 1
) r ON true;
```

An index on `rates (currency, valid_from DESC)` makes each lookup cheap. For "within a window" matches, use a range condition (`ON e.ts BETWEEN s.start AND s.end`), or `tstzrange` columns with a GiST index and the `&&` / `@>` operators for fast overlap joins.

---

## Part 5: Join filtering and predicate pushdown

The planner doesn't run your query in the written order. It **pushes filters down** so rows are discarded as early as possible, before the join does its work.

For inner joins, `ON` and `WHERE` are interchangeable, and the planner moves single-table conditions down to the scans. It also derives conditions through equality: given `a.id = b.a_id AND a.id = 5`, it deduces `b.a_id = 5` and filters both sides.

For outer joins, the placement changes the answer:

```sql
-- Keeps every customer; 2026 orders attach where they exist
FROM customers c LEFT JOIN orders o
  ON o.customer_id = c.id AND o.created_at >= '2026-01-01'

-- Customers without 2026 orders vanish: it's now effectively an inner join
FROM customers c LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.created_at >= '2026-01-01'
```

In the second form the planner notices the `WHERE` rejects `NULL`-padded rows and rewrites the `LEFT JOIN` into an inner join. That's the **outer join reduction** you'll sometimes see, and it's a handy tell that your outer join wasn't doing anything. Filters on the _preserved_ side (customers) in `WHERE` are still pushed below the join safely.

Pushdown **doesn't happen** across some barriers: a subquery with `LIMIT` or `OFFSET`, `DISTINCT ON`, a window function (only conditions on the `PARTITION BY` columns can be pushed), or a recursive CTE. Non-recursive CTEs referenced once are inlined since PG 12, and you can control it with `WITH x AS MATERIALIZED (...)` or `NOT MATERIALIZED`.

In `EXPLAIN` you can read what happened by where the condition appears:

```
Hash Join
  Hash Cond: (o.customer_id = c.id)       -- the join condition
  ->  Seq Scan on orders o
        Filter: (amount > 100)            -- pushed down: applied during the scan
  ->  Hash
        ->  Seq Scan on customers c
```

A line called **`Join Filter`** is the one to watch: it means a condition is checked at the join node against pairs, typical for non-equality joins or nested loops, and it's often where time disappears.

---

## Part 6: Join algorithms

Postgres picks one of three strategies per join, based on estimated cost:

|Algorithm|How it works|Best when|Conditions|
|---|---|---|---|
|**Nested Loop**|for each outer row, find matches in the inner side|outer side small, inner side indexed|any condition|
|**Hash Join**|build a hash table from the smaller side, probe it with the other|large unsorted inputs|equality only|
|**Merge Join**|walk two inputs sorted on the key in parallel|both sides big and already sorted (or indexed)|equality only|

A few details that explain real plans:

- A nested loop is only fast if the inner side has an index. Without one, it rescans the inner table per outer row. PG 14+ can add a **Memoize** node that caches inner results for repeated keys.
- A hash join is fastest when the hash table fits in `work_mem` (scaled by `hash_mem_multiplier`). If not, it splits into batches written to disk, and `EXPLAIN ANALYZE` shows `Batches: 4` or more instead of `1`.
- A merge join needs sorted input, so it either reads from an index or adds a `Sort`, which is where its cost hides.
- The planner also chooses the **join order**. Its search is exhaustive up to `join_collapse_limit` (8 tables), and beyond roughly 12 tables it switches to the genetic optimizer (`geqo_threshold`).

If a plan looks wrong, the usual causes are stale statistics (run `ANALYZE`) or a missing index on a join column. You can temporarily disable a method for testing with `SET enable_nestloop = off`, but treat that as a diagnostic, not a fix.

---

## Part 7: Foreign data joins

`postgres_fdw` makes tables in another Postgres database look local, so you can join across servers. Setup is four statements:

```sql
CREATE EXTENSION postgres_fdw;

CREATE SERVER sales_srv FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'db2.example.com', port '5432', dbname 'sales');

CREATE USER MAPPING FOR current_user SERVER sales_srv
    OPTIONS (user 'reader', password 'secret');

CREATE SCHEMA remote;
IMPORT FOREIGN SCHEMA public LIMIT TO (orders) FROM SERVER sales_srv INTO remote;
```

Now it's just a join:

```sql
SELECT c.name, o.amount
FROM customers c                      -- local table
JOIN remote.orders o ON o.customer_id = c.id;
```

What matters is **how much work is pushed to the remote server**. Check with `EXPLAIN VERBOSE`:

- If both tables live on the **same remote server**, `postgres_fdw` can ship the whole join over (you'll see a single `Foreign Scan` with a `Remote SQL:` line containing the `JOIN`), and only the result crosses the network.
- For a **local-to-remote** join, the local server pulls the (filtered) remote rows and joins locally. So filters on the remote table matter a lot: they're pushed into the remote SQL when they use built-in or shippable functions and operators.
- Remote tables have no local statistics until you run `ANALYZE` on the foreign table, and the `use_remote_estimate` option can ask the remote server for estimates instead. Raising `fetch_size` (default 100 rows per round trip) helps big scans.

Rule of thumb: keep the small table local, filter the remote one as hard as you can, and for heavy repeated reporting, copy the remote data locally instead (next section).

---

## Part 8: Materialized joins

An expensive join that many queries need can be computed once and stored. That's a **materialized view**:

```sql
CREATE MATERIALIZED VIEW customer_summary AS
SELECT c.id, c.name, count(o.id) AS orders, coalesce(sum(o.amount), 0) AS spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
WITH DATA;

CREATE UNIQUE INDEX ON customer_summary (id);     -- index it like a normal table
```

Reads are now as fast as reading one table. The trade-off is **freshness**: the stored result is a snapshot, and it only updates when you refresh:

```sql
REFRESH MATERIALIZED VIEW customer_summary;                 -- rebuilds; blocks reads while it runs
REFRESH MATERIALIZED VIEW CONCURRENTLY customer_summary;    -- readers keep working
```

`CONCURRENTLY` requires at least one **unique index** on the view, and it's slower overall because it diffs old against new. Postgres core has no incremental refresh, so every refresh recomputes the full join. Schedule it with `pg_cron` or your application. When you need always-current data without full rebuilds, the alternatives are a summary table maintained by triggers, or an extension such as `pg_ivm` for incremental maintenance.

Choosing between the three stores comes down to freshness and cost: a plain **view** is always fresh but recomputes the join every time, a **materialized view** is fast but stale until refreshed, and a **trigger-maintained table** is fast and fresh but costs extra work on every write.




[[PostgreSQL]]