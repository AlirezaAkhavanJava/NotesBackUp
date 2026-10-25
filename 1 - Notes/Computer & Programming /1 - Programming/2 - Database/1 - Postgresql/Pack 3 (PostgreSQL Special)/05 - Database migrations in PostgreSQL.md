



A **migration** is a small, versioned file that describes one change to your database structure, such as "create the `customers` table" or "add a `phone` column." Instead of changing your database by hand, you write each change as a file, number it, and let a tool run the files in order. The tool remembers which ones have already run, so each change is applied exactly once, on every machine.

The word comes from the idea of *moving* your database from one version of its structure to the next, like `v1 → v2 → v3`. Since we are in a PostgreSQL chat, I'll teach this meaning. (The word is also used for "moving data from one database to another," for example SQLite to PostgreSQL. I'll cover that briefly at the end.)

---

## 1. The problem it solves

Imagine you build an app and your local database has a `clients` table. Then you add a `phone` column by clicking in pgAdmin. Now think about what goes wrong:

| Situation | What breaks |
|---|---|
| A teammate pulls your code | Their database has no `phone` column, so the app crashes with `column "phone" does not exist` |
| You deploy to a server | The server database is missing the column too, and you must remember to change it by hand |
| You come back in 3 months | You can't remember what you changed, or in which order |
| Something goes wrong | There is no record of what to undo |

The root issue is that **your Java code is in Git, but your database structure is not**. Code has history and review. Your schema has nothing.

Migrations fix this. The schema changes become files that live in Git next to your code. Every environment (your Debian machine, your Windows machine, a test server, production) can rebuild the *same* structure by running the same files in the same order.

---

## 2. How it works, step by step

Say you use **Flyway** (one of the two popular tools, covered below). You create files like this:

```
src/main/resources/db/migration/
    V1__create_clients.sql
    V2__create_orders.sql
    V3__add_phone_to_clients.sql
```

Each file contains plain SQL, for example `V1__create_clients.sql`:

```sql
CREATE TABLE clients (
    id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  text NOT NULL,
    email varchar(255) NOT NULL UNIQUE
);
```

And `V3__add_phone_to_clients.sql`:

```sql
ALTER TABLE clients ADD COLUMN phone varchar(30);
```

When your app starts, the tool does this:

1. It looks for a bookkeeping table in your database, called `flyway_schema_history`. If there is none, it creates one.
2. It reads that table to see which versions have already run.
3. It finds the files that have *not* run yet.
4. It runs those, in version order, and records each one in the history table.

After the first start, the history table looks like this:

| version | description | checksum | installed_on | success |
|---|---|---|---|---|
| 1 | create clients | 1839204 | 2026-10-25 14:10 | true |
| 2 | create orders | -557120 | 2026-10-25 14:10 | true |
| 3 | add phone to clients | 90211 | 2026-10-25 14:10 | true |

Next week you add `V4__...sql`. On start, the tool sees versions 1 to 3 are done, and runs only version 4. A brand new teammate with an empty database runs all four, and ends up with the identical structure.

Notice the **checksum** column. It is a fingerprint of each file's contents, and it is important in the rules below.

---

## 3. The golden rules

**Rule 1: Never edit a migration that has already run.** If `V3` has run anywhere, treat it as set in stone. If you change its contents, the checksum no longer matches, and the tool refuses to start:

```
Migration checksum mismatch for migration version 3
-> Applied to database : 90211
-> Resolved locally    : 44872
```

To change something, add a **new** migration (`V4`) that fixes it.

**Rule 2: One purpose per file.** Small files are easier to review and debug than one giant file.

**Rule 3: Keep them in Git** with your code, so the code and the schema version move together.

**Rule 4: Never let the app and the database drift.** Don't change the structure by hand in pgAdmin on a shared database. Do it through a migration.

**Rule 5: Make migrations safe for existing data.** For example, adding a `NOT NULL` column to a table that already has rows needs a default:

```sql
ALTER TABLE clients ADD COLUMN status varchar(20) NOT NULL DEFAULT 'active';
```

