

## 1. What a UUID Is

**UUID** = **U**niversally **U**nique **ID**entifier. It's a 128-bit value, usually shown as a 36-character string:

```
550e8400-e29b-41d4-a716-446655440000
```

The key property: it's **generated in a way that makes collisions astronomically unlikely**, even across different machines, databases, and services — with no central coordinator handing out numbers. Compare that to auto-incrementing integers (`1, 2, 3...`), which only guarantee uniqueness _within a single table on a single database_.

---

## 2. Why You'd Use a UUID Instead of an Auto-Increment `Long id`

This connects directly to the domain modeling we've been doing — an entity's `id` is a design decision, not just a technical afterthought.

### Reason 1 — No central authority needed

With `@GeneratedValue(strategy = GenerationType.IDENTITY)`, the _database_ hands out the next number. That means:

- You can't know the ID before inserting the row
- Merging data from two databases (e.g., syncing offline mobile data back to a server) causes ID collisions — both had a "Book #5"

A UUID is generated **in your Java code**, before the row even touches the database. No coordination needed, ever.

### Reason 2 — Security / obscurity

Auto-increment IDs leak information:

```
GET /api/orders/1042
```

An attacker instantly knows: order volume, growth rate, and can enumerate every order by incrementing the number (`1041`, `1043`...). A UUID in the URL reveals nothing:

```
GET /api/orders/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d
```

### Reason 3 — Safe for distributed systems

If your `Loan` entities are ever created client-side (e.g., a mobile app creates a loan record while offline, then syncs later), a UUID means the ID is already correct and permanent the moment it's created — no risk of two offline devices both generating "Loan #7."

### The tradeoffs (be honest about these — don't cargo-cult UUIDs everywhere)

||`Long` (auto-increment)|`UUID`|
|---|---|---|
|Size|8 bytes|16 bytes (2x storage, bigger indexes)|
|Readability|Easy to read/type/debug|Ugly in logs, hard to eyeball|
|DB index performance|Sequential → very index-friendly|Random → can fragment indexes (matters at large scale)|
|Uniqueness scope|Single table/DB|Global|
|Exposure risk|Leaks business info|Opaque|

**Rule of thumb:** use `UUID` for entities that are:

- Exposed in public APIs/URLs
- Created in distributed or offline contexts
- Merged across systems (e.g., microservices)

Use plain `Long` for purely internal entities where none of the above applies and you want simplicity + index performance.

---

## 3. How to Use UUID in a Spring Boot / JPA Entity

### Basic entity field

```java
import java.util.UUID;
import jakarta.persistence.*;

@Entity
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)  // Hibernate 6+ generates it for you
    private UUID id;

    private String title;
    private String author;
    private String isbn;

    // getters, setters / or use a record-style constructor
}
```

`GenerationType.UUID` was added in **Hibernate 6** (Spring Boot 3+). Before that, people did it manually:

```java
@Id
private UUID id = UUID.randomUUID();
```

or via a `@PrePersist` hook:

```java
@PrePersist
public void generateId() {
    if (id == null) {
        id = UUID.randomUUID();
    }
}
```

### Repository — barely changes

```java
public interface BookRepository extends JpaRepository<Book, UUID> {
    // JpaRepository<Entity, IdType> — just swap Long for UUID
}
```

### Controller — path variable becomes UUID

```java
@RestController
@RequestMapping("/books")
@RequiredArgsConstructor
public class BookController {
    private final BookService bookService;

    @GetMapping("/{id}")
    public BookDto getBook(@PathVariable UUID id) {
        return bookService.findById(id);
    }
}
```

Spring automatically converts the URL string `9b1deb4d-3b7d-...` into a `UUID` object — no extra parsing code needed.

### Database column type

Depending on your DB:

- **PostgreSQL** has a native `UUID` column type — most efficient
- **MySQL/MariaDB** has no native UUID type — Hibernate stores it as `BINARY(16)` or `CHAR(36)`, which is why PostgreSQL is usually preferred when UUIDs are central to your design

---

## 4. Applying This to Our Library Domain

Revisiting the glossary from the Domain Overview:

- `Book`, `Member` → good candidates for `UUID` if you'll ever expose them via a public API (`GET /books/{id}`) — which you will.
- `Loan` → also a good candidate, especially since a future mobile/offline scenario (a member requesting a hold while offline, syncing later) benefits from client-generatable IDs.

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
    private LocalDate returnDate;

    @Enumerated(EnumType.STRING)
    private LoanStatus status; // ACTIVE, RETURNED, OVERDUE
}
```

---

## 5. One More Practical Note — UUID Versions

Not all UUIDs are generated the same way. You'll see this mentioned in docs:

|Version|How it's generated|Use case|
|---|---|---|
|**v4**|Fully random|Default — what `UUID.randomUUID()` and Hibernate's `GenerationType.UUID` produce|
|**v7**|Time-ordered + random|Newer, solves the "random UUIDs fragment DB indexes" problem — sortable by creation time, better for primary keys at scale|

`UUID.randomUUID()` in plain Java only produces **v4**. If you care about index performance with UUIDs (real concern at scale), libraries like `com.github.f4b6a3:uuid-creator` give you v7 generation — worth knowing exists, not something to worry about yet while learning.

---

## Quick summary

1. Use `UUID` when IDs are exposed publicly, created client-side, or merged across systems
2. Use plain `Long` for simple, purely internal entities — it's faster on indexes and easier to debug
3. In Spring Boot 3+/Hibernate 6+: `@GeneratedValue(strategy = GenerationType.UUID)` — that's it
4. Repository and Controller generics just swap `Long` → `UUID`




[[Java]]
[[0 - Spring Framework]]