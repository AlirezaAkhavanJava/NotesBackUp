

### 1️⃣ `HttpStatus`

- **Package:** `org.springframework.http`
    
- **What it is:**  
    Enum that represents **HTTP status codes** like `200 OK`, `404 NOT_FOUND`, `500 INTERNAL_SERVER_ERROR`.
    
- **Usage Example:**
    
    ```java
    return new ResponseEntity<>("User not found", HttpStatus.NOT_FOUND);
    ```
    
- **Common Values:**
    
    |Constant|Meaning|
    |---|---|
    |`HttpStatus.OK`|200 – Request succeeded|
    |`HttpStatus.CREATED`|201 – Resource created|
    |`HttpStatus.BAD_REQUEST`|400 – Invalid input|
    |`HttpStatus.UNAUTHORIZED`|401 – Not logged in|
    |`HttpStatus.NOT_FOUND`|404 – Resource missing|
    |`HttpStatus.INTERNAL_SERVER_ERROR`|500 – Server-side error|
    

---

### 2️⃣ `ResponseEntity<T>`

- **Package:** `org.springframework.http`
    
- **What it is:**  
    A full **HTTP response object** that includes:
    
    - body (the data you return)
        
    - status code
        
    - headers (optional)
        
- **Why it’s useful:**  
    Gives **fine-grained control** over your HTTP responses.
    
- **Example:**
    
    ```java
    @GetMapping("/user/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        User user = service.findById(id);
        if (user == null)
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        return new ResponseEntity<>(user, HttpStatus.OK);
    }
    ```
    

---

### 3️⃣ `ControllerAdvice`

- **Package:** `org.springframework.web.bind.annotation`
    
- **What it is:**  
    A **global error handler** for all controllers.  
    You can catch exceptions thrown by any `@RestController`.
    
- **Think of it as:**  
    A “manager” that listens for all exceptions and handles them in one place.
    
- **Example:**
    
    ```java
    @ControllerAdvice
    public class GlobalExceptionHandler {
        @ExceptionHandler(Exception.class)
        public ResponseEntity<String> handleAll(Exception ex) {
            return new ResponseEntity<>("Something went wrong!", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    ```
    

---

### 4️⃣ `ExceptionHandler`

- **Package:** `org.springframework.web.bind.annotation`
    
- **What it is:**  
    Used **inside** `@ControllerAdvice` or a controller to mark a method that handles a specific exception type.
    
- **Example:**
    
    ```java
    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<String> handleUserNotFound(UserNotFoundException ex) {
        return new ResponseEntity<>(ex.getMessage(), HttpStatus.NOT_FOUND);
    }
    ```
    

---

### 5️⃣ `ResponseStatus`

- **Package:** `org.springframework.web.bind.annotation`
    
- **What it is:**  
    An annotation to mark a custom exception with a specific HTTP status.
    
- **Example:**
    
    ```java
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public class UserNotFoundException extends RuntimeException {
        public UserNotFoundException(String message) {
            super(message);
        }
    }
    ```
    
    👉 When this exception is thrown, Spring automatically sends a **404** response.
    

---

### 6️⃣ `WebRequest`

- **Package:** `org.springframework.web.context.request`
    
- **What it is:**  
    Represents the **current HTTP request** inside the Spring context.  
    Lets you access details like request attributes and parameters.
    
- **Example:**
    
    ```java
    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleAll(Exception ex, WebRequest request) {
        String path = request.getDescription(false);
        return new ResponseEntity<>("Error at: " + path, HttpStatus.INTERNAL_SERVER_ERROR);
    }
    ```
    

---

### 7️⃣ `ResponseEntityExceptionHandler`

- **Package:** `org.springframework.web.servlet.mvc.method.annotation`
    
- **What it is:**  
    A **base class** for centralized exception handling.  
    You can extend it to customize how Spring handles exceptions globally.
    
- **Example:**
    
    ```java
    @ControllerAdvice
    public class CustomExceptionHandler extends ResponseEntityExceptionHandler {
        @Override
        protected ResponseEntity<Object> handleExceptionInternal(
            Exception ex, Object body, HttpHeaders headers,
            HttpStatus status, WebRequest request) {
            return new ResponseEntity<>(new ErrorMessage("Internal error"), status);
        }
    }
    ```
    

---

### 8️⃣ `ErrorMessage` (Your Custom Class)

- **Likely Purpose:**  
    To structure error responses in a consistent format.
    
- **Example:**
    
    ```java
    @Data
    @AllArgsConstructor
    public class ErrorMessage {
        private String message;
        private String details;
    }
    ```
    
- **Returned Example:**
    
    ```json
    {
      "message": "User not found",
      "details": "/api/users/12"
    }
    ```
    

---


[[1 - HTTP]]