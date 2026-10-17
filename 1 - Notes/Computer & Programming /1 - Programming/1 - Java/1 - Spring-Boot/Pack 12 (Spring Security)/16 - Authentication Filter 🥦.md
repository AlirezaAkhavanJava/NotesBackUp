
### 1️⃣ What it is

An **Authentication Filter** is a special kind of filter in the **Spring Security Filter Chain** that handles **verifying user credentials** and establishing a **SecurityContext**.

- Input: request with username/password, token, or other credentials
    
- Output: authenticated user in the `SecurityContext` or failure
    

Think of it like the **bouncer at the club**: checks ID, decides if you get in, and assigns your “VIP status” (roles/authorities).

---

### 2️⃣ Common Authentication Filters

|Filter|Purpose|
|---|---|
|`UsernamePasswordAuthenticationFilter`|Handles form login (username & password)|
|`BasicAuthenticationFilter`|Handles HTTP Basic authentication (Authorization header)|
|`BearerTokenAuthenticationFilter`|Handles OAuth2/JWT Bearer tokens|
|`AbstractPreAuthenticatedProcessingFilter`|For pre-authenticated systems (like SSO)|

---

### 3️⃣ UsernamePasswordAuthenticationFilter Example

- Default filter for **form login**.
    
- It triggers **AuthenticationManager** which checks credentials using `UserDetailsService`.
    

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .csrf().disable()
        .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
        .formLogin(Customizer.withDefaults()); // automatically uses UsernamePasswordAuthenticationFilter
    return http.build();
}
```

**Flow**:

1. User submits login form (POST `/login`)
    
2. `UsernamePasswordAuthenticationFilter` extracts username & password
    
3. Delegates to `AuthenticationManager`
    
4. If success → stores Authentication in `SecurityContext`
    
5. If failure → redirects to `/login?error`
    

---

### 4️⃣ Custom Authentication Filter

You can create your own filter if you want **custom authentication logic**:

```java
public class MyAuthFilter extends UsernamePasswordAuthenticationFilter {

    @Override
    public Authentication attemptAuthentication(HttpServletRequest request,
                                                HttpServletResponse response) {
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        UsernamePasswordAuthenticationToken authToken =
            new UsernamePasswordAuthenticationToken(username, password);

        return this.getAuthenticationManager().authenticate(authToken);
    }
}
```

Add it to the chain:

```java
http.addFilterAt(new MyAuthFilter(), UsernamePasswordAuthenticationFilter.class);
```

---

### 5️⃣ Key Points

- **Runs before authorization filters** — authentication must happen first.
    
- Can handle **form login, tokens, SSO, API keys**, etc.
    
- Custom filters often extend `AbstractAuthenticationProcessingFilter` or `UsernamePasswordAuthenticationFilter`.
    

---

If you want, I can make a **diagram showing where the Authentication Filter sits in the full Spring Security Filter Chain**—it’s extremely helpful to visualize 🐐.

Do you want me to do that?

###### Tags : [[1 - Spring Security 🍌]]