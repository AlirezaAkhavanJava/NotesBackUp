
# Creating Indexes in SQLite3: Syntax and Rules

## 1. Definition

An **index** is a separate, sorted data structure that SQLite maintains alongside a table. It stores the values of one or more columns, each paired with the `rowid` of the row it came from. Because the values are kept in sorted order (internally a B-tree), SQLite can find matching rows without reading the whole table.

`CREATE INDEX` is the statement that builds this structure.

## 2. Why it exists and what problem it solves

Without an index, a query like `WHERE email = 'ali@example.com'` forces SQLite to do a **full table scan**: read every row and compare. With 10 rows that is nothing. With 5 million rows it is slow, and the cost grows linearly with table size.

With an index on `email`, SQLite does a **search** in the sorted structure, which grows logarithmically. Millions of rows can be searched in a handful of steps.

An index speeds up:

- `WHERE` filters (`=`, `<`, `>`, `BETWEEN`, `IN`, prefix `LIKE 'abc%'` under certain conditions)
- `JOIN` conditions (the column you join on)
- `ORDER BY` (rows come out already sorted, so no separate sort step)
- Enforcing uniqueness (`UNIQUE` indexes)

## 3. The syntax

```sql
CREATE [UNIQUE] INDEX [IF NOT EXISTS] index_name
ON table_name (column_or_expression [COLLATE collation] [ASC | DESC], ...)
[WHERE condition];
```

|Part|Meaning|
|---|---|
|`UNIQUE`|Optional. Rejects duplicate values in the indexed columns.|
|`IF NOT EXISTS`|Optional. No error if an index with that name already exists.|
|`index_name`|Name you choose.|
|`ON table_name`|The table being indexed.|
|`(columns...)`|One or more columns (or expressions) to index.|
|`COLLATE`|Optional. How text is compared (e.g. `NOCASE`).|
|`ASC` / `DESC`|Optional sort direction per column.|
|`WHERE`|Optional. Makes it a **partial index**.|

Removing one:

```sql
DROP INDEX [IF EXISTS] index_name;
```

## 4. Worked example: from slow to fast

Create a table and some data:

```sql
CREATE TABLE users (
    id      INTEGER PRIMARY KEY,
    email   TEXT NOT NULL,
    name    TEXT,
    city    TEXT,
    active  INTEGER DEFAULT 1
);

INSERT INTO users (email, name, city) VALUES
  ('ali@example.com',  'Ali',  'Tehran'),
  ('sara@example.com', 'Sara', 'Shiraz'),
  ('omid@example.com', 'Omid', 'Tehran');
```

**What this does:** creates a `users` table and inserts three rows. `id` is an `INTEGER PRIMARY KEY`, so it already acts as the rowid and is already fast to look up. `email` has no index yet.

Check how SQLite would run a search on `email`:

```sql
EXPLAIN QUERY PLAN
SELECT * FROM users WHERE email = 'ali@example.com';
```

Output:

```
SCAN users
```

**What this means:** `SCAN` means a full table scan, every row is examined. That is what we want to eliminate.

Now create the index:

```sql
CREATE INDEX idx_users_email ON users (email);
```

**What this does:** builds a sorted structure of all `email` values pointing to their rows. SQLite fills it from existing data immediately.

Run the same plan again:

```
SEARCH users USING INDEX idx_users_email (email=?)
```

**What this means:** `SEARCH ... USING INDEX` means SQLite jumped straight to the matching entry instead of scanning. `EXPLAIN QUERY PLAN` is how you verify an index is really being used, so get used to running it.

## 5. The variants you will actually use

### 5.1 Unique index

```sql
CREATE UNIQUE INDEX idx_users_email_unique ON users (email);
```

**What this does:** builds the index and also forbids two rows with the same `email`. An `INSERT` of a duplicate fails with `UNIQUE constraint failed: users.email`. This is the same mechanism behind a `UNIQUE` column constraint. SQLite creates a unique index automatically when you write `UNIQUE` in `CREATE TABLE`.

### 5.2 Multi-column (composite) index

```sql
CREATE INDEX idx_users_city_name ON users (city, name);
```

