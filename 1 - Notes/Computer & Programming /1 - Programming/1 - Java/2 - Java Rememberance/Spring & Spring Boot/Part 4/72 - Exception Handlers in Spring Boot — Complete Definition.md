

An **exception handler** is a method that Spring MVC calls when a controller (or anything it invokes) throws an exception. Instead of letting the exception bubble up to the servlet container and produce a generic 500 page, Spring routes it to a method you wrote, which decides the HTTP status, headers, and body.

There are **four** places you can define one. Each has a different scope. Seniors know exactly which one to use and why.

---

## 1. The four levels of exception handling

```text
+-------------------------------------------------------------+
| Level 1: Try/Catch inside the method                        |
|   - local, ad hoc, last resort                              |
+-------------------------------------------------------------+
| Level 2: @ExceptionHandler inside the controller             |
|   - applies only to that controller                         |
+-------------------------------------------------------------+
| Level 3: @ExceptionHandler inside @RestControllerAdvice      |
|   - applies globally, per advice class, ordered by @Order   |
+-------------------------------------------------------------+
| Level 4: HandlerExceptionResolver (framework-level)          |
|   - custom resolution strategy, runs before/after advice    |
+-------------------------------------------------------------+
```

The rule of thumb:

- **Level 1** — only when you truly need a local decision.
- **Level 2** — for controller-specific errors (rare).
- **Level 3** — the standard production approach.
- **Level 4** — only when you need to override Spring's resolution pipeline.

---

## 2. Level 1 — Try/catch inside the method

```java
@GetMapping("/{id}")
public ResponseEntity<?> get(@PathVariable Long id) {
    try {
        return ResponseEntity.ok(userService.findById(id));
    } catch (UserNotFoundException e) {
        return ResponseEntity.status(404).body(new ErrorDto("USER_NOT_FOUND", e.getMessage()));
    }
}
```

What it is: plain Java. Not a Spring exception handler.

When to use: almost never. It bypasses centralized handling, duplicates code, and mixes HTTP concerns into the controller.

When it is acceptable: a single method needs a very specific fallback that no other endpoint shares, and you accept the duplication.

---

## 3. Level 2 — `@ExceptionHandler` inside a controller

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping("/{id}")
    public UserDto get(@PathVariable Long id) {
        return userService.findById(id);
    }

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorDto> handle(UserNotFoundException ex, HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ErrorDto.of(404, "Not Found", "USER_NOT_FOUND", ex.getMessage(), req.getRequestURI()));
    }
}
```

What it is: a method annotated with `@ExceptionHandler` inside a `@Controller` / `@RestController` class. It applies **only** to exceptions thrown by methods of that same controller.

How Spring finds it:

1. A controller method throws.
2. Spring looks for an `@ExceptionHandler` method **in the same controller** matching the exception type.
3. If found, it is invoked. If not, Spring continues to global advice.

Signature rules:

- Zero or one parameter of the exception type (or its supertypes).
- Can also accept `HttpServletRequest`, `HttpServletResponse`, `WebRequest`, `Locale`, `Principal`.
- Return type can be `ResponseEntity<T>`, a DTO, `void`, `ModelAndView`, or `ProblemDetail`.
- Can be annotated with `@ResponseStatus` to set the status.

```java
@ExceptionHandler(UserNotFoundException.class)
@ResponseStatus(HttpStatus.NOT_FOUND)
public ErrorDto handle(UserNotFoundException ex) {
    return ErrorDto.of(404, "Not Found", "USER_NOT_FOUND", ex.getMessage(), null);
}
```

Pros: simple, self-contained, no global config.

Cons: duplicated across controllers, no shared error shape, easy to forget in a new controller.

When to use: the exception only makes sense for that controller, or you are prototyping.

---

## 4. Level 3 — `@ExceptionHandler` inside `@RestControllerAdvice`

This is the production standard.

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorDto> handle(UserNotFoundException ex, HttpServletRequest req) {
        return build(HttpStatus.NOT_FOUND, "USER_NOT_FOUND", ex.getMessage(), req);
    }

    @ExceptionHandler(EmailAlreadyUsedException.class)
    public ResponseEntity<ErrorDto> handle(EmailAlreadyUsedException ex, HttpServletRequest req) {
        return build(HttpStatus.CONFLICT, "EMAIL_ALREADY_USED", ex.getMessage(), req);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorDto> handleGeneric(Exception ex, HttpServletRequest req) {
        log.error("Unhandled error {} {}", req.getMethod(), req.getRequestURI(), ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "Unexpected error", req);
    }

    private ResponseEntity<ErrorDto> build(HttpStatus status, String code, String message,
                                           HttpServletRequest req) {
        return ResponseEntity.status(status)
                .body(ErrorDto.of(status.value(), status.getReasonPhrase(), code, message, req.getRequestURI()));
    }
}
```

