


## 1. Mental model

Think of a **librarian with a catalog**:

- **Entity** = a catalog card format. A Java class describes what one row of a table looks like.
- **Repository** = the librarian's desk. You say what you want ("all books under $20"), and you never walk the shelves yourself.
- **Hibernate (JPA provider)** = the staff who translate your request into real SQL and fetch the rows.
- **Persistence context** = the librarian's notepad. Every entity loaded in a transaction is tracked, and changes to it are written back automatically.

What you write and what runs:

```
BookRepository (interface you write)
   ↓ Spring generates a proxy at startup
SimpleJpaRepository (Spring's implementation of CRUD methods)
   ↓
EntityManager (JPA API)
   ↓
Hibernate (JPA provider) → SQL → Database
```

You never write an implementation class. Spring Data reads your interface and builds it for you.

---

## 2. Setup

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <scope>runtime</scope>
</dependency>
```

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/library
spring.datasource.username=postgres
spring.datasource.password=secret
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

`ddl-auto=update` is fine for learning. In production use `validate` plus a migration tool such as Flyway.

---

## 3. Entities and the annotations they use

We'll use this model for the whole lesson: **an Author has many Books**.

```java
import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "authors")
public class Author {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String country;

    @OneToMany(mappedBy = "author")
    private List<Book> books = new ArrayList<>();

    // constructors, getters, setters
}
```

```java
@Entity
@Table(name = "books")
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(precision = 8, scale = 2)
    private BigDecimal price;

    @Column(name = "published_year")
    private int publishedYear;

    @Enumerated(EnumType.STRING)
    private Genre genre;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id")
    private Author author;

    // constructors, getters, setters
}

public enum Genre { FANTASY, SCIFI, HISTORY, TECH }
```

|Annotation|Purpose|
|---|---|
|`@Entity`|Marks the class as a table-mapped entity (requires a no-arg constructor)|
|`@Table(name=...)`|Sets the table name (default is the class name)|
|`@Id`|Primary key|
|`@GeneratedValue`|Key generation. `IDENTITY` uses DB auto-increment, `SEQUENCE` uses a DB sequence|
|`@Column`|Column settings: name, nullable, length, unique, precision|
|`@Enumerated(STRING)`|Stores the enum as text. The default `ORDINAL` stores 0, 1, 2 and breaks if you reorder constants|
|`@ManyToOne` / `@OneToMany`|Relationships. `mappedBy` points to the owning side's field|
|`@JoinColumn`|The foreign key column (lives on the "many" side)|

**Why `LAZY`?** It means "don't load the author until someone calls `book.getAuthor()`". It avoids useless joins, but it causes the main gotcha in section 11.

---

## 4. The repository hierarchy and default methods

```java
public interface BookRepository extends JpaRepository<Book, Long> {
}
```

`<Book, Long>` means entity type and primary key type. That empty interface already gives you a full CRUD API:

```
Repository                      (marker, no methods)
 └ CrudRepository               save, findById, delete, count ...
    └ ListCrudRepository        same, but returns List instead of Iterable
 └ PagingAndSortingRepository   findAll(Sort), findAll(Pageable)
    └ JpaRepository             flush, batch deletes, getReferenceById ...
```

### Default methods you get for free

|Method|What it does|
|---|---|
|`save(entity)`|INSERT if new, UPDATE if it exists|
|`saveAll(list)`|Save many|
|`findById(id)`|Returns `Optional<Book>`|
|`findAll()`|All rows|
|`findAll(Sort)`|All rows, sorted|
|`findAll(Pageable)`|One page of rows (returns `Page<Book>`)|
|`findAllById(ids)`|Several rows by id|
|`existsById(id)`|`true`/`false`|
|`count()`|Row count|
|`deleteById(id)` / `delete(entity)`|Delete one|
|`deleteAll()` / `deleteAllById(ids)`|Delete many (loads entities, then deletes them one by one)|
|`deleteAllInBatch()`|A single `DELETE FROM books`, no entity loading|
|`flush()` / `saveAndFlush()`|Push pending changes to the DB now|
|`getReferenceById(id)`|A lazy proxy with no query until you touch it|
|`findAll(Example)`|Query by example (probe object)|

Usage:

```java
@Service
public class BookService {
    private final BookRepository bookRepository;

