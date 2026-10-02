**Java Database Connectivity (JDBC)** is a standard Java API for connecting to and interacting with relational databases. It provides a way to execute SQL queries, retrieve results, and manage database connections in a platform-independent manner. This guide explains JDBC concepts in a simple way, focusing on its use with **PostgreSQL**, **H2**, and **MySQL** databases, including necessary configurations, annotations, and examples.

---
## Overview

- **Purpose**: Enables Java applications to connect to relational databases, execute SQL queries, and process results.
- **Key Features**:
    - **Database Agnostic**: Works with any database providing a JDBC driver (e.g., PostgreSQL, MySQL, H2).
    - **SQL Execution**: Supports queries, updates, and stored procedures.
    - **Connection Management**: Handles database connections, statements, and result sets.
    - **Transaction Support**: Allows committing or rolling back database changes.
- **Use Cases**: Building data-driven applications, performing CRUD operations, and integrating with relational databases.

## Key JDBC Concepts

1. **JDBC Driver**: A database-specific library that translates JDBC calls into database commands. Each database (PostgreSQL, MySQL, H2) requires its own driver.
2. **Connection**: A session with the database, established via a URL, username, and password.
3. **Statement**: Executes SQL queries (e.g., `Statement`, `PreparedStatement`).
4. **ResultSet**: Holds the results of a query for processing.
5. **Transaction**: A group of SQL operations executed as a single unit, with commit or rollback.

## Key JDBC Components

### Key Interfaces and Classes

#### 1. **DriverManager** (`java.sql`)

- **Purpose**: Manages database connections by loading JDBC drivers and creating connections.
- **Key Methods**:
    - `getConnection(String url, String user, String password)`: Establishes a database connection.
- **Example**:

```java
Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/mydb", "root", "password");
```

#### 2. **Connection** (`java.sql.Connection`)

- **Purpose**: Represents a database session for executing SQL statements.
- **Key Methods**:
    - `createStatement()`: Creates a `Statement` object for SQL queries.
    - `prepareStatement(String sql)`: Creates a `PreparedStatement` for parameterized queries.
    - `setAutoCommit(boolean autoCommit)`: Enables/disables auto-commit for transactions.
    - `commit()`: Commits a transaction.
    - `rollback()`: Rolls back a transaction.
    - `close()`: Closes the connection.
- **Use Case**: Managing database interactions and transactions.

#### 3. **Statement** (`java.sql.Statement`)

- **Purpose**: Executes static SQL queries.
- **Key Methods**:
    - `executeQuery(String sql)`: Executes a SELECT query, returns a `ResultSet`.
    - `executeUpdate(String sql)`: Executes INSERT, UPDATE, or DELETE queries, returns the number of affected rows.
    - `execute(String sql)`: Executes any SQL statement, returns a boolean indicating result type.
- **Use Case**: Simple, non-parameterized queries.
- **Note**: Vulnerable to SQL injection; prefer `PreparedStatement` for dynamic queries.

#### 4. **PreparedStatement** (`java.sql.PreparedStatement`)

- **Purpose**: Executes parameterized SQL queries, improving security and performance.
- **Key Methods**:
    - `setInt(int parameterIndex, int value)`: Sets an integer parameter.
    - `setString(int parameterIndex, String value)`: Sets a string parameter.
    - `executeQuery()`: Executes a SELECT query.
    - `executeUpdate()`: Executes an INSERT, UPDATE, or DELETE query.
- **Use Case**: Secure queries with user input.
- **Example**:

```java
PreparedStatement ps = conn.prepareStatement("SELECT * FROM users WHERE id = ?");
ps.setInt(1, 1);
ResultSet rs = ps.executeQuery();
```

#### 5. **ResultSet** (`java.sql.ResultSet`)

- **Purpose**: Represents the results of a database query.
- **Key Methods**:
    - `next()`: Moves to the next row, returns false if no more rows.
    - `getInt(String columnLabel)`: Retrieves an integer column value.
    - `getString(String columnLabel)`: Retrieves a string column value.
    - `close()`: Closes the result set.
- **Use Case**: Processing query results.
- **Example**:

```java
while (rs.next()) {
    System.out.println(rs.getString("name"));
}
```

### Utility Classes

#### 1. **DataSource** (`javax.sql.DataSource`)

- **Purpose**: A factory for database connections, often used in Spring or connection pools.
- **Key Methods**:
    - `getConnection()`: Returns a database connection.
- **Use Case**: Preferred over `DriverManager` for enterprise applications with connection pooling.
- **Example** (with Spring):

