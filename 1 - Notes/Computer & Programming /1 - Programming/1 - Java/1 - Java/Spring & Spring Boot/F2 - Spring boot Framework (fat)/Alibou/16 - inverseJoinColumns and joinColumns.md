
## `joinColumns`

### Definition

**Foreign key columns in the join table that reference the owning entity.**

In human terms:

> “This column points back to **me**.”

### Rules

- Used **only inside `@JoinTable`**
    
- Refers to the entity **where the annotation is written**
    
- Usually references that entity’s **primary key**
    

### Example

```java
@JoinTable(
    joinColumns = @JoinColumn(name = "course_id")
)
```

Means:

```
join table.course_id → course.id
```

---

## `inverseJoinColumns`

### Definition

**Foreign key columns in the join table that reference the other entity.**

In human terms:

> “This column points to **the other side**.”

### Rules

- Used **only inside `@JoinTable`**
    
- Refers to the **inverse (target) entity**
    
- Also usually references its **primary key**
    

### Example

```java
@JoinTable(
    inverseJoinColumns = @JoinColumn(name = "author_id")
)
```

Means:

```
join table.author_id → author.id
```

---

## Side-by-side comparison

|Attribute|`joinColumns`|`inverseJoinColumns`|
|---|---|---|
|References|Owning entity|Other entity|
|FK direction|Join table → this entity|Join table → target entity|
|Written on|Owning side only|Owning side only|
|Common confusion|Swapped order|Forgetting it|

---

## One-sentence memory trick

> **joinColumns = me**  
> **inverseJoinColumns = the other guy**

---

## Final truth (Hibernate reality)

- Only the **owning side** defines `@JoinTable`
    
- Only that side **writes rows** into the join table
    
- Inverse side with `mappedBy` is just a spectator
    

That’s it. No extra magic, no hidden behavior.

###### Tags : [[0 - Spring Framework]]