

A **profile** is a name you attach to a running Spring app, such as `dev`, `test` or `prod`. Spring uses that name for two jobs: it decides which extra `application-{profile}.properties` file gets layered on top of your base settings, and it decides which beans get created at all.

This lets one built JAR behave differently on your laptop, in your tests and in production, with no code changes and no `if (env.equals("prod"))` checks scattered through your business logic. You pick the mode when you launch the app, and Spring does the rest.

---

## Two tools for two different problems

The most useful thing to learn first is which tool fits which problem.

|You need...|Use|
|---|---|
|The **same bean with different values** (a URL, a log level)|`application-{profile}.properties`|
|**Different beans** (a fake vs a real implementation), or a bean that should exist only in some environments|`@Profile`|

Here is a case for `@Profile`. In dev you want an email sender that only prints to the console. In prod you want one that calls a real email API. They are two different classes behind one interface:

```java
public interface EmailSender {
    void send(String to, String subject, String body);
}

@Component
@Profile("dev")
public class ConsoleEmailSender implements EmailSender {
    private static final Logger log = LoggerFactory.getLogger(ConsoleEmailSender.class);

    public void send(String to, String subject, String body) {
        log.info("[DEV] would send to {}: {}", to, subject);
    }
}

@Component
@Profile("prod")
public class SendGridEmailSender implements EmailSender {
    public void send(String to, String subject, String body) {
        // real API call
    }
}
```

Any service that injects `EmailSender` has no idea which one it got. Only one of the two beans exists in a given run, so injection is never ambiguous.

---

## Activating a profile

All of these set the same thing. Pick whichever fits where you're running:

```bash
# Command line
java -jar app.jar --spring.profiles.active=prod

# Environment variable (the usual choice in Docker and servers)
SPRING_PROFILES_ACTIVE=prod java -jar app.jar

# Maven, for local development
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

```properties
# application.properties (fine for a local default, but don't rely on it for prod)
spring.profiles.active=dev
```

```yaml
# docker-compose.yml
services:
  backend:
    environment:
      SPRING_PROFILES_ACTIVE: prod
```

Command-line arguments and environment variables beat the value in `application.properties`. So the same JAR can be launched in any mode without being edited. That is the "build once, deploy anywhere" idea.

---

## Profile files: layered, not replaced

```text
src/main/resources/
├── application.properties         ← always loaded (shared defaults)
├── application-dev.properties     ← added when "dev" is active
├── application-test.properties    ← added when "test" is active
└── application-prod.properties    ← added when "prod" is active
```

```properties
# application.properties
spring.application.name=library-app
spring.jpa.hibernate.ddl-auto=validate
logging.level.root=INFO

# application-dev.properties
spring.datasource.url=jdbc:postgresql://localhost:5432/library
spring.jpa.hibernate.ddl-auto=update
logging.level.root=DEBUG

# application-prod.properties
spring.datasource.url=${DATABASE_URL}
logging.level.root=WARN
```

Read it like this: Spring loads the base file, then the profile file, and the profile file wins on any key they share. In dev you get `ddl-auto=update` and `DEBUG`. In prod you get `ddl-auto=validate` (from the base file) and `WARN`.

Notice that the prod file doesn't contain a real password or URL. It points at an environment variable. The profile file says _which settings apply_, and the environment supplies the _secret values_. Real secrets never go into the JAR or into git.

---

## `@Profile` on classes and methods

On a whole `@Configuration` class, everything inside it is skipped unless the profile is active:

```java
@Configuration
@Profile("dev")
public class DevDataInitializer {
    @Bean
    CommandLineRunner seedData(BookRepository repo) {
        return args -> repo.save(new Book("Effective Java", "Joshua Bloch"));
    }
}
```

This is a common pattern. Fake data gets seeded in dev and can't run against a real database.

On individual `@Bean` methods, it works the same way. Use it when a bean needs constructor arguments or setup that is easier to write in a method:

```java
@Configuration
public class EmailConfig {
    @Bean @Profile("dev")
    EmailSender devSender() { return new ConsoleEmailSender(); }

