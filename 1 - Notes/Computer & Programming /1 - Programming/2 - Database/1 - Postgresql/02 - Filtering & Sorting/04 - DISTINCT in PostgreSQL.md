


`DISTINCT` removes duplicate rows from a query's result. If your query would return the same row several times, adding `DISTINCT` makes each unique row appear only once. It's one of the first things people learn in SQL, and also one of the most overused, because it's tempting to sprinkle it on a query to hide duplicates without asking why they're there.

In this tutorial we'll cover how `DISTINCT` works, how it treats `NULL`s, the Postgres-only `DISTINCT ON` (which is far more powerful than it first looks), how it compares to `GROUP BY`, and when it's a sign of a deeper problem in your query.

---

## The problem it solves

Say we have a table of orders:

```sql
CREATE TABLE orders (
    id          serial PRIMARY KEY,
    customer_id int NOT NULL,
    status      text NOT NULL,
    country     text,
    created_at  timestamptz NOT NULL DEFAULT now()
);
```

You want to know which customers have ever placed an order. This returns one row per _order_, so a customer with 40 orders shows up 40 times:

```sql
SELECT customer_id FROM orders;
```

`DISTINCT` collapses those repeats:

```sql
SELECT DISTINCT customer_id FROM orders;
```

Now each customer appears once.

## How it works

`DISTINCT` compares the **entire row of selected columns**. Two rows count as duplicates only if _every_ selected column matches:

```sql
SELECT DISTINCT customer_id, status FROM orders;
```

This returns each unique `(customer_id, status)` pair. A customer with both paid and refunded orders appears twice, once per status. A common mistake is expecting `DISTINCT` to apply only to the first column. It never does: it always applies to the whole select list.

Behind the scenes, Postgres either sorts the rows so duplicates sit next to each other, or builds a hash table of rows it has already seen. Either way it has to look at all the rows first, so `DISTINCT` on a big result isn't free (more on that below).

## NULLs: treated as equal

Normally `NULL = NULL` is not true, but `DISTINCT` is an exception. For deduplication, all `NULL`s are considered the same value, so they collapse into one:

```sql
SELECT DISTINCT country FROM orders;
-- returns each country once, plus a single NULL row if any are missing
```

There's a related operator with a similar spirit, **`IS DISTINCT FROM`**, which is a null-safe comparison: `a IS DISTINCT FROM b` behaves like `a <> b` but treats two `NULL`s as equal. It's a different feature from `SELECT DISTINCT`, but it comes from the same idea, and it's handy in `WHERE` clauses when you're comparing nullable columns.

## Counting unique values

You can use `DISTINCT` inside an aggregate to count or combine only unique values:

```sql
SELECT count(*)                    AS orders,
       count(DISTINCT customer_id) AS customers,
       count(DISTINCT country)     AS countries
FROM orders;
```

Two details: `count(DISTINCT col)` ignores `NULL`s (unlike `SELECT DISTINCT`, which keeps one), and it can be noticeably slower on large tables because each distinct count needs its own sort or hash. It works with other aggregates too, like `sum(DISTINCT x)` and `string_agg(DISTINCT name, ', ')`, though the latter needs its `ORDER BY` to match the distinct expression.

## DISTINCT ON: the Postgres superpower

Plain `DISTINCT` can only say "keep one of each unique row." But a very common real question is **"give me the first row per group."** For example, each customer's most recent order, with all its details:

```sql
SELECT DISTINCT ON (customer_id)
       customer_id, id, status, created_at
FROM orders
ORDER BY customer_id, created_at DESC;
```

Here's how to read it:

- `DISTINCT ON (customer_id)` keeps exactly one row per `customer_id`.
- The `ORDER BY` decides **which** row survives: after sorting, the _first_ row in each customer's group wins. Here that's the newest order.
- The `ORDER BY` must start with the same expressions as the `DISTINCT ON` list. After that, the remaining columns define the "winner."

If you leave out the `ORDER BY`, Postgres still returns one row per customer, but _which_ row is arbitrary and can change between runs. So with `DISTINCT ON`, the `ORDER BY` isn't optional in practice.

This is hard to do with `GROUP BY`, because grouping can't hand you "the whole row with the latest date." The usual alternatives are a window function with `row_number()` (more portable, a bit wordier) or a lateral join. `DISTINCT ON` is the shortest, and with an index on `(customer_id, created_at DESC)` it can be very fast.

## DISTINCT vs GROUP BY

For plain deduplication they're equivalent, and the planner treats them nearly the same:

