


`DROP` is the DDL command that **deletes an object**: its definition and, for tables, all the data inside it. There is a `DROP` command for every kind of object you learned in the pgAdmin object tree: tables, views, indexes, sequences, schemas, types, functions, extensions, roles, and whole databases. The basic form is always `DROP <object type> <name>`.

In your DDL lesson, `CREATE` built objects, and in the ALTER lesson you changed them. `DROP` is the end of the object's life, and it has two things you must understand before using it: **dependencies** (other objects that use the thing you are dropping) and **permanence** (once you commit, the data is gone unless you have a backup). The syntax is short. Most of this lesson is about how `DROP` behaves around dependencies and how to use it safely.

We use the same `departments` and `employees` tables, plus a view:

```sql
CREATE VIEW high_paid AS
SELECT * FROM employees WHERE salary > 4000;
```

## 1. DROP TABLE

```sql
DROP TABLE employees;
```

This removes the table, all its rows, and everything that belongs to it: its indexes, triggers, constraints, and the sequence behind a `serial` or identity column. The disk space is freed when the transaction commits.

If the table does not exist, you get `ERROR: table "employees" does not exist`. In scripts you run more than once, add `IF EXISTS`:

```sql
DROP TABLE IF EXISTS employees;
```

Now it only prints `NOTICE: table "employees" does not exist, skipping`.

You can drop several tables in one statement:

```sql
DROP TABLE employees, departments;
```

Because both go together, the foreign key between them is not a problem here.

## 2. Dependencies: RESTRICT and CASCADE

What happens if we try to drop `departments`, which `employees` points to with a foreign key?

```sql
DROP TABLE departments;
```

```
ERROR:  cannot drop table departments because other objects depend on it
DETAIL: constraint employees_department_id_fkey on table employees depends on table departments
HINT:   Use DROP ... CASCADE to drop the dependent objects too.
```

PostgreSQL refuses by default. This default is called **RESTRICT**: "do not drop if anything depends on it". It protects you. Your two options:

1. **Remove the dependency first**, then drop (the careful way):

```sql
ALTER TABLE employees DROP CONSTRAINT employees_department_id_fkey;
DROP TABLE departments;
```

2. **Use CASCADE**, which also drops the dependent objects:

```sql
DROP TABLE departments CASCADE;
```

```
NOTICE:  drop cascades to constraint employees_department_id_fkey on table employees
```

The important detail: `CASCADE` drops the **constraint**, not the `employees` table. The `employees` table keeps all its rows, and `department_id` becomes a plain integer column with no foreign key. Likewise, if a view depends on the table, `CASCADE` drops the **view**, but nothing else.

Here is what happens to the things around a table:

|Related object|When you `DROP TABLE`|
|---|---|
|The rows (data)|deleted|
|The table's own indexes, triggers, constraints|dropped with it|
|A sequence owned by a `serial` / identity column|dropped with it|
|A view that reads the table|**blocks**, unless `CASCADE` (then the view is dropped)|
|A foreign key in another table pointing to it|**blocks**, unless `CASCADE` (then only the constraint is dropped)|
|A function that mentions the table in its body text|not tracked, so the drop succeeds and the function fails later when it runs|

The last row is a trap: PostgreSQL cannot see inside a function body written as a string, so it will not warn you.

### See the dependents before you drop

In `psql`, `\d+ departments` lists the table's columns, indexes, and a section called **Referenced by**, which shows foreign keys from other tables. In pgAdmin, open the table's **Dependents** tab. Check this _before_ you reach for `CASCADE`.

## 3. Dropping parts of a table

You already used these in the ALTER lesson, because they are `ALTER TABLE` actions:

```sql
ALTER TABLE employees DROP COLUMN phone;
ALTER TABLE employees DROP CONSTRAINT salary_positive;
```

They follow the same rules: `RESTRICT` by default, `CASCADE` if you want dependents gone, and `IF EXISTS` to make them safe to repeat:

```sql
ALTER TABLE employees DROP COLUMN IF EXISTS phone CASCADE;
```

## 4. DROP for other objects

```sql
DROP VIEW high_paid;
DROP MATERIALIZED VIEW IF EXISTS sales_summary;
DROP INDEX idx_employees_name;
DROP SEQUENCE order_seq;
DROP TYPE mood;
DROP SCHEMA archive CASCADE;
DROP FUNCTION total_pay(int);
DROP TRIGGER audit_trg ON employees;
DROP EXTENSION pg_trgm;
```

Notes on the ones with special behavior:

|Command|What to know|
|---|---|
|`DROP INDEX CONCURRENTLY idx`|drops the index without blocking reads and writes. It cannot run inside a transaction block and cannot use `CASCADE`. Use it on busy tables.|
|`DROP SEQUENCE`|fails if a column default (`nextval(...)`) still uses it|
|`DROP TYPE`|fails if a column uses the type, until you change or drop that column|
|`DROP SCHEMA`|fails if the schema is not empty. `CASCADE` drops **everything inside it**, so be very careful.|
|`DROP FUNCTION f(int)`|you must give the argument types when the name is overloaded|
|`DROP EXTENSION`|removes everything the extension installed|

### DROP DATABASE

```sql
DROP DATABASE appdb;
```

Two rules: you cannot drop the database you are connected to (connect to `postgres` first), and nobody else may be connected, otherwise you get `database "appdb" is being accessed by other users`. In PostgreSQL 13 and newer, you can disconnect the others with:

```sql
DROP DATABASE appdb WITH (FORCE);
```

`DROP DATABASE` cannot run inside a transaction block.

### DROP ROLE

A role that still owns objects cannot be dropped: `role "app" cannot be dropped because some objects depend on it`. Hand the objects to someone else first:

