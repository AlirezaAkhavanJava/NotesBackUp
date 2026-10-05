

This covers Spring Boot 4.x (Hibernate 7) with PostgreSQL on Debian. Property names are the ones you'd put in `application.properties`.

## 1. The scenario

1. You create a Spring Boot 4 project with `spring-boot-starter-data-jpa` and the PostgreSQL driver, and start it. It fails with `Failed to configure a DataSource: 'url' attribute is not specified`.
2. You add the datasource URL, username and password. The app boots, but the first query fails with `relation "users" does not exist`.
3. You set `ddl-auto=update` and the tables appear.
4. You want to see the SQL, so you add `show-sql=true`. The output shows `where id=?`, with no actual values.
5. The console prints a warning: `spring.jpa.open-in-view is enabled by default`. You ignore it.
6. A teammate copies your dev config to staging, which has `ddl-auto=create`. On restart the staging data is gone.
7. Under load you see `HikariPool-1 - Connection is not available, request timed out after 30000ms`.
8. Loading 100 orders produces 101 SELECT statements.

Every one of these is a configuration problem, and each belongs to a different layer.

## 2. The core mental model

> **There are three layers, each with its own settings. The connection pool decides how you reach the database, Hibernate decides how objects become SQL and when it runs, and Spring Boot's `spring.jpa.*` properties are the glue that feeds both.**

```
Your code
   |
Spring Data repository         (Spring Data JPA: findBy..., save())
   |
JPA EntityManager              (the SPEC: jakarta.persistence API)
   |
Hibernate                      (the IMPLEMENTATION: generates SQL)
   |
JDBC + HikariCP pool           (reusable connections)
   |
PostgreSQL

Config prefix at each level:
  spring.jpa.*                         -> Spring Boot / JPA behaviour
  spring.jpa.properties.hibernate.*    -> passed straight to Hibernate
  spring.datasource.*                  -> DB connection
  spring.datasource.hikari.*           -> connection pool
```

JPA is a specification (a set of interfaces and annotations). Hibernate is the library that implements it. Spring Data JPA sits on top and writes repository code for you. `spring.jpa.properties.hibernate.*` is a pass-through: Spring Boot strips the `spring.jpa.properties.` prefix and hands the rest to Hibernate untouched, so any Hibernate setting can be reached that way.

## 3. Step-by-step walkthrough

### Step 1: the datasource (how to reach the DB)

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/appdb
spring.datasource.username=app
spring.datasource.password=${DB_PASSWORD}
```

- You don't need `driver-class-name`. Spring Boot infers it from the `jdbc:postgresql:` prefix.
- Read secrets from environment variables (`${DB_PASSWORD}`), not from a file you commit to Git.

### Step 2: the connection pool (HikariCP)

Opening a database connection costs a TCP handshake, authentication, and a server-side process. So a pool keeps connections open and lends them out.

```properties
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.max-lifetime=1800000
```

```
Request 1 --\                         +---------+
Request 2 ---+--> [ Hikari pool: 10 ]-> | Postgres |
...         |    (waiting if all busy)+---------+
Request 11 -/   <- waits up to connection-timeout, then fails
```

|Property|Meaning|
|---|---|
|`maximum-pool-size`|Hard cap on open connections (default 10)|
|`connection-timeout`|How long a request waits for a free connection before failing|
|`max-lifetime`|Retire connections after this long (keep it below any DB or firewall timeout)|

More connections do not mean more speed. A database has limited CPU and disk, so beyond a small number, extra connections just queue inside Postgres instead of inside your app.

### Step 3: `ddl-auto` (who owns the schema)

```properties
spring.jpa.hibernate.ddl-auto=validate
```

|Value|What Hibernate does at startup|Use for|
|---|---|---|
|`none`|Nothing|Production with migrations|
|`validate`|Checks that entities match tables, fails if not|Production with migrations|
|`update`|Adds missing tables and columns, never removes or alters|Throwaway prototypes only|
|`create`|Drops and recreates all tables|Local tests|
|`create-drop`|Like `create`, plus drops at shutdown|In-memory test DBs|

If you don't set it, Spring Boot defaults to `create-drop` for an embedded DB (like H2) and `none` for everything else. `spring.jpa.generate-ddl` is a generic on/off switch from the JPA side. `ddl-auto` is the Hibernate-specific one, and it wins if both are set.

`update` is dangerous because it only ever adds. It can't rename a column, change a type, or drop anything, and it leaves no history of what changed. Production schemas should come from migration files (section 7).

### Step 4: seeing the SQL

```properties
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.orm.jdbc.bind=TRACE
spring.jpa.properties.hibernate.format_sql=true
```

```
spring.jpa.show-sql=true            -> prints to System.out, no bound values
logging.level.org.hibernate.SQL     -> goes through your logger, respects levels
...orm.jdbc.bind=TRACE              -> shows the actual parameter values
```

Prefer the logger approach. `show-sql` bypasses your logging setup and never shows parameter values. Remember to turn this off in production, because it is noisy and may log personal data.

### Step 5: open-in-view

```properties
spring.jpa.open-in-view=false
```

By default, Spring keeps the Hibernate session (and a DB connection) open for the **entire web request**, including JSON serialization.

```
open-in-view=true                    open-in-view=false
-----------------                    ------------------
connection borrowed at request       connection borrowed only inside
start, held until response sent      @Transactional methods
lazy loading works anywhere          lazy loading outside a transaction
                                     throws LazyInitializationException
