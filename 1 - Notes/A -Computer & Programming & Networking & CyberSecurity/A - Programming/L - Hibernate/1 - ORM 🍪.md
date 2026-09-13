
**ORM (Object–Relational Mapping)** is a **programming technique** that establishes a **mapping between object-oriented models and relational database systems**.

In theory, it allows software to **convert data between incompatible systems** — objects in an object-oriented language and tables in a relational database — **automatically**.

ORM frameworks handle this mapping by representing database tables as **classes**, table rows as **objects**, and table columns as **object fields**. This enables developers to work with database data in the form of objects, rather than writing SQL queries manually.

In short:

> ORM is a theoretical concept that abstracts the database layer, allowing object-oriented programs to interact with relational data using object semantics instead of relational ones.

---
**ORM (Object–Relational Mapping)** is a technique that lets you interact with a **database using objects** instead of raw SQL queries.

### In simple terms:

ORM acts as a **bridge** between your **object-oriented code (like Java classes)** and the **relational database (like MySQL tables)**.

---

### 🔹 Example

Without ORM (using plain JDBC):

```java
String sql = "SELECT * FROM students WHERE id = ?";
PreparedStatement stmt = conn.prepareStatement(sql);
stmt.setInt(1, 1);
ResultSet rs = stmt.executeQuery();
```

With ORM (like Hibernate or JPA):

```java
Student student = entityManager.find(Student.class, 1);
```

➡️ No SQL written — ORM handles it.

---

### 🔹 What ORM Does

- Maps **classes ↔ tables**
    
- Maps **fields ↔ columns**
    
- Generates and runs **SQL queries automatically**
    
- Manages **transactions**, **caching**, **relationships** (OneToMany, ManyToMany, etc.)
    

---

### 🔹 Popular Java ORMs

- **Hibernate** (most common)
    
- **JPA** (Java Persistence API – a standard; Hibernate implements it)
    
- **EclipseLink**
    
- **Spring Data JPA** (wrapper around JPA to simplify use)
    

---

### 🔹 Why Use ORM

✅ Less boilerplate SQL  
✅ Easier to maintain  
✅ Database-agnostic (works with MySQL, PostgreSQL, etc.)  
✅ Supports object relationships naturally

---


```java
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.Id;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Column;

@Entity                      // Marks this class as a JPA entity (a table in DB)
@Table(name = "students")    // Maps it to the table named "students"
public class Student {

    @Id                                          // Marks this field as the primary key
    @GeneratedValue(strategy = GenerationType.IDENTITY)  
    private Long id;                             // Maps to column 'id'

    @Column(name = "first_name", nullable = false, length = 50)
    private String firstName;                    // Maps to 'first_name' column

    @Column(name = "last_name", nullable = false, length = 50)
    private String lastName;                     // Maps to 'last_name' column

    @Column(name = "email", unique = true)
    private String email;                        // Maps to 'email' column

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
```

### 🔹 What’s happening:

- `@Entity` → Tells ORM this class represents a table.
    
- `@Table` → Specifies the table name in the database.
    
- `@Id` → Marks the primary key.
    
- `@GeneratedValue` → Defines how IDs are generated (auto-increment, etc.).
    
- `@Column` → Customizes column name, length, nullability, etc.
    

ORM frameworks (like **Hibernate**) use this mapping to automatically:  
✅ Create tables (if configured)  
✅ Insert/update/delete rows  
✅ Fetch objects as query results


##### [[25 - Spring Data JPA and ORM]]