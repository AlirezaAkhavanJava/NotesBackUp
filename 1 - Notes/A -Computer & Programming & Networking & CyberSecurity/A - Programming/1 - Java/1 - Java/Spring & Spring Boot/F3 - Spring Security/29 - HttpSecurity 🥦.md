


### Definition  
**HTTP Security in Spring Boot** refers to the configuration and mechanisms provided by **Spring Security** to protect the HTTP endpoints (REST APIs, web pages, etc.) of a Spring Boot application against common web vulnerabilities and unauthorized access.

In practice, it answers the questions:  
- Who is the user making this HTTP request? (Authentication)  
- Is this user allowed to access this URL or perform this action? (Authorization)  
- Is the request coming over HTTPS, protected from CSRF, CORS-safe, etc.? (Channel security & attack protection)

### Core Components You Configure

| Component                      | What it does                                                                 |
|--------------------------------|------------------------------------------------------------------------------|
| Authentication                 | Verifies identity (username/password, JWT, OAuth2 token, API key, etc.)     |
| Authorization                  | Decides if the authenticated user can access a specific endpoint/method    |
| CSRF Protection                | Prevents cross-site request forgery (enabled by default for stateful apps) |
| CORS                           | Controls which origins can call your API                                    |
| Session Management             | Stateless (JWT) vs stateful (classic session cookie)                        |
| Password Encoding              | BCrypt, Argon2, etc. for stored passwords                                   |
| Login / Logout                 | Form login, Basic Auth, OAuth2 Login (Google, GitHub…), or none (stateless) |
| Method Security (@PreAuthorize)| Secures service methods, not just URLs                                      |

### Most Common Real-World Styles in 2025

| Style                          | Typical Use Case                         | Authentication Method          |
|--------------------------------|------------------------------------------|--------------------------------|
| JWT + OAuth2 Resource Server   | Modern REST APIs, microservices, SPAs    | Bearer Token (stateless)       |
| OAuth2 Login + Session         | Traditional web apps (Thymeleaf, etc.)   | Session cookie                 |
| OAuth2 Login (Google, etc.)    | “Login with Google/GitHub” for web apps  | OpenID Connect                 |
| Basic Auth or API Keys         | Internal services, simple tools          | HTTP Basic or custom header    |

### Minimal Example (Spring Boot 3 + Spring Security 6)

```java
@EnableWebSecurity
@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/public/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .csrf(csrf -> csrf.disable())          // safe for pure APIs
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        return http.build();
    }
}
```

That single class is the modern definition of “HTTP Security in Spring Boot” for most production APIs today.

In short:  

Spring Boot HTTP Security = Spring Security configured to protect your HTTP endpoints with authentication, authorization, and web attack mitigations.

###### Tags : [[1 - Spring Security 🍌]]