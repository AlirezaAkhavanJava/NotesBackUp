![[Pasted image 20251119120905.png]]


### 1️⃣ What is the Security Filter Chain?

Spring Security works by **intercepting HTTP requests** before they hit your controllers. This interception is done via a **chain of servlet filters**, each responsible for a specific security task.

Think of it like a **conveyor belt of security checks**: each filter either lets the request pass, blocks it, or modifies it.

---

### 2️⃣ How It Works

1. A request comes in (e.g., `GET /admin`).
    
2. It enters the **filter chain**.
    
3. Filters execute in a pre-defined order:
    
    - **`SecurityContextPersistenceFilter`** – loads or creates a `SecurityContext` for the session.
        
    - **`UsernamePasswordAuthenticationFilter`** – handles form login authentication.
        
    - **`BasicAuthenticationFilter`** – handles HTTP Basic auth.
        
    - **`CsrfFilter`** – checks CSRF tokens.
        
    - **`ExceptionTranslationFilter`** – handles authentication/authorization exceptions.
        
    - **`FilterSecurityInterceptor`** – enforces URL-based access rules (`hasRole`, `permitAll`, etc.).
        
4. If authentication and authorization pass, the request reaches your controller.
    

---

### 3️⃣ Configuring a Filter Chain

Since **Spring Security 5.7+, `WebSecurityConfigurerAdapter` is deprecated**, so you define the filter chain with a `SecurityFilterChain` bean:

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf().disable()
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/admin/**").hasRole("ADMIN")
            .requestMatchers("/user/**").hasAnyRole("USER", "ADMIN")
            .anyRequest().authenticated()
        )
        .formLogin(withDefaults()); // default login page

    return http.build();
}
```

---

### 4️⃣ Custom Filters

You can insert custom filters **before** or **after** a standard filter:

```java
http.addFilterBefore(new MyCustomFilter(), UsernamePasswordAuthenticationFilter.class);
http.addFilterAfter(new AnotherFilter(), CsrfFilter.class);
```

This is useful for **JWT validation**, **logging**, **rate limiting**, etc.

---

### 5️⃣ Key Takeaways

- The **filter chain is the backbone** of Spring Security.
    
- **Order matters** – filters run in a strict sequence.
    
- You can **customize the chain** via `SecurityFilterChain` bean and add your own filters.
    
- Most high-level features (form login, JWT, OAuth) are implemented via filters.
    

---




###### Tags : [[1 - Spring Security 🍌]]