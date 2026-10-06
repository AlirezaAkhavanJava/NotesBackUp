
 **Soft deletion + Views** is a very useful SQLite design pattern, especially when you want deleted records to remain in the database but behave as if they are gone.

## 1. The problem

Suppose you have:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL
);
```

Normally, deleting a user means:

```sql
DELETE FROM users
WHERE id = 5;
```

The row is physically removed.

With **soft deletion**, you don't remove it. You mark it:

```text
id | username | email          | deleted
---+----------+----------------+--------
1  | alice    | alice@mail.com | 0
2  | bob      | bob@mail.com   | 1
3  | john     | john@mail.com  | 0
```

`deleted = 1` means "logically deleted."

---

# 2. Designing the table

A simple design:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
);
```

SQLite doesn't have a native Boolean type, so conventionally:

```text
0 = false
1 = true
```

You can make the intent clearer:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
        CHECK (is_deleted IN (0, 1))
);
```

Now you have an invariant:

```text
is_deleted can ONLY be 0 or 1
```

---

# 3. Soft deleting

Instead of:

```sql
DELETE FROM users
WHERE id = 5;
```

you do:

```sql
UPDATE users
SET is_deleted = 1
WHERE id = 5;
```

The row still physically exists.

You can verify:

```sql
SELECT * FROM users;
```

and get:

```text
1|alice|alice@mail.com|0
2|bob|bob@mail.com|1
3|john|john@mail.com|0
```

---

# 4. The problem this creates

Every query now needs:

```sql
WHERE is_deleted = 0
```

For example:

```sql
SELECT *
FROM users
WHERE is_deleted = 0;
```

And:

```sql
SELECT username
FROM users
WHERE is_deleted = 0
ORDER BY username;
```

And:

```sql
SELECT *
FROM users
WHERE email = 'bob@mail.com'
AND is_deleted = 0;
```

This becomes annoying and, more importantly, **easy to forget**.

That's where a **VIEW** becomes useful.

---

# 5. Create a "normal users" View

Create:

```sql
CREATE VIEW active_users AS
SELECT
    id,
    username,
    email
FROM users
WHERE is_deleted = 0;
```

Now:

```sql
SELECT *
FROM active_users;
```

behaves conceptually like:

```text
users
       |
       | WHERE is_deleted = 0
       v
 active_users
```

You have created a **logical interface over your table**.

---

# 6. Why this is powerful

Your application can query:

```sql
SELECT *
FROM active_users;
```

instead of repeatedly writing:

```sql
SELECT *
FROM users
WHERE is_deleted = 0;
```

So your database design becomes:

```text
                 users
                   |
          +--------+--------+
          |                 |
    is_deleted = 0    is_deleted = 1
          |                 |
          v                 v
   active_users       deleted_users
       VIEW                VIEW
```

You could create both:

```sql
CREATE VIEW active_users AS
SELECT *
FROM users
WHERE is_deleted = 0;
```

and:

```sql
CREATE VIEW deleted_users AS
SELECT *
FROM users
WHERE is_deleted = 1;
```

Then:

```sql
SELECT * FROM active_users;
```

gives normal users.

And:

```sql
SELECT * FROM deleted_users;
```

gives your recycle bin.

---

# 7. Views are dynamic

This is important.

A View doesn't normally store a second copy of the rows.

Suppose:

```sql
CREATE VIEW active_users AS
SELECT *
FROM users
WHERE is_deleted = 0;
```

Initially:

```text
users

1 | Alice | 0
2 | Bob   | 0
```

Then:

```sql
UPDATE users
SET is_deleted = 1
WHERE id = 1;
```

Now:

```sql
SELECT * FROM active_users;
```

immediately gives:

```text
2 | Bob | 0
```

The View reflects the underlying table.

Think:

```text
VIEW = saved SELECT
```

not:

```text
VIEW = copied table
```

---

# 8. Restoring a deleted row

This is another advantage of soft deletion.

```sql
UPDATE users
SET is_deleted = 0
WHERE id = 1;
```

Now Alice appears again:

```sql
SELECT *
FROM active_users;
```

```text
1 | Alice | 0
2 | Bob   | 0
```

You have essentially implemented a recycle bin.

---

# 9. Better production design: deletion timestamp

Instead of:

```sql
is_deleted INTEGER
```

you can use:

```sql
deleted_at TEXT
```

For example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    deleted_at TEXT
);
```

Active:

```text
deleted_at = NULL
```

Deleted:

```text
deleted_at = '2026-10-05 12:20:00'
```

Then:

```sql
UPDATE users
SET deleted_at = CURRENT_TIMESTAMP
WHERE id = 5;
```

Your View becomes:

```sql
CREATE VIEW active_users AS
SELECT
    id,
    username,
    email
FROM users
WHERE deleted_at IS NULL;
```

And:

```sql
CREATE VIEW deleted_users AS
SELECT
    id,
    username,
    email,
    deleted_at
FROM users
WHERE deleted_at IS NOT NULL;
```

I generally prefer `deleted_at` when you care about **auditability**, because you know **when** the deletion happened.

---

# 10. Soft deletion + audit information

You can go further:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,

    deleted_at TEXT,
    deleted_by INTEGER
);
```

Now deletion can mean:

```text
deleted_at = when
deleted_by = who
```

For example:

```text
id | username | deleted_at           | deleted_by
---+----------+----------------------+-----------
1  | alice    | NULL                 | NULL
2  | bob      | 2026-10-05 12:20:00  | 42
```

This is much closer to what you'd see in a serious backend system.

---

# 11. The important distinction

Don't confuse these three concepts:

### Physical deletion

```sql
DELETE FROM users WHERE id = 5;
```

The row disappears.

### Soft deletion

```sql
UPDATE users
SET deleted_at = CURRENT_TIMESTAMP
WHERE id = 5;
```

The row remains but is logically deleted.

### View

```sql
CREATE VIEW active_users AS
SELECT *
FROM users
WHERE deleted_at IS NULL;
```

The View doesn't delete anything.

It simply gives you a **filtered logical representation** of the table.

---

# 12. A good SQLite design

For your practice database, I'd use:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TEXT
);
```

Then:

```sql
CREATE VIEW active_users AS
SELECT
    id,
    username,
    email,
    created_at
FROM users
WHERE deleted_at IS NULL;
```

```sql
CREATE VIEW deleted_users AS
SELECT
    id,
    username,
    email,
    created_at,
    deleted_at
FROM users
WHERE deleted_at IS NOT NULL;
```

Your application primarily works with:

```sql
SELECT * FROM active_users;
```

while administrative/recovery functionality can use:

```sql
SELECT * FROM deleted_users;
```

And deletion is:

```sql
UPDATE users
SET deleted_at = CURRENT_TIMESTAMP
WHERE id = ?;
```

Restoration:

```sql
UPDATE users
SET deleted_at = NULL
WHERE id = ?;
```

Permanent destruction, if you ever need it:

```sql
DELETE FROM users
WHERE id = ?;
```

That gives you a clean **active → soft deleted → restored/permanently deleted** lifecycle.



[[SQlite]]