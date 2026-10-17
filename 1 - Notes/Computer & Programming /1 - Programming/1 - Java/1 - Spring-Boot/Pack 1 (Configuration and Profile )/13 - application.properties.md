
## The core intuition first

Think of your Spring Boot app as a machine with a bunch of dials on it — "which port do I listen on," "what's the database password," "how verbose should logging be." Hard-coding those values into your Java classes would mean recompiling every time you want to change a dial. `application.properties` (or its YAML sibling) is the **external control panel** for those dials: a plain text file Spring reads at startup and uses to configure beans before your code ever runs.

The deeper idea behind this is **externalized configuration** — the practice of keeping "what varies between environments" (dev laptop, staging server, production) completely separate from "what the code does." Same JAR file, different `.properties` file per environment, zero code changes. This is one of the Twelve-Factor App principles, and Spring Boot builds its entire configuration system around it.

---

## The mental model: a giant `Map<String, String>`

Forget Spring for a second. At its heart, `application.properties` is just key-value pairs:

```properties
server.port=8081
app.name=MyStore
```

Spring loads this file into an abstraction called the **`Environment`** — essentially a big property lookup table merged from _multiple sources_ (the file, environment variables, command-line args, etc.). Everything downstream — auto-configuration, `@Value`, `@ConfigurationProperties` — is just querying this `Environment` for a key and getting a value back.

Once you hold onto that mental model, everything else is mechanics.

---

## 1. Where the file lives and how Spring finds it

By default, Spring Boot looks for `application.properties` in (in order of precedence, highest wins):

```
1. /config subdirectory of the current directory
2. current directory
3. /config package on the classpath
4. classpath root (src/main/resources/application.properties)
```

So `src/main/resources/application.properties` is the conventional home — it gets bundled into the JAR and is always found.

---

## 2. Basic syntax and the properties Spring Boot already understands

```properties
# Server
server.port=8081
server.servlet.context-path=/api

# Application identity
spring.application.name=inventory-service

# Database
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=secret
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA / Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# Logging
logging.level.root=INFO
logging.level.org.springframework.web=DEBUG
logging.level.com.example.myapp=TRACE
```

Why do these specific keys "just work" without you writing any code? This is **Spring Boot auto-configuration**. Internally, Spring Boot ships classes like `DataSourceAutoConfiguration` that are annotated roughly like this (simplified):

```java
@ConfigurationProperties(prefix = "spring.datasource")
public class DataSourceProperties {
    private String url;
    private String username;
    private String password;
    // getters/setters
}
```

`@ConfigurationProperties(prefix = "spring.datasource")` tells Spring: "take every key starting with `spring.datasource.` from the `Environment`, strip the prefix, and bind the remainder to this object's fields by name." `spring.datasource.url` → `setUrl(...)`. That's the entire mechanism — no magic, just prefix-matching and reflection-based binding.

This is _why_ the property names are so predictable once you know a library's prefix: `spring.jpa.*`, `spring.kafka.*`, `server.*` — they're all backed by a `@ConfigurationProperties` class somewhere in that library's source.

---

## 3. Reading your own custom properties

### Option A: `@Value` — single value injection

```properties
app.upload.max-size-mb=25
app.feature.dark-mode=true
```

```java
@Component
public class UploadService {

    @Value("${app.upload.max-size-mb}")
    private int maxSizeMb;

    @Value("${app.feature.dark-mode:false}") // ':false' = default if missing
    private boolean darkModeEnabled;
}
```

`${...}` is **property placeholder syntax** — Spring resolves it against the `Environment` at bean-creation time. The `:false` after the colon is a **default value**, used only if the key is absent (not if it's present-but-empty — that's a common gotcha, covered below).

`@Value` is fine for one or two scattered settings, but it doesn't scale — you end up with property keys as string literals sprinkled across your codebase, no compile-time safety, no IDE autocomplete.

### Option B: `@ConfigurationProperties` — the grown-up way

```properties
app.upload.max-size-mb=25
app.upload.allowed-types=jpg,png,pdf
app.upload.storage.bucket=my-bucket
app.upload.storage.region=eu-west-1
```

```java
@Component
@ConfigurationProperties(prefix = "app.upload")
public class UploadProperties {

    private int maxSizeMb;
    private List<String> allowedTypes;
    private Storage storage = new Storage();

    // getters and setters required — Spring needs them to bind values

    public static class Storage {
        private String bucket;
        private String region;
        // getters and setters
    }
}
```

```java
@Service
public class UploadService {
    private final UploadProperties props;

    public UploadService(UploadProperties props) { // constructor injection
        this.props = props;
    }
}
```

What just happened, mechanically:

- Spring sees `@ConfigurationProperties(prefix = "app.upload")` and, at startup, walks every field.
- For `maxSizeMb`, it looks for `app.upload.max-size-mb` — note the **relaxed binding**: `maxSizeMb` (camelCase in Java) automatically matches `max-size-mb` (kebab-case in properties). Spring normalizes both to the same canonical form internally, so you can write kebab-case, camelCase, or even `MAX_SIZE_MB` (env-var style) and they all bind to the same field.
- For `allowedTypes` (a `List<String>`), a comma-separated value like `jpg,png,pdf` is automatically split into a list.
- For `storage`, a **nested object**, it recurses: `app.upload.storage.bucket` → `Storage.bucket`.

