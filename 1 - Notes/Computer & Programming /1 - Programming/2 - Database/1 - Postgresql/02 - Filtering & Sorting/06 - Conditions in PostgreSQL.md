

Plain SQL queries return what is stored. Often you want to _decide_ something per row: label an order "small" or "large", show a fallback when a value is missing, or avoid dividing by zero. SQL has no `if` statement for this, but it has **conditional expressions**, which produce a value based on a condition, right inside your `SELECT`, `WHERE`, `ORDER BY`, `UPDATE`, and so on.

I'm taking "conditions" to mean these conditional expressions. (Conditions inside `WHERE` were covered in the last two topics, and I'll show how they connect at the end.) We'll use this table:

```sql
CREATE TABLE orders (
    id         serial PRIMARY KEY,
    customer   text NOT NULL,
    total      numeric(10,2),
    discount   numeric(10,2),
    status     text NOT NULL,
    shipped_at timestamptz
);
```

---

## CASE: the general-purpose "if / else"

`CASE` is an expression, so it returns a value, and it comes in two forms.

**Searched CASE** tests any conditions, top to bottom, and returns the result of the first one that is true:

```sql
SELECT id, total,
       CASE
           WHEN total >= 500 THEN 'large'
           WHEN total >= 100 THEN 'medium'
           ELSE 'small'
       END AS size
FROM orders;
```

**Simple CASE** compares one expression against several values:

```sql
SELECT id,
       CASE status
           WHEN 'paid'     THEN 'Done'
           WHEN 'refunded' THEN 'Returned'
           ELSE 'In progress'
       END AS label
FROM orders;
```

A few rules worth remembering:

- Branches are checked in order, and the first match wins, so put the most specific condition first.
- If nothing matches and there's no `ELSE`, the result is `NULL`. Add an `ELSE` unless `NULL` is what you want.
- All result branches must be a compatible type. You can't return a number from one branch and text from another without a cast.
- A `NULL` condition counts as not true, so it falls through to the next branch. In the simple form, `WHEN NULL` never matches (it uses `=`), so use `WHEN x IS NULL` in the searched form.

### CASE is also how you control evaluation order

SQL doesn't guarantee that `AND` conditions are checked left to right, so this can still raise a division-by-zero error:

```sql
WHERE quantity <> 0 AND total / quantity > 10      -- not safe
```

`CASE` does guarantee that only the chosen branch is evaluated (with a small caveat: constants may be simplified early by the planner):

```sql
WHERE CASE WHEN quantity <> 0 THEN total / quantity > 10 ELSE false END
```

## COALESCE: first non-NULL value

`COALESCE` takes any number of arguments and returns the first one that isn't `NULL`. It's the standard way to supply defaults:

```sql
SELECT id, COALESCE(discount, 0) AS discount
FROM orders;

SELECT COALESCE(nickname, first_name, 'guest') AS display_name FROM users;
```

It's most useful with arithmetic, because `NULL` poisons any calculation:

```sql
SELECT total - discount FROM orders;                 -- NULL if discount is NULL
SELECT total - COALESCE(discount, 0) FROM orders;    -- what you meant
```

Also handy around aggregates, since `sum` of no rows is `NULL`: `COALESCE(sum(total), 0)`. Arguments after the first non-null one are never evaluated, so `COALESCE` can safely hold an expensive or risky fallback.

## NULLIF: turn a value into NULL

`NULLIF(a, b)` returns `NULL` if `a = b`, otherwise `a`. It's the mirror image of `COALESCE`, and its classic use is dodging division by zero:

```sql
SELECT total / NULLIF(item_count, 0) AS avg_item_price FROM orders;
```

When `item_count` is 0, the divisor becomes `NULL`, so the result is `NULL` instead of an error. It also cleans messy data, such as treating empty strings as missing: `NULLIF(email, '')`. Combine them when you want a default after that: `COALESCE(total / NULLIF(item_count, 0), 0)`.

## GREATEST and LEAST

These pick the largest or smallest of several values _in one row_, unlike `max` and `min`, which work across rows:

```sql
SELECT GREATEST(total - COALESCE(discount, 0), 0) AS payable FROM orders;   -- never below zero
SELECT LEAST(total, 1000) AS capped_total FROM orders;
```

