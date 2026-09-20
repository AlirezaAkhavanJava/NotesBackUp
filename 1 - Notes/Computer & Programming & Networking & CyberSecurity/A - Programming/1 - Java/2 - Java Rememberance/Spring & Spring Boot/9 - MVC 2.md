
## What is MVC in Spring Boot?

**Model-View-Controller** separates responsibilities:

- **Model** — your data (entities, DTOs)
- **View** — what gets rendered/returned to the client
- **Controller** — receives HTTP requests, coordinates between Model and View

In **modern Spring Boot**, the "View" is almost never server-rendered HTML anymore (that was the old JSP/Thymeleaf-heavy style). The modern default is building a **REST API** that returns **JSON**, consumed by a separate frontend (React, Angular, mobile app, etc.). So "View" today usually just means "the JSON representation returned."

## The modern layered architecture

```
Client (browser/mobile/frontend app)
        ↓ HTTP request
Controller layer   (@RestController) — handles HTTP, delegates to service
        ↓
Service layer      (@Service) — business logic
        ↓
Repository layer   (@Repository) — data access
        ↓
Database
```

## 1. The Controller (`@RestController`)

Modern Spring Boot uses `@RestController` (not `@Controller`), which combines `@Controller` + `@ResponseBody` — meaning every method's return value is automatically serialized to JSON, instead of resolved as a view name.

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) { // constructor injection
        this.userService = userService;
    }

    @GetMapping
    public List<UserDto> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long id) {
        UserDto user = userService.getUser(id);
        return ResponseEntity.ok(user);
    }

    @PostMapping
    public ResponseEntity<UserDto> createUser(@Valid @RequestBody CreateUserRequest request) {
        UserDto created = userService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserDto> updateUser(@PathVariable Long id, @Valid @RequestBody UpdateUserRequest request) {
        return ResponseEntity.ok(userService.updateUser(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
```

Key modern conventions here:

- `@RequestMapping("/api/users")` at class level — shared base path
- `@GetMapping`, `@PostMapping`, etc. instead of the older `@RequestMapping(method = RequestMethod.GET)`
- `ResponseEntity<T>` — gives you control over status code + headers + body, not just the body
- `@RequestBody` — deserializes incoming JSON into a Java object
- `@Valid` — triggers Bean Validation (checks constraints like `@NotNull`, `@Size` on the DTO)
- `@PathVariable` — extracts values from the URL path

## 2. DTOs, not entities, in the controller — a modern best practice

Old-style tutorials often return the JPA `@Entity` directly from controllers. **Modern practice avoids this** because:

- It leaks database structure to the API
- Can cause lazy-loading serialization errors
- Couples your API contract to your DB schema

Instead, use **DTOs (Data Transfer Objects)** — and in modern Java, these are often **records** (Java 16+), which are perfect for this since they're immutable and concise:

```java
public record UserDto(Long id, String name, String email) {}

public record CreateUserRequest(
    @NotBlank String name,
    @Email String email
) {}
```

## 3. The Service layer — business logic, mapping entity ↔ DTO

```java
@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public List<UserDto> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(u -> new UserDto(u.getId(), u.getName(), u.getEmail()))
                .toList();
    }

    public UserDto getUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException(id));
        return new UserDto(user.getId(), user.getName(), user.getEmail());
    }

    public UserDto createUser(CreateUserRequest request) {
        User user = new User(request.name(), request.email());
        User saved = userRepository.save(user);
        return new UserDto(saved.getId(), saved.getName(), saved.getEmail());
    }
}
```

## 4. The Repository — Spring Data JPA (modern, minimal-code data access)

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email); // Spring generates the query from the method name
}
```

You don't write implementations — Spring Data generates them at runtime (this itself is done via a dynamic **proxy**, same mechanism as AOP).

## 5. The Entity (Model)

```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String email;

    protected User() {} // required by JPA

    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    // getters/setters
}
```

## 6. Centralized error handling — `@RestControllerAdvice`

Modern Spring Boot doesn't scatter try/catch in every controller. Instead:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(UserNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse(ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + ": " + e.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return ResponseEntity.badRequest().body(new ErrorResponse(message));
    }
}

public record ErrorResponse(String message) {}
```

This is itself a form of AOP-like cross-cutting concern handling — one place for all controllers' exceptions, instead of duplicating error logic everywhere.

## Summary: what makes this "the modern way"

|Old style|Modern style|
|---|---|
|`@Controller` + return view names (JSP/Thymeleaf)|`@RestController` returning JSON|
|Field injection (`@Autowired` on fields)|Constructor injection|
|Return JPA entities directly|Return DTOs (often `record`s)|
|Manual `if/else` validation|`@Valid` + Bean Validation annotations|
|try/catch scattered everywhere|`@RestControllerAdvice` centralizing error handling|
|`@RequestMapping(method=...)`|`@GetMapping`/`@PostMapping`/etc.|
|Plain classes for return values|`record` types (immutable, concise)|
|XML config|Java config + annotations + auto-configuration|

Every piece here — `@RestController`, `@Service`, `@Repository` — is a Spring **bean**, created and wired by the **IoC container** we discussed, and some (like your `UserRepository` interface) are backed by dynamically generated **proxies**, same mechanism as AOP.


[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]
[[Java]]

