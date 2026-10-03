
## The mental model

Think of your controller as a **restaurant waiter**. A request arrives (the customer's order), and the waiter has to figure out:

1. **Which kitchen station?** → URL + HTTP method (`@GetMapping("/users")`)
2. **What details came with the order?** → path, query string, headers, body (`@PathVariable`, `@RequestParam`, `@RequestBody`)
3. **How should the answer be served?** → status code + body (`@ResponseStatus`, `ResponseEntity`)

CRUD maps onto HTTP like this:

|Operation|HTTP method|Typical URL|Success status|
|---|---|---|---|
|**C**reate|POST|`/api/users`|201 Created|
|**R**ead (all)|GET|`/api/users`|200 OK|
|**R**ead (one)|GET|`/api/users/{id}`|200 OK|
|**U**pdate (full)|PUT|`/api/users/{id}`|200 OK|
|**U**pdate (partial)|PATCH|`/api/users/{id}`|200 OK|
|**D**elete|DELETE|`/api/users/{id}`|204 No Content|

---

## 1. Class-level annotations

```java
@RestController
@RequestMapping("/api/users")
public class UserController { ... }
```

**`@RestController`** = `@Controller` + `@ResponseBody`. Every method's return value is written directly into the HTTP response body (serialized to JSON by Jackson) instead of being treated as a view name. Without `@ResponseBody`, returning a `String` would make Spring look for a template with that name.

**`@RequestMapping`** at class level sets a **shared prefix**, so you don't repeat `/api/users` on every method. Its parameters:

|Parameter|Meaning|Example|
|---|---|---|
|`value` / `path`|URL pattern (aliases of each other)|`"/api/users"`|
|`method`|HTTP method(s)|`RequestMethod.GET`|
|`consumes`|Required request `Content-Type`|`"application/json"`|
|`produces`|Response `Content-Type` (matched against `Accept`)|`"application/json"`|
|`params`|Request must contain certain query params|`"version=2"`|
|`headers`|Request must contain certain headers|`"X-API-KEY"`|

```java
@RequestMapping(
    path = "/api/users",
    method = RequestMethod.POST,
    consumes = "application/json",
    produces = "application/json"
)
```

If `consumes` doesn't match you get **415 Unsupported Media Type**. If `produces` doesn't match the client's `Accept` header you get **406 Not Acceptable**.

---

## 2. Method-level shortcuts

`@GetMapping`, `@PostMapping`, `@PutMapping`, `@PatchMapping`, and `@DeleteMapping` are **composed annotations**: each is just `@RequestMapping(method = X)` pre-filled. They accept the same `value/path`, `consumes`, `produces`, `params`, and `headers`, minus `method`.

```java
@GetMapping("/{id}")                       // GET /api/users/5
@PostMapping(consumes = "application/json") // POST /api/users
@DeleteMapping("/{id}")                    // DELETE /api/users/5
```

---

## 3. Parameter annotations (reading the request)

### `@PathVariable`: data inside the URL path

```java
@GetMapping("/{id}")
public User getOne(@PathVariable Long id) { ... }
```

|Parameter|Meaning|
|---|---|
|`name` / `value`|Which `{placeholder}` to bind (needed if the Java variable name differs)|
|`required`|Default `true`; `false` makes it optional (rare)|

```java
@GetMapping("/{userId}/orders/{orderId}")
public Order getOrder(@PathVariable("userId") Long uid,
                      @PathVariable Long orderId) { ... }
```

### `@RequestParam`: query string (`?page=1&size=10`) or form data

```java
@GetMapping
public List<User> list(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size,
        @RequestParam(required = false) String name) { ... }
```

|Parameter|Meaning|
|---|---|
|`name` / `value`|The query parameter name|
|`required`|Default `true`. Missing → **400 Bad Request**|
|`defaultValue`|Used when the param is missing or empty. **Setting it implicitly makes `required=false`**|

You can bind to `Map<String,String>` to capture _all_ query params.

### `@RequestBody`: the JSON payload

```java
@PostMapping
public User create(@RequestBody UserDto dto) { ... }
```

Jackson converts the JSON body into your object. Only parameter: `required` (default `true`; an empty body → 400). There can be **only one** `@RequestBody` per method, because the body stream can be read once.

### `@RequestHeader` and `@CookieValue`

```java
@GetMapping("/me")
public User me(@RequestHeader("Authorization") String token,
               @RequestHeader(value = "X-Lang", defaultValue = "en") String lang,
               @CookieValue(name = "sessionId", required = false) String session) { ... }
```

Same trio as `@RequestParam`: `name`, `required`, `defaultValue`.

### `@Valid` / `@Validated`: triggers bean validation

```java
@PostMapping
public User create(@Valid @RequestBody UserDto dto) { ... }
```

Requires `spring-boot-starter-validation`. Failure throws `MethodArgumentNotValidException` → 400.

---

## 4. Controlling the response

### `@ResponseStatus`: fixed status code

```java
@PostMapping
@ResponseStatus(HttpStatus.CREATED)
public User create(@Valid @RequestBody UserDto dto) { ... }
```

Parameters: `value`/`code` (the status), `reason` (optional message).

### `ResponseEntity<T>`: full control (status + headers + body)

Use it when the status depends on runtime logic or you need headers like `Location`.

```java
return ResponseEntity.created(URI.create("/api/users/" + saved.getId())).body(saved);
return ResponseEntity.notFound().build();
return ResponseEntity.noContent().build();
```

---

## 5. Full CRUD example

**DTO** (never expose your JPA entity directly):

```java
public record UserDto(
        @NotBlank String name,
        @Email @NotBlank String email) {}
```

**Controller:**

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService service;

    public UserController(UserService service) {   // constructor injection
        this.service = service;
    }

    // CREATE
    @PostMapping
    public ResponseEntity<User> create(@Valid @RequestBody UserDto dto) {
        User saved = service.create(dto);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(saved.getId()).toUri();
        return ResponseEntity.created(location).body(saved);   // 201 + Location header
    }

    // READ ALL (with optional filter + paging)
    @GetMapping
    public List<User> findAll(
            @RequestParam(required = false) String name,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return service.findAll(name, page, size);
    }

    // READ ONE
    @GetMapping("/{id}")
    public User findOne(@PathVariable Long id) {
        return service.findById(id);    // throws UserNotFoundException if absent
    }

    // UPDATE (replace whole resource)
    @PutMapping("/{id}")
    public User update(@PathVariable Long id, @Valid @RequestBody UserDto dto) {
        return service.update(id, dto);
    }

    // PARTIAL UPDATE
    @PatchMapping("/{id}")
    public User patch(@PathVariable Long id, @RequestBody Map<String, Object> fields) {
        return service.patch(id, fields);
    }

    // DELETE
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)   // 204
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
```

**Centralized error handling:**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Map<String, String> notFound(UserNotFoundException ex) {
        return Map.of("error", ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Map<String, String> invalid(MethodArgumentNotValidException ex) {
        return ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(
                        FieldError::getField,
                        fe -> Objects.requireNonNullElse(fe.getDefaultMessage(), "invalid"),
                        (a, b) -> a));
    }
}
```

