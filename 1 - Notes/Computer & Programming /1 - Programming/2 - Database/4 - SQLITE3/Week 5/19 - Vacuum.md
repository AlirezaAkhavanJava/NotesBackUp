
# `VACUUM` in SQLite

`VACUUM` **rebuilds the SQLite database file from scratch** into a new, compact database file.

Its main purpose is to **reclaim unused space and reorganize the database file** after operations such as large deletes.

For example:

```sql
DELETE FROM movies
WHERE year < 1980;
```

You might think the database file should immediately become smaller.

Usually, it doesn't.

SQLite can mark the pages that contained those rows as free and reuse them later:

```text
Before:

[used][used][used][used][used]
                         ↓ DELETE
[used][used][free][free][used]
```

The file can remain the same physical size.

Then:

```sql
VACUUM;
```

SQLite rebuilds the database:

```text
Before:
[used][used][free][free][used]

VACUUM

After:
[used][used][used]
```

So the database file itself can become smaller.

### What `VACUUM` actually does

Conceptually:

```text
existing database
       ↓
read the database
       ↓
create a new compact database
       ↓
copy tables + indexes + data
       ↓
rebuild the database structure
       ↓
replace old file
```

This is why `VACUUM` can be relatively expensive: **SQLite is effectively rewriting the database**.

You can run it simply:

```sql
VACUUM;
```

You can also vacuum a specific attached database:

```sql
VACUUM main;
```

### Important distinction

`VACUUM` is **not an index optimizer command**.

It does not mean:

```text
"make my queries faster"
```

It primarily means:

```text
"rebuild and compact my database file"
```

It can improve some I/O characteristics because the rebuilt file is compact and reorganized, but you should not use `VACUUM` as a normal query-performance fix.

### One thing particularly relevant to what we just learned

When you delete rows, SQLite may leave free pages behind:

```text
database file

page 1  → used
page 2  → used
page 3  → FREE
page 4  → FREE
page 5  → used
```

Those pages can be reused by future writes.

`VACUUM` takes that fragmented/free-space situation and creates a new compact database without those unnecessary pages.

You can see how much free space exists with:

```sql
PRAGMA freelist_count;
```

That tells you how many pages are currently on SQLite's freelist.

So the relationship is:

```text
DELETE
  ↓
pages become reusable
  ↓
file may stay same size

VACUUM
  ↓
rebuild database
  ↓
remove unused space from file
```




[[SQlite]]