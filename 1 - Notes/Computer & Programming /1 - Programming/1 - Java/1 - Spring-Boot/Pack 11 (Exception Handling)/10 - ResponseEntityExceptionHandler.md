

`ResponseEntityExceptionHandler` is a base class Spring MVC provides for writing a _global_ exception handler. Instead of scattering `try/catch` blocks across every controller, you extend this one class, override the exception-handling methods you care about, and Spring routes exceptions from _any_ controller in your app through it. It's the class Spring Boot's own built-in error handling is built on top of — the one responsible for turning things like a malformed JSON body or a failed `@Valid` check into a consistent `ProblemDetail` response before your code ever runs.

(Quick note on the name — in older Spring Boot versions, this class was sometimes referred to with "Rest" in front informally, but the actual class name is just `ResponseEntityExceptionHandler`. I'll use the real name throughout.)

## The problem it solves

Without it, you'd write something like this in every controller:

```java
@GetMapping("/accounts/{id}")
public ResponseEntity<Account> getAccount(@PathVariable Long id) {
    try {
        return ResponseEntity.ok(service.findAccount(id));
    } catch (AccountNotFoundException ex) {
        return ResponseEntity.status(404).body(/* some error shape */);
    }
}
```

Repeated in every method, in every controller, often with slightly different error shapes depending on who wrote it. `ResponseEntityExceptionHandler` moves that logic to one place, and standardizes the _framework-level_ exceptions (bad request bodies, unsupported media types, method-not-allowed, etc.) for you automatically.

## How you use it

You extend it in a `@RestControllerAdvice` class:

```java
@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(AccountNotFoundException.class)
    public ProblemDetail handleAccountNotFound(AccountNotFoundException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    }
}
```

Here, `handleAccountNotFound` is a handler _you_ wrote for _your own_ custom exception — that part works the same whether or not you extend `ResponseEntityExceptionHandler`. What extending it gives you is a set of **already-written handler methods for Spring's own built-in exceptions** — `MethodArgumentNotValidException` (failed `@Valid` checks), `HttpMessageNotReadableException` (malformed JSON), `HttpRequestMethodNotSupportedException` (wrong HTTP verb), `MissingServletRequestParameterException`, and many more. You get all of these for free, each already producing a `ProblemDetail` with sensible defaults, without writing a single `@ExceptionHandler` for them yourself.

## Overriding the defaults

If you don't like the default behavior for one of these built-in cases, you override the matching protected method. For example, to customize what happens on a failed validation:

```java
@Override
protected ResponseEntity<Object> handleMethodArgumentNotValid(
        MethodArgumentNotValidException ex,
        HttpHeaders headers,
        HttpStatusCode status,
        WebRequest request) {

    ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST, "Validation failed.");

    List<String> errors = ex.getBindingResult().getFieldErrors().stream()
            .map(error -> error.getField() + ": " + error.getDefaultMessage())
            .toList();

    problem.setProperty("errors", errors);

    return ResponseEntity.status(status).body(problem);
}
```

Each overridable method follows the same signature pattern: the specific exception type, `HttpHeaders`, the `HttpStatusCode` that Spring already determined, and the `WebRequest`. You're not deciding the status code from scratch — Spring hands you the one it would've used by default, and you decide whether to keep it or change it, and how to shape the body.

## How it fits together with your own exceptions

A typical `ApiExceptionHandler` ends up with two kinds of methods side by side:

```java
@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    // Your own domain exception — plain @ExceptionHandler, no override needed
    @ExceptionHandler(AccountNotFoundException.class)
    public ProblemDetail handleAccountNotFound(AccountNotFoundException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    // A built-in Spring exception — override to customize the existing default
    @Override
    protected ResponseEntity<Object> handleHttpMessageNotReadable(
            HttpMessageNotReadableException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST, "Malformed JSON request.");
        return ResponseEntity.status(status).body(problem);
    }
}
```

So the base class doesn't replace your `@ExceptionHandler` methods — it sits alongside them, covering the _framework's_ exceptions so you only have to write handlers for _your own_.



[[Spring Framework]]