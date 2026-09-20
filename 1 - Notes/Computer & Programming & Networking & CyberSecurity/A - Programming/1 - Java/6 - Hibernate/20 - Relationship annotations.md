


# **1. `@OneToOne`**

- **Meaning:** One entity instance is associated with **exactly one** instance of another entity.
    
- **Foreign key:** Usually stored on one side.
    

**Example:**

```java
@Entity
public class Student {
    @Id
    private Long id;

    @OneToOne
    @JoinColumn(name = "address_id") // FK column in Student table
    private Address address;
}
```

**Notes:**

- `fetch` can be `EAGER` or `LAZY`.
    
- `cascade` can propagate operations like persist, remove.
    

---

# **2. `@OneToMany`**

- **Meaning:** One entity is associated with **many instances** of another entity.
    
- **Example:** One student has many courses (or enrollments).
    

```java
@Entity
public class Student {
    @Id
    private Long id;

    @OneToMany(mappedBy = "student", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Course> courses;
}
```

**Notes:**

- `mappedBy` indicates the **owner side** in the other entity.
    
- Default fetch for `@OneToMany` is **LAZY**.
    

---

# **3. `@ManyToOne`**

- **Meaning:** Many instances of this entity relate to **one instance** of another.
    
- **Example:** Many students belong to one school.
    

```java
@Entity
public class Student {
    @ManyToOne
    @JoinColumn(name = "school_id")
    private School school;
}
```

**Notes:**

- Often the **owner of the relationship**.
    
- Default fetch is **EAGER**.
    

---

# **4. `@ManyToMany`**

- **Meaning:** Many instances relate to many instances.
    
- Usually requires a **join table**.
    

```java
@Entity
public class Student {
    @ManyToMany(cascade = CascadeType.ALL)
    @JoinTable(
        name = "student_course",
        joinColumns = @JoinColumn(name = "student_id"),
        inverseJoinColumns = @JoinColumn(name = "course_id")
    )
    private List<Course> courses;
}
```

**Notes:**

- `@JoinTable` defines the linking table.
    
- Fetch is **LAZY** by default.
    

---

# **5. `@JoinColumn`**

- Defines the **foreign key column** in the database.
    
- Can specify `nullable`, `unique`, etc.
    

```java
@OneToOne
@JoinColumn(name = "address_id", nullable = false)
private Address address;
```

---

# **6. `@JoinTable`**

- Used for **@ManyToMany** relationships to specify the join table.
    

```java
@JoinTable(
    name = "student_course",
    joinColumns = @JoinColumn(name = "student_id"),
    inverseJoinColumns = @JoinColumn(name = "course_id")
)
```

---

# **7. `cascade`**

- Specifies **operations that propagate** from parent to child entities.
    

|Type|Meaning|
|---|---|
|`ALL`|All operations (persist, remove, merge, refresh, detach)|
|`PERSIST`|Cascade save|
|`MERGE`|Cascade update|
|`REMOVE`|Cascade delete|
|`REFRESH`|Cascade refresh from DB|
|`DETACH`|Cascade detach from session|

---

# **8. `fetch`**

- Determines **when related entities are loaded**.
    

|Type|Meaning|
|---|---|
|`LAZY`|Load when accessed (default for `@OneToMany`, `@ManyToMany`)|
|`EAGER`|Load immediately with parent (default for `@ManyToOne`, `@OneToOne`)|

---

# **9. `mappedBy`**

- Defines the **inverse side** of a relationship.
    
- Tells Hibernate **which side owns the foreign key**.
    

```java
@OneToMany(mappedBy = "student")
private List<Course> courses;
```

---

# **10. Other Useful Annotations**

|Annotation|Purpose|
|---|---|
|`@PrimaryKeyJoinColumn`|Used in shared primary key one-to-one relationships.|
|`@OrderBy`|Orders a collection by a column.|
|`@MapKey` / `@MapKeyColumn`|Maps a collection to a Map instead of List/Set.|
|`@ElementCollection`|For collections of **basic types or embeddables**, not entities.|
|`@Embeddable` / `@Embedded`|For **component/embedded objects**.|

---

# **🔥 Example Combining Everything**

```java
@Entity
public class Student {
    @Id
    @GeneratedValue
    private Long id;

    @OneToOne(cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @JoinColumn(name = "address_id")
    private Address address;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @OneToMany(mappedBy = "student", cascade = CascadeType.ALL)
    private List<Course> courses;

    @ManyToMany
    @JoinTable(
        name = "student_club",
        joinColumns = @JoinColumn(name = "student_id"),
        inverseJoinColumns = @JoinColumn(name = "club_id")
    )
    private List<Club> clubs;
}
```

---

💡 **Senior Tip:**

- Default fetch type matters for performance: use **LAZY** for collections to avoid unnecessary queries.
    
- Always decide **ownership of relationships** (`mappedBy`) carefully to prevent extra tables or foreign keys.
    
- Combine **cascade** and **fetch** based on how you want persistence and loading to behave.
    

---


##### Tags : [[2 - Hibernate 🍪]]