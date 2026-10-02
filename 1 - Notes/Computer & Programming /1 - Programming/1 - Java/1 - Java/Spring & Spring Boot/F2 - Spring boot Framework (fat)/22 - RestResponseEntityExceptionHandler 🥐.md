

`RestResponseEntityExceptionHandler` is a **Spring Boot class** (usually a custom one) used to handle **exceptions globally** for REST APIs.

Here’s the core idea 👇

### 💡 What it does

It catches exceptions thrown in your controllers and returns a proper HTTP response — usually with a JSON body describing the error.

### 🧱 Example

```java
@RestControllerAdvice
public class RestResponseEntityExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Object> handleResourceNotFound(ResourceNotFoundException ex) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", "Not Found");
        body.put("message", ex.getMessage());
        body.put("timestamp", LocalDateTime.now());

        return new ResponseEntity<>(body, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Object> handleAll(Exception ex) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", "Internal Server Error");
        body.put("message", ex.getMessage());
        body.put("timestamp", LocalDateTime.now());

        return new ResponseEntity<>(body, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
```

### ⚙️ Key annotations

- `@RestControllerAdvice` — tells Spring this class provides global exception handling for REST controllers.
    
- `@ExceptionHandler(ExceptionType.class)` — defines which exception each method handles.
    
- Extending `ResponseEntityExceptionHandler` gives you **default handling** for things like validation errors (`MethodArgumentNotValidException`).
    
---

**Definition:**  
`@ControllerAdvice` is a **Spring annotation** used to define a **global component that can handle exceptions, bind data, or apply model attributes across multiple controllers**. It allows you to centralize common logic instead of repeating it in every controller.

**Key Points:**

1. **Global Exception Handling:** You can handle exceptions for all controllers using `@ExceptionHandler` methods inside a `@ControllerAdvice` class.
    
2. **Global Data Binding:** You can define `@InitBinder` methods to customize request parameter binding for multiple controllers.
    
3. **Global Model Attributes:** You can define `@ModelAttribute` methods to add attributes to the model for all controllers.
    

**Example:**

```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgument(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(ex.getMessage());
    }

    @ModelAttribute
    public void addAttributes(Model model) {
        model.addAttribute("appName", "My Awesome App");
    }
}
```

✅ **Effect:** All controllers automatically use this advice for exception handling and model attributes.




##### Tags : [[0 - Spring Framework]]