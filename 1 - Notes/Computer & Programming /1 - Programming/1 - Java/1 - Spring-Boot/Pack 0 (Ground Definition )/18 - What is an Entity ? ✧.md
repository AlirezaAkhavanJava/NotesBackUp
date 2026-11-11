

An **entity** is a plain Java class that represents a row in a database table. Each instance of the class is one row, each field is a column, and the class itself maps to the table.
In Spring Boot you mark the class with `@Entity` (from JPA, the Jakarta Persistence API), and the framework, usually Hibernate underneath, takes care of translating between your objects and SQL. Hibernate uses the SQL dialect to generate SQL compatible with your database.`spring.jpa.hibernate.ddl-auto` tells Hibernate what to do with the database schema when the application starts.

Think of it as a contract: "this object's state is something I want to persist." Once a class is an entity, you can save, load, update, and delete it by working with objects, and you rarely write `INSERT` or `UPDATE` statements yourself.

## The problem entities solve

Objects and relational tables don't naturally fit together. Objects have references, inheritance, and collections. Tables have rows, foreign keys, and joins. Without something in between, you'd write code like this for every class:

```java
ResultSet rs = stmt.executeQuery("SELECT id, name, email FROM users WHERE id = 1");
User u = new User();
u.setId(rs.getLong("id"));
u.setName(rs.getString("name"));
// ...and the reverse for every insert and update
```

That is repetitive, error-prone, and ties your code tightly to the schema. This gap is called the **object-relational impedance mismatch**, and **ORM** (Object-Relational Mapping) exists to bridge it. Entities are how you describe the mapping to the ORM.

## A first entity

```java
import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(unique = true)
    private String email;

    protected User() {}               // required by JPA

    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    // getters (setters only where you really need them)
}
```

- **`@Entity`** tells JPA to manage this class.
- **`@Table`** is optional. Without it, the table name defaults to the class name.
- **`@Id`** marks the primary key. ***Every entity must have one.***
- **`@GeneratedValue`** lets the database (or a sequence) produce the key. `IDENTITY` uses auto-increment, while `SEQUENCE` is usually preferred on PostgreSQL and Oracle because it allows batch inserts.
- **`@Column`** lets you define mapping rules and constraints for an entity field. Hibernate, as the ORM provider, can translate those rules into SQL schema definitions.
- **The no-arg constructor** is mandatory. Hibernate creates instances reflectively and then fills in the fields. `protected` is enough and stops other code from creating a half-empty object.

With Spring Data you then get a repository almost for free:

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
```

---
## The idea that explains most surprises: the persistence context

This is the concept people skip and then get confused by later. When you load an entity inside a transaction, Hibernate keeps it in a **persistence context** (the `EntityManager`'s first-level cache) and _watches it_. An entity is always in one of these states:

- **Transient**: created with `new`, unknown to JPA, not in the DB.
- **Managed**: tracked by the persistence context. Changes are synchronized to the DB.
- **Detached**: was managed, but the transaction or session ended. Changes are no longer tracked.
- **Removed**: scheduled for deletion.

```java
@Transactional
public void rename(Long id, String newName) {
    User user = userRepository.findById(id).orElseThrow(); //Loading
    user.setName(newName);   // no save() call, and the UPDATE still happens
}
```

That works because of **dirty checking**: at commit, Hibernate compares the managed entity with its original snapshot and issues an `UPDATE` if anything changed. Once you know this, many "magic" behaviors, and many bugs, stop being mysterious. This is also why `@Transactional` matters so much with entities.

![[Spring_JPA Loading and Transactions Infographic.png]]

## Relationships

Real data is connected, so entities reference each other:

```java
@Entity
public class Order {
    @Id @GeneratedValue private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;
}

@Entity
public class User {
    // ...
    @OneToMany(mappedBy = "user")
    private List<Order> orders = new ArrayList<>();
}
```

Three things to understand here:

- **Owning side**: in a bidirectional relationship, the side with the foreign key column (`Order.user`) owns it. `mappedBy` marks the _inverse_ side. Only changes to the owning side are persisted, so keep both sides in sync in your code.
- **Lazy vs. eager loading**: lazy means related data is loaded only when you touch it. `@ManyToOne` and `@OneToOne` default to eager, which is usually not what you want, so set `LAZY` explicitly. Touching a lazy field after the session is closed gives the infamous `LazyInitializationException`.
- **The N+1 problem**: loading 100 users and then reading each one's `orders` can trigger 1 query + 100 queries. Fix it with `JOIN FETCH`, `@EntityGraph`, or batch fetching.

## Entities are not DTOs

It is tempting to return entities straight from your controllers. Avoid it. Entities are tied to the persistence layer, so exposing them leaks your schema into your API, can trigger lazy loading during JSON serialization, and risks infinite recursion with bidirectional links. Instead, map entities to **DTOs** (records work nicely) at the service boundary:

```java
public record UserResponse(Long id, String name, String email) {}
```

## A few gotchas worth knowing early

- **`equals`/`hashCode`**: don't base them on all fields, and be careful with generated IDs, which are `null` before saving. Either use a stable business key or a well-known ID-based pattern.
- **Lombok**: `@Data` on entities is risky because generated `toString`/`equals` can trigger lazy loads or recursion. Prefer `@Getter` and write the rest deliberately.
- **Schema management**: `spring.jpa.hibernate.ddl-auto=update` is fine for experiments, but real projects use migrations (Flyway or Liquibase).

[[Spring Framework]]