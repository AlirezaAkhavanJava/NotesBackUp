

Now that we know SQLite stores tables and indexes as **B-trees made of fixed-size pages**, `VACUUM` becomes much easier to understand.

The most important fact is:

> **`VACUUM` does not simply delete the free pages. It builds a new, compact database and then replaces the old database with it.** ([SQLite](https://www2.sqlite.org/lang_vacuum.html?utm_source=chatgpt.com "VACUUM"))

---

## Before `VACUUM`

Suppose your database has 10 pages:

```text
Page 1   → table
Page 2   → table
Page 3   → index
Page 4   → table
Page 5   → FREE
Page 6   → index
Page 7   → FREE
Page 8   → table
Page 9   → FREE
Page 10  → index
```

Those `FREE` pages are on SQLite's **freelist** and can be reused later. They are still physically part of the database file. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

So:

```text
logical data
    ↓
7 pages actually needed

physical file
    ↓
10 pages allocated
```

The file is larger than necessary.

---

## What `VACUUM` does

Conceptually:

```text
old database
     │
     ▼
read tables + indexes
     │
     ▼
create temporary database
     │
     ▼
write the data again
     │
     ▼
new compact B-trees
     │
     ▼
replace old database
```

SQLite's documentation explicitly describes this as copying the database into a temporary database file and then overwriting the original with the temporary file. The replacement is itself protected using SQLite's normal transaction machinery, including a rollback journal or WAL as appropriate. ([SQLite](https://www2.sqlite.org/lang_vacuum.html?utm_source=chatgpt.com "VACUUM"))

---

## What happens to the B-trees?

This is the interesting part.

Suppose the old table B-tree is fragmented:

```text
Old file:

table B-tree
    │
    ├── page 20
    ├── page 73
    ├── page 41
    ├── page 152
    └── page 96
```

The pages might be scattered around the database.

`VACUUM` rebuilds the database so SQLite can pack the B-trees much more tightly:

```text
New file:

table B-tree
    │
    ├── page 2
    ├── page 3
    ├── page 4
    └── page 5
```

The same happens with indexes.

So `VACUUM` can reduce:

- free pages
    
- fragmentation
    
- partially filled pages
    

and generally pack the tables and indexes more compactly. ([SQLite](https://www2.sqlite.org/lang_vacuum.html?utm_source=chatgpt.com "VACUUM"))

---

## Why doesn't SQLite just move the free pages to the end?

Because `VACUUM` is doing more than that.

Imagine:

```text
page 10 → half empty
page 11 → 30% used
page 12 → free
page 13 → 90% used
```

Simply removing page 12 doesn't solve the partially filled pages.

During rebuilding, SQLite can repack data into new pages:

```text
old:

[60% used]
[30% used]
[FREE]
[90% used]

new:

[100% used]
[100% used]
[80% used]
```

So the new database can need fewer pages overall.

That is one reason `VACUUM` can do more than simply reclaim the freelist. ([SQLite](https://www2.sqlite.org/lang_vacuum.html?utm_source=chatgpt.com "VACUUM"))

---

## What about your indexes?

Suppose:

```sql
CREATE INDEX title_index ON movies(title);
```

The index is itself a B-tree.

When `VACUUM` rebuilds the database, the index is rebuilt too.

So conceptually:

```text
old title_index B-tree
        ↓
read its logical contents
        ↓
build new title_index B-tree
        ↓
pack it into new pages
```

The index's **logical meaning** remains the same:

```text
movies(title)
```

but its physical pages can be completely different.

That's an important distinction:

```text
logical structure
    ↓
same index

physical storage
    ↓
can be completely reorganized
```

---

## The page numbers can change

Remember earlier:

```text
sqlite_schema
    ↓
rootpage
    ↓
B-tree
```

After rebuilding, the B-tree may have different page locations.

So conceptually:

```text
Before:

title_index → root page 73


After:

title_index → root page 5
```

SQLite updates the database structures accordingly during the rebuild.

This is one reason you should think of page numbers as **physical implementation details**, not stable identifiers.

---

## What happens to `ROWID`?

This is a subtle but important consequence.

`VACUUM` **may change the ROWIDs** of rows in tables that do not have an explicit `INTEGER PRIMARY KEY`. ([SQLite](https://www2.sqlite.org/lang_vacuum.html?utm_source=chatgpt.com "VACUUM"))

For example:

```sql
CREATE TABLE movies (
    title TEXT
);
```

The table has an implicit rowid.

After `VACUUM`:

```text
Before:
rowid 1 → Cars
rowid 2 → Avatar
rowid 8 → Jaws

After:
rowid 1 → Cars
rowid 2 → Avatar
rowid 3 → Jaws
```

You should therefore **not treat an implicit rowid as a permanent application-level ID**.

With:

```sql
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT
);
```

`id` is an explicit `INTEGER PRIMARY KEY` and is the stable application key.

---

# Why can `VACUUM` require so much disk space?

Suppose your database is:

```text
10 GB
```

During `VACUUM`, SQLite needs to construct the rebuilt database before replacing the original.

The documentation states that, in the worst case, you may need **up to roughly twice the original database size in free disk space**. ([SQLite](https://www2.sqlite.org/lang_vacuum.html?utm_source=chatgpt.com "VACUUM"))

Conceptually:

```text
10 GB old database
+
10 GB temporary/rebuilt database
+
journal/WAL overhead
```

So don't run:

```text
VACUUM;
```

on a nearly-full disk and assume SQLite only needs a tiny amount of extra space.

---

# Why does this make the database smaller?

Suppose:

```text
page size = 4096 bytes

before:
100,000 pages

after VACUUM:
60,000 pages
```

Then:

```text
before
100,000 × 4096
= 409,600,000 bytes

after
60,000 × 4096
= 245,760,000 bytes
```

The logical database contents didn't magically disappear.

SQLite simply found a more compact physical representation.

---

# And this connects directly to what you learned about RAM

During `VACUUM`, SQLite is doing a **lot of page work**:

```text
old database pages
        ↓
read
        ↓
RAM / page cache
        ↓
write new database pages
        ↓
new database
```

There can therefore be substantial:

```text
CPU work
+
disk I/O
+
temporary storage
```

It's much heavier than:

```sql
DELETE FROM movies ...
```

So `VACUUM` is not something you normally run after every delete.

---

## The whole process

Think about it like this:

```text
              OLD DATABASE

       ┌──────────────────────┐
       │ table B-trees         │
       │ index B-trees         │
       │ free pages            │
       │ fragmented pages      │
       └──────────┬───────────┘
                  │
               VACUUM
                  │
                  ▼
       ┌──────────────────────┐
       │ temporary database   │
       │                      │
       │ rebuilt B-trees      │
       │ tightly packed       │
       │ minimal free space   │
       └──────────┬───────────┘
                  │
                  ▼
          replace old database
                  │
                  ▼
              NEW DATABASE
```

So the best mental model is:

> **`VACUUM` is essentially a database-file rebuild/compaction operation, not a simple “delete unused pages” operation.** ([SQLite](https://www2.sqlite.org/lang_vacuum.html?utm_source=chatgpt.com "VACUUM"))

And that's why it can fix both **free space** and **fragmentation** at the same time.

[[SQlite]]