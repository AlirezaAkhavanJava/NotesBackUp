

Every HTTP request that reaches a Spring Boot app first passes through a line of **filters**, small pieces of code that can inspect, change, accept or reject a request before your controller ever sees it. Spring Security is built from exactly these filters. The "JWT filter chain" is Spring Security's normal line of filters with one extra filter of your own added to it. That filter reads the token from the `Authorization` header, checks it with your `JwtService`, and tells Spring Security who the caller is.

This matters because JWT login is **stateless**. The server keeps no session, so it can't remember you between requests. Your filter has to prove who you are again on every single request, using only the token. Once you understand the order of the filters and where yours sits, the rest of JWT security is just configuration.

## The journey of one request

```
Client request
   │  Authorization: Bearer xxx.yyy.zzz
   ▼
┌─────────────────────────────────────────────┐
│ Spring Security filter chain                │
│                                             │
│  SecurityContextHolderFilter                │
│  ...                                        │
│  ► JwtAuthFilter   (yours: reads the token) │
│  UsernamePasswordAuthenticationFilter       │
│  ...                                        │
│  ExceptionTranslationFilter                 │
│  AuthorizationFilter  (checks the rules)    │
└─────────────────────────────────────────────┘
   │
   ▼
DispatcherServlet → your controller
```

Each filter does its job and then passes the request on. If any filter refuses, the request stops there and the controller never runs.

## Part 1: What a filter is

A servlet filter has one method that matters, and it receives a `FilterChain` object. Calling `filterChain.doFilter(request, response)` means "I'm done, pass this to the next filter."

```java
// the shape of every filter
doFilterInternal(request, response, filterChain) {
    // 1. do something BEFORE the next filter
    filterChain.doFilter(request, response);   // 2. hand over
    // 3. do something AFTER the response comes back (rarely needed)
}
```

Two outcomes are possible:

|What the filter does|Result|
|---|---|
|Calls `doFilter(...)`|The request continues down the chain|
|Does not call it (and writes a response)|The request stops here|

Forgetting to call `doFilter` is the most common beginner bug. The request just hangs or returns an empty page, because nobody passed it on.

## Part 2: How Spring Security organizes its filters

Spring Security doesn't put 15 separate filters into the servlet container. It registers one filter, `FilterChainProxy`, and that proxy runs a list of security filters internally. That list is called a `SecurityFilterChain`, and **you define it as a bean**. The ones you will meet most:

|Filter|What it does|
|---|---|
|`SecurityContextHolderFilter`|Loads and clears the `SecurityContext` around each request|
|`UsernamePasswordAuthenticationFilter`|Handles form login (not used in JWT apps, but it's the landmark you place your filter before)|
|`ExceptionTranslationFilter`|Turns security exceptions into 401 or 403 responses|
|`AuthorizationFilter`|Checks the rules you wrote, like `.anyRequest().authenticated()`|

Order matters. Your JWT filter must run **before** `AuthorizationFilter`, so that by the time the rules are checked, the user is already known. That is why it goes before `UsernamePasswordAuthenticationFilter`, which sits earlier in the chain.

## Part 3: Writing the JWT filter

Your filter extends `OncePerRequestFilter`, a Spring base class that guarantees `doFilterInternal` runs **once per request**, even if the request is forwarded internally.

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

        String header = request.getHeader("Authorization");

        // 1. No token? Not our business. Let the chain decide.
        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 2. Cut off the "Bearer " prefix (7 characters)
        String token = header.substring(7);

        try {
            String username = jwtService.extractUsername(token);

            // 3. Only authenticate if nobody has done it yet
            if (username != null
                    && SecurityContextHolder.getContext().getAuthentication() == null) {

                UserDetails user = userDetailsService.loadUserByUsername(username);

                // 4. Verify the token against this user
                if (jwtService.isValid(token, user)) {
                    UsernamePasswordAuthenticationToken auth =
                            new UsernamePasswordAuthenticationToken(
                                    user, null, user.getAuthorities());

                    auth.setDetails(
                            new WebAuthenticationDetailsSource().buildDetails(request));

                    // 5. Tell Spring Security who this is
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            }
        } catch (JwtException | IllegalArgumentException | UsernameNotFoundException e) {
            // Bad token or unknown user: leave the context empty
        }

        // 6. Always pass the request on
        filterChain.doFilter(request, response);
    }
}
```

Step by step:

1. **Read the header.** A JWT is sent as `Authorization: Bearer <token>`. If the header is missing or has a different format, the filter does nothing and passes the request on. That is correct, because public endpoints like `/login` have no token. The rules later decide whether anonymous access is allowed.
2. **Strip `"Bearer "`.** The word and its space are 7 characters, so `substring(7)` leaves only the token.
3. **Extract the username.** This calls `parseSignedClaims` inside your `JwtService`, which verifies the signature and expiry. A forged or expired token throws here. The check `getAuthentication() == null` avoids repeating the work if the request is already authenticated.
4. **Load the user and validate.** `loadUserByUsername` gets the user's current roles and enabled status from your database. `isValid` confirms the token's subject matches that user.
5. **Build an `Authentication`.** `UsernamePasswordAuthenticationToken` with **three** arguments (user, credentials, authorities) marks it as already authenticated. The credentials are `null` because the token was the proof, and no password is involved. `setDetails` attaches the IP address and session id, which is useful for auditing.
6. **Store it in the `SecurityContext`.** From this point on, `AuthorizationFilter`, `@PreAuthorize`, and `@AuthenticationPrincipal` in your controllers can all see who the caller is.
7. **Pass the request on.** The call to `doFilter` is outside the `if` blocks on purpose, so every path ends with it.

The `catch` block deliberately does nothing. An invalid token means "no authentication was established," and the later filters then reject the request with a 401 or 403. Throwing from inside the filter would skip Spring's normal error handling, because exceptions here happen before the controller layer and `@ControllerAdvice` never sees them.

## Part 4: Registering the filter in the chain

The filter class does nothing until you add it to a `SecurityFilterChain`:

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
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .anyRequest().authenticated())
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
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

What each line does:

|Line|Why it's there|
|---|---|
|`csrf.disable()`|CSRF attacks rely on browsers sending cookies automatically. A Bearer header is not sent automatically, so a stateless JWT API doesn't need it.|
|`requestMatchers("/api/auth/**").permitAll()`|Login and register must be reachable without a token.|
|`anyRequest().authenticated()`|Everything else needs a valid `Authentication` in the context.|
|`STATELESS`|Spring never creates or reads an `HttpSession`. Every request stands alone.|
|`addFilterBefore(...)`|Puts your filter ahead of `UsernamePasswordAuthenticationFilter`.|
|`AuthenticationManager` bean|The login endpoint uses it to check the username and password.|
|`PasswordEncoder` bean|Passwords in the database are stored as BCrypt hashes.|

## Part 5: The two flows

**Flow 1: login (no token yet).** The request goes to `/api/auth/login`, which is `permitAll`. Your filter sees no header and passes it on. The controller calls `authenticationManager.authenticate(...)` with the username and password. If that succeeds, it calls `jwtService.generateToken(appUser)` and returns the token in the response body.

```java
@PostMapping("/api/auth/login")
public Map<String, String> login(@RequestBody LoginRequest req) {
    authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(req.username(), req.password()));

    AppUser user = userRepository.findByUsername(req.username()).orElseThrow();
    return Map.of("token", jwtService.generateToken(user));
}
```

**Flow 2: a protected request.**

|Step|What happens|
|---|---|
|1|Client sends `GET /api/movies` with `Authorization: Bearer <token>`|
|2|`JwtAuthFilter` verifies the token and stores the `Authentication`|
|3|`AuthorizationFilter` sees `authenticated()` and finds a user, so it allows the request|
|4|The controller runs|

If the token is missing or invalid, step 2 stores nothing. In step 3, `AuthorizationFilter` finds no user and rejects the request.

## Part 6: What the client sees when it fails

With only the configuration above, an unauthenticated request usually gets **403 Forbidden**, not 401, because no login mechanism like `httpBasic` is configured. Clients expect 401 for "who are you?" and 403 for "I know you, but no." To fix that, add an entry point:

```java
.exceptionHandling(ex -> ex
        .authenticationEntryPoint((request, response, authException) -> {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\":\"Unauthorized\"}");
        }))
```

Add it inside the `http` chain before `.build()`. Now a missing or bad token returns a clean 401 JSON body.

## Common mistakes

- **Forgetting `filterChain.doFilter(...)`.** The request stops silently in your filter.
- **Throwing exceptions from the filter.** They bypass `@ControllerAdvice`. Catch them and leave the context empty, or write the response yourself.
- **Putting the filter after `AuthorizationFilter`.** The rules run first, find nobody logged in, and reject every request.
- **Leaving sessions on.** Without `STATELESS`, Spring may create a session, and you end up with a mix of session and token login.
- **Protecting the login URL.** If `/api/auth/**` isn't `permitAll`, nobody can ever get a token.
- **Skipping `"Bearer "` handling.** `substring(7)` on a header without the prefix gives you garbage. The `startsWith` check protects against that.
- **Hitting the database on every request without thinking.** `loadUserByUsername` runs per request here. It's fine to start with, and you can cache it or put the roles inside the token later.
- **Registering the filter twice.** A filter marked `@Component` is also picked up by Spring Boot as an ordinary servlet filter. `OncePerRequestFilter` prevents it running twice in practice, but if you see odd behavior, create the filter with `new` inside the config and drop `@Component`.

## A related concept: the `SecurityContext`

The `SecurityContext` is a small holder object that stores the current request's `Authentication`. `SecurityContextHolder` gives you access to it, and by default it is tied to the current thread. Your filter writes to it, and everything after the filter reads from it, such as `AuthorizationFilter`, method security and `@AuthenticationPrincipal`. In a stateless app, it is created empty at the start of each request and cleared at the end, which is why the filter must rebuild the `Authentication` from the token every time.







[[Spring Security]]