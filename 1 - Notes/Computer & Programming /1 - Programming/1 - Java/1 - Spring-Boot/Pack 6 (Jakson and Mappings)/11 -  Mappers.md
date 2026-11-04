

## What a mapper is

A **mapper** is a piece of code whose only job is to convert one object type into another. In a Spring Boot application, that usually means converting an **entity** (a class that maps to a database table) into a **DTO** (a class that defines what the API sends or receives), and sometimes the reverse.

A mapper contains no business rules, no database calls, and no HTTP handling. It takes an object in and returns an object out, shaped differently.

## Why it exists

In the previous lesson, the service returned a `BorrowResponse` record, which the client sees as JSON. The service had to build that record by hand:

```java
return new BorrowResponse(
    book.getId(),
    book.getTitle(),
    book.getAvailableCopies()
);
```

This works for three fields. Now imagine a `Book` with 15 fields, a `Author` relationship, and a timestamp. The service would fill with field-copying code, and that code is noise. It obscures the business logic around it.

A mapper moves that copying into one place. The service asks for the conversion and keeps its focus on rules.

## The problems it solves

**The API shape stays independent of the table shape.** If you rename the `availableCopies` column, you change the entity and the mapper. The client's JSON stays the same, so existing apps keep working.

**Sensitive fields stay out of responses.** A `User` entity might hold a password hash. A mapper to `UserResponse` simply doesn't copy that field, so it can't leak by accident.

**Conversion logic is written once.** If three endpoints return a book summary, they all use the same mapping, and a fix applies everywhere.

**Lazy-loaded data is handled deliberately.** Converting an entity to a DTO forces you to decide which related data to read and when. This is an important point we'll return to below.

## Three ways to write a mapper

### Option 1: Hand-written methods

The simplest approach is a plain Java method:

```java
public final class BookMapper {

    private BookMapper() {}

    public static BorrowResponse toBorrowResponse(Book book) {
        return new BorrowResponse(
            book.getId(),
            book.getTitle(),
            book.getAvailableCopies()
        );
    }
}
```

**What this does:** it reads three values from a `Book` and places them into a `BorrowResponse`. Because it is a static method with no state, you can call it directly without Spring.

This approach has no dependencies, no magic, and no build setup. Its weakness is repetition: every field is copied by hand, and if you add a field to `BorrowResponse` and forget to update the method, the compiler won't tell you. For a small project, this is often the right choice.

### Option 2: MapStruct (generated at compile time)

**MapStruct** lets you write only an interface. At compile time, it generates the implementation as ordinary Java code. You can read that generated code, and it runs as fast as the hand-written version.

Add these to your `pom.xml`:

```xml
<dependencies>
    <dependency>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct</artifactId>
        <version>1.6.3</version>
    </dependency>
</dependencies>

<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <configuration>
                <annotationProcessorPaths>
                    <path>
                        <groupId>org.mapstruct</groupId>
                        <artifactId>mapstruct-processor</artifactId>
                        <version>1.6.3</version>
                    </path>
                </annotationProcessorPaths>
            </configuration>
        </plugin>
    </plugins>
</build>
```

**What this does:** the first dependency gives you the `@Mapper` annotation. The compiler plugin configuration runs MapStruct's processor during compilation, which is what generates the implementation.

Now the mapper interface:

```java
@Mapper(componentModel = "spring")
public interface BookMapper {

    @Mapping(source = "id", target = "bookId")
    @Mapping(source = "availableCopies", target = "remainingCopies")
    BorrowResponse toBorrowResponse(Book book);
}
```

**What this does, line by line:**

- `@Mapper(componentModel = "spring")` tells MapStruct to generate a class that Spring can manage as a bean, so you can inject it with constructor injection.
- `toBorrowResponse(Book book)` declares the conversion. You write no body.
- The first `@Mapping` handles a name difference. The entity calls the field `id`, but the DTO calls it `bookId`. Without this annotation, MapStruct would not know they correspond.
- The second `@Mapping` handles the same kind of difference for `availableCopies` and `remainingCopies`.
- Fields with matching names, like `title`, are copied automatically.

When you compile, MapStruct generates a class called `BookMapperImpl` in `target/generated-sources/annotations`. Open it and read it. It contains the same three-field copy you would have written by hand. Nothing is hidden.

If you forget a mapping, MapStruct emits a compiler warning about an unmapped target property, which catches the problem that hand-written code misses.

### Option 3: ModelMapper and similar reflection-based libraries

Some libraries determine mappings at runtime by inspecting field names through reflection. They require less code to set up, but they find mistakes only when the code runs, not when it compiles, and they are slower. For learning, prefer hand-written or MapStruct. You'll meet the others in existing codebases, and it's worth knowing they exist.

## Using the mapper in the service

The service now receives the mapper through its constructor, and its borrowing logic stays the same:

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

**What changed:** the final `return` no longer builds the record by hand. It asks the mapper. Everything else is untouched, which is the point: the service still knows nothing about how the response is shaped.

## Where mappers belong, and where they don't

Keep these rules in mind as your projects grow:

- **Mappers convert, they don't decide.** A mapper should never contain `if` statements about business rules. If it does, that logic belongs in the service.
- **Mappers don't call repositories.** If a mapper fetches related data from the database, you get hidden queries that are hard to predict and test.
- **Mappers run where the data is already loaded.** Converting an entity to a DTO can trigger lazy loading if the entity has relationships marked to load later. A mapper that touches an unloaded collection inside a loop can fire one query per item, a problem called the **N+1 query problem**. This is why the mapping usually happens inside the service, while the transaction is still open.



[[Spring Framework]]