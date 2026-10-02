
## 1️⃣ `mappedBy` (ownership control)

### What it is

`mappedBy` tells JPA **“this side does NOT own the relationship”**.  
The **owning side** is the one **without** `mappedBy` and contains the **foreign key**.

### Why it exists

To avoid **duplicate foreign keys / join tables** and define **who writes to the DB**.

### Example: One-to-Many

```java
@Entity
class User {
    @OneToMany(mappedBy = "user")
    List<Order> orders;
}

@Entity
class Order {
    @ManyToOne
    @JoinColumn(name = "user_id")
    User user;
}
```

### Key rules

- `mappedBy` value = **field name on the owning side**
    
- The side with `@JoinColumn` is **owning**
    
- Changes on the inverse side **don’t update DB**
    

👉 Here, `Order` owns the relationship.

---

## 2️⃣ `@JoinTable` (link table)

### What it is

`@JoinTable` defines an **explicit join table** (usually for **Many-to-Many**).

### When to use

- Many-to-Many relationships
    
- When you want **custom table/column names**
    
- When the join table has **extra columns** (advanced case → entity instead)
    

### Example: Many-to-Many

```java
@Entity
class Student {
    @ManyToMany
    @JoinTable(
        name = "student_course",
        joinColumns = @JoinColumn(name = "student_id"),
        inverseJoinColumns = @JoinColumn(name = "course_id")
    )
    List<Course> courses;
}
```

### Generated table

```
student_course
----------------
student_id (FK)
course_id  (FK)
```

---

## 3️⃣ `mappedBy` vs `@JoinTable` (truth table)

|Concept|Purpose|
|---|---|
|`mappedBy`|Defines **inverse (non-owning) side**|
|`@JoinColumn`|Defines **foreign key column**|
|`@JoinTable`|Defines **join table**|
|Owning side|Side **without** `mappedBy`|

---

## 4️⃣ Common mistakes (don’t do this)

❌ `mappedBy` on both sides  
❌ `@JoinTable` on One-to-Many without reason  
❌ Updating only inverse side and expecting DB change

---

## Mental model (important)

- **Owning side = writes to DB**
    
- **Inverse side = read-only mirror**
    
- **Many-to-Many = join table**
    
- **One-to-Many = foreign key**
    


###### Tags : [[0 - Spring Framework]]