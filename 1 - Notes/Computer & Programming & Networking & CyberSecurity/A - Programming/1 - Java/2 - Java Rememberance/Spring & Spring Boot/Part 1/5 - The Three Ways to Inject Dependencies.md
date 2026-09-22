

## The Three Ways to Inject Dependencies

All three achieve the same goal — the container supplying a bean's dependencies instead of the bean creating them itself — but differ in **when** and **how** the container hands them over.

---

## 1. Constructor Injection (recommended default)

Dependencies are supplied as constructor parameters.

```java
@Service
public class UserService {

    private final UserRepository userRepository;
    private final EmailService emailService;

    // @Autowired is optional here — Spring 4.3+ auto-detects
    // it when there's exactly one constructor
    public UserService(UserRepository userRepository, EmailService emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
    }
}
```

### Why it's preferred

- **Immutability** — fields can be `final`, so once constructed, dependencies can never be reassigned or left null
- **Guaranteed complete object** — you can't create a `UserService` without its dependencies; there's no half-initialized state
- **Easy to test without Spring at all**:
    
    ```java
    UserService service = new UserService(mockRepo, mockEmailService); // plain Java, no container needed
    ```
    
- **Reveals hidden complexity** — if a constructor needs 8 parameters, that's an honest signal the class is doing too much (a code smell you'd miss with field injection, since fields don't show up as visibly)
- **No circular dependency surprises** — Spring fails fast at startup if A needs B and B needs A via constructors (can't resolve → clear error), rather than letting it slip through

---

## 2. Setter Injection

Dependencies are supplied via setter methods after the object is constructed.

```java
@Service
public class UserService {

    private UserRepository userRepository;

    @Autowired
    public void setUserRepository(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

### When to actually use it

- **Optional dependencies** — the bean can function without it, and you want the option to not set it, or change it later
- Reconfiguring a bean **after** construction (rare in typical apps)

### Downsides

- Fields can't be `final` → mutable, less safe
- Object can exist in a partially-constructed state (created but dependency not yet set) → possible `NullPointerException` if used too early
- Less explicit — you have to read through the whole class to know what it actually needs, versus seeing it all in one constructor signature

---

## 3. Field Injection

Dependencies are injected directly into fields via reflection, bypassing constructors/setters entirely.

```java
@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EmailService emailService;
}
```

### Why it's common in tutorials but discouraged in real projects

- Looks the shortest/cleanest superficially — this is exactly why beginners gravitate to it
- **Can't be `final`** — mutable state, dependencies could theoretically be reassigned
- **Can't construct the object without Spring** — you can't easily do `new UserService()` and manually pass in mocks for testing; you'd need reflection or a full Spring test context, which is slower and more heavyweight
- **Hides the true number of dependencies** — no constructor signature forces you to notice "wait, this class needs 10 things, maybe I should split it up"
- Spring's own documentation explicitly recommends against it for production code

Field injection isn't _broken_ — it works — it's a design/maintainability issue, not a bug.

---

## Comparison table

||Constructor|Setter|Field|
|---|---|---|---|
|Immutability (`final`)|✅ Yes|❌ No|❌ No|
|Mandatory dependency guarantee|✅ Enforced at construction|⚠️ Not enforced|⚠️ Not enforced|
|Testability without Spring|✅ Easy (`new X(mock)`)|⚠️ Needs setter calls|❌ Hard (needs reflection)|
|Circular dependency detection|✅ Fails fast at startup|⚠️ Allowed (resolved lazily)|⚠️ Allowed (resolved lazily)|
|Good for optional dependencies|❌ Awkward|✅ Natural fit|⚠️ Possible with `required=false`|
|Verbosity|Medium|High (getter+setter pairs)|Low|
|Spring team's recommendation|✅ Preferred|Situational|❌ Avoid|

---

## How `@Autowired` resolves _which_ bean to inject (all three methods share this)

Regardless of injection style, once Spring knows a dependency is needed, it resolves _which_ bean to supply using this order:

1. **By type** — if there's exactly one bean of the required type, use it
2. **If multiple beans of the same type exist** — look for `@Primary` on one of them
3. **If still ambiguous** — check for `@Qualifier("beanName")` at the injection point (as we saw when discussing `@Primary`/`@Qualifier` earlier)
4. **If none of the above resolves it** — Spring throws `NoUniqueBeanDefinitionException` (too many candidates) or `NoSuchBeanDefinitionException` (zero candidates) at startup

This connects back to the bean lifecycle — this resolution happens during **step 3, "populate properties,"** before `@PostConstruct` runs, regardless of which injection style you used.

---

## Practical guidance for your own projects

```java
@Service
public class OrderService {

