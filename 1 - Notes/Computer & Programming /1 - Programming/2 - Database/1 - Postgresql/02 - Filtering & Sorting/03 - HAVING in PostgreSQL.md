

`HAVING` filters **groups** after they've been built. `WHERE` can only see individual rows, so it can't answer questions like "which customers have more than 5 orders?" or "which departments average over 60,000?". Those conditions depend on an aggregate result, and the aggregate doesn't exist until the rows have been grouped. `HAVING` is the clause that runs at that point.

It's a small clause with one big idea (it runs at a different stage than `WHERE`), plus a few traps around `NULL`s, aliases, and performance. Let's walk through it.

---

## Why WHERE can't do this job

Using this table:

```sql
CREATE TABLE orders (
    id          serial PRIMARY KEY,
    customer_id int NOT NULL,
    status      text NOT NULL,
    total       numeric(10,2) NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);
```

Suppose you want customers with more than 5 orders. This is the natural first attempt, and it fails:

```sql
SELECT customer_id, count(*)
FROM orders
WHERE count(*) > 5
GROUP BY customer_id;
-- ERROR: aggregate functions are not allowed in WHERE
```

The reason is the order Postgres processes a query in:

1. `FROM` / joins
2. `WHERE` (filters rows)
3. `GROUP BY` (builds groups)
4. aggregates are computed
5. **`HAVING`** (filters groups)
6. `SELECT`
7. `ORDER BY`, then `LIMIT`

When `WHERE` runs, no groups exist yet, so there's no `count(*)` to compare against. `HAVING` runs after step 4, so it can:

```sql
SELECT customer_id, count(*) AS order_count
FROM orders
GROUP BY customer_id
HAVING count(*) > 5;
```

## WHERE and HAVING together

They aren't rivals, and most real queries use both. `WHERE` throws away unwanted rows first, `HAVING` throws away unwanted groups after:

```sql
SELECT customer_id, count(*) AS paid_orders, sum(total) AS spent
FROM orders
WHERE status = 'paid'                 -- 1. only paid orders enter the groups
  AND created_at >= '2026-01-01'
GROUP BY customer_id
HAVING sum(total) > 1000              -- 2. only big spenders survive
ORDER BY spent DESC;
```

The rule of thumb: **if a condition can be written without an aggregate, it belongs in `WHERE`.** It works in `HAVING` too when the column is a grouping column, but it's slower, because Postgres builds groups for rows you were about to discard. (The planner will sometimes push such a condition down for you, but don't count on it.)

```sql
-- Works, but wasteful: groups every status, then drops most of them
GROUP BY status HAVING status = 'paid'

-- Better
WHERE status = 'paid' GROUP BY status
```

## What you can put in HAVING

Anything that makes sense at the group level: aggregates, grouped columns, or combinations of both, using the usual `AND` / `OR` / `NOT`:

```sql
HAVING count(*) >= 3 AND avg(total) < 50
HAVING max(created_at) < now() - interval '1 year'      -- customers inactive for a year
HAVING count(DISTINCT status) = 3                        -- used all three statuses
HAVING sum(total) > 2 * avg(total)
```

You can even use an aggregate in `HAVING` that doesn't appear in your `SELECT` list. The filter and the output are independent:

```sql
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING sum(total) > 1000;       -- sum isn't selected, only used to filter
```

Subqueries work as well, which is handy for "above the overall average" questions:

```sql
SELECT customer_id, avg(total) AS avg_total
FROM orders
GROUP BY customer_id
HAVING avg(total) > (SELECT avg(total) FROM orders);
```

## The alias gotcha

`HAVING` runs _before_ `SELECT`, so you **cannot** use a select-list alias in it:

```sql
SELECT customer_id, count(*) AS order_count
FROM orders
GROUP BY customer_id
HAVING order_count > 5;
-- ERROR: column "order_count" does not exist
```

Repeat the expression (`HAVING count(*) > 5`), or wrap the query in a subquery or CTE and filter with a plain `WHERE` outside:

```sql
SELECT *
FROM (
    SELECT customer_id, count(*) AS order_count
    FROM orders
    GROUP BY customer_id
) t
WHERE order_count > 5;
```

