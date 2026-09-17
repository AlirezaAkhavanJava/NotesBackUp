

A **record** is a special kind of Java class designed to model **immutable data** with a fixed set of components.

Records were introduced as a preview in Java 14 and became a permanent feature in **Java 16**.

The main idea is:

> **Use a record when the primary purpose of a class is to carry data.**

---

## 1. Basic syntax

Traditional class:

```java
public final class User {

    private final String name;
    private final int age;

    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String name() {
        return name;
    }

    public int age() {
        return age;
    }
}
```

With a record:

```java
public record User(String name, int age) {
}
```

Java automatically provides the equivalent data-oriented machinery.

```text
User
 ├── name
 ├── age
 ├── constructor
 ├── name()
 ├── age()
 ├── equals()
 ├── hashCode()
 └── toString()
```

---

# 2. Record components

This:

```java
public record User(String name, int age) {
}
```

defines two **record components**:

```text
String name
int    age
```

Access them with:

```java
User user = new User("Ali", 25);

System.out.println(user.name());
System.out.println(user.age());
```

Notice:

```java
user.name()
```

not:

```java
user.getName()
```

Records use component-named accessor methods by default.

---

# 3. Constructor is generated automatically

For:

```java
public record User(String name, int age) {
}
```

Java provides a canonical constructor conceptually equivalent to:

```java
public User(String name, int age) {
    this.name = name;
    this.age = age;
}
```

Therefore:

```java
User user = new User("Ali", 25);
```

---

# 4. Records are shallowly immutable

This is an important rule.

A record's components cannot be reassigned after construction:

```java
public record User(String name, int age) {
}
```

You cannot do:

```java
user.name = "John"; // ❌
```

However, **immutability is shallow**.

For example:

```java
public record User(List<String> roles) {
}
```

The `roles` reference cannot be reassigned, but the underlying `List` might still be mutable:

```java
roles.add("ADMIN");
```

So:

```text
record
  │
  ├── component reference → cannot be reassigned
  │
  └── referenced object → may still be mutable
```

If you need deep immutability, you must design/copy the contained objects appropriately.

---

# 5. Records automatically provide `equals()`

Two records containing the same component values compare equal.

```java
User a = new User("Ali", 25);
User b = new User("Ali", 25);

System.out.println(a.equals(b));
```

Result:

```text
true
```

The generated `equals()` compares the record components.

---

# 6. Records automatically provide `hashCode()`

```java
User user = new User("Ali", 25);

System.out.println(user.hashCode());
```

The hash code is based on the record components.

This makes records particularly convenient as values used in:

```java
HashMap
HashSet
```

---

# 7. Records automatically provide `toString()`

```java
User user = new User("Ali", 25);

System.out.println(user);
```

Produces something similar to:

```text
User[name=Ali, age=25]
```

---

# 8. You can add methods

A record is still a class.

You can define methods:

```java
public record User(String name, int age) {

    public boolean isAdult() {
        return age >= 18;
    }
}
```

Usage:

```java
User user = new User("Ali", 25);

System.out.println(user.isAdult());
```

---

# 9. You can validate data

Records support a special constructor called the **compact canonical constructor**.

```java
public record User(String name, int age) {

    public User {
        if (age < 0) {
            throw new IllegalArgumentException("Age cannot be negative");
        }
    }
}
```

Notice that you don't write:

```java
this.name = name;
this.age = age;
```

Java performs the component assignments automatically.

Conceptually:

```text
new User(...)
      │
      ▼
canonical constructor
      │
      ├── validation
      │
      ▼
component assignment
```

---

# 10. You can write the full canonical constructor

You can also explicitly declare it:

```java
public record User(String name, int age) {

    public User(String name, int age) {
        if (age < 0) {
            throw new IllegalArgumentException();
        }

        this.name = name;
        this.age = age;
    }
}
```

The compact form is usually cleaner for validation.

---

# 11. You can define static members

Records can have static fields and methods.

```java
public record User(String name, int age) {

    public static final int MIN_AGE = 0;

    public static User anonymous() {
        return new User("Anonymous", 0);
    }
}
```

---

# 12. You cannot extend another class

This is an important restriction.

You cannot:

```java
public record User(...) extends Person {
}
```

