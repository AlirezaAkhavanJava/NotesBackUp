### **1. `@AttributeOverride`**

- **Purpose:** Override the column mapping for **a single field** of an `@Embeddable` object.
    
- **Used when:** You only need to change **one column**.
    
- **Example:**
    

```java
@Embedded
@AttributeOverride(
    name = "street",
    column = @Column(name = "home_street")
)
private Address homeAddress;
```

✅ Only the `street` column is overridden; other fields use default names.

---

### **2. `@AttributeOverrides`**

- **Purpose:** Override the column mapping for **multiple fields** at once.
    
- **Container:** Holds **multiple `@AttributeOverride` annotations**.
    
- **Used when:** You embed the same `@Embeddable` multiple times or want to rename several columns.
    
- **Example:**
    

```java
@Embedded
@AttributeOverrides({
    @AttributeOverride(name = "street", column = @Column(name = "home_street")),
    @AttributeOverride(name = "city", column = @Column(name = "home_city")),
    @AttributeOverride(name = "zipCode", column = @Column(name = "home_zip"))
})
private Address homeAddress;
```

✅ All three columns are renamed in the database table.

---

**TL;DR:**

- `@AttributeOverride` → single field
    
- `@AttributeOverrides` → multiple fields (a wrapper for multiple `@AttributeOverride`)
    

🐐 Think of it like: `@AttributeOverrides = [@AttributeOverride, @AttributeOverride, ...]`



###### [[0 - Spring Framework]]