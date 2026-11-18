

# Spring Security — Complete Learning Roadmap

> **Goal:** Become capable of designing, implementing, debugging, and securing production-ready Spring Boot applications using Spring Security.
> 
> **Technology:** Java, Spring Boot 4, Spring Security 7, PostgreSQL, REST APIs.

## Phase 0 — Prerequisites

Before studying Spring Security itself, understand the technologies underneath it.

- HTTP and HTTPS
    
- HTTP request and response
    
- HTTP headers
    
- HTTP status codes (200, 401, 403, etc.)
    
- HTTP cookies
    
- Sessions
    
- Servlet
    
- Servlet Container (Tomcat)
    
- `HttpServletRequest`
    
- `HttpServletResponse`
    
- Servlet Filters
    
- `FilterChain`
    
- `DispatcherServlet`
    
- Spring IoC and Dependency Injection
    

**Your goal:** Understand how an HTTP request travels from a client through Tomcat and Spring MVC to a controller.

---

## Phase 1 — Spring Security Fundamentals

**Level: Beginner**

Learn what Spring Security is and why it exists.

- What is Spring Security?
    
- Why do we need application security?
    
- What is Authentication?
    
- What is Authorization?
    
- Authentication vs Authorization
    
- What is a Principal?
    
- What are Credentials?
    
- What is an Authority?
    
- Roles vs Permissions
    
- What happens when Spring Security is added to a project?
    
- Spring Security auto-configuration
    
- `@EnableWebSecurity`
    
- `@Configuration`
    
- `SecurityFilterChain`
    
- `HttpSecurity`
    
- `Customizer`
    
- Configuring public and protected endpoints
    

### Practice

Create a Spring Boot application with three endpoints:

```
GET /public     → Everyone can access
GET /user       → Authenticated users only
GET /admin      → Users with ADMIN role only
```

Start by configuring these using `SecurityFilterChain`.

---

## Phase 2 — Spring Security Architecture

**Level: Beginner → Intermediate**

This is one of the most important phases.

Instead of memorizing configuration, understand what Spring Security does internally.

### Learn in this order

- Servlet `Filter` interface
    
- Servlet `FilterChain`
    
- `DelegatingFilterProxy`
    
- `FilterChainProxy`
    
- `SecurityFilterChain`
    
- Multiple SecurityFilterChains
    
- Authentication Filters
    
- `SecurityContextHolderFilter`
    
- `AuthorizationFilter`
    
- `ExceptionTranslationFilter`
    
- `AuthenticationEntryPoint`
    
- `AccessDeniedHandler`
    
- Custom Filters
    
- `OncePerRequestFilter`
    
- Filter ordering
    

### Understand this request flow

```
CLIENT
  |
  v
TOMCAT
  |
  v
Servlet FilterChain
  |
  v
DelegatingFilterProxy
  |
  v
FilterChainProxy
  |
  v
Matching SecurityFilterChain
  |
  |-- SecurityContext management
  |
  |-- CSRF / security protection
  |
  |-- Authentication filters
  |
  |-- AuthorizationFilter
  |
  v
DispatcherServlet
  |
  v
Controller
  |
  v
Service
  |
  v
Repository
```

This is a simplified flow. The actual filters and their order depend on your security configuration.

**Your goal:** Be able to explain how a request reaches Spring MVC and how Spring Security can stop it before the controller executes.

---

## Phase 3 — Authentication Internals

**Level: Intermediate**

Now learn how Spring Security verifies a user's identity.

### Core components

- `Authentication` interface
    
- `AuthenticationManager`
    
- `ProviderManager`
    
- `AuthenticationProvider`
    
- `DaoAuthenticationProvider`
    
- `UserDetails`
    
- `UserDetailsService`
    
- `UsernamePasswordAuthenticationToken`
    
- `SecurityContext`
    
- `SecurityContextHolder`
    
- `SecurityContextRepository`
    
- `GrantedAuthority`
    
- `PasswordEncoder`
    

### Authentication mechanisms

- HTTP Basic Authentication
    
- Form-based Authentication
    
- Username/password authentication
    
- In-memory authentication
    
- Database-backed authentication
    

### Understand this flow

