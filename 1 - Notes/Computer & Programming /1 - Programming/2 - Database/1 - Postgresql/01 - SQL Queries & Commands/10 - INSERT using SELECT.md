

Normally you add rows with `INSERT ... VALUES`, where you type the data by hand. But very often the data you want to insert already lives somewhere in the database: in another table, in the result of a join, or in a computed aggregate. `INSERT ... SELECT` lets you feed the result of any query straight into a table, in one statement, entirely inside the database. No round trip to the application, no row-by-row loop.

It's one of the most useful tools for copying, archiving, backfilling, and transforming data, and it has some subtle details (column matching, conflicts, `RETURNING`, CTEs) that are worth learning properly.

---

## The problem it solves

Suppose you need to archive old orders. The naive approach looks like this:

1. Run `SELECT * FROM orders WHERE created_at < '2025-01-01'` in your application.
2. Pull millions of rows over the network.
3. Loop and run `INSERT` for each row into `orders_archive`.

That's slow, uses lots of memory and bandwidth, and is hard to make atomic. With `INSERT ... SELECT`, the database does all of it internally in a single statement:

```sql
INSERT INTO orders_archive
SELECT * FROM orders WHERE created_at < '2025-01-01';
```

The data never leaves the server, and the statement is atomic: either every row is inserted or none are.

## Basic syntax

```sql
INSERT INTO target_table [ (column1, column2, ...) ]
SELECT expr1, expr2, ...
FROM source ...
[ ON CONFLICT ... ]
[ RETURNING ... ];
```

A few things to notice:

- The `SELECT` replaces the `VALUES` clause. Everything a normal `SELECT` can do (joins, `WHERE`, `GROUP BY`, `ORDER BY`, subqueries, window functions) is allowed.
- The **column list is optional but strongly recommended**. Without it, values are matched to the target's columns by position, in table order.
- The number of selected expressions must match the number of target columns, and the types must be compatible (or castable).

## Example tables

The examples below use these tables:

```sql
CREATE TABLE orders (
    id          serial PRIMARY KEY,
    customer_id int NOT NULL,
    total       numeric(10,2) NOT NULL,
    status      text NOT NULL DEFAULT 'new',
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE orders_archive (
    id          int PRIMARY KEY,
    customer_id int NOT NULL,
    total       numeric(10,2) NOT NULL,
    status      text NOT NULL,
    created_at  timestamptz NOT NULL,
    archived_at timestamptz NOT NULL DEFAULT now()
);
```

## Always list your columns

This works, but it's fragile:

```sql
INSERT INTO orders_archive
SELECT * FROM orders;
-- ERROR: INSERT has more target columns than expressions? (or vice versa)
```

Here `orders_archive` has an extra `archived_at` column, so the column counts differ. Even when the counts happen to match, a positional insert silently breaks if someone later adds or reorders a column. Name the columns on both sides:

```sql
INSERT INTO orders_archive (id, customer_id, total, status, created_at)
SELECT id, customer_id, total, status, created_at
FROM orders
WHERE created_at < '2025-01-01';
```

