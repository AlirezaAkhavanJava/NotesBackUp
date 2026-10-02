

## 1. The intuition

`ON DELETE` is a **standing instruction you attach to a foreign key**, telling the database: _"When someone deletes the parent row I point at, here is what you must do with me, the child."_

Analogy: you rent a storage unit (child) under a company's account (parent). The contract has a clause for what happens if the company closes:

- "Refuse to close the company while I still have a unit" → `RESTRICT` / `NO ACTION`
- "Empty and remove my unit too" → `CASCADE`
- "Keep my unit, but mark it as having no owner" → `SET NULL`
- "Keep my unit, transfer it to the default owner" → `SET DEFAULT`

The clause is written **once, in the schema**, and then enforced automatically on every delete, no matter who or what issues it (psql, Spring Boot, a script).

## 2. Syntax

It is part of the FK definition, on the **child** table:

```sql
CREATE TABLE order_items (
    id       INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id)
        ON DELETE CASCADE
);
```

Inline form (column-level) works too:

```sql
order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE
```

Key point: the clause lives on the table that holds the pointer (`order_items`), but it is _triggered_ by a delete on the table being pointed at (`orders`). Beginners often put it on the wrong table.

## 3. What each action does, with a live example

Data:

```
orders:       (1), (2)
order_items:  (10, order 1), (11, order 1), (12, order 2)
```

Now run `DELETE FROM orders WHERE id = 1;`

|Action|Result|
|---|---|
|`NO ACTION` / `RESTRICT`|Error. Nothing is deleted. Items 10 and 11 still reference order 1.|
|`CASCADE`|Order 1 deleted, **and** items 10 and 11 are deleted. Item 12 untouched.|
|`SET NULL`|Order 1 deleted. Items 10 and 11 remain, with `order_id = NULL`.|
|`SET DEFAULT`|Order 1 deleted. Items 10 and 11 remain, `order_id` becomes the column's `DEFAULT` value (which must itself be a valid parent id, or the FK check fails).|

Code to try it in SQLite:

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE orders (id INTEGER PRIMARY KEY);
CREATE TABLE order_items (
    id INTEGER PRIMARY KEY,
    order_id INTEGER,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL
);

INSERT INTO orders VALUES (1), (2);
INSERT INTO order_items VALUES (10, 1), (11, 1), (12, 2);

DELETE FROM orders WHERE id = 1;
SELECT * FROM order_items;
-- 10|NULL   11|NULL   12|2
```

Swap `SET NULL` for `CASCADE` and rerun to see rows 10 and 11 vanish.

## 4. Why it works this way

A foreign key is a promise: _every non-NULL value in this column matches an existing parent_. Deleting a parent would break that promise, so the database must resolve the conflict somehow. There are only a few logical resolutions: block the delete, destroy the dependents, or detach the dependents. `ON DELETE` simply lets **you** choose which, per relationship, instead of the database guessing.

Different relationships deserve different answers:

- Order items **belong to** an order → `CASCADE` (meaningless alone).
- A ticket's `assigned_to` employee → `SET NULL` (ticket should survive).
- An invoice referencing a customer → `RESTRICT` (financial history must not vanish).

## 5. Nuances and gotchas

1. **Default is `NO ACTION`.** If you write no `ON DELETE` clause, you get a blocking behavior, not cascade.
2. **`SET NULL` requires a nullable column.** With `NOT NULL`, the schema is contradictory and the delete fails (or the table creation is rejected in some systems).
3. **Cascades are recursive.** If `order_items` has its own children with `CASCADE`, they go too. One statement can remove thousands of rows across many tables.
4. **`ON DELETE` is separate from `ON UPDATE`.** `ON UPDATE` governs what happens when the parent's _key value changes_. Rarely needed with surrogate ids, which never change.
5. **SQLite needs `PRAGMA foreign_keys = ON`**, or the clause is parsed but never executed. This is the most common reason "my cascade doesn't work".
6. **Cascade skips Hibernate.** If a DB-level cascade deletes rows, JPA's persistence context doesn't know. Entities already loaded in memory may be stale, and `@PreRemove` callbacks won't fire for the cascaded children. This matters once you're in Spring Boot.
7. **Performance:** an index on the child's FK column makes the cascade lookup fast; without it every parent delete scans the whole child table.

## 6. Quick decision guide

- Child meaningless without parent → `CASCADE`
- Child should outlive parent → `SET NULL`
- History must be protected → `RESTRICT` (or just omit the clause)
- Unsure → omit it. A blocked delete is a safe failure; an unexpected cascade is not.

---
# `ON DELETE` examples

Each example is runnable. Use SQLite for 1 to 3 and 6, and psql for 4 and 5 (the SQL is nearly identical, and I'll flag the differences).

## Example 1: Blocking the delete (`RESTRICT` / default)

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE invoices (
    id          INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    amount      REAL,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
);

INSERT INTO customers VALUES (1, 'Alice'), (2, 'Bob');
INSERT INTO invoices  VALUES (100, 1, 250.0);

DELETE FROM customers WHERE id = 1;
-- Error: FOREIGN KEY constraint failed

DELETE FROM customers WHERE id = 2;   -- works, Bob has no invoices
```

