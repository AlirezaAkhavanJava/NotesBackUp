
---
# 1. Identification of Resources

## The principle

Every resource must be uniquely identifiable by a URI. A URI names a **thing**, not an **action**.

The resource is a **concept** — "user 42", "the collection of all orders", "the items in order 7". It exists independently of any representation. The URI is its name.

## The resource vs. the representation

This is the most misunderstood distinction in REST.

- **Resource** — the concept. Lives on the server. Never travels over the wire.
- **Representation** — a snapshot of the resource's state, serialized into bytes (JSON, XML, HTML).

When you `GET /users/42`, you don't receive user 42. You receive a **representation** of user 42 at a moment in time.

```
Resource:        user 42 (the concept, in the database)
URI:             /users/42
Representation:  { "id": 42, "name": "Ada", "email": "ada@example.com" }
```

Two requests a second apart might return different representations if the resource changed. Same resource, different snapshots.

## Rules for good URIs

### Rule 1: Nouns, not verbs

```
✅ GET    /users/42
❌ GET    /getUser?id=42

✅ POST   /orders
❌ POST   /createOrder

✅ DELETE /orders/7
❌ POST   /deleteOrder?id=7
```

The method is the verb. The URI is the noun.

### Rule 2: Plural for collections, singular for items

```
/users          → collection
/users/42       → single item
/users/42/orders → sub-collection
/orders/7/items  → sub-collection
```

Pick a convention and stick to it. Plural is the most common.

### Rule 3: Hierarchical relationships

Express ownership through nesting:

```
/users/42/orders        → orders belonging to user 42
/orders/7/items         → items in order 7
/orders/7/items/3       → item 3 in order 7
```

But don't nest more than 2–3 levels. Deep nesting creates brittle, long URLs. If a resource is independently addressable, give it a top-level URI:

```
✅ GET /orders/7         (not /users/42/orders/7)
✅ GET /items/3          (not /orders/7/items/3)
```

You can still expose the nested form as a convenience:

```
GET /users/42/orders    → list orders for user 42
GET /orders/7           → the same order, addressed directly
```

### Rule 4: URIs are opaque to the client

The client should treat `/users/42/orders` as an opaque identifier. It shouldn't parse it to extract `42`. If the server changes the structure to `/accounts/42/orders`, clients that parsed the URI break.

This is why HATEOAS exists — clients follow links instead of constructing URLs.

### Rule 5: Stable identifiers

The URI identifies the resource **forever**. If user 42 changes their name, the URI stays `/users/42`. If the resource's representation changes, the URI stays. Only when the resource is **deleted** does the URI stop resolving (and even then, `410 Gone` is more accurate than `404`).

### Rule 6: Query parameters for filtering, not identity

```
✅ GET /users?role=admin&active=true     → filter a collection
✅ GET /orders?from=2026-01-01&to=2026-12-31
❌ GET /users?id=42                      → identity belongs in the path
```

Query params shape **which** resources you get from a collection. They don't identify a single resource.

### Rule 7: Lowercase, hyphens, no file extensions

```
✅ /users/42/order-history
❌ /Users/42/OrderHistory
❌ /users/42/order_history
❌ /users/42.json          (use Accept header instead)
```

## Spring Boot: identification in code

```java
@RestController
@RequestMapping("/users")
public class UserController {

    // Collection
    @GetMapping
    public ResponseEntity<CollectionModel<EntityModel<User>>> list(
            @RequestParam(required = false) String role,
            @RequestParam(required = false) Boolean active) {
        // ...
    }

    // Single item
    @GetMapping("/{id}")
    public ResponseEntity<EntityModel<User>> get(@PathVariable Long id) {
        // ...
    }

    // Sub-collection
    @GetMapping("/{id}/orders")
    public ResponseEntity<CollectionModel<EntityModel<Order>>> getOrders(
            @PathVariable Long id) {
        // ...
    }
}
```

`@RequestMapping("/users")` at the class level + `@GetMapping("/{id}")` at the method level produces `/users/{id}`. The URI is composed, never hardcoded as a string.

## Pitfalls

