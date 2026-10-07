

A **B-tree** is a balanced search tree designed so that each node can contain **many keys**, not just one. Databases use it because it minimizes the number of storage pages they need to read to find data.

For SQLite, the important thing is:

> **The B-tree lives in the database file. RAM holds pages of that B-tree temporarily while SQLite is using them.**

The whole B-tree is **not normally loaded into RAM**.

---

## Start with the structure

Imagine an index:

```sql
CREATE INDEX title_index ON movies(title);
```

SQLite stores that index as a B-tree.

Conceptually:

```text
                 [Jaws, Matrix]
                /       |       \
               /        |        \
      [Avatar, Cars] [Jaws] [Matrix, ...]
```

But this picture is simplified.

A real SQLite B-tree node is based on a **database page**, for example a 4096-byte page.

A page can contain many entries:

```text
┌──────────────────────────────────────┐
│ page header                          │
├──────────────────────────────────────┤
│ cell pointer 1                       │
│ cell pointer 2                       │
│ cell pointer 3                       │
│ ...                                  │
├──────────────────────────────────────┤
│ cells containing keys / payload      │
└──────────────────────────────────────┘
```

So instead of:

```text
one node = one key
```

you get something closer to:

```text
one node/page = hundreds of keys
```

depending on key size and page size.

That's why database B-trees are usually **very shallow**.

---

# Why does that make searching fast?

Suppose you have 1,000,000 rows.

A binary tree might need roughly:

```text
log₂(1,000,000) ≈ 20
```

comparisons.

A database B-tree can have a huge branching factor.

For example, if one page can effectively branch to 200 children:

```text
200 × 200 × 200
= 8,000,000
```

So something like:

```text
root
 ↓
level 1
 ↓
level 2
 ↓
leaf
```

can already cover millions of entries.

That means finding something like:

```text
title = 'Cars'
```

may require only a few page accesses.

---

# What does SQLite actually store in those B-tree entries?

For a normal index:

```sql
CREATE INDEX title_index ON movies(title);
```

an index entry is conceptually:

```text
(title, rowid)
```

So:

```text
("Avatar", 12)
("Cars", 15)
("Cars", 83)
("Jaws", 44)
```

The index is sorted by the indexed key.

That lets SQLite navigate:

```text
find "Cars"
    ↓
locate the correct B-tree page
    ↓
locate the correct cells
    ↓
get rowids
```

Then the rowid can be used to access the table's B-tree.

---

# Now the important RAM question

Suppose your database is:

```text
2 GB
```

and your RAM is:

```text
16 GB
```

SQLite does **not** simply do:

```text
load entire 2 GB database into RAM
```

Instead, SQLite works with **pages**.

Think of:

```text
Database file
─────────────────────────────
page 1
page 2
page 3
page 4
...
page 500,000
```

SQLite maintains a cache of pages in memory.

Conceptually:

```text
               DATABASE FILE
                    │
             read required page
                    ↓
              SQLite pager
                    ↓
                page cache
                    ↓
                  RAM
```

So if SQLite needs page 42:

```text
page 42
   ↓
is it already cached?
   ├── YES → use RAM copy
   └── NO  → read from storage → put in cache
```

This is where a huge amount of the practical performance difference comes from.

---

# Walk through an actual lookup

Suppose:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

SQLite chooses:

```text
title_index
```

The index B-tree might look conceptually like:

```text
              page 100
             [M, T]
            /      \
           /        \
     page 101      page 150
 [Avatar...Jaws] [Matrix...]
```

SQLite needs to find `"Cars"`.

### Step 1

Read page 100.

If page 100 is already in RAM:

```text
RAM
└── page 100
```

No storage read is necessary.

If not:

```text
SSD
 ↓
page 100
 ↓
RAM
```

### Step 2

The root tells SQLite:

```text
"Cars belongs in the child range represented by page 101"
```

So SQLite needs page 101.

Again:

```text
cache?
 ├── yes → use RAM
 └── no  → read page 101
```

### Step 3

Page 101 contains the relevant index entries:

```text
Cars → rowid 15
Cars → rowid 83
```

Now SQLite knows which rows to retrieve.

Then it accesses the **table B-tree**:

```text
rowid 15 → movie row
rowid 83 → movie row
```

So an indexed query might involve only a handful of database pages.

---

# This is why RAM can make repeated queries insanely fast

Imagine the relevant pages are already cached:

```text
RAM
├── index root
├── index internal page
├── index leaf
├── table page
└── another table page
```

The next identical query may be able to traverse those pages directly from RAM.

No SSD access for those pages.

So:

