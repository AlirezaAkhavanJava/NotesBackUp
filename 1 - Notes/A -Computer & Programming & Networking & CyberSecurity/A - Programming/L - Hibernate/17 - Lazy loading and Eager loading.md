


## 🔹 1. **Lazy Loading**

**Definition:**

- Data for an entity or a collection is **not loaded from the database immediately**.
    
- Hibernate returns a **proxy** object, and the actual database query executes **only when you access the data**.
    

**Key Points:**

- Saves memory and improves performance if the data is large or rarely used.
    
- Can cause `LazyInitializationException` if accessed **outside an active session**.
    

**Annotation Example:**

```java
@Entity
public class Student {
    @Id
    private Long id;

    @OneToMany(mappedBy = "student", fetch = FetchType.LAZY)
    private List<Course> courses; // Not loaded yet
}
```

**Usage:**

```java
Student s = session.get(Student.class, 1L);
List<Course> courses = s.getCourses(); // DB query happens here
```

---

## 🔹 2. **Eager Loading**

**Definition:**

- Data for an entity or collection is **loaded immediately** with the parent entity.
    
- Hibernate executes **additional SQL** or joins to fetch everything upfront.
    

**Key Points:**

- Guarantees data is available immediately.
    
- Can slow down performance if the data is large or you don’t always need it.
    

**Annotation Example:**

```java
@OneToMany(mappedBy = "student", fetch = FetchType.EAGER)
private List<Course> courses; // Loaded immediately with Student
```

**Usage:**

```java
Student s = session.get(Student.class, 1L);
// Courses already loaded automatically
List<Course> courses = s.getCourses();
```

---

## 🔹 3. **Comparison Table**

|Feature|Lazy Loading|Eager Loading|
|---|---|---|
|When data is loaded|On access (proxy)|Immediately with parent|
|Performance|Efficient if not always needed|Can be heavy if many children|
|SQL Queries|Delayed, may trigger extra queries|Immediate, may use joins|
|Risk|`LazyInitializationException` outside session|No lazy issues|
|Annotation|`fetch = FetchType.LAZY`|`fetch = FetchType.EAGER`|

---

## 🔹 4. **Best Practices**

1. **Default to LAZY** for collections (`@OneToMany`, `@ManyToMany`).
    
2. Use **EAGER** only when you **always need the data**.
    
3. Avoid `EAGER` on large collections — can cause **N+1 queries problem**.
    
4. Consider **fetch joins in HQL/JPQL** for selective eager fetching without changing entity mapping.
    

**Example of fetch join (eager fetching in query):**

```java
List<Student> students = session.createQuery(
    "SELECT s FROM Student s JOIN FETCH s.courses", Student.class
).getResultList();
```

---

💡 **Senior Tip:**

- Lazy loading is generally preferred for scalability.
    
- Eager loading is convenient but can **kill performance** if used indiscriminately.
    


##### Tags : [[2 - Hibernate 🍪]]