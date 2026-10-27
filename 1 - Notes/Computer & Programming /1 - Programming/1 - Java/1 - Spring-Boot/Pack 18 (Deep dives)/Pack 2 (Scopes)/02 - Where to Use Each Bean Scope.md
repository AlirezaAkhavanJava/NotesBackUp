

Picking a scope is really one question: **"Whose data does this bean hold, and for how long?"** If the bean holds no data, or only data that everyone should share, it is a singleton. If it holds data that belongs to one task, one request, one user, or one connection, it gets a shorter-lived scope that matches.

In this lesson we'll use a single imaginary online shop and walk through each scope as a real situation that comes up. For each one you'll see the scenario first, why that scope is the right fit, and then working code.

---

## Quick chooser

|If the bean holds data that belongs to...|Use|
|---|---|
|Nobody (stateless), or data everyone shares|`singleton`|
|One short task you create on demand|`prototype`|
|One HTTP request|`request`|
|One user's browser session|`session`|
|The whole web app, shared by all users|`application`|
|One WebSocket connection|`websocket`|

---

## 1. Singleton: the shop's product service and rate cache

**Scenario.** Your shop shows prices in several currencies. Exchange rates are the same for every customer, and a scheduled job refreshes them every few minutes. You also have a `ProductService` that loads products from the database.

**Why singleton?** Nothing here belongs to one user. Creating a new `ProductService` per request would waste memory for no benefit. One shared object is exactly what you want, as long as it is **stateless** or its state is **thread-safe**.

```java
@Service
public class ProductService {

    private final ProductRepository repository;

    public ProductService(ProductRepository repository) {
        this.repository = repository;
    }

    public Product findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("No product " + id));
    }
}
```

This one has no mutable fields, so it is safe for everyone to share.

```java
@Component
public class ExchangeRateCache {

    private final Map<String, BigDecimal> rates = new ConcurrentHashMap<>();

    public void update(String currency, BigDecimal rate) {
        rates.put(currency, rate);
    }

    public Optional<BigDecimal> get(String currency) {
        return Optional.ofNullable(rates.get(currency));
    }
}
```

**What happens:** this singleton does hold state (the rates), which is fine because the state is meant to be shared and a `ConcurrentHashMap` is safe when many threads touch it at once. A plain `HashMap` here would be a bug.

---

## 2. Prototype: one CSV import job per upload

**Scenario.** An admin uploads a CSV of new products. Each import must count its own successes and collect its own error messages. Two admins importing at the same time must not mix their results.

**Why prototype?** Every import needs its **own fresh object** with its own counters. A prototype bean gives you a new instance each time you ask for one.

```java
@Component
@Scope("prototype")
public class CsvImportJob {

    private int imported;
    private final List<String> errors = new ArrayList<>();

    public void process(String line) {
        String[] parts = line.split(",");
        if (parts.length != 2) {
            errors.add("Bad line: " + line);
            return;
        }
        imported++;   // real code would save the product here
    }

    public ImportResult result() {
        return new ImportResult(imported, errors);
    }
}

public record ImportResult(int imported, List<String> errors) { }
```

The service that uses it is a singleton, so it must ask for a **new** job each time with `ObjectProvider`:

```java
@Service
public class ImportService {

    private final ObjectProvider<CsvImportJob> jobProvider;

    public ImportService(ObjectProvider<CsvImportJob> jobProvider) {
        this.jobProvider = jobProvider;
    }

    public ImportResult importFile(List<String> lines) {
        CsvImportJob job = jobProvider.getObject();   // brand-new job
        lines.forEach(job::process);
        return job.result();
    }
}
```

**What happens:** each call to `importFile` gets its own `CsvImportJob`. If you injected `CsvImportJob` directly into `ImportService`, you would get just **one** job, forever, because the singleton is built once. `ObjectProvider` is the fix.

---

## 3. Request scope: the current tenant (or correlation ID)

**Scenario.** Your shop serves several stores (tenants) from one app. Every request carries an `X-Tenant-Id` header, and many layers need to know which store is calling. Passing `tenantId` through every method signature gets messy.

**Why request scope?** The tenant is true for **this request only**. A request bean holds it once, and any class can read it during that request, then it disappears.

```java
@Component
@RequestScope
public class TenantContext {

    private String tenantId;

    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
}
```

A filter fills it in at the start of every request:

```java
@Component
public class TenantFilter extends OncePerRequestFilter {

    private final TenantContext tenantContext;

    public TenantFilter(TenantContext tenantContext) {
        this.tenantContext = tenantContext;   // this is a proxy
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        String tenant = request.getHeader("X-Tenant-Id");
        tenantContext.setTenantId(tenant != null ? tenant : "default");
        chain.doFilter(request, response);
    }
}
```

Any service can now read it:

```java
@Service
public class PricingService {

    private final TenantContext tenantContext;

    public PricingService(TenantContext tenantContext) {
        this.tenantContext = tenantContext;
    }

    public String describe() {
        return "Prices for store: " + tenantContext.getTenantId();
    }
}
```

**What happens:** the filter and `PricingService` are both singletons, yet each holds a **proxy** for `TenantContext`. On every call, the proxy finds the real `TenantContext` for the current request. Two requests at the same moment each see their own tenant. (Spring Boot registers the filter that makes request scope available before your own filters run, so this works out of the box.)

The same pattern works for a **correlation ID** in logs, an **audit context** (who did what), or request timing.

---

## 4. Session scope: the shopping cart

