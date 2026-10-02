**JDBC** (Java Database Connectivity) is Java's low-level standard API for sending SQL to a database and reading the results. **Hibernate** is an **ORM** (Object-Relational Mapper) that sits on top of JDBC and lets you work with Java objects instead of writing SQL by hand.

**Analogy:** JDBC is writing, addressing, and posting every letter yourself. Hibernate is a secretary: you say "save this book," and the secretary writes the SQL, posts it, and turns the replies back into Java objects. The secretary still uses the same postal system (JDBC) underneath.

## The stack

```
Controller -> Service -> Spring Data JPA Repository -> JPA -> Hibernate -> JDBC -> Driver -> Database
```

- **JDBC:** the bottom layer, the standard API (`java.sql`).
- **JDBC driver:** the database-specific implementation (the `postgresql` or `sqlite-jdbc` dependency you added in earlier lessons). This is the API idea again: your code uses the standard interfaces, and the driver supplies the implementation.
- **JPA** (Jakarta Persistence API): a **specification**, a set of interfaces and annotations (`@Entity`, `@Id`). It is only a contract.
- **Hibernate:** the most popular **implementation** of JPA. It's what Spring Boot uses by default.
- **Spring Data JPA:** generates repository code on top of JPA (the `JpaRepository` you used before).

JPA is to Hibernate what `PaymentService` was to `PayPalService` in the API lesson.

## JDBC: the raw way

```java
String sql = "SELECT id, title, year FROM books WHERE year > ?";

try (Connection conn = DriverManager.getConnection(
         "jdbc:postgresql://localhost:5432/library", "alireza", "secret");
     PreparedStatement ps = conn.prepareStatement(sql)) {

    ps.setInt(1, 2000);                       // fill the ? safely

    try (ResultSet rs = ps.executeQuery()) {
        List<Book> books = new ArrayList<>();
        while (rs.next()) {                   // manual row -> object mapping
            books.add(new Book(rs.getLong("id"),
                               rs.getString("title"),
                               rs.getInt("year")));
        }
    }
}
```

The five JDBC steps are always the same: **connect, prepare SQL, execute, read the result row by row, close everything** (`try-with-resources` closes automatically).

**Why `PreparedStatement` matters:** the `?` placeholder sends your value separately from the SQL text, so it can never be interpreted as SQL. Building the string by hand (`"... WHERE title = '" + input + "'"`) is how **SQL injection** happens.

**The pain of plain JDBC:** you write all the SQL, map every column to every field by hand, manage connections and transactions yourself, and repeat this for every table. It's powerful and transparent but very repetitive.

## The core problem Hibernate solves

Objects and tables are shaped differently. Java has inheritance, references, and collections; a database has rows, foreign keys, and joins. Bridging them by hand is called the **object-relational impedance mismatch**. Hibernate does the bridging from your annotations:

```java
@Entity
@Table(name = "books")
public class Book {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private int year;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id")
    private Author author;
    // getters and setters
}
```

Each class maps to a table, each field to a column, and each reference to a foreign key. You then work with objects:

```java
Book book = new Book();
book.setTitle("Clean Code");
entityManager.persist(book);          // Hibernate generates: INSERT INTO books ...
Book found = entityManager.find(Book.class, 1L);  // SELECT ... WHERE id = 1
```

With Spring Data you rarely touch `EntityManager` directly; `bookRepository.save(book)` does the same.

## How Hibernate really works (the mental model)

This is the part that explains most of its "magic" and its surprises.

**1. Persistence context (the first-level cache).** Inside a transaction, Hibernate keeps a workspace of every entity it has loaded. Ask for `Book` with id 1 twice in the same transaction and you get the **same object** back, with only one SQL query.

**2. Entity states.** An object is _transient_ (new, unknown to Hibernate), _managed_ (tracked by the persistence context), or _detached_ (was managed, but the transaction ended).

**3. Dirty checking.** Hibernate remembers what each managed entity looked like when loaded. At commit it compares, and if a field changed, it writes the `UPDATE` **automatically**:

