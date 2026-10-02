

`@ControllerAdvice` is a **class-level annotation** that marks a class as a global interceptor for all controllers. Its methods can handle exceptions, bind data, and initialize models across every controller in scope — without the controllers knowing.

Its REST variant, `@RestControllerAdvice`, adds `@ResponseBody` so handler return values are serialized directly into the HTTP response.

---

## 1. Where it comes from

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Component
public @interface ControllerAdvice {

    @AliasFor("basePackages")
    String[] value() default {};

    @AliasFor("value")
    String[] basePackages() default {};

    Class<?>[] basePackageClasses() default {};

    Class<?>[] assignableTypes() default {};

    Class<?>[] annotations() default {};
}
```

Three things to notice:

1. It is meta-annotated with `@Component` → the class is picked up by component scanning and registered as a Spring bean.
2. It has **five attributes** that define its scope.
3. It is **not** an exception handler by itself. It is an **advice container**. Its methods carry the actual behavior.

---

## 2. What it can contain

`@ControllerAdvice` supports three kinds of methods:

| Method annotation | Purpose |
|---|---|
| `@ExceptionHandler` | Handle exceptions thrown by any matching controller |
| `@ModelAttribute` | Add attributes to the model for every request (view controllers) |
| `@InitBinder` | Register custom `PropertyEditor` / `Converter` for request parameter binding |

`@RestControllerAdvice` = `@ControllerAdvice` + `@ResponseBody`. It applies `@ResponseBody` to every handler method, so returned objects are serialized to JSON/XML instead of resolved as view names.

---

## 3. The five scope attributes

They filter **which controllers** the advice applies to. If you set none, the advice is **global**.

### `basePackages` / `value`

Applies only to controllers in the given packages.

```java
@ControllerAdvice(basePackages = "com.example.api.v1")
public class V1ExceptionHandler { ... }
```

`value` is an alias for `basePackages`. `@ControllerAdvice("com.example.api.v1")` is the same.

### `basePackageClasses`

A type-safe alternative. Spring uses the package of the given class(es).

```java
@ControllerAdvice(basePackageClasses = ApiMarker.class)
public class ApiExceptionHandler { ... }
```

Preferred over string packages because refactoring tools can follow it.

### `assignableTypes`

Applies only to controllers that are subclasses or implementors of the given types.

```java
@ControllerAdvice(assignableTypes = {BaseRestController.class, AdminController.class})
public class AdminExceptionHandler { ... }
```

### `annotations`

Applies only to controllers annotated with the given annotations.

```java
@ControllerAdvice(annotations = RestController.class)
public class RestApiExceptionHandler { ... }
```

This is a common way to restrict advice to REST controllers only.

### Combining attributes

You can combine them; the advice applies to a controller if **any** of the criteria match (OR semantics across attributes, AND across the same attribute's values is looser — Spring treats them as a union).

---

## 4. `@ControllerAdvice` vs `@RestControllerAdvice`

```java
@RestControllerAdvice  =  @ControllerAdvice  +  @ResponseBody
```

| Aspect | `@ControllerAdvice` | `@RestControllerAdvice` |
|---|---|---|
| `@ResponseBody` | Not applied | Applied to every handler |
| Return value | Treated as view name (unless `@ResponseBody` per method) | Serialized to body |
| Use for | Server-rendered views (Thymeleaf, JSP) | REST APIs returning JSON/XML |
| Typical in microservices | No | Yes |

For REST APIs, always use `@RestControllerAdvice`. Use `@ControllerAdvice` only when you render views and want to return a `ModelAndView` or view name.

---

## 5. Basic example — exception handling

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorDto> handle(UserNotFoundException ex, HttpServletRequest req) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ErrorDto.of(404, "Not Found", "USER_NOT_FOUND", ex.getMessage(), req.getRequestURI()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorDto> handleValidation(MethodArgumentNotValidException ex,
                                                     HttpServletRequest req) {
        Map<String, String> fields = ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(FieldError::getField,
                        fe -> fe.getDefaultMessage() == null ? "invalid" : fe.getDefaultMessage(),
                        (a, b) -> a));
        return ResponseEntity.badRequest().body(
                new ErrorDto(Instant.now(), 400, "Bad Request", "VALIDATION_FAILED",
                        "Validation failed", req.getRequestURI(), fields, null));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorDto> handleGeneric(Exception ex, HttpServletRequest req) {
        log.error("Unhandled error {} {}", req.getMethod(), req.getRequestURI(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ErrorDto.of(500, "Internal Server Error", "INTERNAL_ERROR", "Unexpected error",
                        req.getRequestURI()));
    }
}
```

