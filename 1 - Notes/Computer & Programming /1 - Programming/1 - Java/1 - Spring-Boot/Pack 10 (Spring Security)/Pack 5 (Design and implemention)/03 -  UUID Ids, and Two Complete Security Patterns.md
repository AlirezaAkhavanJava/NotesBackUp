

A **UUID** (Universally Unique Identifier) is a 128-bit value, usually written as 36 characters like `f47ac10b-58cc-4372-a567-0e02b2c3d479`. Instead of the database counting up (1, 2, 3...), your application generates an id that is, for all practical purposes, unique across every table, server and company in the world. Nobody has to coordinate. That is why you see it in so many projects.

This lesson has three parts. First you learn UUIDs properly, including the one version you should pick and the traps. Then you get **Pattern A**, the complete assembled design of everything we covered, shown as code with no re-explaining. Last you get **Pattern B**, the access-token plus refresh-token design that most production apps use, shown as the changes on top of Pattern A. (Versions assumed: Spring Boot 3.3+, Hibernate 6.5+, jjwt 0.12.)

## Part 1: Learning UUID

### What the text means

|Piece|Example|Meaning|
|---|---|---|
|Format|`8-4-4-4-12` hex digits|32 hex digits = 128 bits|
|Version digit|first digit of the 3rd group|Tells you how it was generated|
|v4 example|`f47ac10b-58cc-`**4**`372-a567-0e02b2c3d479`|Almost all bits random|
|v7 example|`018f3b5e-7c2a-`**7**`d4b-9a1e-3f5c8b2d1a90`|Starts with a millisecond timestamp, rest random|

### Which version to use

|Version|Built from|Sorted by creation time?|Verdict|
|---|---|---|---|
|v1|Time + machine MAC address|Roughly|Avoid: leaks the machine address|
|v4|Pure randomness (`UUID.randomUUID()`)|No|Fine for small tables, tokens of no importance|
|v7|Timestamp prefix + randomness|**Yes**|**Best default for database ids**|

Why v7 matters for databases: a table's primary key lives in a B-tree index. With v4, every new row lands at a random spot in that index, so the database keeps splitting pages and its cache works poorly. With v7, new ids always land near the end, like a normal counter, while still being unguessable and generated in your app.

### Honest pros and cons

|Benefit|Cost|
|---|---|
|Ids don't reveal how many users you have|16 bytes instead of 8 (bigger indexes)|
|`/api/users/42` can't be walked through 43, 44, 45...|Harder to read and type when debugging|
|Generated in Java, no round trip to know the id|v4 hurts index performance (use v7)|
|Safe to merge data from several systems||

### The big warning

A UUID is **not** an access-control tool. Hiding the id only makes guessing harder. If `GET /api/orders/{uuid}` doesn't check that the order belongs to the caller, anyone who obtains one id (a shared link, a log file) can read it. Keep your ownership checks (`@PreAuthorize`, or a query filtered by the current user). Also, never use a UUID as a secret token; secrets should come from `SecureRandom` with 256 bits (Pattern B does this).

### Using it in Spring and PostgreSQL

```java
@Id
@GeneratedValue
@UuidGenerator(style = UuidGenerator.Style.VERSION_7)   // Hibernate 6.5+; older: @GeneratedValue(strategy = GenerationType.UUID) gives v4
@Setter(AccessLevel.NONE)
private UUID id;
```

```java
public interface UserCredentialsRepository extends JpaRepository<UserCredentials, UUID> { ... }
```

Rules to remember:

- In PostgreSQL the column type must be **`uuid`** (16 bytes), never `varchar(36)` (36 bytes plus slower comparisons). Hibernate maps `java.util.UUID` to it automatically.
- In controllers, use `@PathVariable UUID id`. A malformed value like `/api/users/abc` is rejected automatically with a 400, before your code runs.
- Foreign keys must also be `uuid`.
- UUIDs are case-insensitive hex; always compare them as `UUID` objects, not as strings.

### A related concept in brief: the hybrid id

