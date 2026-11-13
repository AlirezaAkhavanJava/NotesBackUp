

**What this lesson covers:** `@SequenceGenerator` is a JPA annotation that tells Hibernate how to create the primary key values for your entities by using a database sequence, which is a server-side counter that hands out unique numbers. Instead of letting the database assign IDs one row at a time, you configure a named generator, link it to your ID field, and control how the numbers are produced and how often the database is contacted. Below we'll cover the dependencies, the annotations that work together with it, each parameter with a practical explanation, the SQL that gets generated, and the mistakes beginners commonly make.

## Step 1: The dependencies

You need Spring Boot's JPA starter, which brings in Hibernate (the JPA implementation) and the Jakarta Persistence API that defines the annotation.

```xml
<dependencies>
    <!-- Brings in Spring Data JPA, Hibernate, and jakarta.persistence -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <!-- PostgreSQL JDBC driver: the code that lets Java talk to PostgreSQL -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
</dependencies>
```

`spring-boot-starter-data-jpa` is what makes `@SequenceGenerator` available, because the annotation lives in `jakarta.persistence`. The PostgreSQL driver is marked `runtime` because your code never calls it directly; it's only needed when the app actually runs. On Debian 13 you can install PostgreSQL with `sudo apt install postgresql`.

One important note: sequences are supported by PostgreSQL, Oracle, SQL Server, and MariaDB 10.3+, but **not** by MySQL 8, which only offers `AUTO_INCREMENT`. If you use MySQL, this annotation won't work the way you expect.

## Step 2: The annotations that work together

`@SequenceGenerator` by itself does nothing. It only defines a generator. You then point a field at it using `@Id` and `@GeneratedValue`:

- `@Id` marks the primary key field.
- `@GeneratedValue` tells JPA that the value should be generated automatically. Its `strategy` says how (here, `SEQUENCE`) and its `generator` says which named generator to use.
- `@SequenceGenerator` defines that named generator and its settings.

The `name` in `@SequenceGenerator` must match the `generator` in `@GeneratedValue`. This link is the most important concept in this lesson.

## Step 3: A complete example

```java
import jakarta.persistence.*;

@Entity
@Table(name = "customers")
public class Customer {

    @Id
    @GeneratedValue(
            strategy = GenerationType.SEQUENCE,   // Use a database sequence to create IDs
            generator = "customer_seq_gen"        // Use the generator named below
    )
    @SequenceGenerator(
            name = "customer_seq_gen",            // Name other annotations refer to
            sequenceName = "customer_seq",        // Real sequence name in the database
            allocationSize = 50,                  // IDs fetched per database round trip
            initialValue = 1                      // First value the sequence starts at
    )
    private Long id;

    private String name;

    protected Customer() {}                       // JPA requires a no-argument constructor

    public Customer(String name) {
        this.name = name;
    }

    public Long getId() { return id; }
    public String getName() { return name; }
}
```

Let's walk through what each piece does:

- `@Entity` tells JPA this class maps to a database table.
- `@Table(name = "customers")` sets the table name. Without it, the table would default to the class name.
- `@Id` marks `id` as the primary key.
- `@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "customer_seq_gen")` says "don't let me set this value; generate it from a sequence using the generator called `customer_seq_gen`."
- `@SequenceGenerator(...)` defines that generator. Its parameters are explained in the next section.
- `Long` (the wrapper type rather than `long`) is used because a primitive can't be `null`, and JPA uses `null` to recognize that an entity hasn't been saved yet.
- The protected no-argument constructor is required by JPA, which creates objects through reflection. It's `protected` so application code doesn't use it by accident.

Your Spring Boot `application.properties` can let Hibernate create the table and sequence automatically during development:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/shopdb
spring.datasource.username=postgres
spring.datasource.password=yourpassword
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

`ddl-auto=update` lets Hibernate create or adjust tables and sequences to match your entities. `show-sql=true` prints the SQL it runs, which is very useful for learning. Use `update` only for development. In production, use migration tools like Flyway or Liquibase.

## Step 4: The parameters, one by one

