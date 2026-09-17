
# Java Stream Methods

A **Stream method** is a method provided by Java's `Stream` API to create, transform, process, or terminate a stream of elements.

The methods are easiest to understand by grouping them according to **where they occur in a Stream pipeline**.

```text
SOURCE
  │
  ▼
Stream<T>
  │
  ├── Intermediate operations
  │       ↓
  │   Stream<T>
  │
  └── Terminal operation
          ↓
        RESULT
```

## 1. Stream creation methods

These create a `Stream`.

|Method|Definition|Example|
|---|---|---|
|`collection.stream()`|Creates a sequential stream from a Collection|`list.stream()`|
|`collection.parallelStream()`|Creates a parallel stream|`list.parallelStream()`|
|`Stream.of()`|Creates a stream from given values|`Stream.of(1, 2, 3)`|
|`Stream.empty()`|Creates an empty stream|`Stream.empty()`|
|`Stream.generate()`|Creates an potentially infinite stream using a `Supplier`|`Stream.generate(Math::random)`|
|`Stream.iterate()`|Creates a stream by repeatedly applying a function|`Stream.iterate(1, n -> n + 1)`|
|`Arrays.stream()`|Creates a stream from an array|`Arrays.stream(numbers)`|

---

# 2. Intermediate methods

Intermediate methods **take a Stream and return another Stream**.

This allows chaining:

```java
numbers.stream()
       .filter(...)
       .map(...)
       .sorted(...)
       .toList();
```

They are generally **lazy**.

---

## `filter()`

Keeps elements that satisfy a condition.

```java
numbers.stream()
       .filter(n -> n > 10);
```

```text
1  → ❌
15 → ✅
20 → ✅
5  → ❌
```

**Type:**

```java
Stream<T> filter(Predicate<? super T> predicate)
```

---

## `map()`

Transforms each element into another value.

```java
numbers.stream()
       .map(n -> n * 2);
```

```text
1 → 2
2 → 4
3 → 6
```

**Type:**

```java
<R> Stream<R> map(Function<? super T, ? extends R> mapper)
```

Important:

```text
filter → decides which elements survive
map    → changes the elements
```

---

## `flatMap()`

Maps each element to a stream and then **flattens the resulting streams into one stream**.

```java
List<List<Integer>> lists = List.of(
    List.of(1, 2),
    List.of(3, 4)
);

lists.stream()
     .flatMap(List::stream);
```

Conceptually:

```text
[1, 2] ──┐
         ├──→ 1, 2, 3, 4
[3, 4] ──┘
```

---

## `distinct()`

Removes duplicate elements.

```java
Stream.of(1, 2, 2, 3, 3)
      .distinct();
```

Result:

```text
1, 2, 3
```

Uses the elements' equality semantics (`equals`/`hashCode`).

---

## `sorted()`

Sorts elements according to their natural ordering.

```java
Stream.of(5, 2, 8, 1)
      .sorted();
```

Result:

```text
1, 2, 5, 8
```

You can provide a `Comparator`:

```java
names.stream()
     .sorted(Comparator.reverseOrder());
```

---

## `limit()`

Restricts the stream to at most `n` elements.

```java
Stream.of(1, 2, 3, 4, 5)
      .limit(3);
```

Result:

```text
1, 2, 3
```

---

## `skip()`

Skips the first `n` elements.

```java
Stream.of(1, 2, 3, 4, 5)
      .skip(2);
```

Result:

```text
3, 4, 5
```

---

## `peek()`

Performs an action on elements as they pass through the pipeline.

```java
numbers.stream()
       .peek(n -> System.out.println(n))
       .toList();
```

It is mainly useful for **debugging/observing a pipeline**, not for implementing business logic.

---

## `takeWhile()`

Keeps elements **while** a condition is true.

```java
Stream.of(2, 4, 6, 7, 8)
      .takeWhile(n -> n % 2 == 0);
```

Result:

```text
2, 4, 6
```

It stops when `7` fails the condition.

---

## `dropWhile()`

Drops elements **while** a condition is true, then keeps the rest.

```java
Stream.of(2, 4, 7, 8, 10)
      .dropWhile(n -> n % 2 == 0);
```

Result:

```text
7, 8, 10
```

---

# 3. Terminal methods

Terminal methods **consume the stream** and produce a final result or side effect.

After a terminal operation, you generally cannot reuse that stream.

---

## `toList()`

Collects elements into a `List`.

```java
List<Integer> result =
    numbers.stream()
           .filter(n -> n > 10)
           .toList();
```

---

## `collect()`

