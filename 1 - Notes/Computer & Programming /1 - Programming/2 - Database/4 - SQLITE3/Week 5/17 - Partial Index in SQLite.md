

A **partial index** is an index that contains entries **only for rows that satisfy a `WHERE` condition**.

Normally:

```sql
CREATE INDEX idx_movies_title
ON movies(title);
```

indexes **every row** in `movies`.

A partial index lets you say:

```sql
CREATE INDEX idx_movies_title
ON movies(title)
WHERE status = 'AVAILABLE';
```

Now the index contains only rows where:

```text
status = 'AVAILABLE'
```

---

## Why would we want that?

Imagine:

```text
movies = 1,000,000 rows

AVAILABLE   = 100,000
DELETED     = 900,000
```

Your application frequently does:

```sql
SELECT *
FROM movies
WHERE status = 'AVAILABLE'
  AND title = 'Cars';
```

A normal index:

```sql
CREATE INDEX idx_title
ON movies(title);
```

has entries for all 1,000,000 rows.

A partial index:

```sql
CREATE INDEX idx_available_title
ON movies(title)
WHERE status = 'AVAILABLE';
```

has entries only for the 100,000 available rows.

Conceptually:

```text
Normal index

title → row
----------------
all 1,000,000 rows


Partial index

title → row
----------------
AVAILABLE rows only
```

That can make the index **smaller**, reduce maintenance work for rows outside the condition, and make relevant queries faster.

---

## How SQLite uses it

You create:

```sql
CREATE INDEX idx_available_title
ON movies(title)
WHERE status = 'AVAILABLE';
```

Then:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE status = 'AVAILABLE'
  AND title = 'Cars';
```

SQLite can use:

```text
SEARCH movies USING INDEX idx_available_title (title=?)
```

The important thing is that your query includes the condition that makes the partial index applicable:

```sql
WHERE status = 'AVAILABLE'
```

because SQLite knows:

```text
idx_available_title
    ↓
contains only AVAILABLE rows
```

So it can safely use it.

---

## A very common backend example: soft deletion

This is where partial indexes become especially useful.

Suppose:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    email TEXT NOT NULL,
    deleted_at TEXT
);
```

You use:

```text
deleted_at IS NULL
```

to mean the user is active.

Your application frequently does:

```sql
SELECT *
FROM users
WHERE email = ?
  AND deleted_at IS NULL;
```

You could create:

```sql
CREATE INDEX idx_active_user_email
ON users(email)
WHERE deleted_at IS NULL;
```

Now the index contains only active users.

That's often much better than indexing every user when deleted records are never relevant to that lookup.

---

## Important limitation

A partial index is **not the same thing as a filtered query cache**.

For:

```sql
CREATE INDEX idx_available_title
ON movies(title)
WHERE status = 'AVAILABLE';
```

SQLite does **not** store only the `title` values permanently detached from the table.

It's still a normal B-tree index, except rows that don't satisfy the predicate aren't included.

So conceptually:

```text
movies table
│
├── Cars       AVAILABLE  → in index
├── Avatar     DELETED    → not in index
├── Jaws       AVAILABLE  → in index
└── Matrix     DELETED    → not in index
```

---

## When partial indexes are particularly useful

They shine when:

```text
most rows don't matter to a particular workload
```

Examples:

```sql
-- Active users only
CREATE INDEX idx_active_email
ON users(email)
WHERE deleted_at IS NULL;
```

```sql
-- Failed jobs only
CREATE INDEX idx_failed_jobs
ON jobs(created_at)
WHERE status = 'FAILED';
```

```sql
-- Unprocessed messages only
CREATE INDEX idx_pending_messages
ON messages(created_at)
WHERE processed = 0;
```

The general idea is:

> **Don't build an index over data your query will never care about.**



[[SQlite]]