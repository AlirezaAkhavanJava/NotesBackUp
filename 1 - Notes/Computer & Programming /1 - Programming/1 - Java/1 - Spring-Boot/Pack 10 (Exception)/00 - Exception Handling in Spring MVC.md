

**Definition:** Exception handling in Spring MVC is the mechanism that converts an exception thrown while processing a request into an HTTP response (status code plus body). Without it, an exception escapes the controller and the client gets a generic 500 error page or JSON.

**Mental model:** It is a `try/catch` around your entire web layer, written once, outside your controllers. Your service code throws meaningful exceptions (`ProductNotFoundException`), and one place decides how each maps to HTTP (404 plus a JSON body). The analogy breaks down in one way: it is not AOP or a filter wrapping the call. Spring's `DispatcherServlet` catches the exception _after_ it propagates, then asks a chain of resolvers to turn it into a response. That's why it only covers exceptions thrown inside the MVC pipeline (see edge cases for filters).

## How many types are there?

There is no fixed number, but in practice you choose from five mechanisms plus one Boot fallback:

|#|Mechanism|Scope|Controls the body?|
|---|---|---|---|
|1|`@ExceptionHandler` inside a controller|That controller only|Yes|
|2|`@RestControllerAdvice` / `@ControllerAdvice` with `@ExceptionHandler`|Global, or scoped by package/type/annotation|Yes|
|3|`@ResponseStatus` on an exception class|Every place that exception is thrown|No (status only)|
|4|`ResponseStatusException` thrown in code|That throw site|Limited|
|5|Custom `HandlerExceptionResolver`|Global, low-level|Yes (you write the response yourself)|
|Fallback|Boot's `/error` endpoint (`BasicErrorController`, `ErrorAttributes`)|Everything that escaped MVC|Via `ErrorAttributes`|

Under the hood, 1 and 2 are both implemented by `ExceptionHandlerExceptionResolver`, 3 and 4 by `ResponseStatusExceptionResolver`, and Spring's own exceptions (bad JSON, wrong HTTP method) by `DefaultHandlerExceptionResolver`. Those three are the default resolver chain, tried in that order. Whichever resolver first returns a result wins.

## Why it exists and what it solves

1. **Centralization.** Without it, every controller method has its own `try/catch` and its own error format.
2. **Layer separation.** Services should not know about HTTP. They throw domain exceptions, and the web layer translates them.
3. **A consistent error contract.** Clients get the same JSON shape for every error, instead of a mix of stack traces, HTML pages, and ad-hoc messages.
4. **No information leaks.** A catch-all handler lets you log the full exception server-side while returning a safe message.

## The domain exception

Start with an exception that carries meaning and no HTTP knowledge:

```java
public class ProductNotFoundException extends RuntimeException {

    private final Long id;

    public ProductNotFoundException(Long id) {
        super("Product %d not found".formatted(id));
        this.id = id;
    }

    public Long getId() {
        return id;
    }
}
```

- `extends RuntimeException`: Unchecked, so it passes through `@Transactional` methods and triggers rollback by default. Checked exceptions don't roll back unless configured, and they force `throws` clauses through every layer.
- The `id` field keeps structured data, so the handler can put it in the response without parsing the message string.
- `"...".formatted(id)`: Builds the message once, at the throw site.

The service uses it like this:

```java
Product product = productRepository.findById(id)
        .orElseThrow(() -> new ProductNotFoundException(id));
```

## Mechanism 2: the global handler (what you'll use 90% of the time)

```java
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ProductNotFoundException.class)
    ProblemDetail handleNotFound(ProductNotFoundException ex) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        pd.setTitle("Product not found");
        pd.setProperty("productId", ex.getId());
        return pd;
    }

    @ExceptionHandler(ConstraintViolationException.class)
    ProblemDetail handleConstraintViolation(ConstraintViolationException ex) {
        Map<String, String> errors = new LinkedHashMap<>();
        ex.getConstraintViolations().forEach(v ->
                errors.put(v.getPropertyPath().toString(), v.getMessage()));

        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        pd.setProperty("errors", errors);
        return pd;
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ProblemDetail handleIntegrity(DataIntegrityViolationException ex) {
        log.warn("Data integrity violation", ex);
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT,
                "The request conflicts with existing data");
    }

    @ExceptionHandler(Exception.class)
    ProblemDetail handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR,
                "An unexpected error occurred");
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex, HttpHeaders headers,
            HttpStatusCode status, WebRequest request) {

        Map<String, String> errors = new LinkedHashMap<>();
        for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
            errors.putIfAbsent(fe.getField(), fe.getDefaultMessage());
        }

        ProblemDetail body = ex.getBody();
        body.setProperty("errors", errors);
        return handleExceptionInternal(ex, body, headers, status, request);
    }
}
```

Line by line:

