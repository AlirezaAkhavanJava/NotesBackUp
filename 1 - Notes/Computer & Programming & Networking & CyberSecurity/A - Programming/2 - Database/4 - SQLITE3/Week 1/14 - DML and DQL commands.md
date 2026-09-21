
 If **DDL defines the database structure**, then **DML manipulates the data inside that structure**, while **DQL retrieves/query that data**.

## 1. DML — Data Manipulation Language

DML commands operate on the **rows/records** stored in tables.

The main DML commands are:

```text
INSERT
UPDATE
DELETE
```

### `INSERT`

Adds new rows.

```sql
INSERT INTO users (username, email, age)
VALUES ('alireza', 'alireza@example.com', 25);
```

You can insert multiple rows:

```sql
INSERT INTO users (username, email, age)
VALUES
    ('ali', 'ali@example.com', 20),
    ('john', 'john@example.com', 30),
    ('sara', 'sara@example.com', 24);
```

---

### `UPDATE`

Modifies existing rows.

```sql
UPDATE users
SET age = 26
WHERE username = 'alireza';
```

**Important:** `WHERE` is critical.

This:

```sql
UPDATE users
SET age = 26;
```

updates **every row** in the table.

---

### `DELETE`

Removes rows.

```sql
DELETE FROM users
WHERE username = 'alireza';
```

Again, be careful with `WHERE`:

```sql
DELETE FROM users;
```

deletes **all rows** from the table.

It does **not** delete the table itself.

---

# 2. DQL — Data Query Language

DQL is primarily concerned with **retrieving data**.

The central command is:

```sql
SELECT
```

For example:

```sql
SELECT *
FROM users;
```

Select specific columns:

```sql
SELECT username, email
FROM users;
```

Filter:

```sql
SELECT username, age
FROM users
WHERE age >= 18;
```

Sort:

```sql
SELECT username, age
FROM users
ORDER BY age DESC;
```

Limit:

```sql
SELECT username
FROM users
LIMIT 10;
```

---

## DML vs DQL vs DDL

Think of them as three different layers:

```text
             SQL
              │
     ┌────────┼────────┐
     │        │        │
    DDL      DML      DQL
     │        │        │
 Structure   Data     Query
     │        │        │
 CREATE     INSERT   SELECT
 ALTER      UPDATE
 DROP       DELETE
```

### Example workflow

First, **DDL** creates the table:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    age INTEGER
);
```

Then **DML** puts data into it:

```sql
INSERT INTO users (username, age)
VALUES ('alireza', 25);
```

Then **DQL** retrieves it:

```sql
SELECT username, age
FROM users
WHERE age >= 18;
```

Then **DML** can modify it:

```sql
UPDATE users
SET age = 26
WHERE username = 'alireza';
```

And finally another **DQL** query:

```sql
SELECT *
FROM users;
```

### One distinction worth remembering

```text
DDL → What does the database look like?
DML → What data is inside it / how do I change it?
DQL → What data do I want to retrieve?
```

For SQLite3, that's a very useful mental model. One nuance: SQL command classifications aren't completely standardized across all textbooks/databases; some classify `SELECT` under DML rather than DQL, but treating `SELECT` as **DQL** is extremely common and useful for learning.

[[1 - WHAT IS SQLITE3 🍕]]