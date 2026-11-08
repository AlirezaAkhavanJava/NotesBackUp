

A **migration** is a small, versioned script that changes your database's structure (or sometimes its data) from one state to the next. Instead of logging into the database and typing `ALTER TABLE` by hand, you write the change in a file, give it a version number, and let a tool apply it. Every change to your database becomes a numbered step you can review, repeat, and track, much like commits in Git.

Think of it as a recipe card system for building your database. Anyone can start with an empty PostgreSQL server, apply the cards in order, and end up with exactly the same database you have. Let's look at why that matters and how it works.

## The pain that migrations cure

Picture a team of four developers and a production server. Without migrations, things go wrong in predictable ways:

- Alice adds a column on her laptop and forgets to tell anyone, so Bob's code crashes with "column does not exist."
- Someone fixes a problem directly on the production database at 2 a.m. and nobody remembers exactly what they ran.
- A new teammate joins and nobody can tell them how to build a working database from scratch.
- Staging and production quietly drift apart until a release behaves differently in each.

Migrations solve all of these with one rule: **the database schema changes only through versioned files that live in your repository.**

## What a migration looks like

A migration is usually just a SQL file with a version in its name. Here's a tiny history for a shop:

```
V1__create_customers.sql
V2__create_orders.sql
V3__add_phone_to_customers.sql
```

```sql
-- V1__create_customers.sql
CREATE TABLE customers (
    id    BIGSERIAL PRIMARY KEY,
    name  TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);
```

```sql
-- V3__add_phone_to_customers.sql
ALTER TABLE customers ADD COLUMN phone TEXT;
```

Notice that V3 doesn't recreate the table. It describes only the **difference** between the old state and the new one. The current schema is the sum of all migrations applied in order.

## How the tool knows what has already run

A migration tool keeps a bookkeeping table inside your database, a history of what's been applied. It looks roughly like this:

|version|description|applied_at|checksum|
|---|---|---|---|
|1|create customers|2026-10-01|a91f...|
|2|create orders|2026-10-05|77c0...|

When you run the tool, it compares your migration files against this table and applies only the ones that are missing, in order. That's why running it twice is safe: the second run finds nothing new to do. The **checksum** lets the tool detect if someone edited a migration that was already applied, which brings us to the most important rule.

## The golden rule: never edit an applied migration

Once a migration has run anywhere beyond your own laptop, treat it as **immutable**. If V3 had a mistake, don't fix V3. Write V4 that corrects it:

```sql
-- V4__make_phone_text_not_null_default.sql
UPDATE customers SET phone = '' WHERE phone IS NULL;
ALTER TABLE customers ALTER COLUMN phone SET NOT NULL;
```

Editing history breaks the guarantee that every environment ran the _same_ steps, and the checksum comparison will rightfully refuse to continue.

## Up, down, and the rollback question

Some tools support "up" migrations (apply the change) and "down" migrations (undo it). Down scripts sound great but are harder than they look. You can drop a column, but you can't un-drop the data that was in it. Many teams skip down migrations for production and instead **roll forward**: if something is wrong, they write a new migration that fixes it. A solid backup plan covers the real disasters.

## PostgreSQL's gift: transactional DDL

Remember transactions from our last lesson? PostgreSQL lets you wrap schema changes in a transaction too, which many databases can't do:

```sql
BEGIN;

ALTER TABLE customers ADD COLUMN loyalty_points INT NOT NULL DEFAULT 0;
CREATE INDEX idx_customers_email_lower ON customers (lower(email));

COMMIT;
```

If the second statement fails, the first is undone automatically, so a migration never leaves you with a half-changed schema. Most migration tools run each file in a transaction for exactly this reason.

One exception is `CREATE INDEX CONCURRENTLY`, which cannot run inside a transaction block, so it needs its own migration file with transactions turned off for that file (check your tool's documentation for how).

## Migrating on a live system without breaking it

On a toy database, any change is safe. On a busy production database, some changes **lock the table** and make everyone wait. A few good habits:

- **Adding a column with a constant default** is fast in modern PostgreSQL (11 and later), so it's safe.
- **Build indexes with `CREATE INDEX CONCURRENTLY`** so reads and writes continue while the index builds.
- **Set a `lock_timeout`** so a migration gives up quickly instead of queueing behind a long query and blocking everyone behind it:

```sql
SET lock_timeout = '3s';
ALTER TABLE customers ADD COLUMN nickname TEXT;
```

- **Use the expand/contract pattern for risky changes.** Say you want to rename `phone` to `phone_number` without downtime. Instead of one `RENAME`, you (1) _expand_: add `phone_number` and copy data over, (2) update the application to use the new column, then (3) _contract_: drop the old `phone` column in a later migration. Old and new code can both work during the transition.

## Schema migrations vs. data migrations

Two related ideas share the name:

- A **schema migration** changes structure: tables, columns, indexes, constraints.
- A **data migration** changes the _contents_, such as backfilling a new column or splitting a `full_name` into first and last names.

```sql
-- a data migration
UPDATE customers SET phone = 'unknown' WHERE phone IS NULL;
```

For huge tables, backfill in small batches rather than one giant `UPDATE`, because a single massive transaction holds locks for a long time and bloats the table.

The word "migration" is also used for **moving a whole database** from one place to another (say, from MySQL to PostgreSQL, or from one server to a new one). That's a bigger project with different tools, but the spirit is the same: a careful, repeatable move from one state to another.

## Handy habits to take with you

- **One logical change per migration**, with a descriptive name like `V7__add_index_on_orders_customer_id`.
- **Keep migration files in version control** alongside your code, and review them like code.
- **Test migrations on a copy of production-sized data** when you can, since a change that takes a millisecond on 100 rows may take an hour on 100 million.
- **Run migrations automatically** in your deployment pipeline so no environment is ever updated by hand.

## Wrapping up

A migration is a versioned, ordered, repeatable change to your database, tracked in a history table so every environment ends up identical. Combined with PostgreSQL's transactional DDL and a few safe-deployment habits, it turns scary schema changes into routine, reviewable steps.




[[PostgreSQL]]