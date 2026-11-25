


HATEOAS stands for **Hypermedia As The Engine Of Application State**. It's a REST constraint that says: when your API returns a resource, it shouldn't just return the resource's data — it should also return **links** telling the client what it can do next. The client doesn't need to know your API's URL structure in advance; it discovers it by following links, the same way a browser discovers a website by clicking links on a page instead of memorizing every URL ahead of time.

Most APIs people call "REST" skip this entirely. They return plain JSON with no links, and the client has hardcoded URLs baked into it (`/orders/{id}/cancel`, `/orders/{id}/ship`, etc.). That works, but it's technically not full REST — it's what Roy Fielding (who coined REST) called "a system that violates the constraints and calls itself RESTful anyway." HATEOAS is the piece most people leave out.

## The problem it solves

Say you have an `Order` resource that can be `PENDING`, `SHIPPED`, or `CANCELLED`. Without HATEOAS:

```json
{
  "id": 42,
  "status": "PENDING",
  "total": 59.99
}
```

The client has to _know_, out of band (from docs, from memory, from a Postman collection someone shared), that it's allowed to call `POST /orders/42/cancel` right now, but calling `POST /orders/42/ship` isn't valid yet because payment hasn't cleared. If your business rules change — say cancellation becomes disallowed once an order is older than 24 hours — every client needs updated logic to know that.

With HATEOAS, the server tells the client what's possible _right now_, given the resource's current state:

```json
{
  "id": 42,
  "status": "PENDING",
  "total": 59.99,
  "_links": {
    "self": { "href": "/orders/42" },
    "cancel": { "href": "/orders/42/cancel" },
    "payment": { "href": "/orders/42/payment" }
  }
}
```

Notice there's no `ship` link. The server is saying: "you can't ship this yet." If the order later moves to `SHIPPED`, the next response has a `track` link instead of `cancel`. The client just renders whatever links are present — it never has to hardcode "if status is PENDING, show a cancel button." The server is driving the client's available actions, hence "engine of application state."

## Where this fits: the Richardson Maturity Model

A quick related concept, since it's the usual way HATEOAS gets introduced: the **Richardson Maturity Model** ranks APIs on a 0–3 scale of how "RESTful" they are.

- **Level 0** — one URL, everything's a POST (basically RPC over HTTP, e.g. a single `/api` endpoint).
- **Level 1** — separate URLs per resource (`/orders`, `/orders/42`), but still mostly POST for everything.
- **Level 2** — proper HTTP verbs and status codes (`GET`, `POST`, `PUT`, `DELETE`, `404`, `201`, etc.). This is where almost every "REST API" you've built so far sits, including yours.
- **Level 3** — Level 2 plus HATEOAS. Responses include links describing valid next actions.

Level 2 is perfectly fine for most production systems — don't feel like your existing APIs are "wrong." Level 3 is a specific design choice with real trade-offs, which we'll get to.

## The JSON shape: HAL

Raw HATEOAS doesn't mandate a specific JSON shape — Fielding's definition is abstract. In practice, people use a convention called **HAL** (Hypertext Application Language), which is what Spring's HATEOAS support produces by default. HAL defines two reserved keys:

- `_links` — a map of relation name → link object (`href`, and optionally `templated`, `type`, etc.)
- `_embedded` — for nesting related resources inline (e.g. an order embedding its line items as full resources, each with their own `_links`)

The relation name (`self`, `cancel`, `payment` above) is called the **rel**. `self` is a reserved rel meaning "this is the canonical URL of the resource you're looking at." Everything else is an API-specific rel you define and document — `cancel`, `next-page`, `author`, whatever makes sense.

## Implementing it in Spring Boot

