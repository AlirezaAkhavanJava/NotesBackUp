


## The two categories, restated from the Streams tutorial

Every `Stream` method falls into one of two categories:

```
INTERMEDIATE  → returns another Stream, lazy, doesn't run until a terminal op is called
TERMINAL      → triggers actual execution, produces a final result (not a Stream)
```

This tutorial goes through every major method in both categories, one at a time.

---

# Part 1: Intermediate Operations (return a `Stream`)

## 1. `filter(Predicate<T>)`

Keeps only elements matching a condition. Covered in depth in the `Predicate` tutorial.

```java
List<Integer> evens = numbers.stream()
    .filter(n -> n % 2 == 0)
    .toList();
```

## 2. `map(Function<T, R>)`

Transforms each element into something else. Covered in depth in the `Function` tutorial.

```java
List<Integer> lengths = names.stream()
    .map(String::length)
    .toList();
```

## 3. `flatMap(Function<T, Stream<R>>)`

**Definition:** transforms each element into its **own stream**, then flattens all those streams into **one single stream**.

```java
List<List<Integer>> nested = List.of(
    List.of(1, 2, 3),
    List.of(4, 5),
    List.of(6, 7, 8, 9)
);

List<Integer> flat = nested.stream()
    .flatMap(list -> list.stream()) // each inner List becomes a Stream, then merged
    .toList();

System.out.println(flat); // [1, 2, 3, 4, 5, 6, 7, 8, 9]
```

**The problem it solves:** `map()` alone would give you a `Stream<Stream<Integer>>` — a stream of streams, which isn't usable directly (you'd need a nested loop to unwrap it). `flatMap()` collapses that one extra level of nesting automatically.

```java
// map() alone — WRONG shape, gives Stream<List<Integer>>, not what you want
Stream<List<Integer>> wrong = nested.stream().map(list -> list);

// flatMap() — correctly merges into ONE flat Stream<Integer>
Stream<Integer> correct = nested.stream().flatMap(List::stream);
```

**Common real-world use:** splitting strings into words across many lines, extracting all orders from a list of customers, any "list of lists" → "single flat list" scenario.

```java
List<String> sentences = List.of("Hello world", "Java is fun");

List<String> words = sentences.stream()
    .flatMap(sentence -> Arrays.stream(sentence.split(" ")))
    .toList();

System.out.println(words); // [Hello, world, Java, is, fun]
```

## 4. `distinct()`

**Definition:** removes duplicate elements, using `.equals()` for comparison — conceptually turning the stream into something like a `Set` (from the last several tutorials) temporarily.

```java
List<Integer> nums = List.of(1, 2, 2, 3, 3, 3, 4);
List<Integer> unique = nums.stream().distinct().toList();
System.out.println(unique); // [1, 2, 3, 4]
```

## 5. `sorted()` / `sorted(Comparator<T>)`

**Definition:** sorts the stream's elements — natural order (requires `Comparable`) or a custom `Comparator` (covered in the utility classes tutorial).

```java
List<Integer> sorted = List.of(5, 3, 8, 1).stream().sorted().toList();
System.out.println(sorted); // [1, 3, 5, 8]

List<String> byLength = List.of("ccc", "a", "bb").stream()
    .sorted(Comparator.comparing(String::length))
    .toList();
System.out.println(byLength); // [a, bb, ccc]
```

## 6. `peek(Consumer<T>)`

**Definition:** performs an action on each element **without changing the stream** — passes each element through unchanged, purely for side effects (typically debugging).

```java
List<Integer> result = numbers.stream()
    .peek(n -> System.out.println("Before filter: " + n))
    .filter(n -> n % 2 == 0)
    .peek(n -> System.out.println("After filter: " + n))
    .toList();
```

**Important caveat:** `peek()` is intended primarily for **debugging** — using it for real application logic (mutating external state) is discouraged, since intermediate operations are lazy and might not even execute in the order or frequency you expect if the pipeline is optimized or short-circuited.

## 7. `limit(long n)`

**Definition:** truncates the stream to at most `n` elements.

```java
List<Integer> firstThree = Stream.of(1, 2, 3, 4, 5).limit(3).toList();
System.out.println(firstThree); // [1, 2, 3]
```

**Real-world use:** pagination, "top N" results, capping an otherwise infinite stream (see `Stream.iterate()` below).

## 8. `skip(long n)`

**Definition:** discards the first `n` elements, keeping the rest.

```java
List<Integer> afterFirstTwo = Stream.of(1, 2, 3, 4, 5).skip(2).toList();
System.out.println(afterFirstTwo); // [3, 4, 5]
```

**Real-world use:** `skip()` + `limit()` together implement pagination directly:

```java
int page = 2, pageSize = 3;
List<Integer> pageResults = Stream.of(1,2,3,4,5,6,7,8,9)
    .skip((long) page * pageSize)
    .limit(pageSize)
    .toList();
```

## 9. `takeWhile(Predicate<T>)` (Java 9+)

