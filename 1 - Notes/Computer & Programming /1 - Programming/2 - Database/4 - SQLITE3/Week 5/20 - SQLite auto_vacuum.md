
# SQLite `auto_vacuum`

`auto_vacuum` is a SQLite database setting that controls what happens to database pages that become unused after deletes.

The important difference from `VACUUM` is:

```text
VACUUM
→ you explicitly rebuild the database

auto_vacuum
→ SQLite automatically manages/reclaims pages during normal operation
```

There are **three modes**:

```text
NONE
FULL
INCREMENTAL
```

## `NONE` — the default

With:

```sql
PRAGMA auto_vacuum = NONE;
```

when you delete rows:

```sql
DELETE FROM movies
WHERE year < 1980;
```

SQLite can free the pages for reuse, but it doesn't automatically shrink the database file.

Example:

```text
database file

page 1  used
page 2  used
page 3  FREE
page 4  FREE
page 5  used
```

The file can still occupy all five pages.

Later inserts can reuse pages 3 and 4.

This is basically:

```text
DELETE
  ↓
page becomes reusable
  ↓
file size stays roughly the same
```

---

# `FULL`

With:

```sql
PRAGMA auto_vacuum = FULL;
```

SQLite attempts to move free pages toward the end of the database and truncate the file when transactions commit.

So:

```text
Before:

[used][used][FREE][used][FREE][FREE]

               ↓

After commit:

[used][used][used]
```

The database file can shrink automatically.

But there's a trade-off.

SQLite may need to **move pages around** during writes so that free pages can be removed from the end.

So you're effectively exchanging:

```text
automatic space reclamation
```

for:

```text
additional work during writes
```

That's why `FULL` isn't simply "better."

---

# `INCREMENTAL`

This is a middle ground.

```sql
PRAGMA auto_vacuum = INCREMENTAL;
```

SQLite keeps track of reclaimable pages, but doesn't automatically compact them at every commit.

You explicitly tell it to perform incremental vacuuming:

```sql
PRAGMA incremental_vacuum;
```

or specify the number of pages:

```sql
PRAGMA incremental_vacuum(100);
```

Conceptually:

```text
DELETE
  ↓
free pages accumulate
  ↓
database doesn't fully shrink yet
  ↓
incremental_vacuum(...)
  ↓
reclaim some/all possible space
```

This gives you more control over when the cleanup cost happens.

---

# The important difference from `VACUUM`

This distinction is worth remembering:

```text
VACUUM
```

does a **complete rebuild**.

```text
auto_vacuum
```

changes how SQLite handles free pages as the database operates.

So:

```text
             VACUUM
                │
       explicit full rebuild
                │
                ▼
       compact database


          auto_vacuum
                │
       normal DB operation
                │
       ┌────────┼────────┐
       ▼        ▼        ▼
      NONE     FULL   INCREMENTAL
```

---

# One very important limitation

You generally **cannot simply turn `auto_vacuum` on for an existing database and expect everything to magically reorganize**.

For an existing database, changing from `NONE` to `FULL` or `INCREMENTAL` requires the database to be rebuilt, typically by running:

```sql
PRAGMA auto_vacuum = FULL;
VACUUM;
```

The setting must be established before the rebuild so SQLite can restructure the database appropriately.

You can inspect the current mode with:

```sql
PRAGMA auto_vacuum;
```

Typical values are:

```text
0 = NONE
1 = FULL
2 = INCREMENTAL
```

---

# What should you actually use?

For most SQLite databases, you should **not enable `FULL` just because it sounds cleaner**.

A practical way to think about it:

```text
NONE
→ simplest
→ deleted space can be reused
→ database won't automatically shrink

FULL
→ automatically tries to shrink
→ extra write overhead

INCREMENTAL
→ automatic tracking
→ you choose when to reclaim space
```

For a database that frequently deletes large amounts of data and where **physical file size matters**, `FULL` or `INCREMENTAL` can be useful.

For a database where writes should stay as simple/cheap as possible and reusing freed pages is fine, `NONE` is often perfectly reasonable.





[[SQlite]]