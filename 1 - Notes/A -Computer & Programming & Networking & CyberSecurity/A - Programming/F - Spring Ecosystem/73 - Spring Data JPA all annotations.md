

---

# 🧠 Spring Data JPA — The Complete Cheatsheet (Basic → Advanced)

---

## ⚙️ 1. What JPA Is

**JPA (Java Persistence API)** is a specification for mapping Java objects to relational database tables.  
**Spring Data JPA** is Spring’s abstraction layer that makes JPA dead-simple — no manual SQL needed.

---

## 🏗️ 2. Core Entity Annotations

|Annotation|Use|Example|
|---|---|---|
|`@Entity`|Marks a class as a database entity.|`@Entity public class Student { ... }`|
|`@Table(name="students")`|Specifies table name (optional).|`@Table(name="students")`|
|`@Id`|Marks primary key.|`@Id private Long id;`|
|`@GeneratedValue(strategy=GenerationType.IDENTITY)`|Auto-generate ID (Postgres/MySQL style).|`@GeneratedValue(strategy = GenerationType.IDENTITY)`|
|`@Column(name="student_name", nullable=false, unique=true)`|Customize column.|`@Column(name="student_name")`|
|`@Transient`|Ignore field (not persisted).|`@Transient private int temp;`|
|`@Enumerated(EnumType.STRING)`|Store enums as strings.|`@Enumerated(EnumType.STRING)`|
|`@Lob`|Store large text/blob.|`@Lob private String description;`|
|`@Temporal(TemporalType.TIMESTAMP)`|For `java.util.Date`.|`@Temporal(TemporalType.DATE)`|

✅ **Example:**

```java
@Entity
@Table(name = "students")
public class Student {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String country;

    private boolean isActive;
}
```

---

## 🔗 3. Relationships

|Annotation|Type|Meaning|
|---|---|---|
|`@OneToOne`|One ↔ One|One entity linked to exactly one other|
|`@OneToMany`|One ↔ Many|One entity has many of another|
|`@ManyToOne`|Many ↔ One|Many entities refer to one parent|
|`@ManyToMany`|Many ↔ Many|Both sides can have many of each other|
|`@JoinColumn(name="...")`|Column for foreign key||
|`@JoinTable`|Define join table for many-to-many||

✅ **Example:**

```java
@Entity
public class Course {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;

    @OneToMany(mappedBy = "course")
    private List<Student> students;
}

@Entity
public class Student {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;

    @ManyToOne
    @JoinColumn(name = "course_id")
    private Course course;
}
```

---

## 🧩 4. Repository Layer

### ✅ Base Interface

```java
@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
}
```

**JpaRepository** gives you:

```java
save(), findById(), findAll(), deleteById(), count(), existsById(), ...
```

### 📜 Derived Queries (method naming)

You can define methods by following Spring naming conventions:

|Method|Description|
|---|---|
|`findByName(String name)`|Exact match|
|`findByNameIgnoreCase(String name)`|Case-insensitive|
|`findByNameContaining(String part)`|LIKE %part%|
|`findByNameStartingWith(String prefix)`|LIKE prefix%|
|`findByAgeGreaterThan(int age)`|`>`|
|`findByAgeBetween(int min, int max)`|BETWEEN|
|`findByIsActiveTrue()`|Boolean flag true|
|`findTop5ByOrderByAgeDesc()`|Limit + Order|

✅ **Example:**

```java
List<Student> findByCountryContainingIgnoreCase(String country);
```

---

## 🧮 5. Custom Queries (`@Query`)

### JPQL

```java
@Query("SELECT s FROM Student s WHERE s.name = :name")
List<Student> findByName(@Param("name") String name);
```

### Native SQL

```java
@Query(value = "SELECT * FROM students WHERE country = :country", nativeQuery = true)
List<Student> findByCountry(@Param("country") String country);
```

### Update / Delete Queries

```java
@Modifying
@Transactional
@Query("DELETE FROM Student s WHERE s.id = :id")
void deleteStudent(@Param("id") Long id);
```

---

## ⚡ 6. Pagination and Sorting

Spring Data JPA supports built-in paging and sorting:

```java
Page<Student> findAll(Pageable pageable);
```

Usage:

```java
Pageable pageable = PageRequest.of(0, 10, Sort.by("name").ascending());
Page<Student> page = studentRepo.findAll(pageable);
```

---

## 🧱 7. Auditing & Timestamps

|Annotation|Description|
|---|---|
|`@CreatedDate`|Auto-set on insert|
|`@LastModifiedDate`|Auto-set on update|
|`@EnableJpaAuditing`|Enable auditing in config|
|`@EntityListeners(AuditingEntityListener.class)`|Attach to entity|

