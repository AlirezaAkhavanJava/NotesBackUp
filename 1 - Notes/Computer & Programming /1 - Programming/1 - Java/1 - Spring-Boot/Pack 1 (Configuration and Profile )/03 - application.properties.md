

`application.properties` is a plain text file of `key=value` lines that Spring Boot reads at startup. It holds the settings that change from one machine to another, such as the port, the database URL and the log level. Spring uses them to configure your beans before your own code runs.

The idea behind it is called **externalized configuration**: keep _what varies between environments_ (your laptop, staging, production) out of _what the code does_. You build one JAR and give it a different settings file per environment, with no recompiling.

---

## The mental model: one big lookup table

Forget Spring for a moment. The file is just key-value pairs:

```properties
server.port=8081
app.name=MyStore
```

Spring loads these into an object called the **`Environment`**, a lookup table that merges many sources: this file, OS environment variables, command-line arguments and more. Everything else (auto-configuration, `@Value`, `@ConfigurationProperties`) just asks the `Environment` for a key and gets a value back.

---

## Where Spring looks for the file

|Location|Priority|
|---|---|
|`./config/` next to where you run the app|highest|
|`./` the current directory||
|`classpath:/config/`||
|`classpath:/` (`src/main/resources`)|lowest|

You'll almost always use `src/main/resources/application.properties`. It's packaged inside the JAR, so it's always found. Files placed outside the JAR override it, which is how you change settings on a server without rebuilding.

---

## Keys Boot already understands

```properties
server.port=8081
spring.application.name=inventory-service

spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=${DB_PASSWORD}

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

logging.level.root=INFO
logging.level.com.example.myapp=DEBUG
```

You don't write any code for these to work. Boot ships a class for each prefix that collects the matching keys:

```java
@ConfigurationProperties(prefix = "spring.datasource")
public class DataSourceProperties {
    private String url;
    private String username;
    private String password;
    // getters and setters
}
```

Spring takes every key starting with `spring.datasource.`, strips the prefix, and calls the matching setter. `spring.datasource.url` becomes `setUrl(...)`. That is the whole mechanism, and it's why property names are so predictable: `spring.jpa.*`, `spring.kafka.*` and `server.*` each map to a class like this.

A note on `ddl-auto=update`: it's convenient while learning, but don't use it in production. Use a migration tool such as Flyway there.

---

## Reading your own properties

You have two tools. Here is the same setting both ways.

```properties
app.upload.max-size-mb=25
app.upload.allowed-types=jpg,png,pdf
app.upload.storage.bucket=my-bucket
```

**`@Value`** injects one value:

```java
@Value("${app.upload.max-size-mb}")
private int maxSizeMb;

@Value("${app.feature.dark-mode:false}")   // after the colon: default if missing
private boolean darkMode;
```

Line by line: `${...}` is placeholder syntax, which Spring resolves against the `Environment`, and the `:false` is the fallback. It's fine for one or two values. With more, you end up with string keys scattered everywhere, no autocomplete and no compile-time checking.

**`@ConfigurationProperties`** binds a whole group to a class:

```java
@ConfigurationProperties(prefix = "app.upload")
public record UploadProperties(
        int maxSizeMb,
        List<String> allowedTypes,
        Storage storage) {

    public record Storage(String bucket, String region) {}
}
```

Register it by putting `@ConfigurationPropertiesScan` on your main class, or `@EnableConfigurationProperties(UploadProperties.class)` on a configuration class. Then inject it like any bean:

```java
@Service
public class UploadService {
    private final UploadProperties props;
    public UploadService(UploadProperties props) { this.props = props; }
}
```

What Spring does for you:

- `maxSizeMb` matches `max-size-mb`. This is **relaxed binding**: camelCase, kebab-case and `MAX_SIZE_MB` all map to the same field. Write kebab-case in the file, since it's the standard.
- `allowedTypes` is a `List`, so `jpg,png,pdf` is split automatically.
- `storage` is nested, so `app.upload.storage.bucket` goes into `Storage.bucket`.
- A bad value (`max-size-mb=abc`) fails at startup with a clear binding error. That's good: you want to find out now, not at 2am.

Add `spring-boot-configuration-processor` and your IDE will autocomplete your custom keys too.

**Which to choose?** Use `@ConfigurationProperties` for anything grouped or reused, and `@Value` for a quick one-off.

---

## Profiles: different settings per environment

Create one extra file per environment:

```text
src/main/resources/
├── application.properties         ← always loaded
├── application-dev.properties     ← added when profile "dev" is active
└── application-prod.properties    ← added when profile "prod" is active
```

```properties
# application.properties
logging.level.root=INFO

# application-prod.properties
spring.datasource.url=jdbc:postgresql://prod-db:5432/inventory
logging.level.root=WARN
```

Activate a profile at launch, so "prod" is never baked into a file:

```bash
java -jar app.jar --spring.profiles.active=prod
```

The profile file is **layered on top** of the base file. Keys it defines override the base, and everything else stays. Nothing gets replaced wholesale.

Profiles also work in the other direction: `@Profile("dev")` on a bean decides whether that _bean exists_. Profile files change _values_, and `@Profile` changes _which beans are created_.

---

## Precedence: who wins when a key appears twice?

The rule of thumb: **the closer a setting is to the running process, the higher its priority.** From strongest to weakest:

1. Command-line arguments (`--server.port=9090`)
2. Java system properties (`-Dserver.port=9090`)
3. OS environment variables (`SERVER_PORT=9090`)
4. Profile files outside the JAR, then inside the JAR
5. `application.properties` outside the JAR, then inside the JAR
6. `@PropertySource` and `SpringApplication.setDefaultProperties`

(The full official list has a few more rare entries, such as JNDI and servlet parameters, between these.)

This is why you can change one setting in a Docker container without rebuilding the image: `-e SERVER_PORT=9090` beats the file. Spring maps `SERVER_PORT` to `server.port` on its own (uppercase and underscores become lowercase and dots).

---

## Gotchas

- **Empty is not missing.** `${app.name:Default}` uses the default only if the key is absent. If the file has `app.name=` (blank), you get an empty string.
- **Never commit secrets.** Reference an environment variable instead: `spring.datasource.password=${DB_PASSWORD}`. The real password then lives only outside your repo.
- **YAML is the same thing with nesting.** `application.yml` writes `app:` then `upload:` then `max-size-mb: 25` as indented levels. It fills the same `Environment`. Pick one format per project. If a key appears in both, `.properties` wins.
- **One YAML file can hold several profiles**, separated by `---` (Boot 2.4+). It's handy for small projects and harder to read for big ones.

---

## Related concept in short

**`Environment`** is the merged lookup table described above. You can inject it (`Environment env`) and call `env.getProperty("app.name")`, but `@Value` and `@ConfigurationProperties` are usually nicer.





[[Spring Framework]]