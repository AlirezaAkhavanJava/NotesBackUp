

A **table constraint** is a rule defined at the **table level** that restricts or validates the data that can be stored in a table.

In SQLite, constraints help maintain **data integrity** — they prevent invalid or inconsistent data from entering your database.

### Main SQLite constraints

|Constraint|Purpose|
|---|---|
|`PRIMARY KEY`|Uniquely identifies each row|
|`FOREIGN KEY`|Links a column to a key in another table|
|`UNIQUE`|Prevents duplicate values|
|`NOT NULL`|Prevents `NULL` values|
|`CHECK`|Requires a condition to be true|
|`DEFAULT`|Provides a value when none is supplied|

### Column constraint vs table constraint

Some constraints can be written directly after a column:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT UNIQUE
);
```

These are **column constraints**.

A **table constraint** is written separately, usually after the column definitions:

```sql
CREATE TABLE users (
    id INTEGER,
    username TEXT NOT NULL,
    email TEXT,

    PRIMARY KEY (id),
    UNIQUE (username, email)
);
```

Here:

```sql
PRIMARY KEY (id)
UNIQUE (username, email)
```

are **table constraints**.

The important distinction is that a table constraint can operate on **multiple columns**.

For example:

```sql
CREATE TABLE enrollments (
    student_id INTEGER,
    course_id INTEGER,

    PRIMARY KEY (student_id, course_id)
);
```

This creates a **composite primary key**. The combination of `student_id` and `course_id` must be unique.

### Mental model

Think of it like this:

```text
TABLE
│
├── Columns
│   ├── id INTEGER
│   ├── username TEXT
│   └── email TEXT
│
└── Constraints
    ├── PRIMARY KEY
    ├── FOREIGN KEY
    ├── UNIQUE
    └── CHECK
```

**In short:** a table constraint is a database rule attached to the table, especially useful when the rule involves **multiple columns or relationships between columns**.


[[1 - WHAT IS SQLITE3 🍕]]