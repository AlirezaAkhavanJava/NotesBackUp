
# Java Nested & Inner Classes

## 1. Definition

A **nested class** is a class declared **inside another class or interface**.

```java
class Outer {

    class Inner {
    }
}
```

Java has **four kinds of nested classes**:

|Type|`static`?|Has enclosing object?|Typical use|
|---|--:|--:|---|
|Static nested class|Yes|No|Helper/type logically belonging to outer class|
|Inner class|No|Yes|Object tied to an outer object|
|Local class|No|Yes*|Temporary class inside a method/block|
|Anonymous class|No|Yes*|One-off implementation/subclass|

* Local and anonymous classes can capture the enclosing instance when applicable.

The important distinction is:

```text
Nested class
├── Static nested class
└── Inner class
    ├── Member inner class
    ├── Local class
    └── Anonymous class
```

More precisely, **"inner class" technically means a non-static nested class**, while local and anonymous classes are special kinds of inner classes.

---

# 2. Why Do Nested Classes Exist?

The main reason is **encapsulation and logical grouping**.

Suppose you have:

```java
class LinkedList {

    private class Node {
        int value;
        Node next;
    }
}
```

`Node` is conceptually part of `LinkedList`, but users of `LinkedList` don't need to work with it directly.

Instead of:

```text
LinkedList
Node
SomeOtherClass
Helper
...
```

you express the relationship directly:

```text
LinkedList
└── Node
```

Nested classes are therefore useful when a type:

- belongs conceptually to another type
    
- should have restricted visibility
    
- needs access to the enclosing class
    
- exists only for a particular implementation
    

---

# 3. Static Nested Class

A **static nested class** is declared with `static`.

```java
class Outer {

    static class Nested {
    }
}
```

Create it without an `Outer` object:

```java
Outer.Nested nested = new Outer.Nested();
```

Notice:

```java
new Outer.Nested();
```

not:

```java
new Outer().new Nested();
```

because the nested class does **not require an instance of `Outer`**.

---

## Example

```java
class Computer {

    static class CPU {

        void calculate() {
            System.out.println("Calculating...");
        }
    }
}
```

Usage:

```java
Computer.CPU cpu = new Computer.CPU();

cpu.calculate();
```

The relationship is:

```text
Computer
   │
   └── CPU
       static nested class
```

---

# 4. Static Nested Classes Can Access Static Members

```java
class Outer {

    static int x = 10;

    static class Nested {

        void print() {
            System.out.println(x);
        }
    }
}
```

This works because `x` belongs to the class itself.

---

# 5. Static Nested Classes Cannot Directly Access Instance Members

```java
class Outer {

    int x = 10;

    static class Nested {

        void print() {
            // System.out.println(x); ❌
        }
    }
}
```

Why?

Because there may be **no `Outer` object**.

```java
Outer.Nested nested = new Outer.Nested();
```

Which `Outer.x` would it access?

There isn't an `Outer` instance.

You can explicitly provide one:

```java
class Outer {

    int x = 10;

    static class Nested {

        void print(Outer outer) {
            System.out.println(outer.x);
        }
    }
}
```

---

# 6. Inner Classes

A non-static member class is an **inner class**.

```java
class Outer {

    class Inner {
    }
}
```

Unlike a static nested class, it is associated with an **instance of `Outer`**.

Create it like this:

```java
Outer outer = new Outer();

Outer.Inner inner = outer.new Inner();
```

The syntax is important:

```java
outer.new Inner();
```

---

# 7. Why Does `outer.new Inner()` Exist?

An inner class has an implicit relationship with its enclosing object.

Conceptually:

```text
Outer object
     │
     └──── Inner object
```

The inner object knows which `Outer` instance encloses it.

For example:

```java
class Person {

    private String name = "Alireza";

    class Brain {

        void identify() {
            System.out.println(name);
        }
    }
}
```

Usage:

```java
Person person = new Person();

Person.Brain brain = person.new Brain();

brain.identify();
```

The `Brain` object can directly access:

```java
name
```

from its enclosing `Person`.

---

# 8. Inner Classes Can Access Private Members

This is an important feature.

```java
class Outer {

    private int secret = 42;

    class Inner {

        void printSecret() {
            System.out.println(secret);
        }
    }
}
```

