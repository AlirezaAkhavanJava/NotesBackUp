
**`MethodArgumentNotValidException`** (Spring / Spring Boot)

**What it is**  
Thrown when **request validation fails** for an object annotated with `@Valid` or `@Validated` (usually in a controller).

**When it happens**

- You send invalid JSON/body
    
- Bean Validation annotations fail (`@NotNull`, `@Size`, `@Email`, etc.)
    
- Common with `@RequestBody`
    

**Typical example**

```java
@PostMapping("/users")
public ResponseEntity<?> create(@Valid @RequestBody UserDto dto) {
    return ResponseEntity.ok(dto);
}
```

```java
public class UserDto {
    @NotBlank
    private String name;

    @Email
    private String email;
}
```

If `name` is empty or `email` is invalid → **MethodArgumentNotValidException**

**How to handle it (BEST PRACTICE)**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(
            MethodArgumentNotValidException ex) {

        Map<String, String> errors = new HashMap<>();

        ex.getBindingResult()
          .getFieldErrors()
          .forEach(err ->
              errors.put(err.getField(), err.getDefaultMessage())
          );

        return ResponseEntity.badRequest().body(errors);
    }
}
```

**Key points (truth, no fluff)**

- Happens **before** controller logic runs
    
- Related to **Bean Validation**, not business logic
    
- Only for **object binding** (not query params → that’s `ConstraintViolationException`)
    
- If you don’t handle it → Spring returns ugly default error
    

---

### **1️⃣ Where to handle it (layer)**

- **Controller Layer:** This exception is thrown **before your controller method executes** if `@Valid` fails.
    
- **Global Layer (Recommended):** Use a **`@ControllerAdvice`** or **`@RestControllerAdvice`** to handle it **globally**, so you don’t repeat try/catch in every controller.
    

> ✅ Layer takeaway: Handle it in the **exception handling layer**, not service or repository.

---

### **2️⃣ How to handle it**

#### **Step 1 – Create a global exception handler**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationErrors(
            MethodArgumentNotValidException ex) {

        Map<String, String> errors = new HashMap<>();

        ex.getBindingResult()
          .getFieldErrors()
          .forEach(error -> 
              errors.put(error.getField(), error.getDefaultMessage())
          );

        return ResponseEntity.badRequest().body(errors);
    }
}
```

- **`@RestControllerAdvice`** → handles exceptions across all controllers
    
- **`@ExceptionHandler(MethodArgumentNotValidException.class)`** → catches validation errors
    
- **`ex.getBindingResult().getFieldErrors()`** → gives all failed fields and messages
    

---

#### **Step 2 – Annotate your DTO**

```java
public class UserDto {

    @NotBlank(message = "Name cannot be empty")
    private String name;

    @Email(message = "Invalid email format")
    private String email;
}
```

#### **Step 3 – Use `@Valid` in the controller**

```java
@PostMapping("/users")
public ResponseEntity<UserDto> createUser(@Valid @RequestBody UserDto userDto) {
    return ResponseEntity.ok(userDto);
}
```

---

### **3️⃣ Optional: Custom API Response**

You can create a **custom error object**:

```java
public class ApiError {
    private String field;
    private String message;
}
```

Then return a **list of `ApiError`** instead of a map. Makes your API cleaner.

---

### **Summary**

- **Layer:** Exception handling layer (`@ControllerAdvice`)
    
- **How:** Use `@ExceptionHandler(MethodArgumentNotValidException.class)`
    
- **Why:** Keeps validation errors separate from business logic and ensures consistent API responses
    

---




###### Tags : [[0 - Spring Framework]]