

`@ResponseStatus` lets you attach a fixed HTTP status code to something — an exception class or a controller method — without writing any response-building code. Spring checks for the annotation at the right moment and sets the response's status accordingly. It's the simplest of the status-setting mechanisms in Spring MVC: no `ResponseEntity`, no `ProblemDetail`, just a status code tied directly to the thing that produced it.

## On an exception class

You can annotate a custom exception itself:

```java
@ResponseStatus(HttpStatus.NOT_FOUND)
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}
```

Now, anywhere this exception is thrown and left unhandled by any `@ExceptionHandler`, Spring reads the annotation and sets the response status to `404`, with the exception's message becoming the body:

```java
throw new ResourceNotFoundException("User not found");
```

```
HTTP 404 Not Found
Body: "User not found"
```

This only applies when there's no matching `@ExceptionHandler` to intercept the exception first — if you've written one (as you have for your own exceptions), that handler's return value wins, and the `@ResponseStatus` on the exception class becomes irrelevant for that exception. In practice this means: pick one approach per exception type, not both. If an exception already has a dedicated `@ExceptionHandler`, there's no reason to also annotate the exception class — it won't do anything.

## On a controller method

The other use is marking the success status of a method directly:

```java
@PostMapping("/users")
@ResponseStatus(HttpStatus.CREATED)
public UserDto createUser(@RequestBody UserDto user) {
    return service.create(user);
}
```

This returns `201 Created` instead of Spring's default `200 OK` for a method that returns a body directly (not wrapped in `ResponseEntity`). It's useful specifically because a `POST` that creates a resource is conventionally expected to return `201`, not `200`, and writing `@ResponseStatus(HttpStatus.CREATED)` is shorter than building a `ResponseEntity.status(HttpStatus.CREATED).body(...)` just to get the same result.

## Parameters worth knowing

The annotation has three attributes, though only two see real use:

- **`value`** (or its alias `code`) — the `HttpStatus` to apply. This is the one you'll use essentially every time; the two names are interchangeable, `value` is just the implicit default so you can omit the name (`@ResponseStatus(HttpStatus.NOT_FOUND)` instead of `@ResponseStatus(value = HttpStatus.NOT_FOUND)`).
- **`reason`** — an optional text reason, e.g. `@ResponseStatus(value = HttpStatus.NOT_FOUND, reason = "User not found")`. When set on an exception class, Spring uses it to populate the response and, notably, routes the response through the servlet container's error page mechanism (`HttpServletResponse.sendError`), which means the body ends up being the container's generic error page rather than a clean, structured body. Because of that side effect, teams working with JSON APIs generally avoid `reason` and let the exception's own message (or a dedicated `@ExceptionHandler`) supply the explanatory text instead.

## When to reach for it vs. an `@ExceptionHandler`

Since you already handle exceptions centrally through your `ApiExceptionHandler`, `@ResponseStatus` on an exception class would mostly be redundant — your handler methods already decide the status explicitly via `ProblemDetail.forStatusAndDetail(...)`. Where `@ResponseStatus` genuinely earns its place in a project like yours is the controller-method form, for setting a non-default success status (`201` on create, `204` on delete) where there's no exception involved at all, and no need for a dynamic body shape.




[[Spring Framework]]
[[Exception]]