
# `Function<T, R>` — Complete Definition

## Definition

**`Function<T, R>`** is a functional interface in `java.util.function` representing an operation that takes **one input** of type `T` and produces **one output** of type `R` — a transformation from one value into another.

```java
public interface Function<T, R> {
    R apply(T t);
}
```

```java
Function<String, Integer> length = str -> str.length();
System.out.println(length.apply("Alireza")); // 7
```

You met `Function` briefly in the earlier lambda types tutorial — this is the complete, standalone treatment.

---

## The problem it solves

Before functional interfaces, "transform this value into that value" either had to be inline logic or required a full method/class just to carry that transformation as something passable.

```java
// Without Function — the transformation logic is stuck inline, not reusable as a value
int len = someString.length();
```

```java
// With Function — the transformation itself becomes a reusable, passable VALUE
Function<String, Integer> getLength = str -> str.length();

int len1 = getLength.apply("Alireza"); // 7
int len2 = getLength.apply("Sara");     // 4
```

**The payoff:** a `Function` object can be stored, passed as an argument, returned from a method, or **chained together with other functions** — none of which a plain method call can do on its own.

---

## Core method

```java
R apply(T t)
```

The single abstract method — takes a value of type `T`, returns a value of type `R` (which can be the same type as `T`, or something entirely different).

```java
Function<String, String> shout = str -> str.toUpperCase() + "!";
System.out.println(shout.apply("hello")); // HELLO!

Function<String, Integer> parseIt = Integer::parseInt; // String → Integer
System.out.println(parseIt.apply("42")); // 42
```

---

## Where `Function` is actually used — `map()`

The most common real-world use, connecting directly to the Stream API tutorial:

```java
List<String> names = List.of("Alireza", "Sara", "Ali");

List<Integer> lengths = names.stream()
    .map(name -> name.length()) // this lambda IS a Function<String, Integer>
    .toList();

System.out.println(lengths); // [7, 4, 3]
```

`Stream.map()` takes exactly a `Function<T, R>`:

```java
<R> Stream<R> map(Function<? super T, ? extends R> mapper)
```

Also central to `Collectors.toMap()` (from the utility classes tutorial) and `Optional.map()` (from the same tutorial):

```java
Map<String, Integer> nameToLength = names.stream()
    .collect(Collectors.toMap(name -> name, name -> name.length())); // two Functions
```

```java
Optional<String> maybeName = Optional.of("Alireza");
Optional<Integer> maybeLength = maybeName.map(String::length); // Function<String, Integer>
```

---

## Creating a `Function` — the ways

### Lambda

```java
Function<Integer, Integer> square = n -> n * n;
```

### Method reference — all four kinds, from the earlier tutorial

```java
Function<String, Integer> length = String::length;         // arbitrary-object reference
Function<String, String> upper = String::toUpperCase;         // arbitrary-object reference
Function<String, Integer> parse = Integer::parseInt;            // static method reference
Function<String, StringBuilder> toBuilder = StringBuilder::new;   // constructor reference
```

### Anonymous class

```java
Function<Integer, Integer> square = new Function<Integer, Integer>() {
    @Override
    public Integer apply(Integer n) {
        return n * n;
    }
};
```

---

## Composing functions — default methods

This is `Function`'s most distinctive feature — built-in methods for **chaining transformations together**.

### `andThen(Function after)` — apply this, then apply the next one to the result

```java
Function<Integer, Integer> square = n -> n * n;
Function<Integer, Integer> addOne = n -> n + 1;

Function<Integer, Integer> squareThenAddOne = square.andThen(addOne);

System.out.println(squareThenAddOne.apply(3)); // (3*3) + 1 = 10
```

**Order:** `square.andThen(addOne)` means "run `square` first, then feed its result into `addOne`."

### `compose(Function before)` — apply the given one first, then apply this

```java
Function<Integer, Integer> square = n -> n * n;
Function<Integer, Integer> addOne = n -> n + 1;

Function<Integer, Integer> addOneThenSquare = square.compose(addOne);

System.out.println(addOneThenSquare.apply(3)); // (3+1)^2 = 16
```

**Order:** `square.compose(addOne)` means "run `addOne` first, then feed its result into `square`" — the **opposite** order from `andThen`. This reversed order is a genuinely common point of confusion — remember: `compose` runs the argument **before** the function it's called on; `andThen` runs the argument **after**.

### Chaining several transformations together

```java
Function<String, String> trim = String::trim;
Function<String, String> upper = String::toUpperCase;
Function<String, Integer> length = String::length;

Function<String, Integer> pipeline = trim.andThen(upper).andThen(length);

System.out.println(pipeline.apply("  hello  ")); // trims → "hello", uppercases → "HELLO", length → 5
```

