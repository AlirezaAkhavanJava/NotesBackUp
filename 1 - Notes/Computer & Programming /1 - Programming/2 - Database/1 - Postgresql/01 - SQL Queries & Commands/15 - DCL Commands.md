

DCL is the part of SQL that decides **who is allowed to do what** inside a database. Every other SQL command asks "what should happen to the data?" DCL asks "is this user permitted to make that happen?" It has two core commands: `GRANT`, which gives a permission, and `REVOKE`, which takes it back.

DCL matters the moment more than one account touches your database. Your Spring Boot app, your migration tool, a reporting tool and you in `psql` should not all have the same power. DCL lets you give each one only what it needs. I'll teach this with **PostgreSQL**, since that's what you use. SQLite has no DCL at all, because it is a single file with no users or roles, so access is controlled by file permissions on your OS instead.

---

## 1. Roles: the thing you grant to

Before `GRANT` makes sense, you need something to grant _to_. In PostgreSQL that is a **role**. A role is a user, a group, or both. The only difference is whether it can log in.

```sql
CREATE ROLE app_user LOGIN PASSWORD 'secret123';   -- a "user"
CREATE ROLE readonly_team NOLOGIN;                 -- a "group"
```

Line by line:

- `CREATE ROLE app_user` creates a role named `app_user`.
- `LOGIN` lets it connect. Without it, the role can't open a connection.
- `PASSWORD '...'` sets the password.
- `NOLOGIN` makes a role that nobody can log in as. It only exists to hold permissions that other roles will inherit.

`CREATE ROLE` is technically DDL, not DCL, but you can't practice DCL without it.

---

## 2. GRANT: giving privileges

The shape is always:

```sql
GRANT <privileges> ON <object> TO <role>;
```

```sql
GRANT SELECT, INSERT ON users TO app_user;
```

- `SELECT, INSERT` are the privileges. `app_user` can read and add rows.
- `ON users` is the object, here a table.
- `TO app_user` is the receiver.

`app_user` still **cannot** `UPDATE` or `DELETE`. PostgreSQL denies everything by default, so you only ever list what is allowed.

### Privileges by object type

Different objects accept different privileges:

|Object|Privileges you can grant|
|---|---|
|Table|`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES`, `TRIGGER`|
|Column|`SELECT`, `INSERT`, `UPDATE`, `REFERENCES`|
|Sequence|`USAGE`, `SELECT`, `UPDATE`|
|Schema|`USAGE`, `CREATE`|
|Database|`CONNECT`, `CREATE`, `TEMPORARY`|
|Function|`EXECUTE`|

`ALL PRIVILEGES` is a shortcut for everything valid on that object.

### Gotcha 1: the schema needs `USAGE`

Table access alone is not enough. The role must also be allowed to _enter_ the schema:

```sql
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_user;
```

The first line lets `app_user` look inside the schema. The second grants `SELECT` on every table that exists **right now**. Tables you create later are not included (see section 6).

### Gotcha 2: auto-increment columns need sequence access

If `users.id` is `SERIAL` or `BIGSERIAL`, inserting a row calls a sequence behind the scenes. Without this, your `INSERT` fails with "permission denied for sequence":

```sql
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
```

This is a very common surprise when a Spring Boot app can `SELECT` fine but `save()` fails.

### Column-level grants

You can restrict a role to specific columns:

```sql
GRANT SELECT (id, email) ON users TO reporting_user;
GRANT UPDATE (email)     ON users TO app_user;
```

`reporting_user` can read `id` and `email` but never sees `password`. `app_user` can change only `email`. Selecting `*` as `reporting_user` fails, because `*` includes columns it has no right to.

---

## 3. Role membership: roles that contain roles