    public BookService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    public Book get(Long id) {
        return bookRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Book " + id + " not found"));
    }
}
```

**How `save()` decides insert vs update:** if the id is `null` (or the entity is detected as new), it calls `persist` (INSERT). Otherwise it calls `merge`, which does a SELECT first and then an UPDATE if something changed.

---

## 5. Derived query methods (no query written)

Spring parses the **method name** and builds the query:

```java
public interface BookRepository extends JpaRepository<Book, Long> {

    List<Book> findByGenre(Genre genre);
    List<Book> findByGenreAndPriceLessThan(Genre genre, BigDecimal max);
    List<Book> findByTitleContainingIgnoreCase(String fragment);
    List<Book> findByPublishedYearBetween(int from, int to);
    List<Book> findByAuthorCountry(String country);   // traverses book.author.country
    List<Book> findTop3ByOrderByPriceDesc();
    Optional<Book> findFirstByTitle(String title);
    boolean existsByTitle(String title);
    long countByGenre(Genre genre);
    void deleteByGenre(Genre genre);                  // needs @Transactional
}
```

Name anatomy: `find` + `By` + property + operator keyword (`And`, `Or`, `LessThan`, `Containing`, `Between`, `In`, `IsNull`, `OrderBy...`).

Typos in property names fail at **startup**, not at runtime, which is a nice safety net.

**Limit:** for 3+ conditions the names get unreadable (`findByGenreAndPriceLessThanAndPublishedYearGreaterThanOrderByTitleAsc`). That is when you switch to `@Query`.

---

## 6. JPQL with `@Query`

**JPQL queries entities and fields, not tables and columns.** You write `Book`, not `books`, and `b.publishedYear`, not `published_year`.

```java
// Named parameters (preferred)
@Query("SELECT b FROM Book b WHERE b.price BETWEEN :min AND :max ORDER BY b.price")
List<Book> findInPriceRange(@Param("min") BigDecimal min, @Param("max") BigDecimal max);

// LIKE with the % wildcard
@Query("SELECT b FROM Book b WHERE LOWER(b.title) LIKE LOWER(CONCAT('%', :kw, '%'))")
List<Book> search(@Param("kw") String keyword);

// Navigating relationships (implicit join)
@Query("SELECT b FROM Book b WHERE b.author.country = :country")
List<Book> byCountry(@Param("country") String country);

// Explicit join + fetching the author in the same query
@Query("SELECT b FROM Book b JOIN FETCH b.author WHERE b.genre = :genre")
List<Book> findWithAuthor(@Param("genre") Genre genre);

// Aggregate
@Query("SELECT AVG(b.price) FROM Book b WHERE b.genre = :genre")
Double averagePrice(@Param("genre") Genre genre);

// IN with a collection
@Query("SELECT b FROM Book b WHERE b.genre IN :genres")
List<Book> byGenres(@Param("genres") Collection<Genre> genres);
```

Positional parameters (`?1`, `?2`) also work, but named ones are safer when you reorder arguments.

### Returning something other than the full entity

**Constructor expression into a record:**

```java
public record BookSummary(String title, String authorName) {}

@Query("SELECT new com.example.library.BookSummary(b.title, b.author.name) FROM Book b")
List<BookSummary> findSummaries();
```

Use the fully qualified class name here.

**Interface projection** (Spring generates the implementation):

```java
public interface BookView {
    String getTitle();
    BigDecimal getPrice();
}

List<BookView> findByGenre(Genre genre);   // works with derived methods too
```

Only `title` and `price` get selected, so the query is lighter than loading whole entities.

**Group-by with a record:**

```java
public record GenreCount(Genre genre, long total) {}

@Query("SELECT new com.example.library.GenreCount(b.genre, COUNT(b)) FROM Book b GROUP BY b.genre")
List<GenreCount> countPerGenre();
```

---

## 7. Update and delete queries

`@Query` is read-only by default. For writes you need `@Modifying`, and a transaction:

```java
@Modifying(clearAutomatically = true, flushAutomatically = true)
@Transactional
@Query("UPDATE Book b SET b.price = b.price * :factor WHERE b.genre = :genre")
int raisePrices(@Param("genre") Genre genre, @Param("factor") BigDecimal factor);

@Modifying
@Transactional
@Query("DELETE FROM Book b WHERE b.publishedYear < :year")
int deleteOld(@Param("year") int year);
```

The return value is the number of affected rows.

**Why `clearAutomatically`?** A bulk JPQL update goes straight to the database and bypasses the persistence context. Entities already loaded in memory still hold the old price. Clearing the context forces fresh data on the next read. `flushAutomatically` pushes pending changes first, so nothing gets lost.

---

## 8. Native SQL queries

Use real SQL when you need DB-specific features (window functions, `ILIKE`, JSON operators, CTEs) or hand-tuned queries:

```java
@Query(value = "SELECT * FROM books WHERE published_year > :year", nativeQuery = true)
List<Book> findNewerThan(@Param("year") int year);

