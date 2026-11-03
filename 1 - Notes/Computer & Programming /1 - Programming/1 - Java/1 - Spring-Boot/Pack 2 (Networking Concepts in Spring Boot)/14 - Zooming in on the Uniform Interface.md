

In the overview we saw _what_ the four sub-constraints are. This document is the "how do I actually apply them?" version: which URI shape to pick, what a `PUT` really means for your DTO, which headers make caches behave, and what hypermedia looks like once it depends on state. One theme runs through all of it: **the client should depend on your contract, never on your internals.** Almost every rule below is a way of keeping that wall intact, so when a rule seems arbitrary, ask what internal detail it keeps from leaking.

I won't repeat the resource-vs-representation distinction, safe/idempotent, or the Richardson levels from before. This builds on them.

---

## Naming: URIs are the hardest thing to change

A URI ends up in client code, bookmarks, logs, caches, and other people's documentation. You can rename a Java method in seconds, but you can't rename a public URI without breaking someone. So the URI rules are mostly about **choosing names you'll never regret**:

- **Nouns, plural collections** (`/users`, `/users/42`). Consistency matters more than which convention you pick.
- **Nest for ownership, but cap the depth.** `/users/42/orders` is a natural way to ask "orders of this user". But if an order is meaningful on its own, give it a top-level address too (`/orders/7`). A resource reachable _only_ through its parents forces every client to know the whole chain. Both forms can coexist: the nested one is a convenient view, the top-level one is the identity.
- **Path = identity, query = narrowing.** `/users?role=admin` filters a collection; `/users?id=42` is identity in disguise. Caches and tooling treat paths as "which thing" and queries as "which slice".
- **No file extensions.** `/users/42.json` creates a second URI for the same resource, which violates "one resource, one name". `Accept` already does that job.
- **Lowercase and hyphens**, because paths are case-sensitive and `order_history` vs `OrderHistory` vs `order-history` would otherwise be three arguments.
- **Stable forever.** Don't encode versions or states into the identity. When a resource is truly gone, `410 Gone` ("it existed, it's deliberately removed") tells clients more than `404`.
- **Nothing sensitive in URIs**, since they land in server logs, browser history, and `Referer` headers.

In Spring, class-level `@RequestMapping("/users")` plus method-level `@GetMapping("/{id}")` composes the path in one place. Resist building URI strings by hand elsewhere; use `ServletUriComponentsBuilder` or `linkTo(...)` so a route change happens once.

## Speaking in representations: the server is a gatekeeper

Each method has a precise contract about what the body means, and mixing them up is where most real bugs come from:

- **POST (create):** the client does _not_ send the ID. The server assigns it and answers `201 Created` with a `Location` header.
- **PUT (replace):** the body is the _complete_ new state, and omitted fields count as removed. That's exactly why it's idempotent, and why your PUT DTO should require the full set of fields.
- **PATCH (partial):** the body describes _changes_. The subtle part is that "field absent" and "field explicitly null" mean different things in a merge patch (`application/merge-patch+json`, RFC 7396): absent = leave alone, `null` = clear it.

```json
{ "nickname": null }      // clear the nickname
{ }                       // change nothing
```

A normal DTO can't distinguish those two cases, since both give you `null` in Java. That's why the document's `PATCH` handler takes a `Map<String, Object>`: `containsKey` tells you which one you got. The alternative is **JSON Patch** (RFC 6902), a list of explicit operations (`add`, `remove`, `replace`), which is more verbose but unambiguous.

- **DELETE:** repeating it is idempotent in _effect_, even if the second response is `404` instead of `204`.

Because the body is a _request_, not a command, the server stays in charge: it can reject (`400` for malformed, `422` for well-formed but semantically invalid), normalize, ignore fields like `id`, or enforce rules like unique email.

### Why DTOs aren't optional

The document is right to be firm here, and it's worth knowing the actual reasons:

1. **Mass assignment** is a real security hole. If you bind the body straight onto an entity, a client can send `"role": "ADMIN"` or `"id": 1` and you've let them set fields you never meant to expose. A DTO is an allow-list.
2. **Entities leak internals** (password hashes, lazy relations that blow up during serialization).
3. **Your database schema and your API contract change at different speeds.** A DTO decouples them.

Use _two_ shapes: a request DTO (`name`, `email`, validated with `@Valid`) and a response DTO (adds `id`, `createdAt`, `version`). Fields like `id` shouldn't even exist on the input side. Records plus Bean Validation make this cheap, and MapStruct removes the mapping boilerplate.

