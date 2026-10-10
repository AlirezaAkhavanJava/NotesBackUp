


An **interface** is a contract: a named set of methods that a class promises to provide. Java has several kinds of interfaces, and they differ in what they contain and what they are used for. The kinds are not separate keywords. They are patterns you build from the same `interface` declaration, with a few extra rules that Java added over time.

## The map first

|Kind|Distinguishing feature|Introduced|Main purpose|
|---|---|---|---|
|Standard (abstract) interface|Only abstract methods|Java 1.0|Define a contract|
|Interface with default methods|`default` methods that have bodies|Java 8|Add behavior without breaking old implementers|
|Interface with static and private methods|`static` and `private` methods with bodies|Java 8, 9|Helpers and utilities that belong to the contract|
|Functional interface|Exactly one abstract method|Java 8|Target for lambdas and method references|
|Marker interface|No methods at all|Java 1.0|Tag a type so code can test for it|
|Sealed interface|Explicit list of permitted implementers|Java 17|Closed set of types, checked by the compiler|
|Generic interface|Type parameters|Java 5|Contract that works for any element type|
|Constant interface|Only constant fields|Java 1.0|Anti-pattern, shown so you can recognize it|

The sections below explain each one. The first two rows are the foundation, and the rest are variations built on them.

## 1. Standard interface

**Definition.** A standard interface declares method signatures without bodies. Any class that implements it must provide a body for each method.

**Why it exists.** It lets code depend on a behavior rather than a concrete class. A method that takes a `List` does not care whether the list is an `ArrayList` or a `LinkedList`.

**How it works.** Every method in an interface is implicitly `public abstract`, and every field is implicitly `public static final`. You do not write those modifiers, but the compiler adds them.

```java
interface Notifier {
    void send(String message);   // implicitly public abstract
}

class EmailNotifier implements Notifier {
    @Override
    public void send(String message) {
        System.out.println("Email: " + message);
    }
}
```

`EmailNotifier` must implement `send`, or `javac` rejects the class. That enforcement is the point of the contract.

## 2. Interface with default methods (Java 8)

**Definition.** A default method is a method in an interface that has a body and is marked with the `default` keyword. Implementing classes inherit it unless they override it.

**Why it exists.** Before Java 8, adding a method to a published interface broke every class that implemented it. The Java library designers needed to add methods such as `forEach` to `Collection` without breaking existing code. Default methods solved that.

**How it works.** A class that implements the interface gets the default body automatically. If two interfaces supply the same default method, the class must resolve the conflict by overriding it, and it can call a specific version with `InterfaceName.super.method()`.

```java
interface Notifier {
    void send(String message);

    default void sendUrgent(String message) {
        send("URGENT: " + message);   // built on the abstract method
    }
}
```

Any `Notifier` gets `sendUrgent` for free, and it depends only on `send`, which each class defines.

## 3. Static and private methods in interfaces

**Definition.** A `static` method in an interface belongs to the interface itself and is called through its name. A `private` method (Java 9) is a helper that only the interface's own default and static methods can call.

**Why it exists.** Static methods let an interface offer factory methods or utilities next to the contract they relate to. Private methods let you share code between default methods without exposing it to implementers.

**How it works.** Static interface methods are not inherited. A class that implements `Notifier` does not get `Notifier.of(...)`, so you always call it as `Notifier.of(...)`.

```java
interface Notifier {
    void send(String message);

    static Notifier console() {
        return msg -> System.out.println("Console: " + msg);
    }

    default void sendAll(String... messages) {
        for (String m : messages) {
            send(decorate(m));
        }
    }

    private String decorate(String m) {
        return "[" + m + "]";
    }
}
```

`decorate` is invisible outside the interface. That keeps the public contract small.

## 4. Functional interface

**Definition.** A functional interface has exactly one abstract method. Default, static, and private methods do not count, and neither do the public methods that every object already has, such as `equals`.

**Why it exists.** A lambda expression needs a target type that has exactly one method to implement. Functional interfaces are that target, so `() -> ...` and `x -> ...` can be written without naming a class.

**How it works.** The `@FunctionalInterface` annotation is optional, but it asks the compiler to verify the rule. You will meet many functional interfaces in the standard library:

- `Runnable`: `void run()`
- `Supplier<T>`: `T get()`
- `Consumer<T>`: `void accept(T t)`
- `Function<T, R>`: `R apply(T t)`
- `Predicate<T>`: `boolean test(T t)`
- `Comparator<T>`: `int compare(T a, T b)`

`Comparator` has many default methods such as `reversed()` and `thenComparing(...)`, yet it is still functional, because only `compare` is abstract.

## 5. Marker interface

**Definition.** A marker interface has no methods and no fields. A class implements it to declare a property that code can test at runtime.

**Why it exists.** Some behavior cannot be expressed as a method. The JDK uses marker interfaces for things like `Serializable` (the object may be written to a stream), `Cloneable` (the object may be copied with `clone()`), and `RandomAccess` (a list supports fast indexed access).

**How it works.** The check is an ordinary `instanceof`, performed by the code that cares about the property:

```java
interface Auditable { }   // no methods: a tag only

class Order implements Auditable { }

Object item = new Order();
if (item instanceof Auditable) {
    System.out.println("Record this change");
}
```

Modern Java often uses annotations for the same purpose, such as `@Entity` in JPA or `@Component` in Spring. Annotations can carry data, and marker interfaces cannot. You will still see marker interfaces in older APIs.

## 6. Sealed interface (Java 17)

