---

---



---
## Mental Model First: The IoC Container as a "Bean Warehouse"

Think of the Spring IoC container as a highly organized warehouse. Your application's classes are the products. The container's job is to:

1. **Discover** products (classes annotated with stereotypes like `@Component`, `@Service`, etc.).
2. **Assemble** products that need parts from other products (dependency injection).
3. **Deliver** products to the places that request them (injection points).

`@Configuration` and `@Bean` are your **custom manufacturing instructions** for products you can't or don't want to annotate directly. `@Autowired` is the **delivery request**. `@Qualifier` and `@Primary` are the **disambiguation rules** when the warehouse has multiple products of the same type.

---

## 1. The Core Annotations: Precise Definitions

### `@Configuration`

A class-level annotation that marks a class as a **source of bean definitions**. It is itself meta-annotated with `@Component`, meaning configuration classes are also Spring-managed beans. The key difference from `@Component` is behavioral, which we'll explore deeply in the `proxyBeanMethods` section.

```java
@Configuration
public class AppConfig {
    // @Bean methods go here
}
```

### `@Bean`

A method-level annotation that tells Spring: "Call this method and register the returned object as a bean in the container." The bean's name defaults to the method name, and its type is inferred from the method's return type. `@Bean` is a direct analog of the XML `<bean/>` element.

```java
@Configuration
public class AppConfig {
    @Bean
    public TransferService transferService() {
        return new TransferServiceImpl();
    }
}
```

This registers a bean named `transferService` of type `TransferServiceImpl` bound to the `TransferService` interface. The method's parameters describe the bean's dependencies, resolved exactly like constructor injection.

### `@Autowired`

Marks a **dependency injection point**. Spring resolves the dependency by type first, then by qualifier. It can be placed on constructors, fields, setter methods, or arbitrary methods. Since Spring Framework 4.3, if a class has exactly one constructor, `@Autowired` is no longer required on that constructor — Spring injects automatically.

### `@Qualifier`

A **fine-grained filter** applied at a specific injection point. When multiple beans of the same type exist, `@Qualifier("name")` tells Spring exactly which one to inject. It can also be used on `@Bean` methods to assign a qualifier value to the produced bean.

### `@Primary`

A **container-level default marker**. When multiple beans of the same type are candidates for a single-valued injection point, the one marked `@Primary` wins if no `@Qualifier` is present. It answers the question: "What should I use by default?"

**Critical rule**: `@Qualifier` always wins over `@Primary`. This is because `@Qualifier` is a local, explicit choice at the injection point, while `@Primary` is a global fallback preference.

---

## 2. The Full Disambiguation Hierarchy: `@Qualifier`, `@Primary`, and `@Fallback`

Spring Boot 4 (Spring Framework 7) introduces `@Fallback` as a companion to `@Primary`. The resolution order is:

| Priority | Annotation | Semantics |
|---|---|---|
| 1 (highest) | `@Qualifier` at injection point | Explicit local choice — always wins |
| 2 | `@Primary` bean | Global default when no qualifier is given |
| 3 | Regular bean | Selected when no primary exists |
| 4 (lowest) | `@Fallback` bean | Selected only if all other candidates are eliminated |

`@Fallback` is useful for infrastructure beans like `ObjectMapper` or `Clock` where you want a "last resort" implementation that is only used if no other bean of that type is available.

```java
@Configuration
public class JsonConfig {

    @Bean
    @Primary
    public ObjectMapper objectMapper() {
        return new ObjectMapper()
            .registerModule(new JavaTimeModule());
    }

    @Bean
    @Fallback
    public ObjectMapper fallbackObjectMapper() {
        return new ObjectMapper(); // minimal, no modules
    }
}
```

### Custom Qualifier Annotations

You can create your own qualifier annotations by meta-annotating them with `@Qualifier`. This gives you type-safe, domain-specific disambiguation without string literals.

```java
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Qualifier
public @interface Email {
}
```

```java
@Service
@Email
public class EmailNotificationService implements NotificationService {
    // ...
}

@Service
public class SmsNotificationService implements NotificationService {
    // ...
}
```

```java
@Service
public class NotificationDispatcher {

    private final NotificationService emailService;
    private final NotificationService smsService;

    public NotificationDispatcher(
        @Email NotificationService emailService,
        NotificationService smsService  // fails if more than one non-qualified bean
    ) {
        this.emailService = emailService;
        this.smsService = smsService;
    }
}
```

This is more expressive than `@Qualifier("email")` because the qualifier is a type, enabling IDE navigation and compile-time safety (to the extent annotations allow).

