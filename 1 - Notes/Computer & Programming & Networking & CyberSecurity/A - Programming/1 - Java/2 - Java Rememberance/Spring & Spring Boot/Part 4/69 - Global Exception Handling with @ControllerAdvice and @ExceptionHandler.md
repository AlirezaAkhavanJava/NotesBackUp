

This completes the picture. Instead of building error `ResponseEntity` objects inside every controller method, you centralize error handling in one place. Your controllers stay clean, and every error response has a consistent shape.

---

## 1. The problem it solves

Without global handling, every controller must catch its own exceptions:

```java
@GetMapping("/{id}")
public ResponseEntity<?> getById(@PathVariable Long id) {
    try {
        UserDto dto = userService.findById(id);
        return ResponseEntity.ok(dto);
    } catch (UserNotFoundException e) {
        return ResponseEntity.status(404).body(new ErrorResponse("USER_NOT_FOUND", e.getMessage()));
    } catch (Exception e) {
        return ResponseEntity.status(500).body(new ErrorResponse("INTERNAL", "Unexpected error"));
    }
}
```

Problems:

- Repeats the same try/catch in every method.
- Error response shape drifts over time.
- Business exceptions leak into controller code.
- Validation errors (from `@Valid`) are not handled consistently.

`@ControllerAdvice` + `@ExceptionHandler` solve this by moving all of it to one class.

---

## 2. The two annotations

### `@ControllerAdvice`

A class-level annotation that marks a class as a **global interceptor for exceptions and other cross-cutting concerns** across all controllers.

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Component
public @interface ControllerAdvice {
    @AliasFor("basePackages") String[] value() default {};
    String[] basePackages() default {};
    Class<?>[] basePackageClasses() default {};
    Class<?>[] assignableTypes() default {};
    Class<?>[] annotations() default {};
}
```

Parameters:

| Parameter | Meaning |
|---|---|
| `basePackages` / `value` | Apply advice only to controllers in these packages |
| `basePackageClasses` | Apply advice to controllers in the same package as these classes |
| `assignableTypes` | Apply advice only to these controller classes |
| `annotations` | Apply advice only to controllers annotated with these annotations |

If you leave them empty, the advice applies **globally** to every `@Controller` / `@RestController`.

### `@RestControllerAdvice`

Convenience annotation that combines `@ControllerAdvice` + `@ResponseBody`:

```java
@RestControllerAdvice
public class GlobalExceptionHandler { ... }
```

Use this for REST APIs. Every method return value is serialized to the response body (JSON), exactly like `@RestController`.

Use plain `@ControllerAdvice` only for server-rendered views.

### `@ExceptionHandler`

A method-level annotation that says: "When this exception is thrown from any controller, run this method."

```java
@Target(ElementType.METHOD)
public @interface ExceptionHandler {
    Class<? extends Throwable>[] value() default {};
}
```

Parameters:

| Parameter | Meaning |
|---|---|
| `value` | One or more exception classes this method handles |

Rules:

- One `@ExceptionHandler` method can handle multiple exception types.
- More specific exceptions win over more general ones (`UserNotFoundException` beats `RuntimeException`).
- The method can take the exception as a parameter.
- The method can return `ResponseEntity<T>`, a plain DTO, or nothing.
- You can also annotate the method with `@ResponseStatus` to set a fixed status.

---

## 3. Recommended architecture

```text
Controller
   |  throws UserNotFoundException
   v
Spring MVC ExceptionResolver
   |
   |  looks for @ExceptionHandler in @RestControllerAdvice
   v
GlobalExceptionHandler
   |
   |  builds ErrorResponse DTO
   v
ResponseEntity<ErrorResponse>  ->  JSON to client
```

The controller never catches anything. The service throws domain exceptions. The advice translates them to HTTP.

---

## 4. Error response DTO

Define one consistent shape for all errors:

```java
public record ErrorResponse(
        Instant timestamp,
        int status,
        String error,
        String code,
        String message,
        String path,
        Map<String, String> fieldErrors
) {}
```

- `timestamp` — when it happened.
- `status` — HTTP status code.
- `error` — HTTP reason phrase ("Not Found", "Bad Request").
- `code` — your application error code (`USER_NOT_FOUND`).
- `message` — human-readable message.
- `path` — request URI.
- `fieldErrors` — validation errors per field (nullable).

---

## 5. Domain exceptions

Define your own exceptions, usually extending `RuntimeException`:

```java
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(Long id) {
        super("User with id " + id + " was not found");
    }
}

public class EmailAlreadyUsedException extends RuntimeException {
    public EmailAlreadyUsedException(String email) {
        super("Email " + email + " is already in use");
    }
}

public class BusinessRuleException extends RuntimeException {
    public BusinessRuleException(String message) {
        super(message);
    }
}
```

Services throw them:

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final UserDtoMapper dtoMapper;

    @Transactional(readOnly = true)
    public UserDto findById(Long id) {
        return userMapper.findById(id)
            .map(dtoMapper::toDto)
            .orElseThrow(() -> new UserNotFoundException(id));
    }
}
```

