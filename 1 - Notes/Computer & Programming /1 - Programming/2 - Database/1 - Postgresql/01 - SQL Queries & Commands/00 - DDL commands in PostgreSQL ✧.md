

DDL stands for **Data Definition Language**. It is the group of SQL commands that define and change the _structure_ of your database: tables, columns, constraints, indexes, views, and so on. DDL does not work with the rows inside a table. It works with the containers that hold the rows.

You use DDL when you set up a database, and again every time the app's data model changes. Everything you write in an entity class (`@Entity`, `@Table`, `@Column`) has to exist as DDL in PostgreSQL. Hibernate can generate that DDL for you, but in production you write it yourself and control it. This lesson shows you how.

The database and the schema, which you already know, are the places where these objects live. Here we focus on the objects themselves.

## The commands at a glance

|Command|What it does|Example target|
|---|---|---|
|`CREATE`|Makes a new object|table, index, view, sequence, type|
|`ALTER`|Changes an existing object|add a column, rename, add a constraint|
|`DROP`|Deletes an object completely|table, index, view|
|`TRUNCATE`|Removes all rows, keeps the table|table|

Data types such as `BIGINT`, `VARCHAR`, and `NUMERIC` are covered in your data types lesson, so I use them here without explaining them again.

---
## CREATE TABLE

```sql
CREATE TABLE users (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      VARCHAR(255) NOT NULL UNIQUE,
    full_name  VARCHAR(100) NOT NULL,
    active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
```


Now a second table that points to the first one:

```sql
CREATE TABLE orders (
    id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT        NOT NULL,
    total   NUMERIC(10,2) NOT NULL,
    status  VARCHAR(20)   NOT NULL DEFAULT 'NEW',

    CONSTRAINT fk_orders_user  FOREIGN KEY (user_id) REFERENCES users (id) ON        DELETE CASCADE,
    CONSTRAINT ck_orders_total CHECK (total >= 0)
);
```

Two things to notice here.

**Name your constraints.** If you skip `CONSTRAINT fk_orders_user`, PostgreSQL invents a name. Error messages and later `ALTER ... DROP CONSTRAINT` commands then use that invented name. Your own names are easier to read and to reuse.

**`ON DELETE` decides what happens to child rows.** 
1. `CASCADE` deletes the orders when the user is deleted. 
2. `RESTRICT`, which is effectively the default, blocks the delete while orders exist. 
3. `SET NULL` keeps the orders but clears `user_id`, so that column must allow null. 
4. `CASCADE` is convenient but dangerous, so pick it on purpose.

Add `IF NOT EXISTS` (`CREATE TABLE IF NOT EXISTS ...`) when a script must be safe to run twice.

---
## ALTER TABLE

Real projects change tables far more often than they create them.

```sql
ALTER TABLE users ADD COLUMN address TEXT DEFAULT 'Homeless';
ALTER TABLE users RENAME COLUMN full_name TO name;
ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(200);
ALTER TABLE users DROP COLUMN phone;

ALTER TABLE users ADD CONSTRAINT uq_users_phone UNIQUE (phone);
ALTER TABLE users DROP CONSTRAINT uq_users_phone;
```

Three traps catch beginners.

**1. Adding `NOT NULL` to a table that already has rows.** This fails if existing rows would have a null. The safe order is three steps:

```sql
ALTER TABLE users ADD COLUMN country VARCHAR(2);            -- 1. add it nullable
UPDATE users SET country = 'DE' WHERE country IS NULL;      -- 2. fill existing rows
ALTER TABLE users ALTER COLUMN country SET NOT NULL;        -- 3. now enforce it
```

If the new column has a constant default, you can do it in one command. `ADD COLUMN country VARCHAR(2) NOT NULL DEFAULT 'DE'` is fast on modern PostgreSQL and does not rewrite the table.

**2. Changing a type needs a conversion rule when the types are not obviously compatible.**

```sql
ALTER TABLE products ALTER COLUMN price TYPE NUMERIC(10,2) USING price::numeric;
```

`USING` tells PostgreSQL how to turn each old value into the new type. Some type changes rewrite the whole table and lock it while they run.

**3. `DROP COLUMN` is permanent.** The data in that column is gone. In a live system you often deploy code that stops using the column first, and drop it in a later release.

---
## DROP and TRUNCATE

```sql
DROP TABLE IF EXISTS orders;        -- table and its data are gone
DROP TABLE users CASCADE;           -- also drops things that depend on it, like foreign keys and views

TRUNCATE TABLE orders;              -- all rows gone, table stays
TRUNCATE TABLE orders RESTART IDENTITY;  -- also resets the id counter to 1
```

`DROP` removes the structure itself. `TRUNCATE` keeps the structure and empties it. `TRUNCATE` is much faster than `DELETE FROM orders` on big tables, because it does not go row by row. But `TRUNCATE users CASCADE` also empties every table that references `users`, so be careful with it. `DELETE` is a DML command, because it changes rows, so it is not part of this lesson.

---
## Indexes

An index is a separate structure PostgreSQL keeps so it can find rows without reading the whole table.

