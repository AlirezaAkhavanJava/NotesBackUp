
When you write `ResponseEntity<Dto>` in a controller, you're really building two separate things at once: a piece of **data** (your Java object) and a piece of the **HTTP protocol** (status line + headers) that wraps it before it goes on the wire. Most Spring developers only ever think about the first part — the DTO — because Spring hides the second part behind convenience methods. But the actual bytes leaving your server follow strict network conventions that exist independently of Spring, and those conventions are what every HTTP client (browsers, Postman, other backends) actually reads to understand your response.



## Part 1 — The network side

### What a response actually is on the wire

Ignoring Java completely, an HTTP response is just text (and sometimes bytes) sent back over the TCP connection, in this exact order:

```
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/orders/42
Content-Length: 87

{"id":42,"item":"Keyboard","status":"PENDING"}
```

Four parts, always in this order:

1. **Status line** — protocol version, status code, reason phrase
2. **Headers** — metadata about the response
3. **Blank line** — separates headers from body (mandatory, not optional)
4. **Body** — the actual payload, if there is one

When your Java code finishes, this is the literal thing that gets generated and sent. The "convention" for each operation is really a convention about what status code, which headers, and what body shape are expected for that kind of request.

### Convention per operation (HTTP method)

**GET (read)**

- Found → `200 OK` + body = the resource
- Not found → `404 Not Found` + body = nothing or an error object
- GET must never change server state (it's safe), and running it twice must give the same result (idempotent)

```
HTTP/1.1 200 OK
Content-Type: application/json

{"id":1,"name":"Keyboard"}
```

**POST (create, or trigger an action)**

- When POST _creates_ a new resource → `201 Created`, plus a `Location` header pointing to where the new resource now lives, plus the created resource in the body
- When POST triggers an action that isn't "creating a resource" (e.g. login, sending an email) → `200 OK`, body = result of the action

```
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/orders/42

{"id":42,"item":"Keyboard","status":"PENDING"}
```

POST is the one method that is **not idempotent** — calling it twice is expected to create two resources, not update the same one.

**PUT (full replace)**

- Resource replaced → `200 OK` + the full updated resource, **or** `204 No Content` if you don't want to return a body
- PUT is idempotent: sending the exact same PUT request 5 times in a row should leave the server in the same end state as sending it once

```
HTTP/1.1 200 OK
Content-Type: application/json

{"id":42,"item":"Keyboard","status":"SHIPPED"}
```

**PATCH (partial update)**

- Same status conventions as PUT (`200 OK` with body, or `204 No Content`)
- Difference is semantic, not about the response: PATCH only sends the fields that changed, PUT sends the entire resource
- PATCH is **not guaranteed idempotent** by the HTTP spec (e.g. "increment counter by 1" is a valid PATCH, but running it twice gives a different result) — though most REST APIs design their PATCH to be idempotent anyway by only supporting "set field to value," not "adjust by."

**DELETE (remove)**

- Deleted successfully → `204 No Content` (most common — nothing meaningful to return) or `200 OK` with a confirmation body if you want one
- Already deleted / doesn't exist → `404 Not Found`
- DELETE is idempotent: deleting something that's already gone should ideally still read as "it's gone," not throw a 500

```
HTTP/1.1 204 No Content
```

Notice: a `204` response has **no body at all**, and by convention should have no `Content-Length` or `Content-Type` header either — there's nothing to describe.

### Error response shape

Errors follow a separate but equally real convention: **RFC 7807 (`application/problem+json`)**, which you've already used through `ProblemDetail`. The convention is that error bodies look structurally different from success bodies — they describe _what went wrong_, not _the resource_:

```
HTTP/1.1 404 Not Found
Content-Type: application/problem+json

{"type":"about:blank","title":"Not Found","status":404,"detail":"Order 99 does not exist"}
```

This is why mixing "success DTO" and "error DTO" into one shape is a design smell — the network convention already expects two distinct response families based on status code range (`2xx` = success shape, `4xx`/`5xx` = problem shape).

## Part 2 — The Spring Boot side: `ResponseEntity`

`ResponseEntity<T>` is Spring's Java representation of exactly the four parts above — status code, headers, and body — bundled into one object your controller method returns. Spring then takes that object and generates the literal bytes from Part 1.

```java
public class ResponseEntity<T> {
    private final int statusCode;
    private final HttpHeaders headers;
    private final T body;
}
```

You never construct it with `new` in practice — you use its static **builder methods**, each one mirroring a status convention from above.

**GET**

```java
@GetMapping("/{id}")
public ResponseEntity<OrderDto> getOrder(@PathVariable Long id) {
    return orderService.findById(id)
        .map(ResponseEntity::ok)                 // 200 OK + body
        .orElse(ResponseEntity.notFound().build()); // 404, no body
}
```

**POST (creating a resource)**

```java
@PostMapping
public ResponseEntity<OrderDto> createOrder(@RequestBody @Valid OrderRequest request) {
    OrderDto created = orderService.create(request);

    URI location = ServletUriComponentsBuilder
        .fromCurrentRequest()
        .path("/{id}")
        .buildAndExpand(created.id())
        .toUri();

    return ResponseEntity.created(location).body(created); // 201 + Location header + body
}
```

`ServletUriComponentsBuilder.fromCurrentRequest()` builds the `Location` URI based on the request that just hit your controller, so it doesn't need to be hardcoded — it adapts to whatever host/path your API is actually running under.

**PUT**

```java
@PutMapping("/{id}")
public ResponseEntity<OrderDto> replaceOrder(@PathVariable Long id, @RequestBody @Valid OrderRequest request) {
    OrderDto updated = orderService.replace(id, request);
    return ResponseEntity.ok(updated); // 200 + full updated resource
}
```

**PATCH**

```java
@PatchMapping("/{id}")
public ResponseEntity<OrderDto> updateOrder(@PathVariable Long id, @RequestBody OrderPatchRequest patch) {
    OrderDto updated = orderService.applyPatch(id, patch);
    return ResponseEntity.ok(updated); // same shape as PUT, different input semantics
}
```

**DELETE**

```java
@DeleteMapping("/{id}")
public ResponseEntity<Void> deleteOrder(@PathVariable Long id) {
    orderService.delete(id);
    return ResponseEntity.noContent().build(); // 204, no body
}
```

`ResponseEntity<Void>` is the type-level way of saying "this response will never carry a body" — the generic type itself documents the convention from Part 1.

**Adding custom headers**

Any builder method can be chained with `.header(...)` before `.body(...)` or `.build()`:

```java
return ResponseEntity.ok()
    .header("X-Total-Count", String.valueOf(total))
    .body(orders);
```

**The builder flow, summarized**

Every `ResponseEntity` you write follows the same three-step shape, matching the network anatomy exactly:

1. **Start** → pick the status: `.ok()`, `.created(uri)`, `.noContent()`, `.notFound()`, `.status(HttpStatus.X)`
2. **Shape** → optionally attach headers: `.header(name, value)`
3. **Finish** → attach the body (`.body(dto)`) or close it with no body (`.build()`)

Whatever you return from the controller method is converted by Spring's `HttpMessageConverter` (Jackson, by default) into the literal JSON body, and the status/headers you chose become the literal status line and header lines from Part 1 — so the Java side and the network side are really just two views of the same response, one written in builder calls, the other written in raw bytes.



[[Spring Framework]]