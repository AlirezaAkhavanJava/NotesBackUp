

Imagine walking into a city where every shop has its own door mechanism: one pulls, one slides, one needs a secret knock. You'd have to learn each door separately, and nobody could build a general-purpose "door opener". The Uniform Interface is REST's answer to this problem for the web: every resource, whether it's a user, an order, or an invoice, is accessed using the same small set of rules, so a client that understands those rules can talk to any such API without learning a custom protocol for each endpoint.

This is the constraint that Fielding considered the heart of REST. The other five constraints (client-server, stateless, cacheable, layered, code on demand) describe how components are arranged. This one describes how they talk to each other. In this tutorial we'll look at the problem it solves, the four ideas it's made of, why HTTP method semantics matter so much, how Spring Boot maps onto all of it, and where real-world APIs bend the rules.

---

## The problem: every API inventing its own language

Picture an API built without any shared convention:

```
GET  /getUserById?id=42
POST /createProduct
POST /deleteOrderById
GET  /fetchAllInvoices
```

Each endpoint is a private verb. This causes three concrete problems:

1. **Clients must learn each endpoint individually.** There's no way to guess that the invoice endpoint is called `fetchAllInvoices` and not `listInvoices`.
2. **Infrastructure is blind.** A cache, proxy, or CDN sees `POST /deleteOrderById` and has no idea it's destructive, or that `GET /fetchAllInvoices` is safe to cache. It treats everything cautiously, so you lose most of the benefit.
3. **Tooling can't be generic.** Every client library, retry mechanism, and monitoring tool needs custom knowledge of your API.

The uniform version:

```
GET    /users/42
POST   /products
DELETE /orders/7
GET    /invoices
```

The method says what to do, and the URI says what to do it to. Anyone (or anything) that understands HTTP already understands the shape of your API. That's the payoff: **generality in exchange for giving up per-endpoint freedom**.

---

## Idea 1: Identify things, don't name actions

Every resource gets a URI, and the URI names a _thing_ (a noun), not an action.

```
/users/42          → user 42
/users/42/orders   → orders belonging to user 42
```

A key distinction here is **resource vs. representation**. The resource is the abstract concept ("user 42"). The representation is a concrete snapshot of it sent over the wire: JSON, XML, HTML. One URI, one resource, many possible representations:

```
GET /users/42   Accept: application/json  →  {"id":42,"name":"Ada"}
GET /users/42   Accept: application/xml   →  <user><id>42</id>...</user>
```

Two supporting rules: URIs should be **stable** (don't change them just because your JSON shape changed), and clients should treat them as **opaque**, meaning they follow them rather than parse meaning out of them.

## Idea 2: Change things by sending representations

The client never reaches into the server's database. It sends a representation of the state it _wants_, and the server decides how to make that true:

```
PUT /users/42
Content-Type: application/json

{ "name": "Ada Lovelace", "email": "ada@example.com" }
```

This reads as "here's what user 42 should look like", not "run UPDATE on table users". It's a declarative style, and it keeps the client decoupled from your internals: you can restructure your storage entirely and the conversation stays the same.

## Idea 3: Messages explain themselves

Any message should be understandable on its own, without out-of-band knowledge. The headers and status line carry that information:

- `Content-Type` says how to parse the body
- `Accept` says what the client can handle
- The method says what operation is intended
- The status code says what happened
- `Cache-Control` says whether intermediaries may reuse it

This is what lets a generic proxy do useful work without understanding your domain. Things that break it: relying on "we always send JSON" instead of setting `Content-Type`, custom headers the receiver must know about, and, the classic, returning `200 OK` with `{"error": "not found"}` in the body. The status code is the part intermediaries read, so a lying status code lies to the whole infrastructure.

## Idea 4: Hypermedia (HATEOAS)

The most ambitious part: a client should discover what it can do next by following **links in responses**, the way you browse a website by clicking rather than memorizing URLs.

```json
{
  "id": 42,
  "name": "Ada Lovelace",
  "_links": {
    "self":   { "href": "/users/42" },
    "orders": { "href": "/users/42/orders" }
  }
}
```

The benefit is that the server can reorganize its URL structure and well-behaved clients keep working. The cost is verbosity, immature tooling, and the fact that most clients are written against documentation and hardcode their URLs anyway. That's why this is the piece almost everyone skips.

---

## Why method semantics are not just etiquette

The uniform interface only works if HTTP methods mean the same thing everywhere. Two properties matter:

- **Safe**: doesn't change server state (`GET`, `HEAD`, `OPTIONS`).
- **Idempotent**: doing it N times has the same effect as doing it once (`GET`, `PUT`, `DELETE`, plus the safe ones).

|Method|Safe|Idempotent|Typical use|
|---|:-:|:-:|---|
|GET|✓|✓|Read|
|POST|✗|✗|Create / non-idempotent actions|
|PUT|✗|✓|Replace whole resource|
|PATCH|✗|not guaranteed|Partial update|
|DELETE|✗|✓|Remove|

These guarantees are what let other parties act without asking you. A cache can store any `GET`. A client that times out can blindly retry a `PUT`, because the result is identical even if the first attempt landed. But it **cannot** safely retry a `POST`, since it might create a duplicate order. That's why payment-style APIs use **idempotency keys**: a client-generated token that lets the server recognize and ignore a repeated `POST`. If your `GET` mutates data, crawlers and link-prefetchers will happily trigger it. If your `PUT` increments a counter, retries will corrupt your data.

---

## In Spring Boot

Ideas 1 and 2 map onto controller design:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/{id}")
    public User get(@PathVariable Long id) { ... }

    @PostMapping
    public ResponseEntity<User> create(@RequestBody User user) {
        User created = userService.create(user);
        URI location = URI.create("/users/" + created.getId());
        return ResponseEntity.created(location).body(created);   // 201 + Location
    }

    @PutMapping("/{id}")
    public User replace(@PathVariable Long id, @RequestBody User user) { ... }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();               // 204
    }
}
```

Note the `201 Created` with a `Location` header: that's a self-descriptive message pointing at the new resource's URI.

For idea 3, `ResponseEntity` gives you control over headers, and `produces`/`consumes` on the mappings drive content negotiation:

```java
return ResponseEntity.ok()
        .cacheControl(CacheControl.maxAge(Duration.ofMinutes(5)))
        .eTag("\"" + user.getVersion() + "\"")
        .body(user);