Some teams keep a `bigint` primary key internally (small, fast joins) and add a separate `public_id uuid` column that is the only id ever shown in URLs and JSON. You get fast joins plus unguessable public ids, at the price of two identifiers per row. With v7 you usually don't need it, but you will see it in older projects.

## Part 2: Pattern A, the complete stateless design

This is everything from the previous lessons, assembled. No explanations except where UUID changed something.

### Package layout

```
com.example.app
├── security/
│   ├── config/    SecurityConfig, PasswordConfig
│   ├── jwt/       JwtService, JwtAuthenticationFilter
│   ├── user/      AppUserDetails, AppUserDetailsService
│   └── handler/   AuthEntryPoint, AccessDeniedHandlerImpl
├── auth/          AuthController, AuthService, dto/, validation/
├── user/          UserCredentials, Role, UserCredentialsRepository, MeController
└── common/        GlobalExceptionHandler, DuplicateCredentialException
```

### Database migration (Flyway, `V1__credentials.sql`)

```sql
CREATE TABLE user_credentials (
    id            uuid         PRIMARY KEY,
    email         varchar(254) NOT NULL,
    username      varchar(30)  NOT NULL,
    password_hash varchar(100) NOT NULL,
    role          varchar(20)  NOT NULL,
    enabled       boolean      NOT NULL DEFAULT true,
    locked        boolean      NOT NULL DEFAULT false,
    created_at    timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uk_credentials_email    UNIQUE (email),
    CONSTRAINT uk_credentials_username UNIQUE (username),
    CONSTRAINT ck_credentials_email_lower CHECK (email = lower(email)),
    CONSTRAINT ck_credentials_username_lower CHECK (username = lower(username))
);
```

The two `CHECK` constraints make the database itself refuse un-normalized values.

### Data

```java
public enum Role { USER, ADMIN }
```

```java
@Entity
@Table(name = "user_credentials")
@Getter @Setter @NoArgsConstructor
@ToString(exclude = "passwordHash")
public class UserCredentials {
    @Id @GeneratedValue
    @UuidGenerator(style = UuidGenerator.Style.VERSION_7)
    @Setter(AccessLevel.NONE)
    private UUID id;

    @Column(nullable = false, length = 254) private String email;
    @Column(nullable = false, length = 30)  private String username;
    @Column(name = "password_hash", nullable = false, length = 100) private String passwordHash;

    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20)
    private Role role = Role.USER;

    @Column(nullable = false) private boolean enabled = true;
    @Column(nullable = false) private boolean locked = false;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}
```

```java
public interface UserCredentialsRepository extends JpaRepository<UserCredentials, UUID> {
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);
    Optional<UserCredentials> findByEmailOrUsername(String email, String username);
}
```

### DTOs and validation

```java
public record RegisterRequest(
    @NotBlank @Email @Size(max = 254)                String email,
    @NotBlank @ValidUsername                         String username,
    @NotBlank @Size(min = 8, max = 72)
    @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d).+$", message = "Password must contain a letter and a digit")
                                                     String password) {}

public record LoginRequest(@NotBlank @Size(max = 254) String identifier,
                           @NotBlank @Size(max = 128) String password) {}

public record AuthResponse(String accessToken) {}
public record MeResponse(UUID id, String email, String username, Role role) {}
```

`@ValidUsername` and `UsernameValidator` are exactly as in the previous lesson (pattern `^[A-Za-z][A-Za-z0-9_]{2,29}$` plus the reserved-name list).

### Security machinery

```java
@Configuration
public class PasswordConfig {
    @Bean PasswordEncoder passwordEncoder() { return PasswordEncoderFactories.createDelegatingPasswordEncoder(); }
}
```

```java
public class AppUserDetails implements UserDetails {
    private final UserCredentials c;
    public AppUserDetails(UserCredentials c) { this.c = c; }

    public UUID getId()                      { return c.getId(); }
    public UserCredentials getCredentials()  { return c; }

    @Override public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + c.getRole().name()));
    }
    @Override public String  getPassword()  { return c.getPasswordHash(); }
    @Override public String  getUsername()  { return c.getEmail(); }
    @Override public boolean isEnabled()               { return c.isEnabled(); }
    @Override public boolean isAccountNonLocked()      { return !c.isLocked(); }
    @Override public boolean isAccountNonExpired()     { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
}
```

