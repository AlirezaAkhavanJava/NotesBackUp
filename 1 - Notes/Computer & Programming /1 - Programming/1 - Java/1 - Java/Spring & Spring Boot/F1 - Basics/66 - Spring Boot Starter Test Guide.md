Date : 2025-09-07


This guide covers Spring Boot Starter Test, explaining how to set up and use it for testing your Spring Boot applications, from basics to advanced.


---

## Introduction

Spring Boot Starter Test provides a comprehensive testing setup for Spring Boot applications. It includes popular frameworks like JUnit, Mockito, and Spring TestContext framework to help you write unit, integration, and web tests.

---

## Setting Up Dependencies

**Maven:**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

**Gradle:**

```gradle
dependencies {
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}
```

- `scope/test` ensures dependencies are only used during testing.
    

---

## Testing Frameworks Included

- **JUnit 5 (Jupiter)**: Core framework for writing unit and integration tests.
    
- **Spring TestContext**: Provides Spring context for tests.
    
- **Mockito**: For mocking dependencies.
    
- **AssertJ**: Fluent assertion library.
    
- **Hamcrest**: Matcher library.
    
- **JSONassert**: For JSON comparison in tests.
    
- **Spring Boot Test Utilities**: `@SpringBootTest`, `@WebMvcTest`, etc.
    

---

## Unit Testing

Unit tests check individual components in isolation.

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {
    @Test
    void testAddition() {
        Calculator calc = new Calculator();
        assertEquals(5, calc.add(2, 3));
    }
}
```

- No Spring context needed.
    
- Fast and lightweight.
    

---

## Integration Testing

Integration tests check multiple components together, often with Spring context.

```java
import org.springframework.boot.test.context.SpringBootTest;
import org.junit.jupiter.api.Test;

@SpringBootTest
class UserServiceIntegrationTest {

    @Autowired
    private UserService userService;

    @Test
    void testCreateUser() {
        User user = new User("John", "john@example.com");
        User saved = userService.createUser(user);
        assertNotNull(saved.getId());
    }
}
```

- `@SpringBootTest` loads the full application context.
    
- Slower than unit tests but ensures components work together.
    

---

## Mocking with Mockito

- Use `@Mock` to create mock objects.
    
- Use `@InjectMocks` to inject mocks into the class under test.
    

```java
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import static org.mockito.Mockito.*;

class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testCreateUser() {
        User user = new User("John", "john@example.com");
        when(userRepository.save(user)).thenReturn(user);

        User saved = userService.createUser(user);
        assertEquals("John", saved.getName());
    }
}
```

- Use `when()` and `thenReturn()` to simulate behavior.
    
- Verify interactions with `verify()`.
    

---

## Web Layer Testing

Test controllers without starting the server using `@WebMvcTest`.

```java
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testGetUser() throws Exception {
        mockMvc.perform(get("/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("John"));
    }
}
```

- MockMvc simulates HTTP requests.
    
- Combine with `@MockBean` to mock service dependencies.
    

---

## Data Layer Testing

Test repositories using `@DataJpaTest`.

```java
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.beans.factory.annotation.Autowired;

@DataJpaTest
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void testFindByEmail() {
        User user = new User("John", "john@example.com");
        userRepository.save(user);

        User found = userRepository.findByEmail("john@example.com").orElse(null);
        assertNotNull(found);
    }
}
```

- Uses in-memory database (H2) by default.
    
- Focuses only on JPA components.
    

---

## Advanced Testing Features

1. **Profiles for Testing**: Use `application-test.properties` with `@ActiveProfiles("test")`.
    
2. **Transactional Tests**: Roll back after each test using `@Transactional`.
    
3. **Test Slices**: Focus on layers (`@WebMvcTest`, `@DataJpaTest`, `@RestClientTest`).
    
4. **Parameterized Tests**: Run same test with different inputs using `@ParameterizedTest`.
    
5. **Spring Boot Test Utilities**: `TestRestTemplate`, `MockMvc`, `TestEntityManager`.
    

---

## Best Practices

- Write unit tests for business logic.
    
- Write integration tests for Spring components.
    
- Use mocking to isolate dependencies.
    
- Prefer `@DataJpaTest` for repositories.
    
- Keep tests independent and repeatable.
    
- Name tests clearly indicating purpose.
    
- Rollback database changes to maintain clean state.
    

---

This guide covers Spring Boot Starter Test in depth, from setting up dependencies to unit, integration, web, and data layer testing, along with advanced features and best practices.
##### *Tags : [[0 - Spring Framework]]