


A **lambda expression** is a short block of code you can pass around like a value — essentially an anonymous function. Java lambdas map to **functional interfaces** (interfaces with exactly one abstract method). The "type" of a lambda is really about _how many parameters it takes and what it returns_ — which determines which functional interface it fits.

---

## The problem lambdas solve, in general

Before Java 8, if you wanted to pass "a piece of behavior" (not just data) into a method, you had to create a whole anonymous class:

```java
// Before lambdas — verbose
Runnable r = new Runnable() {
    @Override
    public void run() {
        System.out.println("Running");
    }
};
```

That's a lot of boilerplate for "just run this one line." Lambdas let you write the same thing as:

```java
Runnable r = () -> System.out.println("Running");
```

Lambdas exist to make passing behavior around **short, readable, and inline** — instead of manufacturing a whole class just to carry one method.

---

## 1. No-argument, no return value — `Runnable`

**Shape:** takes nothing, returns nothing.

```java
Runnable task = () -> System.out.println("Task running");
task.run();
```

**Problem it solves:** You need to pass "just do this action" with no input and no output — e.g., a task to run on a thread, or a callback with no data involved.

---

## 2. Consumer — takes an argument, returns nothing

**Shape:** takes 1 input, returns nothing (it _consumes_ the value).

```java
Consumer<String> printer = name -> System.out.println("Hello, " + name);
printer.accept("Alireza");
```

**Problem it solves:** You have data and want to _do something with it_ (print it, save it, log it) without needing a result back. Common in `forEach`:

```java
List<String> names = List.of("Alireza", "Sara");
names.forEach(name -> System.out.println(name));
```

---

## 3. Supplier — takes nothing, returns a value

**Shape:** takes 0 inputs, returns 1 output (it _supplies_ a value).

```java
Supplier<String> greeting = () -> "Hello there!";
System.out.println(greeting.get());
```

**Problem it solves:** You want to **delay/defer creating a value** until it's actually needed (lazy evaluation), instead of computing it upfront every time.

```java
// Only builds the expensive message if logging is actually enabled
logger.debug(() -> "Expensive computation result: " + computeSomething());
```

---

## 4. Function — takes an argument, returns a value

**Shape:** takes 1 input, returns 1 output (transforms input → output).

```java
Function<String, Integer> length = str -> str.length();
System.out.println(length.apply("Alireza")); // 7
```

**Problem it solves:** You need to **transform** one type of data into another — the most common lambda shape, used heavily in streams:

```java
List<String> names = List.of("Alireza", "Sara");
List<Integer> lengths = names.stream()
    .map(name -> name.length())   // Function<String, Integer>
    .toList();
```

---

## 5. Predicate — takes an argument, returns a boolean

**Shape:** takes 1 input, returns `true`/`false` (a yes/no test).

```java
Predicate<Integer> isEven = num -> num % 2 == 0;
System.out.println(isEven.test(4)); // true
```

**Problem it solves:** You need to **filter or test** data against a condition, without writing a full `if` block every time — used constantly in `filter`:

```java
List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6);
List<Integer> evens = numbers.stream()
    .filter(num -> num % 2 == 0)  // Predicate<Integer>
    .toList();
```

---

## 6. BiFunction / BiConsumer / BiPredicate — two-argument versions

**Shape:** same as above, but take **2 inputs** instead of 1.

```java
BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;
System.out.println(add.apply(3, 4)); // 7

BiConsumer<String, Integer> printPair = (name, age) -> 
    System.out.println(name + " is " + age);
printPair.accept("Alireza", 25);
```

**Problem it solves:** Sometimes one input isn't enough — you need to combine, compare, or act on **two** related pieces of data at once (e.g., a map's key and value):

```java
Map<String, Integer> ages = Map.of("Alireza", 25, "Sara", 30);
ages.forEach((name, age) -> System.out.println(name + ": " + age)); // BiConsumer
```

---

## 7. UnaryOperator / BinaryOperator — input and output are the _same_ type

**Shape:** special case of `Function`/`BiFunction` where input type == output type.

```java
UnaryOperator<Integer> square = num -> num * num;
System.out.println(square.apply(5)); // 25

BinaryOperator<Integer> multiply = (a, b) -> a * b;
System.out.println(multiply.apply(3, 4)); // 12
```

**Problem it solves:** `Function<Integer, Integer>` works, but `UnaryOperator<Integer>` says the same thing more precisely — "this transforms a value into _another value of the same type_." Common in `reduce`:

```java
List<Integer> numbers = List.of(1, 2, 3, 4);
int product = numbers.stream()
    .reduce(1, (a, b) -> a * b); // BinaryOperator<Integer>
```

---

## Quick reference table

|Interface|Input|Output|Solves the problem of...|
|---|---|---|---|
|`Runnable`|none|none|"just do this action"|
|`Consumer<T>`|1|none|"do something with this value"|
|`Supplier<T>`|none|1|"give me a value, lazily"|
|`Function<T,R>`|1|1|"transform this into that"|
|`Predicate<T>`|1|boolean|"test/filter this value"|
|`BiFunction<T,U,R>`|2|1|"combine two values into one"|
|`BiConsumer<T,U>`|2|none|"act on a key/value pair"|
|`UnaryOperator<T>`|1 (same type)|same type|"transform within the same type"|
|`BinaryOperator<T>`|2 (same type)|same type|"combine two of the same type"|

---

## How to choose the right one

Ask yourself two questions:

1. **How many inputs does my lambda need?** → 0 (`Supplier`/`Runnable`), 1 (`Consumer`/`Function`/`Predicate`), or 2 (`Bi*`)
2. **What does it return?** → nothing (`Consumer`/`Runnable`), a boolean (`Predicate`), or a value (`Function`/`Supplier`)

That combination tells you exactly which functional interface — and therefore which "type" of lambda — fits your use case.

[[Java]]