

`@Profile` is an annotation that says "only create this bean when this profile is active." If the profile doesn't match, Spring never registers the bean at all. Its constructor never runs, and it never takes up memory.

This is how you keep one interface with several implementations, such as a fake payment service for development and a real one for production, and let Spring pick the right one for the environment. The code that _uses_ the interface never changes and never knows which version it got.

---

## What happens at startup

Understanding the order of events explains every rule in this note.

```text
1. Spring reads the active profile(s)        (property, env var, command line)
2. It finds your bean classes and @Bean methods
3. For each one it asks: is there an @Profile?
      no @Profile        → register the bean
      @Profile matches   → register the bean
      @Profile no match  → skip it. The bean never exists.
4. Only registered beans get created (constructors run, dependencies injected)
```

The filtering happens at step 3, before anything is built. So a `prod`-only bean in a `dev` run isn't "turned off". It was never a candidate. That's why trying to inject it in dev fails at startup instead of giving you a `null` at runtime. Failing early like this is what you want.

---

## Three places to put `@Profile`

|Put it on...|Use it when|
|---|---|
|A `@Component` / `@Service` class|It's your own class and the whole class belongs to one profile|
|A `@Bean` method|The bean needs custom construction, or you can't edit the class|
|A `@Configuration` class|Everything inside belongs to one profile|

### 1. On a stereotype class

```java
@Service
@Profile("dev")
public class MockPaymentService implements PaymentService {
    public void charge(BigDecimal amount) {
        log.info("[DEV] pretending to charge {}", amount);
    }
}

@Service
@Profile("prod")
public class StripePaymentService implements PaymentService {
    public void charge(BigDecimal amount) { stripeClient.createCharge(amount); }
}
```

With `dev` active, only `MockPaymentService` is registered. Anything that injects `PaymentService` gets it without knowing which one it is.

### 2. On a `@Bean` method

```java
@Configuration
public class PaymentConfig {

    @Bean
    @Profile("dev")
    public PaymentService mockPaymentService() {
        return new MockPaymentService();
    }

    @Bean
    @Profile("prod")
    public PaymentService stripePaymentService(@Value("${stripe.api-key}") String apiKey) {
        return new StripePaymentService(new StripeClient(apiKey));
    }
}
```

Line by line:

- Each method is gated on its own. The `PaymentConfig` class is always processed, but only the matching method registers a bean.
- `stripePaymentService` needs an API key from configuration. Doing that in a `@Bean` method keeps `StripePaymentService` a plain Java class with no Spring annotations, which makes it easy to unit test.

### 3. On a whole `@Configuration` class

```java
@Configuration
@Profile("dev")
public class DevDataSeeder {
    @Bean
    CommandLineRunner seedBooks(BookRepository repo) {
        return args -> repo.save(new Book("Effective Java", "Joshua Bloch"));
    }

    @Bean
    CommandLineRunner seedMembers(MemberRepository repo) {
        return args -> repo.save(new Member("Test User", "test@example.com"));
    }
}
```

If `dev` isn't active, the **whole class is skipped**, including both `@Bean` methods and any `@Import` or `@ComponentScan` on it. You write `@Profile` once instead of on every method.

---

## Two traps: too many candidates, or none

### Trap 1: two implementations, nothing to choose between them

If both services are plain `@Service` classes with no `@Profile`, startup fails:

```text
NoUniqueBeanDefinitionException: expected single matching bean but found 2:
mockPaymentService, stripePaymentService
```

`@Profile` solves this by making sure only one is a candidate at a time. (`@Primary` and `@Qualifier` also solve it. See the related concept below.)

### Trap 2: no implementation for the active profile

Now the opposite. Your beans are gated on `dev` and `prod`, and you start the app with no profile at all, or with `staging`. Neither bean exists, so whatever injects `PaymentService` fails at startup. You'll see an `UnsatisfiedDependencyException` that wraps a `NoSuchBeanDefinitionException`.

The check to remember: **for every profile you might run, is there exactly one implementation?**

---

## Making sure one implementation always exists

There are two common fixes.

**Option A: a `default` fallback.** When no profile is active, Spring uses a profile called `default`:

```java
@Service
@Profile("default")      // matches only when NO profile is active
public class MockPaymentService implements PaymentService { ... }
```

The catch is that the moment you activate _any_ profile (even `staging`), `default` switches off and the bean disappears.

**Option B: "everything except prod".**

```java
@Service
@Profile("!prod")        // dev, test, staging... and also "no profile set"
public class MockPaymentService implements PaymentService { ... }

@Service
@Profile("prod")
public class StripePaymentService implements PaymentService { ... }
```

This works in every environment, including ones you invent later. It's a good fit for harmless fakes like a console email sender.

**But know the trade-off.** If production is launched and someone forgets to set `SPRING_PROFILES_ACTIVE=prod`, Spring quietly picks the mock. Nothing crashes. Payments just get logged instead of charged. For anything where a silent mistake is costly, prefer plain `@Profile("prod")` and `@Profile("dev")`, so a missing profile fails loudly at startup instead.

A quick way to check which profile is active is the first lines of the startup log:

```text
The following 1 profile is active: "prod"
No active profile set, falling back to 1 default profile: "default"
```

---

## Testing which bean got wired

```java
@SpringBootTest
@ActiveProfiles("dev")
class PaymentServiceProfileTest {

    @Autowired PaymentService paymentService;

    @Test
    void devProfileWiresTheMock() {
        assertThat(paymentService).isInstanceOf(MockPaymentService.class);
    }
}
```

`@ActiveProfiles("dev")` starts the test context with `dev` active. Write one test per profile you rely on, so that a wrong profile setup fails in your build instead of in production.

---

## All together: an `EmailSender`

```java
public interface EmailSender {
    void send(String to, String subject, String body);
}

@Component
@Profile("!prod")
@Slf4j
public class ConsoleEmailSender implements EmailSender {
    public void send(String to, String subject, String body) {
        log.info("[MOCK] To: {} | Subject: {}", to, subject);
    }
}

@Component
@Profile("prod")
@RequiredArgsConstructor
public class SendGridEmailSender implements EmailSender {
    private final SendGridClient client;
    public void send(String to, String subject, String body) {
        client.send(new Email(to, subject, body));
    }
}

@Service
@RequiredArgsConstructor
public class OverdueNotificationService {
    private final EmailSender emailSender;   // doesn't know which one it got
    // ...
}
```

```bash
./mvnw spring-boot:run                          # no profile → "!prod" matches → console sender
SPRING_PROFILES_ACTIVE=prod java -jar app.jar   # prod → SendGrid sender
```

The business class `OverdueNotificationService` is identical in both runs.

---

## Related concept in short

**`@Primary` and `@Qualifier`** also choose between several beans of the same type, but they work differently. `@Primary` marks one bean as the default winner, and `@Qualifier("name")` picks one by name at the injection point. All the candidates still _exist_. `@Profile` decides which beans exist at all, based on the environment. Use `@Profile` for "which implementation for this environment" and `@Qualifier` or `@Primary` for "which of several that are all present."

---



[[Spring Framework]]