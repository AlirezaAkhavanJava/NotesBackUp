**Generics** are one of the most important parts of Java once you move from beginner code into serious API and framework development.

# 1. What are Generics?

**Generics allow you to write classes, interfaces, and methods that operate on different types while still providing compile-time type safety.**

Instead of writing code specifically for `String`, `Integer`, `User`, etc., you write it using a **type parameter**.

Without generics:

```java
List users = new ArrayList();

users.add("Alireza");
users.add(25);

String name = (String) users.get(0);
```

Problems:

- You can put unrelated types into the list.
    
- You need casts.
    
- Type errors may appear only at runtime.
    

With generics:

```java
List<String> users = new ArrayList<>();

users.add("Alireza");
// users.add(25); // Compile-time error

String name = users.get(0);
```

The compiler knows:

> "`users` contains `String` objects."

So generics primarily give you:

**Type safety + fewer casts + reusable code.**

---

# 2. The basic mental model

Think of:

```java
List<String>
```

as:

> "`List`, but specifically configured to work with `String`."

And:

```java
List<User>
```

as:

> "`List`, but specifically configured to work with `User`."

The `String` and `User` parts are supplied to the generic type.

---

# 3. Type Parameters vs. Type Arguments

This distinction is important.

### Type parameter

A **type parameter** is the placeholder declared by the generic code.

```java
class Box<T> {
    private T value;
}
```

`T` is the **type parameter**.

It means:

> "Some type will be supplied later."

### Type argument

When you actually use the generic type:

```java
Box<String> box;
```

`String` is the **type argument**.

So:

```java
class Box<T>
           ↑
     type parameter
```

while:

```java
Box<String>
    ↑
 type argument
```

A useful rule:

> **Parameter = declaration. Argument = actual type supplied.**

---

# 4. Common Generic Naming Conventions

Java has conventional names for type parameters.

|Convention|Meaning|
|---|---|
|`T`|Type|
|`E`|Element|
|`K`|Key|
|`V`|Value|
|`N`|Number|
|`S`, `U`, `V`|Additional types|

For example:

```java
class Box<T>
```

```java
interface Map<K, V>
```

```java
class Pair<K, V>
```

```java
class Container<T, U>
```

These are **conventions**, not Java keywords.

You could technically write:

```java
class Box<Banana>
```

but don't. 😄

Use meaningful conventional names:

```java
class Box<T>
```

---

# 5. Generic Classes

A **generic class** declares one or more type parameters.

```java
public class Box<T> {

    private T value;

    public Box(T value) {
        this.value = value;
    }

    public T getValue() {
        return value;
    }
}
```

Now we can create:

```java
Box<String> stringBox = new Box<>("Hello");

Box<Integer> integerBox = new Box<>(100);
```

The same class works with different types.

Conceptually:

```text
Box<T>
  │
  ├── Box<String>
  ├── Box<Integer>
  ├── Box<User>
  └── Box<Order>
```

The class itself doesn't care what `T` is.

---

# 6. Multiple Type Parameters

A generic class can have multiple parameters:

```java
public class Pair<K, V> {

    private K key;
    private V value;

    public Pair(K key, V value) {
        this.key = key;
        this.value = value;
    }

    public K getKey() {
        return key;
    }

    public V getValue() {
        return value;
    }
}
```

Usage:

```java
Pair<String, Integer> pair =
        new Pair<>("Age", 25);
```

Here:

```text
K → String
V → Integer
```

This is the same fundamental idea behind:

```java
Map<String, Integer>
```

where:

```text
K = String
V = Integer
```

---

# 7. Generic Methods

Generics aren't limited to classes.

A **generic method** declares its own type parameter.

```java
public static <T> T identity(T value) {
    return value;
}
```

The important part is:

```java
<T>
```

before the return type.

Usage:

```java
String name = identity("Alireza");

Integer number = identity(25);
```

Java infers:

```text
identity("Alireza")
        ↓
T = String

identity(25)
        ↓
T = Integer
```