Performs a mutable reduction using a `Collector`.

```java
List<Integer> result =
    numbers.stream()
           .collect(Collectors.toList());
```

`collect()` is much more general than `toList()`.

For example:

```java
Map<Integer, String> map =
    users.stream()
         .collect(Collectors.toMap(
             User::getId,
             User::getName
         ));
```

---

## `forEach()`

Performs an action for every element.

```java
numbers.stream()
       .forEach(System.out::println);
```

---

## `forEachOrdered()`

Like `forEach()`, but explicitly preserves encounter order when applicable.

Especially relevant for parallel streams.

```java
numbers.parallelStream()
       .forEachOrdered(System.out::println);
```

---

## `count()`

Returns the number of elements.

```java
long count = numbers.stream()
                    .filter(n -> n > 10)
                    .count();
```

---

## `reduce()`

Combines elements into a single result.

For example, sum:

```java
int sum = numbers.stream()
                 .reduce(0, Integer::sum);
```

Conceptually:

```text
1 + 2 + 3 + 4
      ↓
     10
```

`reduce()` is fundamental to understanding functional-style stream processing.

---

# 4. Finding methods

## `findFirst()`

Returns the first element as an `Optional`.

```java
Optional<Integer> result =
    numbers.stream()
           .filter(n -> n > 10)
           .findFirst();
```

---

## `findAny()`

Returns **some** element as an `Optional`.

```java
Optional<Integer> result =
    numbers.stream()
           .filter(n -> n > 10)
           .findAny();
```

It is particularly useful with parallel streams where a specific first element isn't required.

---

# 5. Matching methods

These return `boolean`.

## `anyMatch()`

Does **at least one** element satisfy the condition?

```java
boolean result =
    numbers.stream()
           .anyMatch(n -> n > 100);
```

```text
ANY?
 │
 ├── 50  ❌
 ├── 20  ❌
 └── 150 ✅ → true
```

---

## `allMatch()`

Do **all** elements satisfy the condition?

```java
boolean result =
    numbers.stream()
           .allMatch(n -> n > 0);
```

---

## `noneMatch()`

Does **no** element satisfy the condition?

```java
boolean result =
    numbers.stream()
           .noneMatch(n -> n < 0);
```

---

# 6. Min / Max

## `min()`

Finds the minimum element.

```java
Optional<Integer> min =
    numbers.stream()
           .min(Integer::compareTo);
```

## `max()`

Finds the maximum element.

```java
Optional<Integer> max =
    numbers.stream()
           .max(Integer::compareTo);
```

Both return `Optional<T>` because the stream could be empty.

---

# 7. Primitive Stream methods

Java also has specialized streams:

```text
IntStream
LongStream
DoubleStream
```

For example:

```java
IntStream.range(1, 5);
```

produces:

```text
1, 2, 3, 4
```

They provide useful numeric operations such as:

```java
sum()
average()
min()
max()
count()
```

Example:

```java
int sum = IntStream.range(1, 5)
                   .sum();
```

Result:

```text
10
```

---

# The most important classification

Memorize this structure:

|Category|Methods|Returns|
|---|---|---|
|**Creation**|`stream()`, `of()`, `generate()`, `iterate()`|`Stream`|
|**Transformation**|`map()`, `flatMap()`|`Stream`|
|**Filtering**|`filter()`, `distinct()`, `limit()`, `skip()`|`Stream`|
|**Ordering**|`sorted()`|`Stream`|
|**Observation**|`peek()`|`Stream`|
|**Short-circuiting intermediate**|`takeWhile()`, `dropWhile()`|`Stream`|
|**Collection**|`toList()`, `collect()`|Collection/result|
|**Iteration**|`forEach()`, `forEachOrdered()`|`void`|
|**Reduction**|`reduce()`, `count()`|Result|
|**Finding**|`findFirst()`, `findAny()`|`Optional`|
|**Matching**|`anyMatch()`, `allMatch()`, `noneMatch()`|`boolean`|
|**Extremes**|`min()`, `max()`|`Optional`|

### The fundamental rule

The easiest way to understand a Stream method is to ask:

> **Does this method return another `Stream`, or does it finish the pipeline?**

```text
                    Stream methods
                         │
             ┌───────────┴───────────┐
             │                       │
       Intermediate              Terminal
             │                       │
       returns Stream            ends Stream
             │                       │
   filter(), map(),          collect(), reduce(),
   flatMap(), sorted()        count(), forEach(),
                              findFirst(), anyMatch()
```

That distinction is the **core of the Stream API**.


[[Java]]