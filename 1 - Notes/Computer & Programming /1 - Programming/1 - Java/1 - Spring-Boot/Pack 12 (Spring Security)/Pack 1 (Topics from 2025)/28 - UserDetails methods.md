

# ✅ **1. `getAuthorities()`**

### **What it is**

Returns the **roles/permissions** the user has.

### **Why it matters**

Spring Security uses these to decide what the user is allowed to access (`ROLE_ADMIN`, `ROLE_USER`, etc.).

### **Example**

```java
@Override
public Collection<? extends GrantedAuthority> getAuthorities() {
    return List.of(new SimpleGrantedAuthority("ROLE_USER"));
}
```

Right now yours returns `List.of()`, meaning **your user has zero permissions**.

---

# ✅ **2. `getPassword()`**

### **What it is**

Returns the **hashed** password.

### **Why it matters**

Spring Security compares this to the password stored in the DB (after encoding).

You did it correctly:

```java
return user.getPassword();
```

---

# ✅ **3. `getUsername()`**

### **What it is**

The field Spring Security uses to identify the user when logging in.

### **Why it matters**

This is the value from the login form.

Correct:

```java
return user.getUsername();
```

---

# Now the important ones people ignore 👇

## ⚠️ The remaining methods determine the _status_ of the account.

These control whether Spring Security rejects the login **EVEN if the username/password are correct**.

---

# ✅ **4. `isAccountNonExpired()`**

### **What it is**

Controls whether the **account has expired**.

### **If `false`:**

User CANNOT log in.

### **Use case**

- subscriptions
    
- trial accounts
    

### **You currently return**

```java
return UserDetails.super.isAccountNonExpired(); // always TRUE
```

So account is always considered non-expired.

---

# ✅ **5. `isAccountNonLocked()`**

### **What it is**

Tells Spring whether the account is **locked**.

### **If `false`:**

User cannot log in.

### **When used**

- Lock account after too many failed logins
    
- Admin disabled user temporarily
    

### **You currently return**

```java
return UserDetails.super.isAccountNonLocked(); // always TRUE
```

Good for now.

---

# ✅ **6. `isCredentialsNonExpired()`**

### **What it is**

Checks if the **password has expired**.

### **If `false`:**

Login fails — user must change password.

### **Used in**

Enterprises that force password reset every 90/180 days.

### **You return**

```java
return UserDetails.super.isCredentialsNonExpired(); // TRUE
```

Meaning password never expires.

---

# ✅ **7. `isEnabled()`**

### **What it is**

Determines if the account is **active or disabled**.

### **If `false`:**

Login is always blocked.

### **Used for**

- Email not verified yet
    
- Admin deactivated user
    
- Banned user
    

### **You return**

```java
return UserDetails.super.isEnabled(); // TRUE
```

---

# ⚠️ Conclusion (Direct + Honest)

Your class **fully works**, but:

### ✔️ User always:

- account not expired
    
- account not locked
    
- password not expired
    
- enabled
    

### ❌ User has **no authorities**, meaning they can't access any secured endpoint that checks roles.

If you want roles to work, you **must** fix `getAuthorities()`.

---



###### Tags : [[1 - Spring Security 🍌]]