|Parameter|Type|Default|Purpose|
|---|---|---|---|
|`name`|String|(required)|The logical name that `@GeneratedValue(generator = ...)` refers to.|
|`sequenceName`|String|Provider-chosen|The actual sequence name in the database.|
|`schema`|String|Default schema|The database schema that holds the sequence.|
|`catalog`|String|Default catalog|The database catalog, for databases that use catalogs.|
|`initialValue`|int|1|The first number the sequence produces.|
|`allocationSize`|int|50|How many IDs Hibernate reserves in memory per database call.|

**`name`** is required and only has to be unique within your application's mapping. Because `@GeneratedValue` refers to it by name, a typo here causes a startup error, which is good because it fails early instead of at runtime.

**`sequenceName`** is the name of the real object in the database. Always set it explicitly. If you don't, the default name depends on the provider and Hibernate version, and you'll have a harder time finding the sequence in your database later.

**`schema` and `catalog`** matter only when your database has several schemas or catalogs and your sequence lives somewhere other than the default. For a simple app, you can ignore them.

**`initialValue`** controls where the numbering starts. The default of 1 is fine for most cases. You might change it when importing legacy data that already uses IDs up to a certain number.

**`allocationSize`** is the most important and most misunderstood parameter, so let's look at it closely.

## Step 5: Why `allocationSize` matters

Without batching, every `save()` call would need its own trip to the database to fetch the next ID. That's slow. Hibernate avoids this with an optimization: it asks the database for a block of IDs once, then hands them out from memory.

With `allocationSize = 50`, the sequence in the database must increase by 50 each time. Hibernate fetches one number, say 1, and knows it can safely use IDs 1 through 50 itself without asking again. The next database call returns 51, and so on.

This means the sequence and `allocationSize` must agree. Here's the SQL Hibernate generates for the example above on PostgreSQL:

```sql
create sequence customer_seq start with 1 increment by 50;
```

The `increment by 50` comes directly from your `allocationSize`. Now watch what happens when they don't match:

- **Sequence increments by 1, but `allocationSize = 50`:** Hibernate gets 1 and assumes it owns 1 to 50. Another application instance gets 2 and assumes it owns 2 to 51. The two instances collide and you get duplicate key errors.
- **Sequence increments by 50, but `allocationSize = 1`:** Things work, but every save makes a database call, which removes the performance benefit, and the IDs have large gaps.

**The rule:** `allocationSize` should match the database sequence's increment exactly. If you create the sequence manually, use the same number in both places.

## Step 6: What happens when you save

Here's the flow when your code runs:

```java
Customer alice = new Customer("Alice");
customerRepository.save(alice);
System.out.println(alice.getId());   // Prints a number like 1
```

1. Hibernate sees that `alice.getId()` is `null` and needs a new ID.
2. On first use, it runs `select nextval('customer_seq')` and receives `1`.
3. It knows the sequence increments by 50, so it reserves IDs 1 through 50 in memory and assigns `1` to Alice.
4. The next customer gets `2` from memory with no database call. This continues until 50 is used up, then Hibernate fetches the next block.
5. The `INSERT` statement is sent, and `alice` now has its ID set in Java.

The example is simplified, but the idea is central to understanding how Hibernate handles sequences. Batching improves performance, but it also means IDs can skip numbers if the app restarts. That's normal and harmless, since IDs only need to be unique, not consecutive.

## Step 7: Common mistakes

1. **Name mismatch:** `@GeneratedValue(generator = "seq")` with `@SequenceGenerator(name = "customer_seq")` will fail at startup. The two strings must be identical.
2. **Forgetting `strategy = GenerationType.SEQUENCE`:** Without it, `generator` alone does nothing.
3. **Using `int` instead of `Long`:** Works, but leaves no way to represent "not saved yet" as `null`.
4. **Mismatched `allocationSize`:** Covered above, and the most common source of confusing bugs in multi-instance deployments.
5. **Using it with MySQL 8:** Use `GenerationType.IDENTITY` there instead.

## Try it yourself

Create a `Product` entity with a `@SequenceGenerator` named `product_seq_gen` that uses the sequence `product_seq` with `allocationSize = 10` and `initialValue = 100`. Then, in your Spring Boot app, save three products and print their IDs. Before running, predict what the three IDs will be and what the generated `create sequence` statement will look like. Then check your guesses with `show-sql=true`. Once you're comfortable with this, a natural next step is to experiment with `IDENTITY` and compare how the two strategies behave.



[[Spring Framework]]