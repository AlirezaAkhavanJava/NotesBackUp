# Building Your First Exception Handler, One Step at a Time

**Definition:** An exception handler is a method that Spring calls when an exception escapes your controller. The method receives the exception and returns what the client should see: an HTTP status and a body.

**Mental model:** Your service says _what went wrong_ by throwing an exception. The handler decides _how that looks over HTTP_. Throwing and translating are separate jobs in separate places.

The analogy to a `try/catch` breaks down in one way: you never write the `try`. Spring's `DispatcherServlet` catches the exception after it leaves your controller and looks for a method annotated to handle that type.

## Why you need one

Start with what happens without it. Say a service does this:

```java
Product product = productRepository.findById(id)
        .orElseThrow(() -> new RuntimeException("Product " + id + " not found"));
```

The exception escapes the controller, nobody handles it, and the client gets a **500 Internal Server Error**. That is wrong twice: 500 means "the server is broken", but here the client asked for something that doesn't exist (that is a 404), and the client has no useful way to tell the difference. A handler fixes this.

## Step 1: Create an exception that means something

```java
public class ProductNotFoundException extends RuntimeException {

    public ProductNotFoundException(Long id) {
        super("Product with id " + id + " not found");
    }
}
```

- `extends RuntimeException`: An unchecked exception, so you don't need `throws` in every method signature. It also makes `@Transactional` roll back by default.
- The constructor takes the `id` and builds the message once, so every throw site produces the same text.
- The class has no HTTP knowledge (no status code, no `ResponseEntity`). The service layer shouldn't know it is being called over HTTP. The same exception could be thrown from a scheduled job.

Throw it from the service:

```java
@Service
class ProductService {

    private final ProductRepository productRepository;

    ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    Product get(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException(id));
    }
}
```

- `findById` returns an `Optional<Product>`.
- `orElseThrow(supplier)` returns the value if present. If empty, it calls the supplier and throws what it returns. The lambda is only evaluated in the empty case.

## Step 2: Decide what the error body looks like

Clients need a predictable shape. Start with a simple record:

```java
public record ErrorResponse(int status, String message, Instant timestamp) {}
```

- A record is an immutable data holder. Jackson serializes it to JSON using the component names.
- `Instant` becomes an ISO-8601 string. Spring Boot configures Jackson for this by default.

## Step 3: Write the handler class

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ProductNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleProductNotFound(ProductNotFoundException ex) {
        ErrorResponse body = new ErrorResponse(404, ex.getMessage(), Instant.now());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);
    }
}
```

Line by line:

- `@RestControllerAdvice`: Two things in one. It makes the class a **global** container for handler methods, applying to all controllers, and it means return values are written to the response body as JSON. Spring finds the class through component scanning, so it must be in a package under your `@SpringBootApplication` class. No other registration is needed.
- `@ExceptionHandler(ProductNotFoundException.class)`: Says "call this method when this exception type is thrown." Spring matches the exception type against all registered handlers.
- `handleProductNotFound(ProductNotFoundException ex)`: Spring passes the thrown exception in as an argument. The method name is irrelevant; only the annotation matters.
- `ResponseEntity<ErrorResponse>`: Gives you full control of the status, headers, and body.
- `ResponseEntity.status(HttpStatus.NOT_FOUND).body(body)`: Builds a 404 response with `body` as JSON.

Now `GET /products/99` for a missing product returns:

```
HTTP/1.1 404
Content-Type: application/json

{"status":404,"message":"Product with id 99 not found","timestamp":"2026-10-11T14:03:22.114Z"}
```

The controller needs no changes at all:

```java
@RestController
@RequestMapping("/products")
class ProductController {

    private final ProductService productService;

    ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping("/{id}")
    Product get(@PathVariable Long id) {
        return productService.get(id);
    }
}
```

The exception propagates: repository → service → controller → `DispatcherServlet` → your handler. The controller doesn't catch anything.

## Step 4: A simpler variant, using `@ResponseStatus`

If you only need the status code and don't care about the body, you can skip `ResponseEntity`:

```java
@ExceptionHandler(ProductNotFoundException.class)
@ResponseStatus(HttpStatus.NOT_FOUND)
public ErrorResponse handleProductNotFound(ProductNotFoundException ex) {
    return new ErrorResponse(404, ex.getMessage(), Instant.now());
}
```

- Here the method returns the body directly, and `@ResponseStatus` sets the status.
- The trade-off is that the status is fixed at compile time. With `ResponseEntity`, you could compute it at runtime. For one-exception, one-status handlers, this form is shorter and clearer.
- Without `@ResponseStatus`, a handler that returns a plain object responds with **200 OK**. That is a very common beginner bug: the error message arrives with a success status.

## Step 5: Handle more than one exception

Add handlers as separate methods in the same class:

```java
@ExceptionHandler(EmailAlreadyUsedException.class)
@ResponseStatus(HttpStatus.CONFLICT)
public ErrorResponse handleEmailTaken(EmailAlreadyUsedException ex) {
    return new ErrorResponse(409, ex.getMessage(), Instant.now());
}