    // required dependencies — constructor injection
    private final OrderRepository orderRepository;
    private final PaymentGateway paymentGateway;

    // optional dependency — setter injection, with a sensible default
    private NotificationService notificationService = new NoOpNotificationService();

    public OrderService(OrderRepository orderRepository, PaymentGateway paymentGateway) {
        this.orderRepository = orderRepository;
        this.paymentGateway = paymentGateway;
    }

    @Autowired(required = false)
    public void setNotificationService(NotificationService notificationService) {
        this.notificationService = notificationService;
    }
}
```

**Default rule of thumb:** use constructor injection for everything unless you have a specific reason (truly optional dependency) to reach for setter injection. Avoid field injection outside of quick test/demo code.


---


## Circular Dependencies with Constructor Injection

A circular dependency is when two (or more) beans depend on each other, directly or through a chain:

```java
@Service
public class UserService {
    private final OrderService orderService;

    public UserService(OrderService orderService) { // needs OrderService
        this.orderService = orderService;
    }
}

@Service
public class OrderService {
    private final UserService userService;

    public OrderService(UserService userService) { // needs UserService
        this.userService = userService;
    }
}
```

### Why this breaks with constructor injection specifically

Remember the bean lifecycle: **constructor runs → dependencies are populated → `@PostConstruct`**. For constructor injection, the dependency must **fully exist** before the constructor can even be called (you can't call `new UserService(orderService)` without an already-existing `orderService`).

So the container tries:

```
1. Create UserService → needs OrderService first
2. Create OrderService → needs UserService first
3. Create UserService → needs OrderService first
4. ... infinite loop
```

Spring detects this at startup and fails fast with a clear error:

```
BeanCurrentlyInCreationException: Error creating bean with name 'userService':
Requested bean is currently in creation: Is there an unresolvable circular reference?
```

**This is actually a feature, not a limitation** — as I mentioned before, constructor injection surfaces this problem immediately and loudly, at startup, rather than letting it hide.

### Why the "textbook workaround" (`@Lazy`) exists — but you should be suspicious of it

```java
@Service
public class UserService {
    private final OrderService orderService;

