

The word "environment" means two different things here, and mixing them up is the main source of confusion in this topic.

- **Spring's `Environment`** is a built-in object that holds all of your app's settings (every property from every source) and knows which profiles are active. Spring creates it for you.
- **"The environment" as a deployment idea** means dev, staging or prod. If you want a class of your own that says "I am running in prod, in region eu-west-1," that is your own class, and Spring doesn't provide it.

This note covers both. It builds on three earlier topics: profiles (which environment is active), `@PropertySource` (adding layers of settings), and `@ConfigurationProperties` (binding settings to a typed object). Here you'll see where they all meet.

---

## Part 1: Spring's built-in `Environment`

In the `@PropertySource` note, you saw that Spring keeps a stack of property sources: command line, environment variables, `application.properties` and so on. The `Environment` is the object that holds that whole stack. It is already a bean, registered under the name `environment`, so you never define it. You just inject it:

```java
@Service
public class DatabaseService {

    private final Environment env;

    public DatabaseService(Environment env) {      // constructor injection
        this.env = env;
    }

    public String dbUrl() {
        return env.getProperty("spring.datasource.url");
    }

    public boolean isProd() {
        return env.acceptsProfiles(Profiles.of("prod"));
    }
}
```

Line by line:

- `getProperty(...)` asks the stack for a key. The strongest source that has it wins, using the same precedence order from the `@PropertySource` note.
- `acceptsProfiles(Profiles.of("prod"))` asks "is `prod` active?" It's cleaner than searching `getActiveProfiles()` by hand, and it understands expressions like `Profiles.of("dev | test")`.

The methods you'll use most:

|Method|What it does|
|---|---|
|`getProperty("key")`|The value, or `null` if missing|
|`getProperty("key", "fallback")`|The value, or your fallback|
|`getProperty("key", Integer.class, 8080)`|The value converted to a type, with a fallback|
|`getRequiredProperty("key")`|The value, or an exception if missing (good for must-have settings)|
|`containsProperty("key")`|Whether the key exists|
|`getActiveProfiles()` / `getDefaultProfiles()`|The active profiles / the `default` fallback list|
|`acceptsProfiles(Profiles.of(...))`|Whether a profile expression matches|

Two things to know about `Environment`:

- Lookups use **exact keys**. `env.getProperty("app.max-size")` won't find `app.maxSize` the way `@ConfigurationProperties` relaxed binding would. (Only environment variables get mapped, so `SERVER_PORT` is found as `server.port`.)
- `@PropertySource` works by adding a source to this same `Environment`. That is why anything it loads is readable here.

Don't use `Environment` to branch your business logic by profile, as in `if (isProd())`. The profiles note covered this: swap an implementation with `@Profile`, or use a configurable value, instead.

---

## Part 2: Your own "environment" class

Say you want one typed object that holds `name` and `region`, so the rest of your code can ask `appEnv.name()` instead of looking up strings. Choose the approach by what you need:

|Goal|Use|
|---|---|
|A group of settings in one typed object|`@ConfigurationProperties` (Option A)|
|One or two quick values|A `@Component` with `@Value` (Option B)|
|Construction needs real logic|A `@Bean` method (Option C)|
|The values differ per environment|Profile property files (not `@Profile` beans)|

### Option A: `@ConfigurationProperties` (the best default)

```yaml
# application.yml
app:
  env:
    name: production
    region: eu-west-1
```

```java
@ConfigurationProperties(prefix = "app.env")
public record AppEnvironment(String name, String region) {}
```

Register it with `@ConfigurationPropertiesScan` on your main class, or `@EnableConfigurationProperties(AppEnvironment.class)` on a configuration class. In Spring Boot 3, a record needs no `@ConstructorBinding`. Everything from the `@ConfigurationProperties` note applies here: add `@Validated` and constraints to fail at startup on bad values, and use `@DefaultValue` for defaults:

```java
@ConfigurationProperties(prefix = "app.env")
@Validated
public record AppEnvironment(
        @NotBlank @DefaultValue("local") String name,
        @NotBlank @DefaultValue("eu") String region) {}
```

### Option B: `@Component` with `@Value`

```java
@Component
public class AppEnvironment {
    private final String name;
    private final String region;

    public AppEnvironment(@Value("${app.env.name:local}") String name,
                          @Value("${app.env.region:eu}") String region) {
        this.name = name;
        this.region = region;
    }

    public String getName()   { return name; }
    public String getRegion() { return region; }
}
```

The text after the colon is the default. It works, but you repeat the string keys, and you get no validation. Use it for one or two values.

### Option C: a `@Bean` method

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

Spring injects `Environment` into the method, and you read what you need. Use this only when building the object takes real logic. Otherwise Option A does the same job with less code.

### The environment differs per profile: use property files, not beans

An earlier version of this note had a `@Bean` per profile:

```java
// Avoid: two beans that differ only in their values
@Bean @Profile("dev")  AppEnvironment devEnv()  { return new AppEnvironment("dev",  "local"); }
@Bean @Profile("prod") AppEnvironment prodEnv() { return new AppEnvironment("prod", "eu-west-1"); }
```

The profiles note drew this line: **different values for the same bean belong in `application-{profile}.properties`, and `@Profile` beans are for different implementations.** Here it's the same class with different values, so do this:

```properties
# application-dev.properties
app.env.name=dev
app.env.region=local

# application-prod.properties
app.env.name=prod
app.env.region=eu-west-1
```

One `AppEnvironment` bean from Option A reads them, and the active profile picks which file layers on top. The bean-per-profile version has another weakness: if you start with a profile that has no bean (such as `staging`), nothing is registered and startup fails with a missing bean.

### Switching a bean on or off by property

The decision table mentioned this, so here it is:

```java
@Bean
@ConditionalOnProperty(name = "app.metrics.enabled", havingValue = "true")
public MetricsReporter metricsReporter() { ... }
```

The bean exists only when `app.metrics.enabled=true`. Use it for feature switches. Use `@Profile` for environment-based switches.

---

## Use it

```java
@Service
public class ReportService {

    private final AppEnvironment appEnv;

    public ReportService(AppEnvironment appEnv) {
        this.appEnv = appEnv;
    }

    public void print() {
        System.out.println("Env: " + appEnv.name() + " / " + appEnv.region());
    }
}
```

This uses the record's `name()` and `region()` from Option A. With the class from Option B you would call `getName()` and `getRegion()`.

---

## Mistakes to avoid

- **Defining the class twice.** If you use Option B (`@Component`) _and_ Option C (`@Bean appEnvironment`), both are named `appEnvironment` and Boot refuses to start, because bean overriding is off by default. Pick one option.
- **Naming clash in imports.** Your class and Spring's are both called `Environment` or something close. Importing the wrong `Environment` (or naming yours exactly `Environment`) gives confusing errors. A name like `AppEnvironment` or `AppInfo` keeps them apart.
- **Using `Environment` for grouped settings.** It works, but you're back to string keys with no type safety and no validation.

---

## Related concept in short

**`EnvironmentAware`** is an interface with a `setEnvironment(Environment env)` method. Spring calls it on any bean that implements it, which is handy in classes Spring creates in ways that make constructor injection awkward. Usually you inject `Environment` through the constructor instead.



[[Spring Framework]]


