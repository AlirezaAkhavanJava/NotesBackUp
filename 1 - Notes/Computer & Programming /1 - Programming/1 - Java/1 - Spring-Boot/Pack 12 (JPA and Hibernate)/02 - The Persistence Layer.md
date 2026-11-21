

The **persistence layer** is the part of your application that talks to the database. Its whole job is to save data so it survives after your program stops, and to load that data back when you need it. "Persist" simply means "make it last." Without this layer, everything your app knows would disappear the moment you restarted it.

In a Spring Boot app, the persistence layer is the code made of your **entities** and your **repositories**, plus the database access underneath them (JPA, Hibernate, JDBC, the driver, and the database itself). The rest of your app doesn't need to know how data is stored. It just asks this layer to "save this" or "find that."

---

## Where it sits: layered architecture

Most Spring apps are split into layers. Each layer talks only to the one right below it.

```
Client (browser, mobile app)
        │  JSON
        ▼
┌─────────────────────────┐
│ Presentation layer      │  Controllers, request/response DTOs
├─────────────────────────┤
│ Service layer           │  Business rules, transactions, mappers
├─────────────────────────┤
│ Persistence layer       │  Entities, repositories      ◄── this lesson
├─────────────────────────┤
│ Database                │  PostgreSQL, SQLite, ...
└─────────────────────────┘
```

This connects to what you just learned. The **entity** lives in the persistence layer. The **DTO** lives in the presentation layer. The **mapper** is the translator between them, and it is usually called from the service layer. Now you can see why we kept them separate: they belong to different layers.

---

## What it is made of

|Piece|What it does|Example|
|---|---|---|
|**Entity**|A Java class that mirrors a table|`Product`|
|**Repository**|An interface with methods to save, find, update, delete|`ProductRepository`|
|**ORM / JPA provider**|Translates between objects and rows|Hibernate|
|**JDBC driver and DataSource**|Opens connections and sends SQL|PostgreSQL driver, HikariCP|
|**Database**|Stores the actual data|PostgreSQL|

Each one hands work to the one below it. Your code calls the repository, the repository uses Hibernate, Hibernate builds SQL, JDBC sends it, and the database runs it.

---

## What it looks like in code

In Spring Data JPA, the repository can be just an interface. Spring writes the implementation for you.

```java
public interface ProductRepository extends JpaRepository<Product, Long> {

    List<Product> findByCategoryName(String categoryName);

    Optional<Product> findByNameIgnoreCase(String name);

    @Query("select p from Product p where p.price between :min and :max")
    List<Product> findInPriceRange(BigDecimal min, BigDecimal max);
}
```

Line by line:

- `extends JpaRepository<Product, Long>` gives you ready-made methods: `save`, `findById`, `findAll`, `deleteById`, `count`, and more. `Product` is the entity type. `Long` is the type of its id.
- `findByCategoryName(...)` is a **derived query**. Spring reads the method name and builds the query itself: find products whose category's name matches.
- `Optional<Product>` means "there might be no result", so you are forced to handle that case.
- `@Query` lets you write your own query (in JPQL) when a method name would get too long or too complicated.

You never write `SELECT ... FROM products` or open a connection yourself. That is the benefit of this layer.

---

## What belongs here, and what doesn't

The persistence layer should stay focused. Here is how to tell what goes where.

|Belongs in the persistence layer|Does NOT belong here|
|---|---|
|Entity classes and their mappings|Business decisions ("is this customer allowed a discount?")|
|Queries: find, filter, sort, paginate|JSON or HTTP concerns|
|Relationships and fetch strategies|Request validation for one endpoint|
|Database-specific tuning (indexes, native queries)|Calling other services or sending emails|

A good test: if you changed the database from PostgreSQL to something else, only this layer should need to change. The services above it would keep working.

---

## Why bother with a separate layer?

1. **Swappable storage.** Your services depend on a repository interface, not on SQL. You can change databases, or add a cache like Redis in front, without rewriting business logic.
2. **Easy testing.** You can test a service by giving it a fake repository, with no real database needed.
3. **One place for data rules.** All queries live in one spot, so you can find and optimize them (for example, fixing N+1 query problems) without hunting through controllers.
4. **Cleaner code above.** Services say `productRepository.findById(id)` and read like plain sentences.

---

## The usual mistakes

- **Putting business logic in repositories.** A repository should fetch and store, not decide.
- **Calling repositories directly from controllers.** This skips the service layer, so you lose the transaction boundary and a good place for rules.
- **Letting entities escape upward.** Returning entities to the client leaks your table design. Use DTOs, as in the last lesson.
- **Forgetting that "persistence layer" is more than SQL.** Files, a Redis cache, or a search engine can also be persistence, and they hide behind the same kind of interface.

---

## A related concept: DAO vs Repository

You will see two names for the same idea. A **DAO** (Data Access Object) is the older pattern: a class with methods like `insert`, `update`, `delete` for one table, usually written with plain JDBC. A **Repository** is the newer, more object-oriented version: it acts like a collection of entities ("give me all products in this category"). In Spring Data, you almost always write repositories, and Spring generates the code the old DAO used to need.





[[Spring Framework]]