```sql
SELECT DISTINCT customer_id, status FROM orders;
SELECT customer_id, status FROM orders GROUP BY customer_id, status;
```

Choose by intent:

- Use **`DISTINCT`** when you just want unique rows.
- Use **`GROUP BY`** when you also need aggregates (`count`, `sum`, ...) per group.
- Use **`DISTINCT ON`** when you want one full row per group.

## ORDER BY rules with DISTINCT

With plain `SELECT DISTINCT`, any expression you sort by must appear in the select list. Otherwise Postgres can't know which of the collapsed rows' values to sort on:

```sql
SELECT DISTINCT customer_id FROM orders ORDER BY created_at;
-- ERROR: for SELECT DISTINCT, ORDER BY expressions must appear in select list
```

Either add the column to the select list (which changes what counts as distinct) or switch to `GROUP BY` with an aggregate such as `max(created_at)` to sort by.

## Related: UNION and friends

`UNION` combines two queries **and removes duplicates**, just like a `DISTINCT` on the combined result. `UNION ALL` keeps everything and is faster because it skips the dedupe step:

```sql
SELECT email FROM customers
UNION ALL
SELECT email FROM leads;      -- keeps duplicates, no extra work
```

Use `UNION ALL` unless you truly need duplicates removed. `INTERSECT` and `EXCEPT` also work on distinct rows by default.

## When DISTINCT is a warning sign

The most common misuse is hiding **join fan-out**. Say you join customers to their orders and get duplicate customers:

```sql
SELECT DISTINCT c.id, c.name
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'paid';
```

It works, but Postgres builds the full join and then deduplicates. If you only want to know _whether_ a match exists, `EXISTS` states that directly and avoids the duplicates in the first place:

```sql
SELECT c.id, c.name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id AND o.status = 'paid'
);
```

The planner usually turns this into an efficient semi-join. Worse than the speed issue is the correctness risk: if you add `DISTINCT` to make a wrong-looking `sum` or `count` look right, you may be deduplicating _legitimate_ identical rows (two real orders with the same total, for example) and silently getting wrong numbers. When duplicates surprise you, find out why they appear before reaching for `DISTINCT`.

## Performance notes

- `DISTINCT` must see all rows before it can finish, so it can't stream results the way a plain scan can, and an early `LIMIT` helps less.
- It's cheaper on fewer and narrower columns. Selecting `DISTINCT *` on wide rows means sorting or hashing a lot of data.
- If the data fits in `work_mem`, a hash-based dedupe is fast. If it doesn't, Postgres sorts using temporary disk files, which is slower.
- An index on the distinct columns can let Postgres read rows already in order and dedupe as it goes, avoiding a big sort.
- You can see the strategy in `EXPLAIN`: look for `HashAggregate`, or `Unique` on top of a `Sort`.

## Common mistakes

- Thinking `DISTINCT` applies to just the first column. It applies to the whole select list.
- Using `DISTINCT` to cover up a join that multiplies rows, instead of fixing the join (or using `EXISTS`).
- Using `DISTINCT ON` without a matching `ORDER BY`, which returns an arbitrary row per group.
- Using `UNION` when `UNION ALL` would do, paying for an unneeded dedupe.
- Sorting by a column that isn't in the select list of a `SELECT DISTINCT`.
- Expecting `count(DISTINCT col)` to count `NULL`s (it doesn't).

## Quick cheat sheet

```sql
SELECT DISTINCT a FROM t;                           -- unique values of a
SELECT DISTINCT a, b FROM t;                        -- unique (a, b) combinations
SELECT count(DISTINCT a) FROM t;                    -- number of unique non-null values
SELECT DISTINCT ON (g) g, x FROM t ORDER BY g, x DESC;   -- one row per g, chosen by ORDER BY
a IS DISTINCT FROM b                                -- null-safe "not equal"
UNION ALL                                           -- combine without deduplicating
WHERE EXISTS (SELECT 1 ...)                         -- "has a match", no duplicates
```

## Try it yourself

1. List every country that appears in `orders`, then check whether `NULL` shows up.
2. Count total orders, distinct customers, and distinct countries in one query.
3. Get each customer's most recent order with `DISTINCT ON`, then rewrite it with `row_number()` and compare.
4. Write the "customers with a paid order" query with a join plus `DISTINCT`, then with `EXISTS`, and compare their `EXPLAIN` plans.
5. Compare `UNION` and `UNION ALL` on two overlapping tables and note the row counts.




[[PostgreSQL]]