Without the `DEFAULT`, PostgreSQL fails with `column "status" of relation "clients" contains null values`.

---

## 4. Migrations vs `ddl-auto`

In Spring Boot you may have seen this setting:

```properties
spring.jpa.hibernate.ddl-auto=update
```

It tells Hibernate to compare your entities with the database and change the tables itself. It is tempting, but it has real limits:

| | `ddl-auto=update` | Migrations (Flyway / Liquibase) |
|---|---|---|
| Adds new tables and columns | Yes | Yes |
| Renames a column safely | No (it adds a new one and leaves the old one) | Yes, you write `RENAME COLUMN` |
| Drops columns or tables | No | Yes |
| Moves or fixes existing data | No | Yes, you can include `UPDATE` statements |
| History of what changed | None | Full, in files and a history table |
| Same result on every machine | Not guaranteed | Yes |
| Safe for production | No | Yes |

A good setup for a real project:

```properties
spring.jpa.hibernate.ddl-auto=validate
spring.flyway.enabled=true
```

`validate` doesn't change anything. It only checks that your entities match the tables the migrations created, and stops the app with a clear error if they don't.

---

## 5. Setting up Flyway in Spring Boot

**Step 1: add the dependencies** (Maven):

```xml
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-database-postgresql</artifactId>
</dependency>
```

The second one is the PostgreSQL support module, which Flyway needs in recent versions. Without it you can see an error like `Unsupported Database: PostgreSQL 17.x`.

**Step 2: configure the connection** in `application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/dummy
spring.datasource.username=app_user
spring.datasource.password=change_me

spring.jpa.hibernate.ddl-auto=validate
```

**Step 3: add your first migration** at `src/main/resources/db/migration/V1__create_clients.sql`.

**Step 4: start the app.** Spring Boot runs Flyway *before* Hibernate, so the tables exist by the time Hibernate validates them. Then open pgAdmin, refresh your database, and look: your tables are there, plus `flyway_schema_history`.

### File naming rules (Flyway)

| Type | Pattern | Example | Behavior |
|---|---|---|---|
| Versioned | `V<version>__<description>.sql` | `V2__create_orders.sql` | Runs once, in version order |
| Repeatable | `R__<description>.sql` | `R__refresh_views.sql` | Re-runs whenever its content changes |
| Undo (paid editions) | `U<version>__...sql` | | Reverts a version |

Note the **two underscores** after the version. One underscore, a wrong prefix, or a wrong folder, and Flyway silently ignores the file. Versions compare as numbers, so `V10` comes after `V9`, not after `V1`.

Repeatable migrations are great for things you replace entirely, like views and functions:

```sql
-- R__active_clients_view.sql
CREATE OR REPLACE VIEW active_clients AS
SELECT id, name FROM clients WHERE status = 'active';
```

---

## 6. Liquibase, the other popular tool

| | Flyway | Liquibase |
|---|---|---|
| Change files written in | Plain SQL (mostly) | XML, YAML, JSON, or SQL |
| Style | Simple, file-per-version | A "changelog" listing "changesets" |
| Database-independent syntax | No (you write PostgreSQL SQL) | Yes (can generate SQL per database) |
| Learning curve | Gentle | A bit steeper |

A Liquibase changeset in YAML looks like this:

```yaml
databaseChangeLog:
  - changeSet:
      id: 3
      author: you
      changes:
        - addColumn:
            tableName: clients
            columns:
              - column:
                  name: phone
                  type: varchar(30)
```

Both solve the same problem. If you already know SQL well and use only PostgreSQL, Flyway is usually the quicker start.

---

## 7. A realistic migration sequence

Here is how a small project's migrations might grow over time:

```
V1__create_clients.sql          -- first table
V2__create_orders.sql           -- second table with a foreign key
V3__add_phone_to_clients.sql    -- new column
V4__index_orders_customer.sql   -- CREATE INDEX for speed
V5__rename_name_to_full_name.sql
V6__backfill_status.sql         -- UPDATE existing rows
```

A rename and backfill, line by line:

