# `@Table` and Lombok

Everything here is for Spring Boot 4.x (Hibernate 7, Jakarta Persistence 3.2) on JDK 25. Where behaviour differs from older tutorials, I say so.

## 1. The scenario

1. You create a Spring Boot 4 project on Debian 13 with JDK 25 and PostgreSQL. You add an entity class named `User`, with no `@Table`.
2. You start the app and Hibernate fails on `create table user (...)` with `syntax error at or near "user"`. `user` is a reserved word in PostgreSQL.
3. You add `@Table(name = "users")` and it works.
4. You need `email` to be unique and `last_name` to be searchable, so you read about `uniqueConstraints` and `indexes` on `@Table`.
5. `User.java` is now 120 lines, mostly getters, setters and constructors. You add Lombok's `@Data` to shrink it.
6. A teammate adds `Order` and `OrderItem` with a two-way relationship. Logging an `Order` throws `StackOverflowError`, and a `HashSet<User>` loses users after you save them.
7. You move the project to JDK 25. The build fails with `cannot find symbol: method getEmail()`, even though `@Getter` is right there.

Each of these seven events has its own cause, and the next sections go through them in turn.

## 2. The core mental model

> **`@Table` is metadata that tells JPA how a class maps to a table. Lombok is a compile-time code generator that writes boilerplate into your `.class` files. They never talk to each other, but Lombok's output is what JPA reflects on at runtime.**

```
 YOUR SOURCE            COMPILE TIME              RUNTIME
 -----------            ------------              -------
 User.java     --->  javac + Lombok      --->   Hibernate reads the
 @Getter             (adds getEmail(),          .class: sees getters,
 @Table(...)          constructors, etc.)       @Table, @Entity, fields
```

Lombok has no idea JPA exists, and JPA has no idea Lombok exists. That gap is where most Lombok bugs on entities come from, as section 4 shows.

## 3. Step-by-step walkthrough

### Step 1: with no `@Table`, the table name is derived

```
Class name        Spring Boot naming strategy      Table
User         -->  CamelCaseToUnderscores     -->   user        (reserved word!)
UserProfile  -->  CamelCaseToUnderscores     -->   user_profile
```

Spring Boot's default physical naming strategy turns `UserProfile` into `user_profile` (lowercase, underscores). It does not escape reserved words, so `User` becomes `user`, which Postgres rejects.

### Step 2: `@Table` overrides the name and adds schema-level rules

```java
@Entity
@Table(
    name = "users",
    schema = "app",                        // optional, e.g. a Postgres schema
    uniqueConstraints = @UniqueConstraint(
        name = "uk_users_email", columnNames = "email"),
    indexes = @Index(
        name = "idx_users_last_name", columnList = "last_name")
)
public class User { ... }
```

|Attribute|What it controls|
|---|---|
|`name`|Table name|
|`schema` / `catalog`|Which schema or catalog the table lives in|
|`uniqueConstraints`|Multi-column unique rules, such as `(tenant_id, email)`|
|`indexes`|Secondary indexes|

`@Column(unique = true)` is shorthand for a single-column unique constraint. Use `@Table(uniqueConstraints = ...)` when the constraint spans several columns or when you want to name it.

**Gotcha:** these constraints are only turned into DDL when Hibernate generates the schema (`ddl-auto=create` or `update`). With Flyway or Liquibase, the real constraint lives in your migration SQL, and `@Table` becomes documentation plus something `validate` can check. In production, write the SQL yourself.

### Step 3: how Lombok works

```
User.java (source)               User.class (compiled)
------------------               ---------------------
@Getter @Setter                  getId(), getEmail()
private String email;     --->   setEmail(String)
                                 (the source file is never changed)
```

Lombok is an **annotation processor**. During compilation it edits javac's in-memory syntax tree and adds the methods. The `.java` file on disk stays clean.

### Step 4: the annotations you'll actually use

```java
@Getter @Setter                        // generate getters/setters
@NoArgsConstructor                     // empty constructor (JPA requires one)
@AllArgsConstructor                    // one parameter per field
@RequiredArgsConstructor               // params for final/@NonNull fields only
@ToString / @EqualsAndHashCode         // generated, with include/exclude control
@Builder                               // fluent builder
@Slf4j                                 // gives you a `log` field
```

A common use outside entities is constructor injection:

```java
@Service
@RequiredArgsConstructor               // no hand-written constructor
public class UserService {
    private final UserRepository userRepository;   // final => injected
}
```

### Step 5: a safe Lombok entity