    @Bean @Profile("prod")
    EmailSender prodSender() { return new SendGridEmailSender(); }
}
```

---

## Profile expressions: `!`, `&`, `|`

```java
@Profile("!prod")                 // every profile except prod
@Profile({"dev", "test"})         // dev OR test
@Profile("prod & eu-region")      // both must be active
@Profile("(dev | test) & !ci")    // mixing & and | requires parentheses
```

**Careful with `!prod`.** It looks safe, but it is a _deny-list_: it matches staging, test, and also the case where **no profile is active at all**. If someone starts the app without setting a profile, a `@Profile("!prod")` data seeder runs. For anything that must never touch real data, the allow-list `@Profile("dev")` is the stricter choice.

---

## The `default` profile and what happens with no profile

If no profile is active, Spring treats the profile name as `default`. Two things follow from that:

- `@Profile("default")` marks a bean that exists _only when nothing else is active_. It's a neat way to provide a fallback.
- If **every** implementation of an interface is profile-gated and you start with no profile, the bean doesn't exist, and startup fails with `NoSuchBeanDefinitionException`. For example, `EmailSender` above has only `dev` and `prod` versions, so running with `staging` fails. Fix it by adding a fallback or activating a profile that has one.

---

## Several profiles at once, and groups

Profiles aren't exclusive. You can combine independent concerns instead of inventing one giant profile per combination:

```properties
spring.profiles.active=prod,eu-region,metrics
```

Here `prod` is the environment, `eu-region` is the deployment region, and `metrics` is a feature switch. Each is controlled separately.

If you always activate the same set together, define a **group** (Boot 2.4+):

```properties
spring.profiles.group.production=prod,eu-region,metrics
```

Now `SPRING_PROFILES_ACTIVE=production` turns on all three.

---

## One YAML file, several profiles

Instead of separate files, you can put every profile in one `application.yml` using `---` separators (Boot 2.4+):

```yaml
spring:
  application:
    name: library-app
---
spring:
  config:
    activate:
      on-profile: dev
  datasource:
    url: jdbc:postgresql://localhost:5432/library
---
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: ${DATABASE_URL}
```

It's handy for small projects. Larger ones are easier to read with one file per profile.

---

## Profiles in tests

```java
@SpringBootTest
@ActiveProfiles("test")
class LoanServiceIntegrationTest { }
```

```properties
# src/test/resources/application-test.properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.jpa.hibernate.ddl-auto=create-drop
```

`@ActiveProfiles("test")` makes the test run with `application-test.properties` layered in and with any `@Profile("test")` beans. A word of caution for you, since you use PostgreSQL: H2 isn't PostgreSQL, so SQL that passes on H2 can fail on the real thing. When you can, use **Testcontainers** to run a real PostgreSQL in the test instead.

---

## Reading the active profile in code

When you need it (rarely), ask the `Environment`:

```java
@Autowired Environment env;

boolean isProd = env.acceptsProfiles(Profiles.of("prod"));
String[] active = env.getActiveProfiles();
```

Don't inject it with `@Value("${spring.profiles.active}")`. That key doesn't exist when no profile is set, so the app crashes at startup.

---

## The big mistake to avoid

Don't branch business rules on the profile name:

```java
// Bad: the service now behaves differently by environment
if (activeProfile.equals("dev")) { /* skip the loan limit */ }
```

This hides environment differences inside your core logic. Do one of these instead:

- Swap a **bean implementation** with `@Profile` (infrastructure differences, such as email or storage).
- Use a **configurable value**: `loan.max-active-loans=3` in the base file and `100` in `application-dev.properties`.

---

## The whole flow in a real deployment

```text
CI builds ONE jar (nothing environment-specific inside)
   → the same jar is deployed to staging and prod
   → each sets SPRING_PROFILES_ACTIVE and secrets (DATABASE_URL...) at launch
   → Spring layers application-{profile}.properties
   → @Profile beans are created or skipped
   → @ConfigurationProperties binds the injected values
```

In real infrastructure (Kubernetes, ECS), secrets typically come from a secrets manager, but they reach Spring the same way: as environment variables.

---

## Related concept in short

**Maven profiles are not Spring profiles.** A Maven profile (`-P prod`) changes how the project is _built_ (dependencies, plugins). A Spring profile (`--spring.profiles.active=prod`) changes how the app _runs_. They share a name and nothing else, and beginners mix them up often.

---

## Test yourself

1. You mark a data seeder `@Profile("!prod")` and start the app with no profile set. Does it run, and why?
2. `application.properties` has `logging.level.root=INFO`, and `application-prod.properties` has `logging.level.root=WARN` and a new key `x=1`. With `prod` active, what are the final values?
3. You have `@Profile("dev")` and `@Profile("prod")` email senders, and you start with the profile `staging`. What happens?

---

[[Spring Framework]]