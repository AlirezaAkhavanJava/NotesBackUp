
Here is a **complete and detailed guide** to **Spring Data JPA Specifications** — one of the most powerful tools for writing dynamic, reusable, and type-safe queries in Spring Data JPA.

### What is a Specification?

A `Specification<T>` is a **functional interface** (from `org.springframework.data.jpa.domain.Specification`) that allows you to build **dynamic JPQL queries** in a type-safe, reusable, and composable way.

It is the Spring Data JPA equivalent of the **Criteria API**, but much more convenient and readable.

```java
public interface Specification<T> {
    Predicate toPredicate(Root<T> root, CriteriaQuery<?> query, CriteriaBuilder cb);
}
```

### Core Idea

You define small, reusable **query conditions** (predicates) and then **combine them** using `and()`, `or()`, `not()`.

### 1. Basic Usage

```java
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {
    // JpaSpecificationExecutor gives you the findAll(Specification) methods
}
```

```java
// Repository usage
List<User> users = userRepository.findAll(
    (root, query, cb) -> cb.equal(root.get("email"), "john@example.com")
);
```

### 2. Reusable Specification Classes (Recommended)

```java
public class UserSpecifications {

    public static Specification<User> hasEmail(String email) {
        return (root, query, cb) -> 
            cb.equal(root.get("email"), email);
    }

    public static Specification<User> isActive() {
        return (root, query, cb) -> 
            cb.isTrue(root.get("active"));
    }

    public static Specification<User> hasLastNameLike(String lastName) {
        return (root, query, cb) -> 
            cb.like(cb.lower(root.get("lastName")), "%" + lastName.toLowerCase() + "%");
    }

    public static Specification<User> createdAfter(LocalDate date) {
        return (root, query, cb) -> 
            cb.greaterThanOrEqualTo(root.get("createdAt"), date.atStartOfDay());
    }
}
```

Usage:

```java
Specification<User> spec = UserSpecifications.hasEmail("john@example.com")
    .and(UserSpecifications.isActive())
    .and(UserSpecifications.hasLastNameLike("doe"));

List<User> users = userRepository.findAll(spec);
```

### 3. Combining Specifications

| Method            | Description                              |
|-------------------|------------------------------------------|
| `spec1.and(spec2)`| Logical AND                              |
| `spec1.or(spec2)` | Logical OR                               |
| `spec1.not()`     | Logical NOT                              |
| `Specification.where(spec)` | Starts a chain (returns spec unchanged) |

```java
Specification<User> spec = Specification.where(UserSpecifications.isActive())
    .and(UserSpecifications.hasLastNameLike("smith"))
    .or(UserSpecifications.hasEmail("admin@example.com"));
```

### 4. Advanced Examples

#### A. Joins

```java
public static Specification<User> hasOrderWithStatus(OrderStatus status) {
    return (root, query, cb) -> {
        // Avoid multiple joins for the same association
        query.distinct(true);
        
        Join<User, Order> orders = root.join("orders", JoinType.LEFT);
        return cb.equal(orders.get("status"), status);
    };
}
```

#### B. Fetching associations (eager fetch)

```java
public static Specification<User> fetchOrders() {
    return (root, query, cb) -> {
        root.fetch("orders", JoinType.LEFT);
        query.distinct(true); // important with fetch
        return cb.conjunction(); // always true
    };
}
```

#### C. Dynamic conditions (null-safe)

```java
public static Specification<User> search(String searchTerm) {
    return (root, query, cb) -> {
        if (StringUtils.isBlank(searchTerm)) {
            return cb.conjunction(); // no filter
        }
        
        String pattern = "%" + searchTerm.toLowerCase() + "%";
        Predicate firstName = cb.like(cb.lower(root.get("firstName")), pattern);
        Predicate lastName  = cb.like(cb.lower(root.get("lastName")), pattern);
        Predicate email     = cb.like(cb.lower(root.get("email")), pattern);
        
        return cb.or(firstName, lastName, email);
    };
}
```

