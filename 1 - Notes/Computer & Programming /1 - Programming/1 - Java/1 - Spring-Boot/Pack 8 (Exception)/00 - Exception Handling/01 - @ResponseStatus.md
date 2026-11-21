

## Mental model

Every HTTP response starts with a **status line** (`200 OK`, `404 Not Found`, ...). By default Spring stamps `200` on any method that returns normally. `@ResponseStatus` is a **sticker you put on a method or exception class** that says: _"when this runs, use this status code instead."_

It's the **fixed, compile-time** way to set the status. Its runtime sibling is `ResponseEntity`, which you already know.

## Definition

```java
@ResponseStatus(HttpStatus.CREATED)
```

It can be placed in **three places**, and each behaves differently.

### 1. On a controller method: the success status

```java
@PostMapping
@ResponseStatus(HttpStatus.CREATED)          // 201 instead of 200
public ProductResponse create(@Valid @RequestBody ProductRequest req) {
    return service.create(req);
}

@DeleteMapping("/{id}")
@ResponseStatus(HttpStatus.NO_CONTENT)       // 204
public void delete(@PathVariable Long id) {
    service.delete(id);
}
```

It applies **only if the method returns normally**. If it throws, the annotation is ignored and the exception machinery decides the status.

### 2. On a custom exception class: "if this is thrown, answer with this status"

```java
@ResponseStatus(HttpStatus.NOT_FOUND)
public class ProductNotFoundException extends RuntimeException {
    public ProductNotFoundException(Long id) {
        super("Product " + id + " not found");
    }
}
```

```java
@GetMapping("/{id}")
public ProductResponse getOne(@PathVariable Long id) {
    return service.findById(id);   // throws ProductNotFoundException → 404
}
```

No handler code is needed. The exception itself carries its HTTP meaning. The annotation is also found on **superclasses**, so a base `ApiException` with a status applies to all its children unless they override it.

### 3. On an `@ExceptionHandler` method

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalStateException.class)
    @ResponseStatus(HttpStatus.CONFLICT)                 // 409
    public Map<String, String> conflict(IllegalStateException ex) {
        return Map.of("error", ex.getMessage());
    }
}
```

You already used this form in the first CRUD example. Without it, the handler's response would be **200 OK** with an error message in the body, a classic bug.

## Its parameters

|Parameter|Meaning|
|---|---|
|`value` / `code`|The `HttpStatus` (aliases of each other)|
|`reason`|Optional message string (see the gotcha below)|

```java
@ResponseStatus(HttpStatus.CREATED)
@ResponseStatus(code = HttpStatus.CREATED)
@ResponseStatus(value = HttpStatus.NOT_FOUND, reason = "Product not found")
```

## How it works inside (the "why")

Two different Spring components handle it:

- **On a method:** after your method returns, `ServletInvocableHandlerMethod` reads the annotation and sets the status on the response **before** the body is written.
- **On an exception class:** `ResponseStatusExceptionResolver` catches exceptions that nobody else handled, reads the annotation, and sets the status.

Exceptions pass through a **chain of resolvers, in order**:

```
exception thrown
   1. ExceptionHandlerExceptionResolver   → your @ExceptionHandler methods (win first)
   2. ResponseStatusExceptionResolver     → @ResponseStatus on the exception class,
                                            and ResponseStatusException
   3. DefaultHandlerExceptionResolver     → Spring's built-in ones (400 type mismatch, 405, ...)
   (nobody handled it) → 500
```

That order explains a common surprise: **if an `@ExceptionHandler` exists for the exception, the `@ResponseStatus` on the exception class is ignored**, because step 1 already handled it.

## `@ResponseStatus` vs `ResponseEntity` vs `ResponseStatusException`

||`@ResponseStatus`|`ResponseEntity`|`ResponseStatusException`|
|---|---|---|---|
|Decided|compile time (fixed)|runtime|runtime|
|Sets headers?|no|yes|limited|
|Changes the body?|no|yes|no|
|Where|method / exception class|return value|thrown anywhere|
|Best for|one predictable success code, or an exception with a fixed meaning|status or headers depend on logic|quick one-off error without creating a class|

`ResponseStatusException` is the programmatic cousin:

```java
return repo.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product " + id + " not found"));
```

Rule of thumb: **fixed success code → `@ResponseStatus`; dynamic or needs headers → `ResponseEntity`; error → throw an exception.**

## What happens if you don't use it

|Situation|Without it|
|---|---|
|POST that creates something|Returns **200** instead of 201. It works, but clients and API tools expecting 201 treat it as non-standard|
|`@ExceptionHandler` returning an error body|Responds **200 OK with an error JSON**. Clients think the request succeeded|
|Custom exception, no handler, no annotation|Falls through to **500 Internal Server Error**, so the client can't tell "not found" from "server crashed"|
|`void` delete|200 with an empty body, which is not wrong but less precise than 204|

## Nuances and gotchas

**1. `reason` changes behavior significantly.** When `reason` is set (or on an exception class), Spring calls `response.sendError(status, reason)` instead of just setting the status. That hands control to the servlet container's **error dispatch**, so in Spring Boot the response body comes from `BasicErrorController` (`/error`), not from your code. Spring Boot 3 also hides the message by default (`server.error.include-message=never`), so `reason` often **doesn't appear** to the client. For readable error bodies, use an `@ExceptionHandler` returning a `ProblemDetail`.

**2. `ResponseEntity` wins.** If a method has both `@ResponseStatus` and returns `ResponseEntity`, the `ResponseEntity` status is used. Don't mix them.

**3. It can't be dynamic.** `@ResponseStatus(HttpStatus.CREATED)` always means 201. Found-or-not logic can't be expressed in it.

**4. `void` + `@ResponseStatus` is the clean idiom for empty replies.** Spring treats a `void` method with this annotation as "response fully handled", so it doesn't try to resolve a view name. Without it, in a plain `@Controller`, a `void` method falls back to guessing a view from the URL.

**5. 204 and 304 must have no body.** Putting `@ResponseStatus(NO_CONTENT)` on a method that returns an object is a mistake. Use `void` for 204.

**6. You can't annotate classes you don't own.** Exceptions from libraries (JPA, Jackson) can't carry the annotation. Map them with `@ExceptionHandler`.

**7. Exception classes become coupled to HTTP.** Putting `@ResponseStatus` on a domain exception makes your service layer "know" about HTTP. Many teams keep domain exceptions pure and translate them in `@RestControllerAdvice` instead. For small projects the annotation is fine, and it's a design trade-off, not a rule.

**8. Spring's own exceptions already have statuses.** `MethodArgumentNotValidException` → 400, `HttpRequestMethodNotSupportedException` → 405, and so on. Those come from `DefaultHandlerExceptionResolver` (step 3 above), not from this annotation.

## Quick reference

|Status|Constant|Typical use|
|---|---|---|
|200|`OK`|default, no annotation needed|
|201|`CREATED`|POST created a resource|
|202|`ACCEPTED`|work queued, not finished|
|204|`NO_CONTENT`|DELETE / update with no body|
|400|`BAD_REQUEST`|invalid input|
|404|`NOT_FOUND`|resource missing|
|409|`CONFLICT`|duplicate / state conflict|
|422|`UNPROCESSABLE_ENTITY`|semantically invalid data|

Test it with `-i` so you can see the status line:

```bash
curl -i -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Keyboard","price":49.90,"stock":10}'
# HTTP/1.1 201
```



[[Spring Framework]]
[[Networking]]