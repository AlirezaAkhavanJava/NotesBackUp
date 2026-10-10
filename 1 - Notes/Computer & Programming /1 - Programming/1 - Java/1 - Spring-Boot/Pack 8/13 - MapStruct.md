

Before learning the annotations, read what MapStruct produces. Suppose your project has this entity:

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

    @Enumerated(EnumType.STRING)
    private Genre genre;

    protected Book() {}

    // getters and setters for each field
}
```

And this DTO, which is what the API sends:

```java
public record BookDetail(Long id, String title, String author,
                         int remainingCopies, String genre) {}
```

Notice the differences: the DTO calls the field `remainingCopies` where the entity says `availableCopies`, and `genre` is an enum in one place and a `String` in the other.

Now the mapper interface:

```java
@Mapper(componentModel = "spring")
public interface BookMapper {

    @Mapping(source = "availableCopies", target = "remainingCopies")
    @Mapping(source = "genre", target = "genre", qualifiedByName = "")
    BookDetail toDetail(Book book);
}
```

That second `@Mapping` is a mistake I put in deliberately, and we'll return to it. For now, here is roughly what MapStruct generates when you compile. I've trimmed it for readability; the exact output varies by MapStruct version, but the shape is the same:

```java
@Component
public class BookMapperImpl implements BookMapper {

    @Override
    public BookDetail toDetail(Book book) {
        if (book == null) {
            return null;
        }

        Long id = book.getId();
        String title = book.getTitle();
        String author = book.getAuthor();
        int remainingCopies = book.getAvailableCopies();
        String genre = book.getGenre() != null ? book.getGenre().name() : null;

        return new BookDetail(id, title, author, remainingCopies, genre);
    }
}
```

Read that code carefully, because it answers most of your questions:

- The `null` check at the top means a `null` book produces a `null` DTO instead of an exception.
- Each DTO field is filled by calling a getter on the entity. There is no reflection and no runtime lookup. It is ordinary Java, and you can step through it in a debugger.
- The enum became a string through `.name()`. MapStruct generated that conversion for you.
- The `@Component` annotation appeared without you writing it, because of `componentModel = "spring"`.

Everything below explains how the interface produces this class.

## How MapStruct matches fields

MapStruct does not guess. It follows a fixed sequence for each target property:

1. If a `@Mapping` names this target, use the source it names.
2. Otherwise, look for a source property with the **same name** and a compatible type.
3. Otherwise, report the target as unmapped, which becomes a warning or an error depending on your policy.

Rule 2 is why `title`, `author`, and `id` mapped without any annotation. Rule 1 is why `remainingCopies` needed one.

Compatible types include exact matches and common conversions: `int` to `Integer`, `Integer` to `long`, and `Enum` to `String` as in the genre example. Nested beans are handled too. If `Book` had a `Publisher publisher` field and `BookDetail` had a `PublisherDto publisher` field, MapStruct would look for a mapping from `Publisher` to `PublisherDto` and generate it if one exists or can be inferred.

## Turning warnings into errors

The mapper I showed above has a silent risk. Suppose someone adds `int pageCount` to `BookDetail` and forgets to add it to the entity. MapStruct emits only a warning, and the field stays at its default value of `0`. The code compiles, the API returns wrong data, and nobody notices.

Make it strict:

```java
@Mapper(componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.ERROR)
public interface BookMapper {
    // methods
}
```

Now the same missing field stops the build with an error that names the property. For real projects, use `ERROR` from the start. You'll find that the compiler is a better reviewer than your memory.

## Controlling what gets copied

Four annotations cover most decisions.

**Renaming** uses `@Mapping(source, target)`, as shown earlier.

**Constants** set a fixed value regardless of the source:

```java
@Mapping(target = "currency", constant = "USD")
```

**Expressions** insert a Java expression. Use them sparingly, because the logic is hidden inside a string the compiler barely checks:

```java
@Mapping(target = "slug", expression = "java(book.getTitle().toLowerCase())")
```

**Ignoring** skips a target entirely, which matters for fields the mapping should never fill:

```java
@Mapping(target = "id", ignore = true)
```

Ignore `id` when mapping a request into a new entity, so the database assigns it.

## Custom conversions with `@Named`

Suppose the API should show the genre as a readable label such as "Science fiction" rather than `SCIENCE_FICTION`. You could write a default method in the mapper interface:

```java
@Mapper(componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.ERROR)
public interface BookMapper {

    @Mapping(source = "availableCopies", target = "remainingCopies")
    @Mapping(source = "genre", target = "genre", qualifiedByName = "genreLabel")
    BookDetail toDetail(Book book);

    @Named("genreLabel")
    default String genreLabel(Genre genre) {
        if (genre == null) {
            return "Unknown";
        }
        return switch (genre) {
            case SCIENCE_FICTION -> "Science fiction";
            case MYSTERY -> "Mystery";
            default -> genre.name().toLowerCase();
        };
    }
}
```

**What this does, piece by piece:**

- `@Named("genreLabel")` gives the method a name so it can be selected explicitly.
- `qualifiedByName = "genreLabel"` tells MapStruct to use that method for this one property, rather than its default enum-to-string conversion.
- The method is `default`, so it lives inside the interface with a body. MapStruct calls it from the generated code.

Without `qualifiedByName`, MapStruct would not know which of several `Genre → String` conversions to use. The name is the disambiguator. That's the reason the earlier example with `qualifiedByName = ""` was wrong: an empty name matches nothing, and the compiler will reject it.

If a conversion is shared by many mappers, put it in its own mapper and reference it with `uses`:

```java
@Mapper(componentModel = "spring", uses = GenreLabels.class)
public interface BookMapper { /* ... */ }
```

## Collections come almost free

If the service needs a list, declare the method for a single item and MapStruct generates the loop:

```java
List<BookDetail> toDetails(List<Book> books);
```

The generated method creates a new `ArrayList`, calls `toDetail` for each element, and returns the result. You don't write the loop.

## Updating an existing entity

Sometimes you want to copy an incoming request into a row that already exists, not create a new object. `@MappingTarget` marks the parameter to fill:

```java
public record BookUpdate(String title, String author) {}

void applyUpdate(BookUpdate update, @MappingTarget Book book);
```

The method returns `void`, and the generated code calls `book.setTitle(...)` and `book.setAuthor(...)` on the entity you pass in. Two details matter here. First, MapStruct needs setters on the target, so an entity with no setters cannot be a target. Second, a `null` property in the source will overwrite the existing value unless you tell MapStruct otherwise. For partial updates, configure `NullValuePropertyMappingStrategy.IGNORE` on the mapper.

## Where mapping goes wrong

**Lazy collections.** If `Book` has `@OneToMany(fetch = FetchType.LAZY) List<Review> reviews`, and `BookDetail` includes a `reviews` property, the generated code calls `book.getReviews()`. The getter triggers a database query, which needs an open session. Called outside a transaction, it throws `LazyInitializationException`. Call the mapper inside the service method that is annotated `@Transactional`, or fetch the reviews explicitly in the repository query.

**Cycles.** If `Author` has a list of `Book` and `Book` has an `Author`, mapping one can recurse forever. MapStruct detects some of these cases, but the usual fix is to design the DTOs so each one contains only one direction, or to ignore the back-reference with `@Mapping(target = "...", ignore = true)`.

**Setters and constructors.** MapStruct can fill a target through setters, a builder, or a constructor. Records work through their canonical constructor, which is why `BookDetail` needed nothing extra. A JPA entity with a protected no-argument constructor and getters but no setters can be a source but not a target.



[[Spring Framework]]