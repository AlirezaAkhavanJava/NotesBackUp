

System Design is the practice of planning how a software system's components fit together to meet both **functional requirements** (what the system does) and **non-functional requirements** (how well it does it — scale, speed, reliability, cost). It's the discipline that sits above individual code: where DSA is about choosing the right structure for a single operation, System Design is about choosing the right _architecture_ for an entire application — how data flows, where it's stored, how components talk to each other, and what happens when something fails or traffic spikes 100x overnight.

It splits into two levels people usually distinguish:

- **High-Level Design (HLD)** — the big picture: which services exist, how they communicate, what databases are used, where caching and load balancing sit. This is the "boxes and arrows" diagram level.
- **Low-Level Design (LLD)** — the implementation detail within one component: class structures, design patterns, database schemas, API contracts. This is closer to the code you actually write day to day.

## The non-functional requirements that drive every decision

These are the forces you're constantly balancing, and almost every System Design decision is a trade-off between them:

- **Scalability** — can the system handle growth in users/data/traffic?
- **Availability** — is the system up and responding, even when parts of it fail?
- **Consistency** — do all parts of the system see the same data at the same time?
- **Latency** — how fast is a single request/response?
- **Throughput** — how many requests can the system handle per second?
- **Fault tolerance** — does the system keep working (or degrade gracefully) when a component crashes?

A famous formalization of the tension between two of these is the **CAP theorem**: in a distributed system, when a network partition happens, you can only guarantee _either_ Consistency or Availability, not both at the same time. PostgreSQL in a single-node setup favors consistency; a system like Cassandra, by design, leans toward availability during a partition.

## Scaling: vertical vs horizontal

```
Vertical scaling:   [ 1 server: 4 CPU, 16GB ]  →  [ 1 server: 32 CPU, 256GB ]
Horizontal scaling: [ 1 server ]  →  [ server ] [ server ] [ server ]
```

**Vertical scaling** means making one machine more powerful. It's simple — no code changes needed — but it has a hard ceiling (you can't buy an infinitely powerful single machine) and a single point of failure.

**Horizontal scaling** means adding more machines and distributing load across them. This is how virtually every large-scale system actually scales, but it introduces real complexity: now you need a **load balancer** to distribute traffic, and your app must be **stateless** (no session data stored in one instance's memory) so any instance can handle any request. This is exactly why things like Spring Session + Redis exist — to externalize session state so horizontal scaling is even possible.

## The core building blocks

**Load Balancer** — distributes incoming requests across multiple server instances (round-robin, least-connections, or consistent hashing are common algorithms). Nginx, which you've already looked at, can act as one.

**Caching** — storing frequently-accessed data somewhere faster than the primary data store, to avoid repeating expensive work. This is the same DSA idea (O(1) hash lookup vs. recomputation) applied at the architecture level:

```java
@Cacheable("products")
public Product getProduct(Long id) {
    return productRepository.findById(id).orElseThrow();
}
```

Here, `@Cacheable` means the first call hits PostgreSQL, but subsequent calls for the same `id` are served from a cache (often Redis) without touching the database at all.

**Database scaling strategies:**

- **Replication** — copying data to multiple database nodes (one primary for writes, replicas for reads) to spread read load and add fault tolerance.
- **Sharding** — splitting one logical dataset across multiple databases based on a key (e.g., `user_id % 4` decides which of 4 shards a user's data lives on), so no single database has to hold everything.
- **Indexing** — the same B-tree/hash-index concept from DSA, applied to make queries fast at scale instead of full table scans.

**Message Queues** — this is exactly where Kafka and RabbitMQ, which you just covered, fit into System Design: they decouple services so a slow or failing consumer doesn't take down the producer, and they let you absorb traffic spikes by buffering work instead of processing everything synchronously.

**CDN (Content Delivery Network)** — a network of geographically distributed servers that cache and serve static content (images, JS, CSS) from a location physically close to the user, reducing latency.

## A worked example: designing a URL shortener

System Design is usually taught through concrete problems, so here's the classic one in miniature, to show how the pieces connect:

1. **Requirement**: given a long URL, generate a short code; given the short code, redirect to the original URL.
2. **Data model**: a table/key-value store mapping `short_code → original_url`.
3. **ID generation**: you need unique, compact codes — options include a counter + base62 encoding, or a hash of the URL truncated and checked for collisions.
4. **Read-heavy optimization**: redirects (`GET /abc123`) vastly outnumber creations, so you'd cache `short_code → original_url` mappings in Redis in front of the primary database.
5. **Scaling**: shard the database by short code prefix if the dataset grows beyond one machine's capacity; put a CDN/load balancer in front of the whole thing for global low-latency access.

Notice this single small example already touches caching, database design, ID generation (a DSA concern), and horizontal scaling — which is the point of System Design: it's the layer where all your other knowledge (DSA, databases, Spring, messaging, deployment) gets assembled into one working, scalable system.


[[Spring Framework]]