```java
@Entity
@Table(name = "users")
@Getter @Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)   // JPA needs it, callers shouldn't use it
@ToString(onlyExplicitlyIncluded = true)             // opt in, not opt out
public class User {

    @Id @GeneratedValue
    @ToString.Include
    private Long id;

    @Column(nullable = false, length = 255)
    @ToString.Include
    private String email;

    public User(String email) { this.email = email; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof User other)) return false;
        return id != null && id.equals(other.getId());
    }

    @Override
    public int hashCode() {
        return Hibernate.getClass(this).hashCode();
    }
}
```

I wrote `equals` and `hashCode` by hand on purpose. Section 4 explains why.

## 4. The conflicts: where the tools can't decide for you

### Failure A: reserved table name

```
ERROR: syntax error at or near "user"
```

Hibernate can't know that your database treats `user` as a keyword. It just emits the derived name.

### Failure B: `@Data` on an entity

`@Data` bundles `@Getter`, `@Setter`, `@ToString`, `@EqualsAndHashCode` and `@RequiredArgsConstructor`. On an entity, three things go wrong:

```
1. @EqualsAndHashCode uses ALL fields, including the mutable `id`:

   User u = new User("a@x.com");      // id = null  -> hash = H1
   set.add(u);
   repo.save(u);                      // id = 7     -> hash = H2
   set.contains(u);                   // false: it's in the wrong bucket

2. @ToString walks every field. With Order <-> OrderItem:

   Order.toString() -> items.toString() -> item.toString() -> order.toString() ...
   StackOverflowError

3. @ToString on a lazy collection triggers a SELECT, or throws
   LazyInitializationException if the session is already closed.
```

Lombok can't decide for you because it doesn't know which fields are identity, which are lazy, and which form cycles. That is JPA knowledge, and Lombok lacks it.

### Failure C: Lombok silently doing nothing on JDK 25

```
error: cannot find symbol
  symbol:   method getEmail()
```

Since JDK 23, `javac` no longer runs annotation processors it finds on the classpath unless you ask it to. Older JDKs ran them implicitly. Without an explicit processor path, Lombok never runs, and your code calls methods that were never generated.

## 5. Resolution

**For A:** use `@Table(name = "users")`, or `app_user` if you prefer to avoid the plural.

**For B:** don't use `@Data` on entities. Use targeted annotations with explicit control:

```
BEFORE (@Data)                       AFTER (targeted)
--------------                       ----------------
equals/hashCode: all fields    -->   equals/hashCode: id-based, hand-written
toString: all fields           -->   @ToString(onlyExplicitlyIncluded = true)
setters on everything          -->   @Setter only where you want mutation
```

**For C:** register Lombok explicitly as an annotation processor.

Maven (`pom.xml`):

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>

<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <annotationProcessorPaths>
            <path>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
            </path>
        </annotationProcessorPaths>
    </configuration>
</plugin>
```

Gradle:

```groovy
compileOnly 'org.projectlombok:lombok'
annotationProcessor 'org.projectlombok:lombok'
```

Then check the Lombok version. Java 25 support arrived in Lombok 1.18.40, so anything older fails on JDK 25. Run `mvn dependency:tree | grep lombok`. If Spring Boot's managed version is too old for your JDK, override it with `<lombok.version>` in your `pom.xml` properties. Reports on the Lombok issue tracker show some JDK 24/25 breakage persisting in a few setups even after 1.18.40, so use the newest release and check its changelog if something odd happens.

## 6. Advanced example: `Order` and `OrderItem`

This is a bidirectional one-to-many. It combines `@Table`, a unique constraint, Lombok, and `@Builder`, and it has several traps.

```java
@MappedSuperclass
@Getter
public abstract class BaseEntity {
    @CreationTimestamp
    private Instant createdAt;
}

@Entity
@Table(name = "orders",
       uniqueConstraints = @UniqueConstraint(
           name = "uk_orders_number", columnNames = "order_number"))
@Getter @Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString(onlyExplicitlyIncluded = true)
public class Order extends BaseEntity {

    @Id @GeneratedValue
    @ToString.Include
    private Long id;

    @Column(name = "order_number", nullable = false)
    @ToString.Include
    private String orderNumber;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    // keeps both sides of the relationship in sync
    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
    }

    // equals/hashCode as in section 3, step 5
}

