
Spring Security isn't one feature — it's a toolbox of independent pieces that all plug into the same request pipeline. Each piece answers one question: who is this, what are they allowed to do, how do we remember them, and what attacks are we blocking. You've already gone deep on several of these pieces individually (Authentication, UserDetails, JWT, CORS, bcrypt/salt, filter chain design), so this version trims those down to quick callbacks and spends more room on the parts you haven't seen yet.

## 1. Authentication — proving who you are

Spring Security supports many login mechanisms, and you turn each on with one line:

```java
http
    .formLogin(Customizer.withDefaults())
    .httpBasic(Customizer.withDefaults())
    .oauth2Login(Customizer.withDefaults());
```

|Mechanism|Used for|
|---|---|
|Form login|classic HTML login page|
|HTTP Basic|username:password in a header, good for quick APIs/tools|
|OAuth2 / OIDC login|"Sign in with Google/GitHub"|
|JWT resource server|APIs validating a signed token|
|SAML2|enterprise SSO|
|LDAP / Active Directory|corporate directories|
|X.509|machines proving identity with certificates|
|Passkeys (WebAuthn)|passwordless login|
|Remember-me|"keep me logged in"|

Each `.xxx(...)` call adds a filter to the chain that knows how to parse that specific kind of credential. You already know `UserDetailsService`/`UserDetails` and `PasswordEncoder` from earlier lessons — the only new piece worth flagging here is that the **delegating** encoder stores a prefix label (`{bcrypt}$2a$10$...`), which is what lets you migrate hashing algorithms later without breaking existing users' passwords.

## 2. Authorization — what you're allowed to do

**URL-level**, checked top-to-bottom, first match wins:

```java
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/public/**").permitAll()
    .requestMatchers("/admin/**").hasRole("ADMIN")
    .anyRequest().authenticated());
```

**Method-level**, turned on with `@EnableMethodSecurity`:

```java
@PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.id")
public void deleteUser(long userId) { ... }

@PostAuthorize("returnObject.owner == authentication.name")
public Document load(long id) { ... }
```

`@PreAuthorize` runs the check before the method executes — useful when you can decide from the arguments alone. `@PostAuthorize` runs after, checking the _returned_ object — useful when you only know the owner once you've loaded the record. Both are written in SpEL, and `#userId` is just a reference to the method's own parameter.

**Roles vs authorities**: an authority is a raw permission string (`ORDER_DELETE`); a role is an authority with a `ROLE_` prefix, and `hasRole("ADMIN")` is really checking for `ROLE_ADMIN`. A **role hierarchy** lets you declare "ADMIN includes everything MANAGER can do" once, instead of repeating rules for every admin-accessible resource.

**Object-level** ("Alice can edit _this_ doc but not _that_ one") has a built-in ACL module backed by the database, but in practice most teams just write the ownership check directly into `@PreAuthorize`/`@PostAuthorize` rather than adopting ACL.

## 3. Staying logged in

