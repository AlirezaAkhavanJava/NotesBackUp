

# the index itself does **not** know the table name

This is the part that usually makes SQLite's design click.

When you create:

```sql
CREATE INDEX title_index ON movies(title);
```

SQLite creates **two related things**:

```text
sqlite_schema
    │
    └── metadata saying:
         "title_index belongs to movies"
         "its B-tree starts at root page X"
         "it was created on movies(title)"

database pages
    │
    ├── movies table B-tree
    │
    └── title_index B-tree
```

The **B-tree itself does not contain the string `movies` as its identity**.

The schema metadata tells SQLite what that B-tree represents. SQLite's file format documents this explicitly: `sqlite_schema` has `name`, `tbl_name`, and `rootpage`; `rootpage` identifies the root B-tree page for tables and indexes. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

That distinction is very important.

---

## Look at it yourself

Create a tiny database:

```bash
sqlite3 test.db
```

Then:

```sql
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER
);

CREATE INDEX title_index ON movies(title);
CREATE INDEX year_index ON movies(year);
```

Now:

```sql
SELECT type, name, tbl_name, rootpage, sql
FROM sqlite_schema;
```

You'll see something conceptually like:

```text
type   name          tbl_name   rootpage   sql
-----  ------------  ---------- ---------  ------------------------------------
table  movies        movies     2          CREATE TABLE movies (...)
index  title_index   movies     3          CREATE INDEX title_index ON movies(title)
index  year_index    movies     4          CREATE INDEX year_index ON movies(year)
```

The exact page numbers will differ.

Look at what happened:

```text
title_index
    │
    ├── name     = title_index
    ├── tbl_name = movies
    └── rootpage = 3

year_index
    │
    ├── name     = year_index
    ├── tbl_name = movies
    └── rootpage = 4
```

So when SQLite opens the database, it can establish:

```text
title_index → movies
year_index  → movies
```

and:

```text
root page 3 → title_index's B-tree
root page 4 → year_index's B-tree
```

The `sqlite_schema` table is itself a special table and contains one row describing each table, index, view, and trigger. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

---

# Now the interesting part: what is actually on page 3?

Suppose the data is:

```text
rowid    title
-----    -----
1        Cars
2        Avatar
3        Cars
4        Jaws
```

The table B-tree is conceptually:

```text
movies table B-tree

rowid  → row data

1      → Cars
2      → Avatar
3      → Cars
4      → Jaws
```

But the index B-tree is different.

For:

```sql
CREATE INDEX title_index ON movies(title);
```

SQLite builds an **index B-tree** whose entries contain the indexed column values followed by the row's key. For an ordinary rowid table, that key is the rowid. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

Conceptually:

```text
title_index B-tree

"Avatar" → 2
"Cars"   → 1
"Cars"   → 3
"Jaws"   → 4
```

Notice something:

There is no need for:

```text
"movies"
```

inside every index entry.

The schema already established:

```text
title_index → movies
```

So the index can simply store:

```text
indexed value → row identifier
```

---

# Then your query arrives

You execute:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

SQLite does **not** blindly look through every index in the database.

First, SQLite's query planner examines the SQL statement and the available schema information and determines possible ways to execute the query. SQLite uses a cost-based query planner to choose among possible access strategies. ([SQLite](https://www.sqlite.org/queryplanner.html?utm_source=chatgpt.com "Query Planning"))

The planner sees:

```text
FROM movies
WHERE title = 'Cars'
```

So it knows the important search condition is:

```text
movies.title = 'Cars'
```

It examines available indexes that can help with that table/column.

Conceptually:

```text
Available indexes

title_index → movies.title     ← useful
year_index  → movies.year      ← not useful
```

It can therefore choose:

```text
title_index
```

---

# What happens after it chooses `title_index`?

Now we get into the actual lookup.

The B-tree is ordered by the indexed value.

Something conceptually like:

```text
                    [Cars]
                   /      \
             [Avatar]     [Jaws]
                          ...
```

The exact physical tree depends on how many pages/entries there are, but the fundamental property is that the index is a **B-tree**, allowing SQLite to navigate through the tree rather than inspect every entry. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

SQLite searches for:

```text
"Cars"
```

and finds:

```text
"Cars" → rowid 1
"Cars" → rowid 3
```

Now SQLite knows:

```text
I need rows 1 and 3 from movies.
```

So it goes to the table B-tree:

```text
rowid 1 → Cars
rowid 3 → Cars
```

This is why an index can make a huge difference.

Without the index:

```text
movies
  ↓
inspect row 1
inspect row 2
inspect row 3
inspect row 4
...
inspect row N
```

With the index:

```text
title_index
     ↓
find "Cars"
     ↓
rowid 1, rowid 3
     ↓
movies B-tree
     ↓
retrieve rows 1 and 3
```

SQLite's query-planner documentation describes this basic pattern: use the index to find rowids, then use those rowids to retrieve the corresponding table rows. ([SQLite](https://www.sqlite.org/queryplanner.html?utm_source=chatgpt.com "Query Planning"))

---

# So there are actually THREE different pieces

This is the mental model I want you to keep:

