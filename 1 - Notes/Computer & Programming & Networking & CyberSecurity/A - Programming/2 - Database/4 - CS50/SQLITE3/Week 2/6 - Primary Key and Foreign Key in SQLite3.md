


These two concepts are fundamental to relational databases:

- **Primary Key (PK)** → uniquely identifies a row.
    
- **Foreign Key (FK)** → connects a row to a row in another table.
    

---

## 1. Create a Primary Key

Use `PRIMARY KEY` when defining the column:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT
);
```

Now `id` is the primary key.

```text
users
+----+------+
| id | name |
+----+------+
| 1  | Ali  |
| 2  | Sara |
| 3  | Reza |
+----+------+
```

Each `id` uniquely identifies a user.

You can also explicitly write:

```sql
CREATE TABLE users (
    id INTEGER,
    name TEXT,
    PRIMARY KEY (id)
);
```

Both are valid.

---

# 2. Create a Foreign Key

Suppose you have:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

Now create posts:

```sql
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    user_id INTEGER,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
);
```

Here:

```text
users
+----+------+
| id | name |
+----+------+
| 1  | Ali  |
| 2  | Sara |
+----+------+

             ▲
             │
             │ references
             │
posts        │
+----+-------+----------+
| id | title | user_id  |
+----+-------+----------+
| 1  | Hello | 1        |
| 2  | SQL   | 2        |
+----+-------+----------+
```

`posts.user_id` is the **foreign key**.

It references:

```text
users.id
```

---

# 3. Why use a Foreign Key?

Without a foreign key, you could accidentally do:

```sql
INSERT INTO posts (title, user_id)
VALUES ('Hello', 999);
```

even though user `999` doesn't exist.

A foreign-key constraint tells the database:

> `posts.user_id` must refer to an existing `users.id`.

---

# 4. Enable Foreign Keys in SQLite

This is an important SQLite-specific detail.

SQLite supports foreign keys, but you should enable enforcement for the connection:

```sql
PRAGMA foreign_keys = ON;
```

Check it:

```sql
PRAGMA foreign_keys;
```

You should get:

```text
1
```

Then:

```sql
INSERT INTO posts (title, user_id)
VALUES ('Hello', 999);
```

will fail because user `999` doesn't exist.

---

# 5. Primary Key + Foreign Key together

A typical relational design:

```sql
CREATE TABLE authors (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE books (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id)
        REFERENCES authors(id)
);
```

You now have:

```text
authors
┌────┬────────┐
│ id │ name   │
├────┼────────┤
│ 1  │ Tolkien│
│ 2  │ Orwell │
└────┴────────┘
       ▲
       │
       │ author_id
       │
books  │
┌────┬───────────────┬───────────┐
│ id │ title         │ author_id │
├────┼───────────────┼───────────┤
│ 1  │ 1984          │ 2         │
│ 2  │ The Hobbit    │ 1         │
└────┴───────────────┴───────────┘
```

The relationship is:

```text
books.author_id
       │
       ▼
authors.id
```

---

# 6. Composite Primary Key

Sometimes a table needs **more than one column** to uniquely identify a row.

For example, students enrolling in courses:

```sql
CREATE TABLE enrollments (
    student_id INTEGER,
    course_id INTEGER,

    PRIMARY KEY (student_id, course_id),

    FOREIGN KEY (student_id)
        REFERENCES students(id),

    FOREIGN KEY (course_id)
        REFERENCES courses(id)
);
```

Here the combination:

```text
(student_id, course_id)
```

must be unique.

So:

```text
student 1 + course 10   → valid
student 1 + course 20   → valid
student 2 + course 10   → valid
student 1 + course 10   → duplicate
```

This is extremely common for **many-to-many relationships**.

---

## The mental model

```text
PRIMARY KEY
     │
     ▼
"Who/what is this row?"
     │
     └── uniquely identifies the row


FOREIGN KEY
     │
     ▼
"What other row is this related to?"
     │
     └── references another table's primary/unique key
```

And the SQL pattern to memorize is:

```sql
CREATE TABLE parent (
    id INTEGER PRIMARY KEY
);

CREATE TABLE child (
    id INTEGER PRIMARY KEY,
    parent_id INTEGER,

    FOREIGN KEY (parent_id)
        REFERENCES parent(id)
);
```

That's the fundamental **PK → FK relationship** you'll use throughout SQLite, PostgreSQL, Spring Data JPA, and relational database design.



[[1 - WHAT IS SQLITE3]]