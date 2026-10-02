

The **Uniform Interface** is the fourth constraint of REST — and arguably the most important. Fielding called it the **central feature** that distinguishes REST from other architectural styles. Without it, you don't have REST. You just have HTTP.

The other five constraints (Client-Server, Statelessness, Cacheability, Layered System, Code on Demand) are about **how components relate**. The Uniform Interface is about **how they communicate**.

## The core idea

> All resources are accessed through the same, standardized set of rules — regardless of what the resource is, who the client is, or what the server does internally.

A user, a product, an order, a payment — they're all accessed the same way:

- Identified by a URI
- Manipulated through standard HTTP methods
- Represented in a standard format
- Connected through hypermedia

The client doesn't need a custom protocol for each resource type. One interface, many resources.

## Why this matters

Without a uniform interface, every API invents its own rules:

```
GET  /getUserById?id=42
POST /createProduct
POST /deleteOrderById
GET  /fetchAllInvoices
```

Each endpoint is a **custom verb**. The client must learn each one. The server must document each one. Intermediaries (caches, proxies) can't reason about any of them.

With a uniform interface:

```
GET    /users/42
POST   /products
DELETE /orders/7
GET    /invoices
```

The method says **what to do**, the URI says **what to do it to**. Any client that understands HTTP understands your API.

## The four sub-constraints

Fielding breaks the Uniform Interface into four parts. You need all four:

### 1. Identification of Resources

Every resource is identified by a **URI**. The URI is a noun, not a verb.

```
/users/42          → user 42
/users/42/orders   → orders belonging to user 42
/orders/7/items    → items in order 7
```

**Rules:**
- A URI identifies **one** resource (or a collection).
- URIs are **stable** — they don't change when the resource's representation changes.
- URIs are **opaque** to the client — the client shouldn't parse them for meaning.

**The resource vs. its representation:**

The resource is the *concept* (user 42). The representation is the *bytes* sent over the wire (JSON, XML, HTML). The URI identifies the resource, not the representation.

```
GET /users/42
Accept: application/json     → { "id": 42, "name": "Ada" }

GET /users/42
Accept: application/xml      → <user><id>42</id><name>Ada</name></user>
```

Same URI, same resource, different representations.

### 2. Manipulation of Resources Through Representations

The client doesn't manipulate the resource directly. It sends a **representation** of the desired state, and the server decides what to do.

```
PUT /users/42
Content-Type: application/json

{ "name": "Ada Lovelace", "email": "ada@example.com" }
```

The client says: "Here's what user 42 should look like." The server applies it. The client never touches the database.

**Key insight:** the client and server exchange **representations**, not resources. The resource lives on the server. The representation travels over the wire.

### 3. Self-Descriptive Messages

Every message must contain enough information for the receiver to understand it — without prior knowledge.

This means:
- **Content-Type** tells the receiver how to parse the body.
- **Accept** tells the server what formats the client wants.
- **HTTP method** tells the server what operation is intended.
- **Status code** tells the client what happened.
- **Cache-Control** tells intermediaries whether to cache.

```http
POST /users HTTP/1.1
Host: api.example.com
Content-Type: application/json
Accept: application/json
Authorization: Bearer eyJhbGc...

{ "name": "Ada", "email": "ada@example.com" }
```

Every piece is explicit. No out-of-band knowledge required.

**What breaks self-descriptiveness:**
- Custom headers the receiver must know about
- Implicit formats ("we always send JSON, so we don't set Content-Type")
- Side effects not signaled by the method
- Status codes that lie (returning 200 for errors)

### 4. HATEOAS (Hypermedia as the Engine of Application State)

This is the one almost nobody implements. It says:

> A client should navigate the API by following **links** in responses, not by hardcoding URLs.

Like a web page: you don't memorize every URL on a site. You click links. The server tells you what you can do next.

```json
{
  "id": 42,
  "name": "Ada Lovelace",
  "email": "ada@example.com",
  "_links": {
    "self":    { "href": "/users/42" },
    "orders":  { "href": "/users/42/orders" },
    "update":  { "href": "/users/42", "method": "PUT" },
    "delete":  { "href": "/users/42", "method": "DELETE" }
  }
}
```

The client sees `_links.orders` and knows it can fetch orders. It doesn't need to know the URL pattern in advance.

**Why it matters:** the server can change URL structures without breaking clients. The client follows links, not hardcoded paths.

**Why nobody does it:** it's complex, verbose, and most clients hardcode URLs anyway. The tooling is immature. It's the most "pure" part of REST and the least practical.

## The HTTP method semantics

The Uniform Interface relies on HTTP methods having **consistent meaning**:

| Method | Safe? | Idempotent? | Purpose |
|--------|-------|-------------|---------|
| `GET` | Yes | Yes | Read a resource |
| `HEAD` | Yes | Yes | Read headers only |
| `POST` | No | No | Create a resource |
| `PUT` | No | Yes | Replace a resource |
| `PATCH` | No | No* | Partially update |
| `DELETE` | No | Yes | Remove a resource |
| `OPTIONS` | Yes | Yes | Discover allowed methods |

