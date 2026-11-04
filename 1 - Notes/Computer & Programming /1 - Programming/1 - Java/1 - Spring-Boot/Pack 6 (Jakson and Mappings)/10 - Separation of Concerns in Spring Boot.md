

## What it is

**Separation of Concerns** (SoC) is the principle of dividing a program into parts so that each part handles one kind of responsibility, and the parts reach into each other only through small, deliberate interfaces.

A _concern_ is a distinct responsibility in a program. In a web application, typical concerns are:

- Receiving HTTP requests and sending HTTP responses
- Enforcing business rules, such as "a book can't be borrowed if no copies are left"
- Reading and writing the database
- Validating and shaping the data that crosses the boundary between client and server
- Configuration, such as database URLs and API keys

SoC says each of these should live in its own place, with its own code, and that each place should know as little as possible about the others.

## Why it exists

Code that mixes these concerns is hard to change. When one controller parses HTTP, applies business rules, runs SQL, and builds the JSON response, every change touches everything. A small change to a business rule might require editing code that also handles HTTP status codes and SQL queries, and a mistake there can break unrelated behavior.

## The problems it solves

**1. Changes stay local.** If the database changes from PostgreSQL to MongoDB, only the data layer should change. If the business rule for borrowing changes, only the service layer should change.

**2. Code can be tested in isolation.** If your business logic is inside a controller, testing it requires starting a web server. If it lives in a plain service class, you can test it with a plain unit test that runs in milliseconds.

**3. Logic can be reused.** If the borrowing rule lives in a service, a REST endpoint, a scheduled job, and a command-line tool can all call the same code. If it lives in a controller, only HTTP can reach it.

**4. Internal details don't leak to clients.** If a controller returns your JPA entity directly, your database structure becomes part of your public API. Changing a column name then breaks clients.

## How Spring Boot supports it: the layers

Spring Boot doesn't force separation of concerns, but its annotations and conventions make it the natural way to write code. The most common structure is the **layered architecture**:

```
HTTP request
   │
   ▼
Controller      (web layer: HTTP in, HTTP out)
   │
   ▼
Service         (business layer: rules and decisions)
   │
   ▼
Repository      (data layer: reading and writing the database)
   │
   ▼
Database
```

Each layer has one job and talks only to the layer directly below it.

- **Controller**, annotated `@RestController`. It maps URLs to methods, extracts parameters, calls a service, and returns a response. It contains no business rules.
- **Service**, annotated `@Service`. It holds the business rules and coordinates work. It knows nothing about HTTP.
- **Repository**, an interface extending `JpaRepository`. Spring Data generates the database code for it. It contains no business rules.
- **Entity**, annotated `@Entity`. It maps a Java class to a database table.
- **DTO** (Data Transfer Object), usually a Java `record`. It defines the shape of data entering or leaving the API, separate from the entity.

## A bad version first

Here is a common beginner design, where one controller does everything:

```java
@RestController
@RequestMapping("/api/books")
public class BookController {

    @Autowired
    private JdbcTemplate jdbc;

    @PostMapping("/{id}/borrow")
    public ResponseEntity<String> borrow(@PathVariable Long id) {
        // HTTP concern: reading the path variable happens above

        // Data concern: raw SQL inside the controller
        List<Map<String, Object>> rows =
            jdbc.queryForList("SELECT * FROM books WHERE id = ?", id);

        if (rows.isEmpty()) {
            // Business concern mixed with HTTP concern
            return ResponseEntity.status(404).body("Book not found");
        }

        int copies = (Integer) rows.get(0).get("available_copies");

        // Business rule buried in a controller
        if (copies == 0) {
            return ResponseEntity.status(409).body("No copies left");
        }

        jdbc.update("UPDATE books SET available_copies = ? WHERE id = ?",
                    copies - 1, id);

        // Response built by hand as a String
        return ResponseEntity.ok("Borrowed. Remaining: " + (copies - 1));
    }
}
```

**What this code does:** it borrows a book. It looks up the book, checks whether copies remain, decrements the count, and returns a message.

**What's wrong with it:**

- The borrowing rule (`copies == 0` means refuse) can't be reused by anything except this HTTP endpoint.
- Testing the rule requires a running server and a database.
- The SQL is tied to this endpoint. If you need the same query elsewhere, you copy it.
- The response is a plain string, so clients can't parse it reliably.
- Two different concerns, "not found" and "no copies", are both expressed as HTTP status codes inside the business logic.

## The separated version

Now the same feature, split by concern. Each file has one job.

### 1. The entity (data representation)

```java
@Entity
@Table(name = "books")
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String author;
    private int availableCopies;

    protected Book() {
        // JPA requires a no-argument constructor
    }

    public Book(String title, String author, int availableCopies) {
        this.title = title;
        this.author = author;
        this.availableCopies = availableCopies;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getAuthor() { return author; }
    public int getAvailableCopies() { return availableCopies; }
    public void setAvailableCopies(int availableCopies) {
        this.availableCopies = availableCopies;
    }
}
```

**What this does:** it describes what a book looks like in the database. JPA turns this class into a `books` table and maps each field to a column. It has no logic about borrowing.

### 2. The repository (data access)

```java
public interface BookRepository extends JpaRepository<Book, Long> {
    List<Book> findByAuthorIgnoreCase(String author);
}
```

