You've already run into the first-level cache in passing — it's the persistence context itself, the thing holding the `EntityEntry` snapshots from your dirty-checking lesson. This lesson makes that explicit and formal, then introduces the second-level cache as a genuinely separate thing sitting above it — closer in spirit to the Redis caching layer from your scalable-design lesson, but built into Hibernate itself.

## First-level cache: you've already been using it

The first-level cache **is** the persistence context — there's no separate object to configure or enable. It's scoped to exactly one `EntityManager` (one `Session`, in native Hibernate terms), which in a typical Spring app means it's scoped to one transaction.

Its behavior: if you ask for the same entity by id twice within the same persistence context, the second call never touches the database — it returns the exact same Java object reference from the first call.

```java
@Transactional
public void demo(Long id) {
    User a = entityManager.find(User.class, id); // SELECT fires, result cached
    User b = entityManager.find(User.class, id); // no SELECT — returned from first-level cache
    System.out.println(a == b); // true — literally the same object reference
}
```

This is why it's sometimes called **identity scope** caching — within one persistence context, there's a guarantee of at most one Java object per database row. This guarantee is also what dirty checking depends on: there's exactly one snapshot per id to compare against, because there's exactly one managed instance per id.

The lifetime is strict: the moment the `EntityManager` closes (transaction ends), the cache is gone. There's no sharing between two concurrent requests, two different transactions, or two different users — each gets its own, short-lived first-level cache. This is both its safety and its limitation: perfectly consistent within a transaction, zero reuse across them.

## Second-level cache: shared, cross-transaction, opt-in

The second-level cache sits one layer above, at the `EntityManagerFactory`/`SessionFactory` level — meaning it's shared across **every** transaction and every user in the running application, not scoped to one request. Unlike the first-level cache, it's completely optional and off by default; you have to explicitly configure it and explicitly mark which entities participate.

```xml
<dependency>
    <groupId>org.hibernate.orm</groupId>
    <artifactId>hibernate-jcache</artifactId>
</dependency>
<dependency>
    <groupId>org.ehcache</groupId>
    <artifactId>ehcache</artifactId>
</dependency>
```

```properties
spring.jpa.properties.hibernate.cache.use_second_level_cache=true
spring.jpa.properties.hibernate.cache.region.factory_class=jcache
```

```java
@Entity
@Cacheable
@org.hibernate.annotations.Cache(usage = CacheConcurrencyStrategy.READ_WRITE)
public class Country {
    @Id
    private Long id;
    private String name;
    // country data barely ever changes — a good caching candidate
}
```

With this in place, loading a `Country` by id in one transaction, then loading that same id in a completely unrelated transaction later (different user, different request), can skip the database entirely on the second load — served from the shared cache instead.

## What actually gets cached: not the object, its state

An important internal detail: the second-level cache does **not** store the live entity Java object itself. It stores a **disassembled, serializable representation** of its state — field values in a neutral form, not the object graph with its Hibernate proxies and lazy-loading machinery attached. When a cache hit occurs, Hibernate reassembles a fresh managed entity instance from that stored state for the requesting persistence context.

This matters for a subtle reason: each transaction still gets its own object reference, freshly built from the cached state, even though the underlying data came from the shared cache rather than the database. The `==` reference-identity guarantee you saw for the first-level cache does **not** extend across transactions via the second-level cache — only same-process-request identity within one persistence context gets that guarantee.

## `CacheConcurrencyStrategy`: how the cache handles concurrent writes

Because the second-level cache is shared across concurrent transactions, Hibernate needs a policy for what happens when one transaction updates an entity while another might be reading the stale cached version. Four strategies:

- **`READ_ONLY`** — the strongest guarantee, for data that truly never changes after creation (lookup tables, country/currency codes). Any attempt to update a `READ_ONLY`-cached entity throws an exception. Fastest option since there's no invalidation logic needed at all.
- **`READ_WRITE`** — the common general-purpose choice. Uses soft locks on cache entries during an update, ensuring a concurrent read during that window gets the database value instead of a stale cached one, rather than silently serving incorrect data.
- **`NONSTRICT_READ_WRITE`** — weaker consistency: an update simply evicts the cache entry rather than coordinating a lock, so there's a brief window where a concurrent reader could still get stale data. Chosen when occasional staleness is tolerable in exchange for less locking overhead.
- **`TRANSACTIONAL`** — full JTA-transactional consistency with the cache provider itself (requires a cache implementation that supports it, like certain Infinispan configurations). The strictest and most complex option, rarely needed outside distributed-transaction environments.

## Query cache: a separate, related feature

Caching entities by id (what you've seen so far) doesn't automatically cache the _results of queries_ — a JPQL query returning "all users named Alice" is a different cacheable unit, covering the list of matching ids rather than the entity data itself:

```java
TypedQuery<User> query = entityManager.createQuery(
    "SELECT u FROM User u WHERE u.name = :name", User.class);
query.setParameter("name", "Alice");
query.setHint("org.hibernate.cacheable", true);
```

The query cache stores just the resulting list of entity ids and the query's parameters as the cache key; the actual `User` data behind those ids is still fetched from (and must exist in) the regular second-level entity cache to be served without hitting the database. Caching a query without caching its underlying entity type gets you a cached list of ids that still triggers individual database lookups for the actual data — easy to enable without realizing it isn't actually saving the queries you think it is.

## Why Redis is often preferred over Hibernate's built-in second-level cache in production

This connects directly to your scalable-design lesson: Hibernate's second-level cache lives **inside the JVM process** of each application instance by default (Ehcache, the example above, is in-memory per-node). In a horizontally scaled deployment — multiple instances of the same Spring Boot app behind a load balancer, which is exactly the scaling model from that lesson — each instance would maintain its _own separate_ second-level cache, with no coordination between them. Instance A updating a `Country` row has no way to invalidate the cached copy sitting in Instance B's memory, leading to different instances serving different "truth" for the same row.

Hibernate does support pluggable second-level cache providers backed by Redis or Infinispan specifically to solve this (so all instances share one external cache rather than each keeping its own), but at that point the architectural tradeoff becomes: is it simpler to configure Hibernate's caching abstraction to talk to Redis, or to just cache explicitly in your service layer using Spring's `@Cacheable` directly against Redis, with full control over keys and eviction? Many production teams choose the latter specifically to avoid the second-level cache's extra layer of indirection and the subtlety of concurrency strategies above — explicit caching at the service layer is easier to reason about than entity-state caching happening implicitly underneath repository calls.

[[Spring Framework]]