**Definition:** takes elements from the start of the stream **only while** the condition holds true, stopping entirely at the first element that fails it (even if later elements would pass).

```java
List<Integer> nums = List.of(1, 2, 3, 8, 4, 5);
List<Integer> result = nums.stream()
    .takeWhile(n -> n < 5)
    .toList();
System.out.println(result); // [1, 2, 3] — stops at 8, even though 4 and 5 are also < 5
```

**Difference from `filter()`:** `filter()` checks _every_ element independently; `takeWhile()` stops as soon as the condition first fails, ignoring everything after — genuinely different semantics, useful for sorted/ordered data where you want "everything up until this point."

## 10. `dropWhile(Predicate<T>)` (Java 9+)

**Definition:** the mirror image — **skips** elements from the start while the condition holds, then keeps everything from the first failure onward.

```java
List<Integer> nums = List.of(1, 2, 3, 8, 4, 5);
List<Integer> result = nums.stream()
    .dropWhile(n -> n < 5)
    .toList();
System.out.println(result); // [8, 4, 5] — drops 1,2,3, then keeps everything else once condition fails
```

---

# Part 2: Terminal Operations (produce a final result)

## 1. `forEach(Consumer<T>)`

**Definition:** applies an action to every element. Doesn't return anything.

```java
names.stream().forEach(System.out::println);
```

**Note:** for a simple `List`, you'd typically just use `list.forEach(...)` directly (from the `Collection` interface, covered in the `List` tutorial) rather than going through `.stream()` first — `stream().forEach()` matters when it's the end of a longer pipeline (after `filter`/`map`, etc.).

## 2. `collect(Collector)`

**Definition:** gathers stream elements into a collection or other structure, using a `Collector` (from `Collectors`, covered in the utility classes tutorial).

```java
List<String> list = stream.collect(Collectors.toList());
Set<String> set = stream.collect(Collectors.toSet());
Map<String, Integer> map = stream.collect(Collectors.toMap(s -> s, String::length));
String joined = stream.collect(Collectors.joining(", "));
Map<Integer, List<String>> grouped = stream.collect(Collectors.groupingBy(String::length));
```

## 3. `toList()` (Java 16+)

**Definition:** a shortcut for the extremely common `collect(Collectors.toList())`, returning an **immutable** list.

```java
List<String> list = stream.toList(); // shorter than collect(Collectors.toList())
```

## 4. `reduce(...)`

Covered in full in the last tutorial — combines all elements into a single value.

```java
int sum = numbers.stream().reduce(0, Integer::sum);
```

## 5. `count()`

**Definition:** returns the number of elements in the stream, as a `long`.

```java
long count = numbers.stream().filter(n -> n > 3).count();
```

## 6. `sum()` / `average()` / `max()` / `min()` — on primitive streams

**Definition:** aggregate numeric operations, available on `IntStream`/`LongStream`/`DoubleStream` (the primitive-specialized streams from the Java API reference tutorial), not on plain `Stream<Integer>`.

```java
int total = numbers.stream().mapToInt(Integer::intValue).sum();
OptionalDouble avg = numbers.stream().mapToInt(Integer::intValue).average().getAsDouble();
```

```java
Optional<Integer> max = numbers.stream().max(Comparator.naturalOrder()); // available on regular Stream too, with a Comparator
Optional<Integer> min = numbers.stream().min(Comparator.naturalOrder());
```

## 7. `anyMatch(Predicate<T>)` / `allMatch(Predicate<T>)` / `noneMatch(Predicate<T>)`

**Definition:** boolean checks against a condition, using `Predicate` (covered in the `Predicate` tutorial). **Short-circuiting** — they stop as soon as the answer is determined, without processing the rest of the stream.

```java
boolean hasNegative = numbers.stream().anyMatch(n -> n < 0);   // stops at first match found
boolean allPositive = numbers.stream().allMatch(n -> n > 0);     // stops at first NON-match found
boolean noneNegative = numbers.stream().noneMatch(n -> n < 0);     // stops at first match found (which disproves it)
```

## 8. `findFirst()` / `findAny()`

**Definition:** returns the first element (or _any_ element, useful in parallel streams) as an `Optional<T>` (from the `Optional` tutorial) — empty if the stream has no elements.

```java
Optional<Integer> first = numbers.stream().filter(n -> n > 3).findFirst();
Optional<Integer> any = numbers.parallelStream().filter(n -> n > 3).findAny(); // may be faster in parallel — order doesn't matter
```

**Difference:** `findFirst()` guarantees the actual first matching element in encounter order; `findAny()` makes no such guarantee, which lets it terminate faster on a parallel stream (from the parallelism tutorial) since it doesn't need to coordinate "which one came first" across threads.

## 9. `toArray()`

**Definition:** collects the stream into an array.

```java
Integer[] array = numbers.stream().toArray(Integer[]::new); // using a constructor reference, from the method reference tutorial
```

