### What `@Embeddable` Does

- Marks a class whose **instances can be embedded** in another entity.
    
- Such a class **doesn’t have its own table**, but its fields are stored in the table of the entity that owns it.
    

### Example

```java
import jakarta.persistence.Embeddable;

@Embeddable
public class Address {
    private String street;
    private String city;
    private String zipCode;

    // getters, setters, constructors
}
```

```java
import jakarta.persistence.*;

@Entity
public class Person {
    @Id
    @GeneratedValue
    private Long id;

    private String name;

    @Embedded
    private Address address; // Embed Address fields into Person table
}
```

- `@Embedded` is used in the **entity** to include the `@Embeddable` class.
    
- The database table for `Person` will have columns like `street`, `city`, `zipCode`.
    

💡 **Key point:** `@Embeddable` classes **cannot have their own primary key**. They exist only as part of an entity.


###### [[0 - Spring Framework]]