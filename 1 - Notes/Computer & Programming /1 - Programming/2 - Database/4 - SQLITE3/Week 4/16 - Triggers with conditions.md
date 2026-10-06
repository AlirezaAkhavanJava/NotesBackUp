
 In SQLite, this is where **triggers + views + `INSTEAD OF` + `WHEN`** become really useful.

The key idea is:

> **A trigger can enforce conditions based on values coming through a view, while the trigger itself performs the operation on the underlying table.**

Let's build it properly.

---

# 1. Basic structure

Suppose you have:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1
);
```

And you expose only active users through a view:

```sql
CREATE VIEW active_users AS
SELECT id, username
FROM users
WHERE active = 1;
```

The view is read-only by default.

If you want:

```sql
INSERT INTO active_users ...
```

you need an **`INSTEAD OF` trigger**.

---

# 2. Trigger on a view

```sql
CREATE TRIGGER insert_active_user
INSTEAD OF INSERT ON active_users
BEGIN
    INSERT INTO users (id, username, active)
    VALUES (NEW.id, NEW.username, 1);
END;
```

Now:

```sql
INSERT INTO active_users (username)
VALUES ('alice');
```

actually performs:

```sql
INSERT INTO users ...
```

The flow is:

```text
INSERT INTO active_users
        │
        ▼
INSTEAD OF INSERT trigger
        │
        ▼
INSERT INTO users
        │
        ▼
underlying table
```

---

# 3. Conditions with `WHEN`

SQLite triggers support a `WHEN` clause.

For example:

```sql
CREATE TRIGGER insert_active_user
INSTEAD OF INSERT ON active_users
WHEN NEW.username IS NOT NULL
BEGIN
    INSERT INTO users (username, active)
    VALUES (NEW.username, 1);
END;
```

The trigger only executes when:

```sql
NEW.username IS NOT NULL
```

is true.

So:

```sql
INSERT INTO active_users (username)
VALUES ('alice');
```

works.

But:

```sql
INSERT INTO active_users (username)
VALUES (NULL);
```

doesn't execute the trigger.

However, there's an important detail:

**`WHEN` doesn't give you a nice application-level error.**

If you want to explicitly reject invalid data, use:

```sql
RAISE()
```

---

# 4. Condition + `RAISE()`

This is usually the better design.

```sql
CREATE TRIGGER insert_active_user
INSTEAD OF INSERT ON active_users
BEGIN

    SELECT CASE
        WHEN NEW.username IS NULL
        THEN RAISE(ABORT, 'username cannot be NULL')
    END;

    INSERT INTO users (username, active)
    VALUES (NEW.username, 1);

END;
```

Now:

```sql
INSERT INTO active_users (username)
VALUES (NULL);
```

produces an error:

```text
Error: username cannot be NULL
```

The trigger acts like a database-level validation layer.

---

# 5. Conditions involving the underlying table

This is where it gets interesting.

Suppose:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    active INTEGER NOT NULL DEFAULT 1
);
```

View:

```sql
CREATE VIEW active_users AS
SELECT id, username
FROM users
WHERE active = 1;
```

Now suppose you want:

> A username can only be inserted through the view if that username doesn't already exist in the underlying table.

You can check the table inside the trigger:

```sql
CREATE TRIGGER insert_active_user
INSTEAD OF INSERT ON active_users
BEGIN

    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM users
            WHERE username = NEW.username
        )
        THEN RAISE(ABORT, 'username already exists')
    END;

    INSERT INTO users (username, active)
    VALUES (NEW.username, 1);

END;
```

Notice the distinction:

```sql
NEW.username
```

comes from the **view operation**.

While:

```sql
SELECT 1 FROM users
```

checks the **underlying table**.

---

# 6. `NEW` and `OLD`

This is fundamental when working with triggers.

For an INSERT:

```text
NEW
```

represents the row being inserted.

For DELETE:

```text
OLD
```

represents the row being deleted.

For UPDATE:

```text
OLD → previous row
NEW → new row
```

Example:

```sql
UPDATE active_users
SET username = 'bob'
WHERE id = 5;
```

An `INSTEAD OF UPDATE` trigger can use both:

```sql
CREATE TRIGGER update_active_user
INSTEAD OF UPDATE ON active_users
BEGIN
    UPDATE users
    SET username = NEW.username
    WHERE id = OLD.id;
END;
```

Conceptually:

