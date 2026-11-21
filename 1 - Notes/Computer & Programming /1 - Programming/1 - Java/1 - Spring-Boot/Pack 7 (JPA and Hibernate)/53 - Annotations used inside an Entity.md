 Annotations are labels you attach to a Java class and its fields so JPA (through Hibernate) knows how each field maps to a database table. In this lesson you'll learn how to mark the primary key with `@Id` and `@GeneratedValue`, how to name and index a table with `@Table`, how to describe columns with `@Column`, and how to enforce uniqueness at both the field level and the multi-column level. Each annotation gets a short explanation of its parameters, and then we'll write the matching Flyway migration, since the database is what actually enforces these rules.

## The annotations at a glance

Here's a map of the annotations you'll use most often. We'll go through each group in detail.

|Annotation|Applies to|What it does|
|---|---|---|
|`@Entity`|Class|Marks the class as a table-backed entity|
|`@Table`|Class|Sets the table name, schema, unique constraints, and indexes|
|`@Id`|Field|Marks the primary key|
|`@GeneratedValue`|Field|Says how the primary key value is created|
|`@EmbeddedId`|Field|Uses a separate class as a composite primary key|
|`@Column`|Field|Describes one column's name, rules, and size|
|`@UniqueConstraint`|Inside `@Table`|Defines a uniqueness rule across one or more columns|
|`@Index`|Inside `@Table`|Defines a database index to speed up lookups|

## Part 1: Marking the primary key

A primary key is the column that uniquely identifies each row. JPA needs to know which field plays this role, and it tells you with `@Id`. Every entity must have exactly one `@Id` field, or an `@EmbeddedId` for a composite key. Without one, Hibernate refuses to start.

```java
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;
```

- `@Id` says "this field is the primary key." That's all it does. It doesn't create any value on its own.
- `@GeneratedValue` says "the database or Hibernate creates this value for me, so I should not set it." It has one parameter, `strategy`, which picks the method.
- `Long` is used rather than `long` for the same reason as before: a new, unsaved object has `null` as its ID, and a primitive can't represent that.

The strategies you'll meet most often:

- **`GenerationType.IDENTITY`**: the database assigns the value, using `BIGSERIAL` in PostgreSQL. Simple and common, and it's what we use in this lesson.
- **`GenerationType.SEQUENCE`**: uses a database sequence, which you saw in the first lesson. Better for batch inserts.
- **`GenerationType.UUID`**: Hibernate generates a random UUID in Java. Useful when IDs must be unpredictable or created on different servers. The field type is `UUID`, and the SQL column is typically `UUID`.
- **`GenerationType.AUTO`**: lets Hibernate choose. It's convenient, but the choice can change between database providers, so explicit strategies are safer.

### Composite primary keys

Sometimes no single column is unique, but a combination is. For example, a student can enroll in a course only once, so the pair (student, course) is the key. Use `@EmbeddedId` with a separate class:

```java
@Embeddable
public class EnrollmentId implements Serializable {

    private Long studentId;
    private Long courseId;

    protected EnrollmentId() {}                       // Required by JPA

    public EnrollmentId(Long studentId, Long courseId) {
        this.studentId = studentId;
        this.courseId = courseId;
    }

    @Override
    public boolean equals(Object o) {                 // Two keys are equal if both parts match
        if (this == o) return true;
        if (!(o instanceof EnrollmentId other)) return false;
        return Objects.equals(studentId, other.studentId)
                && Objects.equals(courseId, other.courseId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(studentId, courseId);
    }
}
```

- `@Embeddable` marks a class whose fields are stored as columns of its owner's table, rather than as a separate table.
- `Serializable` is required by the JPA specification for composite keys.
- `equals` and `hashCode` must be overridden, because Hibernate compares keys to decide whether two objects represent the same row. Without them, two identical keys would look different.

Then the entity uses it:

```java
@Entity
@Table(name = "enrollments")
public class Enrollment {

    @EmbeddedId
    private EnrollmentId id;

    @Column(name = "enrolled_at", nullable = false)
    private Instant enrolledAt;

    protected Enrollment() {}

    public Enrollment(EnrollmentId id) {
        this.id = id;
        this.enrolledAt = Instant.now();
    }
}
```