### Negotiation has two failure codes

The document covers `406 Not Acceptable` (can't produce what `Accept` asks for). The request-side counterpart is **`415 Unsupported Media Type`**: the client sent a `Content-Type` your `consumes` doesn't allow. Spring returns both automatically when you declare `produces`/`consumes`.

## Messages: remember who is reading

Self-descriptiveness is easier to understand if you picture the _readers_: not just the client, but every proxy, CDN, and gateway in between, none of which knows your domain. They can only act on what's in the standard headers and status line. This explains several rules:

- **The status code is the primary signal**, because it's the part a generic component can act on. A `200` with an error body is invisible to all of them (and, for example, can get cached as a success).
- **`Vary: Accept`** exists because a cache keys on the URL by default. If the same URL returns JSON or XML depending on `Accept`, a cache that doesn't know that may hand XML to a JSON client. `Vary` tells it which request headers to include in its key.
- **`ETag` + `If-None-Match`** give you cheap revalidation: the client asks "still version 5?", and `checkNotModified(etag)` in Spring answers `304` with no body. That's what the `return null; // 304` in the final example is doing: the framework has already written the response.
- **`Retry-After`** with `429`/`503` lets clients back off correctly without custom conventions.
- **Custom `X-App-Result` headers** are out-of-band knowledge by definition, and every client has to learn them.

### Errors deserve a standard shape

`ProblemDetail` is Spring's implementation of RFC 7807 (since superseded by **RFC 9457**, same idea). Error responses get a predictable structure (`type`, `title`, `status`, `detail`, plus extension properties) under `application/problem+json`. Two practical notes: extending `ResponseEntityExceptionHandler` gives you this for Spring's own exceptions, and `spring.mvc.problemdetails.enabled=true` turns it on without writing a handler.

One caution about the document's YAML: `favor-path-extension` was, as far as I know, removed in Spring Framework 6 / Boot 3, so on a modern stack you can drop it. The `Accept` header is the only strategy by default anyway.

## Hypermedia: where it earns its keep

The overview framed HATEOAS as "server can change URLs without breaking clients". The document adds the more convincing argument: **state-driven links**. Look at the `activate`/`deactivate` example. The server decides, based on the user's status, which actions are currently valid, and expresses that as which links are present. Without this, every client re-implements your business rules ("can this user be activated?") and they drift out of sync. With it, the rule lives in one place. I'd say this is a better reason to adopt hypermedia than URL flexibility.

### The formats, in one line each

- **HAL**: minimal `_links` + `_embedded`; Spring's default.
- **JSON:API**: opinionated about the whole document (`data`, `relationships`, pagination, sparse fields).
- **Siren**: includes `actions` with method and fields, so the response says _how_ to perform them.
- **Collection+JSON**: collection-centric, with templates for writes.

### Two corrections worth knowing

First, **HAL links don't carry an HTTP method**. The `"method": "PUT"` entries in the document's JSON samples aren't standard HAL; clients learn the method from the link relation's documented meaning. And in Spring, `.withType("DELETE")` sets the link's _media type hint_, not the HTTP verb, so it won't produce what that example's output shows. If you want the client told how to act, look at **HAL-FORMS** (Spring HATEOAS supports it through `Affordances`) or Siren.

Second, the "realistic client" snippet using `restTemplate.getForObject(..., EntityModel.class)` is simplified. Generic `EntityModel<User>` doesn't deserialize that easily in practice. Spring's purpose-built tool is **Traverson**, which follows links by relation name (`follow("orders")`), and is the natural companion to everything above.

### A pragmatic middle path

Even if no client ever follows your `orders` link, hypermedia pays off in narrow spots: `self` links, and `next`/`prev` in pagination, where clients genuinely shouldn't be computing page URLs. Many teams adopt just those and skip the rest, which is a fair stopping point.

---

## Related concepts worth knowing next

- **`If-Match` on writes** (with `412 Precondition Failed`, or `428` if you require it): the write-side partner to `ETag`, and a clean way to prevent lost updates (optimistic locking) over HTTP.
- **IANA link relations** (`self`, `next`, `prev`, `collection`): use registered names before inventing your own, and use URI-based rels for custom ones.
- **JSON Patch vs. merge patch**, as above.
- **Pagination design**: links, cursors vs. offsets.
- **OpenAPI**, which most teams use in place of hypermedia for discoverability, and why hardcoded URLs persist.
- **Idempotency keys** for retry-safe `POST`, mentioned earlier but especially important for payments.





[[Spring Framework]]