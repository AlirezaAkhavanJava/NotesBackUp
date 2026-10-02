
In **SQLite3**, row-to-row relationships are represented through **foreign keys**. The same fundamental relationship types used in relational databases apply:

### 1. One-to-One (1:1)

One row in Table A relates to **exactly one** row in Table B, and vice versa.

Example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT
);

CREATE TABLE user_profiles (
    id INTEGER PRIMARY KEY,
    user_id INTEGER UNIQUE,
    bio TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

```text
users
┌────┬──────────┐
│ id │ username │
├────┼──────────┤
│ 1  │ alireza  │
└────┴──────────┘
      │
      │ 1 : 1
      ▼
user_profiles
┌────┬─────────┬─────┐
│ id │ user_id │ bio │
├────┼─────────┼─────┤
│ 10 │ 1       │ ... │
└────┴─────────┴─────┘
```

The `UNIQUE` constraint on `user_id` prevents multiple profiles from belonging to the same user.

---

### 2. One-to-Many (1:N)

One row in Table A can relate to **many rows** in Table B.

This is the **most common relationship**.

Example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    content TEXT,

    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

```text
users
┌────┬──────────┐
│ id │ username │
├────┼──────────┤
│ 1  │ alireza  │
└────┴──────────┘
      │
      ├──────────────┐
      │              │
      ▼              ▼
   post 1          post 2
```

One user → many posts.

The important point is that `posts.user_id` **does not have `UNIQUE`**.

---

### 3. Many-to-One (N:1)

This is simply the **reverse perspective of One-to-Many**.

```text
Many posts ──────► One user
```

For example:

```text
Post 1 ──┐
Post 2 ──┼──► User 1
Post 3 ──┘
```

In SQL, you implement it the same way as 1:N:

```sql
FOREIGN KEY (user_id) REFERENCES users(id)
```

---

### 4. Many-to-Many (N:M)

Many rows in Table A can relate to many rows in Table B.

You **cannot normally represent this directly with a single foreign-key column**.

You introduce a **junction/associative table**.

Example: users and courses.

```text
User 1 ──┐
         ├──► user_courses ◄── Course 1
User 2 ──┘          │
                    ├────────── Course 2
```

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT
);

CREATE TABLE courses (
    id INTEGER PRIMARY KEY,
    name TEXT
);

CREATE TABLE user_courses (
    user_id INTEGER,
    course_id INTEGER,

    PRIMARY KEY (user_id, course_id),

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

Now:

```text
users        user_courses       courses

User 1 ──────┐
             ├──── (1, 10) ────► Java
User 1 ──────┤
             └──── (1, 20) ────► SQL

User 2 ────────── (2, 10) ─────► Java
```

So:

```text
User 1 → Java
User 1 → SQL
User 2 → Java
```

---

## The 3 fundamental relationship types

Usually, you should memorize these three:

|Relationship|Meaning|Typical implementation|
|---|---|---|
|**1:1**|One ↔ One|FK + `UNIQUE`|
|**1:N**|One ↔ Many|FK on the "many" side|
|**N:M**|Many ↔ Many|Junction table + two FKs|

**N:1 is just 1:N viewed from the other direction.**

### The key concept

A relationship is not really a special SQLite object called a "relationship." It emerges from how **primary keys, foreign keys, and constraints** connect rows.

For example:

```sql
users.id
   ▲
   │
   │ FOREIGN KEY
   │
posts.user_id
```

That means:

> `posts.user_id` contains a value identifying a row in `users`.

Then the **constraints** determine whether that relationship is 1:1, 1:N, etc.

If you're studying CS50 SQL, the next important concept after these is **how `JOIN` actually traverses these relationships**.


[[1 - WHAT IS SQLITE3 🍕]]