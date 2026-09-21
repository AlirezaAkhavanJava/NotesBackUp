

A **conditional** lets you branch logic based on whether something is true or false — either to filter _which rows_ come back, or to compute _different values_ per row. SQLite3 gives you conditionals at two levels: filtering conditionals (`WHERE`, `HAVING`) and value-producing conditionals (`CASE`, and a few shorthand functions).

## 1. `WHERE` — filter rows based on a condition

The most basic conditional — decides which rows even make it into the result.

```sql
SELECT title FROM movies WHERE year > 2010;
```

### Comparison operators

|Operator|Meaning|
|---|---|
|`=`|Equal|
|`!=` or `<>`|Not equal|
|`>` `<` `>=` `<=`|Greater/less than (or equal)|
|`BETWEEN a AND b`|Inclusive range|
|`LIKE`|Pattern match (`%` = any chars, `_` = one char)|
|`IN (...)`|Match any value in a list|
|`IS NULL` / `IS NOT NULL`|Null checks (never use `= NULL`, it won't work)|

```sql
SELECT title FROM movies WHERE year BETWEEN 2000 AND 2010;
SELECT title FROM movies WHERE title LIKE 'Star%';
SELECT title FROM movies WHERE year IN (1999, 2001, 2010);
SELECT * FROM ratings WHERE rating IS NOT NULL;
```

## 2. Combining conditions — `AND`, `OR`, `NOT`

```sql
SELECT title FROM movies WHERE year > 2000 AND year < 2010;
SELECT title FROM movies WHERE year = 1999 OR year = 2001;
SELECT title FROM movies WHERE NOT year = 1999;
```

⚠️ **Precedence matters** — `AND` binds tighter than `OR`. Always parenthesize when mixing:

```sql
-- Ambiguous-looking, but AND runs first regardless
SELECT * FROM movies WHERE year = 1999 OR year = 2000 AND rating > 8;

-- Be explicit about intent
SELECT * FROM movies WHERE (year = 1999 OR year = 2000) AND rating > 8;
```

## 3. `CASE` — conditional _value_, not just filtering (SQL's if/else)

This is your main tool for computing different output based on a condition, per row.

```sql
SELECT title,
       CASE
           WHEN rating >= 8 THEN 'Excellent'
           WHEN rating >= 6 THEN 'Good'
           WHEN rating IS NULL THEN 'Unrated'
           ELSE 'Average'
       END AS category
FROM movies
JOIN ratings ON ratings.movie_id = movies.id;
```

Two forms of `CASE`:

```sql
-- Searched CASE (conditions can be anything)
CASE WHEN x > 10 THEN 'big' WHEN x > 5 THEN 'medium' ELSE 'small' END

-- Simple CASE (compares one value against several)
CASE year WHEN 1999 THEN 'nineties' WHEN 2020 THEN 'twenties' ELSE 'other' END
```

## 4. `HAVING` — conditional filter AFTER aggregation

`WHERE` filters rows _before_ grouping; `HAVING` filters _groups_ after `GROUP BY`/aggregate functions run. This trips up a lot of beginners.

```sql
SELECT publisher_id, COUNT(*) AS num_books
FROM books
GROUP BY publisher_id
HAVING COUNT(*) > 5;    -- only publishers with more than 5 books
```

You **cannot** use an aggregate function like `COUNT(*)` inside `WHERE` — that's exactly what `HAVING` exists for.

```sql
-- ❌ Wrong — errors out
SELECT publisher_id FROM books WHERE COUNT(*) > 5;

-- ✅ Correct
SELECT publisher_id FROM books GROUP BY publisher_id HAVING COUNT(*) > 5;
```

## 5. `IIF()` — shorthand inline if/else (SQLite-specific)

A lighter alternative to `CASE` for simple two-way branches.

```sql
SELECT title, IIF(rating >= 7, 'Good', 'Not Great') AS verdict
FROM movies JOIN ratings ON ratings.movie_id = movies.id;
```

Same as: `CASE WHEN rating >= 7 THEN 'Good' ELSE 'Not Great' END` — just shorter.

## 6. `EXISTS` / `NOT EXISTS` — conditional based on related-row presence

Covered before, but worth repeating here since it's a true/false conditional over a subquery:

```sql
SELECT title FROM movies m
WHERE EXISTS (SELECT 1 FROM ratings WHERE ratings.movie_id = m.id);
```

## Quick reference: WHERE vs HAVING vs CASE

|Keyword|Operates on|Purpose|
|---|---|---|
|`WHERE`|Individual rows, before grouping|Decide which rows to include|
|`HAVING`|Groups, after `GROUP BY`/aggregation|Decide which groups to include|
|`CASE`|Any row's values|Compute a different _output value_ per row|
|`IIF()`|Any row's values|Shorthand `CASE` for simple two-branch logic|

## Practice question for you

Try writing: **"Show each movie's title and label it 'Blockbuster' if it has more than 100,000 votes, otherwise 'Indie'."**

Think about whether you need `WHERE`, `CASE`, or both — then give it a shot and I'll check it.


[[1 - WHAT IS SQLITE3 🍕]]