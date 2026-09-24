

We touched layering in the Project Architecture tutorial at a high level. Let's now go deep on **each layer individually** — what belongs in it, what doesn't, the annotations that define it, and the rules that keep boundaries clean. This is the conceptual foundation every Spring Boot app sits on.

---

## 1. Why Layers Exist — The Underlying Principle

Every layer exists to answer one question: **if this concern changes, how much of my code breaks?**

- Change your database from PostgreSQL to MongoDB → only the **Repository/Persistence layer** should care
- Change your API from REST to GraphQL → only the **Controller/Presentation layer** should care
- Change a business rule (e.g., "3 book limit" → "5 book limit") → only the **Service layer** should care

Layering is how you physically enforce this separation in code, so a change in one place doesn't ripple everywhere. This is the same Separation of Concerns principle from the architecture tutorial — now let's examine each layer's actual responsibilities.

---

## 2. The Five Layers, In Full

```
┌──────────────────────────────────────────┐
│  1. Presentation Layer (Controller)         │  ← HTTP in, HTTP out
├──────────────────────────────────────────┤
│  2. Service Layer (Business Logic)            │  ← orchestration, rules
├──────────────────────────────────────────┤
│  3. Persistence Layer (Repository)              │  ← data access
├──────────────────────────────────────────┤
│  4. Domain Layer (Entities)                       │  ← the "things"
├──────────────────────────────────────────┤
│  5. Cross-Cutting (Config, Security, etc.)          │  ← spans all layers
└──────────────────────────────────────────┘
```

Let's take each one individually — its job, its annotations, and exactly what should _never_ leak into it.

---

## 3. Layer 1 — Presentation Layer (Controller)

### Responsibility

Translate HTTP requests into service calls, and service results back into HTTP responses. **Nothing more.**

### Key annotations

|Annotation|Purpose|
|---|---|
|`@RestController`|Marks a class as a controller returning JSON/data (not view names)|
|`@RequestMapping`|Base path for all endpoints in the class|
|`@GetMapping` / `@PostMapping` / `@PutMapping` / `@PatchMapping` / `@DeleteMapping`|Maps HTTP verbs to methods|
|`@PathVariable`|Extracts a value from the URL path (`/books/{id}`)|
|`@RequestParam`|Extracts a query parameter (`?author=Bloch`)|
|`@RequestBody`|Deserializes the JSON request body into a Java object|
|`@Valid`|Triggers Bean Validation on a `@RequestBody`|

```java
@RestController
@RequestMapping("/books")
@RequiredArgsConstructor
public class BookController {
    private final BookService bookService;

    @GetMapping("/{id}")
    public BookDto getOne(@PathVariable UUID id) {
        return bookService.findById(id);
    }

    @PostMapping
    public ResponseEntity<BookDto> create(@Valid @RequestBody CreateBookRequest request) {
        BookDto created = bookService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
}
```

### What must NEVER be in a controller

- Business rules (`if (loanCount >= 3) throw ...`) — belongs in Service
- Direct repository calls (`bookRepository.findById(...)`) — controller talks to Service only, never skips a layer
- Manual JSON parsing/building — Spring + Jackson handle this via `@RequestBody`/return values automatically

**The litmus test:** if you deleted your entire REST API and replaced it with a CLI tool or a message queue consumer tomorrow, the Service layer underneath should need **zero changes**. If moving to a different "front door" would force you to rewrite business logic, your layering has broken down.

---

## 4. Layer 2 — Service Layer (Business Logic)

### Responsibility

This is where your Use Cases (remember the Requirements Engineering tutorial) actually live in code. Orchestrates repositories, enforces business rules, coordinates multiple domain objects.

### Key annotations

|Annotation|Purpose|
|---|---|
|`@Service`|Marks a class as a Spring-managed business logic component|
|`@Transactional`|Wraps a method in a database transaction — all-or-nothing|
|`@RequiredArgsConstructor` (Lombok)|Generates the constructor for injected dependencies|

```java
@Service
@RequiredArgsConstructor
public class LoanService {
    private final LoanRepository loanRepository;
    private final BookRepository bookRepository;
    private final MemberRepository memberRepository;

    @Transactional
    public LoanDto borrowBook(UUID memberId, UUID bookId) {
        Member member = memberRepository.findById(memberId)
            .orElseThrow(() -> new MemberNotFoundException(memberId));
        Book book = bookRepository.findById(bookId)
            .orElseThrow(() -> new BookNotFoundException(bookId));

        long activeLoans = loanRepository.countByMemberIdAndStatus(memberId, LoanStatus.ACTIVE);
        if (activeLoans >= 3) {
            throw new BorrowLimitExceededException(memberId);
        }
        if (book.getAvailableCopies() <= 0) {
            throw new BookUnavailableException(book.getTitle());
        }

        book.decrementAvailableCopies();
        Loan loan = new Loan(member, book, LocalDate.now(), LocalDate.now().plusDays(14));
        return toDto(loanRepository.save(loan));
    }
}
```

### `@Transactional` — why it belongs specifically here