You can grant a _role_ to another role, which is how you build groups:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_team;
GRANT readonly_team TO alice;
GRANT readonly_team TO bob;
```

- Line 1 gives the group its permissions once.
- Lines 2 and 3 make `alice` and `bob` members, so they inherit those permissions.

When the team's access changes, you edit one role instead of every person. This is the same idea as Spring Security roles being a bundle of permissions, just enforced at the database level instead of in your app.

By default members inherit automatically (`INHERIT`). You can disable that per role with `CREATE ROLE x NOINHERIT`, and the member then has to run `SET ROLE readonly_team;` to use the group's rights.

---

## 4. WITH GRANT OPTION: letting others grant

```sql
GRANT SELECT ON users TO lead_dev WITH GRANT OPTION;
```

Now `lead_dev` can run `GRANT SELECT ON users TO someone_else;` too. Use it sparingly, because it spreads permission control to people who may not need it. (For role membership, the equivalent is `WITH ADMIN OPTION`.)

---

## 5. REVOKE: taking privileges back

`REVOKE` mirrors `GRANT`:

```sql
REVOKE INSERT ON users FROM app_user;
REVOKE ALL PRIVILEGES ON users FROM app_user;
REVOKE readonly_team FROM alice;
```

Notice `FROM` instead of `TO`. Three important behaviors:

- **Revoking something never granted does nothing**, with no error.
- **Revoking from a group doesn't revoke what a user was granted directly.** If `alice` has `SELECT` directly _and_ through `readonly_team`, removing her from the team leaves the direct one.
- **Cascade:** if `lead_dev` granted rights onward using their grant option, you need `REVOKE ... CASCADE` to remove those too. To remove only the ability to grant, use `REVOKE GRANT OPTION FOR SELECT ON users FROM lead_dev;`.

---

## 6. ALTER DEFAULT PRIVILEGES: covering future tables

`GRANT ... ON ALL TABLES` only affects tables that exist today. For tables created later:

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
```

From now on, any table created **by the role that ran this command** in `public` automatically gives `app_user` those rights. If a different role (like your migration user) creates the tables, add `FOR ROLE migration_user` after `ALTER DEFAULT PRIVILEGES`.

---

## 7. The `PUBLIC` pseudo-role

`PUBLIC` means "every role, including ones created later":

```sql
REVOKE ALL ON DATABASE mydb FROM PUBLIC;
```

By default PostgreSQL lets everyone `CONNECT` to a database and use `TEMPORARY`. Revoking from `PUBLIC` is a common first hardening step. Since PostgreSQL 15, ordinary users also no longer get `CREATE` on the `public` schema by default.

---

## 8. Checking what exists

In `psql`:

```
\du            -- list roles
\dp users      -- show privileges on table "users"
```

`\dp` prints something like `app_user=ar/postgres`. Each letter is a privilege: `a` = INSERT, `r` = SELECT, `w` = UPDATE, `d` = DELETE. After the `/` is the role that granted it.

In SQL, you can ask directly:

```sql
SELECT has_table_privilege('app_user', 'users', 'INSERT');   -- true or false
```

---

## 9. Putting it together for your Spring Boot app

A sensible setup uses two accounts:

```sql
-- Owns the tables, used by migrations only
CREATE ROLE migration_user LOGIN PASSWORD '...';

-- Used by the running app, DML only
CREATE ROLE app_user LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE mydb TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE migration_user IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
```

Your `spring.datasource.username` then points at `app_user`. If the app is compromised or has a bug, it can't `DROP TABLE` or change the schema. One catch: if you use `spring.jpa.hibernate.ddl-auto=update`, the app _needs_ DDL rights, so use a migration tool such as Flyway or Liquibase with `migration_user` instead.

---

## Common mistakes

1. **Granting on the table but forgetting `USAGE` on the schema.** The error says the table does not exist or permission is denied.
2. **Forgetting sequences**, so `INSERT` fails.
3. **Assuming `ALL TABLES` covers future tables.** It doesn't. Use `ALTER DEFAULT PRIVILEGES`.
4. **Running the app as the `postgres` superuser.** Superusers bypass every check, so none of your DCL applies to them.
5. **Table owners.** The owner has all rights on its table automatically, and only the owner (or a superuser) can grant on it.

---

## Related concept: the other SQL sub-languages

DCL is one of several groups of SQL commands:

|Group|Meaning|Commands|
|---|---|---|
|DDL|Defines structure|`CREATE`, `ALTER`, `DROP`|
|DML|Changes data|`INSERT`, `UPDATE`, `DELETE`|
|DQL|Reads data|`SELECT`|
|TCL|Controls transactions|`BEGIN`, `COMMIT`, `ROLLBACK`|
|DCL|Controls permissions|`GRANT`, `REVOKE`|

Also worth knowing exists: **Row-Level Security** (`CREATE POLICY`) in PostgreSQL goes one step beyond DCL by controlling which _rows_ a role can see, not just which tables. And SQL Server adds a `DENY` command that blocks a permission even if another role grants it, which PostgreSQL doesn't have.




[[PostgreSQL]]