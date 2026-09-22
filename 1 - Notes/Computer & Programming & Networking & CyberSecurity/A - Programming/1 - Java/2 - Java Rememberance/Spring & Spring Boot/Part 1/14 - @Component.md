

## Part 1: The Mental Model

Back to the restaurant. Last time, `@Configuration` was a **recipe book** — a class whose methods are recipes for building dishes you assemble yourself (`new MyService()`).

`@Component` is different. It's a **"I am a dish"** sticker you put on a class. You're not writing a recipe; you're declaring *this class is itself a thing the kitchen should prepare and manage*. The kitchen (Spring) figures out how to make it — typically by calling its constructor.

Analogy shift:

- `@Configuration` + `@Bean` = "Here's how to build a `DataSource` from a third-party library." (You write the construction.)
- `@Component` = "This is my `OrderService`. Make one, wire its dependencies, keep it around." (Spring writes the construction.)

Both end up as beans in the same container. The difference is **who calls `new`** and **how the bean definition is discovered**.

---

## Part 2: The Mechanics

### 2.1 What `@Component` actually is

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Indexed
public @interface Component {
    String value() default "";
}
```

Just metadata. On its own it does **nothing**. The magic is component scanning.

### 2.2 Component scanning

Spring scans packages for classes annotated with `@Component` (or meta-annotations of it) and registers a `BeanDefinition` for each. Enabled by:

```java
@Configuration
@ComponentScan("com.example")
public class AppConfig { }
```

Or in Boot: `@SpringBootApplication` includes `@ComponentScan` with the package of the main class as the base, recursively.

The scanner:

1. Walks the classpath under the base package.
2. Finds candidate classes (`.class` files, usually via ASM bytecode reading — not reflection, for speed).
3. Checks for `@Component` or meta-annotations.
4. Registers a `BeanDefinition` with the class name, scope, etc.

Boot 3 / Spring 6 can also use an **AOT-generated index** (`META-INF/spring/aot.factories` and the compile-time component index) so it doesn't have to scan at runtime — important for native images and startup time.

### 2.3 Stereotype annotations

These are all `@Component` under the hood:

```java
@Component        // generic
@Service          // semantically: business logic
@Repository       // semantically: data access; also enables exception translation
@Controller       // semantically: web MVC controller
@RestController   // @Controller + @ResponseBody
```

`@Repository` is the only one with real behavior: it registers a `PersistenceExceptionTranslationPostProcessor` that translates vendor-specific exceptions (`SQLException`, JPA `PersistenceException`) into Spring's `DataAccessException` hierarchy.

The others are documentation/semantics. `@Service` and `@Controller` don't change behavior; they change *intent* and are used by tooling (AOP pointcut matching, IDE navigation, ArchUnit rules).

### 2.4 How Spring constructs the bean

For a `@Component`, Spring:

1. Picks a constructor (see §3.2).
2. Resolves each constructor parameter as a dependency.
3. Calls the constructor.
4. Applies `BeanPostProcessor`s (including `@Autowired` field/setter injection if you're using it).
5. Runs `@PostConstruct` / `InitializingBean`.
6. Stores in the singleton cache.

Compare with `@Bean`: there, *you* call `new` inside your method, and Spring just invokes the method. Constructor injection for `@Component` is resolved by the container's autowiring machinery; for `@Bean`, dependencies come in as **method parameters**.

---

## Part 3: Injection Details

### 3.1 The three injection styles

```java
@Component
public class OrderService {

    // 1. Constructor injection — PREFERRED
    private final PaymentService payment;
    public OrderService(PaymentService payment) { this.payment = payment; }

    // 2. Setter injection
    @Autowired
    public void setPayment(PaymentService payment) { this.payment = payment; }

    // 3. Field injection — works, but discouraged
    @Autowired
    private PaymentService payment;
}
```

Why constructor injection wins:

- **Immutability**: fields can be `final`.
- **Fail-fast**: if a dependency is missing, the bean fails to construct — not later at first use.
- **Testability**: you can `new OrderService(mockPayment)` without Spring.
- **Circular dependency detection**: the container detects A→B→A at construction and fails loudly, rather than silently injecting proxies.

Field injection uses reflection to set private fields *after* construction — hidden, untestable without a container, and it masks circular dependencies (Spring can inject a half-built bean via proxy). Avoid it.

### 3.2 Constructor resolution rules

If a class has:

- **One constructor** → Spring uses it, no `@Autowired` needed. (Since 4.3.)
- **Multiple constructors, one `@Autowired`** → that one.
- **Multiple constructors, none `@Autowired`** → uses the no-arg constructor; if none exists, fails.

```java
@Component
public class A {
    public A() { }                       // picked
    public A(Dep d) { }
}
```

This silently ignores `A(Dep)` and can confuse people. If you want the parameterized one, annotate it.

### 3.3 `@Qualifier`, `@Primary`, and disambiguation

When two beans match a type:

```java
@Component @Primary
public class StripePayment implements Payment { }

