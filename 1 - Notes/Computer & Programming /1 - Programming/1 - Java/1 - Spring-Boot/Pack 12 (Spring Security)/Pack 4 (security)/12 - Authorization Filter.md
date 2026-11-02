![[Spring Security Authorization Flow.png]]
# Spring Security Authorization Filter — Complete Tutorial

## 1. The problem it solves

Authentication answers **“Who are you?”** Authorization answers **“Are you allowed to do this?”**

Consider two users:

|Username|Authorities|Endpoint|
|---|---|---|
|`alice`|`ROLE_USER`|`GET /api/profile`|
|`alice`|`ROLE_USER`|`GET /api/admin`|
|`bob`|`ROLE_ADMIN`|`GET /api/admin`|

Both users might be authenticated, but only Bob should be allowed to access the admin endpoint. The `AuthorizationFilter` is one of the components that enforces that decision **before the request reaches Spring MVC**.

> **Mental model:** Authentication checks your ID card; authorization checks whether your ID card grants access to a particular room.

## 2. The big picture

In a typical Spring Security servlet application with URL-based authorization:

```
Client
  |
  | HTTP request
  v
Servlet container (Tomcat)
  |
  v
Spring Security's FilterChainProxy
  |
  v
Matching SecurityFilterChain
  |
  +--> SecurityContextHolderFilter
  |      Makes a SecurityContext available for the request
  |
  +--> Authentication filter (when applicable)
  |      Establishes an authenticated Authentication
  |
  +--> ExceptionTranslationFilter
  |      Handles security exceptions thrown downstream
  |
  +--> AuthorizationFilter
  |      Asks AuthorizationManager whether access is allowed
  |                |
  |             Decision
  |                |
  |       +--------+--------+
  |       |                 |
  |     GRANTED           DENIED
  |       |                 |
  |       v                 v
  |   Continue          AccessDeniedException
  |       |                 |
  |       v                 v
  | DispatcherServlet   ExceptionTranslationFilter
  |       |                 |
  |       v          401 or 403 response,
  |   Controller       depending on identity
  |       |
  |       v
  |    Response
  v
Client
```

The exact filter list and ordering depend on your configuration. The drawing is a **simplified** view, not a universal sequence of every installed filter.

**Important correction to simplified diagrams:** `SecurityContext` is not a separate filter that sends the request to `AuthorizationFilter`. It is the object from which an `AuthorizationManager` can obtain the current `Authentication` when evaluating access.

## 3. What is `AuthorizationFilter`?

`AuthorizationFilter` is a servlet filter that enforces request-level authorization using an `AuthorizationManager`.

Its core responsibility is approximately:

1. Receive the HTTP request after earlier filters.
2. Ask its `AuthorizationManager` to evaluate access using the current authentication and request.
3. **If access is granted**, invoke the rest of the servlet filter chain.
4. **If access is denied**, throw an `AccessDeniedException` (or a subtype).

It does **not** load the user from the database or validate a password. Those are authentication concerns.

### The components and their jobs

|Component|Job|
|---|---|
|`Authentication`|Represents the principal and the granted authorities|
|`SecurityContext`|Holds the current `Authentication`|
|`SecurityContextHolder`|Makes the current `SecurityContext` accessible|
|`AuthorizationFilter`|Enforces request-level access rules|
|`AuthorizationManager`|Evaluates authorization policy|
|`ExceptionTranslationFilter`|Translates authentication/authorization exceptions into HTTP behavior|
|`AuthenticationEntryPoint`|Starts authentication, often producing HTTP 401|
|`AccessDeniedHandler`|Handles access denial for an authenticated user, commonly HTTP 403|
|`DispatcherServlet`|Sends permitted requests to Spring MVC controllers|

## 4. `Authentication` and authorities

Once authentication succeeds, Spring Security has an `Authentication` object. Conceptually:

```
Authentication
  principal: alice
  authenticated: true
  authorities: [ROLE_USER]
```

Authorities are permissions represented by `GrantedAuthority` values. A role is commonly stored as an authority with the `ROLE_` prefix.

```
Authentication authentication =
        SecurityContextHolder.getContext().getAuthentication();

String username = authentication.getName();
boolean authenticated = authentication.isAuthenticated();
Collection<? extends GrantedAuthority> authorities =
        authentication.getAuthorities();
```

**Warning:** Some configurations supply an `AnonymousAuthenticationToken`; its `isAuthenticated()` may be `true` even though the caller is anonymous. To enforce a genuinely logged-in user, prefer Spring Security's `.authenticated()` authorization rule instead of building an authorization rule that relies only on `isAuthenticated()`.

