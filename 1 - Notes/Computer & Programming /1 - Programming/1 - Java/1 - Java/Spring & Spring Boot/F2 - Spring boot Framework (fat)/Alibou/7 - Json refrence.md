

# 🟦 **1. @JsonManagedReference**

### **What it is**

The **parent** side of a bidirectional relationship.

### **What it does**

Jackson **includes** this field when converting to JSON.

### **Purpose**

Break infinite loops in bidirectional relationships **by marking the “forward” path”.**

### **Where you put it**

On the **parent** entity — usually:

- `OneToMany` list
    
- `OneToOne` parent side
    

Example:

```java
@OneToMany(mappedBy = "user")
@JsonManagedReference
private List<Post> posts;
```

### **Serialization behavior**

When serializing a User → posts will appear.

### **When to use**

- Parent-child relationship with back-reference
    
- REST APIs using JPA entities directly (not DTOs)
    

### **Pros**

- Simple
    
- Prevents infinite recursion
    
- Automatic
    

### **Cons**

- Won’t work if you need to serialize both directions
    
- Requires matching back reference
    
- Harder to use in complex models
    

---

# 🟧 **2. @JsonBackReference**

### **What it is**

The **child** side of the relationship.

### **What it does**

Jackson will **NOT** include this field during serialization.

### **Purpose**

Mark the **backward reference** to prevent infinite loops.

### **Where you put it**

The side that contains the **foreign key**.

Example:

```java
@ManyToOne
@JoinColumn(name = "user_id")
@JsonBackReference
private User user;
```

### **Serialization behavior**

When serializing a User:

- Posts list appears
    
- Each Post **does NOT** include the User field
    

### **When to use**

- Bidirectional JPA relationships
    
- You only want to show parent → children direction
    

### **Pros**

- Safely prevents recursion
    
- Child side is hidden cleanly
    

### **Cons**

- You lose child→parent information in JSON
    
- Not good for rich APIs where both sides are needed
    

---

# 🟫 **3. @JsonIgnore**

### **What it is**

Low-level “shut up and hide this from JSON” annotation.

### **What it does**

**Always ignores** the field in JSON:

- serialize → hidden
    
- deserialize → hidden
    

### **Purpose**

Hide something from JSON permanently.

### **Where you put it**

Anywhere you want JSON to ignore a field completely.

Example:

```java
@ManyToOne
@JoinColumn(name = "user_id")
@JsonIgnore
private User user;
```

### **Serialization behavior**

Same as if the field does not exist.

### **When to use**

- You don’t ever want this field in APIs
    
- Sensitive data (password, internal objects)
    
- Bidirectional fix when Managed/Back is overkill
    
- Avoid JSON recursion fast
    

### **Pros**

- Very simple
    
- No pairing required
    
- Works everywhere
    

### **Cons**

- Too strong — hides field always
    
- Cannot selectively show or hide
    
- Not ideal for relationships needing both sides
    

---

# 🟩 **4. @JsonIdentityInfo**

### **What it is**

A powerful solution that gives each entity a **JSON ID**, so recursion stops naturally.

### **What it does**

Instead of hiding references, it outputs references as **IDs**.

### **Purpose**

Allow full object graph (both directions) **without recursion**.

### **Example**

```java
@JsonIdentityInfo(
    generator = ObjectIdGenerators.PropertyGenerator.class,
    property = "id"
)
@Entity
public class User {
```

### JSON OUTPUT:

Instead of infinite nesting, you get:

```json
{
  "id": 1,
  "name": "Ethan",
  "posts": [
    {
      "id": 10,
      "title": "Hello",
      "user": 1
    }
  ]
}
```

See how `"user": 1` references the ID instead of the object?  
That stops recursion.

### **When to use**

- Complex models
    
- Graph-like structures
    
- Want both sides of relationship visible
    
- Not happy with Managed/Back pair
    

### **Pros**

- Very powerful
    
- Both directions appear in JSON
    
- Perfect for graph data structures
    

### **Cons**

- JSON becomes less pretty
    
- More complex to configure
    
- Not ideal for simple REST output
    

---

# 🧠 **Super Summary (Half-Brain Mode)**

|Annotation|Purpose|Effect|
|---|---|---|
|**@JsonManagedReference**|Parent side|Visible|
|**@JsonBackReference**|Child side|Hidden|
|**@JsonIgnore**|Hide always|Invisible|
|**@JsonIdentityInfo**|Use IDs to refer|Both sides visible without recursion|


###### Tags : [[0 - Spring Framework]]