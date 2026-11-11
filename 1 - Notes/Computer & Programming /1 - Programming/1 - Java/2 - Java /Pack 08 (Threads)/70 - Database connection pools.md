

A **database connection pool** is a set of already-open database connections that your application keeps ready and lends out to code that needs to run SQL. Opening a connection to PostgreSQL is expensive: a TCP connection, authentication, session setup, and on the server side a whole backend process. Instead of paying that cost on every query, the pool opens connections once, hands one to your code, and takes it back when you're done. In Spring Boot the default pool is **HikariCP**, and it sits behind the `DataSource` you met in the JDBC lesson.

This topic matters beyond performance because the pool is a second, much smaller limit sitting behind Tomcat's worker pool. Tomcat can run 200 requests at once, but if the pool holds 10 connections, only 10 of them can talk to the database at the same moment. The rest wait. Understanding where that waiting happens explains most "the app freezes under load" problems.

## What `getConnection()` really does

Recall `DataSource.getConnection()` from the JDBC lesson. With a plain driver `DataSource`, it opens a brand new physical connection. With a pool, it borrows one:

```java
try (Connection c = dataSource.getConnection();            // borrow
     PreparedStatement ps = c.prepareStatement("select 1")) {
    ps.execute();
}                                                          // close() = return to pool
```

The important line is the last one. With a pool, `close()` does **not** close the physical connection. Hikari hands you a thin wrapper (a proxy, the same idea as the Spring proxies from the AOP lesson), and its `close()` just marks the connection as available again. Forgetting to close it is therefore not a small leak, it permanently removes one connection from the pool. That is why try-with-resources is non-negotiable in raw JDBC.

## The pool's life of one connection

Every pooled connection is in one of three states:

|State|Meaning|
|---|---|
|**in use**|Borrowed by a thread, executing or holding a transaction|
|**idle**|Open and waiting in the pool|
|**removed**|Closed (too old, broken, or pool shrinking)|

When a thread asks for a connection, Hikari does this:

1. If an idle connection exists, check it is still alive and hand it over.
2. Else, if the pool is below its maximum, open a new connection.
3. Else, **block the calling thread** until another thread returns one, or until `connectionTimeout` passes, then throw an exception.

Step 3 is the bridge to Tomcat. The thread that blocks is whichever thread called the repository.

## The settings

You saw the Hikari lines in the PostgreSQL configuration lesson. Here is what they mean for behaviour:

```properties
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=10
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000
spring.datasource.hikari.leak-detection-threshold=20000
```

- **`maximum-pool-size`** (default 10): the hard ceiling of connections. This is the number that matters most.
- **`minimum-idle`**: how many idle connections to keep. If you leave it unset, Hikari uses the same value as the maximum, giving a fixed-size pool, which its authors recommend.
- **`connection-timeout`** (default 30 seconds): how long a thread may wait in step 3 before failing with `SQLTransientConnectionException`.
- **`max-lifetime`** (default 30 minutes): a connection is retired after this age, even if healthy. Keep it a few minutes shorter than any timeout your database or firewall applies, so the pool retires connections before something kills them silently.
- **`idle-timeout`**: only applies when `minimum-idle` is lower than the maximum. It retires extra idle connections.
- **`leak-detection-threshold`** (off by default): logs a stack trace if a connection stays borrowed longer than this. Turn it on in development to find code that holds connections too long.

## How Tomcat threads and the pool interact

Put the two pools side by side. Tomcat has up to 200 workers (covered in the thread pool lesson), Hikari has 10 connections:

```
200 Tomcat workers  ──►  [ Hikari: 10 connections ]  ──►  PostgreSQL
```

Suppose each request runs a query that takes 100 ms. Ten connections, each serving 10 queries per second, give about **100 requests per second** of database throughput. Now send 200 simultaneous requests:

- 10 workers hold a connection and run their query.
- 190 workers call `getConnection()` and **block**, each still holding its Tomcat worker thread.
- After 30 seconds without a free connection, a waiting thread throws `SQLTransientConnectionException: Connection is not available, request timed out`, which your exception handler turns into a 500.

