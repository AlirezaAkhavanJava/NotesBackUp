

Knowing Spring Security's pieces (filters, `Authentication`, `AuthenticationManager`, JWT) is like knowing the parts of an engine. Building a real app means deciding how those parts fit together, and in which order you build them. Most people get stuck because they start coding the filter first. The right start is a few design decisions made on paper, then a fixed build order.

In this lesson you get one design pattern to follow: **a self-contained security layer with a fixed build order**. You decide five things first, put all security code in its own package, and build it step by step, testing each step before the next.

## Part 1: Five decisions before any code

Write these down for your app. Every class you create later follows from them.

|Decision|Common choice for a REST API|Why|
|---|---|---|
|How do users prove who they are?|Username/email + password at login|Simplest to start|
|How do we remember them between requests?|Stateless JWT in the `Authorization: Bearer` header|No server session, fits REST and Docker|
|What are the roles?|`USER`, `ADMIN` (an enum)|Start tiny, grow later|
|Where do we enforce rules?|URL rules in config + `@PreAuthorize` on methods|URLs for broad rules, methods for fine rules|
|How do failures look?|JSON with 401 (not logged in) and 403 (not allowed)|Frontends need predictable errors|

Remember the difference between the two failures, because you will implement both:

- **401 Unauthorized** means "I don't know who you are" (no token, bad token).
- **403 Forbidden** means "I know who you are, but you may not do this."

## Part 2: The pattern, a security layer with a build order

Keep security code in one package so it never gets mixed into business logic:

```
com.example.app
├── security/
│   ├── config/        SecurityConfig, PasswordConfig
│   ├── jwt/           JwtService, JwtAuthenticationFilter
│   ├── user/          AppUserDetails, AppUserDetailsService
│   └── handler/       AuthEntryPoint, AccessDeniedHandlerImpl
├── auth/              AuthController, AuthService, LoginRequest, RegisterRequest, AuthResponse
├── user/              User (entity), Role (enum), UserRepository
└── ...your business features (movies, habits, etc.)
```

Notice the split. `security/` is the _machinery_. `auth/` is the _feature_ (register and login endpoints). `user/` is _data_. Your business code never touches JWTs or filters. It only asks "who is the current user?" and "is this allowed?".

**The build order.** Build in this order, because each step depends on the one before it:

|Step|You build|You can test it by|
|---|---|---|
|1|`Role` enum, `User` entity, `UserRepository`|Saving a user in the database|
|2|`PasswordEncoder` bean|Encoding a password in a test|
|3|`UserDetails` wrapper + `UserDetailsService`|Loading a user by email|
|4|Minimal `SecurityConfig` (everything open except auth endpoints)|App starts, no default password in the log|
|5|`AuthService` + `AuthController`: register|POST creates a user with a hashed password|
|6|`JwtService`|A unit test that creates and parses a token|
|7|Login (`AuthenticationManager` + JWT)|POST returns a token|
|8|`JwtAuthenticationFilter` + wire it into the chain|A protected endpoint works with the token and returns 401 without it|
|9|Roles on endpoints (URL rules + `@PreAuthorize`)|USER gets 403 on an admin endpoint|
|10|Custom 401/403 JSON handlers|Errors look the same everywhere|
|11|CORS (only if you have a browser frontend)|Frontend can call the API|
|12|Security tests (`@WithMockUser`, MockMvc)|Tests protect you from breaking security later|

## Part 3: The code, step by step

### Steps 1 to 3: Users and roles

```java
public enum Role { USER, ADMIN }
```

```java
@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String password;      // always the HASH, never plain text

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role = Role.USER;
}
```

Walkthrough: `EnumType.STRING` stores `"ADMIN"` instead of `1`, so reordering the enum later can't silently change everyone's role. The default of `Role.USER` means nobody becomes admin by accident.

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
```

Now the bridge between your `User` and Spring Security. I recommend a **wrapper** instead of making the entity implement `UserDetails`. This keeps your entity free of security code:

```java
public class AppUserDetails implements UserDetails {
    private final User user;
    public AppUserDetails(User user) { this.user = user; }

    public User getUser() { return user; }