```text
                     DATABASE FILE
┌─────────────────────────────────────────────┐
│                                             │
│  sqlite_schema                              │
│  ┌─────────────────────────────────────┐    │
│  │ title_index → movies → rootpage 3  │    │
│  └─────────────────────────────────────┘    │
│                    │                        │
│                    │ tells SQLite           │
│                    │ where the index is     │
│                    ▼                        │
│             index B-tree                    │
│             ┌─────────────────┐             │
│             │ Avatar → 2      │             │
│             │ Cars   → 1      │             │
│             │ Cars   → 3      │             │
│             │ Jaws   → 4      │             │
│             └─────────────────┘             │
│                    │                        │
│                    │ rowid                  │
│                    ▼                        │
│             movies B-tree                   │
│             ┌─────────────────┐             │
│             │ 1 → complete row│             │
│             │ 2 → complete row│             │
│             │ 3 → complete row│             │
│             │ 4 → complete row│             │
│             └─────────────────┘             │
│                                             │
└─────────────────────────────────────────────┘
```

That is much closer to how you should think about SQLite internally than:

```text
"the index belongs to the table somehow"
```

It doesn't belong because the B-tree has a table name embedded in it.

It belongs because **SQLite's schema metadata associates the index object with the table**.

---

# And here's where `rootpage` becomes important

Remember:

```text
title_index → rootpage 3
```

SQLite databases are divided into pages.

A B-tree consists of pages:

```text
             root page
                 3
              /     \
             /       \
          page 8    page 9
          /   \      /   \
        ...   ...  ...   ...
```

The root page lets SQLite locate the entire B-tree.

SQLite's file format defines a B-tree by its root page; all child pages can be reached from that root. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

So internally:

```text
sqlite_schema
      │
      │ rootpage = 3
      ▼
   page 3
      │
      ├── page 8
      ├── page 9
      └── ...
```

That is the physical connection.

---

# Now let's connect this to the query planner

Suppose you have:

```sql
CREATE INDEX title_index ON movies(title);
```

and:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

The planner effectively has to answer:

> "Can some available access path efficiently find rows satisfying `movies.title = 'Cars'`?"

It sees:

```text
Query:
movies.title = 'Cars'

Index:
title_index
    table → movies
    key   → title
```

That's a match.

But there is an important subtlety:

SQLite doesn't simply say:

```text
"index exists → use index"
```

It considers **whether using it is actually cheaper**.

For example, suppose:

```text
movies = 10 rows
```

A full table scan might be so cheap that an index isn't worthwhile.

Whereas with:

```text
movies = 10,000,000 rows
```

an index that reduces the search to a handful of rows can be dramatically cheaper.

SQLite's planner estimates costs and chooses a plan rather than automatically using every available index. ([SQLite](https://www.sqlite.org/queryplanner.html?utm_source=chatgpt.com "Query Planning"))

That's why:

```sql
CREATE INDEX ...
```

does **not** mean:

> "SQLite will always use this index."

It means:

> "SQLite now has this access path available."

The planner decides whether that access path is useful.

---

# You can inspect the metadata at different levels

These commands are worth knowing.

### See all schema objects

```sql
SELECT type, name, tbl_name, rootpage, sql
FROM sqlite_schema;
```

### See indexes belonging to a particular table

```sql
PRAGMA index_list('movies');
```

### See what columns an index contains

```sql
PRAGMA index_info('title_index');
```

For a simple index:

```text
seqno   cid   name
------  ----  -----
0       1     title
```

Meaning the index contains the `title` column.

For deeper inspection:

```sql
PRAGMA index_xinfo('title_index');
```

That exposes more of the index's internal column information.

---

# One advanced detail you should know now

For a normal index:

```sql
CREATE INDEX idx ON movies(title);
```

the index key is conceptually:

```text
(title, rowid)
```

not merely:

```text
(title)
```

That's why duplicate titles work.

Suppose:

```text
rowid  title
-----  -----
10     Cars
20     Cars
30     Cars
```

If the index contained only:

```text
Cars
Cars
Cars
```

you would have no unique identifier for each entry.

Instead, the effective key is conceptually:

```text
(Cars, 10)
(Cars, 20)
(Cars, 30)
```

SQLite documents this directly: index entries consist of the indexed columns followed by the corresponding table-row key; for ordinary tables that key is the rowid. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

This is also why an index can find **multiple rows** for:

```sql
WHERE title = 'Cars'
```

rather than only one.

---

## The complete journey

When you run:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

the conceptual chain is:

```text
SQL statement
     │
     ▼
Parser
     │
     ▼
Query planner
     │
     │ examines:
     │
     ├── movies table
     ├── title_index
     ├── year_index
     └── other possible access paths
     │
     ▼
Chooses title_index
     │
     ▼
Find title = 'Cars'
inside index B-tree
     │
     ▼
Gets rowids
     │
     ├── 1
     └── 3
     │
     ▼
Lookup rows in movies B-tree
     │
     ├── row 1
     └── row 3
     │
     ▼
Return result
```

And the connection between the **logical object** and the **physical B-tree** is:

```text
sqlite_schema
    │
    ├── tbl_name = movies
    └── rootpage = 3
             │
             ▼
       index B-tree
```

That's the core SQLite internal model.





[[SQlite]]