**Definition.** A sealed interface declares exactly which types may implement or extend it, using a `permits` clause.

**Why it exists.** An open interface can be implemented by any class anywhere, so the compiler can never know every possible case. A sealed interface gives a closed set of cases. That lets a `switch` be checked for completeness, so a missing case becomes a compile error instead of a runtime surprise.

**How it works.** Every permitted subtype must be declared `final` (no further subclasses), `sealed` (with its own `permits`), or `non-sealed` (open again). Records are implicitly final, so they fit well.

```java
sealed interface Shape permits Circle, Square {
    double area();
}

record Circle(double radius) implements Shape {
    public double area() { return Math.PI * radius * radius; }
}

record Square(double side) implements Shape {
    public double area() { return side * side; }
}
```

## 7. Generic interface

**Definition.** A generic interface declares one or more type parameters in angle brackets, so the contract is written in terms of a type the implementer chooses.

**Why it exists.** Without generics, a container of "any object" forces casts everywhere and lets type mistakes reach runtime. A generic interface states the element type once, and the compiler checks every use.

**How it works.** The parameters are placeholders. You supply real types when implementing or using the interface:

```java
interface Repository<T, ID> {
    void save(T item);
    T findById(ID id);
}

class UserRepository implements Repository<User, Long> {
    public void save(User user) { /* store it */ }
    public User findById(Long id) { return null; /* look it up */ }
}
```

Here `T` is `User` and `ID` is `Long`. The compiler now rejects `findById("abc")`. Spring Data's `JpaRepository<T, ID>` is this same pattern at a larger scale, which you will meet in your Spring Boot work.

## 8. Constant interface (anti-pattern)

**Definition.** An interface that contains only constant fields and no methods, which classes implement just to access those constants.

```java
interface Config {                       // anti-pattern
    int MAX_RETRIES = 3;
}
```

**Why it is a problem.** Implementing an interface should mean the class _is_ a kind of that type. Here the class is not a kind of `Config`, it just wants the number. The constants also leak into every implementer's public surface. Use a `final` class with a private constructor, or an enum, or a `static final` field in the class that owns the value.

## Seeing several kinds together

This program uses a sealed interface, a functional interface, an interface with default and private methods, and a marker. Save it as `InterfaceKinds.java` in a new folder:

```java
// 1. Sealed interface: closed set of implementations
sealed interface Shape permits Circle, Square {
    double area();
}

record Circle(double radius) implements Shape {
    public double area() { return Math.PI * radius * radius; }
}

record Square(double side) implements Shape {
    public double area() { return side * side; }
}

// 2. Functional interface: one abstract method, so lambdas can target it
@FunctionalInterface
interface Transformer {
    String apply(String input);
}

// 3. Interface with default, static, and private methods
interface Greeter {
    String name();

    default String greet() {
        return decorate("Hello, " + name());
    }

    static Greeter of(String n) {
        return () -> n;               // lambda works because Greeter is functional
    }

    private String decorate(String s) {
        return "[" + s + "]";
    }
}

// 4. Marker interface: no methods, used as a tag
interface Auditable { }

class Order implements Auditable {
    String id = "A-1";
}

public class InterfaceKinds {

    // Exhaustive switch: the compiler knows only Circle and Square exist
    static String describe(Shape s) {
        return switch (s) {
            case Circle c -> "circle with area " + String.format("%.2f", c.area());
            case Square q -> "square with area " + q.area();
        };
    }

    public static void main(String[] args) {
        System.out.println(describe(new Circle(1)));    // circle with area 3.14
        System.out.println(describe(new Square(2)));    // square with area 4.0

        Transformer shout = s -> s.toUpperCase() + "!";
        System.out.println(shout.apply("interfaces"));  // INTERFACES!

        Greeter g = Greeter.of("Alireza");
        System.out.println(g.greet());                  // [Hello, Alireza]

        Object o = new Order();
        if (o instanceof Auditable) {
            System.out.println("Order is auditable");   // printed
        }
    }
}
```

What each part demonstrates:

- `describe` uses a `switch` with no `default` branch. It compiles only because `Shape` is sealed, so the two cases cover every possibility. Add a third `record` that implements `Shape` without updating `permits`, and the compiler stops you.
- `shout` is a lambda assigned to `Transformer`. It works only because `Transformer` has exactly one abstract method.
- `Greeter.of` returns a lambda, and `greet()` runs the default method. That method calls `decorate`, which is private, so nothing outside `Greeter` can reach it.
- `instanceof Auditable` tests the marker at runtime. `Order` has no methods from `Auditable`, so the test is the only way to ask about the property.

Compile and run it on Debian 13 with a Java 21 JDK, which you can install with `sudo apt install openjdk-21-jdk`:

```bash
javac InterfaceKinds.java
java InterfaceKinds
```

Try removing `Greeter.of` and see what breaks. Then try adding a second abstract method to `Transformer`, and watch the `@FunctionalInterface` annotation reject the change. Those two experiments show the functional rule better than any explanation.

## How you'll use this

In Spring Boot you will meet most of these kinds. Standard interfaces define service and repository contracts, which is why you can swap implementations in tests. Generic interfaces like `JpaRepository<T, ID>` provide ready-made CRUD methods. Functional interfaces appear whenever you pass behavior, such as a `Supplier` in a configuration bean or a `Predicate` in a stream. Default methods are how libraries evolve without breaking your classes. Sealed interfaces are a good fit for domain results, such as a payment that is either `Approved` or `Declined`, because a `switch` over them is checked for completeness.


[[Java]]