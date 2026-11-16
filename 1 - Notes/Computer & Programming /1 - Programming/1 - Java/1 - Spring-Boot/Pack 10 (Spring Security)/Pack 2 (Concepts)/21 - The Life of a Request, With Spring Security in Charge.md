![[16c95e59-37da-4ce1-b53e-8a14781e41a4.png]]

When a client sends an HTTP request to your Spring Boot app, it doesn't walk straight into your controller. It has to pass through a sequence of checkpoints first — and in a secured app, most of that sequence exists to answer one question before your business logic ever runs: _"should this request even be allowed to do this?"_

What follows is the full path a request takes, from the moment it hits your server to the moment a response goes back, with the Spring Security portion covered in full depth since that's where most of the "gatekeeping" logic lives.

## 1. The request arrives at the servlet container

Before Spring exists at all, your embedded Tomcat (or whichever servlet container you're using) accepts the raw HTTP connection and turns it into a `HttpServletRequest` / `HttpServletResponse` pair. At this point Spring hasn't touched anything — this is pure servlet-API territory.

Tomcat then needs to decide which **filters** and which **servlet** get a turn with this request. That decision is based on URL mappings configured when the app starts.

## 2. Entering Spring's filter world: `DelegatingFilterProxy`

Spring Security isn't a servlet filter itself — Spring doesn't register its filters directly with Tomcat. Instead, Spring Boot auto-configures a single servlet filter called `DelegatingFilterProxy`, mapped to `/*`. Its only job is to hand the request off to a Spring-managed bean named `springSecurityFilterChain`.

That bean is actually a `FilterChainProxy`. It holds a _list_ of `SecurityFilterChain` objects — remember, you can define more than one in your `SecurityConfig`, each matched by a `securityMatcher`. `FilterChainProxy` picks the first chain whose matcher matches the current request path, and runs _that_ chain's filters, in order, on the request.

```java
@Bean
SecurityFilterChain apiFilterChain(HttpSecurity http) throws Exception {
    http.securityMatcher("/api/**")
        .csrf(csrf -> csrf.disable())
        .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/auth/**").permitAll()
            .requestMatchers("/api/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated()
        )
        .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
    return http.build();
}
```

This is the chain you've already built pieces of — now let's walk through what actually happens inside it, filter by filter.

## 3. The filter chain, in execution order

A typical chain (stateless JWT setup) runs roughly in this order. Each filter either does its job and calls `chain.doFilter()` to pass the request along, or short-circuits by writing a response and stopping.

1. **`DisableEncodeUrlFilter`** — strips URL-based session encoding (`;jsessionid=...`), which is a historical session-fixation attack vector. Rarely something you touch, but it's always first.
    
2. **`SecurityContextHolderFilter`** (replaces the older `SecurityContextPersistenceFilter`) — at the _start_ of the chain, it loads any existing `SecurityContext` (from a session, if you're using one) into `SecurityContextHolder` for this thread. In a stateless JWT setup there's usually nothing to load yet — your custom filter builds the context later.
    
3. **`CorsFilter`** — if you've configured `CorsConfigurationSource`, this runs early and handles preflight `OPTIONS` requests and adds the `Access-Control-Allow-*` headers.
    
4. **`CsrfFilter`** — validates a CSRF token for state-changing methods (`POST`, `PUT`, `DELETE`, `PATCH`) if CSRF protection is enabled. You disable this for stateless token-based APIs, which is why you saw `.csrf(csrf -> csrf.disable())` above — there's no cookie-based session to protect against CSRF for.
    
5. **`LogoutFilter`** — checks if the request matches your configured logout URL; if so, it clears authentication and context, then stops the chain.
    
6. **Your custom authentication filter** (e.g. `JwtAuthFilter`, a `OncePerRequestFilter`) — this is where _authentication actually happens_ for a token-based setup. More detail below.
    
7. **`UsernamePasswordAuthenticationFilter`** — only relevant if you're using form-login. It intercepts the login URL/method, pulls `username`/`password` from the request, and hands them to the `AuthenticationManager`. In a pure JWT API this filter exists in the chain but never fires, since your requests don't hit the login URL it's listening for.
    
8. **`DefaultLoginPageGeneratingFilter` / `DefaultLogoutPageGeneratingFilter`** — only active if you haven't defined a custom login page and haven't disabled form login; generates Spring's default login HTML. Usually irrelevant once you've built a real app.
    
9. **`RequestCacheAwareFilter`** — restores a previously-cached request (used after a redirect-to-login flow in session-based apps, where the original request is replayed once login succeeds).
    
10. **`AnonymousAuthenticationFilter`** — if, after everything above, `SecurityContextHolder` still has no `Authentication` set, this filter populates it with an `AnonymousAuthenticationToken` so that downstream code never has to null-check. This is why `SecurityContextHolder.getContext().getAuthentication()` is basically never literally `null` once you're past this point — "unauthenticated" is represented as a real, typed object.
    
11. **`SessionManagementFilter`** — enforces session fixation protection and concurrent session limits, if configured. With `STATELESS` policy, this mostly becomes a no-op since no session is being tracked.
    
12. **`ExceptionTranslationFilter`** — this one matters a lot, and it's positioned _just before_ the authorization filter on purpose. It wraps the rest of the chain in a try/catch for two specific exception types: `AuthenticationException` and `AccessDeniedException`. More in the failure-handling section below.
    
13. **`AuthorizationFilter`** (this replaced the older `FilterSecurityInterceptor`) — the last filter in the chain. This is where _authorization_ happens: it checks the current `Authentication` against the rules you declared in `authorizeHttpRequests(...)`, via an `AuthorizationManager`. If it denies, it throws `AccessDeniedException`, which `ExceptionTranslationFilter` (already on the call stack, wrapping everything below it) catches.
    

If the request survives all of that, `AuthorizationFilter` calls `chain.doFilter()` one last time — and _that_ is the call that finally reaches Spring MVC's `DispatcherServlet`.

## 4. Authentication, in detail: how `Authentication` actually gets built

Step 6 above is the one that deserves the deepest look, since it's where the identity-proving work happens.

For a JWT-based filter:

```java
public class JwtAuthFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res,
                                     FilterChain chain) throws ServletException, IOException {

        String header = req.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(req, res);
            return;
        }

        String token = header.substring(7);
        String username = jwtService.extractUsername(token);

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails user = userDetailsService.loadUserByUsername(username);

            if (jwtService.isTokenValid(token, user)) {
                Authentication auth = new UsernamePasswordAuthenticationToken(
                        user, null, user.getAuthorities());
                auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(req));
                SecurityContextHolder.getContext().setAuthentication(auth);
            }
        }
        chain.doFilter(req, res);
    }
}
```

The pieces you've already met individually (`UserDetailsService`, `Authentication`, `GrantedAuthority`) are all doing their jobs right here, together:

- `userDetailsService.loadUserByUsername(username)` returns a `UserDetails` — your `User` entity implementing that interface.
- A fresh `UsernamePasswordAuthenticationToken` is built with that `UserDetails` as the **principal**, `null` as **credentials** (there's no password to hold onto — the JWT already proved identity), and `user.getAuthorities()` as the authority list.
- `SecurityContextHolder.getContext().setAuthentication(auth)` is the exact moment the request stops being anonymous. From here on, every later filter, every `@PreAuthorize`, every `SecurityContextHolder.getContext().getAuthentication()` call in your controller sees _this_ object.

Contrast this with form-login: there, `UsernamePasswordAuthenticationFilter` extracts raw credentials and hands them to `AuthenticationManager.authenticate(...)`, which delegates to a `DaoAuthenticationProvider`, which calls the same `UserDetailsService`, then checks the raw password against the stored hash via `PasswordEncoder.matches(...)` before producing the same kind of `Authentication` object. Different trigger, same destination: a populated `SecurityContext`.

## 5. Authorization, in detail: how `AuthorizationFilter` decides

By the time `AuthorizationFilter` runs, it has an `Authentication` object (real or anonymous) sitting in the context. It evaluates your `authorizeHttpRequests` rules top-to-bottom against the request's path and method, using the first matching rule:

```java
.authorizeHttpRequests(auth -> auth
    .requestMatchers("/api/auth/**").permitAll()
    .requestMatchers(HttpMethod.DELETE, "/api/orders/**").hasRole("ADMIN")
    .requestMatchers("/api/orders/**").hasAnyAuthority("ORDER_READ", "ORDER_WRITE")
    .anyRequest().authenticated()
)
```

Each rule resolves to an `AuthorizationManager<RequestAuthorizationContext>`. `hasRole("ADMIN")` under the hood checks for authority `"ROLE_ADMIN"` in `user.getAuthorities()` — which is exactly the role-as-bundled-authorities design you already learned. If none of the authorities match what the rule requires, authorization fails.

This same mechanism exists one layer deeper, at the _method_ level, if you've enabled it:

```java
@EnableMethodSecurity
// ...
@PreAuthorize("hasAuthority('ORDER_WRITE')")
public Order createOrder(OrderRequest request) { ... }
```

`@PreAuthorize` doesn't live in the filter chain — it's enforced by an AOP proxy wrapped around your bean (the same proxy mechanism from your `@Transactional`/AOP lesson), evaluated right before the method body runs, after the request has already cleared the filter-chain-level authorization. So a request can pass the URL-level check and still get rejected at the method level if the two sets of rules disagree — this is why professional setups usually pick _one_ layer as the primary enforcement point and use the other sparingly, rather than duplicating identical rules in both places.

## 6. What happens when it fails

This is where `ExceptionTranslationFilter` earns its position in the chain. It's listening for exactly two exception types bubbling up from anything downstream of it (including `AuthorizationFilter`):

- **`AuthenticationException`** (thrown when there's no valid identity at all, or a later check realizes the "authenticated" user shouldn't be treated as such) → delegated to an **`AuthenticationEntryPoint`**, which typically writes a `401 Unauthorized`.
- **`AccessDeniedException`** (thrown by `AuthorizationFilter` when there _is_ an identity, but it lacks the required authority) → delegated to an **`AccessDeniedHandler`**, which typically writes a `403 Forbidden`.

```java
http.exceptionHandling(ex -> ex
    .authenticationEntryPoint((req, res, authEx) ->
        res.sendError(HttpServletResponse.SC_UNAUTHORIZED, authEx.getMessage()))
    .accessDeniedHandler((req, res, accessEx) ->
        res.sendError(HttpServletResponse.SC_FORBIDDEN, accessEx.getMessage()))
);
```

Notice the distinction this enforces: "I don't know who you are" and "I know who you are, and the answer is no" are genuinely different failures, with different status codes and different handlers — the chain is structured so you can never accidentally conflate them.

If you want these to come back as `ProblemDetail` responses matching the rest of your API's error format (from your `@RestControllerAdvice` lesson), you write the entry point / handler to build a `ProblemDetail` and serialize it directly here, since by this point the request hasn't reached `DispatcherServlet` yet — your `@RestControllerAdvice` can't catch exceptions that never made it that far.

## 7. Past security: entering Spring MVC

Assuming the request survives `AuthorizationFilter`, it finally reaches `DispatcherServlet` — the single servlet Spring Boot registers to handle everything. From here the flow you've already learned takes over:

1. `DispatcherServlet` asks each registered `HandlerMapping` (your `@RequestMapping`-scanning one, primarily) which handler method matches this URL + HTTP method.
2. Any `HandlerInterceptor`s you've registered via `WebMvcConfigurer.addInterceptors(...)` run their `preHandle()` here — this is a _separate_ interception point from the security filters, scoped only to MVC-mapped requests.
3. The matched `HandlerAdapter` resolves your controller method's arguments (`@RequestBody`, `@PathVariable`, `@Validated` DTOs triggering Bean Validation, and even `Authentication`/`@AuthenticationPrincipal` injected straight from `SecurityContextHolder`), then invokes it.
4. Your method-level `@PreAuthorize` AOP proxy (if present) runs its check right here, before your actual method body executes.
5. Your controller delegates to the service layer, which delegates to the repository layer — ordinary layered-architecture work, nothing security-specific left to do unless you're also checking authorization _inside_ business logic (e.g. "can this user edit _this specific_ order," which is data-dependent and can't be expressed as a static URL or role rule).
6. The return value gets converted to JSON (or whatever your `HttpMessageConverter` produces) and interceptors' `postHandle()`/`afterCompletion()` run.
7. If anything threw along the way, your `@RestControllerAdvice` + `ProblemDetail` setup catches it here — this is the exception-handling layer that's _only_ reachable for exceptions thrown inside MVC, which is why security-layer failures use `AuthenticationEntryPoint`/`AccessDeniedHandler` instead.

## 8. The way back out

The response doesn't just appear — it travels back through the exact same filters it came through, in reverse, since each filter's call to `chain.doFilter()` is a synchronous call that only returns once everything downstream is done. Filters that do `postHandle`-style work (rare in Security's own filters, more common in custom ones you write) run their "after" logic on the way back up. Then it leaves `DelegatingFilterProxy`, and Tomcat writes the bytes to the socket.

---

**The one-sentence version of all of this:** a request has to be _parsed_ (servlet container), then _authenticated_ (your custom filter building an `Authentication`), then _authorized_ (`AuthorizationFilter` checking that `Authentication`'s authorities against your rules), before it's ever allowed to reach `DispatcherServlet` and trigger a single line of your actual business logic — and every failure along the way is caught at a specific, deliberate point (`ExceptionTranslationFilter`) rather than leaking down into code that was never meant to handle it.



[[Spring Security]]
