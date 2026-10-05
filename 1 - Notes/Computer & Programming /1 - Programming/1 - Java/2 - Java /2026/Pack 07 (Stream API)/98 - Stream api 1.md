
# Java Stream API — Complete In-Depth Guide

---

## 1. What Is the Java Stream API?

### Definition

The **Java Stream API** (introduced in Java 8, `java.util.stream`) is a functional-style API for processing sequences of elements. A `Stream<T>` is **not a data structure** — it is a **view** over a source (collection, array, I/O channel, generator function, etc.) that supports **declarative**, **lazy**, and potentially **parallel** operations.

### Core Characteristics

| Characteristic | Meaning |
|---|---|
| **Declarative** | You say *what* to do, not *how* to loop. |
| **Lazy** | Intermediate operations are not executed until a terminal operation is invoked. |
| **Single-use** | A stream can be consumed only once. Reusing throws `IllegalStateException`. |
| **Non-mutating** | Streams do not modify the source; they produce new results. |
| **Possibly unbounded** | Streams can be infinite (e.g., `Stream.iterate`, `Stream.generate`). |
| **Possibly parallel** | `.parallel()` enables multi-threaded processing via Fork/Join. |
| **Composable** | Operations chain into a pipeline. |

### Stream vs Collection

| Collection | Stream |
|---|---|
| Stores data | Does not store data |
| Can be traversed many times | Single-use |
| Eager | Lazy |
| External iteration (`for`, `while`) | Internal iteration (`forEach`, `reduce`) |
| Focus on data | Focus on computation |

### Pipeline Anatomy

```
Source  →  Intermediate Ops (lazy)  →  Terminal Op (eager)
List    →  filter → map → sorted    →  collect
```

---

## 2. Types of Streams

### By element type

| Type | Description |
|---|---|
| `Stream<T>` | Reference-type stream (objects). |
| `IntStream` | Primitive `int` stream — avoids boxing. |
| `LongStream` | Primitive `long` stream. |
| `DoubleStream` | Primitive `double` stream. |

> There is **no** `Stream<byte>`, `Stream<short>`, `Stream<char>`, `Stream<float>`, or `Stream<boolean>` — those box to their wrapper types.

### By execution mode

| Type | Description |
|---|---|
| **Sequential stream** | Default. Operations run on the calling thread. |
| **Parallel stream** | Splits work across `ForkJoinPool.commonPool()`. Enabled by `.parallel()` or `collection.parallelStream()`. |

### By source

- Collection streams (`list.stream()`)
- Array streams (`Arrays.stream(arr)`)
- I/O streams (`Files.lines(path)`, `BufferedReader.lines()`)
- Generator streams (`Stream.generate`, `Stream.iterate`)
- Builder streams (`Stream.builder()`)
- Range streams (`IntStream.range`, `IntStream.rangeClosed`)
- Random streams (`Random.ints()`, `Random.doubles()`)
- Regex streams (`Pattern.splitAsStream()`)

---

## 3. Creating Streams

```java
// From a collection
List<String> list = List.of("a", "b", "c");
Stream<String> s1 = list.stream();
Stream<String> s2 = list.parallelStream();

// From an array
int[] nums = {1, 2, 3};
IntStream s3 = Arrays.stream(nums);
Stream<String> s4 = Stream.of("x", "y", "z");

// Empty & singleton
Stream<String> empty = Stream.empty();
Stream<String> single = Stream.of("one");

// Infinite — generate (supplier)
Stream<Double> randoms = Stream.generate(Math::random).limit(5);

// Infinite — iterate (seed + unary operator)
Stream<Integer> evens = Stream.iterate(0, n -> n + 2).limit(10);

// Java 9+ iterate with predicate
Stream<Integer> until100 = Stream.iterate(0, n -> n < 100, n -> n + 2);

// Ranges
IntStream.range(1, 5);        // 1,2,3,4
IntStream.rangeClosed(1, 5);  // 1,2,3,4,5

// Builder
Stream<String> built = Stream.<String>builder().add("a").add("b").build();

// From files
try (Stream<String> lines = Files.lines(Path.of("file.txt"))) { ... }

// From regex
Pattern.compile(",").splitAsStream("a,b,c");

// From Random
new Random().ints(5, 1, 100); // 5 ints between 1 and 99
```

