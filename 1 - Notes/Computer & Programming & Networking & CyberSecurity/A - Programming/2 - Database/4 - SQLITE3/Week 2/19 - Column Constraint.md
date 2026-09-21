

A **column constraint** is a rule defined on a column that restricts what values can be stored in that column.

### Syntax

```sql
column_name DATA_TYPE CONSTRAINT
```

### Example

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT UNIQUE,
    age INTEGER CHECK (age >= 18),
    country TEXT DEFAULT 'Germany'
);
```

Here, each constraint is attached directly to a column:

|Constraint|Example|Meaning|
|---|---|---|
|`PRIMARY KEY`|`id INTEGER PRIMARY KEY`|Uniquely identifies a row|
|`NOT NULL`|`username TEXT NOT NULL`|Cannot contain `NULL`|
|`UNIQUE`|`email TEXT UNIQUE`|Cannot contain duplicate values|
|`CHECK`|`age INTEGER CHECK (age >= 18)`|Value must satisfy a condition|
|`DEFAULT`|`country TEXT DEFAULT 'Germany'`|Uses a value when none is provided|
|`COLLATE`|`name TEXT COLLATE NOCASE`|Defines text comparison behavior|
|`REFERENCES`|`user_id INTEGER REFERENCES users(id)`|References another table|

### Simple example

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price REAL CHECK (price > 0),
    sku TEXT UNIQUE,
    stock INTEGER DEFAULT 0
);
```

Think of it as:

```text
Column
  │
  ├── Data Type
  │
  └── Constraints
       ├── PRIMARY KEY
       ├── NOT NULL
       ├── UNIQUE
       ├── CHECK
       ├── DEFAULT
       └── REFERENCES
```

**Definition:** A column constraint is a rule attached to a specific column that controls the values permitted in that column.


[[1 - SQL 🥞]]
[[1 - WHAT IS SQLITE3 🍕]]