No getter is required.

The nested class has access to the enclosing class's members subject to Java's normal access rules.

Likewise, the outer class can access members of its nested class.

---

# 9. `this` in an Inner Class

There are potentially **two objects**:

```text
Outer object
Inner object
```

Therefore:

```java
this
```

inside the inner class refers to the **inner object**.

To refer to the outer object:

```java
Outer.this
```

Example:

```java
class Outer {

    int value = 10;

    class Inner {

        int value = 20;

        void print() {
            System.out.println(value);
            System.out.println(this.value);
            System.out.println(Outer.this.value);
        }
    }
}
```

Output:

```text
20
20
10
```

This syntax is extremely important when working with nested classes.

---

# 10. Member Nested Classes vs Local Classes

These are different.

### Member class

Declared directly inside the class:

```java
class Outer {

    class Inner {
    }
}
```

### Local class

Declared inside a method:

```java
class Outer {

    void method() {

        class Local {
        }

        Local local = new Local();
    }
}
```

The scope of `Local` is limited to that method/block.

---

# 11. Local Classes

A **local class** is a class declared inside a method, constructor, initializer, or another block.

```java
void process() {

    class Processor {

        void run() {
            System.out.println("Processing");
        }
    }

    Processor processor = new Processor();

    processor.run();
}
```

Outside `process()`:

```java
// Processor p; ❌
```

`Processor` doesn't exist in that scope.

---

# 12. Why Use Local Classes?

They're useful when you need:

> A real class with multiple methods/state, but only inside one particular operation.

For example:

```java
void processUsers(List<User> users) {

    class Statistics {

        int countAdults() {
            // ...
            return 0;
        }

        int countChildren() {
            // ...
            return 0;
        }
    }

    Statistics statistics = new Statistics();
}
```

If the type is only useful inside this operation, making it a top-level class may be unnecessary.

---

# 13. Local Classes Can Capture Local Variables

Consider:

```java
void test() {

    int number = 10;

    class Printer {

        void print() {
            System.out.println(number);
        }
    }

    new Printer().print();
}
```

This works.

But the local variable must be **final or effectively final**.

This works:

```java
int number = 10;

class Printer {
    void print() {
        System.out.println(number);
    }
}
```

This does not:

```java
int number = 10;

number++;

class Printer {
    void print() {
        System.out.println(number); // ❌
    }
}
```

The same capture rule applies to lambdas and anonymous classes.

---

# 14. Anonymous Classes

An **anonymous class** is a class without a name that is declared and instantiated in one expression.

Example:

```java
Runnable runnable = new Runnable() {

    @Override
    public void run() {
        System.out.println("Hello");
    }
};
```

There is no class name like:

```java
class MyRunnable
```

Instead:

```text
new Runnable() {
    ...
}
```

creates an anonymous subclass/implementation.

---

# 15. Anonymous Class Implementing an Interface

Suppose:

```java
interface Animal {

    void speak();
}
```

You can write:

```java
Animal animal = new Animal() {

    @Override
    public void speak() {
        System.out.println("Woof");
    }
};
```

Conceptually:

```text
Animal interface
      ↑
anonymous implementation
      │
      └── object
```

---

# 16. Anonymous Class Extending a Class

Anonymous classes aren't limited to interfaces.

```java
abstract class Animal {

    abstract void speak();
}
```

Then:

```java
Animal animal = new Animal() {

    @Override
    void speak() {
        System.out.println("Woof");
    }
};
```

You're creating an unnamed subclass.

---

# 17. Anonymous Classes with `Comparator`

You've probably seen:

```java
List<String> names = new ArrayList<>();

names.sort(new Comparator<String>() {

    @Override
    public int compare(String a, String b) {
        return a.length() - b.length();
    }
});
```

The anonymous class is essentially:

```java
new Comparator<String>() {
    public int compare(String a, String b) {
        return a.length() - b.length();
    }
}
```

Historically, this was extremely common.

Today, because `Comparator` is a **functional interface**, you'd normally write:

```java
names.sort(
    (a, b) -> Integer.compare(a.length(), b.length())
);
```

The lambda is much shorter.

---

# 18. Anonymous Classes and `Runnable`

Old-style:

```java
Thread thread = new Thread(new Runnable() {

    @Override
    public void run() {
        System.out.println("Running");
    }
});
```

Because `Runnable` is functional, this can become:

```java
Thread thread = new Thread(
    () -> System.out.println("Running")
);
```

So:

```text
Anonymous class
        ↓
Lambda
```

is often possible **when the target type is a functional interface**.

But they are **not the same feature**.

---

# 19. Anonymous Class vs Lambda

Important distinction:

|Feature|Anonymous class|Lambda|
|---|---|---|
|Creates an anonymous class|Yes|No|
|Can implement functional interface|Yes|Yes|
|Can implement non-functional interface|Yes|No|
|Can extend a class|Yes|No|
|Can declare multiple methods|Yes|No|
|Has its own class identity|Yes|Different mechanism|
|Can declare fields|Yes|No normal class fields|
|Verbose|More|Less|

Example:

```java
Runnable r = new Runnable() {

    private int counter = 0;

    @Override
    public void run() {
        counter++;
    }
};
```

An anonymous class can have its own field.

A lambda cannot simply declare an instance field like that.

---

# 20. Nested Classes and `static`

A very common misconception is:

> "A class inside another class is automatically associated with an outer object."

No.

There are two fundamentally different cases:

### Static

```java
class Outer {

    static class Nested {
    }
}
```

No outer instance required.

### Non-static

```java
class Outer {

    class Inner {
    }
}
```

Outer instance required.

Remember:

```text
static nested class
        ↓
class-level relationship

inner class
        ↓
object-level relationship
```

---

# 21. Complete Example

```java
class Computer {

    private String model = "ThinkPad";

    // 1. Static nested class
    static class CPU {

        void calculate() {
            System.out.println("CPU calculating");
        }
    }

    // 2. Inner class
    class GPU {

        void render() {
            System.out.println(model + " GPU rendering");
        }
    }

    void start() {

        // 3. Local class
        class Startup {

            void execute() {
                System.out.println("Starting " + model);
            }
        }

        Startup startup = new Startup();
        startup.execute();

        // 4. Anonymous class
        Runnable task = new Runnable() {

            @Override
            public void run() {
                System.out.println("Background task");
            }
        };

        task.run();
    }
}
```

This one class demonstrates all four forms:

```text
Computer
│
├── static class CPU
│
├── class GPU
│
└── start()
    │
    ├── local class Startup
    │
    └── anonymous Runnable
```

---

# 22. Access Rules Summary

|Class type|Can access outer instance fields directly?|Requires outer instance?|
|---|--:|--:|
|Static nested|No|No|
|Member inner|Yes|Yes|
|Local class|Yes|Yes, when enclosing instance exists|
|Anonymous class|Yes|Yes, when enclosing instance exists|

All of them can access members according to Java's access rules, including private members of the enclosing class.

---

# 23. When Should You Use Each?

### Static nested class

Use when the class logically belongs to another class but **doesn't need an outer object**.

```java
class Map {

    static class Entry<K, V> {
    }
}
```

A very common pattern.

---

### Inner class

Use when the nested object's behavior genuinely depends on a particular outer object.

```java
class Graph {

    class Node {
    }
}
```

---

### Local class

Use when you need a **small, named class whose scope should be restricted to one method/block**.

```java
void process() {

    class Processor {
    }

    // use Processor here
}
```

---

### Anonymous class

Use when you need a **one-off implementation/subclass** and a lambda isn't appropriate.

```java
SomeInterface object = new SomeInterface() {

    @Override
    public void execute() {
    }
};
```

---

# 24. The Big Picture

The hierarchy to remember is:

```text
                 Nested Classes
                      │
          ┌───────────┴───────────┐
          │                       │
       Static                  Non-static
       nested                    nested
       class                     class
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                 Member         Local        Anonymous
                 inner          class          class
```

And the fundamental question is:

> **Does this nested type need an enclosing object?**

```text
No
 ↓
static nested class

Yes
 ↓
inner class
```

Then:

```text
Where is it declared?

Inside class body
    → member inner class

Inside method/block
    → local class

No class name + immediate instantiation
    → anonymous class
```

That mental model covers essentially the entire **nested-class picture in Java**.


[[Java]]