```
Username + Password
        |
        v
Authentication Filter
        |
        v
AuthenticationManager
        |
        v
AuthenticationProvider
        |
        v
UserDetailsService
        |
        v
Database / User Store
        |
        v
PasswordEncoder.matches()
        |
        v
Authentication Result
        |
        v
SecurityContext
```

This illustrates a common username/password authentication flow. Other authentication mechanisms use different providers and components.

### Practice

Create two users in memory:

```
Username: admin
Role: ADMIN

Username: user
Role: USER
```

Implement HTTP Basic authentication and test both accounts with curl or Postman.

**Your goal:** Understand exactly how Spring Security checks credentials and establishes an authenticated identity.

---

## Phase 4 — Authentication with PostgreSQL

**Level: Intermediate**

Move from hardcoded users to real database users.

### Learn

- Spring Security integration with Spring Data JPA
    
- Designing an `AppUser` entity
    
- Storing users in PostgreSQL
    
- Password hashing vs encryption
    
- `BCryptPasswordEncoder`
    
- `DelegatingPasswordEncoder`
    
- Implementing `UserDetailsService`
    
- Custom `UserDetails`
    
- Registration service
    
- Login authentication
    
- Invalid credentials handling
    
- Disabled and locked accounts
    
- Unique usernames and emails
    

### Practice Project — User Authentication System

Build:

```
POST /api/auth/register
POST /api/auth/login

GET  /api/users/me
GET  /api/admin/dashboard
```

Create a PostgreSQL table:

```
app_users
---------
id
username
email
password_hash
enabled
created_at
```

Hash passwords in the service layer before persistence using `PasswordEncoder`. Never store plaintext passwords.

**Your goal:** Authenticate actual application users stored in PostgreSQL.

---

## Phase 5 — Authorization and Access Control

**Level: Intermediate**

Authentication asks _Who are you?_

Authorization asks _What are you allowed to do?_

### Learn

- `authorizeHttpRequests()`
    
- `requestMatchers()`
    
- `permitAll()`
    
- `authenticated()`
    
- `denyAll()`
    
- `hasRole()`
    
- `hasAnyRole()`
    
- `hasAuthority()`
    
- Role prefixes (`ROLE_`)
    
- Role-Based Access Control (RBAC)
    
- Permission-based authorization
    
- `AuthorizationManager`
    
- `@EnableMethodSecurity`
    
- `@PreAuthorize`
    
- `@PostAuthorize`
    
- Object-level authorization
    
- Difference between 401 and 403
    

### Example

```
@PreAuthorize("hasRole('ADMIN')")
public void deleteUser(Long id) {
    // Only ADMIN users are allowed.
}
```

### Practice

Implement:

|Endpoint|Required access|
|---|---|
|`/api/public/**`|Everyone|
|`/api/profile/**`|Authenticated|
|`/api/admin/**`|ADMIN|
|`/api/moderator/**`|MODERATOR or ADMIN|

Add ownership checks so users can update their own profiles but not another user's profile.

**Your goal:** Secure both HTTP endpoints and business operations.

---

## Phase 6 — Sessions and Stateful Authentication

**Level: Intermediate**

Before JWT, understand traditional authentication with HTTP sessions.

### Learn

- What is an HTTP Session?
    
- `HttpSession`
    
- `JSESSIONID` cookie
    
- Session-based authentication
    
- `SecurityContextRepository`
    
- `HttpSessionSecurityContextRepository`
    
- Session creation policies
    
- `SessionCreationPolicy`
    
- `SessionCreationPolicy.STATELESS`
    
- Session fixation protection
    
- Session expiration
    
- Login and logout
    
- Remember-me authentication
    
- Concurrent session control
    
- Stateful vs Stateless Authentication
    

### Practice

Create a login system where:

1. A user logs in.
    
2. The server maintains an authenticated session.
    
3. The browser sends the session cookie on later requests.
    
4. The server recognizes the user's session.
    
5. Logging out invalidates the session.
    

**Your goal:** Understand how a server remembers an authenticated user across requests.

---

## Phase 7 — Web Security and Common Attacks

**Level: Intermediate**

Authentication alone does not make an application secure.

### Learn

- CSRF (Cross-Site Request Forgery)
    
- `CsrfFilter`
    
- CSRF tokens
    
- CORS (Cross-Origin Resource Sharing)
    