```java
@Autowired
DataSource dataSource;
Connection conn = dataSource.getConnection();
```

#### 2. **SQLException** (`java.sql`)

- **Purpose**: Handles database-related errors.
- **Key Methods**:
    - `getSQLState()`: Returns the SQL state code.
    - `getErrorCode()`: Returns the database-specific error code.
- **Use Case**: Error handling for JDBC operations.

## JDBC with PostgreSQL, MySQL, and H2

Each database requires a specific JDBC driver, connection URL, and configuration. Below are details for **PostgreSQL**, **MySQL**, and **H2**.

### 1. **PostgreSQL**

- **JDBC Driver**: `org.postgresql.Driver`
- **Maven Dependency**:

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.7.4</version>
</dependency>
```

- **Connection URL**: `jdbc:postgresql://host:port/database`
    - Example: `jdbc:postgresql://localhost:5432/mydb`
- **Configuration**:
    - Ensure PostgreSQL is running (default port: 5432).
    - Create a database (e.g., `mydb`) and user with credentials.
- **Example**:

```java
Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/mydb", "postgres", "password");
```

### 2. **MySQL**

- **JDBC Driver**: `com.mysql.cj.jdbc.Driver`
- **Maven Dependency**:

```xml
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.33</version>
</dependency>
```

- **Connection URL**: `jdbc:mysql://host:port/database`
    - Example: `jdbc:mysql://localhost:3306/mydb`
- **Configuration**:
    - Ensure MySQL is running (default port: 3306).
    - Create a database (e.g., `mydb`) and user with credentials.
- **Example**:

```java
Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/mydb?useSSL=false", "root", "password");
```

### 3. **H2 (In-Memory Database)**

- **JDBC Driver**: `org.h2.Driver`
- **Maven Dependency**:

```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <version>2.3.230</version>
</dependency>
```

- **Connection URL**:
    - In-memory: `jdbc:h2:mem:testdb`
    - File-based: `jdbc:h2:~/testdb`
- **Configuration**:
    - H2 is lightweight, ideal for testing or development.
    - No external server setup required for in-memory mode.
- **Example**:

```java
Connection conn = DriverManager.getConnection("jdbc:h2:mem:testdb", "sa", "");
```

## Spring Boot Integration with JDBC

Spring Boot simplifies JDBC usage by providing auto-configuration, connection pooling, and the `JdbcTemplate` utility class. Below is how to configure and use JDBC with Spring Boot for PostgreSQL, MySQL, and H2.

### Spring Boot Dependencies

Add the following to `pom.xml`:

```xml
<dependencies>
    <!-- Spring Boot Starter JDBC -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-jdbc</artifactId>
    </dependency>
    <!-- Database-specific driver (choose one or more) -->
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

### Spring Boot Configuration (`application.properties`)

Configure the database connection in `src/main/resources/application.properties`:

#### PostgreSQL

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=postgres
spring.datasource.password=password
spring.datasource.driver-class-name=org.postgresql.Driver
spring.jdbc.database-platform=org.hibernate.dialect.PostgreSQLDialect
```

#### MySQL

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/mydb?useSSL=false
spring.datasource.username=root
spring.datasource.password=password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jdbc.database-platform=org.hibernate.dialect.MySQLDialect
```

#### H2 (In-Memory)

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.username=sa
spring.datasource.password=
spring.datasource.driver-class-name=org.h2.Driver
spring.jdbc.database-platform=org.hibernate.dialect.H2Dialect
spring.h2.console.enabled=true
```

### Key Spring Boot Annotations

- **`@SpringBootApplication`**: Marks the main application class, enabling auto-configuration.
- **`@Autowired`**: Injects dependencies like `JdbcTemplate` or `DataSource`.
- **`@Repository`**: Marks a class as a data access component, enabling exception translation.
- **`@Transactional`**: Manages transactions for database operations.

### Using JdbcTemplate

Spring Boot’s `JdbcTemplate` simplifies JDBC operations by handling connection management, exception translation, and query execution.

- **Key Methods**:
    
    - `query(String sql, RowMapper<T> rowMapper)`: Executes a SELECT query and maps results to objects.
    - `queryForObject(String sql, Class<T> requiredType, Object... args)`: Retrieves a single object.
    - `update(String sql, Object... args)`: Executes INSERT, UPDATE, or DELETE queries.
    - `execute(String sql)`: Executes any SQL statement.
- **Example** (User DAO with JdbcTemplate):
    

