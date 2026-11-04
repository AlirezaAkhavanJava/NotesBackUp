

# Exception Handling Reference: Annotations and Exceptions

**Definition:** Two lists: the annotations that _declare, scope, or influence_ how exceptions turn into HTTP responses, and the exceptions you will meet in a Spring Boot web app, grouped by where they come from.

**Mental model:** Annotations are the wiring, and exceptions are the signals. Each exception is a message from a specific layer (web framework, validation, database, security, JDK, outgoing HTTP client). A mapping to a status code only makes sense once you know which layer raised it.

## Part 1: Annotations

|Annotation|Package|Goes on|Purpose|
|---|---|---|---|
|`@ExceptionHandler`|`org.springframework.web.bind.annotation`|Method|Says "call me for these exception types"|
|`@RestControllerAdvice`|same|Class|Global handler container, return values written as JSON|
|`@ControllerAdvice`|same|Class|Same, but return values resolve as views unless `@ResponseBody` is present|
|`@ResponseStatus`|same|Exception class or handler method|Fixes the HTTP status|
|`@ResponseBody`|same|Method/class|Write the return value to the body (already implied by `@RestControllerAdvice`)|
|`@Order`|`org.springframework.core.annotation`|Advice class|Priority between several advice classes|
|`@Valid` / `@Validated`|Jakarta / Spring|Parameter / class|Triggers validation, which is what _throws_ the validation exceptions|
|`@Transactional`|`org.springframework.transaction.annotation`|Class/method|Decides which exceptions roll back|
|`@MessageExceptionHandler`|`org.springframework.messaging.handler.annotation`|Method|The WebSocket/STOMP equivalent of `@ExceptionHandler`|

### `@ExceptionHandler`

```java
@ExceptionHandler(ProductNotFoundException.class)                 // one type
@ExceptionHandler({EmailTakenException.class, ConflictException.class})  // several types
@ExceptionHandler                                                 // no value: inferred from the method parameter
ProblemDetail handle(IllegalStateException ex) { ... }
```

- Without a `value`, Spring reads the exception type from the method parameter. Declaring neither is a startup error.
- The method name is irrelevant. Only the annotation and the types matter.
- Allowed parameters: the exception itself, `HttpServletRequest`/`WebRequest`, `HttpServletResponse`, `Principal`, `Locale`, `HandlerMethod` (the controller method that threw).
- Allowed return types: `ProblemDetail`, `ResponseEntity<T>`, a plain object (becomes the body), `String` (a view name in a plain `@ControllerAdvice`), or `void` if you write to the response yourself.
- Where it is placed decides the scope: inside a controller means that controller only, and inside an advice class means global (or whatever the advice is scoped to).

### `@ControllerAdvice` / `@RestControllerAdvice` and their scoping attributes

```java
@RestControllerAdvice                                         // everything
@RestControllerAdvice(basePackages = "com.example.api")       // controllers in this package
@RestControllerAdvice(basePackageClasses = AdminController.class)
@RestControllerAdvice(assignableTypes = {OrderController.class, ProductController.class})
@RestControllerAdvice(annotations = PublicApi.class)          // controllers carrying a custom annotation
```

- They are `@Component`s, so component scanning registers them. The class must live under your `@SpringBootApplication` package.
- Scoping lets you return a different error format for a public API and an admin API.
- `@RestControllerAdvice` = `@ControllerAdvice` + `@ResponseBody`. In a plain `@ControllerAdvice`, returning an object without `@ResponseBody` makes Spring look for a _view_ with that name, so you get a template error instead of JSON.

### `@ResponseStatus`

```java
@ResponseStatus(HttpStatus.NOT_FOUND)                         // on an exception class
public class ProductNotFoundException extends RuntimeException { ... }

@ExceptionHandler(ConflictException.class)                    // on a handler method
@ResponseStatus(HttpStatus.CONFLICT)
ErrorBody handle(ConflictException ex) { ... }
```

- On a handler method, it sets the status for the returned body. Without it, a handler returning a plain object responds with **200**.
- On an exception class, it gives status-only handling with no handler method. The body then comes from Boot's `/error` fallback.
- Its `reason` attribute calls `response.sendError(status, reason)`. That hands the response to the container's error page and bypasses your JSON body. Avoid `reason` in REST APIs.

