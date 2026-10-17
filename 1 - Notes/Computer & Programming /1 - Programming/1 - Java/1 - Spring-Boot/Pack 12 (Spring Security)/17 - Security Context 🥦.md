
![[Pasted image 20251119121630.png]]


### 1️⃣ SecurityContext

- `SecurityContext` is a container that **holds the Authentication object** for the current user.
    
- Stored **per request** in `SecurityContextHolder`.
    
- Example:
    

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
String username = auth.getName(); // logged-in username
Collection<?> roles = auth.getAuthorities(); // roles/authorities
```

Think of it like your **user ID card** that all filters and controllers can check: “Who is this user? What can they do?”

![[Pasted image 20251203092425.png]]

---

### 2️⃣ Authentication Filter → SecurityContext Flow

1. **Request enters filter chain**
    
2. **Authentication Filter runs** (e.g., `UsernamePasswordAuthenticationFilter`)
    
    - Extracts credentials (username/password, token, etc.)
        
    - Delegates to `AuthenticationManager` → checks credentials via `UserDetailsService`
        
3. **If authentication succeeds**:
    
    - Creates an `Authentication` object
        
    - Stores it in `SecurityContext`:
        

```java
SecurityContextHolder.getContext().setAuthentication(auth);
```

4. **SecurityContext persists** through the request lifecycle (via `SecurityContextPersistenceFilter`)
    
5. **Controllers and services** can now check the user:
    

```java
if (SecurityContextHolder.getContext().getAuthentication().isAuthenticated()) {
    // user is authenticated
}
```

---

### 3️⃣ Important Notes

- **Unauthenticated users** → `SecurityContext` may contain an `AnonymousAuthenticationToken` (default for unauthenticated requests).
    
- **Thread-local storage**: `SecurityContextHolder` uses a `ThreadLocal` by default, so each request’s context is isolated.
    
- **After request** → `SecurityContextPersistenceFilter` clears it automatically.
    

---

### 4️⃣ Visual Flow (Simplified)

```
Incoming Request
      ↓
[Authentication Filter] ----> AuthenticationManager ---> UserDetailsService
      ↓
      ↓ (success)
SecurityContextHolder.setAuthentication(auth)
      ↓
Other filters / Controllers
      ↓
Response
      ↓
SecurityContextHolder cleared
```




###### Tags : [[1 - Spring Security 🍌]]