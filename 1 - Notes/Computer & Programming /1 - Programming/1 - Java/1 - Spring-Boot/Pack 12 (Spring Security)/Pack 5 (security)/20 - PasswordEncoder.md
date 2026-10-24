
#  PasswordEncoder with UserDetailsService

In Spring Security, `UserDetailsService` answers the question **"Does this user exist, and what is their stored data?"** `PasswordEncoder` answers **"Does the password the user typed match what we stored?"** Together they make up the core of database-backed login.

We'll cover the concepts first, then build a small working example and trace the login flow.

## Part 1: The Problem PasswordEncoder Solves

Never store passwords as plain text. If your database leaks, every user's password is exposed, and many people reuse passwords across sites.

Instead, we store a **hash**: a one-way transformation of the password. Hashing differs from encryption in one important way. Encryption can be reversed with a key, while hashing cannot be reversed. To check a login, we hash the typed password and compare the result with the stored hash.

A plain hash like SHA-256 is still not enough, because attackers can precompute hashes of common passwords (rainbow tables). **BCrypt** fixes this by:

1. **Adding a random salt** to each password, so the same password produces different hashes.
2. **Being deliberately slow**, controlled by a _cost factor_, which makes brute-force guessing expensive.

A BCrypt hash looks like this:

```
$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
 │   │  └─────────────┬────────────┘└──────────┬───────────┘
 │   │          22-char salt            31-char hash
 │   └── cost factor (10 means 2^10 = 1024 rounds)
 └── algorithm identifier (BCrypt)
```

The salt is stored inside the hash string itself, so Spring can recheck a password later without a separate salt column.

## Part 2: The PasswordEncoder Interface

`PasswordEncoder` is an interface with three important methods:

|Method|What it does|When you call it|
|---|---|---|
|`encode(String raw)`|Returns a hash of the raw password (new salt each time)|When **registering** or **changing** a password|
|`matches(String raw, String encoded)`|Returns `true` if the raw password produces that stored hash|**Automatically during login**|
|`upgradeEncoding(String encoded)`|Returns `true` if the hash uses an outdated setting|Optional, for migrating old hashes|

The main implementation is `BCryptPasswordEncoder`. Its constructor takes one optional parameter:

```java
new BCryptPasswordEncoder();    // default strength 10
new BCryptPasswordEncoder(12); // strength 12: about 4x slower, and stronger
```

The strength value must be between 4 and 31. Each increase of 1 doubles the work. Ten is a common default, and you can increase it if your hardware allows.

## Part 3: Where UserDetailsService Fits

Here is what happens when someone logs in:

```
Client sends username + password
        │
        ▼
AuthenticationManager
        │
        ▼
DaoAuthenticationProvider          (created automatically by Spring Boot)
        │
        ├── 1. calls UserDetailsService.loadUserByUsername("alice")
        │         └── returns UserDetails (username, STORED HASH, roles)
        │
        └── 2. calls PasswordEncoder.matches(typedPassword, STORED HASH)
                  ├── true  → authenticated ✅
                  └── false → BadCredentialsException ❌
```

**Key point:** `loadUserByUsername` does _not_ check the password. It only loads the user, including the stored hash. The password comparison happens afterward, inside `DaoAuthenticationProvider`, which calls your `PasswordEncoder`.

Spring Boot wires this together automatically when it finds both a `UserDetailsService` bean and a `PasswordEncoder` bean.

## Part 4: Building the Example

### Step 1: Dependencies (`pom.xml`)

```xml
<dependencies>
    <!-- Web: REST endpoints (@RestController, @PostMapping) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- Security: login, filters, PasswordEncoder, UserDetailsService -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!-- JPA: saving and loading users from a database via repositories -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <!-- H2: a small in-memory database for learning. Runtime scope means it is needed only when the app runs, not to compile. -->
    <dependency>
        <groupId>com.h2database</groupId>
        <artifactId>h2</artifactId>
        <scope>runtime</scope>
    </dependency>
</dependencies>
```

Each starter bundles several libraries, so you only declare the feature areas you need. The `runtime` scope on H2 tells Maven the driver is needed to run the app but not to compile your code.

### Step 2: The User Entity

