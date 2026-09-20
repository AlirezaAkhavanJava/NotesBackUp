## 1️⃣ Definition

**`UserDetailsService`** and **`UserDetails`** are core interfaces in **Spring Security** used for authentication. They work together to allow Spring Security to load user-specific data when someone tries to log in.

- **`UserDetailsService`**: This is a service interface with a single method, `loadUserByUsername(String username)`. Its job is to retrieve a `UserDetails` object based on a username (or any unique identifier). Spring Security calls this during the authentication process.
    
- **`UserDetails`**: This interface represents a user in Spring Security. It contains methods to get the username, password, roles (authorities), and account status (like enabled/locked/expired). Essentially, it’s a model of the authenticated user.
    

---

## 2️⃣ Related Components

### a) **AuthenticationManager**

- The `AuthenticationManager` in Spring Security is responsible for handling authentication requests.
    
- When a user tries to log in:
    
    1. The `AuthenticationManager` calls `UserDetailsService.loadUserByUsername()`.
        
    2. Spring Security gets a `UserDetails` object back.
        
    3. The password and roles from `UserDetails` are checked against the submitted credentials.
        

### b) **PasswordEncoder**

- Passwords are stored encoded (hashed). `UserDetails` provides the stored password.
    
- Spring Security uses `PasswordEncoder` to verify if the submitted password matches the stored one.
    

### c) **GrantedAuthority**

- `UserDetails.getAuthorities()` returns a list of `GrantedAuthority`. These represent roles or permissions (`ROLE_ADMIN`, `ROLE_USER`, etc.) and are used for authorization.
    

### d) **AuthenticationProvider**

- Often, `DaoAuthenticationProvider` is used. It leverages `UserDetailsService` to load users and `PasswordEncoder` to check credentials.
    

---

## 3️⃣ Examples

### Example 1: Custom UserDetails

```java
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;

public class MyUserDetails implements UserDetails {

    private String username;
    private String password;
    private Collection<? extends GrantedAuthority> authorities;
    private boolean active;

    public MyUserDetails(String username, String password, Collection<? extends GrantedAuthority> authorities, boolean active) {
        this.username = username;
        this.password = password;
        this.authorities = authorities;
        this.active = active;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return active;
    }
}
```

**Explanation:**

- We define our user model by implementing `UserDetails`.
    
- Spring Security will call the getter methods to check username, password, roles, and account status.
    
- You can add extra fields (like email, phone) but the core security-related fields are what Spring cares about.
    

---

### Example 2: Custom UserDetailsService

```java
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class MyUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    public MyUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
        return new MyUserDetails(
                user.getUsername(),
                user.getPassword(),
                user.getRoles(), // assuming roles are mapped as GrantedAuthority
                user.isActive()
        );
    }
}
```

**Explanation:**

- `loadUserByUsername` fetches the user from the database.
    
- Converts your entity (`User`) into a `UserDetails` object.
    
- Spring Security then uses this to authenticate.
    

---

## 4️⃣ Methods of `UserDetails` (Step by Step)

1. **`getUsername()`** → returns the username. Used during authentication.
    
2. **`getPassword()`** → returns the stored password (usually hashed). Used to compare with the input password.
    
3. **`getAuthorities()`** → returns a collection of roles or permissions for the user.
    
4. **`isAccountNonExpired()`** → checks if the account has expired.
    
5. **`isAccountNonLocked()`** → checks if the account is locked.
    
6. **`isCredentialsNonExpired()`** → checks if the credentials (password) are expired.
    
7. **`isEnabled()`** → checks if the account is active.
    

---

## 5️⃣ Professional/Advanced Workflow

Here’s how `UserDetailsService` and `UserDetails` fit into Spring Security's authentication process:

1. A user submits login form → Spring Security `UsernamePasswordAuthenticationFilter`.
    
2. Filter creates `UsernamePasswordAuthenticationToken`.
    
3. `AuthenticationManager` calls `DaoAuthenticationProvider`.
    
4. `DaoAuthenticationProvider` calls your `UserDetailsService.loadUserByUsername(username)`.
    
5. Your `UserDetailsService` loads user from DB and returns a `UserDetails`.
    
6. Password is checked via `PasswordEncoder`.
    
7. Authorities (roles) are assigned to the `Authentication` object.
    
8. User is authenticated; SecurityContext is updated.
    

Think of it as **`UserDetailsService` = fetcher** and **`UserDetails` = blueprint of the user**. Without either, authentication fails.

---


###### Tags : [[1 - Spring Security 🍌]]