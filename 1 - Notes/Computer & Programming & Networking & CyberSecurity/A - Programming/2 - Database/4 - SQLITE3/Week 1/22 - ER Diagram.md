![[Pasted image 20260909164920.png]]
An **ER Diagram (Entity–Relationship Diagram)** is a visual representation of the **structure of a database**.

It shows:

1. **Entities** — things the database stores information about.
    
2. **Attributes** — properties/data belonging to an entity.
    
3. **Relationships** — how entities are connected to each other.
    
4. **Cardinality** — how many rows of one entity can relate to rows of another.
    

### Example

Suppose you're designing a database for a blogging system:

```text
┌─────────────────┐
│      USER       │
├─────────────────┤
│ PK id           │
│    username     │
│    email        │
└────────┬────────┘
         │
         │ 1
         │
         │
         │ N
┌────────▼────────┐
│      POST       │
├─────────────────┤
│ PK id           │
│ FK user_id      │
│    title        │
│    content      │
└─────────────────┘
```

This says:

```text
USER 1 ─────────── N POST
```

Meaning:

> **One user can have many posts.**

---

## The three main components

### 1. Entity

An **entity** represents a type of thing you want to store.

Examples:

```text
USER
POST
COURSE
STUDENT
ORDER
PRODUCT
```

In an actual SQLite database, an entity will usually become a **table**.

```sql
CREATE TABLE users (...);
CREATE TABLE posts (...);
```

---

### 2. Attribute

An **attribute** describes an entity.

For example:

```text
USER
├── id
├── username
├── email
└── age
```

These usually become **columns**:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT,
    email TEXT,
    age INTEGER
);
```

So:

```text
ER Diagram          SQLite

Entity       →      Table
Attribute    →      Column
Entity row   →      Row
```

---

### 3. Relationship

A **relationship** describes how entities are connected.

For example:

```text
USER ──────── POST
```

could represent:

```text
USER 1 ─────── N POST
```

Implemented in SQLite using a foreign key:

```sql
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
);
```

Here:

```text
users.id
   ▲
   │
   │ referenced by
   │
posts.user_id
```

---

## ER Diagram vs Database

Think of an ER diagram as the **blueprint** and SQLite as the **implementation**.

```text
             ER DIAGRAM
                 │
                 │ design
                 ▼
        ┌──────────────────┐
        │    DATABASE       │
        ├──────────────────┤
        │ users             │
        │ posts             │
        │ comments          │
        └──────────────────┘
                 │
                 │ implemented using
                 ▼
              SQLite
```

For example:

```text
ER Model

USER ───────< POST
  │
  │
  └────────< COMMENT
```

can become:

```text
users
posts
comments
```

with:

```sql
posts.user_id
comments.user_id
comments.post_id
```

as foreign keys.

### Important distinction

An **ER diagram is not SQL**.

It is a **database modeling/design tool** used _before or alongside_ writing SQL.

The conceptual mapping is:

```text
Entity       → Table
Attribute    → Column
Primary Key  → PK
Relationship  → Foreign Key / Junction Table
Cardinality  → Constraints + database design
```

And the relationship types you just asked about—**1:1, 1:N, and N:M**—are normally represented directly in an ER diagram.

[[1 - WHAT IS SQLITE3 🍕]]