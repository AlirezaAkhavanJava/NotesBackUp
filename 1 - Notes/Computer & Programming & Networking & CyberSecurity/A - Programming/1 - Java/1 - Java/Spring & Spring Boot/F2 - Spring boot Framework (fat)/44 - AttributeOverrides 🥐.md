### **`@AttributeOverrides`**

- **Purpose:** Allows you to **override the column mapping** of multiple fields in an `@Embeddable` class when it’s embedded in an entity.
    
- **Used on:** The **entity field** that’s `@Embedded`.
    
- **Contains:** One or more `@AttributeOverride` annotations.
    

---

### **`@AttributeOverride`**

- Overrides **a single field’s column mapping**.
    
- Syntax:
    

```java
@AttributeOverride(
    name = "fieldNameInEmbeddable",
    column = @Column(name = "new_column_name")
)
```

---

### **Example**

```java
@Embedded
@AttributeOverrides({
    @AttributeOverride(name = "street", column = @Column(name = "home_street")),
    @AttributeOverride(name = "city", column = @Column(name = "home_city"))
})
private Address homeAddress;
```

- `street` → stored in column `home_street`
    
- `city` → stored in column `home_city`
    

Without `@AttributeOverrides`, Hibernate would just use the **field names** from `Address` as column names.

---

**TL;DR:**  
`@AttributeOverrides` = **“Hey Hibernate, don’t use the default column names for this embedded object, use these ones instead.”** 🐐

---

### 1. Recap: `@Embeddable` & `@Embedded`

- `@Embeddable` → marks a class that **can be embedded** in an entity. No separate table.
    
- `@Embedded` → used in an entity to **include the embeddable class**.
    

By default, the **fields of the embeddable class become columns** in the owning entity’s table.

---

### 2. Problem: Two embedded objects of the same type

If you embed the **same `@Embeddable` class twice**, Hibernate will try to create **columns with the same name** → conflict.

**Solution:** Use `@AttributeOverrides` to rename columns.

---

### 3. Example

#### Embeddable Class

```java
import jakarta.persistence.Embeddable;

@Embeddable
public class Address {
    private String street;
    private String city;
    private String zipCode;

    // Constructors, getters, setters
}
```

#### Entity Class with Two Addresses

```java
import jakarta.persistence.*;

@Entity
public class Person {
    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @Embedded
    @AttributeOverrides({
        @AttributeOverride(name = "street", column = @Column(name = "home_street")),
        @AttributeOverride(name = "city", column = @Column(name = "home_city")),
        @AttributeOverride(name = "zipCode", column = @Column(name = "home_zip"))
    })
    private Address homeAddress;

    @Embedded
    @AttributeOverrides({
        @AttributeOverride(name = "street", column = @Column(name = "work_street")),
        @AttributeOverride(name = "city", column = @Column(name = "work_city")),
        @AttributeOverride(name = "zipCode", column = @Column(name = "work_zip"))
    })
    private Address workAddress;
}
```

---

### 4. What happens in the database

The `Person` table will have columns:

|id|name|home_street|home_city|home_zip|work_street|work_city|work_zip|
|---|---|---|---|---|---|---|---|

- No separate table for `Address`.
    
- Each embedded object’s fields are **flattened into the entity table**.
    
- `@AttributeOverrides` lets you **customize the column names** to avoid conflicts.
    

---

### 5. How it works internally

1. Hibernate sees `@Embedded` → looks for `@Embeddable` class.
    
2. It **flattens the fields** of the embeddable into the entity table.
    
3. If `@AttributeOverrides` is present → **uses the overridden column names** instead of the default field names.
    
4. When saving a `Person`:
    
    - `homeAddress.street` → `home_street` column
        
    - `workAddress.city` → `work_city` column
        

It’s like a **struct inside a struct**, but in a SQL table. 🐐




###### [[0 - Spring Framework]]