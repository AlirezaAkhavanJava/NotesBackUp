

Every HTTP response starts with a three-digit number that tells the client, before it reads a single byte of the body, whether the request worked and, if it didn't, whose fault that was. That number is the **status code**, and it's a contract that browsers, load balancers, API clients and monitoring tools all rely on. If you return `200 OK` for everything and hide the real result inside the JSON, you break that contract and all the infrastructure built on it. This tutorial shows what each code means, which ones you'll actually use, and how to return them cleanly from Spring Boot.

## 1. Why the status code matters

The classic beginner mistake is returning `200` for everything:

```
❌ Bad: the status says "success", the body says "failure"
HTTP 200 OK
{ "success": false, "error": "Book not found" }
```

A frontend check like `if (response.ok)`, your error tracker (Sentry, Datadog) and your load balancer all look at the **status code**, not the body. They'll treat the response above as a success. Get the code right and a lot of tooling works for free:

```
✅ Good: status and body agree
HTTP 404 Not Found
{ "error": "Book not found" }
```

## 2. The five classes

The first digit is the category:

|Class|Meaning|Remember it as|
|---|---|---|
|`1xx`|Informational|Rarely touched in app code|
|`2xx`|Success|It worked|
|`3xx`|Redirection|Look somewhere else|
|`4xx`|Client error|**Fix your request**|
|`5xx`|Server error|**We messed up**|

This split is useful for debugging. A spike in `4xx` usually means a client is integrating badly. A spike in `5xx` means your backend has a bug.

## 3. Success codes (`2xx`)

|Code|Name|Use it for|
|---|---|---|
|`200`|OK|`GET`, `PUT`, `PATCH` that return data|
|`201`|Created|A `POST` that created something|
|`202`|Accepted|Work accepted but processed later (background jobs)|
|`204`|No Content|Success with nothing to return, typically `DELETE`|

### 201 Created and the `Location` header

A proper `201` tells the client where the new resource lives, using a `Location` header. Returning the new resource in the body is common and handy, but the header is the part that's part of the convention.

```java
@PostMapping
public ResponseEntity<BookResponse> create(@Valid @RequestBody CreateBookRequest request) {
    BookResponse created = bookService.create(request);

    URI location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(created.id())
            .toUri();

    return ResponseEntity.created(location).body(created);
}
```

```
HTTP/1.1 201 Created
Location: http://localhost:8080/books/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d

{ "id": "9b1deb4d-...", "title": "Effective Java" }
```

`ServletUriComponentsBuilder` builds the URL from the current request, so you never hardcode `/books/`.

### 204 No Content for deletes

```java
@DeleteMapping("/{id}")
public ResponseEntity<Void> delete(@PathVariable UUID id) {
    bookService.delete(id);
    return ResponseEntity.noContent().build();
}
```

Don't return `200` with an empty `{}`. `204` says precisely "done, nothing more to say."

## 4. Client errors (`4xx`)

This is where precision pays off, because the exact code tells the client what to fix.

|Code|Name|Use it when|
|---|---|---|
|`400`|Bad Request|Malformed or invalid input (failed validation, missing field, wrong type)|
|`401`|Unauthorized|The caller isn't authenticated (no token, or invalid or expired)|
|`403`|Forbidden|Authenticated, but not allowed to do this|
|`404`|Not Found|The resource doesn't exist|
|`405`|Method Not Allowed|Wrong HTTP verb for this URL|
|`409`|Conflict|The request clashes with the current state|
|`422`|Unprocessable Entity|Valid syntax, but breaks a business rule|
|`429`|Too Many Requests|Rate limit exceeded|

### 401 vs 403 (everyone mixes these up)

- **401:** "I don't know who you are." _(Despite the name "Unauthorized", it really means unauthenticated.)_
- **403:** "I know exactly who you are, and you're not allowed."

Example: no token or an expired token gives `401`. A valid token for a Member who calls a librarian-only endpoint gives `403`. Spring Security produces both for you once it's configured.

### 400 vs 422

- **400:** the request itself is broken (a missing field, or a string where a number belongs).
- **422:** the request is well-formed but violates a rule (for example, `dueDate` is before `loanDate`).

Lots of real APIs just use `400` for both, and that's a perfectly fine simplification. Know that `422` exists, but don't feel forced to use it.

### 409 Conflict

`409` means "your request is fine, but it doesn't fit the current state of things." Borrowing a book that has zero available copies is a textbook case:

```
POST /loans
{ "memberId": "...", "bookId": "..." }

→ 409 Conflict
{ "error": "No copies available" }
```

Some teams use `422` for business-rule violations like this. Either choice is defensible. What matters is that you pick one and stay consistent across the API.

## 5. Server errors (`5xx`)

|Code|Name|When|
|---|---|---|
|`500`|Internal Server Error|An unexpected exception escaped your code|
|`502`|Bad Gateway|A service you called returned garbage or failed|
|`503`|Service Unavailable|Temporarily can't serve (deploy, overload, maintenance)|

