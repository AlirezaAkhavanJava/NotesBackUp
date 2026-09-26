
In **Spring Boot + JPA/Hibernate**, SQL relationships are represented between Java **entities** using relationship annotations.

The four main relationships are:

|SQL relationship|JPA annotation|Example|
|---|---|---|
|One-to-One|`@OneToOne`|User ↔ Profile|
|One-to-Many|`@OneToMany`|User → Receipts|
|Many-to-One|`@ManyToOne`|Many Receipts → One User|
|Many-to-Many|`@ManyToMany`|Students ↔ Courses|

The important idea is:

```text
SQL
Foreign Key
     ↓
JPA/Hibernate
     ↓
Entity relationship
```

---

## 1. One-to-One

One `User` has one `Profile`.

### SQL

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY
);

CREATE TABLE profiles (
    id BIGINT PRIMARY KEY,
    user_id BIGINT UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Entities

```java
@Entity
public class User {

    @Id
    @GeneratedValue
    private Long id;

    @OneToOne
    private Profile profile;
}
```

```java
@Entity
public class Profile {

    @Id
    @GeneratedValue
    private Long id;

    @OneToOne
    private User user;
}
```

`UNIQUE` on the foreign key is what makes the database relationship truly one-to-one.

---

# 2. One-to-Many / Many-to-One

This is probably the **most important relationship in normal Spring applications**.

Example:

> One user can have many receipts.

```text
User
 │
 ├── Receipt
 ├── Receipt
 └── Receipt
```

### SQL

The foreign key normally lives on the **many side**:

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY
);

CREATE TABLE receipts (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### `User`

```java
@Entity
public class User {

    @Id
    @GeneratedValue
    private Long id;

    @OneToMany(mappedBy = "user")
    private List<Receipt> receipts;
}
```

### `Receipt`

```java
@Entity
public class Receipt {

    @Id
    @GeneratedValue
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}
```

The important part is:

```java
@ManyToOne
@JoinColumn(name = "user_id")
private User user;
```

This corresponds to:

```text
receipts.user_id
       ↓
   users.id
```

### Why `mappedBy`?

```java
@OneToMany(mappedBy = "user")
```

means:

> "The `Receipt.user` field owns the database relationship."

So you don't create another unnecessary foreign-key relationship from `User`.

---

# 3. Many-to-Many

Example:

```text
Student ←→ Course
```

A student can take many courses, and a course can contain many students.

SQL usually needs a **junction table**:

```sql
CREATE TABLE students (
    id BIGINT PRIMARY KEY
);

CREATE TABLE courses (
    id BIGINT PRIMARY KEY
);

CREATE TABLE student_courses (
    student_id BIGINT,
    course_id BIGINT,

    PRIMARY KEY (student_id, course_id),

    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

JPA:

```java
@Entity
public class Student {

    @Id
    @GeneratedValue
    private Long id;

    @ManyToMany
    @JoinTable(
        name = "student_courses",
        joinColumns = @JoinColumn(name = "student_id"),
        inverseJoinColumns = @JoinColumn(name = "course_id")
    )
    private Set<Course> courses;
}
```

And:

```java
@Entity
public class Course {

    @Id
    @GeneratedValue
    private Long id;

    @ManyToMany(mappedBy = "courses")
    private Set<Student> students;
}
```

---

# The key concept: owning side

This is one of the most important JPA concepts.

Suppose:

```java
class User {
    @OneToMany(mappedBy = "user")
    List<Receipt> receipts;
}
```

and:

```java
class Receipt {
    @ManyToOne
    @JoinColumn(name = "user_id")
    User user;
}
```

The **owning side** is:

```java
Receipt.user
```

because it contains:

```java
@JoinColumn(name = "user_id")
```

Think of it as:

```text
             Java
              │
              ▼
        Receipt.user
              │
              ▼
        user_id column
              │
              ▼
        users.id
```

Hibernate uses this relationship metadata to generate SQL such as:

```sql
SELECT *
FROM receipts
WHERE user_id = ?;
```

---

## 4. `@JoinColumn`

`@JoinColumn` tells JPA which database column represents the foreign key.

```java
@ManyToOne
@JoinColumn(name = "user_id")
private User user;
```

Conceptually:

```text
Receipt entity
      │
      └── user
           │
           └── user_id → users.id
```

Without understanding `@JoinColumn`, JPA relationships can feel like magic. They're really just **object references mapped to foreign-key relationships**.

---

## 5. The complete mental model

Think in three layers:

```text
Java Object Model
       ↓
JPA/Hibernate Mapping
       ↓
SQL Relational Model
```

For example:

```java
Receipt
   │
   │ @ManyToOne
   ▼
User
```

becomes:

```text
receipts
----------------
id
user_id ──────────┐
                  │
                  ▼
users
----------------
id
```

So when designing Spring entities, first ask:

> **What is the relationship between these real-world objects?**

Then map it to:

```text
1 ↔ 1  → @OneToOne
1 ↔ N  → @OneToMany + @ManyToOne
N ↔ N  → @ManyToMany
```

And remember: **the foreign key normally lives on the "many" side.**


[[Java]]