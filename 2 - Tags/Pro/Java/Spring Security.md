

Spring Security is a Spring framework that protects your Java applications by controlling who can access them and what they are allowed to do.

For a Spring Boot backend, it provides authentication, authorization, and protection against common security attacks.

## 1. What problem does it solve?

Imagine you're building a task-management API with Spring Boot.

```
GET    /api/v1/tasks
POST   /api/v1/tasks
DELETE /api/v1/tasks/42
```

Without security rules, your application might allow anyone to access these endpoints.

Spring Security lets you define rules such as:

- Only authenticated users can view their tasks.
    
- Only the owner of a task can delete it.
    
- Only administrators can access administrative endpoints.
    
- Unauthenticated users must log in before accessing protected resources.
    

## 2. The three main concepts

Authentication

Who are you?

Verifies identity using credentials, sessions, tokens, or other supported mechanisms.

Authorization

What are you allowed to do?

Determines whether an authenticated user has permission to perform an operation.

Security protections

Helps protect against threats such as CSRF and supports secure password handling, security headers, and other defenses.

## 3. How does Spring Security work internally?

A typical request passes through a chain of security filters before reaching your controller.

1. HTTP Request

`POST /api/v1/tasks`

2. Security Filter Chain

Checks credentials and applies security rules

3. Authentication & Authorization

Identifies the user and checks permissions

4. Controller → Service → Repository

Executes the application logic if access is permitted

If access is denied, Spring Security generally stops the request before it reaches the controller. Depending on the situation, it may return `401 Unauthorized` or `403 Forbidden`.

## 4. A practical Spring Boot example

You configure security using a `SecurityFilterChain` bean.

```
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(
            HttpSecurity http) throws Exception {

        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/public/**").permitAll()
                        .requestMatchers("/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated()
                )
                .build();
    }
}
```

What these rules mean:

|Rule|Meaning|
|---|---|
|`permitAll()`|Anyone can access the matching endpoint.|
|`hasRole("ADMIN")`|The authenticated user needs the `ADMIN` role.|
|`authenticated()`|The user must be authenticated.|
|`anyRequest()`|Matches requests not covered by earlier rules.|

This is a basic configuration example, not a complete production security setup. For example, CSRF configuration depends on whether you're using browser sessions, stateless bearer tokens, or another authentication approach.

## 5. Where does it fit into Spring Boot?

A simplified view of the technologies:

- Spring MVC handles HTTP requests and routes them to controllers.
    
- Spring Security determines whether requests and operations are permitted.
    
- Spring Data JPA handles persistence through repositories.
    
- PostgreSQL stores your application data.
    

These technologies work together, but they solve different problems.

## What should you learn first?

I'd recommend this order for mastering Spring Security:

1. Security fundamentals: authentication, authorization, principals, roles, and authorities.
    
2. Filter chain: `SecurityFilterChain`, `DelegatingFilterProxy`, and security filters.
    
3. Configuration: `authorizeHttpRequests`, matchers, and access rules.
    
4. User authentication: `UserDetails`, `UserDetailsService`, `AuthenticationProvider`, and `PasswordEncoder`.
    
5. Advanced security: sessions, CSRF, CORS, JWT, OAuth 2.0, and method-level security.
    
6. Testing: verify access restrictions and test for security vulnerabilities.
    

The most important idea: Spring Security is not just a login system. It is an extensible security framework that integrates into the request-processing pipeline and enforces access-control policies throughout your application.


[[Java]]
[[Spring Framework]]