```text
First query
storage → RAM → CPU

Later query
RAM → CPU
```

That difference can be enormous.

---

# But there are actually multiple layers of caching

This is where it gets interesting.

Your data may travel through something like:

```text
CPU
 ↓
RAM
 ↓
OS page cache
 ↓
SQLite pager/cache
 ↓
filesystem
 ↓
SSD
```

The exact behavior depends on SQLite configuration and the I/O path, but the important concept is:

> There can be caching at more than one level.

SQLite has its own **page cache**, and the operating system also manages file pages through virtual memory/page-cache mechanisms.

So don't think:

```text
SQLite = directly reading SSD every time
```

That's far too simplistic.

---

# RAM doesn't understand "B-tree"

Another important distinction:

RAM itself doesn't know:

```text
"This is a B-tree."
```

RAM is just memory addresses containing bytes.

SQLite interprets some bytes as:

```text
page header
cell pointers
keys
rowids
payload
```

So:

```text
RAM
└── raw bytes

SQLite
└── interprets those bytes as B-tree pages
```

This is similar to a file:

```text
disk → bytes
program → interprets bytes as objects/data structures
```

---

# What happens when you INSERT?

This is where B-trees become especially interesting.

Suppose a leaf page is full:

```text
page 200

[Avatar]
[Cars]
[Ford]
[Jaws]
[Matrix]
[...]
FULL
```

You insert another key and there's no room.

SQLite may need a **page split**.

Conceptually:

```text
Before:

        page 200
 [Avatar Cars Ford Jaws Matrix]


After:

           parent
          /      \
       page 200  page 201
      [Avatar]  [Jaws Matrix]
      [Cars]    [Ford]
```

The exact structure is more complicated, but the idea is:

```text
full page
   ↓
split
   ↓
new page
   ↓
update parent
```

Now RAM may contain:

```text
page 200   ← modified
page 201   ← new/modified
parent     ← modified
```

Those are **dirty pages**.

Eventually SQLite must persist the changes according to its transaction/journaling mechanism.

---

# What does "dirty page" mean?

A **dirty page** is simply:

> A database page in memory whose contents differ from the version currently persisted on storage.

For example:

```text
SSD:
page 200 = old data

RAM:
page 200 = modified data
```

RAM is newer.

SQLite cannot just forget that page.

It needs to safely commit it according to the transaction mechanism.

With SQLite's journaling/WAL modes, the exact persistence path differs, which is one of the reasons SQLite's pager and locking architecture exist.

---

# Why B-trees are good for disks

This is probably the most important reason databases use B-trees rather than ordinary binary search trees.

A disk/SSD has much higher access cost than a CPU register or RAM access.

You therefore want:

```text
few storage/page accesses
```

A B-tree is designed to make each node large enough to correspond well to a storage page.

So instead of:

```text
read one tiny node
read another tiny node
read another tiny node
read another tiny node
...
```

you can do:

```text
read one page containing lots of keys
read another page containing lots of keys
read leaf page
```

That gives you:

```text
high branching factor
+
few tree levels
+
page-oriented storage
=
efficient database lookup
```

---

# Now connect this back to indexes

This is why your earlier question about:

```sql
CREATE INDEX title_index ON movies(title);
```

is much more powerful than the syntax makes it look.

You wrote one simple line.

SQLite did conceptually a lot of work:

```text
CREATE INDEX
     ↓
build sorted B-tree
     ↓
allocate database pages
     ↓
store index entries
     ↓
record metadata in sqlite_schema
     ↓
maintain this B-tree on future writes
```

Then a query:

```sql
WHERE title = 'Cars'
```

can become:

```text
SQL
 ↓
query planner
 ↓
title_index
 ↓
B-tree traversal
 ↓
few pages
 ↓
RAM cache / storage
 ↓
rowids
 ↓
table B-tree
 ↓
result
```

---

# The mental model I want you to keep

Don't think:

> “An index is a list stored in RAM.”

Think:

> **An SQLite index is a B-tree persisted in database pages. RAM temporarily holds the pages SQLite needs to work with.**

And:

```text
              DISK / SSD
        ┌─────────────────────┐
        │ database pages      │
        │                     │
        │ table B-tree        │
        │ index B-tree        │
        └──────────┬──────────┘
                   │
                load page
                   ↓
                  RAM
        ┌─────────────────────┐
        │ SQLite page cache   │
        │                     │
        │ page 100            │
        │ page 101            │
        │ page 200            │
        └──────────┬──────────┘
                   ↓
                  CPU
                   ↓
          traverse B-tree
```

That is the connection between **index → B-tree → pages → RAM → CPU**.





[[SQlite]]