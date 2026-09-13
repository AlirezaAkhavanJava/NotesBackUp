
### **What it is**

`JpaRepository` is an **interface** in Spring Data JPA that provides **ready-made CRUD (Create, Read, Update, Delete) and pagination operations** for your entities. It extends two other interfaces:

- `PagingAndSortingRepository` → for paging & sorting.
    
- `CrudRepository` → for basic CRUD operations.
    

Basically, if your entity is like a cow , `JpaRepository` is the farm that takes care of feeding it, milking it, and keeping it alive, without you writing the boring chores manually.

---

### **Basic Syntax**

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Custom queries can be added here
    User findByUsername(String username);
}
```

- `User` → Your entity class
    
- `Long` → Type of your primary key (can be `Integer`, `UUID`, etc.)
    

---

### **Commonly Used Methods**

`JpaRepository` gives you tons of methods out of the box:

|Method|Description|
|---|---|
|`save(S entity)`|Insert or update an entity|
|`saveAll(Iterable<S> entities)`|Save multiple entities|
|`findById(ID id)`|Find entity by primary key|
|`existsById(ID id)`|Check if entity exists|
|`findAll()`|Get all entities|
|`findAllById(Iterable<ID> ids)`|Get multiple entities by IDs|
|`deleteById(ID id)`|Delete by ID|
|`delete(T entity)`|Delete entity|
|`deleteAll()`|Delete all entities|
|`count()`|Count entities|
|`findAll(Sort sort)`|Get all entities sorted|
|`findAll(Pageable pageable)`|Get paginated entities|

---

### **Custom Queries**

You can add methods by **naming convention**:

```java
List<User> findByEmail(String email);
List<User> findByAgeGreaterThan(int age);
```

Or using **@Query**:

```java
@Query("SELECT u FROM User u WHERE u.email LIKE %?1")
List<User> searchByEmail(String emailPart);
```

---

### **Why use JpaRepository?**

- No need to write SQL for basic CRUD operations.
    
- Supports pagination and sorting out of the box.
    
- Integrates seamlessly with Spring Boot.
    
- Lets you focus on **business logic**, not boilerplate.
    

---

### This is a **complete cheat sheet for `JpaRepository`**—hierarchy, syntax, and common methods : 



## **1. JpaRepository Hierarchy**

```
java.lang.Object
   └─ org.springframework.data.repository.Repository<T, ID>
       └─ org.springframework.data.repository.CrudRepository<T, ID>
           └─ org.springframework.data.repository.PagingAndSortingRepository<T, ID>
               └─ org.springframework.data.jpa.repository.JpaRepository<T, ID>
```

**Explanation:**

- `Repository` → marker interface, does nothing by itself.
    
- `CrudRepository` → basic CRUD: save, delete, find.
    
- `PagingAndSortingRepository` → adds pagination & sorting.
    
- `JpaRepository` → adds JPA-specific features like batch operations and flushing.
    

---

## **2. Syntax to Define a Repository**

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Custom query methods
    User findByUsername(String username);
    List<User> findByAgeGreaterThan(int age);
}
```

- `User` → Entity class
    
- `Long` → Primary key type
    

---

## **3. Common Methods in JpaRepository**

|Category|Method|Description|
|---|---|---|
|**CRUD**|`save(S entity)`|Save or update entity|
||`saveAll(Iterable<S> entities)`|Save multiple entities|
||`findById(ID id)`|Find entity by ID|
||`existsById(ID id)`|Check if entity exists|
||`findAll()`|Get all entities|
||`findAllById(Iterable<ID> ids)`|Get multiple entities by IDs|
||`deleteById(ID id)`|Delete entity by ID|
||`delete(T entity)`|Delete entity|
||`deleteAll()`|Delete all entities|
|**Pagination & Sorting**|`findAll(Sort sort)`|Get sorted entities|
||`findAll(Pageable pageable)`|Get paginated entities|
|**Batch & Flush**|`saveAndFlush(S entity)`|Save and flush immediately|
||`flush()`|Flush pending changes to DB|
|**Counting**|`count()`|Count all entities|

---

## **4. Custom Queries**

**Derived query from method name:**

```java
List<User> findByEmail(String email);
List<User> findByAgeGreaterThan(int age);
List<User> findByUsernameAndActive(String username, boolean active);
```

**Using @Query:**

```java
import org.springframework.data.jpa.repository.Query;

@Query("SELECT u FROM User u WHERE u.email LIKE %?1")
List<User> searchByEmail(String emailPart);

@Query(value = "SELECT * FROM users WHERE age > ?1", nativeQuery = true)
List<User> searchByAgeNative(int age);
```

---

## **5. Notes & Tips**

- `JpaRepository` **requires a JPA entity** (annotated with `@Entity`).
    
- `ID` type must match the primary key type in your entity.
    
- Works **out of the box** with Spring Boot—no implementation class needed.
    
- Can combine **derived methods + @Query** for flexibility.
    
- Use **`Pageable`** for paging:
    

```java
Page<User> findAll(Pageable pageable);
```


##### Tags : [[0 - Spring Framework]]