---

## 4. Intermediate Operations (Lazy)

Intermediate operations return a **new stream**. They do nothing until a terminal operation runs.

### 4.1 `filter(Predicate<T>)`

**Definition:** Keeps elements matching the predicate.

```java
List<Integer> evens = Stream.of(1,2,3,4,5,6)
    .filter(n -> n % 2 == 0)
    .collect(Collectors.toList()); // [2,4,6]
```

### 4.2 `map(Function<T,R>)`

**Definition:** Transforms each element via a function.

```java
List<Integer> lengths = Stream.of("apple","fig","banana")
    .map(String::length)
    .collect(Collectors.toList()); // [5,3,6]
```

### 4.3 `mapToInt` / `mapToLong` / `mapToDouble`

**Definition:** Map to primitive streams (avoids boxing, enables `sum()`, `average()`, etc.).

```java
int total = Stream.of("a","bb","ccc")
    .mapToInt(String::length)
    .sum(); // 6
```

### 4.4 `flatMap(Function<T, Stream<R>>)`

**Definition:** Maps each element to a stream and flattens the result.

```java
List<String> words = List.of("Hello World", "Java Streams");
List<String> tokens = words.stream()
    .flatMap(w -> Arrays.stream(w.split(" ")))
    .collect(Collectors.toList()); // [Hello, World, Java, Streams]
```

### 4.5 `flatMapToInt` / `flatMapToLong` / `flatMapToDouble`

```java
IntStream ints = Stream.of("1 2", "3 4")
    .flatMapToInt(s -> Arrays.stream(s.split(" ")).mapToInt(Integer::parseInt));
// 1,2,3,4
```

### 4.6 `distinct()`

**Definition:** Removes duplicates using `equals`/`hashCode`.

```java
Stream.of(1,2,2,3,3,3).distinct().toList(); // [1,2,3]
```

### 4.7 `sorted()` and `sorted(Comparator)`

**Definition:** Returns a sorted stream (natural or custom order). **Stateful** — buffers all elements.

```java
Stream.of(3,1,2).sorted().toList(); // [1,2,3]

Stream.of("bb","a","ccc")
    .sorted(Comparator.comparingInt(String::length))
    .toList(); // [a, bb, ccc]
```

### 4.8 `peek(Consumer<T>)`

**Definition:** Performs an action on each element as it flows through. Mainly for **debugging**.

```java
Stream.of(1,2,3)
    .peek(System.out::print)   // 123
    .map(n -> n * 2)
    .forEach(System.out::print); // 246
```

> ⚠️ Do **not** use `peek` for business logic — it may be skipped when the terminal op doesn't need all elements.

### 4.9 `limit(long n)`

**Definition:** Truncates the stream to at most `n` elements. **Short-circuiting**.

```java
Stream.iterate(1, i -> i + 1).limit(5).toList(); // [1,2,3,4,5]
```

### 4.10 `skip(long n)`

**Definition:** Discards the first `n` elements.

```java
Stream.of(1,2,3,4,5).skip(2).toList(); // [3,4,5]
```

### 4.11 `takeWhile(Predicate)` (Java 9+)

**Definition:** Takes elements while predicate is true; stops at first failure.

```java
Stream.of(1,2,3,10,4).takeWhile(n -> n < 5).toList(); // [1,2,3]
```

### 4.12 `dropWhile(Predicate)` (Java 9+)

**Definition:** Drops elements while predicate is true; keeps the rest.

```java
Stream.of(1,2,3,10,4).dropWhile(n -> n < 5).toList(); // [10,4]
```

### 4.13 `boxed()` (primitive streams)

**Definition:** Converts `IntStream`/`LongStream`/`DoubleStream` to `Stream<Integer>` etc.

