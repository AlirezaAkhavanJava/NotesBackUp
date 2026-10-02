

Picking the natural next step — we introduced `@ConfigurationProperties` briefly as a _better alternative_ to scattered `@Value` fields. Let's now go deep on it properly, since it's the idiomatic way real Spring Boot apps handle configuration.

---

## 1. The Core Idea — Binding, Not Injecting

`@Value("${mail.host}")` **injects** one property into one field, one at a time. `@ConfigurationProperties` **binds** an entire prefixed group of properties into one structured object, all at once — including nested objects, lists, and maps.

```properties
mail.host=smtp.example.com
mail.port=587
mail.from=noreply@library.example.com
mail.retry.max-attempts=3
mail.retry.delay-seconds=10
```

Instead of five separate `@Value` fields, one object captures the whole group, structure included:

```java
@ConfigurationProperties(prefix = "mail")
public record MailProperties(
    String host,
    int port,
    String from,
    Retry retry
) {
    public record Retry(int maxAttempts, int delaySeconds) {}
}
```

Notice `retry.max-attempts` (kebab-case in the file) binds to `maxAttempts` (camelCase in Java) automatically — this is **relaxed binding**, covered in detail below.

---

## 2. Enabling It — Two Ways

### Option A — `@EnableConfigurationProperties` (explicit, what we used earlier)

```java
@Configuration
@EnableConfigurationProperties(MailProperties.class)
public class MailConfig {
}
```

This registers `MailProperties` as a Spring bean explicitly, from wherever you place this line. Good when you want full control over exactly where/when it's registered — especially relevant in multi-module projects.

### Option B — `@ConfigurationPropertiesScan` (auto-discovery)

```java
@SpringBootApplication
@ConfigurationPropertiesScan
public class LibraryApplication {
    public static void main(String[] args) {
        SpringApplication.run(LibraryApplication.class, args);
    }
}
```

This tells Spring Boot to scan your whole package tree (same scanning root as component scanning, from our Maven Structure tutorial) and auto-register **every** class annotated `@ConfigurationProperties`, without listing them one by one. Less boilerplate, but less explicit — you have to go looking for the annotation to know what's registered.

**Practical guidance:** `@ConfigurationPropertiesScan` is the more common modern default for application-wide settings. `@EnableConfigurationProperties` remains useful when a properties class belongs to a specific module/library (tying back to the multi-module `@PropertySource` scenario from before) and you want that module to control its own registration explicitly.

---

## 3. Relaxed Binding — The Rules

This is the mechanism that let `retry.max-attempts` map to `maxAttempts`. Spring Boot normalizes property names across several common naming conventions so your properties file, environment variables, and Java fields can each use their own natural convention:

|Properties file|Environment variable|Java field|
|---|---|---|
|`mail.retry.max-attempts`|`MAIL_RETRY_MAXATTEMPTS`|`maxAttempts`|
|`mail.retry.maxAttempts`|(same)|`maxAttempts`|
|`mail.retry.MAX_ATTEMPTS`|(same)|`maxAttempts`|

**Why this matters practically:** environment variables can't contain dots or mixed case reliably across every OS/shell — so relaxed binding is _why_ you can set `MAIL_RETRY_MAXATTEMPTS=5` as a Docker environment variable (exactly like the `SPRING_DATASOURCE_URL` we used in the Docker Compose tutorial) and have it correctly bind to `retry.maxAttempts` in your Java record, with zero extra config. This is the same mechanism underneath both.

**The one convention to standardize on for `.properties`/`.yml` files themselves:** kebab-case (`max-attempts`). It's the most broadly compatible across relaxed binding's rules and what Spring Boot's own reference docs use — pick it consistently rather than mixing styles across your config file.

---

## 4. Validation — Fail Fast on Bad Config

This is one of `@ConfigurationProperties`'s biggest practical advantages over `@Value`: you can validate the _entire group_ at startup, using standard Bean Validation annotations — the same ones from our REST API error-handling tutorial (`@NotBlank`, `@Pattern`, etc.), just applied to config instead of request bodies.