#### D. Pagination + Sorting + Specification

```java
Specification<User> spec = ...;

Page<User> page = userRepository.findAll(spec, PageRequest.of(0, 20, Sort.by("lastName").ascending()));
```

### 5. Common Patterns & Best Practices

| Pattern                              | Recommendation |
|--------------------------------------|----------------|
| **Naming**                           | `UserSpecifications`, `ProductSpecs`, etc. |
| **Package**                          | `domain.specification` or `repository.spec` |
| **Null-safe**                        | Always check input params → return `cb.conjunction()` if no filter |
| **Avoid N+1**                        | Use `fetch()` in specs when needed |
| **Reuse**                            | Build small, atomic specs and compose them |
| **Distinct**                         | Call `query.distinct(true)` when joining |
| **Performance**                      | Avoid unnecessary joins/fetches |

### 6. Specification vs Other Approaches (2025 Perspective)

| Approach                     | Best for                                      | Type-Safe? | Dynamic? | Reusable? |
|------------------------------|-----------------------------------------------|------------|----------|-----------|
| Method name queries          | Simple static queries                         | Yes        | No       | No        |
| `@Query` with JPQL           | Medium complexity, static                     | Partial    | No       | Yes       |
| `@NamedQuery`                | Reusable complex static queries               | Partial    | No       | Yes       |
| **Specification**            | **Dynamic, composable, type-safe queries**    | Yes        | Yes      | Yes       |
| QueryDSL                     | Very complex dynamic queries, fluent API      | Yes        | Yes      | Yes       |
| Criteria API (raw)           | Full control, low-level                       | Yes        | Yes      | No        |

### 7. When to Use Specification (Real Scenarios)

| Scenario | Use Specification? |
|----------|---------------------|
| Search form with 5–10 optional filters (name, age, status, date range…) | Yes — perfect fit |
| Multi-tenant application (filter by tenantId always) | Yes — add tenant spec everywhere |
| Reporting with dynamic grouping/sorting | Yes |
| Admin dashboard with many filters | Yes |
| Simple CRUD (findByEmail, findById…) | No — use method names |
| Very complex static report (10+ joins) | Maybe `@NamedQuery` or QueryDSL |
| You already use QueryDSL | No need for Specification |

### 8. Example: Full Search Specification

```java
public static Specification<User> searchUser(UserSearchCriteria criteria) {
    return Specification.where(hasEmail(criteria.getEmail()))
        .and(hasLastNameLike(criteria.getLastName()))
        .and(isActive())
        .and(createdBetween(criteria.getFromDate(), criteria.getToDate()))
        .and(hasRole(criteria.getRole()));
}
```

### 9. Bonus: Spring Data JPA + Specification + OpenAPI/Swagger

Many modern apps use Specification + a DTO for search criteria:

```java
@GetMapping("/users/search")
public Page<UserDto> search(@RequestParam Map<String, String> params) {
    UserSearchCriteria criteria = UserSearchCriteria.from(params);
    Specification<User> spec = UserSpecifications.searchUser(criteria);
    Page<User> page = userRepository.findAll(spec, pageable);
    return page.map(UserDto::fromEntity);
}
```

### Summary Table: When to Choose Specification

| Requirement                        | Specification is ideal |
|------------------------------------|------------------------|
| Dynamic filters (search form)      | Yes                    |
| Type-safe query construction       | Yes                    |
| Reusable query parts               | Yes                    |
| Compose multiple conditions        | Yes                    |
| Fetching relations without N+1     | Yes                    |
| Static simple queries              | No — use method names  |
| Very complex static reports        | Maybe `@NamedQuery`    |
| Need fluent, chainable API         | Consider QueryDSL      |

**Bottom line (2025 best practice):**  
Use **Specifications** whenever you need **dynamic, composable, type-safe queries** — especially for search, filtering, and reporting features. It’s one of the most powerful and modern ways to write flexible queries in Spring Data JPA.

###### Tags : [[0 - Spring Framework]]