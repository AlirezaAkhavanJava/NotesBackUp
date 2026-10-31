
Java is not purely a "reference type language." It has two families of types: **primitive types** and **reference types**. A primitive variable holds the value itself (like `int age = 25`). A reference variable holds the address of an object that lives somewhere else in memory (like `Dog d = new Dog()`). Almost everything you build in Java, such as classes, interfaces, arrays, enums, and `String`, is a reference type, which is why people say "everything is an object." That is only almost true, because those eight primitives are the exception.

This matters because the two families behave differently when you copy them, compare them, and pass them to methods. This is also what we talked about before: `Animal a = new Dog()` works because `a` is a reference, a remote control pointing at the object, not the object itself.

## The two families

**The 8 primitives:**

|Type|Holds|Example|
|---|---|---|
|`byte`, `short`, `int`, `long`|whole numbers|`int count = 10;`|
|`float`, `double`|decimal numbers|`double price = 9.99;`|
|`char`|one character|`char grade = 'A';`|
|`boolean`|true or false|`boolean done = false;`|

**Reference types:** everything else. Classes (`Dog`, `String`, `ArrayList`), interfaces (`List`), arrays (`int[]`), enums, and records.

A quick way to tell them apart: primitive type names start with a lowercase letter (`int`), and reference type names start with an uppercase letter (`String`). The exception is that variable names are lowercase for both.

## What is really stored in the variable

```java
int a = 5;
int b = a;       // b gets its own copy of 5
b = 99;
System.out.println(a);   // 5  (a is untouched)

Dog d1 = new Dog("Rex");
Dog d2 = d1;     // d2 gets a copy of the ADDRESS, same object
d2.setName("Max");
System.out.println(d1.getName());   // Max  (same object changed)
```

Line by line:

- `int b = a;` copies the number 5 into a second box. Now there are two separate boxes, so changing `b` does not affect `a`.
- `Dog d2 = d1;` copies the address, not the dog. Both variables now point to the same single `Dog` object.
- `d2.setName("Max")` changes that one shared object, so `d1` sees the change too.

You can picture it like this:

```
Stack (variables)            Heap (objects)
a  [ 5 ]
b  [ 99 ]
d1 [ ──────┐ ]
d2 [ ──────┴────────►  Dog{ name = "Max" }
```

The simple version: local variables live on the **stack**, and objects live on the **heap**. A reference variable is a small box on the stack holding an arrow to the heap.

## Comparing: `==` vs `.equals()`

For primitives, `==` compares the values. For references, `==` compares the **addresses**, which asks "are these the exact same object?"

```java
String s1 = new String("hi");
String s2 = new String("hi");

System.out.println(s1 == s2);        // false (two different objects)
System.out.println(s1.equals(s2));   // true  (same content)
```

Use `.equals()` when you want to compare content. This is one of the most common beginner bugs.

## null: a reference pointing at nothing

A primitive always has a value, but a reference can point to nothing:

```java
Dog d = null;
d.bark();   // NullPointerException: no object to call bark() on
```

An `int` can never be null. This is the reason `NullPointerException` exists only for references.

## Passing to methods: Java is always pass-by-value

This surprises many people. Java **always copies what is in the variable**. For a primitive, it copies the number. For a reference, it copies the address, so the method gets its own arrow to the same object.

```java
static void change(int x, Dog d) {
    x = 100;               // changes only the local copy
    d.setName("Changed");  // follows the arrow, changes the real object
    d = new Dog("Other");  // moves the LOCAL arrow only
}

int n = 1;
Dog rex = new Dog("Rex");
change(n, rex);

// n is still 1
// rex's name is "Changed" (the object was modified)
// rex still points to the same Dog (the new Dog("Other") was lost)
```

So a method can change the **object** a reference points to, but it cannot make your variable point somewhere else.

## Wrapper classes: where the two families meet

Each primitive has a reference twin: `int` has `Integer`, `double` has `Double`, `boolean` has `Boolean`, and so on. You need them because generics only work with references: `List<int>` is illegal, but `List<Integer>` is fine. Java converts automatically (autoboxing):

```java
List<Integer> nums = new ArrayList<>();
nums.add(5);        // int -> Integer (autoboxing)
int x = nums.get(0); // Integer -> int (unboxing)
```

Be careful with `==` on wrappers. `Integer` values from -128 to 127 are cached, so `==` may work for small numbers and fail for large ones. Use `.equals()`.

## Related concept: String is a reference type, but it feels like a primitive

`String` is a class, but Java lets you write it as a literal (`"hello"`) and use `+`. It is also **immutable**: once created, its content never changes. `s = s + "!"` creates a new String and moves the arrow. That is why strings behave in a value-like way even though they are references.



Java is a language with both: 8 primitive types that hold values directly, and everything else as reference types that hold addresses to objects. Knowing which one you have tells you how copying, `==`, `null`, and method arguments will behave.




[[Java]]