
## ✅ **1. What is JPQL?**

JPQL is an **object-oriented query language** used in JPA/Hibernate to query **entities**, not tables.

- JPQL deals with **entity classes** and **their fields**.
    
- SQL deals with **tables** and **their columns**.
    

**JPQL → Java world**  
**SQL → Database world**

Example:

```jpql
SELECT s FROM Student s
```

Hibernate converts it to SQL automatically.

---

## ✅ **2. How JPQL Works (Under the Hood)**

1. You write queries using **entity names** and **Java field names**.
    
2. Hibernate reads your mappings (`@Entity`, `@Column`, etc.).
    
3. Hibernate translates JPQL → actual SQL.
    
4. Results are mapped back to entities.
    

**You never write table names or column names in JPQL.**

---

## ✅ **3. Key Components of JPQL**

### **A. Entity name**

Taken from the Java class name:

```java
@Entity
public class Student { }
```

JPQL uses **Student**, not `tbl_student`.

---

### **B. Entity alias**

Short name for easier writing:

```jpql
SELECT s FROM Student s
```

---

### **C. Entity fields**

JPQL uses **Java field names**, not DB column names:

```jpql
WHERE s.emailId = :email
```

Even if the DB column is `email_address`.

---

### **D. Parameters**

#### Named parameters:

```jpql
WHERE s.firstName = :name
```

#### Positional parameters:

```jpql
WHERE s.id = ?1
```

---

### **E. JPQL Clauses**

JPQL supports:

- `SELECT`
    
- `FROM`
    
- `WHERE`
    
- `GROUP BY`
    
- `HAVING`
    
- `ORDER BY`
    
- joins: `JOIN`, `LEFT JOIN`, etc.
    

---

## ✅ **4. JPQL Examples**

### **Simple query**

```java
@Query("SELECT s FROM Student s")
List<Student> getAllStudents();
```

### **Filter**

```java
@Query("SELECT s FROM Student s WHERE s.emailId = :email")
Student findByEmail(@Param("email") String email);
```

### **Partial fields**

```java
@Query("SELECT s.firstName, s.lastName FROM Student s")
List<Object[]> getNames();
```

### **Join**

```java
@Query("SELECT e FROM Enrollment e JOIN e.student s WHERE s.firstName = :name")
List<Enrollment> findByStudentName(String name);
```

---

## ✅ **5. Important JPQL-related Annotations**

### **`@Query`**

Allows writing custom JPQL (or SQL if `nativeQuery = true`):

```java
@Query("SELECT s FROM Student s WHERE s.age > :age")
List<Student> findOlderThan(int age);
```

---

### **`@Param`**

Binds method parameter → JPQL parameter:

```java
@Query("SELECT s FROM Student s WHERE s.firstName = :firstName")
Student findByName(@Param("firstName") String name);
```

---

### **`@NamedQuery`**

Defines reusable JPQL queries at the entity level:

```java
@Entity
@NamedQuery(
    name = "Student.findAllActive",
    query = "SELECT s FROM Student s WHERE s.active = true"
)
public class Student {}
```

Repository:

```java
List<Student> findAllActive();
```

---

### **`@Entity` / `@Table`**

Define entity and table name.

### **`@Column`**

Maps entity field to DB column—JPQL still uses the **field name**.

### **`@Embeddable` / `@Embedded`**

Used when querying embedded fields:

```java
List<Student> findByGuardian_Name(String name);
```

---

## ✅ **6. Why JPQL Exists**

SQL is **table-centric** → not great for OO design.  
JPQL is **entity-centric** → perfect for Java objects.

Hibernate handles the translation.

---

## 🔥 **TL;DR Summary**

- JPQL queries **entities**, not tables.
    
- JPQL uses **field names**, not column names.
    
- Hibernate converts JPQL → SQL automatically.
    
- `@Query` lets you define custom JPQL.
    
- `@Param` binds parameters.
    
- Joins and nested fields work just like navigating Java objects.
    




###### [[0 - Spring Framework]]