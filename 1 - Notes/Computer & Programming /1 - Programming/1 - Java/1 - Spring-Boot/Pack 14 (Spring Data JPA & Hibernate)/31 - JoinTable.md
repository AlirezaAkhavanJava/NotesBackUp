
`@JoinTable` in **Spring Boot JPA** is a **JPA annotation** used to **define the join table** for **many-to-many** (and sometimes one-to-many) relationships between two entities.

It is applied on the **owning side** of the relationship and specifies:
- The **name** of the join table
- The **foreign key columns** linking to both entities

---

## When to Use `@JoinTable`?

Use it in **many-to-many** relationships when:
- You want to **customize** the intermediate table (default is `entity1_entity2`)
- You need **additional columns** in the join table (e.g., `created_at`)
- You want **explicit control** over column names

---

## Basic Syntax

```java
@ManyToMany
@JoinTable(
    name = "table_name",
    joinColumns = @JoinColumn(name = "fk_column_for_this_entity"),
    inverseJoinColumns = @JoinColumn(name = "fk_column_for_other_entity")
)
private Collection<OtherEntity> others;
```

---

## Real-World Example: **Student ↔ Course** (Many-to-Many)

### 1. `Student.java`

```java
@Entity
@Table(name = "students")
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @ManyToMany
    @JoinTable(
        name = "student_courses",                    // Join table name
        joinColumns = @JoinColumn(name = "student_id"),     // FK to Student
        inverseJoinColumns = @JoinColumn(name = "course_id") // FK to Course
    )
    private Set<Course> courses = new HashSet<>();

    // getters, setters, addCourse(), removeCourse()
}
```

### 2. `Course.java` (Inverse side – no `@JoinTable`)

```java
@Entity
@Table(name = "courses")
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @ManyToMany(mappedBy = "courses")  // Refers to field in Student
    private Set<Student> students = new HashSet<>();

    // getters, setters
}
```

---

## Generated Database Table: `student_courses`

```sql
CREATE TABLE student_courses (
    student_id BIGINT NOT NULL,
    course_id  BIGINT NOT NULL,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

---

## Advanced: Join Table with **Extra Columns**

Sometimes you need metadata in the join table (e.g., enrollment date).

### Solution: Use a **separate entity** for the join table

### 1. `Enrollment.java` (Join Entity)

```java
@Entity
@Table(name = "student_courses")
@IdClass(EnrollmentId.class)
public class Enrollment {

    @Id
    private Long studentId;

    @Id
    private Long courseId;

    private LocalDate enrolledAt;

    // Constructors, equals(), hashCode()
}
```

### 2. `EnrollmentId.java`

```java
public class EnrollmentId implements Serializable {
    private Long studentId;
    private Long courseId;
    // equals, hashCode
}
```

### 3. Update `Student.java`

```java
@OneToMany(mappedBy = "student", cascade = CascadeType.ALL)
private Set<Enrollment> enrollments = new HashSet<>();
```

> **Note**: `@JoinTable` **cannot** have extra columns. Use a **join entity** instead.

---

## Common `@JoinTable` Options

| Attribute | Description | Example |
|---------|-------------|--------|
| `name` | Name of join table | `name = "user_roles"` |
| `joinColumns` | FK column for **owning entity** | `@JoinColumn(name = "user_id")` |
| `inverseJoinColumns` | FK column for **target entity** | `@JoinColumn(name = "role_id")` |
| `uniqueConstraints` | Add uniqueness | `@UniqueConstraint(columnNames = {"user_id", "role_id"})` |
| `indexes` | Add index | `@Index(columnList = "user_id")` |

---

## Example with Indexes & Constraints

```java
@ManyToMany
@JoinTable(
    name = "user_roles",
    joinColumns = @JoinColumn(name = "user_id"),
    inverseJoinColumns = @JoinColumn(name = "role_id"),
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "role_id"}),
    indexes = {
        @Index(name = "idx_user_id", columnList = "user_id"),
        @Index(name = "idx_role_id", columnList = "role_id")
    }
)
private Set<Role> roles;
```

---

## Best Practices

| Practice | Why |
|--------|-----|
| Always define `@JoinTable` on **one side only** | Avoid duplicate tables |
| Use `Set` instead of `List` | Prevent duplicates |
| Use `mappedBy` on inverse side | Maintain consistency |
| For extra columns → use **join entity** | JPA limitation |
| Name columns clearly: `xxx_id` | Improves SQL readability |

---

## Common Mistakes

| Mistake | Result |
|-------|--------|
| `@JoinTable` on both sides | Two join tables created |
| Wrong `mappedBy` | `NullPointerException` or infinite loop |
| Using `List` without `@OrderColumn` | Unpredictable order |
| Forgetting `cascade` in join entity | Orphaned rows |

---

## Summary

| You Want | Use |
|--------|-----|
| Simple Many-to-Many | `@ManyToMany + @JoinTable` |
| Custom table/column names | `@JoinTable(name=..., joinColumns=...)` |
| Extra fields in join table | **Separate Entity** (`Enrollment`) |
| One-to-Many with join table | `@JoinTable` on `@ManyToOne` side (rare) |


##### Tags : [[1 - SQL 🦬]]