
Lombok and Spring Data annotations are the most common helpers in production code, and several Hibernate annotations solve problems that come up in every real project. I'll skip anything from earlier lessons (`@Id`, `@GeneratedValue`, `@Table`, `@Column`, `@Index`, `@UniqueConstraint`, `@Embeddable`, `@EmbeddedId`, `@Enumerated`, and the relationship annotations). The UUID annotation is spelled `@UuidGenerator`, and it needs Hibernate 6.2 or later, which Spring Boot 3 includes. Some annotations below need Hibernate 6.4 or later, which Spring Boot 3.2 and newer include.

## The full list

|Annotation|Source|Purpose|
|---|---|---|
|`@UuidGenerator`|Hibernate|Generates UUID keys with control over the style|
|`@CreationTimestamp`|Hibernate|Sets a field to the time of insert|
|`@UpdateTimestamp`|Hibernate|Sets a field to the time of each update|
|`@Immutable`|Hibernate|Makes an entity or field read-only after insert|
|`@DynamicInsert`|Hibernate|Leaves out null columns so database defaults apply|
|`@DynamicUpdate`|Hibernate|Updates only the columns that changed|
|`@SoftDelete`|Hibernate|Marks rows as deleted instead of removing them|
|`@SQLRestriction`|Hibernate|Adds a filter to every query for an entity|
|`@NaturalId`|Hibernate|Marks a business key used for lookups|
|`@BatchSize`|Hibernate|Loads lazy collections in groups, reducing query count|
|`@Formula`|Hibernate|Maps a read-only value calculated by SQL|
|`@Generated`|Hibernate|Lets the database fill in a column value|
|`@ColumnTransformer`|Hibernate|Wraps a column's read and write SQL|
|`@JdbcTypeCode`|Hibernate|Selects a column type, such as JSON|
|`@Cache`|Hibernate|Enables second-level caching for an entity|
|`@MappedSuperclass`|JPA|Shares fields with a parent class without a table|
|`@Version`|JPA|Enables optimistic locking|
|`@Transient`|JPA|Keeps a field out of the database|
|`@Embedded`|JPA|Stores an embeddable object's fields in the same table|
|`@PrePersist`, `@PreUpdate`, `@PostLoad`, `@PreRemove`|JPA|Lifecycle callbacks|
|`@EntityListeners`|JPA|Attaches reusable callback classes|
|`@CreatedDate`, `@LastModifiedDate`|Spring Data|Filled in automatically by auditing|
|`@EnableJpaAuditing`|Spring Data|Turns auditing on|
|`@Getter`, `@Setter`|Lombok|Generates accessor methods|
|`@NoArgsConstructor`, `@AllArgsConstructor`, `@RequiredArgsConstructor`|Lombok|Generates constructors|
|`@Builder`, `@Builder.Default`|Lombok|Generates a fluent builder|
|`@SuperBuilder`|Lombok|Builder for class hierarchies|
|`@EqualsAndHashCode`, `@ToString`|Lombok|Generates equality and text output|
|`@Value`|Lombok|Makes an immutable value class|
|`@With`|Lombok|Generates copy-with-change methods|
|`@Singular`|Lombok|Adds collection items one at a time in a builder|
|`@NonNull`|Lombok|Generates null checks|
|`@Slf4j`|Lombok|Adds a logger field|
|`@Data`|Lombok|Bundles several annotations (avoid on entities)|

## Part 1: Hibernate helpers

### `@UuidGenerator`

This replaces `@GeneratedValue(strategy = UUID)` when you need control over how the UUID is built.

```java
import org.hibernate.annotations.UuidGenerator;
import java.util.UUID;

@Entity
@Table(name = "tickets")
public class Ticket {

    @Id
    @UuidGenerator(style = UuidGenerator.Style.TIME)   // Time-ordered UUIDs
    private UUID id;

    protected Ticket() {}
}
```

