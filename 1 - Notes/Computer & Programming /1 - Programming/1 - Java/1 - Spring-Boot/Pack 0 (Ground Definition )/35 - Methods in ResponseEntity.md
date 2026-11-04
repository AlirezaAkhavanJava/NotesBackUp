

`ResponseEntity` has a small but layered API. There are really three things to learn: the **static factory methods** that start a response, the **builder methods** that shape it, and the **terminal methods** that finish it. Once you see them as a pipeline (start, shape, finish), choosing the right call becomes mechanical. We already covered `ok`, `created`, `noContent` and the basic idea, so this tutorial focuses on everything else and on the decision of which method to use when.

## The pipeline

```text
ResponseEntity.<starter>(...)   ->   .<builder methods>(...)   ->   .body(x) or .build()
     picks the status              adds headers / metadata          produces the final object
```

The type you hold in the middle matters. Starters like `ok()`, `created(uri)`, `status(...)` return a **`BodyBuilder`** (you can finish with `.body(x)` or `.build()`). Starters like `noContent()`, `notFound()`, `badRequest()`... split: `noContent()` and `notFound()` return a **`HeadersBuilder`** (finish with `.build()` only, since those statuses carry no body), while `badRequest()`, `unprocessableEntity()` and `internalServerError()` return a `BodyBuilder`.

## Starters (status)

|Method|Status|Body allowed|When to use|
|---|---|---|---|
|`ok()` / `ok(body)`|200|yes|Successful read or update|
|`created(URI)`|201|yes|POST that created a resource; sets `Location`|
|`accepted()`|202|yes|Work queued for async processing, not finished yet|
|`noContent()`|204|no|Successful delete, or update where you return nothing|
|`badRequest()`|400|yes|Malformed request you detect manually|
|`notFound()`|404|no|Missing resource (prefer exceptions, see below)|
|`unprocessableEntity()`|422|yes|Well-formed but semantically rejected|
|`internalServerError()`|500|yes|Rarely used by hand; let exception handling do it|
|`status(HttpStatusCode)` / `status(int)`|any|yes|Anything without a shortcut: `409`, `403`, `429`...|
|`of(Optional<T>)`|200 or 404|yes|Converts an `Optional` directly|
|`of(ProblemDetail)`|from the detail|yes|Returning a standards-based error body|

Two of these deserve a closer look.

**`accepted()`** means "I received your request and will process it later." Pair it with a `Location` header pointing to a status endpoint the client can poll:

```java
@PostMapping("/reports")
public ResponseEntity<Void> generate(@RequestBody ReportRequest request) {
    String jobId = reportService.enqueue(request);
    return ResponseEntity.accepted()
            .location(URI.create("/reports/jobs/" + jobId))
            .build();
}
```

**`of(Optional)`** removes the `.map(...).orElseGet(...)` idiom from before:

```java
return ResponseEntity.of(userService.find(id));   // 200 with body, or 404 if empty
```

**`status(...)`** is the escape hatch. Prefer the `HttpStatus` enum for readability:

```java
return ResponseEntity.status(HttpStatus.CONFLICT).body(problem);
```

## Builder methods (shaping the response)

These are chained between the starter and the terminal call, and each returns the builder so you can keep chaining.

**`header(String name, String... values)`** adds an arbitrary header, and calling it again with the same name appends values rather than replacing them. **`headers(HttpHeaders)`** or **`headers(Consumer<HttpHeaders>)`** is better when setting several at once:

```java
return ResponseEntity.ok()
        .headers(h -> {
            h.add("X-Request-Id", requestId);
            h.add("X-Rate-Limit-Remaining", String.valueOf(remaining));
        })
        .body(dto);
```

**`contentType(MediaType)`** sets the `Content-Type`. Use it when the body is not the default JSON, such as `APPLICATION_PDF`, `TEXT_PLAIN`, `IMAGE_PNG`, or `APPLICATION_OCTET_STREAM` for arbitrary binary data. Note that `contentType` also influences which `HttpMessageConverter` serializes the body.

**`contentLength(long)`** sets `Content-Length`. Useful for downloads where you know the size so the client can show progress. For small JSON responses, skip it; Spring computes it.

**`location(URI)`** sets the `Location` header. Used with `201` (new resource URL), `202` (status endpoint), and `3xx` redirects.

**`eTag(String)`** and **`lastModified(Instant)`** are the validators behind HTTP caching. **`cacheControl(CacheControl)`** controls caching rules. They work together:

