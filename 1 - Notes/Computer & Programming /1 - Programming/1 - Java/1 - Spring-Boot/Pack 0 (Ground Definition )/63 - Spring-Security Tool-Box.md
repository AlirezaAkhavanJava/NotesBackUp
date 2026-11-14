
Spring Security is a large toolbox, but in a real Boot 4 app (Spring Security 7) you use a small core of it every day. The rest is situational. Below is the map, grouped by the job each piece does and ordered so each group builds on the last. After the map, I start teaching with the first group.



## The map

**1. Request rules (the `HttpSecurity` DSL)**

- `authorizeHttpRequests`, `requestMatchers`, `PathPatternRequestMatcher`
- Rule methods: `permitAll`, `authenticated`, `hasRole`, `hasAuthority`, `denyAll`, `access`
- `csrf`, `sessionManagement`, `exceptionHandling`, `headers`, `logout`, `formLogin`, `httpBasic`, `securityMatcher`
- `Customizer.withDefaults()`

**2. Who is the current user**

- `SecurityContextHolder`, `SecurityContext`, `SecurityContextRepository`
- `@AuthenticationPrincipal`, `@CurrentSecurityContext`
- `Authentication`,  `UserDetails` / `UserDetailsService`

**3. When security says no**

- `AuthenticationEntryPoint` (401), `AccessDeniedHandler` (403)
- `AuthenticationException`, `BadCredentialsException`, `AccessDeniedException`
- Success and failure handlers for form login

**4. Method security**

- `@EnableMethodSecurity`, `@PreAuthorize`, `@PostAuthorize`, `@PreFilter`, `@PostFilter`
- `@Secured`, `@HandleAuthorizationDenied`, `@AuthorizeReturnObject`
- SpEL expressions, calling your own beans from SpEL
- `AuthorizationManager`, `RoleHierarchy`

**5. Attack protection**

- CSRF: `CsrfTokenRepository`, `CookieCsrfTokenRepository`, the SPA setup
- Security headers: HSTS, CSP, frame options
- Session fixation protection

**6. Sessions**

- `SessionCreationPolicy`, `SessionRegistry`, concurrent session limits, remember-me

**7. Helper classes you meet constantly**

- `AuthenticationProvider`, `DaoAuthenticationProvider`, `AuthorityUtils`, `User.withUsername(...)`
- `WebSecurityCustomizer`, `AuthorizationDecision`, `AuthorizationManagers`

**8. OAuth2 / OIDC (only if you go that way)**

- Resource server: `JwtDecoder`, `NimbusJwtDecoder`, `JwtAuthenticationConverter`, `JwtGrantedAuthoritiesConverter`
- Login: `oauth2Login`, `ClientRegistration`, `OAuth2AuthorizedClient`

**9. Testing**

- `spring-security-test`, `@WithMockUser`, `@WithUserDetails`, `@WithAnonymousUser`
- Request post-processors: `user()`, `jwt()`, `csrf()`


**Design styles**

- Stateless token API (what your JWT work is)
- Session + form login (server-rendered apps)
- OAuth2 resource server (tokens issued by someone else)
- OAuth2 login / BFF (the backend holds the tokens for a browser app)
- Multiple filter chains split by `securityMatcher`
- Deny-by-default URL rules, with method security as a second layer

**What changed in Boot 4 / Security 7**

- The lambda DSL is the only style. `and()`, `authorizeRequests()`, `antMatchers()` and `WebSecurityConfigurerAdapter` are gone.
- `AntPathRequestMatcher` and `MvcRequestMatcher` are replaced by `PathPatternRequestMatcher`.
- Authorization is built on `AuthorizationManager`. The old voter classes moved to a legacy module.
- Security serialization moved to Jackson 3.
- On the OAuth2 side, PKCE is on by default and the password grant is removed.

---

## Lesson 1: The `HttpSecurity` DSL

`HttpSecurity` is the object you configure inside a `SecurityFilterChain` bean. Each method on it (`csrf`, `sessionManagement`, `authorizeHttpRequests`, and so on) switches a built-in security feature on, off, or changes its behavior. Your earlier lessons showed where this bean lives and how filters are ordered. This lesson covers the settings you put inside it.

### What you get with zero configuration

If you add `spring-boot-starter-security` and write nothing else, Boot gives you:

- every endpoint requires authentication
- a form login page and HTTP Basic
- one generated user (`user`) whose password is printed in the startup log
- CSRF protection on
- an `HttpSession` to remember the login

Everything below is how you replace those defaults with your own.

### Lambda style

Every feature takes a lambda (a `Customizer`). In Security 7 this is the only style.

```java
http.csrf(csrf -> csrf.disable());   // configure it
http.httpBasic(Customizer.withDefaults());   // enable it with defaults
```

`Customizer.withDefaults()` means "turn this feature on and change nothing."

### A complete stateless API chain