Alice is protected because an invoice still points at her. Bob has no children, so he can be deleted freely. In PostgreSQL the error is more descriptive:

```
ERROR:  update or delete on table "customers" violates foreign key constraint
        "invoices_customer_id_fkey" on table "invoices"
DETAIL:  Key (id)=(1) is still referenced from table "invoices".
```

## Example 2: A cascade through three levels (`CASCADE`)

```sql
CREATE TABLE customers   (id SERIAL PRIMARY KEY, name TEXT);
CREATE TABLE orders      (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE
);
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product TEXT
);

INSERT INTO customers (name) VALUES ('Alice'), ('Bob');
INSERT INTO orders (customer_id) VALUES (1), (1), (2);
INSERT INTO order_items (order_id, product) VALUES
  (1,'pen'), (1,'ink'), (2,'book'), (3,'lamp');

DELETE FROM customers WHERE id = 1;
-- DELETE 1

SELECT * FROM orders;        -- only order 3 (Bob's) remains
SELECT * FROM order_items;   -- only 'lamp' remains
```

One statement removed 1 customer, 2 orders, and 3 items. The cascade propagated twice: `customers → orders → order_items`. Bob's data is untouched because the cascade follows only the rows that actually reference the deleted one.

**Seeing the cascade as it happens (PostgreSQL):**

```sql
BEGIN;
DELETE FROM customers WHERE id = 1;
SELECT count(*) FROM order_items;    -- 1
ROLLBACK;
SELECT count(*) FROM order_items;    -- 4, everything is back
```

`RETURNING *` only shows rows from the statement's own target table, not the cascaded ones, so count the child tables yourself before and after.

