

A user account is the one place where the Entity, DTO, and mapper split really pays off. The **entity** stores the username and a _hashed_ password. The **DTOs** describe what a client may send (a plain password, once) and what a client may see (never the password, in any form). The **mapper** copies the safe fields and deliberately does _not_ touch the password logic. Spring Security sits on top and uses the entity to log people in.

In this lesson you will build all four pieces for a registration and login flow. The golden rule is simple: **the raw password lives for only a few milliseconds**, inside a request DTO, until the service hashes it. After that, only the hash exists.

---

## The big picture: who handles what

```
POST /register  { "username": "sara", "password": "Secret123" }
        │
        ▼
RegisterRequest (record)  ← validation happens here (@Valid)
        │
        ▼
UserService  ← checks username is free, HASHES the password
        │
        ▼
UserMapper.toEntity(request, hashedPassword)
        │
        ▼
User (entity)  ← stores the hash
        │
        ▼
UserMapper.toResponse(user) → UserResponse { id, username, role }   (no password)
```

|Piece|Username|Password|Role|
|---|---|---|---|
|**Entity**|unique, length-limited|stores the **hash** only|enum, set by the server|
|**RegisterRequest**|validated (length, characters)|validated (length, strength), raw|not present|
|**LoginRequest**|`@NotBlank` only|`@NotBlank` only, raw|not present|
|**UserResponse**|yes|**never**|yes|
|**Mapper**|copies|receives the _already hashed_ value|sets the default|
|**Service**|checks uniqueness|calls `passwordEncoder.encode(...)`|decides who gets which role|

---

## 1. The Entity

```java
@Entity
@Table(name = "users")
@Getter @Setter
@NoArgsConstructor
public class User implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Column(nullable = false, length = 100)
    private String password;            // BCrypt hash, never the raw password

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role = Role.USER;

    private boolean enabled = true;

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }

    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isAccountNonLocked()      { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
}

public enum Role { USER, ADMIN }
```

Line by line:

- `@Table(name = "users")`: in PostgreSQL, `user` is a reserved word. Naming the table `users` avoids strange SQL errors.
- `implements UserDetails`: this is the interface Spring Security uses to represent "a person who can log in." If your entity implements it, you can return it straight from your `UserDetailsService`.
- `unique = true` on `username`: the _database_ guarantees no duplicates, even if two requests arrive at the same moment.
- `length = 100` on `password`: a BCrypt hash is 60 characters. 100 leaves room if you change the algorithm later. Never size this column for the raw password.
- `@Enumerated(EnumType.STRING)`: stores `"USER"` instead of `0`. If you reorder the enum later, ordinal numbers would silently point to the wrong roles.
- `getUsername()`, `getPassword()`, and `isEnabled()` are required by `UserDetails`. Lombok's `@Getter` already creates all three from the fields, so you don't write them.
- `getAuthorities()` converts the role to what Spring Security understands. The `ROLE_` prefix is what makes `hasRole("ADMIN")` work.
- Do **not** add `@Data` or `@ToString` here. They would print the password hash into your logs.

**Alternative:** if you prefer a clean entity, keep `User` as a plain entity and write a separate `CustomUserDetails` class that wraps it. It is more code, but the entity stays free of security interfaces.

---

## 2. The DTOs (records)

### Registration request

```java
public record RegisterRequest(

        @NotBlank(message = "Username is required")
        @Size(min = 3, max = 50, message = "Username must be 3 to 50 characters")
        @Pattern(regexp = "^[a-zA-Z0-9._-]+$",
                 message = "Username can only contain letters, digits, dots, dashes and underscores")
        String username,

        @NotBlank(message = "Password is required")
        @Size(min = 8, max = 72, message = "Password must be 8 to 72 characters")
        @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).+$",
                 message = "Password needs a lowercase letter, an uppercase letter and a digit")
        String password
) {
    public RegisterRequest {
        if (username != null) {
            username = username.trim();
        }
    }

    @Override
    public String toString() {
        return "RegisterRequest[username=" + username + ", password=****]";
    }
}
```

Walking through the parts that are easy to miss:

- `@NotBlank` rejects `null`, `""`, and `" "`. Use it instead of `@NotNull` for text.
- `@Size(max = 72)` on the password: BCrypt only reads the first **72 bytes**. A longer password would be silently cut off, so we reject it up front.
- `@Pattern` with lookaheads (`(?=...)`) checks that the password contains each kind of character without caring about the order.
- The **compact constructor** (`public RegisterRequest { ... }`) runs when the record is created. Here it trims spaces around the username, so `" sara "` becomes `"sara"`. You trim the username, but **never trim the password**, because spaces may be part of it.
- The `toString()` override is a safety net. Records generate a `toString()` that prints _every_ field. If anyone logs the request object, the raw password would appear in your logs. This override masks it.

### Login request

