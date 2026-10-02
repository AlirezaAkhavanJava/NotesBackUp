

## Part 1: The Mental Model — REST as a Resource-Oriented Architecture

### 1.1 The Core Intuition: Think "Nouns," Not "Verbs"

The most common mistake in API design is modeling endpoints as remote procedure calls. You end up with URLs like `/getUserById`, `/createOrder`, `/deleteProduct`. That is not REST; it is RPC over HTTP.

REST models your system as **resources** — any information worth exposing — each uniquely identified by a **URI**. The idea is to design URIs that make logical sense based on your resource set, as if you were designing a browsable website [12†L15-L22]. Clients interact with resources using a small, uniform set of **HTTP verbs** (GET, POST, PUT, PATCH, DELETE) [12†L24-L27].

**Analogy:** Think of a library. You don't ask the librarian "fetchBookByTitle." You navigate to the shelf (collection URI `/books`), pick a specific book (`/books/978-0-13-468599-1`), read it (GET), replace it (PUT), or remove it (DELETE). The shelf itself is a resource; each book is a resource. The verbs are the same regardless of what you're manipulating.

### 1.2 The Uniform Interface and HTTP Semantics

The uniform interface is what makes REST scalable: every resource is manipulated the same way. But the verbs carry **semantic contracts** that production systems must honor:

| Verb | Semantics | Safe? | Idempotent? |
|------|-----------|-------|-------------|
| GET | Retrieve a resource | Yes | Yes |
| POST | Create a new resource (server assigns URI) | No | No |
| PUT | Replace a resource entirely (client knows URI) | No | Yes |
| PATCH | Partially modify a resource | No | No* |
| DELETE | Remove a resource | No | Yes |

*PUT is idempotent: calling it N times with the same body produces the same state as calling it once. GET is safe: it must never cause side effects and must be cacheable [12†L25-L31].

This matters because intermediaries (proxies, CDNs, browsers) rely on these contracts. If your GET endpoint deletes a record, you break the web's caching and prefetching assumptions.

### 1.3 The Collection/Item Rhythm

Resources naturally organize into collections and individual items:

```
/orders              → collection of orders
/orders/{id}         → a single order
/orders/{id}/items   → sub-collection of items within an order
/orders/{id}/items/{itemId} → a single item
```

This rhythm is not arbitrary. It maps to how clients reason about your domain. A client listing orders hits the collection; a client viewing one order hits the item. Relationships are expressed by nesting, but only when the child resource genuinely cannot exist outside the parent context. For many-to-many or complex relationships, prefer top-level resources with query parameters.

### 1.4 The Representation: What Travels on the Wire

A resource is a conceptual entity. Its **representation** is what you actually send: JSON, XML, or any registered media type. The same resource can have multiple representations selected via content negotiation (`Accept` header) [12†L32-L36].

In Spring Boot, the default representation is JSON via Jackson. You should never expose your database entities directly — this is the "zero entity leaks" principle [7†L5-L6]. Entities carry persistence concerns (lazy proxies, bidirectional relationships, column mappings) that do not belong in an API contract. Use Data Transfer Objects (DTOs) as the boundary.

**Why DTOs matter:** An entity might have a `password` field or a `createdBy` relationship that triggers lazy loading. A DTO is a deliberate, minimal contract. Java Records are ideal for DTOs: immutable, concise, and automatically generating `equals`/`hashCode`/`toString` [7†L25-L26].

```java
// Bad: exposing the entity
@GetMapping("/users/{id}")
public User getUser(@PathVariable Long id) { ... }

// Good: exposing a DTO
public record UserResponse(Long id, String username, String email) {}

@GetMapping("/users/{id}")
public UserResponse getUser(@PathVariable Long id) {
    return userService.findById(id)
        .map(user -> new UserResponse(user.getId(), user.getUsername(), user.getEmail()))
        .orElseThrow(() -> new UserNotFoundException(id));
}
```

---

## Part 2: Spring Boot Mechanics — From Annotations to Production Controllers