1. **Verbs in URIs** — `/getUser`, `/createOrder`, `/activateAccount`.
2. **Deep nesting** — `/users/42/orders/7/items/3/reviews/9/comments/2`.
3. **Sensitive data in URIs** — `/users?ssn=123-45-6789`. URIs end up in logs, browser history, and referrer headers.
4. **File extensions** — `/users/42.json`. Use `Accept` instead.
5. **Unstable URIs** — `/users/42-v2` or `/users/42/name`. The URI should identify the resource, not a version or a field.

---

# 2. Manipulation of Resources Through Representations

## The principle

The client never manipulates the resource directly. It sends a **representation** of the desired state, and the server decides how to apply it.

The client says: "Here's what I want user 42 to look like."
The server says: "Got it — here's the result."

The client has no idea whether the server uses PostgreSQL, MongoDB, or a text file. It sends bytes and receives bytes.

## How it works per method

### POST — create

The client sends a representation of a **new** resource. The server assigns an ID and creates it.

```http
POST /users HTTP/1.1
Content-Type: application/json

{
  "name": "Ada Lovelace",
  "email": "ada@example.com"
}
```

```http
HTTP/1.1 201 Created
Location: /users/42
Content-Type: application/json

{
  "id": 42,
  "name": "Ada Lovelace",
  "email": "ada@example.com"
}
```

Note: the client didn't send an ID. The server assigned it. The response includes the created representation plus a `Location` header pointing to the new resource.

### PUT — replace

The client sends a representation that **replaces** the existing one entirely.

```http
PUT /users/42 HTTP/1.1
Content-Type: application/json

{
  "name": "Ada Byron",
  "email": "ada.byron@example.com"
}
```

Every field must be present. Fields omitted are considered removed. `PUT` is **idempotent** — sending it twice produces the same result as once.

### PATCH — partial update

The client sends a representation of the **changes**, not the full resource.

```http
PATCH /users/42 HTTP/1.1
Content-Type: application/merge-patch+json

{
  "email": "ada.byron@example.com"
}
```

`PATCH` is **not** idempotent in general. The payload describes a transformation.

### DELETE — remove

The client sends no body. The URI identifies what to delete.

```http
DELETE /users/42 HTTP/1.1
```

```http
HTTP/1.1 204 No Content
```

### GET — read

The client sends no body. The server returns a representation.

```http
GET /users/42 HTTP/1.1
Accept: application/json
```

```http
HTTP/1.1 200 OK
Content-Type: application/json

{ "id": 42, "name": "Ada", "email": "ada@example.com" }
```

## Content negotiation

The client says what it can accept via `Accept`. The server says what it sent via `Content-Type`.

```http
GET /users/42
Accept: application/json, application/xml;q=0.9
```

The server picks JSON (higher preference). If it can't satisfy any, it returns `406 Not Acceptable`.

## The server controls the mapping

The client's representation is a **request**, not a command. The server can:

- Reject it (`400 Bad Request`, `422 Unprocessable Entity`)
- Transform it (normalize email to lowercase)
- Enrich it (add timestamps, IDs)
- Ignore fields (e.g., `id` in a `POST` body)
- Apply business rules (e.g., "email must be unique")

This is why representation-based manipulation is powerful: the server keeps control of its own state.

