
In **Spring Data JPA**, **auditing** is a feature that automatically tracks and records metadata about entity changes, like **who created or modified an entity and when**. Think of it as a built-in diary for your database rows. 🐐

---

### **Key Features**

1. **Created date** – When the entity was first persisted.
    
2. **Last modified date** – When the entity was last updated.
    
3. **Created by** – Who created the entity.
    
4. **Last modified by** – Who updated it last.
    

This is extremely useful for logging, tracking, or compliance purposes.

---

### **How to Enable Auditing**

1. Add the annotation on your **main application class** or configuration:
    

```java
@EnableJpaAuditing
@SpringBootApplication
public class WanderArcadeApplication {
    public static void main(String[] args) {
        SpringApplication.run(WanderArcadeApplication.class, args);
    }
}
```

2. Add auditing fields in your entity:
    

```java
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Column;
import java.time.LocalDateTime;

@Entity
public class TravelPackage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    // getters & setters
}
```

3. Optionally, you can track **who** made the changes using `@CreatedBy` and `@LastModifiedBy` (requires implementing an `AuditorAware` bean).
    

---

### **What happens automatically**

- When you save a new entity, `createdAt` is set automatically.
    
- When you update the entity, `updatedAt` is updated automatically.
    
- No need to manually set timestamps in your code.
    

---

 Here’s how you track **who and when** changes happen in Spring Data JPA.



### **1. Enable JPA Auditing**

In your main application class:

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing(auditorAwareRef = "auditorProvider")
public class WanderArcadeApplication {
    public static void main(String[] args) {
        SpringApplication.run(WanderArcadeApplication.class, args);
    }
}
```

> `auditorAwareRef` points to the bean that will provide the current user.

---

### **2. Implement `AuditorAware`**

This tells Spring Data who the current user is:

```java
import org.springframework.context.annotation.Bean;
import org.springframework.data.domain.AuditorAware;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class AuditorConfig {

    @Bean
    public AuditorAware<String> auditorProvider() {
        // In real apps, get user from SecurityContext (e.g., Spring Security)
        return () -> Optional.of("ethan"); // hardcoded for demo
    }
}
```

> Replace `"ethan"` with the logged-in username in a real app.

---

### **3. Add Auditing Fields to Your Entity**

```java
import jakarta.persistence.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@EntityListeners(AuditingEntityListener.class)
public class TravelPackage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @CreatedBy
    @Column(updatable = false)
    private String createdBy;

    @LastModifiedBy
    private String lastModifiedBy;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    // getters & setters
}
```

---

### **4. How It Works**

- On `save()`:
    
    - `createdAt` & `createdBy` are set.
        
- On `update()`:
    
    - `updatedAt` & `lastModifiedBy` are updated automatically.
        
- No manual intervention required.
    

---

💡 **Pro tip:** In a real application, you would get the current user from **Spring Security** like this:

```java
return Optional.ofNullable(SecurityContextHolder.getContext().getAuthentication().getName());
```



##### [[0 - Spring Framework]]