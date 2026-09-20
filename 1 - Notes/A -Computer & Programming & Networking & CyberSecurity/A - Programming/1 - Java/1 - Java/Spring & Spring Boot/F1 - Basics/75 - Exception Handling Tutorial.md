


## Step 1: Understanding Exceptions and Default Handling

### What Are Exceptions?

Exceptions are events that disrupt your program's flow, such as invalid user input or database errors. In Spring Boot, unhandled exceptions can crash your app or confuse users if not managed properly.

### Default Exception Handling in Spring Boot

- **What it does**: Spring Boot's `BasicErrorController` automatically handles uncaught exceptions, returning a JSON response for REST APIs or an error page for web apps. It includes fields like `status`, `error`, `message`, `timestamp`, and `path`.
- **Why use it**: Requires no setup, ideal for quick prototypes, prevents app crashes.
- **Functionality**: Driven by `ErrorAttributes`, customizable via `application.properties` (e.g., `server.error.include-stacktrace=never`).
- **Pro way**: Use as a fallback, but override for production to control responses and hide sensitive data like stack traces.

**Example 1: Observing Default Handling**  
Let's create a controller that throws an exception to see Spring Boot's default behavior.

```java
package com.example.demo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    @GetMapping("/error")
    public String triggerError() {
        throw new RuntimeException("Something went wrong!");
    }
}
```

- **Run it**: Call `http://localhost:8080/error` using Postman or a browser.
- **Result**: You get a JSON response:
    
    ```json
    {
      "timestamp": "2025-10-22T14:15:00.000+04:00",
      "status": 500,
      "error": "Internal Server Error",
      "message": "Something went wrong!",
      "path": "/error"
    }
    ```
    
- **Takeaway**: The default handler is generic. For a user management API, we want specific messages and status codes (e.g., 400 for bad input, 404 for not found).

## Step 2: Local Exception Handling with `@ExceptionHandler`

### Introducing `@ExceptionHandler`

- **What it does**: The `@ExceptionHandler` annotation (from `org.springframework.web.bind.annotation`) marks a method in a `@Controller` or `@RestController` to handle specific exceptions thrown by that controller's methods.
- **Why use it**: Allows targeted error handling for specific endpoints (e.g., invalid user ID in a `/user/{id}` endpoint). Suitable for small apps or controller-specific errors.
- **Functionality**: The method can take the exception object, `HttpServletRequest`, or `WebRequest` as parameters and return any type (e.g., `String`, `ResponseEntity`). Supports multiple exceptions with `@ExceptionHandler({Ex1.class, Ex2.class})`.
- **Pro way**: Use with `ResponseEntity` for HTTP status control. Log exceptions for debugging. Move to global handling for reuse across controllers.

**Example 2: Local Exception Handling**  
Let's handle invalid user IDs in our `UserController`.

```java
package com.example.demo.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    @GetMapping("/user/{id}")
    public String getUser(@PathVariable Long id) {
        if (id == null || id <= 0) {
            throw new IllegalArgumentException("Invalid user ID: must be positive");
        }
        return "User with ID " + id;
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgumentException(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ex.getMessage());
    }
}
```

- **Run it**: Call `http://localhost:8080/user/-1`.
- **Result**:
    
    ```json
    {
      "status": 400,
      "error": "Bad Request",
      "message": "Invalid user ID: must be positive"
    }
    ```
    
- **Takeaway**: The handler catches the exception locally, but it's limited to `UserController`. If another controller needs the same logic, we'd duplicate code.

## Step 3: Introducing `ResponseEntity` for Flexible Responses

### What is `ResponseEntity`?

- **What it does**: `ResponseEntity` (from `org.springframework.http`) represents a complete HTTP response, including status code, headers, and body.
- **Why use it**: In REST APIs, you need control over HTTP status (e.g., `404 Not Found`) and headers (e.g., `Content-Type`). It’s more powerful than returning plain objects.
- **Functionality**:
    - Constructors: `ResponseEntity(body, status)`, `ResponseEntity(body, headers, status)`.
    - Static methods: `ResponseEntity.ok(body)`, `ResponseEntity.notFound().build()`, `ResponseEntity.status(HttpStatus).body(body)`.
    - Builder pattern: Chain `.headers()`, `.body()`.
    - Methods: `getBody()`, `getStatusCode()`, `getHeaders()`.
