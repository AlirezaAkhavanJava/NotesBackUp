

`@ConfigurationProperties` takes every property that starts with a chosen prefix, such as `mail.`, and fills a single typed Java object with them. You get one structured object instead of a handful of separate string lookups, and it can hold nested objects, lists and maps.

Because Spring checks the values while binding, a wrong or missing setting can stop the app at startup with a clear message, instead of failing hours later on some rarely used code path. This is the standard way real Spring Boot apps read their own configuration.

---

## Binding versus injecting

`@Value` injects **one** property into **one** field. `@ConfigurationProperties` binds a **whole prefixed group** at once.

```properties
mail.host=smtp.example.com
mail.port=587
mail.from=noreply@library.example.com
mail.retry.max-attempts=3
mail.retry.delay=10s
```

```java
@ConfigurationProperties(prefix = "mail")
public record MailProperties(
        String host,
        int port,
        String from,
        Retry retry) {

    public record Retry(int maxAttempts, Duration delay) {}
}
```

Line by line:

- `prefix = "mail"` means every key starting with `mail.` goes into this object, with the prefix removed.
- `mail.host` goes into `host`, and `mail.retry.*` goes into the nested `Retry` record.
- `max-attempts` in the file lands in `maxAttempts` in Java. That's **relaxed binding**, explained below.
- `10s` becomes a real `Duration`, which is covered in the conversions section.

A record is bound through its constructor, so it is immutable after binding. In Spring Boot 3 a record with a single constructor needs no extra annotation.

---

## Registering it so Spring knows it exists

Writing the annotation isn't enough. The class also has to be registered as a bean. There are two ways.

|Way|How|Best for|
|---|---|---|
|`@ConfigurationPropertiesScan`|One annotation on your main class. It finds every `@ConfigurationProperties` class under that package.|Most applications|
|`@EnableConfigurationProperties(MailProperties.class)`|You name each class on a `@Configuration` class.|Libraries and modules that control their own registration|

```java
@SpringBootApplication
@ConfigurationPropertiesScan
public class LibraryApplication { ... }
```

```java
@Configuration
@EnableConfigurationProperties(MailProperties.class)
public class MailConfig {}
```

One mistake to avoid: don't also put `@Component` on a record that is bound through its constructor. The scan or the enable annotation is what registers it.

---

## Relaxed binding: one property, several spellings

Spring Boot treats several naming styles as the same property. That means your file, your environment variables and your Java fields can each use their own natural style.

|Where|Accepted forms for `maxAttempts`|
|---|---|
|`.properties` / `.yml` file|`max-attempts` (recommended), `maxAttempts`, `max_attempts`|
|Environment variable|`MAIL_RETRY_MAXATTEMPTS`|

For environment variables the rule is: replace dots with underscores, remove dashes, uppercase it. So `mail.retry.max-attempts` becomes `MAIL_RETRY_MAXATTEMPTS`. That is why `MAIL_RETRY_MAXATTEMPTS=5` in a Docker `environment:` block works with no extra code.

Two tips:

- In files, always write **kebab-case**. It's the standard, and it's the one form that works everywhere.
- `@Value` is much stricter than `@ConfigurationProperties`. For `@Value`, write the key exactly as it appears in the file.

---

## Validation: fail at startup, not at 2am

Add Bean Validation annotations and `@Validated`:

```java
@ConfigurationProperties(prefix = "mail")
@Validated
public record MailProperties(
        @NotBlank String host,
        @Min(1) @Max(65535) int port,
        @Email String from,
        @Valid @NotNull Retry retry) {

    public record Retry(@Min(1) int maxAttempts, @NotNull Duration delay) {}
}
```

If `mail.port=99999`, the app refuses to start and names the property:

```text
Binding to target MailProperties failed:
    Property: mail.port
    Value: "99999"
    Reason: must be less than or equal to 65535
```

Two things trip people up here:

1. **You need the validation starter.** Add `spring-boot-starter-validation` to your `pom.xml`. Without it, the annotations are silently ignored.
2. **Nested objects need `@Valid`.** Without `@Valid` on the `retry` component, the constraints _inside_ `Retry` are never checked.

---

## Structures `@Value` can't express

### Lists

```properties
library.branch-names=Downtown,Uptown,Suburban
```

```yaml
library:
  branch-names:
    - Downtown
    - Uptown
```

