
# ProblemDetail

`ProblemDetail` is a class Spring provides (since Spring Framework 6 / Spring Boot 3) for building error responses that follow **RFC 9457** ("Problem Details for HTTP APIs" — the successor to RFC 7807). Instead of every team inventing their own JSON shape for error responses, RFC 9457 standardizes on a handful of fields, and `ProblemDetail` is Spring's built-in Java representation of that shape. When you return it from a controller or an exception handler, Spring serializes it as `application/problem+json`, and the client gets a predictable, self-describing error body instead of a raw stack trace or an ad-hoc `{"error": "..."}` map.

## What the standard shape looks like

The RFC defines these fields:

```json
{
  "type": "https://example.com/errors/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 403,
  "detail": "Your balance is 25, but the transfer requires 50.",
  "instance": "/accounts/12345/transactions/abc"
}
```

- **type** — a URI identifying the _category_ of problem. Defaults to `"about:blank"` if you don't set one.
- **title** — a short, human-readable summary of the problem type. Should be stable across occurrences of the same `type`.
- **status** — the HTTP status code, duplicated here so the body is self-contained even if something strips the HTTP status line.
- **detail** — a human-readable explanation specific to _this_ occurrence (can include the actual numbers, as above).
- **instance** — a URI identifying this specific occurrence (often just the request path).

Spring's `ProblemDetail` class models exactly this, plus lets you attach arbitrary extra properties.

## Creating one

The easiest way is a static factory method:

```java
ProblemDetail problem = ProblemDetail.forStatusAndDetail(
        HttpStatus.FORBIDDEN,
        "Your balance is 25, but the transfer requires 50."
);
```

`forStatusAndDetail` sets `status` and `detail` for you, and fills in a default `title` ("Forbidden") derived from the status code. You can also start from just a status:

```java
ProblemDetail problem = ProblemDetail.forStatus(HttpStatus.NOT_FOUND);
```

and fill in the rest yourself with setters:

```java
problem.setTitle("Account Not Found");
problem.setDetail("No account exists with id 12345.");
problem.setType(URI.create("https://example.com/errors/account-not-found"));
problem.setInstance(URI.create("/accounts/12345"));
```

## Adding custom properties

Real APIs usually need more than the five standard fields — a timestamp, a trace ID, a list of field errors. `ProblemDetail` supports this through `setProperty`:

```java
problem.setProperty("timestamp", Instant.now());
problem.setProperty("errorCode", "ACC_NOT_FOUND");
```

These get serialized as extra top-level JSON fields alongside `type`, `title`, `status`, `detail`, and `instance` — which is exactly what RFC 9457 allows (it calls these "extension members").

## Using it in a controller or exception handler

You can return `ProblemDetail` directly from a handler method:

```java
@GetMapping("/accounts/{id}")
public ResponseEntity<Account> getAccount(@PathVariable Long id) {
    Account account = repository.findById(id)
            .orElseThrow(() -> new AccountNotFoundException(id));
    return ResponseEntity.ok(account);
}
```

and then handle the exception centrally with `@ExceptionHandler` inside a `@RestControllerAdvice`:

```java
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(AccountNotFoundException.class)
    public ProblemDetail handleAccountNotFound(AccountNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setTitle("Account Not Found");
        problem.setProperty("timestamp", Instant.now());
        return problem;
    }
}
```

Spring sees the return type is `ProblemDetail`, sets the response's HTTP status from `problem.getStatus()`, and serializes the body as `application/problem+json`. You never have to manually wrap it in a `ResponseEntity` — though you can, if you need to add response headers:

```java
@ExceptionHandler(AccountNotFoundException.class)
public ResponseEntity<ProblemDetail> handleAccountNotFound(AccountNotFoundException ex) {
    ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND, ex.getMessage());
    return ResponseEntity.status(problem.getStatus())
            .header("X-Error-Source", "account-service")
            .body(problem);
}
```

## Where it plugs into Spring Boot's defaults

Spring Boot's own built-in exception handling (`ResponseEntityExceptionHandler`, which handles things like malformed request bodies or validation failures before your code even runs) already returns `ProblemDetail` under the hood. That's why, if you've ever hit a validation error in a Spring Boot 3+ app without writing any custom handler, you've already seen a `problem+json` response — Spring Boot produces it automatically. Writing your own `@RestControllerAdvice` methods like above is how you extend that same consistent format to your own custom exceptions, so a client talking to your API never has to deal with two different error shapes depending on whether Spring or your code raised the problem.


[[Spring Framework]]