A record implicitly extends:

```java
java.lang.Record
```

and Java classes can only have one superclass.

So:

```text
Record
  ↑
User
```

You cannot change the superclass.

---

# 13. Records can implement interfaces

This is allowed:

```java
public interface Identifiable {
    long id();
}
```

```java
public record User(long id, String name)
        implements Identifiable {
}
```

This is perfectly valid.

So:

```text
        Interface
            ↑
            │
          User
         record
            │
            ▼
         Record
```

---

# 14. Records cannot declare instance fields

This is **not allowed**:

```java
public record User(String name) {

    private int age; // ❌
}
```

The record's instance state is represented by its components.

You can have static fields:

```java
public record User(String name) {

    private static final int VERSION = 1;
}
```

but not additional instance fields.

---

# 15. Records are implicitly final

You cannot extend a record:

```java
public record User(String name) {
}
```

Then:

```java
class Admin extends User { } // ❌
```

Records are effectively:

```text
final
+
data-oriented class
```

---

# 16. Record components must be initialized

Because the canonical constructor establishes the record state, every component must receive a value.

```java
public record User(String name, int age) {
}
```

requires:

```java
new User("Ali", 25);
```

---

# 17. Records are excellent for DTOs

One of the most useful applications in Spring Boot is a **DTO**.

Instead of:

```java
public class UserResponse {

    private final Long id;
    private final String username;
    private final String email;

    // constructor
    // getters
    // equals
    // hashCode
    // toString
}
```

you can write:

```java
public record UserResponse(
        Long id,
        String username,
        String email
) {
}
```

Then:

```java
@GetMapping("/{id}")
public UserResponse getUser(@PathVariable Long id) {
    return new UserResponse(
            id,
            "alireza",
            "ali@example.com"
    );
}
```

This is one of the most common practical uses of records in modern Spring applications.

---

# Rules of Records

Here's the part worth memorizing.

|Rule|Meaning|
|---|---|
|`record` is a special class|It is still a Java class|
|Components are declared in the header|`record User(String name, int age)`|
|Components are final|They cannot be reassigned|
|Records are implicitly final|They cannot be extended|
|Records extend `java.lang.Record`|You cannot choose another superclass|
|Cannot declare additional instance fields|State comes from components|
|Can implement interfaces|`implements MyInterface` is allowed|
|Can have methods|Normal instance/static methods are allowed|
|Can have static fields|Allowed|
|Constructor is generated|Canonical constructor exists automatically|
|Can validate in constructor|Use compact canonical constructor|
|`equals()` is generated|Based on components|
|`hashCode()` is generated|Based on components|
|`toString()` is generated|Displays component values|
|Accessors are generated|`name()` rather than `getName()`|
|Immutability is shallow|Referenced mutable objects can still change|

---

# When should you use a record?

Use a record when the class primarily represents **data/value state**.

Good examples:

```java
public record UserResponse(
        Long id,
        String username
) {}
```

```java
public record Point(
        double x,
        double y
) {}
```

```java
public record Money(
        BigDecimal amount,
        Currency currency
) {}
```

```java
public record LoginRequest(
        String username,
        String password
) {}
```

Especially useful for:

```text
DTOs
API requests/responses
Value objects
Projections
Configuration/data carriers
Small immutable data structures
```

---

# When NOT to use a record

Don't use a record simply because it is shorter.

A normal class is usually better when the object has:

- Significant mutable state
    
- Complex lifecycle/state transitions
    
- A need for inheritance
    
- Many framework-specific requirements around mutable JavaBeans
    
- Identity-based domain behavior rather than primarily value-based semantics
    

For example, a typical JPA entity is generally better represented as a normal class rather than a record.

---

## Mental model

Think of a record as:

```text
              RECORD
                 │
        ┌────────┼────────┐
        │        │        │
     State    Equality   Display
        │        │        │
   components  equals()  toString()
        │
        ├── constructor
        ├── accessors
        └── hashCode()
```

**Core idea:**

> **A record is Java's concise way of declaring a class whose identity is primarily its data components.**

For modern Java, the important comparison to understand next is **`record` vs normal class vs sealed class vs enum**, because they solve four very different modeling problems.


[[Java]]