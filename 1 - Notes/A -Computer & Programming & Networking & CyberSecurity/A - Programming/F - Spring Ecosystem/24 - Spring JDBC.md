**Spring JDBC** is a module of the Spring Framework that simplifies database operations by providing a high-level abstraction over raw JDBC (Java Database Connectivity). It reduces boilerplate code, handles resource management, and provides exception translation, making it easier to interact with relational databases like **PostgreSQL**, **MySQL**, and **H2**. Spring JDBC is particularly useful for developers who need direct SQL control without the overhead of full ORM frameworks like Hibernate or Spring Data JPA.

This document explains Spring JDBC in a simple and comprehensive way, covering its key components, configurations, annotations, and examples, with a focus on PostgreSQL, MySQL, and H2 databases.

---
## Overview

- **Purpose**: Simplifies JDBC-based database operations by providing utilities like `JdbcTemplate`, connection pooling, and exception handling.
- **Key Features**:
    - **JdbcTemplate**: A central class for executing SQL queries and updates with minimal code.
    - **Exception Translation**: Converts SQLException into Spring’s `DataAccessException` hierarchy.
    - **Connection Management**: Automatically handles connection opening, closing, and pooling.
    - **Support for Transactions**: Simplifies transaction management with annotations or programmatic APIs.
    - **Database Agnostic**: Works with any JDBC-compliant database (e.g., PostgreSQL, MySQL, H2).
- **Use Cases**: Building lightweight data access layers, executing custom SQL queries, or integrating with databases in Spring Boot applications.

## Key Concepts

1. **JdbcTemplate**: The core class for executing SQL queries, updates, and stored procedures.
2. **DataSource**: A factory for database connections, typically configured with connection pooling.
3. **RowMapper**: Maps database rows (`ResultSet`) to Java objects.
4. **DataAccessException**: Spring’s exception hierarchy for handling database errors.
5. **Transaction Management**: Ensures data consistency using `@Transactional` or `TransactionTemplate`.
6. **NamedParameterJdbcTemplate**: A variant of `JdbcTemplate` that supports named parameters for cleaner queries.

## Key Components

### Key Classes

#### 1. **JdbcTemplate** (`org.springframework.jdbc.core.JdbcTemplate`)

- **Purpose**: Simplifies JDBC operations by handling connection management, statement execution, and result processing.
- **Key Methods**:
    - `query(String sql, RowMapper<T> rowMapper)`: Executes a SELECT query and maps results to objects.
    - `queryForObject(String sql, Class<T> requiredType, Object... args)`: Retrieves a single object.
    - `queryForList(String sql, Object... args)`: Returns a list of results.
    - `update(String sql, Object... args)`: Executes INSERT, UPDATE, or DELETE queries.
    - `execute(String sql)`: Executes any SQL statement (e.g., DDL).
    - `call(CallableStatementCreator creator, List<SqlParameter> params)`: Executes stored procedures.
- **Use Case**: Performing CRUD operations with minimal boilerplate.
- **Example**:

```java
@Autowired
JdbcTemplate jdbcTemplate;

public List<User> findAllUsers() {
    String sql = "SELECT * FROM users";
    return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(User.class));
}
```

#### 2. **NamedParameterJdbcTemplate** (`org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate`)

- **Purpose**: Extends `JdbcTemplate` to support named parameters (e.g., `:name`) instead of positional placeholders (`?`).
- **Key Methods**:
    - `query(String sql, Map<String, ?> paramMap, RowMapper<T> rowMapper)`: Executes a query with named parameters.
    - `queryForObject(String sql, Map<String, ?> paramMap, Class<T> requiredType)`: Retrieves a single object.
    - `update(String sql, Map<String, ?> paramMap)`: Executes an update with named parameters.
- **Use Case**: Writing readable queries with complex parameter sets.
- **Example**:

```java
@Autowired
NamedParameterJdbcTemplate namedParameterJdbcTemplate;

public User findUserByName(String name) {
    String sql = "SELECT * FROM users WHERE name = :name";
    Map<String, Object> params = new HashMap<>();
    params.put("name", name);
    return namedParameterJdbcTemplate.queryForObject(sql, params, new BeanPropertyRowMapper<>(User.class));
}
```

#### 3. **RowMapper** (`org.springframework.jdbc.core.RowMapper`)

- **Purpose**: Maps a `ResultSet` row to a Java object.
- **Key Method**:
    - `T mapRow(ResultSet rs, int rowNum)`: Converts a row to an object.
- **Use Case**: Custom mapping of database results to domain objects.
- **Example**:

