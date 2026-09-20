
# Spring Security — Complete Examples

This document contains four parts:

1. Visual diagram of the authentication flow (ASCII + explanation)
    
2. Complete Spring Boot template (JPA + UserDetailsService + PasswordEncoder + DaoAuthenticationProvider)
    
3. JWT authentication version (stateless token-based, filter + provider)
    
4. Custom AuthenticationProvider example (API key)
    

---

# Part 1 — Visual Diagram (Simplified)

```
Incoming HTTP Request
        ↓
SecurityFilterChain (FilterChainProxy)
  ├─ SecurityContextPersistenceFilter (restore/clear SecurityContext)
  ├─ CsrfFilter
  ├─ CorsFilter
  ├─ UsernamePasswordAuthenticationFilter (form login)
  ├─ BasicAuthenticationFilter
  ├─ BearerTokenAuthenticationFilter (JWT)
  ├─ CustomAuthFilters (addFilterBefore/After/At)
  └─ AuthorizationFilter / ExceptionTranslationFilter
        ↓
Controller (if permitted)
        ↓
Response → back through filters (maybe modify headers)

Authentication flow (detailed):
  Filter extracts credentials → creates Authentication token → calls AuthenticationManager.authenticate(token)
  → ProviderManager iterates AuthenticationProviders → matching provider.authenticate(token)
  → On success, returns authenticated Authentication → filter sets SecurityContextHolder.getContext().setAuthentication(authenticated)
```

Notes:

- `SecurityContextPersistenceFilter` loads/stores context (HttpSession or stateless storage).
    
- `AuthenticationManager` (often `ProviderManager`) delegates to `AuthenticationProvider`s.
    
- `PasswordEncoder` is used by `DaoAuthenticationProvider` to validate password hashes.
    

---

# Part 2 — Complete Spring Boot Project Template (JPA + DAO auth)

**pom.xml (key deps)**

```xml
<dependencies>
  <dependency> <!-- Spring Boot Starter Web -->
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
  </dependency>
  <dependency> <!-- Spring Boot Starter Security -->
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
  </dependency>
  <dependency> <!-- Spring Data JPA -->
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
  </dependency>
  <dependency> <!-- H2 for demo -->
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
  </dependency>
</dependencies>
```

**Application.java**

```java
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

**Entity: AppUser.java**

```java
@Entity
@Table(name = "users")
public class AppUser {
    @Id @GeneratedValue
    private Long id;
    @Column(unique = true, nullable = false)
    private String username;
    @Column(nullable = false)
    private String password; // stored encoded
    private boolean enabled = true;
    private String roles; // comma separated, e.g. "ROLE_USER,ROLE_ADMIN"
    // getters/setters
}
```

**Repository: UserRepository.java**

```java
public interface UserRepository extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByUsername(String username);
}
```

**UserDetails implementation: AppUserDetails.java**

```java
public class AppUserDetails implements UserDetails {
    private final AppUser user;
    public AppUserDetails(AppUser user){ this.user = user; }
    @Override public Collection<? extends GrantedAuthority> getAuthorities(){
        return Arrays.stream(user.getRoles().split(","))
                     .map(String::trim)
                     .filter(s -> !s.isEmpty())
                     .map(SimpleGrantedAuthority::new)
                     .collect(Collectors.toList());
    }
    @Override public String getPassword(){ return user.getPassword(); }
    @Override public String getUsername(){ return user.getUsername(); }
    @Override public boolean isAccountNonExpired(){ return true; }
    @Override public boolean isAccountNonLocked(){ return true; }
    @Override public boolean isCredentialsNonExpired(){ return true; }
    @Override public boolean isEnabled(){ return user.isEnabled(); }
}
```

**Service: CustomUserDetailsService.java**

```java
@Service
public class CustomUserDetailsService implements UserDetailsService {
    private final UserRepository repo;
    public CustomUserDetailsService(UserRepository repo){ this.repo = repo; }
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser user = repo.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found"));
        return new AppUserDetails(user);
    }
}
```

**Config: SecurityConfig.java**

```java
@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder(){
        return new BCryptPasswordEncoder();
    }

    @Bean
    public DaoAuthenticationProvider daoAuthProvider(UserDetailsService uds, PasswordEncoder pe){
        DaoAuthenticationProvider p = new DaoAuthenticationProvider();
        p.setUserDetailsService(uds);
        p.setPasswordEncoder(pe);
        return p;
    }

    @Bean
    public AuthenticationManager authManager(AuthenticationConfiguration config) throws Exception{
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, DaoAuthenticationProvider daoProvider) throws Exception{
        http.authenticationProvider(daoProvider)
            .csrf().disable()
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .formLogin(Customizer.withDefaults())
            .httpBasic(Customizer.withDefaults());
        return http.build();
    }
}
```

**Data initialization (CommandLineRunner)**

```java
@Bean
public CommandLineRunner init(UserRepository repo, PasswordEncoder pe){
    return args -> {
        if (repo.findByUsername("user").isEmpty()){
            AppUser u = new AppUser();
            u.setUsername("user");
            u.setPassword(pe.encode("password"));
            u.setRoles("ROLE_USER");
            repo.save(u);
        }
        if (repo.findByUsername("admin").isEmpty()){
            AppUser a = new AppUser();
            a.setUsername("admin");
            a.setPassword(pe.encode("adminpass"));
            a.setRoles("ROLE_ADMIN");
            repo.save(a);
        }
    };
}
```

**Notes**

- DaoAuthenticationProvider will call your `CustomUserDetailsService` and use `PasswordEncoder` to verify passwords.
    
- `SecurityContext` is populated by the filter on successful authentication.
    

---

# Part 3 — JWT Authentication (Stateless) — Minimal Example

This section shows the components:

- JwtUtil (create/verify tokens)
    
- JwtAuthenticationFilter (extract token, authenticate)
    
- JwtAuthenticationProvider (validate token and produce Authentication)
    
- Security config wiring
    

**JwtUtil.java (very small)**

```java
@Component
public class JwtUtil {
    private final Key key = Keys.hmacShaKeyFor("01234567890123456789012345678901".getBytes(StandardCharsets.UTF_8));

