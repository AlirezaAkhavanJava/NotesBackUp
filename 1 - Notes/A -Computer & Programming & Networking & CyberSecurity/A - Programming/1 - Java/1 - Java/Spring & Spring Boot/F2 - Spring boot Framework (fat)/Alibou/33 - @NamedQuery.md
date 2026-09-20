
`@NamedQueries` (and the singular `@NamedQuery`) is a **JPA** (Java Persistence API) annotation that allows you to **define reusable, named JPQL or native SQL queries** directly on an entity class.

In the context of **Spring Data JPA**, `@NamedQueries` is **still fully supported** and very commonly used, especially when you want to:

- Keep queries close to the entity they belong to
- Reuse the same query in multiple repositories
- Have compile-time checked JPQL syntax (IDE can validate it)
- Avoid writing long method names in Spring Data query methods

### 1. Basic Syntax

```java
@Entity
@Table(name = "users")
@NamedQueries({
    @NamedQuery(
        name = "User.findByEmail",
        query = "SELECT u FROM User u WHERE u.email = :email"
    ),
    @NamedQuery(
        name = "User.findActiveByLastName",
        query = "SELECT u FROM User u " +
                "WHERE u.lastName = :lastName " +
                "AND u.active = true"
    ),
    @NamedQuery(
        name = "User.countByRole",
        query = "SELECT COUNT(u) FROM User u WHERE u.role = :role"
    ),
    @NamedQuery(
        name = "User.findByNameNative",
        query = "SELECT * FROM users WHERE first_name LIKE :namePattern",
        resultClass = User.class
    )
})
public class User implements Serializable {
    // fields, getters, setters...
}
```

### 2. How Spring Data JPA Uses Named Queries

Spring Data JPA automatically recognizes and registers `@NamedQuery` definitions.

You can then use them in several ways:

#### A. In a Spring Data JPA repository (most common)

```java
public interface UserRepository extends JpaRepository<User, Long> {

    // 1. Using the exact name of the @NamedQuery
    User findByEmail(String email);          // calls "User.findByEmail"

    // 2. Using @Query with the named query reference
    @Query("User.findActiveByLastName")
    List<User> findActiveUsersByLastName(@Param("lastName") String lastName);

    // 3. Using EntityManager directly (less common in Spring Data)
    // EntityManager.createNamedQuery("User.findByEmail")
}
```

**Spring Data convention**:  
If you name a repository method **exactly** the same as the `@NamedQuery` name (without the entity prefix), Spring Data will automatically use the named query.

```java
// This automatically uses the @NamedQuery "User.findByEmail"
User findByEmail(String email);
```

#### B. Using `@Query` annotation with named query reference

```java
@Query("User.countByRole")
long countUsersByRole(@Param("role") String role);
```

### 3. Important Attributes of `@NamedQuery`

| Attribute         | Description                                                                 | Required? |
|-------------------|-----------------------------------------------------------------------------|-----------|
| `name`            | Unique name of the query (usually `EntityName.queryName`)                   | Yes       |
| `query`           | The JPQL query string                                                      | Yes (unless native) |
| `resultClass`     | Class of the result (useful for native queries)                            | No        |
| `resultSetMapping`| Name of a `@SqlResultSetMapping` if using native query with complex mapping | No        |
| `hints`           | Query hints (e.g. caching, timeout, fetch size)                            | No        |
| `lockMode`        | Pessimistic/optimistic locking mode                                        | No        |

### 4. Native vs JPQL Named Queries

```java
@NamedQuery(
    name = "User.findRichUsers",
    query = "SELECT * FROM users WHERE salary > ?1",
    resultClass = User.class
)
```

```java
@NamedNativeQuery(   // ← separate annotation for native queries
    name = "User.findRichUsersNative",
    query = "SELECT * FROM users WHERE salary > :minSalary",
    resultClass = User.class
)
```

