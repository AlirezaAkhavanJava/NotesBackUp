

# Spring Boot + Spring Data JPA + PostgreSQL: `application.properties` guide

## 1. Mental model

`application.properties` is a **settings panel for auto-configuration**. When Spring Boot starts, it sees `spring-boot-starter-data-jpa` and the PostgreSQL driver on the classpath. It then builds a chain of objects for you, and each property you write tweaks one link:

```
Your code → Repository (Spring Data JPA) → JPA/Hibernate → JDBC → HikariCP (pool) → PostgreSQL driver → PostgreSQL
              spring.data.*              spring.jpa.*              spring.datasource.hikari.*   spring.datasource.url
```

Boot's philosophy is **convention over configuration**: every property has a sensible default, and you only write the ones you want to change. The properties below are grouped by layer, from the database up to the web server.

Dependencies (Maven):

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <scope>runtime</scope>
</dependency>
```

Setting up PostgreSQL on Debian 13 (it ships PostgreSQL 17):

```bash
sudo apt install postgresql
sudo -u postgres psql
```

```sql
CREATE USER app_user WITH PASSWORD 'secret';
CREATE DATABASE mydb OWNER app_user;
```

---

## 2. DataSource: connecting to PostgreSQL

**`spring.datasource.url`**

- **What:** The JDBC URL, in the form `jdbc:postgresql://host:port/database`.
- **Example:** `spring.datasource.url=jdbc:postgresql://localhost:5432/mydb`
- **Why:** It tells the driver where the database is. Without it, Boot tries an embedded DB (H2) if one is on the classpath, otherwise it fails to start.
- **Useful URL parameters:**
    - `?currentSchema=myschema` sets the default schema.
    - `&reWriteBatchedInserts=true` makes batch inserts much faster on PostgreSQL.
    - `&ApplicationName=my-app` makes your app visible in `pg_stat_activity`.
    - `&sslmode=require` enforces encryption (needed for most cloud databases).
    - `&connectTimeout=10` is in seconds.

**`spring.datasource.username`** and **`spring.datasource.password`**

- **What:** The database credentials.
- **Example:**
    
    ```properties
    spring.datasource.username=app_userspring.datasource.password=${DB_PASSWORD}
    ```
    
- **Why:** Never hardcode real passwords. The `${DB_PASSWORD}` syntax reads an environment variable, and you can give a fallback with `${DB_PASSWORD:secret}`.

**`spring.datasource.driver-class-name`**

- **What:** The JDBC driver class.
- **Example:** `spring.datasource.driver-class-name=org.postgresql.Driver`
- **Why:** It is **optional**, because Boot detects it from the URL. Set it only if detection fails.

**`spring.datasource.type`**

- **What:** Forces a specific connection pool implementation.
- **Example:** `spring.datasource.type=com.zaxxer.hikari.HikariDataSource`
- **Why:** Hikari is already the default, so you rarely need this.

---

## 3. HikariCP: the connection pool

**Analogy:** Opening a DB connection is like hiring a taxi driver for each trip, which is slow. A pool is a taxi fleet kept waiting at the station, so your code borrows a connection, uses it, and returns it.

**`spring.datasource.hikari.maximum-pool-size`**

- **What:** The maximum number of connections in the pool. The default is 10.
- **Example:** `spring.datasource.hikari.maximum-pool-size=10`
- **Why:** Too small and requests queue up. Too big and PostgreSQL gets overwhelmed, because each connection is a separate server process using memory. Bigger is not faster. A common starting formula is `(CPU cores × 2) + 1` for the DB server. PostgreSQL's default `max_connections` is 100, shared by all clients.

**`spring.datasource.hikari.minimum-idle`**

- **What:** The minimum number of idle connections to keep ready.
- **Example:** `spring.datasource.hikari.minimum-idle=5`
- **Why:** It keeps warm connections available for sudden traffic. Hikari's own advice is to leave it unset so the pool stays fixed-size. Setting it equal to the max gives a fixed pool, which is the best for performance.

**`spring.datasource.hikari.connection-timeout`**

- **What:** How long (ms) a thread waits for a free connection before throwing an exception. The default is 30000.
- **Example:** `spring.datasource.hikari.connection-timeout=20000`
- **Why:** It fails fast instead of hanging users forever when the pool is exhausted.

**`spring.datasource.hikari.idle-timeout`**

- **What:** How long (ms) an idle connection may sit before being closed. The default is 600000 (10 minutes), and it only applies when `minimum-idle` is less than the max.
- **Example:** `spring.datasource.hikari.idle-timeout=300000`
- **Why:** It frees DB resources when traffic is low.

**`spring.datasource.hikari.max-lifetime`**

