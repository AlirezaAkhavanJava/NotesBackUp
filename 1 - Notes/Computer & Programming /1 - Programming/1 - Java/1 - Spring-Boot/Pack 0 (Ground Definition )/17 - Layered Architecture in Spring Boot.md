

A layered architecture splits your application into stacked parts, where each part has one job and only talks to its neighbor. In a typical Spring Boot back-end, the **controller** handles HTTP, the **service** holds business rules, and the **repository** talks to the database. Each layer can change without rewriting the others.

Without layers, a single class ends up parsing requests, applying rules, and writing SQL. That code is hard to test, hard to read, and hard to change. Layers fix this by giving every kind of change one home, so a new validation rule, a new database, or a new JSON format each touches only one layer.

The code below targets current Spring Boot. Spring Boot 4 is built on Spring Framework 7, with Jakarta EE 11 as the baseline, and the old `javax.*` packages are no longer supported, so every import here uses `jakarta.*`.

## The flow, in both directions

```
HTTP request → Controller → Service → Repository → Database
HTTP response ← Controller ← Service ← Repository ← Database
```

The rule is that **dependencies point downward only**. A controller may call a service, and a service may call a repository. A repository never calls a service, and a service never knows what HTTP is.

## Layer 1: Persistence (repository)

**The problem:** storing and loading objects with raw JDBC means writing lots of repetitive SQL and result-mapping code.

**The solution:** a few pieces stack on each other.

- **JPA** is a specification that describes how objects map to tables.
- **Hibernate** is the implementation that actually does the work.
- **Spring Data JPA** sits on top and generates repository implementations from interfaces, so you write almost no data-access code.

```java
@Entity
@Table(name = "users")                       // "user" is a reserved word in many databases
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true) // enforced by the database, not just by your code
    private String name;

    protected User() {}                      // JPA requires a no-arg constructor

    public User(String name) { this.name = name; }

    public Long getId() { return id; }
    public String getName() { return name; }
}

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByName(String name);  // query generated from the method name
    boolean existsByName(String name);
}
```

Two things matter here. The `unique` constraint is what makes `findByName` safe to return an `Optional`. Without it, two users with the same name would make that method throw an exception. You also don't need `@Repository` on a Spring Data interface, because Spring detects it automatically.

## Layer 2: Service (business logic)

**The problem:** rules like "names must be unique" don't belong in a controller (they'd be duplicated for every entry point) or in a repository (it should only store data).

**The solution:** the service layer owns the rules and the **transaction boundaries**. `@Transactional` makes everything in a method succeed or fail as one unit. `readOnly = true` tells Spring and Hibernate that no writes will happen, which allows some optimizations.

```java
@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {  // constructor injection
        this.userRepository = userRepository;
    }

    @Transactional
    public User createUser(String name) {
        if (userRepository.existsByName(name)) {
            throw new UserAlreadyExistsException(name);
        }
        return userRepository.save(new User(name));
    }

    @Transactional(readOnly = true)
    public User getUser(String name) {
        return userRepository.findByName(name)
                .orElseThrow(() -> new UserNotFoundException(name));
    }
}
```

The service throws **meaningful domain exceptions** and knows nothing about HTTP status codes. It also uses **constructor injection**, which Spring prefers because the dependency is explicit, can be `final`, and is easy to pass in during unit tests.

## Layer 3: Presentation (controller)

**The problem:** the outside world speaks HTTP and JSON, while your inside world speaks entities and exceptions.

**The solution:** the controller translates between the two, and it does nothing else. It uses **DTOs** (Data Transfer Objects) so the API shape is separate from the database shape. Returning an entity directly can leak internal fields, tie your API to your table design, and cause serialization trouble with lazy-loaded relations.

```java
public record CreateUserRequest(@NotBlank String name) {}

public record UserResponse(Long id, String name) {
    static UserResponse from(User u) { return new UserResponse(u.getId(), u.getName()); }
}

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) { this.userService = userService; }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse create(@Valid @RequestBody CreateUserRequest request) {
        return UserResponse.from(userService.createUser(request.name()));
    }

    @GetMapping("/{name}")
    public UserResponse get(@PathVariable String name) {
        return UserResponse.from(userService.getUser(name));
    }
}
```

`@Valid` triggers the `@NotBlank` check and needs the validation starter on your classpath.

## Turning exceptions into HTTP responses

Your service throws domain exceptions, so something must map them to status codes. One `@RestControllerAdvice` class does this for the whole app, using `ProblemDetail`, Spring's built-in standard error format.

```java
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    ProblemDetail notFound(UserNotFoundException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    @ExceptionHandler(UserAlreadyExistsException.class)
    ProblemDetail conflict(UserAlreadyExistsException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage());
    }
}
```

The two exception classes are simply `class UserNotFoundException extends RuntimeException` and the same for `UserAlreadyExistsException`, each with a constructor that builds a message from the name.

## Related concepts worth knowing

- **Testing per layer**: `@DataJpaTest` tests repositories, `@WebMvcTest` tests controllers with a mocked service, and plain unit tests with a mocked repository cover the service.
- **Package structure**: you can group by layer (`controller/`, `service/`, `repository/`) or by feature (`user/`, `order/`). Feature-based grouping tends to scale better in larger apps.
- **Hexagonal / clean architecture**: stricter relatives of layering, worth learning once your domain logic grows.




[[Spring Framework]]