**Persistence** means keeping data alive beyond the run of your program. Data that lives only in Java objects sits in RAM, owned by the JVM process. When the process stops, whether from a restart, a crash, or a redeploy, that data is gone. Persisting data means writing it to storage that outlives the process, such as a file or a database, so the next run can load it back.

This is why CRUD only makes sense with persistence behind it. A `create` that lives only in a `List<Product>` has not really created anything lasting. In this tutorial you will see the difference in code, the main ways Java persists data, and what the word "persist" means in JPA, where it has a more specific meaning than you might expect.

## Transient vs persistent data

Look at this in-memory "repository":

```java
@Repository
public class InMemoryProductRepo {
    private final Map<Long, Product> store = new ConcurrentHashMap<>();
    private final AtomicLong ids = new AtomicLong();

    public Product save(Product p) {
        p.setId(ids.incrementAndGet());
        store.put(p.getId(), p);
        return p;
    }
}
```

It works while the app runs. Restart the app and `store` is empty again, because it is a plain object on the heap. That data is **transient**. Now compare it with a JPA repository:

```java
public interface ProductRepository extends JpaRepository<Product, Long> { }
```

`save()` now ends in an `INSERT` statement, PostgreSQL writes the row to disk, and the row is still there after a restart. That data is **persistent**.

The two classes can expose the same method names, but only one of them keeps the data. That is why the persistence layer you learned earlier is a separate layer: it is the only place where data crosses from memory to storage.

## The main ways to persist data in Java

|Approach|Where data goes|You write|Good for|
|---|---|---|---|
|Files (`Files.writeString`, serialization, JSON)|Disk files|Your own read/write code|Config, logs, small exports|
|JDBC|Database, via SQL|SQL + `PreparedStatement`|Full control, plain SQL|
|`JdbcTemplate`|Database, via SQL|SQL, without the boilerplate|SQL-first apps|
|JPA / Hibernate / Spring Data JPA|Database, via objects|Entities + repositories|Most Spring Boot apps|
|Redis and other stores|Memory-first or other databases|Commands/clients|Caching, special data shapes|

A tiny file example shows the idea in its simplest form:

```java
Path file = Path.of("counter.txt");

int count = Files.exists(file) ? Integer.parseInt(Files.readString(file).trim()) : 0;
count++;
Files.writeString(file, String.valueOf(count));
System.out.println("Run number " + count);
```

Run it three times and it prints 1, 2, 3. The number survives because it went to a file, not a variable. A database does the same thing, but adds structure, queries, transactions and concurrent access, which files do not give you.

## What "persist" means in JPA

In JPA, `persist` has a precise meaning that trips up many beginners. It does not mean "write to the database right now". It means "make this object **managed**, and schedule an `INSERT`".

```java
@Transactional
public void demo(EntityManager em) {
    Product p = new Product("Keyboard", new BigDecimal("49.90")); // 1. transient: JPA doesn't know it
    em.persist(p);                                                // 2. managed: JPA tracks it, INSERT is scheduled
    p.setPrice(new BigDecimal("39.90"));                          // 3. still managed: change is tracked
}                                                                 // 4. commit: flush happens, SQL runs
```

Step by step:

1. `new Product(...)` is a plain Java object. JPA has no idea it exists. This is the **transient** state.
2. `em.persist(p)` puts it under the `EntityManager`'s control. It is now **managed**. With `IDENTITY` ids, Hibernate may run the `INSERT` immediately to get the id. In other cases it waits.
3. Changing a managed object needs no extra call. This is the dirty checking you saw in the CRUD lesson.
4. On commit, JPA **flushes** pending changes to the database. This is the point where SQL is sent for real.

So there are two moments, and they differ: the object becomes managed at `persist`, and the data becomes durable at **commit**. If the transaction rolls back, nothing persists, even though you called `persist()`. Spring Data's `save()` calls `persist` for new entities and `merge` for existing ones, which is why one method handles both create and update.

## A related concept in one short summary

**ORM (Object-Relational Mapping)** is what lets you persist objects instead of writing SQL by hand. It maps a class to a table, a field to a column, and an object to a row. JPA is the specification, and Hibernate is the implementation Spring Boot uses by default. You write the `@Entity`, and the ORM generates the `INSERT`, `SELECT`, `UPDATE` and `DELETE` for you. The price is that you must understand what it generates, because the SQL is no longer in your code.


[[Spring Framework]]