In Java, when you write `Animal a = new Dog();`, the variable `a` is a remote control for the object, and the remote only has the buttons that the `Animal` type defines. The object itself is a full `Dog` and can do everything a `Dog` can. But you are not holding a `Dog` remote, so you can only press `Animal` buttons. This is the rule behind "the reference decides what you can call, the object decides how it runs."

Java has two kinds of type for every object variable. The **reference type** (also called the static or compile-time type) is the type written on the left: `Animal`. The **object type** (the runtime type) is what was created with `new`: `Dog`. The compiler checks your method calls against the reference type. The JVM, while the program runs, picks the actual implementation from the object type.

## The example

```java
class Animal {
    void eat() { System.out.println("Animal eats"); }
}

class Dog extends Animal {
    @Override
    void eat() { System.out.println("Dog eats bones"); }

    void bark() { System.out.println("Woof!"); }   // only Dog has this
}

public class Main {
    public static void main(String[] args) {
        Animal a = new Dog();

        a.eat();    // OK -> prints "Dog eats bones"
        a.bark();   // COMPILE ERROR: cannot find symbol bark() in Animal
    }
}
```

Walking through it line by line:

- `Animal a = new Dog();` creates a real `Dog` in memory. The variable `a` has type `Animal`.
- `a.eat()` compiles because `Animal` declares `eat()`. At runtime the JVM sees the object is a `Dog`, so it runs `Dog`'s version. This is runtime polymorphism.
- `a.bark()` fails to compile. The compiler looks only at `Animal`, finds no `bark()`, and stops. It never asks what the object really is.

## Why Java works this way

**1. The compiler cannot know the real object.** The compiler checks your code before it runs. Consider this:

```java
Animal a = getAnimalFromSomewhere();   // might be Dog, Cat, Bird...
a.bark();
```

At compile time Java has no way to know whether `a` will be a `Dog` or a `Cat`. If `bark()` were allowed and a `Cat` showed up, the program would crash at runtime. The rule is: only allow what is guaranteed for every possible object. `Animal` guarantees `eat()`, so that is allowed.

**2. The reference type is a contract.** `Animal` promises "anything stored in me can do these things." Code written against `Animal` should work with a `Dog`, a `Cat`, or a class added next year. If code could use `Dog`-only methods, it would secretly depend on `Dog`, and the whole point of polymorphism would be lost.

**3. It catches bugs early.** A compile error is much cheaper than a crash in production. Java's static typing moves this whole class of mistakes to compile time.

## How to call the Dog-only method

If you know the object is a `Dog`, tell the compiler by **casting**. Better yet, check first:

```java
Animal a = new Dog();

if (a instanceof Dog) {
    Dog d = (Dog) a;     // now the reference type is Dog
    d.bark();            // works
}

// Java 16+ shorthand:
if (a instanceof Dog d) {
    d.bark();
}
```

A cast changes the remote, not the object. If you cast to the wrong type, for example `(Cat) a` when the object is a `Dog`, Java throws a `ClassCastException` at runtime. That is why `instanceof` is the safe habit.

## Two sets of rules in one line of code

|Question|Decided by|When|
|---|---|---|
|Can I call this method?|Reference type (`Animal`)|Compile time|
|Which version of the method runs?|Object type (`Dog`)|Runtime|

So `a.eat()` is allowed because of `Animal` and runs the `Dog` code because of the real object.

## Related concept: overriding vs. hiding

Only **methods** are chosen by the real object. **Fields** are chosen by the reference type. If both `Animal` and `Dog` declare a field `name`, then `a.name` reads `Animal`'s field even though the object is a `Dog`. This is called field hiding, and it is why fields are usually private and accessed through getters, which can be overridden.

## When this limit is a good thing

Use the most general type that has the methods you need, such as `List<String> list = new ArrayList<>();`. You can only call `List` methods, and that is the intent. You can swap `ArrayList` for `LinkedList` later without touching the rest of your code.




[[Java]]