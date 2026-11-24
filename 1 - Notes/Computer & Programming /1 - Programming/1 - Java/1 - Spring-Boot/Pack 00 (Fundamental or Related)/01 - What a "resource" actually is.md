
A **resource** is any piece of information or capability in your system that's important enough to be given its own identity and addressed directly — a user, an order, a list of orders, a single comment on an order, even a computed thing like "today's exchange rate." If something can be meaningfully pointed at and asked about on its own, it's a candidate to be a resource.

The key shift in thinking, if you're coming from a procedural RPC-style mindset (`doSomething()`, `processOrder()`), is this: **REST isn't modeled around actions, it's modeled around nouns.** You don't design an endpoint called `/cancelOrder`. You design a resource called `order`, and "cancelling" becomes an operation _performed on_ that resource using a standard HTTP verb. This is literally where the "R" in REST comes from — **Re**presentational **S**tate **T**ransfer. The client transfers the _representation_ of a resource's _state_ back and forth with the server. Everything in REST design flows from that one sentence.

## Resource vs representation — a distinction that trips people up

The **resource** itself is an abstract concept — "order #42." The **representation** is the actual bytes you send over the wire describing it at a moment in time — JSON, XML, whatever.

```java
@GetMapping(value = "/orders/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
public OrderDto getOrderAsJson(@PathVariable Long id) { ... }

@GetMapping(value = "/orders/{id}", produces = MediaType.APPLICATION_XML_VALUE)
public OrderDto getOrderAsXml(@PathVariable Long id) { ... }
```

Same resource (`order #42`), two different representations, chosen by content negotiation (the client's `Accept` header). This matters because it tells you _where your design energy should go_: you're not designing "a JSON response," you're designing a resource, and the representation format is a secondary, swappable detail.

## Identifying resources with URIs

Every resource gets a URI (a path) that identifies it, uniquely and durably. A URI identifies _what thing_ you're talking about — the HTTP verb you attach to it says _what you want to do to that thing_.

```
GET    /orders          → the collection of all orders (a resource itself)
POST   /orders          → create a new order inside that collection
GET    /orders/42       → one specific order (a singleton resource)
PUT    /orders/42       → replace order 42 entirely
PATCH  /orders/42       → partially update order 42
DELETE /orders/42       → remove order 42
```

Notice `/orders` (the collection) and `/orders/42` (one member of that collection) are _two different resources_, even though they're obviously related. This collection-vs-member split is one of the most important patterns in resource design — you'll use it constantly.

## Nested resources — modeling relationships

When one resource only makes sense in the context of another, you nest it in the URI:

```
GET /orders/42/items        → the line items belonging to order 42
GET /orders/42/items/7      → one specific line item on order 42
```

`item 7` here isn't addressable on its own at `/items/7` with no context — it's scoped to its parent order. That nesting _is_ the resource design communicating the relationship: "an item belongs to an order," expressed structurally, without needing a sentence of documentation to explain it.

A rule of thumb worth keeping: nest no more than one level deep in the URI itself. `/orders/42/items/7/discounts/3` gets unwieldy fast. Once you're that deep, it's usually cleaner to give the deeply-nested thing its own top-level, independently addressable resource (`/discounts/3`) and let it carry a reference to its parent in its representation instead of in the URI.

## What counts as a resource isn't always obvious

Resources aren't only rows in a database table. Some other things that are legitimately modeled as resources:

```
GET /orders/42/status       → just the status field, as its own addressable sub-resource
POST /orders/42/payment     → "the act of paying for order 42," modeled as creating a payment resource
GET /search?q=laptop        → the result set of a search, as a resource in its own right
```

`/orders/42/payment` is the interesting one — instead of an RPC-style `POST /orders/42/pay`, you model "payment" itself as a resource you're creating. This is the noun-not-verb discipline in action: almost any action can be reframed as "creating, reading, updating, or deleting some resource," even when the action doesn't obviously look like data at first glance.

## Tying it back to what you just learned

This is exactly why your `EntityModel<OrderDto>` from HATEOAS made sense: the `self` link pointed at `/orders/42` because that URI _is_ the resource's identity, and the `_links` around it (`cancel`, `payment`) are themselves pointers to other resources or resource-creating actions reachable from this one. Resource design is the foundation everything else — verbs, status codes, HATEOAS links — gets layered on top of.


[[Spring Framework]]