### 2.1 `@RestController` vs `@Controller`: The View Resolver Bypass

Spring MVC has two controller stereotypes. `@Controller` returns view names resolved by a `ViewResolver` (for server-rendered pages). `@RestController` is a meta-annotation combining `@Controller` and `@ResponseBody`: every method's return value is serialized directly to the HTTP response body [1†L10-L13].

In a REST API, you almost always use `@RestController`. The view resolver is not consulted; Jackson's `HttpMessageConverter` handles JSON serialization [1†L36-L38].

### 2.2 Request Mapping: The Dispatch Contract

`@RequestMapping` is the core annotation that maps HTTP requests to handler methods. It can be placed at class level (a base path) and method level (the specific endpoint) [1†L4-L9]. The specialized variants — `@GetMapping`, `@PostMapping`, `@PutMapping`, `@PatchMapping`, `@DeleteMapping` — are shorthands that pre-set the HTTP method.

```java
@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    private final OrderService orderService;

    // Constructor injection — not @Autowired on the field
    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrderResponse> getOrder(@PathVariable Long id) {
        return orderService.findById(id)
            .map(ResponseEntity::ok)
            .orElseThrow(() -> new OrderNotFoundException(id));
    }

    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(
            @Valid @RequestBody CreateOrderRequest request,
            UriComponentsBuilder uriBuilder) {
        OrderResponse created = orderService.create(request);
        URI location = uriBuilder.path("/api/v1/orders/{id}")
            .buildAndExpand(created.id()).toUri();
        return ResponseEntity.created(location).body(created);
    }
}
```

**Why constructor injection?** Field injection with `@Autowired` makes testing harder (you must use reflection to set dependencies) and obscures required dependencies. Constructor injection makes dependencies explicit and allows `final` fields [7†L25-L26].

### 2.3 Parameter Binding: The Four Sources of Input

Spring MVC binds handler method parameters from four primary sources:

1. **`@PathVariable`** — extracts a segment from the URI template: `/{id}` → `Long id`
2. **`@RequestParam`** — extracts a query parameter: `?page=0&size=20` → `int page, int size`
3. **`@RequestBody`** — deserializes the HTTP body (JSON → object) via Jackson
4. **`@RequestHeader`** — extracts a header value

**Edge case:** Path variables are part of the resource identifier; query parameters are modifiers (filtering, pagination, sorting). Do not use query parameters to identify resources. `/orders?id=42` is not RESTful; `/orders/42` is.

### 2.4 HTTP Status Codes: Semantic Precision

Production APIs use HTTP status codes as the primary contract for outcome. The table below summarizes the codes you will use most [18†L23-L27]:

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 OK | Success | GET, PUT, PATCH with response body |
| 201 Created | Resource created | POST; include `Location` header |
| 202 Accepted | Async processing | Request accepted, not yet complete |
| 204 No Content | Success, no body | DELETE, or PUT/PATCH with no return body |
| 400 Bad Request | Malformed syntax / validation failure | Invalid JSON, missing required fields |
| 401 Unauthorized | Authentication required | Missing or invalid credentials |
| 403 Forbidden | Authenticated but not authorized | Valid credentials, insufficient permission |
| 404 Not Found | Resource does not exist | Invalid ID, deleted resource |
| 409 Conflict | State conflict | Duplicate resource, optimistic locking failure |
| 422 Unprocessable Entity | Semantically invalid | Valid syntax but business rule violation |
| 429 Too Many Requests | Rate limit exceeded | Include `Retry-After` header |
| 500 Internal Server Error | Unexpected server failure | Never expose stack traces |

**Gotcha:** Do not return 200 OK with an error body. This breaks client error handling and monitoring. If you must return a business-level error, use the appropriate 4xx status and a structured error body.

### 2.5 Validation: Fail Fast, Fail Clearly

