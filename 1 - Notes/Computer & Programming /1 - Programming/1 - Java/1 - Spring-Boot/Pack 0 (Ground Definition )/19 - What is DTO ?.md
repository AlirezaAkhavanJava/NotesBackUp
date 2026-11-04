

A **DTO (Data Transfer Object)** is a plain object whose only job is to carry data from one place to another. In a Spring Boot app, that usually means between your API clients and your controllers.

It has fields, maybe some validation annotations, and nothing else: no business logic, no database knowledge. Think of it as a shipping box. It holds exactly what needs to travel, in the shape the receiver expects.

The rule of thumb: **entities stay inside** (service and persistence layers), **DTOs live at the edge** (controller in, controller out).

## Why not just return the entity?

It's tempting, because it works in a demo. Here is what goes wrong in a real project:

- **Leaking data.** If `User` has `passwordHash`, returning the entity exposes it unless you remember to hide it everywhere.
- **API tied to your database.** Rename a column and your public JSON changes, so clients break.
- **Lazy-loading errors.** Jackson touches a lazy collection while serializing and you get `LazyInitializationException` or a pile of extra queries.
- **Infinite recursion.** `User → orders → user → orders …` and serialization never ends.
- **Over-posting (mass assignment).** If you accept an entity as the request body, a client can send fields you never meant to be settable, like `id` or `role`.
- **One shape doesn't fit all.** Creating a user needs a password, showing one must not include it. An entity has one shape; DTOs let you have as many as you need.

## Writing DTOs with records

Since Java 16, **records** are the natural fit. They are immutable, short, and generate `equals`, `hashCode` and `toString` for you.

```java
public record CreateUserRequest(
        @NotBlank @Size(max = 100) String name,
        @Email @NotBlank String email,
        @NotBlank @Size(min = 8) String password) {}

public record UpdateUserRequest(
        @NotBlank @Size(max = 100) String name,
        @Email @NotBlank String email) {}

public record UserResponse(Long id, String name, String email) {}
```

Look at how the shapes differ: creating needs a password, updating doesn't allow changing it, and the response never contains it. That's the whole point of DTOs.

**Watch out:** the generated `toString()` prints every field, so logging a `CreateUserRequest` writes the plaintext password into your logs. Override it:

```java
public record CreateUserRequest(
        @NotBlank @Size(max = 100) String name,
        @Email @NotBlank String email,
        @NotBlank @Size(min = 8) String password) {

    @Override
    public String toString() {
        return "CreateUserRequest[name=%s, email=%s, password=***]".formatted(name, email);
    }
}
```

## How a request flows through the app

**Controller:** receives the request DTO, validates it, returns a response DTO.

```java
@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(userService.create(request));
    }

    @GetMapping("/{id}")
    public UserResponse get(@PathVariable Long id) {
        return userService.get(id);
    }
}
```

`@Valid` is what triggers the annotations on the record. Without it, `@NotBlank` and friends do nothing.

**Service:** converts between DTOs and entities.

```java
@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public UserResponse create(CreateUserRequest request) {
        User user = new User(request.name(), request.email(),
                             passwordEncoder.encode(request.password()));
        return toResponse(userRepository.save(user));
    }

    @Transactional(readOnly = true)
    public UserResponse get(Long id) {
        return userRepository.findById(id)
                .map(this::toResponse)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
    }

    private UserResponse toResponse(User u) {
        return new UserResponse(u.getId(), u.getName(), u.getEmail());
    }
}
```

Two things to notice:

1. **The conversion happens inside the transactional method.** Any lazy data you need is still loadable there. By the time the controller gets the result, it's a plain object with no database connection behind it.
2. **A missing user returns 404, not 500.** A bare `orElseThrow()` throws `NoSuchElementException`, which Spring turns into a 500. A missing record is the client's problem, so say so with a proper status.

## Mapping: by hand or with a library

Writing `toResponse` yourself is perfectly fine for small apps, and it's easy to read and debug. When you have many DTOs, use a mapper:

- **MapStruct** generates the mapping code at compile time. It's fast, type-safe, and the most common choice in Spring projects. It supports records from version 1.4.
- **ModelMapper** uses reflection. It's quicker to start with, but mistakes only show up at runtime.

```java
@Mapper(componentModel = "spring")
public interface UserMapper {
    UserResponse toResponse(User user);
}
```

## Projections: DTOs straight from the database

Sometimes you don't need the entity at all. Spring Data can select only the columns you need directly into a DTO. That skips loading the full entity and is a good fix for the N+1 problem on read-only list screens.

The simplest way is a derived query. Spring Data sees that the return type is a class (a record qualifies) and selects only its fields:

```java
public interface UserRepository extends JpaRepository<User, Long> {
    List<UserResponse> findAllBy();
}
```

Or write it yourself with JPQL:

```java
@Query("select new com.example.UserResponse(u.id, u.name, u.email) from User u")
List<UserResponse> findSummaries();
```

The JPQL version needs the full package name and the exact constructor order. A typo there only fails at startup or runtime, so prefer the derived query when it's enough.

## Common mistakes

- **One DTO per tiny variation.** Aim for a few per resource (create, update, response, maybe a summary), not dozens.
- **Business logic in DTOs.** Validation annotations are fine. Business rules belong in the service.
- **Mapping outside a transaction**, then touching lazy fields. Heads up: Spring Boot enables _Open Session in View_ by default, which often hides this bug until it hits production. Many teams set `spring.jpa.open-in-view=false` so the problem shows up early.
- **Reusing one DTO for request and response.** That brings back over-posting and data exposure.
- **Logging DTOs that contain secrets.**
- **Mixing up DTO and entity.** An entity is persisted state managed by JPA. A DTO is data in transit. They can look alike, but they have different jobs.

[[Spring Framework]]
