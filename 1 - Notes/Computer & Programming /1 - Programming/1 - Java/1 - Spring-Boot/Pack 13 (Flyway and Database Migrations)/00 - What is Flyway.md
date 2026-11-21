

Flyway is a database migration tool. It keeps your database schema under version control, the same way Git does for your code. Instead of changing tables by hand in `psql`, you write each change as a numbered SQL file. When your app starts, Flyway looks at which files the database has already seen, runs the new ones in order, and records them.

The payoff is that your schema becomes reproducible. A fresh database, a teammate's laptop and production all end up with exactly the same structure, built by the same files in the same order. It also replaces `spring.jpa.hibernate.ddl-auto=update`, which guesses at changes and can't be trusted in production. With Flyway, you write the DDL you learned earlier and Flyway makes sure it runs exactly once.

## How Flyway thinks

Flyway has four ideas, and everything else builds on them.

**Migration**: one SQL file that makes one set of changes. There are two kinds:

|Kind|File name|Runs|
|---|---|---|
|Versioned|`V1__create_users.sql`|exactly once, in version order|
|Repeatable|`R__active_users_view.sql`|again every time its content changes, after all versioned ones|

The naming rule is strict: `V` + version + **two underscores** + description + `.sql`. With one underscore, Flyway ignores the file.

**History table**: Flyway creates `flyway_schema_history` in your database. Each applied migration gets a row with its version, description, a **checksum** (a fingerprint of the file's content), who ran it, and whether it succeeded.

**Checksum validation**: on every startup Flyway compares your files against that table. If you edited a migration that was already applied, the checksum no longer matches and the app refuses to start. This is a feature: applied migrations are history, so you never edit them. You add a new migration instead (fix forward).

**Order**: versions are compared numerically, so `V2` runs before `V10`. Flyway applies only versions higher than the latest one in the history table.

## Configuring it step by step

### Step 1: Add the dependencies

Flyway needs its core plus a database-specific module, since Flyway 10 split PostgreSQL support into its own artifact.

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

If you're on Spring Boot 4, the auto-configuration moved out of the main module. Use `spring-boot-starter-flyway` in place of `flyway-core`, and keep the PostgreSQL module. If startup says it can't find a Flyway auto-configuration or doesn't recognise your database, this step is almost always the cause.

### Step 2: Make sure the datasource works

Flyway reuses your Spring datasource (`spring.datasource.url`, username and password) by default, so your existing PostgreSQL config is already enough. Nothing new is needed here.

### Step 3: Create the migration folder

Flyway looks in `src/main/resources/db/migration` by default. Create it and add your first migration:

```sql
-- V1__create_users.sql
CREATE TABLE users (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      VARCHAR(255) NOT NULL UNIQUE,
    password   VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
```

`GENERATED ALWAYS AS IDENTITY` is PostgreSQL's standard auto-incrementing column. Your entity maps to it with `@GeneratedValue(strategy = GenerationType.IDENTITY)`.

### Step 4: Add the Flyway properties

Since you already import `applicationFlyway.properties` through `spring.config.import`, this is the natural home for them:

```properties
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.validate-on-migrate=true
spring.flyway.clean-disabled=true
spring.flyway.connect-retries=5
```

Here is what each one does:

- `enabled`: turns Flyway on or off. It's on by default once the dependency is present.
- `locations`: where migrations live. It accepts several, comma-separated.
- `validate-on-migrate`: runs the checksum check before migrating. It's already the default; setting it makes the intent visible.
- `clean-disabled`: blocks `flyway clean`, a command that drops every object in the schema. Keep it `true` everywhere except a throwaway dev database.
- `connect-retries`: retries the connection at startup, useful when the database container starts slower than the app.

### Step 5: Let Hibernate only check, not change

Flyway now owns the schema, so Hibernate must stop touching it:

```properties
spring.jpa.hibernate.ddl-auto=validate
```

`validate` makes Hibernate compare your entities to the real tables at startup and fail if they disagree. That catches the mistake of changing an entity without writing a migration. Never use `update` or `create` alongside Flyway.

### Step 6: Start the app and verify

Spring Boot runs Flyway before JPA initialises, so the tables exist by the time Hibernate looks at them. Check the result in `psql`:

```sql
SELECT installed_rank, version, description, success
FROM flyway_schema_history;
```

You should see one row for `V1`. Restart the app and nothing runs again, because Flyway sees `V1` is already applied.

### Step 7: Evolve the schema with new migrations

To add a column, never touch `V1`. Add a new file:

```sql
-- V2__add_role_to_users.sql
ALTER TABLE users ADD COLUMN role VARCHAR(30) NOT NULL DEFAULT 'USER';
```

Restart and Flyway applies only `V2`. On PostgreSQL each migration runs inside a transaction by default, because PostgreSQL supports transactional DDL. If a migration fails halfway, the whole file rolls back and the database is left clean.

## Settings you'll meet in real projects

**Existing database that never used Flyway.** The history table doesn't exist, and Flyway refuses to run against a non-empty schema. Tell it to treat the current state as a starting point:

```properties
spring.flyway.baseline-on-migrate=true
spring.flyway.baseline-version=1
```

Flyway then records version 1 as the baseline and applies only migrations above it. Your `V1` file should describe the schema as it already exists, so it gets skipped.

**A separate Flyway user.** Creating tables needs more privileges than reading and writing rows. This is where the GRANT/REVOKE knowledge pays off. Let Flyway connect as an owner role while the running app uses a limited one:

```properties
spring.flyway.user=app_migrator
spring.flyway.password=${FLYWAY_PASSWORD}
```

Flyway also accepts `spring.flyway.url` if it needs a different connection from the app's.

**Schema and history table.** `spring.flyway.default-schema` sets the schema Flyway works in and where it keeps its history table. `spring.flyway.table` renames that table. Use them if you keep your app's tables outside `public`.

**Per-profile data.** Locations can differ by profile, so dev-only seed data never reaches production:

```properties
# application-dev.properties
spring.flyway.locations=classpath:db/migration,classpath:db/dev-data
```

**Placeholders.** Flyway can substitute values into your SQL, written as `${name}`, defined with `spring.flyway.placeholders.name=value`. This helps when the same migration needs a different schema or role name per environment.

## Rules that keep you out of trouble

1. **Never edit an applied migration.** Add a new version instead. This is what the checksum error is protecting.
2. **One logical change per file**, with a clear description in the name.
3. **Out-of-order migrations**: if a teammate merges `V5` after you've already applied `V6`, Flyway refuses by default. `spring.flyway.out-of-order=true` allows it, but fixing the version numbers is usually the cleaner answer.
4. **If a migration fails on a database without transactional DDL**, the history row is marked failed and you must repair it by hand. On PostgreSQL this rarely happens thanks to the rollback.
5. If startup complains that PostgreSQL 18 is unsupported or not tested, your Flyway version is older than your database. Bump the Flyway version in your build.

## Related concept in short: Liquibase

Liquibase solves the same problem differently. Instead of plain SQL files, it describes changes in XML, YAML or SQL "changesets" with ids, and it can generate rollbacks. Flyway is simpler because it's just SQL files in order, so most Spring teams start there. Liquibase fits when you need database-neutral change definitions or built-in rollbacks.


[[Spring Framework]]