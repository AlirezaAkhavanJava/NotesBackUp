
`@Column` is the JPA annotation you use to control **how a Java entity field maps to a database column**.

Think of it as:

```text
Java field                         Database column

private String email;    ───────►  email VARCHAR(...)
       │
       └── @Column(...)
```

Example:

```java
@Column(nullable = false, unique = true)
private String email;
```

means roughly:

```sql
email VARCHAR(...) NOT NULL UNIQUE
```

## 1. Basic usage

You don't actually need `@Column` for every field.

This:

```java
private String email;
```

is already mapped by JPA to a column named approximately:

```text
email
```

You use `@Column` when you want to **configure the mapping**.

---

## 2. Important parameters

The ones you should know first are:

```java
@Column(
    name = "...",
    nullable = ...,
    unique = ...,
    length = ...,
    precision = ...,
    scale = ...,
    insertable = ...,
    updatable = ...
)
```

### `name`

Controls the database column name:

```java
@Column(name = "email_address")
private String email;
```

Database:

```text
email_address
```

This is useful when your Java naming and database naming differ.

---

### `nullable`

```java
@Column(nullable = false)
private String email;
```

Means:

> This column should not contain `NULL`.

Conceptually:

```sql
email VARCHAR(...) NOT NULL
```

Important: `nullable = false` is primarily **schema/DDL metadata**. It does not magically prevent someone from doing:

```java
user.setEmail(null);
```

You should also validate application input:

```java
@NotNull
private String email;
```

or commonly:

```java
@NotBlank
private String email;
```

So think:

```text
@NotBlank
    ↓
application validation

nullable = false
    ↓
database/schema constraint
```

They solve related but different problems.

---

### `unique`

```java
@Column(unique = true)
private String email;
```

Means the database column should have a uniqueness constraint.

Conceptually:

```sql
UNIQUE(email)
```

For something like user email:

```java
@Column(nullable = false, unique = true)
private String email;
```

is a common pattern.

But for serious database design, especially composite uniqueness, you should often use `@Table(uniqueConstraints = ...)` instead.

---

### `length`

Mostly relevant for string columns:

```java
@Column(length = 100)
private String username;
```

Conceptually:

```sql
username VARCHAR(100)
```

Don't blindly put `length = 255` everywhere. Let the database/JPA defaults work unless you actually have a domain constraint.

---

### `precision` and `scale`

These are mainly for decimal numbers.

```java
@Column(precision = 10, scale = 2)
private BigDecimal price;
```

Means approximately:

```text
12345678.90
│────────│
 10 digits total

2 digits after decimal
```

So:

```text
precision = total digits
scale     = digits after decimal
```

For monetary values, `BigDecimal` + explicit precision/scale is often appropriate.

---

# 3. `insertable` and `updatable`

These are more advanced.

```java
@Column(insertable = false)
private Instant createdAt;
```

means JPA should **not include this column when inserting**.

And:

```java
@Column(updatable = false)
private Instant createdAt;
```

means JPA should **not modify this column during UPDATE**.

A common pattern:

```java
@Column(nullable = false, updatable = false)
private Instant createdAt;
```

The idea is:

```text
INSERT
   ↓
createdAt = set

UPDATE
   ↓
createdAt = untouched
```

Very useful for creation timestamps.

---

# 4. `@Column` doesn't mean "create a column"

This distinction is important.

```java
@Column(nullable = false)
private String email;
```

doesn't mean:

> "Create a database column."

It means:

> "When mapping this entity property to a relational column, use these rules."

Hibernate can then use this metadata when generating/validating the schema.

---

# 5. A good entity pattern

For your `User` entity, something like:

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;
}
```

Mentally divide the annotations:

```text
@Entity
   ↓
"This Java class is a database entity"

@Id
   ↓
"This property identifies the entity"

@GeneratedValue
   ↓
"Generate that identity"

@Column
   ↓
"Configure this property's database-column mapping"

@Table
   ↓
"Configure the database table"
```

That's the hierarchy I'd keep in your head while learning JPA.


[[Java]]
[[0 - Spring Framework]]