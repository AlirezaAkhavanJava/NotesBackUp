

We've covered requirements, domain modeling, and a few implementation details (`UUID`, `Instant`). Now let's zoom out to the big picture: **how do you organize all the pieces into a coherent, maintainable project?** This is the architecture layer — the "shape" your codebase takes before you write a single class.

---

## 1. The Core Idea — Separation of Concerns

Every layered architecture exists to answer one question: **when something changes, how much of the codebase breaks?**

If your database schema changes and your REST API code breaks too, your architecture has a problem — those two things should be independent. Good architecture draws boundaries so that changes in one area (UI, business rules, persistence) don't ripple everywhere else.

---

## 2. The Standard Spring Boot Layering (start here)

This is the architecture almost every Spring Boot tutorial teaches, and what you should master first before anything fancier:

```
┌─────────────────────────────────────┐
│           Controller Layer          │  ← handles HTTP, talks in DTOs
├─────────────────────────────────────┤
│            Service Layer            │  ← business logic, orchestration
├─────────────────────────────────────┤
│          Repository Layer           │  ← data access (Spring Data JPA)
├─────────────────────────────────────┤
│         Domain / Entity Layer       │  ← the "things" (Book, Loan, Member)
└─────────────────────────────────────┘
                   │
                   ▼
              Database
```

### The golden rule: dependencies point **downward only**

- Controller → depends on → Service
- Service → depends on → Repository
- Repository → depends on → Domain (entities)
- **Never the reverse.** A `Book` entity should never know a `BookController` exists.

This is the single most important architecture rule to internalize. If you ever find yourself importing something from `controller` inside your `service` package, that's a sign the architecture is inverted and something's wrong.

### What belongs in each layer

**Controller** — thin, no logic:

```java
@RestController
@RequestMapping("/loans")
@RequiredArgsConstructor
public class LoanController {
    private final LoanService loanService;

    @PostMapping
    public LoanDto borrow(@RequestBody BorrowRequest request) {
        return loanService.borrowBook(request.memberId(), request.bookId());
    }
}
```

**Service** — the actual business rules (remember our Use Case steps from earlier — this is where they live):

```java
@Service
@RequiredArgsConstructor
public class LoanService {
    private final LoanRepository loanRepository;
    private final BookRepository bookRepository;
    private final MemberRepository memberRepository;

    public LoanDto borrowBook(UUID memberId, UUID bookId) {
        // FR2: check active loan count < 3
        // FR6: check available copies > 0
        // create Loan, decrement copies
    }
}
```

**Repository** — pure data access, no logic:

```java
public interface LoanRepository extends JpaRepository<Loan, UUID> {
    List<Loan> findByMemberIdAndStatus(UUID memberId, LoanStatus status);
}
```

**Domain/Entity** — the business objects, as we covered in the Domain Overview tutorial.

---

## 3. Package Structure — Putting Layers Into Folders

We touched on this before (package-by-layer vs. package-by-feature). Here's the fuller picture with all layers included:

### Package-by-layer (good for learning, small apps)

```
com.example.library
├── controller/
│   ├── BookController.java
│   ├── LoanController.java
│   └── MemberController.java
├── service/
│   ├── BookService.java
│   ├── LoanService.java
│   └── MemberService.java
├── repository/
│   ├── BookRepository.java
│   ├── LoanRepository.java
│   └── MemberRepository.java
├── domain/
│   ├── Book.java
│   ├── Loan.java
│   └── Member.java
├── dto/
│   ├── BookDto.java
│   └── LoanDto.java
└── exception/
    ├── BookNotFoundException.java
    └── GlobalExceptionHandler.java
```

### Package-by-feature (better once the app grows)

```
com.example.library
├── book/
│   ├── Book.java
│   ├── BookController.java
│   ├── BookService.java
│   ├── BookRepository.java
│   └── BookDto.java
├── loan/
│   ├── Loan.java
│   ├── LoanController.java
│   ├── LoanService.java
│   ├── LoanRepository.java
│   └── LoanDto.java
├── member/
│   └── ...
└── shared/
    ├── exception/
    └── config/
```

**Practical rule of thumb:** start package-by-layer while you're learning — it's easier to reason about and matches how tutorials teach concepts. Migrate to package-by-feature once you have 5+ entities or multiple people working on the codebase simultaneously (fewer merge conflicts, clearer ownership).

---

## 4. A Layer We Haven't Covered Yet: The Mapper

