

## What an exception handler is

An exception handler in Spring MVC is a method that catches an exception thrown while a request is being processed and turns it into an HTTP response. You mark the method with `@ExceptionHandler`. If you put it in a class annotated with `@RestControllerAdvice`, it applies to all your controllers.

## The mental model

Think of it as one big `try/catch` wrapped around every controller method, written once instead of in each place. Your code throws; the handler catches and decides the status code and JSON body.

The analogy breaks in two places:

- It only wraps the **controller layer** (the `DispatcherServlet`). Exceptions thrown in servlet filters, including Spring Security filters, happen before Spring MVC gets involved, so your handler never sees them.
- Spring doesn't literally use `try/catch` here. It asks a chain of `HandlerExceptionResolver` objects, and `@ExceptionHandler` support is one of them.

## The key insight: handlers don't care which layer threw

This answers your folder question. A service throws `UserNotFoundException`, the controller doesn't catch it, so it bubbles up to Spring MVC, which finds a matching handler. The handler is chosen by **exception type**, not by where the exception came from.

So "controller exceptions go here, service exceptions go there" isn't a real distinction. By the time the handler runs, it's all just an exception that escaped the controller. Don't split by layer. Split by **meaning** (not found, conflict, validation, and so on), or by **feature** when the project grows.

## Where to put the files

For a small or medium project, one `exception` (or `error`) package is fine:

```
com.example.app
├── controller
│   └── UserController.java
├── service
│   └── UserService.java
├── repository
└── exception
    ├── GlobalExceptionHandler.java
    ├── ApiError.java
    ├── BusinessException.java
    ├── ResourceNotFoundException.java
    └── DuplicateResourceException.java
```

As the project grows, package by feature, with shared error infrastructure in `common`:

```
com.example.app
├── common
│   └── error
│       ├── GlobalExceptionHandler.java
│       ├── ApiError.java
│       └── BusinessException.java
├── user
│   ├── UserController.java
│   ├── UserService.java
│   └── UserNotFoundException.java
└── order
    ├── OrderController.java
    ├── OrderService.java
    └── OrderAlreadyShippedException.java
```

The rule of thumb is that **exceptions live next to the feature that throws them** (`UserNotFoundException` belongs with `user`), and the **one global handler lives in `common`** because it serves everyone.

## Global vs local handlers

You have three scopes:

1. **Inside a controller:** an `@ExceptionHandler` method in `UserController` only handles exceptions from that controller. It also wins over the global one for that controller.
2. **Global:** `@RestControllerAdvice` with no arguments handles everything.
3. **Scoped advice:** a global-style class limited to certain controllers:

```java
@RestControllerAdvice(basePackages = "com.example.app.order")
public class OrderExceptionHandler { ... }
```

You can also limit by `assignableTypes = {OrderController.class}` or by annotation. That's the only time a second handler class makes sense: one feature needs different error formatting or special rules. Otherwise, one global handler is the usual answer.

## Designing the classes

### 1. The exceptions

```java
public abstract class BusinessException extends RuntimeException {

    private final String code;

    protected BusinessException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
```

```java
public class ResourceNotFoundException extends BusinessException {

    public ResourceNotFoundException(String resource, Object id) {
        super("RESOURCE_NOT_FOUND", resource + " with id " + id + " was not found");
    }
}
```

Line by line:

- `extends RuntimeException`: unchecked on purpose. Spring's `@Transactional` rolls back on unchecked exceptions by default but **not** on checked ones, which surprises many people. Unchecked exceptions also keep service signatures clean.
- `abstract BusinessException`: a shared parent lets you write one handler for "any business rule violation," while still allowing specific handlers for specific children.
- `code`: a stable, machine-readable string. Clients (a front-end or Android app) should switch on `code`, never on the human-readable message, because messages change.
- `ResourceNotFoundException(String resource, Object id)`: builds a consistent message in one place, so no one writes "user not found" in five different ways.

### 2. The error response shape