## Spring Boot: representations in code

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @PostMapping
    public ResponseEntity<EntityModel<User>> create(@RequestBody @Valid UserDto dto) {
        User created = userService.create(dto);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(created.getId())
                .toUri();
        return ResponseEntity.created(location).body(toModel(created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EntityModel<User>> replace(@PathVariable Long id,
                                                     @RequestBody @Valid UserDto dto) {
        User replaced = userService.replace(id, dto);
        return ResponseEntity.ok(toModel(replaced));
    }

    @PatchMapping(value = "/{id}", consumes = "application/merge-patch+json")
    public ResponseEntity<EntityModel<User>> patch(@PathVariable Long id,
                                                   @RequestBody Map<String, Object> updates) {
        User patched = userService.patch(id, updates);
        return ResponseEntity.ok(toModel(patched));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

Content negotiation in Spring:

```java
@GetMapping(value = "/{id}",
            produces = { MediaType.APPLICATION_JSON_VALUE,
                         MediaType.APPLICATION_XML_VALUE })
public ResponseEntity<User> get(@PathVariable Long id) {
    return ResponseEntity.ok(userService.find(id));
}
```

Spring reads `Accept` and picks the matching `produces` type.

## DTOs vs. entities

Never expose your JPA entities directly as representations. Use DTOs:

```java
public record UserDto(
        @NotBlank String name,
        @Email @NotBlank String email
) {}

public record UserResponse(
        Long id,
        String name,
        String email,
        Instant createdAt
) {}
```

Why:
- Entities have lazy-loaded relationships that serialize badly.
- Entities contain internal fields (password hashes, internal flags) you don't want to leak.
- Entities change with your database schema; DTOs change with your API contract.

The representation is part of your **contract**. Protect it from implementation details.

## Pitfalls

1. **Exposing entities directly.** Leaks internal fields, breaks on schema changes, causes lazy-loading exceptions.
2. **Ignoring `Content-Type`.** Accepting any body without checking its declared type is fragile.
3. **Returning `200` for creates.** Use `201 Created` + `Location`.
4. **Using `POST` for updates.** `PUT` and `PATCH` exist for a reason.
5. **Non-idempotent `PUT`.** `PUT /users/42` twice must produce the same state.
6. **No validation.** Always validate the incoming representation. `@Valid` + Bean Validation is your friend.
7. **Mass assignment.** Binding request bodies directly to entities lets clients set fields they shouldn't (`id`, `role`, `isAdmin`). Use DTOs.

---

# 3. Self-Descriptive Messages

## The principle

Every message must carry enough metadata for the receiver to understand it — without out-of-band knowledge.

A self-descriptive message answers:
- What is this? (`Content-Type`)
- What do you want? (`Accept`)
- What operation? (HTTP method)
- What happened? (status code)
- Can it be cached? (`Cache-Control`, `ETag`)
- Who sent it? (`Host`, `Authorization`)
- Can I retry? (method semantics)

If the receiver needs a wiki page to understand your response, it's not self-descriptive.

## The components

### Content-Type (on requests and responses)

Tells the receiver how to parse the body.

```http
POST /users HTTP/1.1
Content-Type: application/json

{ "name": "Ada" }
```

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{ "id": 42, "name": "Ada" }
```

Without `Content-Type`, the receiver guesses. Guessing is how security bugs happen.

### Accept (on requests)

Tells the server what the client can handle.

```http
GET /users/42 HTTP/1.1
Accept: application/json
```

The server must:
- Return `200` with a matching `Content-Type` if it can.
- Return `406 Not Acceptable` if it can't.

### HTTP method

Already covered. The method is part of the message's self-description: it says what operation is intended.

### Status code

The status code is the **primary** signal of what happened.

```
2xx → success
3xx → redirect / not modified
4xx → client error
5xx → server error
```

Returning `200 OK` with `{ "error": "..." }` is the cardinal sin. It forces the client to parse the body to know if the request succeeded.

### Headers that describe caching

```
Cache-Control: max-age=60, public
ETag: "v1"
Last-Modified: Wed, 01 Oct 2026 12:00:00 GMT
Vary: Accept, Accept-Encoding
```

These tell intermediaries whether and how to cache.

### Headers that describe the response

```
Location: /users/42          (where the new resource lives)
Content-Length: 87            (how big the body is)
Content-Encoding: gzip        (how it's compressed)
Retry-After: 120              (when to retry, with 429/503)
```

## What breaks self-descriptiveness

### 1. Custom conventions

```
X-App-Result: SUCCESS
```

Now the client must know what `X-App-Result` means. That's out-of-band knowledge. Use status codes instead.

### 2. Implicit formats

"We always send JSON, so we don't set Content-Type."

This breaks the moment you add XML, Protobuf, or a proxy that needs to know the format.

### 3. Method abuse

Using `POST` for everything. A `POST /users/42?_method=DELETE` is not self-descriptive — the method says "create" but the intent is "delete."

### 4. Lying status codes

Returning `200` for a validation error. Returning `500` for a missing resource. The status code is a contract; don't break it.

### 5. Side effects on `GET`

A `GET` that mutates state breaks the safe-method guarantee. Caches and prefetchers assume `GET` is safe.

## Spring Boot: self-descriptive messages

Spring Boot is self-descriptive **by default** if you let it be:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<UserResponse> get(@PathVariable Long id) {
        UserResponse user = userService.find(id);

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .cacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic())
                .eTag("\"" + user.version() + "\"")
                .header("Vary", "Accept, Accept-Encoding")
                .body(user);
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE,
                 produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<UserResponse> create(@RequestBody @Valid UserRequest request) {
        UserResponse created = userService.create(request);

        return ResponseEntity
                .created(URI.create("/users/" + created.id()))
                .contentType(MediaType.APPLICATION_JSON)
                .body(created);
    }
}
```

### Global exception handling for consistent errors

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ProblemDetail> handleNotFound(UserNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("User Not Found");
        problem.setType(URI.create("https://api.example.com/problems/user-not-found"));
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .body(problem);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST, "Validation failed");
        problem.setProperty("errors", ex.getBindingResult().getFieldErrors().stream()
                .map(e -> Map.of("field", e.getField(), "message", e.getDefaultMessage()))
                .toList());
        return ResponseEntity.badRequest()
                .contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .body(problem);
    }
}
```

`ProblemDetail` (RFC 7807) is a standardized error format — self-descriptive by design.

### Content negotiation configuration

```yaml
spring:
  mvc:
    contentnegotiation:
      favor-parameter: false
      favor-path-extension: false
      media-types:
        json: application/json
        xml: application/xml
```

Disable path extensions (`.json`) and favor the `Accept` header.

## Pitfalls

1. **`200` with error bodies.** Use proper status codes.
2. **Missing `Content-Type`.** Always set it.
3. **Ignoring `Accept`.** If you only support JSON, return `406` when the client asks for XML.
4. **Custom error formats.** Use RFC 7807 (`ProblemDetail`).
5. **`X-` prefixed headers for core semantics.** They're non-standard and often stripped.
6. **Side effects on `GET`.** Breaks caching and prefetching.
7. **Inconsistent error shapes.** Every error should look the same.

---

# 4. HATEOAS — Hypermedia as the Engine of Application State

## The principle

> A client should navigate the API by following **links** in responses, not by hardcoding URLs.

The server tells the client what it can do next. The client doesn't need to know the API's URL structure in advance.

This is how the web works: you land on a page, and the page contains links. You click. You never memorize URLs. The **hypermedia** (links in the HTML) drives your **application state** (which page you're on).

REST applies the same idea to APIs.

## What it looks like

```json
{
  "id": 42,
  "name": "Ada Lovelace",
  "email": "ada@example.com",
  "status": "ACTIVE",
  "_links": {
    "self":     { "href": "/users/42" },
    "orders":   { "href": "/users/42/orders" },
    "activate": { "href": "/users/42/activation", "method": "POST" },
    "delete":   { "href": "/users/42", "method": "DELETE" }
  }
}
```

The client sees `_links.orders` and knows it can fetch orders. It doesn't need to know that orders live at `/users/{id}/orders`.

If the server later moves orders to `/orders?userId=42`, the client keeps working — it follows the link.

## Why HATEOAS matters (the theory)

### 1. Decoupling

The client doesn't know URL structures. The server can refactor them freely.

### 2. Discoverability

The client can explore the API at runtime. No need to read docs to find out what actions are available.

### 3. State-driven navigation

The available links reflect the current state. An inactive user has an `activate` link; an active user has a `deactivate` link. The client doesn't need to know the rules — it just follows what's available.

### 4. Uniformity

Every response follows the same link format. Clients can generalize.

### 5. Versioning

You can add or remove links without breaking clients. New capabilities appear as new links.

## Why almost nobody implements it (the practice)

1. **Complexity.** You have to build link structures into every response.
2. **Verbosity.** Responses get bigger.
3. **Tooling.** Most HTTP clients and testing tools don't understand hypermedia.
4. **Client developers ignore it.** Even when links are present, clients hardcode URLs.
5. **No standard.** HAL, JSON:API, Siren, Collection+JSON, Hydra — pick one.
6. **Diminishing returns.** For stable APIs with known clients, the flexibility isn't worth the cost.

Fielding himself has criticized APIs that call themselves REST but skip HATEOAS. In practice, HATEOAS is the "pure" constraint that most teams skip.

## The main hypermedia formats

### HAL (Hypertext Application Language)

The most common. Uses `_links` and `_embedded`.

```json
{
  "id": 42,
  "name": "Ada",
  "_links": {
    "self": { "href": "/users/42" },
    "orders": { "href": "/users/42/orders" }
  },
  "_embedded": {
    "orders": [
      { "id": 7, "_links": { "self": { "href": "/orders/7" } } }
    ]
  }
}
```

Content type: `application/hal+json`.

### JSON:API

More opinionated. Uses `data`, `relationships`, `links`.

```json
{
  "data": {
    "type": "users",
    "id": "42",
    "attributes": { "name": "Ada", "email": "ada@example.com" },
    "relationships": {
      "orders": { "links": { "related": "/users/42/orders" } }
    },
    "links": { "self": "/users/42" }
  }
}
```

Content type: `application/vnd.api+json`.

### Siren

Rich hypermedia with actions and fields.

```json
{
  "class": ["user"],
  "properties": { "name": "Ada" },
  "actions": [
    { "name": "activate", "method": "POST", "href": "/users/42/activation" }
  ],
  "links": [
    { "rel": ["self"], "href": "/users/42" }
  ]
}
```

### Collection+JSON

Focused on collections.

```json
{
  "collection": {
    "version": "1.0",
    "href": "/users",
    "items": [
      { "href": "/users/42", "data": [{ "name": "name", "value": "Ada" }] }
    ]
  }
}
```

## Spring Boot: HATEOAS in code

### Dependency

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-hateoas</artifactId>
</dependency>
```

### Single resource with links

```java
import static org.springframework.hateoas.server.mvc.WebMvcLinkBuilder.*;

@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/{id}")
    public EntityModel<UserResponse> get(@PathVariable Long id) {
        UserResponse user = userService.find(id);

        return EntityModel.of(user,
                linkTo(methodOn(UserController.class).get(id)).withSelfRel(),
                linkTo(methodOn(UserController.class).list()).withRel("users"),
                linkTo(methodOn(OrderController.class).getOrdersForUser(id)).withRel("orders"),
                linkTo(methodOn(UserController.class).delete(id)).withRel("delete")
                        .withType("DELETE")
        );
    }
}
```

Response:

```json
{
  "id": 42,
  "name": "Ada",
  "_links": {
    "self":   { "href": "/users/42" },
    "users":  { "href": "/users" },
    "orders": { "href": "/users/42/orders" },
    "delete": { "href": "/users/42" }
  }
}
```

### Collection with links

```java
@GetMapping
public CollectionModel<EntityModel<UserResponse>> list() {
    List<EntityModel<UserResponse>> users = userService.findAll().stream()
            .map(u -> EntityModel.of(u,
                    linkTo(methodOn(UserController.class).get(u.id())).withSelfRel()))
            .toList();

    return CollectionModel.of(users,
            linkTo(methodOn(UserController.class).list()).withSelfRel());
}
```

### State-driven links

Links that depend on the resource's state:

```java
@GetMapping("/{id}")
public EntityModel<UserResponse> get(@PathVariable Long id) {
    UserResponse user = userService.find(id);

    EntityModel<UserResponse> model = EntityModel.of(user,
            linkTo(methodOn(UserController.class).get(id)).withSelfRel());

    if (user.status() == Status.INACTIVE) {
        model.add(linkTo(methodOn(UserController.class).activate(id)).withRel("activate"));
    } else {
        model.add(linkTo(methodOn(UserController.class).deactivate(id)).withRel("deactivate"));
    }

    return model;
}
```

The client doesn't need to know the activation rules. It follows whichever link is present.

### Configuration

```yaml
spring:
  hateoas:
    use-hal-as-default-json-media-type: true
```

This makes `application/hal+json` the default. Clients can request it via `Accept: application/hal+json`.

## A realistic client

Without HATEOAS:

```java
// Client hardcodes everything
User user = restTemplate.getForObject("https://api.example.com/users/42", User.class);
List<Order> orders = restTemplate.exchange(
        "https://api.example.com/users/42/orders",
        HttpMethod.GET, null,
        new ParameterizedTypeReference<List<Order>>() {}).getBody();
```

With HATEOAS:

```java
// Client discovers URLs from links
EntityModel<User> user = restTemplate.getForObject(
        "https://api.example.com/users/42", EntityModel.class);

String ordersUrl = user.getLink("orders").orElseThrow().getHref();
List<Order> orders = restTemplate.exchange(
        ordersUrl, HttpMethod.GET, null,
        new ParameterizedTypeReference<List<Order>>() {}).getBody();
```

The second version survives URL refactoring. The first breaks.

## When to use HATEOAS

**Use it when:**
- You have many clients you don't control.
- The API evolves frequently.
- You want true decoupling.
- Discoverability matters.
- You're building a public API with long-term stability goals.

**Skip it when:**
- You have one or two known clients.
- URLs are stable.
- Team familiarity is low.
- The overhead outweighs the benefit.
- You're building an internal API.

## Pitfalls

1. **Links with no semantics.** `"link1": "/foo"` — meaningless. Use `rel` values that describe the relationship.
2. **Hardcoded URLs inside links.** Build them with `WebMvcLinkBuilder` so refactoring works.
3. **Inconsistent link formats.** Pick HAL or JSON:API and stick with it.
4. **Links to actions without methods.** If a link is for `DELETE`, say so.
5. **Over-linking.** Don't link to everything. Link to what the client might do next.
6. **Assuming clients use links.** Most don't. Test that your links are correct anyway.
7. **Forgetting `_embedded`.** Collections of related resources should be embedded, not just linked.

---

# Putting it all together

Here's a single Spring Boot controller that honors all four sub-constraints:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    // 1. Identification: noun URI
    // 2. Manipulation: representation in, representation out
    // 3. Self-descriptive: produces, cache headers, status codes
    // 4. HATEOAS: links in the response
    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<EntityModel<UserResponse>> get(@PathVariable Long id,
                                                         WebRequest request) {
        UserResponse user = userService.find(id);
        String etag = "\"" + user.version() + "\"";

        // Self-descriptive: conditional request handling
        if (request.checkNotModified(etag)) {
            return null; // 304 Not Modified
        }

        EntityModel<UserResponse> model = EntityModel.of(user,
                linkTo(methodOn(UserController.class).get(id)).withSelfRel(),
                linkTo(methodOn(UserController.class).list()).withRel("users"),
                linkTo(methodOn(OrderController.class).getOrdersForUser(id)).withRel("orders"));

        // State-driven hypermedia
        if (user.status() == Status.INACTIVE) {
            model.add(linkTo(methodOn(UserController.class).activate(id)).withRel("activate"));
        }

        return ResponseEntity.ok()
                .eTag(etag)
                .cacheControl(CacheControl.maxAge(Duration.ofMinutes(5)).cachePublic())
                .varyBy("Accept")
                .contentType(MediaType.APPLICATION_JSON)
                .body(model);
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE,
                 produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<EntityModel<UserResponse>> create(
            @RequestBody @Valid UserRequest request) {
        UserResponse created = userService.create(request);

        EntityModel<UserResponse> model = EntityModel.of(created,
                linkTo(methodOn(UserController.class).get(created.id())).withSelfRel());

        return ResponseEntity
                .created(linkTo(methodOn(UserController.class).get(created.id())).toUri())
                .contentType(MediaType.APPLICATION_JSON)
                .body(model);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

Every line maps to a sub-constraint:

| Line | Sub-constraint |
|------|---------------|
| `@RequestMapping("/users")` + `@GetMapping("/{id}")` | Identification |
| `@RequestBody @Valid UserRequest` | Manipulation through representations |
| `produces`, `contentType`, `eTag`, `cacheControl`, `204` | Self-descriptive messages |
| `EntityModel.of(...)`, `linkTo(...)` | HATEOAS |

---

# TL;DR

| Sub-constraint | One-line summary | Spring Boot tool |
|----------------|------------------|------------------|
| **Identification of Resources** | Nouns in URIs, stable, opaque | `@RequestMapping`, `@PathVariable` |
| **Manipulation Through Representations** | Send/return representations, not commands | `@RequestBody`, DTOs, `@Valid` |
| **Self-Descriptive Messages** | Enough metadata to understand without prior knowledge | `ResponseEntity`, `produces`, `ProblemDetail` |
| **HATEOAS** | Links drive navigation | `spring-boot-starter-hateoas`, `EntityModel`, `linkTo` |

The first three are **widely implemented**. The fourth is **rarely implemented** — but it's the one that completes the Uniform Interface and makes an API truly RESTful.




[[Spring Framework]]