```java
@Service
@RequiredArgsConstructor
public class AppUserDetailsService implements UserDetailsService {
    private final UserCredentialsRepository repository;

    @Override
    public UserDetails loadUserByUsername(String identifier) {
        String id = identifier.trim().toLowerCase();
        return repository.findByEmailOrUsername(id, id)
                .map(AppUserDetails::new)
                .orElseThrow(() -> new UsernameNotFoundException("Invalid credentials"));
    }
}
```

```java
@Service
public class JwtService {
    @Value("${app.jwt.secret}")        private String secret;        // Base64, at least 256 bits
    @Value("${app.jwt.expiration-ms}") private long expirationMs;

    private SecretKey key() { return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret)); }

    public String generateToken(AppUserDetails user) {
        Date now = new Date();
        return Jwts.builder()
                .subject(user.getUsername())
                .claim("uid", user.getId().toString())
                .claim("role", user.getCredentials().getRole().name())
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expirationMs))
                .signWith(key())
                .compact();
    }

    public String extractUsername(String token) { return claims(token).getSubject(); }

    public boolean isTokenValid(String token, UserDetails user) {
        Claims c = claims(token);
        return c.getSubject().equals(user.getUsername())
            && c.getExpiration().after(new Date())
            && user.isEnabled() && user.isAccountNonLocked();     // disabled users lose access immediately
    }

    private Claims claims(String token) {
        return Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload();
    }
}
```