✅ **Example:**

```java
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Student {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
```

Then in your config:

```java
@Configuration
@EnableJpaAuditing
public class JpaConfig {}
```

---

## 🧰 8. Transactions

Spring uses `@Transactional` to handle transactions automatically.

```java
@Service
public class StudentService {
    @Autowired StudentRepository repo;

    @Transactional
    public void updateCountry(Long id, String newCountry) {
        Student s = repo.findById(id).orElseThrow();
        s.setCountry(newCountry);
    }
}
```

---

## 🧠 9. Entity Lifecycle Hooks

|Annotation|When it runs|
|---|---|
|`@PrePersist`|Before save|
|`@PostPersist`|After save|
|`@PreUpdate`|Before update|
|`@PostUpdate`|After update|
|`@PreRemove`|Before delete|
|`@PostRemove`|After delete|

✅ **Example:**

```java
@PrePersist
void onCreate() {
    System.out.println("Saving new student: " + name);
}
```

---

## 🧩 10. DTOs & Projections

To avoid returning full entities, you can use:

```java
@Query("SELECT new com.example.StudentDTO(s.name, s.country) FROM Student s")
List<StudentDTO> findAllDTOs();
```

Or **Interface Projection**:

```java
public interface StudentView {
    String getName();
    String getCountry();
}
List<StudentView> findByCountry(String country);
```

---

## 🪄 11. Specification API (Advanced Dynamic Filtering)

Use `JpaSpecificationExecutor<T>` for dynamic queries.

```java
public interface StudentRepository extends JpaRepository<Student, Long>,
                                           JpaSpecificationExecutor<Student> {}
```

Then create specifications:

```java
Specification<Student> countryEq = (root, query, cb) -> cb.equal(root.get("country"), "USA");
List<Student> students = repo.findAll(countryEq);
```

---

## 🧩 12. Common `GenerationType` Strategies

|Strategy|Database Behavior|
|---|---|
|`IDENTITY`|Uses auto-increment column (Postgres/MySQL)|
|`SEQUENCE`|Uses a sequence table (Oracle, PostgreSQL)|
|`TABLE`|Uses a table to generate IDs|
|`AUTO`|Chooses automatically based on DB|

---

## 🔒 13. Validation Annotations (from `jakarta.validation`)

|Annotation|Description|
|---|---|
|`@NotNull`|Field must not be null|
|`@Size(min=, max=)`|String length|
|`@Email`|Valid email|
|`@Pattern(regexp="...")`|Regex|
|`@Positive` / `@Negative`|Number validation|

✅ **Example:**

```java
@Column(nullable=false)
@NotNull
@Size(min=3, max=20)
private String name;
```

---

## 🧭 14. Integration with Spring Boot

- Add dependency:
    
    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
    </dependency>
    ```
    
- Configure `application.properties`:
    
    ```properties
    spring.datasource.url=jdbc:postgresql://localhost:5432/schooldb
    spring.datasource.username=postgres
    spring.datasource.password=1234
    spring.jpa.hibernate.ddl-auto=update
    spring.jpa.show-sql=true
    spring.jpa.properties.hibernate.format_sql=true
    ```
    

---

## 🧱 15. Common SQL Behavior with PostgreSQL

|Task|JPA / SQL|
|---|---|
|Case-insensitive|Use `IgnoreCase` or `LOWER()`|
|JSON columns|Use `@Column(columnDefinition = "jsonb")`|
|Arrays|Use `@Column(columnDefinition = "text[]")`|
|Sequences|`@GeneratedValue(strategy = GenerationType.SEQUENCE)`|

---

## 🧾 Example: Full CRUD Flow

```java
@RestController
@RequestMapping("/students")
public class StudentController {
    @Autowired private StudentRepository repo;

    @GetMapping
    public List<Student> getAll() {
        return repo.findAll();
    }

    @PostMapping
    public Student create(@RequestBody Student s) {
        return repo.save(s);
    }

    @PutMapping("/{id}")
    public Student update(@PathVariable Long id, @RequestBody Student s) {
        Student existing = repo.findById(id).orElseThrow();
        existing.setName(s.getName());
        existing.setCountry(s.getCountry());
        return repo.save(existing);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        repo.deleteById(id);
    }
}
```

---

## 🧩 16. Advanced Topics to Explore

- **Entity Graphs** (`@EntityGraph`) → load specific relationships eagerly.
    
- **Soft Deletes** (boolean flag instead of real delete).
    
- **Specification + Criteria API** for filtering.
    
- **QueryDSL or Spring Data REST** for dynamic endpoints.
    

---

### Tags : [[0 - Spring Framework]]