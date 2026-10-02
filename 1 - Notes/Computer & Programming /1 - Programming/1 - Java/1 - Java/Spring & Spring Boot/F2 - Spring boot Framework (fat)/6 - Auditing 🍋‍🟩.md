
In the context of Spring (and databases), **auditing** is about **automatically tracking changes** to your entities, like who created them, when, and who last modified them. 
It’s very useful for accountability, debugging, and history tracking.

---

### **Key Concepts**

1. **Created Date / Modified Date**
    
    - Automatically store timestamps when an entity is created or updated.
        
2. **Created By / Modified By**
    
    - Automatically store **who** created or updated the entity.
        

---

### **Spring Data JPA Auditing**

1. **Enable Auditing** in your configuration:
    

```java
@Configuration
@EnableJpaAuditing
public class JpaConfig { }
```

2. **Add auditing fields to your entity:**
    

```java
@Entity
public class Students {

    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    @CreatedBy
    private String createdBy;

    @LastModifiedBy
    private String updatedBy;
}
```

3. **Enable an auditor** (who did the change):
    

```java
@Component
public class AuditorAwareImpl implements AuditorAware<String> {

    @Override
    public Optional<String> getCurrentAuditor() {
        // Return the currently logged-in user
        return Optional.of("SYSTEM"); // replace with real user in production
    }
}
```

---

### **What happens**

- When you save a new entity → `createdAt` and `createdBy` are automatically set.
    
- When you update an entity → `updatedAt` and `updatedBy` are automatically updated.
    

---

✅ **Benefits:**

- No manual tracking required
    
- Useful for logs, audits, and debugging
    
- Essential in production for accountability
    

---

### **1. @CreatedDate**

- **Purpose:** Automatically stores the **date and time when the entity was first created**.
    
- **Type:** Works with `LocalDateTime`, `Date`, or `Instant`.
    
- **Example:**
    

```java
@CreatedDate
private LocalDateTime createdAt;
```

- **Behavior:** Spring sets this field **automatically when you save a new entity**.
    

---

### **2. @LastModifiedDate**

- **Purpose:** Automatically stores the **date and time when the entity was last updated**.
    
- **Type:** Works with `LocalDateTime`, `Date`, or `Instant`.
    
- **Example:**
    

```java
@LastModifiedDate
private LocalDateTime updatedAt;
```

- **Behavior:** Spring updates this field **every time the entity is saved/updated**.
    

---

### **3. @CreatedBy**

- **Purpose:** Automatically stores **who created the entity**.
    
- **Type:** Usually `String` (username) or `Long` (user ID).
    
- **Example:**
    

```java
@CreatedBy
private String createdBy;
```

- **Behavior:** Set automatically using an `AuditorAware` implementation.
    

---

### **4. @LastModifiedBy**

- **Purpose:** Automatically stores **who last modified the entity**.
    
- **Type:** Usually `String` (username) or `Long` (user ID).
    
- **Example:**
    

```java
@LastModifiedBy
private String updatedBy;
```

- **Behavior:** Updated automatically whenever the entity is modified.
    

---

### **5. @EnableJpaAuditing**

- **Purpose:** Enables Spring Data JPA auditing globally.
    
- **Where:** Usually in a configuration class.
    
- **Example:**
    

```java
@Configuration
@EnableJpaAuditing
public class JpaConfig { }
```

- **Behavior:** Required for `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy` to work.
    

---

### **6. AuditorAware interface**

- **Purpose:** Defines **how to fetch the current user** for `@CreatedBy` and `@LastModifiedBy`.
    
- **Example:**
    

```java
@Component
public class AuditorAwareImpl implements AuditorAware<String> {
    @Override
    public Optional<String> getCurrentAuditor() {
        // Return currently logged-in user
        return Optional.of("SYSTEM");
    }
}
```

---

💡 **Summary Table**

|Annotation|Tracks|Auto-updated when|Notes|
|---|---|---|---|
|`@CreatedDate`|Creation timestamp|New entity|Use `LocalDateTime` or `Date`|
|`@LastModifiedDate`|Last update timestamp|Every update||
|`@CreatedBy`|Creator (user)|New entity|Needs `AuditorAware`|
|`@LastModifiedBy`|Last modifier (user)|Every update|Needs `AuditorAware`|
|`@EnableJpaAuditing`|Enables auditing globally|N/A|Must be in a `@Configuration` class|

---



##### Tags : [[0 - Spring Framework]]