Unlike most expressions, they **ignore `NULL`s** and return `NULL` only if every argument is `NULL`.

## Conditions inside aggregates: FILTER

To count or sum only some rows per group, `FILTER` is cleaner than `CASE`:

```sql
SELECT customer,
       count(*) FILTER (WHERE status = 'paid')     AS paid,
       sum(total) FILTER (WHERE status = 'paid')   AS paid_total
FROM orders
GROUP BY customer;
```

The `CASE` equivalent is `sum(CASE WHEN status = 'paid' THEN total END)`. It works everywhere, but `FILTER` is shorter and clearer.

## Conditions in UPDATE and ORDER BY

`CASE` works anywhere an expression is allowed. In an `UPDATE`, it lets one statement apply different changes by condition:

```sql
UPDATE orders
SET status = CASE
                 WHEN shipped_at IS NOT NULL THEN 'shipped'
                 WHEN total IS NULL          THEN 'invalid'
                 ELSE status
             END;
```

Note the `ELSE status`: without it, unmatched rows would be set to `NULL`. In `ORDER BY`, `CASE` gives you a custom sort order:

```sql
ORDER BY CASE status WHEN 'pending' THEN 1 WHEN 'paid' THEN 2 ELSE 3 END;
```

## Boolean conditions as values

A comparison is itself an expression that returns a boolean, so you can select it directly, and `IS` tests help when `NULL` is involved:

```sql
SELECT id, (total > 100) AS is_big,
          (shipped_at IS NULL) AS not_shipped
FROM orders;
```

`total > 100` is `NULL` (not `false`) when `total` is `NULL`. If you need a strict true/false, use `COALESCE(total > 100, false)` or `(total > 100) IS TRUE`.

## IF inside PL/pgSQL

Inside functions and `DO` blocks you also get procedural control flow, which is separate from the `CASE` expression:

```sql
DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM orders WHERE status = 'pending';
    IF n > 100 THEN
        RAISE NOTICE 'Backlog is large: %', n;
    ELSIF n > 0 THEN
        RAISE NOTICE 'Some pending: %', n;
    ELSE
        RAISE NOTICE 'All clear';
    END IF;
END $$;
```

Outside of procedural code (plain SQL), there is no `IF()` function in Postgres. Use `CASE`.

## How this connects to WHERE

`WHERE` takes a boolean condition, so everything above composes with it: `WHERE COALESCE(discount, 0) > 10`, or `WHERE CASE ... END = 'large'`. One performance caution: wrapping a column in `COALESCE` or `CASE` means a plain index on that column can't be used. Either create a matching expression index (`CREATE INDEX ON orders ((COALESCE(discount, 0)))`) or rewrite the condition, for example `discount > 10`, which already excludes `NULL`s anyway.

## Common mistakes

- Forgetting `ELSE`, so unmatched rows silently become `NULL`.
- Mixing result types across `CASE` branches.
- Using `WHEN NULL` in simple `CASE` (use `WHEN x IS NULL` in the searched form).
- Writing `COALESCE(x, 0)` everywhere without asking whether `NULL` really means zero. Sometimes `NULL` means "unknown," and hiding it distorts averages.
- Relying on `AND` short-circuiting to avoid errors. Use `CASE` or `NULLIF`.
- Putting `CASE` or `COALESCE` on an indexed column in `WHERE` and wondering why the index isn't used.
- Forgetting `ELSE status` in an `UPDATE ... SET col = CASE ...`.

## Quick cheat sheet

```sql
CASE WHEN cond THEN a WHEN cond2 THEN b ELSE c END   -- general branching
CASE col WHEN 'x' THEN a ELSE b END                  -- compare one value
COALESCE(a, b, 0)                                    -- first non-NULL
NULLIF(a, 0)                                         -- NULL if a = 0 (avoids divide-by-zero)
GREATEST(a, b, c)   LEAST(a, b, c)                   -- per-row max / min (ignore NULLs)
count(*) FILTER (WHERE cond)                         -- conditional aggregate
IF ... THEN ... ELSIF ... END IF;                    -- PL/pgSQL only
```




[[PostgreSQL]]