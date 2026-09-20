
`@MockitoBean` is a **Spring Boot Test** annotation (from `org.springframework.boot.test.mock.mockito`) that combines the behavior of **Mockito's `@Mock`** and **Spring's `@Autowired`** for integration testing.

### Purpose
It creates a **Mockito mock** of a Spring bean and **registers it in the Spring ApplicationContext**, so it can be **injected** into the class under test (just like a real bean).

---

### When to Use
Use `@MockitoBean` when:
- You're writing **integration tests** with `@SpringBootTest` (or `@DataJpaTest`, etc.).
- You want to **mock a dependency** (e.g., a service, repository, or external client) **without loading the real bean**.
- The class under test uses `@Autowired` to inject that dependency.

---

### Example

```java
@SpringBootTest
class UserServiceTest {

    @Autowired
    private UserService userService;  // Class under test

    @MockitoBean
    private UserRepository userRepository;  // This will be a mock

    @Test
    void shouldReturnUsersWhenRepositoryReturnsData() {
        // Arrange
        when(userRepository.findAll()).thenReturn(List.of(
            new User(1L, "Alice"),
            new User(2L, "Bob")
        ));

        // Act
        List<User> users = userService.getAllUsers();

        // Assert
        assertThat(users).hasSize(2);
        verify(userRepository).findAll();
    }
}
```

---

### Key Points

| Feature | Details |
|--------|--------|
| **Creates** | A Mockito mock |
| **Registers** | In Spring's `ApplicationContext` |
| **Injects** | Via `@Autowired` into other beans |
| **Replaces** | The real bean in the context |
| **Scope** | Test-specific (per test class) |

---

### `@MockitoBean` vs `@Mock`

| Annotation | Used With | Context | Injection |
|-----------|----------|--------|----------|
| `@Mock` | `@ExtendWith(MockitoExtension.class)` | Pure Mockito (no Spring) | Manual or `@InjectMocks` |
| `@MockitoBean` | `@SpringBootTest` | Spring-managed | Automatic via Spring DI |

Use `@Mock` for **unit tests**, `@MockitoBean` for **Spring integration tests**.

---

### Common Pitfalls

1. **Forgetting to stub behavior**  
   → Mock returns `null` → `NullPointerException`  
   ```java
   when(userRepository.findById(1L)).thenReturn(Optional.of(new User()));
   ```

2. **Using with `@WebMvcTest` or `@DataJpaTest`**  
   → Works, but only mocks beans in the sliced context.

3. **Multiple beans of same type**  
   → Use `@Qualifier` or ensure only one mock is needed.

---

### Maven/Gradle Dependency

Make sure you have:
```xml
<!-- Maven -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

This includes Mockito and Spring Test.


##### Tags : [[0 - Spring Framework]]