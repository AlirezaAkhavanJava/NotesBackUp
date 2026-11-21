

This lesson builds a small but complete Spring Boot app with JWT login, from an empty project to a working `curl` test. You will write seven short pieces: the config, the user entity and repository, the user loader, `JwtService`, the filter, the security config, and the controllers. Each piece has one job, and together they form the JWT filter chain you learned in the last lesson. The final section collects the **rules** to follow, each with the reason behind it.

The code uses Spring Boot 3.x, Java 17 or newer, jjwt 0.12.x and PostgreSQL. The package names are left out to keep the code short, so let your IDE add the imports.

## The big picture first

```
POST /api/auth/register  →  AuthController  →  save user (BCrypt password)
POST /api/auth/login     →  AuthController  →  AuthenticationManager → JwtService.generateToken
GET  /api/me             →  JwtAuthFilter   →  SecurityContext → MeController
```

|File|Its one job|
|---|---|
|`application.properties`|Holds the settings and reads the secret from the environment|
|`AppUser` + `AppUserRepository`|Stores users in PostgreSQL|
|`AppUserDetailsService`|Turns an `AppUser` into the object Spring Security understands|
|`JwtService`|Creates and verifies tokens|
|`JwtAuthFilter`|Reads the token on every request and sets the logged-in user|
|`SecurityConfig`|Builds the filter chain and the rules|
|`AuthController`, `MeController`|The endpoints|

## Step 1: Dependencies and settings

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.12.6</version>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-impl</artifactId>
    <version>0.12.6</version>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-jackson</artifactId>
    <version>0.12.6</version>
    <scope>runtime</scope>
</dependency>
```

jjwt comes in three parts. `jjwt-api` is what you code against, and `jjwt-impl` and `jjwt-jackson` are the engine and the JSON support, needed only at runtime. If you forget the last two, the app compiles but fails the first time it builds a token.

```properties
# application.properties
spring.datasource.url=jdbc:postgresql://localhost:5432/jwtlab
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=update

jwt.secret=${JWT_SECRET}
jwt.issuer=ALIREZA
jwt.expiration-ms=600000
```

Everything sensitive comes from environment variables. The issuer and the expiry are normal settings, so they live in the file. `600000` ms is 10 minutes, the same lifetime as your `generateToken` method.

## Step 2: The user and the repository

```java
@Entity
@Table(name = "app_users")
public class AppUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    @Column(nullable = false)
    private String password;      // always a BCrypt hash, never plain text

    @Column(nullable = false)
    private String role;          // "USER" or "ADMIN"

    // constructors, getters and setters
}
```

```java
public interface AppUserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByUsername(String username);
}
```

The `unique = true` on `username` makes the database refuse duplicate names. The `role` is stored without the `ROLE_` prefix, because Spring adds it for you in the next step.

## Step 3: Teaching Spring Security about your users

Spring Security doesn't know your `AppUser` class. It knows `UserDetails`. This service is the translator, and it is called both by the login check and by your filter.

```java
@Service
public class AppUserDetailsService implements UserDetailsService {

    private final AppUserRepository repository;

    public AppUserDetailsService(AppUserRepository repository) {
        this.repository = repository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser appUser = repository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        return User.builder()
                .username(appUser.getUsername())
                .password(appUser.getPassword())
                .roles(appUser.getRole())       // "ADMIN" becomes authority "ROLE_ADMIN"
                .build();
    }
}
```

Use `org.springframework.security.core.userdetails.User` for the import, not your own class. The `.roles("ADMIN")` call adds the `ROLE_` prefix, which is why the rule `hasRole("ADMIN")` later matches.

## Step 4: `JwtService`

```java
@Service
public class JwtService {

    private final SecretKey key;
    private final JwtParser parser;
    private final String issuer;
    private final long expirationMs;