This is the layer where **multi-step operations that must succeed or fail together** live. `borrowBook` does two writes — decrementing `availableCopies` and saving a new `Loan`. If the second write failed after the first succeeded, you'd have a book marked unavailable with no corresponding loan record — data corruption. `@Transactional` guarantees both happen, or neither does.

**Why `@Transactional` belongs on the Service layer, not the Controller or Repository:** the Service is where you know the _full business operation's boundaries_ — a Repository method only knows about one table; a Controller only knows about one HTTP request. The Service is the only layer with the context to say "these three database operations are one atomic unit."

### What must NEVER be in a service

- HTTP concerns (`HttpServletRequest`, status codes, `@RequestBody`) — the service shouldn't know it's being called over HTTP at all
- Raw SQL or JPA query building — delegate to the Repository layer
- DTO-to-JSON serialization — that's Jackson's job, triggered automatically at the Controller boundary

---

## 5. Layer 3 — Persistence Layer (Repository)

### Responsibility

Pure data access. Get data in, get data out. No business rules, no orchestration.

### Key annotations / interfaces

|Element|Purpose|
|---|---|
|`JpaRepository<Entity, IdType>`|Base interface giving you `save()`, `findById()`, `findAll()`, `delete()` for free|
|`@Repository`|Marks a class as a data-access component (rarely needed explicitly — `JpaRepository` implementations get it automatically)|
|`@Query`|Custom JPQL/SQL when method-name derivation isn't enough|

```java
public interface LoanRepository extends JpaRepository<Loan, UUID> {

    // Derived query — Spring generates the SQL from the method name itself
    long countByMemberIdAndStatus(UUID memberId, LoanStatus status);

    List<Loan> findByMemberId(UUID memberId);

    // Custom query when method-name derivation gets unwieldy
    @Query("SELECT l FROM Loan l WHERE l.dueDate < :today AND l.status = 'ACTIVE'")
    List<Loan> findOverdueLoans(@Param("today") LocalDate today);
}
```

### Method-name query derivation — worth understanding, not just copying

Spring Data JPA parses your method **name** and builds the query automatically:

```
countByMemberIdAndStatus
   │        │        │
   count    memberId  status
   (aggregate)  (WHERE memberId = ?)  (AND status = ?)
```

This works remarkably well for straightforward queries. Once a query needs joins, subqueries, or complex conditions, drop to `@Query` with explicit JPQL, as shown above — trying to force complex logic into a method name becomes unreadable past 3-4 conditions.

### What must NEVER be in a repository

- Business rules (`if (activeLoans >= 3)`) — that's the Service layer's job; a repository just _answers_ "how many active loans does this member have," it doesn't _decide_ what to do with that number
- HTTP/DTO concerns — a repository only knows about entities, never DTOs

---

## 6. Layer 4 — Domain Layer (Entities)

### Responsibility

Represent the core business objects — what we built out fully in the Domain Overview and Domain Model tutorials.

### Key annotations

|Annotation|Purpose|
|---|---|
|`@Entity`|Marks a class as mapped to a database table|
|`@Id` / `@GeneratedValue`|Primary key definition|
|`@Column`|Customize column mapping (name, nullable, length)|
|`@ManyToOne` / `@OneToMany` / `@ManyToMany`|Relationships between entities|
|`@Enumerated`|How an enum is stored (usually `EnumType.STRING`)|

```java
@Entity
public class Loan {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    private Member member;

    @ManyToOne
    private Book book;

    private LocalDate loanDate;
    private LocalDate dueDate;

    @Enumerated(EnumType.STRING)
    private LoanStatus status;

    // A well-designed entity can hold simple, self-contained business logic
    public boolean isOverdue() {
        return status == LoanStatus.ACTIVE && LocalDate.now().isAfter(dueDate);
    }
}
```

### A nuance worth knowing — "anemic" vs "rich" domain models

Two schools of thought on how much logic belongs directly on entities:

- **Anemic model** (common in Spring apps): entities are almost pure data holders (getters/setters only); _all_ logic lives in the Service layer
- **Rich model** (more DDD-aligned): entities hold logic that's intrinsically about _themselves_ — like `isOverdue()` above, which only needs the entity's own fields — while cross-entity orchestration (checking loan limits across a Member's other Loans) still lives in the Service

**Practical guidance for now:** keep genuinely self-contained logic (checks using only that entity's own fields) on the entity itself — it's more object-oriented and testable in isolation. Keep anything that needs _other_ entities or repositories in the Service layer. Don't stress over getting this perfectly "pure" while learning; both styles are common in real Spring codebases.

### What must NEVER be in a domain entity

- Repository/database calls — an entity should never call `bookRepository.findById(...)` itself
- HTTP/DTO concerns
- Spring-specific annotations beyond JPA (`@Autowired` has no business inside an `@Entity`)

---

## 7. Layer 5 — Cross-Cutting Concerns

Some things don't belong to any _one_ layer — they apply across all of them. We've built several of these already across previous tutorials:

|Concern|Example from our tutorials|
|---|---|
|**Configuration**|`CorsConfig`, `JpaAuditingConfig`|
|**Exception Handling**|`GlobalExceptionHandler` (`@RestControllerAdvice`)|
|**Security**|Spring Security filters, JWT validation|
|**Mapping**|`BookMapper` (Entity ↔ DTO conversion)|
|**Auditing**|`@CreatedDate`/`@LastModifiedDate` from the `Instant` tutorial|

These typically live in a `shared/` or `config/` package (from our Project Architecture tutorial), precisely because they don't belong to any single feature or layer — they're infrastructure that every layer relies on.

---

## 8. The DTO — Not a Layer, But a Boundary

Worth being precise about this: **DTOs aren't a "layer" with their own logic** — they're the **data shape that crosses the boundary** between Controller and the outside world (and sometimes between Service and Controller).

```
Entity (Domain layer, internal)
   ↓  mapped by Service or Mapper
DTO (crosses the Controller ↔ client boundary)
```

```java
// Entity — internal, full detail, JPA-mapped
@Entity
public class Book {
    private UUID id;
    private String title;
    private String internalWarehouseCode;  // should never reach the client
}

// DTO — what actually crosses the boundary
public record BookDto(UUID id, String title) {}
```

This is why the DTO↔Entity mapping (via a `BookMapper` or done inline in the Service) is one of the most important boundary-crossing points in the whole architecture — it's your deliberate choice of _what the outside world is allowed to see_.

---

## 9. Full Request Flow — Every Layer Together

Let's trace one complete request through every layer, tying the whole series together:

```
POST /loans  { "memberId": "...", "bookId": "..." }
   │
   ▼
① LoanController.borrow()
   - deserializes @RequestBody into BorrowRequest
   - calls loanService.borrowBook(memberId, bookId)
   │
   ▼
② LoanService.borrowBook()  [@Transactional]
   - calls memberRepository.findById() → MemberNotFoundException if absent
   - calls bookRepository.findById() → BookNotFoundException if absent
   - calls loanRepository.countByMemberIdAndStatus() → business rule check
   - calls book.decrementAvailableCopies() → domain entity logic
   - calls loanRepository.save(loan)
   - maps Loan entity → LoanDto
   │
   ▼
③ LoanRepository (Spring Data JPA)
   - generates SQL, talks to PostgreSQL
   │
   ▼
④ Loan entity (Domain layer)
   - represents the row, enforces its own invariants (isOverdue(), etc.)
   │
   ▼
Back up through ② → ①
   - Service returns LoanDto
   - Controller wraps it: ResponseEntity.status(201).body(loanDto)
   │
   ▼
201 Created
{ "id": "...", "dueDate": "2026-10-07", "status": "ACTIVE" }

(If any exception was thrown along the way →
 GlobalExceptionHandler intercepts it → maps to the correct 4xx/5xx
 from our Response Codes tutorial)
```

Every layer we've built across this entire tutorial series slots into one coherent picture here — Requirements → Domain Overview → Domain Model → REST design → Response Codes → Error Representation, all converging into this one request's journey.

---

## 10. Testing Implications of Layering (why this pays off)

A well-layered app is dramatically easier to test, because each layer can be tested **in isolation**, without the others:

```java
// Test the Service layer alone — mock the repositories, no real DB needed
@ExtendWith(MockitoExtension.class)
class LoanServiceTest {
    @Mock private LoanRepository loanRepository;
    @Mock private BookRepository bookRepository;
    @InjectMocks private LoanService loanService;

    @Test
    void shouldRejectBorrowWhenLimitReached() {
        when(loanRepository.countByMemberIdAndStatus(any(), any())).thenReturn(3L);
        assertThrows(BorrowLimitExceededException.class,
            () -> loanService.borrowBook(memberId, bookId));
    }
}
```

No HTTP server, no real database, no Spring context needed to start up — just the pure business logic, tested directly. This is only possible _because_ the Service layer doesn't know or care about HTTP or SQL specifics — exactly the payoff of strict layering.

---

## Quick Reference Table

|Layer|Annotation(s)|Knows about|Never touches|
|---|---|---|---|
|Controller|`@RestController`, `@RequestMapping`|HTTP, DTOs|Repositories, business rules|
|Service|`@Service`, `@Transactional`|Business rules, orchestration|HTTP, SQL|
|Repository|`JpaRepository`, `@Query`|Entities, SQL/JPQL|DTOs, business rules|
|Domain/Entity|`@Entity`, `@Id`, relationships|Its own fields, self-contained logic|Repositories, HTTP|
|Cross-cutting|`@Configuration`, `@RestControllerAdvice`|Spans everything|—|

---

## Quick Summary

1. **Five layers**: Controller (HTTP) → Service (business logic + `@Transactional`) → Repository (data access) → Domain (entities) → Cross-cutting (config/security/mapping)
2. Dependencies flow **one direction only** — Controller → Service → Repository → Domain, never reversed, never skipped
3. `@Transactional` belongs on the Service layer — it's the only layer with full context of a business operation's boundaries
4. DTOs aren't a layer — they're the **boundary shape** between your internal Entities and the outside world
5. Strict layering is what makes each layer **independently testable** — mock the layer below, test business logic in complete isolation




[[Java]]
[[0 - Spring Framework]]
