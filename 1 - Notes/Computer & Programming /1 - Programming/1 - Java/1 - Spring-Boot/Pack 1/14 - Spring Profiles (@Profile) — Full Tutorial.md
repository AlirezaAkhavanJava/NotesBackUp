
---
## 1. The Core Idea — Profiles Are Named Configuration "Modes"

A **profile** is just a label — `dev`, `test`, `prod`, `staging`, anything you want — that you activate at startup. Spring uses that label to decide:

1. **Which `application-{profile}.properties`/`.yml` file to layer on top of the base config**
2. **Which `@Bean`/`@Component`/`@Configuration` classes to actually instantiate**

Think of it as a runtime `if` statement over your entire application's wiring — but declared with annotations, not scattered `if (env.equals("prod"))` checks throughout your business logic (which would be exactly the kind of hardcoded environment-coupling the whole series has been steering you away from).

---

## 2. Why Profiles Exist — Beyond Just "Different Property Values"

Here's the distinction that separates `@Profile` from what you already know about `@ConfigurationProperties`:

- **Different _values_ for the same bean** → handled by `application-{profile}.properties` (no `@Profile` annotation needed at all — just property overrides)
- **Different _beans entirely_, or beans that should only exist in some environments** → this is where `@Profile` earns its place

Concrete example from our Library domain: in **dev**, you want a fake `EmailSender` that just logs to the console (no real inbox needed, fast iteration). In **prod**, you want a real one that calls SendGrid's API. These aren't the same bean with different property values — they're **entirely different implementations** of the same interface. That's a `@Profile` problem, not a plain-properties problem.

```java
public interface EmailSender {
    void send(String to, String subject, String body);
}
```

```java
@Component
@Profile("dev")
public class ConsoleEmailSender implements EmailSender {
    @Override
    public void send(String to, String subject, String body) {
        log.info("📧 [DEV] Would send to {}: {} — {}", to, subject, body);
    }
}
```

```java
@Component
@Profile("prod")
public class SendGridEmailSender implements EmailSender {
    private final SendGridClient client;

    @Override
    public void send(String to, String subject, String body) {
        client.send(new Email(to, subject, body)); // real API call
    }
}
```

Your `OverdueNotificationService` just injects `EmailSender` — it has **zero idea** which implementation it's getting. This is Dependency Injection doing exactly what it's for: swapping an entire implementation based on environment, with the consuming code completely unaware anything changed.

---

## 3. Activating a Profile

### Via `application.properties`

```properties
spring.profiles.active=dev
```

### Via environment variable (most common in real deployments — connects straight to our Docker Compose tutorial)

```bash
SPRING_PROFILES_ACTIVE=prod java -jar library-app.jar
```

```yaml
# docker-compose.yml
services:
  backend:
    environment:
      SPRING_PROFILES_ACTIVE: prod
```

### Via command-line argument

```bash
java -jar library-app.jar --spring.profiles.active=prod
```

### Via Maven, for local dev convenience

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

**Precedence note (ties back to the layering hierarchy from the `@PropertySource` tutorial):** command-line args and environment variables outrank whatever's written in `application.properties`. This is deliberate — it means the _same jar_, with _nothing changed inside it_, behaves differently purely based on how it's launched. That's the "build once, deploy everywhere" principle made concrete.

---

## 4. Profile-Specific Property Files

Already referenced in earlier tutorials — here's the full mechanics. Spring Boot looks for `application-{profile}.properties` and **layers it on top of** the base `application.properties` (doesn't replace it — merges, with the profile-specific file winning on overlapping keys):

```properties
# application.properties (base — shared defaults)
spring.application.name=library-app
spring.jpa.hibernate.ddl-auto=validate
logging.level.root=INFO
```

```properties
# application-dev.properties
spring.datasource.url=jdbc:postgresql://localhost:5432/library
spring.jpa.hibernate.ddl-auto=update
logging.level.root=DEBUG
logging.level.com.example.library=TRACE
```

```properties
# application-prod.properties
spring.datasource.url=${DATABASE_URL}
logging.level.root=WARN
```

Notice `application-prod.properties` doesn't hardcode the actual database URL — it references `${DATABASE_URL}`, an environment variable, layering **two** mechanisms together: profile-specific files decide _structure_ (which settings apply), while environment variables supply the actual _secret values_. This is the standard real-world pattern — profile files rarely contain literal secrets; they reference where secrets come from.