// PostgreSQL-specific
@Query(value = "SELECT * FROM books WHERE title ILIKE '%' || :kw || '%'", nativeQuery = true)
List<Book> searchIgnoreCase(@Param("kw") String keyword);

// Projection from native SQL
@Query(value = "SELECT genre AS genre, COUNT(*) AS total FROM books GROUP BY genre",
       nativeQuery = true)
List<GenreStats> genreStats();

public interface GenreStats {
    String getGenre();
    Long getTotal();
}
```

For native queries, **column aliases must match the getter names** in the projection interface.

**Paging a native query needs a separate count query:**

```java
@Query(value = "SELECT * FROM books WHERE genre = :genre",
       countQuery = "SELECT COUNT(*) FROM books WHERE genre = :genre",
       nativeQuery = true)
Page<Book> pageByGenre(@Param("genre") String genre, Pageable pageable);
```

Note that here you use **table and column names**, and the genre is a plain string because the DB only sees text.

---

## 9. Paging and sorting

```java
Page<Book> findByGenre(Genre genre, Pageable pageable);
Slice<Book> findByAuthorCountry(String country, Pageable pageable);
```

```java
Pageable pageable = PageRequest.of(0, 10, Sort.by("price").descending());
Page<Book> page = bookRepository.findByGenre(Genre.TECH, pageable);

page.getContent();       // the 10 books
page.getTotalElements(); // total matching rows
page.getTotalPages();
page.hasNext();
```

`Page` runs an extra `COUNT` query to know the totals. `Slice` skips it and only knows whether a next page exists, which is cheaper for "load more" UIs.

---

## 10. Named queries (brief)

You can put the JPQL on the entity instead:

```java
@Entity
@NamedQuery(name = "Book.findCheap", query = "SELECT b FROM Book b WHERE b.price < 10")
public class Book { ... }
```

```java
List<Book> findCheap();   // Spring matches "Book.findCheap" by name
```

Most projects just use `@Query` on the repository because it keeps the query next to its method.

---

## 11. Which approach when?

|Approach|Best for|Checked at startup?|Portable across DBs?|
|---|---|---|---|
|Derived method|Simple filters (1 to 2 conditions)|Yes|Yes|
|JPQL `@Query`|Joins, aggregates, projections|Yes (syntax)|Yes|
|Native `@Query`|DB-specific features, tuned SQL|No (fails at runtime)|No|

---

## 12. Gotchas and edge cases

1. **N+1 problem.** `findAll()` on books, then `book.getAuthor().getName()` in a loop, fires 1 query for books plus N queries for authors. Fix it with `JOIN FETCH`, or `@EntityGraph(attributePaths = "author")` on the repository method.
    
    ```java
    @EntityGraph(attributePaths = "author")
    List<Book> findByGenre(Genre genre);
    ```
    
2. **`LazyInitializationException`.** Touching a lazy field after the transaction has closed (for example in a controller) throws it. Fetch what you need inside the service, or return a DTO or projection.
    
3. **`JOIN FETCH` with paging.** Combined with collection fetches, Hibernate paginates **in memory** (it warns `HHH000104`). Page the parent query first, or use a separate query for the children.
    
4. **`deleteAll()` vs `deleteAllInBatch()`.** The first loads every entity and deletes them one by one (slow, but triggers cascades and lifecycle callbacks). The second is a single SQL statement (fast, but skips both).
    
5. **Derived `deleteBy...` needs `@Transactional`.** Without a transaction you get `TransactionRequiredException`.
    
6. **Dirty checking.** Inside a `@Transactional` method, if you load a Book and call `setPrice(...)`, the UPDATE happens at commit **even without calling `save()`**. This surprises many beginners.
    
7. **`findById` returns `Optional`.** Never call `.get()` blindly. Use `orElseThrow`.
    
8. **Reserved words.** Naming a column `order` or `user` breaks SQL. Use `@Table(name = "orders")` or `@Column(name = "user_name")`.
    
9. **Never concatenate user input into queries.** `@Query("... WHERE name = '" + x + "'")` is SQL injection. Always use `:param`.
    
10. **`@Transactional(readOnly = true)` on read-only service methods.** It lets Hibernate skip dirty-checking and can improve performance.
    




[[Spring Framework]]