What it is: a class-level `@ControllerAdvice` (for views) or `@RestControllerAdvice` (for JSON APIs). Methods annotated with `@ExceptionHandler` apply to **all controllers** matched by the advice's scope.

`@RestControllerAdvice` = `@ControllerAdvice` + `@ResponseBody`. Every handler's return value is serialized to the response body.

### Scoping an advice

```java
@RestControllerAdvice(basePackages = "com.example.api")
@RestControllerAdvice(assignableTypes = {UserController.class, OrderController.class})
@RestControllerAdvice(annotations = RestController.class)
@RestControllerAdvice(basePackageClasses = ApiMarker.class)
```

If none are set, the advice is global.

### Ordering multiple advices

```java
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ValidationExceptionHandler { ... }

@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE + 10)
public class DomainExceptionHandler { ... }

@RestControllerAdvice
@Order(Ordered.LOWEST_PRECEDENCE)
public class FallbackExceptionHandler { ... }
```

Lower `@Order` value = higher priority = checked first.

### How Spring picks a handler

1. Collect all `@ExceptionHandler` methods from the controller and all advices in scope.
2. Keep those whose declared exception type is assignable from the thrown exception.
3. Choose the one with the **deepest / most specific** exception type.
4. If several advices match at the same depth, `@Order` decides.
5. If none match, the exception propagates to the container → 500.

Example specificity:

```text
Thrown: UserNotFoundException
Matches: RuntimeException, Exception, UserNotFoundException
Chosen: UserNotFoundException  (most specific)
```

### `@ControllerAdvice` vs `@RestControllerAdvice`

| | `@ControllerAdvice` | `@RestControllerAdvice` |
|---|---|---|
| Body serialization | Not automatic | Automatic (JSON/XML) |
| Return `ResponseEntity` | Required for body | Optional, but still common |
| Use for | Server-rendered views (Thymeleaf, JSP) | REST APIs |

For REST APIs, always use `@RestControllerAdvice`.

### Pros and cons

Pros: single source of truth, consistent error shape, easy to test, easy to extend.

Cons: easy to create a giant class; split by concern and use `@Order`.

When to use: always, in any real application.

---

## 5. Level 4 — `HandlerExceptionResolver`

Spring MVC resolves exceptions through a chain of `HandlerExceptionResolver` beans. The default chain, in order:

1. `ExceptionHandlerExceptionResolver` — runs `@ExceptionHandler` methods (controller-local + advice).
2. `ResponseStatusExceptionResolver` — handles `@ResponseStatus` and `ResponseStatusException`.
3. `DefaultHandlerExceptionResolver` — maps Spring's built-in exceptions (`HttpRequestMethodNotSupportedException`, `HttpMediaTypeNotSupportedException`, etc.) to standard statuses.

If none resolve it, the exception reaches the servlet container → `/error` → 500.

You can add your own resolver by implementing the interface and registering it as a bean:

```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class CustomExceptionResolver implements HandlerExceptionResolver {

    @Override
    public ModelAndView resolveException(HttpServletRequest req, HttpServletResponse res,
                                         Object handler, Exception ex) {
        if (ex instanceof DomainException de) {
            res.setStatus(de.getHttpStatus().value());
            res.setContentType(MediaType.APPLICATION_JSON_VALUE);
            try {
                res.getWriter().write("""
                    {"code":"%s","message":"%s"}
                    """.formatted(de.getCode(), de.getMessage()));
            } catch (IOException ignored) {}
            return new ModelAndView(); // signal handled
        }
        return null; // let the default chain continue
    }
}
```

