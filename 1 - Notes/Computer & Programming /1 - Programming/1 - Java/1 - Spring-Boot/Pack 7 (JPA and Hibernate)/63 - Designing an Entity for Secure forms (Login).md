![[6a951148-8a50-4482-9587-fa937ff85752.png]]

**What this lesson covers:** A login system needs a table that stores users, and that table must never hold a readable password. Instead, you store a _hash_, a one-way scrambled version of the password that can be checked but not reversed. In this lesson you'll design an `AppUser` entity, write the Flyway migration for it, configure **BCrypt** (a password hashing algorithm built for this job), and build register and login on top of Spring Security. Every component, annotation, and parameter gets an explanation.

## Why the design matters

Before writing code, answer these questions about each field:

- **Who identifies the user?** Usernames and emails must be unique, so the database should enforce it.
- **What is stored for the password?** Only `password_hash`. The field name itself reminds you never to store the raw password.
- **What can the user do?** A `role` decides this, and it should be a fixed set of values, not free text.
- **Can the account be used?** An `enabled` flag lets you disable an account without deleting it.
- **When was it created?** Useful for auditing, and it should never change.

## Why BCrypt, and not MD5 or SHA-256?

Ordinary hash functions like MD5 and SHA-256 are designed to be _fast_. That's ideal for checksums, but terrible for passwords: an attacker with a stolen database can test billions of guesses per second on a GPU.

BCrypt is designed to be _slow on purpose_, and it adds a few protections automatically:

- **Salt:** BCrypt generates a random value for each password and mixes it in. Two users with the password `Summer2026!` get completely different hashes, which defeats precomputed lookup tables (rainbow tables). The salt is stored inside the hash string, so you never manage it yourself.
- **Cost factor:** A number that controls how much work each hash takes. Each increase by 1 doubles the work. A cost of 12 is a sensible modern choice, and the right value is the one where a hash takes roughly a quarter of a second on your server.
- **Format:** A BCrypt hash looks like `$2a$12$...` and is always 60 characters. The parts are the algorithm version (`2a`), the cost (`12`), the salt, and the hash itself.

## Step 1: Add the dependencies

Add these to `pom.xml` alongside what you already have:

