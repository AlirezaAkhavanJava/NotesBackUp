
# `@Entity` and `@Table` Annotations in JPA

These are **JPA annotations** (from `jakarta.persistence` / `javax.persistence`), not Spring-specific. Hibernate (the default JPA provider in Spring Boot) implements them.

---

## 1. `@Entity`

Marks a Java class as a **JPA entity** — meaning it maps to a database table and its instances represent rows.

```java
@Entity
public class User { ... }
```

### What it does
- Registers the class with the persistence context (Hibernate manages it)
- Requires a **no-arg constructor** (can be `protected`)
- Class must **not be `final`** (proxies need to subclass it)
- Fields are not persisted unless annotated (or via `@Id` + default access strategy)
- Every entity **must have a primary key** (`@Id`)

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `name` | `String` | `""` (class name) | The entity name used in **JPQL/HQL queries**. If empty, the unqualified class name is used. |
| `(no other parameters)` | | | `@Entity` only has `name` |

**Example — custom JPQL name:**
```java
@Entity(name = "Person")
public class User { ... }

// Now JPQL uses: SELECT p FROM Person p
// But the table is still determined by @Table (defaults to User)
```

⚠️ **Common confusion:** `@Entity(name = "X")` changes the **JPQL name**, NOT the table name. Use `@Table(name = "...")` to change the table.

---

## 2. `@Table`

Specifies the **database table** details for an entity. Optional — if omitted, the table name defaults to the entity name (which Hibernate may convert to snake_case depending on naming strategy).

```java
@Entity
@Table(name = "users")
public class User { ... }
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `name` | `String` | `""` (entity name) | Name of the database table |
| `catalog` | `String` | `""` | Database catalog (rarely used) |
| `schema` | `String` | `""` | Database schema (e.g., `"public"`, `"app"`) |
| `uniqueConstraints` | `UniqueConstraint[]` | `{}` | Table-level unique constraints |
| `indexes` | `Index[]` | `{}` | Table-level indexes |
| `comment` | `String` | `""` | Table comment (Hibernate-specific, DDL generation) |

---

## 3. Detailed Examples of Each Parameter

### `name`, `schema`, `catalog`
```java
@Entity
@Table(
    name = "users",
    schema = "app",
    catalog = "mydb"
)
public class User { ... }
```
Generates: `mydb.app.users` (fully qualified).

### `uniqueConstraints`
For **composite unique constraints** (single-column uniqueness is better done with `@Column(unique = true)`).

```java
@Entity
@Table(
    name = "users",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_user_email_tenant",
            columnNames = {"email", "tenant_id"}
        )
    }
)
public class User {
    @Column(nullable = false)
    private String email;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;
}
```
> Ensures **no two rows have the same (email, tenant_id) pair**.

### `indexes`
Improves query performance on frequently searched columns.

```java
@Entity
@Table(
    name = "users",
    indexes = {
        @Index(name = "idx_user_email", columnList = "email"),
        @Index(name = "idx_user_status_created", columnList = "status, created_at")
    }
)
public class User {
    private String email;
    private String status;
    @Column(name = "created_at")
    private Instant createdAt;
}
```

**Note on `columnList`:**
- Uses **column names** (DB names, snake_case), not Java field names
- For composite indexes, separate with commas: `"status, created_at"`
- Order matters — put the most selective column first (usually)

### `comment` (Hibernate-specific)
```java
@Table(name = "users", comment = "Application user accounts")
```
Only used when Hibernate generates DDL. Ignored on validate mode.

---

## 4. Common Pitfalls

### ❌ Confusing `@Entity(name)` with `@Table(name)`
```java
@Entity(name = "UserEntity")   // changes JPQL name only
@Table(name = "app_users")     // changes table name
public class User { ... }

// JPQL:  SELECT u FROM UserEntity u
// SQL:   SELECT * FROM app_users
```

### ❌ Using Java field names in `columnList`
```java
// ❌ Wrong (unless your naming strategy keeps camelCase)
@Index(columnList = "createdAt")

// ✅ Correct
@Index(columnList = "created_at")
```

### ❌ Forgetting `@Table` when relying on naming strategy
Spring Boot's default `CamelCaseToUnderscoresNamingStrategy` converts:
- `UserProfile` → `user_profile`
- `OrderItem` → `order_item`

If you want a specific name, always set `@Table(name = "...")` explicitly.

### ❌ Putting `@Table` on non-entities
`@Table` is only meaningful on classes marked `@Entity`.

---

## 5. Reserved Keywords

If your table/column name collides with a SQL reserved word (`user`, `order`, `group`, `key`, etc.), you must escape it:

```java
@Table(name = "\"user\"")   // Hibernate/Postgres
@Table(name = "`user`")     // MySQL
```
Or simply rename to `users`, `orders`, etc.

---

## 6. Quick Reference Cheat Sheet

```java
@Entity(name = "UserJpqlName")          // optional, changes JPQL name
@Table(
    name = "users",                      // table name
    schema = "app",                      // DB schema
    catalog = "mydb",                    // DB catalog
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_email",
            columnNames = {"email"}
        )
    },
    indexes = {
        @Index(name = "idx_status", columnList = "status")
    },
    comment = "User accounts"
)
public class User { ... }
```

| Annotation | Purpose | Key params |
|---|---|---|
| `@Entity` | Marks class as JPA entity | `name` (JPQL name) |
| `@Table` | Maps to DB table | `name`, `schema`, `catalog`, `uniqueConstraints`, `indexes`, `comment` |

**Rule of thumb:** always specify `@Table(name = "...")` explicitly for clarity and to avoid surprises when naming strategies change.



[[Java]]
[[0 - Spring Framework]]