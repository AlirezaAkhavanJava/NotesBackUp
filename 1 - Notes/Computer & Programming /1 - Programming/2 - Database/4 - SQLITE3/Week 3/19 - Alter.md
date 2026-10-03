


`ALTER TABLE` is used to **modify the structure of an existing table**.

In SQLite, the main supported operations are:

### 1. Add a column

```sql
ALTER TABLE users
ADD COLUMN deleted_at TEXT;
```

Before:

```text
id | name
---+------
1  | Alice
2  | Bob
```

After:

```text
id | name  | deleted_at
---+-------+-----------
1  | Alice | NULL
2  | Bob   | NULL
```

This is exactly what you would commonly use to implement **soft deletion**.

---

### 2. Rename a table

```sql
ALTER TABLE users
RENAME TO customers;
```

---

### 3. Rename a column

```sql
ALTER TABLE users
RENAME COLUMN name TO username;
```

---

### 4. Drop a column

Modern SQLite supports:

```sql
ALTER TABLE users
DROP COLUMN deleted_at;
```

---

### Important SQLite limitation

SQLite's `ALTER TABLE` is more limited than databases such as PostgreSQL.

For example, you generally **cannot directly modify a column's datatype or add arbitrary constraints** with:

```sql
ALTER TABLE users
ALTER COLUMN name ...
```

SQLite doesn't support that syntax.

For more complex schema changes, the usual approach is:

```text
CREATE new table
       ↓
COPY data
       ↓
DROP old table
       ↓
RENAME new table
```

So the core SQLite syntax to remember is:

```sql
ALTER TABLE table_name
    ADD COLUMN column_name datatype;

ALTER TABLE table_name
    RENAME TO new_table_name;

ALTER TABLE table_name
    RENAME COLUMN old_name TO new_name;

ALTER TABLE table_name
    DROP COLUMN column_name;
```


[[SQlite]]