```java
List<Integer> boxed = IntStream.range(1,4).boxed().toList(); // [1,2,3]
```

### 4.14 `mapToObj` (primitive streams)

**Definition:** Converts primitive stream to reference stream via a function.

```java
Stream<String> s = IntStream.range(1,4).mapToObj(i -> "n" + i); // n1,n2,n3
```

### 4.15 `asLongStream()` / `asDoubleStream()` (IntStream)

```java
DoubleStream d = IntStream.range(1,3).asDoubleStream(); // 1.0, 2.0
```

### 4.16 `sequential()` / `parallel()`

**Definition:** Switch execution mode. `parallel()` uses Fork/Join.

```java
list.stream().parallel().map(...).toList();
list.parallelStream().sequential().map(...).toList();
```

### 4.17 `unordered()`

**Definition:** Hints that encounter order doesn't matter — may improve parallel performance.

```java
stream.unordered().distinct();
```

### 4.18 `onClose(Runnable)`

**Definition:** Registers a close handler invoked when `stream.close()` is called.

```java
try (Stream<String> s = Files.lines(path).onClose(() -> System.out.println("closed"))) {
    s.forEach(System.out::println);
}
```

---

## 5. Terminal Operations (Eager)

Terminal operations consume the stream and produce a result or side effect.

### 5.1 `forEach(Consumer<T>)`

**Definition:** Performs an action for each element. Order not guaranteed in parallel streams.

```java
Stream.of("a","b").forEach(System.out::println);
```

### 5.2 `forEachOrdered(Consumer<T>)`

**Definition:** Like `forEach` but respects encounter order (even in parallel).

```java
list.parallelStream().forEachOrdered(System.out::println);
```

### 5.3 `toArray()` / `toArray(IntFunction<T[]>)`

```java
Object[] arr = Stream.of("a","b").toArray();
String[] sArr = Stream.of("a","b").toArray(String[]::new);
```

### 5.4 `reduce(BinaryOperator<T>)`

**Definition:** Combines elements into one using an associative accumulator; returns `Optional`.

```java
Optional<Integer> sum = Stream.of(1,2,3,4).reduce(Integer::sum); // 10
```

### 5.5 `reduce(T identity, BinaryOperator<T>)`

```java
int sum = Stream.of(1,2,3,4).reduce(0, Integer::sum); // 10
```

### 5.6 `reduce(U identity, BiFunction<U,T,U> accumulator, BinaryOperator<U> combiner)`

**Definition:** For parallel-friendly reduction where result type differs from element type.

```java
int totalLen = Stream.of("a","bb","ccc")
    .reduce(0, (acc, s) -> acc + s.length(), Integer::sum); // 6
```

### 5.7 `collect(Collector<T,A,R>)`

**Definition:** Mutable reduction — the most powerful terminal op.

```java
List<String> list = stream.collect(Collectors.toList());
Set<String> set   = stream.collect(Collectors.toSet());
```

**Common collectors:**

| Collector | Purpose |
|---|---|
| `toList()` / `toUnmodifiableList()` | Collect to list |
| `toSet()` / `toUnmodifiableSet()` | Collect to set |
| `toMap(keyFn, valueFn)` | Collect to map |
| `toMap(keyFn, valueFn, mergeFn)` | Map with collision handling |
| `joining()` / `joining(delim)` / `joining(delim, pre, suf)` | Concatenate strings |
| `groupingBy(classifier)` | Group into `Map<K, List<V>>` |
| `groupingBy(classifier, downstream)` | Group with downstream collector |
| `partitioningBy(predicate)` | Split into `Map<Boolean, List<V>>` |
| `counting()` | Count elements |
| `summingInt` / `averagingInt` / `summarizingInt` | Numeric aggregation |
| `mapping(fn, downstream)` | Map before downstream |
| `reducing(...)` | Reduce as collector |
| `teeing(c1, c2, merger)` (Java 12+) | Two collectors at once |

