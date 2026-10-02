
**@Polymorphism** is a Hibernate-only annotation that controls **how polymorphic queries behave** across an inheritance hierarchy.

Meaning:  
When you query the **parent entity**, should Hibernate also return **child entities**, or pretend they don’t exist?

Because sometimes you want inheritance, but not _that much_ inheritance.

---

## The annotation

```java
@Polymorphism(type = PolymorphismType.IMPLICIT)
```

Package:

```java
org.hibernate.annotations.Polymorphism
```

Enum:

```java
PolymorphismType.IMPLICIT
PolymorphismType.EXPLICIT
```

---

## Why this exists

By default, JPA assumes **polymorphism is always enabled**.

So this query:

```java
from Animal
```

Returns:

- `Animal`
    
- `Dog`
    
- `Cat`
    
- Every subclass
    

Hibernate lets you say:  
“No. I want only **exactly** `Animal`. Not the children.”

That’s what `@Polymorphism` controls.

---

## PolymorphismType.IMPLICIT (default)

```java
@Polymorphism(type = PolymorphismType.IMPLICIT)
```

### Behavior

- Queries on parent **include subclasses**
    
- This is standard JPA behavior
    
- Works with `SINGLE_TABLE`, `JOINED`, `TABLE_PER_CLASS`
    

### Example

```java
List<Animal> animals =
    entityManager.createQuery("from Animal", Animal.class)
                 .getResultList();
```

Returned:

- Animal
    
- Dog
    
- Cat
    

Hibernate automatically figures out the concrete class.

### Use when

- You actually want polymorphism
    
- 99% of real applications
    

---

## PolymorphismType.EXPLICIT

```java
@Entity
@Polymorphism(type = PolymorphismType.EXPLICIT)
class Animal { }
```

### Behavior

- Parent queries return **ONLY the parent**
    
- Subclasses are excluded unless explicitly queried
    

### Example

```java
from Animal
```

Returns:

- `Animal` only  
    No `Dog`, no `Cat`, no surprises.
    

To get subclasses:

```java
from Dog
from Cat
```

### Why you’d want this

- Huge hierarchies
    
- Performance control
    
- Legacy schemas
    
- When subclasses mean _very_ different things
    

Hibernate is forced to behave instead of being clever.

---

## How it interacts with inheritance strategies

### SINGLE_TABLE

- `IMPLICIT`: discriminator selects all rows
    
- `EXPLICIT`: discriminator selects parent only
    

### JOINED

- `IMPLICIT`: joins parent + child tables
    
- `EXPLICIT`: joins parent table only
    

### TABLE_PER_CLASS

- `IMPLICIT`: uses `UNION`
    
- `EXPLICIT`: skips child tables
    

So yes, `EXPLICIT` can save you from accidental `UNION` disasters.

---

## Important limitations

- **Hibernate-only** (not JPA standard)
    
- Ignored by other providers
    
- Does NOT affect:
    
    - `find()` by ID
        
    - Explicit subclass queries
        
- Affects **HQL / JPQL polymorphic queries only**
    

---

## Common confusion (clear this up)

❌ Not related to Java polymorphism  
❌ Not related to `@DiscriminatorColumn`  
❌ Not a security feature  
❌ Not a fetch strategy

✔ Query behavior control  
✔ Hibernate-specific optimization

---

## When to use it (real advice)

Use `@Polymorphism(EXPLICIT)` only if:

- Your inheritance hierarchy is large
    
- Parent queries are hot paths
    
- You know exactly what you’re doing
    

Otherwise, leave it alone. Hibernate defaults exist for a reason.

---

## One-line summary

**@Polymorphism tells Hibernate whether querying a parent entity should also return its subclasses.**

Hibernate lets you turn polymorphism off because sometimes abstraction is expensive and SQL does not care about your object model.

###### Tags : [[0 - Spring Framework]]