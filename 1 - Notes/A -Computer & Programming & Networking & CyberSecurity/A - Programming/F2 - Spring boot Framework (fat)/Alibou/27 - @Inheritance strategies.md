
JPA inheritance strategies. Four ways to model “is-a” in a database. All of them are compromises. Pick the one whose pain you prefer.

---

## 1. `SINGLE_TABLE`

**One table. All classes. All fields. One big mess.**

```java
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "type")
class Animal { @Id Long id; }

@Entity
class Dog extends Animal { String breed; }

@Entity
class Cat extends Animal { Integer lives; }
```

### Database

```
animal
------
id | type | breed | lives
```

### How it works

- One table stores **all subclasses**
    
- A **discriminator column** tells Hibernate what class a row belongs to
    
- Unused columns are `NULL`
    

### Pros

- Fast queries (no joins)
    
- Simplest mapping
    
- Hibernate loves this
    

### Cons

- Lots of `NULL`s
    
- Table grows wide and ugly
    
- Weak schema integrity
    

### Use when

- Performance matters
    
- Subclasses are simple
    
- You don’t care about a “clean” DB
    

---

## 2. `JOINED`

**Normalized. Polite. Slower.**

```java
@Entity
@Inheritance(strategy = InheritanceType.JOINED)
class Animal { @Id Long id; }

@Entity
@PrimaryKeyJoinColumn(name = "id")
class Dog extends Animal { String breed; }
```

### Database

```
animal
------
id

dog
---
id (PK + FK → animal.id)
breed
```

### How it works

- Parent fields in parent table
    
- Child fields in child table
    
- Same primary key shared across tables
    
- Requires SQL `JOIN`s
    

### Pros

- Clean schema
    
- No null columns
    
- Proper relational design
    

### Cons

- Slower reads
    
- More joins
    
- Inserts touch multiple tables
    

### Use when

- Schema quality matters
    
- You have real inheritance
    
- You’re not allergic to joins
    

---

## 3. `TABLE_PER_CLASS`

**Every class gets its own table. Chaos ensues.**

```java
@Entity
@Inheritance(strategy = InheritanceType.TABLE_PER_CLASS)
class Animal { @Id Long id; }

@Entity
class Dog extends Animal { String breed; }
```

### Database

```
animal
------
id

dog
---
id
breed
```

### How it works

- Each class has **its own table**
    
- No shared parent table
    
- Queries across hierarchy use `UNION`
    

### Pros

- No joins
    
- No discriminator
    
- Tables are independent
    

### Cons

- `UNION` queries are slow
    
- IDs must be unique across tables
    
- Many DBs hate this
    
- Hibernate support is shaky
    

### Use when

- Almost never
    
- Legacy schema
    
- You enjoy pain
    

---

## 4. `@MappedSuperclass`

**Not inheritance. Don’t argue.**

```java
@MappedSuperclass
class BaseEntity {
    @Id Long id;
    LocalDateTime createdAt;
}
```

```java
@Entity
class User extends BaseEntity {
    String username;
}
```

### Database

```
user
----
id
created_at
username
```

### How it works

- No table for the superclass
    
- Fields are copied into child tables
    
- No polymorphism
    

### Pros

- Perfect for shared fields
    
- Simple
    
- Zero joins
    

### Cons

- Not queryable as a parent
    
- No inheritance behavior
    

### Use when

- You just want shared fields
    
- Auditing, IDs, timestamps
    

---

## Strategy Comparison (quick sanity table)

|Strategy|Tables|Joins|Nulls|Polymorphism|Performance|
|---|---|---|---|---|---|
|SINGLE_TABLE|1|❌|✅|✅|⭐⭐⭐⭐⭐|
|JOINED|Many|✅|❌|✅|⭐⭐⭐|
|TABLE_PER_CLASS|Many|❌ (UNION)|❌|✅|⭐⭐|
|MappedSuperclass|Child only|❌|❌|❌|⭐⭐⭐⭐⭐|

---

## Brutally honest advice

- **Default choice**: `SINGLE_TABLE`
    
- **Clean DB**: `JOINED`
    
- **Shared fields only**: `@MappedSuperclass`
    
- **TABLE_PER_CLASS**: stop. think. don’t.
    

Hibernate gives you options. None are perfect. Databases don’t understand inheritance and never will.

###### Tags : [[0 - Spring Framework]]