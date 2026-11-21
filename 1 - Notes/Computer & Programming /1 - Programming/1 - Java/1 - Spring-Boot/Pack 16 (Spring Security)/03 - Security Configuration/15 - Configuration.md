
Spring Security is configured with ordinary Spring beans. The main one is a `SecurityFilterChain`: a bean that describes which requests are allowed, how users prove who they are, and which security filters run in front of your controllers. Around it sit a few supporting beans (`PasswordEncoder`, `UserDetailsService`, `AuthenticationManager`, CORS rules, error handlers). Older tutorials extend `WebSecurityConfigurerAdapter`, but that class was removed, and recent versions only support the lambda style you'll see below.

Where to start is the harder question, because security touches everything and it's easy to configure it in a tangle. The answer is to build in layers, in a fixed order, so you always have something that runs and that you can test. You already know the pieces (password encoding, `UserDetails`, `AuthenticationManager`, the JWT filter, CORS, roles). This lesson is about arranging them into classes that don't fight each other.

## The build order

|Step|What you add|You can now test|
|---|---|---|
|1|Just the starter dependency|Every endpoint answers `401`; Spring prints a generated password|
|2|Supporting beans: `PasswordEncoder`, `UserDetailsService`|Login credentials are checked against your database|
|3|`SecurityFilterChain`: stateless, CSRF, URL rules|Public vs protected endpoints behave right|
|4|Your JWT filter, registered in the chain|A valid token authenticates a request|
|5|Error handlers for `401` and `403`|Failures return clean `ProblemDetail` JSON|
|6|CORS source, then method security|Browser clients work; `@PreAuthorize` rules apply|
|7|Security tests|Rules can't regress silently|

Step 1 is worth doing on purpose. Add the dependency and run the app before writing any config. Seeing "everything is locked" shows you the default is **deny**, and every rule you add afterwards is a deliberate opening.

## How to split the classes

Put each responsibility in its own class:

|Class|Responsibility|
|---|---|
|`SecurityConfig`|The `SecurityFilterChain` only|
|`AuthBeansConfig`|`PasswordEncoder`, `AuthenticationManager`|
|`CorsConfig`|`CorsConfigurationSource`|
|`JwtAuthenticationFilter`|The filter (a class of its own)|
|`RestAuthenticationEntryPoint`, `RestAccessDeniedHandler`|`401` and `403` responses|
|`SecurityProperties`|Secrets, token lifetime, allowed origins (from `application.yml`)|

Splitting isn't only tidiness. It prevents the classic startup failure: a **circular dependency**. If `SecurityConfig` both builds the filter chain _and_ defines the `UserDetailsService` that the JWT filter needs, while the filter chain needs the filter, Spring can't create them in any order. Keeping beans in `AuthBeansConfig` breaks the cycle.

