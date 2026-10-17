
## 1️⃣ Definition

**`AuthenticationProvider`** is a core interface in Spring Security that **performs the actual authentication** of a user. While `UserDetailsService` just **loads user data**, the `AuthenticationProvider` **checks credentials and decides if authentication succeeds**.

Key points:

- Interface: `org.springframework.security.authentication.AuthenticationProvider`
    
- Method:
    
    ```java
    Authentication authenticate(Authentication authentication) throws AuthenticationException;
    boolean supports(Class<?> authentication);
    ```
    
- Spring Security allows multiple `AuthenticationProvider`s to exist; it iterates through them until one successfully authenticates.
    

---

## 2️⃣ Related Components

### a) **UserDetailsService**

- Often used in combination with `DaoAuthenticationProvider`.
    
- The provider calls `UserDetailsService.loadUserByUsername()` to fetch the user.
    

### b) **PasswordEncoder**

- Used by `DaoAuthenticationProvider` to verify passwords.
    
- The provider compares the submitted password with the stored encoded password from `UserDetails`.
    

### c) **AuthenticationManager**

- Delegates authentication to one or more `AuthenticationProvider`s.
    
- If no provider can authenticate, authentication fails.
    

### d) **Authentication**

- The input to `authenticate()` is an `Authentication` object (e.g., `UsernamePasswordAuthenticationToken`).
    
- After successful authentication, the provider returns a fully populated `Authentication` object with authorities.
    

---

## 3️⃣ Examples

### Example 1: Using `DaoAuthenticationProvider` (most common)

```java
@Bean
public DaoAuthenticationProvider authenticationProvider(UserDetailsService userDetailsService, PasswordEncoder passwordEncoder) {
    DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
    provider.setUserDetailsService(userDetailsService);
    provider.setPasswordEncoder(passwordEncoder);
    return provider;
}
```

**Explanation:**

- `DaoAuthenticationProvider` is a built-in provider.
    
- It uses your `UserDetailsService` to fetch user data.
    
- Uses `PasswordEncoder` to validate password.
    
- Spring Security calls `authenticate()` automatically during login.
    

---

### Example 2: Custom `AuthenticationProvider`

```java
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Component;

@Component
public class MyAuthenticationProvider implements AuthenticationProvider {

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String username = authentication.getName();
        String password = authentication.getCredentials().toString();

        // Custom logic: e.g., validate against DB or external service
        if ("user".equals(username) && "pass".equals(password)) {
            return new UsernamePasswordAuthenticationToken(username, password, List.of(() -> "ROLE_USER"));
        } else {
            return null; // Authentication failed
        }
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
```

**Explanation:**

- Custom provider can implement any logic for authentication.
    
- `supports()` tells Spring Security which `Authentication` types this provider can handle.
    
- Returns a fully populated `Authentication` object with roles upon success.
    

---

## 4️⃣ Methods of `AuthenticationProvider` (Step by Step)

1. **`authenticate(Authentication authentication)`**
    
    - Core method.
        
    - Input: `Authentication` object (username/password or token).
        
    - Returns: Authenticated `Authentication` object with authorities.
        
    - Throws: `AuthenticationException` if authentication fails.
        
2. **`supports(Class<?> authentication)`**
    
    - Determines if this provider can handle the given `Authentication` type.
        
    - Example: only supports `UsernamePasswordAuthenticationToken`.
        

---

## 5️⃣ Professional/Advanced Workflow

1. User submits login request → `UsernamePasswordAuthenticationFilter`.
    
2. Filter creates `UsernamePasswordAuthenticationToken` (credentials not yet authenticated).
    
3. `AuthenticationManager` iterates through its `AuthenticationProvider`s.
    
4. Each provider calls `authenticate()`.
    
    - For `DaoAuthenticationProvider`:
        
        - Calls `UserDetailsService.loadUserByUsername()`.
            
        - Uses `PasswordEncoder` to validate password.
            
    - For custom providers: runs your custom logic.
        
5. If a provider successfully authenticates, it returns an **authenticated** `Authentication` object.
    
6. SecurityContext is updated, granting access to resources.
    
7. If no provider authenticates, an exception is thrown, login fails.
    

Think of it this way:

- `UserDetailsService` = fetch user data (like a librarian fetching a book).
    
- `AuthenticationProvider` = judge if credentials are valid (like a security guard checking the book).
    
- Together, they form the authentication backbone of Spring Security.
    

---



##### Tags : [[1 - Spring Security 🍌]]