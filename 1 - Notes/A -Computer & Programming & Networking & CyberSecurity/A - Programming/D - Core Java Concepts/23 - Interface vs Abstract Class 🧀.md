Date : 2025-09-04


# Java Interface vs Abstract Class – Complete Guide (Up to Java 25)

This guide explains **interfaces and abstract classes in Java**, their differences, usage, modern features, best practices, design patterns, and detailed examples from beginner to senior level.

---
> Abstraction is hiding all the complicated crap behind a simple interface so you don’t deal with the mess.  
You only show what matters, and you bury the ugly implementation under the hood.  
The user gets the clean buttons; all the chaos stays behind the curtain.  
If someone wants to use your class, they don’t need to know how the engine works—they just call the method and shut up.


> Inheritance lets you build a new class on top of an existing class, so you don’t rewrite shit you already wrote.  
You take the parent’s abilities and add your own extra behavior.  
It’s basically saying: “I’m like my parent, but better—or at least different.”  
Shared logic stays in one place, so you don’t copy-paste like a clown.


> Polymorphism lets you write one command and let different objects decide how the hell they want to execute it.  
Same method name, different behavior depending on the object.  
You call a method like `move()` and each subclass does its own thing—walk, fly, swim, whatever.  
It’s the ultimate “I don’t care who you are, just do your job your way” for objects.



---
---
Data **abstraction** is the process of hiding certain details and showing only essential information to the user.  
Abstraction can be achieved with either **abstract classes** or interfaces

- **Abstract class:** is a restricted class that cannot be used to create objects (to access it, it must be inherited from another class).

An `interface` is a completely "**abstract class**" that is used to group related methods with empty bodies.

#### Notes on Interfaces:

- Like **abstract classes**, interfaces **cannot** be used to create objects (in the example above, it is not possible to create an "Animal" object in the MyMainClass)
- Interface methods do not have a body - the body is provided by the "implement" class
- On implementation of an interface, you must override all of its methods
- Interface methods are by default `abstract` and `public`
- Interface attributes are by default `public`, `static` and `final`
- An interface cannot contain a constructor (as it cannot be used to create objects)

#### Why And When To Use Interfaces?

1) To achieve security - hide certain details and only show the important details of an object (interface).

2) Java does not support "multiple inheritance" (a class can only inherit from one superclass). However, it can be achieved with interfaces, because the class can **implement** multiple interfaces. **Note:** To implement multiple interfaces, separate them with a comma (see example below).

