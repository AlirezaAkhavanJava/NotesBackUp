

A **scope** answers one question: _how long does a Spring bean live, and who shares it?_ When you ask Spring for a bean, it either hands you an existing object or builds a new one. The scope is the rule that decides which. By default, Spring builds one object and shares it with everyone, which is the **singleton** scope.

`@Scope` is the general annotation where you choose the rule. `@RequestScope` and `@SessionScope` are ready-made shortcuts for web apps: one bean per HTTP request, or one bean per user session. You get a bean whose lifetime matches something that already exists in the web world, so you never write cleanup code yourself.

(You wrote `@Session`. The real annotation is `@SessionScope`, so that's what I'll use.)

---

## 1. Start with the default: singleton

```java
@Service
public class PriceService {
    private int counter = 0;

    public int next() {
        return ++counter;
    }
}
```

Every class that injects `PriceService` gets the **same object**. If user A calls `next()` and gets 1, user B gets 2. That's perfect for stateless services, and a bug if you store per-user data in a field.

So the real question is: _what if a bean must hold data that belongs to one request or one user?_ That's where the other scopes come in.

---

## 2. `@Scope`: the general tool

You put it on a bean and give it a scope name.

```java
@Component
@Scope("prototype")
public class ShoppingTask {
}
```

Here is the full list of scopes Spring knows:

|Scope|Lifetime|Needs a web app?|
|---|---|---|
|`singleton` (default)|One object per Spring container|No|
|`prototype`|A **new object every time** someone asks for it|No|
|`request`|One object per HTTP request|Yes|
|`session`|One object per HTTP session (per user/browser)|Yes|
|`application`|One object per `ServletContext` (whole web app)|Yes|
|`websocket`|One object per WebSocket session|Yes|

You can write the name as a string, but constants are safer:

```java
@Scope(ConfigurableBeanFactory.SCOPE_PROTOTYPE)
@Scope(WebApplicationContext.SCOPE_REQUEST)
```

`@Scope` can also go on a `@Bean` method:

```java
@Configuration
public class AppConfig {

    @Bean
    @Scope("prototype")
    public ReportBuilder reportBuilder() {
        return new ReportBuilder();
    }
}
```

### Prototype in practice

```java
ApplicationContext ctx = ...;
ShoppingTask a = ctx.getBean(ShoppingTask.class);
ShoppingTask b = ctx.getBean(ShoppingTask.class);
System.out.println(a == b); // false: two different objects
```

One catch: Spring creates prototype beans but does **not** manage their destruction. `@PreDestroy` is never called on them. If the bean holds a resource, you clean it up yourself.

---

## 3. `@RequestScope`: one bean per HTTP request

It's a shortcut for `@Scope("request")`, with one extra setting (the proxy, explained in section 5).

```java
@Component
@RequestScope
public class RequestContext {
    private String requestId = UUID.randomUUID().toString();
    private long startTime = System.currentTimeMillis();

    public String getRequestId() { return requestId; }
    public long getStartTime() { return startTime; }
}
```

Now use it in a controller:

```java
@RestController
public class OrderController {

    private final RequestContext requestContext;

    public OrderController(RequestContext requestContext) {
        this.requestContext = requestContext;
    }

    @GetMapping("/orders")
    public String orders() {
        return "Handled request " + requestContext.getRequestId();
    }
}
```

Walk through it line by line:

1. A browser sends `GET /orders`. Spring creates a **fresh** `RequestContext`, with a new UUID.
2. Everything that injects `RequestContext` during this request (controller, service, repository) sees **that same object**.
3. When the response is sent, the bean is thrown away.
4. The next request gets a brand-new `RequestContext` with a different UUID.

**Good for:** request IDs for logging, the current tenant, timing data, anything you'd otherwise pass through five method parameters.

---

## 4. `@SessionScope`: one bean per user session

Same idea, but the bean lives as long as the user's HTTP session (usually tied to a cookie like `JSESSIONID`).

