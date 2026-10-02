
## 1. Core OOP Principles

### 1.1 Encapsulation

**Introduction:** Encapsulation is about **hiding internal data** of objects and exposing only necessary behaviors. This protects object integrity and prevents unwanted interference.

**Teaching Example:**

```java
class Person {
    private String name; // hidden field

    // public methods to access and modify
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}
```

- Fields are private, and controlled via getter/setter methods.
    

---

### 1.2 Inheritance

**Introduction:** Inheritance allows a **class to reuse code from another class**, establishing a hierarchy and promoting code reusability.

**Teaching Example:**

```java
class Animal {
    void eat() { System.out.println("Eating"); }
}
class Dog extends Animal {
    void bark() { System.out.println("Barking"); }
}
```

- `Dog` inherits `eat()` method from `Animal`.
    

---

### 1.3 Polymorphism

> Polymorphism is **a Greek word that means "many-shaped"** and it has two distinct aspects: At run time, objects of a derived class can be treated as objects of a base class in places such as method parameters and collections or arrays.

**Introduction:** Polymorphism allows the **same interface to represent different underlying forms**. There are two types:

- **Compile-time (method overloading)**
    
- **Runtime (method overriding)**
    

**Teaching Example:**

```java
// Method Overloading (compile-time)
class Calculator {
    int add(int a, int b) { return a+b; }
    double add(double a, double b) { return a+b; }
}

// Method Overriding (runtime)
class Cat extends Animal {
    @Override void sound() { System.out.println("Meow"); }
}
```

- Overloading: same method name, different parameters.
    
- Overriding: subclass modifies behavior of superclass method.
    

---

### 1.4 Abstraction

**Introduction:** Abstraction **hides implementation details** and shows only the essential functionality to the user.

**Teaching Example:**

```java
abstract class Shape {
    abstract void draw(); // no implementation
}
class Circle extends Shape {
    void draw() { System.out.println("Drawing Circle"); }
}

interface Flyable {
    void fly();
}
class Bird implements Flyable {
    public void fly() { System.out.println("Flying"); }
}
```

- Abstract classes provide a blueprint.
    
- Interfaces define contracts without implementation.
    

---

## 2. Modern Java OOP Features (Java 16–25)

### 2.1 Records (Java 16+)

**Introduction:** Records are **immutable data classes** that automatically generate common methods.

```java
record Point(int x, int y) {}
Point p = new Point(1,2);
System.out.println(p.x()); // 1
```

- No need to write `equals()`, `hashCode()`, `toString()` manually.
    

### 2.2 Sealed Classes (Java 17+)

**Introduction:** Sealed classes **restrict which classes can extend them**, improving safety and control over hierarchies.

```java
sealed class Vehicle permits Car, Bike {}
final class Car extends Vehicle {}
final class Bike extends Vehicle {}
```

- Only `Car` and `Bike` can extend `Vehicle`.
    

### 2.3 Pattern Matching (Java 21+)

**Introduction:** Simplifies **type checking and casting**.

```java
Object obj = new Dog();
if (obj instanceof Dog d) {
    d.bark();
}
```

- Automatic casting with `instanceof`.
    

### 2.4 Interfaces Enhancements

**Introduction:** Modern interfaces can include **default, private, and static methods**.

```java
interface Logger {
    default void log(String msg) { System.out.println(msg); }
    static void info(String msg) { System.out.println("INFO: " + msg); }
    private void debug(String msg) { System.out.println("DEBUG: " + msg); }
}
```

- Enables reusable behaviors directly in interfaces.
    

### 2.5 Virtual Threads (Java 21+)

**Introduction:** Lightweight threads allow concurrent execution without heavy system threads.

```java
Runnable task = () -> System.out.println(Thread.currentThread());
Thread.startVirtualThread(task);
```

### 2.6 Enhanced Switch with Records (Java 25 Preview)

**Introduction:** Switch expressions can now destructure records for **type-safe handling of objects**.

```java
record Point(int x, int y) {}
Object shape = new Point(3,4);
switch (shape) {
    case Point(int x, int y) -> System.out.println(x + "," + y);
    default -> System.out.println("Unknown shape");
}
```

---

## 3. Summary

- **Encapsulation** → Hides internal state, uses getters/setters.
    
- **Inheritance** → Enables code reuse, hierarchical relationships.
    
- **Polymorphism** → Same interface, multiple behaviors (overloading/overriding).
    
- **Abstraction** → Hides implementation, focuses on essential behavior.
    
- **Modern Java 21–25 OOP features**: Records, sealed classes, pattern matching, virtual threads, enhanced interfaces, and switch destructuring.
    

These features make Java OOP **more expressive, safer, and suitable for modern applications**.



##### *Tags : [[Java]]