    public String generateToken(UserDetails user){
        return Jwts.builder()
            .setSubject(user.getUsername())
            .claim("roles", user.getAuthorities().stream().map(GrantedAuthority::getAuthority).collect(Collectors.toList()))
            .setIssuedAt(new Date())
            .setExpiration(Date.from(Instant.now().plus(1, ChronoUnit.HOURS)))
            .signWith(key)
            .compact();
    }

    public Jws<Claims> validateToken(String token){
        return Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
    }
}
```

**JwtAuthToken.java**

```java
public class JwtAuthToken extends AbstractAuthenticationToken {
    private final String token;
    private final String principal;
    public JwtAuthToken(String token){ super(null); this.token = token; this.principal = null; setAuthenticated(false); }
    public JwtAuthToken(String principal, Collection<? extends GrantedAuthority> authorities){
        super(authorities); this.token = null; this.principal = principal; setAuthenticated(true);
    }
    @Override public Object getCredentials(){ return token; }
    @Override public Object getPrincipal(){ return principal; }
}
```

**JwtAuthenticationProvider.java**

```java
@Component
public class JwtAuthenticationProvider implements AuthenticationProvider {
    private final JwtUtil jwtUtil;
    public JwtAuthenticationProvider(JwtUtil jwtUtil){ this.jwtUtil = jwtUtil; }
    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String token = (String) authentication.getCredentials();
        try {
            Jws<Claims> claims = jwtUtil.validateToken(token);
            String username = claims.getBody().getSubject();
            List<String> roles = claims.getBody().get("roles", List.class);
            List<GrantedAuthority> authorities = roles.stream().map(SimpleGrantedAuthority::new).collect(Collectors.toList());
            return new JwtAuthToken(username, authorities);
        } catch (JwtException e) {
            throw new BadCredentialsException("Invalid JWT token", e);
        }
    }
    @Override public boolean supports(Class<?> authentication) {
        return JwtAuthToken.class.isAssignableFrom(authentication);
    }
}
```

**JwtAuthenticationFilter.java**

```java
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final AuthenticationManager authenticationManager;
    public JwtAuthenticationFilter(AuthenticationManager authenticationManager){ this.authenticationManager = authenticationManager; }
    @Override protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")){
            String token = header.substring(7);
            JwtAuthToken authRequest = new JwtAuthToken(token);
            Authentication authResult = authenticationManager.authenticate(authRequest);
            SecurityContextHolder.getContext().setAuthentication(authResult);
        }
        chain.doFilter(req, res);
    }
}
```

**SecurityConfig (JWT wiring)**

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http, AuthenticationManager authManager, JwtAuthenticationProvider jwtProvider) throws Exception {
    http.authenticationProvider(jwtProvider)
        .csrf().disable()
        .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/auth/**").permitAll()
            .anyRequest().authenticated()
        );

    http.addFilterBefore(new JwtAuthenticationFilter(authManager), UsernamePasswordAuthenticationFilter.class);
    return http.build();
}
```