Validation in Spring Boot is built on Jakarta Bean Validation (JSR-380), with Hibernate Validator as the reference implementation. Since Spring Boot 2.3, `spring-boot-starter-validation` is no longer pulled in automatically by `spring-boot-starter-web` — you must add it explicitly, or your `@Valid` annotations silently do nothing [11†L6-L13].

**How validation actually triggers:** Validation runs only when `@Valid` (from `jakarta.validation`) or Spring's `@Validated` sits directly on the parameter Spring is binding. On a `@RestController` method, annotating a `@RequestBody` parameter with `@Valid` causes Spring's `RequestResponseBodyMethodProcessor` to run the bound object through the configured `Validator` after deserialization [11†L15-L23].

```java
public record CreateOrderRequest(
    @NotBlank String customerId,
    @NotEmpty @Valid List<OrderItemRequest> items
) {}

public record OrderItemRequest(
    @NotBlank String sku,
    @Positive int quantity
) {}
```

**The cascading validation trap:** Hibernate Validator does not validate nested objects by default. If `CreateOrderRequest` has a field `Address shippingAddress`, and `Address` itself has `@NotBlank` on `city`, none of those constraints run unless `shippingAddress` is itself annotated `@Valid` inside `CreateOrderRequest` [11†L33-L41]. Miss that one annotation and the outer object reports "valid" while carrying a completely empty inner object. This is one of the most common silent failures in production APIs.

**List element validation:** Validating `List<T>` elements is inconsistent. Per-element constraints on `List<SomeDto>` request-body fields may not fire as expected depending on how the controller method and DTO are structured [11†L45-L52]. Always test list validation explicitly.

When validation fails, Spring throws `MethodArgumentNotValidException`. Left unhandled, it can leak stack traces. You need an explicit `@ExceptionHandler` or a global `@ControllerAdvice` that maps it to a sanitized 400 response with field-level detail [11†L23-L31].

---

## Part 3: Cross-Cutting Concerns — Error Handling, Versioning, and HATEOAS

### 3.1 Global Exception Handling with `@ControllerAdvice`

Without centralized error handling, your clients receive inconsistent error formats, stack traces leak in production, and debugging becomes a nightmare [8†L7-L9]. `@ControllerAdvice` intercepts exceptions across all controllers and lets you return a standardized response.

Spring Framework 6 (and Spring Boot 3+) supports **RFC 7807 "Problem Details for HTTP APIs"** via the `ProblemDetail` class. The specification defines a standard error structure with fields: `type`, `title`, `status`, `detail`, and `instance` [13†L23-L28]. This is the production-grade approach: it provides a consistent, extensible error format that clients can parse uniformly.

```java
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(OrderNotFoundException.class)
    public ProblemDetail handleOrderNotFound(OrderNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("Order Not Found");
        problem.setType(URI.create("https://api.example.com/problems/order-not-found"));
        return problem;
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, "Validation failed");
        Map<String, List<String>> errors = ex.getBindingResult()
            .getFieldErrors().stream()
            .collect(Collectors.groupingBy(
                FieldError::getField,
                Collectors.mapping(FieldError::getDefaultMessage, Collectors.toList())));
        problem.setProperty("errors", errors);
        return ResponseEntity.badRequest().body(problem);
    }
}
```

**Why extend `ResponseEntityExceptionHandler`?** It already handles all standard Spring MVC exceptions (e.g., `TypeMismatchException`, `HttpMessageNotReadableException`) with RFC 7807 responses. You only override the ones you need to customize [13†L16-L19].

### 3.2 API Versioning: Evolving Without Breaking

APIs are contracts that outlive features. When you need to change a response shape or behavior, you must version. Three strategies exist, each with trade-offs:

**URI versioning** (`/api/v1/orders`): The most visible and easiest to route. Clients can bookmark and share versioned URLs. The downside is that URIs are supposed to identify resources, not versions — but pragmatically, this is the most common approach in industry.

**Header versioning** (`X-API-Version: 1`): Keeps URIs clean. Spring MVC supports this via the `headers` condition on `@GetMapping` [9†L23-L28]. The downside is that clients cannot easily discover the version.

