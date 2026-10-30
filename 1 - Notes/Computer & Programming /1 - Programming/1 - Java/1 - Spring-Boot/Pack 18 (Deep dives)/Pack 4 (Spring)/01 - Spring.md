

## The definition

**Spring Framework** is a Java application framework whose core is an **Inversion of Control (IoC) container**: it creates your objects, wires them together, and manages their lifecycle. Around that core it provides infrastructure such as transactions, data access, and web support, so your business code can stay **plain Java objects (POJOs)** with no dependency on framework APIs.

It came from Rod Johnson. In 2002 he published _Expert One-on-One J2EE Design and Development_, which included a working framework to show a better way of building enterprise apps. Developers and the open-source community turned that code into Spring. Version 1.0 shipped in March 2004.

## The problem: what enterprise Java looked like in 2002

The standard way to build business applications was **J2EE with EJB 2.x** (Enterprise JavaBeans). To write one service class, you needed:

- A **home interface** (for creating or finding the bean)
- A **remote or local interface** (the business methods)
- A **bean class** implementing `SessionBean`, with lifecycle callbacks you didn't care about: `ejbCreate`, `ejbActivate`, `ejbPassivate`, `ejbRemove`, `setSessionContext`
- An **XML deployment descriptor** (`ejb-jar.xml`) describing the bean

Your business logic was buried inside a class shaped entirely by the container's requirements. That caused four concrete problems.

**1. You couldn't unit test without a server.** The bean class depended on container types, and the container created and managed it. To test a discount calculation, you had to deploy to an application server, which took minutes per cycle. Tests became rare, and bugs surfaced late.

**2. Dependencies were found by lookup, which hard-wired you to the environment.** To get a database connection or another bean, code did this:

```java
Context ctx = new InitialContext();
DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/orders");
```

This is JNDI, a naming service that exists only inside a Java EE container. Every class that needed a collaborator repeated this ceremony and could only run where that JNDI tree existed.

**3. Data access was pure boilerplate.** Plain JDBC meant getting a connection, preparing a statement, setting parameters, executing, mapping the result set, then closing everything in nested `finally` blocks, because forgetting any close leaked connections. About 80% of the code was ritual and 20% was the actual query. Errors arrived as the checked `SQLException`, which told you almost nothing portable about what went wrong (a duplicate key and a dead connection looked the same).

**4. Everything was treated as distributed.** EJB assumed components might live on different machines, so even in-process calls got the weight of remote-call machinery. Most applications ran on a single server and paid that cost for nothing.

EJB did offer something valuable: **declarative transactions and security**. You could say "this method runs in a transaction" in configuration instead of writing begin/commit/rollback logic. But the price was the entire heavyweight model above.

## The core idea: the framework knows your classes, your classes don't know the framework

Look at what's wrong with a class that creates its own dependencies:

```java
public class OrderService {
    private final OrderRepository repo = new JdbcOrderRepository(); // fixed forever

    public void placeOrder(Order o) {
        repo.save(o);
    }
}
```

`OrderService` decides which repository implementation it uses. To test it, you need a real database. To swap implementations, you edit the class.

Now reverse the control:

```java
public class OrderService {
    private final OrderRepository repo;

    public OrderService(OrderRepository repo) {   // handed in from outside
        this.repo = repo;
    }

    public void placeOrder(Order o) {
        repo.save(o);
    }
}
```

`OrderService` now only knows the `OrderRepository` interface. In a unit test you write `new OrderService(new InMemoryOrderRepository())` and run it in milliseconds with no server or container. In production, something else decides to pass in the JDBC version. That something is the Spring container. This is **Dependency Injection**, the most common form of IoC, and it's the main idea behind Spring. The decision about which object to use moves out of your class and into configuration.

## The other pillars, each answering a specific EJB pain

**Template abstractions** removed the JDBC ritual. `JdbcTemplate` owns the connection, statement, and cleanup. You supply only the SQL and the row mapping:

```java
List<Order> orders = jdbcTemplate.query(
    "SELECT id, total FROM orders WHERE customer_id = ?",
    (rs, rowNum) -> new Order(rs.getLong("id"), rs.getBigDecimal("total")),
    customerId);
```

**Exception translation** replaced the opaque `SQLException` with a hierarchy of _unchecked_ exceptions (`DataAccessException` and subclasses like `DuplicateKeyException`). The same exception now means the same thing whether you use JDBC, Hibernate, or JPA, and you don't litter signatures with `throws`.

**AOP (Aspect-Oriented Programming)** delivered EJB's best feature without EJB. With `@Transactional`, Spring wraps your bean in a **proxy**: a generated object that sits in front of yours. Calling `placeOrder` actually enters the proxy, which opens a transaction, calls your real method, then commits, or rolls back if a runtime exception escapes. Your class contains zero transaction code. Security and caching work the same way.

**Consistent abstractions** such as `PlatformTransactionManager` let the same code run against a single JDBC datasource or a full JTA setup, so portability stopped depending on the app server.

## The philosophy behind the design

Johnson's stated goals shaped Spring's character: use POJOs, program to interfaces, make code testable by default, prefer unchecked exceptions, and wrap existing technology (JDBC, Hibernate, JMS, even EJB) instead of replacing it. Spring wasn't built to destroy Java EE. It was built to give you a clean way to use the useful parts.

## What happened next

Spring then had a problem of its own: configuration. Wiring was originally done in large XML files. Over time it moved to annotations (2.5, 2007) and Java-based config (3.0, 2009). Even then, setting up a web app meant writing a lot of boilerplate. **Spring Boot** (2014) addressed that with auto-configuration and starter dependencies. So you can think of it this way: Spring fixed the complexity of EJB, and Boot fixed the complexity of Spring. Meanwhile, EJB 3.0 (2006) and JPA copied many of Spring's ideas (DI, annotations, POJOs), which tells you how decisive the argument was.

## Nuances and gotchas worth knowing early

- **"Lightweight" means non-invasive.** It's about your classes not extending framework types, not about the framework being small.
- **DI doesn't require Spring.** The constructor example above works with plain `new`. Spring just automates the wiring at scale.
- **The trade-off:** annotations like `@Autowired` or `@Transactional` reintroduce _some_ framework coupling. It's far milder than EJB, but it isn't zero.
- **Proxy-based AOP has a famous trap:** if one method in a bean calls another method of the _same_ bean (`this.otherMethod()`), the call bypasses the proxy, so `@Transactional` on the second method silently does nothing.
- **Spring ≠ Spring Boot.** Boot is a layer that configures Spring for you. Everything described here still runs underneath.




[[Spring Framework]]