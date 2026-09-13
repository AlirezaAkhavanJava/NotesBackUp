
In Hibernate (and JPA), there are **multiple ways to fetch data** from the database. Each approach has its own behavior, flexibility, and use cases. Here's a detailed overview:

---

## 🔹 1. **Session Methods**

### 1.1 `get(Class<T> clazz, Serializable id)`

- Fetches an entity **by primary key**.
    
- Returns `null` if the entity doesn’t exist.
    
- **Eagerly loads** the entity from the database.
    

```java
Student s = session.get(Student.class, 1L);
```

### 1.2 `load(Class<T> clazz, Serializable id)`

- Fetches an entity **lazily** using a proxy.
    
- Throws `ObjectNotFoundException` if the entity doesn’t exist.
    

```java
Student s = session.load(Student.class, 1L);
```

---

## 🔹 2. **HQL (Hibernate Query Language)**

- Object-oriented query language similar to SQL but **operates on entities**, not tables.
    

```java
List<Student> students = session.createQuery("FROM Student WHERE name = :name", Student.class)
                                .setParameter("name", "Ethan")
                                .getResultList();
```

- Supports joins, ordering, grouping, and more.
    

---

## 🔹 3. **Criteria API (Programmatic / Type-safe Queries)**

- Allows building queries **dynamically in Java code**.
    
- Type-safe and avoids string concatenation errors.
    

```java
CriteriaBuilder cb = session.getCriteriaBuilder();
CriteriaQuery<Student> cq = cb.createQuery(Student.class);
Root<Student> root = cq.from(Student.class);
cq.select(root).where(cb.equal(root.get("name"), "Ethan"));
List<Student> students = session.createQuery(cq).getResultList();
```

---

## 🔹 4. **Native SQL Queries**

- Executes **raw SQL** directly.
    
- Useful when HQL or Criteria cannot express a query.
    

```java
List<Student> students = session.createNativeQuery("SELECT * FROM students WHERE name = :name", Student.class)
                                .setParameter("name", "Ethan")
                                .getResultList();
```

---

## 🔹 5. **Named Queries**

- Predefined queries in the entity class for reuse.
    

```java
@Entity
@NamedQuery(name = "Student.findByName", query = "FROM Student WHERE name = :name")
public class Student { ... }

// Usage
List<Student> students = session.createNamedQuery("Student.findByName", Student.class)
                                .setParameter("name", "Ethan")
                                .getResultList();
```

---

## 🔹 6. **Fetching Strategies (Lazy vs Eager)**

- **Lazy**: Entity or collection loaded **only when accessed**. (`@OneToMany(fetch = FetchType.LAZY)`)
    
- **Eager**: Loaded **immediately** with the parent entity. (`@ManyToOne(fetch = FetchType.EAGER)`)
    

```java
Student s = session.get(Student.class, 1L);
List<Course> courses = s.getCourses(); // triggers DB query if LAZY
```

---

## 🔹 Summary Table

|Method|Type|Fetching|Notes|
|---|---|---|---|
|`get()`|Session|Eager|Returns null if not found|
|`load()`|Session|Lazy|Throws exception if not found|
|HQL|Query|Flexible|Object-oriented SQL|
|Criteria API|Query|Flexible / type-safe|Build queries programmatically|
|Native SQL|Query|Flexible|Use raw SQL|
|Named Query|Query|Flexible|Predefined reusable queries|
|Lazy/Eager|Strategy|Control when data is loaded|Annotation-driven|

---

💡 **Tip:**

- Use `get()` for simple primary key fetch.
    
- Use **HQL/Criteria** for dynamic queries.
    
- Use **Native SQL** only when needed.
    
- Understand **lazy vs eager** to avoid `LazyInitializationException`.
    
---


## 🔹 1. `Session.load(Class<T> entityClass, Serializable id)`

- **Fetches a single entity by its primary key (id)**.
    
- Returns a **proxy** object; data is fetched from DB **only when accessed** (lazy).
    
- Throws `ObjectNotFoundException` if entity doesn’t exist.
    

```java
Student s = session.load(Student.class, 1L);
System.out.println(s.getName());  // triggers DB query
```

---

## 🔹 2. `Session.get(Class<T> entityClass, Serializable id)`

- Also fetches an entity by primary key.
    
- **Eagerly fetches** from the database immediately.
    
- Returns `null` if entity doesn’t exist.
    

```java
Student s = session.get(Student.class, 1L);
```

---

## 🔹 3. `Session.byId(Class<T> entityClass)` (Hibernate 6+)

- Returns a **`IdentifierLoadAccess`** object for fluent API.
    
- You can then call:
    
    - `load(id)` → returns proxy (lazy)
        
    - `getReference(id)` → proxy, like `load()`
        
    - `get(id)` → fetch immediately
        

```java
Student s = session.byId(Student.class).load(1L);  // lazy proxy
Student s2 = session.byId(Student.class).getReference(1L); // also lazy
Student s3 = session.byId(Student.class).get(1L); // eager fetch
```

---

## 🔹 4. `Session.byNaturalId(Class<T> entityClass)`

- Fetch by a **unique natural key** instead of the primary key.
    
- Useful for fields like `email` or `username`.
    

```java
Student s = session.byNaturalId(Student.class)
                   .using("email", "ethan@mail.com")
                   .load();
```

---

## 🔹 5. `Session.createQuery(String hql, Class<T> type)`

- Create **HQL/JPQL queries** for fetching data.
    
- Flexible, supports joins, conditions, ordering.
    

```java
List<Student> students = session.createQuery(
        "FROM Student s WHERE s.name = :name", Student.class)
        .setParameter("name", "Ethan")
        .getResultList();
```

---

## 🔹 6. **Criteria API**

- Type-safe, programmatic way to build queries.
    

```java
CriteriaBuilder cb = session.getCriteriaBuilder();
CriteriaQuery<Student> cq = cb.createQuery(Student.class);
Root<Student> root = cq.from(Student.class);
cq.select(root).where(cb.equal(root.get("name"), "Ethan"));
List<Student> students = session.createQuery(cq).getResultList();
```

---

## 🔹 7. `Session.createNativeQuery(String sql, Class<T> type)`

- Fetch using **raw SQL**, mapping results to entities.
    

```java
List<Student> students = session.createNativeQuery(
    "SELECT * FROM students WHERE name = :name", Student.class)
    .setParameter("name", "Ethan")
    .getResultList();
```

---

### 🔹 Summary Table

|Method|Fetch Type|Returns if not found|Notes|
|---|---|---|---|
|`get()`|Eager|`null`|Fetches immediately|
|`load()`|Lazy|Exception|Returns proxy|
|`byId().get()`|Eager|`null`|Fluent API (6+)|
|`byId().load()`|Lazy|Exception|Fluent API (6+)|
|`byNaturalId().load()`|Lazy|Exception|Fetch by natural unique key|
|HQL / JPQL|Flexible|Empty list|Queries using entity names|
|Criteria API|Flexible / type-safe|Empty list|Programmatic query builder|
|Native SQL|Flexible|Empty list|Raw SQL mapping|

---

💡 **Tip:**

- Use `byId()` in Hibernate 6+ for **cleaner, fluent fetching**.
    
- Use `load()` when you **don’t need immediate DB access** (lazy).
    
- Use `get()` for **immediate retrieval**.
    
- `byNaturalId()` is perfect for unique fields like `email`.
    


##### Tags : [[1 - ORM 🍪]]