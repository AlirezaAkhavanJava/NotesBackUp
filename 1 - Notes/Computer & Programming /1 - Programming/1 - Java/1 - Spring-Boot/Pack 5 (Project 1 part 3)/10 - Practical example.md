

# Two production-style examples

I picked two different _types_ of API, because they stress different annotations:

||Type 1: **Resource CRUD**|Type 2: **Nested resource + search + file**|
|---|---|---|
|Example|Product catalog|Orders that belong to a user|
|Shape|`/api/products/{id}`|`/api/users/{userId}/orders/{orderId}`|
|Stresses|`@RequestBody`, `@Valid`, `ResponseEntity`, `URI`, error handling|multiple `@PathVariable`s, `@RequestParam` filters, `@RequestHeader`, `PATCH`, headers, file download, CORS|

The `Service` is a placeholder here, since that's the next topic. Assume `spring-boot-starter-web` and `spring-boot-starter-validation`.

---

# Type 1: Product catalog (classic CRUD)

## The DTOs: separate "what comes in" from "what goes out"

```java
public record ProductRequest(
        @NotBlank @Size(max = 100) String name,
        @NotNull @DecimalMin("0.01") BigDecimal price,
        @Min(0) int stock) {}

public record ProductResponse(Long id, String name, BigDecimal price, int stock) {}
```

## The controller

```java
@RestController
@RequestMapping(path = "/api/products", produces = MediaType.APPLICATION_JSON_VALUE)
public class ProductController {

    private final ProductService service;

    public ProductController(ProductService service) {
        this.service = service;
    }

    // CREATE
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody ProductRequest req) {
        ProductResponse saved = service.create(req);
        URI location = ServletUriComponentsBuilder.fromCurrentRequestUri()
                .path("/{id}").buildAndExpand(saved.id()).toUri();
        return ResponseEntity.created(location).body(saved);
    }

    // READ ALL: filter + paging
    @GetMapping
    public ResponseEntity<List<ProductResponse>> search(
            @RequestParam(required = false) String name,
            @RequestParam(defaultValue = "0")  @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        Page<ProductResponse> result = service.search(name, page, size);
        return ResponseEntity.ok()
                .header("X-Total-Count", String.valueOf(result.getTotalElements()))
                .body(result.getContent());
    }

    // READ ONE
    @GetMapping("/{id}")
    public ProductResponse getOne(@PathVariable Long id) {
        return service.findById(id);          // throws ProductNotFoundException
    }

    // FULL UPDATE
    @PutMapping(path = "/{id}", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ProductResponse update(@PathVariable Long id,
                                  @Valid @RequestBody ProductRequest req) {
        return service.update(id, req);
    }

    // DELETE
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

## The error handling

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ProductNotFoundException.class)
    public ProblemDetail notFound(ProductNotFoundException ex) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        pd.setTitle("Product not found");
        return pd;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail invalid(MethodArgumentNotValidException ex) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        pd.setProperty("errors", ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(FieldError::getField,
                        fe -> Objects.requireNonNullElse(fe.getDefaultMessage(), "invalid"),
                        (a, b) -> a)));
        return pd;
    }
}
```

`ProblemDetail` is Spring 6's built-in standard error body (RFC 9457) with `type`, `title`, `status`, and `detail`. Returning it from a handler also sets the HTTP status automatically.

## What happens at runtime

**Request:**

```bash
curl -i -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Keyboard","price":49.90,"stock":10}'
```

**Step by step:**

1. Spring matches `POST /api/products`. It checks `consumes` (the body is JSON, so it passes) and `produces` (the client accepts JSON, so it passes).
2. The `Content-Type` header makes Spring choose Jackson, which turns the JSON into a `ProductRequest`.
3. `@Valid` runs the constraints (`@NotBlank`, `@DecimalMin`, ...). All pass, so the method body executes.
4. The service saves the product and returns it with a generated `id` (say 7).
5. The `URI` builder creates `http://localhost:8080/api/products/7`.
6. `ResponseEntity.created(...)` sets status 201 and the `Location` header, and Jackson writes the body.

```
HTTP/1.1 201
Location: http://localhost:8080/api/products/7
Content-Type: application/json

{"id":7,"name":"Keyboard","price":49.90,"stock":10}
```

