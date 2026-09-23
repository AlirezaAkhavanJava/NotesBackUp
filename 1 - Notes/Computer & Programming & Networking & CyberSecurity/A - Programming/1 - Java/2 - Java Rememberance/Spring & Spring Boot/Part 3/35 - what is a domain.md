
In Spring Boot (and Java/OOP generally), a **domain** refers to the core business objects your application is modeling — the real-world "things" your app cares about, independent of frameworks, databases, or web stuff.

## The idea

If you're building a bookstore app, your domain is things like `Book`, `Author`, `Order`, `Customer` — the actual concepts of the business, not technical plumbing like controllers or repositories.

A **domain class** (often called a domain model or entity) is a plain Java class representing one of these concepts:

```java
public class Book {
    private Long id;
    private String title;
    private String author;
    private BigDecimal price;

    // getters, setters, and maybe some business logic
    public boolean isExpensive() {
        return price.compareTo(new BigDecimal("50")) > 0;
    }
}
```

## Where it fits in a typical Spring Boot project

You'll often see a package structure like:

```
com.example.bookstore
├── domain/          ← Book, Author, Order (the business objects)
├── repository/       ← BookRepository (data access)
├── service/           ← BookService (business logic)
├── controller/        ← BookController (handles HTTP requests)
└── dto/                ← BookDTO (data shape for API responses)
```

The `domain` package holds your **entities** — if you're using Spring Data JPA, these classes are usually annotated with `@Entity` so they map to database tables:

```java
@Entity
public class Book {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String author;
    // ...
}
```

## Domain vs. DTO — a common point of confusion

- **Domain object**: the "true" business entity, often tied to your database (via JPA).
- **DTO (Data Transfer Object)**: a separate class used to send data over the API, which may hide or reshape fields (e.g., not exposing internal IDs or sensitive info).

You usually don't want to expose your domain/entity classes directly in your REST API — that's why people map domain → DTO before sending a response.

## Domain-Driven Design (a step further)

If you dig deeper into Spring Boot architecture, you'll hear the term **Domain-Driven Design (DDD)**. There, "domain" means something a bit more formal: the domain layer is the innermost layer of your app, containing entities, value objects, and business rules — completely isolated from frameworks, databases, or the web layer. Spring Boot doesn't enforce DDD, but many production apps structure their packages this way to keep business logic decoupled from technical details.



[[Java]]
[[0 - Spring Framework]]