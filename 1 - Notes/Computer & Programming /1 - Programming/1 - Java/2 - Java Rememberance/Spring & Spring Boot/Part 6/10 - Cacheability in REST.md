
First, a critical distinction that trips almost everyone up:

| Concept | What it caches | Where it lives |
|---------|---------------|----------------|
| **HTTP caching / cacheability** | Responses sent over HTTP | Between client and server (browser, CDN, proxy) |
| **`@Cacheable` in Spring** | Method return values | Inside your server (in-memory, Redis, etc.) |

When REST talks about "cacheable," it means the **first one** — HTTP caching. Spring's `@Cacheable` is a completely different feature that has nothing to do with REST cacheability. Many developers conflate them. Let's keep them separate.

---
## Part 1: What "cacheable" means in REST

REST says responses should be **explicitly labeled** as cacheable or not. This is one of the six REST constraints (Cacheability). The goal:

- A client or intermediary (CDN, proxy, browser) can reuse a response **without asking the server again**.
- This reduces latency, bandwidth, and server load.

The rules live in **HTTP**, not in REST itself. REST just says "use them."

### The two axes of caching

Every cacheable response answers two questions:

1. **Is it still fresh?** (Can I use it without asking the server?)
2. **If not fresh, has it changed?** (Can I cheaply ask the server "did this change?")

These correspond to two mechanisms:

- **Freshness** → `Cache-Control`, `Expires`
- **Validation** → `ETag` + `If-None-Match`, `Last-Modified` + `If-Modified-Since`

---

## Part 2: Freshness — `Cache-Control`

The `Cache-Control` header is the main tool. Common directives:

```
Cache-Control: max-age=60
```
Response is fresh for 60 seconds. Client uses it without asking.

```
Cache-Control: no-cache
```
Client **must** revalidate with the server before using. (Confusingly named — it means "cache, but revalidate," not "don't cache.")

```
Cache-Control: no-store
```
Never store this response anywhere. Use for secrets, tokens, PII.

```
Cache-Control: public, max-age=3600
```
Any cache (including shared CDNs) may store it for 1 hour.

```
Cache-Control: private, max-age=600
```
Only the end client's private cache may store it (not shared proxies). Use for user-specific data.

```
Cache-Control: must-revalidate
```
Once stale, must revalidate — don't serve stale on error.

### In Spring Boot

```java
@GetMapping("/products/{id}")
public ResponseEntity<Product> getProduct(@PathVariable Long id) {
    Product p = productService.find(id);

    return ResponseEntity.ok()
            .cacheControl(CacheControl.maxAge(Duration.ofMinutes(10)).cachePublic())
            .body(p);
}
```

`CacheControl` is a Spring builder that emits proper `Cache-Control` syntax. You can chain:

```java
CacheControl.maxAge(Duration.ofHours(1))
            .cachePublic()
            .mustRevalidate()
```

For "don't cache":

```java
return ResponseEntity.ok()
        .cacheControl(CacheControl.noStore())
        .body(sensitiveData);
```

---

## Part 3: Validation — ETag and Last-Modified

Freshness alone is crude. If `max-age` expires, the client would have to re-download everything. Validation fixes that: the client asks "has this changed?" and the server replies **304 Not Modified** with an empty body if not.

### ETag (entity tag)

An ETag is an opaque fingerprint of the response content — usually a hash or a version number.

**Server sends:**
```
ETag: "abc123"
```

**Client later sends:**
```
If-None-Match: "abc123"
```

**Server replies:**
- `304 Not Modified` (nothing changed, use your cached copy) — no body
- `200 OK` with new body + new ETag (changed)

### Last-Modified

Same idea but time-based.

**Server sends:**
```
Last-Modified: Wed, 01 Oct 2026 12:00:00 GMT
```

**Client later sends:**
```
If-Modified-Since: Wed, 01 Oct 2026 12:00:00 GMT
```

**Server replies:**
- `304 Not Modified`
- `200 OK`

### In Spring Boot

The easiest way is `WebRequest.checkNotModified(...)`. Spring handles the header parsing and 304 logic for you.

```java
@GetMapping("/users/{id}")
public ResponseEntity<User> getUser(@PathVariable Long id, WebRequest request) {
    User user = userService.find(id);
    String etag = "\"" + user.getVersion() + "\"";   // must be quoted

    if (request.checkNotModified(etag)) {
        return null;   // Spring returns 304 automatically
    }

    return ResponseEntity.ok()
            .eTag(etag)
            .cacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic())
            .body(user);
}
```

Or with a timestamp:

```java
if (request.checkNotModified(user.getUpdatedAt().toEpochMilli())) {
    return null;
}
```

`checkNotModified` works with both ETag and Last-Modified and handles the `If-None-Match` / `If-Modified-Since` headers.

### Automatic ETag with `ShallowEtagHeaderFilter`

If you don't want to compute ETags manually, register this filter:

```java
@Bean
public FilterRegistrationBean<ShallowEtagHeaderFilter> etagFilter() {
    FilterRegistrationBean<ShallowEtagHeaderFilter> reg = new FilterRegistrationBean<>();
    reg.setFilter(new ShallowEtagHeaderFilter());
    reg.addUrlPatterns("/api/*");
    return reg;
}
```

**How it works:** it buffers the response body, computes an MD5 hash, and sets the ETag. If the client sends a matching `If-None-Match`, it returns 304.

**Trade-off:** it buffers the entire response in memory and still runs your controller on every request. It saves bandwidth, not CPU. For heavy responses, prefer computing ETags from a version field or a hash you already have.

---

## Part 4: `Vary` — when the response depends on request headers

If your response differs based on `Accept`, `Accept-Encoding`, `Accept-Language`, or `Authorization`, you must tell caches:

