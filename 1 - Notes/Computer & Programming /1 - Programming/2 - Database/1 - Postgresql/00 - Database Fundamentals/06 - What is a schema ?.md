

A **schema** is a named namespace _inside_ a database. It groups tables, views, sequences, functions and types under one name, so the same object name can exist several times in one database without clashing. Every table you have ever created in PostgreSQL already lives in a schema. If you never chose one, it went into the schema called `public`.

In the hierarchy from the database lesson, the schema is the level between the database and the table: **cluster → database → schema → table**. A full table name is really `schema.table`, and when you type just `users`, PostgreSQL silently decides which schema you meant. Understanding how it decides (the `search_path`) is most of what you need to know.

---

## 1. Seeing and creating schemas

```
shopdb=# \dn
  List of schemas
  Name  |  Owner
--------+----------
 public | pg_database_owner
```

```sql
CREATE SCHEMA audit;
CREATE SCHEMA billing AUTHORIZATION app_owner;
```

- `CREATE SCHEMA audit;` makes an empty namespace called `audit`.
- `AUTHORIZATION app_owner` makes that role the owner, so it can create and drop things inside.

Now create two tables with the **same name** in different schemas:

```sql
CREATE TABLE public.users (id serial PRIMARY KEY, email text);
CREATE TABLE audit.users  (id serial PRIMARY KEY, changed_by text);
```

|Full name|Columns|
|---|---|
|`public.users`|`id`, `email`|
|`audit.users`|`id`, `changed_by`|

Two different tables, no conflict. Query each with its qualified name:

```sql
SELECT * FROM audit.users;
```

`\dt audit.*` lists tables in one schema, and `\dt *.*` lists every schema's tables (including system ones).

---

## 2. How PostgreSQL resolves an unqualified name: `search_path`

When you write `SELECT * FROM users;` with no schema, PostgreSQL walks through an ordered list of schemas and uses the **first one containing a table called `users`**. That list is the `search_path`:

```sql
SHOW search_path;
```

```
   search_path
-----------------
 "$user", public
```

Read it left to right:

1. `"$user"` means a schema with the same name as the current role. If you're logged in as `app_user` and a schema `app_user` exists, it is checked first. Otherwise it's skipped.
2. `public` is checked next.

Change it for the current session:

```sql
SET search_path TO audit, public;
SELECT * FROM users;     -- now resolves to audit.users first
```

Make it permanent for a role or a database:

```sql
ALTER ROLE app_user SET search_path = billing, public;
ALTER DATABASE shopdb SET search_path = billing, public;
```

One more rule: **`CREATE TABLE users` (unqualified) creates the table in the first existing schema of the search_path.** That is how tables end up in `public` without you asking.

---

## 3. The `public` schema

Every new database gets a `public` schema, and it's the default home for everything. Two things to know:

- It's a normal schema. You can drop it or restrict it.
- Since PostgreSQL 15, ordinary roles can no longer create objects in `public` by default. Only the database owner can. So an `app_user` trying `CREATE TABLE` there gets "permission denied for schema public" unless you grant it.

---

## 4. Schemas and permissions (links to DCL)

Schemas are a permission layer in their own right. Your DCL lesson covered this, so here it is in one block:

```sql
GRANT USAGE  ON SCHEMA audit TO reporting_user;   -- may look inside
GRANT CREATE ON SCHEMA audit TO migration_user;   -- may create objects inside
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO reporting_user;
```

|Privilege|Meaning|
|---|---|
|`USAGE`|Can access objects in the schema (still needs table-level grants)|
|`CREATE`|Can create new tables and objects in it|

Without `USAGE`, a role can't use `audit.users` even if it has `SELECT` on the table. This lets you hide a whole group of tables with one `REVOKE`.

---

## 5. What schemas are used for

|Use|Example|
|---|---|
|Separate parts of one app|`billing`, `inventory`, `auth` schemas in one database|
|Separate permissions|Give `reporting_user` only the `reports` schema|
|Multi-tenant apps|One schema per customer: `tenant_acme.orders`, `tenant_globex.orders`|
|Keep extensions tidy|`CREATE EXTENSION pgcrypto SCHEMA ext;`|
|Version-safe migrations|Build a `v2` schema beside the live one, then switch|

The decision rule from the database lesson still holds: separate **databases** for separate projects (they can't query each other), separate **schemas** for separate areas of the same project (they can join across schemas freely):

```sql
SELECT o.id, u.email
FROM   billing.orders o
JOIN   public.users   u ON u.id = o.user_id;
```

---

## 6. Using schemas from Spring Boot

Your app picks its schema in one of these ways:

```properties
# 1. In the JDBC URL
spring.datasource.url=jdbc:postgresql://localhost:5432/shopdb?currentSchema=billing

# 2. Hibernate default for all entities
spring.jpa.properties.hibernate.default_schema=billing
```

```java
// 3. Per entity
@Entity
@Table(name = "orders", schema = "billing")
public class Order { ... }
```

- Option 1 sets the connection's `search_path` to `billing`.
- Option 2 makes Hibernate prefix every table with `billing.`.
- Option 3 overrides it for just one entity.

Also remember `spring.jpa.hibernate.ddl-auto`: when it creates tables, it creates them in the default schema, and the schema itself must already exist (Hibernate does not create it for you, so run `CREATE SCHEMA billing;` first).

---

## 7. Dropping and moving

```sql
DROP SCHEMA audit;              -- fails if it still contains objects
DROP SCHEMA audit CASCADE;      -- deletes the schema AND everything inside
ALTER TABLE public.users SET SCHEMA audit;     -- move a table
ALTER SCHEMA audit RENAME TO audit_log;
```

`CASCADE` is dangerous, because it silently drops every table, view and function inside.

---

## 8. Common mistakes

1. **"relation does not exist" even though the table exists.** It is in a schema that isn't on your `search_path`. Check `\dt *.*` and `SHOW search_path;`.
2. **Granting table rights without `USAGE` on the schema.**
3. **Relying on `public` for everything**, then being blocked by the PostgreSQL 15 change.
4. **Hibernate pointing at a schema that doesn't exist yet.**
5. **Confusing "who owns the schema" with "who owns the tables".** They can be different roles, and ownership decides who may drop or grant.

---

## Related concept: the other meaning of "schema"

In general database talk, "schema" also means the **design of your tables** (their columns, types, keys and relationships), as in "show me the database schema" or an ER diagram. In PostgreSQL the word has that meaning _and_ the namespace meaning above, which causes confusion. A related wrinkle: in MySQL, "schema" is simply a synonym for "database", which is not true in PostgreSQL. In SQLite there are no schemas, apart from a few built-in names like `main` and `temp` for attached database files.




[[PostgreSQL]]