# Hibernate ORM

**Hibernate ORM** (Object-Relational Mapping) is a powerful, open-source Java framework that simplifies database interactions by mapping Java objects to relational database tables. It implements the **Java Persistence API (JPA)** specification and extends it with additional features, providing a robust solution for data persistence in Java applications. Hibernate eliminates much of the boilerplate code associated with raw JDBC, making it easier to perform CRUD (Create, Read, Update, Delete) operations and manage complex relationships.

This document explains Hibernate ORM in a simple and comprehensive way, covering its key concepts, components, annotations, configurations, and examples, with a focus on its use with databases like **PostgreSQL**, **MySQL**, and **H2**.

## Overview

- **Purpose**: Maps Java objects to database tables, enabling developers to work with objects instead of writing raw SQL queries.
- **Key Features**:
    - **ORM**: Maps Java classes to tables and fields to columns.
    - **JPA Compliance**: Implements the JPA standard, with additional Hibernate-specific features.
    - **Automatic SQL Generation**: Generates SQL queries based on object operations.
    - **Relationship Management**: Handles complex entity relationships (e.g., one-to-many, many-to-many).
    - **Caching**: Supports first-level and second-level caching for performance.
    - **Transaction Management**: Ensures data consistency with transactional operations.
- **Use Cases**: Building data-driven applications, such as web apps, microservices, or enterprise systems, requiring seamless database integration.

## Key Concepts

1. **Entity**: A Java class annotated with `@Entity` that maps to a database table.
2. **Session**: Hibernate’s primary interface (`org.hibernate.Session`) for database operations, similar to JPA’s `EntityManager`.
3. **SessionFactory**: A thread-safe factory for creating `Session` objects, built from configuration settings.
4. **Persistence Context**: Tracks managed entities and synchronizes changes with the database.
5. **HQL (Hibernate Query Language)**: A database-agnostic query language similar to JPQL for querying entities.
6. **Lazy/Eager Loading**: Controls when related entities are fetched from the database.
7. **Caching**: Improves performance by storing frequently accessed data.

## Key Hibernate Components

### Key Interfaces

#### 1. **Session** (`org.hibernate.Session`)

- **Purpose**: Manages persistence operations (e.g., saving, updating, querying entities).
- **Key Methods**:
    - `save(Object entity)`: Persists a new entity.
    - `update(Object entity)`: Updates an existing entity.
    - `get(Class<T> clazz, Serializable id)`: Retrieves an entity by ID.
    - `createQuery(String hql)`: Creates an HQL query.
    - `beginTransaction()`: Starts a transaction.
    - `getTransaction().commit()`: Commits a transaction.
    - `close()`: Closes the session.
- **Use Case**: Core interface for database operations (used directly or via JPA’s `EntityManager`).

#### 2. **SessionFactory** (`org.hibernate.SessionFactory`)

- **Purpose**: A thread-safe, immutable factory for creating `Session` objects.
- **Key Methods**:
    - `openSession()`: Creates a new `Session`.
    - `getCurrentSession()`: Retrieves the session bound to the current thread (in a transactional context).
- **Use Case**: Initializes Hibernate and manages sessions.

#### 3. **Query** (`org.hibernate.query.Query`)

- **Purpose**: Represents an HQL or native SQL query.
- **Key Methods**:
    - `setParameter(int position, Object value)`: Sets query parameters.
    - `getResultList()`: Returns query results as a list.
    - `getSingleResult()`: Returns a single result.
- **Use Case**: Executing HQL or SQL queries.

### Key Annotations (JPA-Based)

Hibernate uses JPA annotations, with some Hibernate-specific extensions:

- **`@Entity`**: Marks a class as a database entity.
- **`@Table(name = "table_name")`**: Specifies the database table name.
- **`@Id`**: Marks the primary key field.
- **`@GeneratedValue`**: Configures automatic ID generation (e.g., `strategy = GenerationType.IDENTITY`).
- **`@Column`**: Maps a field to a column, with attributes like `name`, `nullable`, or `length`.
- **`@OneToMany` / `@ManyToOne` / `@ManyToMany` / `@OneToOne`**: Defines relationships between entities.
- **`@JoinColumn`**: Specifies the foreign key column for relationships.
- **`@NamedQuery`**: Defines reusable JPQL/HQL queries.
- **Hibernate-Specific**:
    - **`@NaturalId`**: Marks a field as a natural identifier (non-primary key unique field).
    - **`@Type`**: Specifies custom Hibernate types for complex data.

### Utility Classes

#### 1. **Configuration** (`org.hibernate.cfg.Configuration`)

- **Purpose**: Configures Hibernate settings (e.g., database URL, dialect) and builds the `SessionFactory`.
- **Key Methods**:
    - `configure()`: Loads settings from `hibernate.cfg.xml`.
    - `addAnnotatedClass(Class<?> clazz)`: Registers an entity class.
    - `buildSessionFactory()`: Creates a `SessionFactory`.
- **Use Case**: Bootstrapping Hibernate in non-Spring applications.

#### 2. **StandardServiceRegistry** (`org.hibernate.service`)

- **Purpose**: Manages Hibernate services (e.g., connection pooling, dialect).
- **Use Case**: Internal component used by `SessionFactory`.

## Hibernate with Spring Boot

Spring Boot simplifies Hibernate usage by auto-configuring the JPA provider (Hibernate by default), `DataSource`, and `EntityManager`. It integrates with **Spring Data JPA** for repository abstractions.

### Dependencies (Maven)

