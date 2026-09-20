


---

# 🧠 Full Developer Note — Mockito, Spring, Lombok & Production Coding Mastery (2025 Edition)

---

## 🏗️ 1. Mockito Annotations — Modernized for Spring Boot 3.4+ / Framework 6.2+

### ⚙️ What Changed?

Spring Boot 3.4 deprecated:

```java
@MockBean   ❌
@SpyBean    ❌
```

and replaced them with:

```java
@MockitoBean    ✅
@MockitoSpyBean ✅
```

Now, Mockito integration lives **inside Spring Framework**, not Boot — cleaner, more maintainable, and forward-compatible.

---

### 🧩 `@MockitoBean`

**Purpose:** Replace a real Spring bean with a Mockito mock inside your test context.

**Example:**

```java
@SpringBootTest
class StudentServiceTest {

    @MockitoBean
    private StudentRepository studentRepository; // Mock replaces the real bean

    @Autowired
    private StudentService studentService;

    @Test
    void testFindStudent() {
        when(studentRepository.findById(1L))
            .thenReturn(Optional.of(Student.builder().id(1L).name("Ethan").build()));

        Student s = studentService.getById(1L);
        assertEquals("Ethan", s.getName());
    }
}
```

✅ **Use When:** You’re running an integration test with a Spring context.  
🧠 **Replaces:** The old `@MockBean`.  
📦 **Scope:** Inside the Spring ApplicationContext.

---

### 🧩 `@MockitoSpyBean`

**Purpose:** Wraps a **real bean** with a **spy** — real logic executes unless you stub specific methods.

**Example:**

```java
@SpringBootTest
class StudentServiceSpyTest {

    @MockitoSpyBean
    private StudentService studentService;

    @Test
    void testSpy() {
        doReturn(Student.builder().id(1L).name("Mocked").build())
            .when(studentService).getById(1L);

        Student s = studentService.getById(1L);
        assertEquals("Mocked", s.getName());
        verify(studentService).getById(1L);
    }
}
```

✅ Best for **partial mocks** or **behavior verification**.  
🚫 Avoid spying when you can test behavior more directly (less brittle).

---

### 🧩 `@Mock`

**Purpose:** Create a mock **outside** of Spring (plain Mockito unit test).

**Example:**

```java
@ExtendWith(MockitoExtension.class)
class StudentServiceUnitTest {

    @Mock
    private StudentRepository repo;

    @InjectMocks
    private StudentService service;

    @Test
    void testCount() {
        when(repo.count()).thenReturn(5L);
        assertEquals(5, service.countStudents());
    }
}
```

✅ Fastest tests.  
✅ No Spring context — pure unit tests.  
💡 Combine with `@InjectMocks`.

---

### 🧩 `@InjectMocks`

Injects all `@Mock` fields into the target class.

```java
@Mock
private StudentRepository repo;

@InjectMocks
private StudentService service;
```

Mockito will construct `service` and inject the `repo` mock into it.

---

### 🧩 `@Spy`

Wraps a real object with a Mockito spy. Calls real methods unless stubbed.

```java
@Spy
private StudentService realService = new StudentService();

@Test
void testSpy() {
    doReturn("Mocked").when(realService).getName();
}
```

---

### 🧩 `@Captor`

Captures arguments passed to mock methods.

```java
@Captor
private ArgumentCaptor<Long> idCaptor;

@Test
void testCaptor() {
    service.deleteById(42L);
    verify(repo).deleteById(idCaptor.capture());
    assertEquals(42L, idCaptor.getValue());
}
```

---

### 🧩 `@ExtendWith(MockitoExtension.class)`

Activates Mockito for JUnit 5.

```java
@ExtendWith(MockitoExtension.class)
class MyTest { ... }
```

---

### 🧩 `@MockitoSettings`

Customizes global mock behavior.

```java
@MockitoSettings(strictness = Strictness.LENIENT)
class MyTest { ... }
```

---

### 🧾 Quick Summary

|Annotation|Description|Scope|
|---|---|---|
|`@MockitoBean`|Mock Spring bean in context|Spring Boot 3.4+|
|`@MockitoSpyBean`|Spy Spring bean in context|Spring Boot 3.4+|
|`@Mock`|Mock object (no Spring)|Unit test|
|`@InjectMocks`|Inject mocks into target|Unit test|
|`@Spy`|Partial mock|Unit test|
|`@Captor`|Capture method arguments|Unit test|
|`@ExtendWith(MockitoExtension.class)`|Enable Mockito|JUnit 5|
|`@MockitoSettings`|Tweak mock behavior|Optional|

---

## 🧠 2. Lombok for Clean & Professional Code

Lombok eliminates boilerplate like getters, setters, constructors, and builders — making your entities and DTOs cleaner.

---

### 🧩 `@Builder`

**Purpose:** Automatically generates a builder pattern for your class.

**Example:**

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Student {
    private Long id;
    private String name;
    private String email;
}
```

**Usage:**

```java
Student s = Student.builder()
        .id(1L)
        .name("Ethan")
        .email("ethan@mail.com")
        .build();