**A bad request** (`"price": -5`, `"name": ""`):

```
HTTP/1.1 400
Content-Type: application/problem+json

{"title":"Bad Request","status":400,"detail":"Validation failed",
 "errors":{"name":"must not be blank","price":"must be greater than or equal to 0.01"}}
```

Your controller method **never ran**. Validation stopped the request before it.

## What each piece does, why, and what if we don't

|Piece|What it does|Why we did it|If we don't|
|---|---|---|---|
|`@RestController`|Marks the class as an HTTP API and serializes return values to JSON|Methods return objects, not view names|Spring looks for HTML templates and you get 404 or template errors|
|Class-level `@RequestMapping` with `produces`|Shared `/api/products` prefix and a default JSON response type|No repetition, one place to change|Every method repeats the prefix, and a typo in one gives a 404 on only that endpoint|
|`consumes = JSON` on POST/PUT|Rejects bodies that aren't JSON|Fails fast with a clear status|Spring still tries to parse, and the client gets a confusing error instead of a clean 415|
|`ProductRequest` / `ProductResponse` DTOs|Separate in-shape from out-shape and from the DB entity|Control exactly what clients can send and see|**Mass assignment**: a client sends `"id": 1` or `"role": "ADMIN"` and overwrites fields you never meant to expose. Output leaks internal columns|
|`@Valid` + constraints|Rejects invalid data at the door|Never trust client input|Bad data reaches the database: negative prices, empty names, and the failure comes later as a confusing 500|
|`@RequestBody`|Turns JSON into an object|Complex data belongs in the body|You'd receive nothing (null fields), or need 20 `@RequestParam`s|
|`ResponseEntity.created(location)`|201 plus the `Location` header|REST convention: tell the client where the new thing lives|A plain 200 works, but the client has to guess or re-query the new ID, and API tools and clients that follow `Location` stop working|
|`ServletUriComponentsBuilder`|Builds the URI from the current request|Correct host, port, and scheme in every environment|A hardcoded `"http://localhost:8080/..."` breaks the moment you deploy|
|`@RequestParam(defaultValue = "20") @Max(100)`|Optional paging with a safety cap|Predictable defaults, and clients can't ask for everything|`?size=10000000` loads your entire table into memory, a cheap denial-of-service. With no defaults, every client must send `page` and `size` or get 400|
|`X-Total-Count` header|Sends the total count alongside the list|The body stays a clean array while the front-end gets page info|The UI can't draw "page 3 of 12" without an extra request|
|`@PathVariable Long id`|Identifies one product|The ID is part of the resource address|The method can't know which product you mean|
|`ResponseEntity<Void>` + `noContent()`|204 with no body on delete|A body on 204 is illegal HTTP, and the client needs nothing back|`void` with no status gives 200 and an empty body. It works, but it's less precise|
|`@RestControllerAdvice`|Turns exceptions into consistent HTTP errors in one place|Controllers throw, the advice translates|Exceptions become **500 Internal Server Error** with a stack trace or generic page. The client can't tell "not found" from "server crashed"|
|`ProblemDetail`|Standard machine-readable error body|Angular and other clients parse one known shape|Every endpoint invents its own error format and front-end code gets messy|

---

# Type 2: Orders per user (nested resource + search + headers + file)

## The controller

