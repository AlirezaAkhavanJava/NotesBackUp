


## Core intuition

Spring Boot reads `src/main/resources/application.properties` at startup and uses it to auto-configure everything. Each setting is a `key=value` line, and the key prefix tells you who reads it:

- `spring.datasource.*` configures the **connection** (shared by both tools)
- `spring.jpa.*` configures **JPA/Hibernate**
- `spring.flyway.*` configures **Flyway**

The YAML from before and this file are the same configuration in two syntaxes. YAML nests keys by indentation, while properties spells out the full dotted path on every line.

## Minimal working file

```properties
# --- Connection (used by both Flyway and JPA) ---
spring.datasource.url=jdbc:postgresql://localhost:5432/appdb
spring.datasource.username=app
spring.datasource.password=secret

# --- JPA / Hibernate ---
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false

# --- Flyway ---
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
```

Technically, Flyway is enabled by default and `classpath:db/migration` is the default location, so the last two lines only make the defaults visible. Being explicit is good while learning.

## Each setting and why it exists

|Property|Meaning|Why it matters|
|---|---|---|
|`spring.datasource.url`|JDBC URL|Flyway reuses it automatically, so you don't configure the DB twice|
|`spring.jpa.hibernate.ddl-auto`|What Hibernate does to the schema|`validate` = only check, never change. This is the safety net|
|`spring.jpa.open-in-view`|Keeps the DB session open during web rendering|`false` avoids hidden lazy queries in controllers. Spring warns at startup if you leave the default|
|`spring.flyway.enabled`|Turns Flyway on or off|Useful to disable in some test setups|
|`spring.flyway.locations`|Where migration files are|Can list several, comma-separated|

Valid values for `ddl-auto`:

- `none`: do nothing
- `validate`: check entities against the schema, fail on mismatch
- `update`: Hibernate alters the schema (don't combine with Flyway)
- `create` / `create-drop`: rebuild the schema (only for throwaway in-memory databases)

## Useful extras for development

```properties
# See the SQL Hibernate generates
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# Verbose Flyway logging
logging.level.org.flywaydb=DEBUG
```

`show-sql` prints to stdout. To see the bound parameter values too, add `logging.level.org.hibernate.orm.jdbc.bind=TRACE`.

## Flyway-specific options

```properties
# Existing database that already has tables but no history table
spring.flyway.baseline-on-migrate=true
spring.flyway.baseline-version=1

# Check checksums and file validity before migrating (default: true)
spring.flyway.validate-on-migrate=true

# Never allow flyway clean (wipes the DB). Default is true already in recent versions
spring.flyway.clean-disabled=true

# Rename the history table or choose the schema
spring.flyway.table=flyway_schema_history
spring.flyway.default-schema=public

# Allow late-arriving older versions (last resort for team conflicts)
spring.flyway.out-of-order=false

# Retry if the DB isn't ready yet (e.g. in Docker)
spring.flyway.connect-retries=10
```

## Separate users for migrating and running

In a real deployment, the app user should not have permission to drop or alter tables. Flyway can use its own credentials:

```properties
# App runtime user: SELECT/INSERT/UPDATE/DELETE only
spring.datasource.username=app_runtime
spring.datasource.password=${DB_APP_PASSWORD}

# Migration user: DDL rights
spring.flyway.user=app_migrator
spring.flyway.password=${DB_MIGRATOR_PASSWORD}
```

When `spring.flyway.user` is set, Flyway uses it instead of the datasource user. You can also set `spring.flyway.url` if it needs a different connection.

## Never hardcode secrets

The `${...}` syntax reads an environment variable. On Debian:

```bash
export DB_APP_PASSWORD=secret
./mvnw spring-boot:run
```

You can add a default: `${DB_PASSWORD:secret}` uses `secret` when the variable is missing. Spring also maps environment variables to properties by itself: `SPRING_DATASOURCE_PASSWORD` overrides `spring.datasource.password` without touching the file.

## Profiles: different config per environment

Create separate files:

```properties
# application.properties (shared, always loaded)
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
spring.profiles.active=dev
```

```properties
# application-dev.properties
spring.datasource.url=jdbc:postgresql://localhost:5432/appdb_dev
spring.datasource.username=dev
spring.datasource.password=dev
spring.jpa.show-sql=true
spring.flyway.locations=classpath:db/migration,classpath:db/dev-data
```

```properties
# application-prod.properties
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
spring.jpa.show-sql=false
spring.flyway.locations=classpath:db/migration
```

Spring loads `application.properties` first, then layers the active profile's file on top, so profile values win on conflict. This is how the dev-only seed data from the previous topic stays out of production. Switch profiles at launch with `--spring.profiles.active=prod`.

## Gotchas

**Trailing spaces are part of the value.** `spring.flyway.enabled=true` (with a trailing space) can cause confusing errors. Check this first when a property seems ignored.

**No quotes needed.** `spring.datasource.password="secret"` makes the quotes part of the password.

**Comments** start with `#` and must be on their own line. An inline `key=value # comment` makes the comment part of the value.

**Typos fail silently.** `spring.flyway.location` (missing `s`) is just ignored, and Flyway falls back to the default. If a setting has no effect, compare the key character by character. IDEs like IntelliJ autocomplete these keys if `spring-boot-configuration-processor` metadata is available.

**Properties and YAML in the same project.** Don't keep both `application.properties` and `application.yml`. If both exist, both load and properties win on conflicts, which is confusing. Pick one.

**You don't need `spring.jpa.database-platform`.** Hibernate detects the dialect from the connection. Setting an old dialect manually is a common copy-paste problem from outdated tutorials.

**Test config.** Put overrides in `src/test/resources/application-test.properties`, or in a test class with `@DynamicPropertySource` when using Testcontainers, so the container's random port is injected into `spring.datasource.url`.

## Connection to the previous topic

The `validate` setting here is what produces the "missing column" error when you forget a migration. The order of events (Flyway first, then Hibernate) is built into Spring Boot, so nothing in this file controls it. You only describe _what_, and Spring handles the sequencing.




[[Spring Framework]]