Spring has a dedicated module for this: `spring-boot-starter-hateoas`. It gives you three key types:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-hateoas</artifactId>
</dependency>
```

**`RepresentationModel<T>`** — the base class your response wrapper extends. It's what gives an object a `_links` collection.

**`EntityModel<T>`** — wraps a single object (your DTO) and adds links to it. Use this for single-resource responses.

**`CollectionModel<T>`** — wraps a collection of `EntityModel<T>` and adds links at the collection level (e.g. `self`, `next`, `prev` for pagination). Use this for list endpoints.

Here's a controller returning a single order with conditional links:

```java
@GetMapping("/orders/{id}")
public EntityModel<OrderDto> getOrder(@PathVariable Long id) {
    OrderDto order = orderService.findById(id);

    EntityModel<OrderDto> model = EntityModel.of(order);

    model.add(linkTo(methodOn(OrderController.class).getOrder(id)).withSelfRel());

    if (order.getStatus() == OrderStatus.PENDING) {
        model.add(linkTo(methodOn(OrderController.class).cancelOrder(id)).withRel("cancel"));
        model.add(linkTo(methodOn(OrderController.class).payOrder(id)).withRel("payment"));
    }

    if (order.getStatus() == OrderStatus.SHIPPED) {
        model.add(linkTo(methodOn(OrderController.class).trackOrder(id)).withRel("track"));
    }

    return model;
}
```

Two things worth calling out since they're new here: `linkTo(...)` and `methodOn(...)` are static methods from `WebMvcLinkBuilder`. `methodOn(OrderController.class).cancelOrder(id)` doesn't actually _call_ `cancelOrder` — it's a proxy trick that records "what URL would map to this method with this argument," and `linkTo(...)` turns that into an actual `Link` object. `.withRel("cancel")` sets the relation name; `.withSelfRel()` is shorthand for `.withRel("self")`.

This is the part that makes Level 3 actually valuable instead of just decorative: the links aren't static strings — they're computed from `order.getStatus()`. That `if` block is the entire point of HATEOAS. A client built against this API doesn't need its own copy of your state machine; it just checks "is there a `cancel` link in the response" instead of "is status == PENDING, and have the business rules around that changed since I last checked."

For collections with pagination:

```java
@GetMapping("/orders")
public CollectionModel<EntityModel<OrderDto>> getOrders(Pageable pageable) {
    Page<OrderDto> page = orderService.findAll(pageable);

    List<EntityModel<OrderDto>> orders = page.getContent().stream()
        .map(o -> EntityModel.of(o,
            linkTo(methodOn(OrderController.class).getOrder(o.getId())).withSelfRel()))
        .toList();

    CollectionModel<EntityModel<OrderDto>> collection = CollectionModel.of(orders);
    collection.add(linkTo(methodOn(OrderController.class).getOrders(pageable)).withSelfRel());

    if (page.hasNext()) {
        collection.add(linkTo(methodOn(OrderController.class)
            .getOrders(pageable.next())).withRel("next"));
    }
    if (page.hasPrevious()) {
        collection.add(linkTo(methodOn(OrderController.class)
            .getOrders(pageable.previousOrFirst())).withRel("prev"));
    }

    return collection;
}
```

Spring Boot auto-registers a `Jackson2HalModule` when `spring-boot-starter-hateoas` is on the classpath, so `EntityModel`/`CollectionModel` serialize to proper HAL JSON (`_links`, `_embedded`) automatically — you don't write any custom serialization code.

## Advanced: beyond plain HAL

Plain HAL tells the client a link _exists_, but not what HTTP method to use on it, or what body to send. A client still has to know out-of-band that `cancel` means `POST` with no body, while some other `rel` might mean `PUT` with a JSON payload. A few formats go further:

- **HAL-FORMS** — extends HAL with a `_templates` section describing the HTTP method, content type, and expected fields for each action, so the client can even render a generic form from it.
- **Siren** — a competing hypermedia format built explicitly around "entities, actions, and links," where each action declares its method, fields, and types up front.
- **JSON:API** — less focused on affordance-driven state transitions, more on a standardized way to represent resources, relationships, and included (embedded) data with strict pagination/filtering conventions.

Spring HATEOAS supports HAL-FORMS out of the box (`Affordances` API) if you want to go that far — you'd annotate affordances per state transition instead of just adding a bare link. It's a legitimate next step if you're exposing links in `cancel`/`payment` style and want clients to also know _how_ to call them, not just _that_ they can.

## The trade-off, honestly

HATEOAS is the most debated REST constraint for a reason: it adds real implementation cost (every endpoint now needs link-building logic conditioned on state) for a benefit that only materializes if your clients are actually written to _follow_ links dynamically instead of hardcoding URLs — which, in practice, almost no client does. Most teams building internal or first-party-consumed APIs skip it and stay at Level 2, and that's a defensible choice, not a mistake. It earns its cost mainly in public APIs with many independent, long-lived client integrations (think PayPal's or GitHub's APIs), where you genuinely need to evolve server-side behavior — like removing an action when business rules change — without breaking every client that called you last year.


[[Spring Framework]]