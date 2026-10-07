



The most useful way to read SQLite's plan is to stop seeing it as a strange line of text and instead read it as a **description of the execution strategy**.

For example:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE title = 'Cars';
```

might produce:

```text
QUERY PLAN
`--SEARCH movies USING INDEX title_index (title=?)
```

Read that from left to right:

```text
SEARCH
  ↓
movies
  ↓
USING INDEX title_index
  ↓
(title=?)
```

Meaning:

> SQLite is searching `movies`, using `title_index`, and using the `title` condition to locate the rows.

That is the basic skill. Now let's break down every part.

---

## The four pieces underneath the pretty output

SQLite internally represents a query plan as a tree. Each node has four values:

```text
id
parent
notused
detail
```

The SQLite CLI normally hides those raw columns and draws the tree using:

```text
`-- 
|--
```

instead. The fourth field, `detail`, is the part you will usually care about most. ([SQLite](https://www2.sqlite.org/eqp.html?utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

You can make SQLite show the raw/tabular form:

```sql
.explain off
```

and return to the normal graphical form with:

```sql
.explain auto
```

SQLite also warns that the exact output format is intended for interactive debugging and can change between SQLite versions. ([SQLite](https://www2.sqlite.org/eqp.html?utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

---

# First thing: learn `SCAN` and `SEARCH`

These are the two words you should recognize immediately.

### `SCAN`

```text
SCAN movies
```

means SQLite is visiting the entire table.

Conceptually:

```text
movies
 ├── row 1
 ├── row 2
 ├── row 3
 ├── row 4
 ├── ...
 └── row N
```

It does **not** necessarily mean something is wrong. `SCAN` can also mean SQLite is scanning all entries of an index, sometimes because that index provides a useful ordering. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

### `SEARCH`

```text
SEARCH movies USING INDEX title_index (title=?)
```

means SQLite expects to visit only a subset of the rows.

Conceptually:

```text
title_index
     ↓
find Cars
     ↓
matching rows
```

SQLite's documentation defines `SCAN` as a full traversal and `SEARCH` as visiting only a subset of rows. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

So your first instinct should be:

```text
SCAN   → whole thing
SEARCH → narrowed thing
```

But don't stop there.

---

# Now read this line piece by piece

Suppose you get:

```text
SEARCH movies USING INDEX title_index (title=?)
```

There are four useful pieces.

### `SEARCH`

The access strategy.

SQLite is narrowing down the rows.

### `movies`

The table being accessed.

### `USING INDEX title_index`

Which index SQLite chose.

### `(title=?)`

Which condition from the query is being used to search the index.

So:

```sql
WHERE title = 'Cars'
```

becomes:

```text
(title=?)
```

because the plan describes the **shape of the constraint**, not the actual value. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

---

# `USING INDEX` vs `USING COVERING INDEX`

Suppose:

```sql
CREATE INDEX title_index
ON movies(title);
```

and:

```sql
SELECT title, year
FROM movies
WHERE title = 'Cars';
```

The plan might be:

```text
SEARCH movies USING INDEX title_index (title=?)
```

SQLite uses the index to find the rows, but it still needs the table to get `year`.

Conceptually:

```text
title_index
    ↓
find rowid
    ↓
movies table
    ↓
get year
```

Now create:

```sql
CREATE INDEX title_year_index
ON movies(title, year);
```

The plan may become:

```text
SEARCH movies USING COVERING INDEX title_year_index (title=?)
```

`COVERING INDEX` means the index contains all the columns SQLite needs to answer that part of the query, so it can avoid going back to the table. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

Think:

```text
INDEX
  ↓
find row
  ↓
go to table
```

versus:

```text
COVERING INDEX
  ↓
everything needed is already here
```

---

# The parentheses are extremely important

Consider:

```sql
SELECT *
FROM movies
WHERE title = 'Cars'
  AND year > 2000;
```

You might get:

```text
SEARCH movies USING INDEX movie_idx (title=? AND year>?)
```

Read it as:

```text
Index: movie_idx

Used constraints:
    title = ?
    year > ?
```

This is valuable when designing composite indexes because SQLite is telling you **which WHERE conditions it is actually using as index constraints**. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

---

# Now the tree structure matters

Suppose you have:

```sql
SELECT *
FROM movies
JOIN directors
    ON movies.director_id = directors.id
WHERE movies.title = 'Cars';
```

You might see:

```text
|--SEARCH movies USING INDEX title_index (title=?)
`--SEARCH directors USING INTEGER PRIMARY KEY (rowid=?)
```

Do not read these as two unrelated lines.

The tree means:

```text
SEARCH movies
    ↓
for each matching movie
    ↓
SEARCH directors
```

This is a **nested-loop join**.

SQLite implements joins using nested scans, and the order of the plan entries represents the nesting order. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

So the first line is the outer loop:

```text
movies
```

and the second is the inner loop:

```text
directors
```

This becomes extremely important when you start optimizing joins.

---

# Why the order can surprise you

Suppose your SQL is written:

```sql
SELECT *
FROM directors
JOIN movies
    ON movies.director_id = directors.id
WHERE movies.title = 'Cars';
```

You might expect SQLite to process `directors` first because you wrote it first.

It doesn't have to.

The plan could still be:

