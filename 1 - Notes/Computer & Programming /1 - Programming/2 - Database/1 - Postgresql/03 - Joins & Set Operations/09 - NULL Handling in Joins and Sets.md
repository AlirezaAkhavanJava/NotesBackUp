

`NULL` doesn't mean zero, empty, or blank. It means **"unknown" or "no value."** That one idea explains why `NULL` behaves so strangely in SQL, and the strangest part is that it behaves _differently_ depending on where it shows up. In joins and `WHERE` clauses, two `NULL`s are **never equal**. In `UNION`, `DISTINCT`, and `GROUP BY`, two `NULL`s are treated as **the same value**. The mix of those two rules is the source of many silent bugs.

This lesson maps out where each rule applies and why, so you can predict what PostgreSQL will do before you run the query. We'll start with the logic underneath, then walk through joins, then sets, then collect everything into one scoreboard.

## The idea underneath: three-valued logic

Most languages have two truth values. SQL has three: **true, false, and unknown**. Any comparison involving `NULL` gives _unknown_:

```sql
SELECT NULL = NULL;     -- NULL (unknown), not true
SELECT NULL <> 5;       -- NULL
SELECT NULL = 5;        -- NULL
SELECT NULL IS NULL;    -- true  (the only correct way to test for NULL)
```

The question "is an unknown value equal to another unknown value?" honestly can't be answered, so PostgreSQL says "unknown." The key rule is that **`WHERE` and `ON` keep a row only when the condition is true.** Unknown is treated like false, and the row is silently dropped.

Unknown also propagates through logic in a predictable way:

|Expression|Result|
|---|---|
|`TRUE AND NULL`|NULL|
|`FALSE AND NULL`|FALSE|
|`TRUE OR NULL`|TRUE|
|`FALSE OR NULL`|NULL|
|`NOT NULL`|NULL|

This is why `WHERE x <> 5` quietly excludes rows where `x` is `NULL`. Those rows weren't "not 5", they were "unknown."

## Our test tables

Two tiny tables with a `NULL` in each:

```sql
CREATE TABLE a (k INT);
CREATE TABLE b (k INT);

INSERT INTO a VALUES (1), (2), (NULL);
INSERT INTO b VALUES (2), (3), (NULL);
```

Only `2` is a genuine match. The question is what happens to the `NULL`s.

## Part 1: NULLs in joins

### NULLs never match in an equality join

```sql
SELECT a.k AS a_k, b.k AS b_k
FROM a
JOIN b ON a.k = b.k;
```

Result: just `(2, 2)`. The `NULL` in `a` was compared with the `NULL` in `b`, got "unknown," and the pair was discarded. This is usually what you want. Two missing phone numbers shouldn't make two customers "the same person."

### Outer joins _create_ NULLs, which makes them ambiguous

```sql
SELECT a.k AS a_k, b.k AS b_k
FROM a
LEFT JOIN b ON a.k = b.k;
```

|a_k|b_k|
|---|---|
|1|NULL|
|2|2|
|NULL|NULL|

Look at `b_k`. The first `NULL` means "no match was found," and the last one is also "no match" (because `NULL` never matches), but in other data it could mean "a match was found, and the matched row really contains `NULL`." From the output alone you can't tell which. The fix is to check a column that can never be `NULL` in real data, usually the right table's primary key:

```sql
-- "Did the join find a partner?"
WHERE b.id IS NULL      -- reliable if id is a primary key
-- not: WHERE b.some_nullable_col IS NULL
```

### Making NULLs match on purpose: `IS NOT DISTINCT FROM`

Sometimes you really do want `NULL` to match `NULL`, for example when comparing two copies of a table to find differences. PostgreSQL has a null-safe equality operator for that:

```sql
SELECT a.k AS a_k, b.k AS b_k
FROM a
JOIN b ON a.k IS NOT DISTINCT FROM b.k;
```

Now you get `(2, 2)` and `(NULL, NULL)`. Its opposite is `IS DISTINCT FROM`, which treats `NULL` as an ordinary value: `NULL IS DISTINCT FROM 5` is true, and `NULL IS DISTINCT FROM NULL` is false.

