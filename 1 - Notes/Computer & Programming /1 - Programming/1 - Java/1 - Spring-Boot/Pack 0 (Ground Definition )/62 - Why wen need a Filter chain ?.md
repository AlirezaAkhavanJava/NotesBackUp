
A security filter chain is the ordered list of filters that every HTTP request passes through _before_ it reaches your controller. Each filter has one job: load the security context, answer CORS, check CSRF, authenticate, translate errors, or authorize. Your `SecurityFilterChain` bean is where you decide which filters exist, which are off, which of your own you add, and in what order they run.

You already know how to write the bean and how to add a JWT filter. This lesson is about the decisions around them: how many chains you need, what belongs in each, where each concern lives, and how failures turn into responses. These are the decisions that separate a chain that merely works from one that stays safe as the app grows.

## Why you design it instead of copying a tutorial

- **Order is behavior.** The same filters in a different order give a different security outcome. CORS must run before authorization, or a preflight request is rejected before it gets its answer. Your authentication filter must run before the authorization check, or every request looks anonymous.
- **One chain is one policy.** A chain has one session policy, one CSRF decision, and one set of entry points. If your API, your health checks and your docs all share a chain, one weak spot weakens all of them.
- **Everything runs before your controllers.** Nothing in your `@RestControllerAdvice` or controllers can fix a mistake in the chain. It must be right at the front door.

## The pipeline you are designing

For a stateless JWT API, these are the filters that matter, in the order they run. The list is simplified; the real chain has more.

