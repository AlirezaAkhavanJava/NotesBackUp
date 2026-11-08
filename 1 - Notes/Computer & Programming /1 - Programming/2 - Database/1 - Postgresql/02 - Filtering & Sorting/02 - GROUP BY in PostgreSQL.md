


Plain queries return individual rows. But much of the time you want answers about _groups_ of rows: orders per customer, revenue per month, the average salary per department. `GROUP BY` collapses rows that share the same value(s) into one output row per group, and aggregate functions like `count`, `sum`, and `avg` summarize what's inside each group.

This tutorial builds the idea from the ground up, then covers the rules that trigger the classic error messages, the `WHERE` vs `HAVING` split, and some Postgres extras like `FILTER` and `ROLLUP`.

---

## The idea in one example

We'll use this table:

```sql
CREATE TABLE orders (
    id          serial PRIMARY KEY,
    customer_id int NOT NULL,
    status      text NOT NULL,          -- 'paid', 'refunded', 'pending'
    total       numeric(10,2) NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);
```

Without grouping, an aggregate squashes the whole table into one row:

```sql
SELECT count(*), sum(total) FROM orders;      -- one row for everything
```

With `GROUP BY`, you get one row per distinct value:

```sql
SELECT customer_id, count(*) AS orders, sum(total) AS spent
FROM orders
GROUP BY customer_id;
```

Think of it as three steps: Postgres sorts the rows into buckets by `customer_id`, runs the aggregates inside each bucket, and emits one row per bucket.

## The rule behind the famous error

Every column in your `SELECT` list must be either **in the `GROUP BY`** or **inside an aggregate**. Otherwise Postgres has no idea which of the bucket's many values to show:

```sql
SELECT customer_id, status, count(*)
FROM orders
GROUP BY customer_id;
-- ERROR: column "orders.status" must appear in the GROUP BY clause
--        or be used in an aggregate function
```

Fix it by adding `status` to the `GROUP BY` (you get one row per customer _and_ status), or by aggregating it (`max(status)`, `array_agg(status)`).

One Postgres nicety: if you group by a table's primary key, you can select that table's other columns freely, since the key already determines them:

```sql
SELECT c.id, c.name, count(o.id)
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id;          -- c.name is allowed because c.id is the primary key
```

## Grouping by several columns or expressions

Rows land in the same group only if _all_ the grouped values match:

```sql
SELECT customer_id, status, count(*)
FROM orders
GROUP BY customer_id, status;
```

You can group by expressions, which is how you build time reports:

```sql
SELECT date_trunc('month', created_at) AS month,
       sum(total) AS revenue
FROM orders
GROUP BY date_trunc('month', created_at)
ORDER BY month;
```

You can also write `GROUP BY 1` (the first select column) or reuse an alias like `GROUP BY month`. Postgres allows both, but they're less portable, and position-based grouping gets fragile as queries change.

## The aggregates you'll use most

|Function|What it does|
|---|---|
|`count(*)`|Rows in the group|
|`count(col)`|Rows where `col` is not `NULL`|
|`count(DISTINCT col)`|Number of distinct non-null values|
|`sum`, `avg`, `min`, `max`|The usual math|
|`string_agg(col, ', ')`|Join values into one string|
|`array_agg(col)`|Collect values into an array|
|`bool_or`, `bool_and`|Is any / are all values true?|

Two details trip people up. First, **aggregates ignore `NULL`s** (except `count(*)`), so `avg(col)` averages only the non-null values. Second, `sum` over zero rows returns `NULL`, not 0, so use `coalesce(sum(x), 0)` when you want a zero.

## NULLs form their own group

For grouping purposes, all `NULL`s are treated as equal, so they end up together in one group. Rows with no `customer_id` would show up as a single row with a `NULL` key. That's usually what you want, but it can look odd in reports, so label it if needed: `coalesce(region, 'unknown')`.

## WHERE vs HAVING

Both filter, but at different moments:

- **`WHERE`** removes individual rows _before_ grouping.
- **`HAVING`** removes whole groups _after_ aggregation, so it can use aggregate results.

```sql
SELECT customer_id, count(*) AS orders, sum(total) AS spent
FROM orders
WHERE status = 'paid'              -- only paid orders are counted at all
GROUP BY customer_id
HAVING sum(total) > 1000           -- only big spenders remain
ORDER BY spent DESC;
```

