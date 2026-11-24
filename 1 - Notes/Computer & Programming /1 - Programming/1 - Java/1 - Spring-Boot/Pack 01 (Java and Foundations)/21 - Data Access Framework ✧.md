

"DAF" isn't an official Spring term — people use it loosely for the **data access layer**: the part of your app that talks to the database so the rest of your code never writes raw SQL. You'll see it called **DAO**, **repository**, or **persistence layer** in real projects.

### The stack

```
Controller → Service → Repository
                            ↓
                  Spring Data repositories (interface you write)
                            ↓
                  JPA / Hibernate (object-to-table mapping)
                            ↓
                  JDBC (DataSource, PreparedStatement)
                            ↓
                  PostgreSQL / SQLite
```

Each layer hides the one below it — `repo.findByName("Ali")` triggers Hibernate and JDBC underneath, invisibly.

### Your options

|Tool|Use when|
|---|---|
|**Spring Data JPA**|Default choice for relational data|
|**Spring Data JDBC**|Want simpler repos, no lazy-loading/caching magic|
|**`JdbcTemplate`**|Want to write SQL yourself, less boilerplate|
|**MyBatis**|Want full SQL control with object mapping|
|**Spring Data MongoDB/Redis**|Data isn't relational|

For a PostgreSQL app, Spring Data JPA is the standard starting point.

### Example

```java
@Entity
@Table(name = "users")  // "user" is a reserved word in PostgreSQL
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
}

public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByName(String name);
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

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/doitlater
    username: postgres
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate   # "update" only while learning
    show-sql: true
```

### DAO vs. Repository

DAO thinks in terms of the table (`UserDao.insert(...)`); repository thinks in terms of a domain-object collection (`userRepository.save(user)`). Spring Data apps use repositories — many teams still call it "the DAO layer" out of habit.

### Facade: one interface over several sources

Worth adding only when one operation spans multiple sources (DB + cache + external API) or you need to swap storage later without touching services:

```java
public interface UserDataAccess {
    User save(User user);
    Optional<User> findById(Long id);
}

@Component
public class UserDataAccessImpl implements UserDataAccess {
    private final UserRepository jpaRepo;
    private final StringRedisTemplate redis;
}
```

A plain Spring Data repository is already an abstraction — don't wrap it in a facade without one of those two reasons. For simple caching, use `@Cacheable` instead of hand-rolling it.

### Mistakes to avoid

- Business logic in repositories — that belongs in the service.
- Returning entities instead of DTOs to the controller.
- `@Transactional` on a repository, or calling a transactional method via `this`.
- `ddl-auto: update` or plain-text passwords in production.
- Naming a table `user` or `order` — use `users`, `orders`.

### Related: the repository pattern

From Domain-Driven Design — makes the database look like an in-memory collection (`add`, `find`, `remove`), so business code doesn't depend on storage details. Spring Data repositories implement this pattern.


[[Spring Framework]]