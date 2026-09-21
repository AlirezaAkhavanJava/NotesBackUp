
In Spring, **`Environment`** is the abstraction that represents the context your application is running in — it combines two things: **profiles** (which beans are active) and **properties** (config values from files, system properties, env variables, etc).

## The `Environment` interface

You can inject it directly to read config or check active profiles programmatically:

```java
@Component
public class MyService {

    @Autowired
    private Environment env;

    public void printInfo() {
        String dbUrl = env.getProperty("spring.datasource.url");
        boolean isDev = env.acceptsProfiles(Profiles.of("dev"));
        System.out.println("DB URL: " + dbUrl + ", dev profile active? " + isDev);
    }
}
```

Common methods:

- `getProperty("key")` → returns the value or `null`
- `getProperty("key", "default")` → with a fallback
- `getRequiredProperty("key")` → throws if missing
- `getActiveProfiles()` / `getDefaultProfiles()`
- `acceptsProfiles(...)` → check if a profile is active

Usually you don't need this directly — `@Value` and `@ConfigurationProperties` read from the same underlying `Environment` for you.

## Profiles: environment-specific behavior

This is the more common meaning of "environment" in Spring Boot — having different configs/beans for `dev`, `test`, `prod`, etc.

**Environment-specific property files:**

```
application.properties          # common/default
application-dev.properties       # dev overrides
application-prod.properties      # prod overrides
```

```properties
# application-dev.properties
spring.datasource.url=jdbc:h2:mem:devdb
logging.level.root=DEBUG

# application-prod.properties
spring.datasource.url=jdbc:postgresql://prod-host:5432/mydb
logging.level.root=WARN
```

**Activating a profile** — pick one:

```properties
# in application.properties
spring.profiles.active=dev
```

```bash
# or as a JVM arg / env var when running the jar
java -jar app.jar --spring.profiles.active=prod
```

```bash
export SPRING_PROFILES_ACTIVE=prod
```

**Conditional beans with `@Profile`:**

```java
@Configuration
public class DataSourceConfig {

    @Bean
    @Profile("dev")
    public DataSource devDataSource() {
        return new EmbeddedDatabaseBuilder().setType(EmbeddedDatabaseType.H2).build();
    }

    @Bean
    @Profile("prod")
    public DataSource prodDataSource() {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl("jdbc:postgresql://prod-host:5432/mydb");
        return ds;
    }
}
```

You can also stack it on a whole `@Component`/`@Service` class, and use `!dev` to mean "any profile except dev."

## Property precedence (highest wins)

Roughly, from highest to lowest priority:

1. Command-line arguments (`--server.port=9090`)
2. `SPRING_APPLICATION_JSON` env var
3. OS environment variables (`SERVER_PORT=9090`)
4. `application-{profile}.properties`
5. `application.properties`
6. `@PropertySource` on `@Configuration` classes
7. Default properties set in code

## Rule of thumb

- Use **profiles** (`application-{env}.properties` + `@Profile`) to swap beans/config per environment (dev/test/prod).
- Inject `Environment` only when you need to check things dynamically at runtime; for simple config values, prefer `@Value("${my.property}")` or `@ConfigurationProperties`.


[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]
[[Java]]