**Safe** = doesn't change server state.
**Idempotent** = calling it N times has the same effect as calling it once.

These properties aren't suggestions. They're what allows caches, retries, and intermediaries to work correctly.

- A cache can safely cache `GET`.
- A client can safely retry a `PUT` after a timeout.
- A client cannot safely retry a `POST` without an idempotency key.

## Spring Boot: the Uniform Interface in code

### 1. Resource identification

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) { ... }

    @GetMapping
    public ResponseEntity<List<User>> listUsers() { ... }

    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody User user) { ... }

    @PutMapping("/{id}")
    public ResponseEntity<User> replaceUser(@PathVariable Long id,
                                            @RequestBody User user) { ... }

    @PatchMapping("/{id}")
    public ResponseEntity<User> patchUser(@PathVariable Long id,
                                          @RequestBody Map<String, Object> updates) { ... }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) { ... }
}
```

Notice: the URI is `/users/{id}`. The method is the verb. No `/getUser` or `/deleteUser`.

### 2. Manipulation through representations

```java
@PostMapping
public ResponseEntity<User> createUser(@RequestBody User user) {
    User created = userService.create(user);
    URI location = URI.create("/users/" + created.getId());
    return ResponseEntity.created(location).body(created);
}
```

The client sends a `User` representation. The server returns the created representation plus a `Location` header.

### 3. Self-descriptive messages

```java
@GetMapping(value = "/{id}", produces = { MediaType.APPLICATION_JSON_VALUE,
                                          MediaType.APPLICATION_XML_VALUE })
public ResponseEntity<User> getUser(@PathVariable Long id) {
    User user = userService.find(id);
    return ResponseEntity.ok()
            .contentType(MediaType.APPLICATION_JSON)
            .cacheControl(CacheControl.maxAge(Duration.ofMinutes(5)))
            .eTag("\"" + user.getVersion() + "\"")
            .body(user);
}
```

Spring reads `Accept`, sets `Content-Type`, and handles negotiation. The response is self-descriptive.

### 4. HATEOAS with Spring HATEOAS

Add the dependency:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-hateoas</artifactId>
</dependency>
```

Then build representations with links:

```java
import static org.springframework.hateoas.server.mvc.WebMvcLinkBuilder.*;

@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/{id}")
    public EntityModel<User> getUser(@PathVariable Long id) {
        User user = userService.find(id);

        return EntityModel.of(user,
            linkTo(methodOn(UserController.class).getUser(id)).withSelfRel(),
            linkTo(methodOn(UserController.class).listUsers()).withRel("users"),
            linkTo(methodOn(OrderController.class).getOrdersForUser(id)).withRel("orders")
        );
    }
}
```

Response:

```json
{
  "id": 42,
  "name": "Ada Lovelace",
  "email": "ada@example.com",
  "_links": {
    "self":   { "href": "/users/42" },
    "users":  { "href": "/users" },
    "orders": { "href": "/users/42/orders" }
  }
}
```

For collections, use `CollectionModel`:

```java
@GetMapping
public CollectionModel<EntityModel<User>> listUsers() {
    List<EntityModel<User>> users = userService.findAll().stream()
            .map(u -> EntityModel.of(u,
                    linkTo(methodOn(UserController.class).getUser(u.getId())).withSelfRel()))
            .toList();

    return CollectionModel.of(users,
            linkTo(methodOn(UserController.class).listUsers()).withSelfRel());
}
```

## A complete example: before and after

### ❌ Not a uniform interface (RPC style)

```java
@RestController
public class UserController {

    @GetMapping("/getUserById")
    public User getUserById(@RequestParam Long id) { ... }

    @PostMapping("/createNewUser")
    public String createNewUser(@RequestParam String name,
                                @RequestParam String email) { ... }

    @PostMapping("/updateUserEmail")
    public String updateUserEmail(@RequestParam Long id,
                                  @RequestParam String email) { ... }

    @PostMapping("/deleteUserById")
    public String deleteUserById(@RequestParam Long id) { ... }
}
```

Problems:
- Verbs in URIs (`getUserById`, `createNewUser`)
- Everything is `POST` or `GET` — no use of method semantics
- Data passed as query params, not representations
- No status codes — returns strings
- No links — client must hardcode everything

