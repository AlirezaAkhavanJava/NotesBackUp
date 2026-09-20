Date : 2025-09-08

This guide provides a detailed explanation of unit testing in Spring Boot, including setup, tools, best practices, and a complete example. Unit testing ensures that individual components of your application work as expected, helping maintain code quality and reliability.

---
## Introduction to Unit Testing

Unit testing involves testing individual components (e.g., methods or classes) of an application in isolation to ensure they behave as expected. In Spring Boot, unit tests focus on testing specific layers like services, controllers, or repositories without involving external dependencies (e.g., databases or APIs).

Key characteristics of unit tests:

- **Isolated**: Test one component at a time, mocking dependencies.
- **Fast**: Run quickly without relying on external systems.
- **Repeatable**: Produce consistent results.
- **Focused**: Test a single piece of functionality.

## Why Unit Testing in Spring Boot?

Spring Boot applications are often layered (controllers, services, repositories), and unit testing ensures each layer works correctly. Benefits include:

- Catching bugs early in development.
- Improving code quality and maintainability.
- Facilitating refactoring by ensuring existing functionality remains intact.
- Supporting Test-Driven Development (TDD).

## Tools and Dependencies

Common tools for unit testing in Spring Boot:

- **JUnit 5**: A testing framework for writing and running tests.
- **Mockito**: A mocking framework to simulate dependencies.
- **Spring Boot Test**: Provides utilities for testing Spring Boot applications.
- **AssertJ**: A fluent assertion library for readable test assertions.

Spring Boot’s `spring-boot-starter-test` includes these dependencies. Add it to your `pom.xml` (for Maven):

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

For Gradle, add to `build.gradle`:

```gradle
testImplementation 'org.springframework.boot:spring-boot-starter-test'
```

This dependency includes JUnit 5, Mockito, AssertJ, and other testing libraries.

## Setting Up a Spring Boot Project

To demonstrate unit testing, let’s set up a simple Spring Boot project for managing users. The application will have:

- A `User` entity.
- A `UserRepository` for database operations.
- A `UserService` for business logic.
- A `UserController` for handling HTTP requests.

### Project Structure

```
src
├── main
│   ├── java
│   │   └── com.example.demo
│   │       ├── entity
│   │       │   └── User.java
│   │       ├── repository
│   │       │   └── UserRepository.java
│   │       ├── service
│   │       │   └── UserService.java
│   │       ├── controller
│   │       │   └── UserController.java
│   │       └── DemoApplication.java
│   └── resources
│       └── application.properties
├── test
│   └── java
│       └── com.example.demo
│           ├── service
│           │   └── UserServiceTest.java
│           ├── controller
│           │   └── UserControllerTest.java
│           └── repository
│               └── UserRepositoryTest.java
```

### Adding Dependencies

In `pom.xml`, include dependencies for Spring Boot, JPA, and testing:

```xml
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
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

The H2 database is used for testing purposes.

## Writing Unit Tests

Unit tests in Spring Boot typically focus on individual layers. Below, we’ll write tests for the service, controller, and repository layers.

### Testing a Service

The `UserService` contains business logic, such as retrieving or saving users. We’ll mock the `UserRepository` dependency to isolate the service.

Example `UserService` class:

```java
package com.example.demo.service;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {
    private final UserRepository userRepository;

    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User saveUser(User user) {
        return userRepository.save(user);
    }

    public Optional<User> findUserById(Long id) {
        return userRepository.findById(id);
    }

    public List<User> findAllUsers() {
        return userRepository.findAll();
    }

    public void deleteUser(Long id) {
        userRepository.deleteById(id);
    }
}
```

Unit test for `UserService`:

```java
package com.example.demo.service;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private User user;

    @BeforeEach
    void setUp() {
        user = new User(1L, "John Doe", "john@example.com");
    }

    @Test
    void shouldSaveUserSuccessfully() {
        when(userRepository.save(any(User.class))).thenReturn(user);

        User savedUser = userService.saveUser(user);

        assertThat(savedUser).isNotNull();
        assertThat(savedUser.getName()).isEqualTo("John Doe");
        verify(userRepository, times(1)).save(user);
    }

    @Test
    void shouldFindUserById() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        Optional<User> foundUser = userService.findUserById(1L);

        assertThat(foundUser).isPresent();
        assertThat(foundUser.get().getEmail()).isEqualTo("john@example.com");
        verify(userRepository, times(1)).findById(1L);
    }

    @Test
    void shouldReturnEmptyWhenUserNotFound() {
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        Optional<User> foundUser = userService.findUserById(1L);

        assertThat(foundUser).isEmpty();
        verify(userRepository, times(1)).findById(1L);
    }

    @Test
    void shouldFindAllUsers() {
        List<User> users = Arrays.asList(user, new User(2L, "Jane Doe", "jane@example.com"));
        when(userRepository.findAll()).thenReturn(users);

        List<User> allUsers = userService.findAllUsers();

        assertThat(allUsers).hasSize(2);
        assertThat(allUsers.get(0).getName()).isEqualTo("John Doe");
        verify(userRepository, times(1)).findAll();
    }

    @Test
    void shouldDeleteUser() {
        doNothing().when(userRepository).deleteById(1L);

        userService.deleteUser(1L);

        verify(userRepository, times(1)).deleteById(1L);
    }
}
```

**Key Points**:

- `@ExtendWith(MockitoExtension.class)` enables Mockito annotations.
- `@Mock` creates a mock of `UserRepository`.
- `@InjectMocks` injects the mock into `UserService`.
- `when(...).thenReturn(...)` defines mock behavior.
- `verify(...)` checks if the mock was called as expected.
- AssertJ’s `assertThat` provides fluent assertions.

### Testing a Controller

The `UserController` handles HTTP requests. We’ll use `MockMvc` to simulate HTTP requests and test the controller in isolation.

Example `UserController` class:

```java
package com.example.demo.controller;