```java
Map<Integer, List<String>> byLen = Stream.of("a","bb","cc","ddd")
    .collect(Collectors.groupingBy(String::length));
// {1=[a], 2=[bb, cc], 3=[ddd]}

String joined = Stream.of("a","b","c").collect(Collectors.joining(", ", "[", "]"));
// [a, b, c]

Map<Boolean, List<Integer>> parts = IntStream.rangeClosed(1,6).boxed()
    .collect(Collectors.partitioningBy(n -> n % 2 == 0));
```

### 5.8 `collect(Supplier, BiConsumer, BiConsumer)`

**Definition:** Low-level mutable reduction.

```java
List<String> list = stream.collect(ArrayList::new, List::add, List::addAll);
```

### 5.9 `min(Comparator)` / `max(Comparator)`

```java
Optional<String> shortest = Stream.of("aaa","a","bb")
    .min(Comparator.comparingInt(String::length)); // "a"
```

### 5.10 `count()`

```java
long n = Stream.of(1,2,3).count(); // 3
```

### 5.11 `anyMatch` / `allMatch` / `noneMatch`

**Definition:** Short-circuiting boolean tests.

```java
boolean any = Stream.of(1,2,3).anyMatch(n -> n > 2);   // true
boolean all = Stream.of(1,2,3).allMatch(n -> n > 0);   // true
boolean none = Stream.of(1,2,3).noneMatch(n -> n < 0); // true
```

### 5.12 `findFirst()` / `findAny()`

**Definition:** Return an `Optional`. `findFirst` respects order; `findAny` is faster in parallel.

```java
Optional<Integer> first = Stream.of(1,2,3).findFirst(); // 1
Optional<Integer> any   = list.parallelStream().findAny();
```

### 5.13 `iterator()` / `spliterator()`

**Definition:** Escape hatches to imperative iteration.

```java
Iterator<String> it = stream.iterator();
Spliterator<String> sp = stream.spliterator();
```

### 5.14 Primitive terminal ops

```java
int sum = IntStream.rangeClosed(1,5).sum();               // 15
OptionalDouble avg = IntStream.rangeClosed(1,5).average();// 3.0
IntSummaryStatistics stats = IntStream.rangeClosed(1,5).summaryStatistics();
// count=5, sum=15, min=1, max=5, average=3.0
```

### 5.15 Short-circuiting summary

These terminal ops may stop early: `anyMatch`, `allMatch`, `noneMatch`, `findFirst`, `findAny`, and terminal ops combined with `limit`.

---

## 6. Common Problems & Pitfalls

### 6.1 Stream reuse

```java
Stream<String> s = list.stream();
s.forEach(System.out::println);
s.forEach(System.out::println); // ❌ IllegalStateException
```

### 6.2 Infinite streams without `limit`

```java
Stream.iterate(0, i -> i + 1).forEach(System.out::println); // ❌ never ends
```

### 6.3 Side effects in `map`/`filter`

```java
List<String> out = new ArrayList<>();
stream.map(s -> { out.add(s); return s; }); // ❌ anti-pattern
```

### 6.4 `Collectors.toMap` duplicate keys

```java
Stream.of("a","a").collect(Collectors.toMap(s -> s, s -> s));
// ❌ IllegalStateException: Duplicate key
// ✅ Provide merge function:
.collect(Collectors.toMap(s -> s, s -> s, (x, y) -> x));
```

### 6.5 `toMap` with null values

`Collectors.toMap` throws `NullPointerException` if the value mapper returns `null`. Use `HashMap` merge manually or filter nulls.

### 6.6 Parallel stream on non-thread-safe collectors

```java
List<Integer> list = new ArrayList<>();
IntStream.range(0, 1000).parallel().forEach(list::add);
// ❌ race condition; use collect(Collectors.toList())
```

### 6.7 Parallel streams and shared mutable state

```java
int[] sum = {0};
IntStream.range(0, 1000).parallel().forEach(i -> sum[0] += i); // ❌ data race
// ✅ int sum = IntStream.range(0,1000).parallel().sum();
```

