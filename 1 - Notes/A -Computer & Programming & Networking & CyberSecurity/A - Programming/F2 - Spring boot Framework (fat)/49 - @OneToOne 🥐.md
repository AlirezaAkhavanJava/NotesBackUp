

### **1. `@OneToOne`**

- **Purpose:** Defines a one-to-one relationship between two entities.
    
- **Example:** Each `Student` has one `Passport`, and each `Passport` belongs to one `Student`.
    

```java
@Entity
public class Student {
    @Id
    private Long id;

    @OneToOne
    private Passport passport;  // One student → One passport
}
```

- **Default behavior:** JPA will create a foreign key column in the `Student` table pointing to `Passport`.
    

---

### **2. `@JoinColumn`**

- **Purpose:** Specifies the column that will act as the foreign key for the relationship.
    
- **Why use it:** Controls the column name instead of letting JPA generate it automatically.
    

```java
@Entity
public class Student {
    @Id
    private Long id;

    @OneToOne
    @JoinColumn(name = "passport_id")  // custom column name for foreign key
    private Passport passport;
}
```

- This will create a `passport_id` column in the `Student` table referencing `Passport.id`.
    

---

### **3. Combined Example**

```java
@Entity
public class Student {
    @Id
    private Long id;
    private String name;

    @OneToOne
    @JoinColumn(name = "passport_id")
    private Passport passport;
}

@Entity
public class Passport {
    @Id
    private Long id;
    private String number;
}
```

- Now, `Student` has a `passport_id` column linking to `Passport`.
    

---

💡 **Notes:**

- Without `@JoinColumn`, JPA creates a default column like `passport_id`.
    
- `mappedBy` is used on the inverse side to indicate the owner of the relationship.
    

---


###### [[0 - Spring Framework]] [[20 - Relationship annotations]]