    public JwtService(@Value("${jwt.secret}") String secret,
                      @Value("${jwt.issuer}") String issuer,
                      @Value("${jwt.expiration-ms}") long expirationMs) {
        this.key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret));
        this.issuer = issuer;
        this.expirationMs = expirationMs;
        this.parser = Jwts.parser()
                .verifyWith(key)
                .requireIssuer(issuer)
                .clockSkewSeconds(30)
                .build();
    }

    public String generateToken(AppUser appUser) {
        Date now = new Date();
        return Jwts.builder()
                .subject(appUser.getUsername())
                .issuer(issuer)
                .claim("role", appUser.getRole())
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expirationMs))
                .signWith(key)
                .compact();
    }

    public String extractUsername(String token) {
        return parse(token).getSubject();
    }

    public boolean isValid(String token, UserDetails user) {
        try {
            return user.getUsername().equals(extractUsername(token));
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    private Claims parse(String token) {
        return parser.parseSignedClaims(token).getPayload();
    }
}
```

This combines everything from your earlier lessons. The constructor decodes the key and builds the parser **once**, so a bad secret stops the app at startup instead of at the first login. Expiry is checked automatically inside `parseSignedClaims`, so `isValid` doesn't need its own date check. The issuer comes from one setting and is used both when building tokens and when requiring it in the parser, so the two can never disagree.

## Step 5: `JwtAuthFilter`

```java
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    public JwtAuthFilter(JwtService jwtService, UserDetailsService userDetailsService) {
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String header = request.getHeader(HttpHeaders.AUTHORIZATION);

        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = header.substring(7);

        try {
            String username = jwtService.extractUsername(token);

            if (SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails user = userDetailsService.loadUserByUsername(username);

                if (jwtService.isValid(token, user)) {
                    UsernamePasswordAuthenticationToken auth =
                            new UsernamePasswordAuthenticationToken(
                                    user, null, user.getAuthorities());
                    auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            }
        } catch (JwtException | IllegalArgumentException | UsernameNotFoundException e) {
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
```

The flow has three outcomes, and all of them end at `doFilter`:

|Situation|What the filter does|
|---|---|
|No header, or no `Bearer` prefix|Passes on without touching anything|
|Valid token|Stores an `Authentication` in the context, then passes on|
|Bad, expired or unknown-user token|Clears the context, then passes on|

The filter never decides "allowed" or "denied." It only answers "who is this?" The deciding is left to `AuthorizationFilter` and your rules.

## Step 6: `SecurityConfig`

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated())
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((req, res, e) -> {
                            res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                            res.setContentType("application/json");
                            res.getWriter().write("{\"error\":\"Unauthorized\"}");
                        }))
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    @Bean
    AuthenticationManager authenticationManager(AuthenticationConfiguration config)
            throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

The rules in `authorizeHttpRequests` are checked **from top to bottom, and the first match wins**. That is why `/api/auth/**` and `/api/admin/**` come before `anyRequest()`. If you put `anyRequest().authenticated()` first, the more specific lines below it would never be reached.

Because there is exactly one `UserDetailsService` bean and one `PasswordEncoder` bean, Spring Boot wires them into the `AuthenticationManager` automatically. You don't create an authentication provider by hand.

## Step 7: Controllers

```java
public record RegisterRequest(String username, String password) {}
public record LoginRequest(String username, String password) {}
```

```java
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AppUserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthController(AppUserRepository repository,
                          PasswordEncoder passwordEncoder,
                          AuthenticationManager authenticationManager,
                          JwtService jwtService) {
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, String>> register(@RequestBody RegisterRequest req) {
        if (repository.findByUsername(req.username()).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Username already taken"));
        }
        AppUser user = new AppUser();
        user.setUsername(req.username());
        user.setPassword(passwordEncoder.encode(req.password()));   // hash it
        user.setRole("USER");                                       // never trust the client for this
        repository.save(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("status", "created"));
    }

    @PostMapping("/login")
    public Map<String, String> login(@RequestBody LoginRequest req) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(req.username(), req.password()));

        AppUser user = repository.findByUsername(req.username()).orElseThrow();
        return Map.of("token", jwtService.generateToken(user));
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, String>> badCredentials() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("error", "Invalid username or password"));
    }
}
```

```java
@RestController
public class MeController {

    @GetMapping("/api/me")
    public Map<String, Object> me(@AuthenticationPrincipal UserDetails user) {
        return Map.of("username", user.getUsername(),
                      "authorities", user.getAuthorities().toString());
    }

    @GetMapping("/api/admin/ping")
    public Map<String, String> adminPing() {
        return Map.of("message", "hello admin");
    }
}
```

Points worth reading closely:

- `passwordEncoder.encode(...)` turns the password into a BCrypt hash before saving. Login later compares against the hash, so the plain password is never stored.
- `setRole("USER")` is fixed on the server. If you let the request body choose the role, anyone could register as `ADMIN`.
- `authenticate(...)` throws `BadCredentialsException` for a wrong password. The `@ExceptionHandler` turns that into a clean 401 instead of an error page.
- `@AuthenticationPrincipal UserDetails user` receives the object your filter stored in the `SecurityContext`. No database call is needed in the controller.

## Step 8: Run it and test it

Set the secret first, using the generation steps from the last lesson (the `export` form is for Debian, and the `setx` form is for Windows, followed by a new terminal).

On **Debian**, with `curl`:

```bash
# 1. register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"secret123"}'

# 2. login and keep the token
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"secret123"}' | sed 's/.*"token":"\([^"]*\)".*/\1/')

# 3. call a protected endpoint
curl http://localhost:8080/api/me -H "Authorization: Bearer $TOKEN"
```

On **Windows**, with PowerShell:

```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/auth/register `
  -ContentType "application/json" -Body '{"username":"alice","password":"secret123"}'

$r = Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/auth/login `
  -ContentType "application/json" -Body '{"username":"alice","password":"secret123"}'

Invoke-RestMethod -Uri http://localhost:8080/api/me `
  -Headers @{ Authorization = "Bearer $($r.token)" }
```

What you should see:

|Request|Expected result|
|---|---|
|`/api/me` with a valid token|`200` with `username` and `authorities`|
|`/api/me` with no header|`401` `{"error":"Unauthorized"}`|
|`/api/me` with a changed token|`401`|
|`/api/me` after 10 minutes|`401` (expired)|
|`/api/admin/ping` as a normal user|`403` (known, but not allowed)|
|Login with a wrong password|`401` `Invalid username or password`|

The `401` versus `403` split is the sign that your chain works. `401` means "I don't know who you are," and `403` means "I know who you are, and you aren't allowed."

## The rules to follow

**Token rules**

|Rule|Why|
|---|---|
|Always set `exp`, and keep it short (5 to 15 minutes)|A stolen token works until it expires|
|Never put passwords or private data in claims|The payload is readable by anyone|
|Keep claims small: username, role, maybe an id|The token travels in every request|
|Use `parseSignedClaims`, never decode the payload by hand|Only the parser checks the signature|

**Filter rules**

|Rule|Why|
|---|---|
|Always call `filterChain.doFilter(...)` on every path|Otherwise the request hangs|
|The filter only answers "who is this?" and never returns "denied"|The `AuthorizationFilter` is the single place for decisions|
|Catch JWT exceptions inside the filter|Exceptions thrown here bypass `@ControllerAdvice`|
|Clear the context when the token is bad|A leftover `Authentication` could let a request through|
|Check `getAuthentication() == null` before authenticating|Avoids repeated work and overwriting a good login|
|Register it with `addFilterBefore(..., UsernamePasswordAuthenticationFilter.class)`|It must run before the rules are checked|

**Configuration rules**

|Rule|Why|
|---|---|
|Use `STATELESS` sessions|JWT replaces the session. Mixing both creates confusing bugs|
|Put specific `requestMatchers` before `anyRequest()`|First match wins|
|Make login and register `permitAll`|Otherwise nobody can get a token|
|Disable CSRF only for a header-token API|A Bearer header isn't sent automatically by browsers. If you later store the token in a cookie, turn CSRF protection back on|
|Return 401 for "not logged in" through an entry point|The default answer is often 403, which confuses clients|

**Secret and password rules**

|Rule|Why|
|---|---|
|The secret is Base64, 32 bytes or more, random|`hmacShaKeyFor` rejects anything weaker|
|Read it from an environment variable and never commit it|Git history keeps it forever|
|Use a different secret per environment|A leaked dev key can't forge production tokens|
|Hash passwords with BCrypt|A database leak doesn't expose the passwords|
|Set the role on the server|The client must never choose its own role|
|Use HTTPS in production|A Bearer token sent over plain HTTP can be read in transit|

**Testing rules**

- Test the unhappy paths as well as the happy one: no header, tampered token, expired token, wrong role, wrong password.
- To test expiry quickly, set `jwt.expiration-ms=5000` temporarily and wait six seconds.
- Never log full tokens or the secret.

## A related concept: refresh tokens

A 10-minute token is safe, but it would make users log in again every 10 minutes. The usual fix is a second, long-lived **refresh token**. When the short token expires, the client sends the refresh token to a `/refresh` endpoint and gets a new access token without asking for the password. The refresh token is stored in the database so you can revoke it, which is something a plain stateless access token can't do.





[[Spring Security]]