## Overview

**Spring Data JPA** is a module of the Spring Framework that simplifies database operations by providing a high-level abstraction over JPA (Jakarta Persistence API). *It reduces boilerplate code for common CRUD (Create, Read, Update, Delete) operations and supports custom queries through repositories.*

**Hibernate** is a popular JPA provider that handles **Object-Relational Mapping (ORM)**, mapping Java objects to database tables and abstracting low-level JDBC (Java Database Connectivity) operations. *Spring Data JPA uses Hibernate under the hood to manage database interactions.*

**Why Use Spring Data JPA and Hibernate?**

- Simplifies database access with repository interfaces, eliminating manual JDBC code.
- Provides ORM to map Java objects to database tables seamlessly.
- Reduces boilerplate code for CRUD operations and queries.
- Supports advanced features like pagination, custom queries, and auditing.


**Prerequisites**:

- Basic SQL (e.g., `SELECT`, `INSERT`, `UPDATE`, `DELETE`).
- Understanding of JDBC basics (`Connection`, `PreparedStatement`) to appreciate Hibernate’s abstractions.

**Practice Goal**: Build a Spring Boot application to persist and retrieve `Todo` entities in a database using Spring Data JPA and Hibernate, including a custom query with `@Query`.

---

JPA primarily uses **JPQL (Java Persistence Query Language)** for custom queries.

- **JPQL is object-oriented**: you query **entities and their fields**, not database tables and columns.
    
- The syntax looks like SQL, but it operates on the **entity model**.
    

Example:

```sql
@Query("SELECT s FROM Students s WHERE s.name = :name")
List<Students> findByName(@Param("name") String name);

```

- `Students` → the entity class
    
- `s.name` → the entity field, **not the table column**
    

You **can also use native SQL** with `@Query(nativeQuery = true)` if you need to run database-specific queries.
1. **`s`**  
    In JPQL, when you write:
    

`SELECT s FROM Students s WHERE s.name = :name`

- `Students` → the **entity class**
    
- `s` → a **variable/alias** for the entity, just like in SQL you do `SELECT * FROM students s`
    
- You use `s` to refer to the entity’s fields: `s.name`, `s.country`, etc.
    

It’s purely an **alias** to avoid writing the full entity name every time.


2. **`@Param`**  
    In JPQL, you can pass **method parameters** into the query. The syntax `:name` is a **named parameter**.
    

```java
@Query("SELECT s FROM Students s WHERE s.name = :name") 
List<Students> findByName(@Param("name") String name);
```

- `:name` → placeholder in the query
    
- `@Param("name")` → tells Spring which method parameter to bind to `:name`
    

Without `@Param`, Spring won’t know which Java variable goes into the JPQL parameter.

✅ In short:

- `s` = alias for entity
    
- `@Param` = links method parameter to query placeholder
---
## Understanding JDBC Basics

JDBC is Java’s standard API for database connectivity. It requires manual handling of database connections, statements, and result sets, which Hibernate abstracts.

**JDBC Example (Manual Approach)**:

```java
Connection conn = DriverManager.getConnection("jdbc:h2:mem:testdb", "sa", "");
PreparedStatement stmt = conn.prepareStatement("SELECT * FROM todos WHERE id = ?");
stmt.setLong(1, 1L);
ResultSet rs = stmt.executeQuery();
while (rs.next()) {
    System.out.println("Todo: " + rs.getString("title"));
}
stmt.close();
conn.close();
```

**Drawbacks of JDBC**:

- Boilerplate code for connection management.
- Manual mapping of database rows to Java objects.
- Error-prone SQL string manipulation.

**Hibernate’s Abstraction**:

- Maps Java objects (`@Entity`) to database tables.
- Handles SQL generation and database connections.
- Provides a higher-level API for queries and transactions.

---

## Setting Up Spring Data JPA with Hibernate

### 1. Project Setup

Create a Spring Boot project with Maven, adding dependencies for Spring Data JPA and an in-memory database (H2) for simplicity.

#### `pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>todo-app</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

### 2. Configure Database

Configure the H2 database in `src/main/resources/application.properties`.

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
spring.h2.console.enabled=true
```

**Notes**:

- `spring.jpa.hibernate.ddl-auto=update`: Automatically creates/updates tables based on entities.
- `spring.h2.console.enabled=true`: Enables H2’s web console at `http://localhost:8080/h2-console`.

---

## Building the Todo Application

### Project Structure

```
todo-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   ├── com/example/
│   │   │   │   ├── TodoApplication.java
│   │   │   │   ├── model/
│   │   │   │   │   ├── Todo.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── TodoRepository.java
│   │   │   │   ├── controller/
│   │   │   │   │   ├── TodoController.java
│   ├── resources/
│   │   ├── application.properties
├── pom.xml
```

