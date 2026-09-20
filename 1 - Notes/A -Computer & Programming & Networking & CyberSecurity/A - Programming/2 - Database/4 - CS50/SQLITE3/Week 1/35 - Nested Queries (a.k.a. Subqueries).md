


A **nested query** is a `SELECT` statement placed inside another `SELECT` statement, where the inner one executes first and its result feeds into the outer one. "Nested" just emphasizes the structure — one query sitting inside another, like nested parentheses.

```sql
SELECT title FROM books
WHERE publisher_id = (
    SELECT id FROM publishers WHERE publisher = 'Europa Editions'
);
```

## Which table goes where 

### Outer query (the "top") → the table you actually want information FROM

This is the table whose **columns you want returned** in your final result. It's the answer to "what am I trying to see?"

In the example: you want **titles of books** → so `books` is the outer query's table.

```sql
SELECT title FROM books   -- ← books is OUTER: I want info FROM here
WHERE publisher_id = (...)
```

### Inner query (nested inside) → the table you use ONLY as a filter/lookup

This table's job is **not** to contribute columns to your final output. It exists purely to resolve a value that the outer query needs to filter by. You don't see its columns in your result at all.

In the example: you don't want to _see_ publisher data — you just need to **look up an id** to plug into the filter. So `publishers` is the inner query.

```sql
    SELECT id FROM publishers WHERE publisher = 'Europa Editions'
    -- ↑ publishers is INNER: only used to fetch a filter value, not displayed
```

## The rule, stated plainly

> **Outer table** = the table that appears after your `SELECT` column list and main `FROM` — this is where your _displayed_ data comes from.  
> **Inner table** = the table inside the parentheses — its only job is to hand back a value (an id, a max, a count) that the outer query uses in its `WHERE` clause. Its own columns never appear in the final result.

## A second example to lock this in

_"Find all people born the same year as the highest-rated movie's release year"_ (hypothetical, just to illustrate structure):

```sql
SELECT name FROM people          -- OUTER: I want names, FROM people
WHERE birth = (
    SELECT year FROM movies      -- INNER: just fetching one year to filter by
    ORDER BY ... LIMIT 1
);
```

- `people` = outer → because `name` (what I want to see) lives there
- `movies` = inner → because I never asked to see any movie data, I only needed one number (`year`) from it to filter `people`

## Quick test for yourself

Ask: **"Which table's columns actually show up in my final answer?"**

- That table → goes **outside** (top-level `SELECT ... FROM`)
- Any table that only supplies a value used inside `WHERE (...)`, never shown → goes **inside**, nested




[[1 - WHAT IS SQLITE3]]