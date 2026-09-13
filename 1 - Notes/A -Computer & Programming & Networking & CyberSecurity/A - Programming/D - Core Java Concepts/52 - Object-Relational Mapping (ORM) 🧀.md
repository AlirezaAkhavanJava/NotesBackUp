**Object-Relational Mapping (ORM)** is a programming technique that bridges the gap between object-oriented programming (OOP) and relational databases. It maps Java objects to database tables, allowing developers to interact with databases using object-oriented code instead of writing raw SQL queries. In Java, ORM is typically implemented through frameworks like **Hibernate**, **EclipseLink**, or **Spring Data JPA**, which use the **Java Persistence API (JPA)** as a standard.

---
## Overview

- **Purpose**: Simplifies database interactions by representing database tables as Java objects and their relationships as object associations, reducing the need for manual SQL.
- **Key Features**:
    - Maps Java classes to database tables and fields to columns.
    - Handles CRUD (Create, Read, Update, Delete) operations using objects.
    - Manages relationships (e.g., one-to-many, many-to-one) between entities.
    - Supports transactions, lazy/eager loading, and query generation.
- **Use Cases**: Building data-driven applications, such as web apps, microservices, or enterprise systems, where database operations need to integrate seamlessly with Java code.

## Key Concepts

1. **Entity**: A Java class annotated with `@Entity` that maps to a database table.
2. **Fields/Attributes**: Class fields that map to table columns, often annotated with `@Column`.
3. **Primary Key**: A unique identifier for an entity, marked with `@Id`.
4. **Relationships**: Associations between entities (e.g., `@OneToMany`, `@ManyToOne`) that mirror foreign key relationships in the database.
5. **Entity Manager**: A JPA component that manages entity lifecycle (persisting, updating, querying).
6. **Persistence Context**: Tracks managed entities and synchronizes changes with the database.
7. **JPQL (Java Persistence Query Language)**: A query language for querying entities, similar to SQL but object-oriented.

## Key Components in Java ORM (JPA-Based)

### 1. **Entity Classes**

- **Purpose**: Represent database tables as Java objects.
- **Key Annotations**:
    - `@Entity`: Marks a class as a database entity.
    - `@Table(name = "table_name")`: Specifies the table name.
    - `@Id`: Marks the primary key field.
    - `@GeneratedValue`: Configures automatic ID generation (e.g., `AUTO`, `IDENTITY`).
    - `@Column`: Maps a field to a column, with attributes like `name`, `nullable`, or `length`.
- **Example**:

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

### 2. **Relationships**

- **Purpose**: Define associations between entities, mirroring database foreign key relationships.
- **Key Annotations**:
    - `@OneToOne`: One entity instance relates to one instance of another entity.
    - `@OneToMany` / `@ManyToOne`: One entity relates to multiple instances, or vice versa.
    - `@ManyToMany`: Multiple instances relate to multiple instances, typically using a join table.
    - `@JoinColumn`: Specifies the foreign key column.
- **Example (One-to-Many)**:

```java
@Entity
public class Department {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @OneToMany(mappedBy = "department")
    private List<User> users;

    // Getters and setters
}

@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @ManyToOne
    @JoinColumn(name = "department_id")
    private Department department;

    // Getters and setters
}
```

### 3. **EntityManager**

- **Purpose**: Manages entity lifecycle, including persisting, updating, querying, and removing entities.
- **Key Methods**:
    - `persist(Object entity)`: Saves a new entity to the database.
    - `merge(Object entity)`: Updates an existing entity.
    - `find(Class<T> entityClass, Object id)`: Retrieves an entity by ID.
    - `remove(Object entity)`: Deletes an entity.
    - `createQuery(String jpql)`: Creates a JPQL query.
- **Use Case**: Direct JPA operations (often abstracted by Spring Data JPA).
- **Example**:

```java
@PersistenceContext
EntityManager em;

public void saveUser(User user) {
    em.persist(user);
}
```

### 4. **Persistence Unit**

- **Purpose**: Configures the database connection and JPA provider (e.g., Hibernate) in a `persistence.xml` file or Spring Boot configuration.
- **Example (Spring Boot `application.properties`)**:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/mydb
spring.datasource.username=root
spring.datasource.password=password
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

## ORM Frameworks in Java

- **Hibernate**: The most popular JPA implementation, providing advanced features like caching and lazy loading.
- **EclipseLink**: Another JPA provider, often used in enterprise applications.
- **Spring Data JPA**: A Spring module that simplifies JPA usage with repository abstractions (extends `CrudRepository` or `JpaRepository`).
- **Other Frameworks**: OpenJPA, DataNucleus (less common).

## Example: ORM with Spring Data JPA

### Entity

```java
import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private int age;

    // Getters and setters
}
```

### Repository

```java
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByName(String name);
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
}
```

### Configuration (`application.properties`)

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/mydb
spring.datasource.username=root
spring.datasource.password=password
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

## Benefits

- **Simplified Code**: Replaces raw SQL with object-oriented operations.
- **Portability**: Works across different databases (e.g., MySQL, PostgreSQL) with minimal changes.
- **Relationships**: Easily manages complex entity relationships.
- **Productivity**: Reduces boilerplate code, especially with Spring Data JPA.
- **Maintainability**: Encourages clean, object-oriented data access.

## Limitations

- **Performance Overhead**: ORM can be slower than raw SQL for complex queries.
- **Learning Curve**: Requires understanding JPA annotations and ORM concepts.
- **N+1 Problem**: Improperly configured relationships can lead to multiple database queries.
- **Abstraction Leak**: May require native SQL for complex or performance-critical operations.

## Resources

- JPA Specification: [Jakarta Persistence](https://jakarta.ee/specifications/persistence/)
- Hibernate Documentation: [Hibernate ORM](https://hibernate.org/orm/documentation/)
- Spring Data JPA: [Spring Data JPA](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)

[[Java]]