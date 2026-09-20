

SQLite3 lets you perform calculations directly inside SQL — on columns within the same row, across aggregated groups, or even between separate rows. Let's build this up from simple to more advanced.

## 1. Basic Arithmetic Operators (same row, different columns)

|Operator|Meaning|Example|
|---|---|---|
|`+`|Addition|`price + tax`|
|`-`|Subtraction|`total - discount`|
|`*`|Multiplication|`price * quantity`|
|`/`|Division|`votes / 1000.0`|
|`%`|Modulo (remainder)|`id % 2`|

```sql
SELECT title, rating, votes,
       votes / 1000.0 AS votes_in_thousands
FROM ratings
JOIN movies ON movies.id = ratings.movie_id;
```

⚠️ **Integer division trap:** in SQLite3, `INTEGER / INTEGER` truncates to an integer.

```sql
SELECT 5 / 2;      -- returns 2, not 2.5!
SELECT 5.0 / 2;    -- returns 2.5 — force one side to a float
SELECT 5 / 2.0;    -- also returns 2.5
```

**Rule of thumb:** if you want a decimal result, make sure at least one operand has a decimal point or is explicitly cast.

## 2. Dividing values from DIFFERENT rows

This is where it gets more interesting — you can't just write `column / column` if the two values live in _separate rows_. You need to either JOIN the rows together first, or use a self-join, so both values sit side-by-side in one row before dividing.

**Example: "What percentage of total votes did each movie get?"**

```sql
SELECT title,
       votes,
       ROUND(votes * 100.0 / (SELECT SUM(votes) FROM ratings), 2) AS pct_of_total
FROM ratings
JOIN movies ON movies.id = ratings.movie_id;
```

Here, `(SELECT SUM(votes) FROM ratings)` is a subquery producing one scalar value — the total — which every row then divides into. This is the classic case of "getting a single value from all rows to use in a per-row calculation."

**Example: comparing two specific rows via self-join** (e.g., "how many more votes did movie A get than movie B?")

```sql
SELECT r1.votes - r2.votes AS vote_difference
FROM ratings r1
JOIN ratings r2 ON r1.movie_id = 1 AND r2.movie_id = 2;
```

A **self-join** (joining a table to itself, using aliases) is the standard way to bring two separate rows of the same table into one row for comparison.

## 3. `CAST` — force a type conversion

```sql
SELECT CAST(votes AS REAL) / 1000 AS votes_thousands FROM ratings;
```

Useful to guarantee float division, or to convert text-stored numbers into actual numbers for math.

## 4. `ROUND()` — control decimal precision

```sql
SELECT ROUND(rating, 1) FROM ratings;   -- 8.734 → 8.7
```

## 5. Aggregate functions — math across MANY rows at once

|Function|What it does|
|---|---|
|`SUM(col)`|Total of a column|
|`AVG(col)`|Average|
|`MIN(col)` / `MAX(col)`|Smallest / largest value|
|`COUNT(col)` / `COUNT(*)`|Number of rows|
|`TOTAL(col)`|Like SUM but always returns a float, never NULL|

```sql
SELECT AVG(rating), MAX(votes), COUNT(*) FROM ratings;
```

Combine with `GROUP BY` to aggregate per category:

```sql
SELECT publisher_id, AVG(price) AS avg_price
FROM books
GROUP BY publisher_id;
```

## 6. `COALESCE()` — handle NULLs before doing math

Math involving `NULL` always returns `NULL` — this silently breaks calculations if you're not careful.

```sql
SELECT COALESCE(rating, 0) * 10 FROM ratings;
-- if rating is NULL, use 0 instead, so the multiplication doesn't just return NULL
```

## 7. `CASE` — conditional logic inline (like an inline if/else)

```sql
SELECT title,
       CASE
           WHEN rating >= 8 THEN 'Excellent'
           WHEN rating >= 6 THEN 'Good'
           ELSE 'Average'
       END AS category
FROM movies
JOIN ratings ON ratings.movie_id = movies.id;
```

## 8. String operations (small but very useful)

|Function|Use|
|---|---|
|`LENGTH(str)`|Character count|
|`UPPER(str)` / `LOWER(str)`|Case conversion|
|`str1 \| str2`|Concatenation|
|`SUBSTR(str, start, len)`|Substring extraction|
|`TRIM(str)`|Remove whitespace|
|`REPLACE(str, old, new)`|Replace substring|

```sql
SELECT name || ' (' || birth || ')' AS full_info FROM people;
-- "Tom Hanks (1956)"
```

## 9. Date/time functions

|Function|Use|
|---|---|
|`DATE('now')`|Current date|
|`strftime('%Y', date_col)`|Extract year from a date|
|`julianday(date)`|Convert to Julian day number (good for date math)|

```sql
SELECT julianday('2024-01-01') - julianday('2020-01-01') AS days_between;
```

## Quick reference cheat sheet

```sql
-- Math within a row
SELECT price * quantity AS total FROM orders;

-- Math against a whole-table aggregate (subquery)
SELECT price, price / (SELECT MAX(price) FROM orders) AS pct_of_max FROM orders;

-- Math between two specific rows (self-join)
SELECT a.value - b.value FROM t a JOIN t b ON a.id = 1 AND b.id = 2;

-- Safe division avoiding integer truncation
SELECT numerator * 1.0 / denominator;

-- Handle NULLs before math
SELECT COALESCE(col, 0) + 5;

-- Round for display
SELECT ROUND(avg_val, 2);
```

## The core principle to remember

> **Same-row math** = plain arithmetic operators, no JOIN needed.  
> **Math against a single aggregate value from many rows** = subquery returning one scalar.  
> **Math between two distinct, separate rows** = self-join (or a JOIN in general) to bring both rows side-by-side first.

Want to practice with something concrete from the CS50 `movies.db` — like "what percentage of a movie's votes come from movies released after 2010" or similar, so you can apply the subquery-as-scalar pattern yourself?


[[1 - WHAT IS SQLITE3]]