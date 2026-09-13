
 In Spring Security, you **do not manually add individual `Filter` objects** one by one like in older versions. Instead, you configure **what Spring Security should do**, and Spring automatically builds and orders the **correct chain of filters** for you based on your configuration.

### Where are you actually adding the filters?

You **define the behavior** inside the `SecurityFilterChain` bean, and Spring Security **automatically** creates and inserts the appropriate filters into the filter chain.

Example:

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth
            .anyRequest().authenticated()
        )
        .formLogin(withDefaults())
        .httpBasic(withDefaults())
        .csrf(csrf -> csrf.disable());  // only for stateless APIs

    return http.build();
}
```

When you do this, Spring Security **internally** adds and configures a whole chain of filters (about 10–15 filters) in a specific order.  
You **don't touch the filters directly** — you just tell Spring Security **what you want**, and it builds the correct filter chain for you.

### What filters are typically added in a production application?

Here’s a realistic breakdown of what filters Spring Security includes in a typical **production-ready** application:

| Filter (in order)                  | Purpose                                                                 | Usually enabled in production? |
|------------------------------------|-------------------------------------------------------------------------|--------------------------------|
| `ChannelProcessingFilter`          | Enforces HTTPS (if configured with `.requiresChannel()`).               | Yes (if using HTTPS)           |
| `SecurityContextPersistenceFilter` | Loads/stores `SecurityContext` (user info) from session or token.       | Yes                            |
| `HeaderWriterFilter`               | Adds security headers (X-Frame-Options, CSP, HSTS, etc.).               | Yes                            |
| `CsrfFilter`                       | Prevents CSRF attacks (enabled by default).                             | Yes (for stateful apps)        |
| `LogoutFilter`                     | Handles `/logout` requests.                                             | Yes                            |
| `UsernamePasswordAuthenticationFilter` | Processes form login (`/login`).                                   | Yes (if using form login)      |
| `DefaultLoginPageGeneratingFilter` | Generates default login page (if you didn't provide custom).           | Optional (use custom page)     |
| `BasicAuthenticationFilter`        | Handles HTTP Basic Auth.                                                | Optional (mostly for APIs)     |
| `FilterSecurityInterceptor`        | Final filter: enforces authorization (roles, permissions).              | Always                         |
| `ExceptionTranslationFilter`       | Handles access denied, authentication exceptions (redirects to login).  | Always                         |

### Recommended production configuration (modern, secure defaults)

Here’s a **production-ready** `SecurityFilterChain` example for a typical **stateful web app** (with session-based authentication):

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // 1. Enforce HTTPS in production
            .requiresChannel(channel -> channel
                .anyRequest().requiresSecure()  // redirect HTTP → HTTPS
            )

            // 2. Authorization rules
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**", "/css/**", "/js/**", "/images/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/**").authenticated()
                .anyRequest().authenticated()
            )

            // 3. Form login (recommended for web apps)
            .formLogin(form -> form
                .loginPage("/login")
                .defaultSuccessUrl("/home")
                .permitAll()
            )

            // 4. Logout
            .logout(logout -> logout
                .logoutUrl("/logout")
                .logoutSuccessUrl("/login?logout")
                .invalidateHttpSession(true)
                .deleteCookies("JSESSIONID")
                .permitAll()
            )

            // 5. Security headers (very important!)
            .headers(headers -> headers
                .frameOptions(frame -> frame.deny())          // prevent clickjacking
                .httpStrictTransportSecurity(hsts -> hsts
                    .includeSubDomains(true)
                    .maxAgeInSeconds(31536000) // 1 year
                )
                .contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'self'"))
            )

            // 6. Session management
            .sessionManagement(session -> session
                .maximumSessions(1)                          // one session per user
                .maxSessionsPreventsLogin(true)
                .expiredUrl("/login?expired")
            )

            // 7. CSRF enabled by default – do NOT disable unless it's a stateless API
            // .csrf(csrf -> csrf.disable())  // ← only for pure REST APIs with JWT/OAuth

            // 8. Optional: HTTP Basic (for testing or APIs, usually disabled in prod)
            // .httpBasic(withDefaults());
        ;

        return http.build();
    }

    // Recommended: strong password encoding
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12); // strength 12 is good for production
    }
}
```

### Summary: What you should add in production

| Feature                          | Production recommendation                          |
|----------------------------------|----------------------------------------------------|
| HTTPS enforcement                | Yes (`.requiresChannel().anyRequest().requiresSecure()`) |
| Security headers                 | Yes (HSTS, X-Frame-Options, CSP, etc.)             |
| Form login                       | Yes (custom login page)                            |
| CSRF protection                  | Yes (keep enabled unless stateless API)            |
| Session management               | Yes (limit sessions, invalidate on logout)         |
| Role-based access control        | Yes (`.hasRole()`, `.hasAnyRole()`)                |
| Password encoding                | Yes (BCrypt or Argon2)                             |
| HTTP Basic Auth                  | Usually **no** (disable in production)             |

### Quick rule of thumb

- **Web app with sessions** → use **form login**, keep **CSRF**, add **security headers**, enforce **HTTPS**.
- **Stateless REST API** → disable **CSRF**, use **JWT/OAuth2**, add **security headers**, enforce **HTTPS**.

You **never manually add filters** — you just configure the `HttpSecurity` object, and Spring Security takes care of building the proper filter chain for you.

#### Tags : [[1 - Spring Security 🍌]]