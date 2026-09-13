

When your data is split across multiple related tables (which is the whole point of good schema design — no duplication, no giant flat tables), subqueries become the tool that lets you **traverse those relationships** to answer a question that starts in one table but needs an answer rooted in another.

Let's use the IMDB schema again: `movies`, `people`, `stars` (join table), `ratings`, `directors`.

## The core pattern: "chaining" through relationships

Every foreign key relationship is really a bridge. A subquery is how you **cross that bridge inside a single query**, instead of stopping at each table manually.

### Example 1 — One-to-many relationship

_"What's the title of the highest-rated movie?"_

```sql
SELECT title FROM movies
WHERE id = (
    SELECT movie_id FROM ratings
    ORDER BY rating DESC
    LIMIT 1
);
```

Here the relationship is `ratings.movie_id → movies.id`. The subquery finds _which_ movie_id has the top rating, then the outer query resolves that id back into a human-readable title. This mirrors the relationship exactly — you're walking the foreign key backwards.

### Example 2 — Many-to-many relationship (via join table)

_"What movies has Tom Hanks starred in?"_

```sql
SELECT title FROM movies
WHERE id IN (
    SELECT movie_id FROM stars
    WHERE person_id = (
        SELECT id FROM people WHERE name = 'Tom Hanks'
    )
);
```

Notice this is a **nested chain of three tables**: `people → stars → movies`. Each subquery resolves one hop across a foreign key relationship before the next one uses it. This is subqueries doing exactly what join tables are _for_ — letting you travel from one side of a many-to-many relationship to the other.

## Good approach: think in terms of "what table has the info I need to filter by?"

A reliable mental process:

1. **Identify what you actually want returned** (the outer `SELECT`'s table)
2. **Identify what condition filters it** — and which _other_ table holds the info for that condition
3. **Follow the foreign key path** from the filter table back to your target table, one subquery per hop

For "movies Tom Hanks starred in":

- Want: `movies.title`
- Filter: only movies linked to a specific `person_id`
- Path: `people` (name → id) → `stars` (person_id → movie_id) → `movies` (id → title)

Each arrow becomes one nested subquery, innermost-first.

## When subqueries are the _right_ approach vs when they're not

|Use a subquery when...|Use a JOIN instead when...|
|---|---|
|You need to filter based on a value from another table, but don't need to _display_ columns from that table|You need to show columns from **multiple** tables in the final result|
|The relationship reduces to a single value or list (e.g., "the id of X", "all ids of Y")|You're combining rows across a many-to-many or one-to-many relationship for full output|
|Readability matters more — subqueries often read like natural English ("where movie_id = the movie titled...")|Performance matters — SQLite3's query planner generally optimizes JOINs better than nested subqueries|

**Rewriting Example 2 as a JOIN** (functionally same result, different tool):

```sql
SELECT movies.title
FROM movies
JOIN stars ON stars.movie_id = movies.id
JOIN people ON people.id = stars.person_id
WHERE people.name = 'Tom Hanks';
```

Both work. But this JOIN version also lets you _add_ `people.birth` or `stars.movie_id` to the `SELECT` easily — a subquery can't give you columns from the tables it filters through, only the final resolved value.

## The underlying principle

Table relationships (via primary/foreign keys) define **how data is connected**. Subqueries are one of the tools that let you **actually navigate those connections at query time** — turning a static schema of linked tables into a dynamic question like "find me everything reachable from this starting point through these relationships."

> Good approach in one sentence: **map the foreign key path first (on paper if needed), then write the subqueries innermost-out, one per hop** — and if you find yourself needing columns from more than one table in the final output, switch to a JOIN instead.




[[1 - WHAT IS SQLITE3]]