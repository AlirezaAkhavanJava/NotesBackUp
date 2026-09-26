

## 1. Definition

**DDL (Data Definition Language)** is the part of SQL used to **define and modify the structure of a database**.

While DML works with **data**, DDL works with the **database objects that contain and organize that data**.

```text
DDL → structure
DML → data
```

The main SQLite DDL statements are:

|Statement|Purpose|
|---|---|
|`CREATE`|Create a database object|
|`ALTER`|Modify an existing object|
|`DROP`|Remove an object|
|`RENAME`|Rename an object|
|`TRUNCATE`|Not supported as a SQLite statement|

---

# 2. `CREATE`

`CREATE` creates database objects.

In SQLite, the important objects are:

- Tables
    
- Indexes
    
- Views
    
- Triggers
    

---

## `CREATE TABLE`

Creates a table.

### Syntax

```sql
CREATE TABLE table_name (
    column1 datatype constraints,
    column2 datatype constraints,
    ...
);
```

Example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    age INTEGER CHECK (age >= 0)
);
```

This defines the table's **schema**.

```text
users
│
├── id       INTEGER PRIMARY KEY
├── username TEXT NOT NULL UNIQUE
└── age      INTEGER CHECK (...)
```

---

## `CREATE TABLE ... AS SELECT`

You can create a table from a query:

```sql
CREATE TABLE adult_users AS
SELECT *
FROM users
WHERE age >= 18;
```

Important: this copies the query result, but it does **not** reproduce all the original table's constraints and indexes.

---

# 3. `ALTER TABLE`

`ALTER TABLE` changes the structure of an existing table.

SQLite supports several important forms.

### Rename table

```sql
ALTER TABLE users
RENAME TO customers;
```

### Rename column

```sql
ALTER TABLE users
RENAME COLUMN username TO name;
```

### Add column

```sql
ALTER TABLE users
ADD COLUMN email TEXT;
```

Modern SQLite also supports dropping a column:

```sql
ALTER TABLE users
DROP COLUMN email;
```

However, SQLite's `ALTER TABLE` capabilities are more limited than some database systems such as PostgreSQL.

For complex structural changes, a common SQLite technique is:

```text
Create new table
      ↓
Copy data
      ↓
Drop old table
      ↓
Rename new table
```

---

# 4. `DROP`

`DROP` **removes a database object**.

### Drop table

```sql
DROP TABLE users;
```

This removes the table **and its data**.

Unlike:

```sql
DELETE FROM users;
```

which removes rows while leaving the table structure intact.

### Difference

```text
DELETE FROM users;
        ↓
rows removed
table remains


DROP TABLE users;
        ↓
table + rows removed
```

### Drop index

```sql
DROP INDEX index_name;
```

### Drop view

```sql
DROP VIEW view_name;
```

### Drop trigger

```sql
DROP TRIGGER trigger_name;
```

---

# 5. `CREATE INDEX`

An index is a database structure used to make certain queries faster.

```sql
CREATE INDEX idx_users_username
ON users(username);
```

Then:

```sql
SELECT *
FROM users
WHERE username = 'Alireza';
```

can potentially use that index.

You can remove it:

```sql
DROP INDEX idx_users_username;
```

Important:

> An index is part of the **database structure**, so creating/removing one is DDL.

---

# 6. `CREATE VIEW`

A **view** is a named query that behaves like a virtual table.

```sql
CREATE VIEW adult_users AS
SELECT id, username, age
FROM users
WHERE age >= 18;
```

Then:

```sql
SELECT *
FROM adult_users;
```

You can remove it:

```sql
DROP VIEW adult_users;
```

A view normally stores the **query definition**, not a separate copy of the underlying data.

---

# 7. `CREATE TRIGGER`

A trigger defines an action that SQLite automatically performs when a specified event occurs.

Example:

```sql
CREATE TRIGGER prevent_negative_age
BEFORE INSERT ON users
FOR EACH ROW
WHEN NEW.age < 0
BEGIN
    SELECT RAISE(ABORT, 'Age cannot be negative');
END;
```

Now an invalid insert can automatically be rejected.

Triggers are database objects, so creating/removing them is DDL.

---

# 8. `DROP` vs `DELETE`

This is one of the most important distinctions.

### `DELETE`

DML:

```sql
DELETE FROM users;
```

Removes **rows**.

The table remains:

```text
users
├── schema       ← remains
└── rows         ← removed
```

### `DROP`

DDL:

```sql
DROP TABLE users;
```

Removes the **table itself**:

```text
users
├── schema       ← removed
└── rows         ← removed
```

---

# 9. `CREATE DATABASE` in SQLite

SQLite is different from PostgreSQL/MySQL here.

You normally **do not use**:

```sql
CREATE DATABASE mydb;
```

SQLite databases are files.

```bash
sqlite3 university.db
```

creates/opens:

```text
university.db
```

Then DDL creates the structure inside it:

```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

So:

```text
university.db
      │
      └── SQLite database
             │
             ├── tables
             ├── indexes
             ├── views
             └── triggers
```

---

# 10. SQLite Schema Inspection

SQLite provides useful shell commands for examining the structure.

```sql
.schema
```

Show a particular table:

```sql
.schema users
```

List tables:

```text
.tables
```

List indexes:

```sql
.indexes
```

You can also query SQLite's internal schema table:

```sql
SELECT name, type, sql
FROM sqlite_schema;
```

This is particularly useful for understanding how SQLite stores its schema definitions.

---

# 11. DDL vs DML

||DDL|DML|
|---|---|---|
|Full name|Data Definition Language|Data Manipulation Language|
|Works with|Structure|Data|
|`CREATE TABLE`|Yes|No|
|`ALTER TABLE`|Yes|No|
|`DROP TABLE`|Yes|No|
|`CREATE INDEX`|Yes|No|
|`INSERT`|No|Yes|
|`UPDATE`|No|Yes|
|`DELETE`|No|Yes|
|`SELECT`|No*|No* / DQL|

The easiest mental model:

```text
             DATABASE
                │
       ┌────────┴────────┐
       │                 │
   STRUCTURE            DATA
       │                 │
      DDL                DML
       │                 │
    CREATE              INSERT
    ALTER               UPDATE
    DROP                DELETE
```

### The key distinction

```sql
CREATE TABLE users (...);
```

means:

> **"Define what a user table looks like."**

Whereas:

```sql
INSERT INTO users (...) VALUES (...);
```

means:

> **"Put an actual user into that structure."**

So, in one sentence:

> **DDL defines and changes the database's structure; DML manipulates the data stored within that structure.**



[[1 - SQL 🦬]]
[[1 - WHAT IS SQLITE3 🍕]]