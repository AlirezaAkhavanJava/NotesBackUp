
# Deep Dive: `INSERT ... SELECT` and `UPSERT`

I'll cover both in detail since they're the two most powerful and commonly misunderstood.

---

# Part 1: `INSERT INTO ... SELECT`

## Basic Concept

Instead of hardcoding values, you pull them from a query. The column count and types must match.

```sql
INSERT INTO target_table (col1, col2, col3)
SELECT colA, colB, colC FROM source_table WHERE condition;
```

## Example Setup

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    age INTEGER
);

CREATE TABLE archived_users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    age INTEGER
);

CREATE TABLE temp_users (name TEXT, email TEXT, age INTEGER);
```

## 1. Copy All Rows

```sql
INSERT INTO archived_users (id, name, email, age)
SELECT id, name, email, age FROM users;
```

## 2. Copy with a Filter

```sql
INSERT INTO archived_users (id, name, email, age)
SELECT id, name, email, age FROM users
WHERE age > 60;
```

## 3. Copy with Transformation

```sql
INSERT INTO archived_users (id, name, email, age)
SELECT id, UPPER(name), LOWER(email), age FROM users
WHERE email IS NOT NULL;
```

## 4. Insert Aggregated Results

```sql
CREATE TABLE stats (total INTEGER, avg_age REAL, max_age INTEGER);

INSERT INTO stats (total, avg_age, max_age)
SELECT COUNT(*), AVG(age), MAX(age) FROM users;
```

## 5. Insert from a `VALUES` Clause (CTE)

```sql
WITH new_data(name, email, age) AS (
    VALUES ('Alice', 'alice@x.com', 30),
           ('Bob',   'bob@x.com',   25)
)
INSERT INTO users (name, email, age)
SELECT name, email, age FROM new_data;
```

## 6. Insert from a Join

```sql
INSERT INTO user_orders (user_id, order_id, total)
SELECT u.id, o.id, o.total
FROM users u
JOIN orders o ON o.user_email = u.email
WHERE o.total > 100;
```

## 7. Copy from Another Database (ATTACH)

```sql
ATTACH DATABASE 'other.db' AS other;

INSERT INTO users (name, email, age)
SELECT name, email, age FROM other.users;

DETACH DATABASE other;
```

## 8. `INSERT ... SELECT` with Conflict Handling

```sql
INSERT OR IGNORE INTO users (name, email, age)
SELECT name, email, age FROM temp_users;
```

## Common Pitfalls ⚠️

| Pitfall | Fix |
|---------|-----|
| Column count mismatch | Match count and order exactly |
| Forgetting `WHERE` | You'll duplicate all rows |
| Inserting into same table you select from | Allowed, but be careful — SQLite may read while writing |
| Duplicate unique values | Use `INSERT OR IGNORE` or `WHERE NOT EXISTS` |

### Avoid duplicates safely:
```sql
INSERT INTO users (name, email, age)
SELECT name, email, age FROM temp_users t
WHERE NOT EXISTS (
    SELECT 1 FROM users u WHERE u.email = t.email
);
```

---

# Part 2: UPSERT (`ON CONFLICT`)

Available in **SQLite 3.24.0+** (2018). This is the modern, explicit way to handle conflicts.

## The Problem It Solves

You want: *"Insert this row; if it already exists, update it instead."*

Before upsert, people used `INSERT OR REPLACE` — but that **deletes** the row first (losing data, firing DELETE triggers, changing rowid).

## Basic Syntax

```sql
INSERT INTO table (cols...)
VALUES (vals...)
ON CONFLICT (conflict_column) DO UPDATE SET
    col1 = excluded.col1,
    col2 = excluded.col2;
```

- `ON CONFLICT (column)` — specifies which constraint triggers the action
- `excluded.col` — refers to the row you *tried* to insert
- `DO UPDATE SET` — what to do instead

## Example 1: Basic Upsert

```sql
INSERT INTO users (id, name, email, age)
VALUES (1, 'Alice', 'alice@example.com', 30)
ON CONFLICT(id) DO UPDATE SET
    name  = excluded.name,
    email = excluded.email,
    age   = excluded.age;
```

If `id = 1` exists → update it. Otherwise → insert.

## Example 2: `DO NOTHING`

```sql
INSERT INTO users (id, name, email, age)
VALUES (1, 'Alice', 'alice@example.com', 30)
ON CONFLICT(id) DO NOTHING;
```

Silently skips if the row already exists. Equivalent to `INSERT OR IGNORE`.

## Example 3: Partial Update (only change some columns)

```sql
INSERT INTO users (id, name, email, age)
VALUES (1, 'Alice', 'alice@example.com', 30)
ON CONFLICT(id) DO UPDATE SET
    age = excluded.age;   -- only update age, keep name/email
