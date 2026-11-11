

A scalable Spring Boot application is one where every unit of work runs on a thread pool _sized and bounded for that kind of work_, and where every piece of data lives in the store that suits how it is read and written. Part 1 covers the threads: which pools exist, how to separate them, and how to size them. Part 2 covers the data: PostgreSQL as the permanent source of truth, Redis as a fast, disposable layer in front of it.

The two parts are one design, not two. Your Tomcat workers, executors, Hikari connections and Redis calls form a chain, and the chain is only as strong as its smallest, unbounded, or slowest link. The last section follows one request through all of them with real numbers.

---

# Part 1: Designing threads

## Which threads exist in a Boot app

You've met most of these already. Here they are as one map:

|Threads|Created by|Default size|Runs|
|---|---|---|---|
|`http-nio-8080-exec-N`|Tomcat|up to 200|Your controller → service → repository chain|
|`task-N`|Boot's `applicationTaskExecutor`|8 core, unbounded queue|`@Async` methods, if you define no executor of your own|
|`scheduling-N`|Boot's task scheduler|**1**|`@Scheduled` methods|
|Hikari housekeeper|HikariCP|1|Pool maintenance, not your code|
|Lettuce event loop (`lettuce-nioEventLoop-N`)|Redis client|few|Redis network I/O|

Two defaults deserve a second look. The scheduler has a pool of **one thread**, so one slow `@Scheduled` job delays every other job. And `applicationTaskExecutor` has an _unbounded queue_, so its max size never matters: it never grows past 8 threads, and under overload tasks pile up in memory instead of failing.

## The design rule: one pool per kind of work

Different work fails in different ways, so it should not share a pool. When a slow third-party API fills a shared pool, your fast tasks queue behind it. Splitting pools limits the damage to one area (this is called a _bulkhead_).

|Kind of work|Where it runs|Sizing|
|---|---|---|
|Handling HTTP requests|Tomcat workers (or virtual threads)|`threads.max`, from the Tomcat lessons|
|CPU-heavy (password hashing, image resizing, big JSON transforms)|Dedicated pool, bounded|About the number of cores|
|Blocking calls to slow external services|Own pool per dependency, or virtual threads plus a limit|By what the _dependency_ can take|
|Periodic jobs|Scheduler pool|Number of jobs that may overlap|
|Work that must not be lost|**Not a thread**: a durable queue (see the outbox note below)|-|

Remember the bcrypt lesson: hashing is deliberately CPU-heavy. A login burst running bcrypt on all 200 Tomcat workers can starve everything else on the machine.

## Sizing with a formula

Two cases cover most pools:

- **CPU-bound work**: threads ≈ cores (maybe +1). More threads only add context switching.
- **Blocking I/O work**: threads ≈ cores × (1 + wait time ÷ compute time). A task that computes 5 ms and waits 95 ms on I/O can keep about 20 threads per core busy.

The sharper tool is **Little's law**: _concurrent requests = arrival rate × time each takes_. If 500 tasks/second arrive and each takes 40 ms, you need about 500 × 0.04 = 20 threads busy on average, plus headroom for bursts.

## Building the pools

```java
@Configuration
@EnableAsync
public class AsyncConfig {

    @Bean("ioExecutor")
    public ThreadPoolTaskExecutor ioExecutor() {
        var ex = new ThreadPoolTaskExecutor();
        ex.setThreadNamePrefix("io-");
        ex.setCorePoolSize(16);
        ex.setMaxPoolSize(32);
        ex.setQueueCapacity(200);                                  // bounded
        ex.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        ex.setTaskDecorator(new MdcTaskDecorator());
        ex.setWaitForTasksToCompleteOnShutdown(true);
        ex.setAwaitTerminationSeconds(30);
        return ex;
    }

    @Bean("cpuExecutor")
    public ThreadPoolTaskExecutor cpuExecutor() {
        int cores = Runtime.getRuntime().availableProcessors();
        var ex = new ThreadPoolTaskExecutor();
        ex.setThreadNamePrefix("cpu-");
        ex.setCorePoolSize(cores);
        ex.setMaxPoolSize(cores);
        ex.setQueueCapacity(100);
        ex.setRejectedExecutionHandler(new ThreadPoolExecutor.AbortPolicy());  // fail loudly
        return ex;
    }
}
```

