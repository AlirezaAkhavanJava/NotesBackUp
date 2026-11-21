

A well-designed exception handler is really a small piece of API design. You decide which exceptions exist, how they are grouped, what shape the error body takes, and which handler method signatures Spring will accept. We already covered why centralized handling exists, how `@RestControllerAdvice` works at a high level, `ProblemDetail`, and the common status-code mapping, so this tutorial focuses on the parts we skipped: the exact annotation attributes, what arguments and return types a handler method may declare, a design for the whole handler layer, and a few corrections to the document you pasted.

## Corrections to the pasted document

Before the new material, these points in the document are wrong or outdated and are worth fixing in your notes:

|In the document|Correction|
|---|---|
|The `@ControllerAdvice` source shown with `@Target`, `@Retention`, `@Component` and a list of attributes|Simplified. The real annotation also has `@Documented`, and the `value` / `basePackages` pair uses `@AliasFor`. More importantly, you never write this; it is framework source, not something to memorize.|
|`@ExceptionHandler` shown with only `value`|Accurate for the annotation itself, but it implies a handler can only be matched by that attribute. If `value` is empty, Spring infers the exception types from the method's **parameters**.|
|"RFC 7807" for `ProblemDetail`|Superseded by **RFC 9457**, which Spring 6.1+ documents. The format is the same.|
|`Collectors.toMap(..., (a, b) -> a)` for field errors|Fine, but it silently drops the second error on the same field. Use a `Map<String, List<String>>` if one field can fail several constraints.|
|Handlers for 405 and 415 written by hand|Redundant if you extend `ResponseEntityExceptionHandler`, which already covers them (and about a dozen other Spring MVC exceptions). Writing them by hand is only needed if you do not extend it.|
|The catch-all `Exception.class` handler alongside handlers for Spring's own exceptions|Works only because each Spring exception was handled explicitly. Any one you forget silently becomes a `500`.|
|`MethodArgumentTypeMismatchException` listed as a validation exception|It is a **type conversion** failure (binding), not a Bean Validation failure. Different cause, same `400`.|
|`HandlerMethodValidationException` is missing|Since Spring 6.1, method-level validation of controller parameters can throw this instead of `ConstraintViolationException`. Handle both.|
|The document mixes `UserMapper` for MyBatis and DTO mappers|Naming collision. A "mapper" means two different things there (MyBatis SQL mapper vs. object-to-DTO mapper). Rename one, for example `UserRepository` for persistence.|

## The annotations and their attributes

### Class-level: choosing where a handler applies

|Annotation|Purpose|Attributes|
|---|---|---|
|`@ControllerAdvice`|Global handler class for controllers that return views|`basePackages` (or `value`), `basePackageClasses`, `assignableTypes`, `annotations`|
|`@RestControllerAdvice`|Same, plus `@ResponseBody` on every method|Same four attributes|
|`@Order` / `Ordered`|Priority between several advice classes (lower number wins)|`value` (int)|

The four selection attributes decide **which controllers** the advice covers. They combine with OR, and if all are empty the advice is global:

|Attribute|Type|Example|Effect|
|---|---|---|---|
|`basePackages`|`String[]`|`"com.shop.orders"`|Controllers in that package and subpackages|
|`basePackageClasses`|`Class<?>[]`|`OrderController.class`|Type-safe alternative: uses that class's package|
|`assignableTypes`|`Class<?>[]`|`AdminController.class`|Only those controllers (or subtypes)|
|`annotations`|`Class<? extends Annotation>[]`|`RestController.class`|Only controllers carrying that annotation|

A practical use: one advice for your public API and a different one (different error shape) for an internal admin API, each scoped by package.

### Method-level: declaring what a handler catches

|Annotation|Purpose|Attributes|
|---|---|---|
|`@ExceptionHandler`|Marks a method as a handler|`value`: `Class<? extends Throwable>[]`. May be omitted if the parameter declares the type|
|`@ResponseStatus`|Fixes the HTTP status for the method|`value` / `code` (`HttpStatus`), `reason` (String, optional)|

Two usages of `@ExceptionHandler` are equivalent:

```java
@ExceptionHandler(UserNotFoundException.class)       // explicit
public ProblemDetail a(UserNotFoundException ex) { ... }

@ExceptionHandler                                    // inferred from the parameter
public ProblemDetail b(UserNotFoundException ex) { ... }
```

When one method handles several types, the parameter must be a common supertype, and you must list them explicitly:

```java
@ExceptionHandler({EmailAlreadyUsedException.class, UsernameTakenException.class})
public ProblemDetail conflict(RuntimeException ex) { ... }
```

A word of warning about `@ResponseStatus(reason = "...")`: setting `reason` makes Spring call `sendError()`, which routes through the `/error` endpoint and can override your response body. Prefer leaving `reason` unset and returning your own body.

## What a handler method may accept (arguments)

Spring resolves handler arguments by type, so you declare only what you need, in any order.

