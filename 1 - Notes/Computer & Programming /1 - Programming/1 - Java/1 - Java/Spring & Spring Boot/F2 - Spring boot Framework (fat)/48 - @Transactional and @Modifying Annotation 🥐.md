

### **1️⃣ `@Transactional`**

- **Purpose:** Manages database transactions automatically.
    
- **Where it goes:** On a **service method** or **repository method**.
    
- **Behavior:**
    
    - Starts a transaction before the method runs.
        
    - Commits the transaction if the method completes successfully.
        
    - Rolls back the transaction if an exception occurs (by default, unchecked exceptions only).
        

**Example:**

```java
@Service
public class StudentService {

    @Transactional
    public void updateStudentEmail(Long id, String email) {
        Student student = studentRepository.findById(id).orElseThrow();
        student.setEmail(email);
        // No explicit save needed if using JPA (because the entity is managed)
    }
}
```

---

### **2️⃣ `@Modifying`**

- **Purpose:** Needed when you execute **update or delete queries** via `@Query` in Spring Data JPA.
    
- **Why:** Spring Data JPA assumes queries are `SELECT` by default. `@Modifying` tells it that the query **changes data**.
    
- **Typical combo:** `@Modifying` + `@Transactional`.
    

**Example:**

```java
@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {

    @Modifying
    @Transactional
    @Query("UPDATE Student s SET s.email = :email WHERE s.id = :id")
    int updateEmail(@Param("id") Long id, @Param("email") String email);
}
```

**Notes:**

- `@Transactional` is required here because updates/deletes need a transaction. Without it, the operation may fail.
    
- `@Modifying` also supports `clearAutomatically = true` to detach entities after the operation.
    

---

✅ **Quick Rule:**

- `@Transactional` = wraps method in a transaction.
    
- `@Modifying` = tells Spring JPA “this is an update/delete, not a select”.
    

---




###### Tags : [[0 - Spring Framework]]