- **What:** The maximum age (ms) of any connection, after which it is retired and replaced. The default is 1800000 (30 minutes).
- **Example:** `spring.datasource.hikari.max-lifetime=1700000`
- **Why:** Firewalls, load balancers and DB servers silently kill long-lived connections. Set it a few seconds shorter than any such limit so Hikari retires connections _before_ they die.

**`spring.datasource.hikari.keepalive-time`**

- **What:** How often (ms) idle connections are pinged to keep them alive.
- **Example:** `spring.datasource.hikari.keepalive-time=300000`
- **Why:** It prevents idle connections from being dropped by network equipment.

**`spring.datasource.hikari.leak-detection-threshold`**

- **What:** If a connection is held longer than this (ms), Hikari logs a warning with a stack trace. The default is 0 (disabled).
- **Example:** `spring.datasource.hikari.leak-detection-threshold=60000`
- **Why:** It finds code that borrows a connection and never returns it, which eventually exhausts the pool.

**`spring.datasource.hikari.pool-name`**

- **What:** A name for the pool.
- **Example:** `spring.datasource.hikari.pool-name=MyAppPool`
- **Why:** It makes logs and metrics readable.

**`spring.datasource.hikari.auto-commit`**

- **What:** Whether connections start in auto-commit mode. The default is true.
- **Example:** `spring.datasource.hikari.auto-commit=false`
- **Why:** With Spring's `@Transactional`, Spring manages commits itself. Setting it to `false` can avoid an extra round trip when a transaction starts.

---

## 4. JPA and Hibernate

**Analogy:** JPA is the _specification_ (the rules of a language), and Hibernate is the _implementation_ (the translator that does the work). Boot uses Hibernate by default.

**`spring.jpa.hibernate.ddl-auto`**

- **What:** What Hibernate does with your database schema at startup.
- **Values:**

|Value|Behaviour|Use|
|---|---|---|
|`none`|Does nothing|Production|
|`validate`|Checks that entities match the tables, and fails if not|Production|
|`update`|Adds missing tables and columns, never drops|Quick prototyping only|
|`create`|Drops and recreates the schema on every start|Throwaway dev|
|`create-drop`|Like `create`, and drops the schema on shutdown|Tests|

- **Example:** `spring.jpa.hibernate.ddl-auto=validate`
- **Why:** `update` is risky because it never renames, never removes, and cannot handle data migrations. For real projects, use `validate` plus a migration tool such as Flyway (section 7). The default is `none` for real databases, but `create-drop` for embedded ones like H2.

**`spring.jpa.show-sql`**

- **What:** Prints every SQL statement to the console.
- **Example:** `spring.jpa.show-sql=true`
- **Why:** It is great for learning what your repositories do. It uses `System.out`, though, and shows no parameter values. For serious debugging, use the logging approach in section 8 instead.

**`spring.jpa.properties.hibernate.format_sql`**

- **What:** Pretty-prints the SQL across multiple lines.
- **Example:** `spring.jpa.properties.hibernate.format_sql=true`
- **Why:** It makes long queries readable.

**`spring.jpa.properties.hibernate.use_sql_comments`**

- **What:** Adds a comment above each SQL statement showing the originating JPQL/HQL.
- **Example:** `spring.jpa.properties.hibernate.use_sql_comments=true`
- **Why:** It helps you trace which Java query produced which SQL.

**`spring.jpa.properties.hibernate.dialect`** (and `spring.jpa.database-platform`)

- **What:** Tells Hibernate which SQL "accent" to speak.
- **Example:** `spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect`
- **Why:** On Hibernate 6 (Spring Boot 3+) it is **auto-detected** from the connection, so you can usually omit it. Older tutorials always set it, so you will see it a lot.

**`spring.jpa.properties.hibernate.default_schema`**

- **What:** The default schema for all entity tables.
- **Example:** `spring.jpa.properties.hibernate.default_schema=app`
- **Why:** It keeps your tables out of `public` without annotating every entity.

**`spring.jpa.open-in-view`**

- **What:** Keeps the JPA session (and a DB connection) open for the _entire web request_, including view rendering. The default is `true`, and Boot logs a warning about it.
- **Example:** `spring.jpa.open-in-view=false`
- **Why:** When `true`, lazy loading "magically works" in controllers, but each request holds a connection longer, and you can hide N+1 query problems. Most experienced developers set it to `false` and fetch what they need inside the service layer. The catch is that lazy access outside a transaction then throws `LazyInitializationException`. That exception is the correct signal that you need a `JOIN FETCH` or DTO projection.

**`spring.jpa.properties.hibernate.jdbc.batch_size`**

- **What:** The number of inserts/updates grouped into one round trip.
- **Example:**
    
    ```properties
    spring.jpa.properties.hibernate.jdbc.batch_size=50spring.jpa.properties.hibernate.order_inserts=truespring.jpa.properties.hibernate.order_updates=true
    ```
    
