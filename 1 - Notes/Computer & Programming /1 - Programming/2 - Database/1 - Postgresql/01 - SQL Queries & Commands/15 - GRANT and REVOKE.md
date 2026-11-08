

`GRANT` and `REVOKE` are the two PostgreSQL commands that control **permissions**. `GRANT` gives a user or role the right to do something (read a table, insert rows, connect to a database), and `REVOKE` takes that right away. Together they let you decide exactly who can touch which parts of your data.

Think of a building with keycards. Every employee gets a card, but each card opens only certain doors: the receptionist's card opens the front door, the accountant's card also opens the finance room, and nobody's card opens the server room except the admin's. `GRANT` programs a door onto a card, and `REVOKE` removes it. Let's see why this matters and how it works.

## Why we need permissions at all

Imagine your application connects to the database as the all-powerful owner account. Now consider what can go wrong:

- A bug, or an attacker exploiting a SQL injection hole, can `DROP TABLE customers` because the connection is allowed to.
- A reporting tool that only needs to _read_ data can accidentally (or deliberately) modify it.
- An intern running queries on production can see salary data they have no business seeing.

The fix is the **principle of least privilege**: every user and application gets only the permissions it genuinely needs, and nothing more. `GRANT` and `REVOKE` are how you enforce it.

## Roles: the "who"

PostgreSQL has one concept for both users and groups: the **role**. A role with the `LOGIN` attribute can connect (that's what we usually call a user). A role without it is typically used as a group that holds permissions.

```sql
-- A user who can log in
CREATE ROLE alice LOGIN PASSWORD 'a-strong-password';

-- A group role that cannot log in
CREATE ROLE readonly;
```

(`CREATE USER` is just shorthand for `CREATE ROLE ... LOGIN`.)

## GRANT: giving permissions

The general shape is `GRANT <privilege> ON <object> TO <role>`:

```sql
GRANT SELECT ON customers TO alice;
GRANT SELECT, INSERT, UPDATE ON orders TO alice;
GRANT ALL PRIVILEGES ON invoices TO alice;
```

Different object types have different privileges. The common ones:

|Object|Privileges you can grant|
|---|---|
|**Table**|`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES`, `TRIGGER`|
|**Column**|`SELECT`, `INSERT`, `UPDATE`, `REFERENCES` (per column)|
|**Sequence**|`USAGE`, `SELECT`, `UPDATE`|
|**Schema**|`USAGE` (see inside it), `CREATE` (make objects in it)|
|**Database**|`CONNECT`, `CREATE`, `TEMPORARY`|
|**Function**|`EXECUTE`|

You can even restrict access to specific **columns**, which is great for hiding sensitive data:

```sql
GRANT SELECT (id, name, email) ON customers TO support_team;
-- support_team can read those three columns, but not, say, credit_score
```

## REVOKE: taking permissions away

`REVOKE` mirrors `GRANT`:

```sql
REVOKE INSERT, UPDATE ON orders FROM alice;
REVOKE ALL PRIVILEGES ON invoices FROM alice;
```

Notice the word changes: `GRANT ... TO`, but `REVOKE ... FROM`.

## A classic gotcha: schema access

Here's a mistake nearly everyone makes once. You grant `SELECT` on a table, but the user still gets "permission denied." Why? Because to reach a table, the user also needs `USAGE` on the **schema** that contains it:

```sql
GRANT USAGE ON SCHEMA public TO alice;
GRANT SELECT ON customers TO alice;   -- now it works
```

Likewise, a user needs `CONNECT` on the **database** itself. Permissions are layers: database, then schema, then table, then column. A door must be open at every layer.

## Groups: grant to a role, not to every person

Granting permissions one person at a time becomes unmanageable. Instead, grant them to a group role, then put people into the group:

```sql
CREATE ROLE readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- Now adding a new analyst is one line
GRANT readonly TO alice;
GRANT readonly TO bob;
```

When someone leaves the team, `REVOKE readonly FROM bob;` removes everything at once.

## Future tables: `ALTER DEFAULT PRIVILEGES`

Here's another surprise. `GRANT SELECT ON ALL TABLES IN SCHEMA public` only covers tables that **exist right now**. A table you create tomorrow won't be included. To handle future tables, set default privileges:

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO readonly;
```

This applies to tables created later **by the role that runs this command** (or the role you name with `FOR ROLE`), so run it as the role that creates your tables, usually inside a migration.

## Ownership, grant option, and the PUBLIC role

A few more ideas that complete the picture:

- **The owner** of an object (usually whoever created it) automatically has all privileges on it and can grant them to others. Only the owner (or a superuser) can drop or alter it.
- **`WITH GRANT OPTION`** lets the recipient pass the privilege on to others:

```sql
GRANT SELECT ON customers TO alice WITH GRANT OPTION;
```

Use it sparingly, since it spreads control beyond you.

- **`PUBLIC`** is a special pseudo-role meaning "everyone." Some privileges go to `PUBLIC` by default, for example `CONNECT` on new databases. And before PostgreSQL 15, everyone could also create objects in the `public` schema. If you're on an older version, tighten that up:

```sql
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
```

## Checking who has what

In `psql`, `\dp customers` (or `\z customers`) shows a table's privileges in a compact format like `alice=r/postgres`, meaning alice has read (`r` = SELECT), granted by postgres. Or query the standard views:

```sql
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'customers';
```

There's also a handy test function: `SELECT has_table_privilege('alice', 'customers', 'SELECT');` returns true or false.

## Putting it together: a sensible setup

A common real-world pattern separates three kinds of access:

```sql
-- The application: reads and writes data, but cannot change structure
CREATE ROLE app_user LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE shop TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Reporting: read-only
CREATE ROLE reporting LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE shop TO reporting;
GRANT USAGE ON SCHEMA public TO reporting;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting;

-- Migrations: the owner role, used only when deploying schema changes
```

Notice the sequence grant: tables with `BIGSERIAL` ids use sequences behind the scenes, and without `USAGE` on them, the app's `INSERT` statements will fail.

## Good habits

- **Start with nothing, add only what's needed.** It's far safer than starting open and trying to close doors.
- **Never let the application connect as the owner or a superuser.**
- **Use group roles** rather than granting to individuals.
- **Put grants in your migrations**, so every environment ends up with the same permissions.
- **Don't forget sequences and schema `USAGE`**, the two most common causes of "permission denied."

## Quick recap

`GRANT` gives a role specific privileges on specific objects, and `REVOKE` removes them. Permissions stack in layers (database, schema, table, column), roles act as users or groups, and `ALTER DEFAULT PRIVILEGES` covers future tables. Follow least privilege, and a bug or a breach can only do as much damage as the keycard allows.




[[PostgreSQL]]