```java
public record ApiError(
        Instant timestamp,
        int status,
        String code,
        String message,
        String path,
        List<FieldViolation> violations) {

    public record FieldViolation(String field, String message) {}
}
```

- A `record` is ideal: immutable data carrier, Jackson serializes it directly.
- Every error your API returns has the **same shape**. That consistency is half the value of a global handler.
- `violations` is only filled for validation errors and is `null` otherwise.

### 3. The handler

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(ResourceNotFoundException ex,
                                                   HttpServletRequest request) {
        log.warn("Not found: {}", ex.getMessage());
        return build(HttpStatus.NOT_FOUND, ex.getCode(), ex.getMessage(), request, null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex,
                                                     HttpServletRequest request) {
        List<ApiError.FieldViolation> violations = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(fe -> new ApiError.FieldViolation(fe.getField(), fe.getDefaultMessage()))
                .toList();
        return build(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED",
                "Request validation failed", request, violations);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleUnexpected(Exception ex, HttpServletRequest request) {
        log.error("Unexpected error on {}", request.getRequestURI(), ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Something went wrong", request, null);
    }

    private ResponseEntity<ApiError> build(HttpStatus status, String code, String message,
                                           HttpServletRequest request,
                                           List<ApiError.FieldViolation> violations) {
        ApiError body = new ApiError(Instant.now(), status.value(), code,
                message, request.getRequestURI(), violations);
        return ResponseEntity.status(status).body(body);
    }
}
```

Walking through it:

- `@RestControllerAdvice` is `@ControllerAdvice` plus `@ResponseBody`, so returned objects become JSON.
- `handleNotFound`: Spring injects the thrown exception and the current request as parameters. Use `warn` here, because a 404 is the client's mistake and not an incident.
- `handleValidation`: when `@Valid` fails on a `@RequestBody`, Spring throws `MethodArgumentNotValidException`. We turn its field errors into the `violations` list so the client knows exactly which fields failed.
- `handleUnexpected`: the **catch-all**. It logs the full stack trace (the extra `ex` argument) but returns a vague message. Never send `ex.getMessage()` or a stack trace to the client for unexpected errors, because that leaks internals.
- `build`: one private helper so every response has the same shape.

## Edge cases that bite people

- **Most specific wins.** If both `ResourceNotFoundException` and `Exception` handlers exist, Spring picks the closest match in the class hierarchy. That's why the catch-all is safe to have.
- **The catch-all can break Spring Security.** With method security (`@PreAuthorize`), an `AccessDeniedException` can be thrown inside the controller layer. Your `Exception.class` handler would catch it and turn a 403 into a 500. Either add explicit handlers for `AccessDeniedException` that rethrow or return 403, or be careful with the catch-all.
- **Filter exceptions are invisible to your advice.** Authentication failures and anything thrown in a filter need Spring Security's `AuthenticationEntryPoint` and `AccessDeniedHandler`.
- **Spring's own exceptions** (malformed JSON, wrong HTTP method, missing parameter) are not covered by your handlers unless you add them or extend `ResponseEntityExceptionHandler`, which already handles them.
- **Log level matters.** 4xx as `warn` or `info`, 5xx as `error`. Otherwise your error logs fill with client typos.

## Alternatives, and when to use them

- **`@ResponseStatus` on the exception class:** quick, but you can't customize the body. Fine for tiny projects.
- **`ResponseStatusException`:** throw it inline with a status. Convenient, but it scatters HTTP knowledge into your service layer, which is why the custom-exception approach scales better.
- **Local `@ExceptionHandler` in a controller:** good for one controller's special case only.
- **`ProblemDetail` (Spring 6 / Boot 3+):** a built-in class implementing the standard RFC 9457 format. Many teams now return this instead of a hand-made `ApiError`. Worth switching to once the design above makes sense.
- **Boot's default `/error` page (`BasicErrorController`):** what you get if you do nothing. It works, but the format isn't yours to control.




[[Exception]]
[[Spring Framework]]