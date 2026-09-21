


## 1. Definition

**DML (Data Manipulation Language)** is the part of SQL used to **work with the data stored inside database tables**.

In SQLite3, the main DML statements are:

|Statement|Purpose|
|---|---|
|`SELECT`|Read/query data|
|`INSERT`|Add new data|
|`UPDATE`|Modify existing data|
|`DELETE`|Remove data|

Think:

> **DDL defines the structure; DML manipulates the contents.**

```text
Database
│
├── DDL → defines structure
│   ├── CREATE
│   ├── ALTER
│   └── DROP
│
└── DML → manipulates data
    ├── SELECT
    ├── INSERT
    ├── UPDATE
    └── DELETE
```

---

# 2. `INSERT` — Create rows

Adds new rows to a table.

### Syntax

```sql
INSERT INTO table_name (column1, column2, ...)
VALUES (value1, value2, ...);
```

Example:

```sql
INSERT INTO users (name, age)
VALUES ('Alireza', 25);
```

Multiple rows:

```sql
INSERT INTO users (name, age)
VALUES
    ('Alireza', 25),
    ('John', 30),
    ('Sarah', 28);
```

You can also insert from another query:

```sql
INSERT INTO users (name, age)
SELECT name, age
FROM old_users;
```

---

# 3. `SELECT` — Read rows

Retrieves data.

### Basic syntax

```sql
SELECT column1, column2
FROM table_name;
```

Example:

```sql
SELECT name, age
FROM users;
```

All columns:

```sql
SELECT *
FROM users;
```

With filtering:

```sql
SELECT *
FROM users
WHERE age >= 18;
```

With sorting:

```sql
SELECT *
FROM users
ORDER BY age DESC;
```

With grouping:

```sql
SELECT age, COUNT(*)
FROM users
GROUP BY age;
```

`SELECT` is technically often classified separately as **DQL (Data Query Language)** rather than DML, depending on the SQL classification system. In practical SQLite discussions, however, it is frequently grouped with data-manipulation operations.

---

# 4. `UPDATE` — Modify rows

Changes existing data.

### Syntax

```sql
UPDATE table_name
SET column1 = value1,
    column2 = value2
WHERE condition;
```

Example:

```sql
UPDATE users
SET age = 26
WHERE id = 1;
```

Multiple columns:

```sql
UPDATE users
SET name = 'Alireza',
    age = 26
WHERE id = 1;
```

### Critical rule

Be extremely careful with `UPDATE` without `WHERE`.

```sql
UPDATE users
SET age = 26;
```

This changes **every row**.

---

# 5. `DELETE` — Remove rows

Deletes rows from a table.

### Syntax

```sql
DELETE FROM table_name
WHERE condition;
```

Example:

```sql
DELETE FROM users
WHERE id = 5;
```

Again, `WHERE` is important.

```sql
DELETE FROM users;
```

This deletes **all rows** from `users`.

It does **not** normally delete the table itself.

---

# 6. DML with conditions

DML commonly works together with `WHERE`.

```sql
WHERE condition
```

Example:

```sql
UPDATE users
SET age = age + 1
WHERE age >= 18;
```

The logical flow is:

```text
Table
  ↓
WHERE → choose rows
  ↓
DML operation
  ↓
INSERT / UPDATE / DELETE
```

For `SELECT`:

```text
Table
  ↓
WHERE → choose rows
  ↓
SELECT → return them
```

---

# 7. DML and constraints

DML must obey the table's constraints.

For example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    age INTEGER CHECK (age >= 0)
);
```

This can fail:

```sql
INSERT INTO users (username, age)
VALUES (NULL, 25);
```

because of:

```sql
NOT NULL
```

This can also fail:

```sql
INSERT INTO users (username, age)
VALUES ('alireza', -5);
```

because of:

```sql
CHECK (age >= 0)
```

So:

```text
DML
 ↓
Database constraints
 ↓
Valid → operation succeeds
Invalid → operation fails
```

---

# 8. DML + transactions

DML operations can be controlled using transactions.

```sql
BEGIN TRANSACTION;

UPDATE users
SET age = age + 1
WHERE id = 1;

DELETE FROM users
WHERE id = 5;

COMMIT;
```

If something goes wrong:

```sql
ROLLBACK;
```

Mental model:

```text
BEGIN
  ↓
INSERT / UPDATE / DELETE
  ↓
COMMIT     → permanently apply transaction
   or
ROLLBACK   → undo transaction
```

This is extremely important in real applications because multiple DML operations can be treated as **one atomic unit of work**.

---

# 9. SQLite3 DML commands vs SQLite CLI commands

Don't confuse SQL statements with SQLite's command-line commands.

### SQL / DML

```sql
INSERT INTO users ...;
SELECT * FROM users;
UPDATE users ...;
DELETE FROM users ...;
```

### SQLite CLI commands

```text
.tables
.schema users
.headers on
.mode column
.quit
```

The commands beginning with `.` are **SQLite shell commands**, not SQL/DML.

---

# 10. Complete example

Create the table:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    age INTEGER
);
```

Insert:

```sql
INSERT INTO users (username, age)
VALUES ('Alireza', 25);
```

Read:

```sql
SELECT *
FROM users;
```

Update:

```sql
UPDATE users
SET age = 26
WHERE username = 'Alireza';
```

Read again:

```sql
SELECT *
FROM users
WHERE age >= 18;
```

Delete:

```sql
DELETE FROM users
WHERE username = 'Alireza';
```

---

## The mental model

```text
                 SQL
                  │
       ┌──────────┴──────────┐
       │                     │
      DDL                   DML
       │                     │
 Structure                Data
       │                     │
 CREATE                  INSERT
 ALTER                   UPDATE
 DROP                    DELETE
                         SELECT*
```

And the most important distinction:

> **DDL changes the database structure. DML changes the data inside that structure.**

* `SELECT` is commonly treated as DQL in stricter SQL terminology, although it is often discussed alongside DML.


[[1 - WHAT IS SQLITE3 🍕]]