```xml
<dependencies>
    <!-- Spring Boot Starter Data JPA (includes Hibernate) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
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
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

#### MySQL

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/mydb?useSSL=false
spring.datasource.username=root
spring.datasource.password=password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.database-platform=org.hibernate.dialect.MySQLDialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

#### H2 (In-Memory)

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.username=sa
spring.datasource.password=
spring.datasource.driver-class-name=org.h2.Driver
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.h2.console.enabled=true
```

### Key Spring Boot Annotations

- **`@SpringBootApplication`**: Enables auto-configuration, including Hibernate as the JPA provider.
- **`@Entity`**: Marks a class as a persistent entity.
- **`@Repository`**: Marks a Spring Data repository for data access.
- **`@Transactional`**: Manages transactions for database operations.
- **`@PersistenceContext`**: Injects an `EntityManager` for JPA operations.

## Example: Hibernate with Spring Data JPA

### Entity Class

```java
import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_name", nullable = false)
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

### Repository Interface

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByName(String name);

    @Query("SELECT u FROM User u WHERE u.age > ?1")
    List<User> findByAgeGreaterThan(int age);
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
    public User createUser(@RequestBody User user) {
        return userRepository.save(user);
    }

    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        return userRepository.findById(id).orElseThrow();
    }

    @GetMapping
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    @GetMapping("/search")
    public List<User> searchUsers(@RequestParam String name) {
        return userRepository.findByName(name);
    }
}
```

### Main Application

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class HibernateApplication {
    public static void main(String[] args) {
        SpringApplication.run(HibernateApplication.class, args);
    }
}
```

## Example: Hibernate with Raw JPA (No Spring Data)

### Hibernate Configuration (`hibernate.cfg.xml`)

```xml
<!DOCTYPE hibernate-configuration PUBLIC
    "-//Hibernate/Hibernate Configuration DTD 3.0//EN"
    "http://www.hibernate.org/dtd/hibernate-configuration-3.0.dtd">
<hibernate-configuration>
    <session-factory>
        <property name="hibernate.connection.url">jdbc:h2:mem:testdb</property>
        <property name="hibernate.connection.username">sa</property>
        <property name="hibernate.connection.password"></property>
        <property name="hibernate.dialect">org.hibernate.dialect.H2Dialect</property>
        <property name="hibernate.hbm2ddl.auto">create-drop</property>
        <property name="show_sql">true</property>
        <mapping class="com.example.User"/>
    </session-factory>
</hibernate-configuration>
```

### Hibernate Code

```java
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.cfg.Configuration;

public class HibernateExample {
    public static void main(String[] args) {
        // Build SessionFactory
        SessionFactory factory = new Configuration()
                .configure("hibernate.cfg.xml")
                .addAnnotatedClass(User.class)
                .buildSessionFactory();

        // Open Session
        try (Session session = factory.openSession()) {
            session.beginTransaction();

            // Save a user
            User user = new User();
            user.setName("Alice");
            user.setAge(30);
            session.save(user);

            // Query a user
            User retrieved = session.get(User.class, 1L);
            System.out.println(retrieved.getName()); // Output: Alice

            session.getTransaction().commit();
        } finally {
            factory.close();
        }
    }
}
```

## Database-Specific Setup

### PostgreSQL

- **Driver**: `org.postgresql.Driver`
- **Dependency**:

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.7.4</version>
</dependency>
```

- **Configuration**:
    - URL: `jdbc:postgresql://localhost:5432/mydb`
    - Dialect: `org.hibernate.dialect.PostgreSQLDialect`
- **Notes**: Supports advanced features like JSONB and geospatial data.

### MySQL

- **Driver**: `com.mysql.cj.jdbc.Driver`
- **Dependency**:

```xml
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.33</version>
</dependency>
```

- **Configuration**:
    - URL: `jdbc:mysql://localhost:3306/mydb?useSSL=false`
    - Dialect: `org.hibernate.dialect.MySQLDialect`
- **Notes**: Ensure `useSSL=false` for non-SSL connections in development.

### H2

- **Driver**: `org.h2.Driver`
- **Dependency**:

```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <version>2.3.230</version>
</dependency>
```

- **Configuration**:
    - URL: `jdbc:h2:mem:testdb` (in-memory) or `jdbc:h2:~/testdb` (file-based)
    - Dialect: `org.hibernate.dialect.H2Dialect`
- **Notes**: Ideal for testing and prototyping; supports in-memory mode and web console.

## Hibernate-Specific Features

- **Second-Level Cache**: Caches entities across sessions for performance (e.g., using EHCache).
- **Criteria API**: Programmatic query building for dynamic queries.
- **Natural IDs**: Unique identifiers other than primary keys (`@NaturalId`).
- **Interceptors**: Custom logic for entity lifecycle events.
- **Lazy Loading**: Fetches related entities only when needed (`fetch = FetchType.LAZY`).

## Benefits

- **Reduced Boilerplate**: Simplifies database operations compared to raw JDBC.
- **JPA Compliance**: Portable across JPA providers (e.g., Hibernate, EclipseLink).
- **Relationship Management**: Handles complex entity relationships seamlessly.
- **Caching**: Improves performance with first-level and second-level caching.
- **Spring Integration**: Works well with Spring Boot and Spring Data JPA.

## Limitations

- **Performance Overhead**: ORM can be slower than raw SQL for complex queries.
- **Learning Curve**: Requires understanding JPA/Hibernate annotations and concepts.
- **N+1 Problem**: Improperly configured relationships can lead to multiple queries.
- **Complexity**: Advanced features like caching or interceptors require careful configuration.

## Resources

- Hibernate Documentation: [Hibernate ORM](https://hibernate.org/orm/documentation/)
- Spring Data JPA: [Spring Data JPA](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)
- JPA Specification: [Jakarta Persistence](https://jakarta.ee/specifications/persistence/)


[[Java]]