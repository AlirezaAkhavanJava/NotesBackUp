
`@ControllerAdvice` in Spring is a **global interceptor for controllers** — it lets you handle exceptions, bind values, or modify responses **across all controllers**, not just one.

Here’s the breakdown 👇

### 🧠 What it does

`@ControllerAdvice` is like a “global controller helper.” It can:

- Handle exceptions globally (`@ExceptionHandler`)
    
- Add model attributes to all controllers (`@ModelAttribute`)
    
- Apply global data binding (`@InitBinder`)
    

---

### ⚙️ Typical Use Case — Global Exception Handling

```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<String> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleAll(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                             .body("Something went wrong: " + ex.getMessage());
    }
}
```

---

### 🆚 `@RestControllerAdvice` vs `@ControllerAdvice`

|Annotation|Used for|Response Type|
|---|---|---|
|`@ControllerAdvice`|Normal MVC controllers|Returns **views** (HTML, JSP)|
|`@RestControllerAdvice`|REST controllers|Returns **JSON/XML** responses (auto adds `@ResponseBody`)|

So basically:  
👉 `@ControllerAdvice` = for web pages  
👉 `@RestControllerAdvice` = for REST APIs

---
here’s how to handle **validation errors** (like `@Valid` or `@NotBlank`) using `@ControllerAdvice`.



### 🧱 Example

Let’s say you have this controller and DTO:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @PostMapping
    public ResponseEntity<String> createUser(@Valid @RequestBody UserDto userDto) {
        return ResponseEntity.ok("User created: " + userDto.getName());
    }
}

public class UserDto {
    @NotBlank(message = "Name is required")
    private String name;

    @Email(message = "Invalid email format")
    private String email;

    // getters and setters
}
```

Now, if someone sends invalid data, Spring throws `MethodArgumentNotValidException`.  
You catch it in your `@ControllerAdvice` class 👇

---

### 🧰 Global Exception Handler

```java
@ControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", LocalDateTime.now());
        body.put("status", status.value());

        List<String> errors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .toList();

        body.put("errors", errors);

        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }
}
```

---

### 🧩 Result

If you send this JSON:

```json
{
  "name": "",
  "email": "notanemail"
}
```

You’ll get:

```json
{
  "timestamp": "2025-11-09T15:33:00",
  "status": 400,
  "errors": [
    "name: Name is required",
    "email: Invalid email format"
  ]
}
```



##### Tags : [[0 - Spring Framework]]