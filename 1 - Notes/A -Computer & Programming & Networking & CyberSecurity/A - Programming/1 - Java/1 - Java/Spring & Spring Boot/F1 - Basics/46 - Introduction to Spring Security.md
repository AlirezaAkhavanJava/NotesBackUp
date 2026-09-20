
## Overview

**Spring Security** is a powerful and customizable framework for securing Spring-based applications. It provides comprehensive support for authentication (verifying user identity) and authorization (controlling access to resources). This guide focuses on securing APIs with **basic authentication** and **role-based access control** using Spring Security.

**Why Use Spring Security?**

- Protects APIs and web applications from unauthorized access.
- Supports various authentication mechanisms (e.g., basic, JWT, OAuth2).
- Enables fine-grained access control with roles and permissions.
- Integrates seamlessly with Spring MVC and Spring Data JPA.

**How It Works**:

- Add `spring-boot-starter-security` to enable Spring Security.
- Configure `SecurityFilterChain` to define security rules.
- Use `@PreAuthorize` for method-level security.
- Test secured endpoints with tools like Postman.

**Resources**:

- [Spring Security Documentation](https://docs.spring.io/spring-security/reference/index.html)
- _Spring in Action_ by Craig Walls (Chapter 4)
- [Spring Security Reference](https://spring.io/projects/spring-security)

**Prerequisites**:

- Basic understanding of HTTP authentication (e.g., Basic Auth, headers).
- Familiarity with Spring MVC and REST APIs (e.g., the Todo API from previous steps).

**Practice Goal**: Secure a Todo API with basic authentication and role-based access (ADMIN and USER roles), and test it using Postman.

---

## Setting Up Spring Security

### 1. Project Setup

Extend the Todo API (from previous steps) by adding Spring Security. Use Spring Data JPA with H2 for simplicity.

#### `pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>todo-security-app</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

**Notes**:

- `spring-boot-starter-security`: Adds Spring Security dependencies.
- Other dependencies support REST APIs and database operations.

### 2. Configure Application

Set up the H2 database in `src/main/resources/application.properties`.

```properties
spring.datasource.url=jdbc:h2:mem:tododb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
spring.h2.console.enabled=true
```

---

## Building the Secured Todo API

### Project Structure

```
todo-security-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   ├── com/example/
│   │   │   │   ├── TodoApplication.java
│   │   │   │   ├── model/
│   │   │   │   │   ├── Todo.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── TodoRepository.java
│   │   │   │   ├── controller/
│   │   │   │   │   ├── TodoController.java
│   │   │   │   ├── security/
│   │   │   │   │   ├── SecurityConfig.java
│   │   │   │   │   ├── UserConfig.java
│   │   ├── resources/
│   │   │   ├── application.properties
├── pom.xml
```

### 1. Entity Class (`Todo.java`)

Define the `Todo` entity (same as previous steps).

```java
package com.example.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Todo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    private boolean completed;

    // Default constructor for JPA
    public Todo() {}

    public Todo(String title, boolean completed) {
        this.title = title;
        this.completed = completed;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public boolean isCompleted() { return completed; }
    public void setCompleted(boolean completed) { this.completed = completed; }
}
```

### 2. Repository (`TodoRepository.java`)

```java
package com.example.repository;

import com.example.model.Todo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TodoRepository extends JpaRepository<Todo, Long> {
}
```

### 3. Controller (`TodoController.java`)

Secure endpoints with `@PreAuthorize` for role-based access.

```java
package com.example.controller;

import com.example.model.Todo;
import com.example.repository.TodoRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/todos")
public class TodoController {
    private final TodoRepository todoRepository;

    public TodoController(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @GetMapping
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public List<Todo> getAllTodos() {
        return todoRepository.findAll();
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Todo> getTodoById(@PathVariable Long id) {
        return todoRepository.findById(id)
                .map(todo -> ResponseEntity.ok(todo))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Todo> createTodo(@RequestBody Todo todo) {
        Todo savedTodo = todoRepository.save(todo);
        return new ResponseEntity<>(savedTodo, HttpStatus.CREATED);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteTodo(@PathVariable Long id) {
        if (todoRepository.existsById(id)) {
            todoRepository.deleteById(id);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
```

**Notes**:

- `@PreAuthorize("hasRole('ROLE_NAME')")`: Restricts access based on user roles.
- `ROLE_USER` can view todos (`GET`).
- `ROLE_ADMIN` can create (`POST`) and delete (`DELETE`) todos.

### 4. Security Configuration (`SecurityConfig.java`)

Configure basic authentication and role-based access with `SecurityFilterChain`.

```java
package com.example.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/h2-console/**").permitAll() // Allow H2 console access
                .anyRequest().authenticated() // All other requests require authentication
            )
            .httpBasic() // Enable Basic Authentication
            .and()
            .csrf().disable() // Disable CSRF for simplicity (not recommended for production)
            .headers().frameOptions().disable(); // Allow H2 console in iframe
        return http.build();
    }
}
```

**Notes**:

- `@EnableWebSecurity`: Enables Spring Security.
- `@EnableMethodSecurity`: Enables `@PreAuthorize` annotations.
- `httpBasic()`: Configures Basic Authentication (username/password in HTTP header).
- `csrf().disable()`: Disabled for simplicity; enable in production for REST APIs with proper CSRF tokens.
- `headers().frameOptions().disable()`: Allows H2 console access.

### 5. User Configuration (`UserConfig.java`)

Define in-memory users with roles for testing.

```java
package com.example.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;

@Configuration
public class UserConfig {

    @Bean
    public UserDetailsService userDetailsService() {
        var user = User.withUsername("user")
                .password("{noop}userpass") // {noop} for plain text (testing only)
                .roles("USER")
                .build();
        var admin = User.withUsername("admin")
                .password("{noop}adminpass")
                .roles("ADMIN")
                .build();
        return new InMemoryUserDetailsManager(user, admin);
    }
}
```

**Notes**:

- `InMemoryUserDetailsManager`: Defines users for testing (not for production).
- `{noop}`: Indicates plain-text passwords (use a password encoder like `BCryptPasswordEncoder` in production).
- Roles: `ROLE_USER` and `ROLE_ADMIN`.

### 6. Main Application (`TodoApplication.java`)

```java
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TodoApplication {
    public static void main(String[] args) {
        SpringApplication.run(TodoApplication.class, args);
    }
}
```

---

## Running and Testing the Application

### 1. Run the Application

```bash
mvn spring-boot:run
```

### 2. Test with Postman

Use Postman to test the secured API endpoints with Basic Authentication.

#### a. **Get All Todos (USER or ADMIN)**

- **Request**:
    - Method: GET
    - URL: `http://localhost:8080/api/todos`
    - Headers: `Authorization: Basic dXNlcjp1c2VycGFzcw==` (Base64 of `user:userpass`)
- **Expected Response** (HTTP 200):
    
    ```json
    [
        {
            "id": 1,
            "title": "Learn Spring Security",
            "completed": false
        }
    ]
    ```
    
- **Test with Admin**:
    - Headers: `Authorization: Basic YWRtaW46YWRtaW5wYXNz` (Base64 of `admin:adminpass`)

#### b. **Create a Todo (ADMIN only)**

- **Request**:
    - Method: POST
    - URL: `http://localhost:8080/api/todos`
    - Headers: `Authorization: Basic YWRtaW46YWRtaW5wYXNz`, `Content-Type: application/json`
    - Body:
        
        ```json
        {
            "title": "Learn Spring Security",
            "completed": false
        }
        ```
        
- **Expected Response** (HTTP 201):
    
    ```json
    {
        "id": 1,
        "title": "Learn Spring Security",
        "completed": false
    }
    ```
    
- **Test with User**:
    - Headers: `Authorization: Basic dXNlcjp1c2VycGFzcw==`
    - Expected Response: HTTP 403 Forbidden

#### c. **Delete a Todo (ADMIN only)**

- **Request**:
    - Method: DELETE
    - URL: `http://localhost:8080/api/todos/1`
    - Headers: `Authorization: Basic YWRtaW46YWRtaW5wYXNz`
- **Expected Response**: HTTP 204 No Content
- **Test with User**: HTTP 403 Forbidden

#### d. **Test Unauthorized Access**

- **Request**:
    - Method: GET
    - URL: `http://localhost:8080/api/todos`
    - No Authorization header
- **Expected Response**: HTTP 401 Unauthorized

### 3. Test with H2 Console

- URL: `http://localhost:8080/h2-console`
- JDBC URL: `jdbc:h2:mem:tododb`
- Username: `sa`
- Password: (empty)
- Verify the `todos` table and data.

---

## How It Works

- **Spring Security**:
    - `SecurityFilterChain`: Enforces authentication for all requests except `/h2-console`.
    - Basic Authentication: Requires username/password in the `Authorization` header (Base64-encoded).
    - `@PreAuthorize`: Restricts endpoint access based on roles (`ROLE_USER`, `ROLE_ADMIN`).
- **In-Memory Authentication**:
    - `UserConfig` defines two users: `user` (ROLE_USER) and `admin` (ROLE_ADMIN).
- **Hibernate/JPA**:
    - Persists `Todo` entities to the H2 database.
- **Postman**:
    - Tests authentication and authorization by sending requests with correct/incorrect credentials.

**Example HTTP Request (Basic Auth)**:

```
GET /api/todos HTTP/1.1
Host: localhost:8080
Authorization: Basic YWRtaW46YWRtaW5wYXNz
```

---

## Advanced Features

1. **Password Encoding**:  
    Use `BCryptPasswordEncoder` for secure passwords:
    
    ```java
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    
    @Bean
    public UserDetailsService userDetailsService(PasswordEncoder passwordEncoder) {
        var user = User.withUsername("user")
                .password(passwordEncoder.encode("userpass"))
                .roles("USER")
                .build();
        var admin = User.withUsername("admin")
                .password(passwordEncoder.encode("adminpass"))
                .roles("ADMIN")
                .build();
        return new InMemoryUserDetailsManager(user, admin);
    }
    ```
    
2. **Database-Backed Authentication**:  
    Use a `User` entity and `JdbcUserDetailsManager`:
    
    ```java
    @Entity
    public class User {
        @Id
        private String username;
        private String password;
        private String roles; // e.g., "ROLE_USER,ROLE_ADMIN"
    }
    ```
    
3. **Method-Level Security**:  
    Protect service methods:
    
    ```java
    @Service
    public class TodoService {
        @PreAuthorize("hasRole('ADMIN')")
        public Todo saveTodo(Todo todo) {
            return todoRepository.save(todo);
        }
    }
    ```
    
4. **CSRF for REST APIs**:  
    Enable CSRF in production and include CSRF tokens in POST requests:
    
    ```java
    http.csrf().csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse());
    ```
    

---

## Best Practices

- **Use Secure Passwords**: Always use a password encoder (`BCryptPasswordEncoder`) in production.
- **Enable CSRF**: Disable CSRF only for testing; enable it for REST APIs with proper token handling.
- **Role-Based Access**: Define granular roles and use `@PreAuthorize` for fine-grained control.
- **HTTPS**: Use HTTPS in production to encrypt Basic Auth credentials.
- **Test Security**:  
    Use `@SpringBootTest` with MockMvc:
    
    ```java
    @SpringBootTest
    @AutoConfigureMockMvc
    class TodoControllerTest {
        @Autowired
        private MockMvc mockMvc;
    
        @Test
        void testGetTodosWithUserRole() throws Exception {
            mockMvc.perform(get("/api/todos")
                    .with(httpBasic("user", "userpass")))
                    .andExpect(status().isOk());
        }
    }
    ```
    

---

## Conclusion

Spring Security simplifies securing APIs with basic authentication and role-based access control. By configuring `SecurityFilterChain` and `@PreAuthorize`, you can protect endpoints like the Todo API, ensuring only authorized users (e.g., `ROLE_USER`, `ROLE_ADMIN`) access specific operations. Testing with Postman verifies authentication and authorization behavior. Explore advanced features like database-backed authentication and CSRF protection, and refer to the Spring Security documentation for deeper insights.


##### Tags :  [[0 - Spring Framework]]