

We've mentioned "REST API" constantly in previous tutorials without formally defining it. Let's fix that — this is foundational to everything a Spring Boot backend does.

---

## 1. What REST Actually Is

**REST** = **RE**presentational **S**tate **T**ransfer. It's not a protocol or a library — it's an **architectural style** for designing networked APIs, defined by Roy Fielding in his 2000 doctoral dissertation. Spring Boot doesn't enforce REST; you _choose_ to follow REST conventions when you design your endpoints, and Spring Boot gives you the tools (`@RestController`, etc.) to do it easily.

The core idea: **resources** (nouns — `Book`, `Loan`, `Member`) are exposed over HTTP, and you manipulate them using standard HTTP verbs. No custom protocol, no special client needed — any HTTP client (browser, curl, Postman, mobile app) can talk to it.

---

## 2. The Six REST Constraints (know these, even briefly)

Fielding defined REST via constraints a system must follow to be "RESTful." You don't need to memorize these deeply, but recognizing them helps you understand _why_ REST APIs look the way they do:

|Constraint|Meaning|Practical effect|
|---|---|---|
|**Client-Server**|UI and backend are separate|Exactly the split from our last tutorial|
|**Statelessness**|Each request contains everything needed to process it — server holds no session between requests|This is why JWT tokens are sent on _every_ request, not stored server-side in a session|
|**Cacheability**|Responses declare whether they can be cached|`Cache-Control` headers|
|**Uniform Interface**|Consistent way to identify and manipulate resources|This is the big one — covered below|
|**Layered System**|Client doesn't need to know if it's talking directly to the server or through a proxy/gateway|Load balancers, API gateways can sit transparently in between|
|**Code on Demand** (optional)|Server can send executable code to the client|Rarely used in practice|

**Statelessness** is the one that most affects your Spring Boot code: it's _why_ you don't store "logged in user" in a server-side session in a typical REST API — every request must carry its own proof of identity (the JWT from last time).

---

## 3. The Uniform Interface — This Is What You Actually Design

This is the part you'll spend real time on. Four ideas:

### a) Resources are identified by URLs (nouns, not verbs)

A **resource** is a "thing" in your domain — remember our Domain Overview glossary? Each entity becomes a resource.

```
✅ GET /books              (a collection of Book resources)
✅ GET /books/{id}         (a single Book resource)
✅ GET /members/{id}/loans (Loans belonging to a Member — nested resource)

❌ GET /getAllBooks
❌ POST /createBook
❌ POST /books/delete/{id}
```

**The verb is never in the URL.** The HTTP method itself _is_ the verb. This trips up almost everyone coming from other styles (like RPC-style APIs) at first.

### b) HTTP methods map to actions (CRUD)

|HTTP Method|Action|Example|
|---|---|---|
|`GET`|Read (safe, no side effects)|`GET /books/{id}` — fetch one book|
|`POST`|Create|`POST /books` — create a new book|
|`PUT`|Replace entirely|`PUT /books/{id}` — replace all fields|
|`PATCH`|Partial update|`PATCH /books/{id}` — update just `title`|
|`DELETE`|Remove|`DELETE /books/{id}` — delete a book|

Mapped to our Library domain and the Spring Boot code you already know how to write:

```java
@RestController
@RequestMapping("/books")
@RequiredArgsConstructor
public class BookController {
    private final BookService bookService;

    @GetMapping
    public List<BookDto> getAll() {
        return bookService.findAll();
    }

    @GetMapping("/{id}")
    public BookDto getOne(@PathVariable UUID id) {
        return bookService.findById(id);
    }

    @PostMapping
    public BookDto create(@RequestBody CreateBookRequest request) {
        return bookService.create(request);
    }

    @PutMapping("/{id}")
    public BookDto update(@PathVariable UUID id, @RequestBody UpdateBookRequest request) {
        return bookService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable UUID id) {
        bookService.delete(id);
    }
}
```

### c) HTTP status codes communicate outcome (not just 200 for everything)

This is a very common beginner mistake — returning `200 OK` for every response and putting error info only in the JSON body. Real REST APIs use status codes meaningfully:

|Code|Meaning|When to use|
|---|---|---|
|`200 OK`|Success (GET, PUT, PATCH)|Standard successful read/update|
|`201 Created`|Resource created|Response to a successful `POST`|
|`204 No Content`|Success, nothing to return|Successful `DELETE`|
|`400 Bad Request`|Client sent invalid data|Failed validation|
|`401 Unauthorized`|No/invalid authentication|Missing or bad JWT|
|`403 Forbidden`|Authenticated, but not permitted|A Member trying to hit a Librarian-only endpoint|
|`404 Not Found`|Resource doesn't exist|`GET /books/{unknown-id}`|
|`409 Conflict`|State conflict|Borrowing a Book with 0 available copies|
|`500 Internal Server Error`|Unhandled server-side bug|Should be rare — means something wasn't caught|