```sql
-- V5
ALTER TABLE clients RENAME COLUMN name TO full_name;

-- V6
ALTER TABLE clients ADD COLUMN status varchar(20);
UPDATE clients SET status = 'active' WHERE status IS NULL;
ALTER TABLE clients ALTER COLUMN status SET NOT NULL;
```

The `V6` file does it in three safe steps: add the column as nullable, fill the old rows, then make it required. After `V5`, remember to update your Java entity too (`@Column(name = "full_name")`), or `validate` will stop the app.

---

## 8. Errors you may hit

| Error | Meaning | Fix |
|---|---|---|
| `Migration checksum mismatch` | You edited a migration that already ran | Revert the edit, and put the change in a new version. On a throwaway dev database only, you can run `flyway repair` or recreate the database |
| `Found non-empty schema(s) "public" but no schema history table` | The database already has tables, but Flyway has never run there | Set `spring.flyway.baseline-on-migrate=true` (this marks the current state as the starting point), or start from an empty database |
| `Validate failed: Detected failed migration to version 3` | An earlier run failed halfway | Fix the SQL, then repair the history entry. PostgreSQL's transactional DDL means a failed file is normally rolled back cleanly, so this is rarer than in other databases |
| `Detected resolved migration not applied to database: 2` | You added a version *lower* than the latest applied one | Use a new, higher version number, or enable `outOfOrder` (use sparingly) |
| `relation "clients" already exists` | The tables were created by hand or by `ddl-auto` before | Baseline, or clean the database |
| `Schema-validation: missing column [phone] in table [clients]` | Your entity has a field the migrations never created | Add a migration for it |
| `Unsupported Database: PostgreSQL 17` | Missing `flyway-database-postgresql` | Add the module |
| Migration file never runs | Wrong folder or name (single underscore, wrong prefix) | Check `db/migration` and the `V1__name.sql` pattern |
| `CREATE INDEX CONCURRENTLY cannot run inside a transaction block` | Flyway wraps each file in a transaction | Put it in its own file with the `-- flyway:executeInTransaction=false` header, or use `CREATE INDEX` without `CONCURRENTLY` on small tables |

Two cautions with powerful commands. `flyway clean` **drops everything** in the schema, so it is disabled by default in recent versions, and should never be enabled in production. And on large production tables, some `ALTER TABLE` commands take strong locks, so test slow migrations on a copy first.

---

## 9. Good habits

- **Test migrations on an empty database** regularly. Delete a scratch database like `dummy`, rebuild it from `V1`, and confirm the app starts. This proves your files really reproduce the schema.
- **Name files clearly**, so the list reads like a story of your database.
- **Prefer small, reversible steps.** To rename a column on a live system, many teams add the new column, copy the data, switch the code, and only later drop the old one.
- **Don't put secrets** (real passwords, API keys) in migration files. They live in Git forever.
- **Seed data is fine** for lookup values (`INSERT INTO roles ...`), but keep big test data out of migrations.
- **Use one tool.** Don't mix Flyway and `ddl-auto=update` on the same database.

---

## Related concepts, in short

- **Data migration:** moving *data* from one database to another (for example SQLite to PostgreSQL, or old tables to new ones). Tools include `pg_dump` / `pg_restore`, `COPY`, `pgloader`, or `INSERT ... SELECT` through a foreign data wrapper. Schema migrations change the *shape*, data migrations move the *contents*.
- **Baseline:** telling the tool "the database as it exists today counts as version N," so it won't try to rerun old history on an existing database.
- **Rollback / undo migrations:** a migration that reverses another. Many teams skip these and instead write a new forward migration that fixes things, because a real rollback after data has changed is often impossible.
- **Backup:** `pg_dump` takes a copy of the database. Run one before a risky production migration.

---

## Quick summary

```
Migration  = one versioned SQL file = one change to the schema
Tool       = Flyway or Liquibase runs them in order, once each
Bookkeeping = flyway_schema_history table tracks what has run
Golden rule = never edit a migration that already ran; add a new one
Spring Boot = flyway-core + flyway-database-postgresql, ddl-auto=validate
Location    = src/main/resources/db/migration/V1__description.sql
```




[[PostgreSQL]]