
# `@PropertySource` — Full Tutorial

We've used `application.properties` throughout this series without explaining how Spring actually discovers and loads it, or what to do when you need config from _somewhere else_. `@PropertySource` is that mechanism made explicit — worth understanding properly, because it explains a lot of "why does Spring know about this file" that's otherwise invisible.

---

## 1. The Core Idea — Property Sources Are Just Ranked Layers

Spring doesn't read `application.properties` because it's magic — it reads it because Spring Boot **auto-configures** it as one of several **property sources**, each of which is just a named collection of key-value pairs, layered with a priority order. `@PropertySource` is how _you_ add another layer to that stack, explicitly.

Think of it like CSS specificity: multiple sources can define the same property, and Spring resolves conflicts by a strict precedence order — highest wins.

```
Command-line args              ← highest priority
Environment variables
application-{profile}.properties
application.properties
@PropertySource-loaded files    ← what we're covering today
@Value default values           ← lowest priority
```

This matters practically: if you're ever confused why a property "isn't taking effect," 9 times out of 10 it's because a higher-priority source is silently overriding the one you edited.

---

## 2. Why `@PropertySource` Exists at All

`application.properties` is auto-loaded by Spring Boot's own conventions — you never had to ask for it. So why would you need `@PropertySource`?

**Because Spring Boot only auto-loads `application.properties`/`application.yml` by convention. Anything outside that convention — a custom-named file, a file in a non-standard location, or config specific to one particular module — needs to be loaded explicitly.**

Common real scenarios:

- Legacy config file with a different name (`db-config.properties`) you don't want to merge into the main file
- A library or module you're building that ships its own default config, separate from the consuming app's
- Splitting config by concern (`messages.properties`, `feature-flags.properties`) for organizational clarity, without cramming everything into one file

---

## 3. Basic Usage — Loading a Custom Properties File

```properties
# src/main/resources/mail-config.properties
mail.host=smtp.example.com
mail.port=587
mail.from=noreply@library.example.com
```

```java
@Configuration
@PropertySource("classpath:mail-config.properties")
public class MailConfig {
}
```

Once this `@Configuration` class is picked up by component scanning (remember — scanning starts from `LibraryApplication.java` and goes downward, from our Maven Structure tutorial), Spring loads `mail-config.properties` into the environment. Now these properties are usable anywhere via `@Value`:

```java
@Service
public class NotificationService {
    @Value("${mail.host}")
    private String mailHost;

    @Value("${mail.port}")
    private int mailPort;
}
```

Or bound into a strongly-typed config object — the more idiomatic Spring Boot pattern:

```java
@ConfigurationProperties(prefix = "mail")
public record MailProperties(String host, int port, String from) {}
```

```java
@Configuration
@PropertySource("classpath:mail-config.properties")
@EnableConfigurationProperties(MailProperties.class)
public class MailConfig {
}
```

```java
@Service
@RequiredArgsConstructor
public class NotificationService {
    private final MailProperties mailProperties;
    // mailProperties.host(), mailProperties.port(), mailProperties.from()
}
```

**Why prefer `@ConfigurationProperties` over scattered `@Value`:** type safety (port is genuinely an `int`, not a string you parse manually), IDE autocomplete, and one object to inject instead of five separate `@Value` fields. `@Value` is fine for a one-off; `@ConfigurationProperties` is the right tool once you have a _group_ of related settings — which is almost always the real-world case.

---

## 4. `classpath:` vs `file:` — Where the File Actually Lives

The prefix in `@PropertySource` tells Spring **how** to resolve the path — this trips people up if they don't understand Java's classpath concept.

|Prefix|Resolves to|Example use|
|---|---|---|
|`classpath:`|Inside your packaged jar (or `src/main/resources` during dev)|Config bundled with your app|
|`file:`|An absolute or relative filesystem path, outside the jar|Config that lives on the deployment server, not shipped in the build|

```java
@PropertySource("classpath:mail-config.properties")      // bundled with the app
@PropertySource("file:/etc/library-app/secrets.properties") // external, on the server
```