**What this does:** it gives you `findById`, `save`, `deleteById`, and others, without you writing any SQL. Spring generates the implementation at startup. The custom method `findByAuthorIgnoreCase` is derived from its name: Spring reads the name and builds the query. This layer only answers "how do I get and store books?"

### 3. The DTO (the API's shape)

```java
public record BorrowResponse(Long bookId, String title, int remainingCopies) {}
```

**What this does:** it defines the JSON the client receives. A `record` is an immutable class with a constructor and accessors generated automatically. Spring converts it to JSON. The entity can change internally without changing this contract with the client.

### 4. The exceptions (business errors, not HTTP errors)

```java
public class BookNotFoundException extends RuntimeException {
    public BookNotFoundException(Long id) {
        super("No book with id " + id);
    }
}

public class NoCopiesAvailableException extends RuntimeException {
    public NoCopiesAvailableException(String title) {
        super("No copies of '" + title + "' are available");
    }
}
```

**What this does:** the service reports _what went wrong in business terms_. It does not decide what HTTP status code to send. The controller or a global handler makes that translation.

### 5. The service (business rules)

```java
@Service
public class BookService {

    private final BookRepository bookRepository;

    public BookService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    @Transactional
    public BorrowResponse borrow(Long bookId) {
        Book book = bookRepository.findById(bookId)
            .orElseThrow(() -> new BookNotFoundException(bookId));

        if (book.getAvailableCopies() == 0) {
            throw new NoCopiesAvailableException(book.getTitle());
        }

        book.setAvailableCopies(book.getAvailableCopies() - 1);

        return new BorrowResponse(
            book.getId(),
            book.getTitle(),
            book.getAvailableCopies()
        );
    }
}
```

**What this does, step by step:**

1. It asks the repository for the book. If none exists, it throws a business exception.
2. It applies the rule: if no copies remain, it refuses.
3. It updates the count. Because the method is `@Transactional`, the change is saved as one unit when the method finishes successfully. If an exception occurs, the change is rolled back.
4. It returns a DTO describing the result.

Notice what is absent: no `HttpServletRequest`, no status codes, no SQL. This class could be called from a test, a scheduler, or a console app without modification.

Constructor injection (the `BookRepository` passed in the constructor) is the recommended style. It makes the dependency explicit and lets tests supply a fake repository.

### 6. The controller (HTTP translation)

```java
@RestController
@RequestMapping("/api/books")
public class BookController {

    private final BookService bookService;

    public BookController(BookService bookService) {
        this.bookService = bookService;
    }

    @PostMapping("/{id}/borrow")
    public ResponseEntity<BorrowResponse> borrow(@PathVariable Long id) {
        return ResponseEntity.ok(bookService.borrow(id));
    }
}
```

**What this does:** it maps `POST /api/books/{id}/borrow` to the service call. It extracts the `id` from the URL, delegates to the service, and wraps the result in a `200 OK` response. It contains no rules.

### 7. Translating errors to HTTP (one place for all controllers)

The controller above doesn't handle the exceptions. That is handled once, globally:

```java
@RestControllerAdvice
public class BookExceptionHandler {

    @ExceptionHandler(BookNotFoundException.class)
    public ResponseEntity<String> notFound(BookNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }

    @ExceptionHandler(NoCopiesAvailableException.class)
    public ResponseEntity<String> conflict(NoCopiesAvailableException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(ex.getMessage());
    }
}
```

**What this does:** when a service throws `BookNotFoundException` from any controller, Spring routes it here and returns a `404`. The service stays unaware of HTTP, and the HTTP mapping lives in exactly one place.

## Why this is testable

Because the service has no web or database dependencies in its logic, you can test it with a fake repository:

```java
class BookServiceTest {

    @Test
    void borrowingWithNoCopiesLeftIsRefused() {
        BookRepository repo = mock(BookRepository.class);
        Book book = new Book("Dune", "Herbert", 0);
        when(repo.findById(1L)).thenReturn(Optional.of(book));

        BookService service = new BookService(repo);

        assertThrows(NoCopiesAvailableException.class,
                     () -> service.borrow(1L));
    }
}
```

**What this does:** it creates a fake repository that returns a book with zero copies, then verifies the service refuses to lend it. No server starts, no database connects, and the test runs in milliseconds. This is the practical payoff of separation: the rule is testable on its own.

## Rules you'll apply in every project

- **Controllers** call services. They never call repositories and never contain `if` statements about business rules.
- **Services** contain business logic. They never reference `HttpServletRequest`, `ResponseEntity`, or HTTP status codes.
- **Repositories** contain data access only. Put business decisions in services, not in custom repository methods.
- **Entities never leave the service layer through the controller.** Return DTOs. Otherwise your database shape becomes your public API.
- **Exceptions express business meaning.** Map them to HTTP in one `@RestControllerAdvice`.
- **Inject dependencies through constructors**, as shown above.

## Going further

Once you're comfortable with these layers, you'll meet stricter versions of the same idea. **Hexagonal architecture** (also called ports and adapters) makes the domain code independent of Spring and the database entirely, with interfaces for everything external. **Domain-Driven Design** organizes code around business concepts rather than technical layers. Both are refinements of the principle you've just seen, and you'll be better placed to judge when to use them once the layered version feels natural.




[[Spring Framework]]