---

## 3. `proxyBeanMethods`: The Deepest Behavioral Difference Between `@Configuration` and `@Component`

This is the single most misunderstood aspect of `@Configuration`, and it directly answers your question about whether to use `@Configuration` vs `@Component`.

### Full Mode (`proxyBeanMethods = true`, the default)

When you use plain `@Configuration`, Spring creates a CGLIB proxy subclass of your configuration class. This proxy intercepts calls to `@Bean` methods. When one `@Bean` method calls another, the proxy returns the **singleton from the container** instead of executing the method body again.

```java
@Configuration
public class FullConfig {

    @Bean
    public Foo foo() {
        return new Foo(bar()); // proxy intercepts bar() and returns the singleton
    }

    @Bean
    public Bar bar() {
        return new Bar(); // only executed once
    }
}
```

**Why this works**: The CGLIB proxy overrides `bar()`. When `foo()` internally calls `this.bar()`, the proxy sees the call and returns the already-registered `bar` bean. This guarantees singleton semantics even for intra-configuration method calls.

### Lite Mode (`proxyBeanMethods = false`)

When you set `@Configuration(proxyBeanMethods = false)`, or when you use `@Component` on a class containing `@Bean` methods, no CGLIB proxy is created. Intra-class calls to `@Bean` methods are plain Java method calls, producing **new instances** each time.

```java
@Configuration(proxyBeanMethods = false)
public class LiteConfig {

    @Bean
    public Foo foo() {
        return new Foo(bar()); // calls bar() directly — creates a SECOND Bar instance!
    }

    @Bean
    public Bar bar() {
        return new Bar(); // registered as a bean, but foo() ignores that
    }
}
```

### The Critical Rule for Lite Mode

If you use `proxyBeanMethods = false`, **never call one `@Bean` method from another**. Instead, inject the dependency as a method parameter:

```java
@Configuration(proxyBeanMethods = false)
public class CorrectLiteConfig {

    @Bean
    public Foo foo(Bar bar) { // Spring injects the container-managed Bar
        return new Foo(bar);
    }

    @Bean
    public Bar bar() {
        return new Bar();
    }
}
```

### When to Use Full Mode vs Lite Mode

| Use Case | Recommendation |
|---|---|
| `@Bean` methods call each other internally | **Full mode** (`proxyBeanMethods = true`, the default) |
| `@Bean` methods are independent (no intra-class calls) | **Lite mode** (`proxyBeanMethods = false`) for better startup performance and no CGLIB |
| `@Component` class with `@Bean` methods | Lite mode implicitly — always inject as parameters, never call intra-class |

**Spring Boot 4 nuance**: For auto-configuration classes, Spring Boot uses lite mode extensively because auto-configuration beans are designed to be independent and the CGLIB proxy overhead is avoided. For your own application configuration classes, full mode is still the safe default unless you're certain your `@Bean` methods don't call each other.

---

## 4. `@Configuration` vs `@Component` for Configuration: Design Style

### The Decisive Factors

**Use `@Configuration` when:**

1. You are defining `@Bean` methods for **third-party library classes** you cannot annotate (e.g., `DataSource`, `ObjectMapper`, `RestTemplate`).
2. You need **full-mode singleton guarantees** for intra-class `@Bean` method calls.
3. You are creating a **dedicated configuration module** for a specific concern (e.g., `SecurityConfig`, `WebConfig`, `JacksonConfig`).
4. You need `@ConfigurationProperties` binding on the class (with `@Configuration`, you must use `@EnableConfigurationProperties` or `@ConfigurationPropertiesScan`).

**Use `@Component` (or `@Service`, `@Repository`, etc.) when:**

1. The class is your **own application code** that happens to have `@Bean` methods, but the primary role is a service/component, not configuration.
2. You want **lite mode** behavior implicitly and your `@Bean` methods are independent.
3. You are writing a **`@ConfigurationProperties` class** — Spring Boot 4 specifically warns that combining `@Configuration` with `@ConfigurationProperties` on the same class can cause property binding to be skipped. Use `@Component` or `@ConfigurationProperties` alone instead.

### The Recommended Design Pattern

Separate **configuration** from **components**:

```
com.example.myapp
├── MyAppApplication.java          // @SpringBootApplication
├── config/
│   ├── SecurityConfig.java        // @Configuration — third-party beans
│   ├── JacksonConfig.java         // @Configuration — ObjectMapper customization
│   └── WebConfig.java             // @Configuration — WebMvcConfigurer
├── service/
│   ├── UserService.java           // @Service — business logic
│   └── NotificationService.java   // @Service — business logic
└── repository/
    └── UserRepository.java        // @Repository — data access
```

