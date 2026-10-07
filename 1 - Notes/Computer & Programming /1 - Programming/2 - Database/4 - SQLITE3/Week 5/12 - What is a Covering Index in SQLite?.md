

A **covering index** is an index that contains **all the columns SQLite needs for a particular query**, so SQLite can answer the query using the index **without going back to the original table**.

The important word is **covering**:

> The index _covers_ everything the query needs.

---

## Start with a normal index

Suppose:

```sql
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER,
    director TEXT
);
```

Create:

```sql
CREATE INDEX title_index
ON movies(title);
```

Now run:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

The index contains:

```text
title
```

But `SELECT *` needs:

```text
id
title
year
director
```

So SQLite can use the index to **find the rows**, but it still needs to visit the table to get the rest of the data.

Conceptually:

```text
title_index
    ↓
find "Cars"
    ↓
rowid
    ↓
movies table
    ↓
get the actual row
```

That's a normal index lookup.

---

# Now make the index cover the query

Suppose the query is:

```sql
SELECT title, year
FROM movies
WHERE title = 'Cars';
```

Create:

```sql
CREATE INDEX title_year_index
ON movies(title, year);
```

The index contains:

```text
title
year
```

And your query needs:

```text
WHERE → title
SELECT → title, year
```

Everything it needs is already inside the index.

So SQLite can potentially do:

```text
title_year_index
       ↓
find title = Cars
       ↓
read title + year
       ↓
return result
```

It doesn't need to visit `movies`.

That's a **covering index**.

---

## How do you see this in `EXPLAIN QUERY PLAN`?

Run:

```sql
EXPLAIN QUERY PLAN
SELECT title, year
FROM movies
WHERE title = 'Cars';
```

You may see:

```text
SEARCH movies USING COVERING INDEX title_year_index (title=?)
```

The important word is:

```text
COVERING
```

SQLite is telling you:

> I can satisfy this query from the index alone.

---

# Why is that faster?

With a normal index:

```text
Index
  ↓
find matching entry
  ↓
get rowid
  ↓
go to table
  ↓
read row
```

With a covering index:

```text
Index
  ↓
find matching entry
  ↓
read everything needed
```

The second path avoids the extra table lookup.

This becomes more useful when the query returns many matching rows.

---

# Example with actual data

Suppose:

```text
movies

id   title     year
---  --------  ----
1    Cars      2006
2    Avatar    2009
3    Cars      2011
4    Jaws      1975
```

With:

```sql
CREATE INDEX title_index
ON movies(title);
```

the index conceptually contains:

```text
title → rowid

Avatar → 2
Cars   → 1
Cars   → 3
Jaws   → 4
```

Query:

```sql
SELECT title, year
FROM movies
WHERE title = 'Cars';
```

SQLite finds:

```text
Cars → 1
Cars → 3
```

Then it must go to the table:

```text
rowid 1 → Cars, 2006
rowid 3 → Cars, 2011
```

Now with:

```sql
CREATE INDEX title_year_index
ON movies(title, year);
```

the index conceptually contains:

```text
(title, year) → row

(Avatar, 2009)
(Cars,   2006)
(Cars,   2011)
(Jaws,   1975)
```

SQLite finds the `Cars` entries and already has:

```text
title
year
```

So it can return:

```text
Cars  2006
Cars  2011
```

without fetching the table rows.

---

# But there is an important detail: the index still has a row identifier

For an ordinary SQLite rowid table, index entries contain the indexed columns plus the rowid.

So conceptually:

```text
(title, year, rowid)
```

For example:

```text
(Cars, 2006, 1)
(Cars, 2011, 3)
```

That rowid is what lets a normal index go back to the table when it needs columns that aren't in the index.

A covering index simply means:

> SQLite doesn't need to use that rowid to fetch the table because the index already has everything required.

---

# Don't misunderstand "covering"

A covering index is **not a special type of index** that you create using different syntax.

You still create an ordinary index:

```sql
CREATE INDEX idx
ON movies(title, year);
```

Whether it is **covering** depends on the query.

For this query:

```sql
SELECT title, year
FROM movies
WHERE title = 'Cars';
```

it can be covering.

But:

```sql
SELECT title, year, director
FROM movies
WHERE title = 'Cars';
```

isn't covered by that same index because `director` isn't there.

So:

```text
Index:
    title
    year

Query needs:
    title ✓
    year  ✓
    director ✗

→ not covering
```

This is why **covering is a property of the index + query combination**, not just the index by itself.

---

# One more important point

You shouldn't automatically add every selected column to every index just to get `COVERING`.

For example:

```sql
CREATE INDEX gigantic_index
ON movies(title, year, director, description, plot, language, ...);
```

That can make the index much larger and increase the cost of maintaining it.

Usually you first solve the important problem:

```text
Can the index efficiently find the rows?
```

Then, when performance justifies it, you consider:

```text
Can the index also cover the query?
```

So think of it as:

```text
Good search index
       ↓
possibly
       ↓
Covering index
```

rather than:

```text
Every index should contain everything.
```

---

## The simplest definition to remember

> **A covering index is an index that contains every column needed by a query, allowing SQLite to answer that query without accessing the original table.**

And when you see:

```text
USING COVERING INDEX
```

in `EXPLAIN QUERY PLAN`, read it as:

> **“The index alone contains enough information for this query.”**





[[SQlite]]