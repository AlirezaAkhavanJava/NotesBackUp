
# What is `ddl-auto`, and what are all its values?

DDL Auto (`spring.jpa.hibernate.ddl-auto`) is a Spring Boot configuration property that tells Hibernate how to manage the database schema (tables, columns, constraints, etc.) based on your JPA entity classes. It controls whether Hibernate should automatically create, update, validate, or delete database tables when the application starts.

Available values:

| Value         | Description                                                                    |
| ------------- | ------------------------------------------------------------------------------ |
| `none`        | Does not modify or validate the database schema.                               |
| `create`      | Drops existing tables and recreates them on startup.                           |
| `create-drop` | Like `create`, but also drops tables when the application shuts down normally. |
| `update`      | Attempts to update the schema while preserving existing data.                  |
| `validate`    | Checks whether the schema matches your entities without modifying it.          |

Example:

```
spring.jpa.hibernate.ddl-auto=update
```

Best practice: Use `update` for simple development environments, but prefer `validate` with Flyway migrations in production. Hibernate's `update` is not a reliable replacement for version-controlled database migrations.

## The problem it solves

Your Java entities describe tables: `@Entity class User` with `id`, `name` and `email` fields. But the database needs real tables before anything can be saved. Someone has to run `CREATE TABLE`.

`ddl-auto` tells Hibernate: **"At startup, how much should you do about the tables for me?"** (DDL means Data Definition Language, the SQL that creates and changes structure, like `CREATE` and `ALTER`.)

## How you set it

```properties
spring.jpa.hibernate.ddl-auto=update
```

Line by line:

1. **`spring.jpa.hibernate`** is the Hibernate settings area of Spring Boot.
2. **`ddl-auto`** is the switch for schema handling.
3. **`update`** is the value. It picks one of the five behaviors below.

## All the values

|Value|What Hibernate does at startup|Data safe?|
|---|---|---|
|`none`|Nothing. It never touches the schema.|Yes|
|`validate`|Checks that tables and columns match your entities. Fails to start if they don't.|Yes|
|`update`|Adds missing tables and columns. Never deletes anything.|Mostly|
|`create`|Drops your tables, then creates them fresh.|**No, data is wiped**|
|`create-drop`|Same as `create`, and drops the tables again when the app shuts down.|**No, data is wiped**|

### `none`

Hibernate stays out of it. You manage tables yourself, with SQL scripts or a migration tool. This is the safest choice for production.

### `validate`

Hibernate only **looks**. Say your entity has a `phone` field but the table has no `phone` column. The app refuses to start and tells you what is missing. It never changes anything, so it's a good safety net in production.

### `update`

Imagine you add a `phone` field to `User`:

|Before|After restart|
|---|---|
|`id, name, email`|`id, name, email, phone`|

Hibernate runs an `ALTER TABLE` to add the new column. Your existing rows stay. But `update` has limits. It **won't remove** columns you deleted from the entity, it **won't rename** columns (a rename looks like "new column added", so the old data is left behind), and it can't handle complicated changes. That is why people use it while learning but not in production.

### `create`

Every startup, your tables are dropped and rebuilt empty. Handy when you want a clean slate each run. Dangerous if you point it at a database with real data.

### `create-drop`

The same as `create`, plus a cleanup at shutdown. The database ends up empty after the app stops. It is great for tests.

## What if you don't set it?

Spring Boot picks a default for you:

- **Embedded databases** (H2, HSQLDB, Derby): `create-drop`
- **Everything else** (PostgreSQL, MySQL, SQLite): `none`

So with PostgreSQL and no setting, Hibernate creates no tables, and you get errors like `relation "user" does not exist`.

## Which one should I use?

|Situation|Good choice|
|---|---|
|Learning, small personal projects|`update` or `create`|
|Automated tests|`create-drop`|
|Production|`none` or `validate`|

A small tip for your setup. With **SQLite**, `update` is limited because SQLite can't do many `ALTER TABLE` changes. If your schema changes a lot, `create` during development is simpler.

## Related concept: schema migration tools

Tools like **Flyway** and **Liquibase** keep numbered SQL files (`V1__create_users.sql`, `V2__add_phone.sql`) and run each one exactly once, in order. You get a full history of every change, and you control the SQL. That is why real projects use them with `ddl-auto=none` or `validate`.

## Another "auto" you may have meant: `GenerationType.AUTO`

If you meant the one on entity IDs:

```java
@Id
@GeneratedValue(strategy = GenerationType.AUTO)
private Long id;
```

Its values are:

- **`AUTO`**: Hibernate chooses the best method for your database and dialect.
- **`IDENTITY`**: the database auto-increments the ID (`AUTO_INCREMENT`, `identity`).
- **`SEQUENCE`**: the ID comes from a database sequence object. This is the usual choice on PostgreSQL.
- **`TABLE`**: a separate table tracks the next ID. It is slow and rarely used.





[[Spring Framework]]