

A complete progression. Each level builds on the previous one. By the end you will know not just the annotations, but the **architecture, tradeoffs, and production patterns** that senior engineers use.

---

## Level 0 — Mental model first

Before any annotation, understand this:

**An exception is not an error message. It is a control-flow signal.**

- Throw when a rule is violated or a resource is missing.
- Catch only when you can *do something meaningful* about it.
- The HTTP layer is a *translation* layer: it converts Java exceptions into HTTP status + body.

**The golden rule:** business code throws domain exceptions. The web layer translates them. Never the reverse.

```text
Service throws UserNotFoundException
        ↓
Web layer translates → 404 Not Found
```

If your service imports `HttpStatus`, your architecture is already leaking.

---

## Level 1 — Beginner: default Spring behavior

If you do nothing, Spring Boot gives you:

- 500 Internal Server Error for uncaught exceptions.
- Whitelabel error page (HTML) or a JSON body if the request accepts JSON.
- Stack trace logged on the server, generic message to the client.

```java
@GetMapping("/{id}")
public User get(@PathVariable Long id) {
    return userService.findById(id); // if this throws, client gets 500
}
```

This is fine for a demo. It is not fine for production because:

- Every failure looks the same to the client.
- You cannot distinguish 404 from 500 from 400.
- The error body is not machine-readable.

**Beginner takeaway:** never ship default error handling to real clients.

---

## Level 2 — Beginner+: try/catch inside the controller

The first instinct:

```java
@GetMapping("/{id}")
public ResponseEntity<?> get(@PathVariable Long id) {
    try {
        return ResponseEntity.ok(userService.findById(id));
    } catch (UserNotFoundException e) {
        return ResponseEntity.status(404).body(Map.of("error", e.getMessage()));
    } catch (Exception e) {
        return ResponseEntity.status(500).body(Map.of("error", "Unexpected"));
    }
}
```

Why this is a trap:

- Duplicated in every method.
- Error shape drifts between controllers.
- Controllers become bloated.
- Service exceptions leak into the web layer.

Use this only for one-off, local decisions. Everything else moves up.

---

## Level 3 — Intermediate: `@ExceptionHandler` inside a controller

Local handling per controller:

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handle(UserNotFoundException ex) {
        return ResponseEntity.status(404)
            .body(new ErrorResponse("USER_NOT_FOUND", ex.getMessage()));
    }
}
```

Good when:

- The handler is truly specific to that controller.
- You want a controller-local error format.

Bad when:

- The same exception is thrown by other controllers.
- You want one global error shape.

This is a stepping stone, not a destination.

---

## Level 4 — Intermediate: `@RestControllerAdvice` + `@ExceptionHandler`

Global handling. This is the standard production baseline.

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handle(UserNotFoundException ex, HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("USER_NOT_FOUND", ex.getMessage(), req.getRequestURI()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex, HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(new ErrorResponse("INTERNAL_ERROR", "Unexpected error", req.getRequestURI()));
    }
}
```

Key rules:

- One class per concern, not one giant class (see Level 7).
- `@ExceptionHandler(Exception.class)` must be the last resort and must **not** leak the exception message.
- The controller no longer has any try/catch.

**Intermediate takeaway:** centralize translation, keep domain exceptions in the service.

---

## Level 5 — Intermediate+: domain exceptions vs infrastructure exceptions

Separate two families:

**Domain exceptions** — thrown by your business code.

```java
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(Long id) { super("User " + id + " not found"); }
}

public class EmailAlreadyUsedException extends RuntimeException {
    public EmailAlreadyUsedException(String email) { super("Email " + email + " already used"); }
}
```

**Infrastructure exceptions** — thrown by frameworks (JDBC, Jackson, validation, security).

```text
DataAccessException, HttpMessageNotReadableException,
MethodArgumentNotValidException, ConstraintViolationException,
AuthenticationException, AccessDeniedException, ...
```

Your advice has two jobs:

1. Translate domain exceptions to meaningful HTTP responses.
2. Translate infrastructure exceptions to safe HTTP responses.

Never let a raw `SQLException` message reach the client. It leaks schema information.

---

## Level 6 — Intermediate+: validation exceptions

Validation is where beginners lose the most time. Learn these mappings.

