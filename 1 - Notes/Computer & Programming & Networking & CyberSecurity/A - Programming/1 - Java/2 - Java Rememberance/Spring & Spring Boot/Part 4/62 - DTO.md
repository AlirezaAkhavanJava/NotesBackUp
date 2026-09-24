
**creating a `record` after an Entity is a common Spring Boot pattern, not a JPA requirement.**

The usual flow is:

```text
Entity
  ↓
Record / DTO
  ↓
Controller
  ↓
JSON / HTTP
```

Let's build the concept properly.

# 1. What is a Java `record`?

A `record` is a special Java type designed to represent **immutable data**.

For example:

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

This says:

> `UserResponse` is a data carrier containing an ID and an email.

You automatically get:

- constructor
    
- accessors
    
- `equals()`
    
- `hashCode()`
    
- `toString()`
    

So instead of writing:

```java
public class UserResponse {

    private final UUID id;
    private final String email;

    public UserResponse(UUID id, String email) {
        this.id = id;
        this.email = email;
    }

    public UUID id() {
        return id;
    }

    public String email() {
        return email;
    }

    // equals()
    // hashCode()
    // toString()
}
```

you write:

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

That's the basic Java concept.

---

# 2. Why does Spring developers use records after Entities?

Because an **Entity and a DTO have different jobs**.

Consider your entity:

```java
@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;
}
```

You probably **do not want to send this entire object to the client**.

Imagine:

```http
GET /users/123
```

If you return the entity directly:

```java
@GetMapping("/{id}")
public User getUser(...) {
    return userService.findById(...);
}
```

you could accidentally produce:

```json
{
  "id": "...",
  "email": "alice@example.com",
  "password": "secret"
}
```

That's obviously wrong.

Instead, define a response record:

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

Now your API deliberately exposes:

```json
{
  "id": "...",
  "email": "alice@example.com"
}
```

The record is acting as a **DTO — Data Transfer Object**.

---

# 3. Entity vs Record

This distinction is extremely important.

### Entity

```java
@Entity
public class User {
    ...
}
```

represents:

> **Persistent domain state.**

Hibernate/JPA cares about it.

It has:

```text
@Entity
@Id
@Column
@GeneratedValue
```

and participates in:

```text
JPA
 ↓
Hibernate
 ↓
Database
```

### DTO / Record

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

represents:

> **Data crossing an application boundary.**

For example:

```text
Database
   ↓
Entity
   ↓
DTO / Record
   ↓
JSON
   ↓
HTTP client
```

They're solving different problems.

---

# 4. Why not just use the Entity?

Because your database model and your API model shouldn't necessarily be the same.

Suppose your entity eventually becomes:

```java
@Entity
public class User {

    private UUID id;
    private String email;
    private String passwordHash;
    private Instant createdAt;
    private Instant lastLogin;
    private boolean enabled;
    private String internalNote;
}
```

Your public API might only need:

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

Now you have a boundary:

```text
                 INTERNAL
                    │
      ┌─────────────┴──────────────┐
      │                            │
   Database                     Entity
                                   │
                                   │ mapping
                                   ▼
                              UserResponse
                                   │
                                   ▼
                              PUBLIC API
```

Changes to the database/entity don't automatically become changes to your API contract.

That's one of the major reasons DTOs exist.

---

# 5. Records are immutable

This is another major characteristic.

Given:

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

you can do:

```java
UserResponse response =
        new UserResponse(id, "alice@example.com");
```

You access values using:

```java
response.id();
response.email();
```

But you cannot do:

```java
response.setEmail("bob@example.com"); // doesn't exist
```

There are no setters.

This is intentional.

A DTO representing an HTTP response is usually something you construct and then **send**, not something you mutate throughout the application.

---

# 6. Record syntax

The part inside parentheses is called the **record components**:

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

Conceptually Java generates:

```java
public final class UserResponse {

    private final UUID id;
    private final String email;

    public UserResponse(UUID id, String email) {
        this.id = id;
        this.email = email;
    }

    public UUID id() {
        return id;
    }

    public String email() {
        return email;
    }

    // equals
    // hashCode
    // toString
}
```

There are some additional language rules and details, but that's the correct mental model.

---

# 7. How it fits into your Spring architecture

A clean beginner-to-professional structure is:

```text
src/main/java/
└── user/
    ├── User.java
    ├── UserRepository.java
    ├── UserService.java
    ├── UserController.java
    └── UserResponse.java
```

Entity:

```java
@Entity
public class User {
    ...
}
```

Repository:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

DTO:

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

Service:

```java
@Service
public class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }

    public UserResponse getUser(UUID id) {

        User user = repository.findById(id)
                .orElseThrow();

        return new UserResponse(
                user.getId(),
                user.getEmail()
        );
    }
}
```

Controller:

```java
@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/{id}")
    public UserResponse getUser(@PathVariable UUID id) {
        return userService.getUser(id);
    }
}
```

Now the complete flow is:

```text
HTTP GET /users/{id}
          │
          ▼
   UserController
          │
          ▼
     UserService
          │
          ▼
   UserRepository
          │
          ▼
       Hibernate
          │
          ▼
      PostgreSQL
          │
          ▼
        User
       Entity
          │
          │ mapping
          ▼
    UserResponse
      Record/DTO
          │
          ▼
   Jackson serialization
          │
          ▼
        JSON
```

That's the pattern you're probably seeing.

---

# 8. Records aren't only for responses

You can have different DTO records for different boundaries.

For example, a **request**:

```java
public record CreateUserRequest(
        String email,
        String password
) {}
```

And a **response**:

```java
public record UserResponse(
        UUID id,
        String email
) {}
```

Notice something important:

```text
CreateUserRequest
    ↓
client → server

UserResponse
    ↓
server → client
```

This is much better than using one giant `User` object for everything.

---

# 9. Validation works nicely with records

For example:

```java
public record CreateUserRequest(

        @NotBlank
        @Email
        String email,

        @NotBlank
        @Size(min = 8)
        String password

) {}
```

Then:

```java
@PostMapping
public UserResponse create(
        @Valid @RequestBody CreateUserRequest request
) {
    ...
}
```

Now the record represents the **input contract** of your endpoint.

---

# 10. One important misconception

Don't think:

> Entity → Record

as if every entity must have exactly one record.

Instead think:

```text
                 Entity
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
 CreateUser     UpdateUser    UserResponse
  Request         Request
   Record          Record        Record
```

You design DTOs around **use cases and boundaries**, not around the existence of an entity.

For example:

```java
public record CreateUserRequest(...) {}
public record UpdateUserRequest(...) {}
public record UserResponse(...) {}
public record UserSummaryResponse(...) {}
```

They can all represent different views of the same `User` entity.

---

## The mental model to keep

The most useful distinction is:

```text
ENTITY
"What does my application persist?"
        │
        ▼
   JPA / Hibernate
        │
        ▼
     DATABASE


DTO / RECORD
"What data crosses this boundary?"
        │
        ▼
 HTTP / JSON / API
```

And the **record itself is a Java language feature**. Spring doesn't own it.

Spring Boot simply makes records extremely convenient for DTOs because they are concise, immutable data carriers and work naturally with JSON serialization/deserialization.

So when you see a developer create an Entity and then a Record, don't memorize it as a ritual. Ask:

> **"What boundary is this record representing, and what data should be allowed across that boundary?"**

That's the architectural reason behind the pattern.



[[Java]]
[[0 - Spring Framework]]