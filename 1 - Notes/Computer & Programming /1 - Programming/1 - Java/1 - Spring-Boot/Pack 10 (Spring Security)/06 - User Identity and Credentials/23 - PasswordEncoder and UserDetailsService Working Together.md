


`UserDetailsService` and `PasswordEncoder` each handle one part of the password story, and they depend on each other:

- **`PasswordEncoder`** turns a raw password into a hash (`encode`) and checks a typed password against a stored hash (`matches`).
- **`UserDetailsService`** finds the user and supplies the stored hash. It also creates users when you ask it to.

Spring Security connects them during login. You connect them during registration.

## Part 1: The Two Moments in a User's Life

Passwords are touched at two points, and each point uses a different method:

```
REGISTRATION (write side)
  raw password ──► passwordEncoder.encode() ──► hash ──► saved in database

LOGIN (read side)
  typed password + stored hash ──► passwordEncoder.matches() ──► true / false
                                   ▲
                                   └── stored hash comes from loadUserByUsername()
```

Keep two rules in mind:

1. **Encode once, at the moment of writing.** Every stored password must already be a hash before it reaches the database.
2. **Never encode during login.** Spring calls `matches()` for you. If you hash the typed password yourself and compare the strings, the check will always fail, because each BCrypt hash includes a random salt.

## Part 2: The Wiring Spring Does for You

When your application has a `UserDetailsService` bean and a `PasswordEncoder` bean, Spring Boot creates a `DaoAuthenticationProvider` and connects them:

```
AuthenticationManager
        │
        ▼
DaoAuthenticationProvider
        │
        ├── userDetailsService  ◄── your AppUserDetailsService bean
        └── passwordEncoder     ◄── your PasswordEncoder bean
```

You don't write this connection yourself. You only need both beans to exist. The next part shows the explicit version so you can see what Spring builds.

## Part 3: The Complete Example

### Step 1: The Entity

```java
import jakarta.persistence.*;

@Entity
@Table(name = "app_users")
public class AppUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)  // database assigns the id
    private Long id;

    @Column(nullable = false, unique = true)             // login name, must be unique
    private String username;

    @Column(nullable = false)                            // stores the BCrypt HASH only
    private String password;

    @Column(nullable = false)                            // plain role name, e.g. "USER"
    private String role;

    protected AppUser() {}                               // required by JPA

    public AppUser(String username, String password, String role) {
        this.username = username;
        this.password = password;
        this.role = role;
    }

    public Long getId()         { return id; }
    public String getUsername() { return username; }
    public String getPassword() { return password; }
    public String getRole()     { return role; }
}
```

The entity is a plain database mapping. It has no security logic and no encoding logic. Its `password` field holds whatever value it receives, so the service layer must make sure that value is a hash.

### Step 2: The Repository

```java
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByUsername(String username);  // Spring Data writes the SQL
}
```

Spring Data generates the query from the method name. `Optional` makes the missing-user case explicit.

### Step 3: The PasswordEncoder Bean

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class PasswordConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(10);   // strength 10 = 2^10 rounds
    }
}
```

This is a single shared encoder for the whole application. Keeping it in its own class makes it easy to find, and it prevents a circular dependency that can occur if the encoder is defined in the same class as the security filter chain.

### Step 4: The UserDetailsService

This class does two jobs. It supplies stored users during login, and it saves new users during registration. It encodes passwords on the write side.

```java
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsManager;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

@Service
public class AppUserDetailsService implements UserDetailsManager {

    private final AppUserRepository repository;
    private final PasswordEncoder passwordEncoder;

    public AppUserDetailsService(AppUserRepository repository, PasswordEncoder passwordEncoder) {
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
    }

    // ----- LOGIN SIDE: called by Spring, never by you -----

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser user = repository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));

        // Return the stored HASH inside UserDetails. Spring compares it with matches().
        return org.springframework.security.core.userdetails.User
                .withUsername(user.getUsername())
                .password(user.getPassword())
                .authorities(List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole())))
                .build();
    }

    // ----- REGISTRATION SIDE: called by your controller -----

    @Override
    public void createUser(UserDetails details) {
        if (userExists(details.getUsername())) {
            throw new IllegalArgumentException("Username already exists: " + details.getUsername());
        }

        String role = details.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .findFirst()
                .map(a -> a.replace("ROLE_", ""))
                .orElse("USER");

        // Encode HERE, the single place where passwords become hashes.
        // The incoming password is raw, so it must be hashed before saving.
        String hash = passwordEncoder.encode(details.getPassword());

        repository.save(new AppUser(details.getUsername(), hash, role));
    }

    @Override
    public boolean userExists(String username) {
        return repository.findByUsername(username).isPresent();
    }

    // ----- Not needed for this lesson -----

    @Override
    public void updateUser(UserDetails user) {
        throw new UnsupportedOperationException("Not implemented yet");
    }

    @Override
    public void deleteUser(String username) {
        throw new UnsupportedOperationException("Not implemented yet");
    }

    @Override
    public void changePassword(String oldPassword, String newPassword) {
        throw new UnsupportedOperationException("Not implemented yet");
    }
}
```

Notice the change from the previous lesson. The service now holds the `PasswordEncoder` and calls `encode()` inside `createUser`. Because of that, the controller can pass a raw password and the service handles the hashing. The rule now lives in one place, so no caller can skip it.

Also notice that `createUser` receives a `UserDetails` whose password is **raw**. That is the opposite of the earlier lesson, where the controller hashed the password first. Choose one approach and keep it consistent across the project.

### Step 5: The Registration Controller

```java
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
public class RegistrationController {

