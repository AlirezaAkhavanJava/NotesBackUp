

When an API call fails, the client developer is left with one question: "what do I do now?" A good error response answers it. It tells them what went wrong, which part of their request caused it, and whether the fix is on their side or yours. The key is **consistency**: every error from every endpoint should have the same shape, so the client needs only one error-handling function instead of one per endpoint. This tutorial covers what such a shape should contain, how to report validation errors with several problems at once, when to use the standard `ProblemDetail` format, and how to avoid leaking internals.

## 1. One shape everywhere

Bad: every endpoint invents its own format.

```
{ "error": "Book not found" }                         // BookController
{ "message": "no such book", "code": 4 }              // LoanController
{ "errors": ["Book unavailable"], "success": false }  // somewhere else
```

Good: the same shape, every time.

```
{ "status": 404, "error": "Not Found", "message": "...", "timestamp": "...", "path": "/books/..." }
```

## 2. What a good error contains

Five fields cover most real needs:

|Field|Purpose|Example|
|---|---|---|
|`status`|The HTTP status, repeated in the body for convenience|`404`|
|`error`|The status's standard name|`"Not Found"`|
|`message`|A specific, actionable explanation|`"Book not found with id: 9b1d..."`|
|`timestamp`|When it happened (helps you find it in logs)|`"2026-09-23T14:32:07Z"`|
|`path`|Which endpoint was called|`"/books/9b1d..."`|

## 3. Validation errors: the tricky case

One `message` string is enough for "not found". But validation can fail on several fields at once, and the client needs to know _which_ ones. If you report only the first error, the client fixes it, resubmits, hits the next error, and repeats.

**Step 1: annotate the request DTO.** This needs the `spring-boot-starter-validation` dependency.

```java
public record CreateBookRequest(
        @NotBlank(message = "Title is required") String title,
        @NotBlank(message = "Author is required") String author,
        @NotBlank(message = "ISBN is required")
        @Pattern(regexp = "\\d{13}", message = "ISBN must be 13 digits") String isbn) {}
```

`@Pattern` alone accepts `null`, which is why `@NotBlank` is there too. Then add `@Valid` in the controller, or none of this runs:

```java
@PostMapping
public ResponseEntity<BookResponse> create(@Valid @RequestBody CreateBookRequest request) { ... }
```

**Step 2: one error shape with an optional list of field problems.** One record with an optional list is simpler than two separate record types, and it keeps the shape consistent.

```java
public record FieldProblem(String field, String message) {}

@JsonInclude(JsonInclude.Include.NON_NULL) // omit fieldErrors when it is null
public record ErrorResponse(
        int status,
        String error,
        String message,
        Instant timestamp,
        String path,
        List<FieldProblem> fieldErrors) {}
```

The name `FieldProblem` is deliberate. Spring already has a `FieldError` class (`org.springframework.validation.FieldError`), and reusing that name causes confusing import mix-ups.

**Step 3: build the list from the exception.**

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex,
                                                      HttpServletRequest req) {
    List<FieldProblem> problems = ex.getBindingResult().getFieldErrors().stream()
            .map(fe -> new FieldProblem(fe.getField(), fe.getDefaultMessage()))
            .toList();

    return ResponseEntity.badRequest().body(new ErrorResponse(
            400, "Bad Request", "Validation failed", Instant.now(), req.getRequestURI(), problems));
}
```

The client gets everything wrong in one round trip:

```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "timestamp": "2026-09-23T14:32:07Z",
  "path": "/books",
  "fieldErrors": [
    { "field": "title", "message": "Title is required" },
    { "field": "isbn", "message": "ISBN must be 13 digits" }
  ]
}
```

## 4. The standard alternative: Problem Details

Hand-rolling your own `ErrorResponse` is fine, and it is the best way to understand the concepts. But there is an official web standard for exactly this problem: **Problem Details for HTTP APIs**, defined in **RFC 9457**, which replaced the older RFC 7807. You will see both numbers in articles, and the format is the same. Spring 6 and Spring Boot 3 support it through the `ProblemDetail` class.

The standard shape:

```json
{
  "type": "https://example.com/errors/book-not-found",
  "title": "Book Not Found",
  "status": 404,
  "detail": "Book not found with id: 9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "instance": "/books/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"
}
```

|Field|Meaning|
|---|---|
|`type`|A URI naming the _category_ of problem. It is an identifier and does not have to be a live web page. Defaults to `about:blank`.|
|`title`|Short summary, the same for every occurrence of this problem type|
|`status`|The HTTP status code|
|`detail`|Explanation of _this_ occurrence|
|`instance`|The specific request that failed|

The big upgrade is `type`. It gives clients a **stable, machine-readable value** to branch on (`if (problem.type.endsWith("book-not-found"))`) instead of parsing a free-text message that someone might reword next month.

Using it in Spring:

```java
@ExceptionHandler(BookNotFoundException.class)
public ProblemDetail handleNotFound(BookNotFoundException ex) {
    ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    problem.setTitle("Book Not Found");
    problem.setType(URI.create("https://example.com/errors/book-not-found"));
    return problem;
}
```

Spring sets the content type to `application/problem+json` for you, and fills in `instance` with the request path if you don't.

You can add your own fields (the standard calls them _extensions_), which is how validation errors fit in:

```java
problem.setProperty("fieldErrors", problems); // appears as a top-level "fieldErrors" field
```

Two shortcuts worth knowing:

- Setting `spring.mvc.problemdetails.enabled=true` makes Spring's _built-in_ errors (malformed JSON, wrong HTTP method, and so on) use this format too.
- Extending `ResponseEntityExceptionHandler` in your `@RestControllerAdvice` gives you the same, plus easy overrides for each built-in exception.

**Which should you use?** For learning and internal projects, a custom `ErrorResponse` is fine. For a real or public API, prefer `ProblemDetail`, because other developers' tools may already understand it.

## 5. Never leak internals

Raw exception text can expose class names, SQL and file paths, which is useful information for an attacker.

Bad: leaks internals to the client.

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<String> handleAll(Exception ex) {
    return ResponseEntity.status(500).body(ex.toString());
}
```

