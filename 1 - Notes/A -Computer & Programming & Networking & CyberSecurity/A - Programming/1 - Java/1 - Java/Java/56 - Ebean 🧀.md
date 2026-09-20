Date : 2025-09-04

# Ebean Java ORM Framework

Ebean is an Object-Relational Mapping (ORM) framework for Java and Kotlin, designed to simplify database interactions. It maps Java objects to relational database tables, offering a simpler API than JPA (Java Persistence API) through its session-less architecture. This guide covers Ebean from beginner to advanced levels, including recent updates and features up to Java 25 (September 2025).

---

## Phase 1: Basics of Ebean

### What is Ebean?

Ebean is a Java-based ORM framework that provides a simple, intuitive API for database operations. It supports JPA annotations (e.g., `@Entity`, `@OneToMany`) but avoids complex JPA concepts like attached/detached beans and EntityManager session management. It is integrated with frameworks like Play and Spring.[](https://en.wikipedia.org/wiki/Ebean)[](https://medium.com/%40ravinduperera1229/ebean-orm-with-springboot-2e05ab9e9601)

### Key Features

- **Session-Less**: No EntityManager, simplifying persistence.
- **Active Record Pattern**: Entities can save/delete themselves.
- **Type-Safe Queries**: Use query beans for compile-time checking.
- **SQL Flexibility**: Combine ORM with raw SQL for complex queries.
- **Supported Databases**: H2, Postgres, MySQL, MariaDB, SQL Server, Oracle, SAP HANA, SQLite, and more.[](https://ebean.io/)

**Example: Basic CRUD with Ebean**

```java
import io.ebean.Model;
import io.ebean.Finder;
import javax.persistence.Entity;
import javax.persistence.Id;

@Entity
public class Customer extends Model {
    @Id
    Long id;
    String name;

    public Customer(String name) {
        this.name = name;
    }

    public static Finder<Long, Customer> find = new Finder<>(Customer.class);

    public static void main(String[] args) {
        // Save
        Customer customer = new Customer("Joe");
        customer.save();

        // Find
        Customer found = Customer.find.byId(1L);
        System.out.println("Found: " + found.name);

        // Update
        found.name = "Montana";
        found.save();

        // Delete
        found.delete();
    }
}
```

**Output** (assuming database setup):

```
Found: Joe
```

**Key Points**:

- Extend `Model` for active record methods (`save()`, `delete()`).
- Use `Finder` for queries.
- Configure Ebean via `application.conf` (e.g., `ebean.default="models.*"`).[](https://www.playframework.com/documentation/2.2.6/JavaEbean)

---

## Phase 2: Ebean Setup and Configuration

### Setup with Play Framework

Ebean is commonly used with Play Framework. Add the Ebean plugin to your project:

**project/plugins.sbt**:

```sbt
addSbtPlugin("com.typesafe.sbt" % "sbt-play-ebean" % "8.3.0") // Check latest version
```

**build.sbt**:

```sbt
lazy val myProject = (project in file(".")).enablePlugins(PlayJava, PlayEbean)
libraryDependencies += "io.ebean" % "ebean" % "15.11.0" // Check latest version
```

**conf/application.conf**:

```properties
ebean.default="models.*"
db.default.driver=org.h2.Driver
db.default.url="jdbc:h2:mem:test"
```

**Key Points**:

- The Play Ebean plugin enhances bytecode for entity classes.[](https://www.playframework.com/documentation/2.7.0/JavaEbean)
- Use `application.conf` to specify model packages or classes.

### Maven Setup (Standalone)

```xml
<dependency>
    <groupId>io.ebean</groupId>
    <artifactId>ebean</artifactId>
    <version>15.11.0</version> <!-- Latest as of Dec 2024 -->
</dependency>
<dependency>
    <groupId>io.ebean</groupId>
    <artifactId>ebean-agent</artifactId>
    <version>15.11.0</version>
</dependency>
```

**Key Points**:

- Use `ebean-agent` for runtime or build-time enhancement.[](https://github.com/ebean-orm/ebean-agent)
- Enhance entities with Maven, IDE plugins, or `javaagent`.[](https://ebean.io/docs/setup/enhancement)

---

## Phase 3: Advanced Ebean Features

### Type-Safe Query Beans

Ebean generates query beans for type-safe, IDE-friendly queries.

**Example: Type-Safe Query**

```java
import static io.ebean.DB.*;

public class Main {
    public static void main(String[] args) {
        QCustomer qCustomer = QCustomer.alias();
        List<Customer> customers = find(Customer.class)
            .where()
            .ilike(qCustomer.name, "jo%")
            .findList();
        customers.forEach(c -> System.out.println(c.name));
    }
}
```

**Key Points**:

- Query beans provide auto-complete and compile-time checks.[](https://github.com/ebean-orm/ebean)
- Use `QClassName` (generated) for type-safe queries.

### Partial Objects and N+1 Avoidance

Ebean optimizes queries by fetching only needed data (partial objects) and avoiding N+1 issues.

**Example: Partial Object Query**

```java
List<Customer> customers = DB.find(Customer.class)
    .select("name") // Fetch only name
    .findList();
```

**Key Points**:

- Use `select()` to fetch specific fields.
- Ebean’s smart load context automatically avoids N+1 issues.[](https://ebean.io/)

### Raw SQL and Relational Features

Ebean supports raw SQL for complex queries.

**Example: Raw SQL Query**

```java
List<Customer> customers = DB.sqlQuery("SELECT id, name FROM customer WHERE name LIKE :name")
    .setParameter("name", "Jo%")
    .mapTo(Customer.class)
    .findList();
```

**Key Points**:

- Combine ORM with SQL for flexibility.
- Map results to entities or DTOs.[](https://en.wikipedia.org/wiki/Ebean)

---

## Phase 4: Recent Updates (Up to 2025)

### Ebean 15.11.0 (Dec 2024)

- **Dynamic Query Plans**: Support for collecting query plans dynamically with `ebean-insight` version 2+.[](https://github.com/ebean-orm/ebean/releases)
- **New Feature**: `findFutureMap` for asynchronous query execution.[](https://github.com/ebean-orm/ebean/releases)
- **Bug Fix**: Fixed query cache invalidation issue.[](https://github.com/ebean-orm/ebean/releases)
- **Dependency Updates**:
    - Bumped `ebean-datasource` to 9.3.
    - Updated Postgres/PostGIS test containers to version 16.[](https://github.com/ebean-orm/ebean/releases)
- **Native Image Support**: Fixed NPE with `@MappedSuperclass` in GraalVM native images.[](https://github.com/ebean-orm/ebean/releases)
- **Query Bean Enhancements**: Removed deprecated methods (e.g., `filterMany`, `order()`), added public constructor for embedded beans.[](https://github.com/ebean-orm/ebean/releases)

### Other Notable Updates

- **SAP HANA Support**: Added in version 11.23.1 (2018), supporting column/row stores, identity columns, and sequences.[](https://community.sap.com/t5/technology-blogs-by-sap/introducing-ebean-orm-support-for-sap-hana/ba-p/13372284)
- **YugabyteDB Support**: Enhanced integration for distributed SQL databases.[](https://www.yugabyte.com/blog/ebean-orm-yugabytedb/)
- **Docker Test Containers**: Improved testing with containers for Postgres, MySQL, SQL Server, etc.[](https://github.com/ebean-orm/ebean)

---

## Phase 5: Concurrent Ebean Operations

Ebean is session-less, making it suitable for concurrent applications. Use virtual threads (Java 21+) for scalable database operations.

**Example: Concurrent Queries with Virtual Threads**

```java
import java.util.concurrent.Executors;

public class Main {
    public static void main(String[] args) {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (String name : List.of("Joe", "Montana")) {
                executor.submit(() -> {
                    Customer customer = new Customer(name);
                    customer.save();
                    System.out.println("Saved: " + name);
                });
            }
        }
    }
}
```

**Key Points**:

- Ebean’s session-less design avoids concurrency issues like JPA’s EntityManager.
- Virtual threads scale I/O-bound database operations.[](https://medium.com/%40ravinduperera1229/ebean-orm-with-springboot-2e05ab9e9601)

---

## Java Features Up to Java 25 for Ebean

- **Java 8 (2014)**:
    
    - **Lambda Expressions**: Simplify query processing.
        
        ```java
        DB.find(Customer.class).findList().forEach(c -> System.out.println(c.name));
        ```
        
    - **Streams**: Process query results.
        
        ```java
        DB.find(Customer.class).findList().stream().map(c -> c.name).forEach(System.out::println);
        ```
        
- **Java 9 (2017)**:
    
    - **Module System**: Ebean 13+ uses `module-info` for stricter compilation.[](https://github.com/ebean-orm/ebean)
        
        ```java
        module myapp {
            requires io.ebean;
        }
        ```
        
- **Java 10 (2018)**:
    
    - **var**: Cleaner code for Ebean objects.
        
        ```java
        var customer = new Customer("Joe");
        ```
        
- **Java 14 (2020)**:
    
    - **Records**: Use for immutable DTOs with Ebean.
        
        ```java
        record CustomerDTO(Long id, String name) {}
        ```
        
- **Java 17 (2021)**:
    
    - **Pattern Matching for `instanceof`**:
        
        ```java
        if (bean instanceof Customer c) {
            c.save();
        }
        ```
        
- **Java 21 (2023)**:
    
    - **Virtual Threads**: Scalable concurrent database operations (shown above).
    - **Structured Concurrency (Preview)**: Manage multiple Ebean tasks.
        
        ```java
        import java.util.concurrent.StructuredTaskScope;
        
        try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
            var future1 = scope.fork(() -> DB.find(Customer.class).byId(1L));
            scope.join().throwIfFailed();
            System.out.println(future1.get().name);
        }
        ```
        
- **Java 25 (2025)**:
    
    - **Implicit Classes**: Simplify Ebean utility methods.
        
        ```java
        implicit class EbeanUtils {
            static void saveCustomer(String name) {
                new Customer(name).save();
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Validate entity configurations.
        
        ```java
        class Customer {
            Customer(String name) {
                this.name = name;
                if (name.isEmpty()) throw new IllegalArgumentException("Name cannot be empty");
            }
        }
        ```
        

---

## Best Practices

1. **Use Query Beans**: For type-safe queries and IDE support.
2. **Enable Enhancement**: Use IDE plugins, Maven, or `javaagent` for entity enhancement.[](https://ebean.io/docs/setup/enhancement)
3. **Optimize Queries**: Use partial objects and `select()` to reduce data fetching.
4. **Handle Transactions**: Use `@Transactional` or `DB.beginTransaction()` for consistency.[](https://stackoverflow.com/questions/17076055/play-2-1-1-unable-to-rollback-transaction-with-ebean-orm/17568730)
5. **Test with Ebean-Mocker**: Mock EbeanServer for unit tests.[](https://ebean.io/docs/setup/activerecord)
    
    ```xml
    <dependency>
        <groupId>io.ebean</groupId>
        <artifactId>ebean-mocker</artifactId>
        <version>15.11.0</version>
        <scope>test</scope>
    </dependency>
    ```
    

**Related Library: Play Ebean Plugin**  
Simplifies Ebean integration with Play Framework.[](https://www.playframework.com/documentation/2.7.0/JavaEbean)

```xml
<dependency>
    <groupId>com.typesafe.play</groupId>
    <artifactId>play-ebean_2.13</artifactId>
    <version>8.3.0</version>
</dependency>
```

---

## Real-World Applications

- **Web Applications**: Use with Play Framework for REST APIs.[](https://www.yugabyte.com/blog/ebean-orm-yugabytedb/)
- **Microservices**: Persist data in distributed systems like YugabyteDB.[](https://docs.yugabyte.com/preview/drivers-orms/java/ebean/)
- **Data Migration**: Combine ORM and raw SQL for complex migrations.
- **Testing**: Use Docker test containers for database testing.[](https://github.com/ebean-orm/ebean)

---

## Conclusion

Ebean is a lightweight, session-less ORM framework that simplifies database operations in Java and Kotlin. It supports JPA annotations, type-safe queries, and raw SQL, making it versatile for simple and complex use cases. Recent updates (e.g., Ebean 15.11.0) add dynamic query plans, better cache handling, and native image support. Java 25 features like virtual threads and implicit classes enhance Ebean’s scalability and code simplicity.




##### *Tags : [[Java]]