```java
public record LoginRequest(
        @NotBlank(message = "Username is required") String username,
        @NotBlank(message = "Password is required") String password
) {
    @Override
    public String toString() {
        return "LoginRequest[username=" + username + ", password=****]";
    }
}
```

Notice that login has **no** length or strength rules. If you tightened your password policy later, old users with older passwords must still be able to log in. At login you only check that something was sent. Spring Security compares the hash.

### Response

```java
public record UserResponse(Long id, String username, Role role) {}
```

The password field simply does not exist here. A field that isn't in the record can't leak.

---

## 3. The Mapper

The mapper is a pure converter. It must **not** hash passwords, because hashing is a security decision that belongs in the service, and the mapper stays easy to test.

```java
@Component
public class UserMapper {

    public User toEntity(RegisterRequest request, String encodedPassword) {
        User user = new User();
        user.setUsername(request.username());
        user.setPassword(encodedPassword);
        user.setRole(Role.USER);
        return user;
    }

    public UserResponse toResponse(User user) {
        return new UserResponse(user.getId(), user.getUsername(), user.getRole());
    }
}
```

- `toEntity` takes the hash as a **second parameter**. This makes it impossible to accidentally store the raw password, because the method never receives `request.password()` for storage.
- `setRole(Role.USER)`: the role is chosen by the server. If the request contained a `role` field, a client could register themselves as `ADMIN`.
- `toResponse` copies exactly three fields.

**With MapStruct:**

```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "password", ignore = true)    // the service sets the hash
    @Mapping(target = "role", constant = "USER")
    @Mapping(target = "enabled", constant = "true")
    User toEntity(RegisterRequest request);

    UserResponse toResponse(User user);
}
```

Here `password` is ignored on purpose, because the request's `password` field has the same name and would be copied _raw_ into the entity. After mapping, the service must call `user.setPassword(passwordEncoder.encode(request.password()))`. Forgetting that line is the classic MapStruct mistake, which is why many people prefer the manual mapper for user accounts.

---

## 4. The Service, the Encoder, and the Controller

```java
@Configuration
public class SecurityBeans {
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper mapper;

    @Transactional
    public UserResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username already taken");
        }
        String hash = passwordEncoder.encode(request.password());
        User saved = userRepository.save(mapper.toEntity(request, hash));
        return mapper.toResponse(saved);
    }
}
```

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    boolean existsByUsername(String username);
}
```

```java
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<UserResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(userService.register(request));
    }
}
```

- `@Valid` is what activates the annotations on the record. Without it, nothing is checked.
- The validation annotations need the `spring-boot-starter-validation` dependency (it uses `jakarta.validation`).
- `existsByUsername` gives a friendly error. The `unique = true` column is the safety net for the rare case where two identical requests race each other.
- BCrypt adds a random **salt** every time, so encoding the same password twice gives two different hashes. That is normal. Login works because `matches(raw, hash)` reads the salt out of the hash.

### Turning validation failures into clean errors

When `@Valid` fails, Spring throws `MethodArgumentNotValidException`. Catch it once for the whole app:

```java
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
          .forEach(e -> errors.putIfAbsent(e.getField(), e.getDefaultMessage()));
        return ResponseEntity.badRequest().body(errors);
    }
}
```

Result: `{"username":"Username must be 3 to 50 characters","password":"Password needs a lowercase letter, an uppercase letter and a digit"}`. We send only the _message_, never the rejected value, so the typed password isn't echoed back.

---

## Mistakes to avoid

|Mistake|Why it hurts|Fix|
|---|---|---|
|Storing the raw password, even "temporarily"|A database leak exposes every account|Hash with `PasswordEncoder` before the entity is built|
|`@Data` or `@ToString` on the entity|Hash ends up in logs|Use `@Getter`/`@Setter` only|
|Record `toString()` left as default|Raw password appears in logs|Override it to mask the password|
|Returning the entity from a controller|Password hash goes to the client|Return `UserResponse`|
|A `role` field in `RegisterRequest`|Anyone can register as admin|Server sets the role|
|Strength rules on `LoginRequest`|Old users get locked out when you change rules|Only `@NotBlank` at login|
|Password `max` above 72|BCrypt silently ignores the tail|`@Size(max = 72)`|
|Trimming the password|Changes what the user typed|Trim only the username|
|Forgetting `@Valid`|Annotations are never checked|Put it on the `@RequestBody` parameter|
|Table named `user` in PostgreSQL|Reserved word errors|`@Table(name = "users")`|

---

## A related concept: custom validation annotations

If `@Pattern` regexes get long or repeated, you can build your own annotation such as `@StrongPassword`. You write an annotation marked with `@Constraint(validatedBy = ...)` and a small class that implements `ConstraintValidator<StrongPassword, String>` containing the checks. Then your record just says `@StrongPassword String password`. It keeps the rules in one place and lets you give each failure its own message.







[[Spring Framework]]
[[Spring Security]]