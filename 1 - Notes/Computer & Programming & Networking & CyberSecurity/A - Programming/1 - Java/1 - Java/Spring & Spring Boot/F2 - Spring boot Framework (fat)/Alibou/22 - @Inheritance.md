
The **@Inheritance** annotation in **Spring Data JPA** (which builds on standard JPA from Jakarta Persistence) defines how a hierarchy of entity classes is mapped to database tables.

You apply it to the root (superclass) entity of an inheritance hierarchy, along with `@Entity`. It specifies the mapping strategy for the superclass and its subclasses.

### Key Details
- **Package**: `jakarta.persistence.Inheritance`
- **Usage**: Placed on the root entity class.
- **Default strategy**: If omitted, defaults to `InheritanceType.SINGLE_TABLE`.

### Supported Strategies (via `InheritanceType` enum)
1. **SINGLE_TABLE** (default)  
   All classes in the hierarchy map to a **single database table**.  
   A discriminator column (defined via `@DiscriminatorColumn`) distinguishes subclass types.  
   Best for simple hierarchies; supports polymorphic queries easily but can lead to many nullable columns.

2. **JOINED**  
   A **separate table** for the superclass and each subclass.  
   Subclass tables join to the superclass table via primary key.  
   Normalized schema; good for data integrity but requires joins for queries.

3. **TABLE_PER_CLASS**  
   Each concrete class gets its **own table** containing all inherited and local fields.  
   No shared table for the superclass.  
   Supports polymorphic queries less efficiently; optional in JPA (Hibernate supports it).

### Example
```java
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "vehicle_type")
public abstract class Vehicle {
    @Id
    private Long id;
    private String manufacturer;
    // ...
}

@Entity
@DiscriminatorValue("CAR")
public class Car extends Vehicle {
    private int seats;
    // ...
}

@Entity
@DiscriminatorValue("TRUCK")
public class Truck extends Vehicle {
    private double payload;
    // ...
}
```

### Related Annotations
- **@DiscriminatorColumn** and **@DiscriminatorValue** — Used with `SINGLE_TABLE` or `JOINED` to handle type discrimination.
- **Contrast with @MappedSuperclass** — `@MappedSuperclass` shares common fields/mappings without creating a true entity hierarchy in the database (no polymorphic queries, no discriminator). Use it for code reuse only (e.g., common audit fields like `createdDate`).

Spring Data JPA repositories work seamlessly with these hierarchies, allowing polymorphic queries on the root entity repository (e.g., finding all `Vehicle` instances returns `Car` and `Truck` as well).

##### Tags : [[0 - Spring Framework]]