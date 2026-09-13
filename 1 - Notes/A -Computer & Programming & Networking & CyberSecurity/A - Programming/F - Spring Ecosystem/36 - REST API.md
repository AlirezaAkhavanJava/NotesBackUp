### What is a REST API?

A **REST API** (Representational State Transfer Application Programming Interface) is a set of architectural principles for designing networked applications. It enables communication between systems over HTTP, using standard methods like GET, POST, PUT, DELETE, etc., to perform operations on resources (e.g., data entities like users, products). REST APIs are stateless, meaning each request from a client to a server must contain all the information needed to process it, and they typically return data in formats like JSON or XML.

Key characteristics of a REST API:
- **Stateless**: Each request is independent and contains all necessary information.
- **Resource-Based**: Resources (e.g., `/users`, `/products`) are identified by URLs.
- **Standard HTTP Methods**: GET (retrieve), POST (create), PUT (update), DELETE (remove), etc.
- **Data Format**: Commonly uses JSON for data exchange.
- **Scalable and Flexible**: Easy to extend and integrate with other systems.

---

### How to Create a REST API in Spring Boot

Spring Boot is a Java-based framework that simplifies the development of REST APIs by providing pre-configured tools and conventions. Below is a step-by-step guide to creating a simple REST API using Spring Boot.

#### Prerequisites
- Java Development Kit (JDK) 17 or later installed.
- Maven or Gradle for dependency management.
- An IDE like IntelliJ IDEA or Eclipse.
- Basic knowledge of Java and Spring.

#### Step-by-Step Guide

##### 1. **Set Up a Spring Boot Project**
You can create a Spring Boot project using **Spring Initializr** (https://start.spring.io/) or your IDE.

- **Project Settings**:
  - **Project**: Maven or Gradle
  - **Language**: Java
  - **Spring Boot Version**: Latest stable (e.g., 3.2.x)
  - **Dependencies**: Add `Spring Web` (for REST API) and optionally `Spring Data JPA` (for database interaction) and `H2 Database` (for an in-memory database).
  - **Group**: `com.example`
  - **Artifact**: `rest-api-demo`
  - **Package**: `com.example.restapidemo`

Download the project, unzip it, and open it in your IDE.

##### 2. **Project Structure**
After setting up, your project will have a structure like this:
```
rest-api-demo/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/restapidemo/
│   │   │       ├── RestApiDemoApplication.java
│   │   │       ├── controller/
│   │   │       ├── model/
│   │   │       ├── repository/
│   │   │       └── service/
│   │   ├── resources/
│   │   │   └── application.properties
├── pom.xml (or build.gradle)
```

##### 3. **Create a Model**
Define a simple entity (e.g., `User`) to represent the resource.

```java
package com.example.restapidemo.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String email;

    // Constructors
    public User() {}

    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
```

##### 4. **Create a Repository**
Create a repository interface to interact with the database using Spring Data JPA.

```java
package com.example.restapidemo.repository;

import com.example.restapidemo.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
}
```

##### 5. **Create a Service**
Create a service layer to handle business logic.

```java
package com.example.restapidemo.service;

import com.example.restapidemo.model.User;
import com.example.restapidemo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public Optional<User> getUserById(Long id) {
        return userRepository.findById(id);
    }

    public User createUser(User user) {
        return userRepository.save(user);
    }

    public User updateUser(Long id, User userDetails) {
        User user = userRepository.findById(id).orElseThrow(() -> new RuntimeException("User not found"));
        user.setName(userDetails.getName());
        user.setEmail(userDetails.getEmail());
        return userRepository.save(user);
    }

    public void deleteUser(Long id) {
        userRepository.deleteById(id);
    }
}
```

##### 6. **Create a Controller**
Create a REST controller to define API endpoints.

```java
package com.example.restapidemo.controller;

import com.example.restapidemo.model.User;
import com.example.restapidemo.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    // Get all users
    @GetMapping
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    // Get user by ID
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        return userService.getUserById(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // Create a new user
    @PostMapping
    public User createUser(@RequestBody User user) {
        return userService.createUser(user);
    }

    // Update a user
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id, @RequestBody User userDetails) {
        try {
            User updatedUser = userService.updateUser(id, userDetails);
            return ResponseEntity.ok(updatedUser);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // Delete a user
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        try {
            userService.deleteUser(id);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
}
```

##### 7. **Configure Application Properties**
In `src/main/resources/application.properties`, configure the H2 database (or another database if preferred).

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.h2.console.enabled=true
```

The H2 console can be accessed at `http://localhost:8080/h2-console` for testing.

##### 8. **Run the Application**
- The main class (`RestApiDemoApplication.java`) is auto-generated by Spring Initializr:
```java
package com.example.restapidemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class RestApiDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(RestApiDemoApplication.class, args);
    }
}
```

- Run the application using your IDE or by executing:
```bash
./mvnw spring-boot:run
```
The application will start on `http://localhost:8080`.

##### 9. **Test the API**
Use tools like **Postman**, **cURL**, or a browser to test the API endpoints:

- **GET** `http://localhost:8080/api/users` - Retrieve all users.
- **GET** `http://localhost:8080/api/users/1` - Retrieve a user by ID.
- **POST** `http://localhost:8080/api/users` - Create a new user (send JSON like `{"name": "John", "email": "john@example.com"}`).
- **PUT** `http://localhost:8080/api/users/1` - Update a user (send JSON with updated data).
- **DELETE** `http://localhost:8080/api/users/1` - Delete a user.

Example cURL command to create a user:
```bash
curl -X POST http://localhost:8080/api/users -H "Content-Type: application/json" -d '{"name":"John","email":"john@example.com"}'
```

##### 10. **Optional Enhancements**
- **Error Handling**: Add a global exception handler using `@ControllerAdvice` to manage errors gracefully.
- **Validation**: Use `@Valid` and annotations like `@NotNull`, `@Email` in the `User` model for input validation.
- **Security**: Add Spring Security for authentication and authorization.
- **Documentation**: Use Springdoc OpenAPI or Swagger to generate API documentation.

#### Example Response (GET /api/users)
```json
[
    {
        "id": 1,
        "name": "John",
        "email": "john@example.com"
    },
    {
        "id": 2,
        "name": "Jane",
        "email": "jane@example.com"
    }
]
```

---

### Key Spring Boot Annotations Used
- `@SpringBootApplication`: Marks the main application class, enabling auto-configuration.
- `@RestController`: Indicates that the class handles REST API requests and returns JSON/XML.
- `@RequestMapping`: Maps HTTP requests to specific methods or classes.
- `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`: Map specific HTTP methods.
- `@Autowired`: Injects dependencies (e.g., `UserService` into `UserController`).
- `@Entity`: Marks a class as a JPA entity for database persistence.
- `@Id` and `@GeneratedValue`: Define the primary key and auto-increment strategy.

---

### Summary
This guide demonstrates how to create a basic REST API in Spring Boot with CRUD operations for a `User` resource. You can extend it by adding more features like validation, security, or advanced error handling based on your needs. For further details, refer to the [Spring Boot documentation](https://spring.io/projects/spring-boot) or explore Spring Data JPA for more complex database operations.

[[0 - Spring Framework]]
