

`DEFAULT` is a **column constraint** that specifies a value SQLite should automatically use when an `INSERT` statement **does not provide a value for that column**.

### Syntax

```sql
column_name DATA_TYPE DEFAULT value
```

### Example

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    country TEXT DEFAULT 'Germany',
    age INTEGER DEFAULT 18
);
```

Now:

```sql
INSERT INTO users (username)
VALUES ('Alireza');
```

SQLite automatically uses the defaults:

```text
id | username | country  | age
---+----------+----------+----
1  | Alireza  | Germany  | 18
```

## Important distinction

`DEFAULT` applies when the column is **omitted**:

```sql
INSERT INTO users (username)
VALUES ('Ali');
```

But explicitly inserting `NULL` is different:

```sql
INSERT INTO users (username, country)
VALUES ('Ali', NULL);
```

If `country` allows `NULL`, the result is:

```text
country = NULL
```

—not `'Germany'`.

So:

```text
Column omitted        → DEFAULT value
Column = NULL         → NULL
Column = 'something'  → supplied value
```

### Common defaults

```sql
created_at TEXT DEFAULT CURRENT_TIMESTAMP,
active INTEGER DEFAULT 1,
balance REAL DEFAULT 0.0,
role TEXT DEFAULT 'USER'
```

For example:

```sql
CREATE TABLE accounts (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    role TEXT DEFAULT 'USER',
    active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**Definition:** `DEFAULT` provides an automatic value for a column when an `INSERT` does not explicitly supply one.


[[1 - SQL 🥞]]
[[1 - WHAT IS SQLITE3 🍕]]