```

The default is convenient, but it holds a connection while your code does slow things like calling other services, and it hides N+1 queries. Set it to `false`, and fetch what you need explicitly.

### Step 6: performance properties

```properties
spring.jpa.properties.hibernate.jdbc.batch_size=50
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true
spring.jpa.properties.hibernate.default_batch_fetch_size=32
spring.jpa.properties.hibernate.jdbc.time_zone=UTC
```

|Property|What it does|
|---|---|
|`jdbc.batch_size`|Sends up to N INSERT/UPDATE statements in one round trip (needs `SEQUENCE` ids, see the earlier lesson)|
|`order_inserts` / `order_updates`|Groups statements for the same table so batches aren't broken up by interleaving|
|`default_batch_fetch_size`|Loads lazy associations for many parents at once, using `WHERE id IN (...)`|
|`jdbc.time_zone`|Stores timestamps in UTC regardless of server timezone|

`default_batch_fetch_size` turns 101 queries into about 5. It reduces N+1 but does not eliminate it. Real fixes are fetch joins, `@EntityGraph`, or DTO projections.

### Step 7: naming and dialect

```properties
spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
```

- The default (Spring Boot's `CamelCaseToUnderscoresNamingStrategy`) converts `lastName` to `last_name`. Set the strategy above only if you want names used exactly as written.
- **Don't set `hibernate.dialect` or `spring.jpa.database-platform`.** Hibernate 6+ detects the dialect from JDBC metadata. Setting it manually is only for unusual cases, such as pinning behaviour for an older server version.

## 4. The conflict: where config can't decide for you

You set `open-in-view=false` to fix the connection hold. Then a controller does this:

```java
@GetMapping("/orders/{id}")
public OrderDto get(@PathVariable Long id) {
    Order o = orderService.find(id);          // transaction ended here
    return new OrderDto(o.getId(), o.getItems().size());   // lazy collection
}
```

```
org.hibernate.LazyInitializationException:
  could not initialize proxy [Order#items] - no Session
```

The `items` collection is a lazy placeholder. The session that could fill it has closed, and Hibernate can't know whether you wanted the data loaded or want to fail. So it fails.

## 5. Resolution

Load exactly what you need, inside the transaction:

```java
public interface OrderRepository extends JpaRepository<Order, Long> {

    @EntityGraph(attributePaths = "items")
    Optional<Order> findWithItemsById(Long id);
}
```

or return a DTO from the service layer, so entities never leave it:

```java
@Transactional(readOnly = true)
public OrderDto find(Long id) {
    Order o = repo.findWithItemsById(id).orElseThrow();
    return new OrderDto(o.getId(), o.getItems().size());
}
```

```
BEFORE: controller touches lazy field -> no session -> exception
AFTER:  service loads + maps inside transaction -> controller gets a plain DTO
```

## 6. Advanced example: a real multi-environment setup

**Situation:** local dev, plus production running 3 instances against one PostgreSQL server with `max_connections=100`.

`application.properties` (shared by all environments):

```properties
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
spring.jpa.properties.hibernate.jdbc.batch_size=50
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true
spring.jpa.properties.hibernate.jdbc.time_zone=UTC
spring.datasource.hikari.maximum-pool-size=10
```

`application-dev.properties` (loaded with `spring.profiles.active=dev`):

```properties
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.orm.jdbc.bind=TRACE
spring.jpa.properties.hibernate.format_sql=true
```

Schema management through Flyway (put SQL files in `src/main/resources/db/migration/`, such as `V1__create_users.sql`). In Boot 4 the Flyway auto-configuration lives in `spring-boot-starter-flyway`, and PostgreSQL also needs `flyway-database-postgresql`. If migrations don't run, check the Boot 4 migration notes for the current starter name.

### Why this works

- **Flyway runs first, then Hibernate validates.** Flyway creates or alters tables from versioned SQL. Then `validate` confirms the entities still match. If a developer renames a field and forgets the migration, startup fails immediately instead of failing at runtime.
- **The pool maths is checked against the database.** 3 instances x 10 connections = 30, which leaves room under Postgres's 100 for admin tools and migrations.
- **Dev logging lives only in the dev profile.** Production never prints SQL or parameters.
- **Batching works** because IDs come from a sequence (earlier lesson), not `IDENTITY`.

### What could go wrong

- **Autoscaling to 20 instances.** 20 x 10 = 200 connections against a limit of 100, and Postgres answers `FATAL: sorry, too many clients already`. Fix: lower the pool per instance, or put PgBouncer in front of Postgres.
- **`validate` fails on a type mismatch.** A migration says `text` while the entity maps `String` as `varchar(255)`, and `validate` complains. Fix the entity with `@Column(columnDefinition = "text")` or `@Lob`-style mapping, or change the migration so both sides agree.
- **`batch_size` without `order_inserts`.** Inserts into `orders` and `order_items` interleave, which breaks each batch into tiny ones and removes most of the benefit.
- **`max-lifetime` longer than a firewall idle timeout.** The firewall silently drops idle connections, and the pool hands your app a dead one.

### What-if variations

**What if you want YAML instead?** The same keys work in `application.yml`:

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
    properties:
      hibernate:
        jdbc:
          batch_size: 50
```

**What if you need two databases?** The auto-configuration only covers one. You'd define your own `DataSource` and `LocalContainerEntityManagerFactoryBean` beans, which is "Java config" instead of properties.

**What if tests need a real database?** Use Testcontainers with PostgreSQL rather than H2. H2 differs from Postgres in SQL dialect and behaviour, so tests can pass on H2 and fail in production.

## 7. Contrastive comparison: your other options

### Schema management

||Hibernate `ddl-auto`|Flyway / Liquibase|
|---|---|---|
|Source of truth|Your entity classes|Versioned SQL/XML files|
|History / rollback|None|Full history, repeatable|
|Safe for production|No (`update`, `create`)|Yes|
|Best for|Prototypes, tests|Everything real|

### Configuration style

||`.properties`|`.yml`|Java `@Configuration` beans|
|---|---|---|---|
|Readability|Flat, simple|Nested, easier for large configs|Verbose|
|Flexibility|Fixed keys|Fixed keys|Anything, including multiple DBs|
|Best for|Small projects|Larger projects|Non-standard setups|

### Persistence technology

```
JPA + Hibernate    -> maps objects to tables, tracks changes, lazy loading
Spring Data JDBC   -> simpler: no lazy loading, no persistence context
JdbcTemplate       -> you write SQL, Spring runs it
jOOQ               -> type-safe SQL builder generated from your schema
MyBatis            -> SQL in XML/annotations mapped to objects
```

JPA gives the most automation and the most surprises (lazy loading, dirty checking, session scope). Spring Data JDBC and `JdbcTemplate` give more predictable behaviour at the cost of writing more yourself. Hibernate is the default JPA provider in Spring Boot. EclipseLink exists as an alternative, but it needs manual setup and is rare.

## 8. Key mental model recap

- Three layers: connection pool, Hibernate, Spring Boot glue. Each has its own property prefix.
- `spring.jpa.properties.hibernate.*` is a pass-through, so any Hibernate setting is reachable.
- `ddl-auto`: `validate` or `none` in production, with Flyway or Liquibase owning the schema.
- Turn off `open-in-view`, then load what you need inside transactions (`@EntityGraph`, fetch join, DTO).
- Show SQL through the logger, not `show-sql`, and only in dev.
- `batch_size` + `order_inserts` + `SEQUENCE` ids is what makes bulk writes fast.
- Pool size x instance count must stay under the database's `max_connections`.
- Don't set the dialect. Let Hibernate detect it.

```
        app starts
            |
            v
   spring.datasource.*  --> HikariCP pool created
            |
            v
   Flyway runs migrations (schema owned by SQL files)
            |
            v
   Hibernate starts: ddl-auto=validate checks entities vs tables
            |
            v
   request arrives (open-in-view=false)
            |
            v
   @Transactional service: borrow connection, load data
   (EntityGraph / DTO), return connection
            |
            v
   controller returns DTO, no lazy loading outside the transaction
```

**Takeaway:** _Let migrations own the schema, let `validate` guard it, keep sessions short with `open-in-view=false`, and size your connection pool against the database's real limit._




[[Spring Framework]]