


**Soft deletion** means marking a row as deleted instead of physically removing it from the database.

In SQLite, instead of:

```sql
DELETE FROM users WHERE id = 1;
```

you add a column such as:

```sql
deleted_at
```

and update it:

```sql
UPDATE users
SET deleted_at = CURRENT_TIMESTAMP
WHERE id = 1;
```

The row **still exists**, but your application treats it as deleted.

### Example

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    deleted_at TEXT
);
```

Normal user:

```text
id | name   | deleted_at
---+--------+-----------
1  | Alice  | NULL
2  | Bob    | NULL
```

Soft-delete Alice:

```sql
UPDATE users
SET deleted_at = CURRENT_TIMESTAMP
WHERE id = 1;
```

Now:

```text
id | name   | deleted_at
---+--------+---------------------
1  | Alice  | 2026-10-03 14:43:21
2  | Bob    | NULL
```

To retrieve only **active** users:

```sql
SELECT *
FROM users
WHERE deleted_at IS NULL;
```

To retrieve deleted users:

```sql
SELECT *
FROM users
WHERE deleted_at IS NOT NULL;
```

### Soft vs Hard deletion

|Type|Operation|Data remains?|
|---|---|---|
|**Hard delete**|`DELETE FROM users WHERE id = 1`|❌ No|
|**Soft delete**|`UPDATE users SET deleted_at = ...`|✅ Yes|

### Why use it?

Soft deletion is useful when you need:

- **Recovery** — restore accidentally deleted records.
    
- **Audit/history** — know when something was deleted.
    
- **Referential integrity** — preserve records referenced by other tables.
    
- **Business history** — e.g. invoices, orders, receipts, tasks.
    

A common pattern is:

```sql
deleted_at TEXT DEFAULT NULL
```

Then:

```sql
-- Delete
UPDATE users
SET deleted_at = CURRENT_TIMESTAMP
WHERE id = ?;

-- Restore
UPDATE users
SET deleted_at = NULL
WHERE id = ?;

-- Normal query
SELECT *
FROM users
WHERE deleted_at IS NULL;
```

**Mental model:** hard deletion says _"this row no longer exists."_ Soft deletion says _"this row exists, but is no longer active."_


[[SQlite]]