
In SQL, **Relation** and **Relating** are closely connected concepts, especially when you move from a single table to a database containing multiple tables.

## 1. Relation

A **relation** is essentially a **table** in the relational model.

For example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT,
    email TEXT
);
```

Conceptually:

```text
users
┌────┬──────────┬─────────────────┐
│ id │ username │ email           │
├────┼──────────┼─────────────────┤
│ 1  │ alireza  │ a@example.com   │
│ 2  │ john     │ j@example.com   │
└────┴──────────┴─────────────────┘
```

In relational database terminology:

- **Relation** → the table
    
- **Tuple** → a row
    
- **Attribute** → a column
    
- **Value** → the data stored in a cell
    

So:

```text
Relation
   ↓
users table
   ↓
Rows (tuples)
   ↓
Columns (attributes)
```

> In practical SQLite programming, you'll usually hear **"table"** rather than "relation," but "relation" is the formal relational-database term.

---

# 2. Relating

**Relating** means establishing a logical connection between two or more relations (tables).

Suppose you have:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT,
    user_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

Now you have:

```text
users
┌────┬──────────┐
│ id │ username │
├────┼──────────┤
│ 1  │ alireza  │
│ 2  │ john     │
└────┴──────────┘
       │
       │ users.id
       │
       ▼
posts
┌────┬────────────┬─────────┐
│ id │ title      │ user_id │
├────┼────────────┼─────────┤
│ 1  │ Hello      │ 1       │
│ 2  │ SQL Rocks  │ 1       │
│ 3  │ SQLite     │ 2       │
└────┴────────────┴─────────┘
```

Here:

```text
users.id
   ↑
   │
posts.user_id
```

is the **relationship** between the two tables.

`posts.user_id` is a **foreign key** referencing `users.id`.

---

# 3. Relating tables with JOIN

Once tables are related, you can retrieve information from them together using `JOIN`.

```sql
SELECT
    users.username,
    posts.title
FROM users
JOIN posts
    ON users.id = posts.user_id;
```

Result:

```text
username    title
----------  ---------
alireza     Hello
alireza     SQL Rocks
john        SQLite
```

The important part is:

```sql
ON users.id = posts.user_id
```

This tells SQLite **how the two relations are related**.

---

# 4. Types of relationships

The most common relational patterns are:

### One-to-One

One record corresponds to one record.

```text
Person ─────── Passport
  1                1
```

### One-to-Many

One record corresponds to many records.

```text
User ───────< Posts
  1             *
```

For example:

```text
Alireza
   │
   ├── Post 1
   ├── Post 2
   └── Post 3
```

This is probably the most common relationship you'll encounter.

### Many-to-Many

Many records correspond to many records.

```text
Students >──── Courses
```

This normally requires a **junction/association table**:

```text
students
   │
   │
   ▼
student_courses
   ▲
   │
   │
courses
```

For example:

```sql
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

---

## The key distinction

Think about it this way:

```text
RELATION
   ↓
A table

RELATIONSHIP
   ↓
The logical connection between tables

RELATING
   ↓
The process of connecting tables,
usually through keys and JOINs
```

And this is exactly what **CS50 SQL Lecture 1 — "Relating"** is getting at: instead of putting everything into one giant table, you **normalize information into separate relations and establish relationships between them** using keys.

[[1 - WHAT IS SQLITE3 🍕]]