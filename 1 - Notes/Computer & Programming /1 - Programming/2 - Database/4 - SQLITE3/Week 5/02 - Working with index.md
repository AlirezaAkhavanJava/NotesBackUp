
# Lesson: Working with Indexes in SQLite

I'll teach this in order, from the idea to the tools to the mistakes. Run the examples yourself as you read.

---

## Part 1: The core idea

**Definition:** An index is a separate, sorted structure that stores the values of one or more columns, each paired with the location of its row, so SQLite can find rows without scanning the whole table.

**Analogy: a library**

|Library|SQLite|
|---|---|
|The shelves of books|The table|
|A book|A row|
|The card catalog (sorted by author)|An index|
|The shelf location written on the card|The `rowid` stored in the index|
|Walking every aisle to find a book|Full table scan (`SCAN`)|
|Using the catalog, then going to the shelf|Index search (`SEARCH`)|

The catalog doesn't contain the books. It only helps you find them faster. Likewise, an index never replaces the table.

---

## Part 2: The components of an index

**1. The table.** The real data. Every row has a hidden number called the `rowid`.

**2. The index key.** The column value(s) the index is sorted by, for example `email`.

**3. The rowid pointer.** Each index entry stores the key plus the `rowid` of the matching table row.

**4. The B-tree.** The tree structure that keeps the entries sorted so SQLite can jump to the right spot quickly:

- **Root:** the entry point
- **Branches:** guide the search ("go left or right?")
- **Leaves:** hold the actual key and rowid entries

Here is what an index on `city` looks like conceptually:

```
Index (sorted by city)          Table (by rowid)
-----------------------         ----------------------
Berlin   -> rowid 7             1 | Ali    | London
London   -> rowid 1             2 | Sara   | Paris
London   -> rowid 5             ...
Paris    -> rowid 2             7 | Hans   | Berlin
```

**How a lookup works:**

