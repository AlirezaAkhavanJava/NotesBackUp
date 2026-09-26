

Below is a **complete, authoritative guide** to **`IF EXISTS`** and **`IF NOT EXISTS`** in **PostgreSQL** — **not to be confused** with `EXISTS()` in `WHERE`.

These are **DDL (Data Definition Language) clauses** used with:
- `DROP`
- `CREATE INDEX`
- `ALTER TABLE`

They **prevent errors** when an object **already exists** or **does not exist**.

---

## 1. `IF EXISTS` — "Drop only if it exists"

### Syntax
```sql
DROP object_type object_name [IF EXISTS];
```

### Supported Objects
| Object | Example |
|-------|--------|
| `TABLE` | `DROP TABLE IF EXISTS employees;` |
| `VIEW` | `DROP VIEW IF EXISTS active_orders;` |
| `INDEX` | `DROP INDEX IF EXISTS idx_emp_salary;` |
| `SEQUENCE` | `DROP SEQUENCE IF EXISTS seq_id;` |
| `FUNCTION` | `DROP FUNCTION IF EXISTS calc_bonus(numeric);` |
| `SCHEMA` | `DROP SCHEMA IF EXISTS staging;` |
| `DATABASE` | `DROP DATABASE IF EXISTS test_db;` |

### Example
```sql
DROP TABLE IF EXISTS temp_import;
-- No error if table doesn't exist
```

> Without `IF EXISTS` → `ERROR: table "temp_import" does not exist`

---

## 2. `IF NOT EXISTS` — "Create only if it doesn't exist"

### Syntax
```sql
CREATE object_type object_name [IF NOT EXISTS];
```

### Supported Objects
| Object | Example |
|-------|--------|
| `TABLE` | `CREATE TABLE IF NOT EXISTS logs (...);` |
| `INDEX` | `CREATE INDEX IF NOT EXISTS idx_emp_dept ON employees(dept_id);` |
| `SCHEMA` | `CREATE SCHEMA IF NOT EXISTS analytics;` |

**Note**: `CREATE TABLE IF NOT EXISTS` **does NOT** prevent duplicate rows — only duplicate **table name**.

### Example
```sql
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    action TEXT,
    ts TIMESTAMPTZ DEFAULT NOW()
);
-- Safe to run multiple times
```

---

## 3. `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`

```sql
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS middle_name TEXT;
```

> PostgreSQL **12+** only

---

## 4. Real-World Use Cases

### 1. **Idempotent Scripts (Safe to rerun)**
```sql
-- Migration script
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
```

### 2. **Cleanup Scripts**
```sql
DROP TABLE IF EXISTS temp_data;
DROP INDEX IF EXISTS idx_temp;
```

### 3. **Conditional Index Creation**
```sql
CREATE INDEX IF NOT EXISTS idx_orders_date_status
ON orders(order_date, status)
WHERE status = 'pending';
```

---

## 5. Behavior Summary

| Clause | If Object **Exists** | If Object **Does NOT Exist** |
|-------|----------------------|------------------------------|
| `DROP ... IF EXISTS` | Dropped | **No action, no error** |
| `DROP ...` (no clause) | Dropped | **ERROR** |
| `CREATE ... IF NOT EXISTS` | **No action, no error** | Created |
| `CREATE ...` (no clause) | **ERROR** | Created |

---

## 6. Senior-Level Patterns

### 1. **Atomic Migration with `DO` Block**
```sql
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ DEFAULT NOW()
    );

    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '2025-001') THEN
        -- Run migration
        ALTER TABLE employees ADD COLUMN IF NOT EXISTS ssn TEXT;
        
        INSERT INTO schema_migrations (version) VALUES ('2025-001');
    END IF;
END $$;
```

### 2. **Drop & Recreate Safely**
```sql
DROP INDEX IF EXISTS idx_emp_salary;
CREATE INDEX idx_emp_salary ON employees(salary DESC);
```

### 3. **Conditional Column Add with Default**
```sql
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS processed BOOLEAN DEFAULT FALSE;
```

---

## 7. Common Pitfalls

| Mistake | Problem | Fix |
|-------|--------|-----|
| `CREATE TABLE IF NOT EXISTS ... INSERT ...` | Table created, but data duplicated | Use `INSERT ... ON CONFLICT` |
| `DROP TABLE IF EXISTS` in transaction | Still rolls back if error elsewhere | Use `IF EXISTS` always |
| Forgetting `IF NOT EXISTS` on index | `ERROR: relation "idx_name" already exists` | Add clause |

---

## 8. Cheat Sheet

```sql
-- Safe drop
DROP TABLE IF EXISTS temp_table;
DROP INDEX IF EXISTS idx_name;
DROP FUNCTION IF EXISTS my_func(param_type);

-- Safe create
CREATE TABLE IF NOT EXISTS logs (...);
CREATE INDEX IF NOT EXISTS idx_col ON table(col);
CREATE SCHEMA IF NOT EXISTS staging;

-- Safe alter (PG 12+)
ALTER TABLE t ADD COLUMN IF NOT EXISTS col TYPE;

-- Safe to rerun
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS ...;
    -- migration logic
END $$;
```

---

## 9. Decision Table

| Goal | Use |
|------|-----|
| Drop without error | `DROP ... IF EXISTS` |
| Create without error | `CREATE ... IF NOT EXISTS` |
| Add column safely | `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` |
| Make script idempotent | Use all three |

---

## Final Summary

| Clause | Purpose | PostgreSQL Version |
|-------|--------|-------------------|
| `IF EXISTS` | Safe `DROP` | All |
| `IF NOT EXISTS` | Safe `CREATE` | All |
| `ADD COLUMN IF NOT EXISTS` | Safe `ALTER` | **12+** |

---

**Master `IF EXISTS` / `IF NOT EXISTS` → your scripts become bulletproof.**

> **Golden Rule**:  
> **Never write raw `DROP` or `CREATE` in production scripts.**  
> **Always use `IF EXISTS` / `IF NOT EXISTS`.**

Use this guide to **write safe, idempotent, production-grade DDL**.


[[1 - SQL 🦬]]