@ExceptionHandler(MethodArgumentNotValidException.class)
@ResponseStatus(HttpStatus.BAD_REQUEST)
public Map<String, String> handleValidation(MethodArgumentNotValidException ex) {
    Map<String, String> errors = new LinkedHashMap<>();
    for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
        errors.putIfAbsent(fe.getField(), fe.getDefaultMessage());
    }
    return errors;
}
```

- `EmailAlreadyUsedException` → 409 Conflict is the standard status for "this conflicts with existing state".
- `MethodArgumentNotValidException` is what `@Valid @RequestBody` throws when a constraint from your DTO fails (the first lesson). `getBindingResult().getFieldErrors()` gives one entry per failed constraint.
- `putIfAbsent` keeps only the first message per field, because one field can fail several constraints at once.
- This handler returns a `Map` instead of `ErrorResponse`. It works, but a mixed error format is exactly what you wanted to avoid. A better design is a single `ErrorResponse` with an optional `errors` field. See "What to learn next" below.

## Step 6: The catch-all

```java
private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

@ExceptionHandler(Exception.class)
@ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
public ErrorResponse handleUnexpected(Exception ex) {
    log.error("Unhandled exception", ex);
    return new ErrorResponse(500, "An unexpected error occurred", Instant.now());
}
```

- `Exception.class` matches everything not matched by a more specific handler. Spring picks the **closest** type, so your `ProductNotFoundException` handler still wins for that exception.
- `log.error("...", ex)`: Passing the exception as the last argument logs the full stack trace. This is where you find out what really happened.
- The response message is deliberately generic. Returning `ex.getMessage()` here can leak internals: SQL fragments, class names, file paths. Log the detail, and send the client a safe message.

## How Spring chooses (the mechanics)

1. An exception leaves the controller method.
2. `DispatcherServlet` asks its chain of resolvers. The one that matters here is `ExceptionHandlerExceptionResolver`.
3. It looks for an `@ExceptionHandler` method **in the controller itself** first, then in `@ControllerAdvice` classes.
4. Among the candidates it picks the one whose declared exception type is **closest** in the class hierarchy to the thrown exception.
5. It invokes the method, then writes the return value like any controller return value (JSON via `HttpMessageConverter`, status from `ResponseEntity` or `@ResponseStatus`).

If no handler matches, the exception reaches Spring Boot's `/error` fallback, which produces the generic 500 you saw at the start.

## Edge cases to know now

- **Handler method signatures are flexible.** Besides the exception, a handler can accept `HttpServletRequest`, `WebRequest`, `Principal`, and others. For example, `handleX(MyException ex, HttpServletRequest request)` lets you put `request.getRequestURI()` in the body.
- **Your handler can throw too.** If an exception is thrown inside the handler itself, Spring won't try to handle that with the same advice, so keep handlers simple, with no database calls.
- **The status must come from you.** Returning an object from a handler never changes the status by itself. It's 200 unless you set it.
- **Wrong annotation.** If you use `@ControllerAdvice` (no `Rest`) and forget `@ResponseBody` on the methods, Spring tries to interpret the returned `ErrorResponse` as a view name and you get a template-resolution error instead of JSON.
- **Local handlers win.** An `@ExceptionHandler` inside a controller takes priority over the global one for that controller's exceptions.
- **Filters are outside this system.** Exceptions thrown in servlet filters (including Spring Security's) never reach `@RestControllerAdvice`.

## Alternatives

- `@ExceptionHandler` inside a single controller, for one-off behavior.
- `@ResponseStatus` directly on the exception class: status only, no body control.
- `ResponseStatusException`: throw it inline with a status, no handler needed. It's quick for prototypes, but it puts HTTP knowledge in your service code.
- A custom `HandlerExceptionResolver`: lowest level, rarely needed.

**Rule of thumb:** one `@RestControllerAdvice` class, one handler method per exception type (or family), one consistent body shape, and a catch-all that logs and hides.

## What to learn next

You now have the core. Parts of this topic that you haven't asked about yet, roughly in the order I'd learn them:

1. **A unified error body**: one `ErrorResponse` that includes field errors for validation failures, so every error has the same shape.
2. **`ProblemDetail`** (Spring 6 / RFC 9457): the standard error format, which replaces a hand-written `ErrorResponse`.
3. **A base `ApiException` with status and error code**, so you write one handler instead of one per exception.
4. **Testing handlers** with `@WebMvcTest` and `MockMvc`.
5. **Security exceptions** (401/403) and why they need separate handling.

[[Spring Framework]]
[[Exception]]