

We've referenced status codes in almost every previous tutorial without going deep. Let's fix that properly — this is the layer of REST that tells the client _what happened_, independent of whatever's in the JSON body.

---

## 1. Why Status Codes Matter (and the mistake to avoid)

The #1 beginner mistake: returning `200 OK` for everything, and putting success/failure info only inside the JSON body:

```json
// ❌ Bad — status code says "success" but body says "failure"
HTTP 200 OK
{ "success": false, "error": "Book not found" }
```

This breaks the contract every HTTP client, browser, proxy, and monitoring tool relies on. Load balancers, error-tracking tools (Sentry, Datadog), and even simple `if (response.ok)` checks in frontend code all key off the **status code**, not the body content. Get the status code right, and a huge amount of infrastructure "just works" for free.

```java
// ✅ Good — status code and body agree
HTTP 404 Not Found
{ "error": "Book not found with id: ..." }
```

---

## 2. The Five Classes (first digit tells you the category)

|Class|Category|Meaning|
|---|---|---|
|`1xx`|Informational|Rarely touched directly in app code|
|`2xx`|Success|The request worked|
|`3xx`|Redirection|The resource is somewhere else|
|`4xx`|Client Error|**The caller** did something wrong|
|`5xx`|Server Error|**Your code** did something wrong|

The first thing to internalize: **4xx = "fix your request," 5xx = "we messed up."** This distinction matters for debugging — a spike in 4xx usually means a bad client integration; a spike in 5xx means your backend has a bug.

---

## 3. `2xx` — Success Codes

|Code|Name|When to use|Spring Boot example|
|---|---|---|---|
|`200 OK`|Generic success|`GET`, `PUT`, `PATCH` that return data|Default for most successful responses|
|`201 Created`|Resource created|Response to a successful `POST`|Must include the new resource (often with a `Location` header)|
|`202 Accepted`|Request accepted, processing async|Long-running background jobs|Rare in typical CRUD apps|
|`204 No Content`|Success, nothing to return|`DELETE`, or updates where you don't return a body|No JSON body at all|

### `201 Created` — the detail most people skip

A proper `201` response should include a `Location` header pointing to the new resource:

```java
@PostMapping
public ResponseEntity<BookDto> create(@RequestBody CreateBookRequest request) {
    BookDto created = bookService.create(request);
    URI location = URI.create("/books/" + created.id());
    return ResponseEntity.created(location).body(created);
}
```

```
HTTP/1.1 201 Created
Location: /books/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d

{ "id": "9b1deb4d-...", "title": "Effective Java" }
```

### `204 No Content` — for delete

```java
@DeleteMapping("/{id}")
public ResponseEntity<Void> delete(@PathVariable UUID id) {
    bookService.delete(id);
    return ResponseEntity.noContent().build(); // 204, empty body
}
```

Don't return `200 OK` with an empty `{}` body for deletes — `204` communicates "success, and there's nothing more to say" precisely.

---

## 4. `4xx` — Client Error Codes (the ones you'll use most)

This is the range where precision matters most — picking the _right_ 4xx code tells the client exactly what to fix.

