
## SQLite3 Constraints

A **constraint** is a rule that SQLite enforces on your data.

```text
Constraint → "What values are allowed in this table?"
```

The major ones are:

|Constraint|Purpose|
|---|---|
|`PRIMARY KEY`|Uniquely identifies a row|
|`FOREIGN KEY`|Establishes a relationship between tables|
|`NOT NULL`|Prevents `NULL` values|
|`UNIQUE`|Prevents duplicate values|
|`CHECK`|Enforces a condition|
|`DEFAULT`|Provides a value when one isn't supplied|

---

### 1. `PRIMARY KEY`

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT
);
```

`id` uniquely identifies each user.

```text
1 → Alireza
2 → John
3 → Sara
```

---

### 2. `FOREIGN KEY`

Creates a relationship between tables.

```sql
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT,
    user_id INTEGER,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
);
```

```text
users.id
   ↑
   │
posts.user_id
```

Remember to enable foreign-key enforcement in SQLite:

```sql
PRAGMA foreign_keys = ON;
```

---

### 3. `NOT NULL`

Requires a value.

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL
);
```

This fails:

```sql
INSERT INTO users (username)
VALUES (NULL);
```

---

### 4. `UNIQUE`

Prevents duplicate values.

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE
);
```

This is valid:

```text
alireza
john
sara
```

But this isn't:

```text
alireza
alireza  ← duplicate
```

You can also use it on multiple columns:

```sql
CREATE TABLE memberships (
    user_id INTEGER,
    group_id INTEGER,

    UNIQUE (user_id, group_id)
);
```

This prevents the **same user from being assigned to the same group twice**.

---

### 5. `CHECK`

Requires a condition to be true.

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    age INTEGER CHECK (age >= 0)
);
```

This is invalid:

```sql
INSERT INTO users (age)
VALUES (-5);
```

You can make more complex rules:

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    price REAL CHECK (price >= 0),
    stock INTEGER CHECK (stock >= 0)
);
```

Now SQLite enforces:

```text
price >= 0
stock >= 0
```

---

### 6. `DEFAULT`

Provides a value automatically when one isn't specified.

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    active INTEGER DEFAULT 1
);
```

Then:

```sql
INSERT INTO users (username)
VALUES ('alireza');
```

SQLite effectively gives:

```text
username → alireza
active   → 1
```

---

# Combining the Rules

In real database design, you'll commonly combine them:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    age INTEGER CHECK (age >= 0),
    active INTEGER NOT NULL DEFAULT 1
);
```

Here you've established:

```text
id       → PRIMARY KEY
username → NOT NULL + UNIQUE
email    → NOT NULL + UNIQUE
age      → CHECK
active   → NOT NULL + DEFAULT
```

And for relationships:

```sql
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
);
```

This is the foundation of **relational database integrity**:

```text
                 DATABASE
                    │
          ┌─────────┴─────────┐
          │                   │
        users                posts
          │                   │
     PRIMARY KEY ◄──── FOREIGN KEY
          │
       UNIQUE
          │
      NOT NULL
          │
       CHECK
          │
      DEFAULT
```

### The senior-level mental model

Don't think of constraints as decoration. They're **invariants enforced by the database**.

For example:

```sql
age INTEGER CHECK (age >= 0)
```

means:

> **The database must never contain a user whose age is negative.**

That's much stronger than merely checking the value in your Java application. Your Java code, another application, a script, or a SQL client all have to obey the same database invariant.

[[1 - WHAT IS SQLITE3]]