Good: log the details on the server, send a generic message out.

```java
@ExceptionHandler(Exception.class)
public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex, HttpServletRequest req) {
    log.error("Unhandled exception at {}", req.getRequestURI(), ex);
    return ResponseEntity.status(500).body(new ErrorResponse(
            500, "Internal Server Error", "An unexpected error occurred",
            Instant.now(), req.getRequestURI(), null));
}
```

Be especially careful with database exceptions. A raw `DataIntegrityViolationException` message can reveal table and column names. Catch it and translate it into something like "A book with this ISBN already exists" (`409`).

A good rule of thumb: it is safe to send messages from **your own** domain exceptions, because you wrote them for clients, but never forward the message of an exception you didn't write.

## 6. Write messages for the client

Bad:

```
"Optional.get() called on empty Optional"      // implementation detail
"SQL constraint violation: fk_loan_book"        // database detail
```

Good:

```
"Book not found with id: 9b1deb4d-..."          // clear and actionable
"Cannot borrow: no copies of 'Effective Java' are currently available"
```

Notice the good messages use your domain vocabulary (Book, Copy, available). Using the same words in your requirements, your code and your error messages is what makes an API feel coherent.

## 7. Putting it together

Custom exceptions, one per real business scenario:

```java
public class BookNotFoundException extends RuntimeException {
    public BookNotFoundException(UUID id) {
        super("Book not found with id: " + id);
    }
}

public class BookUnavailableException extends RuntimeException {
    public BookUnavailableException(String title) {
        super("Cannot borrow: no copies of '" + title + "' are currently available");
    }
}
```

One handler class for the whole API:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(BookNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(BookNotFoundException ex, HttpServletRequest req) {
        return build(HttpStatus.NOT_FOUND, ex.getMessage(), req, null);
    }

    @ExceptionHandler(BookUnavailableException.class)
    public ResponseEntity<ErrorResponse> handleUnavailable(BookUnavailableException ex, HttpServletRequest req) {
        return build(HttpStatus.CONFLICT, ex.getMessage(), req, null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex,
                                                          HttpServletRequest req) {
        List<FieldProblem> problems = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> new FieldProblem(fe.getField(), fe.getDefaultMessage()))
                .toList();
        return build(HttpStatus.BAD_REQUEST, "Validation failed", req, problems);
    }

    @ExceptionHandler(AccessDeniedException.class) // Spring Security: keep it a 403, not a 500
    public ResponseEntity<ErrorResponse> handleDenied(AccessDeniedException ex, HttpServletRequest req) {
        return build(HttpStatus.FORBIDDEN, "Access denied", req, null);
    }

    @ExceptionHandler(Exception.class) // safety net, should rarely fire
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception at {}", req.getRequestURI(), ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred", req, null);
    }

    private ResponseEntity<ErrorResponse> build(HttpStatus status, String message,
                                                HttpServletRequest req, List<FieldProblem> fieldErrors) {
        return ResponseEntity.status(status).body(new ErrorResponse(
                status.value(), status.getReasonPhrase(), message,
                Instant.now(), req.getRequestURI(), fieldErrors));
    }
}
```

Not-found, conflict, validation and unexpected bugs all produce the same predictable, safe shape. The `AccessDeniedException` handler is there because a catch-all `Exception` handler would otherwise turn Spring Security's `403` into a `500`.

## Key takeaways

1. Use **one consistent error shape** across the whole API.
2. Minimum useful fields: `status`, `error`, `message`, `timestamp`, `path`.
3. Validation errors need a **list** of field-level problems, not a single string.
4. `ProblemDetail` (RFC 9457) is the standard version. Its `type` field gives clients something stable to branch on. Prefer it for real or public APIs.
5. **Never** send stack traces, exception class names or SQL to the client. Log them on the server and return a generic message.
6. Centralize everything in one `@RestControllerAdvice`.




[[Spring Framework]]