```sql
REASSIGN OWNED BY app TO postgres;   -- give its objects to another role
DROP OWNED BY app;                   -- remove its privileges (and any objects left)
DROP ROLE app;
```

## 5. DROP vs DELETE vs TRUNCATE

Beginners mix these up. They all "remove data," but at different levels:

||`DELETE` (DML)|`TRUNCATE`|`DROP TABLE`|
|---|---|---|---|
|Removes|chosen rows|all rows|the whole table|
|`WHERE` allowed|yes|no|no|
|Table still exists after|yes|yes|no|
|Speed on big tables|slow (row by row)|very fast|very fast|
|Can roll back|yes|yes|yes|
|Resets the id sequence|no|only with `RESTART IDENTITY`|the sequence is dropped too|
|Needs `CASCADE` for foreign keys|no|yes, if other tables reference it|yes, if other objects depend on it|

```sql
DELETE FROM employees WHERE id = 4;                   -- one row
TRUNCATE employees RESTART IDENTITY;                  -- all rows, ids start again at 1
DROP TABLE employees;                                 -- the table itself
```

Rule of thumb: use `DELETE` to remove some rows, `TRUNCATE` to empty a table you will keep using (tests, staging tables), and `DROP` only when the table should no longer exist.

## 6. DROP is transactional, until you commit

Like `ALTER`, `DROP` works inside a transaction in PostgreSQL, so you can undo it:

```sql
BEGIN;
DROP TABLE employees CASCADE;
SELECT to_regclass('employees');   -- NULL: the table is gone inside this transaction
ROLLBACK;
SELECT to_regclass('employees');   -- employees: it is back, with all its data
```

`to_regclass()` returns the table name if it exists, or `NULL` if not, without raising an error. After `COMMIT`, there is no undo. Only a backup can bring the data back.

`DROP TABLE` also takes an **ACCESS EXCLUSIVE** lock (the same lock from the ALTER lesson), so it waits for running queries on that table and blocks new ones. Use `SET lock_timeout = '3s';` before dropping on a live system.

## 7. Safe habits

- **Back up first:** `pg_dump -U postgres -t employees mydb > employees_backup.sql` saves just that table.
- **Rename before you drop.** Run `ALTER TABLE employees RENAME TO employees_old;` and wait a week. If nothing breaks, drop `employees_old`. If something breaks, rename it back.
- **Run it in a transaction** and check the result before `COMMIT`.
- **Read the `NOTICE` lines** that `CASCADE` prints. They list exactly what else was dropped.
- **Do not use `CASCADE` just to make the error go away.** First look at what depends on the object.
- **Use `IF EXISTS`** in scripts that can run twice.
- **Check which database you are connected to.** Dropping in the wrong database is the classic mistake. In `psql`, `SELECT current_database();` tells you.

## 8. DROP in a Spring Boot project

Real schema removals belong in migrations, written as plain SQL, just like the `ALTER` ones:

```sql
-- V6__drop_legacy_phone.sql
ALTER TABLE employees DROP COLUMN IF EXISTS phone;
```

The safe order is: first release code that no longer reads the column, and only then run the migration that drops it. If you drop first, the old code still running in production will fail on every query that mentions the column.

Two places where Spring or its tools drop things automatically, so know them:

- `spring.jpa.hibernate.ddl-auto=create` drops and recreates your tables **every time the app starts**, and `create-drop` also drops them when it stops. Use these only on a throwaway test database, never on real data.
- Flyway has a `clean` command that drops everything in the configured schemas. It is disabled by default for safety, so leave it disabled in production.

## 9. Common errors

|Error message|Cause|Fix|
|---|---|---|
|`cannot drop table x because other objects depend on it`|a view or foreign key uses it|drop the dependent first, or use `CASCADE` after checking|
|`table "x" does not exist`|wrong name, wrong schema, or already dropped|check the name, or use `IF EXISTS`|
|`cannot drop sequence x because other objects depend on it`|a column default uses it|change the column default first|
|`cannot drop column x because other objects depend on it`|a view or constraint uses the column|drop the dependent, or use `CASCADE`|
|`database "x" is being accessed by other users`|other connections are open|disconnect them, or `DROP DATABASE ... WITH (FORCE)`|
|`cannot drop the currently open database`|you are connected to it|connect to another database first|
|`role "x" cannot be dropped because some objects depend on it`|the role still owns objects|`REASSIGN OWNED BY`, then `DROP OWNED BY`|
|`DROP INDEX CONCURRENTLY cannot run inside a transaction block`|you used it after `BEGIN`|run it on its own|
|`permission denied`|you are not the owner|use the owner role or a superuser|

## Related concept, in short

**Soft delete** is the opposite habit of `DROP` and `DELETE`: instead of removing a row, you set a column such as `deleted_at` (or `active = false`) and filter it out in queries. The data stays recoverable, but every query must remember the filter. In Spring, Hibernate's `@SQLRestriction` (or `@Where` in older versions) can add that filter automatically.

## Quick summary

- `DROP` removes an object permanently. For a table, that means the structure and all its data.
- The default is `RESTRICT`: PostgreSQL refuses if other objects depend on it. `CASCADE` drops those dependents too, but only the dependent _objects_ (a view, a foreign key constraint), not other tables.
- Function bodies are not tracked as dependents, so a drop can silently break them.
- `DELETE` removes rows, `TRUNCATE` empties a table, `DROP` removes the table.
- `DROP` is transactional, so you can roll back before commit. After commit, only a backup helps.
- Use `IF EXISTS` in scripts, `CONCURRENTLY` for indexes on busy tables, `WITH (FORCE)` for databases, and `REASSIGN OWNED` before dropping roles.
- In Spring, drop through migrations, remove the code usage first, and never leave `ddl-auto=create` on a real database.




[[PostgreSQL]]