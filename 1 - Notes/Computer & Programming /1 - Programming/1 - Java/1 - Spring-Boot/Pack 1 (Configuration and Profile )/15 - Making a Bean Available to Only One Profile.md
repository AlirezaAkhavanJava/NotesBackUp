


You've seen `@Profile` used in passing across the last tutorial — let's now isolate this one specific technique and cover it completely: every way to scope a bean to exactly one profile, the subtleties around each approach, and the mistakes that bite people in practice.

---

## 1. The Core Mechanism — `@Profile` on a Bean Definition

`@Profile` is a **conditional annotation** — Spring evaluates it during the bean-definition scanning phase (before any beans are actually instantiated) and simply **skips registering** any bean whose `@Profile` doesn't match the active profile(s). The bean doesn't exist "disabled" somewhere — it's never created, never occupies memory, and its constructor never runs.

There are three places you can put `@Profile`, and they behave slightly differently depending on where.

---

## 2. Approach 1 — On a `@Component`/`@Service`/`@Repository` Class Directly

The simplest case — the entire class only gets registered as a bean when its profile is active.

```java
@Service
@Profile("dev")
public class MockPaymentService implements PaymentService {
    @Override
    public void charge(BigDecimal amount) {
        log.info("[DEV] Pretending to charge {}", amount);
    }
}
```

```java
@Service
@Profile("prod")
public class StripePaymentService implements PaymentService {
    @Override
    public void charge(BigDecimal amount) {
        stripeClient.createCharge(amount);
    }
}
```

**What happens at startup, precisely:**

- If `dev` is active → only `MockPaymentService` is registered; `StripePaymentService`'s `@Service` annotation is seen during scanning, but Spring evaluates `@Profile("prod")`, sees it doesn't match, and **skips bean registration entirely**
- Anything that does `@Autowired PaymentService paymentService` gets whichever one _was_ registered — completely transparent to the consumer

This is the exact same mechanism the `EmailSender` example used in the previous tutorial — worth re-stating because it's the pattern you'll reach for constantly: **one interface, multiple `@Profile`-gated implementations.**

---

## 3. Approach 2 — On a `@Bean` Method Inside a `@Configuration` Class

Use this when the bean needs custom construction logic (constructor arguments, builder calls, third-party classes you can't annotate directly because you don't own their source).

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

**Why this approach matters specifically:** notice `stripePaymentService` takes a constructor argument (`apiKey`) sourced from config. If `StripePaymentService` were a plain `@Component @Profile("prod")` class, you'd need `@Value` fields _inside_ that class instead — which works, but couples the class to Spring annotations more than necessary. A `@Bean` method keeps construction logic centralized and the actual class itself framework-agnostic (a genuinely POJO `StripePaymentService`, easier to unit test in isolation without any Spring context at all).

**Important subtlety:** `@Profile` on a `@Bean` method only prevents _that specific bean_ from being registered — it doesn't affect the enclosing `@Configuration` class itself unless you _also_ annotate the class. If the class has no `@Profile`, it's always processed, but individual `@Bean` methods inside it are still selectively skipped based on their own `@Profile`.

---

## 4. Approach 3 — On the Entire `@Configuration` Class

```java
@Configuration
@Profile("dev")
public class DevDataSeeder {

    @Bean
    CommandLineRunner seedBooks(BookRepository bookRepository) {
        return args -> {
            bookRepository.save(new Book("Effective Java", "Joshua Bloch"));
        };
    }

    @Bean
    CommandLineRunner seedMembers(MemberRepository memberRepository) {
        return args -> {
            memberRepository.save(new Member("Test User", "test@example.com"));
        };
    }
}
```

Here, `@Profile("dev")` on the **class** means: if `dev` isn't active, **the entire configuration class is skipped** — neither `seedBooks` nor `seedMembers` gets registered, and Spring doesn't even process the class's internals. This is the right choice when _everything_ in a config class logically belongs to one profile — no need to repeat `@Profile("dev")` on every individual `@Bean` method inside it.

---

## 5. What Actually Happens Internally — Building the Mental Model

It helps to understand _when_ this evaluation happens relative to the rest of Spring's startup sequence:

```
1. Spring reads spring.profiles.active (from properties/env var/CLI arg)
        │
        ▼
2. Component scanning discovers all @Component/@Service/@Configuration classes
   on the classpath (regardless of profile — scanning itself isn't profile-aware)
        │
        ▼
3. For each discovered bean DEFINITION, Spring checks: does it have @Profile?
   - No @Profile → always register
   - Has @Profile → register ONLY if it matches an active profile
        │
        ▼
4. Bean INSTANTIATION happens only for registered definitions
   (constructors run, @Autowired dependencies get wired, etc.)
```

**The key insight:** `@Profile` acts at step 3 — _bean definition filtering_ — not step 4. This is why a `@Profile("prod")` bean's constructor genuinely never executes in `dev` — it's not lazily skipped at call time, it was never registered as something Spring even knows to construct. If you tried to `@Autowired` a `prod`-only bean while running under the `dev` profile, you'd get a startup failure (`NoSuchBeanDefinitionException`) — not a null reference at runtime. This is a _good_ thing: it converts a would-be runtime `NullPointerException` bug into an immediate, obvious startup crash — same "fail fast" principle from `@ConfigurationProperties` validation.

