
In **Java Persistence API (JPA)**, the`@Query`annotation is *used to define custom JPQL (Java Persistence Query Language) or  native SQL queries  directly on repository methods  in Spring Data JPA interfaces.*

It allows you to write queries that go beyond the method name derivation mechanism.

---

### Basic Syntax

```java
@Query("your-query-here")
ReturnType methodName(Parameters);
```

---

### 1. **JPQL Query (Default)**

Uses entity names and properties (not database table/column names).

```java
@Query("SELECT u FROM User u WHERE u.email = ?1")
User findByEmail(String email);
```

Or with named parameters:

```java
@Query("SELECT u FROM User u WHERE u.email = :email")
User findByEmail(@Param("email") String email);
```

---

### 2. **Native SQL Query**

Set `nativeQuery = true` to use raw SQL.

```java
@Query(value = "SELECT * FROM users WHERE email = ?1", nativeQuery = true)
User findByEmailNative(String email);
```

> **Warning**: Native queries bypass JPA's entity mapping — ensure column names match entity field names or use `@SqlResultSetMapping`.

---

### 3. **Modifying Queries (UPDATE / DELETE)**

Use `@Modifying` with `@Query` for non-select operations.

```java
@Modifying
@Query("UPDATE User u SET u.active = false WHERE u.id = :id")
int deactivateUser(@Param("id") Long id);
```

For transactions, add `@Transactional` on the service method.

---

### 4. **Pagination & Sorting**

Works seamlessly with `Pageable`:

```java
@Query("SELECT u FROM User u WHERE u.status = :status")
Page<User> findByStatus(@Param("status") String status, Pageable pageable);
```

---

### 5. **Count Query for Pagination**

For custom queries with pagination, define a count query:

```java
@Query(value = "SELECT u FROM User u WHERE u.age > :age",
       countQuery = "SELECT COUNT(u) FROM User u WHERE u.age > :age")
Page<User> findAdults(@Param("age") int age, Pageable pageable);
```

---

### Example Repository

```java
public interface UserRepository extends JpaRepository<User, Long> {

    @Query("SELECT u FROM User u WHERE u.email = ?1")
    User findByEmail(String email);

    @Query(value = "SELECT * FROM users WHERE status = ?1", nativeQuery = true)
    List<User> findActiveUsersNative(String status);

    @Modifying
    @Query("DELETE FROM User u WHERE u.lastLogin < :date")
    int deleteInactiveUsers(@Param("date") LocalDateTime date);
}
```

---

### Key Points

| Feature               | Detail |
|-----------------------|--------|
| Default query type    | JPQL |
| Native SQL            | `nativeQuery = true` |
| Parameters            | `?1`, `?2` or `:name` with `@Param` |
| DML (UPDATE/DELETE)   | Requires `@Modifying` |
| Transactions          | Required for modifying queries |
| Entity-based          | JPQL uses **entity names & fields** |


##### Tags : [[0 - Spring Framework]]