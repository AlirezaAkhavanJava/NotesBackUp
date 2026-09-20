

## `@MappedSuperclass` — complete definition

### What it is

`@MappedSuperclass` marks a **parent class whose fields are mapped to the database**, but **the class itself is NOT an entity**.

It exists **only to share persistent state** with entity subclasses.

---

## What it does

When an entity **extends a mapped superclass**:

- All **fields + JPA annotations** are inherited
    
- Columns are created in the **child entity’s table**
    
- **No separate table** is created for the superclass
    
- The superclass **cannot be queried**
    

---

## What it is NOT

|Thing|Allowed|
|---|---|
|`@Entity`|❌|
|Database table|❌|
|JPQL queries|❌|
|Relationships targeting it|❌|

This class exists only at **compile + mapping time**, not runtime queries.

---

## Basic example

```java
@MappedSuperclass
public abstract class BaseEntity {

    @Id
    @GeneratedValue
    private Long id;

    @Column(nullable = false)
    private LocalDateTime createdAt;
}
```

```java
@Entity
class User extends BaseEntity {
    private String username;
}
```

### Resulting table

```
user
----
id
created_at
username
```

No `base_entity` table. Ever.

---

## Allowed annotations inside `@MappedSuperclass`

✔ `@Id`  
✔ `@Column`  
✔ `@Version`  
✔ `@Enumerated`  
✔ `@Temporal`  
✔ `@Embedded`  
✔ `@MappedSuperclass` (obviously)

---

## Relationships inside `@MappedSuperclass`

### Allowed

You **can define relationships** inside it:

```java
@MappedSuperclass
class Auditable {

    @ManyToOne
    User createdBy;
}
```

➡ The FK appears in **child tables**

### Limitations

- You **cannot target** a `@MappedSuperclass` in a relationship
    
- You cannot use it in JPQL:
    
    ```java
    SELECT a FROM Auditable a ❌
    ```
    

---

## Inheritance comparison (this is where people mess up)

|Feature|`@MappedSuperclass`|`@Inheritance`|
|---|---|---|
|Has table|❌|✅|
|Queryable|❌|✅|
|Polymorphism|❌|✅|
|Field reuse|✅|✅|
|Performance|Excellent|Depends|

---

## When to use it (real reasons)

Use `@MappedSuperclass` when:

- You want **shared columns** like:
    
    - `id`
        
    - `createdAt`
        
    - `updatedAt`
        
- You **don’t need polymorphic queries**
    
- You want **zero joins**
    
- You want **simple schemas**
    

This is why every sane codebase has:

```java
BaseEntity
Auditable
AbstractEntity
```

---

## When NOT to use it

Do NOT use it when:

- You want `SELECT e FROM BaseEntity e`
    
- You want polymorphism
    
- You want inheritance strategies (`JOINED`, `SINGLE_TABLE`)
    
- You want a table per parent
    

That’s when you need `@Entity + @Inheritance`.

---

## Common mistakes (classic JPA pain)

❌ Trying to query a mapped superclass  
❌ Using it as a relationship target  
❌ Expecting a table to exist  
❌ Confusing it with `@Embeddable`

---

## `@MappedSuperclass` vs `@Embeddable`

|Feature|`@MappedSuperclass`|`@Embeddable`|
|---|---|---|
|Inheritance|✅|❌|
|Can have `@Id`|✅|❌|
|Can be extended|✅|❌|
|Embedded multiple times|❌|✅|

---

## One-line mental model

> **`@MappedSuperclass` = reusable mapped fields, not a real entity**





###### Tags : [[0 - Spring Framework]]