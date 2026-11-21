

**Scalability** is a system's ability to handle more work (more users, more requests, more data) by adding resources, without a redesign and without getting unacceptably slow or unreliable. The key phrase is _by adding resources_. A system that serves 100 users fine and collapses at 1,000 isn't scalable, even if it's fast today. A scalable system lets you say "traffic doubled, so we added capacity" and have it work.

In Spring Boot, scalability is mostly **not about Spring Boot itself**. A single Spring Boot instance is already quick. What decides your fate is the architecture around it: whether instances can be cloned freely, whether the database becomes the choke point, whether slow work blocks fast work, and whether one failing dependency drags everything down. This tutorial follows a request through your system and shows what breaks at each stage and what Spring gives you to fix it.

---

## First, what are we measuring?

You can't scale what you can't measure, so the vocabulary comes first:

- **Throughput**: requests handled per second (e.g. 500 req/s).
- **Latency**: how long one request takes. Look at **percentiles**, not averages. If p50 is 80 ms but p99 is 4 s, then 1 in 100 users has a terrible experience, and under load that tail grows first.
- **Saturation**: how full a resource is (CPU, threads, DB connections). Latency usually stays flat until a resource saturates, then shoots up sharply. This "hockey stick" is the typical sign you've hit a limit.

Scaling means pushing that hockey stick further to the right.

## Two ways to grow

**Vertical scaling (scale up)** means a bigger machine: more CPU, more RAM. It's easy because your code doesn't change, but it has a ceiling, gets expensive fast, and leaves you with a single point of failure.

**Horizontal scaling (scale out)** means more machines running the same app behind a load balancer:

```text
            ┌─► App instance 1 ─┐
Client ─► LB├─► App instance 2 ─┼─► Database / Redis / Kafka
            └─► App instance 3 ─┘
```

This has almost no ceiling and gives you redundancy for free, but it only works if **any instance can serve any request**. That condition is the central problem of scaling, and most techniques below exist to satisfy it.

## The core obstacle: state

If instance 1 remembers something that instance 2 doesn't, the load balancer routing you to the wrong one breaks your app. You saw this with HTTP sessions: a login stored in Server A's memory is invisible to Server B.

So the foundational move is **keep your app instances stateless, and push state into shared systems built to hold it.** Concretely, in Spring Boot:

- **User sessions**: use Spring Session with Redis, or switch to JWT with `SessionCreationPolicy.STATELESS`.
- **Uploaded files**: don't write them to the instance's local disk. Use object storage (S3 or similar).
- **In-memory caches and counters**: a plain `HashMap` cache is different on every instance. Use a shared cache like Redis, or accept that local caches are only a per-instance optimization.
- **Scheduled jobs**: a `@Scheduled` method runs on _every_ instance, so with 5 instances your nightly report runs 5 times. A library like ShedLock (a lock in the DB or Redis) makes sure only one instance runs it.

Once instances are interchangeable ("cattle, not pets"), adding or killing one becomes harmless.

## Making instances easy to multiply

Stateless code isn't enough; the instances also need to start, stop, and be judged healthy automatically. Spring Boot helps here:

**Health checks** through Actuator let the load balancer or Kubernetes know whether to send traffic:

```properties
management.endpoints.web.exposure.include=health,metrics,prometheus
management.endpoint.health.probes.enabled=true
```

This exposes liveness and readiness endpoints (`/actuator/health/liveness` and `/readiness`). "Readiness" matters at scale: a new instance shouldn't get traffic until it has finished warming up.

**Graceful shutdown** prevents dropped requests when an instance is removed during scale-in or a deploy:

```properties
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
```

**Externalized configuration** (environment variables, config servers) means the same build artifact runs everywhere. Package it as a container image and let an orchestrator (Kubernetes, ECS) handle the scaling, including autoscaling on CPU or request rate.

## Inside one instance: threads

Even before you add servers, each instance has a limit. The classic Spring MVC model uses **one thread per request**. Embedded Tomcat has a pool (default 200 threads), and a thread that's waiting on a slow database or HTTP call is _blocked_, doing nothing but occupying a slot. When all 200 are blocked, new requests queue up, and you've saturated without using much CPU.

Your options:

1. **Virtual threads (Java 21+, Spring Boot 3.2+)**. These are cheap threads managed by the JVM, so blocking no longer wastes a scarce OS thread. Often it's a single line, and your familiar blocking code stays unchanged:

```properties
spring.threads.virtual.enabled=true
```

2. **Reactive stack (Spring WebFlux)**. It uses a few event-loop threads and non-blocking I/O throughout. It's powerful for very high concurrency, but it demands a reactive style across your whole call chain, including the database driver. Today, virtual threads cover many of the cases people used to reach for WebFlux for.
    
3. **Tune the pool** (`server.tomcat.threads.max`) as a stopgap. Bigger isn't automatically better, because more threads means more contention downstream.
    

## The database: usually the first real bottleneck

You can run 50 app instances, but they all talk to one database. Here is where most Spring Boot systems actually hit their wall, and where the "scale out the app" strategy stops helping.

**Connection pooling.** Spring Boot uses HikariCP. Each instance has its own pool, so the total connections are `instances × pool size`, and that total must fit within the database's `max_connections`. Counterintuitively, a _small_ pool is often faster, because a database does better with a few busy connections than hundreds fighting for CPU:

```properties
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=3000
```

**Fix the queries first.** This is cheaper than any infrastructure:

