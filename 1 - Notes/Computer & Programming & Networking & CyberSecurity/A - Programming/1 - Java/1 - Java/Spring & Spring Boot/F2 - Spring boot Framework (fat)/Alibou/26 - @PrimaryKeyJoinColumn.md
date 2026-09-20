
**@PrimaryKeyJoinColumn** is a JPA annotation used in **entity inheritance** when child and parent entities share the **same primary key value**.

Translation from Hibernate-speak to human: the child table’s primary key is also a foreign key pointing to the parent table’s primary key.

### Where it’s used

- **Inheritance strategies**: mainly `JOINED`
    
- **Relationship**: child ↔ parent
    
- **Key idea**: one ID, two tables, no extra FK column
    

### What it does

- Tells JPA:  
    “This entity’s primary key is joined to the parent entity’s primary key.”
    

### Example

```java
@Entity
@Inheritance(strategy = InheritanceType.JOINED)
class Person {
    @Id
    private Long id;
}
```

```java
@Entity
@PrimaryKeyJoinColumn(name = "id")
class Student extends Person {
    private String major;
}
```

**Resulting tables**

```
person
------
id (PK)

student
-------
id (PK + FK → person.id)
major
```

### Why it exists

- Avoids duplicate IDs
    
- Enforces strict 1-to-1 inheritance mapping
    
- Cleaner schema than random foreign keys everywhere
    

### When NOT to use it

- `SINGLE_TABLE` inheritance
    
- Unrelated entities
    
- Normal `@ManyToOne` / `@OneToOne` mappings
    

### One-line summary

**@PrimaryKeyJoinColumn = child PK is also parent FK. Same ID, different table.**

Hibernate didn’t invent this to annoy you. It just looks that way.

##### Tags : [[0 - Spring Framework]]