- **Pro way**: Use static builders for readability (e.g., `ResponseEntity.ok()`). Set appropriate `HttpStatus` (from `org.springframework.http.HttpStatus`). Add headers for metadata (e.g., caching, CORS). In exception handlers, use it for consistent error responses.

**Example 3: Enhancing with `ResponseEntity`**  
Modify the controller to use `ResponseEntity` for both success and error cases.

```java
package com.example.demo.controller;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    @GetMapping("/user/{id}")
    public ResponseEntity<String> getUser(@PathVariable Long id) {
        if (id == null || id <= 0) {
            throw new IllegalArgumentException("Invalid user ID: must be positive");
        }
        HttpHeaders headers = new HttpHeaders();
        headers.add("X-User-ID", id.toString());
        return ResponseEntity.ok().headers(headers).body("User with ID " + id);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgumentException(IllegalArgumentException ex) {
        HttpHeaders headers = new HttpHeaders();
        headers.add("X-Error-Type", "Validation");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).headers(headers).body(ex.getMessage());
    }
}
```

- **Run it**: Call `http://localhost:8080/user/1` (success) and `/user/-1` (error).
- **Result**:
    - Success: `200 OK`, body: `"User with ID 1"`, header: `X-User-ID: 1`.
    - Error: `400 Bad Request`, body: `"Invalid user ID: must be positive"`, header: `X-Error-Type: Validation`.
- **Takeaway**: `ResponseEntity` adds flexibility, but we still need global handling for reuse.

## Step 4: Introducing `WebRequest` for Request Context

### What is `WebRequest`?

- **What it does**: `WebRequest` (from `org.springframework.web.context.request`) is an interface that abstracts HTTP request details, such as path, parameters, and headers, without tying to `HttpServletRequest`.
- **Why use it**: Provides context in exception handlers for logging or including request details in responses (e.g., "Error at /user/1"). Simplifies debugging.
- **Functionality**:
    - `getParameter(String name)`: Get query parameter.
    - `getHeader(String name)`: Get header.
    - `getDescription(boolean includeClientInfo)`: Request details (e.g., `uri=/user/1`).
    - `getContextPath()`, `getRemoteUser()`.
- **Pro way**: Inject into `@ExceptionHandler` methods. Log request path/details. Avoid exposing sensitive data (e.g., client IP) in responses.

**Example 4: Adding `WebRequest`**  
Update the handler to include request context.

```java
package com.example.demo.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.WebRequest;

@RestController
public class UserController {

    @GetMapping("/user/{id}")
    public ResponseEntity<String> getUser(@PathVariable Long id) {
        if (id == null || id <= 0) {
            throw new IllegalArgumentException("Invalid user ID: must be positive");
        }
        return ResponseEntity.ok("User with ID " + id);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgumentException(IllegalArgumentException ex, WebRequest request) {
        String path = request.getDescription(false);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error at " + path + ": " + ex.getMessage());
    }
}
```

- **Run it**: Call `http://localhost:8080/user/-1`.
- **Result**: `400 Bad Request`, body: `"Error at uri=/user/-1: Invalid user ID: must be positive"`.
- **Takeaway**: `WebRequest` adds useful context, but local handling is repetitive for larger apps.

## Step 5: Global Exception Handling with `@ControllerAdvice`

### Introducing `@ControllerAdvice`

- **What it does**: `@ControllerAdvice` (from `org.springframework.web.bind.annotation`) marks a class to handle exceptions across all controllers, centralizing error handling.
- **Why use it**: Eliminates duplicate handlers in multiple controllers. Ensures consistent error responses app-wide.
- **Functionality**: Can contain multiple `@ExceptionHandler` methods. Supports scoping with `basePackages` or `annotations`.
- **Pro way**: Use for all exception handling. Combine with `ResponseEntity` and `WebRequest`. Log exceptions. Handle specific exceptions first, then a generic `Exception` fallback.

**Example 5: Global Handler**  
Create a global handler class.

```java
package com.example.demo.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgumentException(IllegalArgumentException ex, WebRequest request) {
        String path = request.getDescription(false);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error at " + path + ": " + ex.getMessage());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleAllExceptions(Exception ex, WebRequest request) {
        String path = request.getDescription(false);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Unexpected error at " + path + ": " + ex.getMessage());
    }
}
```

- **Run it**: Call `/user/-1` with the previous `UserController`.
- **Result**: Same as Example 4, but now applies to all controllers.
- **Takeaway**: `@ControllerAdvice` reduces code duplication and standardizes handling.

## Step 6: Custom Exceptions for Domain Logic