- **Why:** Saving 1000 rows becomes about 20 round trips instead of 1000. `order_inserts` and `order_updates` group statements by table so batching actually kicks in.
- **Gotcha:** Batching does **not** work with `@GeneratedValue(strategy = IDENTITY)`, because Hibernate must execute each insert immediately to get the ID. Use `SEQUENCE` for bulk operations. This matters on PostgreSQL, where sequences are native and fast.

**`spring.jpa.properties.hibernate.jdbc.time_zone`**

- **What:** The time zone Hibernate uses when reading and writing timestamps.
- **Example:** `spring.jpa.properties.hibernate.jdbc.time_zone=UTC`
- **Why:** It avoids bugs where a timestamp changes when the app and DB run in different zones. Storing UTC is the safe convention.

**`spring.jpa.properties.hibernate.generate_statistics`**

- **What:** Collects query counts, cache hits and timings.
- **Example:** `spring.jpa.properties.hibernate.generate_statistics=true`
- **Why:** It is a diagnostic tool for finding N+1 problems. Leave it off in production, because it has overhead.

**`spring.jpa.hibernate.naming.physical-strategy`** and **`implicit-strategy`**

- **What:** Control how Java names map to column and table names.
- **Example:** `spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl`
- **Why:** By default Boot converts `firstName` to `first_name`. This setting turns that conversion off, so names map exactly as written.

**`spring.jpa.defer-datasource-initialization`**

- **What:** Runs `data.sql` _after_ Hibernate creates the schema.
- **Example:** `spring.jpa.defer-datasource-initialization=true`
- **Why:** If you use `ddl-auto=create` together with `data.sql` seed data, the default order runs the script before the tables exist.

**`spring.jpa.generate-ddl`**

- **What:** A generic on/off switch for schema generation.
- **Why:** Prefer `hibernate.ddl-auto`, which is more precise.

---

## 5. Spring Data JPA

**`spring.data.jpa.repositories.enabled`**

- **What:** Turns Spring Data repository scanning on or off. The default is `true`.
- **Example:** `spring.data.jpa.repositories.enabled=true`
- **Why:** You can disable it in special test setups.

**`spring.data.jpa.repositories.bootstrap-mode`**

- **What:** When repositories are initialized. The values are `default`, `deferred` and `lazy`.
- **Example:** `spring.data.jpa.repositories.bootstrap-mode=deferred`
- **Why:** It speeds up application startup in large projects, because JPA initialization happens in the background.

**`spring.data.web.pageable.default-page-size`**

- **What:** The default page size when a controller accepts `Pageable` and the client doesn't send one. The default is 20.
- **Example:** `spring.data.web.pageable.default-page-size=10`
- **Why:** It controls pagination behaviour for `?page=0&size=...` requests.

**`spring.data.web.pageable.max-page-size`**

- **What:** The upper limit on the page size a client may request. The default is 2000.
- **Example:** `spring.data.web.pageable.max-page-size=100`
- **Why:** It stops a client from requesting `?size=1000000` and overloading your server.

**`spring.data.web.pageable.one-indexed-parameters`**

- **What:** Makes page numbers start at 1 instead of 0.
- **Example:** `spring.data.web.pageable.one-indexed-parameters=true`
- **Why:** It is friendlier for front ends like Angular paginators, though it's easy to forget and cause off-by-one confusion.

**`spring.transaction.default-timeout`**

- **What:** The default timeout for transactions.
- **Example:** `spring.transaction.default-timeout=30s`
- **Why:** It prevents runaway transactions from holding locks forever.

---

## 6. General Spring Boot and web server

**`spring.application.name`**: names your app, used in logs and monitoring. Example: `spring.application.name=my-app`.

**`server.port`**

- **What:** The HTTP port. The default is 8080. Use `0` for a random port, handy in tests.
- **Example:** `server.port=8081`

**`server.servlet.context-path`**

- **What:** A URL prefix for the entire app.
- **Example:** `server.servlet.context-path=/api` makes `/users` become `/api/users`.

**`server.shutdown=graceful`** with **`spring.lifecycle.timeout-per-shutdown-phase=30s`**

- **What:** On shutdown, in-flight requests get time to finish.
- **Why:** It avoids cutting users off mid-request during deployments.

**`server.error.include-message`** and **`server.error.include-stacktrace`**

- **Example:** `server.error.include-message=always` and `server.error.include-stacktrace=never`
- **Why:** Error responses hide messages and stack traces by default, because leaking internals is a security risk. Opening them up is fine in dev, not in production.

**`server.compression.enabled=true`**: compresses responses to save bandwidth.

**`spring.profiles.active`**

