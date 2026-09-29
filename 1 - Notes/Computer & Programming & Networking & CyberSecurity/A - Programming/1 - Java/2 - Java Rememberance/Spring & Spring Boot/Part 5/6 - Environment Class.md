
# Defining an Environment Class (Bean) in Spring Boot

There are two common interpretations of this question, so I'll cover both:

1. **Injecting Spring's built-in `Environment`** — already a bean, no definition needed.
2. **Creating your own custom environment/config class** and registering it as a Spring bean.

---

## 1. Spring's Built-in `Environment` (Already a Bean)

Spring Boot auto-registers a `ConfigurableEnvironment` in the `ApplicationContext` under the name `"environment"`. You can inject it directly — **you do not need to define it**.

```java
@Service
public class DatabaseService {

    private final Environment env;

    public DatabaseService(Environment env) {   // constructor injection
        this.env = env;
    }

    public String getDbUrl() {
        return env.getProperty("spring.datasource.url");
    }

    public boolean isProd() {
        return Arrays.asList(env.getActiveProfiles()).contains("prod");
    }
}
```

Useful methods: `getProperty(...)`, `getProperty(key, type)`, `getActiveProfiles()`, `getDefaultProfiles()`, `containsProperty(key)`.

---

## 2. Custom Environment Class as a Bean

### Option A — `@Component` (simplest)

```java
@Component
public class AppEnvironment {

    private final String name;
    private final String region;

    public AppEnvironment(
            @Value("${app.env.name:local}") String name,
            @Value("${app.env.region:eu}") String region) {
        this.name = name;
        this.region = region;
    }

    public String getName()   { return name; }
    public String getRegion() { return region; }
}
```

### Option B — `@ConfigurationProperties` (recommended for grouped config)

`application.yml`:
```yaml
app:
  env:
    name: production
    region: eu-west-1
```

```java
@Component
@ConfigurationProperties(prefix = "app.env")
public class AppEnvironment {
    private String name;
    private String region;

    // getters + setters (or use a record with @ConstructorBinding)
}
```

Or with a Java record (Spring Boot 3):
```java
@ConfigurationProperties(prefix = "app.env")
public record AppEnvironment(String name, String region) {}
```
Then enable it:
```java
@SpringBootApplication
@EnableConfigurationProperties(AppEnvironment.class)
public class Application { ... }
```

### Option C — `@Bean` method in a `@Configuration` class

```java
@Configuration
public class AppConfig {

    @Bean
    public AppEnvironment appEnvironment(Environment env) {
        return new AppEnvironment(
                env.getProperty("app.env.name", "local"),
                env.getProperty("app.env.region", "eu"));
    }
}
```

### Option D — Profile-specific beans

```java
@Configuration
public class EnvConfig {

    @Bean
    @Profile("dev")
    public AppEnvironment devEnvironment() {
        return new AppEnvironment("dev", "local");
    }

    @Bean
    @Profile("prod")
    public AppEnvironment prodEnvironment() {
        return new AppEnvironment("prod", "eu-west-1");
    }
}
```

Activate with `--spring.profiles.active=prod` or `spring.profiles.active: prod` in YAML.

---

## 3. Consuming the Bean

```java
@Service
public class ReportService {

    private final AppEnvironment appEnv;

    public ReportService(AppEnvironment appEnv) {
        this.appEnv = appEnv;
    }

    public void print() {
        System.out.println("Env: " + appEnv.getName() + " / " + appEnv.getRegion());
    }
}
```

---

## Quick Decision Guide

| Goal | Use |
|------|-----|
| Read individual properties dynamically | Inject `Environment` directly |
| Group related config into a typed object | `@ConfigurationProperties` |
| Simple constants from `@Value` | `@Component` + constructor `@Value` |
| Different beans per environment | `@Profile` on `@Bean` methods |
| Conditional on a property | `@ConditionalOnProperty` |

**Best practice:** prefer `@ConfigurationProperties` over injecting `Environment` everywhere — it's type-safe, validated (add `@Validated` + JSR-303 annotations), and testable. Use the raw `Environment` only when you genuinely need dynamic or unknown-at-compile-time keys.


[[0 - Spring Framework]]