### Introducing Custom Exceptions

- **What it does**: Custom exceptions are user-defined classes extending `Exception` or `RuntimeException`, representing app-specific errors (e.g., `UserNotFoundException`).
- **Why use it**: Improves readability (e.g., `throw new UserNotFoundException()` vs. `throw new RuntimeException()`). Maps to specific HTTP statuses (e.g., 404).
- **Functionality**: Inherit from `RuntimeException` for unchecked exceptions. Add constructors or fields for details.
- **Pro way**: Extend `RuntimeException`. Include error codes or metadata. Handle in `@ControllerAdvice` with tailored responses.

**Example 6: Custom Exception**  
Create and use a custom exception.

```java
package com.example.demo.exception;

public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(String message) {
        super(message);
    }
}
```

```java
package com.example.demo.service;

import com.example.demo.exception.UserNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    public String findUserById(Long id) {
        if (id == null || id <= 0) {
            throw new UserNotFoundException("User with ID " + id + " not found");
        }
        return "User with ID " + id;
    }
}
```

```java
package com.example.demo.controller;

import com.example.demo.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/user/{id}")
    public ResponseEntity<String> getUser(@PathVariable Long id) {
        String user = userService.findUserById(id);
        return ResponseEntity.ok(user);
    }
}
```

```java
package com.example.demo.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<String> handleUserNotFoundException(UserNotFoundException ex, WebRequest request) {
        String path = request.getDescription(false);
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Error at " + path + ": " + ex.getMessage());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleIllegalArgumentException(IllegalArgumentException ex, WebRequest request) {
        String path = request.getDescription(false);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error at " + path + ": " + ex.getMessage());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleAllExceptions(Exception ex, WebRequest request) {
        String path = request.getDescription(false);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Unexpected error at " + path + ": " + ex.getMessage());
    }
}
```

- **Run it**: Call `http://localhost:8080/user/-1`.
- **Result**: `404 Not Found`, body: `"Error at uri=/user/-1: User with ID -1 not found"`.
- **Takeaway**: Custom exceptions clarify intent and map to appropriate statuses.

## Step 7: HTTP-Related Exceptions

### Introducing HTTP-Related Exceptions

Spring provides exceptions in `org.springframework.web` and `org.springframework.web.bind` for HTTP issues. These are often handled by `ResponseEntityExceptionHandler`.

1. **`MethodArgumentNotValidException`**:
    - **What it does**: Thrown when `@Valid` validation fails on `@RequestBody` or `@ModelAttribute`.
    - **Why use it**: Enforces input validation (e.g., `@NotBlank`).
    - **Functionality**: Extends `BindException`; `getBindingResult()` provides errors.
    - **Pro way**: Extract field errors for detailed responses.
2. **`HttpMessageNotReadableException`**:
    - **What it does**: Thrown for invalid request bodies (e.g., malformed JSON).
    - **Why use it**: Catches deserialization issues.
    - **Functionality**: Extends `HttpInputMessage`; `getMessage()` for details.
    - **Pro way**: Return user-friendly messages.
3. **`HttpRequestMethodNotSupportedException`**:
    - **What it does**: Thrown for unsupported HTTP methods.
    - **Why use it**: Enforces method restrictions.
    - **Functionality**: `getMethod()`, `getSupportedMethods()`.
    - **Pro way**: Suggest allowed methods.
4. **`MissingServletRequestParameterException`**:
    - **What it does**: Thrown for missing `@RequestParam`.
    - **Why use it**: Ensures required params.
    - **Functionality**: `getParameterName()`, `getParameterType()`.
    - **Pro way**: Specify missing param.
5. **`HttpMediaTypeNotSupportedException`**:
    - **What it does**: Thrown for unsupported `Content-Type`.
    - **Why use it**: Enforces media types.
    - **Functionality**: `getContentType()`, `getSupportedMediaTypes()`.
    - **Pro way**: Suggest supported types.
6. **`NoHandlerFoundException`**:
    - **What it does**: Thrown for 404 (no endpoint).
    - **Why use it**: Custom 404 handling.
    - **Functionality**: `getHttpMethod()`, `getRequestURL()`.
    - **Pro way**: Enable in properties; provide friendly 404s.

**Example 7: Validation with `@Valid`**  
Create a DTO and update the controller.

```java
package com.example.demo.dto;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

public class UserDTO {
    @NotBlank(message = "Name is mandatory")
    @Size(min = 2, max = 50, message = "Name must be between 2 and 50 characters")
    private String name;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}
```

