

## Mental Model First

We've already used `@Profile` once — in the `PaymentGateway` example under Abstraction, where `StripePaymentGateway` was `@Profile("prod")` and `FakePaymentGateway` was `@Profile("test")`. Now let's formalize it.

Think of Profiles as **labels on bean definitions that the container checks before deciding whether a bean even exists.** This is fundamentally different from everything else we've discussed (DI, AOP, scope) — those all operate on beans **after** they're registered. Profiles operate **before registration even happens** — a bean whose profile doesn't match simply never makes it into that `Map<String, Object>` we keep coming back to. It's not "created but inactive" — it's as if the `@Component` annotation wasn't there at all, for that particular run.

The play analogy again: profiles are like having **entirely different casts** for a matinee show versus an evening show. The stage (container) is the same, the script structure is the same, but which actors actually walk on stage depends on which show is running. You don't want your "test understudy" showing up during the real evening performance.

---

## Part 1: The Core Mechanism

### Declaring a bean as profile-specific

```java
public interface PaymentGateway {
    PaymentResult charge(Money amount);
}

@Service
@Profile("prod")
public class StripePaymentGateway implements PaymentGateway {
    public PaymentResult charge(Money amount) {
        // real Stripe API call
    }
}

@Service
@Profile("dev")
public class FakePaymentGateway implements PaymentGateway {
    public PaymentResult charge(Money amount) {
        return PaymentResult.success(); // no real charge
    }
}
```

### Activating a profile

Several ways, in order of how commonly you'll use them:

**1. `application.properties` / `application.yml`**

```properties
spring.profiles.active=dev
```

**2. Environment variable (very common in containerized deployments)**

```bash
export SPRING_PROFILES_ACTIVE=prod
java -jar app.jar
```

**3. JVM system property**

```bash
java -Dspring.profiles.active=prod -jar app.jar
```

**4. Command-line argument**

```bash
java -jar app.jar --spring.profiles.active=prod
```

**5. Programmatically (rare, mostly for tests)**

```java
SpringApplication app = new SpringApplication(MyApp.class);
app.setAdditionalProfiles("dev");
app.run(args);
```

### What actually happens at startup