The skipped column `archived_at` gets its `DEFAULT`, which is `now()`. Any column you omit from the list is filled with its default (or `NULL` if there's no default).

## Inserting computed and constant values

The `SELECT` list can contain literals, expressions, and function calls, so you can mix copied data with new values:

```sql
INSERT INTO orders_archive (id, customer_id, total, status, created_at, archived_at)
SELECT id, customer_id, total, 'archived', created_at, clock_timestamp()
FROM orders
WHERE status = 'done';
```

You can also insert without any source table:

```sql
INSERT INTO orders (customer_id, total)
SELECT 42, 19.99;
```

This is equivalent to `VALUES (42, 19.99)`.

## Inserting from joins and aggregates

Because it's just a query, you can build summary or denormalized tables:

```sql
CREATE TABLE customer_totals (
    customer_id int PRIMARY KEY,
    order_count int NOT NULL,
    lifetime_value numeric(12,2) NOT NULL
);

INSERT INTO customer_totals (customer_id, order_count, lifetime_value)
SELECT customer_id, count(*), sum(total)
FROM orders
GROUP BY customer_id;
```

## Generating test data with generate_series

A very handy trick for creating lots of rows quickly:

```sql
INSERT INTO orders (customer_id, total, created_at)
SELECT
    (random() * 1000)::int,
    round((random() * 500)::numeric, 2),
    now() - (random() * interval '365 days')
FROM generate_series(1, 100000);
```

That inserts 100,000 random rows in a fraction of a second.

## Handling conflicts: ON CONFLICT

If the target has a unique constraint and the `SELECT` produces a duplicate, the whole statement fails. `ON CONFLICT` lets you decide what to do instead.

**Skip duplicates:**

```sql
INSERT INTO orders_archive (id, customer_id, total, status, created_at)
SELECT id, customer_id, total, status, created_at
FROM orders
WHERE created_at < '2025-01-01'
ON CONFLICT (id) DO NOTHING;
```

**Update on duplicate (an "upsert"):**

```sql
INSERT INTO customer_totals (customer_id, order_count, lifetime_value)
SELECT customer_id, count(*), sum(total)
FROM orders
GROUP BY customer_id
ON CONFLICT (customer_id) DO UPDATE
SET order_count    = EXCLUDED.order_count,
    lifetime_value = EXCLUDED.lifetime_value;
```

`EXCLUDED` refers to the row that was proposed for insertion. One gotcha: if the `SELECT` itself returns **two rows with the same conflict key**, `DO UPDATE` fails with _"ON CONFLICT DO UPDATE command cannot affect row a second time."_ Deduplicate in the `SELECT` first (with `GROUP BY` or `DISTINCT ON`).

## Seeing what was inserted: RETURNING

`RETURNING` gives back the inserted rows, which is especially useful for getting generated IDs:

```sql
INSERT INTO orders (customer_id, total)
SELECT id, 0
FROM customers
WHERE is_new
RETURNING id, customer_id;
```

## Chaining statements with CTEs

Combining `INSERT ... SELECT` with a Common Table Expression gives you a powerful "move rows" pattern. This deletes old orders and archives exactly the rows that were deleted, in one atomic statement:

```sql
WITH moved AS (
    DELETE FROM orders
    WHERE created_at < '2025-01-01'
    RETURNING id, customer_id, total, status, created_at
)
INSERT INTO orders_archive (id, customer_id, total, status, created_at)
SELECT id, customer_id, total, status, created_at
FROM moved;
```

You can also put the `SELECT` side in a CTE just to keep complex logic readable:

```sql
WITH recent_big AS (
    SELECT customer_id, sum(total) AS spent
    FROM orders
    WHERE created_at > now() - interval '30 days'
    GROUP BY customer_id
    HAVING sum(total) > 1000
)
INSERT INTO vip_customers (customer_id, spent)
SELECT customer_id, spent FROM recent_big;
```

## Inserting into the same table you read from

It's legal to select from the table you're inserting into, for example to duplicate rows:

```sql
INSERT INTO orders (customer_id, total, status)
SELECT customer_id, total, 'copy'
FROM orders
WHERE id = 7;
```

The `SELECT` sees a snapshot taken when the statement began, so the new rows are not re-read by the same statement and you won't get an infinite loop.

## Creating a table from a query: the cousins

Two related commands create the target table for you:

```sql
CREATE TABLE orders_2024 AS
SELECT * FROM orders WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01';

SELECT * INTO orders_backup FROM orders;   -- older syntax, same idea
```

These copy the data and column types, but **not** constraints, indexes, defaults, or the primary key. If you want the structure copied properly, create the table first (for example with `CREATE TABLE new (LIKE orders INCLUDING ALL)`) and then use `INSERT ... SELECT`.

## Performance tips for big inserts

- **One big statement beats many small ones.** It's far less overhead than row-by-row inserts.
- **Consider batching** very large copies (for example by id ranges) so a failure doesn't roll back hours of work and so locks and WAL stay manageable.
- **Indexes and triggers slow inserts.** For a huge initial load into an empty table, creating indexes _after_ the insert is often much faster.
- **Run `ANALYZE` afterward** so the planner has up-to-date statistics for the new data.
- **`ORDER BY` in the `SELECT`** does not guarantee any physical order in the target, but it can influence the insertion order, which sometimes helps clustering and index locality.

## Common pitfalls

- **Skipping the column list**, which breaks silently when the schema changes.
- **Column count or type mismatches.** Add explicit casts like `col::int` when needed.
- **Violating `NOT NULL` or unique constraints.** One bad row fails the entire statement, so use `ON CONFLICT` or filter in the `SELECT`.
- **Duplicates within the source** when using `ON CONFLICT DO UPDATE`.
- **Forgetting that it's all-or-nothing.** The statement is atomic, which is usually what you want but means a failure rolls back every row.
- **Assuming sequences won't be consumed on failure.** Failed or conflicting rows may still use up serial/identity values, leaving gaps. That's normal and harmless.

## Quick cheat sheet

```sql
-- Basic copy with explicit columns
INSERT INTO target (a, b) SELECT a, b FROM source WHERE ...;

-- With computed/constant values
INSERT INTO target (a, b, note) SELECT a, b, 'imported' FROM source;

-- Skip duplicates
INSERT INTO target (id, x) SELECT id, x FROM source ON CONFLICT (id) DO NOTHING;

-- Upsert
INSERT INTO target (id, x) SELECT id, x FROM source
ON CONFLICT (id) DO UPDATE SET x = EXCLUDED.x;

-- Get inserted rows back
INSERT INTO target (a) SELECT a FROM source RETURNING *;

-- Move rows atomically
WITH moved AS (DELETE FROM src WHERE ... RETURNING *)
INSERT INTO dst SELECT * FROM moved;

-- Test data
INSERT INTO t (n) SELECT g FROM generate_series(1, 100000) AS g;
```




[[PostgreSQL]]