You can't put an aggregate in `WHERE` (`WHERE count(*) > 5` errors out), because groups don't exist yet at that stage. And don't put row-level conditions in `HAVING`: it works, but it makes Postgres do the grouping work for rows you were going to throw away anyway.

## FILTER: several conditional counts in one pass

Say you want, per customer, the number of paid and refunded orders side by side. Instead of repeating the query or using `CASE`, attach `FILTER` to each aggregate:

```sql
SELECT customer_id,
       count(*)                                   AS all_orders,
       count(*) FILTER (WHERE status = 'paid')    AS paid,
       count(*) FILTER (WHERE status = 'refunded') AS refunded,
       sum(total) FILTER (WHERE status = 'paid')  AS paid_revenue
FROM orders
GROUP BY customer_id;
```

It reads cleanly and scans the table only once. This is the standard way to "pivot" a few known categories into columns.

## Subtotals and grand totals: ROLLUP, CUBE, GROUPING SETS

Sometimes a report needs several levels of grouping at once. `ROLLUP` adds subtotals going up a hierarchy, plus a grand total:

```sql
SELECT status, customer_id, sum(total)
FROM orders
GROUP BY ROLLUP (status, customer_id);
```

You get rows per `(status, customer)`, a subtotal per `status` (where `customer_id` is `NULL`), and a final grand-total row (both `NULL`). Because real `NULL`s can look the same as these "subtotal" nulls, use `GROUPING(col)`, which returns 1 when the column was rolled up, to tell them apart. `CUBE` produces subtotals for _every_ combination, and `GROUPING SETS` lets you list exactly the groupings you want.

## GROUP BY vs DISTINCT vs window functions

- `SELECT DISTINCT a, b` is essentially `GROUP BY a, b` with no aggregates.
- **Window functions** compute an aggregate _without collapsing rows_, which is what you want when you need each order alongside its customer's total:

```sql
SELECT id, customer_id, total,
       sum(total) OVER (PARTITION BY customer_id) AS customer_total
FROM orders;
```

Rule of thumb: if the output should have fewer rows than the input, use `GROUP BY`. If it should keep every row, use a window function.

## How Postgres does it (and why speed varies)

`EXPLAIN` shows one of two strategies:

- **HashAggregate:** builds an in-memory hash table keyed by the group values. It's usually fastest when the number of groups fits in `work_mem`. If it doesn't, Postgres spills to disk (PG 13+).
- **GroupAggregate:** reads rows already sorted by the group key and finishes each group as it goes. It's used when the data comes pre-sorted, for example from an index on the grouping column, and it needs very little memory.

Practical tips: an index on the grouping column can enable a streaming `GroupAggregate`, filter early with `WHERE` so fewer rows reach the grouping step, and keep statistics fresh with `ANALYZE` so the planner estimates group counts sensibly. Grouping by a huge number of distinct values, or by wide columns, costs more memory.

## Common mistakes

- Selecting a column that's neither grouped nor aggregated.
- Putting aggregate conditions in `WHERE`, or plain row conditions in `HAVING`.
- Using `count(col)` when you meant `count(*)`, so `NULL`s quietly go uncounted.
- **Join fan-out:** joining `orders` to `order_items` _before_ summing `orders.total` repeats each order once per item and inflates the sum. Aggregate in a subquery first, then join.
- Forgetting `ORDER BY`: grouped results come back in no guaranteed order.
- Expecting `sum` of nothing to be 0.

## Quick cheat sheet

```sql
SELECT g, count(*), sum(x) FROM t GROUP BY g;                 -- basic
GROUP BY a, b                                                 -- multiple keys
GROUP BY date_trunc('month', ts)                              -- by expression
WHERE ... GROUP BY g HAVING count(*) > 5                      -- row filter, then group filter
count(*) FILTER (WHERE cond)                                  -- conditional aggregate
GROUP BY ROLLUP (a, b)                                        -- subtotals + grand total
string_agg(name, ', ' ORDER BY name)                          -- ordered list per group
sum(x) OVER (PARTITION BY g)                                  -- aggregate without collapsing
```





[[PostgreSQL]]