- **`style`** chooses the algorithm. `RANDOM` produces fully random UUIDs (version 4). `TIME` produces UUIDs that start with a timestamp, so they sort roughly by creation time. That keeps database index inserts close to the end of the index, which is faster than random UUIDs. `AUTO` lets Hibernate pick.
- The field needs no `@GeneratedValue`, because `@UuidGenerator` takes over that job.

For most production systems, `TIME` is the better choice for primary keys.

### `@CreationTimestamp` and `@UpdateTimestamp`

These let Hibernate fill in timestamps, so you don't need to set them in constructors.

```java
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

@CreationTimestamp
@Column(name = "created_at", nullable = false, updatable = false)
private Instant createdAt;

@UpdateTimestamp
@Column(name = "updated_at", nullable = false)
private Instant updatedAt;
```

- `@CreationTimestamp` sets the field once, when the row is first inserted.
- `@UpdateTimestamp` sets the field on every insert and update.
- By default the timestamp comes from the application's clock. Hibernate 6.2 and later also accept a `source` setting if you prefer the database's clock.

These are simpler than the constructor approach from earlier lessons, though the auditing approach in Part 2 is more flexible when you also need the user who made the change.

### `@Immutable`

This marks an entity or field as read-only after it's inserted. Hibernate ignores changes to it.

```java
@Entity
@Table(name = "audit_log")
@Immutable
public class AuditEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 500)
    private String action;

    protected AuditEntry() {}
}
```

Audit logs and historical records should never change, so putting `@Immutable` on the class protects them from accidental updates. You can also place it on a single field, such as a creation reference that should never be replaced.

### `@DynamicInsert` and `@DynamicUpdate`

By default, Hibernate writes every column in both `INSERT` and `UPDATE` statements, which is wasteful and can overwrite database defaults.

```java
@Entity
@Table(name = "products")
@DynamicInsert   // Leave out null columns, so database DEFAULT values apply
@DynamicUpdate   // Include only the columns that changed
public class Product {
    // fields...
}
```

- `@DynamicInsert` skips columns whose value is `null` in the `INSERT`. If the column has a `DEFAULT` in SQL, the database fills it in. Without this annotation, Hibernate would send `NULL` and override the default.
- `@DynamicUpdate` builds the `UPDATE` with only the changed columns. This reduces lock contention and makes logs easier to read.

Both cost a little CPU per statement, because Hibernate has to build the SQL each time. The cost is usually small.

### `@SoftDelete` and `@SQLRestriction`

Soft delete keeps a row in the database but marks it as deleted. This is useful when you need recovery, auditing, or reporting on removed records.

```java
import org.hibernate.annotations.SoftDelete;
import org.hibernate.annotations.SoftDeleteType;

@Entity
@Table(name = "products")
@SoftDelete(columnName = "deleted", strategy = SoftDeleteType.DELETED)
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private boolean deleted;   // Hibernate sets this to true when you call delete()

    protected Product() {}
}
```

- **`columnName`** is the column Hibernate updates instead of deleting the row. Your migration must create it.
- **`strategy`** decides which value means "deleted." With `DELETED`, the column is `true` for deleted rows. With `ACTIVE`, the column is `true` for active rows and `false` for deleted ones.

When you call `repository.delete(product)`, Hibernate runs an `UPDATE` instead of a `DELETE`. Queries then automatically exclude deleted rows.

`@SQLRestriction` adds a fixed filter to every query for an entity. It's useful for simpler cases, such as hiding inactive records:

```java
@SQLRestriction("active = true")
```

Hibernate 6.3 and later use this name. Older code used `@Where`, which is deprecated. Be careful combining `@SQLRestriction` with `@SoftDelete`, since both add filters and can hide rows you expected to see.

### `@NaturalId`

A natural ID is a business key, a value that identifies the entity in the real world, such as an SKU, a national ID, or an ISBN. Unlike the database's primary key, it's meaningful outside the database.

