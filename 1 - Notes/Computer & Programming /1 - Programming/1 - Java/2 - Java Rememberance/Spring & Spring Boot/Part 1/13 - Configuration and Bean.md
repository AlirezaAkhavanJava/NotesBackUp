


# `@Configuration` and `@Bean` in Spring Boot — A Deep Dive

## Part 1: The Mental Model

Imagine you're running a restaurant. You don't cook every dish yourself — you have a **kitchen manager** whose job is to prepare ingredients, assemble dishes, and hand them to waiters. The waiters never make the food; they just ask the kitchen manager for it.

In Spring:
- The **ApplicationContext** is the restaurant.
- The **kitchen manager** is the container's bean factory.
- A **`@Configuration` class** is a recipe book the kitchen manager follows.
- A **`@Bean` method** is a single recipe: "to make a `DataSource`, do this..."

When Spring starts, it reads your `@Configuration` classes, runs the `@Bean` methods, and stores the results in the container. When some other component asks for a `DataSource`, Spring hands back the exact same instance the `@Bean` method produced.

That's the whole game: **`@Configuration` classes are factories; `@Bean` methods are factory methods whose return values become managed singletons (by default) in the ApplicationContext.**

The interesting part — and where 90% of the subtlety lives — is *how* Spring makes those methods behave like real factory methods instead of ordinary Java method calls. That's the "why it works this way" we'll get to.

---

## Part 2: The Mechanics — What Actually Happens

### 2.1 `@Bean` alone

```java
@Configuration
public class AppConfig {

    @Bean
    public MyService myService() {
        return new MyService();
    }
}
```

What Spring does at startup:

1. Finds `AppConfig` (via component scanning or explicit registration).
2. Sees it's annotated `@Configuration`.
3. Scans its methods for `@Bean`.
4. For each `@Bean` method, it:
   - Determines the bean name (method name by default, or `@Bean(name="...")`).
   - Determines the bean type (return type, unless the method returns a generic/interface — more later).
   - Registers a **BeanDefinition** in the container.
5. When the container is refreshed, it invokes the method and stores the return value.

The bean's lifecycle (instantiation, dependency injection, `@PostConstruct`, `InitializingBean.afterPropertiesSet`, `BeanPostProcessor`s, `@PreDestroy`) all apply to the returned object just like any `@Component`.

### 2.2 `@Bean` without `@Configuration` — the "lite" mode trap

This is the first big gotcha. You can put `@Bean` methods in a plain class:

```java
@Component   // NOT @Configuration
public class NotFullConfig {

    @Bean
    public A a() { return new A(); }

    @Bean
    public B b() { return new B(a()); }   // calls a() directly
}
```

Here, `a()` is called **twice** — once by Spring to register the `A` bean, and once inside `b()`. You get **two different `A` instances**, one of which isn't managed by Spring at all. This is "lite mode."

With `@Configuration`, `a()` is intercepted and returns the *same* singleton. This is the single most important behavioral difference, and it's why `@Configuration` exists as a distinct annotation.

### 2.3 How `@Configuration` intercepts method calls (CGLIB)

`@Configuration` classes are **subclassed at runtime via CGLIB**. Spring generates a subclass that overrides your `@Bean` methods. When `b()` calls `a()`:

