


## The mental model

Spring Boot works like a smart hotel manager. When it sees certain things in your classpath, it assumes you want them and starts setting them up for you. This is called **auto-configuration**.

When you add `spring-boot-starter-data-jpa`, Boot's reasoning is: _"Hibernate and JPA are here, so this app wants to talk to a database. I'll set up a `DataSource`, an `EntityManagerFactory`, and a transaction manager."_

But Boot can't invent a database for you. It needs to know **where** the database is (a URL), **who** to log in as, and **which driver** to use. If you haven't told it, it fails at startup. That is the crash.

## The typical error

```
Failed to configure a DataSource: 'url' attribute is not specified
and no embedded datasource could be configured.

Reason: Failed to determine a suitable driver class
```

Or, when you have a driver but the database isn't reachable or the credentials are wrong:

```
HikariPool-1 - Exception during pool initialization
Connection refused / FATAL: password authentication failed
```

## Why it crashes instead of just warning

Spring creates all beans at startup. `DataSourceAutoConfiguration` activates when two conditions are met:

1. `DataSource` and related classes are on the classpath (JPA brings in `spring-jdbc` and Hikari).
2. You haven't defined your own `DataSource` bean.

Then `HibernateJpaAutoConfiguration` depends on that DataSource bean. If the bean can't be built, the application context fails to start, and Spring **fails fast** by design: a half-working app that silently can't save data is considered worse than one that refuses to start.

One exception worth knowing: if an **embedded** database (H2, HSQLDB, Derby) is on the classpath, Boot configures it automatically with no URL needed. That's why some tutorials "just work" and yours doesn't.

## The fixes

**Option 1: Add a real database (the usual goal).** For PostgreSQL, add the driver to `pom.xml`:

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

Then configure `application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=myuser
spring.datasource.password=mypassword
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

On Debian 13 the database must actually be running. Check with:

```bash
sudo systemctl status postgresql
```

**Option 2: Use H2 for learning.** No installation needed, since it lives in memory:

```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

With H2 on the classpath and no URL set, Boot creates an in-memory database automatically.

**Option 3: You don't want a database yet.** Exclude the auto-configuration:

```java
@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)
public class DemoApplication { ... }
```

This is a workaround, not a goal. If you also have JPA repositories, you'll then get other errors.

## Gotchas and edge cases

- **Driver in the wrong scope or missing:** the error says "Failed to determine a suitable driver class." Check that the driver dependency exists and that Maven reloaded (`mvn clean install`, or reload the project in your IDE).
- **Database running but empty or missing:** PostgreSQL error `database "mydb" does not exist`. Boot creates **tables**, not the database itself. Create it first: `sudo -u postgres createdb mydb`.
- **Wrong dialect or version mismatch:** rare now, since Hibernate auto-detects the dialect. Avoid setting `spring.jpa.database-platform` unless you need to.
- **`ddl-auto` values:** `update` is fine for learning. `create-drop` wipes data on shutdown. `validate` or `none` is for production. Never use `create` or `update` on real data without understanding them.
- **Entity problems also crash startup:** an `@Entity` without an `@Id`, or a repository referencing a non-entity, produces a different error but at the same stage.

## How to diagnose any startup crash

Scroll to the **bottom** of the stack trace and find the `Caused by:` lines. The last one is the real root cause. Spring's wrapper exceptions are long, but the final `Caused by` usually names the exact problem.





[[Spring Framework]]