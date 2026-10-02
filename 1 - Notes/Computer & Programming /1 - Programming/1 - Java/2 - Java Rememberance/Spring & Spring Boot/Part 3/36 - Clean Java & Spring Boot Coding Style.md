

I'll teach you the style most professional Spring Boot codebases converge on: a mix of **Google's Java Style Guide** conventions (formatting) + **idiomatic Spring Boot** patterns (architecture) + a few **Effective Java** principles (object design). This is what you'll see in most real-world repos and what recruiters/reviewers expect.

Let's build it up piece by piece.

---

## 1. Naming Conventions

The foundation of readable code. Get this right and half your battle is won.

|Element|Convention|Example|
|---|---|---|
|Class / Interface|`PascalCase`, noun|`BookService`, `Repository`|
|Method / variable|`camelCase`, verb for methods|`findById()`, `totalPrice`|
|Constant|`UPPER_SNAKE_CASE`|`MAX_RETRY_COUNT`|
|Package|all lowercase, no underscores|`com.example.bookstore.service`|
|Boolean variable/method|reads like a question|`isActive`, `hasPermission()`|

**Bad:**

```java
public class bookservice {
    private int Max_Books = 10;
    public boolean check() { ... }
}
```

**Good:**

```java
public class BookService {
    private static final int MAX_BOOKS = 10;
    public boolean isAvailable() { ... }
}
```

---

## 2. Package-by-Feature, Not Package-by-Layer

This is the biggest style decision in a Spring Boot app. Two common approaches:

**Package-by-layer** (what beginners default to):

```
com.example.bookstore
├── controller/
├── service/
├── repository/
└── domain/
```

**Package-by-feature** (cleaner at scale, preferred in mature codebases):

```
com.example.bookstore
├── book/
│   ├── Book.java
│   ├── BookController.java
│   ├── BookService.java
│   └── BookRepository.java
├── order/
│   ├── Order.java
│   ├── OrderController.java
│   └── OrderService.java
```

**Why it's cleaner:** everything related to "Book" lives together. When a feature grows or gets deleted, you touch one folder instead of hunting across four.

_Start with package-by-layer while learning — it maps directly to concepts you're studying. Switch to package-by-feature once your app grows past ~5 entities._

---

## 3. Constructor Injection Only (never field injection)

This is a Spring-specific rule almost every style guide agrees on.

**Bad — field injection:**

```java
@Service
public class BookService {
    @Autowired
    private BookRepository bookRepository;
}
```

**Good — constructor injection:**

```java
@Service
public class BookService {
    private final BookRepository bookRepository;

    public BookService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }
}
```

**Why:**

- `final` fields → guaranteed immutability, no accidental reassignment
- Makes dependencies explicit and testable (easy to pass mocks in unit tests without Spring)
- If a class needs 6 constructor params, that's a smell telling you the class does too much

**Even cleaner with Lombok** (once you're comfortable with plain Java):

```java
@Service
@RequiredArgsConstructor   // Lombok generates the constructor for you
public class BookService {
    private final BookRepository bookRepository;
}
```

---

## 4. Keep Controllers Thin

Controllers should only: accept the request, call a service, return a response. No business logic.

**Bad:**

```java
@RestController
public class BookController {
    @GetMapping("/books/{id}")
    public Book getBook(@PathVariable Long id) {
        Book book = bookRepository.findById(id).orElseThrow();
        if (book.getPrice().compareTo(new BigDecimal("100")) > 0) {
            book.setDiscount(0.1); // business logic leaking into controller!
        }
        return book;
    }
}
```

**Good:**

```java
@RestController
@RequestMapping("/books")
@RequiredArgsConstructor
public class BookController {
    private final BookService bookService;

    @GetMapping("/{id}")
    public BookDto getBook(@PathVariable Long id) {
        return bookService.findById(id);
    }
}
```

All the discount logic belongs in `BookService`, not the controller.

---

## 5. Use DTOs — Don't Expose Entities Directly

We touched on this before. It's a real style rule, not just theory.

```java
// Entity — internal, maps to DB
@Entity
public class Book {
    @Id @GeneratedValue
    private Long id;
    private String title;
    private String internalNotes; // shouldn't leak to API!
}

// DTO — what the client actually sees
public record BookDto(Long id, String title) {}
```

Use a mapper (manual, or a library like MapStruct) to convert between them in the service layer.

---

## 6. Prefer `Optional` Over Null Returns (in the right places)

```java
// Repository layer
Optional<Book> findById(Long id);

// Service layer — decide what "not found" means
public BookDto findById(Long id) {
    Book book = bookRepository.findById(id)
        .orElseThrow(() -> new BookNotFoundException(id));
    return toDto(book);
}
```

Don't overuse `Optional` for fields or method parameters — it's meant for return types that might be absent.

---

## 7. Custom Exceptions + Global Exception Handling

Don't scatter `try/catch` everywhere. Centralize error handling.

```java
public class BookNotFoundException extends RuntimeException {
    public BookNotFoundException(Long id) {
        super("Book not found with id: " + id);
    }
}

@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BookNotFoundException.class)
    public ResponseEntity<String> handleNotFound(BookNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }
}
```

This keeps controllers and services clean of error-formatting logic.

---

## 8. Formatting Rules (the mechanical stuff)

- 4-space indentation, no tabs
- Opening brace on the same line (`if (x) {`, not on its own line)
- One statement per line
- Max line length ~100–120 chars
- Blank line between logical blocks inside a method
- Import order: no wildcard imports (`import java.util.*;` ❌)

Most teams don't enforce this by hand — they use a formatter:

```bash
# Add to your project — google-java-format or Spotless
mvn spotless:apply
```

---

## Quick summary you can apply immediately

1. Constructor injection, `final` fields
2. Thin controllers, logic lives in services
3. DTOs at the API boundary, entities stay internal
4. Package-by-feature once the project grows
5. Custom exceptions + `@RestControllerAdvice`
6. Consistent naming (`PascalCase`/`camelCase`/`UPPER_SNAKE_CASE`)
7. Auto-format with a tool, don't debate spacing manually




[[Java]]
[[0 - Spring Framework]]