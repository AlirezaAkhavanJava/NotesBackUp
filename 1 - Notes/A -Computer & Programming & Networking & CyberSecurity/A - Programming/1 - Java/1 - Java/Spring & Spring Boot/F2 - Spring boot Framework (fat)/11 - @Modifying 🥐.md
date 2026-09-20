


## **1. What `@Modifying` Is**

`@Modifying` is an **annotation** used on repository methods that execute **update or delete queries** (DML operations) with **JPQL or native SQL**.

By default, Spring Data JPA assumes queries are **select-only**. If you want to modify data (`UPDATE`, `DELETE`), you **must** use `@Modifying`.

---

## **2. Syntax Example**

```java
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;
import jakarta.transaction.Transactional;

@Repository
public interface UserRepository extends CrudRepository<User, Long> {

    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.active = false WHERE u.lastLogin < :date")
    int deactivateInactiveUsers(LocalDate date);

    @Modifying
    @Transactional
    @Query("DELETE FROM User u WHERE u.active = false")
    int deleteInactiveUsers();
}
```

### **Explanation:**

- `@Modifying` → tells Spring Data this is an **update/delete operation**.
    
- `@Transactional` → required because updates/deletes must run inside a transaction.
    
- `int` return type → usually the **number of rows affected**.
    

---

## **3. Notes**

1. Without `@Modifying`, Spring will throw:
    
    ```
    org.springframework.dao.InvalidDataAccessApiUsageException: 
    Executing an update/delete query; use @Modifying
    ```
    
2. Works with **JPQL** or **native SQL** (`nativeQuery = true` in `@Query`).
    
3. Combine with **parameters** using `:paramName`.
    



##### Tags : [[0 - Spring Framework]]