## The filter chain class

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtFilter;
    private final RestAuthenticationEntryPoint entryPoint;
    private final RestAccessDeniedHandler accessDeniedHandler;

    @Bean
    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(Customizer.withDefaults())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/movies/**").permitAll()
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .exceptionHandling(e -> e
                .authenticationEntryPoint(entryPoint)
                .accessDeniedHandler(accessDeniedHandler))
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

Line by line:

- `@Configuration` makes it a configuration class. `@EnableWebSecurity` is optional in Spring Boot but harmless and makes the intent obvious.
- `@EnableMethodSecurity` turns on `@PreAuthorize` and `@PostAuthorize` on your service methods (more below).
- `@Bean SecurityFilterChain` is the whole design: you receive an `HttpSecurity` builder, configure it, and return `http.build()`. Everything is a lambda, so there are no `.and()` calls.
- `csrf.disable()` is only correct for a **stateless API that authenticates with a header token** (like your Bearer JWT). CSRF attacks rely on the browser sending cookies automatically. If you ever use session cookies, keep CSRF on.
- `.cors(withDefaults())` tells Spring Security to use the `CorsConfigurationSource` bean from your CORS lesson. Without this line, preflight `OPTIONS` requests get rejected before your CORS rules run.
- `STATELESS` means no `HttpSession`, so every request must carry its own token.
- `authorizeHttpRequests` holds the URL rules. **Rules are checked top to bottom and the first match wins.** Put specific rules first and `anyRequest()` last. Ending with `anyRequest().authenticated()` (or `denyAll()`) means any endpoint you forget is closed, not open.
- `hasRole("ADMIN")` checks for the authority `ROLE_ADMIN` (see your roles lesson).
- `exceptionHandling` plugs in your two error handlers.
- `addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)` puts your filter early enough to fill the `SecurityContext` before the authorization checks run.

## The supporting beans class

```java
@Configuration
public class AuthBeansConfig {

    @Bean
    PasswordEncoder passwordEncoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();  // or your tuned delegating encoder
    }

    @Bean
    AuthenticationManager authenticationManager(AuthenticationConfiguration configuration) throws Exception {
        return configuration.getAuthenticationManager();
    }
}
```

You don't write an `AuthenticationProvider` bean. If the context contains one `UserDetailsService` bean (your `@Service`) and one `PasswordEncoder`, Spring Security builds the `DaoAuthenticationProvider` for you. The `AuthenticationManager` bean exists so your login service can inject it (the bean method from your `AuthenticationConfiguration` lesson).

## The CORS and properties classes

```java
@Configuration
@RequiredArgsConstructor
public class CorsConfig {

    private final SecurityProperties props;

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOrigins(props.cors().allowedOrigins());
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", cfg);
        return source;
    }
}
```

```java
@ConfigurationProperties(prefix = "app.security")
public record SecurityProperties(Jwt jwt, Cors cors) {
    public record Jwt(String secret, Duration expiration) {}
    public record Cors(List<String> allowedOrigins) {}
}
```

Secrets and origins live in properties, so each Spring profile (dev, prod) supplies its own values and no security class has a hard-coded URL or key. Don't switch security off in dev with an `if`. Keep the same rules everywhere and change only the values.

## Errors from the security layer

A common surprise: your `@RestControllerAdvice` never sees security failures. The filter chain runs _before_ `DispatcherServlet`, so a missing token or a forbidden role is handled by the security layer itself. You need two small handlers that write the response directly:

```java
@Component
@RequiredArgsConstructor
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper mapper;

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException ex) throws IOException {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.UNAUTHORIZED, "Authentication is required");
        response.setStatus(401);
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        mapper.writeValue(response.getOutputStream(), problem);
    }
}
```

`RestAccessDeniedHandler` is the same, with `403` and the message "You do not have permission". The `ProblemDetail` shape is the same one your exception handler returns, so clients see one error format everywhere. (If your Boot version uses Jackson 3, the injected type is `JsonMapper` instead of `ObjectMapper`. Inject whichever your version provides.)

## Method security: the second lock

URL rules are coarse. Method security protects the business operation itself:

```java
@PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.id")
public UserResponse getUser(Long userId) { ... }
```

Use URL rules for broad areas (`/admin/**`) and `@PreAuthorize` for rules that depend on the data (only the owner, or an admin). This works through the proxy mechanism from your `@Transactional` lesson, so a call from another method in the same class skips the check.

## Gotchas

**A filter that is also a `@Component` runs twice.** Spring Boot registers every `Filter` bean in the servlet container _and_ you add it to the security chain. `OncePerRequestFilter` stops it from doing the work twice, but the servlet-level copy runs outside the security chain. If this matters to you, either create the filter with `new` inside the config, or add a `FilterRegistrationBean` that disables the automatic registration.

**Rule order.** `anyRequest()` before a specific matcher throws an error at startup, and a broad `permitAll` placed above a narrow `authenticated` silently opens it.

**`permitAll` still runs your filter.** An endpoint can be public and your JWT filter still executes on it. So the filter must let requests without a token continue down the chain instead of failing them.

**Don't add `.cors()` rules in two places.** Keep one `CorsConfigurationSource` bean, not a `@CrossOrigin` plus a global config plus a filter.

## Testing the rules

```java
@WebMvcTest(MovieController.class)
@Import(SecurityConfig.class)
class MovieSecurityTest {

    @Autowired MockMvc mvc;
    @MockitoBean JwtAuthenticationFilter jwtFilter;   // plus the other beans SecurityConfig needs

    @Test
    void anonymousCannotReadAdminArea() throws Exception {
        mvc.perform(get("/api/v1/admin/users")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "USER")
    void userGetsForbiddenOnAdminArea() throws Exception {
        mvc.perform(get("/api/v1/admin/users")).andExpect(status().isForbidden());
    }
}
```

`@WithMockUser` (from `spring-security-test`) fills the `SecurityContext`, so you test the rules without a real login. These two tests lock in the difference between `401` (who are you?) and `403` (not allowed).

## Related concepts, briefly

- **Several filter chains:** you can define more than one `SecurityFilterChain` bean, each limited with `securityMatcher("/api/**")` and ordered with `@Order`. A typical use is one stateless JWT chain for `/api/**` and a second chain with form login and sessions for server-rendered pages.
- **OAuth2 Resource Server:** instead of writing your own JWT filter, `http.oauth2ResourceServer(o -> o.jwt(...))` lets Spring Security validate tokens for you. Hand-written filters teach you how it works, but this built-in option is common in production once you understand the flow.



[[Spring Security]]