`@EmbeddedId` says "the primary key is the embedded class." Notice that the entity doesn't use `@GeneratedValue`, because the key comes from the two values you provide, not from the database.

## Part 2: Naming the table with `@Table`

`@Table` controls everything about the table itself. Here are its parameters:

- **`name`**: the table name. If you omit it, the table takes the class name converted to snake case, so `AppUser` becomes `app_user`. Setting it explicitly is clearer.
- **`schema`**: the database schema, such as `shop` in `shop.products`. Useful when several apps share a database.
- **`uniqueConstraints`**: a list of `@UniqueConstraint` rules, covered in Part 4.
- **`indexes`**: a list of `@Index` definitions, also covered in Part 4.

A basic example:

```java
@Entity
@Table(name = "products")
public class Product {
    // fields go here
}
```

This tells Hibernate that `Product` lives in a table called `products`. Without `@Table`, the default name would also be `product`, but the explicit name makes the mapping easy to read and avoids surprises when a class is renamed.

## Part 3: Describing columns with `@Column`

`@Column` describes one column. Every parameter is optional, and most have sensible defaults, but each one you set is a rule you're declaring.

- **`name`**: the column name. Spring Boot automatically converts `fullName` to `full_name`, so you only need this when the name should differ from the snake-case version of the field.
- **`nullable`**: `false` means the column is `NOT NULL`. Default: `true`.
- **`unique`**: `true` declares a single-column unique rule. Default: `false`.
- **`length`**: the maximum size for `String` columns, which becomes `VARCHAR(n)`. Default: `255`.
- **`precision` and `scale`**: for decimal numbers. `precision` is the total number of digits, and `scale` is how many come after the decimal point. Used with `BigDecimal` and produces `NUMERIC(p, s)`.
- **`updatable`**: `false` means the column is never included in `UPDATE` statements. Useful for values like `created_at`.
- **`insertable`**: `false` means the column is never included in `INSERT` statements, which is useful when the database fills it in with a default or a trigger.
- **`columnDefinition`**: raw SQL for the column type, such as `"TEXT"` or `"JSONB"`. It's a powerful escape hatch, but it makes the entity dependent on one database.

Here's a realistic set of fields:

```java
@Column(name = "product_name", nullable = false, length = 120)
private String name;

@Column(nullable = false, precision = 10, scale = 2)
private BigDecimal price;

@Column(name = "created_at", nullable = false, updatable = false)
private Instant createdAt;

@Column(length = 2000)
private String description;   // Nullable, because nullable defaults to true
```

What each line means:

- `name = "product_name"` overrides the default `name` column name, which is useful because `name` is a common word and some databases treat it specially.
- `nullable = false` is a promise that every product has a name. Java will reject `null` at save time, and the database will refuse it as well.
- `precision = 10, scale = 2` allows values up to 99,999,999.99, which is suitable for prices.
- `updatable = false` makes sure the creation time can never be overwritten by accident.
- `description` has no `nullable` setting, so it's optional, and `length = 2000` allows longer text.

## Part 4: Enforcing uniqueness

Uniqueness rules prevent two rows from having the same value, or the same combination of values. There are three ways to declare them, and it's important to know which one to use.

### Option A: a single unique column with `@Column(unique = true)`

Use this when one column must be unique by itself, such as an email or a SKU code:

```java
@Column(nullable = false, unique = true, length = 40)
private String sku;
```

### Option B: a multi-column unique rule with `@UniqueConstraint`

Use this when the combination must be unique, but each column alone can repeat. For example, a store can have many products in the category "books", but each store should have only one category entry with a given code:

```java
@Table(
    name = "products",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_products_store_category",
                          columnNames = {"store_id", "category_code"})
    }
)
```

- `@UniqueConstraint` defines one rule. Its `name` gives the constraint a readable name, which matters because error messages show it.
- `columnNames` is an array of the column names involved. The rule applies to the combination, not to each column separately.

### Option C: a unique index with `@Index`