**Content negotiation / media type versioning** (`Accept: application/vnd.example.v1+json`): The most "RESTful" approach, using the `Accept` header. Spring MVC does not take media type parameters into account during content negotiation, so you must include the version in the type itself [3†L24-L29]. This is technically elegant but operationally complex.

```java
// URI versioning — simplest, most common
@RestController
@RequestMapping("/api/v1/orders")
public class OrderControllerV1 { ... }

@RestController
@RequestMapping("/api/v2/orders")
public class OrderControllerV2 { ... }
```

**Deprecation and Sunset headers:** RFC 9745 defines the `Deprecation` header as a structured date value, and RFC 8594 defines `Sunset` as the date after which the API will be unavailable. Include a `Link` header with `rel="successor-version"` to point clients to the replacement [9†L30-L34].

### 3.3 HATEOAS: Making APIs Self-Documenting

HATEOAS (Hypertext as the Engine of Application State) is the constraint that distinguishes true REST from HTTP-based RPC. The API should guide the client through the application by returning relevant information about next potential steps with each response [10†L8-L10]. The goal is to decouple client and server, allowing the API to change its URI scheme without breaking clients.

Spring HATEOAS provides `RepresentationModel`, `Link`, and `WebMvcLinkBuilder` to create hypermedia-driven representations [10†L40-L41]. Resources extend `RepresentationModel` to inherit the `add()` method for attaching links [10†L43-L48].

```java
public class OrderResponse extends RepresentationModel<OrderResponse> {
    private Long id;
    private String status;
    // getters/setters
}

@GetMapping("/{id}")
public OrderResponse getOrder(@PathVariable Long id) {
    OrderResponse order = orderService.findById(id);
    order.add(linkTo(methodOn(OrderController.class).getOrder(id)).withSelfRel());
    order.add(linkTo(methodOn(OrderController.class).cancelOrder(id)).withRel("cancel"));
    return order;
}
```

**When to use HATEOAS:** It is ideal for public APIs or complex state machines where clients need discoverability. It can be excessive for simple internal APIs where the client and server are deployed together [4†L26-L27].

---

## Part 4: Production Nuances — Pagination, Idempotency, and Security

### 4.1 Pagination and Filtering: Handling Large Datasets

Never return an unbounded collection. Spring Data's `Pageable` interface integrates directly with Spring MVC: the framework derives a `Pageable` instance from request parameters (`page`, `size`, `sort`) using a `PageableHandlerMethodArgumentResolver`. The default is `page=0, size=20`, customizable via `@PageableDefault` [14†L33-L37].

```java
@GetMapping
public Page<OrderResponse> listOrders(
        @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC)
        Pageable pageable) {
    return orderService.findAll(pageable);
}
```

**Response shape:** Spring's `Page<T>` serializes to a JSON object with `content`, `totalElements`, `totalPages`, `number`, and `size`. This is machine-readable but not HATEOAS-friendly. For hypermedia APIs, use `PagedResourcesAssembler` to enrich the response with `next`/`prev` links [14†L41-L43].

**Gotcha:** `size` must be capped. A client requesting `size=1000000` will exhaust memory. Configure a maximum in `spring.data.web.pageable.max-page-size`.

### 4.2 Idempotency: Making POST Safe Against Retries

POST is not idempotent by HTTP specification. In distributed systems, network failures cause clients to retry, creating duplicate resources (double-charged credit cards, duplicate orders). The **Idempotency-Key** header solves this: the client generates a unique key (typically a UUID) per logical operation and sends it with the request. The server stores the key and the result. If the same key arrives again, the server returns the stored result instead of re-executing [15†L4-L7].

```java
@PostMapping("/payments")
public ResponseEntity<PaymentResponse> createPayment(
        @RequestHeader("Idempotency-Key") String idempotencyKey,
        @Valid @RequestBody PaymentRequest request) {

    return idempotencyService.findByKey(idempotencyKey)
        .map(existing -> ResponseEntity.ok(existing))
        .orElseGet(() -> {
            PaymentResponse response = paymentService.process(request);
            idempotencyService.store(idempotencyKey, response);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        });
}
```

