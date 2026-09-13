
![[Pasted image 20251128100501.png]]

# 1️⃣ **Definition**

`ProviderManager` is the **default implementation of AuthenticationManager** in Spring Security.

When you call:

```java
authenticationManager.authenticate(authentication)
```

You are actually calling a **ProviderManager** behind the scenes.

**Its job**:  
Take an `Authentication` request → pass it through a list of `AuthenticationProvider`s → return a fully authenticated object.

Think of it as the **brain of authentication routing**.

---

# 2️⃣ **Related Components (That Work With ProviderManager)**

To fully understand ProviderManager, you must understand the components it orchestrates:

---

## **A. AuthenticationProvider**

Each provider knows how to authenticate **one specific type** of authentication.

Examples:

- `DaoAuthenticationProvider` → username/password via DB
    
- `JwtAuthenticationProvider` → JWT token
    
- `LdapAuthenticationProvider` → LDAP login
    
- Custom providers → your own logic
    

ProviderManager goes through these providers one by one.

---

## **B. AuthenticationManager Hierarchy**

ProviderManager itself can have:

- **Parent AuthenticationManager**
    
- **Child ProviderManagers**
    

This makes a tree-like structure.

Used for:

- Delegating between different security filter chains
    
- Reusing authentication logic across modules
    

---

## **C. UserDetailsService**

Used by `DaoAuthenticationProvider` inside ProviderManager’s provider list.

---

## **D. PasswordEncoder**

Used by Dao provider to check passwords.

---

## **E. SecurityFilterChain**

Filters like `UsernamePasswordAuthenticationFilter` or your custom JWT filter call:

```java
authenticationManager.authenticate(authentication);
```

This triggers ProviderManager.

---

# 3️⃣ **How ProviderManager Works (Real Workflow)**

### **Step 1 — It receives an Authentication object**

Example:

```java
new UsernamePasswordAuthenticationToken(username, password);
```

or

```java
new JwtAuthenticationToken(token);
```

---

### **Step 2 — It loops through its providers**

Inside ProviderManager:

```
for (AuthenticationProvider provider : providers) {
    if (provider.supports(authentication.getClass())) {
         return provider.authenticate(authentication);
    }
}
```

**supports()** determines if the provider can handle that authentication type.

---

### **Step 3 — First matching provider attempts authentication**

Example:

- Username/password → DaoAuthenticationProvider
    
- JWT → JwtAuthenticationProvider
    
- OAuth2 → OAuth2LoginAuthenticationProvider
    

Each provider:

1. Loads user data
    
2. Validates credentials/token
    
3. Returns a **fully authenticated Authentication object** or throws an exception
    

---

### **Step 4 — If no provider supports the class**

ProviderManager delegates to the **parent AuthenticationManager** (if exists).  
If no parent → throws:

```
ProviderNotFoundException
```

---

### **Step 5 — Details about “Erase Credentials”**

After successful authentication, ProviderManager **optionally clears password** from memory:

```java
eraseCredentialsAfterAuthentication = true
```

This is a security measure.

---

# 4️⃣ **Example ProviderManager in Action**

Imagine you configure 2 authentication providers:

```java
@Bean
public AuthenticationManager authenticationManager() {
    DaoAuthenticationProvider dao = new DaoAuthenticationProvider();
    dao.setUserDetailsService(userDetailsService);
    dao.setPasswordEncoder(passwordEncoder);

    JwtAuthenticationProvider jwtProvider = new JwtAuthenticationProvider(jwtService);

    return new ProviderManager(List.of(jwtProvider, dao));
}
```

### Now the flow is:

---

### **Case 1 → JWT Request**

- Authentication token type: `JwtAuthenticationToken`
    
- ProviderManager calls:
    

```
jwtProvider.supports(JwtAuthenticationToken.class) → true
```

So it uses jwtProvider.

---

### **Case 2 → Username/Password Request**

- Token type: `UsernamePasswordAuthenticationToken`
    
- ProviderManager checks providers:
    

```
jwtProvider.supports → false  
daoProvider.supports → true
```

So it uses daoProvider.

---

# 5️⃣ **Key ProviderManager Methods**

### **authenticate()**

Core method:

```java
public Authentication authenticate(Authentication authentication) throws AuthenticationException;
```

- Loops through providers
    
- Returns authenticated Authentication
    
- Or throws exception
    

---

### **setParent()**

Allows chaining AuthenticationManagers.

---

### **setEraseCredentialsAfterAuthentication()**

If true → removes credentials from memory.

---

# 6️⃣ **Internal Behavior (Deep Breadth You Want)**

### **A. Graceful fallback**

ProviderManager is designed to handle multiple credential systems at once.

For example:  
You can have login via username/password AND login via JWT, AND login via LDAP.

It chooses the **first provider that supports the token type**.

---

### **B. Hierarchical Manager**

Example:

```
Global AuthenticationManager
    ↓
Child ProviderManager (API Security)
    ↓
Child ProviderManager (Web Security)
```

Reason:

- API routes authenticate via JWT
    
- Form login routes authenticate via password
    
- Both share the same user store
    
- But different filters trigger different managers
    

This gives isolation between filter chains.

---

### **C. Stop on First Success**

ProviderManager **does not** authenticate with multiple providers.  
It stops as soon as one succeeds.

---

# 7️⃣ **Analogy — The Perfect Picture**

Think of ProviderManager as a **professor** handling student problems:

- Students come with different questions (JWT, password, OAuth2).
    
- Professor checks:  
    “Can I answer this type?”
    
- If yes → solves it.
    
- If not → sends to another professor.
    
- If no one can answer → reject the student.
    

It’s a dispatching system.

---

# 8️⃣ **Complete Workflow Diagram**

```
Authentication Request  
        ↓  
Security Filter  
        ↓  
AuthenticationManager (ProviderManager)
        ↓  
───────────────────────────────────────────────  
 For each AuthenticationProvider in order:
        ↓  
  provider.supports(authType)?  
    ↓ yes                     ↓ no  
provider.authenticate()   go to next provider
───────────────────────────────────────────────  
      ↓ success  
Authenticated Authentication  
        ↓  
SecurityContextHolder  
        ↓  
Request becomes authenticated
```

---

# 9️⃣ Summary — What You Should Remember

- ProviderManager **is** AuthenticationManager.
    
- It delegates to providers.
    
- Each provider authenticates a specific type of credentials.
    
- It stops at the first provider that supports the request.
    
- It can delegate to a parent AuthenticationManager.
    
- Underpins Spring Security’s flexible authentication system.
    




##### Tags : [[1 - Spring Security 🍌]]