
### **1. `@EntityListeners`**

- **Purpose:** Tells JPA which **listener class** should react to entity lifecycle events (like create, update, delete).
    
- **Usage with auditing:** Spring Data JPA uses this to **hook into entity events** to set `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, and `@LastModifiedBy`.
    

**Example:**

```java
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Students {

    @Id
    @GeneratedValue
    private Long id;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
```

- **Explanation:**
    
    - `AuditingEntityListener` listens to **persist (insert) and update events**.
        
    - Automatically populates your auditing fields.
        
- **Without `@EntityListeners(AuditingEntityListener.class)`**, Spring won’t know to set the auditing fields.
    

---

### **2. `@EnableJpaAuditing`**

- **Purpose:** Globally **turns on Spring Data JPA auditing**.
    
- **Where:** Usually in a configuration class.
    

```java
@Configuration
@EnableJpaAuditing
public class JpaConfig { }
```

- **Explanation:**
    
    - Activates auditing support.
        
    - Works together with `@EntityListeners(AuditingEntityListener.class)` and `AuditorAware`.
        
    - Without this, annotations like `@CreatedDate` or `@LastModifiedBy` **won’t work**.
        

---

### **How They Work Together**

1. `@EnableJpaAuditing` → Tells Spring “enable auditing.”
    
2. `@EntityListeners(AuditingEntityListener.class)` → Attaches the listener to your entity.
    
3. `AuditingEntityListener` → Calls your `AuditorAware` and sets fields on entity lifecycle events.
    

✅ In short:

|Annotation / Class|Role|
|---|---|
|`@EnableJpaAuditing`|Enables auditing system in Spring globally|
|`@EntityListeners(AuditingEntityListener.class)`|Attaches auditing listener to an entity|
|`AuditingEntityListener`|Listens to JPA entity events and sets auditing fields|

---

@EntityListeners` **can take multiple classes**.

It’s defined like this:

```java
@EntityListeners({AuditingEntityListener.class, AnotherListener.class})
```

- You can attach **any number of listener classes** to a single entity.
    
- Each listener class can implement methods for JPA lifecycle events:
    

|Event|Method annotation in listener|
|---|---|
|Before insert|`@PrePersist`|
|After insert|`@PostPersist`|
|Before update|`@PreUpdate`|
|After update|`@PostUpdate`|
|Before delete|`@PreRemove`|
|After delete|`@PostRemove`|
|After load|`@PostLoad`|

**Example with multiple listeners:**

```java
@Entity
@EntityListeners({AuditingEntityListener.class, LoggingListener.class})
public class Students {
    @Id
    @GeneratedValue
    private Long id;

    @CreatedDate
    private LocalDateTime createdAt;
}
```

- `AuditingEntityListener` → handles `@CreatedDate` / `@LastModifiedDate`
    
- `LoggingListener` → maybe logs entity changes
    

So you’re **not limited to just one** — you can stack multiple listeners.

---
  `AuditingEntityListener` Class :

### **What it is**

- `AuditingEntityListener` is a **JPA entity listener provided by Spring Data**.
    
- It **automatically populates auditing fields** like `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, and `@LastModifiedBy` when an entity is persisted or updated.
    
- You don’t write this class yourself; Spring provides it.
    

---

### **How it works**

1. **Attach it to an entity** using `@EntityListeners`:
    

```java
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Students {
    @Id
    @GeneratedValue
    private Long id;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
```

2. **Listen to lifecycle events:**
    
    - `@PrePersist` → before insert
        
    - `@PreUpdate` → before update
        
3. **Automatically sets fields:**
    
    - If `@CreatedDate` → sets timestamp when entity is first saved
        
    - If `@LastModifiedDate` → updates timestamp whenever entity is updated
        
    - If `@CreatedBy` / `@LastModifiedBy` → sets user info from `AuditorAware`
        

---

### **Requirements**

- `@EnableJpaAuditing` must be **enabled** in a configuration class.
    
- An optional `AuditorAware` bean is required if you want `@CreatedBy` / `@LastModifiedBy` to work.
    

---

### **Why it’s useful**

- No need to manually set timestamps or user info for each entity.
    
- Works **transparently** for all entities where you attach it.
    
- Ensures **consistent auditing** across your application.
    

---

💡 **Flow example:**

1. Save a new `Students` entity.
    
2. `AuditingEntityListener` intercepts `@PrePersist`.
    
3. It sets `createdAt` and `createdBy` automatically.
    
4. On update, it intercepts `@PreUpdate` and sets `updatedAt` and `updatedBy`.
    

---

You **do NOT need to create a class named `AuditingEntityListener`** — it is **predefined internally by Spring Data JPA**.

- Spring provides it for you as part of the framework.
    
- You just reference it in your entity like this:
    

```java
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Students {
    @Id
    @GeneratedValue
    private Long id;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
```

- Spring handles all the logic internally: setting timestamps and calling your `AuditorAware` if needed.
    

✅ So you only **use it**, you don’t implement it.

---

###### what happens **under the hood** with `AuditingEntityListener` when you save or update an entity:


### **1. On Save (Insert)**

1. You call `save(entity)` on your repository.
    
2. JPA triggers the **`@PrePersist`** lifecycle event.
    
3. `AuditingEntityListener` intercepts this event.
    
4. It checks for auditing annotations on the entity:
    
    - `@CreatedDate` → sets the current timestamp.
        
    - `@CreatedBy` → fetches the current user from `AuditorAware` and sets it.
        
5. Entity is persisted with these fields populated automatically.
    

---

### **2. On Update**

1. You call `save(entity)` after modifying it.
    
2. JPA triggers the **`@PreUpdate`** lifecycle event.
    
3. `AuditingEntityListener` intercepts this event.
    
4. It checks for:
    
    - `@LastModifiedDate` → sets the current timestamp.
        
    - `@LastModifiedBy` → fetches the current user from `AuditorAware` and sets it.
        
5. Entity is updated with these fields automatically.
    

---

### **3. Key Components It Uses**

- **Entity lifecycle events** (`@PrePersist`, `@PreUpdate`)
    
- **Reflection** to find annotated fields (`@CreatedDate`, `@LastModifiedDate`, etc.)
    
- **`AuditorAware`** to get the current user for `@CreatedBy` / `@LastModifiedBy`
    

---

### **4. Important Notes**

- You don’t see this logic unless you dig into Spring Data JPA’s source.
    
- All happens **automatically**, so you don’t write any code for timestamps or user tracking.
    
- Works **per entity** that you attach via `@EntityListeners(AuditingEntityListener.class)`.
    

---

# Me : 

```java
package com.arcade.ketano.config;  
  
import org.springframework.lang.NonNull;  
import org.springframework.data.domain.AuditorAware;  
import org.springframework.security.authentication.AnonymousAuthenticationToken;  
import org.springframework.security.core.Authentication;  
import org.springframework.security.core.context.SecurityContextHolder;  
import org.springframework.stereotype.Component;  
  
import java.util.Optional;  
  
/**  
 * AuditorAware implementation for Spring Data JPA auditing. * <p>  
 * Provides the current auditor (user) for @CreatedBy and @LastModifiedBy fields.  
 * Integrates with Spring Security to automatically populate the username of * the authenticated user. Falls back to "SYSTEM" for unauthenticated or * anonymous users. * <p>  
 * This class is referenced by @EnableJpaAuditing(auditorAwareRef = "auditorAwareImpl")  
 * in the main application configuration. */  
@Component("auditorAwareImpl")  
// Registers this bean with Spring and gives it a specific name for JPA auditing reference  
public class AuditorAwareImpl implements AuditorAware<String> {  
  
    /**  
     * Returns the current auditor (the user performing the action) as a non-null Optional.     *     * @return Optional containing the current username, or "SYSTEM" if no authenticated user exists.  
     */  
    @Override  
    @NonNull    public Optional<String> getCurrentAuditor() {  
        // Retrieve the current Authentication object from Spring Security  
        Authentication authentication =  
                SecurityContextHolder.getContext().getAuthentication();  
  
        // Case 1: No authentication present or not authenticated  
        // This can happen for system jobs, anonymous users, or unauthenticated requests        if (authentication == null || !authentication.isAuthenticated()) {  
            return Optional.of("SYSTEM");  
        }  
        // Case 2: Authentication is an anonymous token (Spring Security default for anonymous users)  
        // This prevents storing "anonymousUser" as the auditor        if (authentication instanceof AnonymousAuthenticationToken) {  
            return Optional.of("SYSTEM");  
        }  
        // Case 3: Authenticated user  
        // Return the username of the currently logged-in user        return Optional.of(authentication.getName());  
    }}
```

##### Tags : [[0 - Spring Framework]]