After login, your `Authentication` object is stored in a `SecurityContext`, which by default lives in the HTTP session:

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
```

or, injected directly in a controller:

```java
@GetMapping("/me")
public String me(@AuthenticationPrincipal UserDetails user) {
    return user.getUsername();
}
```

A few session-level protections ride along with this automatically:

- **Session fixation protection** — Spring issues a brand-new session ID at the moment of login, so an ID an attacker planted beforehand becomes worthless.
- **Concurrent session control** — caps how many sessions one account can hold at once.
- **`SessionCreationPolicy.STATELESS`** — tells Spring to never create a session at all, which is what you want for token-based APIs.

**Logout** does more than drop a cookie: it invalidates the session, clears the `SecurityContext`, and can delete cookies — all behind `/logout`, which is itself CSRF-protected.

## 4. Attack protection — the defaults doing their job

|Feature|On by default?|Stops|
|---|---|---|
|CSRF protection|Yes|forged requests riding on your cookies|
|Security headers|Yes|sniffing, clickjacking, stale cached private pages|
|HSTS|Yes (for HTTPS)|silent downgrade to HTTP|
|CSP|No — you write it|injected scripts (XSS damage control)|
|HTTPS enforcement (`requiresChannel`)|No|plain HTTP connections|
|CORS integration|No|preflight requests being wrongly rejected as "not logged in"|
|`HttpFirewall`|Yes|malformed/suspicious URLs — encoded slashes, `;`, `..` tricks|

If you ever see a `RequestRejectedException`, that's the firewall, not a bug in your code.

One gap worth knowing explicitly: Spring Security does **not** give you rate limiting or brute-force login throttling. That's on you — a custom filter, a gateway, or a library like Bucket4j.

## 5. Modern/token-based login

**OAuth2** lets an app act on your behalf without ever learning your password. **OIDC** sits on top of it and adds an identity layer, so the app also learns _who you are_, not just that you're authorized. Spring Security plays three distinct roles here:

|Role|Does|Example|
|---|---|---|
|OAuth2 Client/Login|your app logs users in via Google/GitHub|"Sign in with..." buttons|
|Resource Server|your API validates incoming tokens|backend APIs|
|Authorization Server|your own system _issues_ tokens|separate Spring Authorization Server project|

A resource server validating JWTs is almost no config:

```properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://auth.example.com
```

```java
http.oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()));
```

The server just checks the token's signature — no database lookup needed, since you already know JWTs are self-contained. Also under this umbrella: SAML2 (enterprise SSO), passkeys (device-key passwordless login), one-time-token "magic link" login, and newer built-in MFA support.

## 6. The plumbing underneath

**Multiple filter chains** — you can split security config by URL range entirely, which matters once an app mixes stateless APIs with cookie-based pages:

```java
@Bean @Order(1)
SecurityFilterChain api(HttpSecurity http) throws Exception {
    http.securityMatcher("/api/**")
        .csrf(c -> c.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
        .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()));
    return http.build();
}

@Bean @Order(2)
SecurityFilterChain web(HttpSecurity http) throws Exception {
    http.authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults());
    return http.build();
}
```

`@Order` decides which chain is evaluated first; Spring matches each incoming request against each chain's `securityMatcher` until one fits.

**Error handling** splits into two distinct responses: `AuthenticationEntryPoint` fires when you're not logged in at all (401, or a redirect to login), and `AccessDeniedHandler` fires when you're logged in but lack permission (403). For a JSON API you override both to stop them from producing HTML redirects.

**Events** — Spring publishes things like `AuthenticationSuccessEvent` and `AuthenticationFailureBadCredentialsEvent`, which you can listen to for audit logs or failed-login counters, without wiring that logic into the authentication flow itself.

**Concurrency** — the `SecurityContext` lives in a `ThreadLocal`, so code running on a thread you spawned yourself has no idea who the user is. `DelegatingSecurityContextExecutor` and friends exist specifically to copy the context across to that new thread (this applies to virtual threads too, since they share the same mechanism).

**Testing**:

```java
@Test
@WithMockUser(roles = "ADMIN")
void adminCanDelete() throws Exception {
    mockMvc.perform(delete("/users/1").with(csrf()))
           .andExpect(status().isNoContent());
}
```

`@WithMockUser` fakes a logged-in principal so you don't need a real login flow in your test, and `.with(csrf())` attaches a valid token to the fake request so CSRF protection doesn't reject it.

**Other integrations**, briefly: WebFlux apps get the same concepts via `SecurityWebFilterChain`; WebSocket/RSocket channels get their own protection; Thymeleaf has `sec:authorize="hasRole('ADMIN')"` for hiding page fragments by role; the raw Servlet API (`request.getUserPrincipal()`, `request.isUserInRole(...)`) works as you'd expect; and Spring Data repository queries can reference the current user directly.


[[Spring Security]]