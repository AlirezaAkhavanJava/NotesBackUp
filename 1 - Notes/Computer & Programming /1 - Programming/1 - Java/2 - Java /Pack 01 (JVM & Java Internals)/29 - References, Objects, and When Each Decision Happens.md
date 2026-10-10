

Before deciding _when_ Java makes a choice, you need to be clear about the two things involved.

- **The reference** is a variable. It holds a pointer to an object in memory, or `null`. Its **declared type** is the type you write in the source code, such as `Shape s`.
- **The object** is the instance that exists on the heap, created by `new`. It has an **actual type** (its real class, such as `Circle`), which is recorded in the object itself when it is created and never changes.

These are separate. In `Shape s = new Circle();`, the variable `s` is a reference with declared type `Shape`, and the object it points to is a `Circle` with actual type `Circle`.

## Why the separation matters

Java is statically typed, so the compiler needs to verify that every name you use exists and is legal for the declared type. It cannot know which object a reference will point to, because that depends on the program's execution. So Java splits the work into two phases:

1. **Compile time (`javac`)** checks everything it can determine from the declared types. It verifies the names, the argument types, and the assignments, then encodes its decisions into bytecode.
2. **Runtime (the JVM)** handles what depends on the actual object. It looks at the real class of the object and chooses the implementation to run.

## Compile time: decided by the declared type

When `javac` compiles `s.describe()` it looks at `Shape`, the declared type of `s`. It asks whether `Shape` has a method `describe()` that is accessible and matches the arguments. If not, you get a compile error, even if the object happens to be a `Circle` that has the method.

This is why the following is rejected:

```java
Shape s = new Circle();
s.round();   // compile error: Shape has no round(), even though the object is a Circle
```

The compiler doesn't care what the object really is. It only checks `Shape`.

At compile time `javac` also decides:

- which **field** is accessed, based on the declared type
- which **overload** is chosen, based on the declared argument types
- which **static method** is called, based on the declared type of the reference or the class name
- whether a **cast** is legal at all, based on whether the two types are related

## Runtime: decided by the actual object

When the JVM executes `s.describe()`, the decision is no longer about `Shape`. The JVM reads the class recorded in the object's header, goes to that class's method table, and calls the implementation found there. If the object is a `Circle`, it calls `Circle.describe()`, even though the code says `Shape`.

Runtime also checks what the compiler could not: whether a cast is valid for the actual object, and whether the reference is `null`.

## A complete example

```java
class Shape {
    String name = "shape";

    String describe() {
        return "I am a shape";
    }
}

class Circle extends Shape {
    String name = "circle";      // hides Shape.name, does not override it

    @Override
    String describe() {          // overrides Shape.describe()
        return "I am a circle";
    }

    void round() {
        System.out.println("Rounding the corners");
    }
}

public class RefVsObject {
    public static void main(String[] args) {
        Shape s = new Circle();  // reference type: Shape, object type: Circle

        // Compile time: field resolved by the declared type Shape
        System.out.println(s.name);        // prints "shape"

        // Runtime: method resolved by the actual type Circle
        System.out.println(s.describe());  // prints "I am a circle"

        // Compile time: javac rejects this because Shape has no round()
        // s.round();

        // Compiles, because Shape and Circle are related.
        // Checked at runtime against the actual object, which is a Circle, so it succeeds.
        Circle c = (Circle) s;
        c.round();                         // prints "Rounding the corners"

        // Compiles, but fails at runtime.
        Shape plain = new Shape();         // actual type: Shape
        Circle bad = (Circle) plain;       // ClassCastException: a Shape is not a Circle

        // Runtime: a null reference has no object, so the dispatch fails
        Shape nothing = null;
        // nothing.describe();             // NullPointerException at runtime
    }
}
```

What each part shows:

- `s.name` prints `"shape"` because the field is chosen by the declared type `Shape`, which is decided at compile time.
- `s.describe()` prints `"I am a circle"` because the method is chosen by the actual object's class at runtime.
- `s.round()` is rejected by `javac`, because the compiler only sees `Shape`.
- `(Circle) s` compiles, since the compiler sees a legal relationship between the two types. The JVM then checks the real object and allows the cast.
- `(Circle) plain` compiles but throws at runtime, because the real object is not a `Circle`. The compiler could not have known this.

## Seeing the split in bytecode

You can observe the two phases directly. Compile the file, then inspect the bytecode:

```bash
javac RefVsObject.java
javap -c RefVsObject
```

In the output for `main`, you'll find instructions like these:

- `getfield Shape.name` for `s.name`. The owner is `Shape`, which is the declared type. The field is resolved at compile time.
- `invokevirtual Shape.describe` for `s.describe()`. The owner is still `Shape`, but `invokevirtual` tells the JVM to find the implementation on the **actual** object's class at runtime. That lookup is where late binding happens.
- `checkcast Circle` for `(Circle) s`. This is the runtime check for the cast.

The bytecode records the compiler's decisions, and the JVM finishes the job at runtime.

## Checking the actual type safely

When you need to test the real type before casting, use `instanceof`. Since Java 16, you can also bind the cast result in the same expression:

```java
Shape s = new Circle();

if (s instanceof Circle c) {   // runtime check, then safe cast
    c.round();                 // c is a Circle here
}
```

The `instanceof` test is evaluated at runtime against the actual object. If it is false, the block is skipped and no exception is thrown.

## Summary

|Question|Decided by|Phase|
|---|---|---|
|Does this name exist on the declared type?|Declared type of the reference|Compile time (`javac`)|
|Which field is read?|Declared type|Compile time|
|Which overload is called?|Declared argument types|Compile time|
|Is this cast allowed in principle?|Relationship between declared types|Compile time|
|Which overridden method runs?|Actual object's class|Runtime (JVM)|
|Is this specific cast valid?|Actual object's class|Runtime (`ClassCastException`)|
|Is the reference `null`?|The reference's value|Runtime (`NullPointerException`)|




[[Java]]