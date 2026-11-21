

## The rule

**Mapping happens in the service layer, at the point where data crosses between the outside world and the database.** The controller passes request data in and returns whatever the service gives back. It does not convert entities to DTOs.

Mapping inbound (request DTO to entity) and outbound (entity to response DTO) both belong in the service, because the service is where the entity is loaded, changed, and saved, and where the transaction is open.

## Why not the controller

The controller is tempting because it looks like the place where "the response is built." But mapping there causes two problems.

**The service returns entities.** If the service returns a `Book`, the controller must map it, and now the controller depends on the entity's shape. Any code that calls the service gets a raw entity, which may expose fields or lazy relationships that were never meant to leave the business layer.

**Lazy loading fails or gets hidden.** Suppose the controller maps a `Book` whose `reviews` collection loads lazily:

```java
@GetMapping("/{id}")
public BookDetail get(@PathVariable Long id) {
    Book book = bookService.findEntity(id);   // transaction ends here
    return bookMapper.toDetail(book);          // getReviews() runs now
}
```

By the time the mapper calls `getReviews()`, the transaction has closed. Without help, this throws `LazyInitializationException`. Spring Boot hides this by default through **open-in-view** (`spring.jpa.open-in-view=true`), which keeps the database session alive for the whole HTTP request. The code appears to work, but every lazy access during mapping runs its own query, which is the N+1 problem we discussed earlier. The bug is still there, just invisible.

## Why not the repository

Repositories answer "how do I read and write rows?" They should not know about DTOs. If a repository method returns a `BookDetail`, the data layer has taken on presentation shape, and the same query can't serve two different response formats without duplication.

## Walking one request through the layers

Here is a create endpoint with mapping in the right places.

The request DTO defines what the client sends:

```java
public record CreateBookRequest(String title, String author, Genre genre, int copies) {}
```

The controller receives it, passes it to the service, and returns the result. It contains no mapping logic:

```java
@RestController
@RequestMapping("/api/books")
public class BookController {

    private final BookService bookService;

    public BookController(BookService bookService) {
        this.bookService = bookService;
    }

    @PostMapping
    public ResponseEntity<BookDetail> create(@Valid @RequestBody CreateBookRequest request) {
        BookDetail created = bookService.create(request);
        return ResponseEntity
                .created(URI.create("/api/books/" + created.id()))
                .body(created);
    }
}
```

The service converts the request into an entity, saves it, and converts the result back into a response DTO. Both conversions happen inside the transaction:

```java
@Service
public class BookService {

    private final BookRepository bookRepository;
    private final BookMapper bookMapper;

    public BookService(BookRepository bookRepository, BookMapper bookMapper) {
        this.bookRepository = bookRepository;
        this.bookMapper = bookMapper;
    }

    @Transactional
    public BookDetail create(CreateBookRequest request) {
        Book book = bookMapper.toEntity(request);   // inbound mapping
        Book saved = bookRepository.save(book);
        return bookMapper.toDetail(saved);          // outbound mapping
    }
}
```

The mapper needs a method for the inbound direction. The `id` must be ignored so the database assigns it:

```java
@Mapper(componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.ERROR)
public interface BookMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "availableCopies", source = "copies")
    Book toEntity(CreateBookRequest request);

    @Mapping(source = "availableCopies", target = "remainingCopies")
    BookDetail toDetail(Book book);
}
```

**What to notice:** the controller knows only HTTP and the request and response types. The service knows the business flow and the transaction. The mapper knows the field correspondences. Each layer changes for a different reason.

## The one legitimate exception

The controller may decide things about the HTTP response: the status code, headers such as `Location`, or adding links for clients. These concern how the response is delivered, not what its data contains. Mapping data fields still belongs in the service.

## A useful habit

Set `spring.jpa.open-in-view=false` in `application.properties`. When it's off, a lazy access outside a transaction throws an exception right away instead of silently running queries. That exception shows you exactly where your mapping needs to move into the service, which is the place you want it anyway.

## Exercise

Add an `updateCopies` endpoint that accepts a new count. Decide, before writing any code, which layer will check that the book exists, which will map the response, and which will return an HTTP 404 if it doesn't. Then write the code and check that your controller contains no `if` statements about business rules and no calls to a mapper.


[[Spring Framework]]