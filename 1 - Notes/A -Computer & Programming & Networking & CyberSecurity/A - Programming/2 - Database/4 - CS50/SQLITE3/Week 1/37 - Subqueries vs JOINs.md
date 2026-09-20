

Both let you pull information across related tables, but they solve the problem in fundamentally different ways.

**Subquery** — one `SELECT` nested inside another. The inner query runs, produces a value (or list of values), and the outer query uses that as a filter or computed column. The two tables never actually "merge" — the inner one just hands over a result.

**JOIN** — combines rows from two (or more) tables _side by side_ into one unified result set, based on a matching condition (usually a foreign key = primary key match). Both tables' columns become available together, in the same row.

```sql
-- Subquery: books' columns only; publishers is just consulted, not displayed
SELECT title FROM books
WHERE publisher_id = (SELECT id FROM publishers WHERE publisher = 'Europa Editions');

-- JOIN: columns from BOTH tables appear together in the result
SELECT books.title, publishers.publisher
FROM books
JOIN publishers ON books.publisher_id = publishers.id
WHERE publishers.publisher = 'Europa Editions';
```

## Table of Differences

|Aspect|Subquery|JOIN|
|---|---|---|
|Output columns|Only from the outer table (inner table's columns aren't displayed)|Columns from **all** joined tables, combined into one row|
|Best for|Filtering, existence checks, single computed values|Displaying combined data from multiple tables|
|Performance|Can be slow — especially correlated subqueries (re-run per outer row)|Generally faster — SQLite3's query planner optimizes joins well|
|Readability|Often reads more like natural language ("where id = the id of...")|Reads more like "combine these tables where X matches Y"|
|Row count concerns|Must respect operator rules (`=` needs 1 row, `IN` allows many)|No such restriction — naturally handles many-to-many relationships|
|Handles many-to-many well?|Awkward — needs nested/chained subqueries|Natural fit — this is exactly what join tables (`stars`, etc.) are designed for|
|Can return multiple result rows contributing new combined data?|No — collapses to filter logic only|Yes — genuinely expands the result set with matched pairs|

## Which is the better choice?

**Use a JOIN when:**

- You need to **see/display** data from more than one table together
- You're working with a **many-to-many** relationship (via a join table like `stars`)
- Performance matters on large tables
- This is the majority of real-world queries

**Use a subquery when:**

- You need just **one value** to filter or compute with (a max, a count, a lookup id) — and don't need to display anything from that other table
- You're doing an **existence check** (`EXISTS`) — you only care _whether_ a related row exists, not its contents
- The logic genuinely reads clearer nested (subjective, but sometimes true for simple single-value lookups)

## The honest bottom line

> **JOINs are the better default choice for most real tasks** — especially anything involving relational schemas like the CS50 `movies` database, where you're constantly pulling combined data across `movies`, `people`, `stars`, `ratings`. Subqueries are the _right_ tool only in the narrower cases above (filters, existence checks, single scalar values) — not a general substitute for JOINs.

If you find yourself reaching for a subquery and then wishing you could also grab one more column from the inner table — that's your signal you actually wanted a JOIN all along.


[[1 - WHAT IS SQLITE3]]