Controllers become clean:

```java
@GetMapping("/{id}")
public ResponseEntity<UserDto> getById(@PathVariable Long id) {
    return ResponseEntity.ok(userService.findById(id));
}
```

---

## 6. The global handler

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    // ----- 404 -----
    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(UserNotFoundException ex, HttpServletRequest req) {
        return build(HttpStatus.NOT_FOUND, "USER_NOT_FOUND", ex.getMessage(), req, null);
    }

    // ----- 409 -----
    @ExceptionHandler(EmailAlreadyUsedException.class)
    public ResponseEntity<ErrorResponse> handleConflict(EmailAlreadyUsedException ex, HttpServletRequest req) {
        return build(HttpStatus.CONFLICT, "EMAIL_ALREADY_USED", ex.getMessage(), req, null);
    }

    // ----- 422 -----
    @ExceptionHandler(BusinessRuleException.class)
    public ResponseEntity<ErrorResponse> handleBusiness(BusinessRuleException ex, HttpServletRequest req) {
        return build(HttpStatus.UNPROCESSABLE_ENTITY, "BUSINESS_RULE_VIOLATION", ex.getMessage(), req, null);
    }

    // ----- 400 validation errors from @Valid on @RequestBody -----
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex,
                                                          HttpServletRequest req) {
        Map<String, String> fieldErrors = ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(
                FieldError::getField,
                fe -> fe.getDefaultMessage() == null ? "invalid" : fe.getDefaultMessage(),
                (a, b) -> a
            ));
        return build(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", "Validation failed", req, fieldErrors);
    }

    // ----- 400 constraint violations from @Validated on @RequestParam/@PathVariable -----
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraint(ConstraintViolationException ex,
                                                          HttpServletRequest req) {
        Map<String, String> fieldErrors = ex.getConstraintViolations().stream()
            .collect(Collectors.toMap(
                v -> v.getPropertyPath().toString(),
                ConstraintViolation::getMessage,
                (a, b) -> a
            ));
        return build(HttpStatus.BAD_REQUEST, "CONSTRAINT_VIOLATION", "Validation failed", req, fieldErrors);
    }

    // ----- 400 malformed JSON / type mismatch -----
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleUnreadable(HttpMessageNotReadableException ex,
                                                          HttpServletRequest req) {
        return build(HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST", "Malformed JSON request", req, null);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException ex,
                                                            HttpServletRequest req) {
        String msg = "Parameter '" + ex.getName() + "' has invalid value";
        return build(HttpStatus.BAD_REQUEST, "TYPE_MISMATCH", msg, req, null);
    }

    // ----- 405 method not allowed -----
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMethod(HttpRequestMethodNotSupportedException ex,
                                                      HttpServletRequest req) {
        return build(HttpStatus.METHOD_NOT_ALLOWED, "METHOD_NOT_ALLOWED", ex.getMessage(), req, null);
    }

    // ----- 415 unsupported media type -----
    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMedia(HttpMediaTypeNotSupportedException ex,
                                                     HttpServletRequest req) {
        return build(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "UNSUPPORTED_MEDIA_TYPE", ex.getMessage(), req, null);
    }

    // ----- 500 fallback for anything else -----
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception on {} {}", req.getMethod(), req.getRequestURI(), ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                     "An unexpected error occurred", req, null);
    }

    // ----- helper -----
    private ResponseEntity<ErrorResponse> build(HttpStatus status, String code, String message,
                                                HttpServletRequest req, Map<String, String> fieldErrors) {
        ErrorResponse body = new ErrorResponse(
            Instant.now(),
            status.value(),
            status.getReasonPhrase(),
            code,
            message,
            req.getRequestURI(),
            fieldErrors
        );
        return ResponseEntity.status(status).body(body);
    }
}
```

Key points:

- One method per exception type, grouped by HTTP status.
- The `Exception.class` fallback catches everything else and returns 500 without leaking stack traces to the client.
- Log the stack trace only for unexpected errors.
- Validation errors are reshaped into a `fieldErrors` map.
- The helper avoids duplicating the `ResponseEntity` construction.

---

## 7. Validation exceptions — which one fires when

| Annotation / source | Exception thrown | Handled by |
|---|---|---|
| `@Valid` on `@RequestBody` | `MethodArgumentNotValidException` | `handleValidation` |
| `@Validated` on class + `@NotBlank` on `@RequestParam` / `@PathVariable` | `ConstraintViolationException` | `handleConstraint` |
| Malformed JSON body | `HttpMessageNotReadableException` | `handleUnreadable` |
| Wrong type in query/path (e.g. `"abc"` for `Long`) | `MethodArgumentTypeMismatchException` | `handleTypeMismatch` |
| Wrong HTTP method | `HttpRequestMethodNotSupportedException` | `handleMethod` |
| Wrong `Content-Type` | `HttpMediaTypeNotSupportedException` | `handleMedia` |

Example of class-level validation:

```java
@RestController
@RequestMapping("/api/users")
@Validated
@RequiredArgsConstructor
public class UserController {

    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getById(@PathVariable @Min(1) Long id) {
        return ResponseEntity.ok(userService.findById(id));
    }

