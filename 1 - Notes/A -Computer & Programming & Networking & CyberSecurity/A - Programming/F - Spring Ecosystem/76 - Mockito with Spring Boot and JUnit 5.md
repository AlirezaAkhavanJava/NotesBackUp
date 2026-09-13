

## Welcome to the Tutorial

This tutorial teaches you how to use **Mockito** and **JUnit 5** to test Spring Boot applications, from beginner-friendly basics to advanced, production-ready techniques. We'll cover Mockito for mocking dependencies, JUnit 5 for structuring and running tests, and their integration with Spring Boot components like services, controllers, and repositories. Each section explains:

- **What it is/does**: Definition and purpose.
- **Why use it**: Benefits in a Spring Boot context.
- **Functionality and methods**: Key features and how to use them.
- **Pro way to use it**: Best practices for professional implementation.
- **Example**: Hands-on code to demonstrate the concept.

We'll build a simple Spring Boot user management REST API, testing it with JUnit 5 and Mockito. We assume you know Java and basic Spring Boot concepts (e.g., `@RestController`, `@Service`). The examples are cumulative, forming a cohesive application. Let's dive in!

### Prerequisites

- **Spring Boot Setup**: A project with Spring Web and Spring Boot Test.
- **Dependencies**: Add to your `pom.xml` (Maven):
    
    ```xml
    <dependencies>
        <!-- Spring Boot Starter Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <!-- Spring Boot Starter Test (includes JUnit 5) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <!-- Mockito Core -->
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-core</artifactId>
            <version>5.12.0</version>
            <scope>test</scope>
        </dependency>
        <!-- Mockito JUnit 5 Extension -->
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-junit-jupiter</artifactId>
            <version>5.12.0</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    ```
    

## Step 1: Understanding Mockito and JUnit 5 in Spring Boot

### What is Mockito?

Mockito is an open-source Java mocking framework that creates "mock" objects to simulate dependencies during unit testing.

- **What it does**: It fakes dependencies (e.g., `JpaRepository`, external APIs) in Spring Boot, allowing you to test components in isolation without real databases or services.
- **Why use it in Spring Boot**: Spring Boot apps have layered architectures (controllers, services, repositories). Mockito isolates these layers, making tests fast and independent.
- **Key Functionality**:
    - **Mocking**: Create fake objects.
    - **Stubbing**: Define mock responses.
    - **Verification**: Check method calls on mocks.
    - **Spying**: Partially mock real objects.
- **Pro way**: Use for unit tests of Spring components. Mock only direct dependencies to keep tests focused.

### What is JUnit 5?

JUnit 5 is a modern testing framework for Java, used to write and run unit tests.

- **What it does**: Provides annotations (e.g., `@Test`, `@BeforeEach`) and assertions (e.g., `assertEquals`) to structure and validate tests.
- **Why use it in Spring Boot**: It’s the default testing framework in Spring Boot (via `spring-boot-starter-test`). It integrates seamlessly with Mockito for robust testing.
- **Key Functionality**:
    - **Annotations**: `@Test`, `@BeforeEach`, `@AfterEach`, `@ExtendWith` for extensions.
    - **Assertions**: `assertEquals`, `assertThrows`, `assertNotNull`.
    - **Extensions**: Like `MockitoExtension` for Mockito integration.
- **Pro way**: Use `@ExtendWith(MockitoExtension.class)` for Mockito. Structure tests with given-when-then. Leverage parameterized tests for reusability.

**Example 1: Basic Mockito and JUnit 5 Test**  
Let’s test a `UserService` that depends on a `UserRepository`. First, the app components:

```java
// User.java
package com.example.demo.model;

public class User {
    private Long id;
    private String name;

    public User(Long id, String name) {
        this.id = id;
        this.name = name;
    }

    public Long getId() { return id; }
    public String getName() { return name; }
}
```

```java
// UserRepository.java
package com.example.demo.repository;

import com.example.demo.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
}
```

```java
// UserService.java
package com.example.demo.service;

import com.example.demo.model.User;
import com.example.demo.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public String getUserNameById(Long id) {
        User user = userRepository.findById(id).orElse(null);
        if (user == null) {
            throw new IllegalArgumentException("User not found");
        }
        return user.getName();
    }
}
```

Test with Mockito and JUnit 5:

```java
package com.example.demo.service;

import com.example.demo.model.User;
import com.example.demo.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    private UserService userService;

    @Test
    void testGetUserNameById() {
        // Given
        userService = new UserService(userRepository);
        when(userRepository.findById(1L)).thenReturn(Optional.of(new User(1L, "John Doe")));

        // When
        String name = userService.getUserNameById(1L);

        // Then
        assertEquals("John Doe", name);

        // Test not found
        when(userRepository.findById(2L)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> userService.getUserNameById(2L));
    }
}
```

