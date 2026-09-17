
# Java OOP Fundamentals — In Depth

Object-Oriented Programming (OOP) models software as a set of interacting objects. In Java, the core building blocks are **classes, objects, inheritance, polymorphism, abstraction, and encapsulation**, supported by **constructors, `this`/`super`, access modifiers, `static`, and `final`**.

---

## 1. Classes and Objects

### Class
A **class** is a blueprint/template that defines:
- **State** — fields (instance variables)
- **Behavior** — methods
- **Initialization** — constructors
- **Nested types** — inner classes, enums, interfaces, etc.

```java
class Person {
    String name;
    int age;

    void speak() {
        System.out.println("My name is " + name);
    }
}
```

A class is a reference type. It defines what objects of that type will look like and how they behave.

### Object
An **object** is a runtime instance of a class, created with `new`.

```java
Person p = new Person();
p.name = "Alice";
p.age = 30;
p.speak();
```

Each object has:
- **Identity** — a unique reference
- **State** — its own copy of instance fields
- **Behavior** — methods it can execute

Objects live on the heap. The variable `p` holds a reference to the object, not the object itself.

---

## 2. Constructors

A **constructor** is a special block used to initialize a new object. It:
- Has the same name as the class
- Has **no return type** (not even `void`)
- Is called when you use `new`
- Is **not inherited**

```java
class Person {
    String name;
    int age;

    Person(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

### Key constructor rules
- If you declare **no constructor**, the compiler provides a **default no-arg constructor** that calls `super()`.
- If you declare **any constructor**, the default constructor is no longer provided.
- Constructors can be **overloaded** (same name, different parameter lists).
- A constructor can call another constructor in the same class using `this(...)`.
- A constructor can call a superclass constructor using `super(...)`.
- `this(...)` or `super(...)` must be the **first statement** in a constructor.
- If neither is used, the compiler inserts `super()` automatically.
- Constructors can be `private` (e.g., singletons, factories, utility classes).

```java
class Employee extends Person {
    double salary;

    Employee(String name, int age, double salary) {
        super(name, age); // must be first
        this.salary = salary;
    }
}
```

---

## 3. `this` and `super`

### `this`
`this` is a reference to the **current object**.

Common uses:
- Disambiguate fields from parameters: `this.name = name;`
- Call another constructor in the same class: `this(...)`
- Pass the current object to another method
- Return the current object
- Access instance members

`this` cannot be used in a `static` context.

### `super`
`super` refers to the **superclass part** of the current object. It is not a separate object reference.

Common uses:
- Call a superclass constructor: `super(...)`
- Access an overridden superclass method: `super.method()`
- Access a hidden superclass field: `super.field`

`super` cannot be used in a `static` context. In a constructor, `super(...)` must be the first statement if used.

```java
class Animal {
    void sound() { System.out.println("Some sound"); }
}

class Dog extends Animal {
    @Override
    void sound() {
        super.sound(); // call Animal's version
        System.out.println("Bark");
    }
}
```

---

## 4. Inheritance

**Inheritance** lets one class acquire the accessible members of another class.

```java
class Animal {
    void eat() { System.out.println("Eating"); }
}

class Dog extends Animal {
    void bark() { System.out.println("Barking"); }
}
```

- Java supports **single inheritance of classes**: a class can extend only one direct superclass.
- Java supports **multiple inheritance of type** through interfaces.
- Every class implicitly extends `Object` (except `Object` itself).
- Constructors are **not inherited**.
- `private` members are not inherited.
- `protected` and `public` members are inherited.
- Package-private members are inherited only if the subclass is in the same package.

### Method overriding
A subclass can provide a new implementation of an inherited method with the same signature.

Rules:
- Same name and parameter list
- Return type can be covariant (a subtype)
- Cannot reduce visibility
- Cannot throw broader checked exceptions
- Use `@Override` for compile-time checking

```java
class Animal {
    void sound() { System.out.println("Some sound"); }
}

