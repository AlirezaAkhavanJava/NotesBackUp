

# 🧠 **1. WHY DO WE EVEN NEED THIS?**

When you create **bidirectional JPA relationships**, like:

```java
User <--> List<Post>
```

you get this:

- User points to Posts
    
- Each Post points back to User
    

So when Jackson tries to turn it into JSON:

```
User → posts → each post → user → posts → user → posts → user → ...
```

**INFINITE LOOP → stack overflow → 500 error.**

This is called a **cyclic reference**.

---

# 🧩 **2. WHAT @JsonManagedReference AND @JsonBackReference DO**

They tell Jackson:

> **“This side is the parent (visible)”**  
> **“This side is the child (hidden)”**

### **Parent Side:**

`@JsonManagedReference`  
→ Will be serialized (included in JSON)

### **Child Side:**

`@JsonBackReference`  
→ Will NOT be serialized  
→ Prevents infinite loop

---

# 🧱 **3. Example — The Correct Way**

## 🔷 User (parent)

```java
@OneToMany(mappedBy = "user")
@JsonManagedReference
private List<Post> posts;
```

## 🔶 Post (child)

```java
@ManyToOne
@JoinColumn(name = "user_id")
@JsonBackReference
private User user;
```

### What JSON looks like now:

#### ✔️ Serializing a User:

```json
{
  "id": 1,
  "name": "Ethan",
  "posts": [
    {
      "id": 10,
      "title": "Hello",
    }
  ]
}
```

#### ✔️ Serializing a Post:

```json
{
  "id": 10,
  "title": "Hello"
}
```

**No infinite loop.**

---

# 🧠 **4. How Jackson interprets it (Deep Level)**

Jackson creates an internal **object identity tree**.

- `@JsonManagedReference` marks a **forward reference**
    
- `@JsonBackReference` marks the **back reference**
    
- During serialization, ManagedReference is written, BackReference is ignored.
    

So:

```
User → [Post, Post]
Post → (User reference skipped)
```

---

# 🔥 **5. IMPORTANT RULES**

### ✔️ Rule 1:

They MUST be on both sides of the relationship.

### ✔️ Rule 2:

The parent (collection or owning structure) = ManagedReference.

### ✔️ Rule 3:

The child (the one pointing back) = BackReference.

### ✔️ Rule 4:

Used ONLY for **bidirectional** relationships.

### ✔️ Rule 5:

Names can be specified to support multiple pairs.

---

# 🧩 **6. Using multiple parent-child pairs**

If you have two bidirectional relationships in an entity, you must name them:

### Example

```java
@JsonManagedReference(value = "user-posts")
@JsonManagedReference(value = "user-address")
```

Child side:

```java
@JsonBackReference(value = "user-posts")
@JsonBackReference(value = "user-address")
```

---

# 🔥 **7. When NOT to use these**

Sometimes, instead:

- You flatten with DTOs
    
- You use `@JsonIgnore` (more brutal)
    
- You use `@JsonIdentityInfo` (object IDs instead of recursion)
    

**Best practice in real projects = DTOs.**

---

# 🧨 **8. @JsonManagedReference vs @JsonIgnore**

### `@JsonIgnore`

Completely hides the property always.

### `@JsonBackReference`

Hides only when serializing _from the parent_.  
If you serialize the child directly, the parent is ignored, but child still shows its own fields.

---

# 🧠 “Half-brain summary”

If your brain is in _potato mode_, remember:

> **Managed = show this**  
> **Back = don’t show this (break cycle)**

---



###### Tags [[0 - Spring Framework]]