```java
return ResponseEntity.ok()
        .cacheControl(CacheControl.maxAge(Duration.ofHours(1)).cachePublic())
        .eTag("\"" + product.getVersion() + "\"")
        .lastModified(product.getUpdatedAt())
        .body(productDto);
```

With these set, a client can re-ask with `If-None-Match` and you can answer `304 Not Modified` instead of resending the body. Spring even automates that check: calling `request.checkNotModified(...)` on `WebRequest` handles the comparison for you.

**`allow(HttpMethod...)`** sets the `Allow` header, used when answering `OPTIONS` or `405 Method Not Allowed`.

**`varyBy(String...)`** sets the `Vary` header, telling caches which request headers influence the response (for example `Accept-Language`).

## Terminal methods

- **`build()`** finishes a response with no body. Use with `noContent()`, `notFound()`, `accepted()`, or any case where you only need status and headers.
- **`body(T)`** finishes a response with a body. This is also where the generic type `T` gets fixed.

A subtle point: if the starter was `ok()` and you call `build()`, you get `ResponseEntity<Void>`; if you call `.body(dto)` you get `ResponseEntity<UserResponse>`. So the return type of your method must match what you finish with.

## Reading a ResponseEntity

Everything above builds responses, but the class is also read-only accessible, and you will use these in tests and when consuming other APIs:

|Method|Returns|
|---|---|
|`getStatusCode()`|`HttpStatusCode` (in Spring 6; older code used `HttpStatus`)|
|`getBody()`|the body, possibly `null`|
|`getHeaders()`|`HttpHeaders`|
|`hasBody()`|whether a body exists|

On the client side, `RestTemplate.getForEntity(...)` and `RestClient...retrieve().toEntity(Foo.class)` return a `ResponseEntity<Foo>`, which is how you inspect the status and headers of a call you made to another service:

```java
ResponseEntity<UserResponse> response =
        restClient.get().uri("/users/{id}", 1).retrieve().toEntity(UserResponse.class);

if (response.getStatusCode().is2xxSuccessful()) {
    UserResponse user = response.getBody();
}
```

`HttpStatusCode` offers `is2xxSuccessful()`, `is4xxClientError()`, `is5xxServerError()` and `value()` for the raw number.

## The constructor (and why you skip it)

```java
new ResponseEntity<>(body, headers, HttpStatus.OK);
```

This works, but the static builders express intent more clearly and chain better. The constructor appears mostly in older code, so recognize it, but do not write new code with it.

## Choosing quickly: a decision guide

- **Always 200 with a body, no headers?** Return the DTO directly. Skip `ResponseEntity`.
- **Always the same non-200 status?** Use `@ResponseStatus` on the method.
- **Created something?** `created(uri).body(dto)`.
- **Deleted or nothing to return?** `noContent().build()`.
- **Work continues in the background?** `accepted().location(...).build()`.
- **Lookup that may be missing?** `ResponseEntity.of(optional)`, or throw an exception and let `@RestControllerAdvice` produce the `404`.
- **Need custom headers, caching, or a file download?** `ok()` plus builder methods plus `.body(...)`.
- **Unusual status such as `409` or `429`?** `status(HttpStatus.X).body(...)`.
- **Error of any kind?** Prefer throwing, and use `ResponseEntity` inside the central exception handler.

## Common mistakes

- Calling `.body(...)` on a `HeadersBuilder` result: `noContent()` and `notFound()` only offer `build()`.
- Setting `Content-Type` to JSON manually when Spring would have chosen it correctly anyway.
- Returning `ResponseEntity<String>` containing hand-built JSON text. Return the DTO and let Jackson serialize it.
- Forgetting that `header("X", "a")` called twice yields two values, not a replacement. Use `headers(h -> h.set(...))` when you need replacement.
- Setting `eTag` without quotes. ETag values are quoted strings by spec.
- Using `ResponseEntity` on every method out of habit, which adds noise without adding control.

## Related concepts to study next

- **HTTP caching in depth**: strong vs. weak ETags, `If-None-Match`, `If-Modified-Since`, and `304`
- **`ContentDisposition`** and file download and upload handling
- **`StreamingResponseBody` and `ResponseBodyEmitter`** for large or incremental responses
- **`ProblemDetail`** and `ErrorResponse` (RFC 9457) for standard error bodies
- **`RestClient` and `WebClient`**, the consumers of `ResponseEntity` on the client side
- **Redirects** (`301`, `302`, `303`, `307`, `308`) and how to produce them with `location`
- **Content negotiation** and `produces` / `consumes` on mappings




[[Spring Framework]]