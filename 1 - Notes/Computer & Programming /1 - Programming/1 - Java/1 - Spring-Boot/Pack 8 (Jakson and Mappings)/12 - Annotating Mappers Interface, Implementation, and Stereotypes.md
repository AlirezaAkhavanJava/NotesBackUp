

For a hand-written mapper, you write an **interface** that declares the conversions, then an **implementation class** that does the work and carries `@Component`. Your service depends on the interface, and Spring supplies the implementation. With MapStruct, you write only the interface, and MapStruct generates the implementation and annotates it for you.

The rest of this lesson explains why each piece exists, so you can choose the right design for each situation.

## Why separate the interface from the implementation

A **contract** is the set of methods a class promises to provide. An **implementation** is the code that fulfils that promise. Separating them means the rest of your code depends only on the promise.

This solves three problems:

**Swapping behavior.** Today your mapper copies fields by hand. Next month you might switch to MapStruct, or a version that also reads a localized title. If the service depends on the interface, you replace one class and nothing else changes.

**Testing without the real thing.** A service test can pass a fake or mock mapper, which isolates the test from mapping details.

**Hiding details.** The interface tells a reader what the mapper does without showing how. The implementation's internals can change freely.

Interfaces are not required for every class. Many Spring projects skip them for simple services. For mappers, the interface is worth the extra file because mappers are exactly the kind of code you want to replace or fake.

## Step 1: The interface (the contract)

```java
public interface BookMapper {

    BorrowResponse toBorrowResponse(Book book);

    BookSummary toSummary(Book book);
}
```

**What this does:** it declares two conversions and nothing else. It has no annotations because it is not a Spring bean. Spring creates beans from concrete classes, not from interfaces.

Notice that the methods take entities and return DTOs. The interface describes direction and purpose, so anyone reading the service knows what the mapper is for.

## Step 2: The implementation (the work)

```java
@Component
public class DefaultBookMapper implements BookMapper {

    @Override
    public BorrowResponse toBorrowResponse(Book book) {
        return new BorrowResponse(
            book.getId(),
            book.getTitle(),
            book.getAvailableCopies()
        );
    }

    @Override
    public BookSummary toSummary(Book book) {
        return new BookSummary(
            book.getId(),
            book.getTitle(),
            book.getAuthor()
        );
    }
}
```

**What each part does:**

- `implements BookMapper` ties the class to the contract. If you forget a method, the compiler stops you.
- `@Override` asks the compiler to confirm each method really matches the interface. A typo in a method name becomes a compile error instead of a silent bug.
- `@Component` tells Spring to create one instance of this class at startup and keep it in the application context. That instance is called a **bean**.
- `DefaultBookMapper` is a name that says this is the standard implementation. Naming it after its strategy (for example `FieldCopyBookMapper`) also helps when you later add a second one.

## Step 3: The service depends on the interface

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
    public BorrowResponse borrow(Long bookId) {
        Book book = bookRepository.findById(bookId)
            .orElseThrow(() -> new BookNotFoundException(bookId));

        if (book.getAvailableCopies() == 0) {
            throw new NoCopiesAvailableException(book.getTitle());
        }

        book.setAvailableCopies(book.getAvailableCopies() - 1);
        return bookMapper.toBorrowResponse(book);
    }
}
```

**What this does:** the field type is `BookMapper`, the interface, not `DefaultBookMapper`. When Spring builds `BookService`, it looks for a bean whose type is `BookMapper`, finds `DefaultBookMapper`, and passes it in. The service never names the concrete class.

This is **dependency inversion**: the high-level code (the service) depends on an abstraction, and the detail (the implementation) is supplied from outside.

## Choosing the annotation: the stereotypes

Spring provides several annotations that are all forms of `@Component`. They behave identically at startup. The difference is the label they attach to the class, which tells a reader its role.

|Annotation|Use it for|
|---|---|
|`@Component`|Any Spring-managed class that doesn't fit another role, such as a mapper, a utility, or a client wrapper|
|`@Service`|Business logic classes|
|`@Repository`|Data access classes (also enables translation of database exceptions)|
|`@Controller` / `@RestController`|Web layer classes|

For a mapper, use `@Component`. It contains no business logic, so `@Service` would mislead the next reader into expecting rules there. `@Service` on a mapper would still work at runtime, but it would communicate the wrong role.

## What happens when there are two implementations

Sometimes you have more than one implementation, for example a fast field-copy version and a version that also looks up localized titles. Now Spring finds two beans of type `BookMapper` and refuses to start, because it cannot guess which one you want. You resolve this in one of two ways:

```java
@Component
@Primary
public class DefaultBookMapper implements BookMapper { /* ... */ }