---

## 6. A Practical Trap — Two Implementations, No Profile on Either

If you write both `MockPaymentService` and `StripePaymentService` as plain `@Service` classes implementing `PaymentService`, **without any `@Profile` at all**, Spring will fail at startup with:

```
NoUniqueBeanDefinitionException: expected single matching bean but found 2:
mockPaymentService, stripePaymentService
```

Spring has no way to know which one you want injected — `@Profile` is precisely what resolves this ambiguity _before_ it becomes a conflict, by ensuring **only one of them is ever a candidate at a time**, based on environment. This is worth understanding as _the actual reason_ `@Profile` matters here, beyond "it's convenient" — without it, having two implementations of the same interface is a compile-time-invisible, startup-time-fatal design.

---

## 7. Ensuring Exactly One Implementation Is Always Registered — the `@Primary` / `default` Fallback Question

A subtlety worth knowing: what if **no** profile matches? E.g., you're running with no active profile set at all (Spring Boot's implicit `default` profile) — neither `dev` nor `prod` — and both your beans are gated by `@Profile("dev")`/`@Profile("prod")` respectively. Now **neither** is registered, and anything needing `PaymentService` fails at startup with `NoSuchBeanDefinitionException` — for the opposite reason as before (zero candidates instead of two).

### Fix — target the implicit `default` profile explicitly

```java
@Service
@Profile("default")   // matches when NO profile is explicitly active
public class MockPaymentService implements PaymentService { ... }
```

Or, more robustly, use the negation trick from the previous tutorial to make one implementation the deliberate fallback for "anything that isn't prod":

```java
@Service
@Profile("!prod")     // active whenever prod is NOT active — including "no profile set"
public class MockPaymentService implements PaymentService { ... }

@Service
@Profile("prod")
public class StripePaymentService implements PaymentService { ... }
```

This guarantees exactly one implementation is always available, regardless of what profile combinations exist now or get added later — genuinely worth defaulting to this pattern (`!prod` + `prod`) over listing every non-prod profile individually (`dev`, `test`, `staging`, ...), since it can't silently break when someone adds a new environment name later and forgets to update the list.

---

## 8. Testing a Profile-Gated Bean Directly

```java
@SpringBootTest
@ActiveProfiles("dev")
class PaymentServiceProfileTest {

    @Autowired
    private PaymentService paymentService;

    @Test
    void shouldWireMockImplementationInDevProfile() {
        assertThat(paymentService).isInstanceOf(MockPaymentService.class);
    }
}
```

This directly verifies the wiring itself — genuinely useful the first time you set up multiple profile-gated implementations, to confirm Spring is resolving to the one you expect before you build anything on top of it.

---

## 9. Full Worked Example — Library App's `EmailSender`, End to End

Pulling every piece together into one complete, realistic setup:

```java
// The abstraction — business code depends on this, never on a concrete impl
public interface EmailSender {
    void send(String to, String subject, String body);
}
```

```java
@Component
@Profile("!prod")   // dev, test, staging, or no profile — safe default everywhere except real prod
@Slf4j
public class ConsoleEmailSender implements EmailSender {
    @Override
    public void send(String to, String subject, String body) {
        log.info("📧 [MOCK] To: {} | Subject: {} | Body: {}", to, subject, body);
    }
}
```

```java
@Component
@Profile("prod")
@RequiredArgsConstructor
public class SendGridEmailSender implements EmailSender {
    private final SendGridClient client;

    @Override
    public void send(String to, String subject, String body) {
        client.send(new Email(to, subject, body));
    }
}
```

```java
@Service
@RequiredArgsConstructor
public class OverdueNotificationService {
    private final EmailSender emailSender;   // has ZERO idea which impl it got

    public void notifyOverdue(Loan loan) {
        emailSender.send(
            loan.getMember().getEmail(),
            "Book overdue: " + loan.getBook().getTitle(),
            "Please return your book."
        );
    }
}
```

```bash
# Dev: no SPRING_PROFILES_ACTIVE set at all → "default" profile → matches "!prod" → ConsoleEmailSender
./mvnw spring-boot:run

# Prod: explicit profile → matches "prod" → SendGridEmailSender
SPRING_PROFILES_ACTIVE=prod java -jar library-app.jar
```

`OverdueNotificationService` — the actual business logic — never changes, never knows, never needs to know. This is the full payoff of the layering discipline from way back in the Spring Application Layers tutorial, now demonstrated concretely with profiles as the mechanism.

---

## Quick Summary

1. `@Profile` on a `@Component`/`@Service`/`@Repository` class, on an individual `@Bean` method, or on an entire `@Configuration` class — Spring skips bean _definition_ entirely for non-matching profiles, before any instantiation happens
2. This is _why_ a mismatched-profile bean's constructor never runs — it was never registered, not lazily bypassed
3. Two `@Profile`-less implementations of the same interface → `NoUniqueBeanDefinitionException` at startup; `@Profile` is what resolves that ambiguity
4. Zero matching implementations for the active profile → `NoSuchBeanDefinitionException` at startup — guard against this with `@Profile("!prod")` as your safe default, rather than naming every non-prod profile individually
5. `@ActiveProfiles("test")` in a test class lets you directly assert which implementation got wired, confirming your profile setup behaves as designed





[[Spring Framework]]