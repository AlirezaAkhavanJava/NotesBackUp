

Here’s a recommended and widely used **project structure** for a modern Spring Boot + Spring Security 6 project (2025 best practices). This structure works very well for medium to large applications and keeps security concerns clean and maintainable.

### Recommended Project Structure

```
src/
├── main/
│   ├── java/
│   │   └── com/example/demo/
│   │       ├── DemoApplication.java            # Spring Boot main class
│   │       │
│   │       ├── config/                    # All configuration classes
│   │       │   ├── SecurityConfig.java    # Main Spring Securityconfiguration
│   │       │   ├── JwtConfig.java    # JWT filters, secret, etc. (if using JWT)
│   │       │   ├── MethodSecurityConfig.java #@PreAuthorize,@Secured(if needed)
│   │       │   ├── OAuth2ResourceServerConfig.java #If using OAuth2/JWT resource server
│   │       │   └── WebConfig.java                   # CORS, filters, etc.
│   │       │
│   │       ├── security/                            # Security-specific components
│   │       │   ├── jwt/
│   │       │   │   ├── JwtAuthenticationFilter.java
│   │       │   │   ├── JwtAuthenticationProvider.java
│   │       │   │   ├── JwtService.java              # JWT generation/validation
│   │       │   │   └── JwtAuthenticationEntryPoint.java
│   │       │   │
│   │       │   ├── oauth2/
│   │       │   │   └── CustomOAuth2UserService.java
│   │       │   │
│   │       │   ├── UserDetailsServiceImpl.java      # Custom UserDetailsService
│   │       │   ├── UserDetailsImpl.java             # Custom UserDetails implementation
│   │       │   ├── PasswordEncoderConfig.java       # BCryptPasswordEncoder bean
│   │       │   └── SecurityUtils.java               # Helper methods (get current user, etc.)
│   │       │
│   │       ├── controller/
│   │       │   ├── AuthController.java              # /login, /register, /refresh-token
│   │       │   ├── UserController.java
│   │       │   └── AdminController.java
│   │       │
│   │       ├── service/
│   │       │   ├── UserService.java
│   │       │   └── AuthService.java
│   │       │
│   │       ├── repository/
│   │       │   └── UserRepository.java
│   │       │
│   │       ├── entity/ (or model/)
│   │       │   ├── User.java
│   │       │   ├── Role.java
│   │       │   └── Authority.java
│   │       │
│   │       ├── dto/
│   │       │   ├── LoginRequest.java
│   │       │   ├── RegisterRequest.java
│   │       │   └── JwtResponse.java
│   │       │
│   │       └── exception/
│   │           ├── GlobalExceptionHandler.java
│   │           └── AuthenticationException.java
│   │
│   └── resources/
│       ├── application.yml  (or application-prod.yml, etc.)
│       ├── static/
│       └── templates/
```

### Minimalist Version (for small projects or learning)

If you don’t need JWT/custom filters yet, you can keep it very simple:

```
com.example.demo
├── DemoApplication.java
├── config
│   └── SecurityConfig.java          # Everything in one class (form login, HTTP basic, etc.)
├── controller
│   └── HomeController.java
└── ...
```

### Example: SecurityConfig.java (Spring Security 6 style – SecurityFilterChain)

```java
@Configuration
@EnableMethodSecurity          // for @PreAuthorize (optional)
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

### When to Split Further

| Feature                        | Add folder/class                              |
|--------------------------------|-----------------------------------------------|
| JWT authentication             | security/jwt/*                                |
| OAuth2 Login / Resource Server | security/oauth2/*                             |
| Custom UserDetailsService      | security/UserDetailsServiceImpl               |
| Method-level security          | config/MethodSecurityConfig.java             |
| Multiple authentication methods| Separate AuthenticationProviders              |

This structure scales nicely from a simple learning project to a production-grade microservice with JWT, OAuth2, refresh tokens, roles, permissions, and audit logging.




###### Tags : [[1 - Spring Security 🍌]]