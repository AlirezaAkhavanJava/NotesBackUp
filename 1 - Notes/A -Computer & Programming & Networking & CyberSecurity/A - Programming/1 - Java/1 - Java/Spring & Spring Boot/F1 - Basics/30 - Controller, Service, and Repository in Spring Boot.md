**Date**: 2025-08-24  
**Tags**:  [[0 - Spring Framework]] 

## What Are Controller, Service, and Repository?

In Java, particularly with **Spring Boot**, the **Controller**, **Service**, and **Repository** are layers in a typical web application architecture, often following the **Model-View-Controller (MVC)** pattern. They separate concerns to make code organized, maintainable, and testable. Here’s a simple explanation of each:

- **Controller**: Handles HTTP requests (e.g., from a browser or API client) and returns responses (e.g., HTML, JSON). It acts as the entry point for user interactions.

- **Service**: Contains the business logic of the application. It processes data and coordinates between the Controller and Repository.

- **Repository**: Manages database operations (e.g., saving, retrieving data). It interacts directly with the database using SQL or an ORM (like Spring Data JPA).

---
## Key Concepts

- **Separation of Concerns**: Each layer has a specific role, making the code easier to understand and modify.
- **Spring Boot**: Simplifies setup with annotations like `@Controller`, `@Service`, and `@Repository`.
- **Dependency Injection**: Spring injects dependencies (e.g., Service into Controller, Repository into Service) to keep layers loosely coupled.
- **Flow**:
    1. **Controller** receives an HTTP request (e.g., GET `/users`).
    2. **Controller** calls the **Service** to process the request.
    3. **Service** uses the **Repository** to fetch or save data.
    4. **Controller** returns the response to the client.

## Key Components

### 1. Controller

- **Purpose**: Manages HTTP requests and responses, often returning JSON for APIs or views for web pages.
- **Annotations**:
    - `@Controller`: For MVC controllers returning views (e.g., Thymeleaf templates).
    - `@RestController`: For REST APIs returning data (e.g., JSON).
    - `@GetMapping`, `@PostMapping`, etc.: Map HTTP methods to specific URLs.
- **Role**: Validates input, calls Services, and formats responses.
- **Example**: Handles a request like `/users/1` to fetch a user’s details.

### 2. Service

- **Purpose**: Contains business logic, such as calculations, validations, or data transformations.
- **Annotation**: `@Service` marks a class as a business logic component.
- **Role**: Acts as a middleman between Controller and Repository, ensuring logic is reusable and testable.
- **Example**: Calculates a user’s age or validates input before saving to the database.

### 3. Repository

- **Purpose**: Handles database operations (e.g., CRUD: Create, Read, Update, Delete).
- **Annotation**: `@Repository` marks a class for data access, often using Spring Data JPA.
- **Role**: Provides methods to interact with the database, abstracting SQL queries.
- **Example**: Fetches a list of users or saves a new user to the database.

## How They Work Together

1. **Client Request**: A user sends an HTTP request (e.g., GET `/users`).
2. **Controller**: Receives the request, validates input, and calls the Service.
3. **Service**: Processes the request (e.g., applies business rules) and calls the Repository.
4. **Repository**: Runs SQL queries to fetch or save data.
5. **Response**: The Service returns data to the Controller, which sends it back as JSON or a webpage.

## Common Issues

- **Fat Controllers**: Putting business logic in Controllers makes them hard to maintain.
    - **Fix**: Move logic to the Service layer.
- **Repository Misuse**: Using Repositories for business logic.
    - **Fix**: Keep Repositories for database operations only.
- **Missing Error Handling**: Not catching exceptions in Controllers or Services.
    - **Fix**: Use `@ExceptionHandler` or try-catch blocks.
- **Tight Coupling**: Hardcoding dependencies between layers.
    - **Fix**: Use Spring’s `@Autowired` for dependency injection.

## Best Practices

1. Keep Controllers thin: Only handle HTTP requests and responses.
2. Put business logic in Services: Make Services reusable and testable.
3. Use Repositories for data access: Avoid direct SQL in Controllers or Services.
4. Use dependency injection: Let Spring inject Services into Controllers and Repositories into Services.
5. Handle errors: Use `@ControllerAdvice` for global exception handling.
6. Test each layer: Use JUnit for Services and Repositories, and `MockMvc` for Controllers.

## Example Code

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

// Repository: Handles database operations
interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByAgeGreaterThan(int age);
}

// Service: Contains business logic
@Service
class UserService {
    @Autowired
    private UserRepository repository;

    public List<User> getUsersOlderThan(int age) {
        return repository.findByAgeGreaterThan(age);
    }

    public User saveUser(User user) {
        // Add business logic (e.g., validate user)
        if (user.getName() == null || user.getName().isEmpty()) {
            throw new IllegalArgumentException("Name cannot be empty");
        }
        return repository.save(user);
    }
}

// Controller: Handles HTTP requests
@RestController
@RequestMapping("/users")
class UserController {
    @Autowired
    private UserService service;

    @GetMapping
    public List<User> getUsers(@RequestParam int minAge) {
        return service.getUsersOlderThan(minAge);
    }

    @PostMapping
    public User createUser(@RequestBody User user) {
        return service.saveUser(user);
    }
}

// Model: Represents data
record User(Long id, String name, int age) {}
```

**Note**:

- Add dependencies: `spring-boot-starter-web` and `spring-boot-starter-data-jpa` (Maven/Gradle).
    
- Configure a database (e.g., MySQL) in `application.properties`:
    
    ```properties
    spring.datasource.url=jdbc:mysql://localhost:3306/mydb
    spring.datasource.username=root
    spring.datasource.password=password
    spring.jpa.hibernate.ddl-auto=update
    ```
    
- Run the app and test with `http://localhost:8080/users?minAge=20` (GET) or POST a JSON like `{"name":"John","age":25}`.
    

## Summary

In Spring Boot, **Controller**, **Service**, and **Repository** are layers that work together to handle web requests:

- **Controller**: Manages HTTP requests and responses (use `@RestController`).
- **Service**: Handles business logic (use `@Service`).
- **Repository**: Manages database operations (use `@Repository` with Spring Data JPA). Keep each layer focused, use dependency injection, and handle errors to build clean, scalable web applications.