> **Important**: Use `@NamedNativeQuery` (and `@NamedNativeQueries`) when writing native SQL.

### 5. When to Use `@NamedQueries` vs Spring Data Method Names

| Use Case                                      | Recommended Approach                          |
|-----------------------------------------------|-----------------------------------------------|
| Simple queries (findByX, findAllByY…)         | Spring Data method name query derivation      |
| Complex JPQL (joins, subqueries, CASE…)       | `@NamedQuery`                                 |
| Performance-critical queries                  | `@NamedQuery` + query hints                   |
| Native SQL (database-specific features)       | `@NamedNativeQuery`                           |
| Queries reused in multiple repositories       | `@NamedQuery` on entity                       |
| Dynamic queries                               | Specifications, QueryDSL, Criteria API        |

### 6. Best Practices

1. **Naming convention**  
   Use `EntityName.queryName` (e.g., `User.findByEmailAndActive`, `Order.findRecentByCustomer`)

2. **Keep queries readable**  
   Break long queries into multiple lines with string concatenation.

3. **Use `@Param` for named parameters**  
   Avoid positional parameters (`?1`, `?2`) — they are hard to maintain.

4. **Consider placing in XML (less common today)**  
   ```xml
   <!-- persistence.xml or orm.xml -->
   <named-query name="User.findByEmail">
       <query>SELECT u FROM User u WHERE u.email = :email</query>
   </named-query>
   ```

5. **Use query hints when needed**

```java
@NamedQuery(
    name = "User.findByEmail",
    query = "SELECT u FROM User u WHERE u.email = :email",
    hints = @QueryHint(name = "org.hibernate.cacheable", value = "true")
)
```

### 7. Summary Table: Where to Define Queries in Spring Data JPA

| Technique                      | Location                     | Best for                              |
|--------------------------------|------------------------------|---------------------------------------|
| Method name query derivation   | Repository interface         | Simple queries                        |
| `@Query` with JPQL             | Repository interface         | Medium complexity                     |
| `@NamedQuery`                  | Entity class                 | Reusable, complex JPQL queries        |
| `@NamedNativeQuery`            | Entity class                 | Native SQL, vendor-specific features  |
| QueryDSL / Specifications      | Separate class / repository  | Very dynamic queries                  |
| Criteria API                   | Service / custom repo impl   | Fully dynamic, type-safe              |

### Final Recommendation (2024–2025 style)

```text
Most common modern pattern:
- Simple queries     → method names
- Medium complexity  → @Query on repository
- Complex / reusable → @NamedQueries on entity
- Native / DB-specific → @NamedNativeQueries on entity
- Highly dynamic     → QueryDSL or Specifications
```

Hope this clears up `@NamedQueries` in the context of Spring Data JPA!

---

Here are the most practical **real-world scenarios** where you **should** use `@NamedQueries` (or `@NamedQuery`) in a Spring Data JPA project, and why it’s often a better choice than alternatives.

