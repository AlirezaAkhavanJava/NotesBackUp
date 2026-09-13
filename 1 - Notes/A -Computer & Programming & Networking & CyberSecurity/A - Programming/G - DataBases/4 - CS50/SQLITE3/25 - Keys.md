
## Keys in SQLite3

A **key** is a column (or set of columns) used to uniquely identify or link rows in a table. SQLite3 supports the same key concepts as most relational databases, though it enforces them a bit more loosely than something like PostgreSQL.

### 1. Primary Key

Uniquely identifies each row in a table. No two rows can have the same primary key value, and it can't be NULL.

```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
```

**Problem it solves:** Without a primary key, you have no reliable way to reference a _specific_ row. If two students are both named "Sam," how do you update just one of them? The primary key (`id`) gives every row a unique handle.

In SQLite3, `INTEGER PRIMARY KEY` is special — it becomes an alias for the hidden `rowid` column and auto-increments by default, so you rarely need to specify values manually.

### 2. Foreign Key

A column in one table that references the primary key of another table.

```sql
CREATE TABLE enrollments (
    id INTEGER PRIMARY KEY,
    student_id INTEGER,
    course_id INTEGER,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

**Problem it solves:** Prevents **data inconsistency**. Without foreign keys, nothing stops you from inserting an `enrollments` row pointing to a `student_id` that doesn't exist. Foreign keys enforce **referential integrity** — you can't reference something that isn't there, and (depending on settings) you can't delete a student who still has enrollments without explicitly handling that.

⚠️ Important SQLite3 gotcha: foreign key enforcement is **off by default**. You have to turn it on per connection:

```sql
PRAGMA foreign_keys = ON;
```

### 3. Composite Key

A primary key made of multiple columns together.

```sql
CREATE TABLE enrollments (
    student_id INTEGER,
    course_id INTEGER,
    PRIMARY KEY (student_id, course_id)
);
```

**Problem it solves:** Sometimes no single column is unique, but a _combination_ is. Here, a student can enroll in many courses and a course can have many students, but the same student can't enroll in the same course twice — the composite key enforces that.

### 4. Unique Key

Like a primary key, but a table can have several, and it _can_ allow one NULL (depending on setup).

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    email TEXT UNIQUE
);
```

**Problem it solves:** Enforces uniqueness on columns that aren't the primary identifier but still shouldn't repeat — like email addresses or usernames.

### The underlying theme

All of these exist to solve two core problems:

1. **Identification** — how do I uniquely point to one row?
2. **Integrity** — how do I keep relationships between tables honest, so the database doesn't end up full of orphaned or duplicate data?




[[1 - WHAT IS SQLITE3]]