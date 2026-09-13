


# 🔥 1. `@ManyToOne`

This is the **owning side** 99% of the time.

- Many children → One parent
    
- The **foreign key ALWAYS lives on the Many-side table**.
    

Example:

```java
@Entity
public class Course {
    @Id
    private Long id;

    @ManyToOne
    @JoinColumn(name = "teacher_id") // FK in COURSE table
    private Teacher teacher;
}
```

Meaning:

- Each `Course` has **one** `Teacher`.
    
- A `Teacher` can have **many** `Course`s.
    
- The FK `teacher_id` is in the `course` table.
    

**Senior rule:**  
If there is a FK column, _that_ entity is almost always the `@ManyToOne` side.

---

# 🔥 2. `@OneToMany`

This is the **inverse side** 99% of the time.  
You normally do **NOT** put a `@JoinColumn` here, because that would create an extra relationship table.

Correct way (bidirectional):

```java
@Entity
public class Teacher {
    @Id
    private Long id;

    @OneToMany(mappedBy = "teacher") // inverse side
    private List<Course> courses;
}
```

Meaning:

- Hibernate looks at `Course.teacher` (the owning side).
    
- No extra table is created.
    
- No FK on the `teacher` table.
    
- No `@JoinColumn` here.
    

**Senior rule:**  
If you use `mappedBy`, this side is **read-only for the relationship** (no FK).

---

# 🔥 3. The full correct pair (what senior devs actually write)

```java
@Entity
public class Teacher {

    @Id
    private Long id;

    @OneToMany(mappedBy = "teacher", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Course> courses = new ArrayList<>();
}

@Entity
public class Course {

    @Id
    private Long id;

    @ManyToOne
    @JoinColumn(name = "teacher_id")
    private Teacher teacher;
}
```

### Why this is senior-level:

- FK stored correctly in the `course` table.
    
- `mappedBy` correctly marks inverse side.
    
- `cascade = ALL` + `orphanRemoval` = child lifecycle controlled by parent.
    
- Avoids extra join tables and unnecessary complexity.
    

---

# 🔥 4. Relationship Direction Rule (VERY IMPORTANT)

|Side|Annotation|Owns FK?|Writes FK?|
|---|---|---|---|
|Many-side|`@ManyToOne`|✅ Yes|✅ Yes|
|One-side|`@OneToMany(mappedBy=...)`|❌ No|❌ No|

**FK is always on the Many side. Always.**

---

# 🔥 5. Common mistakes juniors make (you should avoid)

❌ Putting `@JoinColumn` on the `@OneToMany` side  
→ creates a broken schema or extra tables

❌ Trying to save parent without setting both sides  
→ causes children to be “orphaned” or FKs = null

❌ Cascading deletes when entities shouldn’t be deleted  
→ wipes entire data accidentally

❌ Forgetting to initialize the `List<>()`  
→ `NullPointerException` when adding children

---



##### Tags : [[0 - Spring Framework]]