@Component
public class LocalizedBookMapper implements BookMapper { /* ... */ }
```

**What this does:** `@Primary` marks one implementation as the default. Any injection point that asks for `BookMapper` gets the primary bean.

If a particular service needs the other one, name it explicitly:

```java
public BookService(BookRepository bookRepository,
                   @Qualifier("localizedBookMapper") BookMapper bookMapper) {
    this.bookRepository = bookRepository;
    this.bookMapper = bookMapper;
}
```

**What this does:** `@Qualifier` takes the bean name, which Spring derives from the class name by lowercasing the first letter. It selects one specific bean at that injection point.

## The MapStruct version: interface only

With MapStruct, you do **not** write the implementation or the `@Component` annotation. You write the interface and tell MapStruct to generate the class:

```java
@Mapper(componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.ERROR)
public interface BookMapper {

    @Mapping(source = "id", target = "bookId")
    @Mapping(source = "availableCopies", target = "remainingCopies")
    BorrowResponse toBorrowResponse(Book book);

    BookSummary toSummary(Book book);
}
```

**What each part does:**

- `@Mapper` is MapStruct's annotation. It marks the interface for code generation.
- `componentModel = "spring"` tells MapStruct to annotate the generated class with `@Component`. This is the step that replaces the hand-written `@Component`.
- `unmappedTargetPolicy = ReportingPolicy.ERROR` turns a missing field into a **compile error** instead of a warning. Use it on real projects, because a forgotten field is otherwise easy to overlook.
- Each `@Mapping` handles a name difference, as in the earlier lesson.

At compile time, MapStruct generates `BookMapperImpl` with `@Component` already on it. Your service injects `BookMapper` exactly as before, and nothing in the service changes.

**Do not** write a `BookMapperImpl` class yourself when using MapStruct. The generator would create a second class with the same name, and the build would fail.

## Testing each style

With a hand-written mapper, the simplest unit test uses the real class, because it has no dependencies:

```java
class BookServiceTest {

    @Test
    void borrowingWithNoCopiesLeftIsRefused() {
        BookRepository repo = mock(BookRepository.class);
        when(repo.findById(1L))
            .thenReturn(Optional.of(new Book("Dune", "Herbert", 0)));

        BookService service = new BookService(repo, new DefaultBookMapper());

        assertThrows(NoCopiesAvailableException.class,
                     () -> service.borrow(1L));
    }
}
```

**What this does:** it builds the service by hand with a mocked repository and the real mapper. Spring does not start, which keeps the test fast. If you wanted to isolate the service from the mapper, you could pass `mock(BookMapper.class)` instead, because the service depends on the interface.

## A decision guide

- **Mapping is three or four fields, no team conventions yet:** a hand-written `@Component` class implementing an interface.
- **Mapping is many fields or many DTOs:** MapStruct interface with `componentModel = "spring"` and `unmappedTargetPolicy = ERROR`.
- **Mapping is trivial and never changes:** a static utility class with a private constructor. It needs no Spring at all, and this is the one case where skipping both the interface and the annotation is correct.
- **You expect a second implementation:** create the interface from the start, so the service never depends on a concrete class.




[[Spring Framework]]