- **Run it**: The test runs without a database, thanks to Mockito. JUnit 5’s `@Test` and assertions validate the behavior.
- **Explanation**:
    - `@ExtendWith(MockitoExtension.class)` enables Mockito annotations.
    - `@Mock` creates a mock `UserRepository`.
    - `when(...).thenReturn(...)` stubs the repository.
    - `assertEquals` and `assertThrows` (JUnit 5) verify results.
- **Takeaway**: Mockito isolates dependencies; JUnit 5 structures and validates tests.

## Step 2: Verification with Mockito and JUnit 5

### What is Verification?

Verification checks if a mock’s methods were called, ensuring correct interaction with dependencies.

- **What it does**: Confirms that your Spring component (e.g., service) called expected methods on mocks (e.g., `save` on repository).
- **Why use it in Spring Boot**: Common in services that persist data or call external APIs.
- **Functionality**: Use `Mockito.verify(mock).method(args)`, with JUnit 5 assertions for results. Modifiers: `times(n)`, `never()`, `atLeastOnce()`.
- **Pro way**: Verify critical interactions only. Combine with JUnit 5’s `assertDoesNotThrow` for success paths.

**Example 2: Verifying Repository Calls**  
Add a save method to `UserService`:

```java
public User saveUser(String name) {
    if (name == null || name.isEmpty()) {
        throw new IllegalArgumentException("Name cannot be empty");
    }
    return userRepository.save(new User(null, name));
}
```

Test with verification:

```java
@Test
void testSaveUser() {
    // Given
    userService = new UserService(userRepository);
    when(userRepository.save(Mockito.any(User.class))).thenReturn(new User(1L, "Jane Doe"));

    // When
    User savedUser = userService.saveUser("Jane Doe");

    // Then
    Mockito.verify(userRepository).save(Mockito.any(User.class));
    assertEquals("Jane Doe", savedUser.getName());
    assertEquals(1L, savedUser.getId());
}
```

- **Run it**: Passes if `save` is called; JUnit 5 assertions check the output.
- **Takeaway**: Verification ensures side effects; JUnit 5 validates results.

## Step 3: JUnit 5 Annotations and Mockito Integration

### JUnit 5 Annotations

- **What it does**: Provides annotations to structure tests (e.g., `@Test`, `@BeforeEach`).
- **Why use it**: Organizes test lifecycle and assertions in Spring Boot tests.
- **Functionality**:
    - `@Test`: Marks a test method.
    - `@BeforeEach`: Runs before each test (setup).
    - `@AfterEach`: Runs after each test (cleanup).
    - `@DisplayName`: Custom test names for readability.
    - `@ExtendWith`: Enables extensions like `MockitoExtension`.
- **Pro way**: Use `@BeforeEach` for setup, `@DisplayName` for clarity, and combine with Mockito annotations.

### Mockito Annotations

- **What it does**: Simplifies mock creation and injection (`@Mock`, `@InjectMocks`).
- **Why use it in Spring Boot**: Mimics Spring’s dependency injection, reducing boilerplate.
- **Functionality**: `@Mock`, `@Spy`, `@InjectMocks`, `@Captor`.
- **Pro way**: Use constructor injection in tests to align with Spring Boot’s best practices.

**Example 3: JUnit 5 and Mockito Annotations**

```java
package com.example.demo.service;

import com.example.demo.model.User;
import com.example.demo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @BeforeEach
    void setUp() {
        // Optional setup if needed
    }

    @Test
    @DisplayName("Should return user name when user exists")
    void testGetUserNameById() {
        // Given
        when(userRepository.findById(1L)).thenReturn(Optional.of(new User(1L, "John Doe")));

        // When
        String name = userService.getUserNameById(1L);

        // Then
        assertEquals("John Doe", name);
    }
}
```

- **Run it**: `@InjectMocks` creates `UserService` with the mock. `@DisplayName` improves readability.
- **Takeaway**: JUnit 5 annotations structure tests; Mockito annotations simplify mocking.

## Step 4: Testing Spring Controllers with Mockito and MockMvc

### Why Test Controllers?

Controllers handle HTTP requests, so testing ensures correct endpoint behavior, status codes, and JSON responses.

- **What it does**: Mockito mocks services/repositories; `MockMvc` (from `spring-test`) simulates HTTP requests.
- **Why use it in Spring Boot**: Isolates controller logic without starting a server, faster than `@SpringBootTest`.
- **Functionality**: `MockMvc` performs GET/POST requests; JUnit 5 asserts responses.
- **Pro way**: Use `MockMvcBuilders.standaloneSetup()` for unit tests. Mock services, not HTTP layers.