**Real-world use:** building small, named, reusable transformation steps and composing them into a full pipeline — the exact same philosophy as `Predicate`'s `.and()`/`.or()` composition, applied to transformations instead of conditions.

### Static helper: `Function.identity()`

```java
Function<String, String> identity = Function.identity(); // returns input unchanged
System.out.println(identity.apply("hello")); // "hello"
```

**Where it's actually useful:** in `Collectors.toMap()`, when you want the element itself as the map's key:

```java
List<String> names = List.of("Alireza", "Sara");
Map<String, Integer> nameToLength = names.stream()
    .collect(Collectors.toMap(Function.identity(), String::length));
// {Alireza=7, Sara=4}
```

Without `Function.identity()`, you'd have to write `name -> name` — `identity()` just names that pattern explicitly.

---

## `BiFunction<T, U, R>` — the two-argument version

Already touched on in the lambda tutorial — a concrete example here:

```java
BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;
System.out.println(add.apply(3, 4)); // 7

BiFunction<String, Integer, String> repeat = (str, times) -> str.repeat(times);
System.out.println(repeat.apply("ab", 3)); // "ababab"
```

**`BiFunction` also has `andThen()`** (but no `compose()`, since composing "before" a two-argument function doesn't make unambiguous sense — which input would the composed function's result feed into?):

```java
BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;
Function<Integer, String> describe = sum -> "Sum is: " + sum;

BiFunction<Integer, Integer, String> addThenDescribe = add.andThen(describe);
System.out.println(addThenDescribe.apply(3, 4)); // "Sum is: 7"
```

---

## `UnaryOperator<T>` — `Function<T, T>` specialization

Covered briefly in the lambda types tutorial — restated with more detail here:

```java
public interface UnaryOperator<T> extends Function<T, T> {
    static <T> UnaryOperator<T> identity() { ... }
}
```

```java
UnaryOperator<Integer> square = n -> n * n; // input and output are the SAME type
System.out.println(square.apply(5)); // 25
```

**Why it exists as a separate type rather than just using `Function<T, T>` everywhere:** it communicates intent more precisely — "this transforms a value into _another value of the same type_" is clearer at a glance than a generic `Function<T, T>`, and it's used in places specifically expecting that same-type guarantee:

```java
List<Integer> numbers = new ArrayList<>(List.of(1, 2, 3, 4));
numbers.replaceAll(n -> n * 2); // List.replaceAll() specifically expects a UnaryOperator<E>
System.out.println(numbers); // [2, 4, 6, 8]
```

---

## Primitive specializations

Same motivation as `Predicate`'s primitive versions — avoiding boxing overhead for numeric processing:

```java
IntFunction<String> intToString = n -> "Number: " + n;
System.out.println(intToString.apply(5)); // "Number: 5"

ToIntFunction<String> stringToInt = String::length; // R is fixed as int, avoiding boxing on output
System.out.println(stringToInt.applyAsInt("hello")); // 5

IntUnaryOperator doubleIt = n -> n * 2; // int → int, no boxing at all
System.out.println(doubleIt.applyAsInt(5)); // 10
```

|Type|Shape|
|---|---|
|`IntFunction<R>`|`int` → `R`|
|`ToIntFunction<T>`|`T` → `int`|
|`IntUnaryOperator`|`int` → `int`|
|`IntBinaryOperator`|`(int, int)` → `int`|

(Same pattern repeats for `Long`/`Double`.)

---

## Summary table

|Aspect|Detail|
|---|---|
|Package|`java.util.function`|
|Abstract method|`R apply(T t)`|
|Shape|1 input, 1 output (can be different types)|
|Common use|`Stream.map()`, `Optional.map()`, `Collectors.toMap()`|
|Chain with|`.andThen()` (run after), `.compose()` (run before)|
|Static helper|`Function.identity()`|
|Two-argument version|`BiFunction<T, U, R>`|
|Same-type specialization|`UnaryOperator<T>` (used by `List.replaceAll()`)|
|Primitive versions|`IntFunction`, `ToIntFunction`, `IntUnaryOperator`, etc.|

## Where this fits with everything you've learned

`Function` is the exact functional interface behind `Stream.map()` — used constantly across the Stream API and Collections tutorials without always being named explicitly. Its `.andThen()`/`.compose()` methods mirror `Predicate`'s `.and()`/`.or()` philosophy directly: small, named, reusable pieces (transformations instead of conditions) combined into a pipeline — and `UnaryOperator`, in turn, is the exact type `List.replaceAll()` expects, connecting back to the `List` methods tutorial's transformation-in-place capability.


[[Java]]