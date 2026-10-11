
These three names are labels for groups of SQL statements, sorted by what they act on. The labels come from the SQL standard, not from MariaDB, so you may already know them from Postgres. What's worth your time here is how MariaDB treats each group differently, especially around transactions.

## DDL: Data Definition Language

DDL statements define and change the **structure** of the database: the objects that hold your data, not the data itself.

```sql
CREATE DATABASE shop;
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL);
ALTER TABLE users ADD COLUMN email VARCHAR(150);
DROP TABLE users;
TRUNCATE TABLE users;
RENAME TABLE users TO customers;
CREATE INDEX idx_email ON users (email);
```

The members are `CREATE`, `ALTER`, `DROP`, `RENAME`, and `TRUNCATE`. The surprise for most people is `TRUNCATE`: it feels like "delete all rows", but it's DDL, because MariaDB implements it by dropping and recreating the table. That's why it's fast, resets `AUTO_INCREMENT` back to 1, and can't be rolled back, while `DELETE FROM users;` does none of those things.

Here is the biggest difference from Postgres. **In MariaDB, every DDL statement commits implicitly.** Postgres has transactional DDL, so you can write `BEGIN; ALTER TABLE ...; ROLLBACK;` and the change vanishes. In MariaDB that doesn't work:

```sql
START TRANSACTION;
INSERT INTO users (name) VALUES ('Sara');
ALTER TABLE users ADD COLUMN age INT;   -- silently commits the INSERT above
ROLLBACK;                               -- too late, Sara is already saved
```

The `ALTER` closed your transaction for you, and the `ROLLBACK` has nothing left to undo. The practical lesson is to never mix DDL into a transaction you hope to undo, and to take a `mariadb-dump` before risky schema changes. Recent versions have made DDL crash-safe, so a power cut won't leave a half-built table, but crash-safe is not the same as rollback-able.

MariaDB also has a few DDL conveniences Postgres lacks:

```sql
CREATE OR REPLACE TABLE users (...);   -- drop and recreate in one statement
DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (...);
ALTER TABLE users ADD COLUMN IF NOT EXISTS age INT;
```

## DML: Data Manipulation Language

DML statements change the **rows** inside tables.

```sql
INSERT INTO users (name, email) VALUES ('Sara', 'sara@example.com');
UPDATE users SET email = 'new@example.com' WHERE id = 1;
DELETE FROM users WHERE id = 1;
```

DML is transactional on InnoDB, so you get the usual `START TRANSACTION`, `COMMIT`, and `ROLLBACK` safety net. One thing to check on your setup: the shell has **autocommit on by default**, so each statement commits itself unless you open a transaction explicitly. That's the same as `psql`, but it's worth remembering when you're experimenting.

MariaDB's DML has some dialect features you'll find useful:

```sql
-- upsert: Postgres's ON CONFLICT
INSERT INTO users (id, name) VALUES (1, 'Sara')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- REPLACE: delete the conflicting row, then insert (careful: it's a delete+insert)
REPLACE INTO users (id, name) VALUES (1, 'Sara');

-- RETURNING works on INSERT and DELETE
INSERT INTO users (name) VALUES ('Omid') RETURNING id, name;
DELETE FROM users WHERE id = 2 RETURNING *;

-- UPDATE and DELETE accept ORDER BY and LIMIT
DELETE FROM logs ORDER BY created_at LIMIT 1000;
```

Note that `UPDATE ... RETURNING` is **not** supported in MariaDB, unlike Postgres. And `ON DUPLICATE KEY UPDATE` triggers on _any_ unique key that collides, not on a column you name, which is less precise than `ON CONFLICT (email)`. Also, `REPLACE` deserves caution: because it deletes and reinserts, it fires delete behavior, can cascade through foreign keys, and gives the row a new `AUTO_INCREMENT` id if you didn't specify one.

## DQL: Data Query Language

DQL is the smallest group, because it's essentially one statement: `SELECT`.

```sql
SELECT name, email FROM users WHERE id > 10 ORDER BY name LIMIT 5;
```

Everything built around it belongs here too: joins, `GROUP BY`, subqueries, CTEs, and window functions. `SHOW` and `DESCRIBE` are sometimes listed alongside it, but they're really MariaDB's administrative commands, since they report on structure rather than querying your data.

Some people don't separate DQL at all and file `SELECT` under DML. Both conventions exist, so don't be thrown if a textbook says "DML includes SELECT". The split exists because `SELECT` changes nothing, which makes it a useful thing to keep apart in your head. The analogy to "read-only" has one catch: `SELECT ... FOR UPDATE` takes row locks, so it does interfere with other transactions.

## The other two groups

You'll hear two more names alongside these:

- **DCL (Data Control Language)** handles permissions: `GRANT`, `REVOKE`, and `CREATE USER`. This is the user-and-privilege topic from earlier.
- **TCL (Transaction Control Language)** covers `START TRANSACTION`, `COMMIT`, `ROLLBACK`, and `SAVEPOINT`. These group your DML into all-or-nothing units.

## Why the grouping matters in practice

It tells you what a statement can break and whether you can take it back. DQL is always safe. DML is risky but recoverable inside a transaction. DDL is the dangerous one in MariaDB, because it can change or destroy structure and commits instantly. A useful habit follows from that: when a script mixes all three, put the DDL first, then run the DML inside an explicit transaction.

This also lines up with Spring Boot, where the split shows up in your tooling. Schema creation and migrations (Flyway or Liquibase, or Hibernate's `ddl-auto` setting) are DDL, while your repository methods and `@Transactional` services work with DML and DQL. For real projects, keeping DDL in versioned migration files rather than letting Hibernate generate it is the standard approach.




[[MySQL]]