```xml
<!-- Spring Security: authentication, authorization, and password encoders -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<!-- Bean Validation: @NotBlank, @Email, @Size used on request data -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

`spring-boot-starter-security` includes `BCryptPasswordEncoder`, so you don't add a separate hashing library. Adding it also makes every endpoint require login by default, which is why we configure it in Step 5. `spring-boot-starter-validation` provides the annotations that check incoming data before it reaches your code.

## Step 2: Design the Role and the entity

First, a small enum for roles. Create `Role.java`:

```java
public enum Role {
    USER,   // A normal customer
    ADMIN   // Can manage other accounts
}
```

An enum guarantees only valid values exist. Now the entity, `AppUser.java`:

```java
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "app_users")                                   // "user" is a reserved word in PostgreSQL, so we avoid it
public class AppUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)      // Database assigns the ID (BIGSERIAL)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)    // Required, unique, max 50 characters
    private String username;

    @Column(nullable = false, unique = true, length = 255)   // Required and unique, so one email = one account
    private String email;

    @Column(name = "password_hash", nullable = false, length = 100)  // Holds the BCrypt hash, never the raw password
    private String passwordHash;

    @Enumerated(EnumType.STRING)                             // Store "ADMIN" as text, not as 0 or 1
    @Column(nullable = false, length = 20)
    private Role role;

    @Column(nullable = false)                                // Disabled accounts can't log in
    private boolean enabled = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected AppUser() {}                                   // Required by JPA

    public AppUser(String username, String email, String passwordHash, Role role) {
        this.username = username;
        this.email = email;
        this.passwordHash = passwordHash;
        this.role = role;
        this.createdAt = Instant.now();
    }

    // Getters
    public Long getId() { return id; }
    public String getUsername() { return username; }
    public String getEmail() { return email; }
    public String getPasswordHash() { return passwordHash; }
    public Role getRole() { return role; }
    public boolean isEnabled() { return enabled; }
    public Instant getCreatedAt() { return createdAt; }

    // A controlled way to change the password. There is no public setPasswordHash().
    public void changePasswordHash(String newHash) {
        this.passwordHash = newHash;
    }

    public void disable() {
        this.enabled = false;
    }
}
```

Key points:

- `@Enumerated(EnumType.STRING)` stores the role's name. The default, `ORDINAL`, stores the position (0, 1), and adding a new role in the middle would silently change the meaning of existing rows.
- `nullable = false` and `unique = true` are mirrored in the SQL below. The Java annotations describe the rules, but the database is what actually enforces them.
- The `passwordHash` field has no public setter. The only way to change it is `changePasswordHash`, so any password change passes through one controlled place.
- `enabled` defaults to `true` in the field initializer, so a new user is active unless you disable them.

## Step 3: The Flyway migration

Create `src/main/resources/db/migration/V5__create_app_users.sql`. The version number must be the next free one in your project (V5 assumes you completed the previous exercises).

```sql
CREATE TABLE app_users (
    id             BIGSERIAL PRIMARY KEY,
    username       VARCHAR(50)              NOT NULL UNIQUE,
    email          VARCHAR(255)             NOT NULL UNIQUE,
    password_hash  VARCHAR(100)             NOT NULL,
    role           VARCHAR(20)              NOT NULL
                   CHECK (role IN ('USER', 'ADMIN')),   -- Database rejects any other role
    enabled        BOOLEAN                  NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL
);
```

- `password_hash VARCHAR(100)` leaves room for a 60-character BCrypt hash and for stronger encoders that produce longer hashes later. Storing it as `VARCHAR(60)` would break if you ever switch algorithms.
- `CHECK (role IN (...))` is a second safety net. Even if some other code bypasses your enum, the database refuses bad values.
- `DEFAULT TRUE` on `enabled` matches the Java default, so the two stay consistent.
- `UNIQUE` on both `username` and `email` makes duplicates impossible even under concurrent requests.

Start the application and Flyway applies the migration before Hibernate validates the entity (`spring.jpa.hibernate.ddl-auto=validate`, from the previous lesson).

## Step 4: The repository and the request data

The repository, `AppUserRepository.java`:

```java
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {

    Optional<AppUser> findByUsername(String username);   // Used by the login process

    boolean existsByUsername(String username);           // Used before registering

    boolean existsByEmail(String email);
}
```

Spring Data creates the implementation automatically from the method names. `Optional` is used for lookups because the user might not exist, and it forces the caller to handle that case.

The registration request, `RegistrationRequest.java`:

```java
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegistrationRequest(
        @NotBlank @Size(min = 3, max = 50) String username,
        @NotBlank @Email @Size(max = 255) String email,
        @NotBlank @Size(min = 8, max = 72) String password
) {}
```

- `record` gives you an immutable data carrier with no boilerplate.
- `@NotBlank` rejects null, empty, and whitespace-only strings, which `@NotNull` would allow.
- `@Email` checks the format, though it doesn't prove the address exists.
- `@Size(min = 8)` sets a minimum password length. Longer passwords are better, so this is a floor, not a recommendation.
- `@Size(max = 72)` on the password is essential. BCrypt only uses the first 72 bytes of input, so anything longer is silently ignored. Limiting the length makes that behavior explicit instead of a hidden trap.

The request object is a separate class from the entity on purpose. The entity describes the database, and the request describes what a client may send. Keeping them apart prevents a client from setting fields like `role` or `enabled` during registration.

## Step 5: Configure BCrypt and the security rules

`SecurityConfig.java`:

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);            // Cost factor 12: each +1 doubles the work
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())                // Safe for a stateless REST API; see note below
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/register").permitAll()   // Anyone can register
                .anyRequest().authenticated()                        // Everything else needs login
            )
            .httpBasic(Customizer.withDefaults());       // Accept username and password in each request

        return http.build();
    }
}
```