### 6.8 `peek` for side effects

`peek` may be skipped. Only use it for debugging.

### 6.9 Ordering surprises

`forEach` in parallel streams is unordered. Use `forEachOrdered` if order matters.

### 6.10 Boxing overhead

`Stream<Integer>` is slower than `IntStream`. Prefer primitive streams for numeric work.

### 6.11 `flatMap` misuse for 1-to-1

If each element maps to exactly one element, use `map`, not `flatMap`.

### 6.12 Closing I/O streams

`Files.lines`, `BufferedReader.lines`, etc. must be closed — use try-with-resources.

### 6.13 `Collectors.groupingBy` with null keys

`groupingBy` throws NPE on null keys. Filter or map nulls first.

### 6.14 Lazy evaluation confusion

```java
Stream<String> s = list.stream().filter(x -> {
    System.out.println("filtering " + x);
    return true;
});
// Nothing printed yet — no terminal op
s.count(); // now it prints
```

### 6.15 Stateful lambdas in parallel

```java
AtomicInteger counter = new AtomicInteger();
list.parallelStream().map(x -> counter.incrementAndGet() + x); // ❌ nondeterministic
```

---

## 7. Senior-Level Guide

### 7.1 When to use streams

✅ Use streams for:
- Declarative transformations, filtering, grouping
- Aggregations (sum, average, group-by)
- Readable pipelines over collections/arrays
- Parallelizable CPU-bound work on large data

❌ Avoid streams for:
- Simple loops where a `for` is clearer
- Hot loops with tiny data (stream overhead)
- I/O-bound parallelism (use `CompletableFuture` / virtual threads instead)
- Complex control flow with `break`/`continue`

### 7.2 Performance rules of thumb

| Scenario | Recommendation |
|---|---|
| Small data (< 10k) | Sequential stream or plain loop |
| Large data, CPU-bound | Parallel stream |
| I/O-bound | **Never** parallel stream — use async/executors |
| Numeric heavy | Primitive streams (`IntStream`, `DoubleStream`) |
| Need order | `forEachOrdered`, `findFirst`, avoid `unordered()` |

### 7.3 Parallel stream cautions

- Uses the **common ForkJoinPool** — shared with all parallel streams in the JVM.
- Can be **slower** than sequential for small or I/O-bound tasks.
- Avoid with **stateful** lambdas, `limit`, `sorted`, `distinct` on unordered sources.
- Prefer explicit `ForkJoinPool` submission for isolation:

```java
ForkJoinPool pool = new ForkJoinPool(4);
pool.submit(() -> list.parallelStream().map(...).toList()).join();
```

### 7.4 Collectors best practices

- Prefer `Collectors.toUnmodifiableList()` (Java 10+) for immutable results.
- Use `groupingBy` with downstream collectors for multi-level aggregation.
- Use `teeing` (Java 12+) to combine two collectors in one pass.

```java
record Stats(long count, int sum) {}
Stats stats = IntStream.rangeClosed(1,5).boxed()
    .collect(Collectors.teeing(
        Collectors.counting(),
        Collectors.summingInt(Integer::intValue),
        Stats::new));
```

### 7.5 Custom collectors

Implement `Collector<T,A,R>` for specialized reductions (e.g., immutable accumulation, custom data structures).

```java
Collector<String, StringBuilder, String> upperJoiner =
    Collector.of(
        StringBuilder::new,
        (sb, s) -> sb.append(s.toUpperCase()).append(","),
        (a, b) -> a.append(b),
        sb -> sb.length() == 0 ? "" : sb.substring(0, sb.length() - 1)
    );
```

### 7.6 Streams and memory

- Intermediate ops like `sorted`, `distinct`, `limit` on parallel streams **buffer** elements.
- Infinite streams + stateful ops = memory blowup.
- Use `Spliterator` characteristics (`ORDERED`, `SIZED`, `SORTED`, `DISTINCT`) to reason about performance.

### 7.7 Functional purity

