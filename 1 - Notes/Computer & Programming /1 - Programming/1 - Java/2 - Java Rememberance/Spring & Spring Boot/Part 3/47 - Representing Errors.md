

We've used a hand-rolled `ErrorResponse` record in earlier tutorials and mentioned RFC 7807 in passing. Let's now go deep on **how to design error representations properly** — this is the piece that makes an API pleasant (or miserable) to integrate against.

---

## 1. The Core Principle

Just like a success response has a consistent **representation** (our `BookDto`, `LoanDto`), every error your API returns should follow **one consistent shape** — regardless of which endpoint or exception caused it. A frontend developer should be able to write **one** error-handling function that works everywhere in your API, instead of parsing a different error format per endpoint.

```java
// ❌ Inconsistent — every endpoint invents its own error shape
{ "error": "Book not found" }                          // from BookController
{ "message": "no such book", "code": 4 }                 // from LoanController
{ "errors": ["Book unavailable"], "success": false }       // from another endpoint
```

```java
// ✅ Consistent — same shape everywhere, every time
{ "status": 404, "error": "Not Found", "message": "...", "timestamp": "...", "path": "/books/..." }
```

---

## 2. What a Good Error Response Contains

Five pieces of information cover almost every real need:

|Field|Purpose|Example|
|---|---|---|
|`status`|The HTTP status code, duplicated in the body for convenience|`404`|
|`error`|Human-readable name of the status|`"Not Found"`|
|`message`|Specific, actionable explanation|`"Book not found with id: 9b1deb4d-..."`|
|`timestamp`|When the error occurred (useful for correlating with logs)|`"2026-09-23T14:32:07Z"`|
|`path`|Which endpoint was hit|`"/books/9b1deb4d-..."`|

This is exactly the `ErrorResponse` record we introduced two tutorials ago:

```java
public record ErrorResponse(
    int status,
    String error,
    String message,
    Instant timestamp,
    String path
) {}
```

---

## 3. Handling Validation Errors — the Trickiest Case

A plain `message: String` works fine for "not found" or "conflict" errors — one clear sentence is enough. But **validation failures** are different: multiple fields can be wrong at once, and the client needs to know _which_ fields, not just that "something" was invalid.

### Step 1 — Add Bean Validation annotations to your request DTO

```java
public record CreateBookRequest(
    @NotBlank(message = "Title is required")
    String title,

    @NotBlank(message = "Author is required")
    String author,

    @Pattern(regexp = "\\d{13}", message = "ISBN must be 13 digits")
    String isbn
) {}
```

```java
@PostMapping
public ResponseEntity<BookDto> create(@Valid @RequestBody CreateBookRequest request) {
    // @Valid triggers validation before this method body even runs
    return ResponseEntity.status(HttpStatus.CREATED).body(bookService.create(request));
}
```

### Step 2 — Represent validation errors as a list of field-level problems

A single `message` string can't cleanly say "title is missing AND isbn is malformed." Extend your error shape with a `fieldErrors` list, used only when relevant:

```java
public record FieldError(String field, String message) {}

public record ValidationErrorResponse(
    int status,
    String error,
    String message,
    Instant timestamp,
    String path,
    List<FieldError> fieldErrors
) {}
```

