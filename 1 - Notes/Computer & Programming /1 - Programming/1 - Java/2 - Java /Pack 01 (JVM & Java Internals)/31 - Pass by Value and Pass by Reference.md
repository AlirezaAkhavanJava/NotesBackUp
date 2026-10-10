

Imagine you write a method and pass it a variable. Can that method change the variable you passed? The answer depends on the rule the language uses for arguments, and that rule is what these two terms describe.

- **Pass by value** means the method receives a **copy** of the argument. Changes to that copy do not affect the caller's variable.
- **Pass by reference** means the method receives the **variable itself**, so an assignment inside the method changes the caller's variable.

Java uses only pass by value. That statement sounds like it contradicts the way objects behave, so most of this lesson is about resolving that apparent contradiction.

## Why the distinction exists

A method is a separate piece of code with its own local variables. When you call one, the arguments have to get from the caller's variables into the method's parameters somehow. The language has to decide what gets copied across that boundary.

This matters because it determines what a method is allowed to affect. If arguments are copied, a method cannot accidentally change the caller's data by reassigning a parameter. If the caller's variables are passed directly, the method can change them, and the caller has to read every method body to know which variables might change.

Languages make different choices here. C++ offers both behaviors, C and Go pass by value, and Python behaves in a way that is neither, which is a common source of confusion. Java made one choice and applies it everywhere.

## The rule, stated precisely

When you call a method, Java evaluates each argument and **copies the value** of that expression into the matching parameter. The parameter is a new variable that starts with that value.

For a primitive such as `int`, the value is the number itself. For an object, the variable does not hold the object. It holds a **reference**, which is the address of the object in memory. So the value being copied is the reference.

That single fact explains everything below. The method gets its own copy of the address, and that copy points to the same object the caller's variable points to.

## Three experiments that show the rule

Create a folder and a file named `PassDemo.java`:

```java
public class PassDemo {

    static void incrementPrimitive(int x) {
        x = x + 1;                 // changes only the local copy
    }

    static void appendToBuilder(StringBuilder sb) {
        sb.append(" world");       // follows the reference, changes the shared object
    }

    static void replaceBuilder(StringBuilder sb) {
        sb = new StringBuilder("replaced");  // changes only the local copy of the reference
    }

    public static void main(String[] args) {
        int count = 10;
        incrementPrimitive(count);
        System.out.println("count = " + count);       // 10

        StringBuilder text = new StringBuilder("hello");
        appendToBuilder(text);
        System.out.println("text = " + text);         // hello world

        replaceBuilder(text);
        System.out.println("text = " + text);         // hello world
    }
}
```

Run it on Debian with:

```bash
mkdir -p ~/java-lessons/pass && cd ~/java-lessons/pass
nano PassDemo.java          # paste the code, save, exit
javac PassDemo.java
java PassDemo
```

Each method shows a different part of the rule:

- `incrementPrimitive` receives a copy of the number 10. It increments its copy to 11, then the method ends and the copy disappears. `count` is still 10.
- `appendToBuilder` receives a copy of the reference. That copy points to the same `StringBuilder` that `text` points to. Calling `append` modifies the object itself, so the change is visible through `text`. Two references, one object.
- `replaceBuilder` assigns a new object to its local copy of the reference. The caller's `text` still points to the original object, so nothing visible changes.

The second and third cases look similar in source code, yet they behave differently. The difference is whether you change the object or change the variable.

## Drawing the memory

A diagram makes the rule concrete. Before `replaceBuilder` is called, the memory looks like this:

```
Stack (variables)             Heap (objects)
-----------------             -----------------------
main:                          
  text ──────────────────────> StringBuilder: "hello world"

replaceBuilder:
  sb   ──────────────────────> (same object as text)
```

Inside `replaceBuilder`, `sb = new StringBuilder("replaced")` creates a new object and points the local variable `sb` at it. The diagram becomes:

```
Stack                          Heap
-----                          ----
main:
  text ──────────────────────> StringBuilder: "hello world"

replaceBuilder:
  sb   ──────────────────────> StringBuilder: "replaced"
```

When `replaceBuilder` returns, its variable `sb` is gone, and the new object has no references left. `text` still points to the original object. The method never had access to the variable `text`, only to a copy of its pointer.

## Swapping two values

The classic test of pass by reference is a swap method:

```java
static void swap(int a, int b) {
    int temp = a;
    a = b;
    b = temp;
}

public static void main(String[] args) {
    int x = 1, y = 2;
    swap(x, y);
    System.out.println(x + " " + y);   // prints "1 2", not "2 1"
}
```

The swap happens on the copies, and the caller's `x` and `y` never move. In a language with pass by reference, this method would work. In Java, the only way to get the swapped values back is to return them, or to put them in an object the caller can read.

## Why Strings look unchangeable

`String` is an object, so it is passed as a reference, but you cannot change its contents. Every operation produces a new `String`. That makes the behavior easy to confuse with pass by value on objects:

```java
static void tryToChange(String s) {
    s = s + " changed";     // creates a new String, assigns it to the local copy only
}

String name = "Alireza";
tryToChange(name);
System.out.println(name);   // prints "Alireza"
```

The method cannot mutate the original `String`, and it cannot redirect the caller's variable, so the caller sees no change. The `final` keyword has the same effect on the parameter itself: writing `final String s` only forbids reassigning the local copy, and it does not change how the argument is passed.

## Why this design is useful

The rule keeps a method's effects visible. When you call `replaceBuilder(text)`, you know for certain that `text` will still point to something after the call. You do not need to check whether the method reassigned it. The only way a method can change the caller's world is through objects it was handed a reference to, and you can see those in its signature.

This also gives you control over sharing. When you want a method to modify something, you pass an object that can be modified, not an empty variable. When you want a method to be unable to modify something, you pass a copy or an immutable object.

## How you'll use this

Three practical rules follow from the lesson:

1. If a method must produce a result, return it. Do not try to smuggle it out through a parameter reassignment, because that will never work.
2. If a method must change data, pass an object whose state it is supposed to change, and make that intent clear in the method's name, such as `addItem` or `updateBalance`.
3. Remember that anything you pass as an object is shared. If you give a list to a method that stores it, the caller and the method now both hold the same list, and changes from either side are visible to the other.

In Spring Boot, this matters every day. Beans are objects that are injected by reference, so every class that receives the same bean shares one instance. A singleton service that stores request data in a field is a bug waiting to happen, because the same object is reachable from many places at once.


[[Java]]