- `@RestControllerAdvice`: Combines `@ControllerAdvice` and `@ResponseBody`. The class is registered as a global handler container, and return values are serialized to JSON. `@ControllerAdvice` alone would try to resolve return values as view names.
- `extends ResponseEntityExceptionHandler`: A Spring base class with ready-made handlers for the standard MVC exceptions (malformed JSON, wrong method, missing parameter, unsupported media type, validation failure). It already converts them to `ProblemDetail`. Without extending it, those exceptions fall through to `DefaultHandlerExceptionResolver`, which sets the status but gives you no body of your own.
- `@ExceptionHandler(ProductNotFoundException.class)`: Declares which exception type this method handles. The parameter can be that exception, the request, the response, a `Principal`, and so on.
- `ProblemDetail`: Spring 6's representation of RFC 9457 ("Problem Details for HTTP APIs"), a standard JSON error format with `type`, `title`, `status`, `detail`, and `instance`. `forStatusAndDetail` sets the status and the human-readable detail. Returning it from a handler makes Spring set the response status from it and use content type `application/problem+json`.
- `setProperty("productId", ...)`: Adds a custom field. These are serialized at the top level of the JSON.
- `ConstraintViolationException` handler: This is the exception from `@Validated` services and parameter constraints (previous lessons). `getPropertyPath()` gives something like `create.request.email`, which is fine for logs but sometimes ugly for clients.
- `DataIntegrityViolationException` → 409: This is what a violated `UNIQUE` constraint produces, the "DB is the final authority" case from the `@Column` lesson. Log the details, but don't send the SQL error to the client, because it exposes table and constraint names.
- `@ExceptionHandler(Exception.class)`: The catch-all. It logs the full stack trace and returns a deliberately vague message. Without it, an unexpected error goes to Boot's fallback.
- `handleMethodArgumentNotValid` override: This is the exception thrown when `@Valid @RequestBody` fails (first lesson). `ex.getBody()` is a `ProblemDetail` Spring already prepared, and you enrich it with the field errors. `putIfAbsent` keeps one message per field when several constraints fail on the same field. `handleExceptionInternal` is the base class's shared exit point that builds the final `ResponseEntity`.

The result for a bad request body:

```json
{
  "type": "about:blank",
  "title": "Bad Request",
  "status": 400,
  "detail": "Invalid request content.",
  "instance": "/users",
  "errors": { "email": "must be a well-formed email address", "name": "must not be blank" }
}
```

## Mechanism 1: handler local to one controller

```java
@RestController
@RequestMapping("/products")
class ProductController {

    @GetMapping("/{id}")
    Product get(@PathVariable Long id) {
        return productService.get(id);
    }

    @ExceptionHandler(ProductNotFoundException.class)
    ResponseEntity<Map<String, String>> notFound(ProductNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", ex.getMessage()));
    }
}
```

- The handler sits in the same class and only applies to exceptions thrown by _this_ controller's methods.
- `ResponseEntity` is the explicit alternative to returning a `ProblemDetail`: you pick the status and body yourself.
- Use this when one controller has an error behavior no other controller shares. A local handler **beats** a global one for the same exception. Otherwise it only duplicates what the advice does.

## Mechanism 3: `@ResponseStatus` on the exception class

```java
@ResponseStatus(HttpStatus.NOT_FOUND)
public class ProductNotFoundException extends RuntimeException { ... }
```

- Every time this exception escapes a controller, the response status is 404, with no handler method needed.
- It cannot shape the body. The body comes from Boot's fallback `/error` response.
- It makes the exception class aware of HTTP, which breaks the layer separation. Fine for small projects and demos, and awkward when the same exception is also used by a scheduler or a message listener.

## Mechanism 4: `ResponseStatusException`

```java
Product product = repository.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product " + id + " not found"));
```

- No custom exception class and no handler: you throw it directly with a status and a reason.
- Fast for prototypes, but it scatters HTTP codes through your code, and it is hard to reuse and test.
- It implements `ErrorResponse`, so with `ResponseEntityExceptionHandler` or `spring.mvc.problemdetails.enabled=true` it renders as a `ProblemDetail` too.

## Mechanism 5: custom `HandlerExceptionResolver`

```java
@Component
class AuditingExceptionResolver implements HandlerExceptionResolver, Ordered {

    @Override
    public ModelAndView resolveException(HttpServletRequest request, HttpServletResponse response,
                                         Object handler, Exception ex) {
        if (ex instanceof LegacyClientException) {
            response.setStatus(HttpServletResponse.SC_GONE);
            return new ModelAndView();   // empty = "handled, no view to render"
        }
        return null;                     // null = "not mine, ask the next resolver"
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
```

- Returning an empty `ModelAndView` means "handled". Returning `null` passes to the next resolver in the chain.
- Order matters. A custom resolver only runs before the defaults if you give it a high precedence.
- This is the lowest-level option. You write to the response yourself, with no automatic serialization. You rarely need it. It's useful for infrastructure behavior that is not tied to a controller, or if you need to handle exceptions raised in a filter (see below).