|Argument type|What you get|Typical use|
|---|---|---|
|The exception itself (`MyException ex`)|The thrown exception|Read message, fields, status|
|`HttpServletRequest` / `WebRequest` / `NativeWebRequest`|Current request|Path, method, headers for the error body|
|`HttpServletResponse`|Raw response|Rarely; set a header or write manually|
|`HttpMethod`|Request method|Include in log line|
|`Locale`|Resolved locale|Localized messages|
|`Principal`|Authenticated user (or `null`)|Log who triggered the error|
|`HttpSession`|Session|Rare|
|`Model` / `ModelAndView`|View model|Only with `@ControllerAdvice` for HTML pages|
|`HandlerMethod`|The controller method that threw|Useful in logging and metrics (Spring 5.3+ resolves it)|

Not allowed: `@RequestBody`, `@RequestParam`, `@PathVariable` and similar. An exception handler is not a normal request mapping, so those binding annotations are unsupported.

A detail that surprises people: if the handler's exception parameter is a **cause** rather than the top-level type, Spring can also match it. Spring checks the exception first, then walks its causes, so a handler for `SQLException` may fire when it is wrapped inside another exception. This is useful but can mask problems, so rely on explicit, specific types.

## What a handler method may return

|Return type|Behavior|
|---|---|
|`ProblemDetail`|Serialized as `application/problem+json`; status taken from the object|
|`ErrorResponse` (Spring interface)|Same as above; implemented by Spring's own exceptions|
|`ResponseEntity<T>`|Full control over status, headers, body|
|A DTO / record / `Map`|Serialized as the body; status defaults to `200` unless `@ResponseStatus` is present, which is a classic mistake|
|`String` / `ModelAndView`|View name (only meaningful with `@ControllerAdvice`)|
|`void`|Use only when you write to the `HttpServletResponse` yourself|

The most common error in this area: returning a plain DTO from a handler without `@ResponseStatus` and unknowingly sending the error with a `200 OK`.

```java
@ExceptionHandler(UserNotFoundException.class)
public ApiError wrong(UserNotFoundException ex) {              // 200 OK with an error body
    return new ApiError("USER_NOT_FOUND", ex.getMessage());
}

@ExceptionHandler(UserNotFoundException.class)
@ResponseStatus(HttpStatus.NOT_FOUND)                           // fixed
public ApiError right(UserNotFoundException ex) {
    return new ApiError("USER_NOT_FOUND", ex.getMessage());
}
```

## How to design the handler layer

Design it in four decisions, in this order.

### Decision 1: Build an exception hierarchy first

The handler layer is only as clean as the exceptions it receives. Instead of one handler per exception class, create a small hierarchy and handle the **base types**:

```text
ApplicationException (abstract, carries ErrorCode)
 |-- NotFoundException         -> 404
 |-- ConflictException         -> 409
 |-- BusinessRuleException     -> 422
 |-- ForbiddenOperationException -> 403
```

```java
public abstract class ApplicationException extends RuntimeException {
    private final ErrorCode code;

    protected ApplicationException(ErrorCode code, String message) {
        super(message);
        this.code = code;
    }
    public ErrorCode getCode() { return code; }
}

public class NotFoundException extends ApplicationException {
    public NotFoundException(ErrorCode code, String message) { super(code, message); }
}
```

```java
public enum ErrorCode {
    USER_NOT_FOUND, ORDER_NOT_FOUND, EMAIL_ALREADY_USED, INSUFFICIENT_FUNDS
}
```

Now adding "order not found" means adding one enum constant and throwing `new NotFoundException(ErrorCode.ORDER_NOT_FOUND, "...")`. **No new handler is required.**

### Decision 2: Map each base type to a status

|Exception base type|HTTP status|Log level|
|---|---|---|
|`NotFoundException`|404|`debug`|
|`ConflictException`|409|`info`|
|`BusinessRuleException`|422|`info`|
|`ForbiddenOperationException`|403|`warn`|
|Validation / binding failures|400|`debug`|
|Unhandled `Exception`|500|`error` with stack trace|

Logging by level is a design decision, not an afterthought: a flood of `404`s at `error` level hides real problems.

### Decision 3: Extend `ResponseEntityExceptionHandler` for framework exceptions

This base class gives you handlers for standard Spring MVC exceptions, and you customize them by overriding **one** method instead of writing a handler per exception:

```java
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex, HttpHeaders headers,
            HttpStatusCode status, WebRequest request) {

        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        Map<String, List<String>> errors = ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.groupingBy(FieldError::getField,
                         LinkedHashMap::new,
                         Collectors.mapping(FieldError::getDefaultMessage, Collectors.toList())));
        pd.setProperty("errors", errors);
        return handleExceptionInternal(ex, pd, headers, status, request);
    }
}
```

The most useful overridable hooks:

|Method to override|Triggered by|
|---|---|
|`handleMethodArgumentNotValid`|`@Valid` failure on `@RequestBody`|
|`handleHandlerMethodValidationException`|Method validation failure (Spring 6.1+)|
|`handleHttpMessageNotReadable`|Malformed or unreadable JSON|
|`handleTypeMismatch`|Wrong type in path or query value|
|`handleMissingServletRequestParameter`|Required `@RequestParam` missing|
|`handleNoResourceFoundException`|Unknown URL (Spring 6.1+)|
|`handleExceptionInternal`|Central point every handler passes through; override to add common fields (timestamp, trace ID) to **all** responses|

Overriding `handleExceptionInternal` is the cleanest way to enforce one error shape everywhere.

### Decision 4: Write only three kinds of handlers yourself

With the hierarchy and the base class in place, your own methods shrink to three:

```java
@ExceptionHandler(ApplicationException.class)
public ProblemDetail handleApplication(ApplicationException ex) {
    HttpStatus status = statusFor(ex);
    ProblemDetail pd = ProblemDetail.forStatusAndDetail(status, ex.getMessage());
    pd.setProperty("code", ex.getCode().name());
    return pd;
}

@ExceptionHandler(DataIntegrityViolationException.class)
public ProblemDetail handleIntegrity(DataIntegrityViolationException ex) {
    return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, "Request conflicts with existing data");
}

@ExceptionHandler(Exception.class)
public ProblemDetail handleUnexpected(Exception ex, HttpServletRequest req) {
    log.error("Unhandled exception on {} {}", req.getMethod(), req.getRequestURI(), ex);
    return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred");
}
```

with the status decided in one small method:

```java
private HttpStatus statusFor(ApplicationException ex) {
    return switch (ex) {
        case NotFoundException e -> HttpStatus.NOT_FOUND;
        case ConflictException e -> HttpStatus.CONFLICT;
        case BusinessRuleException e -> HttpStatus.UNPROCESSABLE_ENTITY;
        case ForbiddenOperationException e -> HttpStatus.FORBIDDEN;
        default -> HttpStatus.INTERNAL_SERVER_ERROR;
    };
}
```

(Pattern matching in `switch` requires Java 21. On older versions, use `if`/`instanceof` or store the status inside each exception class.)

An alternative that removes even the `switch`: give `ApplicationException` an abstract `HttpStatus getStatus()` method. This couples the exception to HTTP, so choose it only if you accept that tradeoff.

## Design rules for handler quality

|Rule|Reason|
|---|---|
|Handle base types, not every leaf exception|Adding exceptions needs no new handler|
|Never put raw `ex.getMessage()` of unexpected exceptions in a response|Leaks SQL, class names, paths|
|Put a stable `code` field in every body|Clients branch on codes, not on message text|
|Keep messages out of logic|Messages can change or be localized; codes cannot|
|Use `MessageSource` for user-facing text|Supports localization without touching handlers|
|Include a trace or correlation ID in the body|Lets a user report an error you can find in logs|
|Split advice classes only by audience or package|Not by exception type, which fragments the logic|
|Test each status with `@WebMvcTest`|Handlers are easy to break silently|

## Testing a handler

```java
@WebMvcTest(UserController.class)
class UserControllerErrorTest {

    @Autowired MockMvc mvc;
    @MockBean UserService userService;

    @Test
    void returns404WithCode() throws Exception {
        given(userService.get(99L)).willThrow(new NotFoundException(ErrorCode.USER_NOT_FOUND, "User 99 not found"));

        mvc.perform(get("/users/99"))
           .andExpect(status().isNotFound())
           .andExpect(jsonPath("$.code").value("USER_NOT_FOUND"));
    }
}
```

`@WebMvcTest` loads your `@RestControllerAdvice` automatically, so this tests the real handler. (In newer Spring Boot versions `@MockBean` is deprecated in favor of `@MockitoBean`.)

## Common mistakes in handler design

- Returning an error DTO without `@ResponseStatus` or `ResponseEntity`, sending errors with `200`.
- Writing a handler for every leaf exception instead of a hierarchy.
- Forgetting that handlers do not run for exceptions thrown in **filters** or by **Spring Security** before the controller is reached.
- Declaring two handlers for the same exception type in two advice classes without `@Order`, leading to unpredictable choice.
- Handling `Exception.class` but not `Throwable`, so an `Error` (for example `OutOfMemoryError`) bypasses it. This is usually correct, so do not "fix" it.
- Catching and wrapping exceptions in services only to rethrow a generic one, losing the cause. Always pass the original as the `cause`.
- Using `@ControllerAdvice` for a REST API and wondering why the body is a missing view.

## Related concepts to study next

- **`ErrorResponse` and `ErrorResponseException`** (Spring 6): throwing an exception that already knows its own status and `ProblemDetail`
- **`MessageSource` and i18n** for error messages
- **`AuthenticationEntryPoint` and `AccessDeniedHandler`** for security errors outside MVC
- **`HandlerExceptionResolver`** and the resolver chain order
- **`@ConfigurationProperties`-driven error settings** (`server.error.*`, `include-stacktrace`)
- **MDC and trace IDs** (Micrometer Tracing) in error bodies
- **Observability**: counting errors by code with Micrometer metrics




[[Spring Framework]]