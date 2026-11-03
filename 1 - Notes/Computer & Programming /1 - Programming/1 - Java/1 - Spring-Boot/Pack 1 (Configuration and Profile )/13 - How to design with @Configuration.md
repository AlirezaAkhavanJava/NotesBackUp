---

---


Spring's IoC container is like a warehouse. It **finds** your classes, **builds** them, **connects** the ones that need each other, and **hands** each one to whoever asks. The annotations below are your instructions to that warehouse: what to build, what to deliver, and what to do when two items look alike.

Almost everything comes down to three questions: _how does a bean get created?_, _how does it get injected?_, and _what if there are two candidates?_

---

## 1. Creating beans: two ways

|Your situation|Use|
|---|---|
|Your own class|`@Service`, `@Repository`, `@RestController`, `@Component`|
|A third-party class you can't edit (`DataSource`, `ObjectMapper`)|`@Bean` method inside a `@Configuration` class|

```java
@Configuration
public class AppConfig {
    @Bean
    public TransferService transferService() {
        return new TransferServiceImpl();
    }
}
```

The bean name is the method name. Method parameters are its dependencies, resolved like constructor injection. Keep one config class per concern (`SecurityConfig`, `JacksonConfig`, `WebConfig`).

**Bean method tips:**

- Return the most specific type you can. It helps Spring predict types early, which matters for AOT/native builds.
- Don't make `@Bean` methods `private` in a normal `@Configuration`, because the CGLIB proxy can't override them.
- `AutoCloseable` beans are closed automatically on shutdown. Use `destroyMethod = ""` to turn that off.

---

## 2. `@Configuration` vs `@Component`: the proxy question

This is the most misunderstood part. `@Configuration` creates a **CGLIB proxy** around your class by default (`proxyBeanMethods = true`).

**Full mode (default):** if one `@Bean` method calls another, the proxy returns the existing singleton.

```java
@Bean public Foo foo() { return new Foo(bar()); } // gets THE singleton Bar
@Bean public Bar bar() { return new Bar(); }
```

**Lite mode** (`@Configuration(proxyBeanMethods = false)`, or `@Component` with `@Bean` methods): there is no proxy, so `bar()` is a plain Java call that creates a **second** Bar.

The fix in lite mode is to take dependencies as parameters:

```java
@Bean public Foo foo(Bar bar) { return new Foo(bar); }
```

**Rule of thumb:**

- Methods call each other? Use the default full mode.
- Methods are independent? Use `proxyBeanMethods = false`. It starts faster and works better with GraalVM.
- Safest habit: always inject beans as parameters, and lite mode never bites you.

---

## 3. Injecting beans: use the constructor

```java
@Service
@RequiredArgsConstructor
public class OrderService {
    private final PaymentGateway paymentGateway;
    private final InventoryService inventoryService;
}
```

**Why not field injection (`@Autowired private Foo foo`)?**

- Fields can't be `final`, so dependencies can change.
- You can't easily unit-test without Spring.
- A class can quietly grow 10+ dependencies without anyone noticing.
- Circular dependencies hide until runtime. Constructors fail fast at startup.

**Details:**

- With **one constructor**, `@Autowired` is optional. With **several**, mark the one Spring should use.
- For optional dependencies, use `ObjectProvider<T>` or `Optional<T>` (not `required = false`):

```java
MeterRegistry registry = meterRegistryProvider.getIfAvailable();
```

- **Lombok trap:** `@RequiredArgsConstructor` does not copy `@Qualifier` to constructor parameters, so the qualifier is silently lost. Fix it in `lombok.config`:

```properties
lombok.copyableAnnotations += org.springframework.beans.factory.annotation.Qualifier
```

---

## 4. Two beans of the same type? Disambiguate

Spring picks in this order:

1. **`@Qualifier` at the injection point** (explicit, always wins)
2. **`@Primary`** (global default)
3. Otherwise it fails with an ambiguity error (unless the parameter name happens to match a bean name)

`@Fallback` (Spring 6.2+) is the opposite of `@Primary`: that bean is used only if no other candidate exists.

```java
public NotificationDispatcher(@Qualifier("emailNotificationService") NotificationService email) { ... }
```

**Type-safe qualifiers:** make your own annotation to avoid string typos.

```java
@Target({FIELD, PARAMETER, METHOD, TYPE})
@Retention(RUNTIME)
@Qualifier
public @interface Email {}

@Service @Email
class EmailNotificationService implements NotificationService {}

// injection point
public Dispatcher(@Email NotificationService email) { ... }
```

**Advice:** qualify at the injection point, and use `@Primary` sparingly, only for sensible infrastructure defaults like a main `ObjectMapper`.

---

## 5. Related tools worth knowing

|Annotation|What it does|
|---|---|
|`@Scope("prototype")`|New instance each time it's injected|
|`@Lazy`|Create on first use, and can break circular dependencies|
|`@Profile("prod")`|Register only in that profile|
|`@ConditionalOnMissingBean` / `@ConditionalOnProperty`|Conditional registration (the basis of auto-configuration)|
|`@ConfigurationProperties(prefix=...)`|Type-safe binding of properties, better than scattered `@Value`|
|`@Import`|Pull in another config class explicitly|
|`@ComponentScan`|Choose scanned packages. Usually leave the default and keep the main class in the root package|

Circular dependency fix, if refactoring isn't possible:

```java
public A(@Lazy B b) { this.b = b; }
```

---

## 6. Common pitfalls

- Calling a `@Bean` method directly in lite mode creates a duplicate instance. Inject it instead.
- Lombok drops `@Qualifier` unless configured.
- Putting `@Bean` methods for third-party classes inside a `@Service` mixes concerns. Use a config class.
- With Jackson 3 in Spring Boot 4, the auto-configured mapper is a `JsonMapper`. Check which type your override should return so it actually replaces the default.

---

## Cheat sheet

|Question|Answer|
|---|---|
|Third-party class?|`@Bean` in `@Configuration`|
|Own class?|`@Service` etc. + constructor injection|
|Need a default among several?|`@Primary`|
|Need a specific one here?|`@Qualifier`|
|`@Bean` methods call each other?|Full mode|
|Independent `@Bean` methods?|`proxyBeanMethods = false`|
|Optional dependency?|`ObjectProvider<T>`|

**One-line summary:** stereotypes for your code, `@Bean` for external code, constructor injection everywhere, `@Qualifier` before `@Primary`.



[[Spring Framework]]