|Code|Name|When to use|
|---|---|---|
|`400 Bad Request`|Malformed/invalid input|Failed validation, missing required field, wrong data type|
|`401 Unauthorized`|Not authenticated|No JWT, or an invalid/expired JWT|
|`403 Forbidden`|Authenticated, but not allowed|A Member hitting a Librarian-only endpoint|
|`404 Not Found`|Resource doesn't exist|`GET /books/{unknown-id}`|
|`405 Method Not Allowed`|Wrong HTTP verb for this URL|`DELETE /books` (no ID — collection can't be deleted)|
|`409 Conflict`|Request conflicts with current state|Borrowing a Book with 0 available copies|
|`422 Unprocessable Entity`|Syntactically valid, semantically wrong|Body parses fine but violates a business rule|
|`429 Too Many Requests`|Rate limit exceeded|Client is calling too fast|

### `401` vs `403` — the distinction people mix up constantly

- **`401 Unauthorized`** → "I don't know who you are" (no valid credentials at all)
- **`403 Forbidden`** → "I know exactly who you are, and you're not allowed to do this"

```java
// No JWT at all, or expired token → 401
// Valid JWT, but user is a Member trying to POST /books (librarian-only) → 403
```

Spring Security handles both automatically once configured — worth knowing the distinction now so the behavior makes sense later when you set up security.

### `400` vs `422` — a subtler distinction (many APIs simplify to just `400`)

- **`400`** → the request itself is malformed (missing field, wrong JSON type, e.g., sending a string where a number is expected)
- **`422`** → the request is _well-formed_ JSON, but violates a business rule (e.g., `dueDate` is before `loanDate`)

Many real-world APIs don't bother distinguishing these and just use `400` for all validation failures — that's a perfectly reasonable simplification. Know `422` exists, but don't feel obligated to use it if `400` covers your needs.

### `409 Conflict` — connects directly to our earlier Use Case work

Remember the "Borrow Book" use case's alternate flow: _"if no copies available → reject."_ This is exactly a `409`:

```java
@ExceptionHandler(BookUnavailableException.class)
public ResponseEntity<ErrorResponse> handleUnavailable(BookUnavailableException ex) {
    return ResponseEntity.status(HttpStatus.CONFLICT)
        .body(new ErrorResponse(ex.getMessage()));
}
```

```
POST /loans
{ "memberId": "...", "bookId": "..." }

→ 409 Conflict
{ "error": "Book unavailable" }
```

---

## 5. `5xx` — Server Error Codes

|Code|Name|When it happens|
|---|---|---|
|`500 Internal Server Error`|Generic, unhandled failure|An unexpected exception your code didn't catch|
|`502 Bad Gateway`|Upstream service failed|Your server called another service that failed|
|`503 Service Unavailable`|Server temporarily can't handle requests|During deploys, overload, maintenance|

**A `500` in your logs is always a signal to investigate** — unlike `4xx` codes (which are often just normal client mistakes), a `500` means an exception escaped your exception handling. In a well-built Spring Boot app, you should rarely see raw `500`s in production — most failure paths should be caught and converted into a meaningful `4xx` with a clear message.

```java
// Catch-all handler — the safety net, but ideally rarely triggered
@ExceptionHandler(Exception.class)
public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex) {
    // log the full stack trace here — this is a bug, not a client mistake
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(new ErrorResponse("An unexpected error occurred"));
}
```

Never leak the raw exception message or stack trace to the client in a `500` response — that can expose internal implementation details (class names, SQL, file paths). Log it server-side; return a generic message to the caller.

---

## 6. Full Mapping — Library Domain Exceptions → Status Codes

This ties together everything from the Requirements Engineering tutorial (remember the alternate flows we wrote?) straight through to actual HTTP responses:

|Scenario (from our Use Case alternate flows)|Exception|Status Code|
|---|---|---|
|Book doesn't exist|`BookNotFoundException`|`404`|
|Member doesn't exist|`MemberNotFoundException`|`404`|
|Member has 3+ active loans|`BorrowLimitExceededException`|`409`|
|Book has 0 available copies|`BookUnavailableException`|`409`|
|Request body missing `bookId`|(validation failure)|`400`|
|No JWT / expired token|(Spring Security)|`401`|
|Member tries a librarian-only action|(Spring Security)|`403`|
|Unhandled bug|(uncaught exception)|`500`|

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BookNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleBookNotFound(BookNotFoundException ex, HttpServletRequest req) {
        return build(HttpStatus.NOT_FOUND, ex.getMessage(), req);
    }

    @ExceptionHandler(BorrowLimitExceededException.class)
    public ResponseEntity<ErrorResponse> handleBorrowLimit(BorrowLimitExceededException ex, HttpServletRequest req) {
        return build(HttpStatus.CONFLICT, ex.getMessage(), req);
    }

    @ExceptionHandler(BookUnavailableException.class)
    public ResponseEntity<ErrorResponse> handleUnavailable(BookUnavailableException ex, HttpServletRequest req) {
        return build(HttpStatus.CONFLICT, ex.getMessage(), req);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class) // bean validation failures
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest req) {
        return build(HttpStatus.BAD_REQUEST, "Validation failed", req);
    }

    private ResponseEntity<ErrorResponse> build(HttpStatus status, String message, HttpServletRequest req) {
        ErrorResponse error = new ErrorResponse(
            status.value(), status.getReasonPhrase(), message, Instant.now(), req.getRequestURI()
        );
        return ResponseEntity.status(status).body(error);
    }
}
```

One centralized place, every custom exception mapped to its correct code, every error response shaped identically — exactly the consistent error format we established in the Web Resource Formatting tutorial.

---

## 7. Spring Boot's `HttpStatus` Enum — How You Actually Set These

You never hardcode raw numbers — Spring Boot gives you a type-safe enum:

```java
HttpStatus.OK                     // 200
HttpStatus.CREATED                // 201
HttpStatus.NO_CONTENT             // 204
HttpStatus.BAD_REQUEST            // 400
HttpStatus.UNAUTHORIZED           // 401
HttpStatus.FORBIDDEN              // 403
HttpStatus.NOT_FOUND              // 404
HttpStatus.CONFLICT               // 409
HttpStatus.UNPROCESSABLE_ENTITY   // 422
HttpStatus.INTERNAL_SERVER_ERROR  // 500
```

Using the enum (not a magic number like `404`) is itself a clean-code habit — it's self-documenting and the compiler catches typos.

---

## 8. Quick Decision Table (use this when writing any endpoint)

|Situation|Status Code|
|---|---|
|Successful `GET`/`PUT`/`PATCH` with a body|`200`|
|Successful `POST` that created something|`201`|
|Successful `DELETE`, or update with no body to return|`204`|
|Client sent bad/malformed data|`400`|
|No valid authentication at all|`401`|
|Authenticated but not permitted|`403`|
|The specific resource doesn't exist|`404`|
|Request conflicts with current resource state|`409`|
|Anything unhandled/unexpected in your code|`500` (and go fix it)|

---

## Quick Summary

1. **Never** rely on the JSON body alone to signal success/failure — the status code is the contract
2. `2xx` = success, `4xx` = client's fault, `5xx` = your server's fault
3. `401` = "I don't know you," `403` = "I know you, you're not allowed"
4. `409 Conflict` is the natural fit for business-rule violations like "no copies available"
5. Centralize all exception → status-code mapping in one `@RestControllerAdvice` — one consistent error shape everywhere
6. A `500` in logs should be rare and always worth investigating — it means a bug, not a normal client error

---




[[Java]]
[[Networking]]
[[0 - Spring Framework]]