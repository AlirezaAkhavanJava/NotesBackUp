


An **OUTER JOIN** returns matched rows _plus_ unmatched rows from at least one side — filling in `NULL` for whatever columns don't have a match. This is the direct opposite of `INNER JOIN`, which only keeps rows that match on **both** sides and silently drops everything else.

The word "OUTER" describes the behavior: you're keeping rows from _outside_ the intersection of the two tables — rows that exist on one side even when there's nothing corresponding on the other side.

## The problem OUTER JOIN solves

Recall `INNER JOIN`'s limitation: if a movie has no rating, `INNER JOIN` just **removes that movie from the results entirely** — you'd never even know it existed in your query output.

```sql
-- INNER JOIN — movies with no rating simply vanish
SELECT movies.title, ratings.rating
FROM movies
INNER JOIN ratings ON ratings.movie_id = movies.id;
```

If your actual question is _"show me every movie, and its rating if it has one"_ — INNER JOIN can't answer that; it silently hides the very rows you might most need to see (e.g., "which movies are missing ratings?"). **OUTER JOIN solves exactly this** — it guarantees rows from the specified side are never dropped, matched or not.

## Types of OUTER JOIN

### 1. LEFT OUTER JOIN (usually just written `LEFT JOIN`)

Keeps **all rows from the left table**, fills `NULL` for right-table columns where there's no match.

```sql
SELECT movies.title, ratings.rating
FROM movies
LEFT OUTER JOIN ratings ON ratings.movie_id = movies.id;
```

`LEFT JOIN` (without the word `OUTER`) means exactly the same thing — SQLite3, like most SQL dialects, treats `OUTER` as optional/implied. Most people just write `LEFT JOIN`.

**Practical use — finding orphans:**

```sql
SELECT movies.title
FROM movies
LEFT JOIN ratings ON ratings.movie_id = movies.id
WHERE ratings.movie_id IS NULL;
```

This finds every movie with **no rating at all** — impossible to get with `INNER JOIN`, since those rows would just be missing, not flagged.

### 2. RIGHT OUTER JOIN (`RIGHT JOIN`)

Mirror image — keeps **all rows from the right table**, `NULL`s on the left where unmatched. Supported in SQLite3 since version 3.39 (2022).

```sql
SELECT movies.title, ratings.rating
FROM ratings
RIGHT OUTER JOIN movies ON ratings.movie_id = movies.id;
```

Note this is _functionally identical_ to swapping the LEFT JOIN table order:

```sql
SELECT movies.title, ratings.rating
FROM movies
LEFT OUTER JOIN ratings ON ratings.movie_id = movies.id;
```

Same result. In professional practice, most people avoid `RIGHT JOIN` entirely and just reorder tables to use `LEFT JOIN` instead — it's more universally understood and more consistent to read across a codebase.

### 3. FULL OUTER JOIN

Keeps **all rows from both tables** — matched where possible, `NULL` on whichever side lacks a match. Also supported since SQLite 3.39.

```sql
SELECT movies.title, ratings.rating
FROM movies
FULL OUTER JOIN ratings ON ratings.movie_id = movies.id;
```

This returns:

- Movies with a rating → both columns filled
- Movies with no rating → `rating` is `NULL`
- (Hypothetically) ratings with no matching movie → `title` is `NULL`

**Use case:** data auditing/reconciliation — checking for mismatches in _either_ direction at once, without running two separate LEFT/RIGHT queries.

## OUTER JOIN vs INNER JOIN — side by side

||`INNER JOIN`|`LEFT (OUTER) JOIN`|`RIGHT (OUTER) JOIN`|`FULL OUTER JOIN`|
|---|---|---|---|---|
|Keeps unmatched left rows?|❌|✅|❌|✅|
|Keeps unmatched right rows?|❌|❌|✅|✅|
|Fills NULL for missing side?|N/A (drops row)|✅ (right side)|✅ (left side)|✅ (either side)|
|Common use|Only complete relationships|Keep all of "my" table, show gaps|Rare — usually rewritten as LEFT|Full audit both directions|

## The core mental model

> **INNER JOIN** = intersection only (what's common to both)  
> **OUTER JOIN** = intersection **plus** the leftover unmatched rows from one or both sides, with `NULL` filling the gaps

If you ever ask yourself _"but what about the rows that don't have a match — do I still want to see them?"_ — the answer "yes" means you need an OUTER JOIN, not an INNER JOIN.




[[1 - WHAT IS SQLITE3]]