```java
public class UserRowMapper implements RowMapper<User> {
    @Override
    public User mapRow(ResultSet rs, int rowNum) throws SQLException {
        User user = new User();
        user.setId(rs.getLong("id"));
        user.setName(rs.getString("name"));
        user.setAge(rs.getInt("age"));
        return user;
    }
}
```

#### 4. **BeanPropertyRowMapper** (`org.springframework.jdbc.core.BeanPropertyRowMapper`)

- **Purpose**: Automatically maps `ResultSet` columns to JavaBean properties based on matching names.
- **Use Case**: Simplifying row mapping without custom `RowMapper` implementations.
- **Example**:

```java
List<User> users = jdbcTemplate.query("SELECT * FROM users", new BeanPropertyRowMapper<>(User.class));
```

#### 5. **DataSource** (`javax.sql.DataSource`)

- **Purpose**: Provides database connections, typically configured with a connection pool (e.g., HikariCP in Spring Boot).
- **Key Method**:
    - `getConnection()`: Returns a database connection.
- **Use Case**: Configuring database access for `JdbcTemplate`.

### Utility Classes

#### 1. **TransactionTemplate** (`org.springframework.transaction.support.TransactionTemplate`)

- **Purpose**: Simplifies programmatic transaction management.
- **Key Method**:
    - `execute(TransactionCallback<T> action)`: Executes code within a transaction.
- **Use Case**: Managing transactions without `@Transactional`.
- **Example**:

```java
@Autowired
TransactionTemplate transactionTemplate;

public void createUser(String name, int age) {
    transactionTemplate.execute(status -> {
        jdbcTemplate.update("INSERT INTO users (name, age) VALUES (?, ?)", name, age);
        return null;
    });
}
```

#### 2. **DataAccessException** (`org.springframework.dao`)

- **Purpose**: Spring’s exception hierarchy for database errors, wrapping `SQLException`.
- **Key Subclasses**:
    - `DataIntegrityViolationException`: For constraint violations.
    - `DuplicateKeyException`: For duplicate key errors.
    - `EmptyResultDataAccessException`: When no results are found.
- **Use Case**: Consistent error handling across databases.

## Spring JDBC with Spring Boot

Spring Boot auto-configures Spring JDBC with a `DataSource`, `JdbcTemplate`, and connection pooling (HikariCP by default), making it easy to use with databases like PostgreSQL, MySQL, and H2.

### Dependencies (Maven)

```xml
<dependencies>
    <!-- Spring Boot Starter JDBC -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-jdbc</artifactId>
    </dependency>
    <!-- Database Drivers (choose one or more) -->
    <!-- PostgreSQL -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <version>42.7.4</version>
    </dependency>
    <!-- MySQL -->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>8.0.33</version>
    </dependency>
    <!-- H2 -->
    <dependency>
        <groupId>com.h2database</groupId>
        <artifactId>h2</artifactId>
        <version>2.3.230</version>
    </dependency>
</dependencies>
```

### Configuration (`application.properties`)

#### PostgreSQL

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=password
spring.datasource.driver-class-name=org.postgresql.Driver
spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect
spring.sql.init.mode=always
```

#### MySQL

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/mydb?useSSL=false
spring.datasource.username=root
spring.datasource.password=password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.database-platform=org.hibernate.dialect.MySQLDialect
spring.sql.init.mode=always
```

