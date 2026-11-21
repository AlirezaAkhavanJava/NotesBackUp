

`MethodArgumentNotValidException` is an exception Spring MVC throws automatically when an argument annotated with `@Valid` (or `@Validated`) fails Bean Validation. You never throw it yourself — Spring validates the argument _before_ your controller method body runs, and if any constraint fails, it throws this exception instead of calling your method at all. That's an important distinction from a normal business-logic exception: your code never executes, so there's no partial work to clean up, and the failure is purely about the shape of the incoming data, not anything your application decided.

## When it fires

It only fires for **object binding** — meaning a whole request body (or form object) mapped onto a Java object whose fields carry Bean Validation annotations like `@NotBlank`, `@Size`, or `@Email`:

```java
public class UserDto {
    @NotBlank(message = "Name cannot be empty")
    private String name;

    @Email(message = "Invalid email format")
    private String email;
}
```

```java
@PostMapping("/users")
public ResponseEntity<UserDto> createUser(@Valid @RequestBody UserDto userDto) {
    return ResponseEntity.ok(userDto);
}
```

If a client posts `{"name": "", "email": "not-an-email"}`, Spring validates `userDto` against the annotations on `UserDto` before `createUser`'s body runs, finds two failures, and throws `MethodArgumentNotValidException` instead of entering the method.

This is why it's specific to `@RequestBody`/`@ModelAttribute`-style objects, and _not_ to individual `@RequestParam` or `@PathVariable` values — validating those triggers a different exception, `ConstraintViolationException`, because there's no bound object involved, just a loose value.

## Reading what failed

The exception carries a `BindingResult`, which holds one `FieldError` per failed constraint — the field name, the message, and the rejected value:

```java
ex.getBindingResult()
  .getFieldErrors()
  .forEach(error -> errors.put(error.getField(), error.getDefaultMessage()));
```

`getDefaultMessage()` returns whatever string you put in the annotation's `message` attribute (or a generic default if you didn't set one) — so `@NotBlank(message = "Name cannot be empty")` surfaces exactly that text here.

## Handling it

Since the exception is thrown before your controller logic runs, it belongs with the rest of your framework-level error handling — a `@RestControllerAdvice`, not inside the controller, service, or repository:

```java
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult()
          .getFieldErrors()
          .forEach(error -> errors.put(error.getField(), error.getDefaultMessage()));
        return ResponseEntity.badRequest().body(errors);
    }
}
```

If you don't handle it at all, Spring Boot's default handling still kicks in (via `ResponseEntityExceptionHandler`'s built-in support) and returns a generic `400 Bad Request` with a default error body — functional, but not tailored to your API's shape.

## A more structured alternative to a plain map

Returning a bare `Map<String, String>` works, but it only lets one message survive per field (a second failing constraint on the same field overwrites the first). A small record per error avoids that and reads more clearly on the client side:

```java
public record FieldErrorDetail(String field, String message) {}
```

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ResponseEntity<List<FieldErrorDetail>> handleValidation(MethodArgumentNotValidException ex) {
    List<FieldErrorDetail> errors = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .map(error -> new FieldErrorDetail(error.getField(), error.getDefaultMessage()))
            .toList();
    return ResponseEntity.badRequest().body(errors);
}
```

Each entry is now its own object instead of competing for a single map key, so a `name` field with two separate validation failures shows up as two separate entries instead of one overwriting the other.

[[Exception]]
[[Spring Framework]]