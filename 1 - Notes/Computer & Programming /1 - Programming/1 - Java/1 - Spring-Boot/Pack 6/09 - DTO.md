

## 1. Core intuition

Think of a restaurant. The kitchen has a full internal record for every dish: supplier, cost price, raw ingredients, prep notes. But the **menu** shows the customer only the name, description, and price.

- The **entity** is the kitchen's internal record.
- The **DTO** is the menu entry, a purpose-built shape for crossing a boundary.

**A DTO is a simple object whose only job is to carry data across a boundary** (client ↔ server, or layer ↔ layer). It has no business logic and no database mapping, only fields.

## 2. The problem it solves

Without DTOs, you expose your JPA entity directly:

```java
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;
    private String username;
    private String email;
    private String passwordHash;     // internal secret
    private boolean admin;           // internal flag
    @OneToMany(mappedBy = "user")
    private List<Order> orders;      // lazy relation
}

@GetMapping("/users/{id}")
public User get(@PathVariable Long id) {
    return userRepository.findById(id).orElseThrow();   // returns the entity directly
}
```

What goes wrong:

1. **Data leaks.** `passwordHash` and `admin` go straight into the JSON, unless you remember `@JsonIgnore` on every sensitive field.
2. **Mass assignment.** If you accept the entity as `@RequestBody`, a client can send `"admin": true` and set a field you never meant to expose.
3. **Recursion and lazy-loading errors.** The `User ↔ Order` cycle from the `@JsonIgnore` lesson, plus `LazyInitializationException` when Jackson touches an unloaded relation.
4. **Tight coupling.** Renaming a database column silently changes your public API.
5. **One shape doesn't fit all.** Creating a user needs a password, but reading a user must not return it. The entity can't be both.

## 3. The solution

Define separate classes for what crosses the boundary. Since you've seen records, they are the natural fit:

```java
// What the client SENDS to create a user
public record CreateUserRequest(
    @NotBlank String username,
    @Email String email,
    @Size(min = 8) String password
) {}

// What the client RECEIVES
public record UserResponse(
    Long id,
    String username,
    String email
) {}
```

The service layer converts between them:

```java
@Service
public class UserService {

    private final UserRepository repo;
    private final PasswordEncoder encoder;

    // constructor injection omitted for brevity

    public UserResponse create(CreateUserRequest req) {
        User user = new User();
        user.setUsername(req.username());
        user.setEmail(req.email());
        user.setPasswordHash(encoder.encode(req.password()));

        User saved = repo.save(user);
        return new UserResponse(saved.getId(), saved.getUsername(), saved.getEmail());
    }
}

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService service;

    @PostMapping
    public UserResponse create(@Valid @RequestBody CreateUserRequest req) {
        return service.create(req);
    }
}
```

Notice the entity never leaves the service layer. The client cannot send `admin`, and `passwordHash` cannot leak, **because those fields don't exist on the DTOs**. Safety comes from the shape of the class, so you don't rely on remembering annotations.

## 4. Why it works this way

DTOs separate **three different concerns** that would otherwise be welded into one class:

|Concern|Class|
|---|---|
|How data is **stored**|Entity|
|How data is **exchanged** with outsiders (the API contract)|DTO|
|How the **business rules** operate|Domain/service|

These change for different reasons and at different speeds. A database refactor shouldn't break mobile apps, and a new API field shouldn't force a migration. DTOs are the buffer in the middle.

## 5. Naming and variants

Conventions vary, but common ones are:

- `CreateUserRequest`, `UpdateUserRequest`: input
- `UserResponse`: output
- `UserSummary` vs `UserDetails`: different levels of detail for list vs single-item views

Having **several DTOs per entity is normal and healthy**. Don't try to reuse one DTO for everything, because that recreates the original problem in a smaller form.

## 6. Mapping entity ↔ DTO

Manual mapping, as above, is clear but tedious. Options:

**Static factory on the DTO** (simple, no library):

```java
public record UserResponse(Long id, String username, String email) {
    public static UserResponse from(User u) {
        return new UserResponse(u.getId(), u.getUsername(), u.getEmail());
    }
}
```

**MapStruct** (the standard library for larger projects). It generates the mapping code at compile time, so it's fast and type-safe:

```java
@Mapper(componentModel = "spring")
public interface UserMapper {
    UserResponse toResponse(User user);
    User toEntity(CreateUserRequest req);
}
```

MapStruct is worth learning later, but write a few mappings by hand first so you understand what it automates.

## 7. Gotchas

1. **Over-engineering.** For a tiny demo, entity DTO duplication can feel like noise. The rule of thumb: the moment something is exposed to an outside client, use a DTO.
2. **A DTO is not an entity.** No `@Entity`, no JPA annotations, no lazy relations. If a DTO needs related data (a user's orders), include **already-loaded plain data** (`List<OrderSummary>`), not entity references.
3. **No logic.** A DTO may hold validation annotations and tiny helpers, but business rules belong in the service or domain layer.
4. **Validation lives on the input DTO.** `@Valid` on the `@RequestBody` triggers Bean Validation, and this is where `@NotNull`, `@Size`, and `@Email` belong. That is why `required = true` in `@JsonProperty` isn't enough on its own.
5. **Don't confuse the terms.** You will see DTO, "request/response model," and "view model" used loosely. They all mean essentially the same idea in a Spring API.

## 8. Connection to what you just learned

Every Jackson annotation from the last three topics (`@JsonProperty`, `@JsonIgnore`, `@JsonInclude`, `@JsonFormat`, `@JsonCreator`) is best placed **on DTOs, not entities**. That keeps your API formatting rules separate from your database model, and it is why records (immutable, constructor-built, no boilerplate) are the modern choice for DTOs.





[[Spring Framework]]