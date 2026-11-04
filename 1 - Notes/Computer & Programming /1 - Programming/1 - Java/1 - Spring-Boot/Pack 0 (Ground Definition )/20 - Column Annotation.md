

JPA already maps every field of an entity to a database column on its own, so most of the time you write nothing. **`@Column`** is how you step in and say "not the default, do it like this": a different column name, a required value, a unique value, a maximum length, or the number of decimal places. It never creates a column by itself. It only describes how an existing field should map. This lesson covers each setting you will actually use, which ones the database enforces and which are only descriptions, and the mistakes that catch people out.

## 1. The default: no annotation needed

```java
private String email;
```

This is already mapped. By default, Spring Boot converts camelCase to snake_case, so a field named `createdAt` becomes a column named `created_at`.

You add `@Column` only to change something:

```java
@Column(nullable = false, unique = true)
private String email;
```

If Hibernate generates your schema, that gives you roughly:

```sql
email VARCHAR(255) NOT NULL UNIQUE
```

Think of it as a note attached to the field:

```
Java field                        Database column
private String email;  ------->   email VARCHAR(255) NOT NULL UNIQUE
        ^
        |
   @Column(nullable = false, unique = true)
```

## 2. The settings, one at a time

### `name`: the column name

```java
@Column(name = "email_address")
private String email;
```

Use it when the database name must differ from the Java name, most often when you map onto an existing schema you don't control.

### `nullable`: may it be empty?

```java
@Column(nullable = false)
private String email;
```

This declares the column `NOT NULL`. It is mainly **schema information**. Once the constraint exists in the database, the database enforces it. It is not a way to validate what users send you.

Compare the two tools:

|Tool|Where it acts|Purpose|
|---|---|---|
|`@NotBlank` (Bean Validation)|In your application|Reject bad input early, with a friendly `400` response|
|`nullable = false`|In the database schema|A last line of defense that nothing can bypass|

Use both. The first gives users a clear message, and the second keeps bad data out even if a bug slips past the first.

### `unique`: no duplicates

```java
@Column(unique = true)
private String email;
```

This asks for a uniqueness constraint. Two things people often miss:

1. **It only creates anything when Hibernate generates your schema** (`ddl-auto` set to `create` or `update`). If you use Flyway or Liquibase, as most real projects do, the annotation creates nothing. The constraint has to be in your migration script.
2. **The database constraint is the real protection.** Checking "does this email exist?" in Java before saving is not enough, because two simultaneous requests can both pass the check. Let the database reject the duplicate, then turn the resulting `DataIntegrityViolationException` into a `409 Conflict` with a friendly message.

For uniqueness across several columns together, use `@Table`:

```java
@Entity
@Table(
    name = "reservations",
    uniqueConstraints = @UniqueConstraint(columnNames = {"member_id", "book_id", "reserved_on"})
)
public class Reservation { ... }
```

### `length`: maximum size of a string

```java
@Column(length = 100)
private String username;
```

This gives `VARCHAR(100)`. Remember the **default is 255**. That suits names and emails, but a long description will be cut off or rejected. For long text, set a bigger `length` or use `@Column(columnDefinition = "TEXT")`. Set a specific length when you have a real reason, and don't write `length = 255` everywhere out of habit.

### `precision` and `scale`: decimal numbers

```java
@Column(precision = 10, scale = 2)
private BigDecimal price;
```

- `precision` is the total number of digits.
- `scale` is how many of those digits come after the decimal point.

So `precision = 10, scale = 2` holds values up to `99999999.99`: eight digits before the point and two after. For money, always use `BigDecimal` with explicit precision and scale, never `double`, which cannot store most decimal amounts exactly.

### `insertable` and `updatable`: who may write the column

These control whether JPA includes the column in `INSERT` and `UPDATE` statements. The common one is `updatable = false`, which protects a value after the row is created:

```java
@Column(nullable = false, updatable = false)
private Instant createdAt;
```

```
INSERT  ->  createdAt is written
UPDATE  ->  createdAt is left alone
```

`@Column` only _protects_ the value. Something still has to _set_ it. The usual choices are Spring Data auditing (`@CreatedDate` with `@EnableJpaAuditing`), Hibernate's `@CreationTimestamp`, or a `@PrePersist` method.

`insertable = false` is rare. It tells JPA never to write the column on insert, which only makes sense when the **database** fills it in (a default value, a trigger, or a generated column). If you use it on a field your Java code is supposed to set, that value will quietly never be saved.

## 3. A realistic entity

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    protected User() {} // JPA requires a no-argument constructor

    // constructor and getters omitted
}
```

A few choices here are deliberate:

- The table is `users`, not `user`, because `user` is a reserved word in PostgreSQL and causes confusing errors.
- The field is `passwordHash`, because you store the output of a password encoder, never the plain password. The name should make that obvious.
- Entities are normal classes, not records, because JPA needs a no-argument constructor and mutable fields.

## 4. What each annotation says

|Annotation|Meaning|
|---|---|
|`@Entity`|This class is mapped to a database table|
|`@Table`|Configure the table (name, composite constraints, indexes)|
|`@Id`|This field is the primary key|
|`@GeneratedValue`|The key is generated for you|
|`@Column`|Configure this field's column|

## 5. Common mistakes

- **Treating `nullable = false` as input validation.** Also validate with Bean Validation, so users get a clear error.
- **Trusting `unique = true` when you use migrations.** Put the constraint in the migration too.
- **Forgetting the default length of 255** on long text fields.
- **Using `double` for money** instead of `BigDecimal` with `precision` and `scale`.
- **Using `insertable = false` or `updatable = false`** without making sure something else sets the value.

## Key takeaways

1. `@Column` configures how a field maps. It does not create a column, and fields are mapped without it.
2. `nullable = false` and `unique = true` become real constraints only if the schema contains them. With migrations, write them there.
3. Validate in the application (`@NotBlank`) and constrain in the database.
4. Strings default to 255 characters, and money belongs in `BigDecimal` with `precision` and `scale`.
5. `updatable = false` protects a value like `createdAt`, but something must still set it.





[[Spring Framework]]