    @GetMapping
    public ResponseEntity<List<UserDto>> search(
            @RequestParam @NotBlank @Size(min = 2, max = 50) String q) {
        return ResponseEntity.ok(userService.search(q));
    }
}
```

---

## 8. Optional: `ProblemDetail` (RFC 7807)

Spring 6 / Boot 3 supports the standard `ProblemDetail` error format out of the box. You can use it instead of a custom `ErrorResponse`:

```java
@ExceptionHandler(UserNotFoundException.class)
public ProblemDetail handleNotFound(UserNotFoundException ex) {
    ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    pd.setTitle("User not found");
    pd.setType(URI.create("https://example.com/errors/user-not-found"));
    pd.setProperty("code", "USER_NOT_FOUND");
    return pd;
}
```

Or enable it globally:

```yaml
spring:
  mvc:
    problemdetails:
      enabled: true
```

Choose one style and stay consistent. A custom `ErrorResponse` gives you full control; `ProblemDetail` gives you a standard shape and client tooling support.

---

## 9. Full request lifecycle with exception handling

```text
Client
  |  GET /api/users/999
  v
+---------------------------------------------------------------+
| Spring Boot Server                                            |
|                                                               |
|  DispatcherServlet                                            |
|      |                                                        |
|      v                                                        |
|  UserController.getById(999)                                  |
|      |                                                        |
|      v                                                        |
|  UserService.findById(999)                                    |
|      |                                                        |
|      | MyBatis Mapper.findById(999) -> empty                 |
|      | throws UserNotFoundException                           |
|      v                                                        |
|  Exception propagates up                                      |
|      |                                                        |
|      v                                                        |
|  DispatcherServlet -> ExceptionHandlerExceptionResolver       |
|      |                                                        |
|      | finds GlobalExceptionHandler.handleNotFound            |
|      v                                                        |
|  ResponseEntity<ErrorResponse>  (404)                         |
|      |                                                        |
|      | Jackson serializes ErrorResponse to JSON               |
|      v                                                        |
+---------------------------------------------------------------+
  |
  |  HTTP 404 Not Found
  |  {
  |    "timestamp": "2026-09-24T10:00:00Z",
  |    "status": 404,
  |    "error": "Not Found",
  |    "code": "USER_NOT_FOUND",
  |    "message": "User with id 999 was not found",
  |    "path": "/api/users/999",
  |    "fieldErrors": null
  |  }
  v
Client
```

Notice the controller has **zero** error handling code. Everything is centralized.

---

## 10. Best practices

- Use `@RestControllerAdvice` (not `@ControllerAdvice`) for REST APIs.
- One advice class per concern if it grows: `ValidationExceptionHandler`, `PersistenceExceptionHandler`, `SecurityExceptionHandler`. Order with `@Order`.
- Never leak stack traces or SQL messages to the client.
- Log unexpected exceptions with the full stack trace; log expected ones at `warn` or `info`.
- Use domain-specific exceptions in the service layer, not generic `RuntimeException`.
- Keep one error response shape across the whole API.
- Handle validation errors explicitly; do not let `MethodArgumentNotValidException` fall through to the 500 handler.
- Do not catch `Exception` inside controllers; let the advice do it.
- Keep controllers thin: no try/catch, no error DTO construction.
- Test the handler with `MockMvc` and `@WebMvcTest` to verify status and body.

---

## 11. Cheat sheet

| Goal | Annotation |
|---|---|
| Global exception handling for REST | `@RestControllerAdvice` |
| Global exception handling for views | `@ControllerAdvice` |
| Handle a specific exception | `@ExceptionHandler(MyException.class)` |
| Fix a status on a handler | `@ResponseStatus(HttpStatus.X)` |
| Restrict advice to some controllers | `@RestControllerAdvice(basePackages = ...)` |
| Order multiple advices | `@Order(1)` |
| Handle `@Valid` body errors | `MethodArgumentNotValidException` |
| Handle `@Validated` param errors | `ConstraintViolationException` |
| Handle malformed JSON | `HttpMessageNotReadableException` |
| Handle wrong type in path/query | `MethodArgumentTypeMismatchException` |
| Handle wrong HTTP method | `HttpRequestMethodNotSupportedException` |
| Handle wrong content type | `HttpMediaTypeNotSupportedException` |
| Catch-all fallback | `@ExceptionHandler(Exception.class)` |

You now have the full stack: `@RestController` + `@RequestMapping` for routing, `ResponseEntity` for response control, DTO mapper (`toDto`/`fromDto`) for model translation, MyBatis mapper for persistence, and `@RestControllerAdvice` + `@ExceptionHandler` for consistent error handling. If you want, I can put all of it into a single runnable Spring Boot project skeleton with folders and a sample `pom.xml`.


[[Java]]
[[0 - Spring Framework]]
[[32 - Exception]]