```java
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtService jwtService;
    private final AppUserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header == null || !header.startsWith("Bearer ")) { chain.doFilter(request, response); return; }
        try {
            String token = header.substring(7);
            String username = jwtService.extractUsername(token);
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails user = userDetailsService.loadUserByUsername(username);
                if (jwtService.isTokenValid(token, user)) {
                    var auth = UsernamePasswordAuthenticationToken.authenticated(user, null, user.getAuthorities());
                    auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            }
        } catch (JwtException | UsernameNotFoundException ignored) {
            // no authentication set; the entry point answers 401
        }
        chain.doFilter(request, response);
    }
}
```

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
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .cors(Customizer.withDefaults())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .exceptionHandling(e -> e
                .authenticationEntryPoint(authEntryPoint)
                .accessDeniedHandler(accessDeniedHandler))
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    @Bean
    AuthenticationProvider authenticationProvider(AppUserDetailsService uds, PasswordEncoder encoder) {
        DaoAuthenticationProvider p = new DaoAuthenticationProvider(uds);
        p.setPasswordEncoder(encoder);
        return p;
    }

    @Bean
    AuthenticationManager authenticationManager(AuthenticationProvider provider) {
        return new ProviderManager(provider);
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(@Value("${app.cors.origins}") List<String> origins) {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOrigins(origins);                      // explicit list, never "*" with credentials
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE"));
        cfg.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/api/**", cfg);
        return src;
    }
}
```

```java
@Component
public class AuthEntryPoint implements AuthenticationEntryPoint {
    @Override
    public void commence(HttpServletRequest req, HttpServletResponse res, AuthenticationException ex) throws IOException {
        res.setStatus(401);
        res.setContentType("application/json");
        res.getWriter().write("{\"status\":401,\"error\":\"Unauthorized\",\"message\":\"Login required\"}");
    }
}

@Component
public class AccessDeniedHandlerImpl implements AccessDeniedHandler {
    @Override
    public void handle(HttpServletRequest req, HttpServletResponse res, AccessDeniedException ex) throws IOException {
        res.setStatus(403);
        res.setContentType("application/json");
        res.getWriter().write("{\"status\":403,\"error\":\"Forbidden\",\"message\":\"Not allowed\"}");
    }
}
```

### Feature code

```java
@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserCredentialsRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    @Transactional
    public void register(RegisterRequest req) {
        String email = req.email().trim().toLowerCase();
        String username = req.username().trim().toLowerCase();
        if (repository.existsByEmail(email))       throw new DuplicateCredentialException("Email already in use");
        if (repository.existsByUsername(username)) throw new DuplicateCredentialException("Username already taken");

        UserCredentials c = new UserCredentials();
        c.setEmail(email);
        c.setUsername(username);
        c.setPasswordHash(passwordEncoder.encode(req.password()));
        try { repository.save(c); }
        catch (DataIntegrityViolationException e) { throw new DuplicateCredentialException("Email or username already in use"); }
    }

    public AuthResponse login(LoginRequest req) {
        Authentication auth = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(req.identifier().trim().toLowerCase(), req.password()));
        return new AuthResponse(jwtService.generateToken((AppUserDetails) auth.getPrincipal()));
    }
}
```

```java
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<Void> register(@Valid @RequestBody RegisterRequest req) {
        authService.register(req);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest req) { return authService.login(req); }
}

@RestController
public class MeController {
    @GetMapping("/api/me")
    public MeResponse me(@AuthenticationPrincipal AppUserDetails p) {
        UserCredentials c = p.getCredentials();
        return new MeResponse(c.getId(), c.getEmail(), c.getUsername(), c.getRole());
    }

    @GetMapping("/api/users/{id}")
    @PreAuthorize("hasRole('ADMIN') or #id == authentication.principal.id")   // UUID compared as UUID
    public MeResponse byId(@PathVariable UUID id) { /* load via your service */ return null; }
}
```

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ProblemDetail validation(MethodArgumentNotValidException ex) {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        Map<String, String> errors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(e -> errors.putIfAbsent(e.getField(), e.getDefaultMessage()));
        pd.setProperty("errors", errors);
        return pd;
    }

    @ExceptionHandler(DuplicateCredentialException.class)
    ProblemDetail duplicate(DuplicateCredentialException ex) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage());
    }

    @ExceptionHandler(BadCredentialsException.class)
    ProblemDetail badCredentials() {
        return ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED, "Invalid credentials");
    }

    @ExceptionHandler({DisabledException.class, LockedException.class})
    ProblemDetail blocked() {
        return ProblemDetail.forStatusAndDetail(HttpStatus.FORBIDDEN, "Account unavailable");
    }
}

public class DuplicateCredentialException extends RuntimeException {
    public DuplicateCredentialException(String message) { super(message); }
}
```

### application.properties

```properties
spring.jpa.hibernate.ddl-auto=validate
spring.flyway.enabled=true
app.jwt.secret=${JWT_SECRET}
app.jwt.expiration-ms=900000
app.cors.origins=${CORS_ORIGINS}
```

### Where Pattern A is weak

|Limit|Consequence|
|---|---|
|The access token is valid until it expires|You can't log a user out or revoke a stolen token early|
|A longer lifetime is more convenient but riskier|You are forced to pick between safety and "stay logged in"|

That gap is exactly what Pattern B closes.

## Part 3: Pattern B, short access token plus rotating refresh token

This is the pattern most production APIs use. **Keep Pattern A and change only the following.**

### The idea

|Token|Lifetime|Where it lives|Server stores it?|
|---|---|---|---|
|Access token (JWT)|About 15 minutes|Memory of the client, sent in the `Authorization` header|No (stateless)|
|Refresh token|About 14 days|`HttpOnly` cookie, invisible to JavaScript|**Yes, as a hash**|

When the access token expires, the client calls `/refresh`. The server checks the refresh token, **replaces it with a new one** (rotation), and returns a new access token. Logging out or detecting theft means revoking server-side refresh records, which is something Pattern A can't do.

### New migration (`V2__refresh_tokens.sql`)

```sql
CREATE TABLE refresh_tokens (
    id         uuid        PRIMARY KEY,
    user_id    uuid        NOT NULL REFERENCES user_credentials(id) ON DELETE CASCADE,
    family_id  uuid        NOT NULL,
    token_hash char(64)    NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    used       boolean     NOT NULL DEFAULT false,
    revoked    boolean     NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_user   ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_family ON refresh_tokens(family_id);
```

