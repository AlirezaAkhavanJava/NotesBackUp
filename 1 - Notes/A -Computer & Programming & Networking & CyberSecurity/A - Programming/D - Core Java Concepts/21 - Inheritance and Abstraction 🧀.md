Date : 2025-09-04



## 1. Introduction

- **Inheritance:** Mechanism where a class can inherit properties (fields) and behaviors (methods) from another class.
    
- **Abstraction:** Hiding implementation details while exposing only functionality.
    

**Tip:** Think of inheritance as a “child getting traits from a parent” and abstraction as a “black box showing only what’s necessary”.

---

## 2. Inheritance

### 2.1 Basics

- Use `extends` keyword for class inheritance.
    
- Single inheritance for classes; multiple inheritance via interfaces.
    

```java
class Vehicle {
    void start() { System.out.println("Vehicle starting"); }
}

class Car extends Vehicle {
    void honk() { System.out.println("Car honking"); }
}

Car c = new Car();
c.start(); // inherited method
c.honk();  // own method
```

**Tip:** Inheritance promotes **code reuse** and **hierarchical design**.

### 2.2 Types of Inheritance

1. **Single Inheritance:** Child inherits from one parent.
    
2. **Multilevel Inheritance:** Chain of inheritance.
    
3. **Hierarchical Inheritance:** Multiple children inherit from same parent.
    

```java
class GrandParent {}
class Parent extends GrandParent {}
class Child extends Parent {}
```

**Tip:** Avoid deep hierarchies; they make code hard to maintain.

### 2.3 `super` Keyword

- Access parent class members.
    
- Call parent constructor.
    

```java
class Vehicle {
    String type = "Generic";
    Vehicle(String type) { this.type = type; }
}
class Car extends Vehicle {
    Car() { super("Car"); }
    void printType() { System.out.println(super.type); }
}
```

**Tip:** Use `super` to avoid field/method ambiguity.

### 2.4 Method Overriding

- Redefine parent method in child.
    
- Use `@Override` annotation.
    

```java
class Vehicle { void start() { System.out.println("Vehicle"); } }
class Car extends Vehicle { @Override void start() { System.out.println("Car"); } }
```

**Tip:** Overriding enables **polymorphism**.

### 2.5 Polymorphism

- **Compile-time (Overloading)** vs **Runtime (Overriding)**
    
- Parent reference can point to child object:
    

```java
Vehicle v = new Car();
v.start(); // calls Car's start()
```

**Tip:** This allows dynamic behavior based on object type.

---

## 3. Abstraction

### 3.1 Abstract Classes

- Use `abstract` keyword.
    
- Cannot be instantiated.
    
- Can have abstract methods (without body) and concrete methods.
    

```java
abstract class Vehicle {
    abstract void start();
    void fuel() { System.out.println("Filling fuel"); }
}
class Car extends Vehicle {
    void start() { System.out.println("Car starting"); }
}
```

**Tip:** Use abstract classes for shared behavior and partially implemented methods.

### 3.2 Interfaces

- Pure abstraction, multiple inheritance.
    
- Can have **default and static methods** (Java 8+).
    

```java
interface Drivable {
    void drive();
    default void checkFuel() { System.out.println("Fuel OK"); }
    static void info() { System.out.println("Vehicles Info"); }
}
class Car implements Drivable {
    public void drive() { System.out.println("Car driving"); }
}
```

**Tip:** Use interfaces for **contract-based design** and multiple inheritance.

### 3.3 Modern Features (Java 21–25)

- **Sealed Classes:** Restrict which classes can extend a class or implement an interface.
    

```java
sealed class Vehicle permits Car, Bike {}
final class Car extends Vehicle {}
final class Bike extends Vehicle {}
```

- **Records:** Can implement interfaces, enabling abstraction for immutable data.
    
- **Pattern Matching & Switch Expressions:** Work seamlessly with abstract hierarchies.
    

**Tip:** Sealed classes help enforce **strict hierarchy** and maintainable code.

---

## 4. Best Practices

1. Prefer **composition over inheritance** to reduce tight coupling.
    
2. Keep hierarchies **shallow**.
    
3. Use **abstract classes** for shared code, **interfaces** for multiple inheritance and contracts.
    
4. Use `@Override` for clarity.
    
5. Use **sealed classes** for controlled inheritance in modern Java.
    
6. Use inheritance **only when there is an IS-A relationship**.
    

---

## 5. Real-World Usage

- Vehicle and Car, Employee and Manager hierarchies.
    
- GUI frameworks: Component → Button → ImageButton.
    
- Enterprise: BaseService abstract class with CRUD methods.
    
- Design patterns: Template Method, Strategy (inheritance + abstraction).
    

**Tip:** Apply inheritance and abstraction judiciously for maintainable and extensible systems.

---

## 6. Summary

- **Inheritance:** Enables **code reuse and polymorphism**.
    
- **Abstract Classes:** Partial implementation, cannot instantiate.
    
- **Interfaces:** Pure abstraction, multiple inheritance.
    
- **Modern Java:** Sealed classes, records, default/static methods, pattern matching enhance abstraction and control.
    

This guide ensures mastery of **Inheritance and Abstraction in Java from beginner to senior-level**, including updates up to Java 25.




##### *Tags : [[Java]]