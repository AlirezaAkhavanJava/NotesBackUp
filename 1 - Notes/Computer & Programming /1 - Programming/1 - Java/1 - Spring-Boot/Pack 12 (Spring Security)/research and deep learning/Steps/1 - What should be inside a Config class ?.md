
# A **real** Spring Security config class must contain these things:

---

# ✅ 1. `@Configuration` + `@EnableWebSecurity`

Tells Spring: “This class controls security.”

```java
@Configuration
@EnableWebSecurity
public class WebSecurityConfig {
}
```

---

# ✅ 2. A `SecurityFilterChain` bean

This is **mandatory** in Spring Security 6+.

It defines:

- authentication rules
    
- authorization rules
    
- login/logout rules
    
- csrf rules
    
- session rules
    
- basically ALL HTTP security
    

Example minimal version:

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(auth -> auth
            .anyRequest().authenticated()
        )
        .formLogin();

    return http.build();
}
```

---

# ✅ 3. A `PasswordEncoder` bean

You need this for user passwords.

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

---

# ✔️ Optional but common

Depending on your project:

### ➤ UserDetailsService

Used to load users from DB.

```java
@Bean
public UserDetailsService userDetailsService() {
    return new InMemoryUserDetailsManager();
}
```

### ➤ AuthenticationProvider

For custom auth logic.

```java
@Bean
public AuthenticationProvider authProvider() {
    DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
    provider.setUserDetailsService(userDetailsService());
    provider.setPasswordEncoder(passwordEncoder());
    return provider;
}
```

---

# 🎯 FINAL SUMMARY (super short)

A _proper_ Spring Security config class should have:

1. `@Configuration` + `@EnableWebSecurity`
    
2. **SecurityFilterChain** → defines the rules
    
3. **PasswordEncoder** → handles password hashing 
    
4. _(Optional)_ UserDetailsService
    
5. _(Optional)_ AuthenticationProvider
    



##### Tags : [[1 - Spring Security 🍌]]