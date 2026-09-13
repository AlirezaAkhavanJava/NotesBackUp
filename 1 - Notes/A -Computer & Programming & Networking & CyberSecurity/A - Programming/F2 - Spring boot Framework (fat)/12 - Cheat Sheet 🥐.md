**JPA Repository Annotations Cheat Sheet**—all the important ones you’ll use in Spring Data JPA with examples.

---

# **🐐 JPA Repository Annotations Cheat Sheet**

|Annotation|Purpose|Key Notes|Example|
|---|---|---|---|
|**@Repository**|Marks a class as a Spring Data repository|Optional if using `JpaRepository`, but helps with exception translation|`@Repository public interface UserRepository extends JpaRepository<User, Long> {}`|
|**@Query**|Defines a custom JPQL or SQL query|Use `nativeQuery = true` for SQL|`@Query("SELECT u FROM User u WHERE u.email = ?1") User findByEmail(String email);`|
|**@Modifying**|Marks a method as an **update/delete operation**|Must be used with `@Transactional`|`@Modifying @Transactional @Query("DELETE FROM User u WHERE u.active = false") int deleteInactiveUsers();`|
|**@Transactional**|Runs a method inside a **database transaction**|Required for `@Modifying` operations; can also set `readOnly = true`|`@Transactional(readOnly = true) List<User> findAllActiveUsers();`|
|**@Param**|Binds method parameters to query parameters|Useful for named parameters in `@Query`|`@Query("SELECT u FROM User u WHERE u.email = :email") User findByEmail(@Param("email") String email);`|
|**@Lock**|Applies a database lock to queries|Supports `LockModeType.PESSIMISTIC_READ/WRITE`|`@Lock(LockModeType.PESSIMISTIC_WRITE) User findById(Long id);`|
|**@Procedure**|Calls a **stored procedure** in the database|Maps procedure name and parameters|`@Procedure(name = "update_user_status") void updateStatus(Long id);`|
|**@Transactional(readOnly = true)**|Optimizes queries that **do not modify data**|Avoid unnecessary flush/lock|`@Transactional(readOnly = true) List<User> findAll();`|
|**@EnableJpaRepositories**|Configures Spring to scan for JPA repositories|Usually placed in `@Configuration` class|`@EnableJpaRepositories(basePackages = "com.example.repo")`|

---

## **Quick Examples Together**

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // Select query with named parameter
    @Query("SELECT u FROM User u WHERE u.email = :email")
    User findByEmail(@Param("email") String email);

    // Update query
    @Modifying
    @Transactional
    @Query("UPDATE User u SET u.active = false WHERE u.lastLogin < :date")
    int deactivateInactiveUsers(@Param("date") LocalDate date);

    // Delete query
    @Modifying
    @Transactional
    @Query("DELETE FROM User u WHERE u.active = false")
    int deleteInactiveUsers();

    // Read-only query
    @Transactional(readOnly = true)
    List<User> findAllActiveUsers();
}
```

---

✅ **Key Tips:**

- Always combine `@Modifying` with `@Transactional` for updates/deletes.
    
- Use `@Param` for readability and safety with named parameters.
    
- `@Transactional(readOnly = true)` helps optimize select queries.
    
- JPQL is **entity-focused**, SQL (`nativeQuery = true`) is **table-focused**.
    

##### Tags  : [[0 - Spring Framework]]