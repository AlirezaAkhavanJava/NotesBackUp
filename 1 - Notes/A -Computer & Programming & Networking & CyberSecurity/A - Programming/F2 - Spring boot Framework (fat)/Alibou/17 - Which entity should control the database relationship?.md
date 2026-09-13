

> **`mappedBy` goes on the side that does NOT own the relationship.  
> Joins go on the side that OWNS it.**



---

## Step-by-step: how to decide the owning side

### 1️⃣ Ask one brutal question

**Which entity should control the database relationship?**

The answer to that question owns it. That side:

- has `@JoinColumn` or `@JoinTable`
    
- does **NOT** use `mappedBy`
    

The other side:

- uses `mappedBy`
    
- never defines joins
    
- never writes to the DB
    

---

## Case 1: One-to-Many / Many-to-One (easy)

### Rule

**`@ManyToOne` ALWAYS owns the relationship**

Because the foreign key lives there. Databases don’t care about your feelings.

### Example

```java
@Entity
class Order {
    @ManyToOne
    @JoinColumn(name = "user_id")
    User user;
}
```

```java
@Entity
class User {
    @OneToMany(mappedBy = "user")
    List<Order> orders;
}
```

### Why

- FK `user_id` is in `order` table
    
- So `Order` owns it
    
- `User` just watches
    

You don’t decide this. SQL does.

---

## Case 2: One-to-One (you actually choose)

### Rule

The side with the **foreign key column** owns it.

### Example

```java
@Entity
class User {
    @OneToOne
    @JoinColumn(name = "profile_id")
    Profile profile;
}
```

```java
@Entity
class Profile {
    @OneToOne(mappedBy = "profile")
    User user;
}
```

### Decision logic

- Which table should contain the FK?
    
- That entity owns it
    
- Other side uses `mappedBy`
    

---

## Case 3: Many-to-Many (pure design choice)

### Rule

Pick **ONE** side to own the join table.  
The other side gets `mappedBy`.

### Example

```java
@Entity
class Course {
    @ManyToMany
    @JoinTable(
        name = "course_author",
        joinColumns = @JoinColumn(name = "course_id"),
        inverseJoinColumns = @JoinColumn(name = "author_id")
    )
    Set<Author> authors;
}
```

```java
@Entity
class Author {
    @ManyToMany(mappedBy = "authors")
    Set<Course> courses;
}
```

### How to choose?

Ask:

- Which entity logically manages the relationship?
    
- Which side will be modified more often?
    
- Which side reads better in code?
    

There is no “correct” side. Just consistency.

---

## Universal decision table (memorize this)

|Question|Answer|
|---|---|
|Does this entity have the FK?|It owns|
|Does this entity define `@JoinColumn`?|It owns|
|Does this entity define `@JoinTable`?|It owns|
|Does this entity have `mappedBy`?|It does NOT own|

---

## One rule that never fails

> **If you put `mappedBy` on a field, that field is read-only for the database.**

Hibernate will happily ignore your updates and not warn you. Because why would it.

---

## Final sanity check (use this every time)

1. Where is the FK or join table?
    
2. Put joins there
    
3. Put `mappedBy` on the other side
    
4. Never put joins on both sides
    

Do this and JPA stops feeling like a prank.



###### Tags : [[0 - Spring Framework]]