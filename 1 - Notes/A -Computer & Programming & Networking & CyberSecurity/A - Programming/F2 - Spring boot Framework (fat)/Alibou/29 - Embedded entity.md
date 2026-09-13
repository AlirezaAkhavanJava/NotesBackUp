
An **embedded entity** in Spring Data JPA is an object whose fields are **stored in the same table as the owning entity**, instead of its own table.

Translation:  
no table, no ID, no life of its own. It’s just a structured pile of columns.

---

## The two annotations that matter

- `@Embeddable` → marks the class
    
- `@Embedded` → uses it inside an entity
    

---

## Basic example

```java
@Embeddable
class Address {
    String city;
    String street;
    String zipCode;
}
```

```java
@Entity
class User {
    @Id
    Long id;

    String name;

    @Embedded
    Address address;
}
```

### Database table

```
user
----
id
name
city
street
zip_code
```

No `address` table. No joins. No drama.

---

## What an embedded entity really is

- **Value Object**, not an Entity
    
- Has **no @Id**
    
- Cannot be queried directly
    
- Lives and dies with its owner
    
- Stored inline in the owner’s table
    

If the parent row is deleted, the embedded data vanishes without a funeral.

---

## Multiple embedded objects: name collisions

Hibernate is not psychic.

```java
@Embedded
Address home;

@Embedded
Address work;
```

Boom. Duplicate column names.

### Fix with `@AttributeOverrides`

```java
@AttributeOverrides({
  @AttributeOverride(name = "city", column = @Column(name = "home_city")),
  @AttributeOverride(name = "street", column = @Column(name = "home_street"))
})
@Embedded
Address home;
```

Yes, it’s verbose. Yes, everyone hates it.

---

## Embedded vs Entity (important)

|Feature|@Embedded|@Entity|
|---|---|---|
|Has table|❌|✅|
|Has ID|❌|✅|
|Queryable|❌|✅|
|Lifecycle|Owned|Independent|
|Relationships|❌|✅|

If it needs:

- its own lifecycle
    
- relationships
    
- lazy loading
    

It’s **not embedded**. Period.

---

## Nested embedding

Yes, you can embed inside an embeddable.

```java
@Embeddable
class Geo {
    Double lat;
    Double lng;
}

@Embeddable
class Address {
    String city;
    @Embedded
    Geo geo;
}
```

Hibernate will flatten everything like a steamroller.

---

## When to use embedded entities

Use them for:

- Address
    
- Money (amount + currency)
    
- Date ranges
    
- Audit info (createdBy, createdAt)
    

Basically: **concepts, not things**.

---

## When NOT to use them

- Shared data across entities
    
- Anything with an ID
    
- Anything you’d ever want to `JOIN`
    

---

## One-line summary

**An embedded entity is a value object whose fields are stored in the parent table and have no identity of their own.**

Hibernate calls it elegant. SQL calls it columns.

##### Tags : [[0 - Spring Framework]]