This is dramatically better than `@Value` for anything beyond a couple of flat values: type-safe, groupable, testable in isolation, and (if you add the `spring-boot-configuration-processor` dependency) gives you **IDE autocomplete** for your own custom keys, exactly like Spring's built-in ones.

To make Spring actually scan for these classes if `@Component` isn't on it, you can alternatively register it via:

```java
@Configuration
@EnableConfigurationProperties(UploadProperties.class)
public class AppConfig { }
```

This is the _other_ common thing besides `@Bean` you'll see inside a `@Configuration` class — worth connecting back to your earlier question.

---

## 4. Profiles — different dials for different environments

This is where the "externalized configuration" philosophy really pays off.

```
src/main/resources/
├── application.properties          # common/shared settings
├── application-dev.properties      # dev overrides
├── application-prod.properties     # prod overrides
```

```properties
# application.properties (base — always loaded)
spring.application.name=inventory-service
logging.level.root=INFO

# application-dev.properties
spring.datasource.url=jdbc:h2:mem:testdb
logging.level.root=DEBUG

# application-prod.properties
spring.datasource.url=jdbc:postgresql://prod-db:5432/inventory
logging.level.root=WARN
```

You activate a profile via:

```properties
# in application.properties
spring.profiles.active=dev
```

or, more realistically, as an environment variable / launch argument so you never bake "dev" into a file that gets deployed to prod:

```bash
java -jar app.jar --spring.profiles.active=prod
```

**Merge order and precedence** (this is the part people get wrong): the base `application.properties` loads first, then the active profile's file loads **on top of it**, overriding any matching keys. Keys only in the base file that aren't overridden stay as-is. It's a layered merge, not a full replacement.

This connects directly to `@Profile("dev")` from your earlier question — same underlying concept (the active profile), two different mechanisms for reacting to it: `.properties` files swap _values_, `@Profile` on a `@Bean` swaps _which beans exist at all_.

---

## 5. Precedence: the full resolution order (the part everyone eventually needs)

Properties don't only come from the file — Spring merges _many_ sources, and understanding the priority order is essential for debugging "why isn't my property taking effect."

From highest to lowest priority (highest wins when the same key appears in multiple places):

1. Command-line arguments (`--server.port=9090`)
2. `SPRING_APPLICATION_JSON` (inline JSON env var)
3. Servlet init parameters
4. JNDI attributes
5. Java System properties (`-Dserver.port=9090`)
6. OS environment variables (`SERVER_PORT=9090`)
7. Profile-specific `application-{profile}.properties` **outside** the packaged jar
8. Profile-specific `application-{profile}.properties` **inside** the packaged jar
9. `application.properties` outside the jar
10. `application.properties` inside the jar (your `src/main/resources` version)
11. `@PropertySource` on `@Configuration` classes
12. Default properties set via `SpringApplication.setDefaultProperties`

**Why this order exists conceptually:** it's designed so that whatever is "closest to the actual running instance" (a command-line flag you typed right now) always beats whatever is "baked further back" (a value compiled into the jar months ago). This is what lets you do things like override a single property for one Docker container without rebuilding the image — just pass `-e SERVER_PORT=9090` and it beats everything in the file.

This is also exactly why environment variables work as overrides without any extra code: Spring automatically maps `SERVER_PORT` → `server.port` (uppercase + underscores ↔ lowercase + dots), because containerized environments (Docker, Kubernetes) conventionally configure things via env vars, not files.

---

## 6. Gotchas and edge cases

- **Default value vs. empty value in `@Value`:** `${app.name:Default}` only kicks in if the key is _missing entirely_. If `application.properties` contains `app.name=` (present but blank), you get an empty string, not `"Default"`.
- **Type mismatches fail at startup, not silently:** if `app.upload.max-size-mb=abc` and the field is an `int`, Spring Boot fails fast with a clear `ConfigurationPropertiesBindingException` during context startup — this is a _feature_, not an annoyance; you want config errors caught immediately, not at 2am when the upload endpoint is hit in production.
- **`@ConfigurationProperties` needs setters (or a constructor)** — either JavaBean-style getters/setters, or, since Spring Boot 2.2+, an **immutable, constructor-bound** style:
    
    ```java
    @ConfigurationProperties(prefix = "app.upload")public record UploadProperties(int maxSizeMb, List<String> allowedTypes) {}
    ```
    
    This is the modern idiomatic approach in newer Spring Boot — no mutable setters, thread-safe by construction.
- **YAML vs `.properties`:** `application.yml` is functionally equivalent but expresses nesting natively instead of via dots:
    
    ```yaml
    app:  upload:    max-size-mb: 25    storage:      bucket: my-bucket
    ```
    
    Same `Environment` underneath — pick one format per project, don't mix both for the same keys (if you do, `.properties` wins over `.yml` in the default precedence).
- **Multi-document YAML profiles** (Boot 2.4+): you can put multiple profiles in _one_ file using `---` separators instead of separate `application-{profile}.yml` files — handy for small projects, harder to read for large ones.
- **Secrets don't belong in the file at all:** committing `spring.datasource.password=secret` to git is a classic mistake. The standard fix is to reference an environment variable _from_ the properties file:
    
    ```properties
    spring.datasource.password=${DB_PASSWORD}
    ```
    
    — the `${}` here is resolved against the `Environment`, which includes OS env vars, so the actual secret only ever exists outside your codebase.


[[Java]]
[[Spring Framework]]
[[1 - PostgreSQL Confiuration ✧]]