## Boot's fallback: `/error`

If no resolver handles the exception, it propagates to the servlet container, which forwards to `/error`, handled by `BasicErrorController`. It builds the body from an `ErrorAttributes` bean:

```json
{ "timestamp": "...", "status": 500, "error": "Internal Server Error", "path": "/products/1" }
```

Since Boot 2.3, `message`, `stackTrace`, and `errors` are hidden by default. The properties `server.error.include-message`, `include-stacktrace`, and `include-binding-errors` control them. Don't enable `include-stacktrace` in production. To customize the fallback, declare your own `ErrorAttributes` bean (or extend `DefaultErrorAttributes`). To replace it entirely, implement `ErrorController`.

## How Spring picks a handler

1. The exception propagates to `DispatcherServlet`, which asks each resolver in order.
2. Inside `ExceptionHandlerExceptionResolver`: first the **controller's own** `@ExceptionHandler` methods, then `@ControllerAdvice` beans (ordered by `@Order`, with unordered advice last).
3. Within one class, the **closest** exception type wins: `ProductNotFoundException` beats `RuntimeException` beats `Exception`.
4. If no handler matches the exception itself, Spring tries the exception's `getCause()` chain. That is how an exception wrapped by a framework can still reach a handler for the inner type.

Advice can also be scoped, to give different parts of the app different error formats:

```java
@RestControllerAdvice(basePackages = "com.example.api.admin")
class AdminExceptionHandler { ... }
```

`assignableTypes` and `annotations` work similarly.

## Standard exceptions and their default status

These come from `DefaultHandlerExceptionResolver` (or the `ResponseEntityExceptionHandler` base class):

|Exception|Status|Trigger|
|---|---|---|
|`HttpMessageNotReadableException`|400|Malformed JSON body|
|`MethodArgumentNotValidException`|400|`@Valid @RequestBody` failed|
|`HandlerMethodValidationException`|400|Parameter constraints (Spring 6.1+)|
|`MissingServletRequestParameterException`|400|Required `@RequestParam` absent|
|`MethodArgumentTypeMismatchException`|400|`/products/abc` for a `Long`|
|`HttpRequestMethodNotSupportedException`|405|Wrong HTTP verb|
|`HttpMediaTypeNotSupportedException`|415|Wrong `Content-Type`|
|`NoResourceFoundException`|404|Unknown URL (Spring 6.1+)|

## Edge cases

- **Ambiguous handlers.** If your advice extends `ResponseEntityExceptionHandler` and you also add an `@ExceptionHandler` for an exception the base class already handles (like `MethodArgumentNotValidException`), startup or the first request fails with "Ambiguous @ExceptionHandler method mapped". Override the base `handleXxx` method instead.
- **The catch-all can swallow security exceptions.** With `@ExceptionHandler(Exception.class)`, an `AccessDeniedException` thrown by `@PreAuthorize` is caught and returned as 500 instead of 403. Add explicit handlers for `AccessDeniedException` and `AuthenticationException`.
- **Filters are outside the pipeline.** An exception thrown in a servlet filter (including Spring Security's filters) never reaches `@ControllerAdvice`. Spring Security has its own hooks, `AuthenticationEntryPoint` (401) and `AccessDeniedHandler` (403). For custom filters, you can inject the `HandlerExceptionResolver` bean (`@Qualifier("handlerExceptionResolver")`) and call `resolveException(...)` to route the exception through your advice.
- **Don't catch and swallow in services.** A service that catches an exception, logs it, and returns `null` makes the handler never run, and breaks `@Transactional` rollback, because the transaction sees a normal return.
- **`spring.mvc.problemdetails.enabled=true`** gives `ProblemDetail` output for standard Spring exceptions _without_ writing an advice. It's only needed if you don't extend `ResponseEntityExceptionHandler`. The two don't conflict: Boot backs off when it finds your base-class bean.
- **Don't map exceptions to a status in two places.** Choose either `@ResponseStatus` on the class or a handler method, not both, or you won't know which is in effect.

## Alternatives

- `ResponseStatusException` everywhere: least code, worst separation.
- A custom `ApiException(status, code)` base class with a single `@ExceptionHandler(ApiException.class)`: one handler for all domain errors, and each exception carries its own HTTP status and error code. This is a common pattern for larger projects.
- Returning error objects as normal values (`Result<T>`): avoids exceptions for expected failures, but Spring has no built-in support for it, so you handle it manually in every controller.

**Rule of thumb:** services throw domain exceptions, one `@RestControllerAdvice` extending `ResponseEntityExceptionHandler` translates them to `ProblemDetail`, a catch-all logs and hides internals, and everything else is a special case.





[[Spring Framework]]
[[Exception]]