```java
@Transactional
public void renameBook(Long id, String newTitle) {
    Book book = bookRepository.findById(id).orElseThrow();
    book.setTitle(newTitle);
    // no save() call needed: Hibernate detects the change and runs UPDATE at commit
}
```

**4. Delayed writing (flush).** Hibernate batches changes and sends the SQL at commit time (or before a query that needs it), not at each line of code.

**5. Lazy loading.** Related data is fetched **only when you touch it**. `book.getAuthor()` returns a placeholder (a proxy), and the real `SELECT` fires the first time you read a field from it.

This is why `@Transactional` from the PostgreSQL lesson matters so much: the transaction **is** the lifetime of the persistence context.

## Seeing what Hibernate does

Never treat it as a black box. Turn on the SQL log in `application.properties`:

```properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

You'll see every query it generates, which is the best way to learn and the best way to catch performance problems.

## Querying

```java
public interface BookRepository extends JpaRepository<Book, Long> {

    // Derived query: Spring builds it from the method name
    List<Book> findByYearGreaterThan(int year);

    // JPQL: SQL-like language over entities and fields, not tables and columns
    @Query("SELECT b FROM Book b WHERE b.title LIKE %:text%")
    List<Book> search(@Param("text") String text);

    // Native SQL when you need database-specific features
    @Query(value = "SELECT * FROM books WHERE year > ?1", nativeQuery = true)
    List<Book> raw(int year);
}
```

## JDBC vs Hibernate

||JDBC|Hibernate (JPA)|
|---|---|---|
|**You write**|SQL and mapping code|Annotated classes, few or no queries|
|**Control**|Total, you see every query|High-level, queries are generated|
|**Boilerplate**|Heavy|Light|
|**Learning curve**|Easy to start|Harder to master|
|**Performance**|Predictable|Fast if used well, traps if not|
|**Portability**|SQL differs per database|Handles many dialect differences|
|**Best for**|Simple queries, bulk operations, reports|Standard CRUD and object-heavy domains|

They are not rivals. Hibernate **is** JDBC underneath, and real projects often use both: JPA for everyday CRUD, and `JdbcTemplate` (Spring's cleaner JDBC wrapper) or native queries for heavy reports.

## Gotchas

- **The N+1 problem (the most famous Hibernate trap):** you load 100 books with one query, then access `book.getAuthor()` on each, and Hibernate fires 100 more queries, 101 in total. Fix it by fetching together with `JOIN FETCH` or `@EntityGraph`, and notice it by reading the SQL log.
- **`LazyInitializationException`:** you touch a lazy field after the transaction ended (the entity is detached), so Hibernate can no longer query. Fetch what you need inside the transaction, or better, return **DTOs** instead of entities.
- **Don't expose entities directly in REST responses.** Lazy fields, internal columns, and circular references (book to author to books...) cause errors and leaks. This is the DTO point from the real-projects lesson.
- **Mark relationships `LAZY`:** `@ManyToOne` is `EAGER` by default, which loads related data you may not need.
- **`ddl-auto=update` is for learning only.** For real projects use `validate` plus Flyway migrations, as covered in the PostgreSQL lesson.
- **`equals`/`hashCode` on entities** are tricky, because the `id` is `null` until saved. Careless implementations break sets and collections.
- **Hibernate is not a substitute for knowing SQL.** If you don't understand joins and indexes, you won't understand the queries it generates or why they're slow. Your CS50 SQL work pays off here.
- **Bulk operations are slow through entities:** updating a million rows by loading them as objects is far slower than one SQL `UPDATE`. Use a bulk query or JDBC for that.
- **Connection pooling:** Hibernate gets its connections from a pool (HikariCP in Spring Boot), as mentioned in the PostgreSQL lesson, not by opening one per request.

Say "next" to continue, or tell me if a specific part (persistence context, lazy loading, N+1) needs a simpler re-explanation.



[[Spring Framework]]
[[Java]]
[[Data-base]]