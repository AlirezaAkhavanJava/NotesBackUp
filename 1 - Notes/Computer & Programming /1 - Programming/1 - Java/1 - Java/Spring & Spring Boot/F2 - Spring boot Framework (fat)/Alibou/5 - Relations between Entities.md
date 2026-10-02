
# 🧠 **1. WHAT IS AN ENTITY RELATIONSHIP?**

It’s simply how **tables** connect to **other tables**.

Spring Data JPA uses annotations to define this, and each annotation has **arguments** (parameters) you must fully understand.

There are **4 master relationships**:

1. **@OneToOne**
    
2. **@OneToMany**
    
3. **@ManyToOne**
    
4. **@ManyToMany**
    

Everything comes from these four.  
We will go one by one, from dumb-simple → professional depth.

---

# 🧩 **2. BEFORE RELATIONSHIPS: KEY CONCEPTS YOU MUST KNOW**

### ✅ A) **Owning Side vs Inverse Side**

- **Owning side** → the table that contains the foreign key column.
    
- **Inverse side** → just a mirror; refers back using `mappedBy`.
    

### ✅ B) **Join column**

Foreign key in SQL.

`@JoinColumn(name = "something_id")`

### ✅ C) **Cascade**

Automatically push operations to child entities.

```
CascadeType.PERSIST
CascadeType.MERGE
CascadeType.REMOVE
CascadeType.ALL
```

### ✅ D) **Fetch types**

```
FetchType.LAZY   // load when needed
FetchType.EAGER  // load instantly
```

---

# 🟥 **3. @OneToOne (1:1)**

One entity has exactly one related entity.

## ⭐ Basic Example

```
User ---- Profile
```

## ✔️ Owning Side

```java
@OneToOne
@JoinColumn(name = "profile_id")
private Profile profile;
```

## ✔️ Inverse Side

```java
@OneToOne(mappedBy = "profile")
private User user;
```

---

## ⚙️ Arguments You MUST Know

### **mappedBy**

Used only on inverse side.

### **cascade**

Push operations.

### **fetch**

One-to-One default = EAGER  
(You should change it to LAZY manually)

```java
@OneToOne(fetch = FetchType.LAZY, cascade = CascadeType.ALL)
```

### **optional**

Whether FK can be null.

```java
optional = false
```

---

# 🟦 **4. @OneToMany (1 → many)**

One parent has many children.

Example:

```
User ----> List<Post>
```

## ⚠️ Important

**OneToMany is NEVER the owning side by default.  
ManyToOne owns the relationship.**

### ❌ Wrong Parent-Only Relationship

If you do only @OneToMany, JPA creates a join table.  
You don’t want that.

### ✔️ Correct way

Parent:

```java
@OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
private List<Post> posts;
```

Child:

```java
@ManyToOne
@JoinColumn(name = "user_id")
private User user;
```

---

## 📌 Arguments

### **mappedBy**

Always needed.

### **cascade**

Same rules as above.

### **fetch**

OneToMany default = LAZY  
(good, leave it)

### **orphanRemoval**

Deletes children automatically.

```java
orphanRemoval = true
```

---

# 🟩 **5. @ManyToOne (many → one)**

**MOST COMMON RELATIONSHIP.**  
This is the _owning side_ 99% of the time.

Example:

```
Many Posts → One User
```

### Child (owning)

```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "user_id")
private User user;
```

## 📌 Arguments

### **optional**

FK nullability.

### **fetch**

Default = EAGER  
Change to LAZY ALWAYS:

```java
@ManyToOne(fetch = FetchType.LAZY)
```

### **cascade**

Usually don’t cascade here.  
You don’t create users through posts.

---

# 🟨 **6. @ManyToMany (many ↔ many)**

Example:

```
Student ↔ Course
```

## ❌ The naive way (creates join table automatically)

```java
@ManyToMany
private List<Course> courses;
```

## ✔️ Controlled way (recommended)

Student:

```java
@ManyToMany
@JoinTable(
    name = "student_course",
    joinColumns = @JoinColumn(name = "student_id"),
    inverseJoinColumns = @JoinColumn(name = "course_id")
)
private List<Course> courses;
```

Course (inverse):

```java
@ManyToMany(mappedBy = "courses")
private List<Student> students;
```

---

## 📌 Arguments

### **joinColumns**

FK for owning entity

### **inverseJoinColumns**

FK for the related entity

### **mappedBy**

Inverse side

---

# 🔥 **7. ALL RELATIONSHIPS IN ONE TABLE**

|Relationship|Owning Side|Default Fetch|Requires mappedBy?|
|---|---|---|---|
|OneToOne|Either (but the one with FK)|EAGER|On inverse|
|OneToMany|NEVER|LAZY|Yes|
|ManyToOne|ALWAYS|EAGER|No|
|ManyToMany|One side|LAZY|On inverse|

---

# 🧠 **8. ADVANCED JPA BEHAVIOR (PRO LEVEL)**

### ✔️ JPA never creates foreign key on inverse side

Only owning side matters.

### ✔️ Collections = always LAZY

Never make them EAGER.

### ✔️ Always fix bidirectional relationships to avoid infinite JSON recursion

Use:

```
@JsonManagedReference
@JsonBackReference
```

or

```
@JsonIgnore
```

### ✔️ Or use DTOs → best practice

---

# 🔥 **9. Complete "Kid Brain" Summary**

If half your brain is gone, remember this:

> **The side with "@JoinColumn" is the boss (owning side).**  
> The side with "mappedBy" is just the mirror (inverse side).

