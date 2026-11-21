

```java
@RestControllerAdvice
public class StudentControllerExceptions extends RuntimeException {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<?> handleMethodArgumentNotValidException(
            MethodArgumentNotValidException exp
    ) {
        var error = new HashMap<String /*Filed*/, String /*message*/>();
        exp.getBindingResult()
                .getAllErrors()
                .forEach(errors -> {
                    var fieldName = ((FieldError) errors).getField();
                    var errorMessage = errors.getDefaultMessage();
                    error.put(fieldName, errorMessage);
                });
        return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
    }
}

```

## What this code is

This class is a **global exception handler for validation failures**. When a client sends a request body that breaks your validation rules (a blank name, a negative age, and so on), Spring throws an exception. Your class catches it and replies with a `400 Bad Request` and a small JSON object saying which field failed and why.

## The mental model

Picture a controller method like this:

```java
@PostMapping("/students")
public Student create(@Valid @RequestBody StudentRequest request) { ... }
```

Before your method body runs, Spring checks `request` against its annotations (`@NotBlank`, `@Min`, ...). If anything fails, Spring never calls your method. It throws `MethodArgumentNotValidException` instead, and the exception travels up to the `DispatcherServlet`, which looks for a matching `@ExceptionHandler`. Your method is that match.

The `try/catch` analogy only goes so far here. You never wrote a `try` block, and the exception is thrown by Spring's argument-resolving machinery, not by your own code.

## The mechanics, line by line

```java
@RestControllerAdvice
```

This registers the class as advice that applies to all controllers, and makes every return value a response body (JSON), not a view name.

```java
public class StudentControllerExceptions extends RuntimeException {
```

This part is a mistake, and I'd fix it. `extends RuntimeException` makes the class itself an exception type, but this class is a **handler**, not something you throw. It works, since Spring ignores the superclass, but it's misleading, and it carries useless stack-trace fields into a Spring bean. Remove it. A handler class and an exception class are two different jobs.

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
```

This tells Spring: "when this exception type escapes a controller, call this method." If a more specific handler existed, Spring would prefer it; if none matches, Spring falls back to its default behavior.

```java
public ResponseEntity<?> handleMethodArgumentNotValidException(
        MethodArgumentNotValidException exp)
```

Spring inspects the parameter type and injects the thrown exception. `ResponseEntity<?>` lets you control the status code and body together. The `?` works but hides the real type, and a `Map<String, String>` would be more honest.

```java
var error = new HashMap<String /*Filed*/, String /*message*/>();
```

This is a map from field name to message, for example `"name" -> "must not be blank"`. (Small typo in your comment: "Filed" should be "Field".)

```java
exp.getBindingResult()
   .getAllErrors()
   .forEach(errors -> {
```

`getBindingResult()` holds everything the validator found. `getAllErrors()` returns a list of `ObjectError`. The lambda variable is named `errors` but it's a single error, so `error` would read better (which is why the map name collides in your head).

```java
var fieldName = ((FieldError) errors).getField();
var errorMessage = errors.getDefaultMessage();
error.put(fieldName, errorMessage);
```

`FieldError` is the subclass of `ObjectError` that knows which field failed. Casting is needed because `getAllErrors()` is typed as the parent. Then each field and message goes into the map.

```java
return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
```

This returns the map as JSON with status 400.

## What the client actually sees

Request:

```json
{ "name": "", "age": -3 }
```

Response (`400`):

```json
{
  "name": "must not be blank",
  "age": "must be greater than or equal to 0"
}
```

## Edge cases hiding in this version

**1. The cast can blow up.** Not every validation error belongs to a field. A class-level constraint (say, a custom `@PasswordsMatch` on the whole object) produces a plain `ObjectError`, and `(FieldError) errors` throws `ClassCastException`, turning your 400 into a 500. Using `getFieldErrors()` avoids the cast entirely, because it returns only `FieldError` objects already.

**2. Two errors on one field overwrite each other.** If `name` is both `@NotBlank` and `@Size(min = 2)`, an empty string breaks both rules, and `put` keeps only the last message. Whether that's fine depends on your API. The fix is to collect a `List<String>` per field, or keep the first message.

**3. `HashMap` has no ordering.** The fields may come back in a different order each time. `LinkedHashMap` keeps them in the order Spring reported them.

**4. It only covers `@Valid @RequestBody`.** Validation failures on `@PathVariable` or `@RequestParam` throw a different exception (`ConstraintViolationException`, or `HandlerMethodValidationException` in newer Spring versions), which this handler never sees.

## A cleaned-up version

```java
@RestControllerAdvice
public class ValidationExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(
            MethodArgumentNotValidException ex) {

        Map<String, String> errors = new LinkedHashMap<>();
        ex.getBindingResult()
          .getFieldErrors()
          .forEach(fe -> errors.putIfAbsent(fe.getField(), fe.getDefaultMessage()));

        return ResponseEntity.badRequest().body(errors);
    }
}
```

What changed and why:

- No `extends RuntimeException`, because the class is a handler, not an exception.
- `getFieldErrors()` removes the cast and the `ClassCastException` risk.
- `putIfAbsent` keeps the first message per field instead of silently keeping the last.
- `LinkedHashMap` gives a stable order.
- The return type is `ResponseEntity<Map<String, String>>`, which says what you actually return.
- `ResponseEntity.badRequest().body(...)` is the same as `new ResponseEntity<>(..., BAD_REQUEST)` but reads better.
- The name `ValidationExceptionHandler` describes the job; `StudentControllerExceptions` suggests a student-only scope, which `@RestControllerAdvice` without arguments doesn't have.

If you really do want it limited to the student controller, scope it explicitly: `@RestControllerAdvice(assignableTypes = StudentController.class)`.




[[Exception]]
[[Spring Framework]]