


## Part 1 — Abstract Classes vs Interfaces

Both abstract classes and interfaces let you define a **supertype** and achieve abstraction/polymorphism. They differ in **state, inheritance, constructors, method bodies, and evolution**.

### Abstract class
A class declared `abstract`:
- Cannot be instantiated.
- Can have **abstract methods** (no body) and **concrete methods**.
- Can have **instance fields**, constructors, initializer blocks, and any access modifiers.
- Supports **single inheritance**: a class can extend only one abstract class.
- Is used when related classes share **state** and **implementation**.

```java
abstract class Shape {
    protected String name;              // state

    Shape(String name) { this.name = name; }

    abstract double area();             // must be implemented

    void describe() {                   // shared behavior
        System.out.println(name + " area = " + area());
    }
}

class Circle extends Shape {
    private final double r;

    Circle(double r) {
        super("Circle");
        this.r = r;
    }

    @Override
    double area() { return Math.PI * r * r; }
}
```

### Interface
An interface defines a **contract**:
- A class can implement **many** interfaces.
- Historically had only abstract methods and constants.
- Since Java 8: can have `default` and `static` methods.
- Since Java 9: can have `private` methods.
- Cannot have instance fields (only `public static final` constants).
- Cannot have constructors.
- Methods are implicitly `public` unless declared `private`.

```java
interface Drawable {
    void draw();                        // public abstract

    default void drawTwice() {          // optional behavior
        draw();
        draw();
    }

    static Drawable nullDrawable() {    // utility, not inherited
        return () -> {};
    }
}
```

### Key differences

| Feature | Abstract class | Interface |
|---|---|---|
| Inheritance | `extends` one class | `implements` many interfaces |
| State | Instance fields allowed | Only `public static final` constants |
| Constructors | Yes | No |
| Method bodies | Abstract + concrete | Abstract, `default`, `static`, `private` |
| Access modifiers | Any | `public` (or `private` for helpers) |
| Purpose | Shared identity + code | Capability / contract |
| Evolution | Adding concrete method is safe | Adding abstract method breaks implementors; `default` is safe |
| `final` methods | Allowed | Not allowed |
| Multiple inheritance | No | Yes (of type) |

### When to use which

**Use an abstract class when:**
- Classes are closely related and share **state** or **common implementation**.
- You need constructors, protected members, or non-public methods.
- You want to provide a **partial implementation** and force subclasses to fill gaps.
- Example: `InputStream`, `AbstractList`.

**Use an interface when:**
- Unrelated classes should share a **capability**.
- You need **multiple inheritance of type**.
- You want a pure contract with no implementation details.
- You want to support functional programming (`@FunctionalInterface`).
- Example: `Comparable`, `Runnable`, `List`.

**Use both together when:**
- You define an interface for the contract.
- You provide an abstract **skeletal implementation** to reduce boilerplate.
- Example: `List` (interface) + `AbstractList` (skeletal implementation).

---

## Default and Static Methods on Interfaces

### Default methods
A `default` method provides an implementation that implementing classes inherit unless they override it.

```java
interface Greeter {
    void greet(String name);

    default void greetTwice(String name) {
        greet(name);
        greet(name);
    }
}
```

Why they exist:
- Allow adding methods to interfaces **without breaking existing implementations**.
- Enable mixin-like behavior.
- Support optional operations.

Rules:
- A class method always wins over a default method.
- If two interfaces provide conflicting defaults, the class must override.
- If one interface extends another, the **most specific** default wins.
- A default method cannot override `Object` methods like `equals`, `hashCode`, `toString`.

Conflict example:

```java
interface A { default void hello() { System.out.println("A"); } }
interface B { default void hello() { System.out.println("B"); } }

class C implements A, B {
    @Override
    public void hello() {
        A.super.hello();   // explicitly choose one
    }
}
```

### Static methods
Static interface methods belong to the **interface**, not to implementing classes.

```java
interface Vehicle {
    static Vehicle createDefault() {
        return new Car();
    }
}

Vehicle v = Vehicle.createDefault();
```

Key points:
- Not inherited by implementing classes.
- Not overridden — they can be hidden by a class’s own static method.
- Called via `InterfaceName.method()`.
- Useful for factory methods and utility helpers.

### Private methods (Java 9+)
Private interface methods let `default` and `static` methods share code without exposing it.

```java
interface Calculator {
    default int add(int a, int b) { return compute(a, b, '+'); }
    default int sub(int a, int b) { return compute(a, b, '-'); }

    private int compute(int a, int b, char op) {
        return op == '+' ? a + b : a - b;
    }
}
```

---

## Part 2 — Java Enums

An `enum` is a special class that represents a **fixed set of constants**. It is type-safe, powerful, and far more than a simple list of names.

