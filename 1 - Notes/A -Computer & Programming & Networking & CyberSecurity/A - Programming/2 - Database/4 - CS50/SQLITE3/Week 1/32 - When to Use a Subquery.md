
**1. You need a single value to filter by, computed from another table**

```sql
SELECT title FROM movies WHERE year = (SELECT MAX(year) FROM movies);
```

Perfect fit — you just need _one_ number, not extra columns.

**2. You need to check membership in a list (`IN` / `NOT IN`)**

```sql
SELECT name FROM people
WHERE id IN (SELECT person_id FROM stars WHERE movie_id = 1);
```

Good fit — you're asking "is this row's id somewhere in that other set?"

**3. You need an existence check (`EXISTS` / `NOT EXISTS`)**

```sql
SELECT title FROM movies
WHERE EXISTS (SELECT 1 FROM ratings WHERE ratings.movie_id = movies.id);
```

Great fit — "does at least one related row exist?" without caring what that row contains.

**4. You need a per-row computed value in `SELECT`**

```sql
SELECT title,
       (SELECT COUNT(*) FROM stars WHERE stars.movie_id = movies.id) AS num_stars
FROM movies;
```

Good fit — a correlated subquery calculating something extra alongside each row.

**5. Readability — the query reads like the English question**  
"Find the title where the id equals the movie_id where the rating is highest" — subqueries let you write nested logic that mirrors how you'd phrase the question out loud. Useful when you're learning or when the logic is genuinely sequential.

**6. You need to treat a query result as a temporary table**

```sql
SELECT AVG(rating) FROM (
    SELECT rating FROM ratings WHERE votes > 10000
);
```

Good fit — pre-filter, then aggregate.

## When NOT to Use a Subquery

**1. You need columns from multiple tables in the final result**

```sql
-- Bad instinct: subquery can't give you both movie.title AND people.name together
-- Good: use a JOIN
SELECT movies.title, people.name
FROM movies
JOIN stars ON stars.movie_id = movies.id
JOIN people ON people.id = stars.person_id;
```

A subquery only ever resolves to _one column_ (or one value) — it can't hand back a full row of mixed-table data the way a JOIN can.

**2. Performance matters and the subquery is correlated (runs per row)**  
A **correlated subquery** re-executes once for _every row_ of the outer query — that's slow on large tables:

```sql
-- Runs the subquery once per movie row — expensive on big datasets
SELECT title,
       (SELECT COUNT(*) FROM stars WHERE stars.movie_id = movies.id) AS num_stars
FROM movies;
```

```sql
-- Faster: JOIN + GROUP BY does it in one pass
SELECT movies.title, COUNT(stars.person_id) AS num_stars
FROM movies
LEFT JOIN stars ON stars.movie_id = movies.id
GROUP BY movies.id;
```

**3. You're doing multiple levels of aggregation across relationships**  
Deeply nested subqueries (3+ levels) get hard to read and debug. A JOIN with `GROUP BY` is usually clearer and easier to reason about than four layers of parentheses.

**4. You need to update/modify data based on a join condition across tables**

```sql
-- Awkward and sometimes unsupported depending on SQL dialect
UPDATE movies SET title = ... WHERE id = (SELECT ...);
-- Often cleaner conceptually as a JOIN-based UPDATE where the dialect supports it
```

**5. The subquery could return more than one row where only one is expected**

```sql
-- DANGEROUS: if 'Toy Story' matches multiple movie ids (sequels!), this errors or misbehaves
SELECT * FROM ratings WHERE movie_id = (SELECT id FROM movies WHERE title = 'Toy Story');
```

If there's any chance of multiple matches, you need `IN` instead of `=`, or better, rethink with a JOIN.

## Quick decision rule

|Question you're asking|Tool|
|---|---|
|"What's this one value from another table?"|Subquery|
|"Does a related row exist?"|Subquery (`EXISTS`)|
|"Is this value inside that set?"|Subquery (`IN`)|
|"I need combined columns from 2+ tables"|JOIN|
|"I need this to be fast on a big table"|JOIN|
|"I need to group and count/sum across a relationship"|JOIN + `GROUP BY`|

> **Rule of thumb:** if you only need a _value_ from another table, subquery. If you need _rows_ (actual columns) from another table alongside your own, JOIN.



[[1 - WHAT IS SQLITE3]]