### 1. Entity Class (`Todo.java`)

Define the `Todo` entity to map to a database table.

```java
package com.example.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Todo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    private boolean completed;

    // Default constructor for JPA
    public Todo() {}

    public Todo(String title, boolean completed) {
        this.title = title;
        this.completed = completed;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public boolean isCompleted() { return completed; }
    public void setCompleted(boolean completed) { this.completed = completed; }
}
```

**Annotations**:

- `@Entity`: Marks the class as a JPA entity.
- `@Id` and `@GeneratedValue`: Define the primary key with auto-increment.

### 2. Repository (`TodoRepository.java`)

Create a repository interface extending `JpaRepository` for CRUD operations.

```java
package com.example.repository;

import com.example.model.Todo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface TodoRepository extends JpaRepository<Todo, Long> {
    // Custom query using @Query
    @Query("SELECT t FROM Todo t WHERE t.completed = :completed")
    List<Todo> findByCompletedStatus(boolean completed);
}
```

**Key Points**:

- `JpaRepository<Todo, Long>`: Provides built-in methods like `save()`, `findById()`, `findAll()`, `deleteById()`.
- `@Query`: Defines a custom JPQL (Java Persistence Query Language) query to find todos by completion status.

### 3. Controller (`TodoController.java`)

Create a REST controller to handle HTTP requests.

```java
package com.example.controller;

import com.example.model.Todo;
import com.example.repository.TodoRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/todos")
public class TodoController {
    private final TodoRepository todoRepository;

    public TodoController(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @PostMapping
    public ResponseEntity<Todo> createTodo(@RequestBody Todo todo) {
        Todo savedTodo = todoRepository.save(todo);
        return new ResponseEntity<>(savedTodo, HttpStatus.CREATED);
    }

    @GetMapping
    public List<Todo> getAllTodos() {
        return todoRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Todo> getTodoById(@PathVariable Long id) {
        return todoRepository.findById(id)
                .map(todo -> new ResponseEntity<>(todo, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @GetMapping("/completed/{status}")
    public List<Todo> getTodosByCompletedStatus(@PathVariable boolean status) {
        return todoRepository.findByCompletedStatus(status);
    }
}
```

**Key Points**:

- `@RestController`: Marks the class as a REST controller.
- `@RequestMapping("/api/todos")`: Base URL for all endpoints.
- Uses `TodoRepository` for database operations.
- `@Query` method `findByCompletedStatus` is exposed via `/api/todos/completed/{status}`.

### 4. Main Application (`TodoApplication.java`)

```java
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TodoApplication {
    public static void main(String[] args) {
        SpringApplication.run(TodoApplication.class, args);
    }
}
```

---

## Running and Testing the Application

### 1. Run the Application

```bash
mvn spring-boot:run
```

### 2. Test with Postman or cURL

- **Create a Todo (POST)**:
    
    ```bash
    curl -X POST http://localhost:8080/api/todos \
    -H "Content-Type: application/json" \
    -d '{"title":"Learn Spring Data JPA","completed":false}'
    ```
    
    **Response** (HTTP 201):
    
    ```json
    {
        "id": 1,
        "title": "Learn Spring Data JPA",
        "completed": false
    }
    ```
    
- **Get All Todos (GET)**:
    
    ```bash
    curl http://localhost:8080/api/todos
    ```
    
    **Response** (HTTP 200):
    
    ```json
    [
        {
            "id": 1,
            "title": "Learn Spring Data JPA",
            "completed": false
        }
    ]
    ```
    
- **Get Todo by ID (GET)**:
    
    ```bash
    curl http://localhost:8080/api/todos/1
    ```
    
    **Response** (HTTP 200):
    
    ```json
    {
        "id": 1,
        "title": "Learn Spring Data JPA",
        "completed": false
    }
    ```
    
- **Get Completed Todos (Custom Query)**:
    
    ```bash
    curl http://localhost:8080/api/todos/completed/true
    ```
    
    **Response** (HTTP 200):
    
    ```json
    []
    ```
    

### 3. Access H2 Console

- URL: `http://localhost:8080/h2-console`
- JDBC URL: `jdbc:h2:mem:testdb`
- Username: `sa`
- Password: (empty)
- Verify the `todos` table and data.

---

## How Hibernate Abstracts JDBC