```text
|--SEARCH movies USING INDEX title_index (title=?)
`--SEARCH directors USING INTEGER PRIMARY KEY (rowid=?)
```

The plan shows **how SQLite actually chose to execute the query**, not merely the order in which tables appear in your SQL. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

That's a very important distinction:

```text
SQL order
    ≠
execution order
```

---

# `USING INTEGER PRIMARY KEY`

This one is worth recognizing immediately.

Suppose:

```sql
CREATE TABLE directors (
    id INTEGER PRIMARY KEY,
    name TEXT
);
```

and SQLite gives:

```text
SEARCH directors USING INTEGER PRIMARY KEY (rowid=?)
```

That means SQLite is using the table's INTEGER PRIMARY KEY lookup.

In SQLite, an `INTEGER PRIMARY KEY` is an alias for the rowid, so SQLite can locate that row directly using the rowid B-tree.

So this:

```text
SEARCH directors USING INTEGER PRIMARY KEY (rowid=?)
```

is already a very direct lookup.

You don't necessarily need to create another ordinary index on that same primary key.

---

# `USE TEMP B-TREE`

Now look at this:

```text
SEARCH movies USING INDEX title_index (title=?)
USE TEMP B-TREE FOR ORDER BY
```

This means SQLite successfully used the index to find the rows, **but it still needs a temporary B-tree to perform the `ORDER BY`**. SQLite documents this explicitly for `ORDER BY`, `GROUP BY`, and `DISTINCT`. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

Example:

```sql
SELECT *
FROM movies
WHERE title = 'Cars'
ORDER BY year;
```

You might have:

```text
SEARCH movies USING INDEX title_index (title=?)
USE TEMP B-TREE FOR ORDER BY
```

Your index solved:

```text
WHERE title = 'Cars'
```

but not:

```text
ORDER BY year
```

That gives you a design clue:

```sql
CREATE INDEX movie_idx
ON movies(title, year);
```

Then inspect the plan again.

You are not designing indexes blindly anymore.

You're using the plan as feedback.

---

# `MULTI-INDEX OR`

Suppose:

```sql
SELECT *
FROM movies
WHERE title = 'Cars'
   OR year = 2006;
```

SQLite can sometimes use multiple indexes:

```text
`--MULTI-INDEX OR
   |--SEARCH movies USING INDEX title_index (title=?)
   `--SEARCH movies USING INDEX year_index (year=?)
```

Read the tree:

```text
             MULTI-INDEX OR
                 /      \
                /        \
        title_index    year_index
```

SQLite is using separate access paths for the two branches and combining the results. SQLite calls this the OR optimization. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

---

# `AUTOMATIC INDEX`

You may eventually encounter:

```text
SEARCH users USING AUTOMATIC COVERING INDEX (email=?)
```

That means SQLite created a temporary automatic index to help execute the query.

This is particularly interesting because it can indicate:

> "SQLite needed an index here, but you didn't explicitly create one."

Automatic indexes are part of SQLite's query-planning machinery. ([SQLite](https://www.sqlite.org/eqp.html?trk=article-ssr-frontend-pulse_little-text-block&utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))

For repeated production workloads, that can be a clue worth investigating rather than assuming SQLite's temporary solution is your final schema design.

---

# A very useful example

Let's say:

```sql
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER
);
```

And:

```sql
SELECT title, year
FROM movies
WHERE title = 'Cars'
ORDER BY year;
```

### Before indexes

```text
`--SCAN movies
```

SQLite is reading the whole table.

### Add:

```sql
CREATE INDEX idx_title
ON movies(title);
```

Now:

```text
|--SEARCH movies USING INDEX idx_title (title=?)
`--USE TEMP B-TREE FOR ORDER BY
```

Now we know:

```text
GOOD:
    finding Cars

STILL EXPENSIVE:
    sorting by year
```

### Change the index:

```sql
DROP INDEX idx_title;

CREATE INDEX idx_title_year
ON movies(title, year);
```

Now you may get something like:

```text
`--SEARCH movies USING COVERING INDEX idx_title_year (title=?)
```

Now the same index can potentially provide:

```text
title filtering
+
year ordering
+
title/year output
```

That's what **reading the plan and designing the index from it** looks like.

---

# Your reading method

When you see a plan, mentally parse it in this order:

```text
1. What table is being accessed?
        ↓
2. SCAN or SEARCH?
        ↓
3. Which index?
        ↓
4. Which WHERE conditions are used?
        ↓
5. Is it COVERING?
        ↓
6. Is there TEMP B-TREE?
        ↓
7. If multiple lines exist:
   what is the tree/nesting order?
```

For example:

```text
|--SEARCH users USING INDEX idx_email (email=?)
`--SEARCH orders USING INDEX idx_user_id (user_id=?)
```

You should be able to say:

> SQLite searches `users` through `idx_email`, then for those matching users it searches `orders` through `idx_user_id`.

That sentence is the real skill.

---

## One correction to keep in your head

Don't use this simplistic rule:

```text
SCAN = bad
SEARCH = good
```

The real rule is:

```text
SCAN = visit the whole input
SEARCH = visit a subset
```

Whether that is **good or bad depends on the query and data size**. SQLite may intentionally choose a scan when it estimates that scanning is cheaper than using an index. ([SQLite](https://www2.sqlite.org/matrix/eqp.html?utm_source=chatgpt.com "EXPLAIN QUERY PLAN"))




[[SQlite]]