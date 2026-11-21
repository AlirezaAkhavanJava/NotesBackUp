
`ResponseEntity` has a lot of static factory methods, but in real Spring Boot work you'll lean on a small, repeated subset. Here's what actually gets used:

## The ones you'll use constantly

**1. `ResponseEntity.ok(body)`** — 200 OK with a body. This is your default for successful GET/PUT responses.

```java
return ResponseEntity.ok(userDto);
```

**2. `ResponseEntity.status(HttpStatus).body(...)`** — the general-purpose builder for any status code with any body. When nothing more specific fits, this is the fallback:

```java
return ResponseEntity.status(HttpStatus.CONFLICT).body(problemDetail);
```

**3. `ResponseEntity.created(URI location)`** — 201 Created with a `Location` header, used right after a successful POST (this is the one from the earlier `URI` example):

```java
return ResponseEntity.created(location).body(userDto);
```

**4. `ResponseEntity.noContent().build()`** — 204 No Content, the standard response for a successful DELETE (or a PUT that returns nothing):

```java
return ResponseEntity.noContent().build();
```

**5. `ResponseEntity.notFound().build()`** — 404 when a lookup fails. Though in modern Spring Boot you more often throw an exception and let `@RestControllerAdvice` + `ProblemDetail` handle this instead of returning it directly from the controller.

**6. `.header(name, value)`** and **`.headers(HttpHeaders)`** — chained onto a builder (`ok()`, `status()`, etc.) when you need to set a custom response header:

```java
return ResponseEntity.ok().header("X-Total-Count", "42").body(list);
```

**7. `.build()`** — closes off a builder chain when there's no body, e.g. `ResponseEntity.noContent().build()`, `ResponseEntity.ok().build()`.

## The ones you'll rarely touch

- `badRequest()`, `accepted()`, `unprocessableEntity()` — exist and work exactly like `ok()`/`noContent()`, but most teams funnel errors through `@RestControllerAdvice` with `ProblemDetail` instead of returning these directly from a controller.
- `ResponseEntity.of(Optional<T>)` — turns an `Optional` into 200 (if present) or 404 (if empty) automatically. Handy, but many teams avoid it because it hides the 404 decision inside a static method instead of making it explicit.
- Direct constructors (`new ResponseEntity<>(body, headers, status)`) — technically available, but the static builder methods above are considered more readable and are what you'll see in virtually all modern code and style guides.

## The real pattern

In practice, a typical Spring Boot controller only uses **3 or 4 of these**: `ok()`, `created()`, `noContent()`, and `status().body()` as the catch-all — with actual error handling delegated to exceptions and `@RestControllerAdvice`, not to the controller returning a `ResponseEntity` with an error status directly.


[[Spring Framework]]