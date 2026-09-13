
**@DiscriminatorColumn** is a JPA annotation used in **inheritance scenarios** with the **SINGLE_TABLE** or **JOINED** inheritance strategy.

It tells JPA that you are using a **single table** (or joined tables) to store entities of different classes from an inheritance hierarchy, and it defines **which column** will be used to distinguish between the different entity types (subclasses).

### Key Points

| Aspect                     | Description                                                                                   |
|----------------------------|-----------------------------------------------------------------------------------------------|
| **Used with**              | `@Inheritance(strategy = InheritanceType.SINGLE_TABLE)` or `JOINED`                           |
| **Purpose**                | Specifies the column that holds the **type discriminator** (e.g., "EMPLOYEE", "MANAGER", "CONTRACTOR") |
| **Common attributes**      | `name` = column name in database<br>`discriminatorType` = STRING (default) or CHAR or INTEGER |
| **Default value**          | If not specified, Hibernate/JPA uses **DTYPE** as column name (for STRING type)               |

### Example: SINGLE_TABLE strategy (most common)

```java
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "employee_type", discriminatorType = DiscriminatorType.STRING)
public abstract class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private BigDecimal salary;
    // getters/setters
}
```

```java
@Entity
@DiscriminatorValue("FULL_TIME")
public class FullTimeEmployee extends Employee {
    private BigDecimal bonus;
    // ...
}
```

```java
@Entity
@DiscriminatorValue("PART_TIME")
public class PartTimeEmployee extends Employee {
    private BigDecimal hourlyRate;
    // ...
}
```

### Resulting database table

```sql
CREATE TABLE employee (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    salary DECIMAL(19,2),
    employee_type VARCHAR(20),       ← this is the discriminator column
    bonus DECIMAL(19,2),             ← only for FullTimeEmployee
    hourly_rate DECIMAL(19,2)        ← only for PartTimeEmployee
);
```

Sample data:

| id | name       | salary   | employee_type | bonus | hourly_rate |
|----|------------|----------|---------------|-------|-------------|
| 1  | Alice      | 60000    | FULL_TIME     | 5000  | NULL        |
| 2  | Bob        | 30000    | PART_TIME     | NULL  | 25.00       |

### Alternative: Using @DiscriminatorValue on subclasses

You can also specify the value directly on the subclass:

```java
@Entity
@DiscriminatorValue("MGR")
public class Manager extends Employee {
    private String department;
}
```

### Quick Summary Table

| Annotation                  | Purpose                                         | Example value                     |
|-----------------------------|-------------------------------------------------|-----------------------------------|
| `@DiscriminatorColumn`      | Defines the column name and type                | `name="employee_type"`            |
| `@DiscriminatorValue`       | Defines the value stored in that column for a specific subclass | `"FULL_TIME"`, `"MGR"`, `"1"`     |

### When to use

| Strategy             | Discriminator needed? | Typical use case                          |
|----------------------|-----------------------|-------------------------------------------|
| `SINGLE_TABLE`       | Yes                   | Most common – all subclasses in one table |
| `JOINED`             | Yes                   | Separate tables per subclass + discriminator |
| `TABLE_PER_CLASS`    | No                    | One table per concrete class – no discriminator |

### Best Practices

- Always name your discriminator column explicitly (e.g., `employee_type`, `person_type`, `account_type`) instead of relying on default `DTYPE`.
- Use `STRING` discriminator type in most cases — more readable in database.
- Keep discriminator values short and meaningful.

Let me know if you want examples for JOINED strategy or how to handle it with Spring Data JPA repositories!

###### Tags : [[0 - Spring Framework]]