Return `null` = "not handled, continue with the next resolver." Return an empty `ModelAndView` = "handled."

When to use:

- You need to handle exceptions that occur **before** the controller is reached (e.g. during `@RequestBody` deserialization at a point where advice cannot catch, or in a servlet filter).
- You need to short-circuit the default chain.
- You need to handle exceptions in a framework-level component.

Do not use it as a replacement for `@RestControllerAdvice`. Use it only when the advice cannot reach.

---

## 6. Beyond MVC — exceptions outside the controller

`@ExceptionHandler` only catches exceptions thrown **inside the DispatcherServlet pipeline**, i.e. inside a controller method or something it calls (service, repository, mapper, validator, message converter).

Exceptions raised **outside** that pipeline are not caught by advice:

| Source | Caught by advice? | Handle with |
|---|---|---|
| Controller, service, repository | Yes | `@RestControllerAdvice` |
| `@Async` method | No | `AsyncUncaughtExceptionHandler` |
| `@Scheduled` method | No | Wrap in try/catch or a custom `ErrorHandler` |
| Servlet `Filter` before the DispatcherServlet | No | Handle inside the filter |
| Spring Security filter chain | No | `AuthenticationEntryPoint` + `AccessDeniedHandler` |
| Jackson deserialization during argument resolution | Yes (usually) | `@ExceptionHandler(HttpMessageNotReadableException.class)` |
| Bean validation on `@RequestBody` | Yes | `@ExceptionHandler(MethodArgumentNotValidException.class)` |
| Bean validation on `@RequestParam` / `@PathVariable` | Yes | `@ExceptionHandler(ConstraintViolationException.class)` |
| Reactive / WebFlux | Yes, but differently | `@RestControllerAdvice` + `onErrorMap` |

---

## 7. Signature rules and options

A handler method can:

- Take the exception as its only argument.
- Take no arguments (only if you also declare the exception type in the annotation).
- Take additional contextual arguments: `HttpServletRequest`, `HttpServletResponse`, `WebRequest`, `Locale`, `Principal`, `HttpMethod`.

```java
@ExceptionHandler(UserNotFoundException.class)
public ResponseEntity<ErrorDto> handle(UserNotFoundException ex,
                                       HttpServletRequest req,
                                       Locale locale,
                                       Principal principal) { ... }
```

Return types:

| Return type | Behavior |
|---|---|
| `ResponseEntity<T>` | Full control over status, headers, body |
| `T` (DTO) + `@ResponseStatus` | Body = T, status from annotation |
| `T` (DTO) without `@ResponseStatus` | Body = T, status = 200 (usually wrong) |
| `ProblemDetail` | RFC 7807 output |
| `void` | Status and body must be set manually on `HttpServletResponse` |
| `ModelAndView` | For view-based controllers |

Multiple exception types in one handler:

```java
@ExceptionHandler({UserNotFoundException.class, OrderNotFoundException.class})
public ResponseEntity<ErrorDto> handleNotFound(RuntimeException ex, HttpServletRequest req) {
    return build(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage(), req);
}
```

---

## 8. How the whole chain works

```text
Client request
    ↓
DispatcherServlet
    ↓
HandlerMapping → controller method
    ↓
Controller / Service / Repository
    ↓  throws UserNotFoundException
DispatcherServlet catches it
    ↓
HandlerExceptionResolverComposite
    ↓
1. ExceptionHandlerExceptionResolver
       ↓
   a. @ExceptionHandler in the controller
   b. @ExceptionHandler in @RestControllerAdvice (ordered by @Order)
       ↓  if matched → ResponseEntity<ErrorDto> → serialized to JSON
    ↓  if not matched
2. ResponseStatusExceptionResolver
       ↓  @ResponseStatus / ResponseStatusException → status only
    ↓  if not matched
3. DefaultHandlerExceptionResolver
       ↓  framework exceptions → standard statuses
    ↓  if not matched
Servlet container
    ↓
/error  →  500 Internal Server Error
```

