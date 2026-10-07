

This is the point where you move from **“I know what an index is”** to **“I can look at a query and design an index intentionally.”**

The most important idea is:

```text
Don't start with:
"What index should I create?"

Start with:
"How is SQLite executing this query,
and what part of that execution can I improve?"
```

---

## 1. First: understand what `EXPLAIN QUERY PLAN` is telling you

Take:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

Run:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE title = 'Cars';
```

Without an index, you may see:

```text
SCAN movies
```

### `SCAN`

`SCAN` means SQLite is walking through the entire table or entire index.

For the table:

```text
movies
  ↓
row 1 → check title
row 2 → check title
row 3 → check title
...
row N → check title
```

That's a full scan.

Now create:

```sql
CREATE INDEX title_index
ON movies(title);
```

Then:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE title = 'Cars';
```

You may see:

```text
SEARCH movies USING INDEX title_index (title=?)
```

Read that almost like a sentence:

> Search `movies` using `title_index` for a condition on `title`.

---

# 2. `SCAN` vs `SEARCH`

This is the first thing you should train your eyes to recognize.

### Scan

```text
SCAN movies
```

SQLite isn't using an index to directly narrow the rows of the table.

### Search

```text
SEARCH movies USING INDEX title_index (title=?)
```

SQLite has an access path that lets it directly narrow down which rows it needs.

Conceptually:

```text
SCAN

movies
 ├── row 1
 ├── row 2
 ├── row 3
 ├── row 4
 ├── ...
 └── row 1,000,000
```

versus:

```text
SEARCH

title_index
     ↓
   "Cars"
     ↓
rowid 12
rowid 87
rowid 931
     ↓
movies
```

That is the fundamental benefit of the index.

---

# 3. Now let's learn how to design an index from the query

Suppose:

```sql
SELECT *
FROM movies
WHERE title = 'Cars'
  AND year = 2006;
```

Look at the query.

It has:

```text
title = ?
year  = ?
```

One possible index is:

```sql
CREATE INDEX movie_lookup
ON movies(title, year);
```

Now the index is ordered roughly like:

```text
(title, year, rowid)
```

Conceptually:

```text
Avatar   2009 → row
Cars     2006 → row
Cars     2011 → row
Jaws     1975 → row
Matrix   1999 → row
```

SQLite can first get to:

```text
Cars
```

and then find:

```text
Cars + 2006
```

So the index is designed around the **actual search conditions**.

---

# 4. Why does the order of columns matter?

This is one of the most important index concepts.

These are different:

```sql
CREATE INDEX idx1
ON movies(title, year);
```

and:

```sql
CREATE INDEX idx2
ON movies(year, title);
```

They create different B-tree orderings.

### `idx1`

```text
title
  └── year
       └── rowid
```

### `idx2`

```text
year
  └── title
       └── rowid
```

Suppose you have:

```sql
WHERE title = 'Cars'
```

Then:

```text
(title, year)
↑
first column matches
```

is useful.

But:

```text
(year, title)
 ↑
 first column does NOT match
```

is not the same thing.

This is the **leftmost-prefix idea**.

An index:

```text
(title, year)
```

can naturally support:

```sql
WHERE title = ?
```

and:

```sql
WHERE title = ?
  AND year = ?;
```

But it is not naturally designed for:

```sql
WHERE year = ?;
```

because `year` is not the first part of the index.

---

# 5. `EXPLAIN QUERY PLAN` lets you verify your idea

Suppose you start with:

```sql
SELECT *
FROM movies
WHERE title = 'Cars'
  AND year = 2006;
```

Before creating an index:

```text
SCAN movies
```

You create:

```sql
CREATE INDEX movie_lookup
ON movies(title, year);
```

Then run:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE title = 'Cars'
  AND year = 2006;
```

You might get:

```text
SEARCH movies USING INDEX movie_lookup (title=? AND year=?)
```

That is excellent information.

SQLite is telling you:

```text
I am using:
    movie_lookup

For:
    title
    year
```

Now you have evidence that your index matches the query.

---

# 6. `ORDER BY` changes index design

Now consider:

```sql
SELECT *
FROM movies
WHERE title = 'Cars'
ORDER BY year;
```

There are actually **two jobs** here:

```text
1. Find title = 'Cars'
2. Return those rows ordered by year
```

So this:

```sql
CREATE INDEX title_index
ON movies(title);
```

helps with the first part.

But SQLite may still need to sort the results.

You might see:

```text
SEARCH movies USING INDEX title_index (title=?)
USE TEMP B-TREE FOR ORDER BY
```

That second line is important.

It means:

```text
title_index
    ↓
find Cars

TEMP B-TREE
    ↓