The method itself is generic independently of whether its containing class is generic.

---

# 8. Generic Method vs Generic Class

Don't confuse these:

### Generic class

```java
class Box<T> {
    T value;
}
```

`T` belongs to the **class**.

### Generic method

```java
<T> T identity(T value)
```

`T` belongs to the **method**.

You can even have both:

```java
class Box<T> {

    public <U> U convert(U value) {
        return value;
    }
}
```

Here:

```text
T → belongs to Box
U → belongs to convert()
```

---

# 9. Bounded Types — `<T extends ...>`

Sometimes you don't want to accept **any** type.

For example:

```java
public static <T extends Number> double doubleValue(T value) {
    return value.doubleValue();
}
```

The constraint:

```java
<T extends Number>
```

means:

> `T` must be `Number` or a subclass of `Number`.

Therefore:

```java
doubleValue(10);       // Integer → valid
doubleValue(10.5);     // Double → valid
doubleValue(100L);     // Long → valid
```

But:

```java
doubleValue("Hello");  // compile-time error
```

because:

```text
String
  ✗
  ↓
Number
```

is not a subtype relationship.

---

# 10. Why `extends`?

This:

```java
<T extends Number>
```

doesn't necessarily mean class inheritance specifically.

It means:

> **T must be within the specified upper bound.**

It works with interfaces too:

```java
<T extends Comparable<T>>
```

For example:

```java
public static <T extends Comparable<T>> T max(T a, T b) {
    return a.compareTo(b) > 0 ? a : b;
}
```

Now Java knows that `T` has:

```java
compareTo(...)
```

available.

You can also have multiple bounds:

```java
<T extends Number & Comparable<T>>
```

The first bound can be a class; additional bounds must be interfaces.

---

# 11. Wildcards — `?`

A wildcard means:

> **Some unknown type.**

Example:

```java
List<?> list
```

means:

> A `List` containing some type, but we don't know what that type is.

It could be:

```java
List<String>
List<Integer>
List<User>
List<Object>
```

All can be passed to:

```java
void printList(List<?> list) {
    ...
}
```

The key difference:

```java
List<T>
```

means:

> I have a specific type parameter `T`.

while:

```java
List<?>
```

means:

> I don't know the type.

---

# 12. `? extends`

This is an **upper-bounded wildcard**.

```java
List<? extends Number>
```

means:

> A list of some unknown type that is `Number` or a subtype of `Number`.

Therefore:

```java
List<Integer>
List<Double>
List<Float>
```

can all match it.

Example:

```java
void printNumbers(List<? extends Number> numbers) {

    for (Number number : numbers) {
        System.out.println(number);
    }
}
```

You can safely **read** values as `Number`.

But you generally cannot add a `Number`:

```java
List<? extends Number> numbers = ...;

// numbers.add(10); // ❌
```

Why?

Because Java doesn't know whether the actual list is:

```java
List<Integer>
```

or:

```java
List<Double>
```

Adding an arbitrary `Number` could be unsafe.

---

# 13. `? super`

This is a **lower-bounded wildcard**.

```java
List<? super Integer>
```

means:

> A list of `Integer` or one of its supertypes.

Possible types:

```java
List<Integer>
List<Number>
List<Object>
```

You can safely add an `Integer`:

```java
List<? super Integer> numbers = new ArrayList<Number>();

numbers.add(10);
numbers.add(20);
```

Because every possible destination can hold an `Integer`.

But when reading:

```java
Object value = numbers.get(0);
```

The only thing Java can guarantee is `Object`.

---

# 14. The PECS Rule

This is one of the most useful rules for professional Java development:

> **PECS = Producer Extends, Consumer Super**

### Producer → `extends`

If you're primarily **reading/producing** values:

```java
List<? extends Number>
```

Think:

```text
Producer → extends
```

### Consumer → `super`

If you're primarily **putting/consuming** values:

```java
List<? super Integer>
```

Think:

```text
Consumer → super
```

Example:

```java
void copy(
    List<? super Integer> destination,
    List<? extends Integer> source
) {
    ...
}
```

The source **produces** integers:

```java
? extends Integer
```

The destination **consumes** integers:

```java
? super Integer
```

---

# 15. `T extends` vs `? extends`

This distinction is subtle and important.

### Type parameter

```java
<T extends Number>
```

You are **naming the type**.

You can use `T` repeatedly:

```java
<T extends Number>
T process(T value)
```

The same `T` represents the same type.

### Wildcard

```java
? extends Number
```

You are saying:

> There is some subtype of `Number`, but I don't care what its exact type is.

For example:

```java
void process(List<? extends Number> numbers)
```

You don't need to know whether it's:

```text
List<Integer>
List<Double>
List<Float>
```

---

# 16. Type Erasure

This is the part that explains a lot of Java's generic behavior.

Java generics are primarily a **compile-time feature**.

The compiler uses generic information to enforce type safety, but generic type information is largely removed from the runtime representation through **type erasure**.

For example:

```java
List<String> names = new ArrayList<>();
```

and:

```java
List<Integer> numbers = new ArrayList<>();
```

are different at compile time.

But at runtime, both are essentially:

```java
List
```

The JVM does not normally have separate runtime classes called:

```text
List<String>
List<Integer>
```

---

# 17. Why does Java use Type Erasure?

Mainly for **backward compatibility**.

Generics were introduced in Java 5.

Java already had enormous amounts of code using:

```java
List
```

without generics.

Type erasure allowed generic Java code to remain compatible with the older JVM/runtime model.

---

# 18. Consequences of Type Erasure

This is why you can't do:

```java
if (value instanceof List<String>) {
    ...
}
```

Java doesn't have that runtime information in the ordinary case.

Instead:

```java
if (value instanceof List<?>) {
    ...
}
```

is legal.

You also cannot normally do:

```java
T value = new T();
```

because the runtime doesn't know what concrete class `T` represents.

And you cannot create:

```java
T[] array = new T[10];
```

directly.

---

# 19. Generics Don't Work With Primitive Types

This is invalid:

```java
List<int> numbers;
```

Generics require reference types.

Use:

```java
List<Integer> numbers;
```

Java handles conversion through **autoboxing/unboxing**:

```java
List<Integer> numbers = new ArrayList<>();

numbers.add(10);       // int → Integer

int x = numbers.get(0); // Integer → int
```

---

# 20. The Big Picture

You should mentally organize Java generics like this:

```text
                         GENERICS
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
    Type Parameters      Wildcards        Type Erasure
          │                 │
          │          ┌──────┼──────┐
          │          │      │      │
       <T>           ?    ? extends ? super
          │
          └──────────────┐
                         │
                  Bounded Types
                         │
                    <T extends X>
```

And the practical meaning:

```text
<T>
 │
 └── "I am defining a type variable."

<T extends X>
 │
 └── "I am defining a type variable restricted to X."

?
 │
 └── "I don't care what the type is."

? extends X
 │
 └── "Some unknown subtype of X."
     → Producer / reading

? super X
 │
 └── "Some unknown supertype of X."
     → Consumer / writing
```

## The professional mental model

When you see:

```java
List<String>
```

think:

> **Concrete generic type**

When you see:

```java
<T>
```

think:

> **I am defining a reusable type variable.**

When you see:

```java
<T extends Number>
```

think:

> **I am defining a type variable with an upper bound.**

When you see:

```java
List<?>
```

think:

> **I don't care about the element type.**

When you see:

```java
List<? extends Number>
```

think:

> **I want to read Numbers from an unknown subtype.**

When you see:

```java
List<? super Integer>
```

think:

> **I want to put Integers into an unknown supertype container.**

And finally:

> **Generics give the compiler precise type information while keeping APIs reusable. Type erasure is what allows that generic source code to remain compatible with Java's runtime model.**


[[Java]]