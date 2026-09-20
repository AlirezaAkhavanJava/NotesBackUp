
## 1. What is a schema?

A **database schema** is the definition of the **structure of a database**.

It describes things such as:

- Tables
    
- Columns
    
- Data types / type affinities
    
- Primary keys
    
- Foreign keys
    
- Constraints
    
- Indexes
    
- Views
    
- Triggers
    

Think of it as the **blueprint of the database**.

```text
Schema
│
├── Tables
│   ├── columns
│   ├── data types
│   ├── primary keys
│   └── foreign keys
│
├── Indexes
├── Views
└── Triggers
```

---

# 2. Why do we need a schema?

Without a defined structure, a database would have difficulty enforcing what the data is supposed to look like.

For example, imagine storing users:

```text
Alireza, 25
John, thirty
Sarah, -500
```

What does each value mean?

A schema lets us define rules:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER CHECK (age >= 0)
);
```

Now the database knows:

```text
id   → identifier
name → text, required
age  → integer, cannot be negative
```

So the schema provides:

### 1. Structure

Defines how data is organized.

### 2. Integrity

Prevents invalid relationships and values.

### 3. Relationships

Defines how tables relate through foreign keys.

### 4. Consistency

Makes sure different parts of your application follow the same structure.

### 5. Communication

The schema tells developers:

> "This is how this database is designed."

---

# 3. How do you create a schema in SQLite?

Here's an important SQLite-specific detail:

**SQLite does not have PostgreSQL-style `CREATE SCHEMA` namespaces.**

You don't normally do:

```sql
CREATE SCHEMA my_schema;
```

Instead, in SQLite, you **create the schema by creating its database objects**.

For example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_posts_user_id
ON posts(user_id);
```

Together, these definitions constitute part of the database's **schema**.

---

# 4. Complete example

Suppose we're designing a bookstore.

First create/open the database:

```bash
sqlite3 bookstore.db
```

Then define the schema:

```sql
CREATE TABLE authors (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE books (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER NOT NULL,
    price REAL CHECK (price >= 0),
    FOREIGN KEY (author_id) REFERENCES authors(id)
);

CREATE INDEX idx_books_author
ON books(author_id);
```

Now the structure is:

```text
bookstore.db
│
├── authors
│   ├── id
│   └── name
│
├── books
│   ├── id
│   ├── title
│   ├── author_id ──────→ authors.id
│   └── price
│
└── idx_books_author
```

That's your **database schema**.

Then DML operates on it:

```sql
INSERT INTO authors (name)
VALUES ('George Orwell');

INSERT INTO books (title, author_id, price)
VALUES ('1984', 1, 12.99);
```

The distinction is:

```text
SCHEMA / DDL
    ↓
Define the structure
    ↓
┌──────────────┐
│ authors      │
│ books        │
│ relationships│
└──────────────┘
    ↓
DML
    ↓
INSERT / UPDATE / DELETE
    ↓
Actual data
```

---

# 5. How to see the schema in SQLite

In the SQLite CLI:

```text
.schema
```

Show a particular table:

```text
.schema books
```

List tables:

```text
.tables
```

You can also inspect SQLite's internal schema:

```sql
SELECT name, type, sql
FROM sqlite_schema;
```

SQLite stores the definitions of its schema objects in `sqlite_schema`.

---

# 6. Schema vs table

These are **not the same thing**.

### Table

A table is one structure that stores rows:

```text
users
├── id
├── name
└── age
```

### Schema

The schema describes the **whole database structure**:

```text
Database Schema
│
├── users
├── posts
├── comments
├── indexes
├── views
└── triggers
```

So:

> **A table is part of a schema; a schema is the overall structural definition of the database.**

---

## One important SQLite distinction

If you later learn PostgreSQL, you'll encounter:

```sql
CREATE SCHEMA accounting;
```

There, **schema** is also a database namespace/container that can contain tables.

SQLite's terminology is different: it has a **database schema**, but not PostgreSQL's same schema/namespace system.

That distinction is important when moving from **SQLite → PostgreSQL**.


[[1 - WHAT IS SQLITE3]]