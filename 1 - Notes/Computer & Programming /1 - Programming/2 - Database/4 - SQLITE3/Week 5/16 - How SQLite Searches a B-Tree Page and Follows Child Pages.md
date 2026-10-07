


Suppose SQLite has an index:

```sql
CREATE INDEX title_index ON movies(title);
```

and you run:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

SQLite eventually needs to answer:

> “Where in the B-tree is the key `Cars`?”

The important part is that **it doesn't search every cell on every page**. It navigates from the root downward, choosing one child page at each level.

---

## 1. An interior page is basically a set of separators + child pointers

Imagine an interior page containing:

```text
                 Page 20
        ┌─────────────────────────┐
        │  [Cars] [Jaws] [Matrix] │
        │                         │
        │ P1    P2    P3    P4    │
        └─────────────────────────┘
```

Conceptually, the structure is:

```text
P1   [Cars]   P2   [Jaws]   P3   [Matrix]   P4
```

Meaning:

```text
P1 → keys ≤ Cars
P2 → Cars < keys ≤ Jaws
P3 → Jaws < keys ≤ Matrix
P4 → keys > Matrix
```

That's the critical idea.

SQLite's documentation describes each interior cell as containing a **left-child page pointer + key**, while the right-most child pointer is stored separately in the page header. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

---

# 2. Searching the cells inside that page

Suppose the page has these separator keys:

```text
Cars
Jaws
Matrix
```

and SQLite wants:

```text
Cars
```

It examines the keys in sorted order.

Conceptually:

```text
             [Cars] [Jaws] [Matrix]
                ↑
             target
```

Because:

```text
Cars == Cars
```

SQLite knows which child range to descend into.

If instead the target were:

```text
Ford
```

SQLite compares:

```text
Ford < Jaws
Ford > Cars
```

Therefore:

```text
Cars < Ford < Jaws
```

so it chooses the child between `Cars` and `Jaws`.

```text
P1   [Cars]   P2   [Jaws]   P3   [Matrix]   P4
             ↑
             └── choose P2
```

The exact internal search implementation is optimized, but the logical operation is essentially a search over the page's sorted cell keys to determine the correct child. The cell-pointer array is itself arranged in key order. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

---

# 3. Then SQLite follows the child page

Suppose:

```text
root = page 20
```

and it determines:

```text
Ford belongs in child page 25
```

So:

```text
page 20
   │
   │ child pointer
   ▼
page 25
```

Now page 25 is loaded, and **the exact same process happens again**.

Maybe page 25 contains:

```text
[Ford] [Galaxy] [Harry]
```

SQLite compares `Ford`, chooses another child:

```text
page 25
   │
   ▼
page 41
```

Eventually it reaches a **leaf page**.

```text
20
│
└──25
    │
    └──41
        │
        └──73  ← leaf
```

All children of an interior B-tree page are at the same depth in a well-formed SQLite B-tree. ([SQLite](https://www.sqlite.org/fileformat2.html?utm_source=chatgpt.com "Database File Format"))

---

# 4. What changes when it reaches a leaf?

An interior page answers:

> **Which child page should I visit?**

A leaf page answers:

> **Here are the actual entries.**

For an index B-tree:

```text
leaf page 73

Avatar → rowid 4
Cars   → rowid 17
Cars   → rowid 81
Jaws   → rowid 92
```

SQLite searches this leaf page for `Cars`.

It finds:

```text
Cars → 17
Cars → 81
```

Those are the matching index entries.

Then SQLite can use those rowids to reach the corresponding rows in the table B-tree.

---

# 5. The complete lookup

So your query:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

can conceptually become:

```text
                    query
                      │
                      ▼
                title_index
                      │
                      ▼
                   root
                  page 20
                      │
             compare separator keys
                      │
                      ▼
                  child page 25
                      │
             compare separator keys
                      │
                      ▼
                  child page 41
                      │
             compare/search keys
                      │
                      ▼
                  leaf page 73
                      │
                 find "Cars"
                  /       \
                 /         \
          rowid 17       rowid 81
             │               │
             ▼               ▼
        movies table B-tree
```

That's the physical journey.

---

# 6. Where does the actual child page number live?

This ties directly into your previous question about cells.

For an **interior table B-tree cell**, SQLite stores:

```text
4-byte left child page number
+
key
```

For an **interior index B-tree cell**, it stores:

```text
4-byte left child page number
+
key payload
```

The **right-most child** isn't inside the last cell; its page number is stored in the B-tree page header. ([SQLite](https://sqlite.org/fileformat.html?utm_source=chatgpt.com "Database File Format"))

So conceptually:

```text
cell 1:
    left child = page 25
    key = Cars

cell 2:
    left child = page 41
    key = Jaws

cell 3:
    left child = page 60
    key = Matrix

header:
    right child = page 80
```

Which gives:

```text
page 25  → keys ≤ Cars
page 41  → Cars < keys ≤ Jaws
page 60  → Jaws < keys ≤ Matrix
page 80  → keys > Matrix
```

---

# 7. What is the cell pointer doing here?

Remember from the previous lesson:

```text
cell pointer array
```

contains offsets such as:

```text
[310] [270] [190] [120]
```

These aren't child page numbers.

They're:

> **Where is the actual cell located inside this page?**

So there are two different pointers involved:

```text
CELL POINTER
────────────
page-local offset

"Go to byte 310 on this page."
```

versus:

```text
CHILD POINTER
─────────────
database page number

"Go to page 41 of the database."
```

That distinction is extremely important.

```text
Interior page
│
├── cell pointer
│      ↓
│   actual cell
│      │
│      └── child page number
│
└── right-most child page number in header
```

---

# 8. Now bring RAM into it

Suppose the tree traversal is:

```text
page 20
   ↓
page 25
   ↓
page 41
   ↓
page 73
```

SQLite needs those pages.

For each one, it effectively asks the pager/cache:

```text
Is page 20 already available?
```

If yes:

```text
RAM/cache → use it
```

If not:

```text
database file → read page → RAM/cache
```

Then:

```text
page 20 → choose 25
page 25 → choose 41
page 41 → choose 73
page 73 → find Cars
```

So the CPU is comparing keys in **memory-resident page data**, while SQLite's pager handles getting the required pages into memory.

---

# 9. Why B-trees stay shallow

This entire process is fast because one page contains **many keys and therefore many possible children**.

Imagine:

```text
root
 ├── child 1
 ├── child 2
 ├── child 3
 ├── ...
 └── child 200
```

Then every child can have another ~200 children.

Even with a rough branching factor of 200:

```text
200 × 200 × 200 = 8,000,000
```

So millions of entries can fit in a tree only a few levels deep.

That's why the query isn't:

```text
read 1,000,000 rows
```

It is more like:

```text
read a few pages
    ↓
make a few comparisons
    ↓
find target
```

The exact number depends on page size, key size, tree shape, and data distribution, but the principle is the same.

---

## The mental model

At this point, you should visualize an SQLite B-tree lookup like this:

```text
                  ROOT PAGE
                     │
        ┌────────────┼────────────┐
        │            │            │
      keys         keys         keys
        │
        ▼
   choose child
        │
        ▼
   INTERIOR PAGE
        │
   compare keys
        │
        ▼
   choose child
        │
        ▼
    LEAF PAGE
        │
    find key
        │
        ▼
   rowid / result
```

And remember the two pointer types:

```text
cell pointer  = where is the cell inside this page?
child pointer = which database page do I go to next?
```

That distinction is the bridge between understanding a B-tree **conceptually** and understanding SQLite's actual on-disk implementation.



[[SQlite]]