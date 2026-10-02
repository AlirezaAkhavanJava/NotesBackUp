
## `@Builder` (the simple one)

### What it is

Generates a **builder for a single class**.

### Works when

- No inheritance
    
- Or you don’t care about parent fields
    

### Example

```java
@Builder
class User {
    String name;
    int age;
}
```

Usage:

```java
User u = User.builder()
             .name("Ethan")
             .age(25)
             .build();
```

### Hard limitation

❌ **Does NOT work properly with inheritance**

If `User extends BaseEntity`, parent fields are ignored or cause pain.

---

## `@SuperBuilder` (the inheritance-aware one)

### What it is

A builder that **supports class hierarchies**.

It generates:

- One builder per class
    
- Builders that **extend each other**, just like the classes
    

---

## Example with inheritance (this is the real difference)

### Parent

```java
@SuperBuilder
class BaseEntity {
    Long id;
}
```

### Child

```java
@SuperBuilder
class User extends BaseEntity {
    String name;
}
```

Usage:

```java
User user = User.builder()
                .id(1L)
                .name("Ethan")
                .build();
```

This **does NOT work** with `@Builder`.

---

## Key differences (memorize this table)

|Feature|`@Builder`|`@SuperBuilder`|
|---|---|---|
|Supports inheritance|❌|✅|
|Parent fields in builder|❌|✅|
|Builder hierarchy|❌|✅|
|Complexity|Low|Higher|
|Lombok magic level|Mild|Spicy|

---

## Required rules for `@SuperBuilder`

These are non-negotiable:

1️⃣ **All classes in the hierarchy must use `@SuperBuilder`**  
❌ Mixing with `@Builder` breaks everything

2️⃣ Constructors are generated differently

- Lombok creates **protected constructors**
    
- Reflection frameworks are happier than you think
    

3️⃣ Slightly heavier bytecode

- Nothing you’ll notice unless you enjoy micro-optimizing nothing
    

---

## `toBuilder()` support

Both support it, but:

```java
@SuperBuilder(toBuilder = true)
```

Allows:

```java
User updated = user.toBuilder()
                   .name("New Name")
                   .build();
```

Works across inheritance. This alone justifies `@SuperBuilder`.

---

## When to use which (no ambiguity)

### Use `@Builder` when:

- Class is `final`
    
- No inheritance
    
- DTOs, records, simple objects
    

### Use `@SuperBuilder` when:

- BaseEntity pattern
    
- JPA entities with inheritance
    
- Anything that says `extends`
    

---

## Common mistakes (classic Lombok traps)

❌ Using `@Builder` on a subclass  
❌ Mixing `@Builder` and `@SuperBuilder`  
❌ Forgetting to annotate the parent  
❌ Assuming it works with JPA proxies magically (it mostly does, but still)

---

## One-line mental model

> **`@Builder` builds objects.  
> `@SuperBuilder` builds object hierarchies.**

That’s it. Anything else you’ve heard was someone learning this the hard way.

###### Tags : [[0 - Spring Framework]]