
> when i want to implement security for my application i need to create a configuration class holding a websecurityfilterchain and i can add every chain of security i want to it

You create a **configuration class** that provides a `SecurityFilterChain` bean, and in that bean you define **exactly** how security should behave for your application — including which endpoints are protected, what authentication methods are allowed, what roles are required, etc.

### Basic structure (Spring Boot 3.x / Spring Security 6+)

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // 1. Define which requests need authentication/authorization
            .authorizeHttpRequests(auth -> auth
                // Public endpoints (no login required)
                .requestMatchers("/api/public/**", "/home", "/").permitAll()
                
                // Endpoints that require authentication but any role is ok
                .requestMatchers("/api/user/**").authenticated()
                
                // Endpoints that require specific roles
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/manager/**").hasAnyRole("ADMIN", "MANAGER")
                
                // Everything else requires authentication
                .anyRequest().authenticated()
            )

            // 2. Choose authentication method(s)
            .formLogin(form -> form
                .loginPage("/login")              // custom login page (optional)
                .permitAll()
            )
            .httpBasic(httpBasic -> {})           // enable Basic Auth (optional)

            // 3. Logout configuration (optional)
            .logout(logout -> logout
                .logoutUrl("/logout")
                .logoutSuccessUrl("/home")
                .permitAll()
            )

            // 4. CSRF protection (enabled by default, disable only if needed)
            .csrf(csrf -> csrf.disable())  // ← careful: only for APIs or stateless apps

            // 5. Other common settings (optional)
            .sessionManagement(session -> session
                .maximumSessions(1)           // limit to one session per user
            );

        return http.build();
    }
}
```

### Key points you can configure in the `SecurityFilterChain`

| Feature                          | Method / Configuration                              |
|----------------------------------|-----------------------------------------------------|
| Which URLs are public            | `.requestMatchers(...).permitAll()`                 |
| Which URLs require login         | `.requestMatchers(...).authenticated()`             |
| Which URLs require roles         | `.hasRole("ADMIN")`, `.hasAnyRole(...)`             |
| Form login (username/password)   | `.formLogin()`                                      |
| HTTP Basic Auth                  | `.httpBasic()`                                      |
| JWT / OAuth2 / OAuth2 Resource Server | `.oauth2ResourceServer()` or `.oauth2Login()`     |
| Custom login page                | `.formLogin().loginPage("/my-login")`               |
| Remember-me                      | `.rememberMe()`                                     |
| CSRF protection                  | `.csrf()` (enabled by default)                      |
| CORS                             | `.cors()`                                           |
| Session management               | `.sessionManagement()`                              |

### Common additional beans you might need

```java
// Optional: Define users in memory (for testing)
@Bean
public UserDetailsService userDetailsService() {
    UserDetails user = User.withDefaultPasswordEncoder()
        .username("user")
        .password("password")
        .roles("USER")
        .build();

    UserDetails admin = User.withDefaultPasswordEncoder()
        .username("admin")
        .password("admin123")
        .roles("ADMIN")
        .build();

    return new InMemoryUserDetailsManager(user, admin);
}

// Optional: Password encoder (recommended)
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

### Summary – Yes, you have full control

When you add `spring-boot-starter-security`, Spring Security **no longer auto-configures** a default `SecurityFilterChain` if you provide your own `@Bean` of type `SecurityFilterChain`.  
This gives you **complete control** over:

- Which endpoints are secured
- Which authentication mechanisms are allowed
- Role-based access control
- Custom login/logout behavior

So yes — you create **one or more** `SecurityFilterChain` beans and configure **every chain of security** exactly the way you want.

That's the modern, flexible way to implement security in Spring Boot applications.


#### Tags : [[1 - Spring Security 🍌]]