---

## 5. `@Profile` on Beans and Configuration Classes

### On an entire `@Configuration` class

```java
@Configuration
@Profile("dev")
public class DevDataInitializer {

    @Bean
    CommandLineRunner seedTestData(BookRepository bookRepository) {
        return args -> {
            bookRepository.save(new Book("Effective Java", "Joshua Bloch"));
            bookRepository.save(new Book("Clean Code", "Robert Martin"));
        };
    }
}
```

This entire class — and every bean inside it — only exists when `dev` is active. In `prod`, this class is never even instantiated; Spring skips it entirely during component scanning evaluation. This is a genuinely common real pattern: seed your database with fake books/members automatically in dev, but never risk that logic running against a real production database.

### On individual `@Bean` methods within one config class

```java
@Configuration
public class EmailConfig {

    @Bean
    @Profile("dev")
    EmailSender devEmailSender() {
        return new ConsoleEmailSender();
    }

    @Bean
    @Profile("prod")
    EmailSender prodEmailSender() {
        return new SendGridEmailSender();
    }
}
```

Functionally equivalent to the `@Component`-level `@Profile` shown earlier — which style you pick is mostly about whether the bean is simple enough to be a `@Component` on its own, or needs constructor arguments/setup that's easier to express in an explicit `@Bean` method.

---

## 6. Combining Profiles — `!`, `&`, `|` Expressions

`@Profile` accepts **profile expressions**, not just single names — genuinely useful once you have more than two environments.

```java
@Profile("!prod")              // active in every profile EXCEPT prod
public class DevDataInitializer { }

@Profile({"dev", "test"})       // active if EITHER dev OR test is active (OR logic)
public class MockPaymentGateway { }

@Profile("prod & eu-region")     // active only if BOTH are active (AND logic)
public class GdprComplianceFilter { }
```

**A genuinely useful real pattern:** `@Profile("!prod")` on your test-data seeder is often _safer_ than `@Profile("dev")` — because it fails safe. If someone later adds a new `staging` profile and forgets to explicitly exclude the seeder, `@Profile("dev")` would correctly _not_ run it in staging (good), but `@Profile("!prod")` guarantees it can _never_ accidentally run in prod specifically, regardless of what other profiles get invented later. Worth thinking about which direction your safety margin should point.

---

## 7. Multiple Active Profiles Simultaneously

Profiles aren't mutually exclusive — you can activate several at once, and Spring merges all of their property files and enables all matching beans:

```properties
spring.profiles.active=prod,eu-region,feature-x-enabled
```

This is how larger real systems compose orthogonal concerns — `prod` vs `dev` (environment), `eu-region` vs `us-region` (deployment region, maybe different compliance rules), `feature-x-enabled` (a temporary flag for a gradual rollout) — each controlled independently rather than needing one giant profile per every possible combination (`prod-eu-featurex` would explode combinatorially fast).

---

## 8. Profile Groups (Spring Boot 2.4+) — Reducing Repetition

If you find yourself always activating the same combination together, you can define a **group**:

```properties
# application.properties
spring.profiles.group.production=prod,eu-region,metrics-enabled
```

```bash
SPRING_PROFILES_ACTIVE=production java -jar library-app.jar
# equivalent to: SPRING_PROFILES_ACTIVE=prod,eu-region,metrics-enabled
```

Activating `production` transparently activates all three underlying profiles — a convenience layer once your profile combinations get unwieldy to type/remember correctly every time.

---

## 9. `@ActiveProfiles` in Tests

Directly relevant given the testing focus from our Spring Application Layers tutorial:

```java
@SpringBootTest
@ActiveProfiles("test")
class LoanServiceIntegrationTest {
    // runs with application-test.properties layered in —
    // typically pointing at an in-memory H2 database instead of real PostgreSQL
}
```

```properties
# application-test.properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.jpa.hibernate.ddl-auto=create-drop
```

This is _exactly_ why `src/test/resources/application-test.properties` existed in our Maven Project Structure tutorial, now with the full mechanism behind it explained — tests run fast, in-memory, fully isolated from any real database, purely by activating a different profile.

---

## 10. What This Looks Like in a Real Production Deployment