- **What:** Activates environment-specific config.
- **Example:** `spring.profiles.active=dev` loads `application-dev.properties` _on top of_ the base file.
- **Why:** You keep one file for shared settings, and per-environment files for differences such as DB URLs.

**`spring.jackson.*`**

- **Example:**
    
    ```properties
    spring.jackson.default-property-inclusion=non_nullspring.jackson.time-zone=UTC
    ```
    
- **Why:** It controls JSON output. `non_null` omits null fields from responses.

**`spring.servlet.multipart.max-file-size=10MB`** and **`max-request-size=10MB`**: limits for file uploads. The defaults are small (1MB), so uploads fail without them.

**`spring.config.import`**

- **Example:** `spring.config.import=optional:file:.env[.properties]`
- **Why:** It imports extra config files, such as a local file of secrets that isn't committed to Git.

---

## 7. Database migrations (Flyway)

Add `org.flywaydb:flyway-core` and `flyway-database-postgresql` as dependencies.

**`spring.flyway.enabled`**: default `true` when Flyway is on the classpath.

**`spring.flyway.locations`**

- **Example:** `spring.flyway.locations=classpath:db/migration`
- **Why:** It sets where your versioned SQL scripts live, e.g. `V1__create_users.sql`.

**`spring.flyway.baseline-on-migrate=true`**

- **Why:** It lets Flyway adopt an existing non-empty database. It is only needed when introducing Flyway to a database that already has tables.

**Why use Flyway at all:** Schema changes become versioned, reviewable files in Git, so every environment applies the same changes in the same order. `ddl-auto` can't give you that.

---

## 8. Logging SQL properly

```properties
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.orm.jdbc.bind=TRACE
```

- The first line logs the SQL through your logging framework (better than `show-sql`).
- The second line logs the **bound parameter values** (`?` replaced by real values) on Hibernate 6. On Hibernate 5 the logger was `org.hibernate.type.descriptor.sql.BasicBinder`.

Other useful ones:

```properties
logging.level.root=INFO
logging.level.com.zaxxer.hikari=DEBUG   # pool activity
logging.file.name=logs/app.log
```

---

## 9. Actuator (health and metrics)

Add `spring-boot-starter-actuator`.

```properties
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=when-authorized
```

- **Why:** `/actuator/health` includes a DB connectivity check, and the Hikari metrics (active connections, pending threads) show whether your pool is sized well.
- **Security:** Only expose what you need. `*` exposes everything, including sensitive endpoints.

---

## 10. Complete example files

**`application.properties`** (shared base):

```properties
spring.application.name=my-app
spring.profiles.active=dev
server.port=8080
server.shutdown=graceful

spring.datasource.url=jdbc:postgresql://localhost:5432/mydb?reWriteBatchedInserts=true
spring.datasource.username=${DB_USER:app_user}
spring.datasource.password=${DB_PASSWORD}

spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=20000
spring.datasource.hikari.max-lifetime=1700000

spring.jpa.open-in-view=false
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.jdbc.time_zone=UTC
spring.jpa.properties.hibernate.jdbc.batch_size=50
spring.jpa.properties.hibernate.order_inserts=true

spring.data.web.pageable.max-page-size=100
spring.flyway.enabled=true
```

**`application-dev.properties`** (overrides for development):

```properties
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=true
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.orm.jdbc.bind=TRACE
server.error.include-message=always
```

**`application-prod.properties`**:

```properties
spring.jpa.hibernate.ddl-auto=none
spring.datasource.url=jdbc:postgresql://db-host:5432/mydb?sslmode=require
spring.datasource.hikari.leak-detection-threshold=60000
server.error.include-stacktrace=never
management.endpoints.web.exposure.include=health
```

---

## 11. Gotchas and things to remember

1. **Precedence:** environment variables override `application.properties`. `SPRING_DATASOURCE_URL` overrides `spring.datasource.url` (this is "relaxed binding"). That's why the same JAR works in Docker and the cloud without edits.
2. **`spring.jpa.properties.*` is a passthrough:** anything after it goes straight to Hibernate. That is why Hibernate settings look like `spring.jpa.properties.hibernate.xyz`, while Boot's own wrappers look like `spring.jpa.hibernate.ddl-auto`.
3. **Never commit secrets.** Use environment variables, profile files that are git-ignored, or a secrets manager.
4. **Pool size × number of app instances ≤ PostgreSQL `max_connections`.** Running 5 instances with a pool of 20 means 100 connections, which is already the PostgreSQL default limit.
5. **Property names evolve between versions.** This guide targets Spring Boot 3.x and later (Hibernate 6). For your exact version, the official "Common Application Properties" appendix in the Spring Boot docs is the authoritative full list, and your IDE autocompletes it as you type in the properties file.





[[Spring Framework]]