@Entity
@Table(name = "order_items")
@Getter @Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class OrderItem {

    @Id @GeneratedValue
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;                  // NOT in toString: this would be the cycle

    private String sku;
}
```

### Why this works

- `@ToString(onlyExplicitlyIncluded = true)` means `items` and `order` are never touched by `toString()`. That removes both the cycle and the accidental lazy load.
- `equals` compares the `id`, which doesn't change once the entity is saved. `hashCode` uses a class-level constant so the hash stays stable across the null-to-assigned transition.
- `Hibernate.getClass(this)` unwraps proxies. A lazy `Order` reference is a generated subclass, and plain `getClass()` would return that subclass instead of `Order`.
- `@Column(name = "order_number")` and the `columnNames = "order_number"` in `@Table` must match, since both refer to the physical column.

### What could go wrong

- **`@Setter` on `items` plus `orphanRemoval = true`.** If someone calls `order.setItems(newList)`, Hibernate loses track of the old collection and throws `A collection with cascade="all-delete-orphan" was no longer referenced`. Mutate the existing list with `addItem`, or drop `@Setter` for that field with `@Setter(AccessLevel.NONE)`.
- **`@Builder` skips field initializers.** `Order.builder().build()` leaves `items` as `null` unless you add `@Builder.Default` to the field.
- **`@Builder` needs constructors to cooperate.** It uses the all-args constructor. With `@NoArgsConstructor` also present, add `@AllArgsConstructor(access = AccessLevel.PRIVATE)`, or the compiler complains.
- **`@Builder` on an entity with a `@MappedSuperclass` parent** ignores the parent's fields. You'd need `@SuperBuilder` on both, which is one more reason to use plain constructors or factory methods for entities.

### What-if variations

**What if you make the entity a Java `record`?** It won't work. JPA needs a non-final class with a no-arg constructor and mutable fields (Hibernate sets them after construction, and builds proxies by subclassing). Records are final and immutable. They are excellent for **DTOs and projections**, though.

**What if you already have a DTO with `@Data` or `@Value`?** On JDK 25 a `record` replaces both and needs no processor setup:

```java
public record UserDto(Long id, String email) {}
```

**What if you add a new field and forget the unique constraint's column name?** With `ddl-auto=validate`, Hibernate may start fine, while in the real database the constraint is missing or misnamed. That is why the constraint belongs in your Flyway migration, with `@Table` only mirroring it.

## 7. Contrastive comparison: Lombok vs records vs hand-written

```
ENTITY (needs mutability, no-arg ctor, proxies)
  @Data                  -> risky: bad equals/hashCode/toString
  targeted Lombok        -> good: @Getter, @Setter, @NoArgsConstructor
  hand-written equals    -> required for correctness either way

DTO (immutable data carrier)
  record                 -> best: built into JDK, no processor
  @Value / @Data         -> works, but redundant on modern JDKs
```

||Lombok (targeted)|`record`|Hand-written / IDE-generated|
|---|---|---|---|
|Works for JPA entities|Yes|No|Yes|
|Works for DTOs|Yes|Best choice|Verbose|
|Extra build setup|Processor path required (JDK 23+)|None|None|
|Risk|Hidden generated code, JDK upgrade lag|None|Stale code when fields change|
|Best for|Entities, injection constructors, `@Slf4j`|DTOs, projections|Entity `equals`/`hashCode`|

**Rule of thumb:** on entities, use Lombok only where it removes boilerplate without changing semantics (getters, setters, constructors). Write `equals`/`hashCode` yourself, and use records for data carriers.

## 8. Key mental model recap

- `@Table` maps a class to a table. Without it, the name is derived (`User` becomes `user`, which breaks on Postgres).
- `@Table(uniqueConstraints, indexes)` describes schema rules. Real production schemas still come from migrations.
- Lombok is a compile-time processor that writes methods into the `.class`. JPA only sees the result.
- Never use `@Data` on entities. Use `@Getter`, `@Setter` and `@NoArgsConstructor(access = PROTECTED)`.
- Use `@ToString(onlyExplicitlyIncluded = true)` so lazy fields and cycles are never touched.
- Write id-based `equals` and a stable `hashCode`, and use `Hibernate.getClass(this)` for proxies.
- On JDK 23+, you must configure Lombok as an explicit annotation processor, and use a Lombok version with JDK 25 support (1.18.40+).
- Use records for DTOs, since they need no Lombok.

```
        write entity
             |
             v
   @Entity + @Table(name=...)         <- avoids reserved/derived names
             |
             v
   Lombok: @Getter @Setter            <- boilerplate only
           @NoArgsConstructor(PROTECTED)
           @ToString(onlyExplicitlyIncluded)
             |
             v
   hand-written equals/hashCode       <- id-based, proxy-safe
             |
             v
   build config: annotationProcessorPaths   <- required on JDK 23+
             |
             v
   DTOs? --> records (no Lombok)
```

**Takeaway:** _Name your tables explicitly with `@Table`, use Lombok on entities only for boilerplate (never `@Data`), write identity-based `equals`/`hashCode` by hand, and on JDK 25 configure Lombok as an explicit annotation processor._




[[Spring Framework]]