    public UserService(@Lazy OrderService orderService) {
        this.orderService = orderService;
    }
}
```

`@Lazy` here makes Spring inject a **proxy** (yes — same proxy mechanism as AOP and Spring Data repositories) instead of the real bean. The proxy defers actually resolving `OrderService` until its first method call, by which point both beans have finished constructing. This breaks the deadlock.

**Setter or field injection technically "solve" this too**, without needing `@Lazy` — because the object can be constructed empty first, then both objects get their dependencies filled in afterward, in a second pass:

```java
@Service
public class UserService {
    @Autowired
    private OrderService orderService; // set after construction — no deadlock
}
```

### Why this is the wrong fix in almost every real case

A circular dependency is Spring's way of telling you: **your class design has a problem.** Two services needing each other directly almost always means responsibilities are tangled together. The real fix is usually one of:

1. **Extract shared logic into a third service** that both depend on:
    
    ```java
    @Servicepublic class UserOrderService { // shared logic    // logic both UserService and OrderService need}
    ```
    
2. **Use events instead of a direct call** — `OrderService` publishes an event, `UserService` listens, no direct reference needed:
    
    ```java
    @Servicepublic class OrderService {    private final ApplicationEventPublisher publisher;    public void placeOrder() {        // ...        publisher.publishEvent(new OrderPlacedEvent(orderId));    }}@Componentpublic class UserNotifier {    @EventListener    public void onOrderPlaced(OrderPlacedEvent event) {        // react without a direct dependency    }}
    ```
    
3. **Merge the two classes** if they're really one responsibility split awkwardly in two

**Rule of thumb:** if you ever reach for `@Lazy` to fix a circular dependency, treat it as a temporary patch and a signal to refactor — not a real solution.

---

## How `@Transactional` Works Under the Hood

This ties directly back to **AOP** and **proxies**, which we already covered — `@Transactional` is Spring's own built-in aspect.

### The annotation

```java
@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final InventoryRepository inventoryRepository;

    public OrderService(OrderRepository orderRepository, InventoryRepository inventoryRepository) {
        this.orderRepository = orderRepository;
        this.inventoryRepository = inventoryRepository;
    }

    @Transactional
    public void placeOrder(Order order) {
        orderRepository.save(order);              // step 1
        inventoryRepository.decreaseStock(order);  // step 2
        // if step 2 throws, step 1 is automatically rolled back
    }
}
```

### What happens at startup

1. Spring sees the `@Transactional` annotation (this detection is enabled by `@EnableTransactionManagement`, which Spring Boot auto-configures for you when it sees a `DataSource` on the classpath)
2. Just like with the `@Aspect` classes we wrote earlier, Spring creates a **proxy** wrapping `OrderService`
3. This proxy is what actually goes into the container's bean map — not your raw `OrderService`

### What happens on each call — step by step

```
Caller → proxy.placeOrder(order)
           │
           ├─ 1. Proxy intercepts the call (this is the "around advice" we wrote manually earlier with @Around)
           ├─ 2. Gets a DB Connection from the DataSource, sets autocommit = false, starts a transaction
           ├─ 3. Calls the REAL placeOrder() method on your actual object
           │       ├─ orderRepository.save(order)          → SQL runs, but not committed yet
           │       └─ inventoryRepository.decreaseStock()   → SQL runs, but not committed yet
           ├─ 4a. If no exception → proxy calls connection.commit()
           └─ 4b. If a RuntimeException is thrown → proxy calls connection.rollback()
```

This is **literally the same mechanism** as the `@Around` advice example from earlier — Spring's built-in transaction interceptor is conceptually:

```java
public Object invoke(MethodInvocation invocation) throws Throwable {
    TransactionStatus status = transactionManager.getTransaction(...);
    try {
        Object result = invocation.proceed(); // your real method runs here
        transactionManager.commit(status);
        return result;
    } catch (RuntimeException ex) {
        transactionManager.rollback(status);
        throw ex;
    }
}
```

### This is exactly why the "self-invocation" gotcha exists (mentioned back when we covered AOP)

```java
@Service
public class OrderService {

    @Transactional
    public void placeOrder(Order order) {
        saveInternal(order); // calling 'this.saveInternal()' directly
    }

    @Transactional
    public void saveInternal(Order order) {
        orderRepository.save(order);
    }
}
```

When `placeOrder()` calls `saveInternal()`, it's calling it on `this` — the **real object**, not the proxy. The proxy is only ever entered from **outside** the class. So `saveInternal`'s own `@Transactional` is silently ignored in this scenario; it just runs as part of `placeOrder`'s existing transaction (or with no transaction at all, if called from a non-transactional context) — a very common, confusing bug for beginners.

### Important detail: only `RuntimeException` triggers rollback by default

```java
@Transactional
public void placeOrder(Order order) throws IOException {
    orderRepository.save(order);
    if (somethingWrong) {
        throw new IOException("checked exception"); // does NOT roll back by default!
    }
}
```

By default, Spring only rolls back on **unchecked exceptions** (`RuntimeException` and its subclasses). To also roll back on a checked exception, you must say so explicitly:

```java
@Transactional(rollbackFor = IOException.class)
```

### Useful `@Transactional` attributes

```java
@Transactional(
    propagation = Propagation.REQUIRED,     // join existing transaction, or create new one (default)
    isolation = Isolation.READ_COMMITTED,   // DB isolation level
    readOnly = true,                        // optimization hint — no writes expected
    timeout = 5                             // seconds before forced rollback
)
```

- `readOnly = true` is genuinely worth using on query-only service methods — it can let Hibernate skip dirty-checking and some DBs optimize the query plan

---

## The through-line connecting everything we've covered

|Concept|Mechanism|
|---|---|
|IoC Container|Heap-allocated object holding a `Map<String, Object>` of beans|
|DI|Container calls your constructor/setter with already-created beans|
|AOP (`@Aspect`)|Proxy intercepts method calls, runs advice, delegates to real object|
|Spring Data repositories|JDK dynamic proxy + method-name parsing → generated JPQL|
|`@Transactional`|Built-in AOP-style proxy wrapping commit/rollback around your method|
|`@RestControllerAdvice`|Separate mechanism — `DispatcherServlet`'s exception resolver chain|
|Circular dependency failure|Constructor injection can't resolve mutual "needs it before it exists"|

Every one of these "magic" Spring Boot features reduces to the same handful of ideas: **the container owns object creation**, and **proxies intercept method calls** to inject cross-cutting behavior — nothing more exotic than that, running inside the same JVM heap/stack model from your very first question.




[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]
[[Java]]
[[11 - IoC & DI 🍩]]
[[12 - DI & AutoWired 🍩]]
[[4 - What is dependency and DI]]

