

`@ExceptionHandler` is a method-level annotation in Spring MVC. You put it on a method and tell it which exception type to watch for; when a controller method throws (or lets propagate) an exception matching that type, Spring routes the call to this method instead of letting the exception crash the request. The method you write becomes the thing that decides what the client actually sees — the status code, the body, the headers — for that exception.

It works in two places: directly inside a `@RestController` (handles exceptions thrown only by methods in that same controller), or inside a `@RestControllerAdvice` class (handles exceptions thrown by _any_ controller in the app, since advice classes apply globally). The annotation itself behaves identically either way — only its reach changes.

## Syntax

```java
@ExceptionHandler(ExceptionType.class)
public ReturnType handleSomething(ExceptionType ex) {
    // build and return the response
}
```

- The annotation's argument is the exception class to catch.
- The method parameter is the caught exception instance — you read its message or fields from here.
- The return type is whatever you want the response body to be: `ResponseEntity<T>`, `ProblemDetail`, a plain `String`, a `Map`, etc. Spring serializes it the same way it would a normal controller return value.

## Matching one exception

```java
@ExceptionHandler(ResourceNotFoundException.class)
public ResponseEntity<String> handleNotFound(ResourceNotFoundException ex) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
}
```

When `ResourceNotFoundException` is thrown anywhere Spring is looking (the enclosing controller, or every controller if this is in an advice class), this method runs instead of the default error page.

## Multiple handlers in one class

A single controller or advice class can declare several `@ExceptionHandler` methods, each for a different exception type:

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
    Map<String, String> errors = new HashMap<>();
    ex.getBindingResult().getFieldErrors()
            .forEach(err -> errors.put(err.getField(), err.getDefaultMessage()));
    return ResponseEntity.badRequest().body(errors);
}

@ExceptionHandler(ResourceNotFoundException.class)
public ResponseEntity<String> handleNotFound(ResourceNotFoundException ex) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
}

@ExceptionHandler(Exception.class)
public ResponseEntity<String> handleGeneric(Exception ex) {
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Something went wrong");
}
```

Spring picks whichever `@ExceptionHandler` method's exception type most specifically matches the thrown exception. If `ResourceNotFoundException` is thrown, the `ResourceNotFoundException` handler wins over the generic `Exception` one, even though `Exception` technically also matches (it's a superclass of everything) — Spring always prefers the closest match in the exception's class hierarchy.

## One method, multiple exception types

If several unrelated exceptions should be handled the same way, list them together instead of writing duplicate methods:

```java
@ExceptionHandler({ IllegalArgumentException.class, IllegalStateException.class })
public ResponseEntity<String> handleBadInput(Exception ex) {
    return ResponseEntity.badRequest().body(ex.getMessage());
}
```

## Resolution order when both local and global handlers exist

If a controller has its own `@ExceptionHandler` for a given exception type, and a `@RestControllerAdvice` elsewhere also handles that same type, the controller's own method wins — Spring checks the exception's own controller first before falling back to the global advice. This lets you override global behavior for one specific controller without touching the shared advice class.



[[Exception]]
[[Spring Framework]]