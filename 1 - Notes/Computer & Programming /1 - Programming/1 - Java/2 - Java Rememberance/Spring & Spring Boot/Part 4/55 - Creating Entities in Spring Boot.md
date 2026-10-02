

# Creating Entities in Spring Boot: Best Practices & Design Patterns

## 1. Basic Entity Structure

```java
@Entity
@Table(name = "users")
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 100)
    private String name;
    
    @Column(unique = true, nullable = false)
    private String email;
    
    // Constructors, getters, setters, equals/hashCode
}
```

## 2. Design Patterns to Follow

### **Layered Architecture** (most important)
```
Controller → Service → Repository → Entity
```
Entities should **never** be returned directly from controllers. Use **DTOs**.

### **DTO Pattern**
Separate your entity from API contracts:
```java
// Entity (persistence layer)
@Entity
public class User { ... }

// DTO (API layer)
public record UserResponse(Long id, String name, String email) {}
public record CreateUserRequest(String name, String email) {}
```

### **Repository Pattern**
```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
```

### **Builder Pattern** (for complex entities)
Use Lombok's `@Builder` or manual builders.

### **Mapper Pattern**
Use MapStruct or manual mappers between Entity ↔ DTO.

### **Specification Pattern** (for dynamic queries)
For complex filtering, use `JpaSpecificationExecutor`.

---

## 3. Rules & Best Practices

### ✅ **Identification & Keys**
- Always use a **surrogate key** (`@Id`) — don't use natural keys as PK
- Prefer `Long` with `GenerationType.IDENTITY` or `SEQUENCE`
- Avoid composite keys when possible; if needed use `@EmbeddedId` or `@IdClass`

### ✅ **Equality & Hashing**
```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof User)) return false;
    return id != null && id.equals(((User) o).id);
}

@Override
public int hashCode() {
    return getClass().hashCode(); // stable across states
}
```

### ✅ **Constructors**
- Always provide a **protected no-arg constructor** (required by JPA)
- Use a public constructor/builder for domain creation

### ✅ **Naming**
- Table names: plural, snake_case (`users`, `order_items`)
- Column names: snake_case (`first_name`)
- Use `@Table` / `@Column` explicitly for clarity

### ✅ **Associations**
- Default to `FetchType.LAZY` for `@ManyToOne` and `@OneToOne`
- Never use `FetchType.EAGER` unless truly needed
- Always specify `mappedBy` on the inverse side
- Use `cascade` only for true parent-child relationships (`CascadeType.ALL` + `orphanRemoval = true`)

```java
@OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
private List<Order> orders = new ArrayList<>();
```

### ✅ **Bidirectional Helpers**
Keep both sides in sync:
```java
public void addOrder(Order order) {
    orders.add(order);
    order.setUser(this);
}
```

### ✅ **Avoid Common Pitfalls**
| Don't | Do |
|---|---|
| Use `@Data` from Lombok on entities | Use `@Getter`, `@Setter`, `@EqualsAndHashCode(onlyExplicitlyIncluded = true)` |
| Expose entities in REST | Use DTOs |
| Use `FetchType.EAGER` | Use LAZY + fetch joins |
| Use `double`/`float` for money | Use `BigDecimal` |
| Use `java.util.Date` | Use `java.time.*` (`LocalDate`, `Instant`) |
| Make entities `final` | Keep them non-final (proxies need it) |

### ✅ **Lombok Caveats**
```java
@Entity
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class User {
    @EqualsAndHashCode.Include
    @Id
    private Long id;
    // ...
}
```
**Never** use `@Data` or `@Builder` on entities without understanding the implications (breaks equals/hashCode, no-arg constructor).

### ✅ **Validation**
Use Bean Validation:
```java
@NotBlank
@Size(max = 100)
private String name;

@Email
@Column(unique = true, nullable = false)
private String email;
```

### ✅ **Auditing**
Use Spring Data JPA auditing:
```java
@CreatedDate
private Instant createdAt;

@LastModifiedDate
private Instant updatedAt;
```
Enable with `@EnableJpaAuditing`.

### ✅ **Optimistic Locking**
```java
@Version
private Long version;
```

### ✅ **Enum Handling**
```java
@Enumerated(EnumType.STRING)  // never ORDINAL
private Status status;
```

### ✅ **Schema Management**
- Use **Flyway** or **Liquibase** for migrations
- Set `spring.jpa.hibernate.ddl-auto=validate` in production

---

## 4. Complete Example

```java
@Entity
@Table(name = "users", indexes = @Index(columnList = "email", unique = true))
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @NotBlank
    @Column(nullable = false, length = 100)
    private String name;

    @Email
    @Column(nullable = false, unique = true)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserStatus status = UserStatus.ACTIVE;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Order> orders = new ArrayList<>();

    @Version
    private Long version;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    public void addOrder(Order order) {
        orders.add(order);
        order.setUser(this);
    }

    public void removeOrder(Order order) {
        orders.remove(order);
        order.setUser(null);
    }
}
```

---

## 5. Quick Checklist

- [ ] `@Entity` + `@Table` with explicit name
- [ ] Surrogate `@Id` with proper generation strategy
- [ ] Protected no-arg constructor + domain constructor/builder
- [ ] `equals`/`hashCode` on ID only
- [ ] LAZY fetching by default
- [ ] DTOs for API layer
- [ ] `@Version` for optimistic locking
- [ ] Auditing fields
- [ ] Bean Validation annotations
- [ ] Migrations (Flyway/Liquibase)
- [ ] `ddl-auto=validate` in prod
- [ ] Avoid Lombok `@Data`/`@Builder` pitfalls

Following these patterns keeps your persistence layer clean, testable, and performant.


[[Java]]
[[0 - Spring Framework]]