What each part does:

- `@Configuration` marks the class as a source of beans, and `@EnableWebSecurity` turns on Spring Security's web protection.
- The `PasswordEncoder` bean is the single place where the hashing algorithm is chosen. Registration and login both get this same encoder from Spring, so they always agree.
- `csrf.disable()` turns off Cross-Site Request Forgery protection. CSRF attacks rely on browsers automatically sending cookies, and this API uses credentials sent explicitly in headers, so the protection isn't needed here. If you later use cookie-based sessions with a browser front end, enable it again.
- `requestMatchers(...).permitAll()` lets unauthenticated clients reach the register endpoint. Without this, nobody could create an account.
- `anyRequest().authenticated()` is the default-deny rule. New endpoints are protected automatically, which is the safe direction to fail.
- `httpBasic` lets a client send `username:password` in an `Authorization` header. This is convenient for learning and testing. For real applications, you'd usually move to JWT tokens, which is a natural next lesson.

## Step 6: Teach Spring Security how to find users

Spring Security doesn't know about your `AppUser` class. You bridge the gap with a `UserDetailsService`, `AppUserDetailsService.java`:

```java
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class AppUserDetailsService implements UserDetailsService {

    private final AppUserRepository repository;

    public AppUserDetailsService(AppUserRepository repository) {
        this.repository = repository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser user = repository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        return User.withUsername(user.getUsername())
                .password(user.getPasswordHash())        // The stored hash, not a plain password
                .roles(user.getRole().name())            // Adds the "ROLE_" prefix automatically: ROLE_USER
                .disabled(!user.isEnabled())             // Spring refuses login for disabled accounts
                .build();
    }
}
```

- `UserDetailsService` has one job: given a username, return what Spring Security needs to check a login.
- `User.withUsername(...)` is Spring's own `UserDetails` class, which is why we use the full name `User`. Our entity is named `AppUser` to avoid confusion.
- `.roles("USER")` stores the authority as `ROLE_USER`. Spring's `hasRole("USER")` checks look for that prefix, so the mapping matters.

**This is how login works:** when a client sends credentials, Spring calls `loadUserByUsername`, gets the stored hash, and then calls `passwordEncoder.matches(rawPassword, storedHash)` itself. You never write the comparison yourself, which removes a common source of mistakes. Spring also hides whether the username or the password was wrong, responding with "Bad credentials" in both cases, so attackers can't use the error to discover valid usernames.

## Step 7: The registration service

This is where the password gets hashed. `RegistrationService.java`:

```java
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RegistrationService {

    private final AppUserRepository repository;
    private final PasswordEncoder passwordEncoder;

    public RegistrationService(AppUserRepository repository, PasswordEncoder passwordEncoder) {
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional                                       // Save and check run in one database transaction
    public AppUser register(RegistrationRequest request) {
        String username = request.username().trim();
        String email = request.email().trim().toLowerCase();   // Normalize so "Ana@X.com" and "ana@x.com" match

        if (repository.existsByUsername(username)) {
            throw new IllegalArgumentException("Username is already taken");
        }
        if (repository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email is already registered");
        }

        String hash = passwordEncoder.encode(request.password());   // Salted and hashed here, once
        AppUser user = new AppUser(username, email, hash, Role.USER); // New accounts are always USER

        return repository.save(user);
    }
}
```

- `passwordEncoder.encode(...)` is the line that does the hashing. The raw password exists only in this method's variable, and only the hash is passed to the entity and saved.
- Normalizing the email to lowercase means uniqueness works the way people expect. Otherwise `Ana@X.com` and `ana@x.com` would count as two accounts.
- `Role.USER` is hard-coded. Registration must never accept a role from the client, or anyone could register as an admin.
- The `existsBy` checks give friendly error messages. The database's `UNIQUE` constraint is the real guarantee, since two requests can pass the check at the same moment. In production, catch `DataIntegrityViolationException` as well.

