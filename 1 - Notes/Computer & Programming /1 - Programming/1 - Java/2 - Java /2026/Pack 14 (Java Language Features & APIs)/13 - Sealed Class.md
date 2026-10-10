


A **sealed class** is a class that explicitly controls **which classes are allowed to extend it**.

It was finalized in **Java 17**.

```java
public sealed class Animal
        permits Dog, Cat {
}
```

Here, `Animal` says:

> Only `Dog` and `Cat` are allowed to extend me.

```text
             Animal
            /      \
         Dog        Cat
```

---

## 1. Basic syntax

```java
public sealed class Animal
        permits Dog, Cat {
}
```

The permitted subclasses must explicitly declare how they participate in the hierarchy.

### `final`

```java
public final class Dog extends Animal {
}
```

`Dog` cannot be extended further.

### `sealed`

```java
public sealed class Cat extends Animal
        permits PersianCat, TigerCat {
}
```

`Cat` continues restricting its subclasses.

### `non-sealed`

```java
public non-sealed class Cat extends Animal {
}
```

`non-sealed` removes the restriction for that branch.

Now:

```java
public class PersianCat extends Cat {
}
```

is allowed.

---

# 2. The three possibilities

Every direct subclass of a sealed class must be one of:

```text
                    sealed Animal
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
        final          sealed        non-sealed
          │              │              │
       cannot         restricted      unrestricted
       extend         hierarchy       hierarchy
```

Example:

```java
public sealed class Animal
        permits Dog, Cat, Bird {
}
```

```java
public final class Dog extends Animal {
}
```

```java
public sealed class Cat extends Animal
        permits PersianCat {
}
```

```java
public non-sealed class Bird extends Animal {
}
```

---

# 3. Why use sealed classes?

The main purpose is **controlled inheritance**.

Without a sealed class:

```java
class Animal {}

class Dog extends Animal {}
class Cat extends Animal {}
class Snake extends Animal {}
class Whatever extends Animal {}
```

Anyone can create another subclass.

With:

```java
sealed class Animal permits Dog, Cat {}
```

the hierarchy becomes explicitly defined:

```text
Animal
 ├── Dog
 └── Cat
```

No other class can directly extend `Animal`.

---

# 4. Sealed classes work very well with pattern matching

This is one of their biggest advantages.

```java
sealed interface Shape
        permits Circle, Rectangle {
}
```

```java
final class Circle implements Shape {
}

final class Rectangle implements Shape {
}
```

Then:

```java
static double area(Shape shape) {
    return switch (shape) {
        case Circle c -> 0;
        case Rectangle r -> 0;
    };
}
```

Because Java knows that `Shape` can only be `Circle` or `Rectangle`, the compiler can determine that the hierarchy is exhaustive.

This is especially useful for **domain modeling**.

---

# 5. Sealed class vs final class

They solve different problems.

### `final`

```java
public final class Animal {
}
```

Means:

> **Nobody can extend this class.**

```text
Animal
  X
```

### `sealed`

```java
public sealed class Animal
        permits Dog, Cat {
}
```

Means:

> **Only these specific classes can extend me.**

```text
Animal
 ├── Dog
 └── Cat
```

So:

```text
final  → zero subclasses
sealed → controlled subclasses
```

---

# 6. Sealed interface

Sealing isn't limited to classes.

```java
public sealed interface Payment
        permits CashPayment, CardPayment {
}
```

Then:

```java
public final class CashPayment implements Payment {
}
```

```java
public final class CardPayment implements Payment {
}
```

This is often very useful when modeling a fixed set of domain types.

---

# 7. Important rule

A permitted subclass must be explicitly declared as:

```java
final
```

or:

```java
sealed
```

or:

```java
non-sealed
```

For example:

```java
public sealed class Animal
        permits Dog, Cat {
}
```

This is valid:

```java
public final class Dog extends Animal {
}
```

This is also valid:

```java
public non-sealed class Cat extends Animal {
}
```

But simply:

```java
public class Dog extends Animal {
}
```

is **not valid**, because `Dog` must explicitly define what happens to further inheritance.

---

## Mental model

Think of a sealed class as a **closed inheritance contract**:

```text
                    sealed
                   ┌───────┐
                   │ Animal│
                   └───┬───┘
              ┌────────┼────────┐
              ▼        ▼        ▼
            final    sealed   non-sealed
              │        │        │
              ▼        ▼        ▼
             STOP   controlled  open
                    hierarchy
```

**In one sentence:**

> A **sealed class** restricts inheritance to a known set of permitted subclasses, giving the compiler and developer explicit knowledge of the type hierarchy.


[[Java]]