- Add the right **indexes** (check with `EXPLAIN`).
- Kill the **N+1 problem**, where JPA loads a list and then fires one extra query per item. Use `JOIN FETCH`, `@EntityGraph`, or batch fetching.
- **Paginate** (`Pageable`) instead of returning whole tables.
- Use **batching** for bulk inserts (`spring.jpa.properties.hibernate.jdbc.batch_size`).

**Then scale the database itself:**

- **Read replicas**: send reads to copies and writes to the primary. Spring can route between them with a routing `DataSource`. The catch is _replication lag_, so a replica may briefly return stale data right after a write.
- **Sharding / partitioning**: split data across databases by key. It's powerful but adds real complexity, so it's a last resort.

## Caching: don't do the same work twice

If many requests ask for the same expensive result, compute it once. Spring's cache abstraction makes this almost free to adopt:

```java
@EnableCaching  // on a configuration class

@Service
public class ProductService {

    @Cacheable(value = "products", key = "#id")
    public Product find(Long id) {
        return repository.findById(id).orElseThrow(); // runs only on a cache miss
    }

    @CacheEvict(value = "products", key = "#product.id")
    public void update(Product product) {
        repository.save(product);
    }
}
```

```properties
spring.cache.type=redis
spring.cache.redis.time-to-live=10m
```

Redis gives you a cache **shared across instances**; Caffeine gives you an extremely fast **per-instance** cache. The famous difficulty is **invalidation**: when the data changes, every stale copy must go. TTLs are the simple safety net. Caching trades freshness for speed, so decide how stale each piece of data is allowed to be.

## Don't make users wait for slow work

Not everything has to finish inside the request. Sending an email, generating a PDF, or updating a search index can happen _after_ you reply. Putting a message queue (Kafka, RabbitMQ) between "accept the request" and "do the work" has two big benefits:

- **Fast responses**: the controller drops a message on the queue and returns immediately.
- **Load leveling**: a traffic spike fills the queue instead of crashing the app, and workers drain it at their own pace.

```java
@KafkaListener(topics = "orders", groupId = "order-workers")
public void handle(OrderPlaced event) {
    // process the order
}
```

The `groupId` is the scaling trick: Kafka divides the topic's partitions among all consumers in the group, so **starting more instances automatically splits the work**. For simple in-process cases there's also `@Async`, but it only moves work to another thread on the same machine, so it doesn't scale out.

## Surviving failure while scaling

At scale, something is always slow or down. The danger is a **cascading failure**: Service A calls slow Service B, A's threads pile up waiting, A becomes slow, and everything calling A fails too. Defenses:

- **Timeouts on everything.** An HTTP client with no timeout can hang a thread forever.
- **Circuit breakers**: after repeated failures, stop calling the broken dependency for a while and fail fast. Resilience4j integrates with Spring Boot:

```java
@CircuitBreaker(name = "payment", fallbackMethod = "paymentFallback")
public Receipt charge(Order order) {
    return paymentClient.charge(order);
}

private Receipt paymentFallback(Order order, Throwable t) {
    return Receipt.pending(order); // degrade gracefully
}
```

- **Rate limiting and bulkheads**: cap how much any one caller or dependency can consume, so one abusive client or slow integration can't starve the rest.
- **Idempotency**: when retries happen (and they will), repeating a request must not double-charge anyone. Design write endpoints so a retry is safe.

## Measure before you optimize

Guessing which layer is the bottleneck wastes weeks. The loop is: **load test → find the saturated resource → fix it → repeat.**

- Use **Micrometer** with Actuator to export metrics (request latency percentiles, Hikari pool usage, JVM memory) to Prometheus and Grafana.
- Use a load-testing tool such as k6 or Gatling to push realistic traffic at a staging environment.
- Watch for _which_ resource saturates first. If CPU is idle but latency is high, you're probably blocked on threads or the DB, and adding app instances won't help.

## Related ideas worth knowing

- **Elasticity**: scaling _down_ as well as up automatically, so you pay only for what you use.
- **Availability vs. scalability**: related but different. Scalability is handling more load; availability is staying up when parts fail. Horizontal scaling happens to help both.
- **Eventual consistency**: once data is spread across caches, replicas, and queues, different parts of the system may briefly disagree. Scalable systems often accept this deliberately.
- **Amdahl's law**: the part of your system that can't be parallelized (a single DB writer, a global lock) caps your total speedup no matter how many instances you add.
- **Microservices**: they let you scale parts independently, but they're not required for scalability. A well-built stateless monolith on three instances scales further than most projects ever need, and splitting prematurely adds network calls, failure modes, and operational burden.

## Common mistakes

- **Scaling the wrong layer.** Adding app servers when the database is the bottleneck just increases the pressure on it.
- **Premature optimization.** Build the simple stateless design first and scale when measurements demand it.
- **Hidden state.** A static field, a local file, or an in-memory cache that quietly breaks once you run two instances.
- **Unbounded everything.** Unbounded queries, unbounded queues, unbounded thread pools, and unbounded retries all turn a spike into an outage.

## Recap

Scalability means handling growth by adding resources. The recipe in Spring Boot is: **make instances stateless** (Redis sessions or JWT, external file storage) so you can clone them; **run many behind a load balancer** with health probes and graceful shutdown; **use threads efficiently** (virtual threads); **protect and optimize the database** (pooling, indexes, N+1 fixes, replicas); **cache** expensive reads; **push slow work onto queues**; **add timeouts and circuit breakers** so failures don't cascade; and **measure** so you fix the real bottleneck. Most of the time the answer isn't "more servers" but "find what's saturated and relieve it."




[[Spring Framework]]
[[Rest-API]]