### `@Order` for several advice classes

```java
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
class SpecificHandler { ... }

@RestControllerAdvice
@Order(Ordered.LOWEST_PRECEDENCE)
class FallbackHandler {
    @ExceptionHandler(Exception.class) ...
}
```

- The lower the order value, the earlier the advice is consulted. Unordered advice counts as lowest.
- If your catch-all `Exception.class` handler sits in a higher-priority advice than your specific handlers, it **wins** for every exception, because the first advice with _any_ match is used. The "closest type wins" rule only applies _within_ one advice class. Keep the catch-all in its own low-priority advice, or in the same class as the others.

### `@Transactional` and exceptions

```java
@Transactional                                        // rolls back on RuntimeException and Error
@Transactional(rollbackFor = IOException.class)       // also roll back on this checked exception
@Transactional(noRollbackFor = SoftLimitException.class)
```

- By default a **checked** exception commits the transaction. This is the main reason domain exceptions extend `RuntimeException`.
- Rollback is decided by the exception that _leaves the transactional method_. If you catch it inside and return normally, the transaction commits.
- Marking a handler class or controller `@Transactional` is not what makes this work. The transaction boundary is the **service**, and the exception handler runs after the transaction is already finished.

### Related annotations you will see

- `@ResponseStatus` and `@ExceptionHandler` have WebFlux equivalents with the same names, and the same advice annotations work there.
- Spring Retry's `@Retryable(retryFor = ...)` and `@Recover` handle exceptions by retrying, not by producing responses.
- Lombok's `@SneakyThrows` hides checked exceptions from the compiler. It is not a Spring feature, and I'd avoid it while learning.

## Part 2: Exceptions

### The hierarchy you need in your head

```
Throwable
├── Error                                  (OutOfMemoryError ...: don't handle)
└── Exception
    ├── (checked)  IOException, SQLException ...
    └── RuntimeException
        ├── IllegalArgumentException ── NumberFormatException
        ├── IllegalStateException
        ├── NullPointerException, ClassCastException, IndexOutOfBoundsException ...
        ├── org.springframework.dao.DataAccessException
        │       ├── DataIntegrityViolationException ── DuplicateKeyException
        │       ├── OptimisticLockingFailureException
        │       └── ...
        ├── jakarta.validation.ValidationException ── ConstraintViolationException
        ├── org.springframework.web.server.ResponseStatusException
        ├── AuthenticationException        (Spring Security)
        └── AccessDeniedException          (Spring Security)
```

Handler matching uses this tree: the **closest ancestor** declared in an `@ExceptionHandler` wins.

### Spring MVC exceptions (thrown by the framework itself)

If your advice extends `ResponseEntityExceptionHandler`, these get a ready-made `ProblemDetail` response. Otherwise `DefaultHandlerExceptionResolver` sets only the status.

|Exception|Status|When|
|---|---|---|
|`HttpMessageNotReadableException`|400|Malformed or unparseable JSON body|
|`MethodArgumentNotValidException`|400|`@Valid @RequestBody` failed|
|`HandlerMethodValidationException`|400|Constraint on a controller parameter failed (Spring 6.1+)|
|`BindException`|400|`@Valid` failed on a form/query object (`@ModelAttribute`)|
|`MethodArgumentTypeMismatchException`|400|`/products/abc` where a `Long` is expected|
|`MissingServletRequestParameterException`|400|Required `@RequestParam` absent|
|`MissingServletRequestPartException`|400|Required multipart part absent|
|`ServletRequestBindingException`|400|Missing header or cookie binding|
|`HttpMediaTypeNotAcceptableException`|406|Client's `Accept` can't be satisfied|
|`HttpRequestMethodNotSupportedException`|405|Wrong HTTP verb for the URL|
|`HttpMediaTypeNotSupportedException`|415|Unsupported `Content-Type`|
|`NoResourceFoundException`|404|Unknown URL (Spring 6.1+)|
|`NoHandlerFoundException`|404|Unknown URL, in older style or with specific config|
|`MaxUploadSizeExceededException`|413|Upload over the size limit|
|`AsyncRequestTimeoutException`|503|Async request timed out|
|`MissingPathVariableException`|500|Your mapping and `@PathVariable` don't match (a server bug)|
|`HttpMessageNotWritableException`|500|Response can't be serialized (a server bug)|
|`ConversionNotSupportedException`|500|No converter for a value (a server bug)|

