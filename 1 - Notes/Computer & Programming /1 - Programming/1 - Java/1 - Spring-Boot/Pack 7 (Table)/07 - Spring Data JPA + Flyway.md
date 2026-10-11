

## Core intuition

Your app has two things that must agree: **Java objects** (entities) and **database tables**. They can drift apart. Two tools handle the two sides:

- **Spring Data JPA** is the _translator at runtime_. You write `userRepository.findByEmail("a@b.com")` and it generates the SQL, runs it, and maps rows to objects.
- **Flyway** is the _version control for your database schema_. Instead of someone manually running `ALTER TABLE` on each server, you write numbered SQL files and Flyway applies each one exactly once, in order, and records it.

Without Flyway, the usual way to get tables is `spring.jpa.hibernate.ddl-auto=update`, which lets Hibernate guess schema changes. That's fine for a toy, but dangerous in real life because it never drops or renames safely, can't do data migrations, and gives you no history.

**Mental model:** Flyway builds and evolves the schema. JPA only _uses_ the schema. They never overlap in responsibility.

## The sequence at startup

1. Spring Boot starts and sees Flyway on the classpath.
2. Flyway connects to the DB and checks its table `flyway_schema_history`.
3. It finds migration files in `src/main/resources/db/migration` that aren't recorded yet.
4. It runs them in version order and records each one with a checksum.
5. Only after that does Hibernate/JPA initialize, and it validates the entities against the schema.

Spring Boot guarantees that Flyway runs before the `EntityManagerFactory` is created.

## Setup (Maven, PostgreSQL)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-database-postgresql</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

The `flyway-database-postgresql` module is required in Flyway 10+ (which current Spring Boot uses). Without it you get "Unsupported Database" errors.

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/appdb
    username: app
    password: secret
  jpa:
    hibernate:
      ddl-auto: validate   # Hibernate checks, never changes
    open-in-view: false
  flyway:
    enabled: true
    locations: classpath:db/migration
```

`validate` is the key setting: if an entity has a field with no matching column, the app refuses to start. That's your safety net against mismatches.

## Migration files

Location: `src/main/resources/db/migration`

Naming: `V<version>__<description>.sql` (two underscores).

```sql
-- V1__create_users_table.sql
CREATE TABLE users (
    id         BIGSERIAL PRIMARY KEY,
    email      VARCHAR(255) NOT NULL UNIQUE,
    full_name  VARCHAR(100) NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT now()
);
```

```sql
-- V2__add_active_flag_to_users.sql
ALTER TABLE users ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;
```

## Entity and repository

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // matches BIGSERIAL
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private LocalDateTime createdAt;

    private boolean active = true;

    // getters/setters
}
```

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    List<User> findByActiveTrueOrderByCreatedAtDesc();
}
```

You write only the interface. Spring generates the implementation, and the method names are parsed into queries.

## Workflow when the schema changes

1. Add the field to the entity (`private String phone;`).
2. Create `V3__add_phone_to_users.sql` with `ALTER TABLE users ADD COLUMN phone VARCHAR(30);`
3. Run the app. Flyway applies V3, then Hibernate validates successfully.

If you forget step 2, `validate` fails at startup with "missing column [phone]". That's the intended safety net.

## Gotchas and edge cases

**Never edit a migration that has already run.** Flyway stores a checksum of each file. If you change V1 afterward, startup fails with a checksum mismatch. The fix is always a _new_ migration (V4) that corrects things. Editing is only OK on your own local DB before anyone else has run it, and even then you'd have to wipe the DB or use `flyway repair`.

**Version ordering is numeric, not alphabetical.** `V10` comes after `V9`. Versions can be `V1_1` or `V2.3`.

**Two developers, same version number.** On two branches, both create `V5__...`. Merging gives a conflict at startup. Teams handle this with timestamp versions (`V20261005_1430__...`) or by renumbering before merge. Flyway also has `outOfOrder`, but it's a last resort.

**Repeatable migrations** use `R__name.sql`. They have no version, rerun whenever their checksum changes, and run after versioned ones. They're good for views, functions and procedures.

**Existing database with tables already.** Flyway will refuse a non-empty schema with no history table. Use `spring.flyway.baseline-on-migrate=true` plus `baseline-version` so Flyway treats the current state as the starting point.

**Transactions and DDL.** PostgreSQL supports transactional DDL, so a failed migration rolls back cleanly. MySQL does _not_ (DDL auto-commits), so a failure halfway leaves a half-applied migration and a failed entry you must repair manually. This matters a lot when choosing a DB.

**Don't mix tools.** Never let Hibernate generate the schema (`update`/`create`) alongside Flyway. Use `validate` or `none` in production. `create-drop` is only acceptable with an in-memory test DB.

**Type mismatches that `validate` catches (or doesn't).** `validate` checks that columns exist and types are _compatible_, but it won't catch everything, for example nullability, defaults and constraints. Those you verify yourself.

**Seeding data.** Reference data (roles, countries) can go into migrations. Test data should not go in `db/migration`. Use a separate location like `db/dev-data`, enabled only in a dev profile.

**Testing.** Use Testcontainers with a real PostgreSQL so your migrations actually run in tests, instead of H2, which behaves differently and can hide SQL dialect errors.

## How the pieces connect to related concepts

- `ddl-auto` is Hibernate's own schema tool, and Flyway replaces it.
- Liquibase is the main alternative to Flyway (XML/YAML changelogs instead of plain SQL).
- Spring Data JPA sits on top of JPA (the specification), which Hibernate implements. Flyway is independent of all three and works with plain JDBC too.





[[Spring Framework]]