```text
OLD
┌──────────────┐
│ id = 5       │
│ username=a   │
└──────────────┘
       │
       │ UPDATE
       ▼
NEW
┌──────────────┐
│ id = 5       │
│ username=b   │
└──────────────┘
```

---

# 7. Conditions during UPDATE

You can validate the new state against the underlying table.

For example:

```sql
CREATE TRIGGER update_active_user
INSTEAD OF UPDATE ON active_users
BEGIN

    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM users
            WHERE username = NEW.username
              AND id != OLD.id
        )
        THEN RAISE(ABORT, 'username already exists')
    END;

    UPDATE users
    SET username = NEW.username
    WHERE id = OLD.id;

END;
```

The important part is:

```sql
AND id != OLD.id
```

Otherwise, when updating user `5`, the query would find user `5` itself and incorrectly claim that the username already exists.

---

# 8. Conditions based on the view itself

You can also enforce the logical rules represented by the view.

Suppose:

```sql
CREATE VIEW available_products AS
SELECT id, name, price
FROM products
WHERE available = 1;
```

You might want to prevent somebody from inserting a negative price through the view:

```sql
CREATE TRIGGER insert_available_product
INSTEAD OF INSERT ON available_products
BEGIN

    SELECT CASE
        WHEN NEW.price <= 0
        THEN RAISE(ABORT, 'price must be greater than zero')
    END;

    INSERT INTO products (name, price, available)
    VALUES (NEW.name, NEW.price, 1);

END;
```

The architecture becomes:

```text
                 VIEW
                  │
       INSERT / UPDATE / DELETE
                  │
                  ▼
          INSTEAD OF TRIGGER
                  │
          ┌───────┴────────┐
          │                │
      validation       transformation
          │                │
          └───────┬────────┘
                  ▼
             base table
```

---

# 9. `WHEN` vs `RAISE()`

These are different tools.

### `WHEN`

Controls whether the trigger executes:

```sql
CREATE TRIGGER example
AFTER INSERT ON users
WHEN NEW.active = 1
BEGIN
    -- execute only for active users
END;
```

Think:

> **"Should this trigger run?"**

---

### `RAISE()`

Stops the operation:

```sql
SELECT CASE
    WHEN NEW.active NOT IN (0, 1)
    THEN RAISE(ABORT, 'invalid active value')
END;
```

Think:

> **"This operation is invalid; reject it."**

---

# 10. A realistic example: soft deletion

This is especially useful with the soft-delete pattern you were asking about.

Base table:

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0
);
```

Public view:

```sql
CREATE VIEW active_users AS
SELECT id, username
FROM users
WHERE deleted = 0;
```

Now you don't expose deleted users.

For deletion:

```sql
CREATE TRIGGER soft_delete_user
INSTEAD OF DELETE ON active_users
BEGIN
    UPDATE users
    SET deleted = 1
    WHERE id = OLD.id;
END;
```

Now:

```sql
DELETE FROM active_users
WHERE id = 5;
```

doesn't physically delete anything.

It becomes:

```sql
UPDATE users
SET deleted = 1
WHERE id = 5;
```

Then the user disappears from:

```sql
SELECT * FROM active_users;
```

because:

```sql
WHERE deleted = 0
```

no longer matches.

That's a very clean pattern:

```text
              active_users VIEW
                     │
                     │ DELETE
                     ▼
          soft_delete_user TRIGGER
                     │
                     ▼
              UPDATE users
                     │
                     ▼
              deleted = 1
                     │
                     ▼
           disappears from VIEW
```

---

## The mental model

When working with SQLite views and triggers, keep these three layers separate:

```text
┌──────────────────────────────┐
│             VIEW             │
│  What the application sees   │
└──────────────┬───────────────┘
               │
               │ operation
               ▼
┌──────────────────────────────┐
│          TRIGGER             │
│ validation / authorization   │
│ transformation / side-effect │
└──────────────┬───────────────┘
               │
               │ SQL operation
               ▼
┌──────────────────────────────┐
│        BASE TABLE            │
│     actual persistent data   │
└──────────────────────────────┘
```

And remember:

**`INSTEAD OF` triggers belong to views.**  
**`BEFORE` / `AFTER` triggers normally belong to tables.**

A powerful design is to combine them:

```text
INSERT into VIEW
       ↓
INSTEAD OF INSERT
       ↓
validate / transform
       ↓
INSERT into BASE TABLE
       ↓
AFTER INSERT trigger
       ↓
audit / logging / derived data
```

That gives you a surprisingly strong database-side architecture even in SQLite.


[[SQlite]]