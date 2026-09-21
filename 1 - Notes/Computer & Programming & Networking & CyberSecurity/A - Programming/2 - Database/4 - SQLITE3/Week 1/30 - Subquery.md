


A **subquery** (also called a nested query or inner query) is a `SELECT` statement placed inside another SQL statement. It runs first, and its result gets used by the outer (main) query — as if the inner query's output were substituted right into the outer query.

```sql
SELECT name FROM people
WHERE id = (SELECT person_id FROM stars WHERE movie_id = 1);
```

Here, the inner `SELECT person_id FROM stars...` runs first, produces a value, and that value gets plugged into the outer `WHERE id = ...`.

## What problem it solves

Without subqueries, if you want to filter or compute something based on data that lives in a _different_ table (or a computed result), you'd have to run one query, manually read the output, then hand-type a second query using that result. Subqueries let the database do this **in one single query**, automatically, without you as the human being the middleman passing values between two separate `SELECT` statements.

### Concrete CS50 example: "Who starred in Toy Story?"

Say you have `movies`, `stars`, and `people` (from the IMDB schema). You want the names of everyone in "Toy Story."

**Without a subquery (two manual steps):**

```sql
-- Step 1: find the movie's id
SELECT id FROM movies WHERE title = 'Toy Story';
-- → you read the output, say it's 1

-- Step 2: manually plug that id in
SELECT person_id FROM stars WHERE movie_id = 1;
-- → you read those ids...

-- Step 3: manually plug those in again
SELECT name FROM people WHERE id IN (...);
```

**With a subquery (one query, database does the chaining):**

```sql
SELECT name FROM people
WHERE id IN (
    SELECT person_id FROM stars
    WHERE movie_id = (
        SELECT id FROM movies WHERE title = 'Toy Story'
    )
);
```

The problem this solves: it removes the need for **manual, multi-step, human-in-the-loop querying**, and lets you express a _single logical question_ ("who's in the movie titled Toy Story?") as a _single database operation_ — faster, less error-prone, and closer to how you'd actually phrase the question in your head.

### Where subqueries typically appear

|Location|Example|
|---|---|
|In `WHERE`|`WHERE id = (SELECT ...)` — filter based on a computed value|
|In `FROM`|`FROM (SELECT ...) AS temp` — treat a query result as a temporary table|
|In `SELECT`|`SELECT name, (SELECT COUNT(*) FROM stars WHERE movie_id = movies.id) FROM movies` — compute a value per row|
|With `IN`|`WHERE id IN (SELECT ...)` — check membership against a list of results|

### Subquery vs JOIN — a note worth flagging early

You _could_ rewrite most subqueries as a `JOIN` instead, and often `JOIN`s perform better in SQLite3. Subqueries tend to be more readable when you're filtering based on a single derived value; `JOIN`s tend to be better when you actually need columns _from both tables_ in your final result. We can compare these side-by-side with the movies schema if you want — that's a very common CS50 stumbling point.


[[1 - WHAT IS SQLITE3 🍕]]