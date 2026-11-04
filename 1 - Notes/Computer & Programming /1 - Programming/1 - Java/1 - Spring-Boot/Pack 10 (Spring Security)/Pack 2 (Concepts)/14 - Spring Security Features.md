

## The problem it solves

Spring Security is a **security toolbox for the whole request lifecycle**. It protects the request on the way in, controls what your code can do, and protects the response on the way out. Most of its features answer a question from our earlier lessons: "What stops this attack?"

I've grouped the features by the job they do, so you can see how they fit together.

---

## The map

|Group|Features|
|---|---|
|**1. Who are you?**|Authentication mechanisms, user storage, password hashing|
|**2. What may you do?**|URL, method, and object-level authorization, role hierarchy|
|**3. Remembering you**|Sessions, SecurityContext, remember-me, logout|
|**4. Attack protection**|CSRF, security headers, HTTPS/HSTS, CORS, request firewall|
|**5. Modern login**|OAuth2/OIDC, JWT, SAML, passkeys, one-time tokens|
|**6. Plumbing**|Filter chain, error handling, events, concurrency, crypto, testing, reactive|

---

# Group 1: Who are you? (Authentication)

### 1.1 Many ways to log in

**The problem it solves:** Different apps need different login styles, and you don't want to write each one yourself.

Out of the box, Spring Security supports:

|Mechanism|Used for|
|---|---|
|**Form login**|Classic HTML login page|
|**HTTP Basic**|Simple username and password in a header (quick APIs, tools)|
|**OAuth2 / OIDC login**|"Sign in with Google/GitHub"|
|**JWT resource server**|APIs that check a signed token|
|**SAML2**|Company single sign-on|
|**LDAP / Active Directory**|Corporate user directories|
|**X.509 client certificates**|Machines proving identity with certificates|
|**Passkeys (WebAuthn)**|Passwordless login|
|**Remember-me**|"Keep me logged in"|

You switch them on with a line each:

```java
http
    .formLogin(Customizer.withDefaults())
    .httpBasic(Customizer.withDefaults())
    .oauth2Login(Customizer.withDefaults());
```

Each line adds a filter to the chain that knows how to read that kind of credential.

### 1.2 Where users come from: `UserDetailsService`

**The problem it solves:** The framework needs to look up "who is `alice`?" but can't know whether your users live in memory, PostgreSQL, or LDAP.

`UserDetailsService` is a one-method interface you implement:

```java
@Service
public class MyUserService implements UserDetailsService {
    @Override
    public UserDetails loadUserByUsername(String username) {
        // look the user up in your database and return it
    }
}
```

`UserDetails` is the object that describes a user. It has a username, a hashed password, authorities, and four status flags: **enabled, locked, account-expired, credentials-expired**. Those flags give you account locking and disabling without extra code. Built-in versions exist for in-memory and JDBC storage.

### 1.3 Password hashing: `PasswordEncoder`

**The problem it solves:** If your database leaks, plain-text passwords become stolen passwords.

A **hash** is a one-way scramble: you can check a password against it, but you can't turn it back. Spring Security gives you encoders for bcrypt, Argon2, scrypt, and PBKDF2:

```java
@Bean
PasswordEncoder passwordEncoder() {
    return PasswordEncoderFactories.createDelegatingPasswordEncoder();
}
```

The delegating encoder stores passwords with a label, like `{bcrypt}$2a$10$...`. The label lets you **upgrade algorithms later** without breaking old users. There's also a checker for known-leaked passwords.

---

# Group 2: What may you do? (Authorization)

### 2.1 URL-level rules

**The problem it solves:** Whole sections of your site need different access levels.

```java
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/public/**").permitAll()
    .requestMatchers("/admin/**").hasRole("ADMIN")
    .anyRequest().authenticated());
```

Rules are checked **top to bottom, first match wins**. Put specific rules first and the catch-all last.

### 2.2 Method-level security

