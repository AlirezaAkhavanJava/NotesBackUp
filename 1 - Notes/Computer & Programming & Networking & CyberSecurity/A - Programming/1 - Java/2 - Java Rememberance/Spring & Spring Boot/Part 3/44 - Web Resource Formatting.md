

We touched on resource naming briefly in the REST API overview. This topic deserves its own tutorial, because getting URL formatting right (or wrong) is one of the most visible signs of API quality — it's the first thing another developer judges when they look at your API.

---

## 1. The Core Principle

A URL identifies a **resource** — a noun. Everything about formatting flows from that one idea: **the URL is an address, not an instruction.**

```
✅ /books/{id}        → "the book with this id"
❌ /getBookById/{id}   → this is a function call, not a resource address
```

---

## 2. Casing Convention

REST APIs overwhelmingly use **lowercase with hyphens** (`kebab-case`) for URL paths — never camelCase, snake_case, or PascalCase in the path itself.

```
✅ /loan-history
✅ /overdue-books

❌ /loanHistory
❌ /loan_history
❌ /LoanHistory
```

**Why hyphens over underscores:** URLs are case-insensitive-adjacent in some contexts, and hyphens are more universally readable in browsers and SEO tools. This is a near-universal convention across REST APIs — Stripe, GitHub, Twitter/X all use it.

_Note: this is just for the URL path. JSON body field names use `camelCase`, matching Java convention — we'll cover that below._

---

## 3. Pluralization — Collections vs. Single Resources

Already mentioned in the last tutorial, but let's formalize the pattern:

|Pattern|Meaning|Example|
|---|---|---|
|`/books`|Collection of Book resources|`GET /books` → list all|
|`/books/{id}`|One specific Book|`GET /books/{id}` → one book|
|`/books/{id}/copies`|Sub-collection belonging to a Book|`GET /books/{id}/copies`|

**Always plural, always consistent** — don't mix `/book/{id}` in one endpoint and `/books` in another. Pick plural everywhere and never deviate.

---

## 4. Nesting Resources — How Deep Is Too Deep

Nesting expresses **ownership/relationship** between resources. Back to our Library domain:

```
GET /members/{memberId}/loans        → loans belonging to this member
GET /books/{bookId}/copies           → copies of this book
```

**Rule of thumb: nest one level deep, maximum two.** Beyond that, flatten and use query parameters instead:

```
✅ GET /loans?bookId={bookId}&status=OVERDUE

❌ GET /members/{memberId}/loans/{loanId}/book/{bookId}/copies/{copyId}
```

Deep nesting looks "correct" on paper but becomes painful in practice — the URL becomes fragile (every level must exist and match), hard to construct client-side, and awkward to unit test. If a resource can be addressed on its own (`/loans/{loanId}`), prefer that over deep nesting.

**A practical guideline:** nest only when the child resource _cannot exist independently_ of the parent in your domain. A `Copy` only makes sense in relation to a `Book`, so `/books/{id}/copies` is justified. A `Loan` has its own identity and lifecycle (it can be queried, cancelled, returned on its own) — so `/loans/{id}` directly is usually better than always requiring the member/book prefix.

---

## 5. Query Parameters — Filtering, Sorting, Pagination, Searching

Query parameters modify _how_ you view a collection — they never identify a new resource.

### Filtering

```
GET /books?author=Bloch
GET /loans?status=OVERDUE&memberId={id}
```

### Sorting

```
GET /books?sort=title,asc
GET /books?sort=publishedDate,desc
```

### Pagination

```
GET /books?page=0&size=20
```

Spring Boot maps this straight into a `Pageable` parameter, as we saw before:

```java
@GetMapping
public Page<BookDto> getAll(
    @RequestParam(required = false) String author,
    Pageable pageable
) {
    return bookService.findAll(author, pageable);
}
```

### Searching (free text)

```
GET /books/search?q=effective+java
```

A dedicated `/search` sub-path is a common, accepted exception to "no verbs in URLs" — searching isn't quite CRUD, so many APIs (GitHub, Stripe) carve out `/search` as a pragmatic special case.

---

## 6. JSON Body Formatting — `camelCase`, Consistent Structure

