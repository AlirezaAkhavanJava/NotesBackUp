Date : 2025-09-04



## 1. Introduction

- **Java class:** Blueprint for creating objects.
    
- **Types of classes:** Categorized based on behavior, usage, and features.
    

**Tip:** Think of different class types as specialized tools in a toolbox.

---

## 2. Top-Level Classes

- Regular classes declared directly inside a package.
    
- Can be public or package-private.
    

```java
package vehicles;
public class Car {}
class Bike {} // package-private
```

**Tip:** Use package-private for internal implementation hiding.

---

## 3. Nested Classes

### 3.1 Static Nested Class

- Declared `static` inside another class.
    
- Does **not** have reference to outer class instance.
    

```java
class Outer {
    static class Nested {
        void greet() { System.out.println("Hello from Nested"); }
    }
}
Outer.Nested n = new Outer.Nested();
n.greet();
```

**Tip:** Use for grouping classes logically and reducing namespace pollution.

### 3.2 Non-Static (Inner) Class

- Has access to outer class instance and members.
    

```java
class Outer {
    int x = 10;
    class Inner { void print() { System.out.println(x); } }
}
Outer o = new Outer();
Outer.Inner i = o.new Inner();
i.print(); // 10
```

**Tip:** Use inner classes when you need **tight coupling with outer class**.

### 3.3 Local Class

- Defined **inside a method**.
    
- Cannot use `static` modifier.
    

```java
void myMethod() {
    class Local { void greet() { System.out.println("Hello"); } }
    Local l = new Local();
    l.greet();
}
```

**Tip:** Use for short-lived, method-specific logic.

### 3.4 Anonymous Class

- No name, defined at the point of instantiation.
    
- Often used to implement interfaces or extend classes quickly.
    

```java
Runnable r = new Runnable() {
    public void run() { System.out.println("Running"); }
};
new Thread(r).start();
```

- **Java 8+:** Can often replace with lambda expressions.
    

```java
Runnable r = () -> System.out.println("Running");
```

**Tip:** Use for **event listeners, callbacks, and short tasks**.

---

## 4. Abstract Class

- Declared with `abstract` keyword.
    
- Cannot instantiate, can have abstract and concrete methods.
    
- Used for partially implemented functionality.
    

```java
abstract class Vehicle { abstract void start(); }
class Car extends Vehicle { void start() { System.out.println("Car starts"); } }
```

**Tip:** Use abstract classes when you want **common code and some unimplemented methods**.

---

## 5. Final Class

- Declared with `final` keyword.
    
- Cannot be subclassed.
    
- Often used for **immutable classes**.
    

```java
final class Constants {}
```

**Tip:** Use for **security and immutability**.

---

## 6. Sealed Class (Java 17+)

- Restricts which classes can extend it.
    
- Declared with `sealed` keyword, allows `permits` clause.
    

```java
sealed class Vehicle permits Car, Bike {}
final class Car extends Vehicle {}
non-sealed class Bike extends Vehicle {}
```

**Tip:** Use sealed classes to enforce **controlled hierarchy**.

---

## 7. Record Class (Java 16+)

- Immutable data carrier class.
    
- Automatically generates constructors, getters, `equals()`, `hashCode()`, `toString()`.
    

```java
record Point(int x, int y) {}
Point p = new Point(1,2);
```

**Tip:** Use records for **DTOs, keys, and simple immutable objects**.

---

## 8. Enum Class

- Special class representing **constants**.
    
- Can have fields, methods, implement interfaces.
    

```java
enum Day { MONDAY, TUESDAY }
```

**Tip:** Use enums for **type-safe constants and status codes**.

---

## 9. Interface (Abstract Type)

- Defines **contract** with abstract methods.
    
- Can have default and static methods (Java 8+).
    
- Multiple inheritance is allowed.
    

```java
interface Drivable { void drive(); }
class Car implements Drivable { public void drive() {} }
```

**Tip:** Use interfaces for **polymorphism and loose coupling**.

---

## 10. Best Practices

1. Use **top-level classes** for main entities.
    
2. Use **nested classes** for logical grouping.
    
3. Use **abstract classes** for common behavior.
    
4. Use **interfaces** for contracts.
    
5. Prefer **records and enums** for immutable, simple data.
    
6. Use **sealed classes** for controlled inheritance.
    
7. Avoid deep inner class nesting to maintain readability.
    

---

## 11. Real-World Usage

- GUI frameworks: Buttons, Panels as inner/nested classes.
    
- Callbacks: Anonymous classes and lambdas.
    
- Configuration objects: Records.
    
- Status enums for business workflows.
    
- Base service classes: Abstract classes.
    

**Tip:** Choosing the right class type improves **readability, maintainability, and performance**.

---

## 12. Summary

- Java offers **top-level, nested, inner, local, anonymous, abstract, final, sealed, record, enum, and interface classes**.
    
- Modern Java features (records, sealed classes, enums with methods) enhance readability and maintainability.
    
- Understand scope, coupling, and immutability when choosing class type.
    

This guide ensures mastery of **Java class types from beginner to senior-level**, including updates up to Java 25.



##### *Tags : [[Java]]