Line by line, the choices that matter:

- **Bounded queue + explicit rejection policy.** When pool and queue are full, `CallerRunsPolicy` runs the task on the calling thread, which slows the caller and so pushes back on incoming load. `AbortPolicy` throws `RejectedExecutionException`, which you can turn into a 503. Never use an empty handler: it silently drops tasks.
- **Remember the growth rule from the `@Async` lesson:** the pool grows past core size only when the queue is full. A big queue with a small core means you effectively never get more threads.
- **Thread name prefix** (`io-`, `cpu-`): without it, thread dumps and logs can't tell your pools apart.
- **Graceful shutdown:** `setWaitForTasksToCompleteOnShutdown` plus `awaitTerminationSeconds` lets running tasks finish on deploy. Pair it with `server.shutdown=graceful` so Tomcat also drains in-flight requests.

Always name the executor at the use site:

```java
@Async("ioExecutor")
public CompletableFuture<Receipt> sendReceipt(Order o) { ... }
```

This matters more once you define your own executors. Boot's default `applicationTaskExecutor` backs off when you declare an `Executor` bean, and an un-named `@Async` with no single obvious executor can fall back to `SimpleAsyncTaskExecutor`, which starts a **new thread for every call**. Naming the executor removes that risk.

## What does not cross to another thread

Moving work to another thread silently drops three things that live in `ThreadLocal`s:

|Lost on the new thread|Consequence|Fix|
|---|---|---|
|The transaction|The `@Async` method runs in its own transaction, or none|Design it as an independent unit of work|
|`SecurityContext`|`getAuthentication()` returns null|Wrap the executor in `DelegatingSecurityContextAsyncTaskExecutor`|
|Logging `MDC` (trace ids, user ids)|Logs lose their correlation id|A `TaskDecorator`|

```java
public class MdcTaskDecorator implements TaskDecorator {
    @Override
    public Runnable decorate(Runnable task) {
        Map<String, String> ctx = MDC.getCopyOfContextMap();   // captured on the caller thread
        return () -> {
            try {
                if (ctx != null) MDC.setContextMap(ctx);       // restored on the worker thread
                task.run();
            } finally {
                MDC.clear();                                   // pooled threads are reused
            }
        };
    }
}
```

The transaction row has a design consequence: never start a transaction, hand work to another thread, and expect it to see your uncommitted data. It can't, because it is a different connection.

## The scheduler

```properties
spring.task.scheduling.pool.size=4
spring.task.scheduling.thread-name-prefix=sched-
```

Set the size to at least the number of jobs that may legitimately overlap. When you run **several app instances**, every instance fires every `@Scheduled` job, so a nightly cleanup runs N times. For jobs that must run once across the cluster, use a database-backed lock (ShedLock is the common library) or a single dedicated instance.

## Virtual threads as the alternative design

For mostly-blocking I/O code, the simpler design is:

```properties
spring.threads.virtual.enabled=true
```

Tomcat request handling, the `@Async` executor and `@Scheduled` then all run on virtual threads, and you stop hand-tuning pool sizes for blocking work. What changes is _where the limit lives_. With cheap threads, nothing in the thread layer slows callers down anymore, so you must bound the things that really are scarce yourself:

```java
private final Semaphore paymentApiSlots = new Semaphore(20);   // the provider tolerates ~20 parallel calls

public Receipt charge(Order o) throws InterruptedException {
    paymentApiSlots.acquire();
    try { return paymentClient.charge(o); }
    finally { paymentApiSlots.release(); }
}
```

Do not put virtual threads in a pool (they are meant to be created per task), and CPU-heavy work still needs a bounded pool, since virtual threads don't add CPU.

## Related concept: the outbox pattern

An `@Async` task lives in memory, so a restart or crash loses it. For work that must happen (send the confirmation email, publish the event), insert a row into an `outbox` table _in the same transaction_ as your business change, then let a worker read and process unsent rows. The row is committed or rolled back together with your data, so nothing is lost and nothing is sent for a rolled-back order.

---

# Part 2: Designing the database layer (PostgreSQL + Redis)

## Who owns what

