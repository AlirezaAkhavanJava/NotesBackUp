
## DDL in SQLite3

**DDL (Data Definition Language)** is the part of SQL used to **define and modify the structure of a database**.

In SQLite, DDL primarily deals with database objects such as:

- Tables
    
- Columns
    
- Indexes
    
- Views
    
- Triggers
    

The main DDL commands you should know are:

|Command|Purpose|
|---|---|
|`CREATE`|Create a database object|
|`ALTER`|Modify an existing database object|
|`DROP`|Delete a database object|
|`VACUUM`|Rebuild/compact the database file _(SQLite-specific, not traditionally classified as DDL)_|

### 1. `CREATE`

Creates a new database object.

**Create a table:**

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT UNIQUE,
    age INTEGER
);
```

You can also create indexes:

```sql
CREATE INDEX idx_users_username
ON users(username);
```

And views:

```sql
CREATE VIEW adult_users AS
SELECT *
FROM users
WHERE age >= 18;
```

---

### 2. `ALTER`

Changes the structure of an existing object.

SQLite supports several forms, most commonly:

**Add a column:**

```sql
ALTER TABLE users
ADD COLUMN country TEXT;
```

**Rename a table:**

```sql
ALTER TABLE users
RENAME TO accounts;
```

**Rename a column:**

```sql
ALTER TABLE users
RENAME COLUMN username TO name;
```

SQLite's `ALTER TABLE` is more limited than PostgreSQL's. For complex structural changes, you often need to create a new table, copy the data, and replace the old table.

---

### 3. `DROP`

Permanently removes a database object.

**Drop a table:**

```sql
DROP TABLE users;
```

**Drop an index:**

```sql
DROP INDEX idx_users_username;
```

**Drop a view:**

```sql
DROP VIEW adult_users;
```

Be careful: `DROP TABLE` removes the table **and its data**.

---

### DDL vs DML

This distinction is important:

```text
DDL → defines the structure
DML → manipulates the data
```

For example:

**DDL:**

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT
);
```

You're defining the structure.

**DML:**

```sql
INSERT INTO users (name)
VALUES ('Alireza');
```

You're manipulating the data.

Other common DML commands are:

```sql
INSERT
UPDATE
DELETE
```

And `SELECT` is generally classified as **DQL (Data Query Language)**.

### The mental model

Think of a SQLite database like this:

```text
DATABASE
│
├── Tables
│   ├── users
│   └── posts
│
├── Indexes
│   └── idx_users_email
│
├── Views
│   └── active_users
│
└── Triggers
    └── ...
```

DDL is the SQL you use to **build and change this architecture**.


[[1 - WHAT IS SQLITE3]]