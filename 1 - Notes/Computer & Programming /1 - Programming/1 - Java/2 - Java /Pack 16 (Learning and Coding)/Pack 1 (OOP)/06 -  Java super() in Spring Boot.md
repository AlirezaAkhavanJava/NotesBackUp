

In Spring Boot, constructors play an important role in how frameworks create and initialize objects. **JPA needs a no-argument constructor so it can instantiate entity objects when reading data from the database, while Spring typically uses parameterized constructors to inject dependencies into services and controllers.** Lombok provides annotations such as `@NoArgsConstructor`, `@AllArgsConstructor`, and `@RequiredArgsConstructor` to generate these constructors automatically. These requirements are separate from `super()`, but if our class extends another class, Java still requires its constructors to invoke a valid superclass constructor.

## 1. Why Does JPA Need a No-Argument Constructor?

Imagine we have this entity:

```java
@Entity
@Table(name = "users")
public class AppUser {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String username;

    public AppUser(String username) {
        this.username = username;
    }
}
```

When Hibernate retrieves a user from PostgreSQL, it needs to create an `AppUser` instance and populate its persistent fields.

But according to the JPA specification, entities must have a public or protected no-argument constructor.

We can provide one:

```
protected AppUser() {
}
```

Now Hibernate can instantiate the entity through its no-argument constructor and populate its state with the database values.

The simplified process is:

```
Repository.findById(id)
        |
        v
Hibernate executes SQL
        |
        v
Database returns row
        |
        v
Hibernate creates AppUser instance
        |
        v
No-argument constructor
        |
        v
Hibernate populates persistent fields
        |
        v
AppUser is returned
```

### Using Lombok

Instead of writing the constructor manually:

```
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AppUser {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String username;
}
```

`@NoArgsConstructor` generates the constructor Hibernate needs.

**Important:** JPA's requirement is about how the persistence provider instantiates entities. It is not caused by `super()`.

---

## 2. Why Do We Use `@AllArgsConstructor`?

`@AllArgsConstructor` is a Lombok annotation that generates a constructor accepting every non-static field in the class.

Example:

```
@AllArgsConstructor
public class UserDto {

    private String username;
    private String email;
    private int age;
}
```

Lombok generates the equivalent of:

```
public UserDto(
        String username,
        String email,
        int age
) {
    this.username = username;
    this.email = email;
    this.age = age;
}
```

We can then create objects with all their fields initialized:

```
UserDto user = new UserDto(
        "Ali",
        "ali@example.com",
        25
);
```

This constructor is useful for convenience, but **Spring Boot doesn't require every class to have an all-arguments constructor**.

For JPA entities, automatically generating a constructor that includes database-generated identifiers is often unnecessary.

---

## 3. Why Do We Use `@RequiredArgsConstructor`?

This annotation is especially useful in Spring Boot services and controllers.

Consider:

```
@Service
public class AppUserService {

    private final AppUserRepository repository;

    public AppUserService(AppUserRepository repository) {
        this.repository = repository;
    }
}
```

Spring sees the constructor and injects the appropriate repository bean when creating the service.

We can simplify this with Lombok:

```
@Service
@RequiredArgsConstructor
public class AppUserService {

    private final AppUserRepository repository;
}
```

Lombok generates:

```
public AppUserService(AppUserRepository repository) {
    this.repository = repository;
}
```

Spring uses that constructor to inject the dependency.

Unlike JPA entities, **a typical Spring service does not need a no-argument constructor**.

When there is a single constructor, Spring can use it for dependency injection without requiring `@Autowired`.

### What Does "Required Args" Mean?

Lombok considers these fields required:

- Uninitialized `final` instance fields.
    
- Uninitialized fields annotated with Lombok's `@NonNull`.
    

It does not simply mean any arbitrary subset of fields.

---

## 4. Where Does `super()` Actually Matter in Spring Boot?

Now let's connect everything.

Imagine we have a shared superclass for our JPA entities:

```
@MappedSuperclass
public abstract class BaseEntity {

    private String createdBy;

    protected BaseEntity(String createdBy) {
        this.createdBy = createdBy;
    }
}
```

And another entity extends it:

```
@Entity
@NoArgsConstructor
public class Movie extends BaseEntity {

    @Id
    @GeneratedValue
    private Long id;

    private String title;
}
```

**This code will not compile.**

Why?

Because Lombok generates a constructor equivalent to:

```
public Movie() {
    super();
}
```

But `BaseEntity` only has:

```
BaseEntity(String createdBy)
```

The generated constructor cannot call a nonexistent `BaseEntity()` constructor.

This is the same Java inheritance rule we studied earlier, now appearing in a Spring Boot application.

### How Do We Fix It?

Give the superclass a protected no-argument constructor:

```
@MappedSuperclass
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public abstract class BaseEntity {

    private String createdBy;

    protected BaseEntity(String createdBy) {
        this.createdBy = createdBy;
    }
}
```

And our entity:

```
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Movie extends BaseEntity {

    @Id
    @GeneratedValue
    private Long id;

    private String title;

    public Movie(String createdBy, String title) {
        super(createdBy);
        this.title = title;
    }
}
```

Now we have two construction paths:

**When Hibernate loads an entity:**

```
Hibernate instantiates Movie
        |
        v
Movie()
        |
        v
BaseEntity()
        |
        v
Hibernate populates persistent state
```

**When our application creates a new movie:**

```
Movie movie = new Movie("Ali", "Interstellar");
```

```
Movie(String, String)
        |
        v
super(createdBy)
        |
        v
BaseEntity(String)
        |
        v
Initialize title in Movie
        |
        v
Object ready
```

Both paths follow Java's superclass constructor rules, but they use different constructors for different purposes.

---

## 5. Which Constructor Should We Use in Spring Boot?

|Constructor|Main purpose|Common use|
|---|---|---|
|`@NoArgsConstructor`|Creates a constructor without parameters|JPA entities|
|`@AllArgsConstructor`|Creates a constructor accepting all instance fields|DTOs and simple data classes|
|`@RequiredArgsConstructor`|Creates a constructor for required fields|Services, controllers, and dependency injection|
|Custom constructor|Allows explicit initialization and validation logic|Domain entities, services, and value objects|
|`super(...)`|Invokes a superclass constructor|Classes using inheritance|

You do **not** need all three Lombok constructor annotations on every class. In fact, combinations can generate conflicting constructor signatures.

## 6. The Whole Picture

There are three different mechanisms to remember:

1. **Java inheritance:** Requires subclass constructors to invoke a superclass constructor, whether explicitly or implicitly.
    
2. **JPA/Hibernate:** Requires entity classes to provide an accessible no-argument constructor so entities can be instantiated by the persistence provider.
    
3. **Spring dependency injection:** Uses constructors to provide the dependencies needed by Spring-managed objects.
    

### Final Mental Model

`**super()**` **belongs to Java's inheritance mechanism, while constructor requirements in Spring Boot depend on which framework is creating the object and why.** Hibernate typically needs a no-argument constructor to recreate entities from database records, Spring uses dependency constructors to initialize services and controllers, and Lombok simply generates the constructors we request. If those classes also participate in inheritance, Java's `super()` rules apply as usual. These concepts work together, but they solve different problems.



[[Java]]
[[Spring Framework]]