So under overload, Tomcat's 200 workers are not the bottleneck, they are _where the waiting is parked_. Threads you thought were handling requests are actually stuck in `getConnection()`. A thread dump during an incident shows many `exec-N` threads sitting in `HikariPool.getConnection`. That is the signature of an undersized pool or slow queries.

## When exactly a connection is borrowed

This is the part that surprises people. With Spring Data JPA, the connection is **not** borrowed when the request starts. It is borrowed when the first database work needs it, and released when the transaction ends:

```java
@Service
public class OrderService {

    @Transactional                      // transaction begins: connection borrowed here
    public OrderDto place(OrderRequest req) {
        // ...validate, query, save...
        return mapper.toDto(order);
    }                                   // commit, connection returned here
}
```

`@Transactional` (the proxy lesson) is what ties a connection to a thread for the whole method. Everything inside uses that one connection, which is how the commit or rollback covers all of it.

The danger is putting slow, non-database work inside the transaction:

```java
@Transactional
public void checkout(Order o) {
    orderRepo.save(o);                  // connection borrowed
    paymentClient.charge(o);            // HTTP call, 3 seconds, connection still held
    emailClient.send(o);                // another slow call, still held
}
```

For those seconds, one pool connection does nothing but wait. Ten such requests can empty the whole pool while the database sits idle. The fix is to keep transactions short: do remote calls outside the `@Transactional` method, and only open the transaction for the actual reads and writes.

## Open Session In View: a hidden connection holder

Spring Boot enables `spring.jpa.open-in-view=true` by default for web apps. It keeps the JPA `EntityManager`, and in many setups the connection, bound to the request thread until the **response is rendered**, so lazy fields can load in the controller or JSON serialization. The effect is that a connection can be held through your controller code and serialization, not just the service method. Under load, that makes the pool run dry sooner than the SQL timings suggest. Many production apps set:

```properties
spring.jpa.open-in-view=false
```

and load what they need inside the service layer, returning DTOs (as in the Entity/DTO/mapper lessons) instead of lazy entities.

## Sizing the pool

The instinct "200 workers, so I need 200 connections" is wrong, and usually harmful. PostgreSQL can only run as many queries truly in parallel as it has CPU cores and disk capacity. Past that point, extra connections add context switching and memory use on the **database server** and make everything slower. The Hikari documentation suggests a starting formula:

```
pool size ≈ (database CPU cores × 2) + effective disk spindles
```

For a small database server that gives a number around 10 to 20. Start there, then measure with Hikari's metrics:

```properties
management.endpoints.web.exposure.include=health,metrics
```

Watch `hikaricp.connections.active`, `hikaricp.connections.pending` (threads waiting right now), and `hikaricp.connections.acquire` (time spent waiting for a connection). If `pending` is regularly above zero and `acquire` time is growing, first look for slow queries and long transactions before raising the size. Also remember the database's own limit: PostgreSQL's `max_connections` defaults to 100, and every app instance multiplies your pool size. Three instances with a pool of 50 would already exceed it.

## Virtual threads and the pool

With `spring.threads.virtual.enabled=true`, the 200-worker ceiling disappears, so you can have thousands of requests in flight at once. All of them then compete for the same 10 connections. A virtual thread waiting in `getConnection()` is cheap, but the wait is still there. Virtual threads remove the _Tomcat_ limit; the connection pool becomes the single real concurrency limit, so its size and `connection-timeout` need deliberate choices.

## A related concept: connection pool vs thread pool

Both are pools of reusable, expensive resources, but they sit at different layers. A thread pool reuses threads that run code, a connection pool reuses sockets to a database. A request needs one thread for its whole life and a connection only for the part that talks to the database, which is why the two pools are sized differently and why holding a connection longer than necessary is the main way to starve the second one.



[[Threads]]
[[Data-base]]
[[Spring Framework]]