While the **URL path** uses kebab-case, the **JSON body** uses `camelCase` — matching Java field naming, and what Jackson (Spring Boot's default JSON library) produces automatically from your DTOs with zero configuration:

```json
{
  "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "bookTitle": "Effective Java",
  "dueDate": "2026-10-07",
  "isOverdue": false
}
```

```java
public record LoanDto(
    UUID id,
    String bookTitle,
    LocalDate dueDate,
    boolean isOverdue
) {}
```

No manual mapping needed — Jackson converts `bookTitle` (Java field) → `"bookTitle"` (JSON key) automatically, because both already follow camelCase.

**A note on booleans:** name them as a question/predicate — `isOverdue`, `hasCopiesAvailable` — never bare adjectives like `overdue: true`. This matches the boolean naming rule from our coding style tutorial, and it's consistent all the way from Java field → JSON key → API consumer reading it.

---

## 7. Date & Time Formatting — Always ISO 8601

We covered `Instant` and `LocalDate` in Java terms already. In JSON, both should always serialize as **ISO 8601** — Spring Boot's default, no config needed:

```json
{
  "loanDate": "2026-09-23T14:32:07.123456Z",   // Instant → full UTC timestamp
  "dueDate": "2026-10-07"                       // LocalDate → date only
}
```

Never format dates as `"09/23/2026"` or any locale-specific string in an API response — ISO 8601 is unambiguous across every timezone, locale, and consuming client.

---

## 8. Response Envelope — Flat vs. Wrapped

Two common styles for structuring a _collection_ response:

**Flat array (simple, common for small APIs):**

```json
[
  { "id": "...", "title": "Effective Java" },
  { "id": "...", "title": "Clean Code" }
]
```

**Wrapped with metadata (needed once pagination enters the picture):**

```json
{
  "content": [
    { "id": "...", "title": "Effective Java" }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 137,
  "totalPages": 7
}
```

Spring Boot's `Page<T>` return type produces exactly this wrapped shape automatically — which is why `Pageable` is the idiomatic way to handle any collection endpoint that could grow large, rather than always returning a flat array.

---

## 9. Error Response Formatting — Be Consistent

Just like success responses, errors need a predictable shape every consumer can rely on. A common, simple convention:

```json
{
  "status": 404,
  "error": "Not Found",
  "message": "Book not found with id: 9b1deb4d-3b7d-...",
  "timestamp": "2026-09-23T14:32:07Z",
  "path": "/books/9b1deb4d-3b7d-..."
}
```

```java
public record ErrorResponse(
    int status,
    String error,
    String message,
    Instant timestamp,
    String path
) {}
```

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BookNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(BookNotFoundException ex, HttpServletRequest request) {
        ErrorResponse error = new ErrorResponse(
            404, "Not Found", ex.getMessage(), Instant.now(), request.getRequestURI()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
}
```

Every error your API returns — validation failures, not-found, conflicts — should use this _same_ shape. A frontend developer should be able to write one error-handling function that works for every endpoint.

_There's an actual web standard for this — [RFC 7807 "Problem Details for HTTP APIs"](https://www.rfc-editor.org/rfc/rfc7807) — and Spring Boot 3 supports it natively via `ProblemDetail`. Worth knowing it exists; the hand-rolled version above is perfectly fine while learning._

---

## 10. Versioning URLs (a preview)

As your API evolves, you'll eventually need to change a resource's shape without breaking existing clients. The most common convention is a version prefix:

```
/api/v1/books
/api/v2/books
```

Not something to worry about on a learning project, but worth recognizing when you see `/v1/` or `/v2/` in real-world API URLs — that's what it means.

---

## Quick Reference Cheat Sheet

|Element|Convention|Example|
|---|---|---|
|URL path|lowercase, kebab-case, plural nouns|`/loan-history`, `/books`|
|Path params|resource IDs only|`/books/{id}`|
|Query params|filtering/sorting/pagination|`?author=Bloch&page=0`|
|JSON keys|camelCase|`"bookTitle"`, `"isOverdue"`|
|Dates/times|ISO 8601|`"2026-10-07"`, `"2026-09-23T14:32:07Z"`|
|Booleans|question form|`isOverdue`, `hasCopies`|
|Errors|consistent shape everywhere|`{status, error, message, timestamp, path}`|
|Nesting|max 1–2 levels, only for true ownership|`/members/{id}/loans`|

---




[[Java]]
[[Networking]]
[[0 - Spring Framework]]