- **Entity Mapping**: Hibernate maps `Todo` to the `todos` table, handling column mappings (`id`, `title`, `completed`).
- **Connection Management**: Hibernate manages database connections via a connection pool (provided by Spring Boot).
- **SQL Generation**: Hibernate generates SQL queries (e.g., `INSERT INTO todos ...`) based on entity operations.
- **Transaction Management**: Spring Data JPA wraps repository methods in transactions by default.
- **Query Abstraction**: `@Query` or method naming conventions (e.g., `findByCompleted`) translate to SQL queries.

**Example (Hibernate-Generated SQL for `save`)**:

```sql
INSERT INTO todos (title, completed) VALUES ('Learn Spring Data JPA', false);
```

---

## Advanced Spring Data JPA Features

1. **Derived Queries**:  
    Define queries using method names:
    
    ```java
    List<Todo> findByTitleContainingIgnoreCase(String keyword);
    ```
    
2. **Pagination**:  
    Use `Pageable` for paginated results:
    
    ```java
    Page<Todo> findAll(Pageable pageable);
    ```
    
    Example usage in controller:
    
    ```java
    @GetMapping("/page")
    public Page<Todo> getTodosPaged(@RequestParam int page, @RequestParam int size) {
        return todoRepository.findAll(PageRequest.of(page, size));
    }
    ```
    
3. **Auditing**:  
    Enable auditing for tracking creation/modification dates:
    
    ```java
    @Entity
    @EntityListeners(AuditingEntityListener.class)
    public class Todo {
        @CreatedDate
        private LocalDateTime createdAt;
        @LastModifiedDate
        private LocalDateTime updatedAt;
        // Other fields
    }
    ```
    
    Enable auditing in the main application:
    
    ```java
    @SpringBootApplication
    @EnableJpaAuditing
    public class TodoApplication { ... }
    ```
    
4. **Native Queries**:  
    Use SQL directly with `@Query`:
    
    ```java
    @Query(value = "SELECT * FROM todos WHERE completed = :completed", nativeQuery = true)
    List<Todo> findByCompletedNative(boolean completed);
    ```
    

---

## Best Practices

- **Use Constructor Injection**: Prefer constructor-based DI for repositories.
- **Validate Input**: Use `@Valid` with Bean Validation (e.g., `@NotNull`) in entities.
- **Optimize Queries**: Avoid N+1 query issues by using `JOIN FETCH` in JPQL or `@EntityGraph`.
- **Handle Transactions**: Use `@Transactional` for methods that modify data.
- **Choose Appropriate `ddl-auto`**: Use `validate` or `none` in production to avoid accidental schema changes.
- **Test Repositories**: Use `@DataJpaTest` for repository tests:
    
    ```java
    @DataJpaTest
    class TodoRepositoryTest {
        @Autowired
        private TodoRepository todoRepository;
    
        @Test
        void testFindByCompletedStatus() {
            Todo todo = new Todo("Test", true);
            todoRepository.save(todo);
            List<Todo> completedTodos = todoRepository.findByCompletedStatus(true);
            assertEquals(1, completedTodos.size());
        }
    }
    ```
    

---

## Conclusion

Spring Data JPA, with Hibernate as the JPA provider, simplifies database operations by abstracting JDBC complexities and providing a repository-based approach. By creating a `Todo` entity and `JpaRepository`, you can perform CRUD operations and custom queries with minimal code. Hibernate handles ORM, SQL generation, and transaction management, while Spring Data JPA adds powerful abstractions like derived queries and pagination. Experiment with the provided example, explore advanced features like auditing and native queries, and refer to the Spring Data JPA and Hibernate documentation for deeper insights.

---


# 🛠 Maven Complete Guide

## 1. What is Maven?

- **Build automation tool** for Java (and JVM languages).
    
- Handles:  
    ✔ Compilation  
    ✔ Dependencies (download jars automatically)  
    ✔ Testing  
    ✔ Packaging (jar/war)  
    ✔ Running apps
    

---

## 2. Install Maven

On Arch:

```bash
sudo pacman -S maven
```

Check:

```bash
mvn -v
```

---

## 3. Create a New Project

Maven uses **archetypes** (templates).

```bash
mvn archetype:generate -DgroupId=com.example -DartifactId=myapp -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
```

- `groupId` = unique namespace (like a package).
    
- `artifactId` = project name.
    
- This creates a structure:
    

```
myapp
├── pom.xml
├── src
│   ├── main
│   │   └── java
│   │       └── com/example/App.java
│   └── test
│       └── java
│           └── com/example/AppTest.java
```

---

## 4. Project Structure Explained

- `pom.xml` → Maven config (dependencies, plugins, build).
    
- `src/main/java` → Your source code.
    
- `src/test/java` → Unit tests.
    
- `target` → Build output.
    

---

## 5. Basic Commands

Inside project root:

