
## Mental Model First

We already touched scope briefly when covering Beans — here's the deeper version. Go back to the stage-play analogy: the **director** (IoC container) doesn't just decide _who_ plays a role — it decides **how many copies of that actor exist**, and **how long each copy stays on stage** before a new one is cast. That's exactly what scope controls: **instance count + lifetime**, nothing more.

The critical thing to internalize before the mechanics: **scope is a property of the bean _definition_, not of the class itself.** A plain Java class has no concept of "scope" — `new User()` just makes an object. Scope only exists because the **container** decides, each time something asks for a bean, whether to hand back an _existing_ instance or manufacture a _new_ one. This directly follows from the Factory pattern we identified Spring embodies — scope is essentially "what caching policy does this factory use."

---

## Part 1: The Five Built-in Scopes, Precisely

### `singleton` (default)

**One instance per `ApplicationContext`**, created (by default) eagerly at startup, shared by every injection point.

```java
@Service // implicitly @Scope("singleton")
public class UserService { }
```

```java
UserService a = context.getBean(UserService.class);
UserService b = context.getBean(UserService.class);
a == b; // true — literally the same object reference
```

**Why this is correct default for most Spring beans:** `UserService`, `UserRepository`, `OrderController` — these are typically **stateless** (no mutable per-request data stored in fields), so sharing one instance across the entire app is safe and efficient. This is why 95% of the beans in a typical app never specify scope at all.

**Important nuance — "singleton" is per-container, not per-JVM.** We flagged this earlier when comparing Spring's singleton to the classic GoF pattern, but it's worth being fully concrete now: if your app somehow has two `ApplicationContext`s running in the same JVM (rare, but happens in some testing setups, or apps embedding multiple Spring contexts), each gets its **own separate singleton instance**. "Singleton" here means "one per container's bean map," not "one per class, ever, anywhere."

### `prototype`

**A brand-new instance every single time** the bean is requested — via `getBean()`, or via injection into another bean.

```java
@Component
@Scope("prototype")
public class ReportGenerator {
    private List<String> lines = new ArrayList<>(); // mutable state — this is WHY it's prototype
}
```

```java
ReportGenerator a = context.getBean(ReportGenerator.class);
ReportGenerator b = context.getBean(ReportGenerator.class);
a == b; // false — different objects
```

**When you genuinely need this:** any bean holding **mutable, request-specific or call-specific state** that must not be shared. If `ReportGenerator` were a singleton and two threads called methods on it concurrently, they'd corrupt each other's `lines` list — a classic thread-safety bug. Prototype scope sidesteps this by simply never sharing the instance.

### `request` (web apps only)

**One instance per HTTP request** — created when the request starts, discarded when it ends.

```java
@Component
@Scope(value = WebApplicationContext.SCOPE_REQUEST, proxyMode = ScopedProxyMode.TARGET_CLASS)
public class RequestContext {
    private String correlationId;
    // set once per incoming HTTP request, safe to mutate within that request's lifetime
}
```

### `session` (web apps only)

**One instance per HTTP session** — persists across multiple requests from the same user's browser session, until the session expires or is invalidated.

```java
@Component
@Scope(value = WebApplicationContext.SCOPE_SESSION, proxyMode = ScopedProxyMode.TARGET_CLASS)
public class ShoppingCart {
    private List<Item> items = new ArrayList<>(); // persists across a user's browsing session
}
```

### `application`

One instance per `ServletContext` — effectively singleton-like for the whole web application, but distinct from `singleton` scope in a subtle way we'll get to below.

---

## Part 2: The Critical Mechanism — `proxyMode`, and Why It's Non-Optional for Web Scopes

This is where scope collides directly with the **proxy** mechanism we've built up across this whole conversation, and it's the part beginners consistently get wrong.

### The problem, stated precisely

```java
@Service // SINGLETON — created ONCE at startup
public class OrderService {

    @Autowired
    private ShoppingCart shoppingCart; // SESSION scoped — different instance per user!
}
```

Think through the timeline carefully: `OrderService` is a **singleton**, meaning it's constructed **once**, at application startup — before any HTTP request, before any user session even exists. At that exact moment, Spring must inject _something_ into the `shoppingCart` field. But there is no session yet — there's no user, no request, nothing to scope a `ShoppingCart` to.

