
**@EmbeddedId** is how JPA represents a **composite primary key** using an **embedded value object**.

Translation:  
your table has more than one column as its primary key, and JPA refuses to pretend that’s normal.

---

## The problem it solves

Some tables have **no single ID column**.

Example:

```
order_id + product_id = PRIMARY KEY
```

JPA needs one field annotated with `@Id`.  
So you bundle multiple columns into **one object**.

That object becomes the ID.

---

## The two required pieces

### 1. The key class

```java
@Embeddable
class OrderItemId implements Serializable {
    Long orderId;
    Long productId;
}
```

Rules Hibernate will enforce:

- Must be `@Embeddable`
    
- Must implement `Serializable`
    
- Must have `equals()` and `hashCode()`
    
- No `@Id` inside it
    

---

### 2. The entity

```java
@Entity
class OrderItem {

    @EmbeddedId
    private OrderItemId id;

    private int quantity;
}
```

### Database

```
order_item
----------
order_id (PK)
product_id (PK)
quantity
```

The two columns together form **one primary key**.

---

## How JPA treats it

- `@EmbeddedId` is the entity’s **identity**
    
- Persistence context uses it as the key
    
- `find()` requires the full object
    

```java
OrderItemId id =
    new OrderItemId(1L, 5L);

entityManager.find(OrderItem.class, id);
```

Half a key = no entity.

---

## EmbeddedId with relationships (important)

```java
@MapsId("orderId")
@ManyToOne
Order order;

@MapsId("productId")
@ManyToOne
Product product;
```

This maps:

- FK columns
    
- PK columns
    
- Same columns. One set.
    

Hibernate reuses the embedded ID fields.

---

## `@EmbeddedId` vs `@IdClass`

Because there are two ways to suffer.

|Feature|@EmbeddedId|@IdClass|
|---|---|---|
|Key object|Single|Separate|
|Cleaner|✅|❌|
|Encapsulation|Good|Bad|
|Recommended|✅|❌|

Use `@IdClass` only if a legacy schema forces it.

---

## Common mistakes

- Forgetting `equals()` / `hashCode()` → broken caching
    
- Using mutable fields → identity crisis
    
- Trying to auto-generate part of it → pain
    
- Querying by partial key → impossible
    

---

## When to use it

- Join tables with extra fields
    
- Legacy schemas
    
- Natural composite keys
    

## When NOT to use it

- If a surrogate ID would be simpler
    
- When performance matters
    
- When your sanity matters
    

---

## One-line summary

**@EmbeddedId lets you define a composite primary key as an embedded value object.**

Hibernate supports it. Databases allow it. Everyone quietly regrets it later.

##### Tags : [[0 - Spring Framework]]