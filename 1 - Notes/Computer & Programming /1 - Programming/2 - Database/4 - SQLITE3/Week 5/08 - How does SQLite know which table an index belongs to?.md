

The important thing is: **an SQLite index is not globally "floating around" without an owner. The index definition explicitly records the table it was created for.**

When you write:

```sql
CREATE INDEX title_index ON movies(title);
```

SQLite stores metadata roughly equivalent to:

```text
Index: title_index
Table: movies
Column: title
```

So SQLite knows:

```text
title_index
     │
     └── movies.title
```

## Where does SQLite store this information?

SQLite has a special internal table called:

```sql
sqlite_schema
```

You can inspect it:

```sql
SELECT type, name, tbl_name, sql
FROM sqlite_schema
WHERE type = 'index';
```

For example, you might get:

```text
type    name         tbl_name    sql
------  -----------  ----------  -----------------------------------------------
index   title_index  movies      CREATE INDEX title_index ON movies(title)
index   year_index   movies      CREATE INDEX year_index ON movies(year)
index   name_index   actors      CREATE INDEX name_index ON actors(name)
```

Notice this column:

```text
tbl_name
```

That is the table the index belongs to.

So with:

```sql
CREATE INDEX title_index ON movies(title);
```

SQLite records that `title_index` belongs to `movies`.

And:

```sql
CREATE INDEX name_index ON actors(name);
```

belongs to `actors`.

---

## But there is another important detail

SQLite doesn't merely need to know **which table** the index belongs to.

It also needs to know **what columns and expressions the index was built from**.

For example:

```sql
CREATE INDEX movie_search
ON movies(title, year);
```

SQLite knows:

```text
movie_search
     │
     └── movies
          ├── title
          └── year
```

This is why when you execute:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

SQLite's query planner can look at the available indexes and determine:

```text
Query needs: movies.title

Available:
    title_index → movies.title       ✓
    year_index  → movies.year        ✗
    name_index  → actors.name        ✗
```

Therefore `title_index` is a candidate.

---

# How can you have thousands of indexes?

You can have many indexes across many tables:

```text
Database
│
├── movies
│   ├── title_index
│   ├── year_index
│   └── rating_index
│
├── actors
│   ├── name_index
│   └── birth_date_index
│
└── directors
    ├── name_index
    └── country_index
```

SQLite doesn't get confused because each index's schema definition identifies its associated table.

You can see all of them with:

```sql
SELECT name, tbl_name, sql
FROM sqlite_schema
WHERE type = 'index';
```

---

## One thing that may surprise you

The **index itself is a separate structure**, but SQLite doesn't treat it like an independent table that you manually search.

For example:

```sql
CREATE INDEX title_index ON movies(title);
```

conceptually creates:

```text
movies table
    ↓
row data

title_index
    ↓
ordered index entries
```

The index contains references back to rows in the table.

For a normal rowid table, conceptually:

```text
title_index

"Avatar" → rowid 17
"Cars"   → rowid 23
"Cars"   → rowid 81
"Jaws"   → rowid 42
```

Then SQLite can find `"Cars"` in the index and obtain the corresponding row locations in `movies`.

So there are really **two levels of identification** happening:

```text
1. Schema metadata
   "title_index belongs to movies"

2. Index contents
   "this title points to these rows"
```

That's an important distinction.




[[SQlite]]