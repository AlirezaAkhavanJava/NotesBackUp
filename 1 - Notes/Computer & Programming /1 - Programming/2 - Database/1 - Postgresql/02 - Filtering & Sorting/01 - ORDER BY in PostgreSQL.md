


`ORDER BY` decides the order in which a query returns its rows. That matters more than it sounds, because a SQL table has no built-in order. Without `ORDER BY`, the order you see is just whatever Postgres happened to read first, and it can change after an update, a vacuum, or a different query plan.

This is a condensed, more focused version of the earlier one. We'll cover the basics, the gotchas that cause real bugs (`NULL`s, ties, text sorting), and how sorting connects to pagination and indexes.

---

## The basics

```sql
SELECT id, title, created_at
FROM tickets
ORDER BY created_at DESC;      -- newest first; ASC (oldest first) is the default
```

Sort by several columns and later ones break ties in earlier ones:

```sql
ORDER BY priority DESC, due_date ASC;
```

Each column gets its own direction. `ORDER BY` goes after `WHERE`/`GROUP BY` and before `LIMIT`.

**The key rule:** if order matters, always write `ORDER BY`. `LIMIT` without it returns "some N rows," and not necessarily the same ones next time.

## NULLs

Postgres treats `NULL` as larger than any value. So ascending puts `NULL`s last, and **descending puts them first**. That surprises people when "latest due date first" fills the top of the list with tickets that have no due date. Be explicit:

```sql
ORDER BY due_date DESC NULLS LAST;
```

## Text sorting and collation

How text sorts ("alphabetical") depends on the column's **collation**. Under `en_US.UTF-8`, `apple` and `Apple` sit next to each other. Under `C`, every uppercase letter sorts before every lowercase one. You can pick one per query:

```sql
ORDER BY name COLLATE "C";
```

Linguistic collations are slower than `C`, and an index only helps if its collation matches the one you sort with.

## Custom orders

Alphabetically, `high` comes before `low` and `medium`, which is useless for priorities. Two clean fixes:

```sql
ORDER BY CASE priority WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END;
```

Or declare an `ENUM` type (`CREATE TYPE priority_level AS ENUM ('low','medium','high')`), whose values sort in the order you declared them.

Expressions work too: `ORDER BY lower(title)` or `ORDER BY (assignee IS NULL), assignee` to push unassigned rows to the bottom.

## Aliases and positions

`ORDER BY` runs after `SELECT`, so it can use output aliases, but only as a bare name:

```sql
SELECT due_date - current_date AS days_left FROM tickets ORDER BY days_left;   -- OK
-- ORDER BY days_left + 1   -> error, aliases don't work inside expressions
```

`ORDER BY 2` (by position) works but breaks silently when the select list changes, so avoid it in real code.

## Ties and why they cause bugs

If many rows share the same sort value, their relative order is **not guaranteed** and can differ between runs. That's harmless for display but breaks pagination: a row can show up on two pages or on none. The fix is to finish every `ORDER BY` with a unique column:

```sql
ORDER BY created_at DESC, id DESC;
```

## Pagination

`LIMIT ... OFFSET ...` works, but Postgres must produce and throw away all the skipped rows, so deep pages get slow, and rows inserted mid-browsing cause duplicates or gaps. **Keyset pagination** avoids both by remembering the last row seen:

```sql
SELECT id, title, created_at
FROM tickets
WHERE (created_at, id) < ('2026-03-01 10:00+00', 812)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

With an index on `(created_at, id)`, every page costs about the same no matter how deep you go.

## Handy Postgres features

**`DISTINCT ON`** gives you the first row per group, where "first" comes from your `ORDER BY`:

```sql
SELECT DISTINCT ON (assignee) assignee, id, title, due_date
FROM tickets
ORDER BY assignee, due_date NULLS LAST;
```

The `ORDER BY` must start with the `DISTINCT ON` columns.

**Ordering inside functions** is separate from the final sort:

```sql
string_agg(title, ', ' ORDER BY due_date)            -- ordered aggregate
row_number() OVER (PARTITION BY assignee ORDER BY due_date)   -- window function
```

A window's `ORDER BY` does not sort the final result, so add an outer `ORDER BY` if you need that too.

**`FETCH FIRST 3 ROWS WITH TIES`** returns the top 3 plus any rows tied with the third.

## Performance: sorting is expensive

Sorting costs `O(n log n)`. In `EXPLAIN ANALYZE` you'll see one of three methods:

- **quicksort (memory):** fast.
- **top-N heapsort:** used with `LIMIT`; only the best N rows are kept, so it's cheap.
- **external merge (disk):** the data didn't fit in `work_mem` (default 4 MB) and spilled to disk, which is slow.

If an important query spills, raise `work_mem` for that session only, since it's allocated per sort and can add up across many connections.

**The best sort is no sort.** A B-tree index is already ordered, so a matching index lets Postgres skip the sort and stop early:

```sql
CREATE INDEX ON tickets (created_at DESC, id DESC);
```

For multi-column indexes, the column order, directions, and `NULLS` placement must line up with your `ORDER BY` (it can be read forwards or fully backwards). For `WHERE assignee = 'ana' ORDER BY created_at DESC`, use `(assignee, created_at DESC)`.

## Common mistakes

- Relying on implicit order, or `LIMIT` without `ORDER BY`.
- Forgetting `NULLS LAST` with `DESC`.
- Non-unique sort keys combined with pagination.
- Deep `OFFSET` on big tables.
- Assuming `ORDER BY` inside a subquery or view carries to the outer result. Put it on the outermost query.
- `ORDER BY random() LIMIT n` on large tables. It sorts everything; `TABLESAMPLE` is much cheaper for sampling.

## Quick cheat sheet

```sql
ORDER BY col DESC NULLS LAST                 -- control direction and NULLs
ORDER BY a, b DESC                           -- multi-column
ORDER BY created_at DESC, id DESC            -- deterministic (unique tie-breaker)
ORDER BY name COLLATE "C"                    -- choose text rules
SELECT DISTINCT ON (g) ... ORDER BY g, x     -- first row per group
WHERE (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC LIMIT 20   -- keyset paging
```

## Try it yourself

1. Sort tickets by priority (high to low) using a `CASE`, then by due date with undated tickets last.
2. Use `DISTINCT ON` to get each assignee's most urgent ticket.
3. Generate 500,000 rows with `generate_series` and compare `EXPLAIN ANALYZE` for `ORDER BY created_at LIMIT 10` with and without an index.




[[PostgreSQL]]