```java
@Entity
@Table(name = "products")
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NaturalId(mutable = false)                 // The SKU is part of the product's identity
    @Column(nullable = false, unique = true, length = 40)
    private String sku;

    protected Product() {}
}
```

- **`mutable = false`** tells Hibernate the value never changes after insert. This lets Hibernate cache the lookup from SKU to ID, so repeated lookups skip the database.
- The annotation doesn't create a unique rule by itself. Keep the `unique = true` on `@Column` so the database enforces it.

You then look up the entity through Hibernate's session API, for example `session.bySimpleNaturalId(Product.class).load("SKU-1")`, which is faster than a plain query. For everyday lookups, a Spring Data method such as `findBySku` is usually fine.

### `@BatchSize`

This fixes a common performance problem called the N+1 problem. Without it, loading 100 customers and then reading each customer's orders runs 1 query for the customers and 100 more for the orders.

```java
@Entity
@Table(name = "customers")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "customer")
    @BatchSize(size = 20)                       // Load orders for 20 customers per query
    private List<Order> orders = new ArrayList<>();

    protected Customer() {}
}
```

- **`size`** is how many owners Hibernate loads together. With 100 customers and `size = 20`, the 100 order lookups become 5 queries.

`@BatchSize` is a good default for collections you often load in lists. For a precise fix on a single query, `JOIN FETCH` in a JPQL query is usually better.

### `@Formula`

`@Formula` maps a value calculated by SQL. The value is read-only and not stored in the table.

```java
@Formula("(select count(*) from orders o where o.customer_id = id)")
private int orderCount;
```

- The string is raw SQL. `id` refers to the current row's primary key.
- Hibernate reads the value on every load, so it's always current. The cost is a subquery each time, so avoid heavy formulas on large lists.

Use it for counts or totals you display often but don't need to store. For values that are expensive to calculate, store them and update them when the data changes.

### `@Generated`

This tells Hibernate that the database, not Java, sets a column's value, such as a trigger that updates a timestamp.

```java
import org.hibernate.generator.EventType;

@Generated(event = {EventType.INSERT, EventType.UPDATE})
@Column(name = "last_checked", insertable = false, updatable = false)
private Instant lastChecked;
```

- **`event`** lists when the database sets the value. Here it's set on insert and on update.
- The `insertable = false` and `updatable = false` settings tell Hibernate not to send its own value. Without them, Hibernate's value would conflict with the database's.
- After an insert or update, Hibernate reads the value back so the Java field matches the database.

Use this only when a trigger or column default really does set the value. Otherwise Java and the database can disagree.

### `@ColumnTransformer`

This wraps a column's SQL, which is useful for transforming values on read or write without changing the Java code.

```java
@ColumnTransformer(
        read = "LOWER(email)",      // Applied when reading the column
        write = "LOWER(?)"          // Applied when writing; ? is the value being saved
)
@Column(nullable = false, unique = true, length = 255)
private String email;
```

- **`read`** is SQL placed around the column name in every `SELECT`. Here, emails come back in lowercase.
- **`write`** is SQL placed around the value in every `INSERT` and `UPDATE`. The `?` marks where the value goes, so `LOWER(?)` stores lowercase emails.

The transformation happens in the database, so filters and comparisons see the transformed value too. Keep these expressions simple, because they run on every query that touches the column.

### `@JdbcTypeCode`

This tells Hibernate which database type to use for a field, which is needed for types such as JSON.

```java
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@JdbcTypeCode(SqlTypes.JSON)
@Column(columnDefinition = "jsonb")
private Map<String, String> attributes;
```

- **`SqlTypes.JSON`** maps the field to a JSON column. Hibernate converts the map to and from JSON automatically.
- `columnDefinition = "jsonb"` tells the schema which PostgreSQL type to use. The `jsonb` type stores JSON in a binary form that supports indexing and querying, which is usually the right choice in PostgreSQL.

This is much cleaner than writing your own converter when your data has flexible attributes.

### `@Cache`