@Component
public class PaypalPayment implements Payment { }
```

`@Primary` wins by default. Otherwise:

```java
public OrderService(@Qualifier("paypalPayment") Payment p) { ... }
```

Or inject a `Map<String, Payment>` — keys are bean names. Or `List<Payment>` — all of them, ordered by `@Order`/`Ordered`.

### 3.4 `@Value` and `@ConfigurationProperties`

```java
@Component
public class SmtpClient {
    public SmtpClient(@Value("${smtp.host}") String host,
                      @Value("${smtp.port:25}") int port) { ... }
}
```

`@Value` uses SpEL and `PropertySources`. For a group of related properties, prefer:

```java
@Component
@ConfigurationProperties(prefix = "smtp")
public class SmtpProperties {
    private String host;
    private int port;
    // getters/setters
}
```

`@ConfigurationProperties` is type-safe, supports relaxed binding (`smtp.host`, `SMTP_HOST`, `smtpHost`), validation via JSR-303, and metadata generation for IDE autocomplete. It's almost always the right choice over many `@Value`s.

---

## Part 4: The Relationship to `@Configuration`/`@Bean`

This is the heart of it.

### 4.1 They're peers, not alternatives

| | `@Component` | `@Configuration` + `@Bean` |
|---|---|---|
| Annotation location | Class | Class (config) + method (bean) |
| Who instantiates | Spring (via constructor) | You (`new` inside the method) |
| Discovery | Component scanning | Component scanning finds the `@Configuration`; then its `@Bean` methods are read |
| Dependency injection | Constructor/setter/field params | Method parameters |
| Use for | Your own classes | Third-party classes, conditional/derived construction, multiple beans of the same type |
| Proxying | None needed | CGLIB subclass (unless `proxyBeanMethods=false`) |

### 4.2 `@Configuration` **is** a `@Component`

Look at the definition:

```java
@Component
public @interface Configuration {
    @AliasFor(annotation = Component.class)
    String value() default "";
    boolean proxyBeanMethods() default true;
}
```

So a `@Configuration` class is itself discovered by component scanning, registered as a bean, and can have its dependencies injected. The extra thing is that its `@Bean` methods are processed by `ConfigurationClassPostProcessor` — a `BeanDefinitionRegistryPostProcessor` that runs very early and turns `@Bean` methods into bean definitions.

### 4.3 `@Bean` in a `@Component` — lite mode revisited

```java
@Component
public class MyFactory {
    @Bean public A a() { return new A(); }
    @Bean public B b() { return new B(a()); }  // a() called directly → new A each time
}
```

Works, but "lite mode": `a()` is not intercepted. Two `A`s exist — one managed, one floating inside `B`. If `A` had `@PostConstruct` or proxying (e.g., `@Transactional`), the one inside `B` is a plain object with none of that.

So: **`@Bean` in a `@Component` is legal but almost always wrong** unless `b()` doesn't call `a()` and you understand the trade-off. Use `@Configuration` (or `@Configuration(proxyBeanMethods=false)` if you'll inject dependencies as method params instead of calling other `@Bean`s).

### 4.4 Mixing them in practice

A typical Boot app:

```java
@SpringBootApplication
public class App { public static void main(String[] a) { SpringApplication.run(App.class, a); } }

@Service
class OrderService { ... }              // @Component family — you own it

@Configuration
class PersistenceConfig {
    @Bean
    DataSource dataSource(DataSourceProperties props) {  // third-party — you build it
        return props.initializeDataSourceBuilder().build();
    }
}
```

Component scanning finds both `OrderService` and `PersistenceConfig`. The latter's `@Bean` methods become beans too. From the container's perspective, they're indistinguishable — all are `BeanDefinition`s.

---

## Part 5: Advanced & Nuances

### 5.1 `@Component` and proxying (AOP)

`@Transactional`, `@Async`, `@Cacheable`, `@PreAuthorize` all rely on **Spring AOP proxies**. When Spring sees `@Transactional` on a `@Component`, it wraps the bean in a proxy (JDK dynamic proxy if the bean implements interfaces, CGLIB otherwise — or CGLIB always if `proxyTargetClass=true`).

Consequence: **self-invocation doesn't trigger the advice.**

```java
@Service
public class OrderService {
    public void outer() { inner(); }   // does NOT go through the proxy