| Source | Exception | HTTP |
|---|---|---|
| `@Valid` on `@RequestBody` | `MethodArgumentNotValidException` | 400 |
| `@Validated` on class + `@NotBlank` on `@RequestParam` / `@PathVariable` | `ConstraintViolationException` | 400 |
| Malformed JSON | `HttpMessageNotReadableException` | 400 |
| Wrong type in path/query (`"abc"` for `Long`) | `MethodArgumentTypeMismatchException` | 400 |
| Missing required param | `MissingServletRequestParameterException` | 400 |
| Wrong HTTP method | `HttpRequestMethodNotSupportedException` | 405 |
| Wrong `Content-Type` | `HttpMediaTypeNotSupportedException` | 415 |
| Wrong `Accept` | `HttpMediaTypeNotAcceptableException` | 406 |
| Body too large | `MaxUploadSizeExceededException` | 413 |

Handler example:

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex,
                                                      HttpServletRequest req) {
    Map<String, String> fields = ex.getBindingResult().getFieldErrors().stream()
        .collect(Collectors.toMap(FieldError::getField,
                                  fe -> fe.getDefaultMessage() == null ? "invalid" : fe.getDefaultMessage(),
                                  (a, b) -> a));
    return ResponseEntity.badRequest()
        .body(new ErrorResponse("VALIDATION_FAILED", "Validation failed", req.getRequestURI(), fields));
}
```

---

## Level 7 — Advanced: multi-advice architecture with `@Order`

A single `GlobalExceptionHandler` grows into a monster. Split by concern and control precedence with `@Order`.

```java
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ValidationExceptionHandler { ... }

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class DomainExceptionHandler { ... }

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE + 20)
public class PersistenceExceptionHandler { ... }

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE + 30)
public class SecurityExceptionHandler { ... }

@RestControllerAdvice
@Order(Ordered.LOWEST_PRECEDENCE)
public class FallbackExceptionHandler { ... }
```

Rules:

- Lower order value = higher priority = consulted first.
- Within one advice, Spring picks the most specific exception handler.
- Across advices, order decides which advice is checked first.

You can also scope advice to a package or annotation:

```java
@RestControllerAdvice(basePackages = "com.example.api.v1")
@RestControllerAdvice(annotations = RestController.class)
@RestControllerAdvice(assignableTypes = UserController.class)
```

---

## Level 8 — Advanced: layered exception translation

Senior architecture treats exceptions as a **pipeline**, not a single catch.

```text
Persistence layer (MyBatis / JPA)
   throws DataAccessException, SQLException
        ↓  translated at repository boundary
Domain/Service layer
   throws UserNotFoundException, EmailAlreadyUsedException, BusinessRuleException
        ↓  translated at web boundary
Web layer (@RestControllerAdvice)
   returns ResponseEntity<ErrorResponse>
```

Two translation points, not one:

1. **Persistence → Domain:** wrap DB errors into domain exceptions so the service never sees `SQLException`.
2. **Domain → HTTP:** the advice converts domain exceptions into HTTP status + body.

Example of the first translation:

```java
@Repository
@RequiredArgsConstructor
public class UserRepositoryAdapter {

    private final UserMapper userMapper;

    public User findById(Long id) {
        try {
            return userMapper.findById(id)
                .orElseThrow(() -> new UserNotFoundException(id));
        } catch (DuplicateKeyException e) {
            throw new EmailAlreadyUsedException("duplicate email");
        } catch (DataAccessException e) {
            throw new PersistenceException("DB unavailable", e);
        }
    }
}
```

Now the service has a clean vocabulary. The advice only needs to know domain exceptions.

---

## Level 9 — Advanced: exception hierarchy design

Design a small, deliberate hierarchy.

```java
public abstract class ApplicationException extends RuntimeException {
    private final String code;
    protected ApplicationException(String code, String message) {
        super(message);
        this.code = code;
    }
    public String getCode() { return code; }
}

public class NotFoundException extends ApplicationException {
    public NotFoundException(String resource, Object id) {
        super(resource.toUpperCase() + "_NOT_FOUND", resource + " " + id + " not found");
    }
}

public class ConflictException extends ApplicationException {
    public ConflictException(String code, String message) { super(code, message); }
}

public class BusinessRuleException extends ApplicationException {
    public BusinessRuleException(String code, String message) { super(code, message); }
}
```

Then a single handler can map the base class:

```java
@ExceptionHandler(NotFoundException.class)
public ResponseEntity<ErrorResponse> handle(NotFoundException ex, HttpServletRequest req) {
    return build(HttpStatus.NOT_FOUND, ex.getCode(), ex.getMessage(), req);
}
```

Benefits:

- Consistent error codes.
- One handler per family, not per class.
- Easy to add new domain exceptions.

---

## Level 10 — Senior: RFC 7807 `ProblemDetail`

Spring 6 / Boot 3 has first-class support for the standard error format.

```java
@ExceptionHandler(UserNotFoundException.class)
public ProblemDetail handle(UserNotFoundException ex) {
    ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    pd.setTitle("User not found");
    pd.setType(URI.create("https://api.example.com/errors/user-not-found"));
    pd.setProperty("code", "USER_NOT_FOUND");
    return pd;
}
```

Enable global defaults:

```yaml
spring:
  mvc:
    problemdetails:
      enabled: true
