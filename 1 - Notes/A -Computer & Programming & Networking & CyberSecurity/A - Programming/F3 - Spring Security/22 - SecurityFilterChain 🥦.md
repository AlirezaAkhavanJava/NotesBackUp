


### 1️⃣ What it is

- `SecurityFilterChain` is **the core interface representing the chain of security filters** for your application.
    
- Each chain applies to requests **matching certain criteria** (URL patterns, request matchers).
    
- Essentially, it **replaces the old `WebSecurityConfigurerAdapter`** configuration.
    

Think of it as a **recipe for how Spring Security handles requests**: which filters run, in which order, and what rules they enforce.

---

### 2️⃣ How it works

- Spring Security automatically finds all beans of type `SecurityFilterChain`.
    
- For each incoming HTTP request, it selects the **first chain whose matchers fit the request**.
    
- The selected chain’s filters process the request (authentication, authorization, CSRF, etc.) in order.
    

---

### 3️⃣ Creating a SecurityFilterChain Bean

```java
@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()  // disable CSRF for APIs
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers("/user/**").hasAnyRole("USER", "ADMIN")
                .anyRequest().authenticated()
            )
            .formLogin(Customizer.withDefaults())
            .httpBasic(Customizer.withDefaults());

        return http.build();
    }
}
```

**Key points:**

- `http.build()` creates a `SecurityFilterChain` instance.
    
- You can have **multiple `SecurityFilterChain` beans**, each with different `requestMatchers` for separate sets of endpoints.
    

---

### 4️⃣ Multiple Chains Example

```java
@Bean
public SecurityFilterChain apiFilterChain(HttpSecurity http) throws Exception {
    http
        .securityMatcher("/api/**") // only applies to /api endpoints
        .csrf().disable()
        .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
        .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

    return http.build();
}

@Bean
public SecurityFilterChain webFilterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
        .formLogin(Customizer.withDefaults());

    return http.build();
}
```

- Requests to `/api/**` use the first chain (stateless, token-based).
    
- Requests to other endpoints use the second chain (traditional form login).
    

---

### 5️⃣ Notes

- `SecurityFilterChain` **replaces the need for extending `WebSecurityConfigurerAdapter`**.
    
- Ordering matters when you have multiple chains; use `@Order` annotation if needed.
    
- All filters (authentication, authorization, CSRF, etc.) are configured via the `HttpSecurity` builder.
    

---




###### Tags : [[1 - Spring Security 🍌]]