**Never** put `@Bean` methods for third-party classes in a `@Service`. That violates separation of concerns and makes the service class harder to test in isolation.

---

## 5. `@Bean` Method Best Practices in Spring Boot 4

### Return Type: Prefer the Most Specific Type

Declare `@Bean` methods with the **most specific return type** possible, unless you have a deliberate design reason to hide the implementation.

```java
// Preferred: concrete type
@Bean
public HikariDataSource dataSource() {
    return new HikariDataSource();
}

// Acceptable if you want to hide the implementation
@Bean
public DataSource dataSource() {
    return new HikariDataSource();
}
```

**Why specificity matters**: With the concrete return type, Spring can perform **advanced type prediction** before the bean is instantiated. With an interface return type, type matching for `@Autowired HikariDataSource` only succeeds after the bean is created. In Spring Boot 4, this matters more than ever because of AOT (Ahead-of-Time) compilation and GraalVM native image support — the more type information is available at build time, the better the optimization.

**Spring Boot 4 specific warning**: If you define an `ObjectMapper` bean, Spring Boot 4's auto-configuration may still expect a `JsonMapper` (Jackson 3's concrete type). To override the auto-configured mapper, you must return `JsonMapper`, not just `ObjectMapper`. The auto-configuration condition checks by return type.

### Visibility: Always `public`

`@Bean` methods should **always be `public`**. While Spring can technically invoke non-public `@Bean` methods via reflection, CGLIB proxying (in full mode) cannot intercept `private` or `static` methods. This breaks singleton semantics if you ever call a `@Bean` method from another `@Bean` method in the same class.

```java
@Configuration
public class BadConfig {

    @Bean
    private Bar bar() { // private — CGLIB proxy cannot intercept
        return new Bar();
    }

    @Bean
    public Foo foo() {
        return new Foo(bar()); // creates a new Bar every time!
    }
}
```

### `@Bean` Method Naming and Aliases

The bean name defaults to the method name. You can override it:

```java
@Bean("primaryDataSource")
public DataSource dataSource() { ... }

// Or multiple aliases
@Bean(name = {"dataSource", "mainDataSource"})
public DataSource dataSource() { ... }
```

### `@Bean` with `destroyMethod`

For beans that implement `Closeable` or `AutoCloseable`, Spring automatically calls the close method on shutdown. You can customize or disable this:

```java
@Bean(destroyMethod = "shutdown")
public ExecutorService executorService() {
    return Executors.newFixedThreadPool(10);
}

@Bean(destroyMethod = "") // disable automatic destroy
public SomeBean someBean() {
    return new SomeBean();
}
```

---

## 6. `@Autowired` in Modern Spring Boot 4: Constructor Injection Is the Only Serious Choice

### Why Field Injection Is Discouraged

Field injection (`@Autowired private Foo foo;`) has been effectively deprecated as a recommended practice by the Spring team. The reasons are:

1. **Immutability**: Fields cannot be `final` with field injection, so dependencies can be reassigned (accidentally or via reflection).
2. **Testability**: You cannot instantiate the class with mocked dependencies via constructor. You need Spring's test context or reflection utilities.
3. **Hidden dependencies**: Field injection allows a class to accumulate 10+ dependencies without the constructor signature growing — a smell that constructor injection makes painfully visible.
4. **Circular dependency masking**: Field injection can mask circular dependencies until runtime. Constructor injection fails fast at startup.

### Constructor Injection: The Modern Default

```java
@Service
public class OrderService {

    private final PaymentGateway paymentGateway;
    private final InventoryService inventoryService;
    private final NotificationService notificationService;

    // @Autowired is optional here — single constructor
    public OrderService(
        PaymentGateway paymentGateway,
        InventoryService inventoryService,
        NotificationService notificationService
    ) {
        this.paymentGateway = paymentGateway;
        this.inventoryService = inventoryService;
        this.notificationService = notificationService;
    }
}
```

With Lombok's `@RequiredArgsConstructor`, this becomes:

```java
@Service
@RequiredArgsConstructor
public class OrderService {

    private final PaymentGateway paymentGateway;
    private final InventoryService inventoryService;
    private final NotificationService notificationService;
}
```

**Critical Spring Boot 4 + Lombok caveat**: `@RequiredArgsConstructor` does **not** copy `@Qualifier` from fields to constructor parameters by default. If you use qualifiers on fields, you must add this to `lombok.config`:

```properties
lombok.copyableAnnotations += org.springframework.beans.factory.annotation.Qualifier
```

Otherwise, the qualifier is silently dropped and Spring resolves by type alone — potentially injecting the wrong bean.

### When `@Autowired` Is Still Required

- **Multiple constructors**: If a class has more than one constructor, you must annotate the one Spring should use with `@Autowired`.
- **Setter injection for optional dependencies**: `@Autowired(required = false)` on a setter allows the dependency to be absent.
- **Arbitrary method injection**: For injecting into a method that isn't a constructor or setter (rare, but useful for framework extension points).

### Optional Dependencies: `ObjectProvider` vs `@Autowired(required = false)`

Modern Spring Boot prefers `ObjectProvider` over `@Autowired(required = false)` because it handles the absence gracefully and supports lazy resolution:

```java
@Service
public class MetricsService {

    private final ObjectProvider<MeterRegistry> meterRegistryProvider;

    public MetricsService(ObjectProvider<MeterRegistry> meterRegistryProvider) {
        this.meterRegistryProvider = meterRegistryProvider;
    }

    public void record(String metric) {
        MeterRegistry registry = meterRegistryProvider.getIfAvailable();
        if (registry != null) {
            registry.counter(metric).increment();
        }
    }
}
```

For constructor injection, `@Autowired(required = false)` does **not** work — Spring will not inject `null` into a constructor parameter. Use `Optional<T>` or `ObjectProvider<T>` instead.

---

## 7. The Complete Annotation Landscape: Related Concepts

### Bean Scope Annotations

| Annotation | Effect |
|---|---|
| `@Scope("prototype")` | New instance per injection point |
| `@Scope("request")` | One instance per HTTP request |
| `@Scope("session")` | One instance per HTTP session |
| `@Lazy` | Bean created only on first use, not at startup |

`@Lazy` is particularly valuable for breaking circular dependencies and reducing startup time for expensive beans. It can be placed on a `@Bean` method, a `@Component` class, or an injection point.

### `@Profile` and `@Conditional`

```java
@Configuration
@Profile("production")
public class ProductionConfig {

    @Bean
    public DataSource dataSource() {
        return new HikariDataSource(); // production pool
    }
}
```

`@Conditional` (and its Spring Boot derivatives like `@ConditionalOnMissingBean`, `@ConditionalOnProperty`) allows beans to be registered only when specific conditions are met. This is the foundation of auto-configuration.

### `@ConfigurationProperties`

For type-safe configuration binding, use `@ConfigurationProperties` instead of scattered `@Value` annotations:

```java
@Component
@ConfigurationProperties(prefix = "app.notification")
@Validated
public class NotificationProperties {

    @NotBlank
    private String defaultChannel = "email";

    @Min(1)
    private int retryCount = 3;

    // getters and setters
}
```

**Spring Boot 4 warning**: Do **not** combine `@Configuration` with `@ConfigurationProperties` on the same class. In Spring Boot 4.x, this causes property binding to be skipped. Use `@Component` or `@ConfigurationProperties` alone, or register via `@EnableConfigurationProperties`.

### `@Import` and `@ImportResource`

- `@Import(SomeConfig.class)` — imports another `@Configuration` class explicitly, bypassing component scanning.
- `@ImportResource("classpath:legacy.xml")` — imports XML bean definitions. Spring Boot 4 supports this but XML configuration is discouraged for new projects.

### `@ComponentScan`

Controls which packages Spring scans for stereotype-annotated classes. `@SpringBootApplication` includes `@ComponentScan` with the main application class's package as the base. You can customize:

```java
@SpringBootApplication
@ComponentScan(basePackages = {"com.example.myapp", "com.example.shared"})
public class MyAppApplication { ... }
```

**Spring Boot 4 best practice**: Keep your main application class in a root package above all other classes. Avoid customizing `@ComponentScan` unless you genuinely need to scan packages outside your application's hierarchy.

---

## 8. Design Style: How to Structure Your Code

### Rule 1: Stereotype Annotations for Your Code, `@Bean` for Third-Party Code

| Scenario | Annotation |
|---|---|
| Your business logic class | `@Service` |
| Your data access class | `@Repository` |
| Your web controller | `@RestController` or `@Controller` |
| Third-party class needing configuration | `@Bean` inside `@Configuration` |
| Infrastructure setup (Security, Web, Jackson) | `@Configuration` class |

### Rule 2: One Configuration Class per Concern

```java
@Configuration
public class JacksonConfig {
    @Bean
    public JsonMapper jsonMapper() { ... }
}

@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) { ... }
}
```