```java
@RestController
@RequestMapping(path = "/api/users/{userId}/orders", produces = MediaType.APPLICATION_JSON_VALUE)
public class OrderController {

    private final OrderService service;

    public OrderController(OrderService service) {
        this.service = service;
    }

    // CREATE: safe to retry thanks to the Idempotency-Key header
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<OrderResponse> create(
            @PathVariable Long userId,
            @RequestHeader("Idempotency-Key") String idempotencyKey,
            @Valid @RequestBody OrderRequest req) {

        OrderResponse order = service.create(userId, idempotencyKey, req);
        URI location = ServletUriComponentsBuilder.fromCurrentRequestUri()
                .path("/{orderId}").buildAndExpand(order.id()).toUri();
        return ResponseEntity.created(location).body(order);
    }

    // SEARCH: many optional filters, all query params
    @GetMapping
    public ResponseEntity<List<OrderResponse>> search(
            @PathVariable Long userId,
            @RequestParam(required = false) OrderStatus status,
            @RequestParam(required = false)
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false)
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "0")  @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {

        Page<OrderResponse> result = service.search(userId, status, from, to, page, size);
        return ResponseEntity.ok()
                .header("X-Total-Count", String.valueOf(result.getTotalElements()))
                .body(result.getContent());
    }

    // PARTIAL UPDATE: only the status changes
    @PatchMapping(path = "/{orderId}/status", consumes = MediaType.APPLICATION_JSON_VALUE)
    public OrderResponse changeStatus(@PathVariable Long userId,
                                      @PathVariable Long orderId,
                                      @Valid @RequestBody StatusChange change) {
        return service.changeStatus(userId, orderId, change.status());
    }

    // FILE DOWNLOAD
    @GetMapping(path = "/{orderId}/invoice", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<Resource> invoice(@PathVariable Long userId,
                                            @PathVariable Long orderId) {
        Resource pdf = service.loadInvoice(userId, orderId);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename("invoice-" + orderId + ".pdf").build().toString())
                .body(pdf);
    }
}
```

```java
public enum OrderStatus { PENDING, PAID, SHIPPED, CANCELLED }
public record StatusChange(@NotNull OrderStatus status) {}
```

And the CORS config so your Angular app can call this and read the headers:

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:4200")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE")
                .exposedHeaders("X-Total-Count", "Location");
    }
}
```

## What happens at runtime

**Search request:**

```bash
curl -i "http://localhost:8080/api/users/5/orders?status=PAID&from=2026-09-01&page=0"
```

1. Class-level path `/api/users/{userId}/orders` is **concatenated** with the method's (none), and `{userId}` becomes `5`.
2. `status=PAID` is converted from text to the enum `OrderStatus.PAID`. `from` is parsed using the ISO format hint. Missing `to` becomes `null`, and `size` falls back to 20.
3. The service filters by the user and the criteria and returns one page.
4. `ResponseEntity` adds `X-Total-Count: 37`, and the body is just the JSON array of that page's orders.

**Create request with a retry:**

```bash
curl -i -X POST http://localhost:8080/api/users/5/orders \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: 9f1c2a7e-4b1d-4c8e-8f3a-2d6b7a9e1c11" \
  -d '{"items":[{"productId":7,"quantity":2}]}'