(`ORDER BY` runs after `SELECT`, so it _can_ use the alias. `HAVING` can't.) Repeating `count(*)` isn't a performance worry: Postgres computes identical aggregates once.

## HAVING without GROUP BY

This is legal and a little odd. If you use `HAVING` with no `GROUP BY`, the whole table is treated as **one single group**, and you get either one row or none:

```sql
SELECT count(*) AS n, avg(total)
FROM orders
HAVING count(*) > 1000;
```

This returns one row if the table has more than 1,000 orders, and nothing otherwise. It's occasionally useful as a "only report if there's enough data" check.

## NULLs and HAVING

Like `WHERE`, `HAVING` keeps a group only if the condition is exactly `TRUE`. A `NULL` result discards the group. The usual surprise comes from aggregates over `NULL`s:

- `sum()` and `avg()` ignore `NULL` inputs, and return `NULL` if _every_ input is `NULL`. So `HAVING sum(x) < 100` silently drops groups where all `x` are `NULL`.
- `count(col)` skips `NULL`s while `count(*)` doesn't, so `HAVING count(col) = 0` finds groups where the column is entirely empty.

If you want such groups included, handle it explicitly: `HAVING coalesce(sum(x), 0) < 100`.

## Patterns worth knowing

**Finding duplicates** is probably the most common use of `HAVING` in practice:

```sql
SELECT email, count(*)
FROM users
GROUP BY email
HAVING count(*) > 1;
```

**"Customers who did X _and_ Y"** using conditional aggregates with `FILTER`:

```sql
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING count(*) FILTER (WHERE status = 'paid') > 0
   AND count(*) FILTER (WHERE status = 'refunded') > 0;
```

**Groups where everything satisfies a rule**, using `bool_and`:

```sql
SELECT customer_id
FROM orders
GROUP BY customer_id
HAVING bool_and(status = 'paid');       -- every order was paid
```

**"Top groups"** is `HAVING` for a threshold, but `ORDER BY ... LIMIT` for a fixed count. If you want the top 3 spenders, `HAVING` isn't the right tool:

```sql
SELECT customer_id, sum(total) AS spent
FROM orders
GROUP BY customer_id
ORDER BY spent DESC
LIMIT 3;
```

## Performance notes

- **Filter early.** Every row you remove with `WHERE` is a row the grouping step never has to process. Move everything non-aggregate out of `HAVING`.
- **`HAVING` can't use an index to skip work**, because the aggregate has to be computed for each group before it's tested. The index helps indirectly, by making the `WHERE` fast or by feeding rows pre-sorted for a streaming group aggregate.
- If a `HAVING` query is slow, run `EXPLAIN ANALYZE` and look at the aggregate node's row counts: the `Rows Removed by Filter` line shows how many groups `HAVING` threw away. If almost every group gets thrown away, consider whether a `WHERE` condition, a pre-aggregated summary table, or a materialized view could narrow the input first.

## Common mistakes

- Using an aggregate in `WHERE` (it belongs in `HAVING`).
- Using a select alias in `HAVING` (repeat the expression or use a subquery).
- Putting plain row conditions in `HAVING` and paying for needless grouping.
- Forgetting that `NULL` aggregates make groups disappear.
- Using `HAVING` to get "top N" (use `ORDER BY ... LIMIT`).
- Join fan-out inflating `sum` or `count` before `HAVING` tests it. Aggregate in a subquery first, then join.

## Quick cheat sheet

```sql
GROUP BY g HAVING count(*) > 5                           -- groups by size
GROUP BY g HAVING sum(x) > 1000 AND avg(x) < 50          -- several aggregate conditions
WHERE row_filter GROUP BY g HAVING group_filter          -- use both, each at its own stage
HAVING count(*) FILTER (WHERE cond) > 0                  -- conditional check inside a group
HAVING bool_and(cond)                                    -- every row in the group passes
GROUP BY email HAVING count(*) > 1                       -- find duplicates
```

## Try it yourself

1. Find customers with at least 3 orders and an average order total above 100.
2. Find monthly revenue totals, but show only months above 10,000 (group by `date_trunc('month', created_at)`).
3. Find duplicate emails in a `users` table, then list the full rows for those emails using a subquery or join.
4. Find customers who have both a `paid` and a `refunded` order, using `FILTER`.
5. Rewrite one of these using a subquery plus `WHERE` instead of `HAVING`, and compare the `EXPLAIN` plans.



[[PostgreSQL]]