One rule drives the whole design: **PostgreSQL is the source of truth, Redis is a disposable copy.** If someone flushes Redis, the application must still be correct, only slower for a while. Anything that cannot be rebuilt from PostgreSQL does not belong in a cache.

## PostgreSQL: designing for growth

Basics like DDL, schemas, `@Table` and `@GeneratedValue` were covered earlier. This section covers the decisions that change how far the database scales.

### Model first, denormalize on evidence

Start normalized, with correct types, constraints and foreign keys. Denormalize (duplicate a column, store a precomputed total) only for a measured hot path, because every copy is something you must keep in sync.

### Choose the primary key with the index in mind

Primary keys live in a B-tree index. Random UUIDs (version 4) insert at random positions, which fragments the index and hurts write speed on big tables. Time-ordered keys append near the end instead:

- `bigint` identity or sequence: smallest and fastest.
- **UUIDv7**: time-ordered and still globally unique, useful when ids are generated outside the database. PostgreSQL 18 added a built-in `uuidv7()`.

### Indexes: design them from your queries

```sql
-- the query: a customer's newest orders
create index idx_orders_customer_created
    on orders (customer_id, created_at desc, id desc);
```

- **Composite index order**: equality columns first (`customer_id`), then the range or sort column (`created_at`).
- **Foreign keys are not indexed automatically in PostgreSQL.** Index them yourself, or deletes and joins on the parent scan the child table.
- **Partial indexes** cover only the rows you query: `create index ... on orders (created_at) where status = 'PENDING'`.
- Each index slows every write, so create indexes for real queries, not "just in case".
- Verify with `EXPLAIN (ANALYZE, BUFFERS)`: you want an index scan, not a sequential scan over millions of rows.

### Paginate with a keyset, not OFFSET

`OFFSET 100000` makes PostgreSQL read and throw away 100,000 rows, so deep pages get slower and slower. A keyset query remembers where the last page ended and uses the index to jump there:

```java
@Query("""
    select new com.example.OrderRow(o.id, o.total, o.createdAt)
    from Order o
    where o.customerId = :cid
      and (o.createdAt < :lastCreated
           or (o.createdAt = :lastCreated and o.id < :lastId))
    order by o.createdAt desc, o.id desc
    """)
List<OrderRow> nextPage(Long cid, Instant lastCreated, Long lastId, Limit limit);
```

The `where` clause matches the index above, so each page costs about the same however deep the user scrolls. It returns a DTO projection (`OrderRow`), so you skip loading full entities.

### Keep transactions short, protect concurrent updates

Everything from the connection pool lesson applies: no HTTP calls inside `@Transactional`, and `open-in-view=false`. For concurrent edits of the same row, prefer optimistic locking over long locks:

```java
@Entity
public class Product {
    @Id private Long id;
    @Version private long version;     // Hibernate adds "where version = ?" to every update
}
```

If two requests update the same row, the second one throws `OptimisticLockingFailureException`. Map it to a `409 Conflict` in your `@RestControllerAdvice`. For "do this only once" rules (an idempotency key, one active subscription per user), use a **unique constraint**: the database enforces it correctly across all app instances, which no Java-side check can.

### Batch your writes

```properties
spring.jpa.properties.hibernate.jdbc.batch_size=50
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true
```

`GenerationType.IDENTITY` disables JDBC insert batching, because Hibernate must run each insert to learn its id. Use `SEQUENCE` with an `allocationSize` matching the batch size (the `@GeneratedValue` lesson). Adding `reWriteBatchedInserts=true` to the JDBC URL lets the PostgreSQL driver combine the batch into fewer statements.

### Scaling PostgreSQL in the right order

Each step costs more complexity, so go in this order and stop when the problem is solved:

1. **Fix queries and indexes.** Most "we need to scale" problems end here.
2. **Bigger machine** (CPU, RAM, fast disks).
3. **Read replicas**: copies that receive changes by streaming replication and serve read-only queries.
4. **Partitioning**: split one huge table (usually by time) into pieces inside the same database.
5. **Sharding**: split data across separate databases. Last resort.

**Read replicas in Spring** route by transaction type. Spring already knows when a method is read-only:

```java
public class RoutingDataSource extends AbstractRoutingDataSource {
    @Override
    protected Object determineCurrentLookupKey() {
        return TransactionSynchronizationManager.isCurrentTransactionReadOnly()
                ? "replica" : "primary";
    }
}
// register: new LazyConnectionDataSourceProxy(routingDataSource)
```

`@Transactional(readOnly = true)` on a service method sends it to the replica. The `LazyConnectionDataSourceProxy` wrapper is required: it delays fetching the real connection until the first SQL runs, _after_ Spring has set the read-only flag (the proxy idea again). Each target should have its own Hikari pool.

The catch is **replication lag**: a replica may be milliseconds behind. A user who saves a profile and immediately reloads it from a replica can see old data. Read from the primary for the user's own just-written data.

**Partitioning** suits append-only tables such as events, logs or orders:

```sql
create table events (
    id         bigint generated always as identity,
    created_at timestamptz not null,
    payload    jsonb,
    primary key (id, created_at)          -- the partition key must be part of the primary key
) partition by range (created_at);

create table events_2026_11 partition of events
    for values from ('2026-11-01') to ('2026-12-01');
```

Queries filtered by `created_at` touch only the relevant partitions, and old data is removed by detaching or dropping a whole partition, which is instant compared with a huge `DELETE`.

**Schema changes without downtime**: with Flyway, use _expand then contract_. First add the new column (nullable), deploy code that writes both, backfill, switch reads, and only later drop the old column. Never rename a column in one step while old and new app instances run side by side.

## Redis: designing the fast layer

### What Redis is good at

Redis keeps data in memory and executes commands one at a time on a main thread, so single operations take microseconds. The data structure you pick decides what it's good for:

|Need|Redis structure|
|---|---|
|Cache an object|String (JSON) with a TTL|
|Counter, rate limit|`INCR` + `EXPIRE`|
|Leaderboard, top-N|Sorted set|
|User sessions (Spring Session)|Hash|
|Events, background jobs|Stream|
|Short-lived lock|`SET key value NX PX 30000`|

### Cache-aside: the standard pattern

The application, not Redis, controls the flow: read the cache; on a miss, read PostgreSQL, then store the result in Redis with a TTL. On writes, update PostgreSQL first, then remove the cached copy. Spring wraps this in annotations:

```java
@Configuration
@EnableCaching
public class CacheConfig implements CachingConfigurer {

    @Bean
    RedisCacheManager cacheManager(RedisConnectionFactory cf) {
        var defaults = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofMinutes(10))
                .disableCachingNullValues()
                .prefixCacheNameWith("shop:v1:")                     // app name + schema version
                .serializeValuesWith(RedisSerializationContext.SerializationPair
                        .fromSerializer(RedisSerializer.json()));    // readable JSON, not Java serialization

        return RedisCacheManager.builder(cf)
                .cacheDefaults(defaults)
                .withCacheConfiguration("products", defaults.entryTtl(Duration.ofHours(1)))
                .transactionAware()                                  // explained below
                .build();
    }

    @Override
    public CacheErrorHandler errorHandler() { return new LenientCacheErrorHandler(); }
}
```

```java
@Service
public class ProductService {

    @Cacheable(cacheNames = "products", key = "#id", sync = true, unless = "#result == null")
    public ProductDto get(long id) {
        return repo.findById(id).map(mapper::toDto).orElse(null);    // runs only on a miss
    }

    @CacheEvict(cacheNames = "products", key = "#id")
    @Transactional
    public ProductDto update(long id, UpdateProduct req) { ... }
}
```

Design rules built into these lines:

- **Cache DTOs, not entities.** Entities carry lazy proxies and can't be serialized safely, and a DTO gives you a stable shape.
- **Every entry has a TTL**, so a missed invalidation heals itself. Different data gets a different TTL.
- **Key prefix with a version** (`shop:v1:`). When the cached JSON shape changes, bump to `v2` and old entries are ignored instead of failing to deserialize.
- **`sync = true`** makes concurrent misses for the same key in _one JVM_ wait for a single loader instead of all hitting PostgreSQL (a cache stampede). It does not coordinate across instances, so also add random jitter to TTLs so many keys don't expire in the same second.
- **`@Cacheable` is proxy-based**, so the self-invocation gotcha applies: calling `get()` from another method in the same class bypasses the cache.