**Example 4: Testing a Controller**  
Create a `UserController`:

```java
package com.example.demo.controller;

import com.example.demo.model.User;
import com.example.demo.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/users/{id}")
    public ResponseEntity<String> getUserName(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserNameById(id));
    }

    @PostMapping("/users")
    public ResponseEntity<User> createUser(@RequestBody User user) {
        return ResponseEntity.ok(userService.saveUser(user.getName()));
    }
}
```

Test with Mockito, JUnit 5, and `MockMvc`:

```java
package com.example.demo.controller;

import com.example.demo.model.User;
import com.example.demo.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    @Mock
    private UserService userService;

    @InjectMocks
    private UserController userController;

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(userController).build();
    }

    @Test
    @DisplayName("Should return user name for valid ID")
    void testGetUserName() throws Exception {
        // Given
        when(userService.getUserNameById(1L)).thenReturn("John Doe");

        // When & Then
        mockMvc.perform(get("/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value("John Doe"));
    }

    @Test
    @DisplayName("Should create user and return user object")
    void testCreateUser() throws Exception {
        // Given
        User user = new User(null, "Jane Doe");
        when(userService.saveUser("Jane Doe")).thenReturn(new User(1L, "Jane Doe"));

        // When & Then
        mockMvc.perform(post("/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Jane Doe"))
                .andExpect(jsonPath("$.id").value(1L));
    }
}
```

- **Run it**: Tests endpoints without a server. JUnit 5’s `@BeforeEach` sets up `MockMvc`.
- **Takeaway**: `MockMvc` with Mockito isolates controller tests; JUnit 5 ensures robust assertions.

## Step 5: Argument Matchers (Intermediate)

### What are Argument Matchers?

Matchers allow flexible stubbing/verification in Mockito.

- **What it does**: Matches method arguments (e.g., `anyLong()` for any `Long`).
- **Why use it in Spring Boot**: Useful for repositories/services with variable inputs (e.g., any user ID).
- **Functionality**: Matchers: `any()`, `anyString()`, `eq(value)`, `isA(Class)`. All arguments must use matchers if one does.
- **Pro way**: Use for generic cases; prefer exact matches for precision.

**Example 5: Using Matchers**

```java
@Test
@DisplayName("Should save user with any name")
void testSaveUserWithMatcher() throws Exception {
    // Given
    when(userService.saveUser(Mockito.anyString())).thenReturn(new User(1L, "Any Name"));

    // When & Then
    mockMvc.perform(post("/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(new User(null, "Test Name"))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(1L));

    Mockito.verify(userService).saveUser(Mockito.anyString());
}
```

- **Takeaway**: Matchers simplify tests with variable inputs.

## Step 6: Spying in Spring Boot (Advanced)

### What is Spying?

A spy wraps a real object, calling real methods unless stubbed.

- **What it does**: Allows partial mocking of Spring components.
- **Why use it in Spring Boot**: For legacy code or complex services where full mocking is impractical.
- **Functionality**: Use `Mockito.spy(realObject)`. Stub with `when()` or `doReturn()`.
- **Pro way**: Prefer mocks; use spies sparingly to avoid hidden issues.

**Example 6: Spying a Service**  
Create an interface and implementation:

```java
public interface UserService {
    String getUserNameById(Long id);
    User saveUser(String name);
}
```

```java
@Service
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;

    public UserServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public String getUserNameById(Long id) {
        return userRepository.findById(id).map(User::getName).orElse("Real Default");
    }

    @Override
    public User saveUser(String name) {
        return userRepository.save(new User(null, name));
    }
}
```

Test with spy:

```java
@Test
@DisplayName("Should use spy for partial mocking")
void testSpyService() {
    // Given
    UserRepository mockRepo = Mockito.mock(UserRepository.class);
    UserService realService = new UserServiceImpl(mockRepo);
    UserService spyService = Mockito.spy(realService);

    when(spyService.getUserNameById(1L)).thenReturn("Mocked Name");

    // When & Then
    assertEquals("Mocked Name", spyService.getUserNameById(1L));
    assertEquals("Real Default", spyService.getUserNameById(2L));
}
```

- **Takeaway**: Spies blend real and mocked behavior.

## Step 7: Testing Exception Handling with Mockito and JUnit 5

### Why Test Exceptions?

Spring Boot uses `@ControllerAdvice` for exception handling. Mockito and JUnit 5 test these scenarios.

**Example 7: Testing Exception Handling**  
Add a global exception handler:

```java
package com.example.demo.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;

@ControllerAdvice
public class GlobalExceptionHandler {

    public static class ErrorResponse {
        private String errorCode;
        private String message;

        public ErrorResponse(String errorCode, String message) {
            this.errorCode = errorCode;
            this.message = message;
        }

        public String getErrorCode() { return errorCode; }
        public String getMessage() { return message; }
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArgumentException(IllegalArgumentException ex, WebRequest request) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ErrorResponse("INVALID_INPUT", ex.getMessage()));
    }
}
```

Test:

```java
@Test
@DisplayName("Should handle user not found exception")
void testGetUserNameNotFound() throws Exception {
    // Given
    mockMvc = MockMvcBuilders.standaloneSetup(userController)
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    when(userService.getUserNameById(2L)).thenThrow(new IllegalArgumentException("User not found"));

    // When & Then
    mockMvc.perform(get("/users/2")
            .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("INVALID_INPUT"))
            .andExpect(jsonPath("$.message").value("User not found"));
}
```

- **Takeaway**: Mockito stubs exceptions; JUnit 5 verifies responses.

## Step 8: Advanced Features - Argument Captors and BDD

### Argument Captors

- **What it does**: Captures arguments passed to mocks for assertions.
- **Why use it**: Verifies complex objects (e.g., `User` saved to repository).
- **Functionality**: Use `@Captor ArgumentCaptor<Type> captor`, then `verify(mock).method(captor.capture())`.
- **Pro way**: For dynamic or complex argument verification.

**Example 8: Argument Captor**

```java
import org.mockito.ArgumentCaptor;

@Test
@DisplayName("Should capture user name in save operation")
void testCreateUserCaptor() throws Exception {
    // Given
    ArgumentCaptor<String> nameCaptor = ArgumentCaptor.forClass(String.class);
    when(userService.saveUser(Mockito.anyString())).thenReturn(new User(1L, "Jane Doe"));

    // When
    mockMvc.perform(post("/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(new User(null, "Jane Doe"))))
            .andExpect(status().isOk());

    // Then
    Mockito.verify(userService).saveUser(nameCaptor.capture());
    assertEquals("Jane Doe", nameCaptor.getValue());
}
```

### BDD Style

- **What it does**: Uses `BDDMockito` for readable syntax (`given(...).willReturn(...)`).
- **Why use it**: Improves test clarity, aligning with BDD practices.
- **Functionality**: Import `BDDMockito`; use `given()`, `willReturn()`, `willThrow()`.
- **Pro way**: Use for teams following BDD; structure tests as given-when-then.

**Example 9: BDD Style**

```java
import static org.mockito.BDDMockito.given;

@Test
@DisplayName("Should return user name in BDD style")
void testBDDGetUserName() throws Exception {
    // Given
    given(userService.getUserNameById(1L)).willReturn("John Doe");

    // When & Then
    mockMvc.perform(get("/users/1")
            .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").value("John Doe"));
}
```

## Step 9: Production-Level Best Practices

### Using @MockBean for Integration Tests

- **What it does**: `@MockBean` (from `spring-boot-test`) mocks Spring beans in a Spring context.
- **Why use it**: For integration tests with `@SpringBootTest`.
- **Pro way**: Use for testing full Spring wiring; Mockito for unit tests.

**Example 10: Using @MockBean**

```java
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;

@SpringBootTest
@AutoConfigureMockMvc
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Test
    @DisplayName("Should integrate with Spring context using MockBean")
    void testGetUserNameWithMockBean() throws Exception {
        // Given
        when(userService.getUserNameById(1L)).thenReturn("John Doe");

        // When & Then
        mockMvc.perform(get("/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value("John Doe"));
    }
}
```

### Best Practices

1. **Mock Minimally**: Mock only direct dependencies (e.g., repository in service tests).
2. **Use @MockBean for Integration**: When testing Spring context.
3. **JUnit 5 Structure**: Use `@BeforeEach`, `@DisplayName`, given-when-then.
4. **Avoid Over-Mocking**: Don’t mock simple objects (e.g., `String`).
5. **Test Exceptions**: Use Mockito to stub errors; JUnit 5 to verify responses.
6. **CI/CD**: Run tests in builds; use JaCoCo for coverage.
7. **BDD Style**: For readability in large teams.
8. **Clean Tests**: Use annotations, clear naming, and avoid redundant verifications.

## Conclusion

You’ve mastered testing Spring Boot apps with Mockito and JUnit 5, from basic service tests to advanced controller and exception handling. Practice by expanding the user API with more endpoints and tests. This combination ensures fast, reliable, and maintainable tests!

### Tags : [[0 - Spring Framework]]