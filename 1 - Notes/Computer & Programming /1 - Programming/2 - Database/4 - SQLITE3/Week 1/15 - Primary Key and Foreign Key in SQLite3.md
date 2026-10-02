

These are **constraints** that establish **identity and relationships between rows/tables**.

A simple way to think about them:

```text
PRIMARY KEY → "Who are you?"
FOREIGN KEY → "Who are you related to?"
```

---

# 1. PRIMARY KEY

A **primary key (PK)** uniquely identifies each row in a table.

Example:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL
);
```

Here:

```text
id
↓
PRIMARY KEY
```

Every user gets a unique `id`:

```text
┌────┬──────────┬─────────────────────┐
│ id │ username │ email               │
├────┼──────────┼─────────────────────┤
│  1 │ alireza  │ ali@example.com     │
│  2 │ john     │ john@example.com     │
│  3 │ sara     │ sara@example.com    │
└────┴──────────┴─────────────────────┘
```

You cannot have:

```text
id = 1
id = 1
```

for two different rows.

### Primary key properties

A primary key should be:

- **Unique**
    
- **Not NULL**
    
- Stable
    
- Used to identify a specific row
    

---

# 2. FOREIGN KEY

A **foreign key (FK)** creates a relationship between two tables.

Suppose we have:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL
);
```

Now we want users to have posts.

```sql
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    user_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

The important part is:

```sql
FOREIGN KEY (user_id)
REFERENCES users(id)
```

This means:

```text
posts.user_id
      │
      │ references
      ▼
users.id
```

So the relationship is:

```text
users
┌────┬──────────┐
│ id │ username │
├────┼──────────┤
│  1 │ alireza  │
│  2 │ john     │
└────┴──────────┘
       ▲
       │
       │ user_id
       │
posts  │
┌────┬────────────┬─────────┐
│ id │ title      │ user_id │
├────┼────────────┼─────────┤
│ 10 │ Hello      │    1    │
│ 11 │ SQL        │    1    │
│ 12 │ Database   │    2    │
└────┴────────────┴─────────┘
```

Therefore:

```text
alireza → posts 10, 11
john    → post 12
```

---

# 3. Why do we need Foreign Keys?

Without a foreign key, you could accidentally insert:

```sql
INSERT INTO posts (title, user_id)
VALUES ('Hello', 999);
```

even though user `999` doesn't exist.

A foreign-key constraint can prevent this.

In SQLite, **foreign-key enforcement is disabled by default in many configurations**, so you should explicitly enable it for each connection:

```sql
PRAGMA foreign_keys = ON;
```

Then:

```sql
INSERT INTO posts (title, user_id)
VALUES ('Hello', 999);
```

will fail if user `999` doesn't exist.

---

# 4. `PRIMARY KEY` vs `FOREIGN KEY`

||Primary Key|Foreign Key|
|---|---|---|
|Purpose|Identifies a row|Creates a relationship|
|Must be unique?|Yes|No|
|Can repeat?|No|Yes|
|References another table?|No|Usually yes|
|Example|`users.id`|`posts.user_id`|

For example:

```sql
users.id
```

is a **primary key**.

```sql
posts.user_id
```

is a **foreign key**.

And:

```sql
FOREIGN KEY (user_id) REFERENCES users(id)
```

connects them.

---

# 5. One-to-Many Relationship

The example above represents a very common database relationship:

```text
One User
   │
   ├── Post
   ├── Post
   └── Post
```

That's a **one-to-many** relationship.

The "one" side:

```text
users
```

The "many" side:

```text
posts
```

The foreign key lives on the **many side**:

```sql
posts.user_id
```

This is one of the most important relational-database patterns to understand.

---

# 6. `ON DELETE` and `ON UPDATE`

Foreign keys can also define what happens when the referenced row changes.

For example:

```sql
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    user_id INTEGER,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);
```

`ON DELETE CASCADE` means:

```text
DELETE user
     ↓
Delete that user's posts
```

So:

```sql
DELETE FROM users
WHERE id = 1;
```

can automatically delete all posts belonging to user `1`.

Other useful actions include:

```text
CASCADE
SET NULL
SET DEFAULT
RESTRICT
NO ACTION
```

---

## The core concept

If you remember only one thing:

```text
┌───────────────────────┐
│ users                 │
│                       │
│ id  ← PRIMARY KEY     │
└───────────┬───────────┘
            │
            │ referenced by
            ▼
┌──────────────────────────┐
│ posts                    │
│                          │
│ user_id ← FOREIGN KEY    │
└──────────────────────────┘
```

**Primary Key = identity.**

**Foreign Key = relationship + referential integrity.**

And this is the foundation for understanding **JOINs**, normalization, and relational database design.

[[1 - WHAT IS SQLITE3 🍕]]