## 5. `AuthorizationManager` — where the decision happens

`AuthorizationFilter` delegates access evaluation to an `AuthorizationManager` rather than hard-coding your role rules.

At a conceptual level:

```
AuthorizationFilter
      |
      | Authentication + HttpServletRequest
      v
AuthorizationManager
      |
      +--> URL/path matches which rule?
      +--> Is authentication required?
      +--> Does the principal have ROLE_ADMIN?
      |
      v
Permit or deny
```

The `authorizeHttpRequests` DSL configures request authorization managers behind the scenes.

Example policies:

```
.authorizeHttpRequests(auth -> auth
        .requestMatchers("/public/**").permitAll()
        .requestMatchers("/api/admin/**").hasRole("ADMIN")
        .requestMatchers("/api/profile").authenticated()
        .anyRequest().denyAll()
)
```

Rules are matched **in declaration order**, and the first matching rule applies. Keep specific paths before broad catch-all rules.

- `permitAll()` permits a matching request without requiring login.
- `authenticated()` requires an authenticated principal.
- `hasRole("ADMIN")` typically checks for the `ROLE_ADMIN` authority.
- `hasAuthority("documents:read")` checks for that exact authority string.
- `denyAll()` rejects access.

## 6. Authorization flow: success versus failure

Assume Alice has `ROLE_USER` and sends:

```
GET /api/admin/dashboard HTTP/1.1
Authorization: Basic <base64-credentials>
```

> Basic authentication is Base64-encoded, **not encrypted**. Use HTTPS outside local testing.

### Step A — Authentication

An authentication filter such as `BasicAuthenticationFilter` reads the credentials and asks `AuthenticationManager` to authenticate Alice. On success the current `SecurityContext` contains Alice's authenticated identity and authorities.

### Step B — Authorization

`AuthorizationFilter` evaluates the rule:

```
.requestMatchers("/api/admin/**").hasRole("ADMIN")
```

Alice has `ROLE_USER`, not `ROLE_ADMIN`, so access is denied.

### Step C — Exception handling

`AuthorizationFilter` throws an access-denied exception. `ExceptionTranslationFilter`, which wraps downstream authorization processing, handles it:

- **Authenticated user lacking access:** generally **403 Forbidden**, handled via an `AccessDeniedHandler`.
- **Unauthenticated caller requiring authentication:** generally authentication is commenced using an `AuthenticationEntryPoint`; for HTTP Basic that normally means **401 Unauthorized**.

HTTP status details may differ with custom security handlers and authentication mechanisms.

**The controller is not called** for a request rejected by URL authorization.

### Granted path

If Bob has `ROLE_ADMIN`, access is granted and processing continues to `DispatcherServlet`, which can invoke `AdminController`.

## 7. Runnable Spring Boot example

Use Spring Boot with the Spring Web and Spring Security starters. The example uses an in-memory user store so you can focus on authorization before adding PostgreSQL.

### Security configuration

```
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http)
            throws Exception {
        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/public").permitAll()
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/profile")
                            .authenticated()
                        .anyRequest().denyAll()
                )
                .httpBasic(Customizer.withDefaults())
                .build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    UserDetailsService userDetailsService(PasswordEncoder encoder) {
        UserDetails alice = User.withUsername("alice")
                .password(encoder.encode("alicePassword"))
                .roles("USER")
                .build();

        UserDetails bob = User.withUsername("bob")
                .password(encoder.encode("bobPassword"))
                .roles("ADMIN")
                .build();

        return new InMemoryUserDetailsManager(alice, bob);
    }
}
```

**Explanation, in order:**

1. `authorizeHttpRequests` registers policies for incoming requests.
2. `/public` is accessible without a login.
3. `/api/admin/**` requires `ROLE_ADMIN`.
4. `GET /api/profile` requires an authenticated user.
5. Requests matching nothing else are denied, rather than accidentally exposed.
6. `httpBasic` enables HTTP Basic authentication.
7. `UserDetailsService` provides test users and `PasswordEncoder` provides password hashing and verification.

### Controller

```
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DemoController {

    @GetMapping("/public")
    public String publicPage() {
        return "Public endpoint";
    }

    @GetMapping("/api/profile")
    public String profile(Authentication authentication) {
        return "Hello " + authentication.getName();
    }

    @GetMapping("/api/admin/dashboard")
    public String adminDashboard() {
        return "Admin dashboard";
    }
}
```

### Test on Linux