**A performance warning:** `IS NOT DISTINCT FROM` generally can't use indexes and can't be turned into a hash or merge join, so PostgreSQL falls back to a slow nested loop. On large tables that hurts. Two common workarounds:

```sql
-- Option 1: normal join, plus the NULL-to-NULL pairs added separately
SELECT a.k, b.k FROM a JOIN b ON a.k = b.k
UNION ALL
SELECT a.k, b.k FROM a CROSS JOIN b WHERE a.k IS NULL AND b.k IS NULL;

-- Option 2: map NULL to a sentinel that can't occur in the real data
JOIN b ON COALESCE(a.k, -1) = COALESCE(b.k, -1)   -- only safe if -1 never occurs
```

Option 2 is fast only if you back it with a matching expression index, and the sentinel must be truly impossible in your data. Use it carefully.

### The WHERE-versus-ON trap, revisited through NULLs

A `LEFT JOIN` produces `NULL`s for unmatched rows, and a `WHERE` condition on those columns evaluates to unknown, so the rows vanish and your outer join quietly becomes an inner join:

```sql
-- Intended: all of a, with b's value if it's 2
SELECT a.k, b.k
FROM a LEFT JOIN b ON a.k = b.k
WHERE b.k = 2;           -- drops every unmatched row, so this is effectively an INNER JOIN
```

If the condition should only influence _matching_, put it in `ON`. If it should filter the final result, `WHERE` is right. Knowing which you mean prevents this bug.

### Counting across outer joins

Aggregates have their own `NULL` rule: **they ignore `NULL`s**, except `COUNT(*)`, which counts rows.

```sql
SELECT a.k,
       COUNT(*)   AS rows_returned,
       COUNT(b.k) AS matches_found
FROM a
LEFT JOIN b ON a.k = b.k
GROUP BY a.k
ORDER BY a.k;
```

For `a.k = 1` there's no match: `COUNT(*)` gives `1` (the row exists, padded with `NULL`s) but `COUNT(b.k)` gives `0`. When counting related rows after a `LEFT JOIN`, count a column from the right table, never `*`. Likewise `SUM` over no non-`NULL` values returns `NULL`, not `0`, so wrap it: `COALESCE(SUM(x), 0)`.

### The NOT IN landmine

This one deserves a repeat in the `NULL` context. Because `b` contains a `NULL`:

```sql
SELECT k FROM a WHERE k NOT IN (SELECT k FROM b);
```

returns **no rows at all**. For `k = 1`, the test expands to `1 <> 2 AND 1 <> 3 AND 1 <> NULL`, and that last part is unknown, which poisons the whole condition. `NOT EXISTS` doesn't have this problem:

```sql
SELECT k FROM a
WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.k = a.k);
-- returns 1 and NULL
```

Notice that `NULL` appears in this result. The `NULL` in `a` has no partner (since `NULL = NULL` is unknown, nothing matches it), so the anti-join keeps it. Hold that thought, because it contrasts nicely with what comes next.

## Part 2: NULLs in set operations and grouping

Now the rule flips. For operations that decide whether two rows are **duplicates**, PostgreSQL uses a different notion of equality, often called "not distinct": **two `NULL`s count as the same.** The logic is practical. If `DISTINCT` kept every `NULL` row separate, it would fail to remove duplicates in exactly the cases where you'd expect it to.

```sql
SELECT k FROM a
UNION
SELECT k FROM b;
-- 1, 2, 3, NULL   (the two NULLs collapse into one)

SELECT k FROM a
INTERSECT
SELECT k FROM b;
-- 2, NULL         (NULL is "in both")

SELECT k FROM a
EXCEPT
SELECT k FROM b;
-- 1               (the NULL in a is cancelled by the NULL in b)
```

Compare that last result with the `NOT EXISTS` query above. Both are "rows of `a` missing from `b`," yet `NOT EXISTS` returned `1` and `NULL`, while `EXCEPT` returned only `1`. Neither is wrong. They use different equality rules. Choosing between them means deciding whether a `NULL` should count as a match.

