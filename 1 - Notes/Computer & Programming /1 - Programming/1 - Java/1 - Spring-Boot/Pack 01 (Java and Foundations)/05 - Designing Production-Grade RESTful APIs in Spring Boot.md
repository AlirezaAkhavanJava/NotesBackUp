

A REST API exposes your application's data as **resources**, such as orders, users and books. Each resource has its own URL, and clients work with it through the standard HTTP verbs (GET, POST, PUT, PATCH, DELETE). The server answers with a status code that says what happened and a body that carries the data, usually JSON.

This note covers the design rules (what the URLs, verbs and status codes should look like) and the Spring Boot code that implements them, from a first controller to the things a production API needs: validation, error format, versioning, pagination, retries and security. It builds on your Spring Web note (controllers and `DispatcherServlet`), your Entity/DTO/mapper and MapStruct notes, and your Spring Security and JWT notes, and it points back to them where they apply.

---

## Part 1: Model resources, not actions

The most common design mistake is turning URLs into function calls: `/getUserById`, `/createOrder`, `/deleteProduct`. That's RPC over HTTP. In REST the URL names a **thing** (a noun), and the HTTP verb says what to do with it.

```text
GET    /orders          list orders
POST   /orders          create an order
GET    /orders/42       read order 42
PUT    /orders/42       replace order 42
DELETE /orders/42       delete order 42
```

Think of a library. You don't ask for "fetchBookByTitle." You go to the shelf (`/books`), pick one book (`/books/978-0-13-468599-1`), and read, replace or remove it.

### What each verb promises

Proxies, CDNs and browsers rely on these promises, so don't break them.

|Verb|Meaning|Safe?|Idempotent?|
|---|---|---|---|
|GET|Read|Yes|Yes|
|POST|Create (the server picks the URL)|No|No|
|PUT|Replace the whole resource|No|Yes|
|PATCH|Change part of it|No|Not guaranteed|
|DELETE|Remove|No|Yes|

- **Safe** means it never changes server state. A GET that deletes something breaks caching and prefetching.
- **Idempotent** means doing it N times leaves the same state as doing it once. That is why a client can safely retry a PUT or DELETE after a timeout, but not a POST. Part 6 returns to this.

### Collections and items

```text
/orders                         the collection
/orders/{id}                    one order
/orders/{id}/items              the items of one order
/orders/{id}/items/{itemId}     one item
```

Nest only when the child can't exist without the parent. Keep three habits: plural nouns, lowercase with hyphens, and no verbs in the path. The **path identifies** the resource and **query parameters modify** the result (`/orders?status=open&page=0`). `/orders?id=42` is wrong, and `/orders/42` is right.

For an action that isn't plain CRUD, such as cancelling an order, treat the action as a sub-resource: `POST /orders/42/cancellation`. Or change a state field with `PATCH /orders/42`.

### Representation: what travels, and why DTOs

The resource is the concept, and the **representation** is the JSON you send for it. Spring Boot produces JSON with Jackson by default.

Never return your JPA entities directly. They carry persistence details (lazy proxies, two-way relationships, a `password` field) that don't belong in a public contract. Return a **DTO** instead. A record is ideal: short, immutable and with `equals` and `toString` for free (see your Entity/DTO/mapper note).

```java
public record UserResponse(Long id, String username, String email) {}
```

---

## Part 2: A first controller

```java
@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {   // constructor injection
        this.orderService = orderService;
    }

    @GetMapping("/{id}")
    public OrderResponse getOrder(@PathVariable Long id) {
        return orderService.findById(id);   // throws OrderNotFoundException → 404 (Part 4)
    }

    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(
            @Valid @RequestBody CreateOrderRequest request,
            UriComponentsBuilder uriBuilder) {

        OrderResponse created = orderService.create(request);
        URI location = uriBuilder.path("/api/v1/orders/{id}")
                .buildAndExpand(created.id()).toUri();
        return ResponseEntity.created(location).body(created);   // 201 + Location header
    }
}
```

Line by line:

- `@RestController` is `@Controller` plus `@ResponseBody`. The return value is written straight to the response body with Jackson, and no view resolver is involved.
- `@RequestMapping` at class level sets a base path. `@GetMapping`, `@PostMapping`, `@PutMapping`, `@PatchMapping` and `@DeleteMapping` set the verb.
- The constructor makes the dependency explicit, lets the field be `final`, and needs no `@Autowired` when there is only one constructor (see your `@Autowired` note).
- The service returns a **DTO**, not an entity. Part 7 explains why.
- `201 Created` with a `Location` header tells the client where the new resource lives.

### Where input comes from

|Annotation|Source|Example|
|---|---|---|
|`@PathVariable`|A segment of the path|`/orders/42` → `Long id`|
|`@RequestParam`|A query parameter|`?page=0&size=20`|
|`@RequestBody`|The JSON body, via Jackson|`CreateOrderRequest`|
|`@RequestHeader`|A header|`Idempotency-Key`|

### Status codes