Recall from our container discussion: `AnnotationConfigApplicationContext` scans for `@Component`-annotated classes and registers them. Profile checking is inserted **into that scanning step**, via a `Condition` evaluation (we'll connect this to `@Conditional` shortly — same underlying mechanism). For each candidate bean definition:

```
1. Does this class have @Profile("x")?
   NO  → register unconditionally (this is why beans with no @Profile ALWAYS load, in every profile)
   YES → is "x" in the currently active profiles list?
           YES → register normally
           NO  → skip entirely — this bean definition never enters the container
```

**Critical detail:** if you request `PaymentGateway` via constructor injection and _no_ profile is active that provides an implementation, you get the exact same `NoSuchBeanDefinitionException` we discussed under bean naming ambiguity — except now the cause is "the bean was never registered in the first place," not "it exists but Spring can't pick one." Same symptom, structurally different root cause — worth being able to tell these apart when debugging.

---

## Part 2: Where `@Profile` Can Be Applied

### On a whole `@Configuration` class — groups multiple beans under one profile

```java
@Configuration
@Profile("prod")
public class ProdConfig {

    @Bean
    public DataSource dataSource() {
        // real PostgreSQL connection pool
    }

    @Bean
    public PaymentGateway paymentGateway() {
        return new StripePaymentGateway();
    }
}

@Configuration
@Profile("dev")
public class DevConfig {

    @Bean
    public DataSource dataSource() {
        // in-memory H2 database
    }

    @Bean
    public PaymentGateway paymentGateway() {
        return new FakePaymentGateway();
    }
}
```

This is the pattern senior codebases actually use — rather than scattering `@Profile` across many individual `@Service`/`@Component` classes, you centralize environment-specific wiring into dedicated configuration classes. It reads almost like the `AppConfig` pattern from our very first discussion of Java-based configuration, just partitioned by environment.

### On individual `@Bean` methods within one config class

```java
@Configuration
public class DataSourceConfig {

    @Bean
    @Profile("prod")
    public DataSource prodDataSource() { ... }

    @Bean
    @Profile("dev")
    public DataSource devDataSource() { ... }
}
```

Both styles coexist fine — use whichever matches how naturally your beans group together.

### Expressions — combining profiles with logical operators

```java
@Profile("prod & cloud")       // AND — both must be active
@Profile("dev | test")          // OR — either active
@Profile("!prod")               // NOT — active whenever "prod" is NOT active
@Profile({"dev", "test"})       // array = OR, same as "dev | test"
```

```java
@Service
@Profile("!prod")
public class DebugLoggingInterceptor {
    // runs in every profile EXCEPT production — a very common real-world pattern
}
```

The `!` negation is genuinely useful — "give me a debug/verbose logging aspect (tying back to our AOP discussion) in everything except prod" is a one-liner instead of listing every non-prod profile name explicitly.

---

## Part 3: Multiple Active Profiles Simultaneously

Profiles aren't mutually exclusive — you can activate several at once:

```properties
spring.profiles.active=dev,debug,local-db
```

```java
@Component
@Profile("debug")
public class VerboseRequestLogger { }

@Component
@Profile("local-db")
public class H2ConsoleEnabler { }
```

Both beans load simultaneously. This composability is genuinely useful — you can mix orthogonal concerns (environment: `dev`/`prod`, feature toggles: `debug`, `beta-features`) as independent, combinable labels rather than needing one giant profile per exact combination you might want.

---

## Part 4: `application-{profile}.properties` — Profile-Specific Configuration Files

This is arguably used _more_ than `@Profile` on beans directly, and it's important to separate the two mechanisms clearly, since beginners often conflate them.

```
src/main/resources/
├── application.properties           ← always loaded, base/shared config
├── application-dev.properties       ← loaded ONLY when "dev" profile active
├── application-prod.properties      ← loaded ONLY when "prod" profile active
└── application-test.properties      ← loaded ONLY when "test" profile active
```

```properties
# application.properties (shared, always applied)
spring.application.name=order-app
server.port=8080
```

```properties
# application-dev.properties
spring.datasource.url=jdbc:h2:mem:devdb
logging.level.com.example=DEBUG
```

```properties
# application-prod.properties
spring.datasource.url=jdbc:postgresql://prod-db:5432/orders
logging.level.com.example=WARN
```

**Loading order and override rule:** `application.properties` loads first as the base, then `application-{active-profile}.properties` loads on top and **overrides** any matching keys. If a key exists only in the base file and isn't overridden, the base value stands.

**How this differs from `@Profile` on beans:** `@Profile` controls **whether a bean exists at all**. Profile-specific property files control **what configuration values existing beans read** (like `DataSource` auto-configured by Spring Boot itself reading `spring.datasource.url`). Often you don't need `@Profile` on your own beans at all — you just let Spring Boot's auto-configuration (recall `@ConditionalOnMissingBean` from our Beans discussion) create the `DataSource` bean once, and vary its _connection string_ per profile via properties files. `@Profile` on beans is for when you need genuinely **different Java implementations** per environment (like swapping `StripePaymentGateway` for `FakePaymentGateway`) — not just different config values for the same implementation.

---

## Part 5: How This Connects to `@Conditional` — the General Mechanism Underneath

This is the "why does it work this way" depth worth having. `@Profile` isn't a special, hardcoded Spring feature — it's actually a thin, specific case built on top of a much more general mechanism: `@Conditional`.

```java
@Retention(RetentionPolicy.RUNTIME)
@Conditional(ProfileCondition.class) // <-- @Profile is literally implemented using @Conditional
public @interface Profile {
    String[] value();
}
```

`@Conditional` lets you attach **arbitrary logic** — not just "is this profile active" — that decides whether a bean definition gets registered:

```java
public class OnWindowsCondition implements Condition {
    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        return System.getProperty("os.name").toLowerCase().contains("win");
    }
}

@Component
@Conditional(OnWindowsCondition.class)
public class WindowsFileWatcher { }
```

This is the exact same underlying mechanism that powers `@ConditionalOnMissingBean` (which we saw earlier explains Spring Boot's own auto-configuration magic), `@ConditionalOnClass` (register a bean only if a certain library is on the classpath), `@ConditionalOnProperty`, etc. **`@Profile` is just `@Conditional` with the condition logic pre-written to check "is this string in `spring.profiles.active`."**

This connects directly to something we discussed under Beans — auto-configuration classes are riddled with `@ConditionalOnMissingBean` to implement "use my default unless you've defined your own." Now you can see that `@Profile` and Spring Boot's auto-configuration conditionals are actually **the same family of mechanism**, just pre-packaged for different specific checks. This is a nice, senior-level realization: Spring doesn't have dozens of unrelated "special case" annotations — it has one general extensibility point (`Condition` + `@Conditional`), and most of the annotations you already know are just named, pre-built implementations of it.

---

## Part 6: `@ActiveProfiles` — the Testing Counterpart

Directly relevant to how you'll actually use profiles day-to-day: swapping real implementations for fakes/mocks in tests, exactly like the `FakePaymentGateway` example.

```java
@SpringBootTest
@ActiveProfiles("test")
class OrderServiceTest {

    @Autowired
    private OrderService orderService;

    @Autowired
    private PaymentGateway paymentGateway; // resolves to FakePaymentGateway, because "test" profile is active

    @Test
    void placingOrderChargesPaymentGateway() {
        orderService.placeOrder(someOrder);
        // assertions against the fake gateway's recorded state, no real API call ever made
    }
}
```

This is a genuinely clean way to get **real Spring wiring** in your integration test, while swapping out the one dangerous/slow/external-dependent bean (`PaymentGateway`) for a safe fake — without touching any of your actual application code. It's the Strategy pattern (which we identified Spring embodies) doing real work for you in testing, not just theoretical elegance.

---

## Part 7: A Common Gotcha — Default Profile Behavior

```java
@Component
public class SomeBean { } // no @Profile — loads in EVERY profile, always
```

Worth stating precisely, since it trips people up: **a bean with no `@Profile` annotation is not "profile-neutral" in some special sense — it simply has no condition attached, so it always registers**, regardless of which profiles are active or even if _no_ profile is active at all.

There's also a genuinely-named `"default"` profile:

```properties
# if spring.profiles.active is NOT set at all, Spring implicitly treats "default" as active
```

```java
@Component
@Profile("default")
public class FallbackConfig {
    // only loads when NO other profile has been explicitly activated
}
```

This is useful for local development defaults that should apply "out of the box" with zero configuration, but should be cleanly superseded the moment you explicitly activate `dev`, `prod`, etc.

---

## Part 8: Senior-Level Structuring — Where Profiles Fit Into the Project Layout We Discussed

Tying back to our package-by-feature structure from before:

```
com.example.orderapp
├── payment/
│   ├── PaymentGateway.java              (interface)
│   └── impl/
│       ├── StripePaymentGateway.java     @Profile("prod")
│       └── FakePaymentGateway.java       @Profile("dev", "test")
└── common/
    └── config/
        ├── ProdConfig.java               @Profile("prod") @Configuration
        └── DevConfig.java                @Profile("dev")  @Configuration
```

```
src/main/resources/
├── application.properties
├── application-dev.properties
├── application-prod.properties
└── application-test.properties
```

The senior-level discipline here: **use `@Profile` on beans sparingly, for genuinely different implementations** (real vs. fake payment gateway). **Use `application-{profile}.properties` liberally** for configuration values (DB URLs, log levels, feature flags read via `@Value`/`@ConfigurationProperties`). Overusing `@Profile` scattered across many individual classes, rather than centralizing it in a few `@Configuration` classes, is a common intermediate-level mistake that makes it hard to answer "what exactly is different between dev and prod?" at a glance.

---

## Quick Reference

|Mechanism|Controls|Example|
|---|---|---|
|`@Profile` on `@Component`/`@Service`|Whether the bean definition registers at all|`@Profile("prod")` on `StripePaymentGateway`|
|`@Profile` on `@Configuration`|Whether a whole group of `@Bean` methods registers|`@Profile("dev")` on `DevConfig`|
|`application-{profile}.properties`|Configuration _values_ for beans that always exist|DB URL, log level|
|`@ActiveProfiles`|Which profile(s) a test run activates|`@ActiveProfiles("test")`|
|Underlying mechanism|`@Conditional` (general) → `@Profile` (specific pre-built condition)|Same family as `@ConditionalOnMissingBean`|

---

## Two Questions to Test Understanding

**1.** You have `@Profile("prod")` on `StripePaymentGateway` and `@Profile("dev")` on `FakePaymentGateway`, with no third implementation. If you start the app with `spring.profiles.active=staging` (a profile that matches neither), what specifically happens when a bean tries to `@Autowired` a `PaymentGateway` — and at what point (startup vs. first use) does this fail? Explain by tracing through the registration-time mechanism from Part 1.

**2.** Given that `@Profile` is just `@Conditional(ProfileCondition.class)` under the hood, could you write your own custom `@Conditional` annotation that achieves something `@Profile` structurally _cannot_ — specifically, a condition that depends on **another bean's runtime state** (e.g., "only register this bean if a `FeatureFlagService` bean says a certain flag is `true`")? Would this even be possible with `@Profile`, and why or why not — think carefully about _when_ profile/conditional evaluation happens relative to when beans are actually instantiated.


[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]