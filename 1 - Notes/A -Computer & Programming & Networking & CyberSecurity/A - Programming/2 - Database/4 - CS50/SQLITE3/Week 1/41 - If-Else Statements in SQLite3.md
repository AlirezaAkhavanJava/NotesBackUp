

Here's the important thing to know upfront: **SQLite3 does not have a standalone `IF...ELSE` statement** like some other languages or even MySQL. There's no `IF (condition) THEN ... ELSE ... END IF;` block you can just drop into your SQL. Instead, SQLite3 expresses "if-else" logic entirely through **expressions** — meaning it produces a _value_, not a control-flow block.

The two tools that do this job:

## 1. `CASE WHEN ... THEN ... ELSE ... END` — the real if-else equivalent

This **is** SQLite3's if-else. It's an expression that evaluates conditions in order and returns the first matching result.

```sql
SELECT title,
    CASE
        WHEN rating >= 8 THEN 'Excellent'
        WHEN rating >= 6 THEN 'Good'
        ELSE 'Average'
    END AS verdict
FROM movies
JOIN ratings ON ratings.movie_id = movies.id;
```

Read it exactly like nested if-else:

```
if rating >= 8:
    verdict = 'Excellent'
elif rating >= 6:
    verdict = 'Good'
else:
    verdict = 'Average'
```

- `WHEN` = your `if` / `elif` conditions, checked **top to bottom**, first match wins
- `ELSE` = the fallback, like a final `else` — **optional**; if omitted and nothing matches, the result is `NULL`
- `END` = closes the expression (required)

### Multiple conditions (like chained elif)

```sql
SELECT title,
    CASE
        WHEN year < 1980 THEN 'Classic'
        WHEN year BETWEEN 1980 AND 2000 THEN 'Retro'
        WHEN year > 2000 THEN 'Modern'
        ELSE 'Unknown'
    END AS era
FROM movies;
```

## 2. `IIF(condition, true_value, false_value)` — shorthand for simple 2-way if-else

For a plain if/else with just two outcomes, `IIF()` is shorter than writing a full `CASE`.

```sql
SELECT title, IIF(rating >= 7, 'Good', 'Not Great') AS verdict
FROM movies JOIN ratings ON ratings.movie_id = movies.id;
```

This is exactly equivalent to:

```sql
CASE WHEN rating >= 7 THEN 'Good' ELSE 'Not Great' END
```

`IIF()` only handles **one condition, two outcomes** — for anything with 3+ branches, you need `CASE`.

## 3. Nesting if-else (nested CASE, or nested IIF)

```sql
SELECT title,
    CASE
        WHEN rating IS NULL THEN 'Unrated'
        ELSE
            CASE
                WHEN rating >= 8 THEN 'Excellent'
                ELSE 'Average'
            END
    END AS verdict
FROM movies JOIN ratings ON ratings.movie_id = movies.id;
```

Usually cleaner to just add more `WHEN` branches to one `CASE` instead of nesting, but nesting is valid when the logic genuinely branches into sub-cases.

## Why there's no procedural `IF` block

SQL (including SQLite3) is fundamentally a **declarative** language — you describe _what_ you want, not step-by-step _how_ to get it, and every clause has to ultimately resolve to a value or a filter, not a flow-control jump. That's why `CASE` is written as an **expression** you can drop anywhere a value is expected — in `SELECT`, in `WHERE`, in `ORDER BY` — rather than a statement that changes control flow.

```sql
-- CASE used inside ORDER BY — sort "Excellent" movies first
SELECT title, rating FROM movies
JOIN ratings ON ratings.movie_id = movies.id
ORDER BY CASE WHEN rating >= 8 THEN 0 ELSE 1 END;
```

_(One caveat: if you ever write custom SQLite triggers, there's a separate feature — trigger-level conditions using `WHEN` on the trigger itself — but that's a different, more advanced topic from row-level if-else logic.)_

## Quick summary table

|Tool|Branches|Best for|
|---|---|---|
|`CASE WHEN...THEN...ELSE...END`|Any number|General if/elif/else logic|
|`IIF(cond, val1, val2)`|Exactly 2|Quick, simple two-way branch|
|Nested `CASE`|Any number, hierarchical|Sub-branching logic (rare, usually avoidable)|

Want to try converting an if-else you'd write in Java (since you're learning that too) into the equivalent `CASE` statement in SQL? Could be a useful way to cement how the "same logic, different paradigm" translation works.


[[1 - WHAT IS SQLITE3]]