| Feature                         | Abstract Class                                       | Interface                                                |
| ------------------------------- | ---------------------------------------------------- | -------------------------------------------------------- |
| Purpose                         | "Is-a" relationship (inheritance)                    | "Can-do" relationship (contract)                         |
| Multiple inheritance            | Not allowed (single inheritance only)                | Allowed (a class can implement many interfaces)          |
| Can have instance fields        | Yes                                                  | No (only static final constants in Java <8)              |
| Can have constructors           | Yes                                                  | No                                                       |
| Can have any access modifier    | Yes (private, protected, public, etc.)               | Methods are public by default (until Java 8)             |
| Can have implemented methods    | Yes (concrete methods allowed)                       | Yes (default methods since Java 8, C# 8)                 |
| Can have state (mutable fields) | Yes                                                  | No (interfaces are stateless by design)                  |
| Designed for evolution          | Risky (adding new abstract method breaks subclasses) | Safe (adding new method with default impl doesn't break) |
| Best used for                   | Sharing code among closely related classes           | Defining capabilities that unrelated classes can have    |

### Real-world analogy

- **Abstract class** → Like a "partially built car". It has some working parts (fields, concrete methods), an engine, maybe wheels, but you can't drive it yet. All sports cars might extend AbstractSportsCar.
- **Interface** → Like a "driver's license" or "USB port". A Tesla, a bicycle, or a human can all implement Drivable or USBDevice. They have nothing in common otherwise, but they promise to support certain operations.


### Why not just use one or the other?

1. **Java/C# originally couldn't do multiple inheritance of classes** → Interfaces were the only way to get polymorphic behavior from unrelated types.
2. **Abstract classes are for code reuse + shared state** → Perfect when classes are closely related.
3. **Interfaces are for defining APIs/contracts** → Perfect when you want loose coupling and flexibility.



---

## 1. Introduction

- **Interface:** A contract that defines methods which a class must implement.
    
- **Abstract Class:** A class that may have abstract methods (without body) and concrete methods.
    

**Tip:** Interfaces define **what** a class can do, abstract classes define **what it is and what it can do**.

---

## 2. Syntax

### Abstract Class

```java
abstract class Vehicle {
    abstract void start();
    void fuel() { 
	    System.out.println("Fueling vehicle"); 
    }
}
class Car extends Vehicle {
    void start() { 
	    System.out.println("Car starting"); 
	}
}
```

### Interface

```java
interface Drivable {
    void drive();
    default void checkFuel() { 
	    System.out.println("Fuel OK"); 
	}
    static void info() { 
	    System.out.println("Vehicles Info"); 
    }
}
class Car implements Drivable {
    public void drive() { 
	    System.out.println("Car driving"); 
    }
}
```

**Tip:** Default methods (Java 8+) allow interfaces to have behavior.

---

## 3. Key Differences

|Aspect|Abstract Class|Interface|
|---|---|---|
|Multiple Inheritance|Not allowed|Allowed (implements multiple)|
|Constructor|Yes|No|
|Fields|Can have instance variables|Only static/final fields|
|Methods|Abstract + Concrete|Abstract + Default + Static + Private (Java 9+)|
|Access Modifiers|Any|Public (methods), Public static final (fields)|
|Use Case|Shared code + some abstraction|Contract for classes|

**Tip:** Use abstract class when **common code exists**, interface for **behavior specification**.

---

## 4. Modern Java Features (Java 8–25)

- **Default Methods:** Interfaces can have methods with body.
    
- **Static Methods:** Can define utility methods.
    
- **Private Methods in Interfaces (Java 9+):** Reusable code inside interface.
    
- **Sealed Interfaces (Java 17+):** Restrict implementations.
    
- **Records (Java 16+):** Can implement interfaces but not extend abstract classes.
    

```java
sealed interface Vehicle permits Car, Bike {}
final class Car implements Vehicle {}
non-sealed class Bike implements Vehicle {}
```

**Tip:** Use sealed interfaces for controlled polymorphism.

---

## 5. Usage Guidelines

1. **Abstract Class:**
    
    - Use when classes share **common code and properties**.
        
    - Can maintain state with fields.
        
    - Example: BaseService in enterprise apps.
        
2. **Interface:**
    
    - Use to define **capabilities** or contracts.
        
    - Example: Drivable, Serializable, Comparable.
        

**Tip:** Many frameworks (Spring, Hibernate) rely on **interfaces for DI and loose coupling**.

---

## 6. Best Practices

- Prefer interfaces for **flexible and decoupled design**.
    
- Use abstract classes for **shared logic**.
    
- Combine: Abstract class can implement an interface.
    
- Use **default methods** wisely to avoid breaking implementations.
    
- Use **sealed interfaces** or **abstract classes** for controlled hierarchies.
    
- Avoid multiple abstract classes; prefer interfaces for multiple inheritance.
    

---

## 7. Design Patterns

- **Template Method:** Abstract class provides skeleton, subclasses override.
    
- **Strategy/Observer:** Interfaces define behavior.
    
- **Factory:** Abstract classes or interfaces as product types.
    

**Tip:** Choosing interface vs abstract class affects flexibility and extensibility.

---

## 8. Real-World Examples

- **Abstract Class:** BaseController with common methods in Spring Boot.
    
- **Interface:** Repository interface for DAO pattern.
    
- **Record + Interface:** DTO implementing an interface for mapping.
    
- **Sealed Interface:** Controlled set of events in event-driven systems.
    

---

## 9. Summary

- Abstract classes: partial implementation, may have state, one inheritance.
    
- Interfaces: contract, multiple inheritance, default/static/private methods.
    
- Modern Java features: default methods, private methods, sealed interfaces, records.
    
- Use best practices to design maintainable, flexible, and robust code.
    
|Use Abstract Class when...|Use Interface when...|
|---|---|
|You want to share code and state|You want multiple inheritance of type|
|Classes are clearly related|Unrelated classes need same capability|
|You need constructors or fields|You want a pure contract (no implementation)|
|You need protected/private members|You want maximum flexibility and decoupling|
This guide ensures mastery of **Interface vs Abstract Class in Java from beginner to senior-level**, including updates up to Java 25.



##### *Tags : [[Java]]