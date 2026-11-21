

This is an important distinction, and it explains why the repository didn't need `@Repository` earlier.

## 1. Mental model

A restaurant has two kinds of things:

- **Staff** (chef, waiter, cashier): few of them, long-lived, each with a job and tools. These are **Spring beans**: `BookService`, `BookRepository`, `BookController`.
- **Orders** (paper tickets): thousands, created and thrown away constantly, each holding different data. These are **entities**: `Book` #1, `Book` #2, `Book` #3...

Spring hires and manages the staff. The orders are managed by someone else, the **persistence context** (the `EntityManager` notepad from earlier).

## 2. Two containers, two jobs

||Spring bean|JPA entity|
|---|---|---|
|Managed by|Spring IoC container|Persistence context (`EntityManager`/Hibernate)|
|Instances|Usually one (singleton)|One per database row, many at once|
|Created by|Spring, at startup|You with `new`, or Hibernate when loading rows|
|Found by|Component scanning (`@Component`, `@Service`...)|`@EntityScan` / Hibernate scanning for `@Entity`|
|Dependency injection|Yes (`@Autowired`, constructor)|No|
|Lifetime|Application lifetime|Transaction or session|
|Holds|Behavior and dependencies|Data (state of a row)|

Component scanning never creates `Book` objects. `@Entity` only registers **metadata** ("this class maps to table `books`"). No instance exists until you or Hibernate make one.

## 3. Entity lifecycle: what "managed" means

1. `Book b = new Book();` is **transient**. Hibernate doesn't know about it.
2. `bookRepository.save(b);` makes it **managed**. The persistence context now tracks it.
3. At commit, Hibernate compares `b` to its original snapshot and writes the UPDATE if anything changed (dirty checking).
4. After the transaction ends, `b` is **detached**. It's still a Java object, but changes to it are no longer tracked.
5. `bookRepository.delete(b);` makes it **removed**, and the DELETE runs at flush or commit.

```java
@Transactional
public void rename(Long id) {
    Book b = bookRepository.findById(id).orElseThrow(); // managed
    b.setTitle("New title");                            // no save() needed
}                                                       // UPDATE at commit
```

## 4. Consequences and gotchas

**1. Don't `@Autowired` into an entity.** Hibernate creates entities through the no-arg constructor, so Spring never gets a chance to inject.

```java
@Entity
public class Book {
    @Autowired
    private PriceCalculator calculator;  // ❌ stays null
}
```

If you need that logic, put it in a service and pass the entity in:

```java
@Service
public class PricingService {
    private final PriceCalculator calculator;
    // constructor injection ...

    public BigDecimal finalPrice(Book b) { return calculator.apply(b.getPrice()); }
}
```

**2. Don't annotate an entity with `@Component`.** It would become a singleton shared by everyone, so all rows would share one object's state. That's a serious bug.

**3. Entities are not thread-safe singletons.** Two requests loading the same row get separate instances, because each transaction has its own persistence context.

**4. Entity rules come from JPA, not Spring.** The class needs a no-arg constructor (can be `protected`), must not be `final` (Hibernate creates proxies by subclassing for lazy loading), and needs an `@Id`.

**5. "Bean" has two meanings.** A _JavaBean_ is just a class with getters and setters, and entities do look like that. A _Spring bean_ is an object managed by the container. Entities are JavaBean-style, but not Spring beans.

## 5. Edge case: where the two worlds meet

Spring Boot connects Hibernate to the Spring container for **helpers around** entities, not the entities themselves. `@EntityListeners` classes and `AttributeConverter`s can use injection:

```java
@Component
public class BookAuditListener {
    private final AuditService auditService;   // injected ✅

    public BookAuditListener(AuditService auditService) {
        this.auditService = auditService;
    }

    @PostPersist
    void afterInsert(Book book) { auditService.log("Created " + book.getTitle()); }
}

@Entity
@EntityListeners(BookAuditListener.class)
public class Book { ... }
```

The listener is a bean. The `Book` is still a plain object.

## 6. Connection to the repository question

This is why repositories need special scanning while entities do too:

- **Services and controllers** → component scanning (`@Service`, `@RestController`)
- **Repository interfaces** → `@EnableJpaRepositories` (auto-configured)
- **Entities** → `@EntityScan` (auto-configured, also from your main package)

Three different scanners for three different kinds of things, and only the first creates beans from classes you annotated yourself.




[[Spring Framework]]