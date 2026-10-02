
## 1️⃣ What is a **UNIQUE INDEX** in PostgreSQL?

A **UNIQUE INDEX** guarantees that **no two rows can have the same indexed value(s)**.

👉 It enforces **data integrity at the database level**  
👉 PostgreSQL rejects duplicates **before insert/update completes**

Example rule:

```
email must be unique
```

---

## 2️⃣ How to Create a UNIQUE INDEX

### ✅ Single column

```sql
CREATE UNIQUE INDEX idx_user_email
ON users(email);
```

---

### ✅ Multiple columns (composite unique)

```sql
CREATE UNIQUE INDEX idx_user_email_provider
ON users(email, provider);
```

Meaning:

- Same email **allowed**
    
- Same email + same provider ❌ **not allowed**
    

---

### ✅ Partial UNIQUE index (advanced & powerful)

```sql
CREATE UNIQUE INDEX idx_active_email
ON users(email)
WHERE deleted = false;
```

Meaning:

- Active users → email must be unique
    
- Deleted users → ignored
    

---

## 3️⃣ UNIQUE INDEX vs UNIQUE CONSTRAINT (IMPORTANT)

|Feature|UNIQUE INDEX|UNIQUE CONSTRAINT|
|---|---|---|
|Enforces uniqueness|✅|✅|
|Backed by index|—|✅ (creates index internally)|
|Partial allowed|✅|❌|
|Expression allowed|✅|❌|
|Semantic meaning|Performance / control|Data integrity|
|Recommended for business rules|❌|✅|

### Constraint version (preferred)

```sql
ALTER TABLE users
ADD CONSTRAINT uq_user_email UNIQUE (email);
```

👉 PostgreSQL automatically creates a **unique B-Tree index**.

---

## 4️⃣ How PostgreSQL Enforces Uniqueness (Internals)

- During `INSERT / UPDATE`
    
- PostgreSQL checks the index
    
- If duplicate key found → transaction **fails**
    

Error:

```text
ERROR: duplicate key value violates unique constraint
```

---

## 5️⃣ NULL Behavior (Common Trap)

### ❗ PostgreSQL allows **multiple NULLs**

```sql
CREATE UNIQUE INDEX idx_phone
ON users(phone);
```

Allowed:

```
NULL
NULL
NULL
```

Why?

- `NULL ≠ NULL`
    

### Force single NULL (hack)

```sql
CREATE UNIQUE INDEX idx_phone_not_null
ON users(phone)
WHERE phone IS NOT NULL;
```

---

## 6️⃣ When to Use a UNIQUE INDEX

### ✅ Use when:

- You need **conditional uniqueness**
    
- You need **expression-based uniqueness**
    
- You need **partial uniqueness**
    

Examples:

```sql
CREATE UNIQUE INDEX idx_lower_email
ON users(LOWER(email));
```

---

## 7️⃣ When NOT to Use UNIQUE INDEX

❌ Don’t use it to replace constraints blindly  
❌ Don’t rely on app-level uniqueness checks  
❌ Don’t ignore race conditions

Always let **PostgreSQL enforce uniqueness**.

---

## 8️⃣ Spring Boot / JPA Mapping (Real World)

### Entity

```java
@Column(unique = true)
private String email;
```

⚠ This creates a **constraint**, not just an index.

### Better (explicit)

```java
@Table(
  name = "users",
  uniqueConstraints = @UniqueConstraint(columnNames = "email")
)
```

---

## Final Truth

- **UNIQUE INDEX = uniqueness + performance**
    
- **UNIQUE CONSTRAINT = business rule**
    
- PostgreSQL uses **B-Tree** for both
    
- Partial & expression uniqueness → **index only**
    




###### Tags : [[1 - SQL 🦬]]