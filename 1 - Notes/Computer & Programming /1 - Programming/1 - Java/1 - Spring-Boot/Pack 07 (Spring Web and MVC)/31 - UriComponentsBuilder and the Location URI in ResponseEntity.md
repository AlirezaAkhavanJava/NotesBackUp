

`UriComponentsBuilder` is a Spring utility for building URIs piece by piece — scheme, host, port, path, path variables, query parameters — without you concatenating strings yourself. In a `@Controller` method, Spring can inject one for you that's already pre-filled with the current request's scheme, host, and port, so you only need to add the part specific to your endpoint. It matters here because of a REST convention: when you create a resource, the correct response isn't just "200 OK, here's your data" — it's `201 Created`, with a `Location` header telling the client exactly where the new resource now lives. `UriComponentsBuilder` is the standard way to build that `Location` URI without hardcoding it.

### The problem it solves

Say you create a resource:

```java
@PostMapping("/orders")
public ResponseEntity<Order> createOrder(@RequestBody CreateOrderRequest request) {
    Order saved = orderService.create(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(saved);
}
```

This works, but it's incomplete by REST standards. A `201 Created` response is expected to carry a `Location` header pointing to the new resource's URL — that's literally part of the HTTP spec (RFC 9110): the server tells the client "here's where to find/manage what you just created." Without it, the client has to guess the URL of the new order by reading its `id` out of the body and building the URL itself, which couples the client to knowledge it shouldn't need.

The naive fix is to hardcode it:

```java
URI location = URI.create("http://localhost:8080/orders/" + saved.getId());
```

This breaks the moment you deploy behind a different host, a different port, HTTPS instead of HTTP, or a reverse proxy — any of which changes what the "correct" base URL actually is. `UriComponentsBuilder` fixes this by building the URI relative to whatever the _actual current request_ looked like, so it's always correct no matter where the app is deployed.

### Using it

```java
@PostMapping("/orders")
public ResponseEntity<Order> createOrder(
        @RequestBody CreateOrderRequest request,
        UriComponentsBuilder uriBuilder) {

    Order saved = orderService.create(request);

    URI location = uriBuilder
            .path("/orders/{id}")
            .buildAndExpand(saved.getId())
            .toUri();

    return ResponseEntity.created(location).body(saved);
}
```

Spring MVC recognizes `UriComponentsBuilder` as a special argument type and injects an instance that's already seeded with the current request's scheme, host, and port — you just append the path. `.path("/orders/{id}")` adds a path template with a placeholder; `.buildAndExpand(saved.getId())` fills that placeholder with the new order's actual id, producing a `UriComponents` object; `.toUri()` converts that into a `java.net.URI`. `ResponseEntity.created(location)` is a shortcut that sets status `201` and the `Location` header to that URI in one call — equivalent to `ResponseEntity.status(201).header("Location", location.toString())`.

There's also a static entry point, `UriComponentsBuilder.fromPath(...)` or `.fromUriString(...)`, for when you're not inside a controller method and have no request to base it on — but inside a controller, injecting the parameter is preferred specifically because it's request-aware.

### Why this appears on `@PostMapping`, not `@GetMapping`

It comes down to what each verb is doing:

- **POST** creates a new resource whose identity (its URL) didn't exist before the call. The client sends data, the server decides the new resource's id, and _only the server_ knows the resulting URL at that moment. Something has to communicate that new URL back — that's exactly what `Location` + `UriComponentsBuilder` are for. This is why `201 Created` is specifically defined to carry a `Location` header pointing at the newly created resource.
    
- **GET** retrieves a resource whose URL the client _already provided_ in the request itself — `/orders/42` means the client already knows the resource lives at `/orders/42`. There's no new URL to communicate, because the one being used is the one the client asked for. Returning a `Location` header on a `GET /orders/42` response would be redundant — it would just repeat the URL already in the request line.
    

The same logic extends past POST, if you want the fuller picture: `PUT` on a URL the client chose (`PUT /orders/42/shipping-address`) doesn't need a `Location` header either, for the same reason — client-supplied identity, nothing new to report back. Where `UriComponentsBuilder` legitimately shows up again is anywhere the server is the one deciding a brand-new identity, which in practice is almost always resource creation — i.e., POST.


[[Spring Framework]]