**The problem it solves:** URL rules aren't enough. The same service method might be called from a controller, a scheduled job, and a message listener, and it should always be protected.

Turn it on with `@EnableMethodSecurity`, then annotate:

```java
@PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.id")
public void deleteUser(long userId) { ... }

@PostAuthorize("returnObject.owner == authentication.name")
public Document load(long id) { ... }
```

- `@PreAuthorize` checks **before** the method runs. Here, admins may delete anyone, and users may only delete themselves.
- `@PostAuthorize` checks **after**, using the returned object. This is useful when you only learn who owns something after loading it.
- `#userId` refers to the method's own parameter. These expressions are written in **SpEL** (Spring Expression Language).

### 2.3 Roles vs authorities, and role hierarchy

An **authority** is a single permission string like `ORDER_DELETE`. A **role** is an authority with the prefix `ROLE_`, like `ROLE_ADMIN`. `hasRole("ADMIN")` checks for `ROLE_ADMIN` automatically. A **role hierarchy** lets you say "ADMIN includes everything MANAGER can do", so you don't repeat rules.

### 2.4 Object-level security

**The problem it solves:** "Alice can edit _this_ document but not _that_ one." The ACL module supports this in the database, though many teams just write ownership checks inside `@PreAuthorize`.

---

# Group 3: Remembering you

### 3.1 `SecurityContext` and the session