```java
import jakarta.persistence.*;

@Entity                                  // Tells JPA: this class maps to a database table
@Table(name = "app_users")               // Table name (avoids clashing with reserved word "users" in some databases)
public class AppUser {

    @Id                                              // Marks the primary key
    @GeneratedValue(strategy = GenerationType.IDENTITY)  // Database auto-increments the id
    private Long id;

    @Column(nullable = false, unique = true)  // Required, and no two users may share a username
    private String username;

    @Column(nullable = false)                 // Holds the BCrypt HASH, never the raw password
    private String password;

    @Column(nullable = false)                 // Stored without the "ROLE_" prefix, e.g. "USER" or "ADMIN"
    private String role;

    // JPA requires a no-argument constructor. "protected" keeps it out of normal use.
    protected AppUser() {}

    public AppUser(String username, String password, String role) {
        this.username = username;
        this.password = password;
        this.role = role;
    }

    public Long getId()        { return id; }
    public String getUsername() { return username; }
    public String getPassword() { return password; }
    public String getRole()     { return role; }
}
```

Each annotation has a specific job:

- `@Entity` marks the class as a database-mapped object.
- `@Table(name = ...)` sets the table name explicitly.
- `@Id` marks the primary key.
- `@GeneratedValue(strategy = IDENTITY)` lets the database assign ids.
- `@Column(nullable = false, unique = true)` adds database constraints. `nullable = false` means the column must have a value, and `unique = true` prevents duplicates.

### Step 3: The Repository

```java
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {

    // Spring Data generates the SQL from the method name: SELECT ... WHERE username = ?
    Optional<AppUser> findByUsername(String username);
}
```

You write no implementation. Spring Data creates it at startup. `JpaRepository<AppUser, Long>` means the entity is `AppUser` and its primary key is `Long`. `Optional` makes it explicit that the user may not exist.

### Step 4: The UserDetailsService

```java
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service  // Registers this class as a bean; Spring Security finds it automatically
public class AppUserDetailsService implements UserDetailsService {

    private final AppUserRepository repository;

    // Constructor injection: Spring passes in the repository. Preferred over @Autowired on fields.
    public AppUserDetailsService(AppUserRepository repository) {
        this.repository = repository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {

        // 1. Look up the user in the database
        AppUser user = repository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        // 2. Convert our entity into Spring Security's UserDetails object
        return User.withUsername(user.getUsername())
                .password(user.getPassword())  // The stored HASH. Spring compares it using PasswordEncoder.
                .roles(user.getRole())         // Adds the "ROLE_" prefix: "USER" becomes "ROLE_USER"
                .build();
    }
}
```

What each part does:

- **`UserDetailsService`** is an interface with one method, `loadUserByUsername`. Implementing it teaches Spring how to load your users.
- **`UsernameNotFoundException`** is the exception Spring expects when the user is missing. Throwing it correctly is important.
- **`User.withUsername(...)`** is a builder from Spring Security. It creates a `UserDetails` object. Its name clashes with nothing here, because our entity is called `AppUser`.
- **`.password(...)`** receives the stored hash. Passing the hash here is intentional and correct.
- **`.roles(...)`** adds the `ROLE_` prefix automatically. This matters later when you write `hasRole("ADMIN")`, which checks for `ROLE_ADMIN`.

### Step 5: The PasswordEncoder Bean and Security Configuration

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration   // This class defines beans for Spring to manage
@EnableWebSecurity   // Turns on Spring Security's web security support
public class SecurityConfig {

    // One shared PasswordEncoder for the whole application.
    // Both the login process and the registration service will use this same bean.
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();   // Default strength 10
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/register").permitAll()  // Anyone can register
                .anyRequest().authenticated()              // Everything else requires login
            )
            .httpBasic(Customizer.withDefaults());         // Login with HTTP Basic (username:password)

        return http.build();
    }
}
```

Important details:

- `@Bean` tells Spring to create and manage the returned object. Spring then injects this `PasswordEncoder` wherever it's needed.
- `@Configuration` marks the class as a source of bean definitions.
- `@EnableWebSecurity` activates the security configuration. Spring Boot often adds this automatically, but writing it is clearer.
- `HttpSecurity` is a builder for web security rules. Here, `/register` is public, and everything else needs authentication.
- `httpBasic` lets clients send credentials in the `Authorization` header. It's convenient for testing with `curl`, though real apps usually use form login or tokens.

Because `SecurityConfig` defines a `PasswordEncoder` bean, Spring Boot's auto-configuration for `DaoAuthenticationProvider` uses it instead of the default.

### Step 6: Registration Service (Where Encoding Happens)

Encoding must happen at registration. If you store a raw password, login will never match.

```java
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class RegistrationService {

    private final AppUserRepository repository;
    private final PasswordEncoder passwordEncoder;   // Injected from SecurityConfig

    public RegistrationService(AppUserRepository repository, PasswordEncoder passwordEncoder) {
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
    }

    public AppUser register(String username, String rawPassword) {

        // Reject duplicate usernames before saving
        if (repository.findByUsername(username).isPresent()) {
            throw new IllegalArgumentException("Username already taken: " + username);
        }

        // Hash the password. Each call creates a new random salt, so the same password gives a different hash each time.
        String hashedPassword = passwordEncoder.encode(rawPassword);

        // Save the user with the hash. The raw password is never stored.
        return repository.save(new AppUser(username, hashedPassword, "USER"));
    }
}
```

The key line is `passwordEncoder.encode(rawPassword)`. The raw password exists only in memory while this method runs, and only the hash reaches the database.

### Step 7: A Controller for Registration and a Test Endpoint

```java
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController  // Combines @Controller and @ResponseBody: returned objects become JSON
public class AuthController {