```java
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.jdbc.core.BeanPropertyRowMapper;

@Repository
public class UserDao {
    @Autowired
    private JdbcTemplate jdbcTemplate;

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
}
```

### Example: Complete Spring Boot JDBC Application

#### User Class

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

#### Repository (UserDao)

```java
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.jdbc.core.BeanPropertyRowMapper;

@Repository
public class UserDao {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    public void createTable() {
        String sql = "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(100), age INT)";
        jdbcTemplate.execute(sql);
    }

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
}
```

#### Controller

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
    @Autowired
    private UserDao userDao;

    @PostMapping
    public String createUser(@RequestBody User user) {
        userDao.createUser(user.getName(), user.getAge());
        return "User created";
    }

    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        return userDao.findUserById(id);
    }

    @GetMapping
    public List<User> getAllUsers() {
        return userDao.findAllUsers();
    }
}
```

#### Main Application

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.beans.factory.annotation.Autowired;
import javax.annotation.PostConstruct;

@SpringBootApplication
public class JdbcApplication {
    @Autowired
    private UserDao userDao;

    @PostConstruct
    public void init() {
        userDao.createTable(); // Initialize table
    }

    public static void main(String[] args) {
        SpringApplication.run(JdbcApplication.class, args);
    }
}
```

### Database-Specific Setup

#### PostgreSQL

- **Setup**: Install PostgreSQL, create a database (`mydb`), and configure credentials.
- **Connection URL**: `jdbc:postgresql://localhost:5432/mydb`.
- **Notes**: Supports advanced features like JSONB and geospatial data.

#### MySQL

- **Setup**: Install MySQL, create a database (`mydb`), and configure credentials.
- **Connection URL**: `jdbc:mysql://localhost:3306/mydb?useSSL=false`.
- **Notes**: Ensure the `useSSL=false` parameter for non-SSL connections in development.

#### H2

- **Setup**: No external setup required for in-memory mode. Enable H2 console for debugging (`spring.h2.console.enabled=true`).
- **Connection URL**: `jdbc:h2:mem:testdb`.
- **Notes**: Ideal for testing and prototyping due to its in-memory nature.

## Transactions in JDBC

JDBC supports transactions to ensure data consistency:

- **Steps**:
    1. Disable auto-commit: `conn.setAutoCommit(false);`
    2. Execute SQL statements.
    3. Commit or rollback: `conn.commit()` or `conn.rollback()`.
- **Example**:

```java
Connection conn = DriverManager.getConnection("jdbc:h2:mem:testdb", "sa", "");
conn.setAutoCommit(false);
try {
    PreparedStatement ps = conn.prepareStatement("INSERT INTO users (name, age) VALUES (?, ?)");
    ps.setString(1, "Alice");
    ps.setInt(2, 30);
    ps.executeUpdate();
    conn.commit();
} catch (SQLException e) {
    conn.rollback();
} finally {
    conn.setAutoCommit(true);
    conn.close();
}
```

- **Spring Boot Transactions**: Use `@Transactional` for automatic transaction management:

```java
@Transactional
public void createUser(String name, int age) {
    jdbcTemplate.update("INSERT INTO users (name, age) VALUES (?, ?)", name, age);
}
```

## Benefits

- **Portability**: Works with any JDBC-compliant database (PostgreSQL, MySQL, H2, etc.).
- **Flexibility**: Direct SQL control for custom queries.
- **Spring Integration**: `JdbcTemplate` simplifies JDBC operations and connection management.
- **Lightweight**: No ORM overhead, suitable for simple applications.

## Limitations

- **Boilerplate Code**: Raw JDBC requires manual connection and resource management (mitigated by `JdbcTemplate`).
- **SQL Injection**: `Statement` is vulnerable; always use `PreparedStatement` for dynamic queries.
- **Complexity**: Manual mapping of `ResultSet` to objects (mitigated by `RowMapper` in Spring).
- **No ORM**: Lacks object-relational mapping features like JPA (e.g., entity relationships).

## Resources

- Oracle Documentation: [JDBC API](https://docs.oracle.com/en/java/javase/17/docs/api/java.sql/module-summary.html)
- Spring Boot JDBC: [Spring Boot JDBC](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#data.sql.jdbc)
- Database Drivers:
    - [PostgreSQL JDBC](https://jdbc.postgresql.org/)
    - [MySQL Connector/J](https://dev.mysql.com/doc/connector-j/en/)
    - [H2 Database](https://www.h2database.com/)



#### Tags : [[Java]] 