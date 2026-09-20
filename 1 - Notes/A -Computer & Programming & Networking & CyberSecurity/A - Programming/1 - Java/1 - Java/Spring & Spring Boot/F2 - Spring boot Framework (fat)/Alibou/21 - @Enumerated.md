

`@Enumerated` is a JPA annotation used to specify **how a Java `enum` should be persisted in a database**. By default, JPA stores enums as integers (ordinal), but you can also store them as strings.

### Syntax:

```java
@Enumerated(EnumType.STRING) // or EnumType.ORDINAL
private MyEnum myEnum;
```

### EnumType options:

1. **`ORDINAL` (default)**
    
    - Stores the **position of the enum constant** (0, 1, 2…).
        
    - Example:
        
        ```java
        enum Status { NEW, IN_PROGRESS, DONE }
        ```
        
        - `NEW` → 0
            
        - `IN_PROGRESS` → 1
            
        - `DONE` → 2
            
    - **Caution:** Changing the order of enum constants in the code can break the mapping.
        
2. **`STRING`**
    
    - Stores the **name of the enum constant** as a string.
        
    - Example:
        
        ```java
        Status.IN_PROGRESS → "IN_PROGRESS"
        ```
        
    - Safer than `ORDINAL` because reordering enum constants won’t break the database.
        

### Example:

```java
@Entity
public class Task {

    @Id
    @GeneratedValue
    private Long id;

    @Enumerated(EnumType.STRING)
    private Status status;

    // getters and setters
}
```

✅ **Tip:** Always prefer `EnumType.STRING` for production apps unless you have a very strong reason to save space with `ORDINAL`.


###### Tags : [[0 - Spring Framework]]