    private final RegistrationService registrationService;

    public AuthController(RegistrationService registrationService) {
        this.registrationService = registrationService;
    }

    // A record is a compact class that holds two fields. Good for simple request bodies.
    public record RegisterRequest(String username, String password) {}

    @PostMapping("/register")                          // Handles POST /register
    public ResponseEntity<String> register(@RequestBody RegisterRequest request) {  // Converts JSON into the record
        registrationService.register(request.username(), request.password());
        return ResponseEntity.ok("User registered: " + request.username());
    }

    @GetMapping("/hello")                              // Protected by SecurityConfig
    public String hello() {
        return "Hello! You are logged in.";
    }
}
```

`@RestController` tells Spring this class handles web requests and returns data directly. `@PostMapping` and `@GetMapping` map HTTP methods to Java methods. `@RequestBody` reads the JSON request body into the `RegisterRequest` record.

### Step 8: Test It on Debian

Start the app, then run these commands in a terminal.

Register a user:

```bash
curl -X POST http://localhost:8080/register \
     -H "Content-Type: application/json" \
     -d '{"username":"alice","password":"secret123"}'
```

Access the protected endpoint with correct credentials:

```bash
curl -u alice:secret123 http://localhost:8080/hello
# Output: Hello! You are logged in.
```

Try a wrong password:

```bash
curl -i -u alice:wrongpass http://localhost:8080/hello
# Output: HTTP/1.1 401 Unauthorized
```

The `-u` flag makes `curl` send credentials in the Basic Auth header. Spring then runs the full flow from Part 3: it loads `alice` through `AppUserDetailsService`, then compares `secret123` against the stored hash with `matches()`.

To see the hash in the database, enable the H2 console in `application.properties`:

```properties
spring.h2.console.enabled=true
spring.datasource.url=jdbc:h2:mem:testdb
```

Then open `http://localhost:8080/h2-console` in your browser. Run `SELECT * FROM app_users;`. You'll see something like `$2a$10$...` in the password column, which confirms that the raw password was never stored.

## Part 5: Summary of Responsibilities

|Component|Responsibility|
|---|---|
|`AppUser` (entity)|Defines the stored shape of a user|
|`AppUserRepository`|Loads and saves users|
|`AppUserDetailsService`|Tells Spring how to find a user by username|
|`PasswordEncoder` bean|Hashes passwords on registration and compares them on login|
|`RegistrationService`|Encodes the password before saving|
|`SecurityConfig`|Defines the encoder bean and which URLs need login|

## Part 6: Common Mistakes

1. **Saving the raw password.** Always call `encode()` before `save()`. Login will fail, and any leak exposes real passwords.
2. **Encoding during login.** Don't encode the typed password yourself in `loadUserByUsername`. Spring calls `matches()` for you.
3. **Using `NoOpPasswordEncoder`.** Old tutorials show `NoOpPasswordEncoder` or `{noop}` prefixes. These store plain text. Never use them in real code.
4. **Mismatched encoders.** If you change the encoder later, existing hashes may fail. For migrations, `DelegatingPasswordEncoder` (created via `PasswordEncoderFactories.createDelegatingPasswordEncoder()`) stores an algorithm prefix such as `{bcrypt}` so old and new hashes can coexist.
5. **Forgetting the `ROLE_` prefix.** `.roles("ADMIN")` adds it automatically. Writing `.authorities("ADMIN")` does not, so `hasRole("ADMIN")` will fail.
6. **Returning the password in responses.** Never send the `password` field back to the client, even though it is hashed.




[[Spring Security]]