```

For idea 4, add `spring-boot-starter-hateoas` and wrap results in `EntityModel` / `CollectionModel`:

```java
return EntityModel.of(user,
    linkTo(methodOn(UserController.class).getUser(id)).withSelfRel(),
    linkTo(methodOn(OrderController.class).getOrdersForUser(id)).withRel("orders"));
```

Because the links are built from controller methods, renaming a route updates every link automatically, which is a quiet advantage even if no client follows them. By default Spring serializes this as **HAL** (`application/hal+json`), a widely used convention for the `_links` structure.

---

## Reality check: how RESTful is "RESTful"?

Most production APIs implement a pragmatic subset: noun URIs, correct methods, JSON, accurate status codes, and no hypermedia. The **Richardson Maturity Model** names the steps:

- **Level 0**: one endpoint, everything is `POST` (RPC over HTTP)
- **Level 1**: separate URIs per resource
- **Level 2**: proper HTTP verbs and status codes
- **Level 3**: hypermedia controls

Level 2 captures most of the practical value, and that's where most good APIs live. Aiming for Level 3 is a legitimate choice when you have many independent clients and want server-driven evolvability, but it's fine to knowingly stop at Level 2. Just don't call it "pure REST".

Some mistakes to watch for along the way:

- **Verbs in URIs** (`/createOrder`). Action-heavy domains are tricky, though. For something like activation, model it as a state change (`PATCH /users/42`) or as a sub-resource (`POST /users/42/activations`).
- **Tunneling everything through POST**, which throws away caching and safe retries.
- **Using `PATCH` when you really mean `PUT`**, or `PUT` for things that aren't idempotent.
- **Ignoring `Accept` / omitting `Content-Type`**, which makes your API fragile for other clients.

---

## Related concepts worth knowing

- **HTTP caching** (`ETag`, `If-None-Match`, `Cache-Control`): the uniform interface is what makes this possible, and it's the next layer to understand.
- **Content negotiation**: how `Accept` and `produces` choose a representation.
- **HTTP status code families** (2xx/4xx/5xx) and picking the precise one (`201`, `204`, `409`, `422`).
- **Idempotency keys**: how to make `POST` safely retryable.
- **HAL and other hypermedia formats** (JSON:API, Siren): standardized shapes for links.
- **OpenAPI**: in practice, this is how most teams document APIs instead of using hypermedia, and it's the reason hardcoded URLs persist.
- **URI vs. URL**: the REST term is URI, an identifier, which may or may not be a locator you can fetch.




[[Spring Framework]]
[[Networking]]