## Core Concepts

### What is a Repository?

A repository is a component that abstracts and manages data persistence tasks. Its primary purpose is to **decouple data access logic from the business logic**, making your application more modular and easier to maintain. Repositories work directly with **entities**, which are plain Java objects that represent database tables.

### Types of Repositories

- **`CrudRepository`**: Provides fundamental CRUD (Create, Read, Update, Delete) operations. This is your go-to for basic database interactions.
    
- **`JpaRepository`**: Extends `CrudRepository` and adds more features specific to the **Java Persistence API (JPA)**, such as flushing the persistence context and batch deletion.
    
- **`PagingAndSortingRepository`**: Extends `CrudRepository` to support paginating and sorting results, which is essential for handling large datasets efficiently.
    

### Key Annotations

- **`@Repository`**: This annotation marks an interface as a repository, allowing Spring to automatically detect and manage it as a bean.
    
- **`@Query`**: Used to define custom database queries using JPQL (Java Persistence Query Language) or native SQL, especially for more complex operations.
    
- **`@Transactional`**: Although often used in service layers, this annotation ensures that a method's database operations are executed as a single, atomic unit.
    

### Query Methods

A powerful feature of Spring Data is **derived query methods**. You can simply define a method with a specific name (e.g., `findByLastName`) and Spring will automatically generate the appropriate database query for you. For more intricate queries, the `@Query` annotation gives you full control.

### Pagination and Sorting

For applications dealing with a large volume of data, **pagination** is crucial for performance. It allows you to fetch data in small, manageable chunks ("pages"). **Sorting** lets you order the results, for example, by name, date, or any other field.

---

## How to Use Spring Boot Repositories

### Step 1: Add Dependencies

First, include the necessary dependencies in your project, such as **Spring Data JPA** and a database like **H2** for in-memory testing.

XML

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

Next, configure your database connection in `application.properties`:

Properties

```
# Add to application.properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
```

---

### Step 2: Create an Entity

Define a Java class that will be mapped to a database table. Use the `@Entity` annotation to mark it as a JPA entity and `@Id` to specify the primary key.

Java

```
import jakarta.persistence.Entity;
import jakarta.persistence.Id;

@Entity
public class User {
    @Id
    private Long id;
    private String firstName;
    private String lastName;
    private String email;

    // Getters and setters
}
```

---

### Step 3: Create a Repository Interface

Create an interface that extends `JpaRepository` and specify the entity type and the primary key's data type. You can also add your own derived query methods or custom `@Query` methods here.

Java

```
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByLastName(String lastName);

    @Query("SELECT u FROM User u WHERE u.email = :email")
    User findByEmail(@Param("email") String email);
}
```

---

### Step 4: Use the Repository in a Service

Inject the repository into your service layer to perform data operations. This is where you would typically handle business logic and call the repository's methods to save, find, or delete data.

Java

```
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found"));
    }

    public User saveUser(User user) {
        return userRepository.save(user);
    }
}
```

---

### Step 5: Test the Repository

It's a good practice to write tests for your repositories to ensure they work as expected. The `@DataJpaTest` annotation is useful for this, as it configures an in-memory database and other components needed for testing JPA.

Java

```
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest
class UserRepositoryTest {
    @Autowired
    private UserRepository userRepository;

    @Test
    void testFindByLastName() {
        User user = new User();
        user.setId(1L);
        user.setFirstName("John");
        user.setLastName("Doe");
        user.setEmail("john.doe@example.com");

        userRepository.save(user);

        List<User> users = userRepository.findByLastName("Doe");

        assertFalse(users.isEmpty());
        assertEquals("John", users.get(0).getFirstName());
    }
}
```

---

### Step 6: Add Pagination (Optional)

To handle large result sets, you can use **`Pageable`** with the `findAll` method to retrieve data in pages.

Java

```
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

public Page<User> getUsersPaginated(int page, int size) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("lastName"));
    return userRepository.findAll(pageable);
}
```

---

## Best Practices

- **Separate Concerns**: Keep repositories focused solely on data access. Business logic belongs in services.
    
- **Use Clear Method Names**: Name your query methods logically (e.g., `findByEmail`, `findAllByStatus`).
    
- **Index Frequently Queried Fields**: Ensure your database has indexes on columns used in `WHERE` clauses for faster queries.
    
- **One Repository per Entity**: A common pattern is to create a dedicated repository interface for each entity (e.g., `UserRepository`, `OrderRepository`).
    

---

## Project Structure

A well-structured project is key to maintainability. A typical Spring Boot project can be organized into the following packages:

- **`controllers`**: Handles incoming HTTP requests.
    
- **`services`**: Contains the core business logic.
    
- **`repositories`**: Manages all database-related operations.
    
- **`models`**: Defines the entity classes that map to database tables.
    

---

## Resources

- **Spring Data JPA Documentation**: The official guide for detailed information.
    
- **Baeldung**: A great resource for practical tutorials and examples.
    
- **Spring Guides**: Official getting-started guides for data access with JPA.
    

---

## Tags

[[0 - Spring Framework]]