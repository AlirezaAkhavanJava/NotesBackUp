


An **index** in SQLite is a separate data structure that SQLite maintains to find rows more efficiently based on one or more columns.

For example:

```sql
CREATE INDEX title_index ON movies(title);
```

You now have:

```text
movies
   │
   └── title_index
          └── title → row location
```

The important thing to understand is that **SQLite does not provide `ALTER INDEX`**.

## Dropping an index

Use:

```sql
DROP INDEX index_name;
```

For your example:

```sql
DROP INDEX title_index;
```

This removes the index itself. **It does not delete the `movies` table or any movie rows.**

You can verify it with:

```sql
.schema movies
```

or:

```sql
.indexes movies
```

---

## What about altering an index?

There is no command like:

```sql
ALTER INDEX title_index ...
```

SQLite's SQL syntax doesn't provide `ALTER INDEX`.

So if you created:

```sql
CREATE INDEX title_index ON movies(title);
```

and later decide you want an index on `year` instead, you do:

```sql
DROP INDEX title_index;

CREATE INDEX year_index ON movies(year);
```

If you want a composite index:

```sql
CREATE INDEX movie_search_index
ON movies(title, year);
```

Again, if you need to change its columns, you **drop the old index and create a new one**.

### Why?

An index isn't just metadata containing a list of columns that can be casually edited. SQLite builds an actual index data structure containing entries based on those columns.

For:

```sql
CREATE INDEX title_index ON movies(title);
```

SQLite builds a structure conceptually like:

```text
title_index

"Avatar"       → row
"Cars"         → row
"Cars"         → row
"Jaws"         → row
"Matrix"       → row
```

If you change it to:

```sql
CREATE INDEX title_year_index ON movies(title, year);
```

the structure itself has to be built differently:

```text
(title, year)

("Avatar", 2009) → row
("Cars", 2006)   → row
("Cars", 2011)   → row
("Jaws", 1975)   → row
```

So SQLite's approach is:

```text
old index
    ↓
DROP INDEX
    ↓
CREATE INDEX
    ↓
new index
```

### One important distinction

Don't confuse **altering an index** with **altering a table**.

You can do things such as:

```sql
ALTER TABLE movies ADD COLUMN rating REAL;
```

But an index is managed separately:

```sql
CREATE INDEX ...
DROP INDEX ...
```

There is **no `ALTER INDEX` in SQLite**.



[[SQlite]]