**Why this distinction matters practically:** anything with `classpath:` gets baked into your jar at build time — fine for defaults, wrong for secrets or per-environment values (a database password shouldn't be _inside_ the jar you build once and deploy everywhere). `file:` points outside the jar entirely, letting the same built artifact behave differently depending on what's present on each server — directly connects back to the "configuration, not hardcoding" NFR principle from our Requirements Engineering tutorial, way back at the start of this series.

---

## 5. Loading Multiple Files — `@PropertySources`

```java
@Configuration
@PropertySources({
    @PropertySource("classpath:mail-config.properties"),
    @PropertySource("classpath:feature-flags.properties")
})
public class AppConfig {
}
```

In modern Java (with repeatable annotations), you can actually skip the wrapper and just repeat `@PropertySource` directly:

```java
@Configuration
@PropertySource("classpath:mail-config.properties")
@PropertySource("classpath:feature-flags.properties")
public class AppConfig {
}
```

Both are equivalent — the wrapper form is only needed for compatibility with pre-Java 8 annotation processing, which is irrelevant to you on Java 21, but you'll see the wrapped form in older codebases/tutorials.

---

## 6. A Sharp Gotcha — `@PropertySource` Does NOT Support `.yml`

This is the single most common frustration people hit: **`@PropertySource` only understands `.properties` files by default — not YAML.**

```java
// ❌ This silently does NOT work — YamlPropertySourceFactory not applied
@PropertySource("classpath:mail-config.yml")
```

Spring Boot's _auto-loading_ of `application.yml` works because Spring Boot itself wires in special YAML-handling logic behind the scenes — but `@PropertySource` is a **plain Spring Framework** annotation (older, more general-purpose than Spring Boot), and plain Spring never learned to parse YAML.

### The fix — a custom `PropertySourceFactory`

```java
public class YamlPropertySourceFactory implements PropertySourceFactory {
    @Override
    public PropertySource<?> createPropertySource(String name, EncodedResource resource) throws IOException {
        YamlPropertiesFactoryBean factory = new YamlPropertiesFactoryBean();
        factory.setResources(resource.getResource());
        Properties properties = factory.getObject();
        return new PropertiesPropertySource(resource.getResource().getFilename(), properties);
    }
}
```

```java
@Configuration
@PropertySource(value = "classpath:mail-config.yml", factory = YamlPropertySourceFactory.class)
public class MailConfig {
}
```

**Practical guidance:** unless you specifically need this, just use `.properties` for anything you load via `@PropertySource` — it's the path of least resistance. Reserve `.yml` for your main `application.yml`, which Spring Boot already handles natively without any of this ceremony.

---

## 7. Ignoring a Missing File Gracefully

By default, if the file in `@PropertySource` doesn't exist, **Spring Boot fails to start** — a `FileNotFoundException` during context initialization. Sometimes that's exactly what you want (fail fast on missing required config). Sometimes it isn't — e.g., an optional override file that only exists in certain environments:

```java
@PropertySource(value = "classpath:optional-overrides.properties", ignoreResourceNotFound = true)
```

Now a missing file is silently skipped rather than crashing the app — use this deliberately, not as a default habit, since silently missing config can also hide real misconfigurations.

---

## 8. Property Placeholders — Referencing One Property Inside Another

Properties can reference each other:

```properties
# mail-config.properties
mail.host=smtp.example.com
mail.port=587
mail.url=https://${mail.host}:${mail.port}
```

```java
@Value("${mail.url}")
private String mailUrl;
// resolves to: https://smtp.example.com:587
```

For this resolution to actually happen, Spring needs a `PropertySourcesPlaceholderConfigurer` bean — Spring Boot registers this automatically for you, so in a Boot app it just works; in plain Spring Framework (no Boot), you'd need to declare it explicitly. Worth knowing this bean exists, since you'll see it mentioned in older Spring (pre-Boot) tutorials as something you had to wire up by hand.

---

## 9. Profile-Specific `@PropertySource`

Combine with `@Profile` to load different files per environment — connects directly to the `application-dev.properties` / `application-prod.properties` pattern from our Maven Project Structure tutorial, but generalized to arbitrary custom files:

```java
@Configuration
@Profile("dev")
@PropertySource("classpath:mail-config-dev.properties")
public class DevMailConfig {
}

@Configuration
@Profile("prod")
@PropertySource("classpath:mail-config-prod.properties")
public class ProdMailConfig {
}
```

Only the config class matching the **active profile** (`spring.profiles.active=dev`) gets instantiated — meaning only its `@PropertySource` actually loads. This is a clean way to keep environment-specific config _files_ fully separate, not just environment-specific _values_ within one file.

---

## 10. `@PropertySource` vs. Just Adding to `application.properties` — When to Actually Use It

Given that `application.properties` already auto-loads, when do you genuinely reach for `@PropertySource` instead of just adding keys there?

|Situation|Use|
|---|---|
|App-wide config, no strong reason to separate|`application.properties`|
|Config logically tied to one specific module/library, not the whole app|`@PropertySource` on that module's `@Configuration`|
|Building a reusable library that ships its own defaults for consumers to override|`@PropertySource` — keeps your library self-contained|
|Legacy file you're migrating gradually, don't want a giant merge|`@PropertySource`, temporarily|
|Secrets/environment-specific values on the deployment server|`@PropertySource("file:...")` or, more commonly today, environment variables|

**Honest practical take:** in most everyday Spring Boot apps — including the Library app we've built conceptually throughout this whole series — you'll rarely need `@PropertySource` explicitly. `application.properties` (plus profile-specific variants) covers the vast majority of real needs. `@PropertySource` earns its place specifically in **multi-module projects** (remember the `library-domain`/`library-persistence`/`library-api` split from the Maven Structure tutorial) where each module might reasonably want its own isolated config, or when integrating a legacy/third-party file you don't control the format of.

---

## 11. Full Worked Example — Tying It Into the Library App

```
library-api/src/main/resources/
├── application.properties          ← main config, auto-loaded
└── mail-notifications.properties    ← module-specific, needs @PropertySource
```

```properties
# mail-notifications.properties
notifications.overdue.enabled=true
notifications.overdue.mail.from=library-noreply@example.com
notifications.overdue.mail.subject-template=Reminder: '${bookTitle}' is overdue
```

```java
@ConfigurationProperties(prefix = "notifications.overdue")
public record OverdueNotificationProperties(
    boolean enabled,
    Mail mail
) {
    public record Mail(String from, String subjectTemplate) {}
}
```

```java
@Configuration
@PropertySource("classpath:mail-notifications.properties")
@EnableConfigurationProperties(OverdueNotificationProperties.class)
public class NotificationConfig {
}
```

```java
@Service
@RequiredArgsConstructor
public class OverdueNotificationService {
    private final OverdueNotificationProperties properties;

    public void notifyIfEnabled(Loan loan) {
        if (!properties.enabled()) return;
        // build and send using properties.mail().from(), etc.
    }
}
```

This keeps the whole "overdue notification" feature's config **physically separate** from the rest of `application.properties` — a deliberate organizational choice, following exactly the same "package-by-feature" instinct from our Project Architecture tutorial, applied to configuration instead of code.

---

## Quick Summary

1. `@PropertySource` explicitly loads a custom properties file into Spring's environment — needed because Spring Boot only _auto-loads_ `application.properties`/`.yml` by convention, nothing else
2. Precedence: command-line args > env vars > `application-{profile}.properties` > `application.properties` > `@PropertySource` files > `@Value` defaults
3. `classpath:` = bundled inside your jar; `file:` = external, read from the deployment server at runtime — critical distinction for secrets/per-environment config
4. **`@PropertySource` does not support `.yml` out of the box** — needs a custom `PropertySourceFactory`, or just use `.properties` for anything loaded this way
5. Prefer binding into `@ConfigurationProperties` records over scattering individual `@Value` fields — type-safe, groups related settings
6. In practice, most Spring Boot apps rarely need this explicitly — it earns its place in multi-module projects or when isolating a specific feature's/library's config

---




[[0 - Spring Framework]]