Every controller in the application now returns consistent error responses without any code of its own.

---

## 6. Example — `@ModelAttribute` (global model attributes)

Adds data to the model for every request handled by matching controllers. Mainly for view controllers.

```java
@ControllerAdvice(annotations = Controller.class)
public class GlobalModelAdvice {

    @ModelAttribute("currentYear")
    public int currentYear() {
        return Year.now().getValue();
    }

    @ModelAttribute("appName")
    public String appName(@Value("${app.name}") String name) {
        return name;
    }
}
```

Every view rendered by a matching controller now has `currentYear` and `appName` in the model.

---

## 7. Example — `@InitBinder` (global request binding customization)

Registers custom editors or converters globally for request parameter binding.

```java
@ControllerAdvice
public class GlobalBindingAdvice {

    @InitBinder
    public void initBinder(WebDataBinder binder) {
        binder.registerCustomEditor(String.class, new StringTrimmerEditor(true));
        binder.registerCustomEditor(LocalDate.class,
                new PropertyEditorSupport() {
                    @Override public void setAsText(String text) {
                        setValue(LocalDate.parse(text, DateTimeFormatter.ISO_DATE));
                    }
                });
    }
}
```

Every controller now trims strings and parses `LocalDate` the same way.

---

## 8. Ordering multiple advices

`@ControllerAdvice` classes are consulted in the order defined by `@Order` / `Ordered`. Lower value = higher priority.

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
@Order(Ordered.LOWEST_PRECEDENCE)
public class FallbackExceptionHandler { ... }
```

Two rules of selection:

1. **Within one advice**, the most specific `@ExceptionHandler` wins (`UserNotFoundException` beats `RuntimeException`).
2. **Across advices**, order decides which advice is consulted first for a given exception type.

---

## 9. How Spring discovers and applies advices

At startup, Spring MVC scans the application context and builds a list of `ControllerAdviceBean` instances from every bean annotated with `@ControllerAdvice`. Each one records its scope predicates.

At request time:

```text
Request → DispatcherServlet
   ↓
Controller method runs and throws
   ↓
ExceptionHandlerExceptionResolver
   ↓
Build candidate handler methods:
   1. @ExceptionHandler methods in the controller itself
   2. @ExceptionHandler methods in all ControllerAdvice beans
      whose scope matches the current controller
   ↓
Filter by exception type assignability
   ↓
Pick the most specific match (then @Order for ties)
   ↓
Invoke the handler, serialize the return value
```

If no candidate matches, the next resolver in the chain runs (`ResponseStatusExceptionResolver`, then `DefaultHandlerExceptionResolver`), and finally the servlet container's `/error` path.

---

## 10. Realistic multi-advice architecture

```text
+-------------------------------------------------------------+
|  ValidationExceptionHandler  @Order(HIGHEST_PRECEDENCE)     |
|    MethodArgumentNotValidException  -> 400                  |
|    ConstraintViolationException     -> 400                  |
|    HttpMessageNotReadableException  -> 400                  |
+-------------------------------------------------------------+
|  DomainExceptionHandler      @Order(HIGHEST_PRECEDENCE + 10)|
|    NotFoundException                -> 404                  |
|    ConflictException                -> 409                  |
|    BusinessRuleException            -> 422                  |
+-------------------------------------------------------------+
|  SecurityExceptionHandler    @Order(HIGHEST_PRECEDENCE + 20)|
|    AccessDeniedException            -> 403                  |
|    AuthenticationException          -> 401                  |
+-------------------------------------------------------------+
|  PersistenceExceptionHandler @Order(HIGHEST_PRECEDENCE + 30)|
|    DataIntegrityViolationException  -> 409                  |
|    DataAccessResourceFailureException -> 503                |
+-------------------------------------------------------------+
|  FallbackExceptionHandler    @Order(LOWEST_PRECEDENCE)      |
|    Exception                        -> 500                  |
+-------------------------------------------------------------+
```

Each advice has one responsibility, its own tests, and its own error codes.

---

## 11. Scoped advice example

Suppose you have a public API and an internal admin API with different error formats.

```java
// Applies only to controllers under com.example.api.public
@RestControllerAdvice(basePackages = "com.example.api.public")
public class PublicApiExceptionHandler { ... }