- CORS configuration
    
- XSS (Cross-Site Scripting)
    
- Clickjacking
    
- Security HTTP headers
    
- Content Security Policy (CSP)
    
- HTTPS and TLS
    
- HSTS
    
- Cookie security (`HttpOnly`, `Secure`, `SameSite`)
    
- Session hijacking
    
- Session fixation
    
- Brute-force attacks
    
- Login rate limiting
    

### Important

Do not automatically disable CSRF protection just because you are developing a REST API.

Whether CSRF protection is needed depends on how the browser authenticates requests, particularly whether credentials such as cookies are sent automatically.

**Your goal:** Understand common web vulnerabilities and which protections Spring Security provides.

---

## Phase 8 — JWT and Stateless Authentication

**Level: Intermediate → Advanced**

Now you are ready to study JWT.

### JWT fundamentals

- What is a Token?
    
- What is a Bearer Token?
    
- What is JWT?
    
- JWT Header
    
- JWT Payload
    
- JWT Signature
    
- JWT Claims
    
- Signed vs Encrypted tokens
    
- Token expiration
    
- Access tokens
    
- Refresh tokens
    
- Token validation
    
- Token revocation
    
- Token rotation
    
- Secure token storage
    

### Spring Security JWT implementation

- Stateless security architecture
    
- Bearer-token authentication
    
- Spring Security OAuth2 Resource Server
    
- `JwtDecoder`
    
- `JwtAuthenticationProvider`
    
- `JwtAuthenticationConverter`
    
- JWT signature validation
    
- JWT authorities and scopes
    
- `oauth2ResourceServer()`
    
- Understanding custom JWT filters
    
- When custom filters are actually necessary
    

### Practice Project — JWT Protected REST API

```
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout

GET  /api/movies
POST /api/movies
DELETE /api/movies/{id}
```

Use properly issued JWT access tokens to authorize API requests.

Prefer Spring Security's built-in Resource Server support for JWT verification rather than writing a custom JWT validation filter without a specific requirement.

**Your goal:** Build and protect stateless REST APIs while understanding token issuance, verification, and lifecycle management.

---

## Phase 9 — OAuth2 and OpenID Connect

**Level: Advanced**

Learn industry-standard delegated authorization and federated login.

### OAuth2

- What is OAuth 2.0?
    
- OAuth2 Roles
    
- Resource Owner
    
- Client
    
- Authorization Server
    
- Resource Server
    
- Access Tokens
    
- Scopes
    
- Authorization Code Flow
    
- PKCE
    
- Client Credentials Flow
    
- Token introspection
    

### OpenID Connect

- Authentication vs delegated authorization
    
- OpenID Connect (OIDC)
    
- ID Token
    
- UserInfo endpoint
    
- OIDC discovery
    
- Social login
    
- Login with Google / GitHub
    
- Identity providers
    

### Spring Security

- OAuth2 Client
    
- `oauth2Login()`
    
- OAuth2 Resource Server
    
- Spring Security Authorization Server
    
- Integrating with Keycloak
    

**Your goal:** Understand how modern applications authenticate through identity providers and protect distributed services.

---

## Phase 10 — Testing Spring Security

**Level: Intermediate → Advanced**

Security rules must be verified automatically.

### Learn

- `spring-security-test`
    
- `@WithMockUser`
    
- `@WithUserDetails`
    
- MockMvc security integration
    
- Testing 401 responses
    
- Testing 403 responses
    
- Testing method authorization
    
- Testing CSRF protection
    
- Testing authenticated requests
    
- Testing JWT-protected endpoints
    
- Testing password encoding
    
- Integration tests with PostgreSQL/Testcontainers
    

### Practice

Write tests for:

```
Anonymous user → protected endpoint → 401

Authenticated USER → admin endpoint → 403

Authenticated ADMIN → admin endpoint → 200

User A → User B's private data → denied
```

The final ownership test is particularly important because role checks alone cannot prevent access to another user's data.

**Your goal:** Confidently change security configuration without accidentally exposing endpoints or sensitive operations.

---

## Phase 11 — Advanced and Production Security

**Level: Advanced → Professional**

Study these after completing the previous phases.

- Custom `AuthenticationProvider`
    