import com.example.demo.entity.User;
import com.example.demo.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody User user) {
        return ResponseEntity.ok(userService.saveUser(user));
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        Optional<User> user = userService.findUserById(id);
        return user.map(ResponseEntity::ok)
                   .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        return ResponseEntity.ok(userService.findAllUsers());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
```

Unit test for `UserController`:

```java
package com.example.demo.controller;

import com.example.demo.entity.User;
import com.example.demo.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.Optional;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Autowired
    private ObjectMapper objectMapper;

    private User user;

    @BeforeEach
    void setUp() {
        user = new User(1L, "John Doe", "john@example.com");
    }

    @Test
    void shouldCreateUser() throws Exception {
        when(userService.saveUser(any(User.class))).thenReturn(user);

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("John Doe"))
                .andExpect(jsonPath("$.email").value("john@example.com"));

        verify(userService, times(1)).saveUser(any(User.class));
    }

    @Test
    void shouldGetUserById() throws Exception {
        when(userService.findUserById(1L)).thenReturn(Optional.of(user));

        mockMvc.perform(get("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("John Doe"));

        verify(userService, times(1)).findUserById(1L);
    }

    @Test
    void shouldReturnNotFoundWhenUserDoesNotExist() throws Exception {
        when(userService.findUserById(1L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());

        verify(userService, times(1)).findUserById(1L);
    }

    @Test
    void shouldGetAllUsers() throws Exception {
        List<User> users = Arrays.asList(user, new User(2L, "Jane Doe", "jane@example.com"));
        when(userService.findAllUsers()).thenReturn(users);

        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].name").value("John Doe"));

        verify(userService, times(1)).findAllUsers();
    }

    @Test
    void shouldDeleteUser() throws Exception {
        doNothing().when(userService).deleteUser(1L);

        mockMvc.perform(delete("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());

        verify(userService, times(1)).deleteUser(1L);
    }
}
```

**Key Points**:

- `@WebMvcTest(UserController.class)` loads only the web layer, mocking the Spring context.
- `@MockBean` mocks the `UserService` dependency.
- `MockMvc` simulates HTTP requests and verifies responses.
- `ObjectMapper` serializes/deserializes JSON for testing.

### Testing a Repository

The `UserRepository` interacts with the database. For unit tests, we use an in-memory database like H2 to avoid mocking the JPA layer.

Example `User` entity:

```java
package com.example.demo.entity;

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

    public User() {}

    public User(Long id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
```

Example `UserRepository`:

```java
package com.example.demo.repository;

import com.example.demo.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
}
```

Unit test for `UserRepository`:

```java
package com.example.demo.repository;

import com.example.demo.entity.User;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void shouldSaveAndFindUserById() {
        User user = new User(null, "John Doe", "john@example.com");
        User savedUser = userRepository.save(user);

        Optional<User> foundUser = userRepository.findById(savedUser.getId());

        assertThat(foundUser).isPresent();
        assertThat(foundUser.get().getName()).isEqualTo("John Doe");
        assertThat(foundUser.get().getEmail()).isEqualTo("john@example.com");
    }

    @Test
    void shouldReturnEmptyWhenUserNotFound() {
        Optional<User> foundUser = userRepository.findById(999L);

        assertThat(foundUser).isEmpty();
    }

    @Test
    void shouldDeleteUser() {
        User user = new User(null, "John Doe", "john@example.com");
        User savedUser = userRepository.save(user);

        userRepository.deleteById(savedUser.getId());
        Optional<User> foundUser = userRepository.findById(savedUser.getId());

        assertThat(foundUser).isEmpty();
    }
}
```

**Key Points**:

- `@DataJpaTest` configures an in-memory database (H2) and loads only the JPA layer.
- Tests interact directly with the repository, verifying database operations.
- No mocking is needed since H2 provides a real database for testing.

## Mocking with Mockito

Mockito is used to mock dependencies, allowing you to control their behavior. Key Mockito features:

- **Mocking**: Create mock objects with `@Mock` or `mock()`.
- **Stubbing**: Define mock behavior with `when(...).thenReturn(...)` or `doReturn(...).when(...)`.
- **Verification**: Check interactions with `verify(...)`.
- **Argument Matchers**: Use `any()`, `eq()`, etc., for flexible stubbing.

Example of mocking in `UserServiceTest`:

```java
when(userRepository.findById(1L)).thenReturn(Optional.of(user));
verify(userRepository, times(1)).findById(1L);
```

**Tips**:

- Use `any()` for complex objects, but prefer specific values for simple types.
- Use `verifyNoMoreInteractions()` to ensure no unexpected calls to mocks.
- Handle exceptions with `thenThrow()` for negative test cases.

## Best Practices for Unit Testing

1. **Test One Thing at a Time**: Each test should focus on a single behavior.
2. **Use Descriptive Test Names**: E.g., `shouldSaveUserSuccessfully` instead of `testSave`.
3. **Keep Tests Independent**: Tests should not rely on each other.
4. **Mock External Dependencies**: Isolate the unit under test.
5. **Use Arrange-Act-Assert (AAA) Pattern**:
    - **Arrange**: Set up test data and mocks.
    - **Act**: Call the method under test.
    - **Assert**: Verify the outcome.
6. **Test Edge Cases**: Test null values, empty inputs, and error conditions.
7. **Aim for High Test Coverage**: Use tools like JaCoCo to measure coverage.
8. **Keep Tests Fast**: Avoid slow operations like network calls or file I/O.
9. **Use Consistent Test Data**: Set up test data in `@BeforeEach` for consistency.
10. **Refactor Tests**: Keep test code clean and maintainable.

## Running Tests

Run tests using Maven:

```bash
mvn test
```

Or with Gradle:

```bash
./gradlew test
```

You can also run tests from your IDE (e.g., IntelliJ or Eclipse) by right-clicking the test class or method.

To generate a test coverage report with JaCoCo (Maven):

1. Add the JaCoCo plugin to `pom.xml`:
    
    ```xml
    <build>
        <plugins>
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.8.8</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>prepare-agent</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>report</id>
                        <phase>test</phase>
                        <goals>
                            <goal>report</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
    ```
    
2. Run `mvn test` to generate the report in `target/site/jacoco/index.html`.

## Complete Example

Below is a complete example of the `User` entity, repository, service, controller, and their respective tests.

### User Entity

```java
package com.example.demo.entity;

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

    public User() {}

    public User(Long id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
```

### User Repository

```java
package com.example.demo.repository;

import com.example.demo.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
}
```

### User Service

```java
package com.example.demo.service;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {
    private final UserRepository userRepository;

    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User saveUser(User user) {
        return userRepository.save(user);
    }

    public Optional<User> findUserById(Long id) {
        return userRepository.findById(id);
    }

    public List<User> findAllUsers() {
        return userRepository.findAll();
    }

    public void deleteUser(Long id) {
        userRepository.deleteById(id);
    }
}
```

### User Controller

```java
package com.example.demo.controller;

import com.example.demo.entity.User;
import com.example.demo.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody User user) {
        return ResponseEntity.ok(userService.saveUser(user));
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        Optional<User> user = userService.findUserById(id);
        return user.map(ResponseEntity::ok)
                   .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        return ResponseEntity.ok(userService.findAllUsers());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
```

### User Service Test

```java
package com.example.demo.service;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private User user;

    @BeforeEach
    void setUp() {
        user = new User(1L, "John Doe", "john@example.com");
    }

    @Test
    void shouldSaveUserSuccessfully() {
        when(userRepository.save(any(User.class))).thenReturn(user);

        User savedUser = userService.saveUser(user);

        assertThat(savedUser).isNotNull();
        assertThat(savedUser.getName()).isEqualTo("John Doe");
        verify(userRepository, times(1)).save(user);
    }

    @Test
    void shouldFindUserById() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        Optional<User> foundUser = userService.findUserById(1L);

        assertThat(foundUser).isPresent();
        assertThat(foundUser.get().getEmail()).isEqualTo("john@example.com");
        verify(userRepository, times(1)).findById(1L);
    }

    @Test
    void shouldReturnEmptyWhenUserNotFound() {
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        Optional<User> foundUser = userService.findUserById(1L);

        assertThat(foundUser).isEmpty();
        verify(userRepository, times(1)).findById(1L);
    }

    @Test
    void shouldFindAllUsers() {
        List<User> users = Arrays.asList(user, new User(2L, "Jane Doe", "jane@example.com"));
        when(userRepository.findAll()).thenReturn(users);

        List<User> allUsers = userService.findAllUsers();

        assertThat(allUsers).hasSize(2);
        assertThat(allUsers.get(0).getName()).isEqualTo("John Doe");
        verify(userRepository, times(1)).findAll();
    }

    @Test
    void shouldDeleteUser() {
        doNothing().when(userRepository).deleteById(1L);

        userService.deleteUser(1L);

        verify(userRepository, times(1)).deleteById(1L);
    }
}
```

### User Controller Test

```java
package com.example.demo.controller;

