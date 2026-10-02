# Lombok Tutorial: All Annotations and Spring Boot Integration

**Date**: 2025-08-24  
**Course**: Java Language Fundamentals  
**Tags**:  [[0 - Spring Framework]] 

## What is Lombok?

Lombok is a Java library that reduces **boilerplate code** (like getters, setters, constructors) by generating it at compile time using **annotations**. It makes code cleaner, easier to read, and maintainable, especially in **Spring Boot** applications for entities, DTOs, and services. Lombok is widely used, open-source, and maintained at [projectlombok.org](https://projectlombok.org/).

**Why Use It?**

- **Less Code**: Auto-generates methods like `getters`, `setters`, `toString()`, etc.
- **Readable**: Focus on business logic, not repetitive code.
- **Compile-Time**: No runtime overhead; code is generated during compilation.
- **Spring Boot Friendly**: Simplifies JPA entities, DTOs, and logging.

## Setup in Spring Boot (Java 17/21, Spring Boot 3+)

Here’s how to use Lombok with Spring Boot (modern approach, verified for 2025).

### 1. Add Lombok Dependency

**Maven (`pom.xml`)**:

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.36</version> <!-- Latest as of 2025 -->
    <scope>provided</scope>
</dependency>
```

**Gradle (`build.gradle`)**:

```groovy
dependencies {
    compileOnly 'org.projectlombok:lombok:1.18.36'
    annotationProcessor 'org.projectlombok:lombok:1.18.36'
}
```

### 2. Enable Annotation Processing

For Java 17/21, configure the compiler to process Lombok annotations.

**Maven (`pom.xml`)**:

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.13.0</version>
            <configuration>
                <source>21</source>
                <target>21</target>
                <annotationProcessorPaths>
                    <path>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                        <version>1.18.36</version>
                    </path>
                </annotationProcessorPaths>
            </configuration>
        </plugin>
    </plugins>
</build>
```

**Gradle**: The `annotationProcessor` line above is enough.

### 3. IDE Setup

- **IntelliJ IDEA**: Install the Lombok plugin (Settings > Plugins > Marketplace > "Lombok"). Enable annotation processing in Settings > Build, Execution, Deployment > Compiler > Annotation Processors.
- **Eclipse/STS**: Download the Lombok JAR from [projectlombok.org](https://projectlombok.org/setup/eclipse), run it, and follow the installer.
- **VS Code**: Install the "Lombok Annotations Support" extension.

### 4. Verify

Create a Spring Boot project (via [start.spring.io](https://start.spring.io/)) with `spring-boot-starter-web` and Lombok. Test with a simple class (see examples below). Build with `mvn clean install` or `./gradlew build`.

## All Lombok Annotations

Below is a complete list of Lombok annotations (stable and experimental, sourced from [projectlombok.org](https://projectlombok.org/features/all) and Spring Boot tutorials), with examples tailored for Spring Boot.

### Field-Level Annotations

1. **@Getter / @Setter**
    
    - **What**: Generates getter/setter methods for fields.
    - **Use**: For mutable fields in entities or DTOs.
    - **Example** (JPA Entity):
        
        ```java
        import lombok.Getter;
        import lombok.Setter;
        import jakarta.persistence.Entity;
        import jakarta.persistence.Id;
        
        @Entity
        @Getter @Setter
        public class User {
            @Id
            private Long id;
            private String name;
        }
        ```
        
        - Generates `getId()`, `setName()`, etc. Ideal for Spring Data JPA entities.
2. **@NonNull**
    
    - **What**: Adds null checks in setters/constructors, throwing `NullPointerException` if null.
    - **Use**: For mandatory fields.
    - **Example**:
        
        ```java
        import lombok.NonNull;
        
        public class User {
            @NonNull
            private String name;
        }
        ```
        
        - Setter: `if (name == null) throw new NullPointerException();`.
3. **@With**
    
    - **What**: Creates a method to copy an object with one field changed (for immutable classes).
    - **Use**: For immutable DTOs in Spring Boot.
    - **Example**:
        
        ```java
        import lombok.With;
        
        public class UserDTO {
            private final Long id;
            @With
            private final String name;
        
            public UserDTO(Long id, String name) {
                this.id = id;
                this.name = name;
            }
        }
        ```
        
        - Usage: `UserDTO updated = user.withName("Alice");`.

### Constructor Annotations

4. **@NoArgsConstructor**
    
    - **What**: Generates a no-argument constructor.
    - **Use**: Required for JPA entities.
    - **Example**:
        
        ```java
        import lombok.NoArgsConstructor;
        import jakarta.persistence.Entity;
        
        @Entity
        @NoArgsConstructor
        public class User {
            private String name;
        }
        ```
        
        - Generates `public User() {}`.
5. **@AllArgsConstructor**
    
    - **What**: Generates a constructor with all fields.
    - **Use**: For full initialization.
    - **Example**:
        
        ```java
        import lombok.AllArgsConstructor;
        
        @AllArgsConstructor
        public class User {
            private String name;
            private int age;
        }
        ```
        
        - Generates `public User(String name, int age) {...}`.
6. **@RequiredArgsConstructor**
    
    - **What**: Generates a constructor for `final` or `@NonNull` fields.
    - **Use**: For mandatory fields.
    - **Example**:
        
        ```java
        import lombok.RequiredArgsConstructor;
        
        @RequiredArgsConstructor
        public class User {
            private final String name;
            private int age; // Excluded
        }
        ```
        
        - Generates `public User(String name) {...}`.

### Class-Level Annotations

7. **@Data**
    
    - **What**: Combines `@Getter`, `@Setter`, `@ToString`, `@EqualsAndHashCode`, `@RequiredArgsConstructor`.
    - **Use**: For mutable POJOs (e.g., JPA entities), but avoid if `equals`/`hashCode` cause issues.
    - **Example**:
        
        ```java
        import lombok.Data;
        import jakarta.persistence.Entity;
        import jakarta.persistence.Id;
        
        @Entity
        @Data
        public class User {
            @Id
            private Long id;
            private String name;
        }
        ```
        
8. **@Value**
    
    - **What**: Like `@Data` but for immutable classes (final fields, no setters).
    - **Use**: For DTOs in REST APIs.
    - **Example**:
        
        ```java
        import lombok.Value;
        
        @Value
        public class UserDTO {
            String name;
            int age;
        }
        ```
        
9. **@Builder**
    
    - **What**: Generates a builder pattern for creating objects.
    - **Use**: For complex object creation in Spring services.
    - **Example**:
        
        ```java
        import lombok.Builder;
        
        @Builder
        public class User {
            private String name;
            private int age;
        }
        ```
        
        - Usage: `User user = User.builder().name("John").age(30).build();`.
10. **@ToString**
    
    - **What**: Generates `toString()` for all fields (customizable with `exclude`).
    - **Use**: For debugging.
    - **Example**:
        
        ```java
        import lombok.ToString;
        
        @ToString(exclude = "password")
        public class User {
            private String name;
            private String password;
        }
        ```
        
11. **@EqualsAndHashCode**
    
    - **What**: Generates `equals()` and `hashCode()` for fields.
    - **Use**: For object comparison, but exclude relations in JPA entities.
    - **Example**:
        
        ```java
        import lombok.EqualsAndHashCode;
        
        @EqualsAndHashCode(exclude = "age")
        public class User {
            private String name;
            private int age;
        }
        ```
        

### Utility Annotations

12. **@SneakyThrows**
    
    - **What**: Throws checked exceptions as unchecked without `throws` clause.
    - **Use**: For simplifying code in Spring services.
    - **Example**:
        
        ```java
        import lombok.SneakyThrows;
        
        @Service
        public class FileService {
            @SneakyThrows
            public void readFile() {
                // Code throwing IOException
            }
        }
        ```
        
13. **@Synchronized**
    
    - **What**: Generates thread-safe synchronized methods with a private lock.
    - **Use**: For thread safety in Spring components.
    - **Example**:
        
        ```java
        import lombok.Synchronized;
        
        @Service
        public class Counter {
            private int count = 0;
            @Synchronized
            public void increment() {
                count++;
            }
        }
        ```
        
14. **@Log / @Slf4j / @Log4j2**
    
    - **What**: Generates a logger field (e.g., SLF4J’s `log`).
    - **Use**: For logging in Spring Boot services/controllers.
    - **Example**:
        
        ```java
        import lombok.extern.slf4j.Slf4j;
        import org.springframework.stereotype.Service;
        
        @Slf4j
        @Service
        public class UserService {
            public void logUser(String name) {
                log.info("User: {}", name);
            }
        }
        ```
        
15. **@Cleanup**
    
    - **What**: Auto-closes resources (like try-with-resources).
    - **Use**: For database or file operations.
    - **Example**:
        
        ```java
        import lombok.Cleanup;
        
        public class FileReader {
            @Cleanup
            InputStream in = new FileInputStream("file.txt");
        }
        ```
        
16. **@Singular**
    
    - **What**: Enhances `@Builder` for collections, adding methods like `addItem()`.
    - **Use**: For building lists/sets in Spring DTOs.
    - **Example**:
        
        ```java
        import lombok.Builder;
        import lombok.Singular;
        
        @Builder
        public class Team {
            @Singular
            private List<String> members;
        }
        ```
        
        - Usage: `Team team = Team.builder().member("John").member("Alice").build();`.

### Less Common/Experimental Annotations

- **@UtilityClass**: Marks a class as a static utility class (private constructor, static methods).
    
    ```java
    import lombok.experimental.UtilityClass;
    
    @UtilityClass
    public class MathUtils {
        public int add(int a, int b) {
            return a + b;
        }
    }
    ```
    
- **@Delegate**: Delegates methods to a field (experimental).
    
    ```java
    import lombok.experimental.Delegate;
    
    public class Delegator {
        @Delegate
        private List<String> list = new ArrayList<>();
    }
    ```
    
- **@ExtensionMethod**: Adds methods as if they were extensions (experimental, rarely used).

## Best Practices for Spring Boot

- **Entities**: Use `@Data` or `@Getter/@Setter` for JPA entities, but exclude relations from `@EqualsAndHashCode` to avoid infinite loops.
    
    ```java
    @Entity
    @Data
    @EqualsAndHashCode(exclude = "orders")
    public class User {
        @Id
        private Long id;
        private String name;
        @OneToMany
        private List<Order> orders;
    }
    ```
    
- **DTOs**: Use `@Value` or `@Builder` for immutable, clean DTOs in REST APIs.
- **Services/Controllers**: Use `@Slf4j` for logging, `@RequiredArgsConstructor` for dependency injection.
- **Performance**: Avoid `@Data` on large classes; use specific annotations (e.g., `@Getter/@Setter`) for control.
- **Records (Java 17+)**: Combine with `@With` or `@Builder` for immutable DTOs.
- **Delombok**: Use `lombok:delombok` (Maven/Gradle) to generate plain Java for debugging or migration.
- **Testing**: Ensure IDE plugins are installed to avoid compilation errors in tests.

## Common Issues

- **IDE Errors**: Lombok methods not recognized.
    - **Fix**: Install the Lombok plugin and enable annotation processing.
- **JPA Issues**: `@Data` on entities with relations can cause stack overflows in `equals`/`hashCode`.
    - **Fix**: Use `@EqualsAndHashCode(exclude = "relations")`.
- **Build Failures**: Missing annotation processor for Java 17+.
    - **Fix**: Configure `maven-compiler-plugin` or Gradle as shown.
- **Overuse**: Too many annotations reduce readability.
    - **Fix**: Use only necessary annotations (e.g., avoid `@Data` if only `@Getter` needed).

## Example: Spring Boot with Lombok

```java
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;

// JPA Entity
@Entity
@Data
public class User {
    @Id
    private Long id;
    private String name;
}

// Service
@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository repository;

    public User getUser(Long id) {
        log.info("Fetching user with id: {}", id);
        return repository.findById(id).orElse(null);
    }
}

// REST Controller
@RestController
@RequiredArgsConstructor
public class UserController {
    private final UserService service;

    @GetMapping("/users/{id}")
    public User getUser(@PathVariable Long id) {
        return service.getUser(id);
    }
}

// Spring Boot Application
@SpringBootApplication
public class App {
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}

// Repository (Spring Data JPA)
interface UserRepository extends JpaRepository<User, Long> {}
```

**application.properties**:

```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.jpa.hibernate.ddl-auto=update
```

**Note**:

- Add dependencies: `spring-boot-starter-web`, `spring-boot-starter-data-jpa`, `lombok`, and `h2` (for in-memory DB).
- Run and access `http://localhost:8080/users/1` (after saving a user).
- Uses `@Data` for entity, `@RequiredArgsConstructor` for DI, and `@Slf4j` for logging.

## Advanced Notes

- **Java Records**: Combine with `@With`, `@Builder` for modern DTOs:
    
    ```java
    import lombok.Builder;
    import lombok.With
    ```