As your app grows, converting between `Entity` ↔ `DTO` by hand in the service gets messy. A dedicated **mapper** keeps that translation logic isolated:

```java
@Component
public class LoanMapper {
    public LoanDto toDto(Loan loan) {
        return new LoanDto(
            loan.getId(),
            loan.getBook().getTitle(),
            loan.getDueDate(),
            loan.getStatus()
        );
    }
}
```

Or, once you're comfortable, use **MapStruct** to generate this code for you at compile time — worth knowing exists, not something to reach for on day one.

Where it lives: `mapper/` package, or inside each feature folder if using package-by-feature.

---

## 5. Configuration Layer

Every Spring Boot app also needs a place for cross-cutting setup — not tied to any one feature:

```
com.example.library
└── config/
    ├── JpaAuditingConfig.java     (the @EnableJpaAuditing from last time)
    ├── SecurityConfig.java
    └── OpenApiConfig.java
```

These are `@Configuration` classes — infrastructure concerns, not business logic, so they get their own space rather than living inside a feature folder.

---

## 6. A Step Beyond: Hexagonal / Clean Architecture (know it exists)

The layered architecture above is simple, but it has a subtle flaw: your **domain/service layer directly depends on Spring Data JPA** (via `JpaRepository`). That means your core business logic is coupled to a specific persistence technology.

**Hexagonal Architecture** (a.k.a. Ports & Adapters) fixes this by inverting the dependency:

```
                 ┌─────────────────────────┐
                 │      Domain / Core       │   ← no framework dependencies at all
                 │  (business logic, rules) │
                 └───────────┬─────────────┘
                              │ defines interfaces ("ports")
              ┌───────────────┴───────────────┐
              ▼                                ▼
    ┌───────────────────┐          ┌──────────────────────┐
    │  REST Controller    │          │   JPA Repository       │
    │   (adapter, "in")    │          │   (adapter, "out")      │
    └───────────────────┘          └──────────────────────┘
```

The domain defines an interface (`LoanRepositoryPort`), and the **infrastructure layer implements it** using Spring Data JPA. The domain never imports `jakarta.persistence` or Spring at all — meaning you could swap the database technology entirely without touching business logic.

```java
// In the domain layer — pure interface, no Spring/JPA imports
public interface LoanRepositoryPort {
    Loan save(Loan loan);
    Optional<Loan> findById(UUID id);
}

// In the infrastructure layer — the actual Spring Data implementation
@Repository
public interface LoanJpaRepository extends JpaRepository<LoanEntity, UUID>, LoanRepositoryPort {
    // adapts LoanEntity <-> Loan domain object
}
```

**Should you use this now?** Honestly — no, not yet. It adds real complexity (more interfaces, more mapping, more files) that pays off mainly in large, long-lived, team-maintained systems. Learn the standard layered architecture solidly first. I'm flagging hexagonal architecture so you recognize the term and the problem it solves when you encounter it later — not as something to apply to a learning project today.

---

## 7. Putting It All Together — Full Project Tree

Here's a realistic, complete structure for our Library app using the standard layered approach:

```
com.example.library
├── LibraryApplication.java
├── book/
│   ├── Book.java
│   ├── BookController.java
│   ├── BookService.java
│   ├── BookRepository.java
│   ├── BookDto.java
│   └── BookMapper.java
├── loan/
│   ├── Loan.java
│   ├── LoanStatus.java
│   ├── LoanController.java
│   ├── LoanService.java
│   ├── LoanRepository.java
│   ├── LoanDto.java
│   └── LoanMapper.java
├── member/
│   └── ... (same pattern)
├── shared/
│   ├── exception/
│   │   ├── BookNotFoundException.java
│   │   └── GlobalExceptionHandler.java
│   └── config/
│       ├── JpaAuditingConfig.java
│       └── OpenApiConfig.java
└── resources/
    └── application.properties
```

---

## Quick summary

1. **Dependencies flow one direction only**: Controller → Service → Repository → Domain
2. Controllers stay thin, Services hold business logic, Repositories are pure data access
3. Start with **package-by-layer**; move to **package-by-feature** as the app grows
4. Cross-cutting setup (`@Configuration`, exception handling) lives in a `shared/` or `config/` package
5. **Hexagonal architecture** exists for decoupling domain from framework — good to know, overkill for now

---

Want to actually scaffold this full project structure as real files — a working Spring Boot Maven/Gradle project with the Library domain wired up end-to-end, ready to run on your Debian machine?



[[Java]]
[[0 - Spring Framework]]