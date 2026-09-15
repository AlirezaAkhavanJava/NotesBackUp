

A **NATURAL JOIN** automatically joins two tables based on **all columns that share the same name** in both tables — you don't write an `ON` clause at all. SQLite3 figures out the matching condition for you, behind the scenes.

```sql
SELECT * FROM movies NATURAL JOIN ratings;
```

This works _only if_ both tables have a column with an identical name that's meant to match — in this case, both `movies` and `ratings` need a shared column name for it to work. But wait — in the CS50 schema, `movies` has `id`, and `ratings` has `movie_id`. **These column names don't match**, so `NATURAL JOIN` would silently fail to find a relationship, or worse, match on the wrong column if there happens to be an accidental name collision.

## Why NATURAL JOIN is risky — the problem it _creates_ rather than solves

This is one of the few SQL features that's more dangerous than useful, and most professional style guides actively recommend avoiding it. Here's why:

**1. It's implicit — you can't see what it's actually joining on just by reading the query.**

```sql
SELECT * FROM movies NATURAL JOIN ratings;
```

You have to go check both table schemas to figure out what columns it decided to match on. Compare that to an explicit JOIN, where the relationship is right there in the query:

```sql
SELECT * FROM movies JOIN ratings ON ratings.movie_id = movies.id;
```

**2. It silently breaks if a schema changes.**  
Say someone later adds a column called `year` to _both_ `movies` and `ratings` for unrelated reasons (maybe `ratings.year` = the year the rating was submitted, totally different meaning from `movies.year` = release year). Now `NATURAL JOIN` will suddenly start matching on `year` too — this drastically changes your results, **with zero warning**, because nothing about the query text changed.

**3. It only works when your naming conventions happen to align perfectly.**  
In the real CS50 schema, `movies.id` vs `ratings.movie_id` don't share a name — so `NATURAL JOIN` wouldn't even establish a relationship. You'd need to rename columns just to accommodate the join style, which is backwards — your schema shouldn't bend to fit a query technique.

## When would it actually work in this schema?

If you had two tables that genuinely share an identically-named key column:

```sql
CREATE TABLE authors (author_id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE books (author_id INTEGER, title TEXT);

SELECT * FROM authors NATURAL JOIN books;
-- Works because BOTH tables literally have a column named "author_id"
```

This is equivalent to:

```sql
SELECT * FROM authors JOIN books ON authors.author_id = books.author_id;
```

## Professional recommendation

> **Avoid `NATURAL JOIN` in real projects.** Always write explicit `JOIN ... ON` conditions instead. The tiny bit of typing you save with `NATURAL JOIN` is far outweighed by the loss of clarity and the risk of silent, hard-to-debug behavior changes if the schema evolves.

## Quick comparison

||`NATURAL JOIN`|`JOIN ... ON`|
|---|---|---|
|Join condition|Implicit — inferred from matching column names|Explicit — you write it|
|Risk if schema changes|High — new same-named columns silently alter behavior|None — condition is fixed regardless of other columns|
|Readability|Poor — must inspect both schemas to know what's happening|Excellent — self-documenting|
|Professional usage|Rare, generally discouraged|Standard|




[[1 - WHAT IS SQLITE3]]