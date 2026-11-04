

"DAF" isn't an official Spring Boot term, and you won't find it in the Spring documentation. In practice people use it loosely to mean the **data access layer**: the part of your app that talks to the database, so the rest of your code never writes SQL or touches connections. The standard names you'll see in real projects are **DAO** (Data Access Object), **repository**, and **persistence layer** (which your persistence-layer note covered).

If you saw "DAF" in a specific codebase or course, it's worth asking what they mean, because it may be that team's own word. This note covers what it nearly always refers to: how a Spring Boot app is layered over the database, which tools you can choose from, and the facade idea that the second half of the original note described.

---

## The picture: how the layers stack

Your JDBC notes (DataSource, Statement, PreparedStatement) were the bottom of this stack. Everything else is built on top:

```text
Controller → Service → Repository ─────────────┐
                                                ▼
                  Spring Data repositories  (you write an interface)
                                                ▼
                  JPA / Hibernate           (maps objects to tables)
                                                ▼
                  JDBC  (DataSource, PreparedStatement)
                                                ▼
                  PostgreSQL / SQLite
```

Each layer hides the one below it. With Spring Data JPA you write `repo.findByName("Ali")`, and Hibernate and JDBC do the SQL and the connection handling for you.

---

## Your options, and when to pick each

The original table listed these as if they were all the same kind of thing. They aren't, so here they are by level:

|Tool|What it is|Choose it when|
|---|---|---|
|**Spring Data JPA**|Repository interfaces on top of JPA/Hibernate|The default for most apps with relational data|
|**Spring Data JDBC**|Simpler repositories with no lazy loading or caching magic|You want less ORM behavior and clearer SQL|
|**`JdbcTemplate`**|A helper for plain JDBC. Part of the Spring Framework, not Spring Data|You want to write the SQL yourself, with less boilerplate|
|**MyBatis**|A separate SQL-mapper library you add yourself|You want full SQL control with object mapping|
|**Spring Data MongoDB / Redis**|Repositories for NoSQL stores|The data isn't relational (Redis is on your learning list)|

For your `DoItLater`-style app on PostgreSQL, Spring Data JPA is the natural starting point.

---

## A working example (Spring Data JPA with PostgreSQL)

```java
@Entity
@Table(name = "users")                      // not "user": that's a reserved word in PostgreSQL
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    // getters and setters
}

public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByName(String name);     // Spring writes the query for you
}

@Service
public class UserService {
    private final UserRepository repo;

    public UserService(UserRepository repo) { this.repo = repo; }

    @Transactional(readOnly = true)
    public List<UserResponse> findUsers(String name) {
        return repo.findByName(name).stream()
                .map(u -> new UserResponse(u.getId(), u.getName()))
                .toList();
    }
}
```

Line by line:

- `@Table(name = "users")` avoids a classic PostgreSQL error. A table named `user` clashes with a reserved word.
- `JpaRepository<User, Long>` takes the entity type and the type of its ID. It gives you `save`, `findById`, `findAll`, `delete` and more with **no implementation class**. Spring generates one at startup.
- `findByName` is a **derived query**: Spring reads the method name and builds the SQL (`WHERE name = ?`). Add more words to the name for more conditions, such as `findByNameAndActiveTrue`.
- `@Transactional(readOnly = true)` is AOP at work (see your AOP note). The proxy opens a transaction around the method. It belongs on the **service**, not the repository.
- The service returns a **DTO**, not the entity, as your Entity/DTO/mapper notes explained. Mapping inside the transaction avoids lazy-loading errors.

### The configuration

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/doitlater
    username: postgres
    password: ${DB_PASSWORD}                # from an environment variable, not hard-coded
  jpa:
    hibernate:
      ddl-auto: validate                    # use "update" only while learning
    show-sql: true
```

The original used a MySQL URL, `ddl-auto: update` and a password written in the file. Your PostgreSQL configuration note and `@ConfigurationProperties` note explain each of these lines. Boot builds the `DataSource` from them automatically through the starter.

---

## DAO versus repository

You'll meet both words, and they're close but not identical:

||DAO|Repository|
|---|---|---|
|Thinks in terms of|The **table** and its CRUD operations|A **collection of domain objects**|
|Typical style|`UserDao.insert(...)`, `UserDao.update(...)`|`userRepository.save(user)`|

In a Spring Data app you write **repository** interfaces. Many teams still call the layer the "DAO layer" out of habit, and that is fine.

---

## The facade idea: one interface over several data sources

The second meaning in the original note was a **facade**: a class that hides several data sources behind one interface, so the service layer doesn't need to know where the data comes from.

```java
public interface UserDataAccess {
    User save(User user);
    Optional<User> findById(Long id);
}

@Component
public class UserDataAccessImpl implements UserDataAccess {
    private final UserRepository jpaRepo;
    private final StringRedisTemplate redis;
    // ...
}
```

Be careful with this one. A Spring Data repository is **already** an abstraction over the database, so wrapping it in another layer often adds code without adding value. A facade is worth it when:

- one operation really combines **several sources** (database, a cache, an external API), or
- you want to be able to **swap** the storage later without touching services.

For simple caching, don't write the logic by hand. `@Cacheable` is an AOP annotation that does it for you, with the same proxy rules.

---

## Mistakes to avoid

- **Business logic inside repositories.** Repositories read and write. The rules belong in the service.
- **Returning entities from the service to the controller.** Return DTOs.
- **Putting `@Transactional` on the repository or calling a transactional method on `this`.** Both fail in ways your AOP note explained.
- **`ddl-auto=update` and plain-text passwords in production.**
- **Naming a table `user` or `order`** in PostgreSQL. Use plural names such as `users` and `orders`.

---

## Related concept in short

**The repository pattern** comes from Domain-Driven Design. It makes your database look like an in-memory collection of domain objects (`add`, `find`, `remove`), so your business code doesn't depend on how or where they're stored. Spring Data repositories are an implementation of it.




[[Spring Framework]]