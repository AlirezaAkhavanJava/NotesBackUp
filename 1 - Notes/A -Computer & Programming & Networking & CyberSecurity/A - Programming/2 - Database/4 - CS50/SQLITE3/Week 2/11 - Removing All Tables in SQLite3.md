

SQLite does **not** have a command like:

```sql
DROP ALL TABLES;
```

Instead, you remove each table with `DROP TABLE`.

## 1. Remove one table

```sql
DROP TABLE users;
```

If the table might not exist:

```sql
DROP TABLE IF EXISTS users;
```

`IF EXISTS` prevents an error when the table doesn't exist.

---

# 2. Remove all tables

For a small database, you can generate the `DROP` statements from SQLite's schema:

```sql
SELECT 'DROP TABLE IF EXISTS "' || name || '";'
FROM sqlite_schema
WHERE type = 'table'
  AND name NOT LIKE 'sqlite_%';
```

This produces something like:

```sql
DROP TABLE IF EXISTS "users";
DROP TABLE IF EXISTS "posts";
DROP TABLE IF EXISTS "comments";
```

Then execute those statements.

### In the SQLite CLI

You can do it automatically with:

```bash
sqlite3 database.db "
SELECT 'DROP TABLE IF EXISTS \"' || name || '\";'
FROM sqlite_schema
WHERE type = 'table'
  AND name NOT LIKE 'sqlite_%';
" | sqlite3 database.db
```

This removes the user-created tables while leaving SQLite's internal tables alone.

---

# 3. Remove everything from the database

There is an important difference between:

### Remove all rows

```sql
DELETE FROM users;
```

The table remains.

### Remove all tables

```sql
DROP TABLE users;
```

The table itself disappears.

### Delete the entire SQLite database

Since SQLite databases are files, you can simply delete the file:

```bash
rm database.db
```

Then create a new empty database:

```bash
sqlite3 database.db
```

This is effectively a **complete reset**.

> Be careful with `rm`: it permanently removes the database file.

---

# 4. `DROP` commands

The general pattern is:

```sql
DROP object_type object_name;
```

Examples:

```sql
DROP TABLE users;
DROP INDEX idx_users_name;
DROP VIEW adult_users;
DROP TRIGGER audit_users;
```

Safer versions:

```sql
DROP TABLE IF EXISTS users;
DROP INDEX IF EXISTS idx_users_name;
DROP VIEW IF EXISTS adult_users;
DROP TRIGGER IF EXISTS audit_users;
```

---

# 5. Remove all tables but keep other objects

If you only want tables:

```sql
SELECT 'DROP TABLE IF EXISTS "' || name || '";'
FROM sqlite_schema
WHERE type = 'table'
  AND name NOT LIKE 'sqlite_%';
```

If you want to remove **tables, views, indexes, and triggers**, you can generate commands for all user-created schema objects:

```sql
SELECT
    CASE type
        WHEN 'table'  THEN 'DROP TABLE IF EXISTS '
        WHEN 'index'  THEN 'DROP INDEX IF EXISTS '
        WHEN 'view'   THEN 'DROP VIEW IF EXISTS '
        WHEN 'trigger' THEN 'DROP TRIGGER IF EXISTS '
    END
    || '"' || name || '";'
FROM sqlite_schema
WHERE name NOT LIKE 'sqlite_%';
```

However, **indexes belonging to tables are automatically removed when their table is dropped**, so you generally don't need to drop those separately.

---

# 6. Useful SQLite "cleanup" commands

These are worth knowing:

|Command|Meaning|
|---|---|
|`DROP TABLE users;`|Remove table|
|`DROP TABLE IF EXISTS users;`|Remove table if present|
|`DELETE FROM users;`|Remove all rows|
|`DELETE FROM users WHERE ...;`|Remove selected rows|
|`.tables`|List tables in SQLite CLI|
|`.schema`|Show database schema|
|`.schema users`|Show one table's schema|
|`.databases`|Show attached databases|
|`.dump`|Export database as SQL|
|`.read file.sql`|Execute SQL from a file|
|`.backup file.db`|Create a database backup|
|`.quit`|Exit SQLite CLI|

---

## 7. The important hierarchy

Think about database destruction at three different levels:

```text
SQLite database file
│
├── Schema objects
│   ├── Tables
│   ├── Views
│   ├── Indexes
│   └── Triggers
│
└── Data
    └── Rows
```

Therefore:

```sql
DELETE FROM users;
```

→ removes **data**

```sql
DROP TABLE users;
```

→ removes **table + its data**

```bash
rm database.db
```

→ removes the **entire SQLite database**

### Practical rule

If you're experimenting with CS50 SQLite databases and simply want a clean start, **deleting/recreating the `.db` file is often the simplest approach**—provided you don't need any existing data.


[[1 - WHAT IS SQLITE3]]