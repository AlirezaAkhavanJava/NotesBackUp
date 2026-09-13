### **1. What is `@Proxy`?**

- `@Proxy` is a **Hibernate-specific annotation** (not standard JPA).
    
- It controls **lazy-loading behavior** for an entity.
    
- Lazy-loading means Hibernate will **not immediately fetch the entity from the database**; instead, it creates a **proxy object** that fetches data only when you access it.
    
> 'org.hibernate.annotations.Proxy' is deprecated since version 6.2 
---

### **2. Basic usage**

```java
@Entity
@Proxy(lazy = true)
public class Course {
    @Id
    private Long courseId;
    private String title;
}
```

- `lazy = true` → Hibernate will create a proxy object instead of loading the full entity immediately.
    
- `lazy = false` → Hibernate fetches the full entity immediately (no proxy).
    

---

### **3. Why it matters**

- Helps **performance** by avoiding unnecessary SQL queries.
    
- Especially useful for **large objects or relationships** (like `@OneToMany`, `@OneToOne`).
    
- Works with **associations**: Hibernate can return a proxy to the related entity without hitting the DB until needed.
    

---

### **4. Advanced / senior usage**

- **Lazy-loading and proxies can break `equals()`/`hashCode()`** if they access uninitialized fields.
    
- **Avoid `final` classes**: Hibernate proxies cannot extend `final` classes.
    
- Can combine with `@BatchSize` to optimize queries when loading multiple proxies.
    

---

### **5. Example with your entities**

```java
@Entity
@Proxy(lazy = true) // lazy proxy
public class Course {
    @Id
    private Long courseId;
    private String title;
}

@Entity
public class CourseMaterial {
    @Id
    private Long courseMaterialId;

    @OneToOne
    @JoinColumn(name = "course_id")
    private Course course; // will be lazily loaded via proxy
}
```

- When you load `CourseMaterial`, Hibernate **does not fetch the Course immediately**.
    
- Only when you call `material.getCourse().getTitle()`, Hibernate issues a SQL query to fetch `Course`.
    

---

💡 **Senior tip:**

- `@Proxy(lazy = false)` is sometimes used for **small, frequently accessed entities** to avoid the overhead of proxies.
    
- Lazy proxies + JSON serialization can throw exceptions (like `LazyInitializationException`) if the session is closed. You must manage sessions carefully.
    

---



##### Tags : [[0 - Spring Framework]]