A **family** is the chain of tokens created from one login. It is what lets you kill an entire session at once.

### Entity and repository

```java
@Entity
@Table(name = "refresh_tokens")
@Getter @Setter @NoArgsConstructor
public class RefreshToken {
    @Id @GeneratedValue @UuidGenerator(style = UuidGenerator.Style.VERSION_7)
    @Setter(AccessLevel.NONE)
    private UUID id;
    @Column(name = "user_id", nullable = false)    private UUID userId;
    @Column(name = "family_id", nullable = false)  private UUID familyId;
    @Column(name = "token_hash", nullable = false, length = 64) private String tokenHash;
    @Column(name = "expires_at", nullable = false) private Instant expiresAt;
    @Column(nullable = false) private boolean used;
    @Column(nullable = false) private boolean revoked;
}

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)               // two tabs refreshing at once must not both win
    Optional<RefreshToken> findByTokenHash(String tokenHash);

    @Modifying
    @Query("update RefreshToken t set t.revoked = true where t.familyId = :family")
    void revokeFamily(@Param("family") UUID family);

    @Modifying
    @Query("delete from RefreshToken t where t.expiresAt < :now")
    int deleteExpired(@Param("now") Instant now);
}
```

### The service

```java
@Service
@RequiredArgsConstructor
public class RefreshTokenService {
    private static final SecureRandom RANDOM = new SecureRandom();

    private final RefreshTokenRepository repository;
    @Value("${app.jwt.refresh-days}") private long refreshDays;

    public record Rotation(UUID userId, String newRawToken) {}

    @Transactional
    public String issueNewFamily(UUID userId) { return issue(userId, UUID.randomUUID()); }

    @Transactional(noRollbackFor = InvalidRefreshTokenException.class)   // keep the revoke even though we throw
    public Rotation rotate(String rawToken) {
        RefreshToken t = repository.findByTokenHash(sha256(rawToken))
                .orElseThrow(InvalidRefreshTokenException::new);

        if (t.isUsed()) {                                  // an already-used token came back: likely stolen
            repository.revokeFamily(t.getFamilyId());
            throw new InvalidRefreshTokenException();
        }
        if (t.isRevoked() || t.getExpiresAt().isBefore(Instant.now())) throw new InvalidRefreshTokenException();

        t.setUsed(true);
        return new Rotation(t.getUserId(), issue(t.getUserId(), t.getFamilyId()));
    }

    @Transactional
    public void revokeByRawToken(String rawToken) {
        repository.findByTokenHash(sha256(rawToken)).ifPresent(t -> repository.revokeFamily(t.getFamilyId()));
    }

    @Scheduled(cron = "0 0 3 * * *")                       // needs @EnableScheduling
    @Transactional
    public void cleanup() { repository.deleteExpired(Instant.now()); }

    private String issue(UUID userId, UUID familyId) {
        byte[] bytes = new byte[32];                       // 256 random bits
        RANDOM.nextBytes(bytes);
        String raw = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        RefreshToken t = new RefreshToken();
        t.setUserId(userId);
        t.setFamilyId(familyId);
        t.setTokenHash(sha256(raw));
        t.setExpiresAt(Instant.now().plus(Duration.ofDays(refreshDays)));
        repository.save(t);
        return raw;                                        // shown to the client once, never stored
    }

    private static String sha256(String s) {
        try {
            return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) { throw new IllegalStateException(e); }
    }
}
```

Design notes that are different from passwords:

- **SHA-256, not BCrypt.** The token is 256 random bits and can't be guessed, so a fast hash is enough, and you need to look the row up _by_ the hash. BCrypt is for low-entropy human passwords.
- **`noRollbackFor`** is critical. Without it, throwing the exception rolls back the transaction and **undoes the family revocation** you just did.
- **The raw token is never stored**, so a database leak doesn't hand out working sessions.

