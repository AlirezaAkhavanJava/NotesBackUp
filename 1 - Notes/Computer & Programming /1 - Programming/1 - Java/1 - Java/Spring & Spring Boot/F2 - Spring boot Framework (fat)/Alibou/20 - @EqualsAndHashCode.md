
## What `@EqualsAndHashCode` is

It **generates `equals()` and `hashCode()` methods** for a class so you don’t have to write 40 lines of boilerplate and still get it wrong.

By default, it uses **all non-static fields**.

---

## Basic usage

```java
@EqualsAndHashCode
class User {
    Long id;
    String username;
}
```

Generates:

- `boolean equals(Object o)`
    
- `int hashCode()`
    

Based on `id` and `username`.

---

## Why this matters (especially for you)

- `Set`, `Map` depend on it
    
- Hibernate depends on it
    
- Bugs here are **silent and evil**
    

One wrong equals = disappearing entities.

---

## Important options (the ones that actually matter)

### 1️⃣ `of`

Specify **exact fields** to use.

```java
@EqualsAndHashCode(of = "id")
class User {
    Long id;
    String username;
}
```

✔ Common for JPA entities  
✔ Stable identity

---

### 2️⃣ `exclude`

Exclude specific fields.

```java
@EqualsAndHashCode(exclude = "password")
class User {
    Long id;
    String password;
}
```

Useful, but `of` is safer.

---

### 3️⃣ `callSuper`

Include parent class fields.

```java
@EqualsAndHashCode(callSuper = true)
class User extends BaseEntity {
    String username;
}
```

⚠️ Only use if parent has meaningful identity fields.

---

### 4️⃣ `onlyExplicitlyIncluded`

Nothing is included unless you say so.

```java
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
class User {

    @EqualsAndHashCode.Include
    Long id;

    String username; // ignored
}
```

This is the **least dangerous** option.

---

## The JPA landmine (pay attention)

### ❌ Default behavior is WRONG for entities

```java
@EqualsAndHashCode
@Entity
class User {
    @Id
    @GeneratedValue
    Long id;
}
```

Why it’s bad:

- `id` is `null` before persist
    
- `hashCode()` changes after persist
    
- `Set` and `Map` break silently
    

Hibernate won’t warn you. It will just ruin your day.

---

## Correct pattern for JPA entities

### Best practice

```java
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@Entity
class User {

    @Id
    @GeneratedValue
    @EqualsAndHashCode.Include
    Long id;
}
```

Or use a **natural key** if you have one:

```java
@EqualsAndHashCode(of = "email")
```

---

## Equals & inheritance (danger zone)

- Equals **does NOT play nicely** with inheritance
    
- `callSuper = true` is rarely correct
    
- Proxy subclasses can break symmetry
    

For entities, prefer:

- Final equals logic
    
- Or base everything on immutable identifiers
    

---

## Comparison summary

|Option|Use case|
|---|---|
|Default|Simple POJOs|
|`of`|Entities|
|`exclude`|Quick hacks|
|`onlyExplicitlyIncluded`|Safe, explicit|
|`callSuper`|Rare, careful|

---

## One brutal rule to remember

> **If an object can change identity, it should not be in a Set.**

`@EqualsAndHashCode` decides identity. Treat it like a loaded weapon.



###### Tags : [[0 - Spring Framework]]