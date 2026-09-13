
### What is a Many-to-Many Relationship?

A **many-to-many (M:N) relationship** occurs when multiple records in one table can be associated with multiple records in another table.

Classic examples:
- **Students and Courses**: A student can enroll in many courses, and a course can have many students.
- **Books and Authors**: A book can have multiple authors, and an author can write multiple books.
- **Users and Roles**: A user can have many roles, and a role can be assigned to many users.

In a relational database, a pure many-to-many relationship cannot be directly represented with just two tables due to normalization rules. Instead, it requires a **join table** (also called junction, link, or association table) that holds foreign keys to both entities.

Example schema:
- `student` table: id, name
- `course` table: id, title
- `student_course` join table: student_id (FK), course_id (FK) — with a composite primary key on both columns.

---
### Implementing Many-to-Many in Hibernate / Spring Data JPA

JPA (with Hibernate as the provider) simplifies this by allowing you to model the relationship directly on the entities using collections (usually `Set` to avoid duplicates).

There are two main variants:
1. **Unidirectional**: Only one entity knows about the relationship.
2. **Bidirectional**: Both entities reference each other (more common, allows navigation from both sides).

#### 1. Basic Bidirectional Many-to-Many (Recommended)

Use `@ManyToMany` on both sides, with one side as the **owner** (marked with `mappedBy`).

**Student.java**
```java
@Entity
@Table(name = "student")
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @ManyToMany(cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinTable(
        name = "student_course",
        joinColumns = @JoinColumn(name = "student_id"),
        inverseJoinColumns = @JoinColumn(name = "course_id")
    )
    private Set<Course> courses = new HashSet<>();

    // getters, setters, add/remove helper methods
    public void addCourse(Course course) {
        courses.add(course);
        course.getStudents().add(this);
    }

    public void removeCourse(Course course) {
        courses.remove(course);
        course.getStudents().remove(this);
    }
}
```

**Course.java**
```java
@Entity
@Table(name = "course")
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @ManyToMany(mappedBy = "courses")  // Non-owning side
    private Set<Student> students = new HashSet<>();

    // getters, setters
}
```

- The `@JoinTable` is defined only on the **owning side** (Student here).
- Hibernate automatically creates and manages the join table.
- Use **helper methods** (`addCourse`, `removeCourse`) to keep both sides in sync and avoid inconsistencies.

#### 2. Unidirectional Many-to-Many

Only one entity has the collection.

**Student.java** (same as above, with `@JoinTable`)
**Course.java** (no reference to students)

Navigation is possible only from Student → Course, not vice versa.

#### 3. Many-to-Many with Extra Attributes (Common Real-World Case)

If the association needs additional data (e.g., enrollment date, grade), you cannot use plain `@ManyToMany`. Instead, model the join table as a full **entity**.

**Student.java**
```java
@ManyToOne(cascade = CascadeType.ALL)
private Set<Enrollment> enrollments = new HashSet<>();
```

**Course.java**
```java
@ManyToOne
private Set<Enrollment> enrollments = new HashSet<>();
```

**Enrollment.java** (the join entity)
```java
@Entity
@IdClass(EnrollmentId.class)  // or @EmbeddedId
public class Enrollment {

    @Id
    @ManyToOne
    @JoinColumn(name = "student_id")
    private Student student;

    @Id
    @ManyToOne
    @JoinColumn(name = "course_id")
    private Course course;

    private LocalDate enrollmentDate;
    private String grade;

    // equals/hashCode based on both IDs
}
```

This turns two many-to-many into two one-to-many relationships.

#### Business Logic Tips

- Always use **Set** (not List) unless you need ordering (then use `@OrderColumn`).
- Synchronize both sides in bidirectional mappings to prevent ORM confusion.
- Use appropriate **cascading** (usually PERSIST/MERGE, avoid ALL if you don't want deletes to cascade).
- In Spring Data JPA repositories, `save()` on one side will persist the association if cascaded properly.
- Fetching: Use `@ManyToMany(fetch = FetchType.LAZY)` (default) to avoid loading large graphs; handle `LazyInitializationException` with `@Transactional` or DTOs.

This approach works seamlessly in Spring Boot with Spring Data JPA and Hibernate.

###### Tags : [[0 - Spring Framework]]