A `500` in your logs is **always a bug to investigate**, not a normal client mistake. Most failure paths should be caught and turned into a meaningful `4xx`.

Never send the raw exception message or stack trace to the client. It can expose class names, SQL and file paths. Log the details on the server and return a generic message.

## 6. Mapping exceptions to status codes in one place

Instead of building `ResponseEntity`s all over your controllers, throw meaningful exceptions from the service layer and translate them in **one** `@RestControllerAdvice`:

```java
public record ErrorResponse(int status, String error, String message,
                            Instant timestamp, String path) {}
```

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler({BookNotFoundException.class, MemberNotFoundException.class})
    public ResponseEntity<ErrorResponse> handleNotFound(RuntimeException ex, HttpServletRequest req) {
        return build(HttpStatus.NOT_FOUND, ex.getMessage(), req);
    }

    @ExceptionHandler({BookUnavailableException.class, BorrowLimitExceededException.class})
    public ResponseEntity<ErrorResponse> handleConflict(RuntimeException ex, HttpServletRequest req) {
        return build(HttpStatus.CONFLICT, ex.getMessage(), req);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex,
                                                          HttpServletRequest req) {
        String details = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + " " + e.getDefaultMessage())
                .collect(Collectors.joining("; "));
        return build(HttpStatus.BAD_REQUEST, details, req);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleDenied(AccessDeniedException ex, HttpServletRequest req) {
        return build(HttpStatus.FORBIDDEN, "Access denied", req);
    }

    @ExceptionHandler(Exception.class) // safety net: should rarely fire
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception on {}", req.getRequestURI(), ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred", req);
    }

    private ResponseEntity<ErrorResponse> build(HttpStatus status, String message, HttpServletRequest req) {
        return ResponseEntity.status(status).body(new ErrorResponse(
                status.value(), status.getReasonPhrase(), message, Instant.now(), req.getRequestURI()));
    }
}
```

Things worth noticing:

- Each handler lists the exceptions it covers, so related exceptions share one handler.
- The validation handler lists _which fields_ failed, so the client can actually fix the request.
- **The catch-all trap:** a handler for `Exception.class` catches _everything_ that isn't handled more specifically, including Spring Security's `AccessDeniedException`, which would turn a `403` into a `500`. That's why it has its own handler above.
- The catch-all **logs the stack trace** and returns a generic message, exactly as section 5 says.

The mapping at a glance:

|Scenario|Exception|Status|
|---|---|---|
|Book or Member doesn't exist|`BookNotFoundException`, `MemberNotFoundException`|`404`|
|No copies available|`BookUnavailableException`|`409`|
|Member already at the borrow limit|`BorrowLimitExceededException`|`409`|
|Request body fails validation|`MethodArgumentNotValidException`|`400`|
|No or expired token|Spring Security|`401`|
|Not permitted for this role|`AccessDeniedException`|`403`|
|Unexpected bug|any other `Exception`|`500`|

Spring Boot already returns `400` for malformed JSON and `405` for a wrong verb on its own, so you don't need handlers for those.

## 7. Use the `HttpStatus` enum

Don't scatter magic numbers around. Spring gives you a type-safe enum:

```java
HttpStatus.OK                     // 200
HttpStatus.CREATED                // 201
HttpStatus.NO_CONTENT             // 204
HttpStatus.BAD_REQUEST            // 400
HttpStatus.UNAUTHORIZED           // 401
HttpStatus.FORBIDDEN              // 403
HttpStatus.NOT_FOUND              // 404
HttpStatus.CONFLICT               // 409
HttpStatus.INTERNAL_SERVER_ERROR  // 500
```

It's self-documenting, and the compiler catches typos.

## 8. A standard error format (good to know)

Spring Boot 3 and newer can return errors in the standard **Problem Details** format (RFC 9457, previously 7807) using the built-in `ProblemDetail` class. A custom `ErrorResponse` like the one above works fine, but Problem Details is the industry standard, so it's worth reading about once you're comfortable with the basics.

## 9. Quick decision table

|Situation|Code|
|---|---|
|Successful `GET`, `PUT` or `PATCH` with a body|`200`|
|Successful `POST` that created something|`201`|
|Successful `DELETE`, or an update with nothing to return|`204`|
|Malformed or invalid input|`400`|
|Not authenticated|`401`|
|Authenticated but not allowed|`403`|
|Resource doesn't exist|`404`|
|Conflicts with the current state|`409`|
|Unexpected bug in your code|`500` (and go fix it)|

## Key takeaways

1. The status code is the contract. Never signal success or failure only in the body.
2. `4xx` means the client's fault, `5xx` means yours.
3. `401` means "who are you?", `403` means "you can't do that."
4. Business-rule violations like "no copies available" fit `409` (or `422`). Pick one and be consistent.
5. Centralize exception-to-status mapping in one `@RestControllerAdvice`, and don't let a catch-all handler swallow Spring Security exceptions.
6. A `500` in your logs is always a bug worth investigating.






[[Networking]]
[[Spring Framework]]