1. Search the index for `London` (fast, because it's sorted).
2. Read the rowids it finds (1 and 5).
3. Fetch those rows from the table.

---

## Part 3: Set up a practice table

```sql
CREATE TABLE users (
  id      INTEGER PRIMARY KEY,
  name    TEXT,
  email   TEXT,
  city    TEXT,
  age     INTEGER,
  active  INTEGER
);

INSERT INTO users (name, email, city, age, active) VALUES
 ('Ali',  'ali@mail.com',  'London', 30, 1),
 ('Sara', 'sara@mail.com', 'Paris',  25, 1),
 ('Hans', 'hans@mail.com', 'Berlin', 41, 0),
 ('Mia',  'mia@mail.com',  'London', 35, 1);
```

---

## Part 4: Create your first index

**Syntax:**

```sql
CREATE INDEX index_name ON table_name (column);
```

**Example:**

```sql
CREATE INDEX idx_users_email ON users (email);
```

**Naming convention:** `idx_<table>_<column>`. It keeps things readable when you have many.

**Remove it:**

```sql
DROP INDEX idx_users_email;
```

**Safe versions** (won't error if it already exists or is missing):

```sql
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
DROP INDEX IF EXISTS idx_users_email;
```

---

## Part 5: Check that it's being used

Creating an index doesn't guarantee SQLite uses it. Always verify with `EXPLAIN QUERY PLAN`.

```sql
EXPLAIN QUERY PLAN
SELECT * FROM users WHERE email = 'ali@mail.com';
```

**How to read the result:**

|Output|Meaning|
|---|---|
|`SCAN users`|Reading every row (slow on big tables)|
|`SEARCH users USING INDEX idx_users_email (email=?)`|Using the index (good)|
|`SEARCH users USING INTEGER PRIMARY KEY (rowid=?)`|Using the primary key (the fastest)|
|`USING COVERING INDEX ...`|Answered entirely from the index (best)|

**Tip:** make `EXPLAIN QUERY PLAN` a habit. It's how you check your work before you think a query is optimized.

---

## Part 6: Types of indexes

### 6.1 The built-in index: `INTEGER PRIMARY KEY`

```sql
id INTEGER PRIMARY KEY
```

This column is an alias for the `rowid`, so it needs no separate index. Lookups by `id` are the fastest in SQLite.

> If a primary key is another type (like `TEXT`), SQLite builds an automatic index for it, named something like `sqlite_autoindex_...`.

### 6.2 Single-column index

Indexes one column.

```sql
CREATE INDEX idx_users_city ON users (city);
```

Good for: `WHERE city = 'London'`

### 6.3 Unique index

Speeds up lookups and **forbids duplicates**.

```sql
CREATE UNIQUE INDEX idx_users_email_unique ON users (email);
```

Now inserting a second `ali@mail.com` fails with a constraint error. Declaring a column `UNIQUE` does this automatically.

### 6.4 Composite (multi-column) index

Indexes **several columns together**, sorted by the first, then the second, and so on.

```sql
CREATE INDEX idx_users_city_age ON users (city, age);
```

**Analogy:** a phone book sorted by last name, then by first name. Sorting within the same last name is useful, but the book is no help if you only know a first name.

**The Leftmost Prefix Rule** (the most important rule about composite indexes):

An index on `(city, age)` can be used for:

|Query|Uses index?|
|---|---|
|`WHERE city = 'London'`|Yes|
|`WHERE city = 'London' AND age = 30`|Yes (best)|
|`WHERE age = 30`|No, it skips the first column|

The index works from the left. You can't skip the first column.

**Column order matters.** A good rule: put columns tested with `=` first, then range columns (`>`, `<`, `BETWEEN`) last.

### 6.5 Covering index

If the index contains **every column the query needs**, SQLite never touches the table.

```sql
CREATE INDEX idx_users_city_name ON users (city, name);

EXPLAIN QUERY PLAN
SELECT name FROM users WHERE city = 'London';
-- SEARCH users USING COVERING INDEX idx_users_city_name (city=?)
```

**Analogy:** the catalog card already has the answer on it, so you never walk to the shelf.

### 6.6 Partial index

Indexes **only some rows**, using a `WHERE` clause. It's smaller and faster.

```sql
CREATE INDEX idx_users_active_email ON users (email) WHERE active = 1;
```

Great when you mostly query a subset, like active users. The query must include the same condition (`active = 1`) for SQLite to use it.

### 6.7 Expression index

Indexes the **result of a calculation**, so function-based searches can be fast.

```sql
CREATE INDEX idx_users_lower_email ON users (LOWER(email));

SELECT * FROM users WHERE LOWER(email) = 'ali@mail.com';  -- uses the index
```

The query's expression must match the index's expression exactly.

### 6.8 Descending order index

```sql
CREATE INDEX idx_users_age_desc ON users (age DESC);
```

Useful for `ORDER BY age DESC`. SQLite can also read a normal index backwards, so this is rarely required.

---

## Part 7: Indexes and sorting

An index is already sorted, so it can eliminate expensive sorting.

```sql
EXPLAIN QUERY PLAN
SELECT * FROM users ORDER BY age;
```

- Without an index on `age`: you'll see `USE TEMP B-TREE FOR ORDER BY`. SQLite is sorting everything in temporary storage.
- With `CREATE INDEX idx_users_age ON users (age);` that line disappears, because the data is already in order.

---

## Part 8: Keeping the index smart: `ANALYZE`

SQLite decides whether to use an index based on statistics about your data. Update them with:

```sql
ANALYZE;
```

Run it after loading or changing a lot of data. It helps SQLite choose well between indexes. If an index ever becomes corrupted, `REINDEX idx_users_city;` rebuilds it.

---

## Part 9: What to index, and what not to

**Index these:**

- Columns in `WHERE` filters you run often
- Columns used in `JOIN ... ON` (especially foreign keys)
- Columns in `ORDER BY` or `GROUP BY`
- Columns with **many distinct values** (email, user_id, date)

**Avoid or reconsider:**

- Tiny tables (a scan is already instant)
- Columns with few distinct values, like `active` (0/1), unless you use a partial index
- Columns that are rarely queried
- Tables with **heavy writes** and few reads

**The trade-off, always:**

|Gain|Price|
|---|---|
|Faster `SELECT`|Slower `INSERT`/`UPDATE`/`DELETE`|
||More disk space|

Every index must be updated each time the table changes. Ten indexes mean ten extra updates per write.

---

## Part 10: Common mistakes that kill index use

```sql
-- 1. Function on the column (without an expression index)
WHERE LOWER(email) = 'ali@mail.com'

-- 2. Leading wildcard
WHERE email LIKE '%@mail.com'

-- 3. Skipping the first column of a composite index
-- index (city, age):  WHERE age = 30

-- 4. Math on the column
WHERE age + 1 = 31      -- better: WHERE age = 30

-- 5. Type mismatch
WHERE id = '5'          -- compare numbers to numbers
```

In each case, SQLite falls back to `SCAN`. Check with `EXPLAIN QUERY PLAN` whenever a query feels slower than expected.

---

## Part 11: The workflow to follow

1. **Find a slow or growing query.**
2. Run `EXPLAIN QUERY PLAN` on it. Is it `SCAN`?
3. **Create an index** on the filtered, joined, or sorted columns.
4. Run `EXPLAIN QUERY PLAN` again. Now is it `SEARCH`?
5. **Time it** on realistic data sizes.
6. Run `ANALYZE`, and drop indexes that nothing uses.

To list the indexes on a table:

```sql
PRAGMA index_list('users');
PRAGMA index_info('idx_users_city_age');
```

---

## Part 12: Your practice exercises

Try these on the `users` table:

1. Create an index on `city`, then compare `EXPLAIN QUERY PLAN` for `WHERE city = 'Paris'` before and after.
2. Create a composite index on `(city, age)`. Test the plan for `WHERE age = 30` and then `WHERE city = 'London' AND age = 30`. Which one uses the index, and why?
3. Make a covering index so `SELECT name FROM users WHERE city = 'London'` never touches the table.
4. Create a partial index for active users only.
5. Try `WHERE email LIKE '%mail.com'` and see why the index can't help.

---

## Summary

> An index is a **sorted B-tree of keys and rowid pointers** that trades extra disk space and slower writes for much faster reads. Create indexes on columns you filter, join, and sort by. Respect the **leftmost prefix rule**, avoid wrapping indexed columns in functions, and always **verify with `EXPLAIN QUERY PLAN`**.





[[SQlite]]