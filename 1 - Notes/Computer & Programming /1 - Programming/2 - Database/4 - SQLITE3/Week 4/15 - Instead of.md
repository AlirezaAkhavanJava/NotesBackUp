
This is exactly the useful combination to learn in SQLite:

> **VIEW = what you expose**  
> **TRIGGER = what happens automatically**  
> **INSTEAD OF = intercept an operation on a VIEW and do something else**



---

# 1. The problem

Suppose your real table is:

```sql
CREATE TABLE collections (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    accession_number TEXT NOT NULL,
    acquired TEXT,
    deleted INTEGER DEFAULT 0
        CHECK (deleted IN (0, 1))
);
```

You don't want users to directly interact with `collections`.

Instead, expose a view containing only active objects:

```sql
CREATE VIEW active_collections AS
SELECT
    id,
    title,
    accession_number,
    acquired
FROM collections
WHERE deleted = 0;
```

Now:

```sql
SELECT * FROM active_collections;
```

gives you only non-deleted collections.

---

# 2. The interesting problem

Suppose somebody does:

```sql
DELETE FROM active_collections
WHERE id = 3;
```

What should happen?

We don't actually want to physically delete the row from `collections`.

We want:

```text
deleted = 1
```

That's **soft deletion**.

But SQLite normally cannot directly perform this `DELETE` through the view.

This is where:

```sql
INSTEAD OF
```

comes in.

---

# 3. `INSTEAD OF` trigger

Create:

```sql
CREATE TRIGGER soft_delete_collection
INSTEAD OF DELETE ON active_collections
BEGIN
    UPDATE collections
    SET deleted = 1
    WHERE id = OLD.id;
END;
```

Now:

```sql
DELETE FROM active_collections
WHERE id = 3;
```

doesn't actually delete from the view.

Instead:

```text
DELETE from VIEW
       │
       ▼
INSTEAD OF trigger
       │
       ▼
UPDATE collections
SET deleted = 1
WHERE id = 3
```

So the original row remains in the real table.

---

# 4. See it

Before:

```sql
SELECT * FROM collections;
```

```text
3 | Golden Coin | ACC-0003 | 1952-05-13 | 0
```

Execute:

```sql
DELETE FROM active_collections
WHERE id = 3;
```

Then:

```sql
SELECT * FROM collections
WHERE id = 3;
```

You get:

```text
3 | Golden Coin | ACC-0003 | 1952-05-13 | 1
```

But:

```sql
SELECT * FROM active_collections;
```

no longer shows it.

That's the power of combining **VIEW + TRIGGER**.

---

# 5. `OLD` and `NEW`

Triggers give you special references.

For an update:

```text
OLD = value before modification
NEW = value after modification
```

For example:

```sql
CREATE TRIGGER example
AFTER UPDATE ON collections
BEGIN
    -- OLD.title
    -- NEW.title
END;
```

For a delete:

```text
OLD
```

exists, because the row existed before deletion.

There is no `NEW`.

For an insert:

```text
NEW
```

exists.

There is no `OLD`.

Think:

```text
INSERT
    NEW

UPDATE
    OLD → NEW

DELETE
    OLD
```

---

# 6. `INSTEAD OF` vs `AFTER`

This distinction is important.

### `AFTER`

The operation happens first:

```text
UPDATE
  ↓
row changes
  ↓
AFTER trigger
```

Example:

```sql
CREATE TRIGGER log_update
AFTER UPDATE ON collections
BEGIN
    -- do something
END;
```

### `INSTEAD OF`

The original operation **doesn't happen**.

The trigger replaces it:

```text
UPDATE VIEW
     ↓
INSTEAD OF trigger
     ↓
your custom operation
```

That's why `INSTEAD OF` is especially useful with **views**.

---

# 7. Insert through a view

Here's another useful example.

Create a restricted view:

```sql
CREATE VIEW collection_entry AS
SELECT
    title,
    accession_number,
    acquired
FROM collections
WHERE deleted = 0;
```

Now suppose you want:

```sql
INSERT INTO collection_entry
(title, accession_number, acquired)
VALUES
('Roman Coin', 'ACC-0100', '1970-01-01');
```

SQLite normally can't perform that insertion automatically because the view isn't a normal storage table.

So:

```sql
CREATE TRIGGER insert_collection
INSTEAD OF INSERT ON collection_entry
BEGIN
    INSERT INTO collections (
        title,
        accession_number,
        acquired,
        deleted
    )
    VALUES (
        NEW.title,
        NEW.accession_number,
        NEW.acquired,
        0
    );
END;
```

Now:

```sql
INSERT INTO collection_entry
(title, accession_number, acquired)
VALUES
('Roman Coin', 'ACC-0100', '1970-01-01');
```

actually performs:

```sql
INSERT INTO collections (...)
VALUES (..., 0);
```

The user interacts with the **view**, while the trigger translates that operation into an operation on the real table.

---

# 8. The architecture

You should visualize it like this:

```text
                 USER
                  │
                  ▼
        ┌──────────────────┐
        │      VIEW        │
        │ active_collection│
        └────────┬─────────┘
                 │
          INSERT / DELETE
                 │
                 ▼
        ┌──────────────────┐
        │ INSTEAD OF       │
        │     TRIGGER      │
        └────────┬─────────┘
                 │
                 ▼
        ┌──────────────────┐
        │   REAL TABLE     │
        │   collections    │
        └──────────────────┘
```

This is essentially an **interface/abstraction layer** over your table.

---

# 9. Practice this in your CS50 database

Run these yourself.

### Step 1

```sql
CREATE VIEW active_collections AS
SELECT id, title, accession_number, acquired
FROM collections
WHERE deleted = 0;
```

### Step 2

Create the soft-delete trigger:

```sql
CREATE TRIGGER soft_delete_collection
INSTEAD OF DELETE ON active_collections
BEGIN
    UPDATE collections
    SET deleted = 1
    WHERE id = OLD.id;
END;
```

### Step 3

Try:

```sql
DELETE FROM active_collections
WHERE id = 8;
```

### Step 4

Check:

```sql
SELECT * FROM collections
WHERE id = 8;
```

and:

```sql
SELECT * FROM active_collections;
```

You should discover:

```text
collections:
    row still exists
    deleted = 1

active_collections:
    row disappeared
```

That's a very good real-world use of **VIEW + TRIGGER + INSTEAD OF**.


[[SQlite]]