#### H2 (In-Memory)

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.username=sa
spring.datasource.password=
spring.datasource.driver-class-name=org.h2.Driver
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.h2.console.enabled=true
spring.sql.init.mode=always
```

### Initialize Database Schema (`schema.sql`)

Place this in `src/main/resources/schema.sql` for Spring Boot to execute on startup:

```sql
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT
);
```

### Key Annotations

- **`@SpringBootApplication`**: Enables auto-configuration, including `DataSource` and `JdbcTemplate`.
- **`@Autowired`**: Injects `JdbcTemplate`, `NamedParameterJdbcTemplate`, or `DataSource`.
- **`@Repository`**: Marks a data access class, enabling exception translation.
- **`@Transactional`**: Manages transactions for database operations.
    - **Attributes**:
        - `readOnly`: Set to `true` for read-only operations.
        - `rollbackOn`: Specifies exceptions that trigger rollback.

## Example: Spring JDBC Application

### Domain Class

```java
public class User {
    private Long id;
    private String name;
    private int age;

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getAge() { return age; }
    public void setAge(int age) { this.age = age; }
}
```

### Repository

```java
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public class UserRepository {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Transactional
    public void createUser(String name, int age) {
        String sql = "INSERT INTO users (name, age) VALUES (?, ?)";
        jdbcTemplate.update(sql, name, age);
    }

    public User findUserById(Long id) {
        String sql = "SELECT * FROM users WHERE id = ?";
        return jdbcTemplate.queryForObject(sql, new BeanPropertyRowMapper<>(User.class), id);
    }

    public List<User> findAllUsers() {
        String sql = "SELECT * FROM users";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(User.class));
    }

    @Transactional
    public void updateUser(Long id, String name, int age) {
        String sql = "UPDATE users SET name = ?, age = ? WHERE id = ?";
        jdbcTemplate.update(sql, name, age, id);
    }

    @Transactional
    public void deleteUser(Long id) {
        String sql = "DELETE FROM users WHERE id = ?";
        jdbcTemplate.update(sql, id);
    }
}
```

### Controller

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
    @Autowired
    private UserRepository userRepository;

    @PostMapping
    public String createUser(@RequestBody User user) {
        userRepository.createUser(user.getName(), user.getAge());
        return "User created";
    }

    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        return userRepository.findUserById(id);
    }

    @GetMapping
    public List<User> getAllUsers() {
        return userRepository.findAllUsers();
    }

    @PutMapping("/{id}")
    public String updateUser(@PathVariable Long id, @RequestBody User user) {
        userRepository.updateUser(id, user.getName(), user.getAge());
        return "User updated";
    }

    @DeleteMapping("/{id}")
    public String deleteUser(@PathVariable Long id) {
        userRepository.deleteUser(id);
        return "User deleted";
    }
}
```

### Main Application

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SpringJdbcApplication {
    public static void main(String[] args) {
        SpringApplication.run(SpringJdbcApplication.class, args);
    }
}
```

## Database-Specific Setup

### PostgreSQL

- **Driver**: `org.postgresql.Driver`
- **Dependency**: Included in the Maven example above.
- **Setup**:
    - Install PostgreSQL and create a database (`mydb`).
    - Default port: 5432.
    - Configure credentials in `application.properties`.
- **Notes**: Supports advanced features like JSONB and geospatial data.

### MySQL

- **Driver**: `com.mysql.cj.jdbc.Driver`
- **Dependency**: Included in the Maven example above.
- **Setup**:
    - Install MySQL and create a database (`mydb`).
    - Default port: 3306.
    - Use `useSSL=false` in development for simplicity.
- **Notes**: Widely used for web applications.

### H2

- **Driver**: `org.h2.Driver`
- **Dependency**: Included in the Maven example above.
- **Setup**:
    - No external setup required for in-memory mode.
    - Enable H2 console (`spring.h2.console.enabled=true`) for debugging.
- **Notes**: Ideal for testing and prototyping.

## Transactions in Spring JDBC

Spring JDBC supports transactions via:

1. **Declarative Transactions** (using `@Transactional`):

```java
@Transactional
public void createUser(String name, int age) {
    jdbcTemplate.update("INSERT INTO users (name, age) VALUES (?, ?)", name, age);
}
```

2. **Programmatic Transactions** (using `TransactionTemplate`):

```java
@Autowired
TransactionTemplate transactionTemplate;

public void createUser(String name, int age) {
    transactionTemplate.execute(status -> {
        jdbcTemplate.update("INSERT INTO users (name, age) VALUES (?, ?)", name, age);
        return null;
    });
}
```

## Benefits

- **Reduced Boilerplate**: `JdbcTemplate` eliminates manual connection and resource management.
- **Exception Translation**: Converts `SQLException` into meaningful `DataAccessException`.
- **Connection Pooling**: Auto-configured with HikariCP in Spring Boot for performance.
- **Flexibility**: Supports custom SQL for complex queries.
- **Lightweight**: No ORM overhead, ideal for simple applications.

## Limitations

- **Manual Mapping**: Requires `RowMapper` or `BeanPropertyRowMapper` for result mapping (unlike JPA’s automatic entity mapping).
- **No ORM**: Lacks advanced features like entity relationships or lazy loading.
- **SQL Injection**: Developers must use parameterized queries to avoid vulnerabilities.
- **Scalability**: Less suitable for complex applications compared to Spring Data JPA or Hibernate.

## Resources

- Spring Boot JDBC: [Spring Boot JDBC](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#data.sql.jdbc)
- Spring Framework JDBC: [Spring JDBC](https://docs.spring.io/spring-framework/docs/current/reference/html/data-access.html#jdbc)
- Database Drivers:
    - [PostgreSQL JDBC](https://jdbc.postgresql.org/)
    - [MySQL Connector/J](https://dev.mysql.com/doc/connector-j/en/)
    - [H2 Database](https://www.h2database.com/)




###### Tags : [[0 - Spring Framework]]