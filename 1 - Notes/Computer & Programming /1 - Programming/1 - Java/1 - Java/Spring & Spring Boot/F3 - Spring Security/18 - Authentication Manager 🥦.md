![[Pasted image 20251119121851.png]]



## 1️⃣ What AuthenticationManager Is

`AuthenticationManager` is the **central authentication engine** of Spring Security.

Its job:

- Receive an `Authentication` object (usually created by an Authentication Filter)
    
- Validate credentials using one or more **AuthenticationProviders**
    
- Return a **fully authenticated Authentication object** on success
    
- Throw an **AuthenticationException** on failure
    

It is the _core decision-maker_ for authentication.

Signature:

```java
Authentication authenticate(Authentication authentication) throws AuthenticationException;
```

---

## 2️⃣ Where AuthenticationManager Lives in the Flow

### Request → Authentication Filter → AuthenticationManager → SecurityContext

Detailed chain:

1. **Authentication Filter** extracts credentials  
    Example: username & password from a login form
    
2. Filter creates an `Authentication` token (not authenticated yet)  
    e.g.:
    
    ```java
    new UsernamePasswordAuthenticationToken(username, password)
    ```
    
3. Filter calls:
    
    ```java
    authenticationManager.authenticate(authToken)
    ```
    
4. `AuthenticationManager` delegates to **AuthenticationProviders**
    
5. If a provider can authenticate the token:
    
    - It returns an authenticated `Authentication` with roles/authorities
        
6. The filter stores this result in:
    
    ```java
    SecurityContextHolder.getContext().setAuthentication(authenticatedUser)
    ```
    

---

## 3️⃣ AuthenticationManager and AuthenticationProvider

`AuthenticationManager` is just an interface.

The real work is done by **AuthenticationProviders**:

Examples:

- `DaoAuthenticationProvider` → handles username/password via UserDetailsService
    
- `JwtAuthenticationProvider`
    
- `LdapAuthenticationProvider`
    

The default implementation, `ProviderManager`, holds a list of providers.

Flow:

```
AuthenticationManager
    ↓ delegates
AuthenticationProvider #1  (supports? → maybe)
AuthenticationProvider #2  (supports? → no)
AuthenticationProvider #3  (supports? → yes → authenticate)
```

Each provider declares what token types it supports:

```java
public boolean supports(Class<?> authentication)
```

---

## 4️⃣ Default Setup (Typical Spring Boot App)

If you configure `UserDetailsService` and `PasswordEncoder`, Spring creates:

- `DaoAuthenticationProvider`
    
- `ProviderManager` (AuthenticationManager)
    
- `UsernamePasswordAuthenticationFilter` wired to use it
    

Example:

```java
@Bean
public AuthenticationManager authenticationManager(
        AuthenticationConfiguration config) throws Exception {
    return config.getAuthenticationManager();
}
```

---

## 5️⃣ When You Create Custom Authentication

If you build custom authentication (JWT, API Key, etc.):

1. Create your own `AuthenticationToken`
    
2. Create a custom `AuthenticationProvider`
    
3. Register the provider with the AuthenticationManager
    
4. Add a custom filter that calls `authenticationManager.authenticate()`
    

---

## 6️⃣ Summary

|Component|Responsibility|
|---|---|
|**Authentication Filter**|Extracts credentials and initiates authentication|
|**AuthenticationManager**|Delegates authentication tasks|
|**AuthenticationProvider**|Performs actual validation|
|**SecurityContext**|Stores the authenticated result|

The AuthenticationManager is essentially the **boss** that coordinates authentication but _does not_ perform checks itself; it delegates to providers.


###### Tags : [[1 - Spring Security 🍌]]