```java
@Configuration
class SecurityConfig {

    @Bean
    SecurityFilterChain api(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .formLogin(f -> f.disable())
            .httpBasic(b -> b.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/auth/**", "/error").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated());
        return http.build();
    }
}
```

### `authorizeHttpRequests`: the rule list

This is the setting you will touch most. It is an ordered list of rules, and **the first matching rule wins**. So:

- Put specific patterns before general ones.
- End with `anyRequest()`. Security refuses to let you add a rule after it.
- Always finish with a catch-all (`authenticated()` or `denyAll()`) so a forgotten URL is never public by accident.

Path patterns use `PathPatternParser` syntax:

|Pattern|Matches|
|---|---|
|`/api/users`|exactly that path|
|`/api/users/*`|one segment, e.g. `/api/users/5`|
|`/api/users/**`|that path and anything below it|
|`/api/users/{id}`|one segment, captured as a variable|

`requestMatchers(HttpMethod.GET, "/x/**")` restricts a rule to one HTTP method. That is how you make reads public and writes protected.

If your app runs under a servlet path prefix, build the matcher explicitly:

```java
var api = PathPatternRequestMatcher.withDefaults().basePath("/api");
.requestMatchers(api.matcher(HttpMethod.GET, "/products/**")).permitAll()
```

The rule methods:

|Method|Meaning|
|---|---|
|`permitAll()`|anyone, logged in or not|
|`authenticated()`|any logged-in user|
|`hasRole("ADMIN")`|needs authority `ROLE_ADMIN`; the `ROLE_` prefix is added for you|
|`hasAnyRole(...)`|any one of several roles|
|`hasAuthority("order:write")`|exact authority string, no prefix added|
|`hasAnyAuthority(...)`|any one of several authorities|
|`denyAll()`|nobody, ever|
|`access(AuthorizationManager)`|your own custom decision logic|

This is the role-versus-authority prefix difference from your roles lesson. `hasRole("ADMIN")` and `hasAuthority("ROLE_ADMIN")` are the same check.

**The `/error` gotcha.** When a controller throws, Boot forwards internally to `/error`, and that forward is checked against your rules too. If `/error` isn't allowed, every real error (a 400, a 404, a 500) is replaced by a confusing 401 or 403. Permit it, as in the example above.

### `csrf`

CSRF protection defends cookie-based sessions against forged cross-site requests. It requires a token on every state-changing request (POST, PUT, DELETE). If your API authenticates with a header token (`Authorization: Bearer ...`) and never relies on cookies, there is nothing for an attacker to ride on, so disabling it is correct. If you use session login or any cookie auth, **leave it on**. Section 5 of the map covers it properly.

### `sessionManagement`

The one setting that matters here is `SessionCreationPolicy`:

|Policy|Behavior|
|---|---|
|`STATELESS`|Security never creates or uses an `HttpSession` for the login. Every request must carry its own credentials (your JWT).|
|`IF_REQUIRED`|the default; creates a session when needed|
|`ALWAYS` / `NEVER`|rarely used|

With `STATELESS`, your JWT filter must put the `Authentication` into the `SecurityContext` on every request. That is exactly what your filter does.

### `exceptionHandling`

This decides what happens when a request is rejected:

```java
.exceptionHandling(e -> e
    .authenticationEntryPoint(entryPoint)   // not logged in → 401
    .accessDeniedHandler(deniedHandler))    // logged in, not allowed → 403
```

Without these, a stateless API often answers an anonymous request with a 403 and an empty body, which confuses clients. Lesson 3 covers both handlers in depth.

### `formLogin`, `httpBasic`, `logout`, `headers`, `securityMatcher`

- **`formLogin` / `httpBasic`**: built-in login mechanisms. A JWT API disables both, because your own endpoint and filter replace them.
- **`logout`**: only meaningful for session apps. With stateless JWT there is no server session to end.
- **`headers`**: on by default. It sends `X-Content-Type-Options`, `X-Frame-Options: DENY`, no-cache headers, and HSTS over HTTPS. Leave it alone until you have a specific reason.
- **`securityMatcher`**: limits which requests this whole chain handles. You only need it when you define more than one chain.

### Two chains in one app

```java
@Bean @Order(1)
SecurityFilterChain api(HttpSecurity http) throws Exception {
    http.securityMatcher("/api/**")
        .csrf(csrf -> csrf.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(a -> a.anyRequest().authenticated());
    return http.build();
}

@Bean @Order(2)
SecurityFilterChain web(HttpSecurity http) throws Exception {
    http.authorizeHttpRequests(a -> a
            .requestMatchers("/login", "/css/**").permitAll()
            .anyRequest().authenticated())
        .formLogin(Customizer.withDefaults());
    return http.build();
}
```

Chains are tried in `@Order` sequence, and **the first chain whose matcher fits handles the request alone**. The second chain never sees `/api/**` traffic. A chain without `securityMatcher` matches everything, so it must come last.

`@Order` is Spring's annotation for sorting beans. Lower numbers come first.

---





[[Spring Framework]]