## Example 3: Keeping the child (`SET NULL`)

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE employees (id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE tickets (
    id          INTEGER PRIMARY KEY,
    title       TEXT,
    assigned_to INTEGER,                       -- nullable on purpose
    FOREIGN KEY (assigned_to) REFERENCES employees(id) ON DELETE SET NULL
);

INSERT INTO employees VALUES (1, 'Sara'), (2, 'Omid');
INSERT INTO tickets VALUES
  (1, 'Fix login',  1),
  (2, 'Add search', 1),
  (3, 'Update docs', 2);

DELETE FROM employees WHERE id = 1;   -- Sara leaves

SELECT * FROM tickets;
-- 1|Fix login|NULL
-- 2|Add search|NULL
-- 3|Update docs|2
```

The tickets survive and become "unassigned". If you had declared `assigned_to INTEGER NOT NULL`, the same delete would fail, because the database can't set a `NOT NULL` column to `NULL`.

## Example 4: Reassigning to a fallback (`SET DEFAULT`)

A "sentinel" row acts as the new owner:

```sql
CREATE TABLE users (id INT PRIMARY KEY, name TEXT);
INSERT INTO users VALUES (0, 'Deleted User'), (1, 'Alice'), (2, 'Bob');

CREATE TABLE comments (
    id        SERIAL PRIMARY KEY,
    author_id INT NOT NULL DEFAULT 0
              REFERENCES users(id) ON DELETE SET DEFAULT,
    body      TEXT
);
INSERT INTO comments (author_id, body) VALUES (1,'hi'), (1,'nice'), (2,'ok');

DELETE FROM users WHERE id = 1;

SELECT * FROM comments;
--  id | author_id | body
--   1 |         0 | hi
--   2 |         0 | nice
--   3 |         2 | ok
```

This is how forums show "[deleted]" while keeping the thread readable. Note that the column stays `NOT NULL`, which `SET NULL` could not do. The catch is that user `0` must exist. If it doesn't, the new value violates the FK and the delete fails.

## Example 5: Self-reference, and `CASCADE` vs `SET NULL` on the same shape

```sql
CREATE TABLE employees (
    id         INT PRIMARY KEY,
    name       TEXT,
    manager_id INT REFERENCES employees(id) ON DELETE SET NULL
);
INSERT INTO employees VALUES
  (1, 'CEO',  NULL),
  (2, 'VP',   1),
  (3, 'Dev',  2),
  (4, 'QA',   2);

DELETE FROM employees WHERE id = 2;   -- the VP leaves
SELECT * FROM employees;
--  1 | CEO | NULL
--  3 | Dev | NULL     <- orphaned upward, now top-level
--  4 | QA  | NULL
```

With `ON DELETE CASCADE` instead, deleting the VP would also delete Dev and QA, and if one of them had reports, those would go too. For an org chart, `SET NULL` is the sane choice. For something like nested comment threads ("delete a comment and all replies"), `CASCADE` fits.

## Example 6: Mixing actions in one realistic schema

Different FKs on the same parent can behave differently:

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);

CREATE TABLE profiles (                       -- 1-to-1, meaningless alone
    user_id INTEGER PRIMARY KEY,
    bio     TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE posts (                          -- content may outlive author
    id        INTEGER PRIMARY KEY,
    author_id INTEGER,
    title     TEXT,
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE payments (                       -- legal records, never lose
    id      INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    amount  REAL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
);
```

Now deleting a user:

- with a profile and posts but no payments: the profile is removed, the posts become authorless, and the delete succeeds.
- with any payment: the whole delete is refused, and nothing changes, including the profile and posts.

That last point matters. A failed delete is atomic: the cascade and set-null work on `profiles` and `posts` are undone too. You never end up with a half-finished delete.

## Example 7: `NO ACTION` vs `RESTRICT`, where they actually differ (PostgreSQL)

This is the one case where they differ, and it needs a deferrable constraint:

```sql
CREATE TABLE teams   (id INT PRIMARY KEY);
CREATE TABLE members (
    id      INT PRIMARY KEY,
    team_id INT REFERENCES teams(id)
            ON DELETE NO ACTION DEFERRABLE INITIALLY DEFERRED
);
INSERT INTO teams   VALUES (1), (2);
INSERT INTO members VALUES (10, 1), (11, 1);

BEGIN;
DELETE FROM teams WHERE id = 1;            -- no error yet! check is postponed
UPDATE members SET team_id = 2 WHERE team_id = 1;   -- fix the orphans
COMMIT;                                    -- check runs now: all consistent, success
```

With `RESTRICT`, the `DELETE` would fail immediately, before you got the chance to repair the children. `NO ACTION` plus `DEFERRABLE` lets you say "I'll make it consistent by commit time". This is also how you handle circular references.

## Example 8: The silent failure (SQLite with enforcement off)

```sql
-- new connection, no PRAGMA
CREATE TABLE a (id INTEGER PRIMARY KEY);
CREATE TABLE b (id INTEGER PRIMARY KEY, a_id INTEGER REFERENCES a(id) ON DELETE CASCADE);
INSERT INTO a VALUES (1);
INSERT INTO b VALUES (1, 1);

DELETE FROM a WHERE id = 1;   -- succeeds
SELECT * FROM b;              -- 1|1   <- orphan, cascade never ran!

PRAGMA foreign_key_check;     -- b|1|a|0   <- reports the violation
```

The `ON DELETE CASCADE` is stored in the schema but was never executed. If a cascade "doesn't work" in SQLite, check `PRAGMA foreign_keys;` first.

## Which example answers which question

|You want|Use|
|---|---|
|"Block deletion, protect history"|Ex. 1, 6 (`payments`)|
|"Delete the parent and everything below"|Ex. 2, 6 (`profiles`)|
|"Keep the child, mark it ownerless"|Ex. 3, 5, 6 (`posts`)|
|"Keep the child, show a placeholder owner"|Ex. 4|
|"Fix children before the check fires"|Ex. 7|

A good exercise: take Example 2, change one of the `CASCADE`s to `RESTRICT`, and predict what happens when you delete a customer who has orders with items, before you run it.




[[1 - WHAT IS SQLITE3 🍕]]