```

If the connection drops and the client sends the **identical request again** with the same key, the service recognizes the key and returns the _original_ order instead of creating a second one.

**Failure cases you now get for free:**

|Request|Result|Why|
|---|---|---|
|`?status=SHIPPING` (not an enum value)|400|Type conversion fails|
|`?from=03-10-2026`|400|Doesn't match ISO format|
|POST without `Idempotency-Key`|400|Required header is missing|
|`/users/abc/orders`|400|`Long` conversion fails|
|`PATCH` body `{"status": null}`|400|`@NotNull` fails in `@Valid`|
|`DELETE /users/5/orders`|405|Path exists, verb doesn't|

## What each piece does, why, and what if we don't

|Piece|What it does|Why we did it|If we don't|
|---|---|---|---|
|`{userId}` in the class-level path|Every method in the class is automatically scoped to a user|Orders belong to a user, and the URL says so|You repeat `/api/users/{userId}/orders` on every method, and one typo creates an inconsistent route|
|Two `@PathVariable`s (`userId`, `orderId`)|Identify exactly which order of which user|Identity lives in the path|Either one ID is missing and you can't scope the lookup, or you read it from a query param and the URL stops reading like a resource|
|Query params for `status`, `from`, `to`|Optional filters in any combination and order|Filters change the _view_, not the identity|Using path variables forces fixed order and one mapping per combination, so you'd need dozens of routes|
|`OrderStatus` enum type|Spring validates and converts the value for you|The type system rejects invalid values with a 400|With a `String` you write the check yourself, and a typo like `"PAYD"` silently returns zero results instead of an error|
|`@DateTimeFormat(iso = DATE)`|Tells Spring how to parse the text into a `LocalDate`|Dates have no universal text format|Spring can't parse it and you get 400 for every date request|
|`@Min`/`@Max` on `size`|Caps what a client can request|Protects memory and database|One request can pull the whole table|
|`@RequestHeader("Idempotency-Key")`|Reads metadata that isn't part of the order data|The key is about the _request_, not the _order_, so it belongs in a header|If you put it in the body it mixes concerns. If you skip it entirely, a network retry or a double-click creates **duplicate orders and duplicate charges**|
|`@PatchMapping` on `/status` with `StatusChange`|Changes one field with a tiny, validated body|The client shouldn't resend the entire order to change one thing|With `PUT` the client must send the whole object, and a stale copy overwrites other fields (lost update)|
|`consumes`/`produces` on PATCH/invoice|Declare exact content types|Download is PDF, writes are JSON|The invoice route could accidentally return JSON to a client expecting PDF, or fail with confusing errors|
|`ResponseEntity<Resource>` + `Content-Disposition`|Streams a file and tells the browser to save it with a name|Headers control file behavior, so a plain return can't set them|The browser shows raw bytes or tries to render them inline, with a garbage filename|
|File selected by `orderId`, not by a client-supplied filename|The client never chooses a path|Eliminates path traversal (`../../etc/passwd`)|If you accept `{filename}` and read `"/uploads/" + filename`, a client can read any file on your server|
|`exposedHeaders("X-Total-Count")` in CORS|Lets browser JavaScript read custom headers|Browsers hide non-standard headers from cross-origin code by default|Postman and curl show the header, but **Angular silently sees nothing**, and you spend an hour debugging a "working" API|
|`allowedMethods(... "PATCH" ...)`|Permits PATCH in the CORS pre-flight|Browsers ask first with an `OPTIONS` request|PATCH works in curl but the browser refuses before sending it|

---

## Nuances and gotchas

**1. Authorization is missing from both examples, and in production that is a serious hole.** `/api/users/5/orders` returns user 5's orders to _anyone_ who types that URL. Changing the number to `6` reads someone else's data. This is called **IDOR** (insecure direct object reference). The fix is Spring Security: compare the `userId` in the path with the authenticated user, or drop it from the path and use `/api/me/orders`. Validation checks that data is _well-formed_, not that the caller is _allowed_.

**2. `@Min`/`@Max` on `@RequestParam` depends on your version.** In Spring Boot 3.2+ it works automatically and failures raise `HandlerMethodValidationException` (400). In older versions you must put `@Validated` on the class, and failures raise `ConstraintViolationException`, which you must map to 400 yourself, or it becomes a 500.

**3. The idempotency example is simplified.** A real one stores the key with the response in a database table with a unique constraint. Otherwise two simultaneous retries both pass the "have I seen this key?" check. A returning replay would also normally answer 200 with the saved result rather than a fresh 201.

**4. Why `ResponseEntity` appears in some methods and not others.** `getOne` and `update` always return 200, so a plain return is enough, with less code and no loss. `create`, `search`, `delete`, and `invoice` need a custom status or custom headers, so they use `ResponseEntity`. Use the simplest tool that does the job.

**5. The DTO split pays off most in Type 2.** `OrderRequest` is what the client may send. If you bound the JPA entity instead, a client could set `status`, `userId`, or `total` directly in the JSON.

**6. `consumes` on `PATCH` matters.** Without it, a body sent with the wrong `Content-Type` gets a vague parse failure instead of a clean 415, which is much easier to debug.

---

## The big picture: where each annotation sat

```
Client                                              Your code
  │  POST /api/users/5/orders                         │
  │  Idempotency-Key: ...        ──► @RequestHeader   │
  │  {"items":[...]}             ──► @RequestBody ─► @Valid
  │              ▲ /users/5      ──► @PathVariable    │
  │              ▲ ?status=PAID  ──► @RequestParam    │
  │                                                   ▼
  │  201 Created                 ◄── ResponseEntity ◄─ service
  │  Location: .../orders/42     ◄── URI builder
  │  X-Total-Count: 37           ◄── .header(...)
  ▼  errors anywhere             ◄── @RestControllerAdvice + ProblemDetail
```

Every annotation we've covered has a job at a specific point in that flow. If you remove one, the request either fails early with a clear status code (the good case) or goes through with bad data and fails somewhere you can't easily see (the bad case).




[[Spring Framework]]