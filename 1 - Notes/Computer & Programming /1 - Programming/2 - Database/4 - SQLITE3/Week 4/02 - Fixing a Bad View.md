
The key thing is that **a normal SQL view is metadata, not a copy of your table data**, so fixing a bad view is usually much easier than fixing bad `INSERT`/`UPDATE`/`DELETE` operations.

## 1. You made a mistake while creating a view

Suppose you created:

```sql
CREATE VIEW active_tasks AS
SELECT id, title
FROM tasks
WHERE completed = false;
```

Then you realize the definition is wrong.

### PostgreSQL

You can replace it:

```sql
CREATE OR REPLACE VIEW active_tasks AS
SELECT
    id,
    title,
    user_id
FROM tasks
WHERE completed = false;
```

No need to drop it first.

### SQLite

SQLite doesn't support PostgreSQL's:

```sql
CREATE OR REPLACE VIEW
```

So:

```sql
DROP VIEW active_tasks;

CREATE VIEW active_tasks AS
SELECT
    id,
    title,
    user_id
FROM tasks
WHERE completed = 0;
```

---

# 2. You want to completely undo the view

Simply:

```sql
DROP VIEW active_tasks;
```

This removes the **view**, not the underlying tables.

So:

```text
DROP VIEW
     │
     └── removes:
          active_tasks

Does NOT remove:
     users
     tasks
     categories
```

That's an important safety distinction.

---

# 3. What if other views depend on it?

Suppose:

```text
tasks
  ↓
active_tasks
  ↓
user_active_tasks
```

Now:

```sql
DROP VIEW active_tasks;
```

may fail because another view depends on it.

PostgreSQL can tell you:

```text
ERROR: cannot drop view active_tasks because other objects depend on it
```

You have two approaches.

### Safe approach

Drop dependencies first:

```sql
DROP VIEW user_active_tasks;
DROP VIEW active_tasks;
```

Then recreate them.

### Cascade

PostgreSQL supports:

```sql
DROP VIEW active_tasks CASCADE;
```

This means:

> Drop this view **and objects depending on it**.

Be careful.

`CASCADE` is powerful and can remove more database objects than you intended.

I recommend using:

```sql
DROP VIEW ...
```

first and letting PostgreSQL tell you about dependencies.

---

# 4. "I changed the view and want the previous version back"

This is where SQL itself generally **doesn't provide an undo history for DDL**.

For example:

```sql
CREATE OR REPLACE VIEW active_tasks AS ...
```

You don't get:

```sql
UNDO;
```

or:

```sql
ROLLBACK VIEW TO PREVIOUS VERSION;
```

unless you are using a transaction and haven't committed.

This is why **migration/version control** matters.

---

# 5. PostgreSQL: Transactions Can Save You

PostgreSQL supports transactional DDL very well.

You can do:

```sql
BEGIN;

CREATE OR REPLACE VIEW active_tasks AS
SELECT ...
;

-- inspect/test it

ROLLBACK;
```

The view change is undone.

If everything is correct:

```sql
BEGIN;

CREATE OR REPLACE VIEW active_tasks AS
SELECT ...
;

COMMIT;
```

Mental model:

```text
BEGIN
  │
  ├── change view
  │
  ├── test
  │
  ├── looks good ──► COMMIT
  │
  └── mistake ─────► ROLLBACK
```

This is extremely useful when experimenting.

---

# 6. SQLite: Transactions Also Help

SQLite supports transactions around schema changes as well.

For example:

```sql
BEGIN TRANSACTION;

DROP VIEW active_tasks;

CREATE VIEW active_tasks AS
SELECT ...
;

-- test

ROLLBACK;
```

Or:

```sql
BEGIN TRANSACTION;

DROP VIEW active_tasks;

CREATE VIEW active_tasks AS
SELECT ...
;

COMMIT;
```

So don't think:

> "DDL means I can never undo it."

The exact transactional behavior depends on the database system, but both PostgreSQL and SQLite provide transactional mechanisms you can use for schema changes.

---

# 7. The Big Difference: View Mistake vs Data Mistake

This distinction is extremely important.

### View mistake

```sql
CREATE VIEW ...
```

or:

```sql
DROP VIEW ...
```

You're changing database **metadata/schema**.

Usually easy to recover.

### Data mistake

```sql
DELETE FROM tasks;
```

or:

```sql
UPDATE tasks
SET completed = true;
```

Now you've potentially changed actual data.

That's much more serious.

For example:

```sql
BEGIN;

UPDATE tasks
SET completed = true
WHERE user_id = 10;

-- Oh shit, wrong user.

ROLLBACK;
```

This is why transactions are one of your most important SQL tools.

---

# 8. Don't Confuse `DROP VIEW` With `DROP TABLE`

This:

```sql
DROP VIEW active_tasks;
```

means:

```text
remove the view
```

This:

```sql
DROP TABLE tasks;
```

means:

```text
remove the actual table
and its data
```

Very different operations.

---

# 9. Use Version-Controlled SQL Migrations

For a real Spring Boot project, don't rely on manually remembering:

```sql
CREATE VIEW ...
```

Keep schema changes in Git.

For example:

```text
src/main/resources/db/migration/

V1__create_users.sql
V2__create_tasks.sql
V3__create_active_tasks_view.sql
V4__update_active_tasks_view.sql
```

Then Git gives you history:

```text
V3
 │
 └── original view

V4
 │
 └── modified view
```

If V4 is wrong, you can inspect exactly what changed.

With a migration system such as Flyway, you'd generally create a **new corrective migration** rather than editing an already-applied migration.

For example:

```text
V3__create_active_tasks_view.sql
V4__fix_active_tasks_view.sql
```

V4:

```sql
CREATE OR REPLACE VIEW active_tasks AS
SELECT
    id,
    title,
    user_id
FROM tasks
WHERE completed = false;
```

This is much safer for production databases.

---

# 10. A Professional Workflow

When experimenting with views in PostgreSQL:

```sql
BEGIN;

CREATE OR REPLACE VIEW active_tasks AS
SELECT
    id,
    title,
    user_id
FROM tasks
WHERE completed = false;
```

Test:

```sql
SELECT *
FROM active_tasks
LIMIT 10;
```

Inspect:

```sql
\d+ active_tasks
```

If wrong:

```sql
ROLLBACK;
```

If correct:

```sql
COMMIT;
```

So your workflow becomes:

```text
          ┌──────────────┐
          │ BEGIN        │
          └──────┬───────┘
                 ↓
        modify/create view
                 ↓
             test it
                 ↓
        ┌────────┴────────┐
        ↓                 ↓
      wrong             correct
        ↓                 ↓
    ROLLBACK            COMMIT
```

That's the habit I would recommend you build now.

**One more important distinction:** `ROLLBACK` is for changes in the **current transaction**. It is not a general "undo my database history" command. Once a transaction has been committed, you normally recover through another corrective SQL change, a migration, or a backup—not by issuing `ROLLBACK`.


[[SQlite]]
[[PostgreSQL]]