That’s the entire JPA relationship system.


---

# 🧠 **1. `cascade` — WHAT IT REALLY DOES**

Cascade = _“do the same operation on the child entity automatically”_

Example:  
If you save a **User**, cascade decides what happens to **User.profile**, **User.posts**, etc.

### ✔️ Cascade Types (with stupid-simple explanations)

|Cascade|Meaning (Brain-dead version)|
|---|---|
|`PERSIST`|When parent is saved → save child|
|`MERGE`|When parent is updated → update child|
|`REMOVE`|When parent is deleted → delete child|
|`REFRESH`|Reload child if parent is refreshed|
|`DETACH`|Detach child when parent detaches|
|`ALL`|PERSIST + MERGE + REMOVE + REFRESH + DETACH|

### ⭐ When to use

|Relationship|Cascade?|
|---|---|
|**OneToOne**|Often yes|
|**OneToMany**|Usually yes|
|**ManyToOne**|Usually NO (dangerous)|
|**ManyToMany**|Rarely|

If you put cascade on ManyToOne:

> Delete a Post → user also deleted.  
> Congrats, your app is dead.

---

# 🧠 **2. `fetch` — HOW ENTITIES ARE LOADED**

Fetch = _when should JPA load this relationship?_

Two values:

## ✔️ `FetchType.LAZY` (recommended)

Load only when needed.

- Best performance
    
- Avoids heavy SQL
    
- Prevents loading massive lists
    

```java
@OneToMany(fetch = FetchType.LAZY)
```

## ✔️ `FetchType.EAGER` (usually bad)

Loads relationship immediately.

- Causes giant queries (N+1 problem)
    
- Heavy memory usage
    
- JSON infinite recursion
    

Only use EAGER if you absolutely need it.

### JPA defaults

|Relationship|Default|
|---|---|
|ManyToOne|EAGER (change this)|
|OneToOne|EAGER (change this)|
|OneToMany|LAZY|
|ManyToMany|LAZY|

BEST PRACTICE:  
→ Make **every** relationship LAZY unless needed.

---

# 🧠 **3. `mappedBy` — WHO OWNS THE RELATIONSHIP**

`mappedBy` = “I am NOT the boss, the other entity has the foreign key.”

Example:

```java
@OneToMany(mappedBy = "user")
private List<Post> posts;
```

This means:

- `Post` entity has the foreign key (`user_id`)
    
- `User` does NOT own the relationship
    

Golden rule:

> **The side with `@JoinColumn` is the owner.**  
> **The side with `mappedBy` is the mirror.**

---

# 🧠 **4. `optional` — CAN THE FOREIGN KEY BE NULL?**

Used on `@ManyToOne` or `@OneToOne`.

```java
@ManyToOne(optional = false)
```

Meaning:

- **false** = FK cannot be null  
    (child must always have a parent)
    
- **true** = FK can be null  
    (relationship optional)
    

Equivalent to SQL:

```
NOT NULL
```

---

# 🧠 **5. `orphanRemoval` — DELETE CHILD WHEN REMOVED FROM LIST**

Used mostly in OneToMany.

```java
@OneToMany(mappedBy="user", orphanRemoval = true)
private List<Post> posts;
```

If you:

```
user.getPosts().remove(post)
```

JPA will also do:

```
DELETE FROM post WHERE id = ?
```

This is **not cascade**.  
Cascade is about deleting parent → delete child.  
OrphanRemoval is about removing association → delete child.

---

# 🧠 **6. `targetEntity` — Almost Never Needed**

Used if the generic type is not obvious.

Example:

```java
@OneToMany(targetEntity = Post.class)
private List posts;
```

Very rare.  
Only needed if you removed generics (don’t do that).

---

# 🧠 **7. `@JoinColumn` arguments (Very Important)**

```java
@JoinColumn(
    name = "user_id",
    nullable = false,
    unique = false,
    insertable = true,
    updatable = true
)
```

### ✔️ name

Name of FK column.

### ✔️ nullable

FK can be null or not.

### ✔️ unique

Makes it 1:1 if needed.

### ✔️ insertable

Whether JPA can insert into this column.

### ✔️ updatable

Whether JPA can update this column.

You use insertable/updatable=false when you map the same column twice.

---

# 🧠 **8. `@JoinTable` arguments**

Used for ManyToMany or OneToMany with join tables.

```java
@JoinTable(
    name = "student_course",
    joinColumns = @JoinColumn(name = "student_id"),
    inverseJoinColumns = @JoinColumn(name = "course_id")
)
```

### ✔️ joinColumns

FK for the owning entity

### ✔️ inverseJoinColumns

FK for the other entity

---

# 🧠 **9. `unique` / `nullable` / `columnDefinition`**

Sometimes used inside `@Column` but affects relationships indirectly.

```java
@Column(unique=true, nullable=false)
```

- **unique** = prevents duplicates
    
- **nullable** = FK cannot be null
    
- **columnDefinition** = custom SQL type
    

---

# 🧠 **10. SUPER SUMMARY FOR “HALF BRAIN MODE”**

If your brain is at 1% battery, remember this:

- `cascade` → push parent actions to child
    
- `fetch` → load now or load later
    
- `mappedBy` → I am NOT the boss
    
- `optional` → can FK be null?
    
- `orphanRemoval` → remove from list = delete from DB
    
- `joinColumn` → FK column settings
    
- `joinTable` → middle table for ManyToMany
    
- `targetEntity` → rarely needed
    

---


###### Tags : [[0 - Spring Framework]]