`@Cache` puts an entity into Hibernate's second-level cache, which stores entities across sessions so repeated reads skip the database.

```java
import org.hibernate.annotations.Cache;
import org.hibernate.annotations.CacheConcurrencyStrategy;

@Entity
@Table(name = "countries")
@Cache(usage = CacheConcurrencyStrategy.READ_WRITE)
public class Country {
    // fields...
}
```

- **`usage`** picks the concurrency strategy. `READ_ONLY` is for data that never changes. `READ_WRITE` is for data that changes occasionally and keeps the cache consistent when it does.

Caching requires a cache provider such as Ehcache or Caffeine through JCache, plus the setting `spring.jpa.properties.hibernate.cache.use_second_level_cache=true`. Only cache data that is read often and changes rarely, such as reference lists.

## Part 2: JPA and Spring Data helpers

### `@MappedSuperclass`

This marks a base class whose fields are copied into each child entity's table. The base class has no table of its own.

```java
@MappedSuperclass
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    public Long getId() { return id; }
}

@Entity
@Table(name = "products")
public class Product extends BaseEntity {
    private String name;
}
```

- `Product`'s table includes the `id` column from `BaseEntity`.
- The base class is `abstract`, so nobody can create a `BaseEntity` directly.
- Child classes can't be queried as `BaseEntity`. If you need a query across all subclasses, use `@Inheritance` instead, which is a separate topic.

This is the standard way to share an ID, timestamps, and version field across many entities without repeating them.

### `@Version`

`@Version` enables optimistic locking. Hibernate checks the version on each update, so two users editing the same row can't overwrite each other silently.

```java
@Version
private Long version;
```

- Hibernate sets `version` to 0 on insert and increments it on each update.
- An update includes `WHERE version = ?` with the value it read. If another transaction changed the row first, zero rows match, and Hibernate throws an exception instead of overwriting.
- Spring turns this into `ObjectOptimisticLockingFailureException`. The usual response is to show the user a "someone else changed this, please reload" message.

The field type should be `Long` or `Integer`, and you should never set it yourself.

### `@Transient` and `@Embedded`

`@Transient` keeps a field in Java only. Use the JPA version from `jakarta.persistence`:

```java
import jakarta.persistence.Transient;

@Transient
private String displayLabel;   // Computed in Java, not stored
```

The `java.beans.Transient` annotation has the same name and does not work with JPA, which is an easy mistake to make.

`@Embedded` stores an embeddable object's fields as columns in the owning entity's table. It's the field-side counterpart of `@Embeddable`:

```java
@Embedded
private Address address;   // Stores street, city, and postal_code columns in this table
```

### Lifecycle callbacks

These methods run automatically at specific points in an entity's life:

```java
@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String reference;

    @PrePersist                          // Runs just before the first INSERT
    void assignReference() {
        if (reference == null) {
            reference = "ORD-" + UUID.randomUUID().toString().substring(0, 8);
        }
    }

    @PreUpdate                           // Runs just before each UPDATE
    void checkChanges() {
        // validation or normalization goes here
    }

    @PostLoad                            // Runs after the entity is read from the database
    void afterLoad() {
        // computed transient values can be set here
    }

    @PreRemove                           // Runs just before DELETE
    void beforeDelete() {
        // cleanup checks go here
    }

    protected Order() {}
}
```

- The callback methods must be `void` and take no arguments. They can be any visibility, but package-private or `protected` is conventional.
- `@PrePersist` is a good place to fill in a default that depends on other data, because it runs after your constructor and right before the insert.
- Keep callbacks simple. Don't call repositories or other services from them, because the database operation is already in progress.

### `@EntityListeners` and auditing

Auditing records who created or changed a row, and when. Spring Data handles it through a listener class, which you attach to a base entity so all children get it:

```java
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)   // Hooks Spring Data auditing into this entity
public abstract class AuditableEntity {

    @CreatedDate                                  // Set once on insert
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate                             // Set on every insert and update
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
```

