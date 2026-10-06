

An index is a **separate, sorted lookup structure** that lets SQLite find rows without reading the whole table.

## The book analogy

Imagine a 500-page book and you want every page that mentions "Paris."

- **Without an index:** you read all 500 pages from start to finish. (Full table scan)
- **With an index:** you flip to the back of the book, find "Paris → pages 12, 87, 301," and jump straight there. (Index lookup)

The index at the back of the book is exactly what a database index is.

## How it works in SQLite

SQLite stores an index as a **B-tree**, a sorted tree structure. Instead of checking rows one by one, it narrows down the answer by halving the search space at each step.

|Rows|Full scan checks|Index lookup checks (approx.)|
|---|---|---|
|1,000|1,000|~10|
|1,000,000|1,000,000|~20|
|1,000,000,000|1,000,000,000|~30|

That's why index speed barely changes as data grows.

## Example

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  email TEXT,
  city TEXT
);

-- Slow on big tables: scans every row
SELECT * FROM users WHERE email = 'ali@example.com';

-- Create an index on the email column
CREATE INDEX idx_users_email ON users(email);

-- Now the same query uses the index
```

The index stores each `email` value in sorted order, along with a pointer to the matching row.

## Good to know

- **`PRIMARY KEY` is already indexed.** For `INTEGER PRIMARY KEY`, lookups by `id` are the fastest possible in SQLite.
- **`UNIQUE` columns get an index automatically.**
- **Indexes help with:** `WHERE`, `JOIN`, `ORDER BY`, and `GROUP BY` on the indexed column.

## The cost: indexes are not free

|Benefit|Cost|
|---|---|
|Much faster reads|Slower `INSERT`, `UPDATE`, `DELETE` (the index must be updated too)|
||Extra disk space|

So don't index every column. Index the columns you **frequently search, join, or sort by**.

## When an index won't help

- Very small tables (scanning is already instant)
- Columns with few distinct values, like `is_active` (0 or 1)
- Queries like `WHERE email LIKE '%gmail.com'` (a leading wildcard prevents index use)
- Wrapping the column in a function: `WHERE LOWER(email) = '...'`

## Quick summary

> An index trades a little write speed and disk space for much faster reads. It's a sorted shortcut so SQLite doesn't have to look at every row.





[[SQlite]]