// Applies only to controllers annotated with @AdminApi
@RestControllerAdvice(annotations = AdminApi.class)
public class AdminApiExceptionHandler { ... }
```

A request to a public controller consults only the public advice; a request to an admin controller consults only the admin advice.

---

## 12. Common mistakes

| Mistake | Why it is wrong | Fix |
|---|---|---|
| Using `@ControllerAdvice` for a REST API | Return value treated as a view name, body is empty | Use `@RestControllerAdvice` |
| One giant advice class | Hard to read, test, and order | Split by concern + `@Order` |
| No `Exception.class` fallback | Unhandled exceptions produce the default 500 page | Add a fallback at `LOWEST_PRECEDENCE` |
| Leaking `ex.getMessage()` in 500 responses | Exposes internals | Return a generic message, log the details |
| Returning a DTO without `@ResponseStatus` or `ResponseEntity` | Status defaults to 200 | Use `ResponseEntity` or `@ResponseStatus` |
| Forgetting `basePackages` when advices conflict | Both advices may match the same exception | Scope explicitly |
| Expecting advice to catch `@Async`/`@Scheduled` exceptions | They never reach the DispatcherServlet | Handle them separately |
| Expecting advice to catch Security filter exceptions | Filters run before the DispatcherServlet | Use `AuthenticationEntryPoint` / `AccessDeniedHandler` |

---

## 13. Testing advice

Use `@WebMvcTest` with `MockMvc` and mock the service.

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
}
```

`@WebMvcTest` automatically loads `@ControllerAdvice` beans, so the test exercises the real handler chain.

---

## 14. Best practices

1. Use `@RestControllerAdvice` for REST APIs, `@ControllerAdvice` for view controllers.
2. Split advices by concern and order them with `@Order`.
3. Scope advices with `basePackages` / `annotations` when multiple error policies exist.
4. Always include a catch-all `@ExceptionHandler(Exception.class)` at `LOWEST_PRECEDENCE`.
5. Return a single, consistent `ErrorDto` (or `ProblemDetail`) shape.
6. Never leak stack traces, SQL, or class names to the client.
7. Log unexpected exceptions with a full stack trace; log expected ones at INFO/WARN.
8. Include a correlation `traceId` in the error body.
9. Keep handlers thin: translate, do not compute business logic.
10. Test each advice with `@WebMvcTest` + `MockMvc`.
11. Prefer `@ExceptionHandler` in advice over `HandlerExceptionResolver` unless you need pre-controller handling.
12. Remember what advice does **not** catch: `@Async`, `@Scheduled`, filters, Security.

---

## 15. Summary

`@ControllerAdvice` is a Spring bean that intercepts requests and exceptions across controllers. It carries `@ExceptionHandler`, `@ModelAttribute`, and `@InitBinder` methods. Its five attributes — `basePackages`, `value`, `basePackageClasses`, `assignableTypes`, `annotations` — scope it to a subset of controllers; with no attributes it is global. For REST APIs, use its sibling `@RestControllerAdvice`, which adds `@ResponseBody`. In production, split advices by concern, order them with `@Order`, always provide a fallback, and return a single consistent error DTO.


[[Java]]
[[0 - Spring Framework]]