An index speeds up searches, and it can also enforce uniqueness:

```java
@Table(
    name = "products",
    indexes = {
        @Index(name = "idx_products_name", columnList = "product_name"),
        @Index(name = "idx_products_sku_unique", columnList = "sku", unique = true)
    }
)
```

- `name` sets the index name.
- `columnList` is a comma-separated string of columns, such as `"store_id, category_code"`.
- `unique = true` makes the index enforce uniqueness, which works like a constraint.

Use `@Index` for speed, and use `@UniqueConstraint` or `unique = true` for rules. PostgreSQL creates an index automatically for each unique constraint, so you rarely need both on the same columns.

### A very important caveat

Java annotations describe the rules, but Hibernate only creates the SQL for them when it generates the schema itself (`ddl-auto=create` or `update`). In this course we use Flyway, and we set `ddl-auto=validate`, which **checks the structure but doesn't create or enforce anything**. That means the constraints must be written in your migration. If the annotations and the SQL disagree, the database follows the SQL and your Java code can be misled.

## Part 5: A complete example

Here's an entity that uses every annotation from this lesson together:

```java
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(
    name = "products",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_products_store_category",
                          columnNames = {"store_id", "category_code"})
    },
    indexes = {
        @Index(name = "idx_products_name", columnList = "product_name")
    }
)
public class Product {

    @Id                                                        // Primary key
    @GeneratedValue(strategy = GenerationType.IDENTITY)         // Database assigns the ID
    private Long id;

    @Column(nullable = false, unique = true, length = 40)       // Single-column uniqueness
    private String sku;

    @Column(name = "product_name", nullable = false, length = 120)
    private String name;

    @Column(nullable = false, precision = 10, scale = 2)         // Exact decimal for money
    private BigDecimal price;

    @Column(name = "category_code", nullable = false, length = 10)
    private String categoryCode;

    @Column(name = "store_id", nullable = false)
    private Long storeId;

    @Column(length = 2000)                                      // Optional text
    private String description;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected Product() {}

    public Product(String sku, String name, BigDecimal price,
                   String categoryCode, Long storeId, String description) {
        this.sku = sku;
        this.name = name;
        this.price = price;
        this.categoryCode = categoryCode;
        this.storeId = storeId;
        this.description = description;
        this.createdAt = Instant.now();
    }

    public Long getId() { return id; }
    public String getSku() { return sku; }
    public String getName() { return name; }
    public BigDecimal getPrice() { return price; }
    public String getCategoryCode() { return categoryCode; }
    public Long getStoreId() { return storeId; }
    public String getDescription() { return description; }
    public Instant getCreatedAt() { return createdAt; }
}
```

Walking through the class:

- The `@Table` annotation declares two rules and one index, so anyone reading the class sees the table's design at a glance.
- `id` is the primary key, and the database generates it.
- `sku` has `unique = true`, so no two products can share a SKU.
- `storeId` and `categoryCode` appear in the multi-column rule, so the same category can't be added twice to one store.
- `price` uses `precision` and `scale` to store money exactly.
- `description` is nullable, which is the default when you don't write `nullable = false`.
- `createdAt` is set once in the constructor and protected by `updatable = false`.

## Part 6: The matching Flyway migration

Now write the SQL that makes these rules real. Create `src/main/resources/db/migration/V6__create_products.sql`. Use the next free version number in your project.

```sql
CREATE TABLE products (
    id             BIGSERIAL PRIMARY KEY,
    sku            VARCHAR(40)              NOT NULL UNIQUE,
    product_name   VARCHAR(120)             NOT NULL,
    price          NUMERIC(10, 2)           NOT NULL,
    category_code  VARCHAR(10)              NOT NULL,
    store_id       BIGINT                   NOT NULL,
    description    VARCHAR(2000),
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL,

    CONSTRAINT uk_products_store_category UNIQUE (store_id, category_code)
);

CREATE INDEX idx_products_name ON products (product_name);
```

Each piece lines up with an annotation:

- `BIGSERIAL PRIMARY KEY` matches `@Id` and `GenerationType.IDENTITY`. `PRIMARY KEY` also implies `NOT NULL` and `UNIQUE`.
- `NOT NULL` matches `nullable = false`. The column with no `NOT NULL` (`description`) matches the default `nullable = true`.
- `VARCHAR(40)` matches `length = 40`.
- `NUMERIC(10, 2)` matches `precision = 10, scale = 2`.
- `UNIQUE` on `sku` matches `unique = true`.
- `CONSTRAINT uk_products_store_category UNIQUE (store_id, category_code)` matches the `@UniqueConstraint` with the same name and columns. Naming it explicitly is important, because the name is what appears in the error message.
- `CREATE INDEX idx_products_name` matches the `@Index` with the same name and column.
- `created_at` has no default, so the Java constructor must provide the value. That matches `updatable = false` on the Java side, which only controls updates.

Start the application and check that the two sides agree:

```bash
sudo -u postgres psql -d shopdb -c "\d products"
```

The output shows each column, its `NOT NULL` status, and the uniqueness constraints. If Hibernate's `validate` mode starts without complaint, the column names and types match.

## Part 7: Handling a violation in code

When you try to save a duplicate, the database throws an error. You can use the constraint name to explain the problem clearly:

```java
try {
    productRepository.save(new Product("SKU-1", "Notebook", new BigDecimal("4.99"),
                                       "BOOK", 1L, null));
} catch (DataIntegrityViolationException ex) {
    String message = ex.getMostSpecificCause().getMessage();
    if (message.contains("uk_products_store_category")) {
        throw new IllegalArgumentException("This store already has that category");
    }
    if (message.contains("products_sku_key")) {
        throw new IllegalArgumentException("SKU already exists");
    }
    throw ex;
}
```

- `DataIntegrityViolationException` is Spring's wrapper for constraint failures.
- `getMostSpecificCause()` reaches the original database error, which contains the constraint name.
- The constraint names are why naming them matters. Hibernate's default for the `unique = true` column is a generated name, so the SQL name `products_sku_key` is PostgreSQL's default. Setting an explicit name in the migration makes this code more reliable, and it's a good improvement to make in your own project.

## Other annotations you'll see often

These aren't the focus of this lesson, but you'll meet them soon:

- **`@Transient`**: the field exists in Java but is not stored in the database.
- **`@Enumerated(EnumType.STRING)`**: stores an enum by name. You used it in the security lesson.
- **`@Version`**: adds a version number for optimistic locking, which prevents two users from overwriting each other's changes.
- **`@Embedded`**: stores a class's fields as columns in the owner's table, without a key of its own. Useful for an `Address` class.
- **`@OneToMany`, `@ManyToOne`, `@JoinColumn`**: relationships, which you saw in the Flyway lesson.

## Common mistakes

1. **Writing `unique = true` but not the SQL.** With `ddl-auto=validate`, Java annotations don't create the rule. Write it in the migration too.
2. **Mismatched lengths.** If `length = 100` in Java but `VARCHAR(50)` in SQL, long values fail only at runtime.
3. **Forgetting `nullable = false` on required fields.** Java may still allow `null` if you forget the annotation.
4. **Using `double` for money.** Use `BigDecimal` with `precision` and `scale`.
5. **Defining the same rule twice.** Having both `unique = true` on a column and a matching `@UniqueConstraint` creates two constraints. Choose one style per rule.
6. **Writing `equals` without `hashCode` in a composite key.** Hibernate can treat identical keys as different.

## Try it yourself

1. Create a `Customer` entity with `email` unique and `phone` unique within a `country_code` (a composite rule). Write the `@Table` annotation and the matching `V7__create_customers.sql`. Then try to insert two rows with the same email, and read the error message.
2. Add a `@Column(updatable = false)` field called `registeredAt`, and try to change it with a setter-style method. Then explain why the field is safe even though the Java code could still assign it in memory.
3. Replace the `IDENTITY` strategy in `Product` with `UUID`, change the migration to use `UUID PRIMARY KEY` with `gen_random_uuid()` as the default, and explain what changes in the Java field type and in the constructor.




[[Spring Framework]]