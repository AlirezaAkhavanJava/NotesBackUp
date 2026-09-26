

There are several ways to insert data into a table. Here's a complete breakdown:

## 1. `INSERT INTO ... VALUES` (Most Common)

### Insert all columns (must match order)
```sql
INSERT INTO users VALUES (1, 'Alice', 'alice@example.com', 30);
```

### Insert specific columns
```sql
INSERT INTO users (name, email, age) 
VALUES ('Bob', 'bob@example.com', 25);
```

### Insert multiple rows in one statement
```sql
INSERT INTO users (name, email, age) VALUES 
    ('Charlie', 'charlie@example.com', 35),
    ('Diana', 'diana@example.com', 28);
```

---

## 2. `INSERT INTO ... SELECT` (Copy from Another Table)

Copy rows from one table (or query result) into another:

```sql
INSERT INTO users (name, email, age)
SELECT name, email, age FROM temp_users WHERE age > 18;
```

Useful for:
- Migrating/backing up data
- Copying between tables
- Inserting aggregated/computed results

```sql
INSERT INTO user_summary (total_users, avg_age)
SELECT COUNT(*), AVG(age) FROM users;
```

---

## 3. `INSERT OR REPLACE` (Upsert-like)

Replaces rows that violate a `UNIQUE` or `PRIMARY KEY` constraint:

```sql
INSERT OR REPLACE INTO users (id, name, email, age) 
VALUES (1, 'Alice Updated', 'alice@example.com', 31);
```
⚠️ This **deletes** the old row and inserts a new one (triggers `DELETE` triggers).

---

## 4. `INSERT OR IGNORE` (Skip Conflicts)

Skips rows that would cause a constraint violation:

```sql
INSERT OR IGNORE INTO users (name, email, age) 
VALUES ('Alice', 'alice@example.com', 30);
```
No error, just silently skipped.

---

## 5. `INSERT OR ABORT / FAIL / ROLLBACK`

Different conflict-resolution behaviors:

```sql
INSERT OR ABORT    INTO users ...;  -- default: abort statement, revert changes
INSERT OR FAIL     INTO users ...;  -- stop, but keep prior changes
INSERT OR ROLLBACK INTO users ...;  -- rollback entire transaction
```

---

## 6. `UPSERT` (SQLite 3.24+)

Modern, explicit upsert syntax using `ON CONFLICT`:

```sql
INSERT INTO users (id, name, email, age)
VALUES (1, 'Alice', 'alice@example.com', 30)
ON CONFLICT(id) DO UPDATE SET
    name  = excluded.name,
    email = excluded.email,
    age   = excluded.age;
```

Or do nothing on conflict:
```sql
INSERT INTO users (id, name, email, age)
VALUES (1, 'Alice', 'alice@example.com', 30)
ON CONFLICT(id) DO NOTHING;
```

`excluded` refers to the row that would have been inserted.

---

## 7. `DEFAULT VALUES`

Insert a row using only default values:

```sql
INSERT INTO users DEFAULT VALUES;
```
Useful when all columns have defaults or are nullable.

---

## 8. Using `WITH` (CTE) + INSERT

Insert results from a Common Table Expression:

```sql
WITH new_users(name, email, age) AS (
    VALUES ('Grace', 'grace@example.com', 27),
           ('Henry', 'henry@example.com', 33)
)
INSERT INTO users (name, email, age)
SELECT name, email, age FROM new_users;
```

---

## 9. From Application Code (Python example)

```python
import sqlite3
conn = sqlite3.connect('mydatabase.db')
cur = conn.cursor()

# Single row (parameterized — safe)
cur.execute("INSERT INTO users (name, email, age) VALUES (?, ?, ?)",
            ('Ivy', 'ivy@example.com', 29))

# Many rows (efficient)
cur.executemany("INSERT INTO users (name, email, age) VALUES (?, ?, ?)",
                [('Jack', 'jack@example.com', 45),
                 ('Kate', 'kate@example.com', 22)])

conn.commit()
```

---

## Quick Comparison Table

| Method | Use Case |
|--------|----------|
| `INSERT INTO ... VALUES` | Normal single/multi-row insert |
| `INSERT INTO ... SELECT` | Copy from another table/query |
| `INSERT OR IGNORE` | Skip duplicates silently |
| `INSERT OR REPLACE` | Overwrite existing rows |
| `INSERT OR ABORT/FAIL/ROLLBACK` | Control error behavior |
| `UPSERT (ON CONFLICT)` | Modern explicit update-or-insert |
| `DEFAULT VALUES` | Insert row with all defaults |
| `WITH ... INSERT` | Insert from CTE |

---

## Summary of the Flow

```
Do you have the values already?
├── Yes → INSERT INTO ... VALUES
└── No, they come from another table/query → INSERT INTO ... SELECT

What if there's a conflict (UNIQUE/PK)?
├── Ignore it        → INSERT OR IGNORE
├── Replace old row  → INSERT OR REPLACE
├── Update old row   → UPSERT (ON CONFLICT DO UPDATE)
└── Fail             → INSERT OR ABORT / FAIL / ROLLBACK
```




[[1 - WHAT IS SQLITE3 🍕]]