### Basic enum

```java
enum Direction {
    NORTH, SOUTH, EAST, WEST
}
```

- Each constant is a `public static final` instance of the enum.
- The enum implicitly extends `java.lang.Enum`.
- You cannot use `new` to create enum instances.
- Enums can be used in `switch`, `EnumSet`, `EnumMap`, and more.

### Enums with fields and methods

Enums can have fields, constructors, and methods. Constructors are **implicitly private**.

```java
enum Planet {
    MERCURY(3.303e+23, 2.4397e6),
    VENUS(4.869e+24, 6.0518e6),
    EARTH(5.976e+24, 6.37814e6);

    private final double mass;
    private final double radius;

    Planet(double mass, double radius) {
        this.mass = mass;
        this.radius = radius;
    }

    double surfaceGravity() {
        return 6.67300E-11 * mass / (radius * radius);
    }
}
```

Usage:

```java
double g = Planet.EARTH.surfaceGravity();
```

### Constant-specific behavior

Enums can declare abstract methods, and each constant must implement them.

```java
enum Operation {
    PLUS {
        @Override
        public int apply(int a, int b) { return a + b; }
    },
    MINUS {
        @Override
        public int apply(int a, int b) { return a - b; }
    };

    public abstract int apply(int a, int b);
}
```

This is a clean way to implement the **strategy pattern** without separate classes.

### Enums implementing interfaces

```java
interface Describable {
    String description();
}

enum Color implements Describable {
    RED {
        @Override
        public String description() { return "Warm"; }
    },
    BLUE {
        @Override
        public String description() { return "Cool"; }
    };
}
```

### Switch on enums

Classic switch:

```java
Day day = Day.MONDAY;

switch (day) {
    case MONDAY:
    case FRIDAY:
        System.out.println("Work day");
        break;
    case SATURDAY:
    case SUNDAY:
        System.out.println("Weekend");
        break;
    default:
        System.out.println("Midweek");
}
```

Arrow syntax (Java 14+):

```java
switch (day) {
    case MONDAY, FRIDAY -> System.out.println("Work day");
    case SATURDAY, SUNDAY -> System.out.println("Weekend");
    default -> System.out.println("Midweek");
}
```

Switch expression:

```java
String type = switch (day) {
    case SATURDAY, SUNDAY -> "Weekend";
    default -> "Weekday";
};
```

Notes:
- In a `switch` on an enum, cases use the **unqualified constant name**: `case MONDAY:`, not `case Day.MONDAY:`.
- Switch on `null` throws `NullPointerException`.
- For enum switch expressions, if all constants are covered, no `default` is required.

### Common enum methods

```java
Direction d = Direction.NORTH;

d.name();                 // "NORTH"
d.ordinal();              // 0
Direction.valueOf("NORTH"); // Direction.NORTH
Direction.values();       // array of all constants
d.compareTo(Direction.SOUTH); // negative
```

- `name()` returns the exact declared name.
- `ordinal()` returns the position (0-based). Avoid persisting `ordinal()`; use an explicit field instead.
- `valueOf(String)` throws `IllegalArgumentException` if not found.

### Enum collections

`EnumSet` and `EnumMap` are highly optimized for enums.

```java
EnumSet<Direction> vertical = EnumSet.of(Direction.NORTH, Direction.SOUTH);
EnumMap<Direction, String> labels = new EnumMap<>(Direction.class);
```

### Enum singleton

The enum singleton is the safest way to implement a singleton in Java.

```java
enum Singleton {
    INSTANCE;

    void doWork() {
        System.out.println("Working");
    }
}
```

It is serialization-safe and thread-safe.

### When to use enums

Use enums when:
- You have a fixed set of related constants.
- You need type safety instead of `int` or `String` constants.
- You want constants to carry data or behavior.
- You are implementing state machines, strategies, or command patterns.
- You need efficient `EnumSet`/`EnumMap` collections.

Avoid enums when:
- The set of values is not known at compile time.
- You need to extend the type (enums cannot extend another class).

---

## Quick Decision Guide

| Question | Choose |
|---|---|
| Need shared state/constructors? | Abstract class |
| Need multiple inheritance of type? | Interface |
| Defining a capability? | Interface |
| Closely related classes with common code? | Abstract class |
| Want optional methods without breaking implementors? | Interface `default` method |
| Utility method tied to a type? | Interface `static` method |
| Fixed set of constants with behavior? | Enum |
| Need switch over a fixed set? | Enum |
| Need a safe singleton? | Enum |

These constructs work together: interfaces define contracts, abstract classes provide partial implementations, default methods allow safe evolution, and enums give you type-safe constants with full object-oriented power.


[[Java]]