### Controller changes

```java
@PostMapping("/login")
public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest req) {
    AuthService.LoginResult r = authService.login(req);      // now returns access token + raw refresh token
    return ResponseEntity.ok()
            .header(HttpHeaders.SET_COOKIE, refreshCookie(r.refreshToken(), Duration.ofDays(14)).toString())
            .body(new AuthResponse(r.accessToken()));
}

@PostMapping("/refresh")
public ResponseEntity<AuthResponse> refresh(@CookieValue("refresh_token") String raw) {
    AuthService.LoginResult r = authService.refresh(raw);
    return ResponseEntity.ok()
            .header(HttpHeaders.SET_COOKIE, refreshCookie(r.refreshToken(), Duration.ofDays(14)).toString())
            .body(new AuthResponse(r.accessToken()));
}

@PostMapping("/logout")
public ResponseEntity<Void> logout(@CookieValue(value = "refresh_token", required = false) String raw) {
    if (raw != null) authService.logout(raw);
    return ResponseEntity.noContent()
            .header(HttpHeaders.SET_COOKIE, refreshCookie("", Duration.ZERO).toString())
            .build();
}

private ResponseCookie refreshCookie(String value, Duration maxAge) {
    return ResponseCookie.from("refresh_token", value)
            .httpOnly(true).secure(true).sameSite("Strict")
            .path("/api/auth")                              // sent only to the auth endpoints
            .maxAge(maxAge).build();
}
```

In `AuthService`, `login` also calls `refreshTokenService.issueNewFamily(userId)`. `refresh` calls `rotate(raw)`, loads the user by `userId`, refuses if `!enabled || locked`, and builds a new access token. `logout` calls `revokeByRawToken(raw)`. Change `app.jwt.expiration-ms` to `900000` (15 minutes) and add `app.jwt.refresh-days=14`.

Because the refresh cookie is sent automatically by the browser, `SameSite=Strict` and the narrow `path` are your protection against CSRF on `/refresh`. Keep both.

### Flow summary

|Event|What happens|
|---|---|
|Login|New family created; access token in body, refresh token in cookie|
|Access token expires|Client calls `/refresh`; old refresh token marked `used`, new one issued in the same family|
|Old refresh token replayed|Whole family revoked, request rejected; the real user must log in again|
|Logout|Family revoked, cookie cleared|
|Admin disables a user|Access token stops working at the next request (the filter checks flags), and refresh is refused|

## Choosing between patterns

|Pattern|Best when|Trade-off|
|---|---|---|
|A: access JWT only|Learning, prototypes, internal tools|Can't revoke early|
|**B: access plus rotating refresh**|**Public APIs, SPAs and mobile apps**|More code and one table|
|Server sessions with Spring Session and Redis|Server-rendered sites, easy instant logout|Needs shared session storage, CSRF protection back on|
|OAuth2 resource server with Keycloak or Auth0|Many apps or SSO, or you don't want to own passwords|Another system to run, a steeper learning curve|

My recommendation: finish your app with Pattern A, then move to Pattern B before anyone real uses it. It reuses almost everything.

## Production checklist

|Area|Do this|
|---|---|
|Secrets|JWT secret from environment or a secret manager, never in Git|
|Transport|HTTPS only; `Secure` cookies; HSTS at the proxy|
|Brute force|Rate-limit `/login` and `/refresh` (at Nginx or with Bucket4j) and add a failed-attempt counter that sets `locked` temporarily|
|Database|Flyway migrations, `ddl-auto=validate`, least-privilege DB user|
|Tokens|Short access TTL, refresh cleanup job, optional `kid` header so you can rotate the signing key|
|Errors|Same message for unknown user and wrong password; never return stack traces|
|Logging|Log login failures and refresh reuse events; never log passwords or tokens|
|CORS|Explicit origin list per environment|
|Tests|MockMvc tests for 401, 403, validation, duplicate registration, refresh reuse|
|Dependencies|Keep Spring Boot and jjwt updated; scan with a dependency checker|





[[Spring Framework]]