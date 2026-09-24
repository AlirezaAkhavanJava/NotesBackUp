
`@Repository` is a **Spring stereotype annotation** that marks a class/interface as belonging to the **persistence/data-access layer**.

The important distinction is that `@Repository` and `JpaRepository` are **not the same thing**.

---

## 1. Basic meaning

```java
@Repository
public class UserRepository {
    // database operations
}
```

You're telling Spring:

> "This component is responsible for accessing persistent data."

Spring can then discover it during component scanning and register it as a **Spring bean**.

Conceptually:

```text
@Repository
     ↓
Spring detects it
     ↓
creates/registers Bean
     ↓
can be injected with constructor injection
```

---

# 2. But with `JpaRepository`...

This is where it gets interesting.

You normally write:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

**You generally do NOT need:**

```java
@Repository
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

Why?

Because **Spring Data JPA automatically creates the repository bean**.

So:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

is enough.

Spring Data detects the repository interface and creates a proxy implementation.

Conceptually:

```text
UserRepository interface
        │
        ▼
Spring Data JPA
        │
        ▼
generated proxy implementation
        │
        ▼
Spring Bean
```

---

# 3. `@Repository` is more important for manual repositories

Suppose you don't use Spring Data:

```java
@Repository
public class UserRepository {

    private final JdbcTemplate jdbcTemplate;

    public UserRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public User findById(UUID id) {
        // manually execute SQL
    }
}
```

Here `@Repository` is useful because you're telling Spring:

> Register this class as a repository component.

Then:

```java
@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

Spring injects it.

---

# 4. Special feature: exception translation

`@Repository` has another important purpose.

Spring can translate certain persistence-specific exceptions into Spring's `DataAccessException` hierarchy.

Conceptually:

```text
Hibernate/JPA exception
        │
        ▼
@Repository
        │
        ▼
Spring DataAccessException
```

This gives your application a more consistent persistence exception model instead of forcing your service layer to know about every underlying database/JPA implementation exception.

---

# 5. Compare the three things

This is the distinction you want firmly in your head:

|Thing|Purpose|
|---|---|
|`@Entity`|Maps a Java class to a database entity/table|
|`@Repository`|Marks a Spring component as a persistence/data-access component|
|`JpaRepository`|Provides a repository API for JPA entities|

Typical architecture:

```text
┌─────────────────────────┐
│       Controller        │
│       HTTP layer        │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│        Service          │
│      business logic     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│       Repository        │
│      data access        │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│      JPA / Hibernate    │
└───────────┬─────────────┘
            │
            ▼
       PostgreSQL
```

So in your Spring Boot project, this:

```java
public interface UserRepository
        extends JpaRepository<User, UUID> {
}
```

is the normal pattern.

Don't add `@Repository` just because you've seen it on repository examples. **Spring Data JPA already handles repository registration for `JpaRepository` interfaces.**



[[Java]]
[[0 - Spring Framework]]