- It's actually calling the overridden `a()` on the CGLIB subclass.
- That override checks: "Is there already a bean named `a` in the container?"
  - Yes → return it (don't call the real method).
  - No → call the super (real) method, register the result, return it.

This is why:

- `@Configuration` classes **cannot be `final`** — CGLIB can't subclass final classes.
- `@Bean` methods **cannot be `private` or `final`** — the subclass must override them.
- The class needs a non-private, no-arg (or Spring-injectable) constructor.

You can see the generated class in stack traces: `AppConfig$$EnhancerBySpringCGLIB$$...`.

> **Since Spring 5.2 / Boot 2.2**: `proxyBeanMethods = false` on `@Configuration` disables CGLIB proxying. Then the class behaves like lite mode but is still a "full" configuration for other purposes (like `@Import` ordering). Use it when you don't call `@Bean` methods from each other — it speeds startup and avoids the CGLIB constraint on `final`.

---

## Part 3: The Formal Contract

### 3.1 Bean naming

| Situation | Bean name |
|---|---|
| `@Bean public Foo foo()` | `foo` (method name) |
| `@Bean(name = "bar")` | `bar` |
| `@Bean({"a", "b"})` | Two names, same bean (aliases) |
| Multiple `@Bean` methods returning same type | Names disambiguate; injection by type becomes ambiguous |

### 3.2 Injection into `@Bean` methods

`@Bean` methods can declare parameters; Spring resolves them as dependencies:

```java
@Bean
public OrderService orderService(PaymentService payment, @Qualifier("primaryDs") DataSource ds) {
    return new OrderService(payment, ds);
}
```

This is preferred over calling other `@Bean` methods because it's explicit and works in lite mode too.

### 3.3 Return type and the "type narrowing" problem

Spring uses the **declared return type** of the `@Bean` method to determine the bean type for autowiring by type. If you declare a concrete class, injection by interface still works (Spring checks assignability). But if you declare a generic type, you can hit weirdness:

```java
@Bean
public List<String> names() { ... }   // bean type is List<String> — awkward to inject
```

Better: wrap in a holder type, or use `@Qualifier`.

If the method returns an interface, Spring registers the bean with that interface type — the concrete type is not discoverable by type unless you also cast at the call site. Use `@Bean` return types that are as specific as you're willing to depend on.

### 3.4 `@Bean` and `initMethod` / `destroyMethod`

```java
@Bean(initMethod = "start", destroyMethod = "stop")
public Engine engine() { return new Engine(); }
```

These are alternatives to `@PostConstruct`/`@PreDestroy` for classes you don't control. Note: `destroyMethod` defaults to `"(inferred)"`, which auto-detects `close()` or `shutdown()` on the returned object. This is why `@Bean`-produced `Closeable` resources get closed automatically.

---

## Part 4: Advanced Use & Real Patterns

### 4.1 Conditional beans

```java
@Bean
@ConditionalOnMissingBean
public CacheManager cacheManager() { return new SimpleCacheManager(); }
```

This is the backbone of Spring Boot autoconfiguration: provide a sensible default *only if the user hasn't defined their own*. Boot's `@ConditionalOnClass`, `@ConditionalOnProperty`, `@ConditionalOnMissingBean` are the key ones.

Ordering matters: user config is processed before autoconfiguration, so `@ConditionalOnMissingBean` sees user beans first.

### 4.2 Profile-specific beans

```java
@Bean
@Profile("prod")
public DataSource prodDs() { ... }

@Bean
@Profile("!prod")
public DataSource devDs() { ... }
```

### 4.3 `@Import` — composing configurations

```java
@Configuration
@Import({SecurityConfig.class, PersistenceConfig.class})
public class AppConfig { }
```

`@Import` pulls other config classes into the context. This is how you modularize. `@Import` also accepts `ImportSelector` and `ImportBeanDefinitionRegistrar` for dynamic registration — the mechanism behind `@Enable*` annotations.

### 4.4 Programmatic registration — `BeanDefinitionRegistryPostProcessor`

When you need to register beans *before* other beans are created (or based on runtime metadata), you drop below `@Bean`:

```java
public class DynamicRegistrar implements BeanDefinitionRegistryPostProcessor {
    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
        registry.registerBeanDefinition("dynamic", 
            BeanDefinitionBuilder.genericBeanDefinition(MyService.class).getBeanDefinition());
    }
}
```

This is what `@Bean` can't do — `@Bean` methods run during bean instantiation, not registration.

### 4.5 `@Bean` for `BeanPostProcessor` and `BeanFactoryPostProcessor` — a subtle trap

If you declare a `BeanPostProcessor` as a `@Bean` inside a `@Configuration` that *also* has other `@Bean` methods, those other beans may be created **before** the post-processor is registered, so they won't be processed. Declare `BeanPostProcessor`/`BeanFactoryPostProcessor` beans as `static @Bean` methods:

```java
@Bean
public static MyBeanPostProcessor myBpp() { return new MyBeanPostProcessor(); }
```

`static` forces early registration before the configuration class is instantiated.

### 4.6 `@Bean` vs `@Component`

| | `@Component` (+ `@Service`, `@Repository`) | `@Bean` |
|---|---|---|
| Where | On the class | On a method in a `@Configuration`/`@Component` class |
| Who controls instantiation | Spring (via classpath scanning + reflection) | You (you write `new`) |
| Use when | You own the class and it's a simple component | You're wiring a third-party class, need conditional logic, or need multiple instances |
| Constructor injection | Automatic | You write it (method parameters) |

Rule of thumb: `@Component` for your own classes, `@Bean` for library classes and anything requiring construction logic.

### 4.7 Prototype and other scopes

```java
@Bean
@Scope("prototype")
public Task task() { return new Task(); }
```

With prototype scope, `proxyBeanMethods = true` still intercepts calls, but each call returns a *new* instance. Careful: injecting a prototype bean into a singleton gives you one instance forever — use `@Lookup` or `ObjectProvider<Task>` to get fresh instances.

### 4.8 `@Bean` and generics

```java
@Bean
public Repository<User> userRepo() { ... }

@Bean
public Repository<Order> orderRepo() { ... }
```

Spring 4+ resolves generic types for injection, so `@Autowired Repository<User>` picks the right one. But if you have two beans of the same erased type and no generics to disambiguate, you need `@Qualifier` or `@Primary`.

---

## Part 5: Gotchas Recap

1. **Lite mode silently breaks singleton semantics.** Always use `@Configuration` unless you deliberately want `proxyBeanMethods = false`.
2. **`@Configuration` classes can't be `final`; `@Bean` methods can't be `private`/`final`.**
3. **`@Bean` return type is the bean type for autowiring.** Declare the most specific useful type.
4. **`BeanPostProcessor` `@Bean`s must be `static`.**
5. **`destroyMethod = "(inferred)"`** auto-closes `Closeable`s — can surprise you if your bean has a `close()` you didn't want called.
6. **`@ConditionalOnMissingBean`** only works reliably in autoconfiguration ordering; user config runs first.
7. **Prototype + singleton injection** = a hidden singleton. Use `ObjectProvider` / `@Lookup`.
8. **`@Bean` methods are not normal methods** when proxied — `this.a()` and `a()` inside `b()` behave differently than you'd expect from plain Java.

---

## Part 6: Test Your Understanding

**Question 1.** You have:

```java
@Configuration
public class Cfg {
    @Bean
    public A a() { System.out.println("creating A"); return new A(); }

    @Bean
    public B b() { return new B(a(), a()); }
}
```

How many times does `"creating A"` print, and why? Now change `@Configuration` to `@Component` — what changes and why? What single annotation parameter would make `@Configuration` behave like `@Component` in this respect?

**Question 2.** You're writing a Spring Boot starter. You want to provide a default `MetricsExporter` bean, but you want users to be able to override it. You also want the default to only exist if Micrometer is on the classpath and the property `metrics.enabled` is `true`. Write the `@Bean` method with the appropriate annotations, and explain why `@ConditionalOnMissingBean` must be evaluated *after* the user's configuration — and what Spring mechanism guarantees that ordering.

---




[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]