```
# Public endpoint: 200 OK
curl -i http://localhost:8080/public

# Without authentication: 401 Unauthorized
curl -i http://localhost:8080/api/profile

# Alice is authenticated: 200 OK
curl -i -u alice:alicePassword http://localhost:8080/api/profile

# Alice lacks ADMIN: 403 Forbidden
curl -i -u alice:alicePassword http://localhost:8080/api/admin/dashboard

# Bob has ADMIN: 200 OK
curl -i -u bob:bobPassword http://localhost:8080/api/admin/dashboard
```

This shows the distinction directly: Alice can authenticate successfully but still be denied an admin resource.

## 8. URL-based vs method-based authorization

There are **two separate enforcement locations** to understand:

|Type|Where it runs|Typical mechanism|
|---|---|---|
|Request/URL authorization|Servlet filter chain, before Spring MVC|`AuthorizationFilter` + `AuthorizationManager`|
|Method authorization|Around invocation of a secured method|Method-security interceptors + authorization managers|

For method security, enable it explicitly:

```
@Configuration
@EnableMethodSecurity
public class MethodSecurityConfig {
}
```

Then secure a service method:

```
@Service
public class AdminService {

    @PreAuthorize("hasRole('ADMIN')")
    public String getSensitiveReport() {
        return "Sensitive report";
    }
}
```

**Important:** `@PreAuthorize` does **not** execute inside `AuthorizationFilter`. Method security has its own interception mechanism, commonly built with Spring AOP. It enforces rules when the secured method is invoked through the relevant Spring proxy.

You can use request authorization and method authorization together as defense in depth.

## 9. Custom authorization rules

For specialized business constraints, you can provide a custom `AuthorizationManager` or implement authorization in a protected service layer.

For example, a rule might say:

> A user may update a task only if the task belongs to that user.

That is more specific than merely checking `ROLE_USER`. It often requires checking resource ownership using the authenticated principal and a task identifier.

A high-level policy could be:

```
Authenticated user?
     |
     +-- No --> Reject
     |
     +-- Yes --> Owns requested task?
                     |
                     +-- Yes --> Allow
                     +-- No  --> Deny
```

For ownership rules, remember that a frontend hiding a button is **not** authorization. The backend must enforce ownership independently.

## 10. Common mistakes

|Mistake|Why it is wrong|Better approach|
|---|---|---|
|“Authenticated means permitted.”|A valid identity can lack permissions.|Check roles, authorities, or ownership.|
|“AuthorizationFilter validates passwords.”|Password verification is part of authentication.|Use authentication providers.|
|“`@PreAuthorize` runs inside AuthorizationFilter.”|It is method-level security.|Distinguish servlet filters from method interceptors.|
|“`hasRole("ADMIN")` looks for `ADMIN`.”|Default role rules use the `ROLE_` prefix.|Assign `ROLE_ADMIN` or use `hasAuthority` for exact checks.|
|“A rejected request always gives 403.”|Unauthenticated requests often trigger an authentication entry point and yield 401.|Distinguish unauthenticated and forbidden.|
|“If the UI hides the admin page, it is secured.”|An attacker can still call the endpoint directly.|Enforce checks on the server.|
|“Put `anyRequest().permitAll()` first.”|Broad first-match rules can shadow restrictive rules.|Specific rules first; catch-all last.|

## 11. Practice exercises

1. Add `/api/reports` so only users with `ROLE_ADMIN` can access it.
2. Try the same endpoint as Alice and Bob; explain the different status codes.
3. Create a `/api/settings` endpoint that allows either `ROLE_ADMIN` or `ROLE_MANAGER` using `.hasAnyRole("ADMIN", "MANAGER")`.
4. Enable method security and add `@PreAuthorize("hasRole('ADMIN')")` to a service method.
5. Add an endpoint that requires an exact authority such as `task:delete` instead of a role.

## 12. The whole picture

```
AUTHENTICATION                          AUTHORIZATION
--------------                          -------------
Who are you?                            May you access this resource?
      |                                              |
      v                                              v
Authentication Filter                  AuthorizationFilter
      |                                              |
      v                                              v
AuthenticationManager                  AuthorizationManager
      |                                              |
      v                                              v
AuthenticationProvider                 Policy evaluation
      |                                   /             \
      v                                ALLOW             DENY
UserDetailsService / PasswordEncoder     |                |
      |                                 v                v
      v                          DispatcherServlet   Security exception
Authenticated Authentication             |                |
      |                                 v                v
      v                              Controller       401 or 403
SecurityContext
```

**Remember:**

- **Authentication** establishes the user's identity.
- **Authorization** determines whether the user can perform a requested operation.
- `AuthorizationFilter` is responsible for **request-level** authorization decisions, delegated to an `AuthorizationManager`.
- Spring Security can enforce **method-level** authorization separately.
- A successful authentication does not guarantee permission.




[[Spring Security]]