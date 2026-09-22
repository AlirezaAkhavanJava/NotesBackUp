In Spring Boot, **DAF** most commonly stands for **Data Access Framework** (or sometimes **Data Access Facade**). Let me explain both meanings, as the term isn't an official Spring Boot acronym but is used in practice.

## 1. Data Access Framework (DAF)

This refers to the **layer/abstraction in a Spring Boot application responsible for interacting with data sources** (databases, NoSQL stores, APIs, etc.).

Spring Boot's primary Data Access Frameworks include:

| Framework | Purpose |
|-----------|---------|
| **Spring Data JPA** | Repository abstraction over JPA/Hibernate |
| **Spring Data JDBC** | Simpler JDBC-based persistence |
| **Spring Data MongoDB** | MongoDB integration |
| **Spring Data Redis** | Redis integration |
| **MyBatis** | SQL mapper framework |
| **JdbcTemplate** | Low-level JDBC helper |

### Typical Layered Architecture

```
Controller  →  Service  →  Repository (DAF)  →  Database
```

### Example (Spring Data JPA as the DAF)

```java
// Entity
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;
    private String name;
    // getters/setters
}

// Repository (part of the Data Access Framework)
public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByName(String name);
}

// Service using the DAF
@Service
public class UserService {
    private final UserRepository repo;

    public UserService(UserRepository repo) { this.repo = repo; }

    public List<User> findUsers(String name) {
        return repo.findByName(name);
    }
}
```

### Configuration in `application.yml`

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/mydb
    username: root
    password: secret
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
```

## 2. Data Access Facade (DAF)

In some enterprise codebases, a **DAO/DAF pattern** is used where a facade wraps multiple repositories/data sources behind a single interface — hiding persistence complexity from the service layer.

```java
public interface UserDataAccessFacade {
    User save(User user);
    Optional<User> findById(Long id);
}

@Component
public class UserDataAccessFacadeImpl implements UserDataAccessFacade {
    private final UserRepository jpaRepo;
    private final UserCacheRepository cacheRepo;
    // combines JPA + Redis + external API behind one facade
}
```

## Key Takeaway

- **DAF is not an official Spring Boot term** — it's a general architecture acronym.
- In Spring Boot context, it typically means the **persistence layer** built on **Spring Data** projects (JPA, JDBC, Mongo, etc.).
- Spring Boot auto-configures the DAF via starters like `spring-boot-starter-data-jpa`.

If you saw "DAF" in a specific codebase or document, let me know the context — it could also mean something project-specific (e.g., **Data Access Filter**, **Dynamic Application Framework**).In Spring Boot, **DAF** most commonly stands for **Data Access Framework** (or sometimes **Data Access Facade**). Let me explain both meanings, as the term isn't an official Spring Boot acronym but is used in practice.

## 1. Data Access Framework (DAF)

This refers to the **layer/abstraction in a Spring Boot application responsible for interacting with data sources** (databases, NoSQL stores, APIs, etc.).

Spring Boot's primary Data Access Frameworks include:

| Framework | Purpose |
|-----------|---------|
| **Spring Data JPA** | Repository abstraction over JPA/Hibernate |
| **Spring Data JDBC** | Simpler JDBC-based persistence |
| **Spring Data MongoDB** | MongoDB integration |
| **Spring Data Redis** | Redis integration |
| **MyBatis** | SQL mapper framework |
| **JdbcTemplate** | Low-level JDBC helper |

### Typical Layered Architecture

```
Controller  →  Service  →  Repository (DAF)  →  Database
```

### Example (Spring Data JPA as the DAF)

```java
// Entity
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;
    private String name;
    // getters/setters
}

// Repository (part of the Data Access Framework)
public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByName(String name);
}

// Service using the DAF
@Service
public class UserService {
    private final UserRepository repo;

    public UserService(UserRepository repo) { this.repo = repo; }

    public List<User> findUsers(String name) {
        return repo.findByName(name);
    }
}
```

### Configuration in `application.yml`

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/mydb
    username: root
    password: secret
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
```

## 2. Data Access Facade (DAF)

In some enterprise codebases, a **DAO/DAF pattern** is used where a facade wraps multiple repositories/data sources behind a single interface — hiding persistence complexity from the service layer.

```java
public interface UserDataAccessFacade {
    User save(User user);
    Optional<User> findById(Long id);
}

@Component
public class UserDataAccessFacadeImpl implements UserDataAccessFacade {
    private final UserRepository jpaRepo;
    private final UserCacheRepository cacheRepo;
    // combines JPA + Redis + external API behind one facade
}
```

## Key Takeaway

- **DAF is not an official Spring Boot term** — it's a general architecture acronym.
- In Spring Boot context, it typically means the **persistence layer** built on **Spring Data** projects (JPA, JDBC, Mongo, etc.).
- Spring Boot auto-configures the DAF via starters like `spring-boot-starter-data-jpa`.



[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]
[[Java]]