The status code is the main answer to "what happened?" Use the precise one.

|Code|Use it when|
|---|---|
|200 OK|A GET, PUT or PATCH succeeded and returns a body|
|201 Created|A POST created something (include `Location`)|
|202 Accepted|The request was accepted but is still processing|
|204 No Content|Success with no body (typical for DELETE)|
|400 Bad Request|Malformed JSON or failed validation|
|401 Unauthorized|No valid credentials (not logged in)|
|403 Forbidden|Logged in, but not allowed|
|404 Not Found|The resource doesn't exist|
|409 Conflict|A state conflict, such as a duplicate or an optimistic-lock failure|
|412 Precondition Failed|An `If-Match` check failed|
|422 Unprocessable Entity|Valid JSON that breaks a business rule|
|429 Too Many Requests|Rate limit hit (add `Retry-After`)|
|500 Internal Server Error|An unexpected failure|

Spring already returns 405 (wrong verb), 406 (can't produce the requested type) and 415 (unsupported body type) for you. The rule that matters most: **never return 200 with an error in the body.** It breaks client error handling and monitoring.

---

## Part 3: Validation

Validation uses Jakarta Bean Validation. The same annotations appeared in your Lombok and validation-messages note, and your `@ConfigurationProperties` note used them for settings. Here they guard the request body.

Add the dependency, or `@Valid` silently does nothing:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

```java
public record CreateOrderRequest(
        @NotBlank String customerId,
        @NotNull @Valid Address shippingAddress,
        @NotEmpty List<@Valid OrderItemRequest> items) {}

public record OrderItemRequest(@NotBlank String sku, @Positive int quantity) {}
```

Line by line:

- `@Valid` on the `@RequestBody` parameter in the controller is what _starts_ validation.
- **Nested objects need their own `@Valid`.** Without it on `shippingAddress`, the constraints inside `Address` never run, and an empty address passes as valid. This is the most common silent failure.
- `List<@Valid OrderItemRequest>` validates each element of the list. Test list validation explicitly.

When validation fails, the exception depends on where the constraint is:

- A failed `@RequestBody` throws `MethodArgumentNotValidException`.
- A failed constraint on a `@PathVariable` or `@RequestParam` throws `HandlerMethodValidationException` in Spring 6.1 and later (or `ConstraintViolationException` with class-level `@Validated`).

Handle both in one place, as the next part shows.

---

## Part 4: One format for every error

Without central handling, every error looks different and clients can't parse them. `@RestControllerAdvice` catches exceptions from all controllers, and `ProblemDetail` gives them a standard shape. It follows RFC 9457 (which replaced RFC 7807) with the fields `type`, `title`, `status`, `detail` and `instance`.

```java
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(OrderNotFoundException.class)
    public ProblemDetail handleNotFound(OrderNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("Order Not Found");
        problem.setType(URI.create("https://api.example.com/problems/order-not-found"));
        return problem;
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex, HttpHeaders headers,
            HttpStatusCode status, WebRequest request) {

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        problem.setProperty("errors", ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.groupingBy(FieldError::getField,
                        Collectors.mapping(FieldError::getDefaultMessage, Collectors.toList()))));
        return ResponseEntity.badRequest().body(problem);
    }
}
```

Extending `ResponseEntityExceptionHandler` gives you ready-made problem-detail responses for the standard Spring MVC exceptions (bad JSON, wrong type, wrong verb). You override only the ones you want to customize. Boot can also produce problem details for those by itself, with one property in `application.properties` (the settings note covered where these live):

```properties
spring.mvc.problemdetails.enabled=true
```

On stack traces: Boot's default error body doesn't include them (`server.error.include-stacktrace=never`), so the real problem is _inconsistent_ errors, not leaked traces. Keep it that way in production.

---

## Part 5: Changing the API without breaking clients

An API is a contract that outlives its features. When a response shape has to change, you version it.

|Style|Looks like|Trade-off|
|---|---|---|
|URI|`/api/v1/orders`|Most visible and common. A URI should identify a resource, not a version, but it's the pragmatic default|
|Header|`X-API-Version: 1`|Clean URIs, but hard for clients to discover|
|Media type|`Accept: application/vnd.example.v1+json`|Most "pure" REST, but more work to operate|

Start with URI versioning. When you retire a version, announce it with headers. `Deprecation` (RFC 9745) says it's deprecated, `Sunset` (RFC 8594) says when it stops working, and `Link: <...>; rel="successor-version"` points to the replacement. Newer Spring releases (Framework 7 / Boot 4) add built-in versioning support, so check your version's docs before hand-rolling one.

### HATEOAS: links in the response

HATEOAS means each response also tells the client what it can do next, through links. That lets the server change its URLs without breaking clients, and it suits public APIs and complex state machines. For a simple internal API it's usually extra work.

Spring HATEOAS wraps your DTO instead of changing it, so your records stay records:

```java
@GetMapping("/{id}")
public EntityModel<OrderResponse> getOrder(@PathVariable Long id) {
    OrderResponse order = orderService.findById(id);
    return EntityModel.of(order,
            linkTo(methodOn(OrderController.class).getOrder(id)).withSelfRel(),
            linkTo(methodOn(OrderController.class).cancelOrder(id)).withRel("cancel"));
}
```

(It needs `spring-boot-starter-hateoas`.)

---

## Part 6: Production concerns

### Pagination

Never return an unbounded list. Spring Data turns `?page=0&size=20&sort=createdAt,desc` into a `Pageable` for you:

```java
@GetMapping
public Page<OrderResponse> list(
        @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC)
        Pageable pageable) {
    return orderService.findAll(pageable);
}
```

Three things to do:

- **Cap the size**, or a client can ask for `size=1000000`:
    
    ```properties
    spring.data.web.pageable.max-page-size=100
    ```
    
- **Don't serialize `Page` directly** in newer Spring Data. Use `@EnableSpringDataWebSupport(pageSerializationMode = PageSerializationMode.VIA_DTO)` for a stable JSON shape.
- **Whitelist the sort fields.** A client-chosen `sort` parameter can name any property on your entity, including ones you meant to keep private.

### Idempotency: making POST safe to retry

POST isn't idempotent, so a client that retries after a network timeout can create a duplicate order or charge a card twice. The fix is an `Idempotency-Key` header: the client generates a unique value (a UUID) for each logical operation and sends it with the request.

```text
1. Client sends  Idempotency-Key: <uuid>
2. Server tries to INSERT the key (unique constraint on user + key)
3. Insert fails (key exists)  → return the SAME status and body as the first time
                                (or 409 if the first request is still running)
4. Insert succeeds            → do the work, save the response with the key, return it
5. Same key, different body   → 422
6. Delete old keys after a TTL (for example 24 hours)
```

The unique constraint is what makes it safe. A "look it up, then process, then save" version has a race, because two simultaneous retries can both pass the lookup. The header is an IETF draft, widely used by payment APIs.

### Concurrent edits

Two clients updating the same resource can overwrite each other. Use an `@Version` field on the entity (an optimistic lock) and return **409** on a conflict, or use `ETag` and `If-Match` headers and return **412**.

### Stateless security

A REST API keeps no session. Each request carries a token, usually a JWT in `Authorization: Bearer <token>`, as your JWT and Bearer-header notes described. Your security config is a `@Configuration` class that exposes a `SecurityFilterChain` bean (see the `@Configuration` note):

```java
@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http,
                                           JwtAuthenticationFilter jwtFilter) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers(HttpMethod.DELETE, "/api/v1/orders/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
```

Line by line:

- **CSRF is disabled** because attacks like that rely on cookie sessions. A token sent explicitly in a header isn't attached by the browser automatically. Only disable it when you really have no cookie-based login.
- `STATELESS` tells Spring Security not to create or use a session.
- `addFilterBefore` plugs in your own JWT filter, from your JWT filter chain lesson. This is the right choice when your own login endpoint issues the tokens.
- If tokens come from an **external authorization server** instead, use `.oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()))`. It validates tokens issued elsewhere and does not fit a self-issued login token. Pick one approach.

Also remember **CORS** if a browser front end on another origin calls the API.

---

## Part 7: Layers and mapping

Keep controllers thin. A controller parses the request, validates it, calls a service, and shapes the response. Business rules live in the service, and database access lives in the repository (your persistence-layer note).

Do the entity-to-DTO mapping **inside the service**, within the transaction, and return a DTO. If you return entities and map them in the controller, lazy relationships get touched after the transaction has closed, and you either hit `LazyInitializationException` or quietly lean on `spring.jpa.open-in-view`, which keeps a database connection open for the whole request. MapStruct (your MapStruct note) is a popular mapper because it generates plain, type-safe mapping code at compile time.

This also keeps your two models independent. You can refactor entities without changing the API, and reshape the API without changing the schema.

---

## Checklist

|Concern|Do this|
|---|---|
|Resources|Plural nouns, no verbs; path identifies, query modifies|
|Verbs|Honor safe and idempotent rules|
|Status codes|Precise codes; never 200 with an error|
|DTOs|Return records, never entities; map in the service|
|Validation|Add the starter; `@Valid` on the body and on nested objects|
|Errors|`@RestControllerAdvice` with `ProblemDetail`|
|Versioning|URI by default; announce retirements with `Deprecation` and `Sunset`|
|Pagination|`Pageable`, capped size, whitelisted sorts|
|Retries|`Idempotency-Key` with a unique constraint|
|Concurrency|`@Version` or `ETag`, with 409 or 412|
|Security|Stateless tokens; CSRF off only with no cookie login; CORS if needed|

---

## Related concept in short

**The Richardson maturity model** rates how "RESTful" an API is: level 0 is one endpoint (RPC), level 1 adds resources, level 2 adds proper verbs and status codes, and level 3 adds hypermedia links (HATEOAS). Most real-world APIs stop at level 2, which is a perfectly good place to be.






[[Spring Framework]]