```java
package com.example.demo.controller;

import com.example.demo.dto.UserDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.validation.Valid;

@RestController
public class UserController {

    @PostMapping("/user")
    public ResponseEntity<String> createUser(@Valid @RequestBody UserDTO userDTO, @RequestParam String type) {
        return ResponseEntity.ok("User created: " + userDTO.getName() + ", Type: " + type);
    }
}
```

- **Run it**: Send a POST to `http://localhost:8080/user` with body `{"name": ""}` or missing `type` param.
- **Result**: Default response is `400 Bad Request` (we'll handle it next).

## Step 8: Advanced Handling with `ResponseEntityExceptionHandler`

### Introducing `ResponseEntityExceptionHandler`

- **What it does**: `ResponseEntityExceptionHandler` (from `org.springframework.web.servlet.mvc.method.annotation`) is an abstract class with default handlers for Spring's HTTP exceptions, returning `ResponseEntity`.
- **Why use it**: Reduces boilerplate for common HTTP errors (e.g., validation, JSON parsing). Extensible for customization.
- **Functionality**: Provides methods like `handleMethodArgumentNotValid`, `handleHttpMessageNotReadable`. Each takes exception, `HttpHeaders`, `HttpStatus`, `WebRequest`; returns `ResponseEntity`.
- **Pro way**: Extend in `@ControllerAdvice`. Override specific handlers. Add logging and `WebRequest` context. Use with custom exceptions.

**Example 8: Full Global Handler**  
Create a comprehensive handler.

```java
package com.example.demo.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {
    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    public static class ErrorResponse {
        private String errorCode;
        private String message;
        private String details;

        public ErrorResponse(String errorCode, String message, String details) {
            this.errorCode = errorCode;
            this.message = message;
            this.details = details;
        }

        public String getErrorCode() { return errorCode; }
        public void setErrorCode(String errorCode) { this.errorCode = errorCode; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        public String getDetails() { return details; }
        public void setDetails(String details) { this.details = details; }
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex,
            HttpHeaders headers,
            HttpStatus status,
            WebRequest request) {
        logger.warn("Validation error at {}: {}", request.getDescription(false), ex.getMessage());
        Map<String, String> errors = new HashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            errors.put(error.getField(), error.getDefaultMessage());
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errors);
    }

    @Override
    protected ResponseEntity<Object> handleHttpMessageNotReadable(
            HttpMessageNotReadableException ex,
            HttpHeaders headers,
            HttpStatus status,
            WebRequest request) {
        logger.warn("Invalid JSON at {}: {}", request.getDescription(false), ex.getMessage());
        ErrorResponse errorResponse = new ErrorResponse(
                "INVALID_REQUEST_BODY",
                "Invalid request body",
                ex.getMessage()
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    @Override
    protected ResponseEntity<Object> handleHttpRequestMethodNotSupported(
            HttpRequestMethodNotSupportedException ex,
            HttpHeaders headers,
            HttpStatus status,
            WebRequest request) {
        logger.warn("Method not supported at {}: {}", request.getDescription(false), ex.getMessage());
        ErrorResponse errorResponse = new ErrorResponse(
                "METHOD_NOT_SUPPORTED",
                "HTTP method not supported",
                "Supported methods: " + ex.getSupportedMethods()
        );
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(errorResponse);
    }

    @Override
    protected ResponseEntity<Object> handleMissingServletRequestParameter(
            MissingServletRequestParameterException ex,
            HttpHeaders headers,
            HttpStatus status,
            WebRequest request) {
        logger.warn("Missing parameter at {}: {}", request.getDescription(false), ex.getMessage());
        ErrorResponse errorResponse = new ErrorResponse(
                "MISSING_PARAMETER",
                "Missing required parameter",
                "Parameter '" + ex.getParameterName() + "' is required"
        );
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    @Override
    protected ResponseEntity<Object> handleHttpMediaTypeNotSupported(
            HttpMediaTypeNotSupportedException ex,
            HttpHeaders headers,
            HttpStatus status,
            WebRequest request) {
        logger.warn("Unsupported media type at {}: {}", request.getDescription(false), ex.getMessage());
        ErrorResponse errorResponse = new ErrorResponse(
                "UNSUPPORTED_MEDIA_TYPE",
                "Unsupported media type",
                "Supported types: " + ex.getSupportedMediaTypes()
        );
        return ResponseEntity.status(HttpStatus.UNSUPPORTED_MEDIA_TYPE).body(errorResponse);
    }

    @Override
    protected ResponseEntity<Object> handleNoHandlerFoundException(
            NoHandlerFoundException ex,
            HttpHeaders headers,
            HttpStatus status,
            WebRequest request) {
        logger.warn("No handler found at {}: {}", request.getDescription(false), ex.getMessage());
        ErrorResponse errorResponse = new ErrorResponse(
                "NO_HANDLER_FOUND",
                "Resource not found",
                "No endpoint found for " + ex.getRequestURL()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleUserNotFoundException(UserNotFoundException ex, WebRequest request) {
        logger.error("User not found at {}: {}", request.getDescription(false), ex.getMessage());
        ErrorResponse errorResponse = new ErrorResponse(
                "USER_NOT_FOUND",
                ex.getMessage(),
                "The requested user does not exist"
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleAllExceptions(Exception ex, WebRequest request) {
        logger.error("Unexpected error at {}: {}", request.getDescription(false), ex.getMessage(), ex);
        ErrorResponse errorResponse = new ErrorResponse(
                "INTERNAL_SERVER_ERROR",
                "An unexpected error occurred",
                ex.getMessage()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }
}
```

- **Run it**:
    - POST `{"name": ""}` to `/user?type=admin`: `400`, `{"name": "Name is mandatory"}`.
    - POST `{invalid json}`: `400`, `{"errorCode": "INVALID_REQUEST_BODY", ...}`.
    - GET `/user`: `405`, `{"errorCode": "METHOD_NOT_SUPPORTED", ...}`.
    - POST `/user` without `type`: `400`, `{"errorCode": "MISSING_PARAMETER", ...}`.
    - POST with `Content-Type: text/plain`: `415`, `{"errorCode": "UNSUPPORTED_MEDIA_TYPE", ...}`.
    - GET `/invalid`: `404`, `{"errorCode": "NO_HANDLER_FOUND", ...}` (after enabling in properties).
- **Enable `NoHandlerFoundException`**:
    
    ```properties
    spring.mvc.throw-exception-if-no-handler-found=true
    spring.web.resources.add-mappings=false
    ```
    

## Step 9: Testing Exception Handling

### Why Test?

Testing ensures handlers work as expected, covering success and error cases.

**Example 9: MockMvc Tests**

```java
package com.example.demo.controller;

import com.example.demo.dto.UserDTO;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testCreateUserValid() throws Exception {
        UserDTO userDTO = new UserDTO();
        userDTO.setName("John Doe");

        mockMvc.perform(post("/user?type=admin")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(userDTO)))
                .andExpect(status().isOk())
                .andExpect(content().string("User created: John Doe, Type: admin"));
    }

    @Test
    public void testCreateUserInvalidInput() throws Exception {
        UserDTO userDTO = new UserDTO();
        userDTO.setName("");

        mockMvc.perform(post("/user?type=admin")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(userDTO)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.name").value("Name is mandatory"));
    }

    @Test
    public void testCreateUserInvalidJson() throws Exception {
        mockMvc.perform(post("/user?type=admin")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{ \"name\": }"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST_BODY"));
    }

    @Test
    public void testCreateUserUnsupportedMethod() throws Exception {
        mockMvc.perform(get("/user?type=admin")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.errorCode").value("METHOD_NOT_SUPPORTED"));
    }

    @Test
    public void testCreateUserMissingParameter() throws Exception {
        UserDTO userDTO = new UserDTO();
        userDTO.setName("John Doe");

        mockMvc.perform(post("/user")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(userDTO)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MISSING_PARAMETER"));
    }

    @Test
    public void testNoHandlerFound() throws Exception {
        mockMvc.perform(get("/invalid-endpoint")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("NO_HANDLER_FOUND"));
    }
}
```

- **Takeaway**: Tests cover all scenarios, ensuring robust handling.

## Step 10: Production Best Practices

1. **Use `ResponseEntity`**: For all responses, control status/headers.
2. **Extend `ResponseEntityExceptionHandler`**: Handle HTTP exceptions efficiently.
3. **Use `WebRequest`**: Log context like path.
4. **Custom Exceptions**: Clarify domain errors.
5. **Standardize Responses**: Use `ErrorResponse` DTO.
6. **Log Smartly**: Use SLF4J, avoid sensitive data.
7. **Secure Responses**: Hide stack traces in prod.
8. **Test Everything**: Cover all cases with MockMvc.




### Tags : [[0 - Spring Framework]]