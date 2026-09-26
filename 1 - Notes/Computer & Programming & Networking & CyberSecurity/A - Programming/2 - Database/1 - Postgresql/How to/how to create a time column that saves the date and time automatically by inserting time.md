
In PostgreSQL you usually use `TIMESTAMP` (or `TIMESTAMPTZ` if you want timezone-aware) with a default value of `NOW()`.

Example:

```sql
CREATE TABLE logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### ✅ What happens:

- When you `INSERT` a row without specifying `created_at`, PostgreSQL will automatically use the current date & time.
    
- Example:
    

```sql
INSERT INTO logs (message) VALUES ('Hello world');
SELECT * FROM logs;
```

Output:

```
 id |   message     |        created_at
----+---------------+----------------------------
  1 | Hello world   | 2025-09-27 13:45:12.123456
```

---

⚡ If you want **timezone included** (recommended), use `TIMESTAMPTZ`:

```sql
created_at TIMESTAMPTZ DEFAULT NOW()
```

---



#### Tags : [[1 - SQL 🦬]]