```

## Example 4: Conditional Update with `WHERE`

```sql
INSERT INTO users (id, name, email, age)
VALUES (1, 'Alice', 'alice@example.com', 30)
ON CONFLICT(id) DO UPDATE SET
    age = excluded.age
WHERE excluded.age > users.age;   -- only update if new age is higher
```

Reference the existing row with the **table name** (`users.age`).

## Example 5: UPSERT on a Unique Column

```sql
INSERT INTO users (name, email, age)
VALUES ('Alice', 'alice@example.com', 31)
ON CONFLICT(email) DO UPDATE SET
    name = excluded.name,
    age  = excluded.age;
```

Here the conflict is on `email`, not the primary key.

## Example 6: UPSERT with a Computed Value

```sql
INSERT INTO counters (key, count)
VALUES ('visits', 1)
ON CONFLICT(key) DO UPDATE SET
    count = counters.count + 1;   -- increment existing counter
```

Great for counters/aggregation.

## Example 7: Multi-row UPSERT

```sql
INSERT INTO users (id, name, email, age) VALUES
    (1, 'Alice', 'alice@x.com', 30),
    (2, 'Bob',   'bob@x.com',   25),
    (3, 'Carol', 'carol@x.com', 40)
ON CONFLICT(id) DO UPDATE SET
    name  = excluded.name,
    email = excluded.email,
    age   = excluded.age;
```

Each row is checked individually.

## Example 8: UPSERT Using `INSERT ... SELECT`

```sql
INSERT INTO users (id, name, email, age)
SELECT id, name, email, age FROM temp_users
ON CONFLICT(id) DO UPDATE SET
    name  = excluded.name,
    email = excluded.email,
    age   = excluded.age;
```

## `excluded` — What Is It?

`excluded` is a pseudo-table representing the row that **would have been inserted** but hit a conflict.

```sql
ON CONFLICT(id) DO UPDATE SET
    name = excluded.name;   -- the name from VALUES
```

You can also reference the **existing** row by the table name:

```sql
ON CONFLICT(id) DO UPDATE SET
    age = users.age + excluded.age;   -- combine old + new
```

## UPSERT vs `INSERT OR REPLACE`

| Feature | `INSERT OR REPLACE` | `UPSERT (ON CONFLICT)` |
|---------|---------------------|------------------------|
| Deletes old row? | ✅ Yes | ❌ No |
| Fires DELETE triggers? | ✅ Yes | ❌ No |
| Preserves rowid? | ❌ No (new rowid) | ✅ Yes |
| Handles FK cascades? | ⚠️ May cascade delete | ✅ Safe |
| Partial updates? | ❌ No (full replace) | ✅ Yes |
| Conditional update? | ❌ No | ✅ Yes (`WHERE`) |

**Rule of thumb:** Prefer `UPSERT` unless you specifically want replace semantics.

## Conflict Targets You Can Use

```sql
ON CONFLICT (column_name)       -- specific column with UNIQUE/PRIMARY KEY
ON CONFLICT (col1, col2)        -- composite unique constraint
ON CONFLICT                     -- any constraint (catch-all)
```

## Practical Pattern: Sync Two Tables

```sql
-- Sync temp_users into users, updating on email match
INSERT INTO users (name, email, age)
SELECT name, email, age FROM temp_users
ON CONFLICT(email) DO UPDATE SET
    name = excluded.name,
    age  = excluded.age;
```

## Practical Pattern: Idempotent Inserts

```sql
-- Safe to run multiple times — no duplicate errors
INSERT INTO settings (key, value)
VALUES ('theme', 'dark')
ON CONFLICT(key) DO UPDATE SET value = excluded.value;
```

## Practical Pattern: Counter / Analytics

```sql
INSERT INTO page_views (page, views)
VALUES ('/home', 1)
ON CONFLICT(page) DO UPDATE SET
    views = page_views.views + 1;
```

---

# Summary Cheat Sheet

### `INSERT ... SELECT`
```sql
INSERT INTO target (a, b, c)
SELECT x, y, z FROM source
WHERE condition
ON CONFLICT ... ;   -- can combine with upsert!
```

### `UPSERT`
```sql
INSERT INTO t (id, col)
VALUES (1, 'val')
ON CONFLICT(id) DO UPDATE SET
    col = excluded.col
WHERE <optional condition>;
```

### When to use which

| Goal | Use |
|------|-----|
| Copy rows from another table | `INSERT ... SELECT` |
| Insert if new, else update | `UPSERT` |
| Insert if new, else ignore | `ON CONFLICT DO NOTHING` |
| Insert if new, else overwrite fully | `INSERT OR REPLACE` |
| Increment/aggregate on conflict | `UPSERT` with computed value |

---




[[1 - WHAT IS SQLITE3 🍕]]