```java
@Component
@SessionScope
public class ShoppingCart {
    private final List<String> items = new ArrayList<>();

    public void add(String item) { items.add(item); }
    public List<String> getItems() { return items; }
}
```

```java
@RestController
@RequestMapping("/cart")
public class CartController {

    private final ShoppingCart cart;

    public CartController(ShoppingCart cart) {
        this.cart = cart;
    }

    @PostMapping("/{item}")
    public List<String> add(@PathVariable String item) {
        cart.add(item);
        return cart.getItems();
    }
}
```

What happens:

- User A adds "milk" and then "bread". Their cart holds `[milk, bread]`.
- User B (a different browser) adds "eggs". Their cart holds only `[eggs]`.
- Each user's cart survives across many requests, until the session expires or is invalidated.

Compare the two web scopes:

||`@RequestScope`|`@SessionScope`|
|---|---|---|
|Created|At the start of each request|At the first use in a session|
|Destroyed|When the request ends|When the session ends or times out|
|Shared by|Everything in one request|Every request from one user|
|Typical use|Request ID, per-request context|Cart, user preferences, wizard steps|

A practical warning: session beans are stored in the HTTP session. In a cluster of several servers, they need to be serializable (`implements Serializable`) and the session must be shared or replicated.

---

## 5. The part that confuses everyone: scoped proxies

Look back at `OrderController`. It is a **singleton**, created once at startup. But it needs a `RequestContext`, which changes on _every_ request. How can a long-lived object hold a short-lived one?

Spring solves this with a **proxy**: a stand-in object.

```java
@Component
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class RequestContext { ... }
```

`@RequestScope` and `@SessionScope` already set `proxyMode = TARGET_CLASS` for you. That's their main advantage over plain `@Scope("request")`.

How it works:

- At startup, the controller receives a **proxy** (a fake `RequestContext`).
- Whenever you call a method on that proxy, it looks up "which real `RequestContext` belongs to the current request?" and forwards the call there.

So the controller holds one proxy forever, and the proxy quietly finds the right real bean each time.

If you use plain `@Scope("request")` without a proxy, startup will fail with an error like _"Scope 'request' is not active for the current thread"_, because Spring tries to inject a request bean while no request exists yet.

An alternative that avoids proxies is injecting `ObjectProvider<RequestContext>` and calling `.getObject()` when you need it.

---

## 6. Common mistakes

1. **Using a web scope outside a web request.** In a background thread, a scheduled job, or a plain unit test, there is no request, so you get `IllegalStateException: No thread-bound request found`.
2. **Injecting a prototype into a singleton and expecting a new one each time.** The singleton is built once, so it gets one prototype once. Use `ObjectProvider<T>` to get a fresh one on demand.
3. **Storing user data in a singleton field.** It's shared between all users. Use a request or session bean, or pass data in method arguments.
4. **Putting heavy objects in the session.** They stay in memory until the session expires, for every user.

---

## 7. Related concepts, in short

- **`@ApplicationScope`:** one bean for the whole web application (like a singleton, but tied to the `ServletContext`).
- **Singleton vs. `@ApplicationScope`:** in a normal single-context app they behave almost the same. The difference only appears with multiple Spring contexts in one web app.
- **Custom scopes:** you can implement the `Scope` interface and register your own (for example, a "per tenant" scope). It's rare, but this is the mechanism that powers the built-in ones.
- **Thread safety:** singleton beans are shared across threads, so they must be stateless or thread-safe. Request and session beans are safer for per-user state, though a session bean can still be hit by two simultaneous requests from the same user.

---

## Quick recap

- `@Scope` is the general switch for a bean's lifetime (`singleton`, `prototype`, `request`, `session`, ...).
- `@RequestScope` gives one bean per HTTP request.
- `@SessionScope` gives one bean per user session.
- The web scopes work because of **scoped proxies**, which `@RequestScope` and `@SessionScope` configure for you.






[[Spring Framework]]