- **`@EntityListeners`** attaches the listener that reads these annotations and fills the fields.
- **`@CreatedDate`** and **`@LastModifiedDate`** mark the timestamp fields.
- There are also **`@CreatedBy`** and **`@LastModifiedBy`** for user names. They need a bean implementing `AuditorAware`, which returns the current user, usually taken from Spring Security.

Auditing must be switched on once in configuration:

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@Configuration
@EnableJpaAuditing   // Turns on the listener in every entity that uses it
public class JpaConfig {
}
```

Without `@EnableJpaAuditing`, the annotations are silently ignored, which is a common reason for `null` timestamps.

## Part 3: Lombok

Lombok generates methods during compilation, so your source code stays short. Add it to `pom.xml` (Spring Boot manages the version):

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>   <!-- Needed only at compile time, not shipped in the app -->
</dependency>
```

`optional` keeps Lombok out of anything that depends on your project. If your IDE shows errors about missing getters, enable annotation processing in its settings.

### `@Getter` and `@Setter`

```java
@Getter                // Generates getters for every field
@Entity
@Table(name = "products")
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
}
```

- `@Getter` on a class creates a getter for each field. You can also put it on a single field.
- `@Setter` creates setters. Avoid it on entities, because public setters let any code change any field without a rule. Prefer methods with names that describe the change, such as `rename(String newName)`, or add `@Setter` only to specific fields that truly need it.

### `@NoArgsConstructor`, `@AllArgsConstructor`, `@RequiredArgsConstructor`

```java
@Entity
@NoArgsConstructor(access = AccessLevel.PROTECTED)   // JPA's required constructor, hidden from app code
@AllArgsConstructor                                  // One constructor taking every field
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String fullName;
}
```

- **`@NoArgsConstructor(access = AccessLevel.PROTECTED)`** replaces the hand-written `protected Customer() {}` from earlier lessons. The `access` parameter sets visibility, and `PROTECTED` keeps the constructor out of normal use.
- **`@AllArgsConstructor`** generates a constructor with one parameter per field, in declaration order. Its order is fixed by your field list, so reordering fields changes the constructor.
- **`@RequiredArgsConstructor`** generates a constructor for only the `final` fields and any field marked `@NonNull`. It's the usual choice for services, because Spring can inject dependencies through it:

```java
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;   // Becomes a constructor parameter
    private final PaymentClient paymentClient;

    // No constructor written by hand
}
```

### `@Builder` and `@Builder.Default`

`@Builder` generates a fluent builder, which makes objects with many optional fields readable:

```java
@Entity
@Table(name = "products")
@Builder
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)   // The builder needs an all-args constructor
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(length = 2000)
    private String description;

    @Builder.Default                                 // Keeps the initial value when using the builder
    @Column(nullable = false)
    private boolean active = true;
}
```

Usage:

```java
Product product = Product.builder()
        .name("Notebook")
        .description("A4 ruled")
        .build();
```

- `@Builder` needs a constructor with every field. The `@AllArgsConstructor(access = PRIVATE)` provides it without exposing it to other code.
- **`@Builder.Default`** is needed whenever a field has an initializer, such as `= true`. Without it, the builder ignores the initializer and sets the field to `false`, a bug that is easy to miss.

### `@SuperBuilder`

`@Builder` doesn't work with inheritance, because a child's builder can't set the parent's fields. `@SuperBuilder` solves this by generating builders that chain up the hierarchy. Every class in the chain needs it:

```java
@MappedSuperclass
@Getter
@SuperBuilder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}

@Entity
@Table(name = "products")
@Getter
@SuperBuilder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Product extends BaseEntity {

    @Column(nullable = false, length = 120)
    private String name;
}
```

Usage:

```java
Product product = Product.builder()
        .name("Notebook")
        .build();
```

- The builder lets you set `name` from `Product` and `createdAt` from `BaseEntity` in one chain.
- Because `@SuperBuilder` is abstract-aware, the abstract `BaseEntity` gets its own builder base class that `Product`'s builder extends. You never call `BaseEntity.builder()` directly.

