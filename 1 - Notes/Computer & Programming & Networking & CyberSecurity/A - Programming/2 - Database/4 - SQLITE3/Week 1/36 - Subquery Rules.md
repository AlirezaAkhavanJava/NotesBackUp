
## Subquery Rules

A **subquery** must follow certain structural rules depending on where and how it's used in the outer query. Getting these wrong is the most common source of runtime errors when you're starting out (CS50 students hit "sub-select returns N columns" constantly).

## Table of Subquery Rules

|Context / Operator|Rows Returned|Columns Returned|Notes|
|---|---|---|---|
|`=`, `!=`, `>`, `<`, `>=`, `<=`|**Exactly 1**|**Exactly 1**|Comparing to a single scalar — anything else errors out|
|`IN` / `NOT IN`|**0 or many**|**Exactly 1**|Treated as a list; column shape still restricted to 1|
|`EXISTS` / `NOT EXISTS`|**0 or many** (content ignored)|Doesn't matter|Only checks _whether_ rows exist, not their values — `SELECT 1` is conventional here|
|In `SELECT` clause (as a computed column)|**Exactly 1** (per outer row, if correlated)|**Exactly 1**|Runs once per outer row if it references the outer table (correlated subquery)|
|In `FROM` clause (as a derived table)|**0 or many**|**1 or many**|Acts like a temporary table — needs an alias, e.g. `(SELECT ...) AS temp`|
|`ANY` / `SOME`|**0 or many**|**Exactly 1**|True if the comparison holds for _at least one_ returned value|
|`ALL`|**0 or many**|**Exactly 1**|True only if the comparison holds for _every_ returned value|

## General structural rules (apply everywhere)

|Rule|Explanation|
|---|---|
|Must be wrapped in parentheses `( ... )`|`WHERE id = (SELECT ...)` — syntax requirement|
|Cannot use `ORDER BY` unless paired with `LIMIT`|Ordering alone is meaningless without limiting rows in most subquery contexts|
|Can reference the outer query's columns (correlated subquery)|Enables per-row logic, but re-executes once per outer row — can be slow|
|Cannot modify data structure of the outer query|A subquery filters or supplies values — it doesn't change what columns the outer `SELECT` returns unless it's in the `SELECT` list itself|
|Executes before (or alongside, if correlated) the outer query|The inner result is what the outer query actually operates on|
|Aliases are required when used in `FROM`|`SELECT * FROM (SELECT ...) AS t` — SQLite (and SQL generally) requires naming derived tables|

## Two-question quick check before writing any subquery

1. **What operator connects it to the outer query?** (`=` → needs exactly 1 row/col; `IN`/`EXISTS` → more flexible)
2. **Does the inner query need to "see" the outer query's current row?** If yes, it's a **correlated subquery** — and it'll run once per outer row, which can hurt performance on large tables.
---
## Broken Example 1: `=` with multiple rows returned

```sql
SELECT title FROM books
WHERE publisher_id = (
    SELECT id FROM publishers WHERE publisher LIKE '%Press%'
);
```

**Error:** `runtime error: more than one row returned by a subquery used as an expression`

**Why:** `LIKE '%Press%'` could match _multiple_ publishers (e.g., "Charco Press", "Persephone Press", "Melville House Press"). The inner query returns 3 rows, but `=` demands exactly 1.

**Fix:** Swap `=` for `IN`:

```sql
SELECT title FROM books
WHERE publisher_id IN (
    SELECT id FROM publishers WHERE publisher LIKE '%Press%'
);
```

---

## Broken Example 2: Selecting multiple columns in the inner query

```sql
SELECT title FROM books
WHERE publisher_id = (
    SELECT id, publisher FROM publishers WHERE publisher = 'Europa Editions'
);
```

**Error:** `sub-select returns 2 columns - expected 1`

**Why:** The inner query returns _two_ columns (`id` and `publisher`), but the outer `WHERE publisher_id = (...)` only knows how to compare against a single value.

**Fix:** Only select the one column you actually need:

```sql
SELECT title FROM books
WHERE publisher_id = (
    SELECT id FROM publishers WHERE publisher = 'Europa Editions'
);
```

---

## Broken Example 3: Assuming a name is always unique

```sql
SELECT title FROM books
WHERE author_id = (
    SELECT id FROM authors WHERE name = 'John Smith'
);
```

**Problem:** This _might_ run fine today... and then explode in production the moment there are two authors named "John Smith" — a very real possibility. This is a **silent landmine**, not a syntax error — it _will_ run, until the data changes underneath it.

**Fix:** Either use `IN` defensively, or add more filtering criteria to guarantee uniqueness (like birth year, or better — always query by `id` once you have it, not by name):

```sql
SELECT title FROM books
WHERE author_id IN (
    SELECT id FROM authors WHERE name = 'John Smith'
);
```

---

## Broken Example 4: Forgetting the subquery needs its own `FROM`

```sql
SELECT title FROM books
WHERE publisher_id = (
    SELECT id WHERE publisher = 'Europa Editions'
);
```

**Error:** SQLite3 will complain about a missing `FROM` clause, or misbehave depending on context — you simply left out `FROM publishers`.

**Fix:** Every subquery is a complete, self-contained `SELECT` — it needs its own `FROM`, just like any query:

```sql
SELECT title FROM books
WHERE publisher_id = (
    SELECT id FROM publishers WHERE publisher = 'Europa Editions'
);
```

---

## Quick test for you

What's wrong with this one? (Try to spot it before I explain)

```sql
SELECT name FROM people
WHERE id = (
    SELECT person_id FROM stars ORDER BY movie_id
);
```




[[1 - WHAT IS SQLITE3 🍕]]