**Scenario.** A visitor browses your shop and adds items over many page loads, before they've even logged in. Their cart must follow them across requests, and must not leak to anyone else.

**Why session scope?** The cart belongs to **one user's browser session** and must outlive a single request. That's exactly what a session bean is.

```java
@Component
@SessionScope
public class ShoppingCart implements Serializable {

    private final Map<String, Integer> items = new LinkedHashMap<>();

    public void add(String sku, int quantity) {
        items.merge(sku, quantity, Integer::sum);
    }

    public Map<String, Integer> getItems() {
        return Collections.unmodifiableMap(items);
    }

    public void clear() {
        items.clear();
    }
}
```

```java
@RestController
@RequestMapping("/cart")
public class CartController {

    private final ShoppingCart cart;
    private final OrderService orderService;

    public CartController(ShoppingCart cart, OrderService orderService) {
        this.cart = cart;
        this.orderService = orderService;
    }

    @PostMapping("/add")
    public Map<String, Integer> add(@RequestParam String sku,
                                    @RequestParam(defaultValue = "1") int qty) {
        cart.add(sku, qty);
        return cart.getItems();
    }

    @GetMapping
    public Map<String, Integer> view() {
        return cart.getItems();
    }

    @PostMapping("/checkout")
    public String checkout() {
        orderService.placeOrder(cart.getItems());
        cart.clear();
        return "Order placed";
    }
}
```

**What happens:** Anna adds 2 shirts, Ben adds a mug. They each have a separate `ShoppingCart`. When Anna refreshes the page, her cart is still there, because her session is still alive. After `checkout`, we clear it.

Other good fits: a **multi-step checkout wizard** (shipping step, then payment step) and **per-user preferences** like theme or language.

Two cautions:

- If your API is **stateless** (for example JWT tokens and no server session), session scope isn't a good fit, because there's no session to attach to.
- Session beans stay in memory until the session expires. Keep them small.

---

## 5. Application scope: a site-wide visitor counter

**Scenario.** The shop's home page footer says "Visits so far: 18,204", and the number is the same for everyone.

**Why application scope?** The data belongs to the **whole web application**, not to any one user or request.

```java
@Component
@ApplicationScope
public class VisitorCounter {

    private final AtomicLong visits = new AtomicLong();

    public long hit() {
        return visits.incrementAndGet();
    }

    public long total() {
        return visits.get();
    }
}
```

```java
@RestController
public class HomeController {

    private final VisitorCounter counter;

    public HomeController(VisitorCounter counter) {
        this.counter = counter;
    }

    @GetMapping("/")
    public String home() {
        return "Visits so far: " + counter.hit();
    }
}
```

**What happens:** every request from every user increments the same counter. Because many threads hit it at once, it uses `AtomicLong` (thread-safe), not a plain `long`.

Honest note: in a normal Spring Boot app, this behaves almost exactly like a singleton, so most developers just use a singleton. Also, the counter lives **inside one running app instance**. If you run three servers, each has its own count, and the counter resets on restart. For a real shared and persistent counter, store it in a database or Redis.

---

## 6. WebSocket scope: per-connection chat state

**Scenario.** Your shop has a live chat with support. Each connected customer has a nickname and a set of rooms they've joined, and that state must live exactly as long as their **WebSocket connection**.

**Why websocket scope?** The data belongs to **one connection**. A session bean would live too long (the HTTP session can outlive the socket), and a request bean wouldn't exist at all, since WebSocket messages aren't HTTP requests.

```java
@Component
@Scope(scopeName = "websocket", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class ChatUserSession {

    private String nickname = "guest";
    private final Set<String> rooms = new HashSet<>();

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    public Set<String> getRooms() { return rooms; }
}
```

```java
@Controller
public class ChatController {

    private final ChatUserSession userSession;

    public ChatController(ChatUserSession userSession) {
        this.userSession = userSession;
    }

    @MessageMapping("/join")
    @SendTo("/topic/chat")
    public String join(String nickname) {
        userSession.setNickname(nickname);
        return nickname + " joined the chat";
    }

    @MessageMapping("/say")
    @SendTo("/topic/chat")
    public String say(String text) {
        return userSession.getNickname() + ": " + text;
    }
}
```

**What happens:** two customers connected at once each have their own `ChatUserSession`. When Ana sends `/say`, the proxy finds **Ana's** session bean, so her message is tagged with her nickname. When her connection closes, her bean is discarded. This needs WebSocket/STOMP support enabled (`@EnableWebSocketMessageBroker`), and unlike the other web scopes, `@Scope("websocket")` has no shortcut annotation, so you add the proxy yourself.

---

## Related concept, in short

**`HttpSession` and `@SessionAttributes`** also store per-user data between requests. `HttpSession` is the raw servlet object you read and write by key, and `@SessionAttributes` keeps selected model attributes for one controller. A `@SessionScope` bean is usually cleaner because you work with a normal typed object, not string keys.

---

## Cheat sheet: scenario to scope

|Scenario|Scope|
|---|---|
|Services, repositories, rate cache|`singleton`|
|One import/export job per upload|`prototype`|
|Tenant, correlation ID, audit context|`request`|
|Shopping cart, checkout wizard, user preferences|`session`|
|Site-wide counter, global in-memory flags|`application`|
|Per-connection chat state|`websocket`|

And two habits to remember:

1. **Keep singletons stateless** (or thread-safe). Never put per-user data in their fields.
2. **Pick the shortest scope that still does the job.** A shorter life means less memory and fewer chances to leak data between users.





[[Spring Framework]]