**If Spring just injected one real `ShoppingCart` instance at startup**, every user would end up sharing that same cart — completely defeating the purpose of session scope, and silently so (a nightmare bug: users see each other's cart items).

### The solution — the same proxy trick, applied to scope this time

```java
@Component
@Scope(value = WebApplicationContext.SCOPE_SESSION, proxyMode = ScopedProxyMode.TARGET_CLASS)
public class ShoppingCart {
    private List<Item> items = new ArrayList<>();
}
```

`proxyMode = ScopedProxyMode.TARGET_CLASS` tells Spring: **don't inject the real bean — inject a proxy** (CGLIB, since it's `TARGET_CLASS`; use `INTERFACES` if `ShoppingCart` implements an interface, same JDK-vs-CGLIB choice we covered under AOP). This is **exactly the same proxy mechanism** as `@Transactional` and Spring Data repositories — a stand-in object satisfying the same type, injected once into the singleton `OrderService` at startup.

Here's the key behavioral difference from AOP proxies though: **this proxy doesn't wrap one fixed target — it looks up the _correct_ target dynamically, on every single method call**, based on the current thread's request/session context (Spring tracks this via a `ThreadLocal`, which is how it knows "which HTTP request/session is currently executing on this thread").

```
OrderService (singleton, created once)
    └── holds a reference to: ShoppingCart proxy (also created once)

Every time OrderService calls shoppingCart.addItem(...):
    proxy intercepts the call
    → looks up: "which session is the CURRENT thread handling?"
    → fetches (or creates) the real ShoppingCart FOR THAT SESSION
    → delegates addItem(...) to that specific instance
```

So `OrderService` holds one proxy reference forever, but **that proxy transparently redirects to a different real object depending on which user's request is currently running on the thread.** This is polymorphism doing genuinely clever work — from `OrderService`'s point of view, it's just calling a method on a `ShoppingCart`; it has no idea the proxy is playing traffic controller behind the scenes.

### What happens if you forget `proxyMode`

```java
@Component
@Scope(WebApplicationContext.SCOPE_SESSION) // no proxyMode!
public class ShoppingCart { }
```

Injecting this directly into a singleton bean throws at startup:

```
Error creating bean with name 'orderService': Scope 'session' is not active for the current thread;
consider defining a scoped proxy for this bean if you intend to refer to it from a singleton
```

Spring fails fast here — same philosophy as circular dependency detection — rather than silently doing the wrong thing.

**Important exception:** you only need `proxyMode` when injecting a narrower-scoped bean **into a wider-scoped one** (session-into-singleton, request-into-singleton). If you inject a `request`-scoped bean into a `@RestController` that's itself... wait, controllers are singletons too by default, so this still applies. The only case where you _don't_ need a scoped proxy is injecting directly where the scope naturally matches (rare in practice) — as a rule of thumb, **always use `proxyMode` for `request`/`session` scoped beans**, since they're almost always injected into singleton services/controllers.

---

## Part 3: `application` vs `singleton` — the subtle distinction

This one's genuinely obscure, but worth knowing since it clarifies what "singleton" actually scopes to:

- **`singleton`** = one instance per **`ApplicationContext`**
- **`application`** = one instance per **`ServletContext`**

In a typical Spring Boot app, there's usually a 1:1 relationship between these — one `ApplicationContext`, one `ServletContext`, so in practice they behave identically. The distinction only matters in more complex setups (e.g., a web app with **multiple** `ApplicationContext`s — like a parent context plus child contexts, common in older Spring MVC XML-configured apps, less common in modern Spring Boot) where several contexts might share **one** `ServletContext`. In that edge case, `application` scope means "shared across all those contexts," while `singleton` means "one per context" — so a bean could exist multiple times as `singleton` (once per context) but only once as `application` scope.

For your Spring Boot work specifically: you'll essentially never use `application` scope in practice — it's mentioned here mainly so you understand precisely what `singleton` is actually promising, by contrast.

---

## Part 4: Prototype Scope's Real Gotcha — Lifecycle Is Only _Partially_ Managed

This connects directly back to the bean lifecycle diagram from before, and it's a genuinely important nuance.

```java
@Component
@Scope("prototype")
public class ReportGenerator {

    @PostConstruct
    public void init() {
        System.out.println("Created"); // called every time — fine
    }

    @PreDestroy
    public void cleanup() {
        System.out.println("Destroyed"); // NEVER CALLED — this is the gotcha
    }
}
```

**Spring calls the full initialization lifecycle for prototype beans** (constructor → DI → `@PostConstruct`) every time one is created — that part matches singleton behavior. But **Spring does _not_ track prototype instances after handing them out**, and therefore **never calls `@PreDestroy`** on them. Why: for a singleton, the container holds a permanent reference in its bean map, so it always knows what to destroy at shutdown. For prototype, the container **hands over the object and forgets about it** — ownership (and cleanup responsibility) transfers entirely to _you_, the caller.