### ✅ Uniform interface (REST style)

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/{id}")
    public ResponseEntity<EntityModel<User>> getUser(@PathVariable Long id) {
        User user = userService.find(id);
        return ResponseEntity.ok(EntityModel.of(user,
                linkTo(methodOn(UserController.class).getUser(id)).withSelfRel()));
    }

    @PostMapping
    public ResponseEntity<EntityModel<User>> createUser(@RequestBody User user) {
        User created = userService.create(user);
        URI location = linkTo(methodOn(UserController.class)
                .getUser(created.getId())).toUri();
        return ResponseEntity.created(location)
                .body(EntityModel.of(created,
                        linkTo(methodOn(UserController.class)
                                .getUser(created.getId())).withSelfRel()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EntityModel<User>> replaceUser(@PathVariable Long id,
                                                         @RequestBody User user) {
        User updated = userService.replace(id, user);
        return ResponseEntity.ok(EntityModel.of(updated,
                linkTo(methodOn(UserController.class).getUser(id)).withSelfRel()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

Same functionality. Completely different client experience.

## The four sub-constraints as a checklist

When designing an API, ask:

**1. Identification**
- Is every resource identified by a URI?
- Are URIs nouns, not verbs?
- Is the URI stable across representation changes?

**2. Manipulation through representations**
- Does the client send representations, not commands?
- Does the server return representations, not just status strings?

**3. Self-descriptive messages**
- Is `Content-Type` always set?
- Is `Accept` respected?
- Do status codes accurately reflect outcomes?
- Are caching headers present when relevant?

**4. HATEOAS**
- Do responses include links to related resources?
- Can a client navigate without hardcoding URLs?
- Are available actions discoverable?

## Common pitfalls

1. **Verbs in URIs.** `/getUser`, `/createOrder`, `/deleteItem`. Use nouns + HTTP methods instead.

2. **Using only GET and POST.** Many developers tunnel everything through POST because "it's easier." This breaks caching, retries, and semantics.

3. **Returning 200 for errors.** `200 OK` with `{ "error": "not found" }` breaks self-descriptiveness. Use `404`.

4. **Ignoring `Accept`.** Always returning JSON regardless of the `Accept` header breaks content negotiation.

5. **No `Content-Type`.** Relying on the client to guess the format is fragile.

6. **Custom action endpoints.** `POST /users/42/activate` is a verb. If activation is a state change, model it as `PATCH /users/42` with `{ "active": true }` — or accept that it's a sub-resource: `POST /users/42/activations`.

7. **Hardcoding URLs in clients.** If your client has `String BASE = "https://api.example.com"` and builds paths manually, you're not using HATEOAS. That's fine for many APIs — but know you're skipping a constraint.

8. **Making `GET` unsafe.** A `GET` that deletes data or triggers side effects breaks the safe-method guarantee. Caches, prefetchers, and crawlers will wreak havoc.

9. **Making `PUT` non-idempotent.** Calling `PUT /users/42` twice should produce the same result as once. If it increments a counter, it's broken.

10. **Overusing `PATCH`.** `PATCH` is for partial updates. If you're replacing the whole resource, use `PUT`.

## The tension: purity vs. practicality

The Uniform Interface is the most debated constraint because it's the hardest to follow fully.

- **HATEOAS** is pure but rarely implemented.
- **Strict method semantics** can be awkward for complex operations.
- **Content negotiation** (JSON vs. XML) adds complexity most APIs don't need.
- **Resource modeling** is hard for action-oriented domains (payments, workflows).

Most "REST APIs" today are really:

- Resources with noun URIs ✅
- HTTP methods used correctly ✅
- JSON representations ✅
- Status codes used correctly ✅
- HATEOAS ❌ (skipped)
- Content negotiation ❌ (JSON only)

That's a **pragmatic subset**. It's not pure REST, but it captures 90% of the value. Richardson's Maturity Model calls this **Level 2**. HATEOAS would be **Level 3**.

## Richardson Maturity Model

A useful way to think about how RESTful an API is:

| Level | Name | What it has |
|-------|------|-------------|
| **0** | The Swamp of POX | One URI, one method (usually POST). RPC over HTTP. |
| **1** | Resources | Many URIs, one per resource. Still one method. |
| **2** | HTTP Verbs | Correct use of GET, POST, PUT, DELETE, status codes. |
| **3** | Hypermedia | HATEOAS. Links drive the client. |

Most production "REST APIs" are **Level 2**. Level 3 is rare. Level 0 and 1 are common in legacy systems.

The Uniform Interface is what pushes you from Level 1 to Level 2 (and Level 3 if you add hypermedia).

## TL;DR

- **Uniform Interface** = all resources accessed through the same standardized rules.
- Four sub-constraints: **identification of resources**, **manipulation through representations**, **self-descriptive messages**, **HATEOAS**.
- URIs are **nouns**. HTTP methods are **verbs**.
- Clients send **representations**, not commands.
- Messages carry enough metadata (`Content-Type`, `Accept`, status codes) to be understood without prior knowledge.
- HATEOAS makes APIs **discoverable** through links — powerful but rarely implemented.
- HTTP method semantics (**safe**, **idempotent**) aren't optional — they enable caching, retries, and intermediaries.
- Spring Boot supports all of this via `@RestController`, `ResponseEntity`, and `spring-boot-starter-hateoas`.
- Most real APIs implement a **pragmatic subset** (Level 2 on the Richardson Maturity Model), skipping HATEOAS and content negotiation.

You've now covered all six REST constraints:

1. **Client-Server** — separation of concerns
2. **Statelessness** — every request is self-contained
3. **Cacheability** — responses declare if they can be reused
4. **Uniform Interface** — resources, methods, representations, hypermedia ← *you are here*
5. **Layered System** — intermediaries are transparent
6. **Code on Demand** — *optional*: ship executable code to clients





[[0 - Spring Framework]]