### Step 3 — Catch `MethodArgumentNotValidException` and build the list

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ResponseEntity<ValidationErrorResponse> handleValidation(
        MethodArgumentNotValidException ex, HttpServletRequest request) {

    List<FieldError> fieldErrors = ex.getBindingResult().getFieldErrors().stream()
        .map(fe -> new FieldError(fe.getField(), fe.getDefaultMessage()))
        .toList();

    ValidationErrorResponse response = new ValidationErrorResponse(
        400, "Bad Request", "Validation failed",
        Instant.now(), request.getRequestURI(), fieldErrors
    );
    return ResponseEntity.badRequest().body(response);
}
```

Resulting response — the client gets everything wrong in one round trip, instead of fixing one field, resubmitting, hitting the _next_ error, and repeating:

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

---

## 4. The Standardized Alternative — RFC 7807 `ProblemDetail`

Hand-rolling `ErrorResponse` is completely fine for learning and small projects. But there's an actual **web standard** for this exact problem — [RFC 7807 "Problem Details for HTTP APIs"](https://www.rfc-editor.org/rfc/rfc7807) — and Spring Boot 3 supports it natively.

### The standard shape

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
|`type`|A URI identifying the _category_ of error (can be a doc page, doesn't have to be a real live URL)|
|`title`|Short, human-readable summary — stays the same across instances of this error type|
|`status`|HTTP status code, duplicated for convenience (same idea as before)|
|`detail`|Specific explanation for _this_ occurrence|
|`instance`|Which specific request/URI triggered it|

The `type` field is the key upgrade over the hand-rolled version — it gives clients something **machine-readable and stable to branch on** (`if (problem.type === '.../book-not-found')`), instead of parsing a free-text `message` string, which can change wording and silently break client code.

### Using it in Spring Boot 3

```java
@ExceptionHandler(BookNotFoundException.class)
public ProblemDetail handleBookNotFound(BookNotFoundException ex) {
    ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    problem.setTitle("Book Not Found");
    problem.setType(URI.create("https://example.com/errors/book-not-found"));
    return problem;
}
```

Spring automatically sets the `Content-Type` header to `application/problem+json` (instead of plain `application/json`) — this itself is a signal to HTTP-aware tooling that this response is a structured error, not normal data.

**Should you use `ProblemDetail` instead of a hand-rolled `ErrorResponse`?** For a learning project, either is fine — the concepts (status, message, path) transfer directly. `ProblemDetail` is worth adopting once you're building something you intend to be a "real" public-facing API, since consumers may already have tooling that expects RFC 7807.

---

## 5. Never Leak Internal Details in Error Responses

A common security mistake: letting a raw exception message or stack trace reach the client.

```java
// ❌ Dangerous — leaks internal class names, SQL, file paths to the client
@ExceptionHandler(Exception.class)
public ResponseEntity<String> handleAll(Exception ex) {
    return ResponseEntity.status(500).body(ex.toString());
}
```

```java
// ✅ Safe — log the real detail server-side, return a generic message to the client
@ExceptionHandler(Exception.class)
public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex, HttpServletRequest request) {
    log.error("Unhandled exception at {}", request.getRequestURI(), ex); // full stack trace, server-side only
    ErrorResponse error = new ErrorResponse(
        500, "Internal Server Error", "An unexpected error occurred",
        Instant.now(), request.getRequestURI()
    );
    return ResponseEntity.status(500).body(error);
}
```

This is especially important for **database-related exceptions** — a raw `DataIntegrityViolationException` message can expose your table/column names and SQL structure. Always catch it and translate to a clean, generic message.

---

## 6. Domain-Specific vs. Generic Error Messages — Write for the Client, Not for You

Compare:

```json
❌ { "message": "Optional.get() called on empty Optional" }     // leaked implementation detail
❌ { "message": "SQL constraint violation: fk_loan_book" }        // leaked DB detail
✅ { "message": "Book not found with id: 9b1deb4d-..." }          // clear, actionable, domain language
✅ { "message": "Cannot borrow: no copies of 'Effective Java' are currently available" }
```

Notice the last one uses the exact **domain vocabulary** from our Domain Overview glossary (`Book`, `Copy`, `available`) — this consistency, all the way from requirements → domain glossary → exception messages → API errors, is what makes an API feel coherent rather than assembled from mismatched parts.

---

## 7. Full Example — Tying It All Together

```java
// Custom exceptions — one per real business scenario
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

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BookNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(BookNotFoundException ex, HttpServletRequest req) {
        return build(HttpStatus.NOT_FOUND, ex.getMessage(), req);
    }

    @ExceptionHandler(BookUnavailableException.class)
    public ResponseEntity<ErrorResponse> handleUnavailable(BookUnavailableException ex, HttpServletRequest req) {
        return build(HttpStatus.CONFLICT, ex.getMessage(), req);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ValidationErrorResponse> handleValidation(
            MethodArgumentNotValidException ex, HttpServletRequest req) {
        List<FieldError> fieldErrors = ex.getBindingResult().getFieldErrors().stream()
            .map(fe -> new FieldError(fe.getField(), fe.getDefaultMessage()))
            .toList();
        return ResponseEntity.badRequest().body(new ValidationErrorResponse(
            400, "Bad Request", "Validation failed", Instant.now(), req.getRequestURI(), fieldErrors
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception at {}", req.getRequestURI(), ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred", req);
    }

    private ResponseEntity<ErrorResponse> build(HttpStatus status, String message, HttpServletRequest req) {
        ErrorResponse error = new ErrorResponse(
            status.value(), status.getReasonPhrase(), message, Instant.now(), req.getRequestURI()
        );
        return ResponseEntity.status(status).body(error);
    }
}
```

One class. Every error path in your entire API — not-found, conflict, validation, unexpected bugs — produces a predictable, safe, well-formed response.

---

## Quick Summary

1. Every error uses **one consistent shape** across the whole API — never invent a new format per endpoint
2. Minimum useful fields: `status`, `error`, `message`, `timestamp`, `path`
3. Validation errors need a **list** of field-level problems, not a single string
4. RFC 7807 `ProblemDetail` is the standardized version — built into Spring Boot 3, worth adopting for real/public APIs
5. **Never** leak stack traces, exception class names, or SQL details to the client — log them server-side, return a generic safe message
6. Centralize everything in one `@RestControllerAdvice` class

---




[[Java]]
[[0 - Spring Framework]]
[[1 - HTTP]]