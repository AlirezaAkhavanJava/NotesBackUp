# `SCAN` vs `INDEX` in SQLite

**`SCAN` and `INDEX` are not opposites.**

`SCAN` describes **how SQLite traverses something**. An index is **the structure SQLite may traverse**.

So you can have:

```text
SCAN table
SCAN index
SEARCH table using index
SEARCH table using covering index
```

## `SCAN`

Example:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies;
```

You might get:

```text
SCAN movies
```

SQLite is walking through the table from beginning to end.

Conceptually:

```text
movies
 ↓
row 1
row 2
row 3
...
row N
```

Now this is interesting:

```sql
EXPLAIN QUERY PLAN
SELECT title
FROM movies
ORDER BY title;
```

SQLite might choose:

```text
SCAN movies USING INDEX title_index
```

This means:

> SQLite is scanning the **entire index**, not searching for a small subset.

Why would that be useful?

Because `title_index` is already ordered by `title`, so SQLite can walk the index in order instead of scanning the table and then sorting it.

So **`SCAN` doesn't mean “bad.”**

---

## `SEARCH`

Now:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE title = 'Cars';
```

with:

```sql
CREATE INDEX title_index ON movies(title);
```

might produce:

```text
SEARCH movies USING INDEX title_index (title=?)
```

This means SQLite is using the index to locate a **subset** of rows.

Conceptually:

```text
index
  ↓
find Cars
  ↓
matching rowids
  ↓
movies rows
```

So the key distinction is:

```text
SCAN  → traverse everything
SEARCH → find a subset
```

---

## Why not always use an index?

Suppose there are only 10 rows:

```text
movies = 10 rows
```

and your query is:

```sql
SELECT *
FROM movies;
```

An index doesn't magically make “give me everything” faster.

SQLite may simply:

```text
SCAN movies
```

because reading all 10 rows directly is cheap.

Now imagine:

```text
movies = 10,000,000 rows
```

and:

```sql
WHERE title = 'Cars'
```

A suitable index can let SQLite jump directly toward the relevant entries instead of examining millions of rows.

---

## The important thing to remember from `EXPLAIN QUERY PLAN`

When you see:

```text
SCAN movies
```

think:

> **SQLite is traversing the whole table.**

When you see:

```text
SCAN movies USING INDEX title_index
```

think:

> **SQLite is traversing the whole index, often because the index's ordering is useful.**

When you see:

```text
SEARCH movies USING INDEX title_index (title=?)
```

think:

> **SQLite is using the index to narrow down the rows.**

And:

```text
SEARCH movies USING COVERING INDEX title_index (title=?)
```

means:

> **It can get everything it needs directly from the index.**

That's the distinction you should carry when reading plans.


[[SQlite]]