sort the Cars rows by year
```

Now consider:

```sql
CREATE INDEX movie_lookup
ON movies(title, year);
```

The index itself is ordered:

```text
title → year
```

So for:

```text
title = Cars
ORDER BY year
```

SQLite can potentially walk the `Cars` part of the index already in `year` order.

That means the index helps with **both search and ordering**.

---

# 7. This is how you should think about index design

Don't look at an index as:

```text
"index for title"
```

Think of it as:

```text
"an ordered access path designed for a particular workload"
```

For example:

```sql
CREATE INDEX idx_movies_title_year
ON movies(title, year);
```

isn't merely:

> an index containing two columns.

It creates a particular order:

```text
title → year → rowid
```

That order determines **which queries can efficiently use it**.

---

# 8. What does `COVERING INDEX` mean?

Consider:

```sql
SELECT title, year
FROM movies
WHERE title = 'Cars';
```

And:

```sql
CREATE INDEX movie_lookup
ON movies(title, year);
```

Look carefully.

The query needs:

```text
WHERE:
    title

SELECT:
    title
    year
```

The index already contains both:

```text
title
year
```

So SQLite may not need to visit the actual table at all.

The plan can become:

```text
SEARCH movies USING COVERING INDEX movie_lookup (title=?)
```

That means:

> The index contains all the information necessary to answer this query.

Conceptually:

### Normal index

```text
index
  ↓
find rowid
  ↓
go to table
  ↓
get data
```

### Covering index

```text
index
  ↓
everything required is already here
```

That's an optimization on top of normal index usage.

---

# 9. But don't create giant indexes

You might think:

```sql
CREATE INDEX everything
ON movies(title, year, director, rating, genre, language, runtime, ...);
```

Then every query can use it.

Not a good strategy.

Indexes themselves have costs.

Every time SQLite changes indexed table data, relevant indexes may also need maintenance.

So more indexes mean:

```text
more disk space
+
more memory/cache pressure
+
more work on INSERT
+
more work on UPDATE
+
more work on DELETE
```

The goal isn't:

> Create as many indexes as possible.

The goal is:

> Create indexes that make important queries significantly cheaper.

---

# 10. `SEARCH` does not automatically mean "optimal"

This is a very important professional-level point.

Suppose:

```sql
SELECT *
FROM users
WHERE country = 'USA';
```

You have:

```sql
CREATE INDEX idx_country
ON users(country);
```

And SQLite says:

```text
SEARCH users USING INDEX idx_country (country=?)
```

That means the index **can be used**.

It does not necessarily mean:

> This is the fastest possible execution strategy.

Imagine:

```text
10,000,000 users
9,000,000 are from USA
```

The index still has to find an enormous number of matching rows.

Sometimes a different plan can be cheaper.

SQLite's query planner estimates the costs of available strategies and chooses among them.

So:

```text
SEARCH
```

is a clue.

Not a guarantee that you designed the perfect database.

---

# 11. A practical index-design process

Take a real query:

```sql
SELECT title, year
FROM movies
WHERE title = 'Cars'
ORDER BY year;
```

Don't immediately create an index.

First analyze the query:

```text
WHERE
    title = ?

ORDER BY
    year

SELECT
    title, year
```

Now ask:

> Can one index satisfy several of these requirements?

Candidate:

```sql
CREATE INDEX idx_movies_title_year
ON movies(title, year);
```

Then test it:

```sql
EXPLAIN QUERY PLAN
SELECT title, year
FROM movies
WHERE title = 'Cars'
ORDER BY year;
```

Read the result.

You are looking for things like:

```text
SEARCH ...
USING INDEX ...
```

and whether SQLite still needs:

```text
USE TEMP B-TREE FOR ORDER BY
```

Then compare before/after.

That is actual index engineering.

---

# 12. One example with three queries

Suppose you have:

```sql
CREATE INDEX idx_movies_title_year
ON movies(title, year);
```

Now:

### Query A

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

Good fit:

```text
title
 ↑
first index column
```

### Query B

```sql
SELECT *
FROM movies
WHERE title = 'Cars'
  AND year = 2006;
```

Even better fit:

```text
title → year
```

### Query C

```sql
SELECT *
FROM movies
WHERE year = 2006;
```

Not the same situation.

You are asking SQLite to search by the **second** index column without restricting the first one.

That's where understanding the physical order of the B-tree becomes important.

---

# Put the whole thing together

When you see:

```sql
EXPLAIN QUERY PLAN
SELECT ...
FROM ...
WHERE ...
ORDER BY ...;
```

read it as:

```text
What table is SQLite accessing?
        ↓
SCAN or SEARCH?
        ↓
Which index?
        ↓
Which indexed columns are being used?
        ↓
Does it need a TEMP B-TREE?
        ↓
Can I design one better access path?
```

And your index-design workflow becomes:

```text
                SQL QUERY
                    │
                    ▼
        ┌─────────────────────┐
        │ WHERE / JOIN        │
        │ ORDER BY / GROUP BY │
        │ SELECT              │
        └──────────┬──────────┘
                   ▼
          Design candidate index
                   │
                   ▼
        EXPLAIN QUERY PLAN
                   │
                   ▼
          Inspect actual plan
                   │
          ┌────────┴────────┐
          ▼                 ▼
       Good path         Bad/expensive
          │                 │
          ▼                 ▼
        Test             Redesign
```




[[SQlite]]