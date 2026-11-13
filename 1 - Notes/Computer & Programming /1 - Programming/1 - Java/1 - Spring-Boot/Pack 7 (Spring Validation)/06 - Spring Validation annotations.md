
These are the seven groups from the "study next" list. They build on each other: validation feeds the controller tests in section 7, `@Query` and `@EntityGraph` sit under the `@Transactional` boundary you already know, and `@Async` connects back to your thread and connection-pool lessons. Each section stands on its own, so you can read them in any order.

I'm assuming you know the constraint annotations from your validation-messages lesson, the proxy rules (public methods, no self-invocation), and the `ProblemDetail` handler. Those are used below but not repeated.

---

## 1. `@Valid` and `@Validated`

Both annotations trigger validation. The difference is where they work and what they add:

||`@Valid`|`@Validated`|
|---|---|---|
|Comes from|Jakarta Bean Validation|Spring|
|Triggers validation of the annotated object|Yes|Yes|
|Cascades into nested objects|Yes, put it on the field|No|
|Validation groups|No|Yes|
|On a class: validates method parameters of that bean|No|Yes|

**Nested objects are only validated if you cascade.** `@NotNull` on a nested field checks that it exists, not what's inside it.

```java
public record CreateOrderRequest(
        @NotNull Long productId,
        @Positive int quantity,
        @NotNull @Valid AddressRequest shipTo,
        @NotEmpty List<@Valid ItemRequest> items) {}
```

`List<@Valid ItemRequest>` validates each element, and `@NotEmpty` checks the list itself.

**Where validation fires, and what it throws:**

```java
@PostMapping
public ResponseEntity<OrderResponse> create(@Valid @RequestBody CreateOrderRequest request) { ... }

@GetMapping("/{id}")
public OrderResponse get(@PathVariable @Positive Long id) { ... }
```

- A failing `@Valid @RequestBody` throws `MethodArgumentNotValidException`.
- A failing constraint directly on `@PathVariable` or `@RequestParam` throws `HandlerMethodValidationException`. Since Spring 6.1, controllers validate these parameters on their own, with no class-level annotation needed.
- If you put `@Validated` on the controller class, Spring switches to the older proxy-based route, and failures become `ConstraintViolationException`. Pick one style per project.

**On service beans**, class-level `@Validated` is what makes parameter constraints work:

```java
@Service
@Validated
public class ProductService {
    public ProductResponse find(@Positive Long id) { ... }
    public void rename(@NotBlank @Size(max = 80) String name) { ... }
}
```

That throws `ConstraintViolationException`, so your advice needs a handler for it. If your advice extends `ResponseEntityExceptionHandler`, the two Spring exceptions are already handled.

```java
@ExceptionHandler(ConstraintViolationException.class)
public ProblemDetail handleConstraintViolation(ConstraintViolationException ex) {
    ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
    problem.setProperty("errors", ex.getConstraintViolations().stream()
            .map(v -> v.getPropertyPath() + ": " + v.getMessage())
            .toList());
    return problem;
}
```

**Groups** let one DTO have different rules for create and update:

```java
public interface OnCreate {}
public interface OnUpdate {}

public record ProductRequest(
        @Null(groups = OnCreate.class) @NotNull(groups = OnUpdate.class) Long id,
        @NotBlank(groups = {OnCreate.class, OnUpdate.class}) String name) {}

@PostMapping
public ProductResponse create(@Validated(OnCreate.class) @RequestBody ProductRequest request) { ... }
```

Groups work, but two separate records (`CreateProductRequest`, `UpdateProductRequest`) are usually clearer and need no extra marker interfaces.

---

## 2. `@Query`, `@Modifying` and `@EntityGraph`

Derived method names (`findByStatus`) stop being readable once a query has three conditions. These three annotations cover the cases that remain: custom reads, bulk writes, and controlling what gets loaded.

**`@Query` for custom reads.** JPQL works on entities and fields, not tables and columns:

```java
public interface OrderRepository extends JpaRepository<Order, Long> {

    @Query("""
           select o from Order o
           where o.status = :status and o.createdAt >= :since
           order by o.createdAt desc
           """)
    List<Order> findRecent(@Param("status") OrderStatus status, @Param("since") Instant since);
}
```

`@Param` binds the `:name` placeholders. Spring Boot's build setup keeps parameter names, so it is often optional, but being explicit costs nothing. Add `nativeQuery = true` for raw SQL, and cast enum parameters as you saw in the `@JdbcTypeCode` lesson.

**`@Modifying` for bulk writes.** `@Query` normally means a read, so a bulk update needs this marker:

```java
@Transactional
@Modifying(clearAutomatically = true)
@Query("update Order o set o.status = :to where o.status = :from and o.createdAt < :before")
int expireOld(@Param("from") OrderStatus from, @Param("to") OrderStatus to,
              @Param("before") Instant before);
```

- It returns the number of rows changed.
- A bulk update goes straight to the database and bypasses the persistence context, so entities you already loaded keep stale values. `clearAutomatically = true` clears the context afterwards, and `flushAutomatically = true` flushes pending changes first.
- Add `@Transactional` on the method (or call it from a transactional service). Spring Data's repository methods default to read-only transactions, and PostgreSQL will reject an `UPDATE` inside one.

**`@EntityGraph` for fetching.** This is the fix for the N+1 problem from your relationship lessons. Loading 100 orders and then reading `order.getCustomer().getName()` in a loop runs 1 query for the orders plus 100 for the customers. Tell Spring to fetch the relation in the same query:

```java
@EntityGraph(attributePaths = {"customer"})
List<Order> findByStatus(OrderStatus status);

@EntityGraph(attributePaths = {"customer", "items"})
@Query("select o from Order o where o.id = :id")
Optional<Order> findDetailed(@Param("id") Long id);
```

Be careful with two limits:

- **Fetching one collection is fine.** Fetching two collections in one query can throw `MultipleBagFetchException` or multiply your rows, so load them in separate queries.
- **Pagination plus a collection fetch** makes Hibernate paginate in memory (it logs a warning). Use `@EntityGraph` only for the single-valued relations when you return a `Page`.

---

## 3. `@PreAuthorize` with `@EnableMethodSecurity`

URL rules in your `SecurityFilterChain` protect endpoints. Method security protects the _operations_, so the rule holds no matter who calls the method. Turn it on once in your security configuration class:

```java
@Configuration
@EnableMethodSecurity
public class MethodSecurityConfig {}
```

`@PreAuthorize` takes an expression that must be true before the method runs. It uses your roles and permissions model directly:

```java
@Service
public class OrderService {

    @PreAuthorize("hasAuthority('ORDER_READ')")
    public List<OrderResponse> listAll() { ... }

    @PreAuthorize("hasRole('ADMIN') or @orderSecurity.isOwner(#id, authentication)")
    public OrderResponse get(Long id) { ... }

    @PostAuthorize("returnObject.ownerEmail() == authentication.name")
    public OrderResponse getDetailed(Long id) { ... }
}

@Component("orderSecurity")
public class OrderSecurity {
    private final OrderRepository orders;
    // constructor ...
    public boolean isOwner(Long orderId, Authentication auth) {
        return orders.existsByIdAndOwnerEmail(orderId, auth.getName());
    }
}
```

The pieces you can use inside the expression:

|Piece|Meaning|
|---|---|
|`hasRole('ADMIN')` / `hasAuthority('X')`|Role (the `ROLE_` prefix is added for you) or exact authority|
|`#id`|The method parameter named `id`|
|`authentication`, `principal`|The current `Authentication` and its principal|
|`@orderSecurity.isOwner(...)`|Call a method on a bean, for rules that need the database|
|`returnObject`|The return value (`@PostAuthorize` only)|

You can bundle a rule into your own annotation, which keeps expression strings out of your code:

```java
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@PreAuthorize("hasRole('ADMIN')")
public @interface AdminOnly {}
```

Things that catch people:

- **`@PostAuthorize` runs after the method.** If the method wrote data, the write already happened before the check. Use it for reads only.
- **A catch-all `@ExceptionHandler(Exception.class)` turns 403 into 500.** A denied call throws `AccessDeniedException` (specifically `AuthorizationDeniedException` in recent versions), and a catch-all handler swallows it. Add a specific handler for it or rethrow.
- **Same proxy rules as `@Transactional`.** A self-invocation skips the check.
- **Scheduled jobs have no logged-in user.** Don't call `@PreAuthorize` methods from them; give the job an internal method without the annotation.

---

## 4. `@Cacheable` with Redis

Spring's cache annotations wrap a method so that a repeated call with the same arguments returns the stored result instead of running the method. Redis is the storage behind it, which means the cache is shared between all instances of your app and survives restarts.

Dependencies and properties:

```properties
spring.data.redis.host=localhost
spring.data.redis.port=6379
spring.cache.type=redis
spring.cache.redis.time-to-live=10m
spring.cache.redis.cache-null-values=false
```

Add `spring-boot-starter-cache` and `spring-boot-starter-data-redis`, put `@EnableCaching` on a configuration class, and use the annotations on service methods:

```java
@Service
@Transactional(readOnly = true)
public class ProductService {

    @Cacheable(cacheNames = "products", key = "#id", unless = "#result == null")
    public ProductResponse getProduct(Long id) { ... }

    @CachePut(cacheNames = "products", key = "#result.id()")
    @Transactional
    public ProductResponse update(Long id, UpdateProductRequest request) { ... }

    @CacheEvict(cacheNames = "products", key = "#id")
    @Transactional
    public void delete(Long id) { ... }
}
```

|Annotation|Behavior|
|---|---|
|`@Cacheable`|Check the cache first; run the method only on a miss, then store the result|
|`@CachePut`|Always run the method, then overwrite the cache entry|
|`@CacheEvict`|Remove an entry (`allEntries = true` clears the whole cache)|
|`key`|SpEL expression for the cache key; defaults to all parameters|
|`condition`|Checked _before_ the call: should caching apply at all?|
|`unless`|Checked _after_ the call, with `#result` available: should this result be skipped?|

Rules that decide whether caching helps or hurts:

- **Cache DTOs, not entities.** Entities hold lazy proxies and can't be stored cleanly.
- **Every entry needs a way to expire.** A time-to-live is the safety net; `@CachePut` and `@CacheEvict` on write methods keep entries fresh in between. For a different TTL per cache, use a `RedisCacheManagerBuilderCustomizer` bean.
- **Serialization.** By default, values are stored with Java serialization, so your DTO records must `implements Serializable`. To store readable JSON instead, use a Jackson-based Redis serializer. In Spring Data Redis 4 the generic one does _not_ enable default typing on its own, so a cached value can come back as a plain `Map` and fail with a `ClassCastException` on the second call. Always test a cache _hit_, not only the first call.
- Same proxy rules apply: public methods, called from another bean.

---

## 5. `@Async` and `@Scheduled`

Both annotations move work off the request thread. `@Async` runs a method on another thread when someone calls it, and `@Scheduled` runs a method on a timer. Enable them and define a bounded executor for the async work:

```java
@Configuration
@EnableAsync
@EnableScheduling
public class AsyncConfig {

    @Bean(name = "mailExecutor")
    public ThreadPoolTaskExecutor mailExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("mail-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        return executor;
    }
}
```

`CallerRunsPolicy` is a rejection policy: when the queue is full, the calling thread runs the task itself, which slows callers down instead of dropping work or growing without limit. It is the same executor design you saw in the thread lessons.

```java
@Service
public class NotificationService {

    @Async("mailExecutor")
    public CompletableFuture<Void> sendConfirmation(Long orderId) {
        // slow work: build and send the email
        return CompletableFuture.completedFuture(null);
    }
}
```

How `@Async` behaves:

- The return type must be `void`, `Future` or `CompletableFuture`.
- Exceptions in a `CompletableFuture` method travel inside the future. In a `void` method, they go to an `AsyncUncaughtExceptionHandler`, and the default one only logs them.
- The new thread has **no transaction and no security context** from the caller. Pass IDs into the method, not entities, and let the async method open its own transaction.

`@Scheduled` methods take no arguments, and the timing comes from one of three attributes:

```java
@Component
public class OrderJobs {

    private final OrderService orders;
    // constructor ...

    @Scheduled(fixedDelayString = "${app.jobs.expire.delay:PT10M}")
    public void expireUnpaidOrders() { orders.expireUnpaid(); }

    @Scheduled(cron = "0 0 2 * * *", zone = "UTC")
    public void nightlyCleanup() { orders.deleteOldDrafts(); }
}
```

|Attribute|Meaning|
|---|---|
|`fixedRate`|Start every N ms, measured start to start|
|`fixedDelay`|Wait N ms after the previous run _finishes_|
|`cron`|Six fields: second, minute, hour, day-of-month, month, day-of-week|

Use `fixedDelay` for jobs that could overlap themselves. The delay value above uses a property with a default and an ISO duration (`PT10M` is ten minutes).

Two important defaults:

- Spring Boot's scheduler uses **one thread by default** (`spring.task.scheduling.pool.size`), so a slow job delays every other job.
- With `spring.threads.virtual.enabled=true`, Boot uses virtual threads for both. Concurrency is then no longer limited by a pool, so your database connection pool becomes the limit.

Related concept: if you run two instances of your app, **both** run the scheduled job. A library called ShedLock makes the jobs take a lock in the database so only one instance runs each execution.

---

## 6. `@Value`, `@Primary` and `@Qualifier`