In Spring Boot, you control this via `ResponseEntity` or exception handling (remember `@RestControllerAdvice` from the coding style tutorial):

```java
@PostMapping
public ResponseEntity<BookDto> create(@RequestBody CreateBookRequest request) {
    BookDto created = bookService.create(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}
```

```java
@ExceptionHandler(BookNotFoundException.class)
public ResponseEntity<ErrorResponse> handleNotFound(BookNotFoundException ex) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(new ErrorResponse(ex.getMessage()));
}
```

### d) Representations, not the resource itself

The client never gets your actual `Book` Java object or database row — it gets a **representation** of it, typically JSON. This is exactly why we use **DTOs** (from the coding style tutorial) — the DTO _is_ the REST representation, decoupled from your internal entity structure.

```json
GET /books/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d

{
  "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "title": "Effective Java",
  "author": "Joshua Bloch",
  "availableCopies": 2
}
```

---

## 4. Designing URLs Well — Practical Rules

A few conventions that separate a clean REST API from a messy one:

**Use plural nouns for collections:**

```
✅ /books
❌ /book
```

**Nest resources to express relationships, but don't go too deep:**

```
✅ GET /members/{memberId}/loans        (loans belonging to a member)
❌ GET /members/{memberId}/loans/{loanId}/book/{bookId}/author   (too deep — flatten it)
```

**Use query parameters for filtering, sorting, pagination — not new endpoints:**

```
✅ GET /books?author=Bloch
✅ GET /books?page=0&size=20
✅ GET /books?sort=title,asc

❌ GET /getBooksByAuthor?author=Bloch
```

Spring Boot supports pagination natively via `Pageable`:

```java
@GetMapping
public Page<BookDto> getAll(Pageable pageable) {
    return bookService.findAll(pageable);
}
```

Calling `GET /books?page=0&size=20&sort=title,asc` just works — Spring binds it automatically.

---

## 5. Where Our Use Case Maps to a REST Endpoint

Remember the "Borrow Book" use case from the Requirements tutorial? Here's how it becomes a REST endpoint, tying the whole pipeline together:

```
Use Case: Borrow Book
Actor: Member
Main flow: check loan limit → check availability → create Loan → decrement copies
```

Becomes:

```java
@PostMapping("/loans")
public ResponseEntity<LoanDto> borrow(@RequestBody BorrowRequest request) {
    LoanDto loan = loanService.borrowBook(request.memberId(), request.bookId());
    return ResponseEntity.status(HttpStatus.CREATED).body(loan);
}
```

```
POST /loans
{ "memberId": "...", "bookId": "..." }

→ 201 Created
{ "id": "...", "bookTitle": "Effective Java", "dueDate": "2026-10-07", "status": "ACTIVE" }
```

And the alternate flows (loan limit exceeded, book unavailable) map directly to error responses:

```
→ 409 Conflict
{ "error": "Borrow limit reached" }
```

This is the payoff of doing requirements/use-case work first — the REST API design falls out naturally instead of being guessed at.

---

## 6. REST vs. Alternatives (context, briefly)

Worth knowing these exist, so you recognize the terms:

|Style|What it is|When you'd meet it|
|---|---|---|
|**REST**|Resource-based, HTTP verbs, what we just covered|Default choice for most APIs, including what you're learning|
|**GraphQL**|Client specifies exactly which fields it wants, single endpoint|When clients need flexible, nested data-fetching|
|**gRPC**|Binary protocol, strongly typed, very fast|Service-to-service communication in microservices, not browser-facing|
|**SOAP**|XML-based, heavier, older enterprise standard|Legacy enterprise systems, rare in new projects|

For learning Spring Boot, REST is the right starting point — it's the industry default and what nearly every job/tutorial assumes.

---

## 7. Documenting Your REST API (a practical necessity)

Once you have real endpoints, you'll want a way to explore/test them without writing custom docs by hand. **springdoc-openapi** auto-generates interactive API docs from your controllers:

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.x.x</version>
</dependency>
```

Add that dependency, run your app, and visit `http://localhost:8080/swagger-ui.html` — every endpoint you've written appears automatically, testable right in the browser. This is what most teams use instead of Postman collections for day-to-day API exploration.

---

## Quick summary

1. **REST** = resources (nouns) + HTTP verbs (GET/POST/PUT/PATCH/DELETE) + status codes that mean something
2. URLs identify **things**, never actions — the HTTP method is the verb
3. Statelessness means no server-side session — this is why JWTs get sent on every request
4. DTOs are your REST **representations** — never expose entities directly
5. Use query params for filtering/sorting/pagination, not new endpoints
6. `springdoc-openapi` gives you free interactive API docs from your existing controllers

---




[[Java]]
[[Networking]]
[[0 - Spring Framework]]