```java
@ConfigurationProperties(prefix = "mail")
@Validated
public record MailProperties(
    @NotBlank
    String host,

    @Min(1) @Max(65535)
    int port,

    @Email
    String from
) {}
```

If `mail.port=99999` or `mail.from=not-an-email` in your properties file, **the application refuses to start**, with a clear validation error naming exactly which property is wrong:

```
Binding to target org.example.MailProperties failed:
    Property: mail.port
    Value: "99999"
    Reason: must be less than or equal to 65535
```

**Why this matters:** without validation, a bad config value might not surface as an error until the first time that code path actually runs in production — maybe hours after deploy, maybe only when the overdue-notification job runs at 2am. `@Validated` + Bean Validation turns a silent runtime landmine into an immediate, loud startup failure — exactly the "fail fast" principle worth internalizing for any config-driven behavior.

---

## 5. Nested Objects, Lists, and Maps — Full Binding Power

`@ConfigurationProperties` handles structures `@Value` simply cannot express cleanly.

### Nested objects (already seen above with `Retry`)

### Lists

```properties
library.branch-names[0]=Downtown
library.branch-names[1]=Uptown
library.branch-names[2]=Suburban
```

```java
@ConfigurationProperties(prefix = "library")
public record LibraryProperties(List<String> branchNames) {}
```

In YAML, this is far more natural to read/write:

```yaml
library:
  branch-names:
    - Downtown
    - Uptown
    - Suburban
```

### Maps

```yaml
library:
  branch-hours:
    downtown: "9-18"
    uptown: "10-17"
```

```java
@ConfigurationProperties(prefix = "library")
public record LibraryProperties(Map<String, String> branchHours) {}
```

### Lists of nested objects — the most powerful case

```yaml
library:
  branches:
    - name: Downtown
      capacity: 500
    - name: Uptown
      capacity: 200
```

```java
@ConfigurationProperties(prefix = "library")
public record LibraryProperties(List<Branch> branches) {
    public record Branch(String name, int capacity) {}
}
```

This is genuinely difficult to express cleanly with `@Value` at all — it's the clearest case where `@ConfigurationProperties` isn't just "nicer," it's the _only_ practical option.

---

## 6. Records vs. Classes for `@ConfigurationProperties`

We've been using **Java records** throughout (`public record MailProperties(...)`), which Spring Boot has fully supported since version 2.6+ via **constructor binding**. Worth knowing the older, still-common alternative:

### The older style — mutable class with setters

```java
@ConfigurationProperties(prefix = "mail")
public class MailProperties {
    private String host;
    private int port;
    private String from;

    // getters AND setters required — Spring binds via setter injection
    public String getHost() { return host; }
    public void setHost(String host) { this.host = host; }
    // ... etc for every field
}
```

### Why records are the better modern choice

||Mutable class|Record|
|---|---|---|
|Boilerplate|Getter + setter per field|None — generated automatically|
|Mutability|Mutable after construction (can be reassigned anywhere)|Immutable once bound — safer|
|Binding mechanism|Setter injection|Constructor binding|
|Null safety|Fields can be silently left null|Constructor binding fails fast on missing required values|

