

**Date**: 2025-08-24  
**Concept**: Object-Oriented Programming (OOP) in Java  
**Course**: Java Programming Fundamentals  
**Tags**: [[Java]]

---
## Terms

- **Interface**: A blueprint for classes that defines methods without implementing them. Classes implementing an interface must provide the method bodies.
    
- **Functional Interface**: An interface with exactly one abstract method, often used with lambda expressions in Java (e.g., Runnable, Comparator).
    
- **Abstraction (Methods & Classes)**: Hiding complex details by defining methods or classes (using abstract keyword) that specify _what_ to do, not _how_. Abstract classes can have both implemented and unimplemented methods.
    
- **Inheritance & Implementations**: Inheritance allows a class to inherit fields and methods from another class using extends. Implementation refers to a class providing concrete logic for an interface’s methods using implements.
    

---

## Notes

- **Interfaces**:
    
    - Use the interface keyword to define.
        
    - All methods are implicitly public and abstract (no body unless default or static).
        
    - Example: interface Animal { void makeSound(); }
        
    - Classes use implements to adopt an interface.
        
    - Supports multiple interfaces: class Dog implements Animal, Pet { ... }.
        
- **Functional Interfaces**:
    
    - Marked with @FunctionalInterface to ensure one abstract method.
        
    - Enables lambda expressions: (x) -> x * 2 for a functional interface like Function<Integer, Integer>.
        
    - Common in Java streams and event handling.
        
- **Abstraction**:
    
    - Abstract classes can’t be instantiated but can have constructors for subclasses.
        
    - Abstract methods must be implemented by non-abstract subclasses.
        
    - Example: abstract class Shape { abstract void draw(); }
        
- **Inheritance & Implementations**:
    
    - Use extends for class-to-class inheritance (single inheritance in Java).
        
    - Use implements for class-to-interface relationships.
        
    - Override inherited methods with @Override for clarity.
        
    - Polymorphism allows subclasses to be treated as their parent type.
        

**Key Rules**:

- Interfaces can have default methods (with implementation) and static methods since Java 8.
    
- Abstract classes can have fields, constructors, and concrete methods; interfaces cannot (except static or final fields).
    
- A class can implement multiple interfaces but extend only one class.
    
- Use @Override when overriding methods to avoid errors.
    
- Avoid deep inheritance hierarchies to keep code maintainable.
    

**Things to Know**:

- **Polymorphism**: Objects of a subclass can be used where a parent class is expected (e.g., Animal dog = new Dog();).
    
- **Encapsulation**: Combine with abstraction to hide data using private fields and public getters/setters.
    
- **When to Use**:
    
    - Use interfaces for flexible, contract-based design.
        
    - Use abstract classes when you need shared code or state.
        
    - Use functional interfaces for concise lambda-based coding.
        
- **Common Pitfalls**:
    
    - Forgetting to implement all interface methods causes compilation errors.
        
    - Overusing inheritance can make code rigid; prefer composition where possible.
        

---

## Summary

This note covers core Java OOP concepts: interfaces define method contracts, functional interfaces enable lambda expressions, abstraction hides complexity, and inheritance allows code reuse. Use interfaces for flexibility, abstract classes for shared logic, and ensure proper method overrides. Understanding these concepts helps build modular, maintainable Java programs.

---

## Idea

Create a small Java project to practice these concepts:

- Define an Animal interface with a makeSound() method.
    
- Create an abstract class Mammal with a move() method.
    
- Implement a Dog class that extends Mammal and implements Animal.
    
- Use a functional interface with a lambda to sort animals by name.

## Example in Code
// Interface

interface Animal {
    void makeSound();
}

// Functional Interface

@FunctionalInterface
interface Nameable {
    String getName();
}


// Abstract Class
abstract class Mammal {
    abstract void move();
    void breathe() {
        System.out.println("Breathing as a mammal...");
    }
}


// Concrete Class
class Dog extends Mammal implements Animal, Nameable {
    private String name;

    Dog(String name) {
        this.name = name;
    }

    @Override
    public void makeSound() {
        System.out.println(name + " says: Woof!");
    }

    @Override
    void move() {
        System.out.println(name + " runs on four legs.");
    }

    @Override
    public String getName() {
        return name;
    }
}

// Main Class to Test
public class Main {
    public static void main(String[] args) {
        Dog dog = new Dog("Buddy");
        dog.makeSound(); // Output: Buddy says: Woof!
        dog.move();      // Output: Buddy runs on four legs.
        dog.breathe();   // Output: Breathing as a mammal...

        // Using Functional Interface with Lambda
        Nameable nameable = () -> "Buddy the Dog";
        System.out.println("Name: " + nameable.getName());
    }
}