Use `@SuperBuilder` whenever you have a `@MappedSuperclass` base and want builders on the children.

### `@EqualsAndHashCode` and `@ToString`

These generate `equals`, `hashCode`, and `toString` from fields. On entities, the default behavior is risky. Two problems come up:

- Including the `id` breaks equality before the entity is saved, when `id` is `null`.
- Including relationships, such as `orders` in a customer, can recurse forever when two entities point to each other.

Lombok's `onlyExplicitlyIncluded` option lets you choose exactly what counts:

```java
@Entity
@Table(name = "products")
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(onlyExplicitlyIncluded = true)
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @EqualsAndHashCode.Include                       // Business key: stable across saves
    @ToString.Include
    @Column(nullable = false, unique = true, length = 40)
    private String sku;

    @Column(nullable = false, length = 120)         // Not included: name changes shouldn't change identity
    private String name;

    @OneToMany(mappedBy = "product")                // Not included: would cause recursion in toString
    private List<Review> reviews = new ArrayList<>();
}
```

- **`onlyExplicitlyIncluded = true`** means only fields marked with `@Include` take part, which makes the choice visible.
- **`@EqualsAndHashCode.Include`** marks a field for equality. Using a stable business key like `sku` gives equal results before and after saving.
- **`@ToString.Include`** marks a field for `toString`. Keeping relationships out prevents infinite loops and avoids accidentally loading lazy collections.
- If you need to exclude a single field from the default behavior, use `@ToString.Exclude` or `@EqualsAndHashCode.Exclude` instead.

### `@Value`

`@Value` makes a class immutable. Its fields become `private final`, the class becomes `final`, and it gets an all-args constructor, getters, `equals`, `hashCode`, and `toString`:

```java
@Value
public class ProductSummary {
    String name;
    BigDecimal price;
}
```

Use it for read-only data such as DTOs or view models. For entities, don't use it, because JPA needs to change fields and needs a no-args constructor. On Java 16 and later, a `record` does the same job for simple cases, so choose whichever your team prefers.

### `@With`

`@With` generates methods that return a copy with one field changed, which fits immutable objects:

```java
@Value
@With
public class Price {
    BigDecimal amount;
    String currency;
}
```

```java
Price euros = new Price(new BigDecimal("9.99"), "EUR");
Price higher = euros.withAmount(new BigDecimal("12.99"));   // euros is unchanged
```

The original object never changes, which avoids bugs when the same object is shared between parts of the code.

### `@Singular`

`@Singular` makes a collection field in a builder accept one item at a time, with a singular method name:

```java
@Builder
public class Article {
    @Singular
    private List<String> tags;
}
```

```java
Article article = Article.builder()
        .tag("java")         // Adds one item
        .tag("spring")
        .build();
```

Lombok creates the singular name from the field name, so `tags` gives `tag(...)`. You can also pass a whole list through `tags(...)`. Lombok generates the matching method names, and it works best with simple names.

### `@NonNull`

`@NonNull` tells Lombok to generate a null check. If a null is passed, the constructor or setter throws a `NullPointerException` with a clear message:

```java
@Value
public class CreateOrderCommand {
    @NonNull Long customerId;
    @NonNull String productSku;
}
```

With `@Value` and `@AllArgsConstructor`, a `null` customer ID fails fast at the point of creation, rather than deep inside a database call. Bean Validation (`@NotNull`) does similar work at the web layer, and the two complement each other. `@NonNull` also works on method parameters, for example `void send(@NonNull String message)`.

### `@Slf4j`

`@Slf4j` adds a logger named `log` to a class, so you don't write the logger declaration yourself:

```java
@Slf4j
@Service
public class OrderService {

    public void placeOrder(Long customerId) {
        log.info("Placing order for customer {}", customerId);   // {} is replaced by the value
    }
}
```