|Command|Purpose|
|---|---|
|`mvn compile`|Compile source code into `target/classes`|
|`mvn test`|Run unit tests|
|`mvn package`|Build a JAR/WAR in `target/`|
|`mvn clean`|Remove `target/`|
|`mvn install`|Install built jar into local Maven repo (`~/.m2/repository`)|
|`mvn exec:java -Dexec.mainClass="com.example.App"`|Run main class (if exec plugin added)|

---

## 6. Run Code

### Option 1: Direct `java`

```bash
java -cp target/classes com.example.App
```

### Option 2: Exec plugin (recommended)

Add to `pom.xml`:

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.codehaus.mojo</groupId>
      <artifactId>exec-maven-plugin</artifactId>
      <version>3.1.0</version>
      <configuration>
        <mainClass>com.example.App</mainClass>
      </configuration>
    </plugin>
  </plugins>
</build>
```

Run:

```bash
mvn exec:java
```

---

## 7. Build a JAR File

Run:

```bash
mvn package
```

Output:

```
target/myapp-1.0-SNAPSHOT.jar
```

Run jar:

```bash
java -cp target/myapp-1.0-SNAPSHOT.jar com.example.App
```

---

## 8. Create **Executable JAR**

To run with `java -jar`, you need a `Main-Class` in the manifest.

Add to `pom.xml`:

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-jar-plugin</artifactId>
      <version>3.3.0</version>
      <configuration>
        <archive>
          <manifest>
            <mainClass>com.example.App</mainClass>
          </manifest>
        </archive>
      </configuration>
    </plugin>
  </plugins>
</build>
```

Rebuild:

```bash
mvn clean package
```

Now run:

```bash
java -jar target/myapp-1.0-SNAPSHOT.jar
```

---

## 9. Dependencies

Add libraries inside `<dependencies>` in `pom.xml`:

```xml
<dependencies>
  <!-- Example: Gson for JSON parsing -->
  <dependency>
    <groupId>com.google.code.gson</groupId>
    <artifactId>gson</artifactId>
    <version>2.10.1</version>
  </dependency>
</dependencies>
```

Maven downloads them automatically into `~/.m2/repository`.

---

## 10. Advanced Features

### Profiles

Define different build configs (dev, prod, etc.):

```xml
<profiles>
  <profile>
    <id>dev</id>
    <properties>
      <env>development</env>
    </properties>
  </profile>
  <profile>
    <id>prod</id>
    <properties>
      <env>production</env>
    </properties>
  </profile>
</profiles>
```

Run with:

```bash
mvn package -Pdev
```

---

### Multi-Module Projects

You can have a parent `pom.xml` managing multiple submodules (microservices, libraries).  
This avoids duplicating dependencies and keeps versions consistent.

---

### Plugins

- **maven-compiler-plugin** → set Java version.
    
- **maven-surefire-plugin** → test runner.
    
- **maven-shade-plugin** → create “fat jar” (with dependencies included).
    

Example (fat jar):

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-shade-plugin</artifactId>
  <version>3.5.0</version>
  <executions>
    <execution>
      <phase>package</phase>
      <goals><goal>shade</goal></goals>
      <configuration>
        <transformers>
          <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
            <mainClass>com.example.App</mainClass>
          </transformer>
        </transformers>
      </configuration>
    </execution>
  </executions>
</plugin>
```

Now:

```bash
mvn package
java -jar target/myapp-1.0-SNAPSHOT-shaded.jar
```

---

# ⚡ Summary

1. `mvn archetype:generate` → create project.
    
2. `mvn compile` → build.
    
3. `mvn exec:java` or `java -cp target/classes ...` → run.
    
4. `mvn package` → jar file.
    
5. Use **plugins** (jar, shade, exec) for executable jars, fat jars, and easy running.
    
6. Use **dependencies** in `pom.xml` → auto-downloads libraries.
    
Here’s the concise list of Maven lifecycle commands:

---

### **Clean Lifecycle**

```bash
mvn clean            # Deletes target/ directory
```

---

### **Default (Build) Lifecycle**

```bash
mvn validate         # Validate project
mvn compile          # Compile source code
mvn test-compile     # Compile test code
mvn test             # Run tests
mvn package          # Package into JAR/WAR/EAR
mvn verify           # Run checks on the package
mvn install          # Install artifact into local repo (~/.m2)
mvn deploy           # Deploy artifact to remote repo
```

---

### **Site Lifecycle**

```bash
mvn site             # Generate project documentation
mvn site-deploy      # Deploy documentation
```

---

⚡ **Shortcut notes**:

* `mvn compile` also runs `validate`.
* `mvn package` runs all phases up to `package` automatically.
* `mvn install` runs everything up to `install`.


---




[[0 - Spring Framework]]