import com.example.demo.entity.User;
import com.example.demo.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.Optional;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Autowired
    private ObjectMapper objectMapper;

    private User user;

    @BeforeEach
    void setUp() {
        user = new User(1L, "John Doe", "john@example.com");
    }

    @Test
    void shouldCreateUser() throws Exception {
        when(userService.saveUser(any(User.class))).thenReturn(user);

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("John Doe"))
                .andExpect(jsonPath("$.email").value("john@example.com"));

        verify(userService, times(1)).saveUser(any(User.class));
    }

    @Test
    void shouldGetUserById() throws Exception {
        when(userService.findUserById(1L)).thenReturn(Optional.of(user));

        mockMvc.perform(get("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("John Doe"));

        verify(userService, times(1)).findUserById(1L);
    }

    @Test
    void shouldReturnNotFoundWhenUserDoesNotExist() throws Exception {
        when(userService.findUserById(1L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());

        verify(userService, times(1)).findUserById(1L);
    }

    @Test
    void shouldGetAllUsers() throws Exception {
        List<User> users = Arrays.asList(user, new User(2L, "Jane Doe", "jane@example.com"));
        when(userService.findAllUsers()).thenReturn(users);

        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].name").value("John Doe"));

        verify(userService, times(1)).findAllUsers();
    }

    @Test
    void shouldDeleteUser() throws Exception {
        doNothing().when(userService).deleteUser(1L);

        mockMvc.perform(delete("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());

        verify(userService, times(1)).deleteUser(1L);
    }
}
```

### User Repository Test

```java
package com.example.demo.repository;

import com.example.demo.entity.User;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void shouldSaveAndFindUserById() {
        User user = new User(null, "John Doe", "john@example.com");
        User savedUser = userRepository.save(user);

        Optional<User> foundUser = userRepository.findById(savedUser.getId());

        assertThat(foundUser).isPresent();
        assertThat(foundUser.get().getName()).isEqualTo("John Doe");
        assertThat(foundUser.get().getEmail()).isEqualTo("john@example.com");
    }

    @Test
    void shouldReturnEmptyWhenUserNotFound() {
        Optional<User> foundUser = userRepository.findById(999L);

        assertThat(foundUser).isEmpty();
    }

    @Test
    void shouldDeleteUser() {
        User user = new User(null, "John Doe", "john@example.com");
        User savedUser = userRepository.save(user);

        userRepository.deleteById(savedUser.getId());
        Optional<User> foundUser = userRepository.findById(savedUser.getId());

        assertThat(foundUser).isEmpty();
    }
}
```

### Application Properties

In `src/main/resources/application.properties`, configure the H2 database:

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.h2.console.enabled=true
```

## Conclusion

Unit testing in Spring Boot ensures that individual components work correctly in isolation. By using JUnit, Mockito, and Spring Boot Test, you can write robust tests for controllers, services, and repositories. Follow best practices like the AAA pattern, mocking dependencies, and testing edge cases to maintain high-quality code. The provided example demonstrates a complete setup for a user management application, including all necessary tests.

To extend your testing knowledge, explore:

- **Integration Testing**: Use `@SpringBootTest` to test the entire application context.
- **Test-Driven Development (TDD)**: Write tests before implementing functionality.
- **Mockito Advanced Features**: Use `@Spy`, `ArgumentCaptor`, or custom answer behaviors.
- **Test Coverage Tools**: Use JaCoCo or SonarQube for detailed coverage reports.






##### *Tags : [[0 - Spring Framework]]