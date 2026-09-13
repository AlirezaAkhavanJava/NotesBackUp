


**`@EmbeddedId` requires the ID class to implement `Serializable` because JPA needs to safely copy, cache, compare, and transport entity identities.**  
Now the long, boring, but correct explanation.

---

## Where the rule comes from

The **JPA specification** explicitly requires that:

- An `@EmbeddedId` class **must implement `Serializable`**
    

This is not Hibernate being dramatic. It’s standard JPA.

---

## What JPA actually does with an ID

An entity ID is used as:

- Key in the **Persistence Context** (1st-level cache)
    
- Key in **2nd-level cache**
    
- Reference in **lazy proxies**
    
- Identity in **distributed sessions / clustering**
    
- Value passed between layers (EntityManager ↔ provider)
    

All of those need:

- Stable binary form
    
- Safe copying
    
- Predictable equality
    

That’s exactly what `Serializable` is for.

---

## Why this matters more for `@EmbeddedId`

With a simple `Long id`, Java already knows how to serialize it.

With `@EmbeddedId`, **you created a custom object**:

```java
class OrderItemId {
    Long orderId;
    Long productId;
}
```

JPA now has to:

- Store it in caches
    
- Clone it internally
    
- Send it around if needed
    

Without `Serializable`, Hibernate can’t guarantee that works.

---

## What happens if you don’t implement it

Best case:

- Hibernate logs warnings
    
- Your IDE complains
    

Worst case:

- Caching breaks
    
- Proxies fail
    
- Serialization errors at runtime
    
- “works on my machine” syndrome
    

Hibernate might let it slide. The spec will not.

---

## Is Java serialization actually used?

Most of the time: **no**.

But JPA needs the **capability**, not constant usage.

Think of it like `equals()`:

- You might not call it
    
- Hibernate definitely will
    

---

## Minimal correct implementation

```java
@Embeddable
public class OrderItemId implements Serializable {

    private Long orderId;
    private Long productId;

    // equals & hashCode REQUIRED
}
```

No custom `serialVersionUID` required unless you enjoy ceremony.

---

## Important side rules (don’t skip these)

For `@EmbeddedId`:

- Fields should be **immutable**
    
- Implement `equals()` and `hashCode()`
    
- Avoid business logic
    
- Treat it as a **value object**
    

If your ID changes, your entity’s identity changes. That’s illegal in JPA land.

---

## One-line summary

**`@EmbeddedId` must implement `Serializable` because JPA treats the ID as a transportable, cacheable identity object, not just a bunch of fields.**

It’s annoying. It’s mandatory. It saves you from invisible bugs later.

###### Tags : [[0 - Spring Framework]]