Use the `{}` placeholder form rather than string concatenation. The message is built only if the log level is enabled, which saves work in production. Never log passwords, tokens, or personal data.

### `@Data`, and why to avoid it on entities

`@Data` combines `@Getter`, `@Setter`, `@ToString`, `@EqualsAndHashCode`, and `@RequiredArgsConstructor`. It looks convenient, but on an entity it causes the problems described earlier: setters everywhere, equality based on mutable fields, and `toString` that can load lazy relationships. Use explicit annotations on entities and `@Value` or records for DTOs.

## Part 4: Putting it together

Here is a production-style base class and entity that use several helpers from this lesson together:

```java
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.SoftDelete;
import org.hibernate.annotations.SoftDeleteType;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.Instant;

@MappedSuperclass                                        // Fields are copied into each child's table
@EntityListeners(AuditingEntityListener.class)           // Fills the @CreatedDate and @LastModifiedDate fields
@Getter
@SuperBuilder                                            // Builder that works with inheritance
@NoArgsConstructor(access = AccessLevel.PROTECTED)       // Required by JPA
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version                                             // Optimistic locking
    private Long version;
}
```

```java
@Entity
@Table(name = "products")
@Getter
@SuperBuilder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@SoftDelete(columnName = "deleted", strategy = SoftDeleteType.DELETED)
public class Product extends BaseEntity {

    @Column(nullable = false, length = 120)
    private String name;

    @Builder.Default
    @Column(nullable = false)
    private boolean deleted = false;

    public void rename(String newName) {                 // A named behavior instead of a public setter
        this.name = newName;
    }
}
```

What this combination gives you:

- `BaseEntity` supplies the ID, the audit timestamps, and the version to every entity that extends it, and each child table gets those columns.
- `@SuperBuilder` on both classes lets you write `Product.builder().name("Notebook").build()`, and the base fields are set through the same chain.
- `@Getter` provides read access without a public setter. Changes go through methods like `rename`, which can enforce rules later.
- `@SoftDelete` makes `delete()` mark the row instead of removing it, and Hibernate hides deleted rows from queries automatically.
- `@Version` protects concurrent edits, and auditing fills the timestamps without any constructor code.

Remember that the `created_at`, `updated_at`, `version`, and `deleted` columns still need to exist in your migration, since these annotations describe the mapping but don't create the columns.

## Common mistakes

1. **Using `@Data` on entities.** Mutable equality, public setters, and recursive `toString` cause hard-to-find bugs.
2. **Forgetting `@Builder.Default`.** The initializer is silently ignored, so `active` becomes `false`.
3. **Forgetting `@EnableJpaAuditing`.** The auditing annotations do nothing, and timestamps stay `null`.
4. **Using `java.beans.Transient`.** JPA ignores it, so the field still gets saved. Import `jakarta.persistence.Transient`.
5. **Putting `@Version` on a field you set manually.** Hibernate owns the version. Leave it alone.
6. **Expecting `@SoftDelete` to remove rows.** Rows stay in the table, so unique constraints still apply to them. Plan for that.
7. **Calling a repository inside `@PrePersist`.** The insert is already in progress, and the call can break the transaction.
8. **Using `@Value` on an entity.** JPA can't set its fields or create it without a no-args constructor.

## Try it yourself

1. Create a `BaseEntity` with `@MappedSuperclass`, `@SuperBuilder`, `@Version`, and auditing. Add a `Category` entity that extends it, build one with the builder, and print its `createdAt` after saving. Explain why `createdAt` is set even though your code never assigned it.
2. Add `@Immutable` to an `AuditEntry` class, then try to change one of its fields and save. Observe what Hibernate does with the change, and explain why you would want that behavior for logs.
3. Write a `@Value` DTO named `ProductView` with `name` and `price`, and a `@ToString.Include`-based entity that prints only its SKU. Explain which of the two classes can safely use `@Data` and why neither should.


[[Spring Framework]]