    @Transactional
    public void inner() { ... }        // transaction NOT started
}
```

Because `outer()` calls `this.inner()`, bypassing the proxy. Fix: inject yourself (`@Autowired OrderService self`), use `AopContext.currentProxy()`, or restructure. This trips up everyone once.

### 5.2 Proxy type mismatch

If you inject the concrete class and the proxy is JDK-dynamic (interface-based), you'll get a `ClassCastException` or a bean-not-found. Fix: `@EnableAspectJAutoProxy(proxyTargetClass = true)`, or inject by interface. Boot defaults to CGLIB proxies (`spring.aop.proxy-target-class=true`), which sidesteps this — one reason Boot "just works" where raw Spring often doesn't.

### 5.3 Lazy initialization

```java
@Component
@Lazy
public class ExpensiveService { ... }
```

The bean isn't created until first requested. Useful for breaking circular dependencies and speeding startup, but hides errors until runtime. Boot 2.2+ can globally lazy-init via `spring.main.lazy-initialization=true` — a startup-speed knob at the cost of fail-late.

### 5.4 Scope and proxies

```java
@Component
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class RequestScopedBean { ... }
```

`request`/`session` scopes don't exist in a plain singleton context. To inject a request-scoped bean into a singleton, Spring injects a **scoped proxy** that looks up the real bean on each method call. `proxyMode` controls whether it's JDK or CGLIB. Without `proxyMode`, you'll get an error at startup.

### 5.5 `@Component` vs `@Bean` — the decision rule

- You wrote the class, no complex construction → `@Component` (or a stereotype).
- It's a library class, or you need conditions, or you need multiple configured instances, or you want explicit control over construction → `@Bean` in a `@Configuration`.
- You're writing a Boot starter → `@Configuration` + `@Bean` + `@ConditionalOnMissingBean`, essentially always.

### 5.6 Component scanning gotchas

- Base package is the package of the `@ComponentScan`-annotated class (or `@SpringBootApplication`'s class). Sub-packages included; sibling/parent packages **not**.
- If you put your app class in the default package (no `package` declaration), scanning breaks or scans everything — never do this.
- Multiple `@ComponentScan`s are additive but can cause duplicate registration; `@ComponentScan` has `excludeFilters`/`includeFilters` for control.
- `@ComponentScan` on a class is itself processed via `@Import(ComponentScanningConfiguration.class)`-style machinery.

### 5.7 Boot's auto-configuration is `@Configuration`, not scanning

`@EnableAutoConfiguration` (inside `@SpringBootApplication`) imports `AutoConfigurationImportSelector`, which loads candidate configs from `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` (Boot 2.7+) or `spring.factories` (older). Each is a `@Configuration` class full of `@Bean` + `@ConditionalOn*`. **This is why Boot doesn't component-scan your whole classpath** — it explicitly lists configs, keeping startup fast and behavior predictable.

---

## Part 6: Test Your Understanding

**Question 1.** Consider:

```java
@Service
public class OrderService {
    @Autowired private InventoryService inventory;

    public void placeOrder() { reserve(); }

    @Transactional
    public void reserve() { inventory.decrement(); }
}

@Service
public class InventoryService {
    @Autowired private OrderService orderService;   // circular!
}
```

(a) Will this start up? What does Spring do about the cycle, and what's the risk?
(b) When `placeOrder()` runs, does the `@Transactional` on `reserve()` take effect? Explain precisely why or why not, and give two ways to fix it.
(c) If `InventoryService` were instead `@Scope("prototype")`, would the cycle be a problem? Why or why not?

**Question 2.** You're writing a library that ships a `@Component`-annotated `MetricsClient` in package `com.acme.metrics`. A user of your library writes their app in `com.theircompany.app` and adds `@SpringBootApplication`. Will your `MetricsClient` be picked up? Why or why not? What are two ways to make it reliably register, and which is idiomatic for a library (versus an application)? Relate your answer to how Spring Boot itself registers its own beans.

---




[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]