```java
return ResponseEntity.ok()
        .varyBy("Accept", "Accept-Encoding")
        .body(data);
```

Without `Vary`, a cache might serve a JSON response to a client that asked for XML, or worse, serve a user-specific response to another user.

If you cache per-user, use `Cache-Control: private` **and** think hard about `Vary: Authorization`.

---

## Part 5: Which methods are cacheable?

Per HTTP spec:

| Method | Cacheable? | Notes |
|--------|-----------|-------|
| `GET` | Yes | The main case |
| `HEAD` | Yes | Same as GET, no body |
| `POST` | Rarely | Only if `Cache-Control` explicitly allows and response has a `Content-Location` |
| `PUT` / `DELETE` | No | They change state |
| `PATCH` | No | Changes state |

**Rule of thumb:** if a method is *safe* (doesn't change state), it's cacheable. If it's *unsafe*, it isn't.

This is why REST design pushes reads onto `GET` — so they can be cached.

---

## Part 6: The `@Cacheable` confusion (server-side caching)

Spring's `@Cacheable` does **not** make an HTTP response cacheable. It caches the *method's return value inside your server*:

```java
@Service
public class ProductService {

    @Cacheable("products")
    public Product find(Long id) {
        // expensive DB call — only runs on cache miss
        return repo.findById(id).orElseThrow();
    }
}
```

Enable it with:

```java
@SpringBootApplication
@EnableCaching
public class App { ... }
```

What this gives you:
- The second call to `find(42)` returns the cached object — no DB hit.
- The client still receives a full `200 OK` response every time.
- The browser/CDN knows nothing about it.

What this does **not** give you:
- Fewer HTTP requests
- Bandwidth savings
- 304 responses

### You usually want both

```java
@GetMapping("/products/{id}")
public ResponseEntity<Product> getProduct(@PathVariable Long id, WebRequest request) {
    Product p = productService.find(id);           // @Cacheable protects the DB

    if (request.checkNotModified(p.getVersion())) { // HTTP layer protects the network
        return null;
    }

    return ResponseEntity.ok()
            .eTag("\"" + p.getVersion() + "\"")
            .cacheControl(CacheControl.maxAge(Duration.ofMinutes(10)).cachePublic())
            .body(p);
}
```

- `@Cacheable` → server doesn't hit the DB.
- `ETag` + `Cache-Control` → client doesn't hit the server.

They solve different problems and compose beautifully.

---

## Part 7: Common pitfalls

1. **Caching user-specific data publicly.** If a response contains "my orders," you must use `Cache-Control: private`. Otherwise a shared CDN might serve Alice's orders to Bob. This is a real, well-documented class of security bug.

2. **Forgetting `Vary`.** Caching a response that depends on `Accept-Language` without `Vary: Accept-Language` serves the wrong language.

3. **Caching POST/PUT/DELETE.** Don't. It breaks the semantics of unsafe methods.

4. **Assuming `no-cache` means "don't cache."** It means "cache but revalidate." For "don't cache," use `no-store`.

5. **Using `ShallowEtagHeaderFilter` on huge responses.** It buffers the whole body in memory. Fine for small JSON, dangerous for large payloads.

6. **Not quoting ETags.** `ETag: abc123` is invalid. It must be `ETag: "abc123"` (quoted). `ResponseEntity.eTag()` handles this, but manual headers don't.

7. **Confusing `@Cacheable` with HTTP caching.** Covered above. This is the #1 source of "why isn't my response cached?" confusion.

8. **Mutating a cached object.** With `@Cacheable`, if you return a mutable object and a caller modifies it, you've corrupted the cache. Return immutable objects or defensive copies.

---

## Part 8: A complete, realistic example

```java
@RestController
@RequestMapping("/api/articles")
public class ArticleController {

    private final ArticleService service;

    public ArticleController(ArticleService service) {
        this.service = service;
    }

    @GetMapping("/{id}")
    public ResponseEntity<Article> getArticle(@PathVariable Long id, WebRequest request) {
        Article article = service.find(id);   // @Cacheable-backed
        String etag = "\"" + article.getVersion() + "\"";

        if (request.checkNotModified(etag)) {
            return null;                      // -> 304 Not Modified
        }

        return ResponseEntity.ok()
                .eTag(etag)
                .cacheControl(CacheControl
                        .maxAge(Duration.ofMinutes(10))
                        .cachePublic()
                        .mustRevalidate())
                .varyBy("Accept-Encoding")
                .body(article);
    }
}
```

What happens on repeated requests:

1. **First request** → server runs controller, returns `200 OK` with body, `ETag`, `Cache-Control`.
2. **Within 10 minutes** → client uses cached copy. **No network request at all.**
3. **After 10 minutes** → client sends `If-None-Match: "v1"`.
   - If unchanged → server returns `304 Not Modified`, empty body. **Bandwidth saved.**
   - If changed → server returns `200 OK` with new body and new ETag.

Three layers of protection: freshness (no request), validation (tiny request), and server-side `@Cacheable` (no DB hit).

---

## TL;DR

- **REST cacheability = HTTP caching.** It's about labeling responses so clients and proxies can reuse them.
- **`Cache-Control`** controls *freshness* (`max-age`, `public`, `private`, `no-store`).
- **`ETag` / `Last-Modified`** enable *validation* → `304 Not Modified`.
- **Spring Boot:** use `CacheControl` + `ResponseEntity.eTag()` + `WebRequest.checkNotModified()`. Optionally `ShallowEtagHeaderFilter` for automatic ETags.
- **`Vary`** whenever the response depends on request headers.
- **Only `GET` and `HEAD` are naturally cacheable.**
- **`@Cacheable` is server-side method caching — a different thing.** Use both for maximum effect.


[[Spring Framework]]