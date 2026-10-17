
**ORM (Object–Relational Mapping)** is a **programming technique** that establishes a **mapping between object-oriented models and relational database systems**.

In theory, it allows software to **convert data between incompatible systems** — objects in an object-oriented language and tables in a relational database — **automatically**.

ORM frameworks handle this mapping by representing database tables as **classes**, table rows as **objects**, and table columns as **object fields**. This enables developers to work with database data in the form of objects, rather than writing SQL queries manually.

In short:

> ORM is a theoretical concept that abstracts the database layer, allowing object-oriented programs to interact with relational data using object semantics instead of relational ones.

---


An ORM lets you work with database rows as ordinary objects in your code, so you don't have to write SQL by hand for every simple operation.

## The problem it solves

Your Java code thinks in **objects**: a `User` with a name, an email, and a list of `Order` objects. Your database thinks in **tables and rows**: a `users` table, an `orders` table, and a foreign key linking them.

These two worlds don't line up neatly. Without an ORM, you write a lot of glue code by hand. You run a SQL query, read each column out of the result set, and copy the values into a `User` object. To save, you do the reverse. This is tedious and easy to get wrong. People call the gap between the two worlds the **object-relational impedance mismatch**. That's just a fancy name for "objects and tables are shaped differently."

An ORM does that translation for you. The "mapping" is a set of rules you give it: this class maps to that table, this field maps to that column.

## What it looks like in Java

In the Java world, the standard is **JPA** (Jakarta Persistence API). **Hibernate** is the most common implementation of it. Spring Boot's `spring-boot-starter-data-jpa` gives you both.

You describe the mapping with annotations:

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String email;

    @OneToMany(mappedBy = "user")
    private List<Order> orders;

    // getters and setters
}
```

`@Entity` tells the ORM that this class represents a table. `@Id` marks the primary key. `@OneToMany` describes the relationship to orders.

Then you use it like normal Java:

```java
User user = userRepository.findById(1L).orElseThrow();
user.setEmail("new@example.com");
userRepository.save(user);
```

You never wrote `SELECT` or `UPDATE`. The ORM generated that SQL for you and ran it against PostgreSQL (or SQLite, or whatever you use).

## What the ORM does behind the scenes

A good ORM handles several jobs at once:

- **Generates SQL** for inserts, updates, deletes, and lookups.
- **Converts types** between database columns and Java fields.
- **Tracks changes.** Hibernate notices when you modify a loaded object and writes the change back at the end of the transaction. You don't even need to call `save` in some cases.
- **Loads relationships.** When you call `user.getOrders()`, it can fetch the orders for you.
- **Works across databases.** Switching from SQLite to PostgreSQL mostly means changing a dialect and a connection setting, not rewriting queries.

## The catches

ORMs are convenient, but they hide the SQL, and hidden things can bite you. Here are the ones you'll meet most often.

**The N+1 problem.** Say you load 100 users, then loop over them and call `getOrders()` on each. The ORM may run 1 query for the users and then 100 more, one per user. That's 101 queries instead of 1 join. The fix is to fetch the data together, for example with `JOIN FETCH` or an entity graph.

**Lazy loading surprises.** By default, relationships are often loaded only when you first touch them. If the database session has already closed by then, you get a `LazyInitializationException`.

**Performance on complex queries.** For heavy reports or tricky joins, the generated SQL may not be what you'd write yourself. Many projects use the ORM for everyday CRUD and drop down to native SQL for the hard cases. JPA supports that directly.

**A learning curve of its own.** Hibernate has many concepts, such as persistence context, cascading, and entity states. Using it well takes some study.

## ORM vs. writing SQL yourself

||ORM (JPA/Hibernate)|Plain SQL (JDBC)|
|---|---|---|
|Speed of writing simple code|Fast|Slow, lots of boilerplate|
|Control over the exact query|Less|Total|
|Easy to see what's running|You must turn on SQL logging|Obvious|
|Good for|CRUD-heavy apps|Reports, tuned queries|

Many developers combine them: ORM for the routine work, hand-written SQL where it matters.

## A practical tip

When you start with an ORM, turn on SQL logging so you can see what it's running. In Spring Boot, add this to `application.properties`:

```properties
spring.jpa.show-sql=true
```

Seeing the real queries is the best way to learn what your annotations do, and the fastest way to catch an N+1 problem.




[[Spring Framework]]