Pulling this together with the Docker Compose tutorial — here's a realistic, complete picture of profiles in an actual deployed system:

```
library-app/
└── src/main/resources/
    ├── application.properties           ← shared defaults, no secrets
    ├── application-dev.properties        ← localhost DB, DEBUG logging, seed data on
    ├── application-test.properties        ← H2 in-memory, used only by @ActiveProfiles("test")
    └── application-prod.properties         ← references env vars, WARN logging, no seed data
```

```yaml
# docker-compose.prod.yml (a production-oriented compose file)
services:
  backend:
    image: registry.example.com/library-app:1.4.2   # a specific, tagged, tested build
    environment:
      SPRING_PROFILES_ACTIVE: prod
      DATABASE_URL: ${DATABASE_URL}           # injected by the deployment platform/secrets manager
      MAIL_HOST: ${MAIL_HOST}
    ports:
      - "8080:8080"
```

In real production infrastructure (Kubernetes, AWS ECS, etc. — beyond Docker Compose, but the same idea scales up), `SPRING_PROFILES_ACTIVE=prod` and the actual secret values (`DATABASE_URL`, API keys) are typically injected by a **secrets manager** (AWS Secrets Manager, HashiCorp Vault, Kubernetes Secrets) rather than sitting in plain text anywhere — but the _mechanism_ Spring Boot uses to receive them is identical: environment variables, resolved via the same relaxed-binding rules from the `@ConfigurationProperties` tutorial.

### The complete flow, one more time, end to end

```
1. CI/CD builds ONE jar: library-app-1.4.2.jar (no environment baked in)
        │
        ▼
2. That exact jar is deployed to staging AND prod — same artifact, unmodified
        │
        ▼
3. Each environment sets SPRING_PROFILES_ACTIVE differently at launch
   (staging: "staging" / prod: "prod")
        │
        ▼
4. Spring Boot layers application-{profile}.properties on top of the base
        │
        ▼
5. @Profile-annotated beans are conditionally created (real EmailSender, no seed data, etc.)
        │
        ▼
6. @ConfigurationProperties records bind actual environment-injected secret values
        │
        ▼
Same code. Same jar. Completely different runtime behavior.
```

This is genuinely the payoff of the entire configuration chapter of this series — Requirements said "make it configurable," and this is what that principle looks like, fully realized, in a real deployed system.

---

## 11. A Common Beginner Mistake Worth Naming

Putting **business logic branches** inside `@Profile`-gated beans, instead of just swapping _implementations_ of the same interface:

```java
// ❌ Bad — LoanService itself changes behavior based on profile
@Service
public class LoanService {
    @Value("${spring.profiles.active}")
    private String activeProfile;

    public void borrowBook(...) {
        if (activeProfile.equals("dev")) {
            // skip loan limit check for testing
        }
        // ... real logic
    }
}
```

This reintroduces environment-coupling directly into your core business logic — exactly what layering and profiles exist to prevent. If dev genuinely needs different _business rules_ (rare — usually it's infrastructure that differs, not rules), express that as a **configurable value** (`@ConfigurationProperties` — e.g., `loan.max-active-loans=3`, overridden to `100` in `application-dev.properties`), never as an `if` branch checking the profile name directly inside a service class.

---

## Quick Summary

1. Profiles are named modes (`dev`, `test`, `prod`) that control **which property files layer in** and **which beans get created**
2. Use plain `application-{profile}.properties` for different _values_; use `@Profile` on beans/configs when you need different _implementations_ entirely (e.g., `ConsoleEmailSender` vs `SendGridEmailSender`)
3. Activate via `SPRING_PROFILES_ACTIVE` env var (most common in Docker/production) — same jar, different behavior, zero rebuild
4. Profile expressions (`!prod`, `{"dev","test"}`, `"prod & eu-region"`) give you AND/OR/NOT logic across combinations
5. `@ActiveProfiles("test")` is how your test suite gets a fast, isolated, in-memory database instead of touching real infrastructure
6. In real production: one built jar + `SPRING_PROFILES_ACTIVE=prod` + secrets injected via environment variables from a secrets manager — never hardcoded, never baked into the jar
7. Never branch business logic directly on the active profile name — express environment differences as configurable values or swapped bean implementations instead





[[Spring Framework]]