**Implementation details:** The key should be unique per endpoint and per user to avoid collisions. Store the key with a TTL (e.g., 24 hours) and the full response. Use a database unique constraint on the key to prevent race conditions [15†L35-L39].

### 4.3 Security: Stateless Authentication and Authorization

REST APIs are stateless: each request carries all information needed to process it. This makes JWT (JSON Web Token) authentication the natural fit. The client authenticates once (via `/auth/login`), receives a signed JWT, and includes it in the `Authorization: Bearer <token>` header on subsequent requests.

Spring Security 6 (in Spring Boot 3) uses a Lambda DSL for configuration. The key configuration for a stateless REST API:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // Stateless API — no CSRF
            .sessionManagement(session -> 
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/orders/**").hasRole("USER")
                .requestMatchers(HttpMethod.DELETE, "/api/v1/orders/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()));
        return http.build();
    }
}
```

**Why disable CSRF?** CSRF attacks exploit cookie-based session authentication. A stateless JWT API does not use cookies; the token is sent explicitly in the header, so CSRF is not applicable. Disabling it is correct for this architecture [7†L40-L42].

### 4.4 DTO Mapping and Layer Separation

Keep controllers thin. The controller's job is HTTP concern: parse the request, validate, delegate to the service, and format the response. Business logic belongs in the service layer. The service layer works with domain objects and entities; the controller maps between DTOs and domain objects.

```java
// Controller — HTTP concern only
@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {
    private final OrderService orderService;
    private final OrderMapper orderMapper;

    @PostMapping
    public ResponseEntity<OrderResponse> create(@Valid @RequestBody CreateOrderRequest request) {
        Order order = orderMapper.toDomain(request);
        Order saved = orderService.create(order);
        OrderResponse response = orderMapper.toResponse(saved);
        return ResponseEntity.created(URI.create("/api/v1/orders/" + saved.getId()))
            .body(response);
    }
}
```

MapStruct is the production-standard mapper: it generates type-safe mapping code at compile time, eliminating reflection overhead and runtime errors [17†L4-L10]. It handles nested mappings, custom conversions, and `@MappingTarget` for updates.

**Why this separation matters:** It keeps the API contract independent of the persistence model. You can refactor your JPA entities without changing the API. You can change the API response shape without altering the database schema.

---

## Part 5: Summary — The Production Checklist

| Concern | Production Practice |
|---------|---------------------|
| **Resource modeling** | Nouns, not verbs; collection/item rhythm; URI identifies resource, query params modify |
| **HTTP methods** | Honor safety and idempotency contracts |
| **Status codes** | Semantic precision; never 200 OK with error body |
| **DTOs** | Never expose entities; use Java Records; MapStruct for mapping |
| **Validation** | Add `spring-boot-starter-validation`; cascade `@Valid` on nested objects; handle `MethodArgumentNotValidException` globally |
| **Error handling** | `@RestControllerAdvice` + RFC 7807 `ProblemDetail`; never leak stack traces |
| **Versioning** | URI versioning for simplicity; document deprecation with `Deprecation` and `Sunset` headers |
| **HATEOAS** | Use for public/complex APIs; skip for simple internal APIs |
| **Pagination** | `Pageable` with capped `size`; never return unbounded collections |
| **Idempotency** | `Idempotency-Key` header for POST; store result with unique constraint and TTL |
| **Security** | Stateless JWT; Lambda DSL; disable CSRF only when session-less |
| **Layering** | Thin controllers; business logic in services; DTO mapping at the boundary |

The thread running through all of this is **intentionality**: every decision — which verb, which status code, which header — is a deliberate contract with the client. Production APIs are not just code; they are interfaces that must be predictable, evolvable, and safe.


[[Spring Framework]]