Note the three 500s: they mean _your code or configuration_ is wrong, not the client's request.

### Spring's own "carry a status" exceptions

- `ResponseStatusException`: throw it with a status and reason, no handler needed.
- `ErrorResponseException`: a base class for your own exceptions that carry a `ProblemDetail` themselves. It implements the `ErrorResponse` interface, which is why Spring renders it as a proper problem response without extra code.

### Validation exceptions

|Exception|Package|Thrown by|
|---|---|---|
|`MethodArgumentNotValidException`|Spring|`@Valid @RequestBody`|
|`HandlerMethodValidationException`|Spring|Constraints on controller parameters (6.1+)|
|`ConstraintViolationException`|`jakarta.validation`|`@Validated` services, parameter constraints with class-level `@Validated`, and entity persist-time checks|
|`UnexpectedTypeException`|`jakarta.validation`|A constraint on an unsupported type (`@NotBlank` on `Integer`). It's a coding error, not user error|
|`ValidationException`|`jakarta.validation`|The parent of the two above|

### Persistence exceptions

|Exception|Meaning|Typical status|
|---|---|---|
|`DataIntegrityViolationException`|`UNIQUE`, `NOT NULL`, foreign key, or length violation in the DB|409 or 400|
|`DuplicateKeyException`|A unique violation (only in JDBC/some stacks; with JPA you usually see the parent type)|409|
|`EmptyResultDataAccessException`|`deleteById` on a missing row, or an expected row was absent|404|
|`IncorrectResultSizeDataAccessException`|Expected one row, found several|500|
|`OptimisticLockingFailureException` / `ObjectOptimisticLockingFailureException`|`@Version` mismatch: someone else updated the row|409|
|`PessimisticLockingFailureException` / `CannotAcquireLockException`|Lock timeouts, deadlocks|503 or 409|
|`JpaObjectRetrievalFailureException`|Wraps `EntityNotFoundException`|404|
|`jakarta.persistence.EntityNotFoundException`|`getReference` on a missing row|404|
|`jakarta.persistence.NoResultException` / `NonUniqueResultException`|`getSingleResult()` returned zero / several|404 / 500|
|`LazyInitializationException`|Lazy relation accessed after the session closed (a bug)|500|
|`TransactionSystemException`|Commit failed. Often wraps a validation or DB failure|depends on cause|
|`DataAccessResourceFailureException` / `CannotCreateTransactionException`|Database unreachable|503|
|`QueryTimeoutException`|Query exceeded its timeout|504 or 503|

Spring translates the raw `SQLException`/Hibernate exceptions into the `DataAccessException` hierarchy, so your handlers don't depend on the JDBC driver. A name clash to watch for: Hibernate has its own `org.hibernate.exception.ConstraintViolationException` (a database constraint), which is a different class from `jakarta.validation.ConstraintViolationException` (a validation constraint). Check the import, since importing the wrong one makes your handler silently never match.

### Security exceptions

|Exception|Status|Note|
|---|---|---|
|`AuthenticationException` and subclasses (`BadCredentialsException`, `DisabledException`, `LockedException`, `InsufficientAuthenticationException`, `UsernameNotFoundException`)|401|Login and token failures|
|`AccessDeniedException`|403|Authenticated but not allowed|
|`AuthorizationDeniedException`|403|Subclass thrown by `@PreAuthorize` and friends (Security 6.3+)|

Exceptions from Security's **filters** never reach `@RestControllerAdvice`. They go through `AuthenticationEntryPoint` and `AccessDeniedHandler`. Only exceptions thrown from `@PreAuthorize`-style method security (which run inside the MVC pipeline) reach your advice, which is why a catch-all `Exception.class` handler turns them into 500s unless you add explicit handlers.

### JDK exceptions you will see surfaced