|Filter|Its job|Your decision|
|---|---|---|
|`SecurityContextHolderFilter`|Loads the `SecurityContext`, clears it after the request|Keep|
|`HeaderWriterFilter`|Adds protective response headers|Keep, tune with `headers()`|
|`CorsFilter`|Answers CORS and preflight requests|Enable with `cors()`|
|`CsrfFilter`|Checks CSRF tokens|Disable for a pure token API|
|`LogoutFilter`|Handles `/logout`|Disable (a JWT can't be "logged out" server-side)|
|**Your JWT filter**|Authenticates from the `Authorization` header|Add it before `UsernamePasswordAuthenticationFilter`|
|`AnonymousAuthenticationFilter`|Gives unauthenticated requests an anonymous identity|Keep|
|`ExceptionTranslationFilter`|Turns security exceptions into 401 or 403|Customize with `exceptionHandling()`|
|`AuthorizationFilter`|Applies your `authorizeHttpRequests` rules|Keep, this is your policy|

To see the real chain for your app, set `logging.level.org.springframework.security=DEBUG`. At startup it prints every filter of each chain in order.

## Seven design decisions, in order

**1. How many chains, and which request each owns.** Spring picks the _first_ chain whose `securityMatcher` matches the request. Give each chain a clear scope and an `@Order`, and end with a catch-all.

||Question it answers|
|---|---|
|`securityMatcher(...)`|Does _this chain_ handle this request at all?|
|`requestMatchers(...)` inside `authorizeHttpRequests`|Which _rule_ inside the chain applies?|

**2. Session policy.** For a JWT API: `STATELESS`, so Spring never creates or reads an HTTP session. For a browser app with server sessions, you design a different chain with form login.

**3. CSRF.** CSRF attacks work because browsers send cookies automatically. A token sent in the `Authorization` header is not sent automatically, so you can disable CSRF for a pure header-token API. If you keep your token in a cookie, keep CSRF protection on.

**4. CORS.** Connect it with `.cors(Customizer.withDefaults())`, which uses the `CorsConfigurationSource` bean from your CORS lesson. This puts `CorsFilter` early so preflight requests never reach the authorization check.

**5. Turn off what you don't use.** Form login, HTTP Basic, logout and the request cache are all filters you don't need on a token API. Every filter you remove is one less thing that can misbehave.

**6. Authorization rules.** They are checked top to bottom, and the _first match wins_. Put specific rules first and finish with a default that denies or requires authentication. Keep these rules coarse (URL and role), and use `@PreAuthorize` for the fine-grained rules.

**7. Error handling.** Decide what a 401 and a 403 look like as JSON, covered below.

## The assembled design

Three chains: a public one with no JWT filter at all, the main API chain, and a catch-all that denies everything else.

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtFilter) {
        this.jwtFilter = jwtFilter;
    }

    @Bean
    @Order(1)
    SecurityFilterChain publicChain(HttpSecurity http) throws Exception {
        http.securityMatcher("/actuator/health/**", "/v3/api-docs/**", "/swagger-ui/**")
            .authorizeHttpRequests(a -> a.anyRequest().permitAll())
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        return http.build();
    }

    @Bean
    @Order(2)
    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        http.securityMatcher("/api/**")
            .csrf(AbstractHttpConfigurer::disable)
            .cors(Customizer.withDefaults())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .formLogin(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .logout(AbstractHttpConfigurer::disable)
            .requestCache(AbstractHttpConfigurer::disable)
            .authorizeHttpRequests(a -> a
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/products/**").permitAll()
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req, res, ex) ->
                        ProblemJson.write(res, HttpStatus.UNAUTHORIZED, "Authentication is required"))
                .accessDeniedHandler((req, res, ex) ->
                        ProblemJson.write(res, HttpStatus.FORBIDDEN, "You do not have permission")))
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    @Order(3)
    SecurityFilterChain fallbackChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(a -> a.anyRequest().denyAll());
        return http.build();
    }
}
```

The fallback chain is a safety net: any path you forgot (a new `/internal/**` controller, for example) is denied instead of silently exposed.

Two new things appear in the code:

- **`AuthenticationEntryPoint`** (the first lambda) runs when someone _without a valid identity_ hits a protected resource. That is the 401.
- **`AccessDeniedHandler`** (the second lambda) runs when someone _with_ an identity lacks the right. That is the 403.

## Handling errors: your filter's exceptions never reach your advice

These two handlers run inside the filter chain, which executes _before_ `DispatcherServlet`. Your `@RestControllerAdvice` and `ProblemDetail` handlers can't see these errors, so you write the JSON yourself, in the same `application/problem+json` shape:

```java
final class ProblemJson {

    static void write(HttpServletResponse response, HttpStatus status, String detail) throws IOException {
        response.setStatus(status.value());
        response.setContentType("application/problem+json");
        response.getWriter().write("""
                {"type":"about:blank","title":"%s","status":%d,"detail":"%s"}
                """.formatted(status.getReasonPhrase(), status.value(), detail));
    }
}
```

The same rule applies to exceptions thrown _inside your own filter_. `ExceptionTranslationFilter` sits _after_ your JWT filter, so it never catches what your filter throws. An expired token would bubble up as a 500. So design your JWT filter to never reject. It only authenticates, and on a bad token it falls back to "anonymous" and lets the chain continue:

```java
try {
    // read the header, validate the token, set the Authentication in the SecurityContext
} catch (JwtException | IllegalArgumentException e) {
    SecurityContextHolder.clearContext();   // treat the request as anonymous
}
filterChain.doFilter(request, response);
```

Now a bad token on a protected URL reaches `AuthorizationFilter`, which denies it, and your entry point answers a clean 401. A bad token on a `permitAll` URL still works. Each filter does one job, and one place makes the decision.

## What belongs inside the chain, and what doesn't

|Concern|Where it lives|
|---|---|
|Who is this request from?|An authentication filter (yours or built-in)|
|Which URLs need which role?|`authorizeHttpRequests`, coarse rules only|
|Which row or action is allowed?|`@PreAuthorize` in the service layer|
|Browser protections|`cors()`, `headers()`, `csrf()`|
|401 / 403 response format|`exceptionHandling()`|
|Rate limiting on `/auth/**`, request IDs|Small extra filters|

Keep business logic and database queries (beyond validating the token) out of filters. Every request pays the cost of a filter, and a filter can't use your service-layer transactions.

For extra filters, place them relative to a built-in one and give each a single job. A rate-limit filter on your login endpoint should run _before_ authentication, so brute-force attempts are stopped early:

```java
.addFilterBefore(rateLimitFilter, JwtAuthenticationFilter.class)
```

## Pitfalls that hide in a working chain

- **Rule order.** Spring refuses to configure a rule after `anyRequest()`, because everything after it would be unreachable. Keep `anyRequest()` last.
- **`permitAll()` does not skip filters.** The request still runs the whole chain, including your JWT filter. That is why the filter must be tolerant. When you want no filters at all, use a separate chain, like `publicChain` above.
- **Avoid `web.ignoring()` for endpoints.** It removes the request from the chain entirely, including the security headers. Use `permitAll()` or a separate chain.
- **A `@Component` filter is registered twice.** If your `JwtAuthenticationFilter` is a bean (as many tutorials make it), Spring Boot also registers it as a plain servlet filter outside the security chain. Because it extends `OncePerRequestFilter` it won't double-process requests that went through the chain, but requests handled by a chain _without_ it, like `publicChain`, still hit it and can fail on a bad token. Switch off that second registration:

```java
@Bean
FilterRegistrationBean<JwtAuthenticationFilter> jwtFilterRegistration(JwtAuthenticationFilter filter) {
    FilterRegistrationBean<JwtAuthenticationFilter> registration = new FilterRegistrationBean<>(filter);
    registration.setEnabled(false);
    return registration;
}
```

## Test the design, not just the code

A chain is policy, so test the policy. Two tests prove most of it, using the slice testing from the last lesson:

```java
@WebMvcTest(OrderController.class)
@Import(SecurityConfig.class)
class SecurityChainTest {

    @Autowired MockMvc mockMvc;
    @MockitoBean OrderService orderService;
    // plus @MockitoBean for whatever your JwtAuthenticationFilter needs, like JwtService

    @Test
    void anonymousGets401AsProblemJson() throws Exception {
        mockMvc.perform(get("/api/v1/orders/1"))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentType("application/problem+json"));
    }

    @Test
    @WithMockUser(roles = "USER")
    void userCannotEnterAdminArea() throws Exception {
        mockMvc.perform(get("/api/v1/admin/stats"))
                .andExpect(status().isForbidden());
    }
}
```

`@Import(SecurityConfig.class)` is needed because test slices don't pick up your configuration classes by scanning.

Related concept: **`FilterChainProxy`** is the single servlet filter Spring Security registers. It holds all your `SecurityFilterChain` beans, picks the first one that matches the request, and runs only that chain's filters. That is why a catch-all chain and `@Order` matter.


[[Spring Framework]]