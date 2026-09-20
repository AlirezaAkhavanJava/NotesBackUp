

### **`@AttributeOverride`**

- **Purpose:** Overrides the **column mapping for a single field** in an `@Embeddable` class when it’s embedded in an entity.
    
- **Used on:** An `@Embedded` field in an entity.
    
- **Contains:** The **name of the field** in the embeddable and the **new column mapping**.
    

---

### **Syntax**

```java
@AttributeOverride(
    name = "fieldNameInEmbeddable",  // field in @Embeddable
    column = @Column(name = "new_column_name")  // override column name
)
```

---

### **Example**

```java
@Embeddable
public class Address {
    private String street;
    private String city;
    private String zipCode;
}
```

```java
@Entity
public class Person {
    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @Embedded
    @AttributeOverride(
        name = "street", 
        column = @Column(name = "home_street")
    )
    private Address homeAddress;
}
```

- `homeAddress.street` → stored in column `home_street` instead of `street`.
    
- Other fields (`city`, `zipCode`) use default column names.
    

---

**TL;DR:**  
> `@AttributeOverride` = **rename a single column of an embedded object** in the entity table.




###### [[0 - Spring Framework]]