class Cat extends Animal {
    @Override
    void sound() { System.out.println("Meow"); }
}
```

### Field hiding vs method overriding
- **Methods** are overridden (runtime polymorphism).
- **Fields** are hidden (compile-time resolution).
- **Static methods** are hidden, not overridden.

### `final` and inheritance
- A `final` class cannot be extended.
- A `final` method cannot be overridden.

---

## 5. Polymorphism

**Polymorphism** means “many forms.” In Java, it comes in two main forms:

### Compile-time polymorphism (static)
Achieved through **method overloading**.

```java
void print(int x) { }
void print(String s) { }
```

The compiler chooses the method based on the reference type and arguments.

### Runtime polymorphism (dynamic)
Achieved through **method overriding** and **dynamic method dispatch**.

```java
Animal a = new Dog();
a.sound(); // Dog's sound() is called at runtime
```

The JVM looks at the **actual object type**, not the reference type, to decide which overridden instance method to call.

Important:
- Instance methods are polymorphic.
- `static` methods are not polymorphic — they are hidden.
- Fields are not polymorphic — they are resolved by reference type.
- `private` methods are not overridden.
- `final` methods cannot be overridden.

Polymorphism allows you to write flexible code against a supertype while working with many subtypes.

---

## 6. Abstraction

**Abstraction** hides implementation details and exposes only essential behavior. It focuses on **what** an object does, not **how** it does it.

Java provides two main abstraction tools:

### Abstract class
- Declared with `abstract`
- Can have abstract methods (no body) and concrete methods
- Cannot be instantiated
- Can have constructors, fields, and methods
- A subclass must implement all abstract methods unless it is also abstract

```java
abstract class Shape {
    abstract double area();
}
```

### Interface
- A contract of behavior
- A class can implement multiple interfaces
- Methods are `public abstract` by default
- Can have `default`, `static`, and `private` methods (Java 8+ / 9+)
- Fields are `public static final` by default

```java
interface Flyable {
    void fly();
}
```

Abstraction reduces complexity and decouples code from concrete implementations.

---

## 7. Encapsulation

**Encapsulation** means bundling data and the methods that operate on that data inside a class, while restricting direct access to internal details.

Typical Java approach:
- Make fields `private`
- Provide `public` getters/setters or, better, meaningful behavior methods

```java
class BankAccount {
    private double balance;

    public void deposit(double amount) {
        if (amount > 0) balance += amount;
    }

    public double getBalance() {
        return balance;
    }
}
```

Benefits:
- Protects invariants
- Hides implementation details
- Allows internal changes without breaking callers
- Improves security and maintainability
- Reduces coupling

Encapsulation is enforced mainly through **access modifiers**.

---

## 8. Access Modifiers

Java has four access levels:

| Modifier | Same class | Same package | Subclass (same package) | Subclass (different package) | Anywhere |
|---|---|---|---|---|---|
| `private` | Yes | No | No | No | No |
| package-private (default) | Yes | Yes | Yes | No | No |
| `protected` | Yes | Yes | Yes | Yes* | No |
| `public` | Yes | Yes | Yes | Yes | Yes |

\* `protected` in a different package can be accessed only through inheritance, and only on `this` or instances of the subclass — not on an arbitrary superclass reference.

### Details
- **`private`** — only within the same class (and nested classes of the same top-level class).
- **package-private** — no keyword; accessible only within the same package.
- **`protected`** — same package plus subclasses in other packages, with restrictions.
- **`public`** — accessible from anywhere.

Top-level classes can only be `public` or package-private. Nested classes can use all four.

Access modifiers apply to classes, fields, methods, and constructors.

---

## 9. `static` vs Instance Members

### Instance members
- Belong to an **object**
- Each object has its own copy of instance fields
- Instance methods can access `this`, instance fields, and static members
- Accessed through an object reference

```java
class Counter {
    int count; // instance field
    void increment() { count++; }
}
```

### Static members
- Belong to the **class**, not to any object
- One copy per class (per classloader)
- Shared by all instances
- Accessed via class name: `ClassName.member`
- Static methods cannot use `this` or `super`
- Static methods cannot directly access instance members
- Static methods can be overloaded but not overridden — they are hidden
- Static blocks run once when the class is initialized

```java
class MathUtil {
    static final double PI = 3.14159;
    static int add(int a, int b) { return a + b; }
}
```

Use `static` for:
- Constants
- Utility methods
- Counters shared across instances
- Factory methods
- Static nested classes

Instance members are stored per object on the heap. Static members are associated with the class in metaspace/method area.

---

## 10. `final` on Variables, Methods, and Classes

### `final` variable
- Can be assigned **only once**
- For fields: must be initialized in declaration, initializer block, or constructor
- For `static final` fields: must be initialized in declaration or static initializer
- For local variables: must be assigned before use
- For parameters: cannot be reassigned inside the method

```java
final int MAX = 100;
final Person p = new Person();
// p = new Person(); // error
p.name = "Bob"; // allowed — object state can change
```

A `final` reference does **not** make the object immutable. It only prevents reassigning the reference.

### `final` method
- Cannot be overridden by a subclass
- Can still be inherited and called
- Used for security, consistency, and design constraints

```java
class Base {
    final void show() { }
}
```

### `final` class
- Cannot be extended
- Often used for immutability or security
- Examples: `String`, `Integer`, `System`

```java
final class Constants { }
// class Sub extends Constants { } // error
```

### Other notes
- `final` and `abstract` cannot be combined.
- `final` can be applied to local variables and parameters.
- `finalize()` is unrelated to the `final` keyword.

---

## Summary Mapping to OOP Pillars

| Pillar | Java Mechanism |
|---|---|
| Encapsulation | Classes, private fields, access modifiers, getters/setters |
| Abstraction | Abstract classes, interfaces |
| Inheritance | `extends`, `implements`, `super` |
| Polymorphism | Overloading, overriding, dynamic dispatch |

These fundamentals work together: classes define objects, constructors initialize them, encapsulation protects state, inheritance reuses code, abstraction hides detail, polymorphism enables flexibility, and `static`/`final`/access modifiers control scope, sharing, and immutability.


[[Java]]