
**@DiscriminatorValue** is a JPA annotation used **together with @DiscriminatorColumn** in inheritance scenarios (when using `SINGLE_TABLE` or `JOINED` inheritance strategies).

It specifies **the exact value** that will be stored in the **discriminator column** for instances of **that particular subclass**.

### Key Points

| Aspect                     | Description                                                                                   |
|----------------------------|-----------------------------------------------------------------------------------------------|
| **Used on**                | Concrete entity classes (subclasses) in an inheritance hierarchy                              |
| **Purpose**                | Tells JPA which value in the discriminator column corresponds to this entity type             |
| **Common values**          | String (most common), e.g., `"FULL_TIME"`, `"MANAGER"`, `"CONTRACTOR"`                        |
| **Required?**              | Yes, if the parent class has a `@DiscriminatorColumn`                                         |
| **Default behavior**       | If omitted, JPA uses the **fully qualified class name** as the discriminator value (not recommended) |

### Example (SINGLE_TABLE strategy)

```java
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "employee_type", discriminatorType = DiscriminatorType.STRING)
public abstract class Employee {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    // ...
}
```

```java
@Entity
@DiscriminatorValue("FULL_TIME")    // ← this value goes into the employee_type column
public class FullTimeEmployee extends Employee {
    private BigDecimal bonus;
    // ...
}
```

```java
@Entity
@DiscriminatorValue("PART_TIME")    // ← different value for this subclass
public class PartTimeEmployee extends Employee {
    private BigDecimal hourlyRate;
    // ...
}
```

### Resulting database table (simplified)

```sql
CREATE TABLE employee (
    id BIGINT PRIMARY KEY,
    name VARCHAR(255),
    employee_type VARCHAR(20),    ← discriminator column
    bonus DECIMAL(19,2),
    hourly_rate DECIMAL(19,2)
);
```

Sample data:

| id | name     | employee_type | bonus | hourly_rate |
|----|----------|---------------|-------|-------------|
| 1  | Alice    | **FULL_TIME** | 5000  | NULL        |
| 2  | Bob      | **PART_TIME** | NULL  | 25.00       |

### Alternative: Using class name as default (not recommended)

If you don't specify `@DiscriminatorValue`, JPA defaults to the **fully qualified class name**:

```java
@Entity
@DiscriminatorValue("com.example.FullTimeEmployee")  // ← ugly and long
public class FullTimeEmployee extends Employee {
    // ...
}
```

→ Avoid this! Always explicitly set short, meaningful values.

### Quick Comparison

| Annotation              | Where used                     | What it defines                              |
|-------------------------|--------------------------------|----------------------------------------------|
| `@DiscriminatorColumn`  | On the parent/abstract entity  | Defines **which column** stores the type     |
| `@DiscriminatorValue`   | On each concrete subclass      | Defines **what value** goes in that column   |

### Best Practices

- Use short, uppercase, meaningful values (e.g., `"FT"`, `"PT"`, `"MGR"`, `"CONTRACTOR"`)
- Use `STRING` discriminator type (default) for readability
- Be consistent with naming (e.g., all uppercase or all camelCase)

### Summary

| Purpose                                      | Annotation              | Example                              |
|----------------------------------------------|-------------------------|--------------------------------------|
| Define the column                            | `@DiscriminatorColumn`  | `name="employee_type"`               |
| Define the value for a specific subclass     | `@DiscriminatorValue`   | `"FULL_TIME"` or `"MGR"`             |



###### Tags : [[0 - Spring Framework]]