
---

# MongoDB with Spring Boot – Notes (Basic to Advanced + PostgreSQL Comparison)

### 1. **Why MongoDB vs PostgreSQL**

|Feature|PostgreSQL (Relational)|MongoDB (NoSQL Document)|
|---|---|---|
|Schema|Fixed, tables & rows|Flexible, collections & documents|
|Joins|Supports complex joins|Limited joins; prefer embedding or referencing|
|Transactions|Strong ACID support|ACID supported only in replica sets|
|Use Case|Structured data, analytics|Dynamic/unstructured data, JSON APIs|
|Scaling|Vertical scaling|Horizontal scaling (sharding)|

**When to use MongoDB in Spring Boot instead of PostgreSQL:**

- Flexible schema (e.g., user profiles with dynamic fields)
    
- Large JSON data storage
    
- Real-time analytics
    
- High-volume write operations
    
- File storage (via GridFS)
    

---

### 2. **Spring Boot Setup for MongoDB**

1. **Add Dependencies (Maven)**
    

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-mongodb</artifactId>
</dependency>
```

2. **Application Properties**
    

```properties
spring.data.mongodb.uri=mongodb://localhost:27017/testDB
spring.data.mongodb.database=testDB
```

---

### 3. **MongoDB Entities in Spring Boot**

- Use **@Document** to map a class to a MongoDB collection.
    
- Use **@Id** for the primary key.
    

```java
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "users")
public class User {
    @Id
    private String id;
    private String name;
    private int age;
    private List<String> skills;
}
```

---

### 4. **Repository Layer**

- Spring Data MongoDB provides **MongoRepository** and **CrudRepository**.
    
- Supports CRUD without writing queries.
    

```java
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface UserRepository extends MongoRepository<User, String> {
    List<User> findByAgeGreaterThan(int age);
    List<User> findBySkillsIn(List<String> skills);
}
```

---

### 5. **Service Layer Example**

```java
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class UserService {
    private final UserRepository userRepository;
    
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }
    
    public User addUser(User user) {
        return userRepository.save(user);
    }
    
    public List<User> getUsersBySkill(String skill) {
        return userRepository.findBySkillsIn(List.of(skill));
    }
}
```

---

### 6. **Controller Layer Example**

```java
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/users")
public class UserController {
    private final UserService userService;
    
    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    @PostMapping
    public User createUser(@RequestBody User user) {
        return userService.addUser(user);
    }

    @GetMapping("/skill/{skill}")
    public List<User> getUsersBySkill(@PathVariable String skill) {
        return userService.getUsersBySkill(skill);
    }
}
```

---

### 7. **Advanced Queries in Spring Boot**

- Spring Data MongoDB supports **@Query** annotation for custom queries.
    

```java
import org.springframework.data.mongodb.repository.Query;

@Query("{ 'age' : { $gte: ?0 }, 'skills' : { $in: ?1 } }")
List<User> findAdvanced(int minAge, List<String> skills);
```

---

### 8. **Aggregation in Spring Boot**

- Use **Aggregation Framework** via `Aggregation` class.
    

```java
import org.springframework.data.mongodb.core.aggregation.Aggregation;
import org.springframework.data.mongodb.core.aggregation.AggregationResults;
import org.springframework.data.mongodb.core.MongoTemplate;

Aggregation agg = Aggregation.newAggregation(
        Aggregation.match(Criteria.where("age").gte(25)),
        Aggregation.group("skills").avg("age").as("avgAge"),
        Aggregation.project("avgAge").and("skills").previousOperation()
);

AggregationResults<Document> results = mongoTemplate.aggregate(agg, "users", Document.class);
results.getMappedResults().forEach(System.out::println);
```

---

### 9. **Transactions in Spring Boot**

- MongoDB supports transactions in **replica sets**.
    
- Use `@Transactional` in Spring Boot.
    

```java
import org.springframework.transaction.annotation.Transactional;

@Transactional
public void performTransaction() {
    userRepository.save(new User("Alice", 25, List.of("Java")));
    userRepository.deleteById("12345");
}
```

---

### 10. **Comparison with PostgreSQL in Spring Boot**

|Feature|PostgreSQL|MongoDB|
|---|---|---|
|Entities|`@Entity`|`@Document`|
|Repository|`JpaRepository`|`MongoRepository`|
|Queries|JPQL / Criteria|MongoDB Query / Aggregation|
|Joins|Supports naturally|Prefer embedding or `$lookup`|
|Transactions|Default ACID|ACID only in replica sets, `@Transactional` needed|

---

### 11. **Tips for Migrating/Using MongoDB in Projects**

- For JSON-heavy APIs: MongoDB is simpler than PostgreSQL.
    
- For reporting/analytics: PostgreSQL is better.
    
- Keep indexing for frequently queried fields.
    
- For multi-table joins, either embed or use `$lookup` (MongoDB’s join).
    
- Use `MongoTemplate` for advanced queries and aggregation.
    

---



### Tags : [[1 - MongoDB 🍂]]