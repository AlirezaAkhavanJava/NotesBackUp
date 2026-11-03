

`@PropertySource` is an annotation that tells Spring to load an extra properties file and add its keys to the app's settings. You put it on a `@Configuration` class and give it a path, such as `classpath:mail-config.properties`.

You need it because Spring Boot only loads `application.properties` and `application.yml` automatically. Any other file, such as a custom name, a file outside the JAR, or a feature's own settings, has to be loaded explicitly. This note covers how to do that, what goes wrong, and when Boot's newer alternative is the better choice.

---

## Where it sits among your settings

Spring doesn't read `application.properties` by magic. It keeps a stack of named **property sources**, each one a set of key-value pairs, and when the same key appears twice, the higher source wins. `@PropertySource` adds one more layer, and it lands near the **bottom**:

```text
Command-line arguments              ← strongest
Environment variables
application-{profile}.properties
application.properties
@PropertySource files               ← weaker than all of the above
```

That has a practical consequence. If a key from your `@PropertySource` file "isn't taking effect," check whether `application.properties`, an environment variable or a command-line argument is overriding it. Nine times out of ten, that's the reason.

(`@Value("${x:default}")` isn't a layer. The text after the colon is only a fallback when no layer has the key.)

---

## Basic usage

```properties
# src/main/resources/mail-config.properties
mail.host=smtp.example.com
mail.port=587
mail.from=noreply@library.example.com
```

```java
@Configuration
@PropertySource("classpath:mail-config.properties")
public class MailConfig {}
```

Line by line:

- `@Configuration` makes this class something Spring processes. Your main class's component scan finds it.
- `@PropertySource` loads the file into the `Environment`, so its keys are now available everywhere.

Read the values with `@Value`:

```java
@Value("${mail.host}") private String mailHost;
@Value("${mail.port}") private int mailPort;
```

Or, better for a group of related settings, bind them to one record:

```java
@ConfigurationProperties(prefix = "mail")
public record MailProperties(String host, int port, String from) {}
```

```java
@Configuration
@PropertySource("classpath:mail-config.properties")
@EnableConfigurationProperties(MailProperties.class)
public class MailConfig {}
```

The two annotations do different jobs. `@PropertySource` _loads the file_, and `@EnableConfigurationProperties` _registers the record_, which then reads from the loaded values. (`@ConfigurationPropertiesScan` on your main class works instead of the second one.)

---

## `classpath:` versus `file:`

|Prefix|Resolves to|Use it for|
|---|---|---|
|`classpath:`|Inside your JAR (`src/main/resources` while developing)|Defaults that ship with the app|
|`file:`|A path on the machine's disk, outside the JAR|Settings that live on the server|

```java
@PropertySource("classpath:mail-config.properties")
@PropertySource("file:/etc/library-app/secrets.properties")
```

Anything under `classpath:` is baked into the JAR at build time. That's fine for defaults and wrong for secrets, because you build the JAR once and deploy it everywhere. `file:` reads from the server at runtime, so the same JAR can behave differently per machine. A relative `file:` path is relative to the folder where you start the app.

---

## Several files

```java
@Configuration
@PropertySource("classpath:mail-config.properties")
@PropertySource("classpath:feature-flags.properties")
public class AppConfig {}
```

You can repeat the annotation directly. The older wrapper form, `@PropertySources({ ... })`, does the same thing, and you'll see it in older code.

---

## Gotchas

### 1. It doesn't understand YAML

`@PropertySource` is a plain Spring Framework annotation, and plain Spring only parses `.properties` files. Spring Boot's own `application.yml` support is separate.

```java
// Wrong: the YAML text is read as if it were a .properties file
@PropertySource("classpath:mail-config.yml")
```

The file is read as properties, so the keys come out wrong or the load fails. Two fixes:

- Use `.properties` for anything loaded this way.
- Or add a custom factory:

```java
public class YamlPropertySourceFactory implements PropertySourceFactory {
    @Override
    public PropertySource<?> createPropertySource(String name, EncodedResource resource) {
        YamlPropertiesFactoryBean factory = new YamlPropertiesFactoryBean();
        factory.setResources(resource.getResource());
        return new PropertiesPropertySource(
                resource.getResource().getFilename(), factory.getObject());
    }
}

@PropertySource(value = "classpath:mail-config.yml",
                factory = YamlPropertySourceFactory.class)
```

In a Boot app, there's a much easier route for YAML. See `spring.config.import` below.

### 2. It loads too late for Boot's own settings

`@PropertySource` is processed while Spring builds your beans, which happens _after_ Boot has already read some settings. So keys such as `server.port`, `logging.*` and `spring.datasource.*` won't take effect from a `@PropertySource` file. Put those in `application.properties` instead.

### 3. A missing file stops the app

By default, a missing file fails startup. That's often what you want, because missing required config should be loud. For a genuinely optional file:

```java
@PropertySource(value = "classpath:optional-overrides.properties",
                ignoreResourceNotFound = true)
```

Use it deliberately. It can hide a real misconfiguration.

### 4. Non-ASCII text can come out garbled

Properties files are read as ISO-8859-1 by default. If your file has accented or non-Latin characters, say so:

```java
@PropertySource(value = "classpath:messages-config.properties", encoding = "UTF-8")
```

---

## Properties that reference other properties

```properties
mail.host=smtp.example.com
mail.port=587
mail.url=https://${mail.host}:${mail.port}
```

`@Value("${mail.url}")` resolves to `https://smtp.example.com:587`. In Spring Boot this just works. In plain Spring with no Boot, you must declare the resolver yourself, as a `static` bean:

```java
@Bean
public static PropertySourcesPlaceholderConfigurer placeholderConfigurer() {
    return new PropertySourcesPlaceholderConfigurer();
}
```

The reverse is also true. **Any `${...}` in a value is treated as a reference.** To keep literal template text such as a book title placeholder, use a different syntax, like `{bookTitle}`, or Spring will try to resolve it and fail.

---

## A different file per profile

```java
@Configuration
@Profile("dev")
@PropertySource("classpath:mail-config-dev.properties")
public class DevMailConfig {}

@Configuration
@Profile("prod")
@PropertySource("classpath:mail-config-prod.properties")
public class ProdMailConfig {}
```

Only the config class matching the active profile is processed, so only its file loads. This is useful for _custom-named_ files. For the standard names, `application-{profile}.properties` already does this with no code.

---

## The Boot alternative: `spring.config.import`

Since Boot 2.4 you can load an extra file straight from `application.properties`:

```properties
spring.config.import=classpath:mail-notifications.yml,optional:file:./local.properties
```

Compared with `@PropertySource`:

||`@PropertySource`|`spring.config.import`|
|---|---|---|
|Works with YAML|No (needs a custom factory)|Yes|
|Loads early enough for `server.*`, `logging.*`|No|Yes|
|Optional file|`ignoreResourceNotFound = true`|`optional:` prefix|
|Where you write it|Java annotation|A properties file|
|Works without Boot|Yes|No|

In a Boot app, `spring.config.import` is usually the better choice. `@PropertySource` still matters when you work in plain Spring or in a shared library that shouldn't depend on Boot.

---

## When to actually use `@PropertySource`

|Situation|Use|
|---|---|
|App-wide settings|`application.properties`|
|Settings that belong to one module or library|`@PropertySource` on that module's `@Configuration`|
|A library that ships its own defaults|`@PropertySource`, so the library stays self-contained|
|A legacy file you're migrating gradually|`@PropertySource` (or `spring.config.import`)|
|Secrets on a server|Environment variables, or `file:`|

Most Spring Boot apps rarely need it explicitly. It earns its place in multi-module projects and when you must load a file you don't control.

---

## All together: one feature's settings in its own file

```properties
# mail-notifications.properties
notifications.overdue.enabled=true
notifications.overdue.mail.from=library-noreply@example.com
notifications.overdue.mail.subject-template=Reminder: {bookTitle} is overdue
```

```java
@ConfigurationProperties(prefix = "notifications.overdue")
public record OverdueNotificationProperties(boolean enabled, Mail mail) {
    public record Mail(String from, String subjectTemplate) {}
}

@Configuration
@PropertySource("classpath:mail-notifications.properties")
@EnableConfigurationProperties(OverdueNotificationProperties.class)
public class NotificationConfig {}

@Service
@RequiredArgsConstructor
public class OverdueNotificationService {
    private final OverdueNotificationProperties properties;

    public void notifyIfEnabled(Loan loan) {
        if (!properties.enabled()) return;
        // use properties.mail().from(), etc.
    }
}
```

The feature's settings live in their own file, away from the rest of `application.properties`.

---

## Related concept in short

**`Environment`** is the object that holds all these layers together. `@PropertySource` adds a layer to it, and `@Value`, `@ConfigurationProperties` and `env.getProperty("mail.host")` all read from it.

---

## Test yourself

1. `mail.port=587` is in your `@PropertySource` file, and `MAIL_PORT=2525` is set as an environment variable. Which value does `@Value("${mail.port}")` get, and why?
2. You put `server.port=9090` in a `@PropertySource` file, but the app still starts on 8080. Why?
3. You write `@PropertySource("classpath:config.yml")`. What happens, and what are two ways to fix it?





[[Spring Framework]]