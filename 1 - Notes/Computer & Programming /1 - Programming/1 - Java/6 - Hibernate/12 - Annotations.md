
In **Hibernate / JPA**, **annotations** are used to define **mappings between Java classes (entities) and database tables**, as well as relationships and constraints. Here’s a structured overview:

---

## 🔹 1. **Entity Definition**

|Annotation|Purpose|
|---|---|
|`@Entity`|Marks a class as a JPA entity (table in DB).|
|`@Table(name = "table_name")`|Optional: specifies table name; otherwise class name is used.|
|`@Id`|Marks the primary key field.|
|`@GeneratedValue(strategy = GenerationType.IDENTITY)`|Auto-generates primary key values (auto-increment).|
|`@Column(name = "column_name", nullable = false, unique = true, length = 50)`|Maps a field to a column; allows customization.|

**Example:**

```java
@Entity
@Table(name = "students")
public class Student {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "student_name", nullable = false)
    private String name;
}
```

---

## 🔹 2. **Relationship Annotations**

|Annotation|Purpose|
|---|---|
|`@OneToOne`|One entity is linked to another (1:1).|
|`@OneToMany`|One entity maps to many entities (1:N).|
|`@ManyToOne`|Many entities map to one entity (N:1).|
|`@ManyToMany`|Many entities link to many entities (N:N).|
|`@JoinColumn(name = "column_name")`|Specifies foreign key column for relationships.|
|`@JoinTable(name = "table_name", joinColumns = ..., inverseJoinColumns = ...)`|For many-to-many join tables.|

---

## 🔹 3. **Other Useful Annotations**

|Annotation|Purpose|
|---|---|
|`@Transient`|Field is not persisted in the database.|
|`@Enumerated(EnumType.STRING)`|Persists enum values as strings (or `ORDINAL` as integers).|
|`@Temporal(TemporalType.DATE/TIME/TIMESTAMP)`|Maps `java.util.Date` or `Calendar` to SQL date/time types.|
|`@Lob`|Maps large objects (CLOB/BLOB).|
|`@Version`|Used for optimistic locking (versioning).|

---

## 🔹 4. **Auditing / Timestamps (optional)**

|Annotation|Purpose|
|---|---|
|`@CreationTimestamp`|Automatically sets creation time.|
|`@UpdateTimestamp`|Automatically updates modification time.|

---

### 🔹 Example with Relationships and Auditing

```java
@Entity
@Table(name = "students")
public class Student {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @ManyToOne
    @JoinColumn(name = "class_id")
    private SchoolClass schoolClass;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
```

---

### 🧭 Summary

> Hibernate / JPA annotations define **table mappings, relationships, constraints, and entity behavior**.  
> Using them correctly allows Hibernate to generate SQL automatically and manage objects seamlessly.



##### Tags : [[1 - ORM 🍪]]