```sql
CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE UNIQUE INDEX uq_users_email_lower ON users (lower(email));
CREATE INDEX idx_orders_open ON orders (user_id) WHERE status = 'NEW';   -- partial index
CREATE INDEX idx_orders_user_status ON orders (user_id, status);         -- composite index
```

- PostgreSQL indexes primary keys and `UNIQUE` columns for you. It does **not** index foreign key columns. If you often query `orders` by `user_id`, create that index yourself.
- In a composite index the column order matters. `(user_id, status)` helps queries that filter on `user_id`, or on `user_id` and `status`. It does not help queries that filter only on `status`.
- Every index slows down inserts and updates a little and takes disk space. Add indexes for real queries, not "just in case".
- On a busy production table use `CREATE INDEX CONCURRENTLY ...`. It avoids blocking writes, but it cannot run inside a transaction block.

---
## Views

A view is a ***saved*** `SELECT` that you query like a table. It stores no data of its own.

```sql
CREATE VIEW active_users AS
SELECT id, email, name FROM users WHERE active = TRUE;

CREATE OR REPLACE VIEW active_users AS
SELECT id, email, name, created_at FROM users WHERE active = TRUE;
```

A **materialized view** is different. It stores the result, so reads are fast, but the data goes stale until you run `REFRESH MATERIALIZED VIEW view_name;`.

---
## Sequences

***A sequence is a counter object that hands out the next number***. The identity column you used above creates and manages one for you behind the scenes. You can also create one by hand:

```sql
CREATE SEQUENCE invoice_no_seq START 1000 INCREMENT 1;
SELECT nextval('invoice_no_seq');   -- 1000, then 1001, ...
```

Older code uses `SERIAL`, which does the same job with an attached sequence. For new tables, prefer `GENERATED ... AS IDENTITY`. When you reach JPA's `@GeneratedValue`, you will see exactly how it uses these sequences.

---
## Enums and domains

An **enum** is a type with a fixed list of allowed values:

```sql
CREATE TYPE order_status AS ENUM ('NEW', 'PAID', 'SHIPPED');
ALTER TYPE order_status ADD VALUE 'CANCELLED';

ALTER TABLE orders ALTER COLUMN status DROP DEFAULT;
ALTER TABLE orders ALTER COLUMN status TYPE order_status USING status::order_status;
ALTER TABLE orders ALTER COLUMN status SET DEFAULT 'NEW';
```

You can add values to an enum, but you cannot easily remove or reorder them. Many Spring teams therefore use `VARCHAR` plus a `CHECK` constraint instead, which is simpler to change and simpler to map with JPA.

A **domain** is a reusable type with built-in rules:

```sql
CREATE DOMAIN email_address AS VARCHAR(255) CHECK (VALUE LIKE '%_@_%');
```

Now any column declared as `email_address` carries that check automatically.

---
## Transactional DDL

PostgreSQL lets you run DDL inside a transaction and undo it:

```sql
BEGIN;
ALTER TABLE users ADD COLUMN nickname VARCHAR(50);
CREATE INDEX idx_users_nickname ON users (nickname);
ROLLBACK;   -- both changes disappear, as if they never ran
```

This is useful for migrations. If step 3 of 5 fails, PostgreSQL rolls back steps 1 and 2, and you are not left with a half-changed schema. The exception is statements like `CREATE INDEX CONCURRENTLY`, which cannot run in a transaction.

SQLite also supports transactional DDL, but its `ALTER TABLE` is much more limited. For example, it cannot change a column's type directly, and it has no enums and no schemas.

---
## DDL in your Spring Boot project: Flyway

You should not rely on `spring.jpa.hibernate.ddl-auto=update` in production. Hibernate guesses the changes, cannot do renames or data fixes, and leaves you with no history. The standard approach is **versioned migration files**, and Flyway is the common tool for them.

You put plain SQL files in `src/main/resources/db/migration`:

```
V1__create_users.sql
V2__create_orders.sql
V3__add_country_to_users.sql
```

The name format is `V<version>__<description>.sql`, with two underscores. At startup Flyway checks its `flyway_schema_history` table, runs only the files that have not run yet, in version order, and records each one with a checksum.

Two rules follow from that.

- **Never edit a migration that has already been applied.** The checksum no longer matches, and Flyway refuses to start. Write a new `V4__...` file instead.
- Set `spring.jpa.hibernate.ddl-auto=validate` so Hibernate only _checks_ that your entities match the tables. It does not change anything.

With current Flyway versions, PostgreSQL needs `flyway-core` and `flyway-database-postgresql` in your dependencies.

---
## Related concept: how DDL fits with the other SQL groups

- **DML** (`INSERT`, `UPDATE`, `DELETE`, `SELECT`) works with the _rows_ inside the tables that DDL created.
- **DCL** (`GRANT`, `REVOKE`), which you already learned, controls _who may_ run DDL and DML.
- **TCL** (`BEGIN`, `COMMIT`, `ROLLBACK`) groups statements into transactions, as in the transactional DDL example above.




[[PostgreSQL]]