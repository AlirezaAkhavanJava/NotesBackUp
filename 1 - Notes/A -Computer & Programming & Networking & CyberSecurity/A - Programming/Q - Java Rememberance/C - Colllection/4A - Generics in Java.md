


## Definition

**Generics** let you write classes, interfaces, and methods that operate on a **type you specify later**, rather than hardcoding a specific type — represented with angle brackets `<T>`. You've already used generics constantly throughout this whole conversation (`List<String>`, `Map<K,V>`, `Optional<T>`) without a formal definition — this is that definition.

```java
List<String> names = new ArrayList<>();  // <String> is the generic type parameter
List<Integer> numbers = new ArrayList<>(); // same class, different type plugged in
```

`ArrayList` itself isn't written to hold `String`s or `Integer`s specifically — it's written **once**, generically, to hold "some type `T`," and you decide what `T` is each time you use it.

---

## The problem generics solve

### Before generics (pre-Java 5) — collections held plain `Object`

```java
List list = new ArrayList(); // no type specified — holds Object
list.add("Alireza");
list.add(42); // whoops — an int got added too, no error at all

String name = (String) list.get(0); // manual cast required, every time
String oops = (String) list.get(1);  // ClassCastException — RUNTIME crash, not caught at compile time!
```

Two real problems here:

1. **No compile-time type safety.** Nothing stopped you from adding an `Integer` into a list "meant" for `String`s — the mistake only surfaces later, at runtime, often far from where the actual bug was introduced.
2. **Manual casting everywhere.** Since the list only knows about `Object`, you must cast every single time you retrieve something — verbose, and itself a source of `ClassCastException` if you cast wrong.

### With generics — the compiler catches the mistake immediately

```java
List<String> list = new ArrayList<>();
list.add("Alireza");
list.add(42); // COMPILE ERROR — caught immediately, not at runtime

String name = list.get(0); // no cast needed — compiler already knows it's a String
```

**Generics solve both problems at once:** the compiler enforces that only the declared type goes in, and automatically inserts the correct cast for you when retrieving — this is called **type safety** plus **elimination of manual casting**.

---

## How generics work — the mechanism

### Generic classes

```java
class Box<T> {
    private T content;

    public void set(T content) { this.content = content; }
    public T get() { return content; }
}
```

`T` is a **type parameter** — a placeholder standing in for whatever real type gets plugged in when the class is used.

```java
Box<String> stringBox = new Box<>();
stringBox.set("Hello");
String value = stringBox.get(); // no cast needed

Box<Integer> intBox = new Box<>();
intBox.set(42);
// intBox.set("wrong type"); // COMPILE ERROR
```

**One class definition, used safely for any type** — this is the entire value proposition. Without generics, you'd need a separate `StringBox`, `IntegerBox`, `UserBox`, etc., each duplicating identical logic.

### Generic methods

A method can introduce its own type parameter, independent of the class it's in:

```java
class Utils {
    static <T> T firstElement(List<T> list) {
        return list.get(0);
    }
}

String first = Utils.firstElement(List.of("a", "b", "c")); // T inferred as String
Integer firstNum = Utils.firstElement(List.of(1, 2, 3));    // T inferred as Integer
```

The `<T>` right before the return type declares this method's own type parameter — the compiler **infers** what `T` actually is from the argument you pass, so you rarely need to specify it explicitly.

### Generic interfaces

You've already used several of these throughout this conversation:

```java
public interface Comparable<T> {
    int compareTo(T o);
}

public interface List<E> extends Collection<E> { ... }

public interface Function<T, R> {
    R apply(T t);
}
```

`Comparable<T>`, `List<E>`, `Function<T, R>` — all generic interfaces, all following the exact same pattern you now understand.

---

## Multiple type parameters

```java
class Pair<K, V> {
    private K key;
    private V value;

    public Pair(K key, V value) {
        this.key = key;
        this.value = value;
    }

    public K getKey() { return key; }
    public V getValue() { return value; }
}

Pair<String, Integer> entry = new Pair<>("Alireza", 25);
System.out.println(entry.getKey() + " is " + entry.getValue());
```

This is exactly how `Map<K, V>` is defined — two independent type parameters, one for keys, one for values.

---

## Bounded type parameters — restricting what `T` can be

Sometimes you don't want `T` to be _any_ type — you want it restricted to types that support certain operations.

```java
class NumberBox<T extends Number> { // T must be Number or a subclass (Integer, Double, etc.)
    private T value;

    public NumberBox(T value) { this.value = value; }

    public double doubled() {
        return value.doubleValue() * 2; // safe — Number guarantees doubleValue() exists
    }
}

NumberBox<Integer> box = new NumberBox<>(5);   // OK — Integer extends Number
NumberBox<String> bad = new NumberBox<>("x");   // COMPILE ERROR — String is not a Number
```

**Why this matters:** without the bound (`extends Number`), the compiler would only know `T` is "some type" — it couldn't assume `.doubleValue()` exists, since a plain `T` could be anything, including a type with no such method. `extends Number` tells the compiler exactly what capabilities `T` is guaranteed to have.

```java
<T extends Comparable<T>> T max(T a, T b) {
    return a.compareTo(b) > 0 ? a : b; // safe — Comparable<T> guarantees compareTo() exists
}
```

---

## Wildcards — `?`, `? extends`, `? super`

Wildcards handle situations where you don't need to name the exact type, just describe a relationship.

### `?` — unbounded wildcard ("some unknown type")

```java
void printAll(List<?> list) { // accepts a List of ANY type
    for (Object item : list) {
        System.out.println(item);
    }
}

printAll(List.of("a", "b"));   // works
printAll(List.of(1, 2, 3));     // also works
```