- Multiple `SecurityFilterChain` configurations
    
- Custom `AuthenticationEntryPoint`
    
- Custom `AccessDeniedHandler`
    
- Authentication success/failure handlers
    
- Authentication events and audit logs
    
- Multi-Factor Authentication (MFA)
    
- Passkeys and WebAuthn
    
- Password reset flows
    
- Email verification
    
- Account lockout and throttling
    
- Secret and signing-key management
    
- JWT key rotation
    
- Security monitoring
    
- Dependency vulnerability scanning
    
- Least-privilege access control
    
- OAuth2 security best practices
    
- Spring Security in microservices
    
- Spring Cloud Gateway security
    
- Reactive Spring Security (WebFlux), when needed
    

**Your goal:** Design security systems that remain maintainable, observable, and resilient in production.

---

# Recommended Project Progression

Learn each group of concepts by implementing a progressively more capable application.

|Project|What you build|Phases|
|---|---|---|
|1. Basic Security|Protected endpoints and HTTP Basic|0–3|
|2. User Management|PostgreSQL users, registration, login|4–5|
|3. Session Login|Session cookies, logout, CSRF|6–7|
|4. Secure REST API|JWT validation, roles, permissions|8|
|5. Social Login|OAuth2 and OIDC login|9|
|6. Production Hardening|Tests, security controls, monitoring|10–11|

# What You Should Focus on First

Since you already know Spring Boot REST APIs, servlet fundamentals, `SecurityFilterChain`, `HttpSecurity`, and some authentication components, follow this immediate sequence:

- 1. `DelegatingFilterProxy` and `FilterChainProxy`
    
- 2. `SecurityFilterChain` and filter execution
    
- 3. `Authentication` and `AuthenticationManager`
    
- 4. `AuthenticationProvider` and `DaoAuthenticationProvider`
    
- 5. `UserDetailsService` and `UserDetails`
    
- 6. `PasswordEncoder`
    
- 7. `SecurityContext` and `SecurityContextHolder`
    
- 8. `AuthorizationFilter` and `AuthorizationManager`
    
- 9. `@PreAuthorize` and role-based access control
    
- 10. PostgreSQL-backed registration and login
    

Once you can implement these concepts without copying an entire tutorial, move to session-based authentication, CSRF, and then JWT.

# Modern Spring Security Notes

Use modern Spring Security 7 configuration styles.

Prefer:

```
http.authorizeHttpRequests(auth -> auth
        .requestMatchers("/public/**").permitAll()
        .anyRequest().authenticated()
);
```

Avoid learning obsolete approaches as your primary method:

- `WebSecurityConfigurerAdapter` — removed in Spring Security 6.
    
- `authorizeRequests()` — removed in Spring Security 7.
    
- `antMatchers()` — old configuration style.
    
- Chained `.and()` configuration — replaced by the lambda DSL in Spring Security 7.
    

You should still recognize older APIs when reading existing projects.

# The Whole Picture

|Area|Main question it answers|
|---|---|
|HTTP / Servlets|How does a request reach the application?|
|Security Filters|How does Spring Security intercept it?|
|Authentication|Who is making the request?|
|AuthenticationManager|Who coordinates authentication?|
|AuthenticationProvider|How are credentials verified?|
|UserDetailsService|Where are user details loaded from?|
|SecurityContext|Where is the authenticated identity held?|
|Authorization|What may this user access?|
|PasswordEncoder|How are passwords securely stored and verified?|
|Sessions|How does stateful authentication persist?|
|JWT|How can requests authenticate using signed tokens?|
|OAuth2 / OIDC|How do external authorization and identity systems integrate?|
|Security Testing|How do we verify our controls work?|
|Production Security|How do we defend and maintain the whole system?|

## Final Advice

**Learn the architecture before trying to customize it.**

A Spring Security developer should be able to explain the full request lifecycle, configure authentication and authorization, and debug why a request was accepted or rejected.

JWT, OAuth2, and advanced authentication mechanisms become much easier once those foundations are solid.

The two best topics to study next are:

1. **Complete Spring Security Filter Chain Architecture** — understand how filters are selected and executed.
    
2. **AuthenticationManager and AuthenticationProvider Internals** — understand exactly how a user's credentials are verified.



[[Spring Security]]