Lambdas should be:
- **Stateless** (no external mutation)
- **Non-interfering** (don't modify the source)
- **Associative** for `reduce` (so parallel works correctly)

### 7.8 Debugging streams

- Use `peek` temporarily.
- Break pipelines into named variables.
- Prefer `IntStream` for numeric debugging (no boxing surprises).
- Use `Stream.of(...).toList()` in tests.

### 7.9 Java version highlights

| Version | Feature |
|---|---|
| Java 8 | Stream API, lambdas, `Collectors` |
| Java 9 | `takeWhile`, `dropWhile`, `iterate` with predicate, `ofNullable` |
| Java 10 | `Collectors.toUnmodifiableList/Set/Map` |
| Java 11 | `Predicate.not`, `Stream.toList()` (Java 16 actually) |
| Java 12 | `Collectors.teeing` |
| Java 16 | `Stream.toList()` shorthand |
| Java 22+ | Stream Gatherers (preview → stable in 24) — custom intermediate ops |

### 7.10 Stream Gatherers (Java 22+ preview / 24 stable)

`Stream.gather(Gatherer)` enables custom intermediate operations like windowing, folding, etc.

```java
// Fixed-size windows (conceptual)
stream.gather(Gatherer.windowFixed(3)).toList();
```

---

## 8. Practice Problems

1. **Filter & Map:** Given `List<String>`, return lengths of strings starting with "A".
2. **FlatMap:** Flatten `List<List<Integer>>` into a single sorted list.
3. **Grouping:** Group employees by department, then by salary band.
4. **Reduce:** Compute the product of all integers in a list.
5. **Partition:** Split numbers into primes and non-primes.
6. **Custom Collector:** Build an immutable `Map<String,Integer>` from a stream of words (word → length).
7. **Parallel:** Sum 1..10,000,000 using parallel `IntStream` and compare with sequential.
8. **Infinite Stream:** Generate first 10 Fibonacci numbers.
9. **Teeing:** Compute both min and max in one pass.
10. **Gatherer (Java 22+):** Implement a sliding window of size 3 over an `IntStream`.

---

## 9. Quick Reference Cheat Sheet

| Category | Methods |
|---|---|
| **Create** | `stream()`, `parallelStream()`, `Stream.of`, `Arrays.stream`, `IntStream.range`, `generate`, `iterate`, `builder`, `Files.lines` |
| **Intermediate** | `filter`, `map`, `mapToInt/Long/Double`, `flatMap`, `flatMapToInt/Long/Double`, `distinct`, `sorted`, `peek`, `limit`, `skip`, `takeWhile`, `dropWhile`, `boxed`, `mapToObj`, `asLongStream`, `asDoubleStream`, `sequential`, `parallel`, `unordered`, `onClose` |
| **Terminal** | `forEach`, `forEachOrdered`, `toArray`, `reduce` (3 forms), `collect` (2 forms), `min`, `max`, `count`, `anyMatch`, `allMatch`, `noneMatch`, `findFirst`, `findAny`, `iterator`, `spliterator`, `sum`, `average`, `summaryStatistics` |
| **Collectors** | `toList`, `toSet`, `toMap`, `joining`, `groupingBy`, `partitioningBy`, `counting`, `summingInt`, `averagingInt`, `summarizingInt`, `mapping`, `reducing`, `teeing` |

---

## 10. Summary

The Stream API is a **declarative, lazy, single-use pipeline** for processing data. Master it by:

1. Understanding **source → intermediate → terminal** structure.
2. Choosing the right **stream type** (reference vs primitive, sequential vs parallel).
3. Knowing **all intermediate and terminal operations** and their laziness/short-circuit behavior.
4. Avoiding **side effects, stream reuse, and unsafe parallel code**.
5. Using **Collectors** and **custom collectors** for complex reductions.
6. Applying **senior-level judgment**: streams for clarity and parallelizable CPU work; loops when simpler or faster.

This gives you the complete mental model to write idiomatic, efficient, and safe Java Stream code.


[[Java]]