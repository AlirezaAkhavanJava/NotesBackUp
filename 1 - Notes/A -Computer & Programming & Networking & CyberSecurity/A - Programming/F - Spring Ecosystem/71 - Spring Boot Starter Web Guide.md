Date : 2025-09-07

This guide teaches Spring Boot Starter Web from basic to advanced, using easy explanations and examples.

---


## Introduction

Spring Boot Starter Web helps you build web applications and RESTful APIs easily. It includes Spring MVC, Tomcat (embedded), and JSON processing.

---

## Setup Spring Boot Web

1. Add the dependency in `pom.xml`:
    

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

2. For Gradle:
    

```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
```

---

## Creating REST Controllers

A controller handles HTTP requests.

```java
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class MyController {

    @GetMapping("/hello")
    public String hello() {
        return "Hello World";
    }
}
```

- `@RestController` = `@Controller + @ResponseBody`
    
- `@RequestMapping` sets base path.
    

---

## Request Mapping and Parameters

### Path Variables

```java
@GetMapping("/user/{id}")
public String getUser(@PathVariable int id) {
    return "User ID: " + id;
}
```

### Request Parameters

```java
@GetMapping("/search")
public String search(@RequestParam String query) {
    return "Searching for: " + query;
}
```

### Request Body

```java
@PostMapping("/user")
public User createUser(@RequestBody User user) {
    return user;
}
```

---

## Response Handling

- Return Java objects and Spring converts them to JSON automatically.
    
- Use `ResponseEntity` for custom status codes:
    

```java
return ResponseEntity.status(HttpStatus.CREATED).body(user);
```

---

## Exception Handling

Use `@ControllerAdvice` to handle exceptions globally:

```java
import org.springframework.web.bind.annotation.*;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public String handleException(Exception ex) {
        return ex.getMessage();
    }
}
```

---

## Advanced Features

1. **Content Negotiation**: Return JSON or XML depending on request.
    
2. **Filters & Interceptors**: Handle requests globally.
    
3. **CORS Configuration**:
    

```java
@CrossOrigin(origins = "http://example.com")
```

4. **Serving Static Content**: Place files in `src/main/resources/static`.
    
5. **Async Controllers**: Return `CompletableFuture` for async responses.
    

---

## Best Practices

- Keep controllers thin; delegate logic to services.
    
- Use DTOs for request/response objects.
    
- Handle exceptions globally.
    
- Validate input (combine with Spring Validation).
    
- Version your APIs (`/api/v1/...`).
    

---

This guide provides a complete path from beginner to advanced usage of Spring Boot Starter Web, including controllers, request handling, responses, exceptions, and advanced features.




##### *Tags : [[0 - Spring Framework]]