
In JPA, the `@Entity` annotation tells Hibernate (or another JPA provider) that a class represents a **database table**.

`@GeneratedValue` is used in JPA to tell the persistence provider **how to automatically generate the value of a primary key** (`@Id`) when a new entity is saved.

![[GeneratedValue (1) 2.png]]

### Strategies:

1. **`AUTO`**
    

- Default strategy.
    
- JPA picks the best generation strategy based on the database.
    
- Example: might use sequences for Oracle, identity for MySQL.
    

2. **`IDENTITY`**
    

- Database generates the ID automatically (like `AUTO_INCREMENT` in MySQL).
    
- JPA relies on the database to assign the primary key when inserting.
    

3. **`SEQUENCE`**
    

- Uses a **database sequence** object to generate IDs.
    
- Mostly used in Oracle, PostgreSQL.
    
- Example:
    

```Java
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "student_seq")
@SequenceGenerator(name = "student_seq", sequenceName = "student_sequence", allocationSize = 1)
private Long id;

```

4. **`TABLE`**
    

- Uses a separate table to generate IDs.
    
- Rarely used today, slower than other strategies.
    

✅ Key points:

- `@GeneratedValue` **only works with `@Id`** fields.
    
- Lets you **avoid manually assigning IDs**.
    
- Strategy choice depends on the database and your preference for performance/portability.

![[GenerationType.png]]

---



`@SequenceGenerator` is used in JPA when you want to **use a database sequence to generate primary key values**. It works together with `@GeneratedValue(strategy = GenerationType.SEQUENCE)`.

![[SequenceGenerator.png]]


```java
@Entity
public class Students {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "student_seq")
    @SequenceGenerator(
	    name = "student_seq",
        sequenceName = "student_sequence",
        allocationSize = 1)
    private Long id;

    private String name;
}

```


### Explanation:

1. **`name`** → the name of the sequence generator you reference in `@GeneratedValue`.
    
2. **`sequenceName`** → the name of the database sequence object. JPA will use this to get the next value.
    
3. **`allocationSize`** → performance optimization; JPA prefetches this many sequence values in memory to reduce DB calls. Usually 1 if you want sequential IDs.
    

 Key points:

- Only works with `GenerationType.SEQUENCE`.
    
- Useful in databases like **Oracle, PostgreSQL** that support sequences.
    
- Gives more control over ID generation than `IDENTITY`.

##### Tags : [[0 - Spring Framework]]