**AuthController** (login endpoint to get token)

```java
@RestController
@RequestMapping("/auth")
public class AuthController {
    private final AuthenticationManager authManager;
    private final JwtUtil jwtUtil;
    private final UserDetailsService uds;

    public AuthController(AuthenticationManager authManager, JwtUtil jwtUtil, UserDetailsService uds){
        this.authManager = authManager; this.jwtUtil = jwtUtil; this.uds = uds;
    }

    @PostMapping("/login")
    public Map<String,String> login(@RequestBody AuthRequest req){
        UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken(req.getUsername(), req.getPassword());
        Authentication auth = authManager.authenticate(token); // uses DaoAuthenticationProvider
        String jwt = jwtUtil.generateToken((UserDetails)auth.getPrincipal());
        return Map.of("token", jwt);
    }
}
```

Notes:

- This design uses both DaoAuthenticationProvider (for /auth/login) and JwtAuthenticationProvider (for subsequent requests).
    
- `sessionCreationPolicy(STATELESS)` avoids HTTP sessions; SecurityContext is per-request.
    

---

# Part 4 — Custom AuthenticationProvider Example (API Key)

**ApiKeyAuthToken.java**

```java
public class ApiKeyAuthToken extends AbstractAuthenticationToken {
    private final String apiKey;
    public ApiKeyAuthToken(String apiKey){ super(null); this.apiKey = apiKey; setAuthenticated(false); }
    public ApiKeyAuthToken(String apiKey, Collection<? extends GrantedAuthority> authorities){
        super(authorities); this.apiKey = apiKey; setAuthenticated(true);
    }
    @Override public Object getCredentials(){ return apiKey; }
    @Override public Object getPrincipal(){ return apiKey; }
}
```

**ApiKeyAuthProvider.java**

```java
@Component
public class ApiKeyAuthProvider implements AuthenticationProvider {
    private final ApiKeyService service; // your service to validate / lookup
    public ApiKeyAuthProvider(ApiKeyService service){ this.service = service; }
    @Override public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String key = authentication.getCredentials().toString();
        ApiKeyRecord record = service.findByKey(key).orElseThrow(() -> new BadCredentialsException("Invalid API Key"));
        List<GrantedAuthority> authorities = record.getRoles().stream().map(SimpleGrantedAuthority::new).collect(Collectors.toList());
        return new ApiKeyAuthToken(record.getOwner(), authorities);
    }
    @Override public boolean supports(Class<?> authentication){ return ApiKeyAuthToken.class.isAssignableFrom(authentication); }
}
```

**ApiKeyFilter.java**

```java
public class ApiKeyFilter extends OncePerRequestFilter {
    private final AuthenticationManager authManager;
    public ApiKeyFilter(AuthenticationManager authManager){ this.authManager = authManager; }
    @Override protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String apiKey = req.getHeader("X-API-KEY");
        if (apiKey != null){
            ApiKeyAuthToken token = new ApiKeyAuthToken(apiKey);
            Authentication result = authManager.authenticate(token);
            SecurityContextHolder.getContext().setAuthentication(result);
        }
        chain.doFilter(req, res);
    }
}
```

**Register provider & filter**

```java
http.authenticationProvider(apiKeyAuthProvider)
    .addFilterBefore(new ApiKeyFilter(authManager), UsernamePasswordAuthenticationFilter.class);
```

Notes:

- API Key approach is useful for service-to-service or internal APIs.
    
- You can combine with other auth (JWT/username) by registering multiple providers.
    

---

# Running & Testing

- Build and run the Spring Boot app.
    
- For JPA example, use `/login` form or `POST /auth/login` to get JWT (if you enabled JWT flow).
    
- For API key, add header `X-API-KEY: SECRET123` (or as configured) to test protected endpoints.
    

---

# References & Next Steps

- Replace the symmetric JWT secret with a secure key management solution in production.
    
- Consider `PasswordEncoder` strength (BCrypt rounds) vs performance.
    
- Add `@EnableMethodSecurity` and use `@PreAuthorize` for method-level checks.
    
- Implement exception handling for auth failures (AuthenticationEntryPoint / AccessDeniedHandler).
    

---

End of document.

###### Tags : [[1 - Spring Security 🍌]]