---

## 9. Comparison table

| Aspect | Controller-local `@ExceptionHandler` | `@RestControllerAdvice` | `HandlerExceptionResolver` |
|---|---|---|---|
| Scope | One controller | All controllers in scope | Whole MVC pipeline |
| Applies to | Exceptions from that controller | Exceptions from any controller | Exceptions anywhere in the DispatcherServlet chain |
| Ordering | N/A | `@Order` | `@Order` |
| Typical use | Rare, controller-specific | Production standard | Framework-level, pre-controller |
| Body serialization | Automatic with `@RestController` | Automatic | Manual |
| Testability | Easy | Easy | Harder |

---

## 10. Best practices

1. **Use `@RestControllerAdvice` for 99% of cases.** Controllers should have zero try/catch.
2. **Split advices by concern** (`Validation`, `Domain`, `Security`, `Persistence`, `Fallback`) and control order with `@Order`.
3. **One `ErrorDto` shape for the entire API.** Build it from the handlers.
4. **Always provide a catch-all** `@ExceptionHandler(Exception.class)` at `LOWEST_PRECEDENCE`.
5. **Never leak stack traces, SQL, or internal class names** in the response body.
6. **Log unexpected exceptions with full stack trace; log expected ones at INFO/WARN.**
7. **Return the correct HTTP status** and make it match the `status` field in the body.
8. **Handle validation explicitly** (`MethodArgumentNotValidException`, `ConstraintViolationException`).
9. **Include a `traceId`** in every error response for observability.
10. **Handle security exceptions in the filter chain**, not only in advice.
11. **Handle `@Async` and `@Scheduled` exceptions separately** — advice does not see them.
12. **Prefer `@RestControllerAdvice` over `HandlerExceptionResolver`** unless you need pre-controller resolution.
13. **Test every handler with MockMvc** asserting status, `code`, and body shape.
14. **Version your error contract** if you change `ErrorDto` — clients depend on it.

---

## 11. Minimal complete setup

```java
// 1. Error DTO
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorDto(Instant timestamp, int status, String error, String code,
                       String message, String path, Map<String, String> fieldErrors,
                       String traceId) {
    public static ErrorDto of(int status, String error, String code, String message, String path) {
        return new ErrorDto(Instant.now(), status, error, code, message, path, null, MDC.get("traceId"));
    }
}

// 2. Advice
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorDto> handle(UserNotFoundException ex, HttpServletRequest req) {
        return build(HttpStatus.NOT_FOUND, "USER_NOT_FOUND", ex.getMessage(), req);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorDto> handleValidation(MethodArgumentNotValidException ex,
                                                     HttpServletRequest req) {
        Map<String, String> fields = ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(FieldError::getField,
                        fe -> fe.getDefaultMessage() == null ? "invalid" : fe.getDefaultMessage(),
                        (a, b) -> a));
        ErrorDto body = new ErrorDto(Instant.now(), 400, "Bad Request", "VALIDATION_FAILED",
                "Validation failed", req.getRequestURI(), fields, MDC.get("traceId"));
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorDto> handleGeneric(Exception ex, HttpServletRequest req) {
        log.error("Unhandled error {} {}", req.getMethod(), req.getRequestURI(), ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "Unexpected error", req);
    }

    private ResponseEntity<ErrorDto> build(HttpStatus status, String code,
                                           String message, HttpServletRequest req) {
        return ResponseEntity.status(status)
                .body(ErrorDto.of(status.value(), status.getReasonPhrase(), code, message, req.getRequestURI()));
    }
}
```

## Summary:
**an exception handler is a method Spring calls when a controller throws. Define them locally with `@ExceptionHandler` in a controller only when scoped, globally in `@RestControllerAdvice` for production, and at the framework level via `HandlerExceptionResolver` when you need to intercept before or outside the advice chain. Always return a single, consistent `ErrorDto` shape.**


[[Java]]
[[0 - Spring Framework]]