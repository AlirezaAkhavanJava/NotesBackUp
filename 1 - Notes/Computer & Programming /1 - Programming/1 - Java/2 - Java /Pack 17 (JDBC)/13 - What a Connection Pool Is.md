
Opening a connection to a database isn't cheap. It means a TCP handshake, authentication, and the database server setting up session state for you — this can take tens of milliseconds. If your app opened and closed a brand new connection for every single query, you'd be paying that cost over and over, and under load this becomes a serious bottleneck.

A **connection pool** solves this by keeping a set of database connections open and ready to reuse. Instead of opening a new connection per request, your app borrows an already-open connection from the pool, runs its query, and gives it back. Nothing gets torn down — the connection just sits there waiting for its next borrower.

## HikariCP

Spring Boot ships with **HikariCP** as its default connection pool implementation (it's on the classpath automatically with `spring-boot-starter-data-jpa` or `spring-boot-starter-jdbc`). It's known for being fast and lightweight compared to older pools like Apache DBCP or C3P0.

You configure it through normal Spring Boot properties, prefixed `spring.datasource.hikari.*`:

```properties
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000
spring.datasource.hikari.connection-timeout=30000
```

Here's what each of these actually controls:

- **`maximum-pool-size`** — the hard ceiling on how many connections the pool will ever hold open at once, idle or in use. This is the single most important setting.
- **`minimum-idle`** — the minimum number of idle (unused) connections Hikari tries to keep ready, so a sudden burst of requests doesn't have to wait for new connections to be opened from scratch. Hikari's own docs recommend just setting this equal to `maximum-pool-size` (a fixed-size pool) for most cases, since it behaves more predictably.
- **`idle-timeout`** — how long (ms) a connection is allowed to sit idle in the pool before Hikari closes it, if the pool currently has more than `minimum-idle` connections open.
- **`max-lifetime`** — the maximum age (ms) a connection is allowed to live, even while actively in use, before Hikari retires it and opens a replacement. This matters because databases (and things like load balancers or firewalls in front of them) often silently kill connections that have been open too long — retiring them proactively avoids your app hitting a dead connection.
- **`connection-timeout`** — how long (ms) a thread will wait for a connection to become available from the pool before giving up and throwing an exception.

In code, you can reach the same configuration directly if you're building the `DataSource` as a bean yourself:

```java
@Bean
public DataSource dataSource() {
    HikariConfig config = new HikariConfig();
    config.setJdbcUrl("jdbc:postgresql://localhost:5432/trash");
    config.setUsername("ethan");
    config.setMaximumPoolSize(10);
    config.setMinimumIdle(10);
    return new HikariDataSource(config);
}
```

## How Borrowing Actually Works

When your code needs to talk to the database — say, inside a repository method — it asks the pool for a connection. The pool hands over one of its already-open connections. Your code uses it, and when it's released (Spring does this for you automatically at the end of a transaction or query), it goes back into the pool's idle set instead of being closed. The next piece of code that needs a connection gets that same physical connection, recycled.

If every connection in the pool is currently checked out and a new request comes in needing one, that request's thread **blocks** — it just waits — until either a connection is returned, or `connection-timeout` is reached, at which point it fails with a `SQLTransientConnectionException`.

## Why Pool Size Interacts With Tomcat Threads

This is the part that actually matters for sizing your pool correctly in a Spring Boot app, and it ties directly into your thread management lessons.

Tomcat runs a pool of worker threads to handle incoming HTTP requests (bounded by `server.tomcat.threads.max`, default 200). Each incoming request gets assigned one Tomcat worker thread for its entire duration. If that request's handling involves a database call — which most do — that same thread needs to borrow a connection from the Hikari pool for as long as the query takes, then release it.

Here's the problem this creates: if Tomcat can run far more concurrent request-handling threads than Hikari has connections available, you get **thread contention at the pool**. Imagine Tomcat has 200 worker threads and Hikari's `maximum-pool-size` is 10. Under real load, you could have 200 requests all trying to run a DB query at once, but only 10 of them can actually be holding a connection at any given moment. The other 190 threads are just sitting there blocked, waiting on `connection-timeout`, doing nothing useful — they're occupying Tomcat worker threads without making progress, which means new incoming HTTP requests can't even get picked up because all 200 Tomcat threads are stuck waiting on a scarce resource of only 10.

So the two pools need to be sized with each other in mind, not independently. A common approach:

```properties
server.tomcat.threads.max=50
spring.datasource.hikari.maximum-pool-size=20
```

The exact ratio depends on your database server's actual capacity (how many concurrent connections _it_ can handle) and how long your typical queries take — a pool that's too large doesn't help if the database itself chokes on that many simultaneous connections, since each DB connection also costs the database server memory and CPU to maintain.

## Monitoring Pool Health

Hikari exposes metrics (through Micrometer, if you're using Spring Boot Actuator) that let you watch this in production rather than guess at the right numbers:

- `hikaricp.connections.active` — connections currently checked out
- `hikaricp.connections.idle` — connections sitting ready
- `hikaricp.connections.pending` — threads currently blocked, waiting for a connection

If `pending` is consistently above zero under normal load, that's your signal the pool is undersized relative to demand.


[[Java]]