```

Use `ProblemDetail` when:

- You want a standard client-consumable shape.
- You integrate with API gateways or tooling that expects RFC 7807.

Use a custom `ErrorResponse` when:

- You have an established internal format.
- You need extra fields that do not fit the standard.

Pick one and stay consistent across the whole API.

---

## Level 11 — Senior: security exceptions

Spring Security throws before your controller is reached. You handle it in two places.

**401 / 403 via `AuthenticationEntryPoint` and `AccessDeniedHandler`:**

```java
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {
    @Override
    public void commence(HttpServletRequest req, HttpServletResponse res,
                         AuthenticationException ex) throws IOException {
        res.setStatus(HttpStatus.UNAUTHORIZED.value());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.getWriter().write("""
            {"code":"UNAUTHORIZED","message":"Authentication required"}
            """);
    }
}

@Component
public class RestAccessDeniedHandler implements AccessDeniedHandler {
    @Override
    public void handle(HttpServletRequest req, HttpServletResponse res,
                       AccessDeniedException ex) throws IOException {
        res.setStatus(HttpStatus.FORBIDDEN.value());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.getWriter().write("""
            {"code":"FORBIDDEN","message":"Access denied"}
            """);
    }
}
```

Wire them:

```java
http.exceptionHandling(e -> e
    .authenticationEntryPoint(restAuthenticationEntryPoint)
    .accessDeniedHandler(restAccessDeniedHandler));
```

If you also want `@ExceptionHandler(AccessDeniedException.class)` to work for method security (`@PreAuthorize`), add:

```java
@ExceptionHandler(AccessDeniedException.class)
public ResponseEntity<ErrorResponse> handle(AccessDeniedException ex, HttpServletRequest req) {
    return build(HttpStatus.FORBIDDEN, "FORBIDDEN", "Access denied", req);
}
```

---

## Level 12 — Senior: observability and logging

Error handling and observability are the same topic.

Rules:

- Log **expected** exceptions at `WARN` or `INFO` with a short message, no stack trace.
- Log **unexpected** exceptions at `ERROR` with the full stack trace.
- Include a correlation/trace ID in the response and in the logs.
- Never log secrets, tokens, passwords, or full request bodies with PII.
- Include the path, method, status, and error code in the log line.

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<ErrorResponse> handleGeneric(Exception ex, HttpServletRequest req) {
    String traceId = MDC.get("traceId");
    log.error("Unhandled error [traceId={}] {} {}", traceId, req.getMethod(), req.getRequestURI(), ex);
    return build(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                 "Unexpected error", req, Map.of("traceId", traceId));
}
```

With Micrometer + OpenTelemetry or Sleuth, the trace ID propagates automatically. Your error response should echo it so support can find the log line.

---

## Level 13 — Senior: idempotency, retries, and transaction boundaries

Exceptions interact with transactions. Know these facts:

- By default, `@Transactional` rolls back on `RuntimeException` and `Error`, not on checked exceptions.
- Use `@Transactional(rollbackFor = Exception.class)` if you throw checked exceptions.
- If you catch an exception inside a transactional method and do not rethrow, the transaction may still commit — often a bug.
- Use `noRollbackFor` when an exception should not roll back (rare).

```java
@Transactional(rollbackFor = Exception.class)
public UserDto create(CreateUserRequest req) { ... }
```

For retries, combine with Spring Retry or Resilience4j and only retry **idempotent** operations:

```java
@Retryable(retryFor = TransientDataAccessException.class, maxAttempts = 3)
public UserDto findById(Long id) { ... }
```

After retries are exhausted, throw a domain exception that the advice maps to 503 or 500.

---

## Level 14 — Senior: async and reactive exceptions

**`@Async` methods:** exceptions do not propagate to the caller. They are swallowed unless you handle them.

```java
@Async
public CompletableFuture<UserDto> load(Long id) {
    return CompletableFuture.supplyAsync(() -> {
        try { return userService.findById(id); }
        catch (Exception e) { throw new CompletionException(e); }
    });
}
```

Configure a global handler:

```java
@Configuration
public class AsyncConfig implements AsyncConfigurer {
    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return (ex, method, params) ->
            log.error("Async error in {}", method.getName(), ex);
    }
}
```

