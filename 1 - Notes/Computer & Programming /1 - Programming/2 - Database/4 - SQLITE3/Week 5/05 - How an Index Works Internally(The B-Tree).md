

## 1. Definition

A **B-tree** is a tree-shaped data structure where every node holds many sorted keys, and each node is sized to fit exactly one **page** of the database file. SQLite stores every index as a B-tree.

Three terms you need first:

- **Page**: SQLite's database file is split into fixed-size blocks called pages. The default is 4096 bytes. SQLite always reads and writes whole pages, never single rows. Check yours with `PRAGMA page_size;`.
- **Node**: one page of the B-tree. It holds a sorted list of entries.
- **Fan-out**: how many children a node can point to. In SQLite, one page can hold hundreds of entries, so fan-out is high.

One precision point: SQLite stores _tables_ as B+trees keyed by `rowid`, with row data only in the leaf pages. _Indexes_ are B-trees keyed by the indexed column values, with the `rowid` appended to every entry.

## 2. Why it exists: the problem it solves

Storage is read in pages, and every page read is expensive compared to work done in memory. So the real cost of a search is **how many pages you must read**, not how many comparisons you make.

Compare the alternatives:

|Structure|Problem|
|---|---|
|Unsorted rows (table scan)|Must read every page. Cost grows linearly with table size.|
|Sorted array + binary search|Fast to search, but inserting a value in the middle means shifting everything after it.|
|Binary tree|Each node holds 1 key, so the tree is very deep (about 20 levels for a million keys). Each level is a separate page read.|
|**B-tree**|Each node holds hundreds of keys, so the tree is very shallow (about 3 levels for millions of keys), and inserts only touch a few pages.|

The B-tree exists to **minimize page reads while keeping inserts cheap**.

## 3. What one index entry looks like

For this index:

```sql
CREATE INDEX idx_users_city_name ON users (city, name);
```

each entry is a tuple: `(city, name, rowid)`. The entries are kept sorted by `city`, then `name`, then `rowid` as a tiebreaker.

Given this table data:

|rowid|city|name|
|---|---|---|
|1|Tehran|Ali|
|2|Shiraz|Sara|
|3|Tehran|Omid|
|4|Tabriz|Reza|
|5|Shiraz|Nima|

the index contains, **in sorted order**:

```
(Shiraz, Nima, 5)
(Shiraz, Sara, 2)
(Tabriz, Reza, 4)
(Tehran, Ali, 1)
(Tehran, Omid, 3)
```

Keep this sorted list in mind. Every rule from the previous lesson comes from it.

## 4. The structure, drawn

A small B-tree with a root page and three leaf pages:

```
                    ┌─────────────────────────┐
         ROOT PAGE  │   "Shiraz,Sara"  "Tabriz,Reza"  │
                    └───┬──────────┬──────────┬───────┘
                        │          │          │
              ┌─────────┘          │          └──────────┐
              ▼                    ▼                     ▼
      ┌──────────────┐    ┌──────────────┐     ┌──────────────────┐
      │ (Shiraz,Nima,5)│   │(Tabriz,Reza,4)│    │ (Tehran,Ali,1)   │
      │               │    │              │     │ (Tehran,Omid,3)  │
      └──────────────┘    └──────────────┘     └──────────────────┘
        keys < Shiraz,Sara   between the two      keys > Tabriz,Reza
```

The root holds **separator keys** that divide the key space. Each pointer leads to a page containing only keys in that range. Real pages hold hundreds of entries, not two or three, but the shape is the same.

## 5. How a lookup works, step by step

Query:

```sql
SELECT * FROM users WHERE city = 'Tehran' AND name = 'Omid';
```

1. **Read the root page** (1 page read). Compare `(Tehran, Omid)` against the separators. It is greater than `(Tabriz, Reza)`, so follow the rightmost pointer.
2. **Read the leaf page** (1 page read). Scan its sorted entries and find `(Tehran, Omid, 3)`.
3. **Take the rowid, 3**, and search the _table's_ B+tree for rowid 3 (a few more page reads). This returns the full row.

So an index lookup is really **two B-tree searches**: one in the index to find the rowid, one in the table to fetch the row. This second step is called a **table lookup** (or "bookmark lookup"), and it explains the covering index idea in section 8.

## 6. The math: why the tree stays shallow

Assume a 4096-byte page and index entries of roughly 20 bytes. One page holds on the order of 200 entries, so fan-out is about 200.

|Tree depth|Approximate rows reachable|
|---|---|
|1 level|200|
|2 levels|200 × 200 = 40,000|
|3 levels|200³ = 8,000,000|
|4 levels|200⁴ = 1,600,000,000|

So finding one row among **8 million** takes about **3 page reads**. A full scan of the same table would read thousands of pages. Real numbers vary with the size of your keys (long text keys mean fewer entries per page and a deeper tree), but the principle holds: depth grows with the _logarithm_ of row count, base roughly 200.

This also explains a practical rule: **smaller keys make better indexes**. More entries fit per page, so the tree is shallower and more of it fits in memory cache.

## 7. How inserts keep the tree balanced

When you run `INSERT`, SQLite must add an entry to **every index** on the table:

1. Search down the tree to find the correct leaf page for the new key (same as a lookup).
2. If the leaf has room, insert the entry in sorted position. Done.
3. If the leaf is **full**, SQLite performs a **page split**: it allocates a new page, moves about half the entries into it, and adds a new separator key to the parent.
4. If the parent is also full, it splits too, and this can propagate up to the root. If the root splits, the tree grows one level taller.

Because splits happen from the bottom up, **all leaves always stay at the same depth**. That is what "balanced" means, and it guarantees every lookup costs the same number of page reads.

This is the concrete reason rule 10 from the previous lesson exists: each extra index means an extra tree to search and possibly split on every write. `UPDATE` is similar: changing an indexed column means removing the old entry and inserting a new one in a different position.

## 8. Why the rules you learned follow from this structure

Now you can derive them instead of memorizing them.

**Leftmost prefix rule.** The index `(city, name)` is sorted by city first. Look back at the sorted list in section 3:

```
(Shiraz, Nima, 5)
(Shiraz, Sara, 2)
(Tabriz, Reza, 4)
(Tehran, Ali, 1)
(Tehran, Omid, 3)
```

All `Tehran` entries sit together, so SQLite can jump to them. But the name `Omid` could be anywhere, because names are only sorted _within_ each city. A query on `name` alone has no way to navigate the tree, so it cannot use the index efficiently.

**Function on a column breaks the index.** The tree is sorted by the raw stored value. `WHERE lower(email) = 'x'` asks for the _output of a function_, and the sorted order of raw values says nothing about the sorted order of lowercased values. An expression index fixes this by storing the function's results, sorted.

**`LIKE 'abc%'` can use an index, `LIKE '%abc'` cannot.** A prefix like `abc%` is a _range_ (everything from `abc` up to just before `abd`), and a range is a contiguous slice of a sorted tree. A leading wildcard has no starting point to navigate to. (SQLite also requires specific collation conditions for `LIKE` optimization, which is a topic for later.)

**`ORDER BY` is free.** Walking the index entries in order _is_ sorted output. No separate sort step is needed.

**Range queries work.** `WHERE city BETWEEN 'Shiraz' AND 'Tabriz'` finds the first matching entry via tree descent, then reads forward through consecutive entries until the range ends.

### Covering indexes: skipping the second search

Recall step 3 in section 5: after finding the rowid, SQLite searches the table too. If the index already contains **every column the query needs**, SQLite can skip that table lookup entirely. That is called a **covering index**.

```sql
CREATE INDEX idx_users_city_email ON users (city, email);

EXPLAIN QUERY PLAN
SELECT email FROM users WHERE city = 'Tehran';
```

Output:

```
SEARCH users USING COVERING INDEX idx_users_city_email (city=?)
```

**What this does:** `city` is used to navigate the tree, and `email` is already stored in the entries, so the answer comes straight from the index. The word `COVERING` in the plan confirms the table was never touched. If you instead ran `SELECT name FROM users WHERE city = 'Tehran'`, `name` is not in the index, so SQLite would do the table lookup for each match, and the plan would not say `COVERING`.

## 9. Try it yourself in your terminal

Open `sqlite3` and build a table with 200,000 rows so the difference is measurable:

```sql
CREATE TABLE people (
    id    INTEGER PRIMARY KEY,
    email TEXT,
    city  TEXT
);

WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 200000
)
INSERT INTO people (email, city)
SELECT 'user' || n || '@example.com',
       CASE n % 3 WHEN 0 THEN 'Tehran' WHEN 1 THEN 'Shiraz' ELSE 'Tabriz' END
FROM seq;
```

**What this does:** the `WITH RECURSIVE` part generates the numbers 1 to 200000 as a temporary sequence. The `INSERT ... SELECT` turns each number into a row with a unique email and one of three cities.

Now measure a search without an index:

```sql
.timer on
EXPLAIN QUERY PLAN SELECT * FROM people WHERE email = 'user150000@example.com';
SELECT * FROM people WHERE email = 'user150000@example.com';
```

**What this does:** `.timer on` prints how long each statement takes. The plan will show `SCAN people`, and the query reads the whole table.

Create the index and run the same thing again:

```sql
CREATE INDEX idx_people_email ON people (email);

EXPLAIN QUERY PLAN SELECT * FROM people WHERE email = 'user150000@example.com';
SELECT * FROM people WHERE email = 'user150000@example.com';
```

**What this does:** the plan now shows `SEARCH people USING INDEX idx_people_email (email=?)`, and the time drops sharply. Exact timings depend on your machine, but the gap should be obvious.

Then look at the physical side:

```sql
PRAGMA page_size;
PRAGMA page_count;
```

**What this does:** `page_size` is the size of each B-tree node in bytes. `page_count` is how many pages the whole file has, including table and index pages. Run `PRAGMA page_count;` before and after creating the index and you will see the file grow: that growth is the index's storage cost.

## 10. Summary

- An index is a **B-tree of pages**, with entries `(indexed columns..., rowid)` kept sorted.
- High fan-out keeps the tree shallow, so a search costs about 3 to 4 page reads even for millions of rows.
- Inserts find the right leaf and **split pages** when full, which keeps the tree balanced and explains the write cost of indexes.
- Almost every indexing rule (leftmost prefix, functions breaking indexes, `LIKE` prefixes, free `ORDER BY`) follows directly from "the entries are sorted in this exact order".
- A **covering index** avoids the second search into the table.

---





[[SQlite]]