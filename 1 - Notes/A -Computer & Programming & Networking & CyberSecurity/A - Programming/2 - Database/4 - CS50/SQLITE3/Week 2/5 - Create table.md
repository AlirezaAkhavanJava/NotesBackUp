

You create a table with the SQL **`CREATE TABLE`** statement.

## 1. Basic syntax

```sql
CREATE TABLE table_name (
    column_name data_type,
    column_name data_type,
    ...
);
```

For example:

```sql
CREATE TABLE users (
    id INTEGER,
    name TEXT,
    age INTEGER
);
```

This creates:

```text
users
├── id     INTEGER
├── name   TEXT
└── age    INTEGER
```

---

## 2. Primary key

Usually, you want a column that uniquely identifies every row:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    age INTEGER
);
```

Now `id` is the **primary key**.

```text
id   name    age
1    Ali     25
2    Sara    23
3    Reza    28
```

Two rows cannot have the same primary-key value.

---

## 3. Constraints

You can add rules to columns:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    age INTEGER CHECK (age >= 0)
);
```

Meaning:

|Definition|Meaning|
|---|---|
|`PRIMARY KEY`|Uniquely identifies a row|
|`NOT NULL`|Value is required|
|`UNIQUE`|No duplicate values|
|`CHECK`|Value must satisfy a condition|

---

## 4. Foreign keys

To create relationships between tables:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
);
```

Relationship:

```text
users
  │
  │ id
  ▼
posts.user_id
```

---

## 5. Using it in SQLite3

Start SQLite:

```bash
sqlite3 database.db
```

Create the table:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER
);
```

Check that it exists:

```sql
.tables
```

Output:

```text
users
```

See its definition:

```sql
.schema users
```

Output:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER
);
```

---

## 6. Then insert data

Creating the table **doesn't insert data**.

You use `INSERT`:

```sql
INSERT INTO users (name, age)
VALUES ('Ali', 25);
```

Then:

```sql
SELECT * FROM users;
```

Result:

```text
1|Ali|25
```

So the basic workflow is:

```text
CREATE TABLE
      ↓
INSERT
      ↓
SELECT
      ↓
UPDATE / DELETE
```

### One important distinction

```sql
CREATE TABLE
```

**defines the structure**.

```sql
INSERT INTO
```

**adds data**.

That distinction is fundamental to understanding SQLite and relational databases.


[[1 - WHAT IS SQLITE3]]