| # | Scenario | Why use `@NamedQuery`? | Alternatives (and why they’re worse here) |
|---|---------------------------------------------|-------------------------------------------------------------|--------------------------------------------|
| 1 | **Complex JPQL queries** with multiple joins, subqueries, CASE, COALESCE, GROUP BY with HAVING, etc. | Method names become unreadable or impossible (`findAllBy...`). `@Query` on repository works, but `@NamedQuery` keeps entity + query together. | Long method names → unmaintainable<br>Long `@Query` on repo → repository becomes bloated |
| 2 | **Queries reused in multiple repositories** or services | One definition on the entity → can be called from anywhere via `EntityManager` or repository method name. | Duplicating `@Query` in multiple repos → violates DRY |
| 3 | **Performance-critical or frequently executed queries** (reporting, dashboards, batch jobs) | You can add query **hints** (`@QueryHint`) for caching, fetch size, read-only, etc. directly on the entity. | Method names and plain `@Query` don’t support hints easily |
| 4 | **Native SQL queries** that use database-specific features (e.g. PostgreSQL JSONB, MySQL GROUP_CONCAT, Oracle hierarchical queries) | `@NamedNativeQuery` is the cleanest place to define them. | `@Query(nativeQuery = true)` on repo clutters the repository |
| 5 | **Queries that return projections, DTOs, or custom result sets** (especially with native queries + `@SqlResultSetMapping`) | You can define the mapping once on the entity and reuse it. | Repeating `@SqlResultSetMapping` or constructor expressions in multiple places → maintenance hell |
| 6 | **Team prefers queries near the entity** (domain-driven design style) | Keeps domain logic (including queries) close to the entity, improving cohesion. | Queries scattered in repositories → harder to find |
| 7 | **Legacy code migration** or when moving from raw JPA/Hibernate to Spring Data JPA | `@NamedQueries` were already defined on entities → just keep them and let Spring Data use them automatically. | Rewriting everything as method names or `@Query` → unnecessary work |
| 8 | **Queries that are part of the domain model** (business invariants, reports required by the business) | Makes it clear that this query is a core part of the entity’s behavior. | Hides important business queries in repository |
| 9 | **You want compile-time / IDE validation** of JPQL | IDEs (IntelliJ, Eclipse) can validate JPQL syntax inside `@NamedQuery` more reliably than in string-based `@Query` in repositories. | `@Query("...")` → less IDE support for syntax checking |
| 10 | **You need to override default Spring Data queries** | Example: override `findAll()` or `findById()` with a custom implementation that includes hints or locking. | `findAll()` method override in repository is less elegant |

### Quick Decision Guide (When to use `@NamedQuery` vs other options)

| Condition | Recommended Choice |
|----------|---------------------|
| Query is simple (1-2 conditions, no joins) | Spring Data method name |
| Query has joins, subqueries, complex conditions | `@NamedQuery` or `@Query` on repository |
| Query is used in **multiple places** | `@NamedQuery` on entity |
| Query uses **native SQL** or DB-specific syntax | `@NamedNativeQuery` on entity |
| Query needs **query hints** (cache, fetch size, timeout…) | `@NamedQuery` + `@QueryHint` |
| Query returns **DTO/projection** with constructor or mapping | `@NamedQuery` + `@SqlResultSetMapping` |
| Query is **very dynamic** (filters change at runtime) | Specifications / QueryDSL / Criteria API |
| You want to keep domain logic close to entity | `@NamedQuery` |

### Real-world examples where `@NamedQuery` shines

1. **User search with multiple optional filters**  
   → One `@NamedQuery` with dynamic conditions (using COALESCE or CASE) instead of 10 method names.

2. **Reporting queries** (e.g. monthly sales per product)  
   → Complex GROUP BY + JOIN + calculations → `@NamedQuery` + DTO projection.

3. **Soft-deleted entities**  
   ```java
   @NamedQuery(name = "Product.findAllActive", query = "SELECT p FROM Product p WHERE p.deleted = false")
   ```

4. **Audit / history queries**  
   ```java
   @NamedNativeQuery(name = "Order.findHistory", query = "SELECT * FROM order_audit WHERE order_id = :id ORDER BY revision DESC")
   ```

5. **High-performance cacheable queries**  
   ```java
   @NamedQuery(
       name = "Category.findAllWithProducts",
       query = "SELECT c FROM Category c JOIN FETCH c.products",
       hints = @QueryHint(name = "org.hibernate.cacheable", value = "true")
   )
   ```

### Summary: Use `@NamedQueries` when…

- The query is **complex** or **reused**
- You need **native SQL**, **query hints**, or **result set mappings**
- You want to keep queries **close to the entity** (better cohesion)
- You want **better IDE support** and **DRY** principle

Otherwise, stick with **method name queries** or simple `@Query` annotations on the repository for most CRUD operations.

##### Tags : [[0 - Spring Framework]]