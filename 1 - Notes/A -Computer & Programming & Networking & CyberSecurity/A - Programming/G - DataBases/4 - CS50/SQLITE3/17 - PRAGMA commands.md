
**SQLite-specific commands/statements that control the database engine**, like:

```sql
PRAGMA foreign_keys = ON;
```

These are different from DDL/DML/DQL.

## SQLite `PRAGMA` commands

`PRAGMA` is SQLite's mechanism for **querying or changing SQLite-specific configuration and behavior**.

The general syntax is:

```sql
PRAGMA name;
```

or:

```sql
PRAGMA name = value;
```

---

### `PRAGMA foreign_keys`

Controls **foreign-key constraint enforcement**.

```sql
PRAGMA foreign_keys = ON;
```

Enable foreign keys.

```sql
PRAGMA foreign_keys = OFF;
```

Disable foreign keys.

Check the current setting:

```sql
PRAGMA foreign_keys;
```

Result:

```text
1
```

means enabled.

```text
0
```

means disabled.

---

### `PRAGMA journal_mode`

Controls SQLite's **transaction journal mode**.

```sql
PRAGMA journal_mode;
```

Check the current mode.

You can set WAL mode:

```sql
PRAGMA journal_mode = WAL;
```

`WAL` = **Write-Ahead Logging**.

It's commonly useful when you have concurrent readers/writers.

---

### `PRAGMA synchronous`

Controls how aggressively SQLite synchronizes writes to storage.

```sql
PRAGMA synchronous;
```

Possible values include:

```text
OFF
NORMAL
FULL
EXTRA
```

For example:

```sql
PRAGMA synchronous = NORMAL;
```

This is a performance/durability trade-off.

---

### `PRAGMA table_info`

Displays information about a table's columns.

```sql
PRAGMA table_info(users);
```

You might get something like:

```text
cid | name     | type    | notnull | dflt_value | pk
----+----------+---------+---------+-------------+---
0   | id       | INTEGER | 0       | NULL        | 1
1   | username | TEXT    | 1       | NULL        | 0
2   | age      | INTEGER | 0       | NULL        | 0
```

This is extremely useful when inspecting an existing database.

---

### `PRAGMA index_list`

Shows indexes belonging to a table:

```sql
PRAGMA index_list(users);
```

---

### `PRAGMA index_info`

Shows information about an index:

```sql
PRAGMA index_info(idx_users_username);
```

---

### `PRAGMA foreign_key_list`

Shows the foreign keys defined on a table:

```sql
PRAGMA foreign_key_list(posts);
```

For example, you could inspect:

```sql
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

with:

```sql
PRAGMA foreign_key_list(posts);
```

---

### `PRAGMA database_list`

Shows databases currently attached to the connection:

```sql
PRAGMA database_list;
```

You'll commonly see:

```text
0 | main | /path/to/database.db
```

If you use `ATTACH DATABASE`, additional databases appear here.

---

### `PRAGMA user_version`

A particularly useful one for application development.

You can store a **schema version number**:

```sql
PRAGMA user_version;
```

Set it:

```sql
PRAGMA user_version = 1;
```

Later:

```sql
PRAGMA user_version = 2;
```

This is commonly used by applications to track database schema migrations.

---

## Important distinction

Don't call these DDL/DML commands:

```sql
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
```

They are **SQLite PRAGMA statements**.

A useful classification is:

```text
SQL
│
├── DDL
│   ├── CREATE
│   ├── ALTER
│   └── DROP
│
├── DML
│   ├── INSERT
│   ├── UPDATE
│   └── DELETE
│
├── DQL
│   └── SELECT
│
└── SQLite-specific
    └── PRAGMA
        ├── foreign_keys
        ├── journal_mode
        ├── synchronous
        ├── table_info
        ├── index_list
        ├── foreign_key_list
        └── database_list
```

**For your SQLite learning, `PRAGMA foreign_keys = ON` is especially important** because SQLite's foreign-key enforcement is connection-specific. When writing Java/JDBC applications, you should understand when and how that setting gets enabled on each database connection.

> SQlite has 5 major category commands : 

| Category   | Meaning                                                                 | Main commands/statements                              |
| ---------- | ----------------------------------------------------------------------- | ----------------------------------------------------- |
| **DDL**    | Data Definition Language [[13 - DDL commands]]                          | `CREATE`, `ALTER`, `DROP`                             |
| **DML**    | Data Manipulation Language [[14 - DML and DQL commands]]                | `INSERT`, `UPDATE`, `DELETE`                          |
| **DQL**    | Data Query Language [[14 - DML and DQL commands]]                       | `SELECT`                                              |
| **TCL**    | Transaction Control Language [[18 - TCL commands]]                      | `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`, `RELEASE` |
| **PRAGMA** | SQLite-specific database control/configuration [[17 - PRAGMA commands]] | `PRAGMA foreign_keys`, `PRAGMA journal_mode`, etc.    |

[[1 - WHAT IS SQLITE3]]