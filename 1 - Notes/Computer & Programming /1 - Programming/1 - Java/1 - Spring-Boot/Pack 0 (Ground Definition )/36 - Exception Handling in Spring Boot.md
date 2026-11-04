

Exception handling in Spring Boot is the practice of deciding, in one organized place, what your API tells the client when something goes wrong. Services and repositories throw exceptions (user not found, validation failed, unique constraint violated, a bug), and the framework's job is to translate each of them into a proper HTTP response with the right status code and a consistent body. The core idea is **separation of concerns**: your business code *throws* meaningful exceptions without knowing anything about HTTP, and a central handler *translates* them into responses. This is the "throw, don't return errors" approach we kept pointing toward in the DTO, validation and `ResponseEntity` tutorials, and now we build it fully.

## The problem: errors without a strategy

If you do nothing, Spring Boot still responds, but not helpfully. An uncaught exception becomes a generic `500 Internal Server Error` with Boot's default error JSON (timestamp, status, path), and details are hidden by default. A client cannot tell "you sent bad data" from "our server crashed".

If you handle errors by hand in each controller, you get a different mess:

```java
User user = userRepository.findById(id).orElse(null);
if (user == null) {
    return ResponseEntity.status(404).body("not found");   // one format here
}
// ...another controller returns {"error": "..."}; a third returns plain text
```

This is repetitive, inconsistent, and buries the success path under error branches. What you want is:

- Business code that simply throws `UserNotFoundException`.
- One place that maps exceptions to status codes and bodies.
- Every error across the whole API sharing one shape.

## How Spring finds a handler (the mechanism)

When an exception escapes a controller method, Spring MVC hands it to a chain of **exception resolvers**. The ones that matter, in the order you will meet them:

1. **`@ExceptionHandler` methods** (in the controller, or in a global advice class)
2. **`@ResponseStatus` on the exception class**
3. **Spring's built-in handling** (`DefaultHandlerExceptionResolver`) for framework exceptions like `HttpRequestMethodNotSupportedException` (405) and `HttpMessageNotReadableException` (400)
4. **Boot's fallback**: the `/error` endpoint and `BasicErrorController`, which produces the default JSON

If none of the first three claims the exception, it falls through to the generic error page or JSON. Your goal is to claim the exceptions you care about before they get there.

## Step 1: Create meaningful exceptions

Start with exceptions that describe business situations, not technical ones. Extending `RuntimeException` (unchecked) is the standard choice in Spring, because Spring's `@Transactional` rolls back on unchecked exceptions by default but not on checked ones, and unchecked exceptions do not clutter method signatures.

```java
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(Long id) {
        super("User %d not found".formatted(id));
    }
}

public class EmailAlreadyUsedException extends RuntimeException {
    public EmailAlreadyUsedException(String email) {
        super("Email already in use: " + email);
    }
}
```

The service throws them and stays free of HTTP concerns:

```java
@Transactional(readOnly = true)
public UserResponse get(Long id) {
    return userRepository.findById(id)
            .map(userMapper::toResponse)
            .orElseThrow(() -> new UserNotFoundException(id));
}
```

## Step 2: Handle them in one place with `@RestControllerAdvice`