**Use when:** you only need to _read_ elements generically (as `Object`), not care about the specific type.

### `? extends T` — upper-bounded wildcard ("T or any subtype")

```java
double sumAll(List<? extends Number> list) { // accepts List<Integer>, List<Double>, etc.
    double sum = 0;
    for (Number n : list) {
        sum += n.doubleValue();
    }
    return sum;
}

sumAll(List.of(1, 2, 3));        // List<Integer> — works
sumAll(List.of(1.5, 2.5));        // List<Double> — also works
```

**Use when:** you're only **reading** from the collection (producing values out of it) — hence the mnemonic "PECS: Producer `extends`."

### `? super T` — lower-bounded wildcard ("T or any supertype")

```java
void addNumbers(List<? super Integer> list) { // accepts List<Integer>, List<Number>, List<Object>
    list.add(1);
    list.add(2);
}

List<Number> numbers = new ArrayList<>();
addNumbers(numbers); // works — Number is a supertype of Integer
```

**Use when:** you're only **writing** into the collection (consuming values into it) — "PECS: Consumer `super`."

**PECS mnemonic:** "**P**roducer **E**xtends, **C**onsumer **S**uper" — if a generic parameter only gives you values out (produces), use `extends`; if you only put values in (consumes), use `super`.

---

## Type erasure — how generics actually work at runtime (an important detail)

This is genuinely important to understand, because it explains several otherwise-confusing Java behaviors:

```java
List<String> strings = new ArrayList<>();
List<Integer> ints = new ArrayList<>();

System.out.println(strings.getClass() == ints.getClass()); // true !!
```

**Java's generics are implemented via "type erasure"** — generic type information (`<String>`, `<Integer>`) exists **only at compile time**, for the compiler to check your code. At runtime, the compiled bytecode has that information **erased** — `List<String>` and `List<Integer>` become the exact same raw `List` class in the actual running JVM.

**Why Java did this:** to maintain backward compatibility with pre-Java 5 code (which used raw, untyped collections) without needing a totally separate runtime representation.

**Consequences of type erasure:**

```java
// You CANNOT do this — no runtime type info to check against
if (list instanceof List<String>) { } // COMPILE ERROR

// You CANNOT create a generic array directly
T[] array = new T[10]; // COMPILE ERROR — T is erased, JVM doesn't know what array type to make

// You CANNOT have overloads that differ only by generic type
void process(List<String> list) { }
void process(List<Integer> list) { } // COMPILE ERROR — same erased signature: process(List)
```

These are genuine, well-known Java quirks — knowing about type erasure is _why_ they happen, rather than them seeming like arbitrary limitations.

---

## Generics with your own custom classes — a complete example

```java
class Stack<T> {
    private List<T> elements = new ArrayList<>();

    public void push(T item) {
        elements.add(item);
    }

    public T pop() {
        if (elements.isEmpty()) {
            throw new IllegalStateException("Stack is empty");
        }
        return elements.remove(elements.size() - 1);
    }

    public boolean isEmpty() {
        return elements.isEmpty();
    }
}

Stack<String> stack = new Stack<>();
stack.push("first");
stack.push("second");
System.out.println(stack.pop()); // "second" — no cast needed, type-safe
```

This is a genuinely realistic example — you've built exactly this kind of structure conceptually in the stack/queue tutorial; this shows how you'd implement your own version generically, so it works for any type without duplicating code.

---

## Where generics show up across everything you've already learned

|Where|Example|
|---|---|
|Collections|`List<E>`, `Map<K,V>`, `Set<E>` — every collection class is generic|
|Functional interfaces|`Function<T,R>`, `Consumer<T>`, `Supplier<T>`, `Predicate<T>`|
|`Optional`|`Optional<T>`|
|`Comparable`/`Comparator`|`Comparable<T>`, `Comparator<T>`|
|Concurrency|`Future<V>`, `Callable<V>`, `CompletableFuture<T>`, `AtomicReference<V>`|
|Streams|`Stream<T>`, `Collectors.toList()` returning `List<T>`|

Every one of these types you've already used across this entire conversation is a generic class or interface — generics are the reason `List<String>.get()` returns a `String` directly, `Function<T,R>.apply()` is type-checked at compile time, and `Optional<User>.get()` gives you a `User` without casting.

---

## Summary

|Concept|Definition|
|---|---|
|**Generics**|writing code that works with a type specified later, via `<T>`|
|**Type parameter** (`T`, `E`, `K`, `V`, `R`)|placeholder for a real type, filled in at usage|
|**Type safety**|compiler catches wrong-type mistakes at compile time, not runtime|
|**Bounded type** (`T extends X`)|restricts `T` to a specific type or its subtypes|
|**Wildcard `?`**|represents an unknown type, for flexible method parameters|
|**`? extends T`**|upper bound — for reading/producing values|
|**`? super T`**|lower bound — for writing/consuming values|
|**Type erasure**|generic type info exists only at compile time; erased in the compiled bytecode|

## Why this matters practically

Generics are the reason the entire Collections Framework hierarchy you just mapped out can be written **once** per data structure, yet used safely for any type — `ArrayList<T>` is a single, real class in the JDK source code, and `List<String>`/`List<Integer>`/`List<User>` are all just that same class with different type parameters plugged in. This is also directly relevant heading into Spring Boot: you'll constantly see generic types in method signatures (`ResponseEntity<User>`, `List<Order>`, `Optional<Product>`, `JpaRepository<User, Long>`) — understanding generics is what makes those signatures actually meaningful rather than just syntax to memorize.


[[Java]]