

Every JPA entity needs a way to answer one question: "which database row is this object?" **`@Id`** marks the field that answers it, and **`@GeneratedValue`** says the value should be created for you instead of being supplied by your code. Together they give each entity a stable identity that Hibernate uses to find, update and delete rows. This lesson covers what each annotation does, the generation strategies and when to pick which, and the habits that keep identity problems out of your project.

## 1. The two annotations, two jobs

```java
@Id
@GeneratedValue(strategy = GenerationType.UUID)
private UUID id;
```

- **`@Id`** answers _what_ identifies this entity.
- **`@GeneratedValue`** answers _who_ creates that identifier.

## 2. Why JPA requires an identity

Hibernate must be able to tell which Java object corresponds to which database row. Imagine the table:

|id|email|
|---|---|
|`a1...`|alice@example.com|
|`b7...`|bob@example.com|

With an ID, Hibernate can say "update the user whose id is `a1...`". Without one, it has no reliable way to link an object to its row. The identifier is the entity's **primary key**, and Hibernate uses it to load, update and delete rows, to track objects inside a transaction, to build relationships between entities, and for caching.

Note that `@Id` doesn't require the field to be named `id`. That is just the convention, and you should follow it. Every entity needs exactly one identifier (or a composite one, which is a more advanced topic).

## 3. What `@Id` does

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    private UUID id;

    private String email;
}
```

`@Id` maps the field to the table's primary key:

```sql
CREATE TABLE users (
    id    UUID PRIMARY KEY,
    email VARCHAR(255)
);
```

On its own, `@Id` means _you_ must set the value before saving.

## 4. What `@GeneratedValue` does

It removes that burden. Instead of:

```java
user.setId(UUID.randomUUID());
```

you write:

```java
User user = new User();
user.setEmail("alice@example.com");
userRepository.save(user);   // the ID is created here
```

```
new User()          id = null
   |
repository.save()   Hibernate generates the ID
   |
INSERT INTO users ...   id = 550e8400-e29b-41d4-a716-446655440000
```

## 5. The generation strategies

The `strategy` parameter decides how the ID is created.

### `GenerationType.UUID`

```java
@Id
@GeneratedValue(strategy = GenerationType.UUID)
private UUID id;
```

Hibernate creates a random UUID **in your application**, before the insert. This strategy needs JPA 3.1, which means Spring Boot 3 or newer.

Pros: no database round trip to get the ID, IDs can't be guessed one after another, and IDs are unique across systems. Con: random UUIDs are scattered, so on very large tables the primary-key index can become slower than with sequential numbers. If that matters, Hibernate offers time-ordered UUIDs:

```java
@Id
@GeneratedValue
@UuidGenerator(style = UuidGenerator.Style.TIME)
private UUID id;
```

For most applications the plain `UUID` strategy is fine.

### `GenerationType.IDENTITY`

```java
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;
```

The **database** assigns the number (an auto-increment column). Simple and conventional.

One cost: Hibernate cannot know the ID until the row is inserted, so it must run each `INSERT` immediately. This **disables JDBC batch inserts**, which matters if you save thousands of rows at once.

### `GenerationType.SEQUENCE`

```java
@Id
@GeneratedValue(strategy = GenerationType.SEQUENCE)
private Long id;
```

Hibernate asks a database **sequence** for numbers. It works with batching, because Hibernate can fetch a block of IDs ahead of time. It's the usual high-performance choice for numeric IDs on PostgreSQL and Oracle.

You can configure the sequence yourself:

```java
@Id
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "user_seq")
@SequenceGenerator(name = "user_seq", sequenceName = "user_id_seq", allocationSize = 50)
private Long id;
```

Watch out for `allocationSize`. It is how many IDs Hibernate reserves at once, and it **must match the sequence's increment** in your database. A mismatch causes duplicate-key errors or large gaps. The default is 50.

### `GenerationType.AUTO` and `TABLE`

`AUTO` lets Hibernate choose based on the ID type and database. It's convenient, but the result is less obvious, so for real projects choose a strategy explicitly. `TABLE` simulates a sequence with a table. It's slow and almost never the right choice.

### What is `generator`?

The `generator` parameter connects `@GeneratedValue` to a named configuration such as `@SequenceGenerator`:

```
@GeneratedValue(generator = "user_seq")
        |
        v
@SequenceGenerator(name = "user_seq", sequenceName = "user_id_seq")
```

For UUIDs and `IDENTITY` you normally don't need it.

## 6. Which one should you use?

|Situation|Choice|
|---|---|
|You want unguessable, globally unique IDs|`UUID`|
|Simple app, numeric IDs, no heavy bulk inserts|`IDENTITY`|
|Numeric IDs and you insert many rows at once|`SEQUENCE`|

For a typical Spring Boot project, `UUID` or `IDENTITY` is a perfectly good default.

A note on UUIDs: they make guessing other records' IDs impractical, but that is not a replacement for authorization. Always check that the current user is allowed to access a record.

## 7. Don't set a generated ID yourself

If the ID is generated, don't call `user.setId(...)` on a new entity. With Spring Data, a non-null ID makes `save()` assume the entity already exists, so it tries to load and update a row that isn't there. Depending on the version, that leads to extra queries or errors. Leave the ID `null` and let Hibernate fill it in.

Also, use the wrapper type `Long` rather than the primitive `long` for numeric IDs. A primitive can never be `null`, so Hibernate cannot tell whether an entity is new.

## 8. The ID is not your business identifier

Don't use a business value like an email as the primary key:

```java
@Id
private String email;   // risky
```

People change their email addresses, and a primary key is referenced from other tables, so changing it is painful. Keep identity technical and put business rules on separate columns:

```java
@Id
@GeneratedValue(strategy = GenerationType.UUID)
private UUID id;

@Column(nullable = false, unique = true)
private String email;
```

```
id     technical identity: "which row is this?"
email  business attribute: "how does a person recognise this user?"
```

## 9. A complete example

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    protected User() {}   // JPA requires a no-argument constructor

    public User(String email) {
        this.email = email;
    }

    public UUID getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }
}
```

The ID has a getter but no setter, which is deliberate: it is created for you, so nothing should overwrite it.

## Key takeaways

1. `@Id` marks the entity's identity (the primary key). `@GeneratedValue` says who creates it.
2. Use `UUID` for unguessable IDs, `IDENTITY` for simple auto-increment, and `SEQUENCE` when you need fast bulk inserts.
3. `IDENTITY` disables batch inserts. For `SEQUENCE`, `allocationSize` must match the database sequence.
4. Choose a strategy explicitly. Don't rely on `AUTO`.
5. Never set a generated ID yourself, and use `Long` (not `long`).
6. Keep the technical ID separate from business values like email.



[[Spring Framework]]