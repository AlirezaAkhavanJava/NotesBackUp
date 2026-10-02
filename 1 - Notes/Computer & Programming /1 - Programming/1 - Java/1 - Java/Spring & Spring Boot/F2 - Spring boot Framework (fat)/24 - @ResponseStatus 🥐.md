
`@ResponseStatus` in Spring is used to tell the framework **which HTTP status code** to return when a certain exception (or method) is triggered.

It’s a simple way to map exceptions → HTTP status without needing a full handler.

---

### 🧱 Example 1 — On an Exception Class

You can attach it directly to a custom exception:

```java
@ResponseStatus(HttpStatus.NOT_FOUND)
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}
```

Now, if you throw this exception anywhere:

```java
throw new ResourceNotFoundException("User not found");
```

Spring automatically returns:

```
HTTP 404 Not Found
Body: "User not found"
```

---

### 🧱 Example 2 — On a Controller Method

You can also use it to set the response status for a successful endpoint:

```java
@PostMapping("/users")
@ResponseStatus(HttpStatus.CREATED)
public void createUser(@RequestBody UserDto user) {
    // create logic
}
```

This returns `201 Created` even though you didn’t manually build a `ResponseEntity`.

---

### ⚖️ When to Use

✅ Use `@ResponseStatus`

- For **simple, fixed** responses (e.g. 404, 201, 400)
    
- When your exception doesn’t need custom JSON response body
    

❌ Don’t use it

- When you need **dynamic error messages**, timestamps, or custom body → use `@ControllerAdvice` / `@RestControllerAdvice` instead.
    

---

`@ExceptionHandler` in Spring tells a controller (or a `@ControllerAdvice`) **which method should handle a specific exception** when it’s thrown.

It’s the backbone of Spring’s exception handling system.

---

### 🧱 Example — Inside One Controller

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping("/{id}")
    public String getUser(@PathVariable int id) {
        if (id == 0)
            throw new ResourceNotFoundException("User not found");
        return "User #" + id;
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<String> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }
}
```

If `/users/0` is called → Spring catches `ResourceNotFoundException` and returns:

```
HTTP 404
Body: "User not found"
```

---

### 🧰 Example — Global Exception Handling

You can centralize it using `@ControllerAdvice` or `@RestControllerAdvice`:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Object> handleNotFound(ResourceNotFoundException ex) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", "Not Found");
        body.put("message", ex.getMessage());
        body.put("timestamp", LocalDateTime.now());

        return new ResponseEntity<>(body, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Object> handleAll(Exception ex) {
        return new ResponseEntity<>(Map.of(
                "error", "Internal Error",
                "message", ex.getMessage()
        ), HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
```

---

### ⚖️ Summary

|Concept|Purpose|
|---|---|
|`@ExceptionHandler`|Handles specific exception types|
|`@ResponseStatus`|Sets fixed HTTP status for exceptions|
|`@ControllerAdvice` / `@RestControllerAdvice`|Makes those handlers apply **globally**|



##### Tags : [[0 - Spring Framework]]