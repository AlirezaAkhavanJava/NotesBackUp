

## What dispatch means

**Dispatch** is the act of selecting which method body to execute for a given call. **Virtual dispatch** is dispatch where the selection depends on the runtime class of the receiver, the object the call is made on. Overridden instance methods use virtual dispatch. Everything else, such as static methods, private methods, and constructors, is resolved without looking at the receiver's class.

Last time we established that `javac` checks the declared type and the JVM uses the actual object. This lesson is about how the JVM does that second step fast enough to run every method call in your program.

## The problem a naive lookup would have

Suppose the JVM handled `s.describe()` the simplest way possible. It would read the object's class name, search that class for a method named `describe` with the right signature, and if it was not there, move to the parent class and search again, repeating until it found one.

That works, but every call pays for a string comparison and a walk up the hierarchy. Java programs make millions of calls per second, and most of them are polymorphic calls on ordinary class hierarchies. The JVM needs a lookup that costs the same small amount every time, regardless of how deep the hierarchy is.

The fix is to do the expensive work once, when the class is loaded, and turn each method into a number. Then every call becomes "find entry number N in a table," which is a single memory read.

## The vtable

A **vtable** (virtual method table) is an array that belongs to a class. Each entry holds a pointer to the implementation of one virtual method for that class. Each virtual method has a fixed **slot number**, and that number never changes for that method across the hierarchy.

Every object's header contains a pointer to its class metadata, and the class metadata contains that class's vtable. So the path from an object to its method implementation is:

object → class pointer in header → vtable → slot N → method code

Here are three classes:

```java
class Shape {
    String describe() { return "shape"; }   // slot 0
    double area()    { return 0; }          // slot 1
}

class Circle extends Shape {
    @Override String describe() { return "circle"; }   // replaces slot 0
    @Override double area()     { return Math.PI; }    // replaces slot 1
    void grow() { }                                    // new virtual method, appended as slot 2
}

class Square extends Shape {
    @Override double area() { return 4.0; }            // replaces slot 1 only
}
```

The vtables for these classes look like this:

```
Shape vtable:   [0] Shape.describe    [1] Shape.area
Circle vtable:  [0] Circle.describe   [1] Circle.area    [2] Circle.grow
Square vtable:  [0] Shape.describe    [1] Square.area
```

Three rules produce these tables, and they are the whole idea:

1. A subclass starts with a copy of its parent's vtable.
2. If the subclass overrides a method, the entry in the same slot is replaced.
3. If the subclass adds a new virtual method, it is appended at the end.

Because the parent's table is a prefix of the child's table, a slot number computed from `Shape` is valid for `Circle` and `Square` too. Slot 1 is always `area` in every class that extends `Shape`.

## Why `s.area()` works through slot 1

Consider the call site, with `s` declared as `Shape`:

```java
Shape s = (args.length > 0) ? new Circle() : new Square();
System.out.println(s.area());
```

`javac` compiles `s.area()` to an `invokevirtual` instruction that names `Shape.area`. It does not know which object `s` will hold, so it cannot pick a body. It only records the symbolic name.

At runtime, the JVM resolves that symbolic name to slot 1 by looking at `Shape`'s layout. Then, for the actual object:

1. Read the class pointer from the object's header.
2. Go to that class's vtable.
3. Read entry 1.
4. Jump to that method's code.

If the object is a `Circle`, entry 1 is `Circle.area`. If it is a `Square`, entry 1 is `Square.area`. The call site did not change, and the cost is the same either way.

## Seeing invokevirtual in bytecode

You can observe this directly. Save the following as `Dispatch.java` in a new folder:

```java
class Shape {
    double area() { return 0; }
}

class Square extends Shape {
    @Override double area() { return 4.0; }
}

public class Dispatch {
    public static void main(String[] args) {
        Shape s = new Square();
        System.out.println(s.area());
    }
}
```

Build it and inspect the bytecode for `main`. On Debian 13, install a JDK if you do not already have one (`sudo apt install openjdk-21-jdk`, or check with `javac -version` first), and then run:

```bash
javac Dispatch.java
javap -c -p Dispatch.class
```

In the `main` method you will see a line like this:

```
invokevirtual #7    // Method Shape.area:()D
```

The operand names `Shape.area`, which is the declared type, and the `invokevirtual` opcode tells the JVM to dispatch on the receiver's actual class. The `()D` at the end is the descriptor: no parameters, returns a `double`. Note that `main` contains no mention of `Square` at all.

The `-p` flag shows private members as well. Without it, `javap` hides them.