**Practical guidance:** always prefer records for new `@ConfigurationProperties` classes on Java 21 (which you're already using per our Maven tutorial). The mutable-class style is what you'll see in older tutorials/codebases predating Spring Boot 2.6 — recognize it, but don't write new code that way.

---

## 7. Default Values

Records need a slightly different approach than you might expect, since records can't have field initializers the way classes traditionally used defaults with setters.

### Using a compact constructor

```java
public record MailProperties(String host, int port, String from) {
    public MailProperties {
        if (port == 0) port = 587; // applies only if not set in config
    }
}
```

### Or, more idiomatically, via `@DefaultValue`

```java
public record MailProperties(
    String host,
    @DefaultValue("587") int port,
    @DefaultValue("noreply@library.example.com") String from
) {}
```

`@DefaultValue` is the cleaner, more declarative approach — the default lives right next to the field it applies to, readable at a glance, rather than buried in constructor logic.

---

## 8. `@ConfigurationProperties` vs `@Value` — When to Use Which

|Scenario|Use|
|---|---|
|One-off, single unrelated property|`@Value`|
|A group of 3+ related settings|`@ConfigurationProperties`|
|Need validation on config values|`@ConfigurationProperties` (`@Validated`)|
|Nested structure, lists, or maps|`@ConfigurationProperties` — `@Value` can't express this cleanly|
|Property used in exactly one place, no reuse|Either works; `@Value` is slightly less ceremony|
|Property used across multiple classes|`@ConfigurationProperties` — inject the one typed object everywhere, instead of repeating `@Value` strings|

**A concrete failure mode `@ConfigurationProperties` prevents:** with `@Value("${mail.host}")` repeated across five classes, a typo in _one_ of them (`${mail.hots}`) silently resolves to nothing at runtime (or throws, depending on config) — and you won't catch it until that specific class runs. With `@ConfigurationProperties`, the property name is spelled **once**, in one record definition, and every consumer just injects the typed object — a typo in the key only breaks binding at startup, in one obvious place.

---

## 9. Full Worked Example — Extending Our Library App's Overdue Notifications

Picking up exactly where the `@PropertySource` tutorial left off, now with full validation and structure:

```yaml
# mail-notifications.yml (hypothetically, or .properties equivalent)
notifications:
  overdue:
    enabled: true
    mail:
      from: library-noreply@example.com
      subject-template: "Reminder: '${bookTitle}' is overdue"
    retry:
      max-attempts: 3
      delay-seconds: 10
    reminder-days-before-due:
      - 3
      - 1
```

```java
@ConfigurationProperties(prefix = "notifications.overdue")
@Validated
public record OverdueNotificationProperties(
    boolean enabled,

    @NotNull
    Mail mail,

    @DefaultValue Retry retry,

    List<Integer> reminderDaysBeforeDue
) {
    public record Mail(
        @Email String from,
        @NotBlank String subjectTemplate
    ) {}

    public record Retry(
        @DefaultValue("3") int maxAttempts,
        @DefaultValue("10") int delaySeconds
    ) {}
}
```

```java
@SpringBootApplication
@ConfigurationPropertiesScan  // auto-discovers this class, no manual @EnableConfigurationProperties needed
public class LibraryApplication { ... }
```

```java
@Service
@RequiredArgsConstructor
public class OverdueNotificationService {
    private final OverdueNotificationProperties properties;

    public void checkAndNotify(Loan loan) {
        if (!properties.enabled()) return;

        for (int daysBefore : properties.reminderDaysBeforeDue()) {
            // uses properties.mail().subjectTemplate(), properties.retry().maxAttempts(), etc.
        }
    }
}
```

One fully validated, structured, type-safe config object — startup fails immediately and clearly if `mail.from` isn't a valid email, rather than silently sending malformed emails in production three weeks later.

---

## Quick Summary

1. `@ConfigurationProperties` **binds** a whole prefixed group of properties into one structured object — vs. `@Value` which injects one property at a time
2. **Relaxed binding** lets `kebab-case` (files), `SCREAMING_SNAKE_CASE` (env vars), and `camelCase` (Java) all resolve to the same property — this is exactly why Docker environment variables just work
3. `@Validated` + Bean Validation annotations = **fail-fast startup** on bad config, instead of a silent runtime landmine later
4. Handles nested objects, lists, and maps naturally — cases `@Value` genuinely cannot express
5. Prefer **records** with `@DefaultValue` over old-style mutable classes with setters — less boilerplate, immutable, fails fast on missing required values
6. Use `@ConfigurationProperties` once you have 3+ related settings or any nested structure; reach for `@Value` only for a true one-off



[[0 - Spring Framework]]