After you log in, Spring Security stores your identity (the `Authentication` object) in a **SecurityContext**. By default, it is saved in the HTTP session, so the next request knows who you are. Anywhere in your code you can read it:

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
```

Or, in a controller, just ask for it:

```java
@GetMapping("/me")
public String me(@AuthenticationPrincipal UserDetails user) {
    return user.getUsername();
}
```

### 3.2 Session protections

|Feature|Problem it solves|
|---|---|
|**Session fixation protection**|An attacker plants a known session ID before you log in. Spring issues a **new ID at login**, so the planted one is useless.|
|**Concurrent session control**|Limits how many places one account can be logged in at once|
|**Session creation policy**|`STATELESS` means "never create a session", which fits token-based APIs|
|**Invalid session handling**|Redirects when a session expires|

### 3.3 Logout

Logout is more than deleting a cookie. It invalidates the session, clears the SecurityContext, and can delete cookies. Spring Security does all of this at `/logout` (a POST, protected by CSRF).

---

# Group 4: Attack protection

You've already met most of these in the earlier lessons. This is where they live in the framework.

|Feature|Default?|What it stops|
|---|---|---|
|**CSRF protection**|On|Forged requests using your cookies|
|**Security headers**|On|`X-Content-Type-Options`, `X-Frame-Options`, cache control, and more for sniffing, clickjacking, and stale cached private pages|
|**HSTS**|On for HTTPS requests|Downgrade to HTTP|
|**CSP**|Off, you write it|Injected scripts (XSS damage control)|
|**HTTPS enforcement**|Off|`requiresChannel` forces secure connections|
|**CORS integration**|Off|Ensures preflight requests aren't rejected as "not logged in"|
|**HttpFirewall**|On|Rejects suspicious URLs (encoded slashes, `;`, `..` path tricks, odd characters) before they reach your code|

The firewall is the one people forget exists. If you ever see a `RequestRejectedException`, that's it doing its job.

One honest note: Spring Security does **not** give you rate limiting or brute-force login throttling. You add that yourself (a filter, a gateway, or a library like Bucket4j).

---

# Group 5: Modern login and token features

### 5.1 OAuth2 and OpenID Connect

**The problem it solves:** You don't want to store passwords at all, or you want one login across many apps.

First, the vocabulary:

- **OAuth2** is a standard for letting an app act on your behalf without learning your password.
- **OIDC (OpenID Connect)** adds an _identity_ layer on top of OAuth2, so the app learns who you are.

Spring Security covers three roles:

|Role|What it does|Typical use|
|---|---|---|
|**OAuth2 Client / Login**|Your app logs users in through Google, GitHub, and so on|"Sign in with..." buttons|
|**Resource Server**|Your API accepts and validates tokens|Backend APIs|
|**Authorization Server**|Your own system issues tokens|Provided by the separate **Spring Authorization Server** project|

A resource server that validates JWTs takes very little config:

```properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://auth.example.com
```

```java
http.oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()));
```

A **JWT** (JSON Web Token) is a signed token carrying claims about the user. The server checks the signature instead of looking anything up.

### 5.2 Also available

- **SAML2:** enterprise single sign-on.
- **Passkeys (WebAuthn):** phishing-resistant login with device keys.
- **One-time-token login:** "magic link" login.
- **Multi-factor authentication:** the newest versions add built-in support.

---

# Group 6: The plumbing that holds it together

### 6.1 The filter chain and multiple chains

Everything above is a **filter** in a chain. You can define **several chains** for different URL ranges:

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

`/api/**` uses stateless tokens, and everything else uses cookie-based form login. `@Order` decides which chain is checked first.

### 6.2 Error handling

When security says no, two classes decide the response:

- **`AuthenticationEntryPoint`:** "You aren't logged in" (usually a 401 or a redirect to the login page).
- **`AccessDeniedHandler`:** "You're logged in but not allowed" (a 403).

For APIs you customize these to return JSON instead of an HTML redirect.

### 6.3 Security events

Spring publishes events like `AuthenticationSuccessEvent` and `AuthenticationFailureBadCredentialsEvent`. You can listen to them for **audit logs, login alerts, or failed-attempt counting**.

### 6.4 Concurrency support

The SecurityContext is stored per thread (a `ThreadLocal`). If you run code in a new thread, it **doesn't know who the user is**. Spring Security has wrappers like `DelegatingSecurityContextExecutor` that copy the context across threads. (Virtual threads work with the same mechanism.)

### 6.5 Crypto module

Small helpers for encrypting text, generating random keys, and encoding bytes safely, so you don't hand-roll cryptography.

### 6.6 Testing support

```java
@Test
@WithMockUser(roles = "ADMIN")
void adminCanDelete() throws Exception {
    mockMvc.perform(delete("/users/1").with(csrf()))
           .andExpect(status().isNoContent());
}
```

- `@WithMockUser` pretends a user is logged in, so you don't need real login in tests.
- `.with(csrf())` adds a valid CSRF token to the fake request.

### 6.7 Integrations

- **Reactive:** `WebFlux` apps use the same ideas with `SecurityWebFilterChain`.
- **WebSocket and RSocket security:** protects real-time channels too.
- **Thymeleaf extras:** hide page parts by role, using `sec:authorize="hasRole('ADMIN')"`.
- **Servlet API integration:** `request.getUserPrincipal()` and `request.isUserInRole(...)` work as expected.
- **Spring Data:** you can reference the current user inside repository queries.

---

## One related concept, briefly

**Authentication object lifecycle:** a login filter creates an _unauthenticated_ `Authentication` holding what you typed, hands it to the `AuthenticationManager`, and receives a fully _authenticated_ one that has your authorities. That object then sits in the SecurityContext. Almost every feature above either creates this object, reads it, or protects it.

---

## Cheat sheet

|I want to...|Feature|
|---|---|
|Log users in with a form|`formLogin` + `UserDetailsService`|
|Store passwords safely|`PasswordEncoder`|
|Protect an admin section|`authorizeHttpRequests`|
|Protect a service method|`@PreAuthorize`|
|Block forged requests|CSRF (default on)|
|Secure a REST API with tokens|OAuth2 resource server (JWT)|
|Offer "Sign in with Google"|`oauth2Login`|
|Allow another site's JS to call my API|`cors`|
|Test secured endpoints|`@WithMockUser`|




[[Spring Security]]