```

✅ Makes object creation clean and readable  
✅ Great for **test data** and **immutable DTOs**  
✅ Works perfectly with Mockito stubs

---

### 🧩 `@Data`

Generates:

- Getters / Setters
    
- `equals()`, `hashCode()`, `toString()`
    
- Required constructors
    

Perfect for **POJOs**, **entities**, and **DTOs**.

```java
@Data
public class Student {
    private Long id;
    private String name;
}
```

---

### 🧩 `@AllArgsConstructor` / `@NoArgsConstructor`

- `@AllArgsConstructor` → constructor with all fields.
    
- `@NoArgsConstructor` → empty constructor (needed by JPA).
    

Use both together on entities.

---

### 🧩 `@Getter` / `@Setter`

Use when you only want half of what `@Data` provides (e.g. readonly objects).

```java
@Getter
@Setter
public class StudentDTO {
    private String name;
    private String email;
}
```

---

### 🧩 `@Value`

Immutable version of `@Data`.  
All fields are `private final`, no setters, class is `final`.

```java
@Value
@Builder
public class StudentDTO {
    Long id;
    String name;
}
```

Perfect for **API responses** or **records**.

---

### 🧾 Lombok Summary

|Annotation|Description|Best For|
|---|---|---|
|`@Data`|All getters/setters + equals/hashCode/toString|Entities, DTOs|
|`@Builder`|Fluent builder pattern|Object creation & testing|
|`@Getter` / `@Setter`|Custom control over access|DTOs|
|`@AllArgsConstructor` / `@NoArgsConstructor`|Constructors|Entities|
|`@Value`|Immutable data class|API responses, records|

---

## 🧩 3. Production-Level Coding Habits (Team & Industry Standard)

These are the habits that move you from “it works” → “it’s production-ready”.

---

### 🔸 Code Readability > Cleverness

Readable code saves hours in debugging and onboarding.

```java
// ❌ Bad
if(x==1){y=z+1;}

// ✅ Good
if (studentCount == 1) {
    totalScore = score + 1;
}
```

---

### 🔸 Follow Layered Architecture

**Controller → Service → Repository**

Keep logic separated:

- **Controller:** handles HTTP requests
    
- **Service:** business logic
    
- **Repository:** data access
    

This makes testing and scaling far easier.

---

### 🔸 Use Proper Exception Handling

Global exception handling pattern:

```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorMessage> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorMessage(ex.getMessage(), HttpStatus.NOT_FOUND));
    }
}
```

---

### 🔸 Write Meaningful Tests

✅ Don’t just check if “it runs” — check correctness.  
✅ Name your tests descriptively.

```java
@Test
void shouldReturnStudentWhenIdExists() { ... }
```

---

### 🔸 Use Assertions Effectively

```java
assertEquals("Ethan", result.getName());
assertNotNull(result);
assertThrows(ResourceNotFoundException.class, () -> service.getById(999L));
```

---

### 🔸 Prefer Constructor Injection

It’s cleaner, immutable, and test-friendly.

```java
@Service
@RequiredArgsConstructor
public class StudentService {
    private final StudentRepository repository;
}
```

---

### 🔸 Turn Off `spring.jpa.open-in-view` in Prod

In `application.properties`:

```properties
spring.jpa.open-in-view=false
```

It avoids lazy-loading leaks and performance issues.

---

### 🔸 Use DTOs Instead of Entities in Controllers

Never expose entities directly.

```java
public record StudentDTO(Long id, String name) {}
```

---

### 🔸 Logging Best Practice

Use Lombok’s logger:

```java
@Slf4j
@Service
public class StudentService {
    public void save(Student s) {
        log.info("Saving student {}", s.getName());
    }
}
```

---

### 🔸 Use Meaningful Package Structure

```
com.arcade.bootapplication
├── controller
├── service
├── repository
├── entity
├── dto
├── exception
└── aspect
```

Clean, discoverable, scalable.

---

## 🧩 4. Advanced Testing Mindset

- 🧪 **Unit tests:** isolate one class → use `@Mock`
    
- 🧩 **Integration tests:** load Spring context → use `@MockitoBean`
    
- 🌐 **End-to-End tests:** test real app flow → use `@SpringBootTest(webEnvironment = RANDOM_PORT)`
    

Always aim for:

- ✅ Fast feedback
    
- ✅ Deterministic results
    
- ✅ Clear naming
    
- ✅ Coverage on logic, not frameworks
    

---

## 🧩 5. Developer Mindset for Production-Level Code

|Mindset|Description|
|---|---|
|💭 **Think maintainability**|Code should be readable months later.|
|🧱 **Design for testing**|Write logic that’s easy to mock, isolate, and verify.|
|📏 **Follow clean code principles**|Single Responsibility, DRY, meaningful naming.|
|🧩 **Embrace dependency injection**|Don’t “new” your dependencies manually.|
|🚀 **Fail fast, log clearly**|Don’t hide exceptions — handle and explain them.|
|🧮 **Measure performance**|Profile queries and endpoints before scaling.|
|🧾 **Document wisely**|Use JavaDoc or Markdown for key modules — future you will thank you.|

---

## 🧩 6. Pro-Level Combo Example

```java
@Slf4j
@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository repository;

    public Student getById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found: " + id));
    }

    public Student save(Student s) {
        log.info("Saving student: {}", s.getName());
        return repository.save(s);
    }
}
```

**Entity:**

```java
@Entity
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Student {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String email;
}
```

**Test:**

```java
@SpringBootTest
class StudentServiceTest {

    @MockitoBean
    private StudentRepository repo;

    @Autowired
    private StudentService service;

    @Test
    void shouldReturnStudentById() {
        Student s = Student.builder().id(1L).name("Ethan").build();
        when(repo.findById(1L)).thenReturn(Optional.of(s));

        Student result = service.getById(1L);
        assertEquals("Ethan", result.getName());
    }
}
```

Clean. Testable. Production-level.

---

# 🏁 Final Takeaways

✅ Use **`@MockitoBean`** and **`@MockitoSpyBean`** — future-proof your tests.  
✅ Use **Lombok** (`@Builder`, `@Data`, etc.) to keep code readable.  
✅ Write **layered**, **testable**, **clear** logic.  
✅ Always aim for **readability**, **consistency**, and **clean design** — not just working code.  
✅ Remember: _Professional code isn’t clever — it’s maintainable._

---


### Tags : [[0 - Spring Framework]]