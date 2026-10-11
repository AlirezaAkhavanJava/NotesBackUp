
## Simple mental model

An HTTP response is a **parcel you send back**, and it has three parts:

```
HTTP/1.1 201 Created                 ← STATUS    (how did it go?)
Location: /api/users/7               ← HEADERS   (metadata about the parcel)
Content-Type: application/json
                                     
{ "id": 7, "name": "Alireza" }       ← BODY      (the contents)
```

If you return a plain object from a controller (`return user;`), Spring fills in the status and headers for you (almost always `200 OK` plus `Content-Type`). You only control the **body**.

`ResponseEntity<T>` lets you control **all three** parts. It's a wrapper: _"here's the body of type `T`, and here's the status and headers to send with it."_

## Definition

`ResponseEntity<T>` is a class representing the **entire HTTP response**. It extends `HttpEntity<T>` (which holds body and headers) and adds the **status code**. When a controller method returns it, Spring writes the status, then the headers, then converts the body to JSON with Jackson, the same `HttpMessageConverter` machinery as `@ResponseBody`.

```java
@GetMapping("/api/users/{id}")
public ResponseEntity<User> getOne(@PathVariable Long id) {
    User user = service.findById(id);
    return ResponseEntity.ok(user);          // 200 + body
}
```

The `T` is the body's type. Use `Void` when there's no body, and `?` when the body type varies.

## Creating one: the builder style (recommended)

`ResponseEntity` has static factory methods that read almost like English:

```java
// 2xx success
ResponseEntity.ok(user)                                  // 200 + body
ResponseEntity.ok().build()                              // 200, no body
ResponseEntity.created(location).body(saved)             // 201 + Location header + body
ResponseEntity.accepted().build()                        // 202 (work queued, not done yet)
ResponseEntity.noContent().build()                       // 204, no body

// 4xx client errors
ResponseEntity.badRequest().body("Invalid input")        // 400
ResponseEntity.notFound().build()                        // 404, no body
ResponseEntity.status(HttpStatus.CONFLICT).body(...)     // any status: 409

// 3xx redirect
ResponseEntity.status(HttpStatus.FOUND).location(uri).build()
```

**The pattern:** pick a status method → optionally chain headers → finish with `.body(x)` or `.build()`.

- `.body(x)` finishes **with** a body.
- `.build()` finishes **without** a body.

## The constructor style (works, but wordier)

```java
return new ResponseEntity<>(user, HttpStatus.OK);
return new ResponseEntity<>(user, headers, HttpStatus.CREATED);
return new ResponseEntity<>(HttpStatus.NO_CONTENT);
```

Same result. The builder style is more readable and is what you'll see in modern code.

## Controlling the three parts

### 1. Status

```java
ResponseEntity.status(HttpStatus.CREATED)      // enum
ResponseEntity.status(418)                     // raw int (any code)
```

### 2. Headers

```java
// One header at a time
return ResponseEntity.ok()
        .header("X-Total-Count", "42")
        .header("X-Request-Id", UUID.randomUUID().toString())
        .body(users);

// Using HttpHeaders for several
HttpHeaders headers = new HttpHeaders();
headers.setLocation(URI.create("/api/users/7"));
headers.setContentType(MediaType.APPLICATION_JSON);
headers.add("X-Custom", "value");
return new ResponseEntity<>(saved, headers, HttpStatus.CREATED);
```

Built-in shortcuts exist for common headers:

```java
ResponseEntity.ok()
        .contentType(MediaType.APPLICATION_JSON)
        .eTag("\"v3\"")
        .cacheControl(CacheControl.maxAge(Duration.ofMinutes(10)))
        .lastModified(Instant.now())
        .location(uri)
        .body(data);
```

### 3. Body

Anything Jackson can serialize: an object, a list, a map, a `String`, `byte[]`, or a `Resource` (for files).

## The classic CRUD uses

```java
// CREATE → 201 + Location header
@PostMapping
public ResponseEntity<User> create(@Valid @RequestBody UserDto dto) {
    User saved = service.create(dto);
    URI location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}").buildAndExpand(saved.getId()).toUri();
    return ResponseEntity.created(location).body(saved);
}

// READ ONE → 200 or 404, decided at runtime
@GetMapping("/{id}")
public ResponseEntity<User> getOne(@PathVariable Long id) {
    return service.findOptionalById(id)               // returns Optional<User>
            .map(ResponseEntity::ok)                  // present → 200 + body
            .orElse(ResponseEntity.notFound().build()); // empty → 404
}

// DELETE → 204
@DeleteMapping("/{id}")
public ResponseEntity<Void> delete(@PathVariable Long id) {
    service.delete(id);
    return ResponseEntity.noContent().build();
}
```

