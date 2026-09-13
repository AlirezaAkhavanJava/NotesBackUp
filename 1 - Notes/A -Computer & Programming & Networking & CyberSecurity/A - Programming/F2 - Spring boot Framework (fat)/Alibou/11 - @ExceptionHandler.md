

### **1️⃣ What it is**

- `@ExceptionHandler` is a **Spring annotation** used to define **methods that handle exceptions** thrown in controllers.
    
- When an exception occurs, Spring looks for a method annotated with `@ExceptionHandler` that matches the exception type.
    
- Can be applied **inside a controller** or **inside a global `@ControllerAdvice`**.
    

---

### **2️⃣ Syntax**

```java
@ExceptionHandler(ExceptionType.class)
public ResponseEntity<ReturnType> handleException(ExceptionType ex) {
    // handle exception
}
```

- **`ExceptionType.class`** → the type of exception to catch
    
- **`ex`** → the exception object
    
- **Return type** → usually `ResponseEntity<...>` for REST APIs
    

---

### **3️⃣ Example 1 – Local controller handling**

```java
@RestController
@RequestMapping("/users")
public class UserController {

    @PostMapping
    public ResponseEntity<UserDto> createUser(@Valid @RequestBody UserDto userDto) {
        // could throw MethodArgumentNotValidException if validation fails
        return ResponseEntity.ok(userDto);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationErrors(
            MethodArgumentNotValidException ex) {

        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors()
          .forEach(err -> errors.put(err.getField(), err.getDefaultMessage()));

        return ResponseEntity.badRequest().body(errors);
    }
}
```

> ✅ Works only for exceptions **inside this controller**.

---

### **4️⃣ Example 2 – Global handling (`@ControllerAdvice`)**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationErrors(
            MethodArgumentNotValidException ex) {

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
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                             .body("Something went wrong");
    }
}
```

- **Catches exceptions across all controllers**
    
- **Multiple `@ExceptionHandler`** methods can coexist in one class
    
- Handles both **specific exceptions** (`MethodArgumentNotValidException`) and **generic** ones (`Exception`)
    

---

### **5️⃣ Key Points**

- The **closest matching handler** is picked first (controller > controller advice)
    
- Can return **JSON, HTML, or any ResponseEntity**
    
- Works **only for exceptions thrown in Spring-managed controllers**
    




###### Tags : [[0 - Spring Framework]]