### Rule 3: Prefer Composition Over Inheritance for Configuration

```java
// Interface with default @Bean methods — Spring Boot 4 supports this
public interface CacheConfig {
    @Bean
    default CacheManager cacheManager() {
        return new ConcurrentMapCacheManager();
    }
}

@Configuration
public class AppConfig implements CacheConfig {
    // inherits cacheManager bean
}
```

### Rule 4: Use `@Configuration(proxyBeanMethods = false)` for Independent Bean Methods

If your `@Bean` methods never call each other, disable CGLIB proxying for faster startup and no class enhancement overhead. This is especially important for Spring Boot 4 applications targeting GraalVM native images, where CGLIB proxies are problematic.

### Rule 5: Constructor Injection Everywhere, with `final` Fields

```java
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final ApplicationEventPublisher eventPublisher;
}
```

### Rule 6: Qualify at the Injection Point, Not at the Bean Definition (When Possible)

While `@Qualifier` on a `@Bean` method or `@Service` class works, the most readable and maintainable approach is often to qualify at the injection point. This keeps the bean definition neutral and the consumer explicit about what it needs.

### Rule 7: Use `@Primary` Sparingly

`@Primary` creates an implicit global default. This is convenient but can be surprising in large codebases. Prefer explicit `@Qualifier` at injection points, and reserve `@Primary` for infrastructure beans where a sensible default genuinely exists (e.g., a default `ObjectMapper`).

---

## 9. Edge Cases and Pitfalls

### Pitfall 1: `@Qualifier` on a Field Is Not Copied by Lombok

As mentioned, you must configure `lombok.copyableAnnotations` for `@Qualifier`. Without it, constructor injection with Lombok silently loses the qualifier.

### Pitfall 2: `@Bean` Method Called from `@PostConstruct`

```java
@Configuration
public class BadConfig {

    @Bean
    public Foo foo() { return new Foo(); }

    @PostConstruct
    public void init() {
        foo(); // creates a NEW Foo, not the singleton!
    }
}
```

`@PostConstruct` runs after bean creation, but calling `foo()` directly invokes the raw method (or the proxy method, which returns the singleton in full mode). In lite mode, this creates a second instance. **Never call `@Bean` methods from lifecycle callbacks.** Inject the bean instead.

### Pitfall 3: `@Primary` with `@Qualifier` on the Same Bean

```java
@Bean
@Primary
@Qualifier("special")
public Foo foo() { ... }
```

This is valid but confusing. `@Qualifier` on the bean definition assigns a qualifier value. `@Primary` marks it as default. If an injection point uses `@Qualifier("special")`, it gets this bean regardless of `@Primary`. If an injection point has no qualifier, `@Primary` wins. This is correct behavior but can surprise readers.

### Pitfall 4: Circular Dependencies with Constructor Injection

Constructor injection makes circular dependencies **fail at startup** with a clear error. This is a feature, not a bug. If you have `A` depends on `B` and `B` depends on `A`, you must refactor — typically by extracting a third class or using `@Lazy` on one injection point.

```java
@Service
public class A {
    private final B b;
    public A(@Lazy B b) { this.b = b; } // breaks the cycle with a proxy
}
```

### Pitfall 5: `@Configuration` and `@ConfigurationProperties` on the Same Class

In Spring Boot 4, this combination causes property binding to be skipped. The fix is to use `@Component` or `@ConfigurationProperties` alone.

---

## Summary: The Decision Tree

| Question | Answer |
|---|---|
| Third-party class needing a bean? | `@Bean` in a `@Configuration` class |
| My own business class? | `@Service` with constructor injection |
| Multiple beans of same type, need a default? | `@Primary` on one bean |
| Multiple beans of same type, need specific one here? | `@Qualifier` at injection point |
| Want type-safe qualifier? | Custom `@Qualifier` meta-annotation |
| `@Bean` methods call each other? | Full mode (`@Configuration` default) |
| `@Bean` methods independent? | Lite mode (`proxyBeanMethods = false`) |
| Class has `@Bean` methods but isn't config? | `@Component` + inject dependencies as parameters |
| Optional dependency? | `ObjectProvider<T>` in constructor |
| Config properties? | `@ConfigurationProperties` on `@Component`, not on `@Configuration` |

This is the modern Spring Boot 4 way: explicit, constructor-injected, stereotype-annotated for your code, `@Bean`-configured for external code, and disambiguated with `@Qualifier` before `@Primary` whenever possible.



[[0 - Spring Framework]]