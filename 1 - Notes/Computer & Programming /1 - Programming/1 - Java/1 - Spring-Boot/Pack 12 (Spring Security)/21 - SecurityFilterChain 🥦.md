
**WebSecurityConfigurerAdapter is gone.**  
In Spring Security 6+, the “web security config class” is simply a `@Configuration` class that declares a **SecurityFilterChain bean**.

Below is the clean, correct template you should use in modern Spring Security.

---

# 1️⃣ Minimal Web Security Filter Chain Class

```java
@Configuration
@EnableMethodSecurity   // optional
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {

        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .formLogin(withDefaults())
            .httpBasic(withDefaults());

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

This is the modern equivalent of the old `WebSecurityConfigurerAdapter`.

---

# 2️⃣ What This Class Actually Does

The class configures:

### **1. Filters**

`SecurityFilterChain` tells Spring _which security filters to apply and in what order._  
Filters include:

- `UsernamePasswordAuthenticationFilter`
    
- `BasicAuthenticationFilter`
    
- `ExceptionTranslationFilter`
    
- `SecurityContextPersistenceFilter`
    
- and many more
    

Spring Security creates the full chain based on your `.formLogin()`, `.httpBasic()`, `.csrf()`, etc.

---

### **2. Authorization Rules**

Configured by:

```java
authorizeHttpRequests(auth -> auth
```

You control:

- what paths require authentication
    
- what paths are open
    
- what roles are needed
    

---

### **3. Authentication Mechanisms**

Added automatically when you call:

- `.formLogin()`
    
- `.httpBasic()`
    
- custom authentication providers
    
- JWT filters (when added)
    

---

### **4. Builds the final chain**

The last line:

```java
return http.build();
```

Assembles the full **SecurityFilterChain** object that Spring Security will use for every request.

---

# 3️⃣ Advanced Example with Custom Filter

```java
@Configuration
public class SecurityConfig {

    private final AuthenticationManager authManager;
    private final CustomApiKeyFilter apiKeyFilter;

    public SecurityConfig(AuthenticationManager authManager,
                          CustomApiKeyFilter apiKeyFilter) {
        this.authManager = authManager;
        this.apiKeyFilter = apiKeyFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {

        http
            .csrf(csrf -> csrf.disable())
            .addFilterBefore(apiKeyFilter, UsernamePasswordAuthenticationFilter.class)
            .authorizeHttpRequests(auth -> auth
                .anyRequest().authenticated()
            );

        return http.build();
    }
}
```

This is how you insert your own filter into the chain.

---

# 4️⃣ Full Breakdown of the Bean

The `SecurityFilterChain` bean is responsible for:

1. **Selecting which filters execute**
    
2. **Ordering them**
    
3. **Connecting them**
    
4. **Applying your authentication rules**
    
5. **Applying your authorization rules**
    
6. **Attaching your custom filters/providers**
    

It is the entry point of _all Spring Security logic_.

---

If you want, I can show:

- the **full list of Spring Security filters in order**
    
- where each filter sits in the chain
    
- what each filter specifically does
    

Tell me if you want the full filter-chain breakdown.


##### Tags : [[1 - Spring Security 🍌]]