|Exception|Usual meaning|Recommended handling|
|---|---|---|
|`IllegalArgumentException`|A caller passed a bad argument|Often 400, but only if you're sure it came from input|
|`NumberFormatException`|Subclass of the above, from `Integer.parseInt` etc.|400|
|`IllegalStateException`|Object is in the wrong state|409 or 500 depending on cause|
|`NoSuchElementException`|`Optional.get()` or `orElseThrow()` with no argument on empty|Usually a bug: use `orElseThrow(() -> new YourException())`|
|`NullPointerException`|A bug|500, log it|
|`UnsupportedOperationException`|Modifying an immutable collection, or a not-implemented method|500|
|`DateTimeParseException`|Invalid date string|400|
|`IOException` / `UncheckedIOException`|File or network problem|500 or 502|

A trap with `IllegalArgumentException`: mapping it globally to 400 is tempting, but libraries throw it for internal bugs too. Then a server bug is reported as "your request is wrong". Prefer your own exception types for client errors.

### Exceptions from calling other services

|Exception|Client|Meaning|
|---|---|---|
|`HttpClientErrorException` (4xx), `HttpServerErrorException` (5xx)|`RestTemplate` (also `RestClient`, as subclasses of `RestClientResponseException`)|The remote service answered with an error status|
|`ResourceAccessException`|`RestTemplate`/`RestClient`|I/O problem: timeout, connection refused|
|`WebClientResponseException`|`WebClient`|Error status from the remote service|
|`WebClientRequestException`|`WebClient`|Connection-level failure|

Don't forward the remote status to your client unchanged. If a downstream service returns 404 for something your client didn't ask for directly, translate it, typically to 502 Bad Gateway or 503/504 for timeouts, because _your_ API didn't fail in the way the client's request implied.

## One handler class that uses most of this

```java
@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler({ProductNotFoundException.class, EmptyResultDataAccessException.class})
    ProblemDetail handleNotFound(Exception ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, "Resource not found");
    }

    @ExceptionHandler({DataIntegrityViolationException.class,
                       ObjectOptimisticLockingFailureException.class})
    ProblemDetail handleConflict(Exception ex) {
        log.warn("Conflict", ex);
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, "Conflicts with existing data");
    }

    @ExceptionHandler(AccessDeniedException.class)
    ProblemDetail handleDenied(AccessDeniedException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.FORBIDDEN, "Access denied");
    }

    @ExceptionHandler(Exception.class)
    ProblemDetail handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "Unexpected error");
    }
}
```

Line by line:

- `extends ResponseEntityExceptionHandler`: Covers the whole Spring MVC table above with proper bodies, so you don't list those exceptions yourself.
- `@ExceptionHandler({A.class, B.class})`: One method handles two exception types. The parameter is typed as `Exception` (the common supertype), since Spring must be able to pass either one in.
- `handleNotFound` hides the original message deliberately. `EmptyResultDataAccessException`'s message contains SQL-ish internal details.
- `handleConflict` logs at `warn` and returns a generic message. The raw `DataIntegrityViolationException` message contains table and constraint names.
- `handleDenied`: Exists so the catch-all doesn't turn a 403 into a 500.
- `handleUnexpected`: The last resort. `Exception.class` is the farthest ancestor, so Spring picks it only when nothing more specific matches.

## Edge cases

- **Ambiguous mapping:** if you extend `ResponseEntityExceptionHandler` and add your own `@ExceptionHandler` for something it already covers, Spring throws "Ambiguous @ExceptionHandler method mapped". Override the base `handleXxx` method instead.
- **Cause chains:** if no handler matches the thrown exception, Spring also tries `getCause()`. So a wrapped exception can still reach a handler for the inner type.
- **Checked exceptions** thrown from a controller work with handlers too, but then you need `throws` on every layer. Prefer unchecked domain exceptions.
- **`@ResponseStatus` on an exception plus a handler for the same exception:** the handler decides, and the annotation on the class is ignored. Using both only confuses readers.

## Alternatives to maintaining an exception-per-case list

- A single `ApiException(HttpStatus, String code)` base class with one handler, so new errors need no new handler.
- `ResponseStatusException` inline, which is fast but scatters status codes through the service code.
- Returning result objects for expected failures, which avoids exceptions but has no built-in Spring support.

**Rule of thumb:** `@RestControllerAdvice` + `@ExceptionHandler` do the work, `@ResponseStatus` sets the code when you return a plain body, `@Order` only matters with several advice classes, and an exception's package tells you its layer.




[[Exception]]
[[Spring Framework]]