## Step 8: The controller and the response

Responses shouldn't expose the entity directly, because that would include the password hash. Create `UserResponse.java`:

```java
public record UserResponse(Long id, String username, String email, Role role) {

    public static UserResponse from(AppUser user) {
        return new UserResponse(user.getId(), user.getUsername(), user.getEmail(), user.getRole());
    }
}
```

`AuthController.java`:

```java
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final RegistrationService registrationService;

    public AuthController(RegistrationService registrationService) {
        this.registrationService = registrationService;
    }

    @PostMapping("/register")
    public ResponseEntity<UserResponse> register(@Valid @RequestBody RegistrationRequest request) {
        AppUser user = registrationService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(UserResponse.from(user));
    }

    @GetMapping("/me")                                   // Requires login, thanks to SecurityConfig
    public String me(Authentication authentication) {
        return "Logged in as " + authentication.getName();
    }

    @ExceptionHandler(IllegalArgumentException.class)     // Turns "already taken" into a 409 response
    public ResponseEntity<String> handleConflict(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(ex.getMessage());
    }
}
```

- `@Valid` triggers the checks from `RegistrationRequest`. If they fail, Spring returns `400 Bad Request` before your method runs.
- `201 Created` is the correct status for a newly created resource.
- `Authentication` is filled in by Spring Security after a successful login, and `getName()` returns the username.
- `@ExceptionHandler` converts the "already taken" error into `409 Conflict`, which is the standard response for this situation.

## Step 9: Test it on Debian 13

Start the app, then register a user:

```bash
curl -i -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"alireza","email":"alireza@example.com","password":"StrongPass123"}'
```

You should get `201 Created` and a JSON body without any password. Try the same request again and you'll get `409 Conflict`. Next, log in with the protected endpoint:

```bash
curl -u alireza:StrongPass123 http://localhost:8080/api/auth/me
curl -u alireza:WrongPassword http://localhost:8080/api/auth/me
```

The first returns the greeting. The second returns `401 Unauthorized`. Finally, look at what's actually stored:

```bash
sudo -u postgres psql -d shopdb -c "SELECT username, email, role, password_hash FROM app_users;"
```

You'll see something like `$2a$12$...`, not `StrongPass123`. Run the registration twice with the same password for two different users, and the two hashes will differ. That's the salt at work.

## Common mistakes

1. **Storing or logging the raw password.** Never put it in a log statement, an exception message, or a `toString()`.
2. **Using MD5, SHA-256, or plain `encode` without BCrypt.** Fast hashes are wrong for passwords.
3. **Returning the entity from the controller.** It exposes `passwordHash`. Always map to a response record.
4. **Letting the client set `role` or `enabled`.** Keep the request object separate from the entity.
5. **Forgetting the 72-byte limit.** Without `@Size(max = 72)`, extra characters are silently ignored.
6. **Comparing hashes yourself with `equals`.** Use `passwordEncoder.matches`, or let Spring do it through `UserDetailsService`.
7. **Naming the table `user`.** PostgreSQL reserves it, which is why we used `app_users`.

## Try it yourself

1. Add a `GET /api/auth/admin-only` endpoint restricted to `ADMIN` using `.requestMatchers("/api/auth/admin-only").hasRole("ADMIN")` in `SecurityConfig`. Then create an admin by updating a row with `psql`, and test it with `curl -u`.
2. Add a `changePassword` endpoint that checks the old password with `passwordEncoder.matches` before calling `changePasswordHash`. Think about why the old password must be checked.
3. Change the cost factor to 14 and measure how long registration takes with `time curl ...`. Then return to 12 and explain in your own words why the cost is a trade-off between security and server load.




[[Spring Framework]]