Test with `-i` to see the status and headers (that's the whole point of this class):

```bash
curl -i -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alireza","email":"ali@mail.com"}'
```

```
HTTP/1.1 201
Location: http://localhost:8080/api/users/7
Content-Type: application/json
```

A handy shortcut for the Optional pattern above:

```java
return ResponseEntity.of(service.findOptionalById(id));
// Optional present → 200 + body, empty → 404
```

## Why use it instead of just returning the object? (the "why")

Because **the status code often depends on what happens at runtime**, and a plain return can only ever say 200.

|Situation|Plain return|`ResponseEntity`|
|---|---|---|
|Always the same success code|Fine (`@ResponseStatus`)|Overkill|
|Found → 200, missing → 404|Can't (needs an exception)|Easy|
|Need a `Location` header after POST|Can't|Easy|
|Custom headers (paging totals, cache, ETag)|Can't|Easy|
|File download with `Content-Disposition`|Can't|Easy|

### `@ResponseStatus` vs `ResponseEntity`

```java
@PostMapping
@ResponseStatus(HttpStatus.CREATED)        // FIXED at compile time
public User create(...) { ... }

@PostMapping
public ResponseEntity<User> create(...) {  // DECIDED at runtime, plus headers
    ...
}
```

Rule of thumb: **fixed status, no headers → `@ResponseStatus`. Dynamic status or headers → `ResponseEntity`.**

## Returning different body types: the `?` wildcard

Sometimes success returns a `User` but failure returns an error message. One declared `T` can't be both:

```java
@GetMapping("/{id}")
public ResponseEntity<?> getOne(@PathVariable Long id) {
    return service.findOptionalById(id)
            .<ResponseEntity<?>>map(ResponseEntity::ok)
            .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "User " + id + " not found")));
}
```

This works but is a code smell: you lose type safety and your API docs can't tell what's returned. The cleaner design is **throw an exception and handle it centrally** (as in the `@RestControllerAdvice` from earlier), so your controller returns `ResponseEntity<User>` only on the happy path.

## File download example

```java
@GetMapping("/files/{name}")
public ResponseEntity<Resource> download(@PathVariable String name) throws IOException {
    Resource file = new FileSystemResource("/home/alireza/uploads/" + name);
    if (!file.exists()) {
        return ResponseEntity.notFound().build();
    }
    return ResponseEntity.ok()
            .contentType(MediaType.APPLICATION_OCTET_STREAM)
            .header(HttpHeaders.CONTENT_DISPOSITION,
                    ContentDisposition.attachment().filename(name).build().toString())
            .contentLength(file.contentLength())
            .body(file);
}
```

(In real code, validate `name` so a client can't send `../../etc/passwd`. That attack is called path traversal.)

## Paging with headers

```java
@GetMapping
public ResponseEntity<List<User>> list(@RequestParam(defaultValue = "0") int page) {
    Page<User> result = service.findPage(page);
    return ResponseEntity.ok()
            .header("X-Total-Count", String.valueOf(result.getTotalElements()))
            .body(result.getContent());
}
```

An Angular front-end can then read `X-Total-Count`. By default, the browser hides custom headers from cross-origin JavaScript, so you must also expose it in your CORS config: `exposedHeaders = "X-Total-Count"`.

## Nuances and gotchas

**1. `ResponseEntity` overrides `@ResponseStatus`.** If a method has both, the `ResponseEntity` status wins. Don't mix them.

**2. `notFound()` and `noContent()` return a builder with no `.body()`.** You must end with `.build()`. Writing `ResponseEntity.notFound().body(x)` doesn't compile. If you want a 404 _with_ a body, use `ResponseEntity.status(HttpStatus.NOT_FOUND).body(x)`.

**3. A 204 or 304 must not have a body.** HTTP forbids it. Use `Void` as the type.

**4. Generics are erased at runtime.** `ResponseEntity<List<User>>` is fine for serialization, because Jackson looks at the actual objects. But this is also why `ResponseEntity<?>` works.

**5. Reading the status back (e.g., in tests or `RestTemplate`).** In Spring 6 / Boot 3, `getStatusCode()` returns `HttpStatusCode` (an interface), not the old `HttpStatus` enum. `getStatusCodeValue()` is deprecated. For a numeric value use `response.getStatusCode().value()`.

**6. Exceptions are still the cleaner path for errors.** A controller full of `if (x) return ResponseEntity.badRequest()...` gets noisy. Throw, then let `@RestControllerAdvice` convert it.

**7. Spring 6 also supports `ProblemDetail`,** a standard error format (RFC 9457, formerly RFC 7807). It's a ready-made body for errors (`type`, `title`, `status`, `detail`), and you can return it directly or wrap it: `ResponseEntity.of(problemDetail).build()`. Worth learning later.

**8. `ResponseEntity` is for the _whole_ response, not partial.** If you set `.body(...)` to a `String`, Spring writes the raw string. If a `String` is returned via plain `@RestController`, it also writes raw text, not JSON-quoted. This confuses people who expect `"hello"` with quotes.

**9. It's synchronous.** For async you wrap it (`CompletableFuture<ResponseEntity<T>>`) or use `ResponseEntity<StreamingResponseBody>` for streaming. Later topics.

## Quick reference

|You want|Code|
|---|---|
|200 + body|`ResponseEntity.ok(body)`|
|201 + Location + body|`ResponseEntity.created(uri).body(body)`|
|202 accepted|`ResponseEntity.accepted().build()`|
|204 no content|`ResponseEntity.noContent().build()`|
|400 + message|`ResponseEntity.badRequest().body(msg)`|
|404 no body|`ResponseEntity.notFound().build()`|
|Any status + body|`ResponseEntity.status(code).body(body)`|
|Optional → 200/404|`ResponseEntity.of(optional)`|
|Add a header|`.header("Name", "value")`|
|Set cache|`.cacheControl(CacheControl.maxAge(...))`|

## How it fits the bigger picture

You now have all the **input** annotations (`@PathVariable`, `@RequestParam`, `@RequestBody`) and the **output** control (`ResponseEntity`, `@ResponseStatus`). Together they describe a full HTTP exchange:

```
Request  →  [@PathVariable / @RequestParam / @RequestBody]  →  your method
Response ←  [ResponseEntity: status + headers + body]        ←  your method
```




[[Spring Framework]]
[[Networking]]