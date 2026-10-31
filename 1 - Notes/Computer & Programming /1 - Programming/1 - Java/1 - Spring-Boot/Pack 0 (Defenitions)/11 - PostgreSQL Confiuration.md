

A PostgreSQL configuration is the small set of settings in your `application.properties` (or `application.yml`) that tells Spring Boot **where your database is, how to log in, how many connections to keep open, and how Hibernate should treat your tables**. Spring Boot reads these lines at startup and builds a `DataSource` (the connection factory) and an `EntityManagerFactory` (Hibernate's engine) from them, so you rarely write any Java for it.

The lines fall into four groups: **connection** (`spring.datasource.*`), **connection pool** (`spring.datasource.hikari.*`), **Hibernate/JPA behavior** (`spring.jpa.*`), and **schema setup** (`spring.sql.init.*`, Flyway/Liquibase). Once you know which group a line belongs to, you know what it affects. I'm assuming you mean the Spring Boot side here. The server's own `postgresql.conf` is a different file, covered briefly at the end.

---

## A complete example first

```properties
# --- Connection ---
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=secret
spring.datasource.driver-class-name=org.postgresql.Driver

# --- Connection pool (HikariCP) ---
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000

# --- JPA / Hibernate ---
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.open-in-view=false
```

Now each group, line by line.

---

## Group 1: The connection

### `spring.datasource.url`

```
jdbc:postgresql://localhost:5432/mydb
```

Split it into parts:

|Part|Meaning|
|---|---|
|`jdbc:`|The protocol. Tells Java this is a JDBC URL.|
|`postgresql:`|The database type. This selects the PostgreSQL driver.|
|`//localhost`|The host. Use a server name or IP for remote databases. In Docker Compose, use the service name.|
|`:5432`|The port. 5432 is PostgreSQL's default. If you mapped a different port (for example `-p 5433:5432`), use the one on the left.|
|`/mydb`|The database name. It must already exist.|

You can add **options** after a `?`, joined with `&`:

```
jdbc:postgresql://localhost:5432/mydb?currentSchema=shop&sslmode=require&ApplicationName=demo-app
```

|Option|What it does|
|---|---|
|`currentSchema=shop`|Uses the `shop` schema instead of `public`|
|`sslmode=require`|Forces an encrypted connection (other values: `disable`, `allow`, `prefer`, `verify-ca`, `verify-full`)|
|`ApplicationName=demo-app`|Shows a name in `pg_stat_activity`, so a DBA can see which app owns a connection|
|`connectTimeout=10`|Seconds to wait when opening a connection|
|`socketTimeout=30`|Seconds to wait for a reply before giving up|
|`reWriteBatchedInserts=true`|Makes batch inserts much faster (the driver merges them)|
|`options=-c%20search_path=shop`|Sets raw PostgreSQL session settings|

### `spring.datasource.username` and `password`

The database login. Never commit real passwords to Git. See the secrets section below.

### `spring.datasource.driver-class-name`

```
org.postgresql.Driver
```

This is the JDBC driver class. **It is optional**: Spring Boot looks at the URL (`jdbc:postgresql:`) and picks the right driver by itself. Write it only if you want to be explicit.

---

## Group 2: The connection pool (HikariCP)

Opening a database connection is slow, so Spring Boot keeps a **pool** of ready connections and lends them out. The default pool is **HikariCP**. These settings tune it.

|Property|Meaning|Default|
|---|---|---|
|`maximum-pool-size`|The most connections the pool will hold. Requests wait if all are busy.|10|
|`minimum-idle`|How many idle connections to keep ready.|same as maximum|
|`connection-timeout`|How long (ms) a request waits for a free connection before failing.|30000|
|`idle-timeout`|How long (ms) an idle connection may sit before being closed (only applies when `minimum-idle` is lower than the maximum).|600000 (10 min)|
|`max-lifetime`|Maximum age (ms) of a connection before it's retired and replaced. Set it a bit lower than any database or firewall timeout.|1800000 (30 min)|
|`keepalive-time`|Pings idle connections at this interval (ms) to stop firewalls from silently dropping them.|disabled|
|`leak-detection-threshold`|Logs a warning if a connection is held longer than this (ms). Great for finding code that forgets to close connections.|disabled|
|`pool-name`|A readable name in the logs.|auto|
|`auto-commit`|Whether connections start in auto-commit mode.|true|

**Picking a pool size.** More isn't better. PostgreSQL has a limit (`max_connections`, default 100 on the server), and every connection uses server memory. A small pool (10 to 20) is enough for most apps. If you run several app instances, remember the total is _instances × pool size_.

---

## Group 3: JPA and Hibernate behavior

### `spring.jpa.hibernate.ddl-auto`

This is the most important and most dangerous line. It decides what Hibernate does to your **tables** at startup.

|Value|What happens|Use for|
|---|---|---|
|`none`|Hibernate touches nothing|**Production** (default for non-embedded databases)|
|`validate`|Checks that your entities match the tables and fails if they don't|Production, with Flyway/Liquibase|
|`update`|Adds missing tables and columns. It never drops or renames anything.|Quick local development only|
|`create`|Drops and recreates all tables every start|Throwaway tests|
|`create-drop`|Like `create`, and also drops them when the app stops|Tests with embedded databases|

Never use `update`, `create`, or `create-drop` against a real production database. `update` can't handle renames or type changes safely, and `create` wipes your data.

### `spring.jpa.show-sql=true`

Prints every SQL statement to the console. It's helpful in development. For better control, use the logger instead: `logging.level.org.hibernate.SQL=DEBUG`.

### `spring.jpa.properties.hibernate.format_sql=true`

Makes the printed SQL multi-line and readable. Anything starting with `spring.jpa.properties.` is passed straight to Hibernate.

### `spring.jpa.open-in-view=false`

By default, Spring Boot keeps a database connection open for the **entire web request**, even while your controller renders JSON. That lets lazy loading work in controllers, but it holds connections longer and hides performance problems. Setting this to `false` is the common recommendation. You then load what you need inside your service layer. Boot also prints a warning at startup if you leave it at the default.

### `spring.jpa.database-platform`

```
spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect
```

The **dialect** tells Hibernate which flavor of SQL to write. Hibernate detects it automatically from your connection, so with current versions you **should not set it**.

### Other useful Hibernate properties

|Property|What it does|
|---|---|
|`spring.jpa.properties.hibernate.default_schema=shop`|Default schema for all entities|
|`spring.jpa.properties.hibernate.jdbc.batch_size=50`|Groups inserts and updates into batches|
|`spring.jpa.properties.hibernate.order_inserts=true`|Orders statements so batching works better|
|`spring.jpa.properties.hibernate.jdbc.time_zone=UTC`|Stores and reads timestamps in UTC|
|`spring.jpa.properties.hibernate.generate_statistics=true`|Prints query counts, useful for spotting N+1 problems|

**A naming note.** Spring Boot's default naming strategy turns `firstName` into `first_name` and `OrderItem` into `order_item`. That matches PostgreSQL's convention of lowercase, snake_case names, so it usually just works.

---

## Group 4: Schema setup scripts

Besides Hibernate, you can create tables with SQL files:

```properties
spring.sql.init.mode=always
spring.sql.init.schema-locations=classpath:schema.sql
spring.sql.init.data-locations=classpath:data.sql
```

- `mode=always` runs the scripts on every start. The default `embedded` only runs them for in-memory databases like H2, which means PostgreSQL ignores `schema.sql` and `data.sql` unless you set this.
- Don't mix this with `ddl-auto=update` on the same tables, or they will fight each other.

For real projects, the better option is a **migration tool**:

```properties
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
```

Flyway (or Liquibase) runs versioned scripts like `V1__create_users.sql` once each and records them. Pair it with `ddl-auto=validate`, and your schema changes become tracked, repeatable, and safe.

---

## Other ways to write the same configuration

### YAML instead of properties

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: postgres
    password: secret
    hikari:
      maximum-pool-size: 10
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
    properties:
      hibernate:
        format_sql: true
```

Same meaning, with indentation replacing the dots.

### Profiles: different settings per environment

Create `application-dev.properties` and `application-prod.properties`, then choose one:

```properties
spring.profiles.active=dev
```

Typically `dev` uses `ddl-auto=update` and `show-sql=true`, while `prod` uses `validate` and a bigger pool.

### Environment variables (best for secrets)

```properties
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
```

Or skip the file entirely. Spring Boot maps `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, and `SPRING_DATASOURCE_PASSWORD` environment variables to the same properties automatically. This is the standard approach with Docker, since you pass them with `-e` or in a Compose file.

### Java configuration (when you need full control)

This ties back to configuration classes:

```java
@Configuration
public class DbConfig {

    @Bean
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:postgresql://localhost:5432/mydb");
        config.setUsername("postgres");
        config.setPassword(System.getenv("DB_PASSWORD"));
        config.setMaximumPoolSize(10);
        return new HikariDataSource(config);
    }
}
```

Declaring your own `DataSource` bean makes Boot back off from building its own. You need this for **multiple databases**.

### Other connection pools

`spring.datasource.type=org.apache.commons.dbcp2.BasicDataSource` switches the pool (DBCP2 or Tomcat JDBC). HikariCP is the default and the usual best choice, so most projects never change it.

---

## Common errors and what they mean

|Error message|Likely cause|
|---|---|
|`Connection refused`|PostgreSQL isn't running, or the host/port is wrong|
|`password authentication failed for user`|Wrong username or password|
|`database "mydb" does not exist`|Create it first (`CREATE DATABASE mydb;`)|
|`Failed to determine a suitable driver class`|The `url` property is missing or misspelled|
|`Connection is not available, request timed out after 30000ms`|Pool exhausted. Connections aren't being returned, or the pool is too small|
|`relation "users" does not exist`|The table wasn't created (check `ddl-auto` or your migrations), or it's in a different schema|
|`too many connections for role`|Pool size × instances exceeds the server limit|

---

## Short summary of a related concept: `postgresql.conf`

Everything above lives on the **application** side. PostgreSQL itself has its own server configuration file, `postgresql.conf`, with settings like `port`, `max_connections`, `shared_buffers` (memory for caching), and `listen_addresses`. A companion file, `pg_hba.conf`, controls **who may connect from where** and with what authentication method. If your app gets "no pg_hba.conf entry for host" errors, the fix is in that server file, not in Spring Boot.

---

## Takeaways

- Four groups: **connection** (`url`, `username`, `password`), **pool** (`hikari.*`), **Hibernate/JPA** (`spring.jpa.*`), and **schema setup** (`sql.init` or Flyway/Liquibase).
- The URL has the shape `jdbc:postgresql://host:port/database?options`.
- `driver-class-name` and the dialect are detected automatically, so you can leave them out.
- `ddl-auto` is the risky one: `update` for local experiments, `validate` plus Flyway for production.
- Keep pool sizes modest, and set `open-in-view=false`.
- Put passwords in environment variables, and use profiles to separate dev from prod.
- For several databases or special setups, declare your own `DataSource` bean.





[[PostgreSQL]]
[[Spring Framework]]