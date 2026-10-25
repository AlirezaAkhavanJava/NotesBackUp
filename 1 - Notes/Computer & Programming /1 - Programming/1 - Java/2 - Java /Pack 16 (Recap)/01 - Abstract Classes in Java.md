

## 1. What is an Abstract Class?

An **abstract class** is a class declared with the `abstract` keyword that cannot be [^1]instantiated directly. It is designed to act as a superclass for other classes, providing shared fields, constructors, and implemented methods while optionally leaving some methods unimplemented for its subclasses.

Think of an abstract class as a **partially implemented class that other classes can extend and complete**.

```java
public abstract class Animal {

    public void eat() {
        System.out.println("Eating...");
    }

    public abstract void makeSound();
}
```

Here:

- `eat()` is a concrete method with an implementation.
    
- `makeSound()` is an abstract method without an implementation.
    
- `Animal` cannot be instantiated directly.
    
- Subclasses can inherit `eat()` and provide their own implementation of `makeSound()`.
    

## 2. The problem it solves

Imagine you have three classes: `Dog`, `Cat`, and `Cow`.

They all share certain behaviors, but each has its own unique behavior.

Instead of repeating the same code in every class, we create an abstract superclass that provides shared functionality and defines what subclasses must implement.

```java
public abstract class Animal {

    private String name;

    public Animal(String name) {
        this.name = name;
    }

    public void sleep() {
        System.out.println(name + " is sleeping");
    }

    public abstract void makeSound();
}
```

Now create a concrete subclass:

```java
public class Dog extends Animal {

    public Dog(String name) {
        super(name);
    }

    @Override
    public void makeSound() {
        System.out.println("Woof!");
    }
}
```

Usage:

```java
Animal animal = new Dog("Max");

animal.sleep();      // Max is sleeping
animal.makeSound();  // Woof!
```

Notice that we can use an abstract class as a reference type. This is **polymorphism**.

We cannot create an `Animal` directly, but we can reference a `Dog` through `Animal`.

---

## 3. Rules of Abstract Classes

|Rule|Explanation|
|---|---|
|1. Cannot be instantiated|You cannot create an object directly using `new AbstractClass()`.|
|2. Can have constructors|Constructors initialize the inherited state of subclasses.|
|3. Can have instance fields|They can maintain state shared through inheritance.|
|4. Can have concrete methods|Methods with complete implementations are allowed.|
|5. Can have abstract methods|Methods without implementations are allowed.|
|6. Abstract methods are optional|An abstract class does not need to contain any abstract methods.|
|7. Can implement interfaces|It may implement zero, some, or all required methods.|
|8. Can extend another class|It can extend a concrete or abstract superclass.|
|9. Supports polymorphism|Abstract superclass references can point to concrete subclass objects.|
|10. Cannot be `final`|A final class cannot be extended, which conflicts with abstraction.|
|11. Can contain static members|Static methods, fields, and initialization blocks are allowed.|
|12. Can contain final methods|A concrete method marked `final` cannot be overridden.|

## 4. Rules of Abstract Methods

An abstract method is declared using the `abstract` keyword and has no body.

```
public abstract void makeSound();
```

Important rules:

1. An abstract method must be declared inside an abstract class or declared as an instance method without a body inside an interface.
    
2. An abstract method cannot have a method body.
    
3. An abstract method cannot be `private`.
    
4. An abstract method cannot be `final`.
    
5. An abstract method cannot be `static`.
    
6. A concrete subclass must implement all inherited abstract methods that do not already have implementations.
    

Example:

```java
public abstract class Animal {

    public abstract void eat();

    public abstract void sleep();
}
```

This is invalid:

```java
public class Dog extends Animal {

    @Override
    public void eat() {
        System.out.println("Eating");
    }

    // Compile error: sleep() is not implemented.
}
```

But this is valid:

```java
public abstract class Mammal extends Animal {

    @Override
    public void eat() {
        System.out.println("Eating");
    }

    // sleep() remains abstract
}
```

Because `Mammal` is also abstract, it can leave `sleep()` for a future subclass to implement.

## 5. An Abstract Class Does Not Need Abstract Methods

This is completely valid:

```java
public abstract class DatabaseConnection {

    public void connect() {
        System.out.println("Connecting...");
    }
}
```

Even though it has no abstract methods, it cannot be instantiated directly.

Why would we do this?

Because we may want to provide a reusable superclass while preventing developers from creating instances of the base class itself.

## 6. Abstract Class and Interface Together

As we discussed earlier, an abstract class can implement an interface without providing every method.

```java
public interface Vehicle {
    void start();
    void stop();
}
```

```java
public abstract class AbstractVehicle implements Vehicle {

    @Override
    public void stop() {
        System.out.println("Stopped");
    }

    // start() remains unimplemented.
}
```

```java
public class Car extends AbstractVehicle {

    @Override
    public void start() {
        System.out.println("Engine started");
    }
}
```

Our design now looks like this:

```
        Vehicle
       (Interface)
           |
       implements
           |
    AbstractVehicle
     (Abstract Class)
           |
         extends
           |
          Car
    (Concrete Class)
```

The interface defines the contract, the abstract class supplies reusable implementation, and the concrete class completes the remaining behavior.

## 7. Abstract Class vs Concrete Class

|Feature|Abstract class|Concrete class|
|---|---|---|
|Can instantiate directly|No|Yes|
|Can have constructors|Yes|Yes|
|Can have fields|Yes|Yes|
|Can have implemented methods|Yes|Yes|
|Can declare abstract methods|Yes|No|
|Can extend another class|Yes|Yes|
|Can implement interfaces|Yes|Yes|
|Must implement inherited abstract methods|No|Yes|

## 8. The Whole Picture

Remember these four principles:

**1. An abstract class represents an incomplete or intentionally non-instantiable superclass.**

**2. An abstract method represents a responsibility that concrete subclasses must eventually fulfill.**

**3. Abstract classes provide code reuse through inheritance and support polymorphism.**

**4. You don't need an interface to create an abstract class, and you don't need an abstract class to implement an interface.**

The most important mental model is:

> An interface says what implementations must provide. An abstract class can provide a shared foundation, while leaving selected responsibilities to subclasses.

### What to learn next

- **Template Method Design Pattern:** How abstract classes can define an algorithm while subclasses customize individual steps.
    
- **Composition vs Inheritance:** When extending an abstract class is appropriate and when using objects as dependencies is a better design.


[[Java]]

[^1]: ***Instantiation*** is the process of creating an actual object (instance) from a class in memory. Think of a class as a blueprint that describes what an object should contain and how it should behave, while instantiation is the moment we use that blueprint to create a real object. In Java, we typically instantiate a class using the `new` keyword, like `Dog dog = new Dog();`. Here, `Dog` is the class, `new Dog()` creates the object by allocating memory and calling its constructor, and `dog` is the reference variable pointing to that object. Remember, a class is the definition, while an instance is an actual object created from that definition.