**What this does:** sorts rows by `city` first, then by `name` within each city. Column order matters, see Rule 5 below.

### 5.3 Descending order

```sql
CREATE INDEX idx_users_name_desc ON users (name DESC);
```

**What this does:** stores names in descending order. For a single column this rarely matters, since SQLite can read an ascending index backwards. It matters mainly in composite indexes with mixed directions, like `(city ASC, name DESC)`.

### 5.4 Case-insensitive index

```sql
CREATE INDEX idx_users_email_nocase ON users (email COLLATE NOCASE);
```

**What this does:** compares emails ignoring upper/lower case. A query only uses it if it compares with the same collation:

```sql
SELECT * FROM users WHERE email = 'ALI@EXAMPLE.COM' COLLATE NOCASE;
```

### 5.5 Expression index

```sql
CREATE INDEX idx_users_lower_email ON users (lower(email));
```

**What this does:** indexes the _result_ of `lower(email)` instead of the raw column. It is used by queries that contain exactly that expression:

```sql
SELECT * FROM users WHERE lower(email) = 'ali@example.com';
```

A plain index on `email` cannot help here, because the query is searching for the output of a function, not the stored value.

### 5.6 Partial index

```sql
CREATE INDEX idx_users_active_city ON users (city) WHERE active = 1;
```

**What this does:** indexes only rows where `active = 1`. The index is smaller and cheaper to maintain. It is used only when the query's `WHERE` clause guarantees that condition:

```sql
SELECT * FROM users WHERE city = 'Tehran' AND active = 1;
```

## 6. The rules

1. **Index names must be unique in the database**, and they share a namespace with tables and views. You cannot name an index the same as a table. Names starting with `sqlite_` are reserved.
2. **You can index only tables**, not views, and not SQLite's internal `sqlite_*` tables.
3. **A `UNIQUE` index fails to create if duplicates already exist** in the data. Fix the duplicates first.
4. **`NULL` values are treated as distinct in unique indexes.** You can store many `NULL`s in a `UNIQUE` column. This is standard SQLite behavior, and it surprises people.
5. **In a composite index, column order matters (leftmost prefix rule).** An index on `(city, name)` helps queries filtering on `city`, or on `city` and `name`. It does **not** help a query filtering only on `name`.
6. **Expressions in indexes must be deterministic.** You cannot use `random()`, `datetime('now')`, subqueries, or columns from other tables. Same function, same input, always the same output.
7. **Partial index `WHERE` clauses follow the same restriction**, and can only reference columns of the indexed table. The query must logically include that condition to use the index.
8. **The query must match the index.** If the index uses a collation or expression, the query must use the same one, or SQLite will ignore the index.
9. **`INTEGER PRIMARY KEY` needs no index.** It is the rowid itself. Other primary keys and `UNIQUE` constraints get an automatic index, so do not create a duplicate one manually.
10. **Indexes are not free.** Every `INSERT`, `UPDATE`, and `DELETE` must also update every index on that table, and each index uses disk space. Index columns you actually search, join, or sort by, not every column.

## 7. Inspecting and maintaining indexes

In the `sqlite3` shell:

```sql
.indexes users                  -- list indexes on a table
.schema users                   -- show table + index definitions
PRAGMA index_list('users');     -- detailed list (name, unique, origin)
PRAGMA index_info('idx_users_email');   -- columns inside an index
REINDEX idx_users_email;        -- rebuild an index
DROP INDEX IF EXISTS idx_users_email;   -- remove it
```

**What these do:** the dot-commands are shell shortcuts; the `PRAGMA`s are real SQL you can also run from Java later through JDBC. `REINDEX` is mainly needed after changing a collation sequence's behavior.

## 8. Common mistakes

- Creating an index on every column "just in case". This slows writes and wastes space.
- Wrapping an indexed column in a function in the query (`WHERE lower(email) = ...`) without an expression index. The plain index is then ignored.
- Assuming an index is used without checking `EXPLAIN QUERY PLAN`.
- Adding `CREATE INDEX` for a tiny table. SQLite may scan it anyway, and it is faster.

---




[[SQlite]]