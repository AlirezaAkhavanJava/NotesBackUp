
**Bean Profiles** (`@Profile`) let you register different beans — or skip registering them entirely — depending on which environment (profile) is active. It's Spring's way of saying "only create this bean if we're running in `dev`" (or `prod`, `test`, etc).

## Basic usage

```java
@Configuration
public class DataSourceConfig {

    @Bean
    @Profile("dev")
    public DataSource devDataSource() {
        return new EmbeddedDatabaseBuilder()
                .setType(EmbeddedDatabaseType.H2)
                .build();
    }

    @Bean
    @Profile("prod")
    public DataSource prodDataSource() {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl("jdbc:postgresql://prod-host:5432/mydb");
        ds.setUsername("prod_user");
        ds.setPassword("secret");
        return ds;
    }
}
```

If `dev` is active, only `devDataSource` gets created. If `prod` is active, only `prodDataSource`. Whichever isn't active simply **doesn't exist** in the context — it's not created-and-ignored, it's never instantiated.

## On a whole component class

`@Profile` also works on `@Component`, `@Service`, `@Repository`, `@Configuration` — the whole class is skipped if the profile doesn't match:

```java
@Service
@Profile("dev")
public class MockEmailService implements EmailService {
    public void send(String to, String msg) {
        System.out.println("MOCK EMAIL to " + to + ": " + msg);
    }
}

@Service
@Profile("prod")
public class SmtpEmailService implements EmailService {
    public void send(String to, String msg) {
        // real SMTP sending logic
    }
}
```

## Multiple profiles / negation

```java
@Profile({"dev", "test"})   // active if EITHER dev OR test is active
@Profile("!prod")           // active if prod is NOT active
```

`!prod` is handy for "everything except production" beans (like an in-memory test double).

## Complex logic with `@Profile` + expressions

Since Spring 5.1, you can use profile expressions:

```java
@Profile("dev & !cloud")   // dev AND NOT cloud
@Profile("dev | qa")       // dev OR qa
```

## Activating a profile

Same mechanisms as before — pick whichever fits your workflow:

```bash
java -jar app.jar --spring.profiles.active=dev
```

```properties
# application.properties
spring.profiles.active=dev
```

```bash
export SPRING_PROFILES_ACTIVE=prod
```

You can also activate **multiple** profiles at once:

```properties
spring.profiles.active=dev,debug
```

## Default profile

If you don't set `spring.profiles.active` at all, Spring uses the `default` profile. You can mark a bean to only load when nothing else is active:

```java
@Bean
@Profile("default")
public DataSource fallbackDataSource() { ... }
```

## Common pitfall: no active profile matches

If you define beans only under `@Profile("dev")` and `@Profile("prod")`, but forget to activate either, **neither bean is created** — and if something else `@Autowired`s that type, you'll get a startup failure (`NoSuchBeanDefinitionException`). Always make sure a profile is active, or provide a `default`/no-profile fallback bean.

## Rule of thumb

|Goal|Approach|
|---|---|
|Swap an entire implementation per environment|`@Profile` on `@Service`/`@Component` classes|
|Swap just a bean's configuration (e.g. DataSource)|`@Profile` on `@Bean` methods inside a `@Configuration` class|
|Combine conditions|Profile expressions: `"dev & !cloud"`, `"a|
|Fallback when no profile is set|`@Profile("default")`|


[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]