**WebFlux / Reactor:** use `onErrorMap` and `onErrorResume` to translate, then a `@RestControllerAdvice` still works because WebFlux honors it.

```java
return userService.findById(id)
    .onErrorMap(NoSuchElementException.class, e -> new UserNotFoundException(id));
```

**Streaming / SSE:** once the response is committed (bytes flushed), you cannot change the status code. Send an error event in the stream instead.

---

## Level 15 — Senior: testing exception handling

Test the advice, not just the service.

**Slice test with MockMvc:**

```java
@WebMvcTest(UserController.class)
class UserControllerExceptionTest {

    @Autowired MockMvc mvc;
    @MockBean UserService userService;

    @Test
    void returns404WhenUserMissing() throws Exception {
        when(userService.findById(999L)).thenThrow(new UserNotFoundException(999L));

        mvc.perform(get("/api/users/999"))
           .andExpect(status().isNotFound())
           .andExpect(jsonPath("$.code").value("USER_NOT_FOUND"))
           .andExpect(jsonPath("$.path").value("/api/users/999"));
    }

    @Test
    void returns400OnValidationFailure() throws Exception {
        mvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
           .andExpect(status().isBadRequest())
           .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
           .andExpect(jsonPath("$.fieldErrors.name").exists());
    }
}
```

**Full integration test** with `@SpringBootTest` + `@AutoConfigureMockMvc` to verify the whole stack including security and transaction rollback.

**Contract tests:** assert the exact JSON shape of error responses, because clients depend on it.

---

## Level 16 — Senior: architecture summary

```text
+--------------------------------------------------------------+
|  Client                                                      |
+--------------------------------------------------------------+
                    ^  HTTP status + JSON error
                    |
+--------------------------------------------------------------+
|  @RestControllerAdvice (multiple, @Order)                    |
|    ValidationExceptionHandler       -> 400                   |
|    DomainExceptionHandler           -> 404/409/422           |
|    SecurityExceptionHandler         -> 401/403               |
|    PersistenceExceptionHandler      -> 409/503               |
|    FallbackExceptionHandler         -> 500                   |
+--------------------------------------------------------------+
                    ^  domain exceptions
                    |
+--------------------------------------------------------------+
|  Service layer                                               |
|    throws NotFoundException, ConflictException, ...          |
|    @Transactional(rollbackFor = Exception.class)             |
+--------------------------------------------------------------+
                    ^  translated infrastructure exceptions
                    |
+--------------------------------------------------------------+
|  Persistence layer (MyBatis / JPA)                           |
|    catches DataAccessException, SQLException                 |
|    throws domain exceptions                                  |
+--------------------------------------------------------------+
                    ^
                    |
                 Database
```

Principles:

1. **Single responsibility per layer.** Persistence translates DB errors. Service expresses business rules. Web translates to HTTP.
2. **Exceptions carry meaning, not messages.** Use types and error codes, not string parsing.
3. **One error shape for the whole API.** Consistent JSON contract.
4. **Never leak internals.** No stack traces, no SQL, no class names to clients.
5. **Log where it matters.** Expected errors are info, unexpected are error with stack trace, always with a trace ID.
6. **Order matters.** Split advices and control precedence with `@Order`.
7. **Test the contract.** MockMvc assertions on status and JSON path.
8. **Respect transaction boundaries.** Know when rollback happens and when it does not.
9. **Handle async and reactive separately.** Exceptions do not propagate the same way.
10. **Standardize when possible.** Prefer RFC 7807 `ProblemDetail` if your clients expect it.

---

## Cheat sheet by level

| Level | Skill |
|---|---|
| Beginner | Know that uncaught exceptions become 500. |
| Beginner+ | Avoid try/catch in controllers. |
| Intermediate | Use `@RestControllerAdvice` + `@ExceptionHandler`. |
| Intermediate+ | Separate domain vs infrastructure exceptions. |
| Intermediate+ | Map validation exceptions correctly. |
| Advanced | Split advices with `@Order`, scope with `basePackages`. |
| Advanced | Translate DB errors at the repository boundary. |
| Advanced | Design an `ApplicationException` hierarchy with codes. |
| Senior | Use `ProblemDetail` (RFC 7807). |
| Senior | Handle security exceptions in Security filter + advice. |
| Senior | Add trace IDs and log discipline. |
| Senior | Respect transaction, retry, and idempotency semantics. |
| Senior | Handle async / reactive exceptions. |
| Senior | Test error contracts with MockMvc. |
| Senior | Enforce layered exception translation as architecture. |



[[Java]]
[[0 - Spring Framework]]