The same "NULLs are twins" rule applies to grouping:

```sql
SELECT k, COUNT(*) FROM (VALUES (1), (NULL), (NULL)) t(k) GROUP BY k;
-- 1 → 1,  NULL → 2    (both NULLs land in one group)

SELECT DISTINCT k FROM (VALUES (NULL::int), (NULL)) t(k);
-- one row
```

## The scoreboard: where NULL equals NULL and where it doesn't

|Context|Are two NULLs treated as equal?|
|---|---|
|`a = b` in `WHERE` or `ON`|**No** (unknown)|
|`IN (...)` and `NOT IN (...)`|**No** (and `NOT IN` can wipe out your result)|
|`EXISTS` with `=` inside|**No**|
|`a IS NOT DISTINCT FROM b`|**Yes**|
|`DISTINCT`|**Yes**|
|`GROUP BY`|**Yes**|
|`UNION`, `INTERSECT`, `EXCEPT` (and `ALL` versions)|**Yes**|
|`UNIQUE` constraint (default)|**No**, so many `NULL`s are allowed|
|`ORDER BY`|Sorted together; `NULL`s come **last** in `ASC`, **first** in `DESC`|

If you remember one pattern, remember this: **comparing** treats `NULL` as unknown, while **de-duplicating and grouping** treats `NULL` as one value.

## Two related corners: constraints

**UNIQUE and NULL.** By default a `UNIQUE` column allows any number of `NULL` rows, because they're "not equal." That surprises people who expected only one. PostgreSQL 15 added an option to change it:

```sql
CREATE TABLE users (
    email TEXT UNIQUE NULLS NOT DISTINCT   -- at most one NULL allowed
);
```

**Foreign keys and NULL.** A `NULL` in a foreign key column means "no reference," and PostgreSQL doesn't check it, so optional relationships work naturally. For _composite_ foreign keys, the default (`MATCH SIMPLE`) skips the check if **any** column in the key is `NULL`, which can let half-filled references slip through. If that matters, add `NOT NULL` to those columns.

## Your NULL toolbox

```sql
COALESCE(x, 0)          -- first non-NULL argument: replace NULL with a default
NULLIF(x, '')           -- returns NULL if x equals '' (turns "empty" into NULL)
x IS DISTINCT FROM y    -- null-safe "not equal"
x IS NOT DISTINCT FROM y -- null-safe "equal"
ORDER BY x NULLS LAST   -- control where NULLs sort
```

Two reminders about expressions: string concatenation with `||` gives `NULL` if any piece is `NULL` (use `concat()` or `COALESCE` when you want to skip missing parts), and arithmetic like `price * NULL` is `NULL`.

## Debugging checklist: when results look wrong

When a join or set query returns too few rows, too many, or the wrong ones, run through these questions:

1. **Could the key columns contain `NULL`?** Check with `SELECT COUNT(*) FROM t WHERE k IS NULL;`.
2. **Did a `NOT IN` meet a `NULL`?** Rewrite with `NOT EXISTS`.
3. **Did a `WHERE` condition on an outer-joined table cancel the outer join?** Move it to `ON`.
4. **Am I counting with `COUNT(*)` after a `LEFT JOIN`?** Count a right-side column.
5. **Do I want `NULL`s to match?** Then use `IS NOT DISTINCT FROM`, `EXCEPT`/`INTERSECT`, or a sentinel, and think about speed.
6. **Is my "no match" test using a nullable column?** Test the right table's primary key instead.

## Wrapping up

`NULL` isn't a value but a statement that a value is unknown, so comparisons with it are unknown too, and `WHERE`/`ON` throw those rows away. Joins, `IN`, and `EXISTS` therefore never match `NULL` to `NULL`, while `DISTINCT`, `GROUP BY`, and the set operators deliberately treat `NULL`s as identical. Keep that split in mind, prefer `NOT EXISTS` over `NOT IN`, and check key columns for `NULL`s whenever a result surprises you.




[[PostgreSQL]]