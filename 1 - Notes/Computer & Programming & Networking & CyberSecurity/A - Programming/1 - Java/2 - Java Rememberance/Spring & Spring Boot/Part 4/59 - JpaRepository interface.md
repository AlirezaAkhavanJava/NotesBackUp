
`JpaRepository` is the Spring Data JPA interface that gives your application a **ready-made persistence API for an entity**.

The important mental model is:

```text
Your code
   │
   ▼
UserRepository
   │
   │ extends JpaRepository<User, UUID>
   ▼
Spring Data JPA
   │
   ▼
Hibernate
   │
   ▼
JDBC
   │
   ▼
PostgreSQL
```

## 1. The basic pattern

Suppose you have:

```java
@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String email;
}
```

Create:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

That's enough.

You don't implement the interface yourself.

Spring Data generates the implementation for you at runtime.

---

# 2. What are the two parameters?

This part is extremely important:

```java
JpaRepository<User, UUID>
             │      │
             │      └── ID type
             └───────── Entity type
```

### First parameter → entity

```java
User
```

means:

> This repository manages `User` entities.

### Second parameter → ID type

```java
UUID
```

means:

> The `User` entity's `@Id` is a `UUID`.

So these must correspond:

```java
@Id
@GeneratedValue(strategy = GenerationType.UUID)
private UUID id;
```

and:

```java
JpaRepository<User, UUID>
```

If you had:

```java
private Long id;
```

you'd write:

```java
JpaRepository<User, Long>
```

---

# 3. What do you get for free?

A huge amount.

For example:

```java
userRepository.save(user);
```

Creates or updates an entity.

```java
userRepository.findById(id);
```

Finds one:

```java
Optional<User>
```

```java
userRepository.findAll();
```

Gets all users.

```java
userRepository.delete(user);
```

Deletes it.

```java
userRepository.deleteById(id);
```

Deletes by ID.

```java
userRepository.existsById(id);
```

Checks existence.

```java
userRepository.count();
```

Counts entities.

You didn't write the SQL.

---

# 4. Why does Spring know what SQL to execute?

Because it has all the information from your entity mapping.

For example:

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;
}
```

and:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

Spring Data + Hibernate understand:

```text
User
 │
 ├── table → users
 │
 ├── id → UUID
 │
 └── email → email
```

So when you call:

```java
userRepository.findById(id);
```

Hibernate can construct the appropriate SQL.

Conceptually:

```sql
SELECT *
FROM users
WHERE id = ?;
```

---

# 5. You can define your own queries through method names

This is one of Spring Data's most useful features.

Suppose:

```java
private String email;
```

You can write:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {

    Optional<User> findByEmail(String email);
}
```

You don't implement it.

Spring interprets:

```text
findByEmail
     │
     └── property: email
```

and generates the query.

Conceptually:

```sql
SELECT *
FROM users
WHERE email = ?;
```

You can build more complex methods:

```java
Optional<User> findByEmailAndRole(
    String email,
    Role role
);
```

or:

```java
List<User> findByRole(Role role);
```

or:

```java
boolean existsByEmail(String email);
```

This is called **query derivation**.

---

# 6. Why an interface?

This:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

looks strange at first because there is no implementation.

Spring creates a proxy implementation.

Conceptually:

```text
You write:

UserRepository
      │
      ▼
Spring Data creates implementation
      │
      ▼
Repository proxy
      │
      ▼
EntityManager
      │
      ▼
Hibernate
```

At runtime, Spring injects that generated repository into your service:

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
}
```

Then:

```java
userRepository.findById(id);
```

works even though you never wrote:

```java
class UserRepositoryImpl implements UserRepository
```

Spring handles that machinery.

---

# 7. `JpaRepository` itself has a hierarchy

Conceptually:

```text
Repository
    │
    ▼
CrudRepository
    │
    ▼
ListCrudRepository
    │
    ▼
ListPagingAndSortingRepository
    │
    ▼
JpaRepository
```

`JpaRepository` gives you JPA-specific persistence functionality on top of the basic repository operations.

You don't need to memorize the hierarchy yet.

The practical rule is:

```java
JpaRepository<Entity, IdType>
```

For your project:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

means:

> **"Spring, create a repository for managing `User` entities whose primary key is a `UUID`, and give me the standard JPA persistence operations."**

That's the core idea.


[[Java]]
[[0 - Spring Framework]]