`@ExceptionHandler` says "handle this exception type"; `@RestControllerAdvice` makes it apply to _all_ controllers. This keeps controllers clean: they throw, the advice translates to HTTP.

---

## 6. Nuances and gotchas

**PUT vs PATCH vs POST (idempotency).** PUT _replaces_ the resource, so sending it 10 times gives the same result (idempotent). PATCH changes only the fields sent. POST creates a new resource each time (not idempotent). DELETE is idempotent in effect.

**Why `@PathVariable Long id` works without a name.** Spring reads the parameter name via reflection, which requires the `-parameters` compiler flag. Spring Boot's Maven/Gradle plugins enable it for you, but in a plain setup you'd need `@PathVariable("id")`.

**Type mismatch → 400, not 500.** `/api/users/abc` for a `Long id` throws `MethodArgumentTypeMismatchException`, which Spring turns into 400 automatically.

**`@RequestParam` vs `@PathVariable` design rule.** Path = _identifies_ a resource (`/users/5`). Query = _filters/modifies_ the view (`/users?role=admin&page=2`).

**Optional query params.** `required=false` gives you `null` for primitives wrappers, but a primitive like `int` can't be null → exception. Use `Integer`, `Optional<Integer>`, or `defaultValue`.

**Always return a DTO, not your entity.** Returning entities leaks fields (e.g. passwords), couples your API to your DB schema, and causes lazy-loading/infinite-recursion JSON problems with relationships.

**Don't use `@RequestBody` on GET.** Technically possible, but many clients and proxies ignore it. Use query params.

**Trailing slashes (Spring 6 / Boot 3+).** `/api/users/` no longer matches `/api/users` by default. This surprises people migrating from older tutorials.

**`@CrossOrigin`** is relevant for your Angular front-end: `@CrossOrigin(origins = "http://localhost:4200")` on the controller (or a global `WebMvcConfigurer`) allows the browser to call your API from the Angular dev server.

---

## Quick reference

|Annotation|Reads from|Key parameters|
|---|---|---|
|`@PathVariable`|URL path|`name`, `required`|
|`@RequestParam`|query string / form|`name`, `required`, `defaultValue`|
|`@RequestBody`|HTTP body (JSON)|`required`|
|`@RequestHeader`|headers|`name`, `required`, `defaultValue`|
|`@CookieValue`|cookies|`name`, `required`, `defaultValue`|
|`@Valid`|triggers validation|(none)|
|`@ResponseStatus`|sets response code|`value`/`code`, `reason`|
|`@ExceptionHandler`|maps exception → response|exception class(es)|


[[Spring Framework]]