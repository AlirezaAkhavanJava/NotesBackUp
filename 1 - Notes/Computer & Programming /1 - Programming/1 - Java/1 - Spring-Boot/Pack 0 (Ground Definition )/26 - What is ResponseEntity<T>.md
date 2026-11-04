

`ResponseEntity<T>` is a Spring class that represents the **entire HTTP response** as an object: the status code, the headers, and the body. When a controller method returns a plain object, Spring decides everything except the body for you (it sends `200 OK` with default headers). When you return a `ResponseEntity`, you take control of all three parts, so you can say "respond with `201 Created`, set this `Location` header, and put this DTO in the body". Despite the name, it has nothing to do with JPA entities. Here, "entity" means the HTTP message (the old HTTP spec literally calls the body "the entity").

## The problem it solves

An HTTP response is more than JSON. Consider what a well-behaved REST API should do:

- Creating a resource should return `201 Created`, not `200`, and tell the client where the new resource lives via a `Location` header.
- Deleting something should return `204 No Content`, with no body at all.
- Looking up a missing resource should return `404`, not `200` with `null`.
- Some responses need headers such as `Cache-Control`, `ETag`, or `Content-Disposition` (file downloads).

A method that returns just `UserResponse` can do none of this dynamically. `ResponseEntity` is how a single method decides, at runtime, what status and headers go out with the body.

## The basics

You build it with static factory methods, so you rarely call a constructor:

```java
@GetMapping("/{id}")
public ResponseEntity<UserResponse> get(@PathVariable Long id) {
    return ResponseEntity.ok(userService.get(id));            // 200 + body
}

@DeleteMapping("/{id}")
public ResponseEntity<Void> delete(@PathVariable Long id) {
    userService.delete(id);
    return ResponseEntity.noContent().build();                // 204, no body
}
```

Two patterns appear everywhere:

- `ResponseEntity.ok(body)` is a shortcut when you have a body. The other shortcuts (`noContent()`, `notFound()`, `badRequest()`, `accepted()`) return a _builder_, so you finish with `.build()` when there is no body, or `.body(x)` when there is one.
- `ResponseEntity.status(HttpStatus.CONFLICT).body(x)` handles any status without a dedicated shortcut.

The generic type is the body type. Use `ResponseEntity<Void>` when there is no body. Avoid `ResponseEntity<?>` where you can, because it hides the response shape from readers and from OpenAPI generators.

## The classic case: creating a resource

```java
@PostMapping
public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
    UserResponse created = userService.create(request);

    URI location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(created.id())
            .toUri();

    return ResponseEntity.created(location).body(created);   // 201 + Location header
}
```

The `Location` header is what makes this RESTful: the client learns the URL of the new resource without guessing. Building it from the current request avoids hard-coding hosts or ports.

## Optional lookups

When the resource may not exist, a compact idiom is:

```java
return userService.find(id)                       // Optional<UserResponse>
        .map(ResponseEntity::ok)
        .orElseGet(() -> ResponseEntity.notFound().build());
```

This is fine for simple cases, but it spreads "not found" handling across every controller method. See the next section for the cleaner approach.

## When you do not need it

`ResponseEntity` is a tool for _dynamic_ control, not something every method must return. Two simpler options exist:

**Plain return value.** If the answer is always `200` with a body, just return the DTO. Less code, same result.

**`@ResponseStatus`.** If the status is fixed, annotate the method:

```java
@PostMapping
@ResponseStatus(HttpStatus.CREATED)
public UserResponse create(@Valid @RequestBody CreateUserRequest request) {
    return userService.create(request);
}
```

This is clean, but it cannot add a `Location` header or vary the status per call. The rule of thumb: use `ResponseEntity` when the status or headers depend on runtime logic, and the simpler forms when they do not.

## Errors: do not return them from every method

A common mistake is to have each controller method build error responses itself:

```java
if (user == null) return ResponseEntity.status(404).body(errorBody);
```

This makes controllers noisy and inconsistent. Instead, let services throw exceptions (`UserNotFoundException`) and translate them in one place with `@RestControllerAdvice`, which can itself return `ResponseEntity` or `ProblemDetail`. Controllers then focus on the success path, which is why many methods end up returning plain DTOs.

## Headers and file downloads

Headers are set through the builder:

```java
return ResponseEntity.ok()
        .header(HttpHeaders.CACHE_CONTROL, "max-age=3600")
        .eTag("\"v" + version + "\"")
        .body(dto);
```

Downloads are the other place `ResponseEntity` is almost mandatory, because you need the content type and a download filename:

```java
return ResponseEntity.ok()
        .contentType(MediaType.APPLICATION_PDF)
        .header(HttpHeaders.CONTENT_DISPOSITION,
                ContentDisposition.attachment().filename("report.pdf").build().toString())
        .body(new ByteArrayResource(pdfBytes));
```

## How it works internally

Spring MVC sees the return type, writes the status and headers first, then passes the body to an `HttpMessageConverter` (Jackson for JSON) to serialize it. Which converter runs depends on **content negotiation**, meaning the client's `Accept` header and the content type you set. `@RestController` is what tells Spring to write return values to the response body instead of resolving a view name.

## Common mistakes

- Returning `200` with `null` or an empty body for "not found".
- Returning `200` from create endpoints and skipping the `Location` header.
- Sending a body with `204`. By definition it must have none.
- Returning entities inside `ResponseEntity`. It does not change the DTO rule from earlier.
- Overusing `ResponseEntity<?>`, or wrapping every method in it when a plain return would do.

## Related concepts to study next

- **HTTP status code semantics** (`200`, `201`, `204`, `400`, `401`, `403`, `404`, `409`, `422`) and choosing the right one
- **`@RestControllerAdvice` and `ProblemDetail`** for consistent error responses
- **`RequestEntity` and `HttpEntity`**, the request-side and parent types
- **`HttpHeaders` and `HttpStatusCode`** (Spring 6 uses `HttpStatusCode` as the broader status type)
- **HTTP caching** with `ETag` and conditional requests
- **`HttpMessageConverter` and content negotiation**
- **Streaming responses** with `StreamingResponseBody` for large files





[[Spring Framework]]