**Redis** is an extremely fast **in-memory data store**. It keeps data in RAM (not on disk) as **key-value pairs**, so reads and writes take well under a millisecond. It runs as a separate server, like PostgreSQL and MongoDB, and listens on **port 6379**.

**Analogy:** PostgreSQL is the **filing room**: organized, permanent, but you walk to the shelf for each lookup. Redis is the **sticky notes on your monitor**: tiny, instant to read, perfect for what you need _right now_, but not where you'd keep the official records.

## Core idea

Every piece of data is stored under a **key** (a name), and the value can be a simple string or a richer structure. You ask for the key, and you get the value back with no query planning, no joins, and no disk seek.

```
SET user:42:name "Alireza"
GET user:42:name          -> "Alireza"
```

Key naming convention: colon-separated segments (`user:42:name`) to keep things organized.

## Data structures (what makes Redis more than a hash map)

|Type|What it is|Typical use|
|---|---|---|
|**String**|Text, number, or bytes|Cached JSON, counters|
|**Hash**|Field-value pairs under one key|A user object|
|**List**|Ordered sequence|Simple queues, recent activity|
|**Set**|Unique unordered items|Tags, unique visitors|
|**Sorted set**|Unique items with a score, kept ordered|Leaderboards, rankings|
|**Stream**|Append-only log|Event pipelines|

```
INCR page:views                      # atomic counter -> 1, 2, 3...
HSET user:42 name "Ali" age 30
ZADD leaderboard 1500 "sam"          # score 1500
ZREVRANGE leaderboard 0 2            # top 3 players
EXPIRE session:abc 1800              # auto-delete after 30 minutes
```

`INCR` is **atomic**, so a thousand simultaneous requests never lose a count. That connects to the ACID/isolation idea from the database lessons.

## Why it is so fast

1. **Everything lives in RAM**, which is orders of magnitude faster than disk.
2. **Simple data structures** with efficient operations.
3. **Mostly single-threaded command execution:** one command runs at a time, so there are no locks, and each command is atomic. (Newer versions use extra threads for network I/O, but commands themselves still run one by one.)

The consequence is that one slow command blocks everyone, so you avoid expensive operations on huge data.

## Persistence: is data lost on restart?

RAM is wiped when power goes out, so Redis offers optional saving to disk:

- **RDB:** periodic snapshots (compact, may lose the last few minutes).
- **AOF:** logs every write (safer, larger).

Even so, Redis is not designed to replace your main database. Treat it as fast, helpful, and _disposable_ unless you've deliberately configured it otherwise.

## Where it fits in a real back-end

```
Angular --> Spring Boot --> Redis (fast layer)
                       \--> PostgreSQL (source of truth)
```

**1. Caching (the most common use).** Database queries are slow relative to RAM, so you store results in Redis. The classic pattern is **cache-aside**:

1. Check Redis for the key.
2. **Hit:** return it immediately.
3. **Miss:** query PostgreSQL, store the result in Redis with an expiry, return it.

**2. Session storage.** Store login sessions in Redis so any of several Spring Boot instances can recognize the user (the "stateless server" idea from the REST lesson, with state moved to a shared place).

**3. Rate limiting.** "Max 100 requests per minute per user" using `INCR` plus `EXPIRE`.

**4. Leaderboards and counters.** Sorted sets rank millions of entries instantly.

**5. Message passing.** Pub/Sub and Streams for lightweight messaging between services.

**6. Distributed locks and temporary data:** one-time codes, password-reset tokens that expire.

## Hands-on on Debian 13

Docker is the easy route (your Docker lesson):

```bash
docker run -d --name redis -p 6379:6379 redis:7
docker exec -it redis redis-cli
```

Or install natively with `sudo apt install redis-server` (check what version Debian 13 provides).

## Using it from Spring Boot

The simplest and most valuable way is **Spring's cache abstraction**. `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
```

`application.properties`:

```properties
spring.data.redis.host=localhost
spring.data.redis.port=6379
spring.cache.type=redis
spring.cache.redis.time-to-live=10m
```

Enable caching and annotate your service:

```java
@SpringBootApplication
@EnableCaching
public class LibraryApplication { ... }

@Service
public class BookService {

    @Cacheable(value = "books", key = "#id")
    public Book getBook(Long id) {
        // runs ONLY on a cache miss; the result is stored in Redis
        return repository.findById(id).orElseThrow();
    }

    @CacheEvict(value = "books", key = "#id")
    public void deleteBook(Long id) {
        repository.deleteById(id);
    }

    @CachePut(value = "books", key = "#result.id")
    public Book update(Book book) {
        return repository.save(book);
    }
}
```

This is the same pattern as `@Transactional`: Spring wraps your service in a **proxy** that checks the cache before calling your method. Your logic doesn't change, and the first call hits PostgreSQL while the next ones return from Redis.

For direct control, use `StringRedisTemplate`:

```java
@Service
public class RateLimiter {
    private final StringRedisTemplate redis;

    public RateLimiter(StringRedisTemplate redis) { this.redis = redis; }

    public boolean allow(String userId) {
        String key = "rate:" + userId;
        Long count = redis.opsForValue().increment(key);
        if (count == 1) {
            redis.expire(key, Duration.ofMinutes(1));
        }
        return count <= 100;
    }
}
```

## Redis vs the databases you've learned

||Redis|PostgreSQL|MongoDB|
|---|---|---|---|
|**Storage**|RAM (optional disk)|Disk|Disk|
|**Model**|Key-value structures|Relational tables|Documents|
|**Speed**|Sub-millisecond|Milliseconds|Milliseconds|
|**Querying**|By key only (no `JOIN`, no `WHERE`)|Full SQL|Rich queries|
|**Capacity**|Limited by RAM|Limited by disk|Limited by disk|
|**Role**|Cache, sessions, counters|Source of truth|Flexible documents|

## Gotchas

- **Cache invalidation is the hard part.** When the database changes, the cached copy becomes stale. Either evict on writes, set a short TTL (time to live), or accept slightly old data. This is a famous difficulty in computing.
- **Always set a TTL on cache entries.** Without expiry, memory fills up forever.
- **RAM is limited and expensive.** When full, Redis either rejects writes or evicts keys, depending on `maxmemory-policy` (for example `allkeys-lru`). Know which one you configured.
- **Don't treat it as your only copy** of important data. A crash or misconfiguration can lose recent writes.
- **Avoid `KEYS *` in production:** it scans everything and blocks the single thread. Use `SCAN` instead.
- **Cached objects must be serializable.** By default Spring uses Java serialization (`Serializable`), which is fragile; configure JSON serialization (`GenericJackson2JsonRedisSerializer`) for readable, safer values.
- **`@Cacheable` is skipped on self-calls.** Calling a cached method from another method in the _same class_ bypasses the proxy, so no caching happens (the same trap as `@Transactional`).
- **Cache stampede:** when a popular key expires, many requests hit the database at once. Mitigate with randomized TTLs or locking.
- **Security:** older default installs had no password and listened on all interfaces. Set a password (`requirepass` or ACLs), bind to localhost or a private network, and never expose port 6379 to the internet. This mirrors the MongoDB warning.
- **Licensing note:** Redis changed its license in 2024, and the community forked it as **Valkey**. They're largely compatible, and Debian may ship either, so check your package. Spring's client works with both.
- **Cache what is read often and changes rarely.** Caching rarely-read or constantly-changing data adds complexity for no gain.




[[Data-base]]