## Why interfaces need a different mechanism

The vtable depends on one rule: a method's slot is the same in every subclass. Interfaces break that rule, because a class can implement several interfaces, and the set of methods it carries is not a simple extension of one parent.

Consider:

```java
interface Drawable { void draw(); }
interface Resizable { void resize(); }

class Box implements Resizable, Drawable {
    public void resize() { }
    public void draw() { }
}

class Dot implements Drawable {
    public void draw() { }
}
```

In `Box`, `draw` might sit at one index, and in `Dot`, `draw` is at a different index. A caller holding a `Drawable` cannot use a fixed slot number from the interface, because no single number is correct for both classes. Any class can implement any combination of interfaces, so there is no global numbering that works.

The JVM handles this with an **itable** (interface method table). Each class keeps a list of the interfaces it implements. For each interface, the class has a small table that maps that interface's methods to this class's implementations. Dispatch then has two steps:

1. Find the entry for the interface, such as `Drawable`, in the object's class.
2. Use the method's index within that interface's table to get the implementation.

The bytecode for a call through an interface reference uses a different opcode:

```java
Drawable d = new Dot();
d.draw();
```

compiles to:

```
invokeinterface Drawable.draw:()V, 1
```

The `1` at the end is the argument count, counting the receiver. You will see it on every `invokeinterface`.

## Why invokeinterface costs more

The vtable path is a single index. The itable path has an extra step, which is finding the right interface entry in the class. HotSpot reduces that cost in practice with **inline caches**. The first time a call site runs, the JVM records which class it saw. If later calls keep seeing the same class, the call site remembers the answer and skips the search. If several classes show up, the call site becomes slower but still correct. If many classes show up, which the JIT calls a **megamorphic** call site, every call does the full search.

This explains some performance advice you will read: a call site that always sees one implementation is cheap, and a call site that sees many implementations through an interface is more expensive. In most applications the difference is small, and you should not design around it prematurely. Knowing the mechanism helps you read profiler output and understand why an abstraction costs what it does.

## The other invoke instructions

Virtual and interface dispatch are two of five invoke opcodes. The other three do not look at the receiver's class:

|Opcode|Used for|Dispatch|
|---|---|---|
|`invokestatic`|Static methods|None, resolved to one method|
|`invokespecial`|Constructors, `private` methods, `super.method()`|None, resolved to one method|
|`invokevirtual`|Overridable instance methods on classes|Vtable, by receiver's class|
|`invokeinterface`|Methods called through an interface type|Itable, by receiver's class|
|`invokedynamic`|Lambdas, string concatenation, and similar|Chosen by a bootstrap method|

Private methods use `invokespecial` because they cannot be overridden, so there is nothing to dispatch on. That means a `private` method in a parent cannot be replaced by a subclass method with the same name, which connects directly to the hiding behavior from our first lesson.

## Putting it together with a program you can run

Create this file and run it. It is designed so that the output shows both kinds of dispatch at work:

```java
interface Named {
    String name();
}

class Animal implements Named {
    public String name() { return "animal"; }
    String sound() { return "..."; }
}

class Cat extends Animal {
    @Override public String name() { return "cat"; }
    @Override String sound() { return "meow"; }
}

public class DispatchDemo {
    public static void main(String[] args) {
        Animal a = new Cat();
        Named n = new Cat();

        System.out.println(a.sound());   // invokevirtual: vtable slot for sound
        System.out.println(a.name());    // invokevirtual: vtable slot for name
        System.out.println(n.name());    // invokeinterface: itable lookup for Named
    }
}
```

The output is `meow`, `cat`, and `cat`. Each line is a virtual or interface call, and each one reaches `Cat`'s implementation without the caller knowing about `Cat`. Now run:

```bash
javac DispatchDemo.java
javap -c -p DispatchDemo.class
```

Look for the three call instructions in `main`. You should find two `invokevirtual` lines and one `invokeinterface` line. Matching the opcode to the declared type of the receiver is the skill this exercise is meant to build.

## How you'll use this

For day-to-day Spring Boot work, you will not manage vtables. You will, however, rely on this behavior every time you program to an interface. Spring's beans, repositories, and services are typically accessed through interface types, which means their calls go through `invokeinterface`. That is the mechanism that lets Spring swap a real implementation for a test double or a proxy.

Two practical rules follow from this lesson. First, prefer depending on interfaces at boundaries, because the dispatch cost is small and the flexibility is large. Second, when you see `final` on a class or method, you now know why it can help performance: it tells the JVM that no override can exist, so the call can be made directly.




[[Java]]