```java
@Service
@RequiredArgsConstructor
public class ReportService {

    private final ObjectProvider<ReportGenerator> reportGeneratorProvider;
    // ObjectProvider — a lazy, repeatable way to request prototype beans on demand

    public void generateReport() {
        ReportGenerator generator = reportGeneratorProvider.getObject(); // fresh instance each call
        try {
            generator.build();
        } finally {
            // if cleanup is genuinely needed, YOU must call it manually — Spring won't
            generator.cleanupManually();
        }
    }
}
```

This is a real, senior-level distinction: **singleton beans have their full lifecycle managed by the container end-to-end; prototype beans only have their _creation_ half managed — destruction is on you.** This surprises a lot of intermediate developers who assume `@PreDestroy` "just works" universally.

### Why `ObjectProvider` instead of direct injection here — connecting back to circular dependency logic

```java
@Service
@RequiredArgsConstructor
public class ReportService {
    private final ReportGenerator reportGenerator; // WRONG for this use case
}
```

If you inject a `prototype` bean directly like this into a `singleton` service, you get it **once, at `ReportService`'s construction time**, and then reuse that _same_ prototype instance forever after — completely defeating the point of prototype scope (a fresh instance per use). This is the same class of mistake as the session-into-singleton problem above, just without Spring throwing a startup error to catch it for you (prototype-into-singleton doesn't fail fast — it silently "works," just not the way you intended, which makes it more dangerous). `ObjectProvider<T>` (or the older `Provider<T>`/`ApplicationContext.getBean()` calls) is the correct pattern: it defers the actual `getBean()` call to the moment you actually need a fresh instance, rather than at construction time.

---

## Part 5: Custom Scopes — Advanced, Rarely Needed, But Shows the Real Extensibility

Spring's scope mechanism is itself pluggable — you can define entirely custom scopes by implementing `org.springframework.beans.factory.config.Scope`:

```java
public class ThreadScope implements Scope {
    private final ThreadLocal<Map<String, Object>> threadScope =
        ThreadLocal.withInitial(HashMap::new);

    @Override
    public Object get(String name, ObjectFactory<?> objectFactory) {
        return threadScope.get().computeIfAbsent(name, k -> objectFactory.getObject());
    }
    // ... remove(), registerDestructionCallback(), etc.
}
```

```java
@Configuration
public class ScopeConfig {
    @Bean
    public static CustomScopeConfigurer customScopeConfigurer() {
        CustomScopeConfigurer configurer = new CustomScopeConfigurer();
        configurer.addScope("thread", new ThreadScope());
        return configurer;
    }
}
```

```java
@Component
@Scope("thread")
public class ThreadLocalCache { }
```

You'll almost never need to write this yourself in real projects (this exact "one instance per thread" need is usually solved more simply with a plain `ThreadLocal` field), but knowing this exists reinforces something important: **`singleton`, `prototype`, `request`, `session` aren't hardcoded special cases in the framework — they're just the built-in implementations of one general `Scope` interface.** This is the abstraction/polymorphism principle from before, applied to the scoping system itself.

---

## Quick Reference Table

|Scope|Instances|Created|Destroyed by container?|Needs `proxyMode` when injected into singleton?|
|---|---|---|---|---|
|`singleton` (default)|1 per container|Eagerly at startup (default)|✅ Yes, at shutdown|N/A|
|`prototype`|New every request|On each `getBean()`/injection|❌ No — caller's responsibility|N/A (but needs `ObjectProvider`, not direct injection)|
|`request`|1 per HTTP request|On request start|✅ Yes, at request end|✅ Required|
|`session`|1 per HTTP session|On session start|✅ Yes, at session end|✅ Required|
|`application`|1 per `ServletContext`|Eagerly|✅ Yes, at context shutdown|Not typically needed|

---

## Two Questions to Test Understanding

**1.** You have a `@RestController` (singleton, by default) that needs a `request`-scoped bean injected with 
```java
proxyMode = ScopedProxyMode.TARGET_CLASS
``` 
Trace through, in your own words, **exactly what object** gets stored in the controller's field at application startup, and **when** the _real_ target instance actually gets created and resolved — connect this to the `ThreadLocal` mechanism mentioned above and to how AOP proxies decide what to delegate to.

**2.** Explain why `@Scope("prototype")` combined with `@Autowired` field/constructor injection **directly** (no `ObjectProvider`) is a subtle bug rather than a hard startup failure — while injecting a `session`-scoped bean into a singleton **without** `proxyMode` _is_ a hard startup failure. Why does Spring catch one case immediately but not the other?


[[Java]]
[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]