These three solve two different questions about injection. `@Value` asks "which _value_ goes here?", and `@Primary` and `@Qualifier` ask "which _bean_ goes here?".

### `@Value`

It injects a single property, with an optional default after the colon:

```java
public CheckoutService(@Value("${app.checkout.max-retries:3}") int maxRetries,
                       @Value("${app.allowed-origins}") List<String> origins) { ... }
```

A comma-separated property converts to a `List` automatically. `#{...}` is a SpEL expression (calculated), while `${...}` is a property placeholder. Use `@Value` for one or two isolated values and `@ConfigurationProperties` for groups, since it gives you validation and relaxed binding, which `@Value` does not.

### `@Primary` and `@Qualifier`

When two beans match the same type, Spring throws `NoUniqueBeanDefinitionException` because it can't choose:

```java
public interface PaymentGateway { PaymentResult charge(Money amount); }

@Component
@Primary
class StripeGateway implements PaymentGateway { ... }

@Component("paypal")
class PaypalGateway implements PaymentGateway { ... }

@Service
public class CheckoutService {
    private final PaymentGateway defaultGateway;
    private final PaymentGateway paypal;

    public CheckoutService(PaymentGateway defaultGateway,
                           @Qualifier("paypal") PaymentGateway paypal) {
        this.defaultGateway = defaultGateway;
        this.paypal = paypal;
    }
}
```

- `@Primary` marks the default winner. Injection points that say nothing get `StripeGateway`.
- `@Qualifier("paypal")` asks for one bean by name, and it **beats** `@Primary`.

Use `@Primary` when one implementation is the normal choice and others are exceptions. Use `@Qualifier` when callers must choose deliberately. When the choice happens at runtime, inject all of them instead:

```java
public CheckoutService(Map<String, PaymentGateway> gateways) { ... }   // keys are bean names
```

Since your project uses Lombok constructors, there is one trap: `@RequiredArgsConstructor` does **not** copy `@Qualifier` onto the generated constructor, so the qualifier is silently ignored. Fix it once in `lombok.config`:

```properties
lombok.copyableAnnotations += org.springframework.beans.factory.annotation.Qualifier
```

---

## 7. Slice testing with `@MockitoBean`

`@SpringBootTest` starts your whole application, which is slow. A _slice_ test starts only one layer, so it runs in a fraction of the time. `@MockitoBean` replaces a bean in that small context with a Mockito mock, so you control what the layer below returns. It replaces the old `@MockBean`, which is removed in Spring Boot 4 (and `@SpyBean` became `@MockitoSpyBean`). Boot 4 also splits the test dependencies into modular starters, so add the one for the slice you use.

**Web layer: `@WebMvcTest`.** Only controllers, advice and web configuration load:

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired MockMvc mockMvc;
    @MockitoBean OrderService orderService;

    @Test
    void rejectsZeroQuantity() throws Exception {
        mockMvc.perform(post("/api/v1/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"productId": 1, "quantity": 0, "items": []}
                                """))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(orderService);
    }

    @Test
    void returnsOrder() throws Exception {
        when(orderService.get(5L)).thenReturn(new OrderResponse(5L, OrderStatus.PAID));

        mockMvc.perform(get("/api/v1/orders/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PAID"));
    }
}
```

The first test proves your section 1 validation works without touching a database. Two things to know:

- With Spring Security on the classpath, requests are unauthenticated and get 401. Add `@WithMockUser` (from `spring-security-test`) to the test or the class.
- Filters are part of this slice. If your JWT filter is a `@Component`, the slice tries to build it and fails when `JwtService` is missing. Provide those beans with `@MockitoBean` in the test.

**Repository layer: `@DataJpaTest`.** Entities, repositories and Flyway load, and each test rolls back:

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class OrderRepositoryTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:18");

    @Autowired OrderRepository orders;

    @Test
    void findRecentFiltersByStatus() {
        // save a PAID and a PENDING order, then assert findRecent(PAID, ...) returns one
    }
}
```

`@ServiceConnection` points the test's datasource at the container automatically, with no URL to configure. Use a real PostgreSQL here, because an in-memory database won't understand your native enum types or your `@Query` native SQL. In Testcontainers 1.x, the container class has a generic parameter, so write `PostgreSQLContainer<?>`.

**Cost to watch:** every different combination of `@MockitoBean` fields creates a new Spring context, and contexts are cached per combination. If your suite gets slow, put the common mocks in a shared base class so tests reuse one context.

Related concept: plain `@Mock` from Mockito is for unit tests with no Spring at all. If you only test one service's logic, that is faster still and needs no annotation from this section.


[[Spring Framework]]