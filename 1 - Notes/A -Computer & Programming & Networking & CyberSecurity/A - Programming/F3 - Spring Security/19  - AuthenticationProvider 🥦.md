

# 1️⃣ What AuthenticationProvider Is

`AuthenticationProvider` is the **component that performs actual credential validation**.

AuthenticationManager delegates to providers.  
Providers do the work.

Interface:

```java
Authentication authenticate(Authentication authentication)
    throws AuthenticationException;

boolean supports(Class<?> authentication);
```

Meaning:

- `supports()` → tells Spring which type of token this provider can handle
    
- `authenticate()` → validates the credentials and returns an **authenticated** token
    

---

# 2️⃣ The default provider: DaoAuthenticationProvider

This is the provider you use when working with a database + UserDetailsService.

It validates:

- username
    
- password (via PasswordEncoder)
    
- loads user from DB
    

Example configuration:

```java
@Bean
public DaoAuthenticationProvider authProvider(
        UserDetailsService userDetailsService,
        PasswordEncoder passwordEncoder) {

    DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
    provider.setUserDetailsService(userDetailsService);
    provider.setPasswordEncoder(passwordEncoder);

    return provider;
}
```

Spring Security then puts this provider inside `ProviderManager` (AuthenticationManager).

---

# 3️⃣ How Providers Fit Into the Flow

Full authentication pipeline:

```
[Authentication Filter]
         ↓
authToken = new UsernamePasswordAuthenticationToken(username, password)
         ↓
authenticationManager.authenticate(authToken)
         ↓
ProviderManager (AuthenticationManager)
         ↓
iterates through AuthenticationProviders
         ↓
 DaoAuthenticationProvider supports? yes
         ↓
authenticate()
         ↓
return authenticated Authentication object
         ↓
SecurityContextHolder stores it
```

---

# 4️⃣ Creating a CUSTOM AuthenticationProvider

You need this when you want to authenticate using:

- API key
    
- JWT
    
- Custom headers
    
- Token from another service
    
- Anything not username/password
    

### Step 1: Create a custom Authentication token

```java
public class ApiKeyAuthToken extends AbstractAuthenticationToken {

    private final String apiKey;

    public ApiKeyAuthToken(String apiKey) {
        super(null);
        this.apiKey = apiKey;
        setAuthenticated(false);
    }

    public ApiKeyAuthToken(String apiKey, Collection<? extends GrantedAuthority> authorities) {
        super(authorities);
        this.apiKey = apiKey;
        setAuthenticated(true);
    }

    @Override
    public Object getCredentials() {
        return apiKey;
    }

    @Override
    public Object getPrincipal() {
        return apiKey;
    }
}
```

---

### Step 2: Create a custom AuthenticationProvider

```java
@Component
public class ApiKeyAuthProvider implements AuthenticationProvider {

    @Override
    public Authentication authenticate(Authentication authentication)
            throws AuthenticationException {

        String apiKey = authentication.getCredentials().toString();

        // Validate your API key here (DB, config, etc)
        if (!"SECRET123".equals(apiKey)) {
            throw new BadCredentialsException("Invalid API Key");
        }

        List<GrantedAuthority> authorities =
                List.of(new SimpleGrantedAuthority("ROLE_API"));

        return new ApiKeyAuthToken(apiKey, authorities);
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return ApiKeyAuthToken.class.isAssignableFrom(authentication);
    }
}
```

---

### Step 3: Create a custom Authentication Filter

```java
public class ApiKeyFilter extends OncePerRequestFilter {

    private final AuthenticationManager authenticationManager;

    public ApiKeyFilter(AuthenticationManager authenticationManager) {
        this.authenticationManager = authenticationManager;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        String apiKey = request.getHeader("X-API-KEY");

        if (apiKey != null) {
            ApiKeyAuthToken authToken = new ApiKeyAuthToken(apiKey);

            Authentication authResult =
                    authenticationManager.authenticate(authToken);

            SecurityContextHolder.getContext().setAuthentication(authResult);
        }

        filterChain.doFilter(request, response);
    }
}
```

---

### Step 4: Register the filter and provider

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http,
                                       AuthenticationManager authManager,
                                       ApiKeyAuthProvider apiKeyAuthProvider)
        throws Exception {

    http.authenticationProvider(apiKeyAuthProvider);

    http.addFilterBefore(
            new ApiKeyFilter(authManager),
            UsernamePasswordAuthenticationFilter.class
    );

    http.authorizeHttpRequests(auth -> auth
            .anyRequest().authenticated()
    );

    return http.build();
}
```

---

# 5️⃣ Summary: Who Does What?

|Component|Responsibility|
|---|---|
|**Authentication Filter**|Extracts credentials, creates Authentication token|
|**AuthenticationManager**|Delegates to providers|
|**AuthenticationProvider**|Validates credentials and returns authenticated token|
|**SecurityContext**|Stores authenticated user for the request|

AuthenticationProvider = **the core validator**.  
AuthenticationManager = **the orchestrator**.  
Authentication Filter = **the entry point**.

---




###### Tags : [[1 - Spring Security 🍌]]