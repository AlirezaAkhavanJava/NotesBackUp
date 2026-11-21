**`ProblemDetail`** is a Spring class (`org.springframework.http.ProblemDetail`) that represents an error response in a standard JSON shape defined by RFC 9457, with the content type `application/problem+json`. Instead of every endpoint inventing its own error format, every error your API returns has the same fields, so a client can parse all of them with one piece of code.

**`ApiExceptionHandler`** is the name I'll use for your global exception handler: a class annotated with `@RestControllerAdvice` that holds `@ExceptionHandler` methods. Each method catches one kind of exception, from any controller, and turns it into an HTTP response. Together they work like this: your controllers and services throw plain exceptions, the handler catches them, and it builds a `ProblemDetail` with the status code and message. You saw in the `@ResponseStatus` lesson that a handler returning its own body needs the annotation to set the status. With `ProblemDetail`, the status lives inside the object, so that annotation is no longer needed.

## What a ProblemDetail contains

|Field|Meaning|Example|
|---|---|---|
|`type`|A URI that identifies the kind of problem. Defaults to `about:blank`.|`https://api.example.com/problems/product-not-found`|
|`title`|Short, human-readable summary. The same for every case of this problem.|`Product not found`|
|`status`|The HTTP status code, repeated in the body.|`404`|
|`detail`|Explanation of **this** occurrence.|`Product 99 not found`|
|`instance`|The request that failed. Spring fills it with the request path if you leave it empty.|`/products/99`|
|_your own fields_|Added with `setProperty(name, value)`. They appear at the top level of the JSON.|`"productId": 99`|

You create one with factory methods and fill it with setters:

```java
ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, "Product 99 not found");
pd.setTitle("Product not found");
pd.setProperty("productId", 99);
```

`forStatus(status)` creates one with only a status. `forStatusAndDetail(status, detail)` also sets `detail`.

## The exceptions your code throws

Keep them plain. They carry data, and they know nothing about HTTP:

```java
public class ProductNotFoundException extends RuntimeException {
    private final Long id;
    public ProductNotFoundException(Long id) {
        super("Product " + id + " not found");
        this.id = id;
    }
    public Long getId() { return id; }
}

public class DuplicateSkuException extends RuntimeException {
    public DuplicateSkuException(String sku) {
        super("A product with SKU " + sku + " already exists");
    }
}
```

In the CRUD service you simply throw them:

```java
public ProductResponse read(Long id) {
    return repo.findById(id)
        .map(mapper::toResponse)
        .orElseThrow(() -> new ProductNotFoundException(id));
}
```

## The ApiExceptionHandler

```java
@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler(ProductNotFoundException.class)
    public ProblemDetail handleNotFound(ProductNotFoundException ex) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        pd.setTitle("Product not found");
        pd.setType(URI.create("https://api.example.com/problems/product-not-found"));
        pd.setProperty("productId", ex.getId());
        return pd;
    }

    @ExceptionHandler(DuplicateSkuException.class)
    public ProblemDetail handleDuplicate(DuplicateSkuException ex) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage());
        pd.setTitle("Duplicate SKU");
        return pd;
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ProblemDetail handleDenied(AccessDeniedException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.FORBIDDEN, "You do not have permission for this action.");
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex, HttpHeaders headers,
            HttpStatusCode status, WebRequest request) {

        Map<String, String> errors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
          .forEach(fe -> errors.putIfAbsent(fe.getField(), fe.getDefaultMessage()));

        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        pd.setTitle("Invalid request");
        pd.setProperty("errors", errors);
        return handleExceptionInternal(ex, pd, headers, status, request);
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return ProblemDetail.forStatusAndDetail(
            HttpStatus.INTERNAL_SERVER_ERROR, "Something went wrong on our side.");
    }
}
```

Reading it from the top:

- **`@RestControllerAdvice`** applies the handlers to every controller and writes return values as JSON.
- **`extends ResponseEntityExceptionHandler`** gives you ready-made `ProblemDetail` handling for Spring's own MVC exceptions: wrong HTTP method (405), unreadable JSON (400), missing parameter (400), unsupported media type (415), and so on. You get consistent errors for free. If you don't extend it, you can set `spring.mvc.problemdetails.enabled=true` instead, but do one or the other.
- **Each `@ExceptionHandler(X.class)` method** runs when `X` or a subclass escapes a controller. Spring picks the most specific match, so `ProductNotFoundException` goes to its own method and not to the `Exception` one.
- **Returning `ProblemDetail`** is enough: Spring uses its `status` for the response, so no `@ResponseStatus` and no `ResponseEntity` is needed.
- **`handleMethodArgumentNotValid`** is the hook for `@Valid` failures. You override it to add an `errors` map with one message per field. Without the override, you still get a 400, but without the field list.
- **The catch-all** returns a fixed, safe message and logs the real exception. Never put `ex.getMessage()` in a 500 response, because it can expose SQL, class names, or file paths.

## The HTTP responses your client sees

**Not found:** `GET /products/99`

```http
HTTP/1.1 404 Not Found
Content-Type: application/problem+json

{
  "type": "https://api.example.com/problems/product-not-found",
  "title": "Product not found",
  "status": 404,
  "detail": "Product 99 not found",
  "instance": "/products/99",
  "productId": 99
}
```

**Validation failure:** `POST /products` with a blank name and a negative price

```http
HTTP/1.1 400 Bad Request
Content-Type: application/problem+json

{
  "type": "about:blank",
  "title": "Invalid request",
  "status": 400,
  "detail": "Validation failed",
  "instance": "/products",
  "errors": {
    "name": "must not be blank",
    "price": "must be greater than 0"
  }
}
```

**Conflict:** `POST /products` with an existing SKU

```http
HTTP/1.1 409 Conflict
Content-Type: application/problem+json

{
  "type": "about:blank",
  "title": "Duplicate SKU",
  "status": 409,
  "detail": "A product with SKU KB-100 already exists",
  "instance": "/products"
}
```

**Built-in Spring error:** `DELETE /products` (no id, method not allowed). You wrote no code for this one. It comes from `ResponseEntityExceptionHandler`:

```http
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD, POST
Content-Type: application/problem+json

{
  "type": "about:blank",
  "title": "Method Not Allowed",
  "status": 405,
  "detail": "Method 'DELETE' is not supported.",
  "instance": "/products"
}
```

**Unexpected failure:**

```http
HTTP/1.1 500 Internal Server Error
Content-Type: application/problem+json

{
  "type": "about:blank",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "Something went wrong on our side.",
  "instance": "/products/5"
}
```

Notice that `title` was filled in automatically for responses where you didn't set it. When it is empty, Spring uses the standard reason phrase of the status.

## Things that catch people out

- **A catch-all `Exception` handler swallows `AccessDeniedException`** thrown by `@PreAuthorize`, turning a 403 into a 500. That is why the handler above has an explicit 403 method. Always add one if you use method security.
- **Security filter exceptions never reach this class.** A missing or invalid JWT fails inside the filter chain, before any controller runs, so `@RestControllerAdvice` cannot see it. For 401 and 403 produced by the filters, you configure an `AuthenticationEntryPoint` and an `AccessDeniedHandler` in your `SecurityFilterChain`, and write the `ProblemDetail` JSON there yourself.
- **Keep one handler class per application**, or order several with `@Order`. Two advice classes handling the same exception give you unpredictable results.
- **`type` is an identifier, not necessarily a working link.** It may point to documentation, but clients should treat it as a stable ID for the problem kind. Leave it as `about:blank` when `title` and `status` already say everything.
- **Log in the handler, not in the service.** Log the 500 with its stack trace once, here. Expected errors like 404 and 409 usually deserve at most a debug line.

## A related concept in one short summary

**`ErrorResponseException`** (and the `ErrorResponse` interface it implements) lets an exception carry its own `ProblemDetail` and status. Spring handles it automatically with no `@ExceptionHandler` needed, and Spring's built-in exceptions such as `MethodArgumentNotValidException` already implement `ErrorResponse`. You can extend it for simple custom errors:

```java
public class ProductNotFoundException extends ErrorResponseException {
    public ProductNotFoundException(Long id) {
        super(HttpStatus.NOT_FOUND,
              ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, "Product " + id + " not found"),
              null);
    }
}
```

This is the same trade-off you met with `@ResponseStatus` on an exception class: it is less code, but the exception now knows about HTTP. The `ApiExceptionHandler` approach keeps that knowledge in one place and is the better fit once your API grows.


[[Spring Framework]]