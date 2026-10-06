




**You don't need `@Repository` on a Spring Data interface.** This works as it is:

```java
public interface BookRepository extends JpaRepository<Book, Long> { }
```

## 2. Mental model

Think of two ways to hire staff:

- **Component scanning** (`@Component`, `@Service`, `@Repository` on a class) is like posting a job ad: "any _person_ wearing this badge is hired." Spring walks your packages, finds **classes** with the badge, and creates instances.
- **Spring Data repository scanning** is like a recruiter reading a **job description**: "any _description_ that extends `Repository` gets a worker built for it." Spring finds the interface and **generates a proxy class** at startup.

Component scanning ignores interfaces, because you can't instantiate one. Spring Data has its own scanner for them, and that scanner looks at what the interface **extends**, not at annotations.

## 3. How it works technically

1. `@SpringBootApplication` enables auto-configuration, which includes `@EnableJpaRepositories` behind the scenes.
2. It scans the package of your main class **and all sub-packages**.
3. Every interface extending `Repository` (directly or through `CrudRepository`, `JpaRepository`, and so on) gets a proxy backed by `SimpleJpaRepository`.
4. The proxy is registered as a bean, so you can inject it anywhere.

Where `@Repository` actually matters is **exception translation**. It marks a class so Spring wraps it with `PersistenceExceptionTranslationPostProcessor`, which converts vendor exceptions (Hibernate's `PersistenceException`, SQL errors) into Spring's `DataAccessException` hierarchy. Spring Data proxies already do this translation, so the annotation adds nothing there.

|Situation|Need `@Repository`?|
|---|---|
|Interface extending `JpaRepository`|No|
|Hand-written class using `EntityManager` or `JdbcTemplate`|**Yes**, for bean registration and exception translation|
|Custom fragment implementation (`...Impl`, see section 6)|Optional, but recommended for translation|

Adding `@Repository` to an interface is harmless but redundant. Many developers do it for readability, and that's a style choice, not a requirement.

## 4. Gotcha: repositories outside the main package

The scan starts from your `@SpringBootApplication` class's package:

```
com.example.library            ← LibraryApplication.java (scan starts here)
 ├ book/BookRepository         ✅ found
 └ author/AuthorRepository     ✅ found

com.shared.data/BookRepository ❌ NOT found, so you get "No qualifying bean" at startup
```

Fix it explicitly:

```java
@SpringBootApplication
@EnableJpaRepositories(basePackages = "com.shared.data")
@EntityScan(basePackages = "com.shared.data")
public class LibraryApplication { ... }
```

**Trap:** once you declare `@EnableJpaRepositories` yourself, the default "scan from my package" behavior **switches off**. If you still want your own package scanned, list it too: `basePackages = {"com.example.library", "com.shared.data"}`. The same applies to `@EntityScan`.

## 5. Design principles

### 5.1 One repository per aggregate root, not per table

An **aggregate root** is the entity you always enter through, with its dependents hanging off it. For example, `Order` owns its `OrderLine`s, so you create `OrderRepository` but no `OrderLineRepository`. Lines are reached through the order. Per-table repositories lead to business rules scattered everywhere.

In our model, `Author` and `Book` can each be their own root, because you query books independently (by genre or price).

### 5.2 Pick the right base interface

```java
// Full power: CRUD + paging + JPA-specific batch ops
public interface BookRepository extends JpaRepository<Book, Long> { }

// Smaller surface: CRUD only
public interface AuthorRepository extends CrudRepository<Author, Long> { }

// Minimal: expose ONLY what you choose
public interface GenreRepository extends Repository<Genre, Long> {
    Optional<Book> findById(Long id);
    List<Book> findByGenre(Genre genre);
}
```

Why would you restrict it? `JpaRepository` exposes `deleteAll()` and `deleteAllInBatch()`. If your service layer has no business deleting everything, a dangerous method sitting one autocomplete away is a design smell. Extending plain `Repository<T, ID>` and **copying only the signatures you want** gives a deliberately narrow API (Spring still implements them for you, because the method signatures match `CrudRepository`).

### 5.3 Share behavior with a base interface

```java
@NoRepositoryBean
public interface BaseRepository<T, ID> extends JpaRepository<T, ID> {
    // shared methods
}

public interface BookRepository extends BaseRepository<Book, Long> { }
```

`@NoRepositoryBean` tells Spring "don't build a proxy for this one, it's only a template." Without it, startup fails because Spring tries to create a bean for a generic interface.

### 5.4 Keep repositories dumb

A repository should only translate "what I want" into a query:

```java
// ❌ Business logic in the repository
default void applyDiscount(Book b) { ... }

// ✅ Repository: data access only
List<Book> findByGenreAndPriceGreaterThan(Genre genre, BigDecimal min);

// ✅ Service: rules and transactions
@Service
public class PricingService {
    @Transactional
    public void discountOldBooks() {
        bookRepository.findByPublishedYearLessThan(2000)
                      .forEach(b -> b.setPrice(b.getPrice().multiply(new BigDecimal("0.9"))));
        // dirty checking persists the changes at commit
    }
}
```

Put `@Transactional` on the **service** methods. A use case often touches several repositories and must succeed or fail as one unit.

### 5.5 Design method signatures deliberately

|Question|Guideline|
|---|---|
|Might nothing be found?|Return `Optional<T>`, never `null`|
|Could the result be huge?|Take a `Pageable` and return `Page` or `Slice`|
|Only some fields needed?|Return an interface or record projection|
|Just an existence check?|`existsBy...` (cheaper than loading)|
|Streaming a large export?|`Stream<Book>` (close it, and use it inside a transaction)|

### 5.6 Naming and layout

```
com.example.library
 ├ book
 │   ├ Book.java
 │   ├ BookRepository.java
 │   ├ BookService.java
 │   └ BookController.java
 └ author
     └ ...
```

Group by **feature** (everything about books together) instead of by layer (all repositories in one folder). It scales better and keeps related code close.

## 6. When the interface isn't enough: custom fragments

For logic that can't be expressed with derived names or `@Query` (dynamic filters, complex Criteria API), add a **fragment**:

```java
// 1. Fragment interface
public interface BookRepositoryCustom {
    List<Book> searchDynamic(String title, Genre genre, BigDecimal maxPrice);
}

// 2. Implementation: the class name MUST be <FragmentInterface>Impl
@Repository
public class BookRepositoryCustomImpl implements BookRepositoryCustom {

    @PersistenceContext
    private EntityManager em;

    @Override
    public List<Book> searchDynamic(String title, Genre genre, BigDecimal maxPrice) {
        StringBuilder jpql = new StringBuilder("SELECT b FROM Book b WHERE 1=1");
        Map<String, Object> params = new HashMap<>();

        if (title != null) {
            jpql.append(" AND LOWER(b.title) LIKE :title");
            params.put("title", "%" + title.toLowerCase() + "%");
        }
        if (genre != null) {
            jpql.append(" AND b.genre = :genre");
            params.put("genre", genre);
        }
        if (maxPrice != null) {
            jpql.append(" AND b.price <= :max");
            params.put("max", maxPrice);
        }

        TypedQuery<Book> q = em.createQuery(jpql.toString(), Book.class);
        params.forEach(q::setParameter);
        return q.getResultList();
    }
}

// 3. Main repository combines both
public interface BookRepository extends JpaRepository<Book, Long>, BookRepositoryCustom { }
```

Spring finds `BookRepositoryCustomImpl` **by the naming convention** and merges it into the proxy. You inject only `BookRepository` and call both generated and custom methods. Here `@Repository` is on a real class, so it earns its keep through exception translation.

(For dynamic filtering, the Specifications API, `JpaSpecificationExecutor`, is the more idiomatic next step. That fits well with the advanced topics ahead.)

## 7. Quick checklist

- Interface extends a Spring Data base interface → **no annotation needed**
- Hand-written class touching `EntityManager` or JDBC → **`@Repository`**
- Repository in another package → **`@EnableJpaRepositories` + `@EntityScan`**
- Shared template interface → **`@NoRepositoryBean`**
- Rules and transactions → **service layer**
- Custom logic → **`...Custom` fragment + `...Impl` class**




[[Spring Framework]]