`@RestControllerAdvice` marks a class whose `@ExceptionHandler` methods apply to **every controller** in the application. Each handler declares which exception type it catches and returns the response.

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ProblemDetail> handleNotFound(UserNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("User not found");
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(problem);
    }

    @ExceptionHandler(EmailAlreadyUsedException.class)
    public ProblemDetail handleConflict(EmailAlreadyUsedException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage());
    }
}
```

Notice the second handler returns a `ProblemDetail` directly. Because a `ProblemDetail` already carries its own status, Spring uses it, so wrapping it in `ResponseEntity` is optional. Use `ResponseEntity` when you also need custom headers.

**Spring picks the most specific matching handler.** If you handle both `UserNotFoundException` and `RuntimeException`, a `UserNotFoundException` goes to the first. That makes a final catch-all safe:

```java
@ExceptionHandler(Exception.class)
public ProblemDetail handleUnexpected(Exception ex) {
    log.error("Unhandled exception", ex);          // log the full stack trace on the server
    return ProblemDetail.forStatusAndDetail(
            HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred");   // never leak internals
}
```

Two rules for the catch-all: always log the real exception, and never put `ex.getMessage()` or a stack trace in a 500 response, since that can reveal class names, SQL, or paths to attackers.

## `ProblemDetail`: the standard error body

Instead of inventing your own `{"error": ...}` shape, Spring 6 and Boot 3 support **RFC 9457 Problem Details**, a standard JSON format for HTTP errors:

```json
{
  "type": "about:blank",
  "title": "User not found",
  "status": 404,
  "detail": "User 42 not found",
  "instance": "/users/42"
}
```

You can attach extra fields with `problem.setProperty("timestamp", Instant.now())`, and set a `type` URI that identifies the error category. Content type is `application/problem+json`. Using a standard format means clients, tools and teammates already know how to read it.

You can switch on Boot's automatic problem details for Spring's own exceptions with:

```properties
spring.mvc.problemdetails.enabled=true
```

Alternatively, extend `ResponseEntityExceptionHandler` in your advice class. It provides handlers for all the standard Spring MVC exceptions (400, 404, 405, 415 and so on) and renders them as `ProblemDetail`, so you only add your own.

## Handling validation errors

Earlier we saw that a failed `@Valid` throws `MethodArgumentNotValidException`. Handle it to return field-level detail:

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
    ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
    Map<String, String> errors = new LinkedHashMap<>();
    ex.getBindingResult().getFieldErrors()
      .forEach(e -> errors.put(e.getField(), e.getDefaultMessage()));
    problem.setProperty("errors", errors);
    return problem;
}
```

Constraints applied to path variables and request parameters (with `@Validated` on the controller) throw a different exception, `ConstraintViolationException` (or `HandlerMethodValidationException` in newer Spring versions). Add handlers for those too, or you will get a surprise `500`.

## Database exceptions

Spring translates vendor-specific SQL errors into its own unchecked `DataAccessException` hierarchy, which is why you never deal with raw `SQLException`. The one you will handle most is `DataIntegrityViolationException`, thrown when a unique, foreign key, or not-null constraint fails:

```java
@ExceptionHandler(DataIntegrityViolationException.class)
public ProblemDetail handleIntegrity(DataIntegrityViolationException ex) {
    return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, "Request conflicts with existing data");
}
```

This is the safety net behind the "username already taken" race condition from the validation tutorial. Use a generic message here, because the exception text contains raw SQL details.

## Choosing status codes

| Situation | Status |
|---|---|
| Malformed JSON, failed input validation | 400 |
| Not authenticated | 401 |
| Authenticated but not allowed | 403 |
| Resource does not exist | 404 |
| Duplicate / state conflict | 409 |
| Well-formed but violates a business rule | 422 (or 409) |
| Unexpected server failure | 500 |

## Other ways to handle exceptions (and when)

**`@ExceptionHandler` inside a controller** handles exceptions for that controller only. It overrides the global advice for that controller. Useful for genuinely controller-specific cases, but the global advice is the default choice.

**`@ResponseStatus` on an exception class** is the shortest option:

```java
@ResponseStatus(HttpStatus.NOT_FOUND)
public class UserNotFoundException extends RuntimeException { ... }
```

It is quick, but it ties the exception to HTTP and offers no control over the body, so it suits small projects better than layered ones.

**`ResponseStatusException`** lets you throw an HTTP-aware exception inline, with no custom class: `throw new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found")`. Handy for prototypes, but it puts HTTP knowledge inside your service layer, which is what we are trying to avoid.

## Design guidelines

- **Exceptions are for exceptional flow**, not normal control flow. "User not found" on a lookup by ID is a reasonable exception, but do not use exceptions to implement ordinary branching.
- **Business exceptions carry meaning, not HTTP.** The service says `InsufficientFundsException`; only the advice decides it is a `422`.
- **One error shape for the whole API**, ideally `ProblemDetail`.
- **Log server errors, not client errors.** A `404` is normal traffic; a `500` deserves a stack trace in your logs.
- **Never expose internals** in responses: no stack traces, SQL, or class names.
- **Consider an error code field** (for example `"code": "USER_NOT_FOUND"`) so clients can react programmatically without parsing messages.

## Common mistakes

- Catching `Exception` inside controllers and returning `200` with an error message in the body.
- Swallowing exceptions with an empty `catch` block, so failures vanish.
- Catching an exception in a service, then not rethrowing it inside a `@Transactional` method, which can prevent the rollback you expected.
- Leaking `ex.getMessage()` from unexpected exceptions to the client.
- Writing a catch-all handler and forgetting that it also catches Spring's own exceptions unless you extend `ResponseEntityExceptionHandler` or handle them separately, turning intended `400`s and `405`s into `500`s.
- Creating one exception class per tiny case instead of a small hierarchy (for example a base `NotFoundException` with subclasses, handled once).

## Related concepts to study next

- **Custom exception hierarchies** and error codes
- **`ResponseEntityExceptionHandler`** and the list of exceptions it covers
- **Spring Security exception handling** (`AuthenticationEntryPoint`, `AccessDeniedHandler`), since security errors happen before controllers and bypass `@RestControllerAdvice`
- **Exception handling in filters**, which also sits outside MVC's reach
- **`@Transactional` rollback rules** (`rollbackFor`, checked vs. unchecked)
- **Logging and correlation IDs** (MDC) so an error response can be matched to a log line
- **Testing handlers** with `@WebMvcTest` and `MockMvc`




[[Spring Framework]]