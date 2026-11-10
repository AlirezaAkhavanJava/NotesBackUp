
`@ResponseStatus` is a Spring annotation that lets you declare, in one line, which HTTP status code a response should have. You put it on a controller method, on an exception class, or on an `@ExceptionHandler` method, and Spring applies that status for you, so you don't need to build the response by hand.

The important word is **declare**. The status is fixed at compile time, so the annotation is perfect when a method or exception always means the same status, and the wrong tool when the status depends on runtime logic. Most of this tutorial is about knowing which case you are in.

## How to use it: three places

**1. On a controller method** to set the status for a normal, successful return.

```java
@PostMapping("/products")
@ResponseStatus(HttpStatus.CREATED)          // 201 instead of the default 200
public ProductResponse create(@Valid @RequestBody ProductRequest req) {
    return service.create(req);
}

@DeleteMapping("/products/{id}")
@ResponseStatus(HttpStatus.NO_CONTENT)       // 204, empty body
public void delete(@PathVariable Long id) {
    service.delete(id);
}
```

Without the annotation, both methods would answer `200 OK`. Spring uses 200 for every successful return unless told otherwise. Two details:

- The status is applied only when the method **returns normally**. If it throws, this annotation plays no part.
- A `void` method with `@ResponseStatus` sends that status with an empty body. That is why `DELETE` → `204` needs no `ResponseEntity`.

**2. On an exception class** to say "whenever this exception escapes a controller, answer with this status".

```java
@ResponseStatus(HttpStatus.NOT_FOUND)
public class ProductNotFoundException extends RuntimeException {
    public ProductNotFoundException(Long id) {
        super("Product " + id + " not found");
    }
}
```

```java
@GetMapping("/products/{id}")
public ProductResponse read(@PathVariable Long id) {
    return repo.findById(id)
        .map(mapper::toResponse)
        .orElseThrow(() -> new ProductNotFoundException(id));   // client gets 404
}
```

Spring's `ResponseStatusExceptionResolver` sees the exception, reads the annotation on its class, and sets 404. You wrote no handler code at all.

**3. On an `@ExceptionHandler` method** inside `@RestControllerAdvice`, to set the status for a handled exception.

```java
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(IllegalStateException.class)
    @ResponseStatus(HttpStatus.CONFLICT)                    // 409
    public ErrorBody handleConflict(IllegalStateException ex) {
        return new ErrorBody("CONFLICT", ex.getMessage());
    }
}

public record ErrorBody(String code, String message) { }
```

Here the handler returns a body, and the annotation supplies the status. Without it, the client would receive your error body with `200 OK`, which is a classic bug.

## When to use it

|Situation|Use it?|Why|
|---|---|---|
|`POST` that always creates → 201|Yes|Fixed status, no extra header needed|
|`DELETE` or other void action → 204|Yes|Fixed status, nothing to return|
|Exception that always means one status, like "not found"|Yes, on the class|Zero handler code|
|`@ExceptionHandler` returning your own error DTO|Yes|Otherwise the status stays 200|

The common thread is that **the status is always the same** for that method or exception.

## When not to use it

**The status depends on runtime logic.** The annotation cannot branch:

```java
@PutMapping("/products/{id}")
public ResponseEntity<ProductResponse> upsert(@PathVariable Long id, @RequestBody ProductRequest req) {
    boolean existed = repo.existsById(id);
    ProductResponse saved = service.save(id, req);
    return existed
        ? ResponseEntity.ok(saved)                  // 200 when updated
        : ResponseEntity.status(HttpStatus.CREATED).body(saved);   // 201 when created
}
```

Use `ResponseEntity` when you must choose the status inside the method.

**You need to set headers, such as `Location` on a 201.** A proper create response includes `Location`, and the annotation can't add it:

```java
return ResponseEntity.created(URI.create("/products/" + saved.id())).body(saved);
```

**The method already returns `ResponseEntity`.** The `ResponseEntity` status wins, and the annotation is dead weight that misleads readers. Pick one.

**You use the `reason` attribute.** `@ResponseStatus(value = NOT_FOUND, reason = "Product missing")` looks convenient, but with `reason` set, Spring calls `response.sendError(...)`. That hands control to the servlet container's error handling, and your body is replaced by the default error page or JSON. It also bypasses your `@RestControllerAdvice`. Leave `reason` out and put the message in the exception or in a `ProblemDetail`.

**You return `ProblemDetail`.** It carries its own `status` field, so the annotation adds nothing:

```java
@ExceptionHandler(ProductNotFoundException.class)
public ProblemDetail handle(ProductNotFoundException ex) {
    ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    pd.setTitle("Product not found");
    return pd;
}
```

**Your exceptions live in the service or domain layer.** Putting `@ResponseStatus` on `ProductNotFoundException` makes a business class depend on HTTP, which is a web-layer concern. In a small project that is an acceptable shortcut. In a larger one, keep the exception plain and map it to a status in `@RestControllerAdvice`, as in the example above. That keeps the HTTP knowledge in one place.

## A related concept in one short summary

**`ResponseStatusException`** is the programmatic version of an exception annotated with `@ResponseStatus`. You throw it inline and choose the status at the throw site, with no custom exception class:

```java
Product p = repo.findById(id)
    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product " + id + " not found"));
```

It is handy for quick endpoints and prototypes. For a real API with many endpoints, a dedicated exception per case plus one `@RestControllerAdvice` is easier to keep consistent.


[[Spring Framework]]