```java
@ConfigurationProperties(prefix = "library")
public record LibraryProperties(List<String> branchNames) {}
```

The comma-separated form works for simple lists. The indexed form (`branch-names[0]=Downtown`) is for properties files, and YAML lists are the easiest to read.

### Maps

```yaml
library:
  branch-hours:
    downtown: "9-18"
    uptown: "10-17"
```

```java
public record LibraryProperties(Map<String, String> branchHours) {}
```

### Lists of objects

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

This last case is where `@ConfigurationProperties` isn't just nicer. It's the only practical option.

---

## Defaults and type conversion

**Defaults.** A missing `int` silently becomes `0`, which is easy to confuse with a real `0`. State the default explicitly:

```java
public record MailProperties(
        String host,
        @DefaultValue("587") int port,
        @DefaultValue("noreply@example.com") String from,
        @DefaultValue Retry retry) {          // creates Retry using its own defaults

    public record Retry(
            @DefaultValue("3") int maxAttempts,
            @DefaultValue("10s") Duration delay) {}
}
```

`@DefaultValue` lives in `org.springframework.boot.context.properties.bind`. Put it right next to the field it applies to, so the default is visible at a glance.

**Conversion.** Spring converts text into richer types for you. The two most useful are:

- `Duration`: write `10s`, `5m` or `2h`, instead of a bare number whose unit you have to remember.
- `DataSize`: write `10MB` or `512KB`.

This is why `delay` above is a `Duration` and not a `delaySeconds` integer.

---

## Records versus classic classes

||Record (recommended)|Mutable class with setters|
|---|---|---|
|Boilerplate|None|A getter and a setter per field|
|Mutability|Immutable once bound|Can be changed anywhere|
|Binding|Through the constructor|Through setters|
|Missing values|Visible through defaults and validation|Silently stay `null`|

You'll meet the setter style in older code, so recognize it, but write new properties classes as records. A class with several constructors needs `@ConstructorBinding` on the one Spring should use.

---

## Binding to a class you don't own

You can put `@ConfigurationProperties` on a `@Bean` method to fill a third-party object from your properties:

```java
@Bean
@ConfigurationProperties(prefix = "app.datasource")
public HikariDataSource appDataSource() {
    return new HikariDataSource();
}
```

Spring creates the object, then sets its setters from every `app.datasource.*` key. This uses setter binding, so the class must have setters.

---

## Choosing between the two tools

|Situation|Use|
|---|---|
|One unrelated setting|`@Value`|
|Three or more related settings|`@ConfigurationProperties`|
|You want validation|`@ConfigurationProperties`|
|Nested objects, lists or maps|`@ConfigurationProperties`|
|Used in several classes|`@ConfigurationProperties`|

The key spelled in only one place is a real advantage. With `@Value("${mail.host}")` copied into five classes, a typo in one copy only shows up when that class runs. With one properties record, the key is written once and every class just injects the typed object.

---

## All together: overdue notifications

```yaml
# application.yml
notifications:
  overdue:
    enabled: true
    mail:
      from: library-noreply@example.com
      subject-template: "Reminder: {bookTitle} is overdue"
    retry:
      max-attempts: 3
      delay: 10s
    reminder-days-before-due: [3, 1]
```

```java
@ConfigurationProperties(prefix = "notifications.overdue")
@Validated
public record OverdueNotificationProperties(
        boolean enabled,
        @Valid @NotNull Mail mail,
        @Valid @DefaultValue Retry retry,
        List<Integer> reminderDaysBeforeDue) {

    public record Mail(@Email String from, @NotBlank String subjectTemplate) {}

    public record Retry(
            @DefaultValue("3") @Min(1) int maxAttempts,
            @DefaultValue("10s") Duration delay) {}
}
```

```java
@Service
@RequiredArgsConstructor
public class OverdueNotificationService {
    private final OverdueNotificationProperties properties;

    public void checkAndNotify(Loan loan) {
        if (!properties.enabled()) return;
        // properties.mail().subjectTemplate(), properties.retry().maxAttempts() ...
    }
}
```

The `{bookTitle}` placeholder uses single braces on purpose. Spring would treat `${bookTitle}` as a property reference and fail to start.

---

## Related concept in short

**`spring-boot-configuration-processor`** is a compile-time dependency that reads your properties classes and generates metadata. Your IDE then autocompletes your own keys in `application.properties`, exactly as it does for Spring's built-in ones.



[[Spring Framework]]