    @Override public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()));
    }
    @Override public String getPassword() { return user.getPassword(); }
    @Override public String getUsername() { return user.getEmail(); }
    // isAccountNonExpired, isAccountNonLocked, isCredentialsNonExpired, isEnabled -> return true
}
```

The `ROLE_` prefix matters: `hasRole("ADMIN")` looks for the authority `ROLE_ADMIN`.

```java
@Service
@RequiredArgsConstructor
public class AppUserDetailsService implements UserDetailsService {
    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String email) {
        return userRepository.findByEmail(email)
                .map(AppUserDetails::new)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }
}
```

This is the one method Spring Security calls when it needs "give me the user with this name."

```java
@Configuration
public class PasswordConfig {
    @Bean
    public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }
}
```

I put this in its own class on purpose. If `SecurityConfig` also needs the encoder through constructor injection, you can get a circular dependency.

### Step 4 and 8 to 10: The central SecurityConfig

This is the "map" of your security. Read it as the one place that answers "who can reach what?"

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtFilter;
    private final AuthEntryPoint authEntryPoint;
    private final AccessDeniedHandlerImpl accessDeniedHandler;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .exceptionHandling(e -> e
                .authenticationEntryPoint(authEntryPoint)
                .accessDeniedHandler(accessDeniedHandler))
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
```

Line by line:

- `csrf.disable()` is fine for a stateless token API (no cookies carry the login). Don't disable it if you use cookie sessions.
- `STATELESS` tells Spring never to create an `HttpSession`. Every request must carry its own token.
- The rules are read **top to bottom, first match wins**. So specific rules go first and `anyRequest().authenticated()` goes last. This is the "deny by default" rule: anything you forgot to list is protected.
- `addFilterBefore(...)` puts your JWT filter early, so by the time the request reaches the controller the `SecurityContext` is already filled.
- Boot finds your `UserDetailsService` and `PasswordEncoder` beans on its own and builds the `DaoAuthenticationProvider` for you. You don't need to wire it by hand.

### Steps 5 to 7: Register and login

```java
@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthResponse register(RegisterRequest req) {
        if (userRepository.existsByEmail(req.email())) {
            throw new IllegalStateException("Email already in use");
        }
        User user = new User();
        user.setEmail(req.email());
        user.setPassword(passwordEncoder.encode(req.password()));
        userRepository.save(user);                       // role defaults to USER
        return new AuthResponse(jwtService.generateToken(new AppUserDetails(user)));
    }

    public AuthResponse login(LoginRequest req) {
        Authentication auth = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(req.email(), req.password()));
        AppUserDetails principal = (AppUserDetails) auth.getPrincipal();
        return new AuthResponse(jwtService.generateToken(principal));
    }
}
```

Two design points here:

1. **Registration never accepts a role from the client.** If your `RegisterRequest` had a `role` field, anyone could register as `ADMIN`. The server decides roles.
2. **Login delegates to `AuthenticationManager`.** You never compare passwords yourself. If the password is wrong it throws `BadCredentialsException`, and you handle that in your exception handler.

The `JwtService` (step 6) and `JwtAuthenticationFilter` (step 8) are the ones you already studied. The filter's job is always the same four moves: read the header, extract the username, validate the token, put an `Authentication` into `SecurityContextHolder`.

### Step 9: Two layers of rules

Use both, for different jobs:

```java
// Coarse rule: in SecurityConfig (whole URL areas)
.requestMatchers("/api/admin/**").hasRole("ADMIN")

// Fine rule: on the method (business-level rules)
@PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.user.id")
public UserDto getUser(Long userId) { ... }
```

The method rule is where "a user can edit only **their own** data" lives. URL rules can't express that, because they don't know about your data.

### Step 10: Clean 401 and 403 responses

```java
@Component
public class AuthEntryPoint implements AuthenticationEntryPoint {
    @Override
    public void commence(HttpServletRequest req, HttpServletResponse res, AuthenticationException ex)
            throws IOException {
        res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        res.setContentType("application/json");
        res.getWriter().write("{\"error\":\"Unauthorized\",\"message\":\"Login required\"}");
    }
}
```

`AccessDeniedHandlerImpl` is the same shape with status 403. Without these, errors from the filter chain come out in Spring's default format, which won't match the rest of your API.

## Part 4: The design rules (the real "pattern")

Keep these as your checklist for every future question:

1. **Deny by default.** End the rules with `anyRequest().authenticated()` and open things deliberately.
2. **Server decides identity and roles.** Never trust a user id or role sent in the request body. Read it from the `Authentication`.
3. **Hash passwords with BCrypt.** Never log passwords or tokens.
4. **Keep security out of business code.** Controllers and services use `@PreAuthorize` or ask for the current user, nothing more.
5. **DTOs at the edge.** Never return your `User` entity from a controller (the password hash would leak). Return a `UserDto`.
6. **One concern per class.** Filter reads tokens, service creates tokens, config declares rules.
7. **Don't reveal which part of login failed.** Say "invalid email or password," never "email not found."
8. **Secrets come from the environment**, not from your source code (the JWT secret especially).

## Part 5: A related concept in brief

**Refresh tokens.** A short-lived access token (about 15 minutes) limits the damage if one leaks. A longer-lived refresh token (stored in the database) lets the client quietly get a new access token without logging in again. Add this _after_ the basic flow works, not before.




[[Spring Framework]]