## 10. `min(Comparator)` / `max(Comparator)`

Already shown above — worth noting explicitly they take a `Comparator`, unlike the primitive-stream `sum()`/`average()` which need no comparator since numeric ordering is implicit.

---

# Part 3: Stream Creation Methods

## `Stream.of(...)`

```java
Stream<String> stream = Stream.of("a", "b", "c");
```

## `Collection.stream()`

```java
Stream<String> stream = List.of("a", "b").stream(); // the most common way — from an existing collection
```

## `Stream.empty()`

```java
Stream<String> empty = Stream.empty(); // useful as a safe default/fallback value
```

## `Stream.generate(Supplier<T>)`

**Definition:** creates an **infinite** stream, where each element is produced by calling a `Supplier<T>` (from the earlier lambda tutorial) repeatedly.

```java
Stream<Double> randoms = Stream.generate(Math::random);
List<Double> fiveRandoms = randoms.limit(5).toList(); // MUST use limit() — otherwise infinite!
```

**Why `limit()` is mandatory here:** without it, this stream would try to generate values forever, and any terminal operation (`toList()`, `forEach()`) would simply never finish.

## `Stream.iterate(seed, UnaryOperator<T>)`

**Definition:** creates an infinite stream by repeatedly applying a function to the previous result — starting from a seed value. Uses `UnaryOperator<T>` (from the `Function` tutorial).

```java
Stream<Integer> powersOfTwo = Stream.iterate(1, n -> n * 2);
List<Integer> firstFive = powersOfTwo.limit(5).toList();
System.out.println(firstFive); // [1, 2, 4, 8, 16]
```

**Java 9+ overload with a `Predicate` stopping condition — avoids needing `limit()`:**

```java
Stream<Integer> upToHundred = Stream.iterate(1, n -> n < 100, n -> n * 2);
System.out.println(upToHundred.toList()); // [1, 2, 4, 8, 16, 32, 64]
```

## `IntStream.range(start, end)` / `IntStream.rangeClosed(start, end)`

**Definition:** generates a sequential range of `int` values — `range` excludes the end, `rangeClosed` includes it.

```java
IntStream.range(1, 5).forEach(System.out::println);        // 1, 2, 3, 4
IntStream.rangeClosed(1, 5).forEach(System.out::println);    // 1, 2, 3, 4, 5
```

## `Files.lines(Path)` (from the I/O tutorials)

```java
try (Stream<String> lines = Files.lines(Path.of("data.txt"))) {
    lines.forEach(System.out::println);
}
```

---

## Complete method reference table

|Method|Type|Returns|Definition|
|---|---|---|---|
|`filter(Predicate)`|intermediate|`Stream<T>`|keep matching elements|
|`map(Function)`|intermediate|`Stream<R>`|transform each element|
|`flatMap(Function)`|intermediate|`Stream<R>`|transform + flatten nested streams|
|`distinct()`|intermediate|`Stream<T>`|remove duplicates|
|`sorted()` / `sorted(Comparator)`|intermediate|`Stream<T>`|sort elements|
|`peek(Consumer)`|intermediate|`Stream<T>`|side-effect action, unchanged stream|
|`limit(n)`|intermediate|`Stream<T>`|keep first n elements|
|`skip(n)`|intermediate|`Stream<T>`|discard first n elements|
|`takeWhile(Predicate)`|intermediate|`Stream<T>`|take until first failure|
|`dropWhile(Predicate)`|intermediate|`Stream<T>`|drop until first failure, keep rest|
|`forEach(Consumer)`|terminal|`void`|apply action to each element|
|`collect(Collector)`|terminal|varies|gather into a collection/structure|
|`toList()`|terminal|`List<T>`|shortcut for `collect(toList())`|
|`reduce(...)`|terminal|`T`/`Optional<T>`|combine into a single value|
|`count()`|terminal|`long`|number of elements|
|`sum()`/`average()` (primitive streams)|terminal|`int`/`double`/etc.|numeric aggregation|
|`max(Comparator)`/`min(Comparator)`|terminal|`Optional<T>`|largest/smallest element|
|`anyMatch`/`allMatch`/`noneMatch(Predicate)`|terminal|`boolean`|condition check, short-circuiting|
|`findFirst()`/`findAny()`|terminal|`Optional<T>`|get one element|
|`toArray()`|terminal|`T[]`|collect into an array|

---

## Where this fits with everything you've learned

Nearly every method here is built directly on functional interfaces you've already learned by name — `filter`/`anyMatch`/`takeWhile` use `Predicate`, `map`/`flatMap` use `Function`, `forEach`/`peek` use `Consumer`, `reduce` uses `BinaryOperator`/`BiFunction`, and `sorted` uses `Comparator`. This method reference is really the "assembly manual" showing exactly where all those individually-learned pieces (lambdas, method references, functional interfaces, `Optional`, `Collectors`) come together into the single cohesive tool the Stream API tutorial first introduced.


[[Java]]