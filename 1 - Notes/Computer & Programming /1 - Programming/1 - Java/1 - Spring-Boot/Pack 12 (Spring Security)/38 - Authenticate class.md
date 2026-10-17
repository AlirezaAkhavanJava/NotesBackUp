

# 1️⃣ **Definition**

`Authentication` is a **core Spring Security interface** that represents:

### ✔️ A user’s identity

### ✔️ Their credentials

### ✔️ Their permissions (authorities)

### ✔️ Whether they are authenticated or not

It is **not a class** — it's an **interface**, and Spring uses many implementations of it.

In simple terms:  
**Authentication = the “security passport” of the user inside Spring Security.**

---

# 2️⃣ **Related Components (Directly Interacting With It)**

To know Authentication fully, you must understand the classes that use it:

---

## **A. AuthenticationManager**

- Accepts an Authentication object (usually containing username/password).
    
- Returns a _fully authenticated_ Authentication object.
    
- Or throws an exception.
    

Authentication is the **input** and **output** of AuthenticationManager.

---

## **B. AuthenticationProvider**

- Validates the Authentication object.
    
- Creates the **authenticated** version of it:
    
    - adds UserDetails
        
    - adds roles
        
    - sets `authenticated = true`
        

---

## **C. SecurityContext / SecurityContextHolder**

After successful authentication, Authentication is stored here:

```
SecurityContextHolder.getContext().setAuthentication(authenticatedToken);
```

This makes the user authenticated throughout the request.

---

## **D. UserDetails**

The authenticated Authentication object usually contains a UserDetails instance in its `principal` field.

---

## **E. Security Filters**

Filters such as:

- UsernamePasswordAuthenticationFilter
    
- JwtAuthenticationFilter
    
- AnonymousAuthenticationFilter
    

All **create**, **modify**, or **read** Authentication.

---

# 3️⃣ **Implementations of Authentication (Very Important)**

There is no single Authentication class — only implementations:

### **1. UsernamePasswordAuthenticationToken**

Used for login with username/password.

Before authentication:

```
principal = username
credentials = password
authenticated = false
```

After authentication:

```
principal = UserDetails
credentials = null (cleared)
authorities = ROLE_USER, ROLE_ADMIN...
authenticated = true
```

---

### **2. JwtAuthenticationToken**

Used when JWT tokens are validated.

---

### **3. AnonymousAuthenticationToken**

Spring uses this when user is NOT logged in.

---

### **4. OAuth2AuthenticationToken**

For OAuth2 logins (Google, GitHub, etc.)

---

### **5. PreAuthenticatedAuthenticationToken**

Used when authentication is handled externally (reverse proxy, SSO, etc.)

---

# 4️⃣ **Fields of Authentication (Teach Deeply)**

Authentication interface has these key methods:

---

### **A. Object getPrincipal()**

Represents the user.

Before authentication:

- Usually a String username
    

After authentication:

- A UserDetails object  
    **This contains: username, password (encoded), roles, flags (enabled, locked, etc.)**
    

---

### **B. Object getCredentials()**

The sensitive data used for login.

Before authentication: plain password  
After authentication: usually **null**

---

### C. Collection

`C. Collection<? extends GrantedAuthority> getAuthorities()`

User’s roles and permissions.

Example:

```
ROLE_USER
ROLE_ADMIN
read:users
write:users
```

---

### **D. boolean isAuthenticated()**

Tells if authentication is complete.

Before:

```
false
```

After:

```
true
```

---

### **E. Object getDetails()**

Extra information, like:

- IP address
    
- Session ID
    
- JWT claims
    
- Login method
    

Depends on the filter that populated it.

---

### **F. String getName()**

Usually the username.

---

# 5️⃣ **Example Usage (Professional Explanation)**

### 📌 _Before authentication_ (inside login filter):

```java
Authentication authRequest =
    new UsernamePasswordAuthenticationToken("ethan", "password123");
```

Fields:

```
principal = "ethan"
credentials = "password123"
authenticated = false
authorities = null
```

---

### 📌 _After authentication_ (inside AuthenticationProvider):

```java
Authentication authResult =
    new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
```

Fields:

```
principal = UserDetails object
credentials = null
authenticated = true
authorities = [ROLE_USER, ROLE_ADMIN]
```

---

### 📌 _Saved to SecurityContext:_

```java
SecurityContextHolder.getContext().setAuthentication(authResult);
```

Now any code anywhere can do:

```java
Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
String username = authentication.getName();
```

---

# 6️⃣ **Real Workflow (Advanced “Oxford” Explanation)**

Let’s trace Authentication through the entire Spring Security pipeline:

---

### **Step 1 — Filter Creates Authentication Object**

UsernamePasswordAuthenticationFilter:

```
UsernamePasswordAuthenticationToken(username, password)
(authenticated = false)
```

---

### **Step 2 — AuthenticationManager authenticates**

```
ProviderManager.authenticate(token)
```

---

### **Step 3 — Provider authenticates**

DaoAuthenticationProvider:

- Loads user using UserDetailsService
    
- Checks password using PasswordEncoder
    
- Creates new authenticated token
    

---

### **Step 4 — Authentication stored in SecurityContext**

```
SecurityContextHolder.getContext().setAuthentication(authenticatedToken);
```

---

### **Step 5 — Authorization uses Authentication.getAuthorities()**

Checks:

- roles
    
- permissions
    

---

### **Step 6 — Filters read Authentication each request**

JWT filters recreate Authentication object from incoming JWT.

---

# 7️⃣ **How Authentication is Used in JWT Workflow**

Very important:

### 🔵 Login:

User sends credentials → AuthenticationManager → authenticated Authentication → JWT returned.

### 🔵 Next requests:

JWT filter extracts token → validates → builds new Authentication → puts in SecurityContext.

Here Authentication represents **JWT identity**, not username/password.

---

# 8️⃣ Summary — What You Must Remember

**Authentication is the identity of the user during the entire request lifecycle.**  
It goes through phases:

1. **Before authentication**
    
    - credentials in it
        
    - no authorities
        
    - not authenticated
        
2. **After authentication**
    
    - principal becomes UserDetails
        
    - credentials cleared
        
    - authorities added
        
    - authenticated = true
        
3. **Stored in SecurityContext**
    
    - used for authorization
        
    - used in controllers with `@AuthenticationPrincipal`
        

---




##### Tags : [[1 - Spring Security 🍌]]