    private final AppUserDetailsService userService;

    public RegistrationController(AppUserDetailsService userService) {
        this.userService = userService;
    }

    public record RegisterRequest(String username, String password) {}

    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody RegisterRequest request) {

        // Build the UserDetails with the RAW password.
        // createUser() will encode it before saving.
        UserDetails details = User.withUsername(request.username())
                .password(request.password())
                .roles("USER")
                .build();

        userService.createUser(details);
        return ResponseEntity.ok("User registered: " + request.username());
    }
}
```

### Step 6: Security Configuration

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/register").permitAll()
                .anyRequest().authenticated()
            )
            .httpBasic(Customizer.withDefaults());

        return http.build();
    }
}
```

Spring Boot sees your `AppUserDetailsService` and `PasswordEncoder` beans and builds the `DaoAuthenticationProvider` from them. You don't need to declare it.

**Optional: the explicit version.** If you want to see the connection, you can declare the provider yourself. Setter names have changed between Spring Security versions, so check the documentation for yours:

```java
@Bean
public DaoAuthenticationProvider authenticationProvider(AppUserDetailsService userService,
                                                        PasswordEncoder passwordEncoder) {
    DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
    provider.setUserDetailsService(userService);  // where to load users from
    provider.setPasswordEncoder(passwordEncoder); // how to compare passwords
    return provider;
}
```

Use this when you need custom behavior. For a standard setup, Spring Boot's automatic wiring is enough.

## Part 4: Testing on Debian

Start the app from your project folder:

```bash
./mvnw spring-boot:run
```

Register a user:

```bash
curl -X POST http://localhost:8080/register \
     -H "Content-Type: application/json" \
     -d '{"username":"carol","password":"mypass789"}'
```

Log in with the correct password:

```bash
curl -u carol:mypass789 http://localhost:8080/hello
# Output: Hello! You are logged in.
```

Log in with a wrong password:

```bash
curl -i -u carol:wrongpass http://localhost:8080/hello
# Output: HTTP/1.1 401 Unauthorized
```

Check the database at `http://localhost:8080/h2-console` (enabled earlier in `application.properties`). Run:

```sql
SELECT username, password, role FROM app_users;
```

The `password` value for `carol` should start with `$2a$10$`, and it should not equal `mypass789`. Register a second user with the same password, and the two hashes will differ because each has its own salt.

## Part 5: Common Mistakes

|Mistake|What happens|Fix|
|---|---|---|
|Saving the raw password|Login always fails, and any leak exposes real passwords|Call `encode()` before `save()`|
|Encoding twice (controller and service)|The stored value is a hash of a hash, and login never matches|Encode in exactly one layer|
|Encoding during login|`matches()` compares against a fresh salt, so it always fails|Let Spring call `matches()`|
|Using `NoOpPasswordEncoder` or `{noop}`|Passwords are stored as plain text|Use `BCryptPasswordEncoder`|
|Mixing old and new encoders|Existing hashes stop matching after a change|Use `DelegatingPasswordEncoder` for migrations|

## Part 6: Summary

|Component|Role in the password flow|
|---|---|
|`PasswordEncoder.encode()`|Converts a raw password into a hash, at registration|
|`PasswordEncoder.matches()`|Compares a typed password with a stored hash, at login|
|`loadUserByUsername()`|Supplies the stored hash to Spring during login|
|`createUser()`|Encodes the raw password and saves the user|
|`DaoAuthenticationProvider`|Connects the service and the encoder, and calls `matches()`|

## Practice Exercises

1. Register the same password for two users, then confirm that their hashes differ in the H2 console.
2. Temporarily move the `encode()` call from `createUser` into the controller. Register a user and try to log in. Explain why the login fails, then move the call back.
3. Change the BCrypt strength to 12 and register a new user. Compare the cost factor in the two hashes.
4. Implement `changePassword(oldPassword, newPassword)` using `SecurityContextHolder` to find the current user. Check the old password with `matches()`, then save the `encode()`d new one.




[[Spring Security]]