### The invalidation race, and `transactionAware()`

Without `transactionAware()`, `@CacheEvict` removes the entry _before_ the transaction commits. In that window another request misses the cache, reads the **old** row from PostgreSQL, and stores it back. The cache then holds stale data until the TTL expires. `transactionAware()` delays the eviction until after the commit, which closes the window.

### Redis may fail: design for that

```java
public class LenientCacheErrorHandler extends SimpleCacheErrorHandler {
    @Override public void handleCacheGetError(RuntimeException e, Cache c, Object key) {
        log.warn("cache get failed: {}", e.toString());     // treat as a miss, go to PostgreSQL
    }
    @Override public void handleCachePutError(RuntimeException e, Cache c, Object key, Object v) {
        log.warn("cache put failed: {}", e.toString());
    }
}
```

```properties
spring.data.redis.timeout=200ms
spring.data.redis.connect-timeout=500ms
```

With short timeouts and this handler, a Redis outage makes the app slower instead of returning errors. Without a short timeout, a stuck Redis call holds a Tomcat worker for as long as the default allows, and the failure spreads upward through your thread pool.

### Operating Redis safely

- **Avoid `KEYS *` and other O(N) commands.** Since commands run one at a time, a single slow command blocks all clients. Use `SCAN` instead, and keep values small.
- **Lettuce** (Boot's default client) shares one thread-safe connection across all your threads, so you don't pool it for normal commands. Only blocking commands or `MULTI` transactions need dedicated connections.
- **Set `maxmemory` and an eviction policy.** For a pure cache instance, `allkeys-lru` evicts old entries when memory fills. Keep data that must not be evicted (sessions, queues) on a _separate_ instance with a different policy.
- **High availability**: Sentinel (automatic failover for one primary with replicas) or Redis Cluster (data split across nodes). Your cache design must still tolerate a failover that loses a few recent writes.
- **Locks**: `SET NX PX` works for coordinating short tasks, but reach for database constraints and optimistic locking first. A lock with an expiry can expire while its holder is still working.

## Related concept: sharding

Partitioning splits a table inside _one_ database server. **Sharding** splits data across _several_ servers by a shard key (for example `customer_id % 4`). It lifts the single-server write limit, but cross-shard queries and transactions become hard, and changing the shard count later is painful. Treat it as the answer to "one primary can't handle the writes anymore", after everything above is done.

---

# Putting it together: one request, with numbers

```
request ─► Tomcat worker (exec-N)
              │
              ├─► Redis GET shop:v1:products::42 ── hit ──► respond (~1 ms)
              │
              └─ miss ─► Hikari getConnection ─► PostgreSQL (~20 ms)
                              └─► Redis SET (TTL) ─► respond
```

Take 1,000 requests per second, each needing one query that takes 20 ms. By Little's law, the number of connections busy at once is arrival rate × time:

- **Without Redis:** 1,000 × 0.020 = **20 busy connections**. A pool of 10 is saturated, so threads wait in `getConnection()` and Tomcat workers fill up with blocked requests.
- **With a 90% hit rate:** 100 misses per second × 0.020 = **2 busy connections** on average. Even a 5× burst needs about 10, which a pool of 10 handles.

So the cache doesn't just speed responses up: it keeps the _connection pool_, and through it the _Tomcat workers_, from being the failure point.

A production setup also gives every layer its own limit, with values that get _shorter_ as you go deeper, so slow dependencies fail fast instead of piling up:

|Layer|Setting|Example|
|---|---|---|
|Redis call|`spring.data.redis.timeout`|200 ms|
|Waiting for a DB connection|`hikari.connection-timeout`|2-3 s (default is 30 s)|
|A whole DB transaction|`@Transactional(timeout = 5)`|5 s|
|External HTTP call|client read timeout|per dependency|
|Background pools|bounded queue + rejection policy|as in Part 1|

Finally, make the limits _visible_. Actuator and Micrometer give you the numbers that tell you which link is saturating: `executor.active` and `executor.queued` for your pools, `hikaricp.connections.pending` and `.acquire` for the database, and `cache.gets` split by hit and miss for Redis. Tune only the link the numbers point at.



[[Threads]]