

## Short definition first

The **Java Stream API** (`java.util.stream`) is a library introduced in Java 8 for processing sequences of elements in a **declarative**, **lazy**, and **composable** way. A `Stream<T>` is **not a data structure** — it does not store elements. It is a **view over a source** (a collection, array, generator, I/O channel, etc.) that supports **aggregate operations** such as `filter`, `map`, `reduce`, `collect`, and `sorted`.

A stream pipeline has three parts:

```
source → zero or more intermediate operations → one terminal operation
```

Intermediate operations are **lazy** and return a new stream. Terminal operations are **eager**, produce a result or side effect, and **consume** the stream. A stream can be used only once.

That is the definition. Now let’s build real understanding.

---

## 1. Prerequisites

Before Stream API makes sense, you need:

| Prerequisite | Why it matters |
|---|---|
| **Generics** | `Stream<T>`, `Collector<T, A, R>`, `Function<T, R>` — the API is built on generics. |
| **Functional interfaces** | `Predicate`, `Function`, `Consumer`, `Supplier`, `BinaryOperator`, `UnaryOperator`. |
| **Lambdas** | `x -> x + 1` is the syntactic glue of the Stream API. |
| **Method references** | `String::length`, `Integer::sum`, `System.out::println`. |
| **Collections** | Streams are often created from `List`, `Set`, `Map`, arrays. |
| **`Optional`** | `findFirst`, `findAny`, `max`, `min`, `reduce` return `Optional`. |
| **Basic complexity analysis** | To reason about performance and when not to use parallel streams. |
| **External vs internal iteration** | The key conceptual shift from loops to streams. |
| **Basic concurrency / Fork-Join** | Needed to understand parallel streams, but not to use sequential streams. |

### Dependency chain

```
Generics + Functional Interfaces + Lambdas
                ↓
           Collections / Arrays
                ↓
            Stream API
                ↓
     Collectors, Optional, Parallel Streams
                ↓
  Data processing pipelines, grouping, reductions
```

If lambdas or functional interfaces feel shaky, pause there. The Stream API is mostly a fluent API over lambdas.

---

## 2. The Problem

### What problem existed before Stream API?

Before Java 8, processing collections was **imperative** and **externally iterated**. You told the computer *how* to iterate:

```java
List<String> names = getNames();
List<String> result = new ArrayList<>();

for (String name : names) {
    if (name.startsWith("A")) {
        result.add(name.toUpperCase());
    }
}
```

This works, but it has problems:

1. **Verbose**: you write loops, temporary lists, conditionals.
2. **Hard to compose**: adding another filter or transformation means nesting or more loops.
3. **Hard to parallelize**: converting this to parallel code requires threads, synchronization, partitioning, merging — all manual and error-prone.
4. **Mixes *what* with *how***: the loop says *how* to iterate, not *what* you want.
5. **No standard aggregation vocabulary**: every codebase invents its own `sum`, `groupBy`, `join` helpers.

### Concrete pain: grouping orders by customer

Without Stream API:

```java
Map<Customer, List<Order>> byCustomer = new HashMap<>();
for (Order order : orders) {
    Customer c = order.getCustomer();
    List<Order> list = byCustomer.get(c);
    if (list == null) {
        list = new ArrayList<>();
        byCustomer.put(c, list);
    }
    list.add(order);
}
```

With Stream API:

```java
Map<Customer, List<Order>> byCustomer = orders.stream()
    .collect(Collectors.groupingBy(Order::getCustomer));
```

The second version says *what* you want, not *how* to build it.

### Why was the problem difficult?

Because the Java language before Java 8 lacked:

- Concise function literals (lambdas).
- Standard functional interfaces.
- A library for declarative data processing.
- A safe, structured way to parallelize collection processing.

The Stream API was created to fill all four gaps at once.

---

## 3. The Core Idea

### Intuitive explanation

Think of a **factory assembly line**.

- Raw materials enter at one end (the **source**).
- They pass through stations: a filter station, a painting station, a sorting station (the **intermediate operations**).
- At the end, a worker packages the result (the **terminal operation**).

The line doesn’t run until the terminal worker starts it. Intermediate stations are just *configured*; they don’t process anything until the terminal operation pulls elements through. This is **laziness**.

You don’t micromanage each item. You describe the stations. The factory handles the movement.

### Precise technical definition

> A `Stream<T>` is a sequence of elements supporting sequential and parallel aggregate operations. It is a **monadic-like** pipeline: intermediate operations return a new stream, and terminal operations produce a result or side effect. Streams are **lazy**, **consumable once**, and **do not store data**.

Key characteristics:

- **Not a data structure**: it does not hold elements; it is a view over a source.
- **Lazy**: intermediate operations are not executed until a terminal operation is invoked.
- **Consumable once**: after a terminal operation, the stream is consumed and cannot be reused.
- **Possibly unbounded**: `Stream.generate`, `Stream.iterate` can be infinite.
- **Functional in style**: operations take lambdas; side effects are discouraged.
- **Parallelizable**: `.parallel()` or `.parallelStream()` splits work across threads.

### Key vocabulary

| Term | Meaning |
|---|---|
| **Source** | Where elements come from: `Collection.stream()`, `Arrays.stream()`, `Stream.of()`, `Files.lines()`, etc. |
| **Intermediate operation** | Returns a new stream; lazy. Examples: `filter`, `map`, `flatMap`, `distinct`, `sorted`, `limit`, `skip`, `peek`. |
| **Terminal operation** | Produces a result or side effect; triggers execution. Examples: `collect`, `forEach`, `reduce`, `count`, `anyMatch`, `findFirst`, `toArray`. |
| **Lazy** | Nothing runs until the terminal operation. |
| **Short-circuiting** | Stops processing early. Examples: `limit`, `findFirst`, `anyMatch`, `allMatch`, `noneMatch`. |
| **Stateless** | Each element processed independently. Examples: `filter`, `map`, `flatMap`. |
| **Stateful** | Requires knowledge of other elements. Examples: `distinct`, `sorted`, `limit`, `skip`. |
| **Encounter order** | The order in which elements are conceptually processed. Preserved for ordered sources unless operations change it. |
| **Spliterator** | The parallel-friendly iterator used internally by streams. |
| **Collector** | A recipe for mutable reduction. Examples: `toList`, `groupingBy`, `joining`. |
| **Reduction** | Combining elements into a single result. `reduce` is immutable reduction; `collect` is mutable reduction. |
| **Parallel stream** | A stream that processes elements concurrently using the Fork-Join pool. |

---

## 4. How It Works

### The pipeline

```
Source
  │
  ├── stream()
  ▼
Intermediate ops (lazy)
  │   filter(...)
  │   map(...)
  │   sorted()
  ▼
Terminal op (eager)
  │   collect(...)
  ▼
Result
```

When you write:

```java
List<String> result = names.stream()
    .filter(n -> n.startsWith("A"))
    .map(String::toUpperCase)
    .sorted()
    .collect(Collectors.toList());
```

Java does **not** process each element through all stages one at a time. Instead:

1. `stream()` creates a `Stream` object.
2. `filter` returns a new `Stream` that wraps the previous one with a filter stage.
3. `map` returns another `Stream` with a map stage.
4. `sorted` returns another `Stream` with a sorting stage.
5. `collect` is the terminal operation. It starts pulling elements.

In sequential mode, elements are generally processed **one at a time through the whole pipeline**, not stage-by-stage for all elements. For example, if the first element passes `filter`, it is immediately `map`ped, then `sorted` collects it, then the next element is processed, etc. `sorted` is stateful, so it must buffer all elements before emitting any. But stateless stages are fused.

### Lazy evaluation

Intermediate operations do nothing until a terminal operation is called.

```java
Stream<String> s = names.stream()
    .filter(n -> {
        System.out.println("filtering " + n);
        return n.startsWith("A");
    });

System.out.println("Nothing printed yet");

long count = s.count();  // NOW filtering runs
```

This laziness enables:

- **Short-circuiting**: `findFirst`, `anyMatch`, `limit` can stop early.
- **Infinite streams**: you can process an infinite source because only as many elements as needed are generated.
- **Optimization**: the library can fuse operations and skip unnecessary work.

### Stateless vs stateful operations

| Operation | Type | Notes |
|---|---|---|
| `filter` | Stateless | One element at a time. |
| `map` | Stateless | One element at a time. |
| `flatMap` | Stateless | One element to many. |
| `peek` | Stateless | Side-effect for debugging. |
| `distinct` | Stateful | Must remember seen elements. |
| `sorted` | Stateful | Must buffer all elements. |
| `limit` | Stateful / short-circuiting | Must count. |
| `skip` | Stateful | Must count. |

Stateful operations can break parallel efficiency because they require coordination or buffering.

### Short-circuiting

Some operations can stop early:

```java
boolean anyAdult = people.stream()
    .anyMatch(p -> p.age() >= 18);  // stops at first adult

Optional<String> first = names.stream()
    .filter(n -> n.startsWith("A"))
    .findFirst();  // stops at first match

List<String> firstThree = names.stream()
    .limit(3)
    .collect(Collectors.toList());
```

Short-circuiting works because the pipeline is lazy: the terminal operation pulls only as many elements as needed.

### Parallel streams

Call `.parallel()` or `.parallelStream()`:

```java
long count = list.parallelStream()
    .filter(x -> x > 0)
    .count();
```

Internally:

1. The source is split using a `Spliterator`.
2. Sub-streams are processed by Fork-Join tasks.
3. Results are combined.

Parallel streams use the common `ForkJoinPool.commonPool()` by default. You can run them in a custom pool, but it’s awkward.

Parallel streams are **not automatically faster**. They help when:

- The data set is large.
- The work per element is substantial.
- The source splits efficiently (`ArrayList`, arrays, `IntStream.range`).
- Operations are stateless and associative.
- There is no shared mutable state.
- The merge step is cheap.

They hurt when:

- The data set is small.
- Operations are I/O-bound.
- Operations are stateful (`sorted`, `distinct`).
- You use `forEach` with shared mutable state.
- Ordering matters and you use `findAny` incorrectly.

---

## 5. Relationships

### Collections vs Streams

| Aspect | Collection | Stream |
|---|---|---|
| Stores data? | Yes | No |
| Can be reused? | Yes | No, consumed once |
| Iteration | External (`for`, `iterator`) | Internal (library controls) |
| Evaluation | Eager | Lazy |
| Size | Finite | May be infinite |
| Purpose | Data storage | Data processing |
| Parallelism | Manual | `.parallel()` |

A collection is about **what data you have**. A stream is about **what computation you want to perform**.

### Iterator vs Stream

- `Iterator` is external iteration: you call `hasNext`/`next`.
- `Stream` is internal iteration: you describe operations, the library iterates.
- `Stream` can be parallel; `Iterator` cannot easily be.

### Optional

Terminal operations that may return no result return `Optional<T>`:

```java
Optional<Person> oldest = people.stream()
    .max(Comparator.comparingInt(Person::age));
```

`Optional` forces you to handle absence explicitly.

### Collectors

`Collectors` is a utility class of `Collector` implementations:

- `toList`, `toSet`, `toMap`
- `groupingBy`, `partitioningBy`
- `joining`, `counting`, `summingInt`, `averagingInt`
- `mapping`, `reducing`, `flatMapping`

`collect` is the most powerful terminal operation.

### Functional interfaces

Stream operations are built on:

- `Predicate<T>`: `boolean test(T)`
- `Function<T,R>`: `R apply(T)`
- `Consumer<T>`: `void accept(T)`
- `Supplier<T>`: `T get()`
- `BinaryOperator<T>`: `T apply(T, T)`
- `UnaryOperator<T>`: `T apply(T)`

### Parallel streams and Fork-Join

Parallel streams use the Fork-Join framework and `Spliterator` to split work. This connects Stream API to `java.util.concurrent`.

### Not to be confused with I/O streams

`java.io.InputStream` / `OutputStream` are **byte streams** for I/O. They are completely different from `java.util.stream.Stream`. The name overlap is unfortunate.

---

## 6. Examples

### Level 1: Beginner — filter and collect

```java
List<String> names = List.of("Alice", "Bob", "Anna", "Charlie", "Alex");

List<String> aNames = names.stream()
    .filter(n -> n.startsWith("A"))
    .map(String::toUpperCase)
    .collect(Collectors.toList());

System.out.println(aNames); // [ALICE, ANNA, ALEX]
```

**What to notice:** `stream()` creates the stream, `filter` and `map` are intermediate, `collect` is terminal. The original list is unchanged.

### Level 2: Real-world — grouping orders

```java
record Order(String customer, double amount) {}

List<Order> orders = List.of(
    new Order("Alice", 100),
    new Order("Bob", 50),
    new Order("Alice", 200),
    new Order("Bob", 75)
);

Map<String, List<Order>> byCustomer = orders.stream()
    .collect(Collectors.groupingBy(Order::customer));

Map<String, Double> totalByCustomer = orders.stream()
    .collect(Collectors.groupingBy(
        Order::customer,
        Collectors.summingDouble(Order::amount)
    ));

System.out.println(totalByCustomer); // {Alice=300.0, Bob=125.0}
```

**What to notice:** `groupingBy` is a collector. The second form uses a downstream collector to aggregate each group.

### Level 3: Practical programming — word frequency

```java
String text = "the quick brown fox jumps over the lazy dog the fox";
Map<String, Long> freq = Arrays.stream(text.split("\\s+"))
    .collect(Collectors.groupingBy(
        word -> word,
        Collectors.counting()
    ));

System.out.println(freq.get("the")); // 2
System.out.println(freq.get("fox")); // 2
```

**What to notice:** `Arrays.stream` creates a stream from an array. `groupingBy` + `counting` counts occurrences.

### Level 4: Professional/production — pipeline with parallel and custom collector

```java
List<Transaction> transactions = loadTransactions();

Map<String, Double> totalByAccount = transactions.parallelStream()
    .filter(t -> t.status() == Status.COMPLETED)
    .collect(Collectors.groupingByConcurrent(
        Transaction::accountId,
        Collectors.summingDouble(Transaction::amount)
    ));
```

**What to notice:** `parallelStream()` uses multiple threads. `groupingByConcurrent` is a concurrent collector that safely merges partial results. This is appropriate for large, CPU-bound, stateless processing. It is *not* appropriate for small lists or I/O-bound work.

### Level 5: Edge case — infinite stream

```java
// First 5 powers of 2
List<Integer> powers = Stream.iterate(1, n -> n * 2)
    .limit(5)
    .collect(Collectors.toList());

System.out.println(powers); // [1, 2, 4, 8, 16]
```

Without `limit`, this stream is infinite. `limit` is short-circuiting, so only 5 elements are generated.

**Another edge case: reusing a stream.**

```java
Stream<String> s = names.stream();
s.forEach(System.out::println);
s.forEach(System.out::println); // IllegalStateException: stream has already been operated upon or closed
```

A stream can be consumed only once.

---

## 7. How to Use It

### Common usage patterns

```java
// Filter
list.stream().filter(x -> x > 0)

// Map
list.stream().map(String::toUpperCase)

// FlatMap (one-to-many)
listOfLists.stream().flatMap(List::stream)

// Distinct
list.stream().distinct()

// Sorted
list.stream().sorted()
list.stream().sorted(Comparator.comparing(Person::name))

// Limit / skip
list.stream().limit(10)
list.stream().skip(5)

// Reduce
int sum = list.stream().reduce(0, Integer::sum)

// Collect
List<String> result = stream.collect(Collectors.toList())
Set<String> set = stream.collect(Collectors.toSet())
Map<K, V> map = stream.collect(Collectors.toMap(Key::new, Value::new))

// Group
Map<String, List<Person>> byCity = people.stream()
    .collect(Collectors.groupingBy(Person::city))

// Partition
Map<Boolean, List<Person>> adults = people.stream()
    .collect(Collectors.partitioningBy(p -> p.age() >= 18))

// Join
String joined = names.stream().collect(Collectors.joining(", "))

// Match
boolean any = stream.anyMatch(predicate)
boolean all = stream.allMatch(predicate)
boolean none = stream.noneMatch(predicate)

// Find
Optional<T> first = stream.findFirst()
Optional<T> any = stream.findAny()  // better for parallel

// Count
long count = stream.count()
```

### Best practices

- **Use streams for data processing, not control flow.** If you need complex branching, loops are clearer.
- **Keep lambdas short and side-effect-free.** A lambda should be a pure function where possible.
- **Use `collect` to gather results**, not `forEach` with a mutable list.
- **Prefer `mapToInt`, `mapToLong`, `mapToDouble`** to avoid boxing.
- **Use `findFirst` for sequential, `findAny` for parallel** when order doesn’t matter.
- **Use `forEachOrdered` in parallel** if order matters.
- **Close streams from I/O sources** with try-with-resources.
- **Prefer method references** (`String::length`) over lambdas when clearer.
- **Use `Collectors` utilities** instead of manual accumulation.
- **Measure before using parallel streams.**

### When to choose Stream API

- Transforming collections.
- Filtering and mapping.
- Grouping, partitioning, joining.
- Aggregating (sum, average, count, min, max).
- Processing large data sets declaratively.
- Parallelizing CPU-bound data processing.

### When to avoid Stream API

- Simple loops where a stream is overkill.
- Complex control flow with `break`, `continue`, multiple exits.
- Checked exception handling inside lambdas.
- Performance-critical tight loops where boxing or lambda overhead matters.
- I/O-bound parallel work.
- When debugging is hard and imperative code is clearer.
- When you need to mutate shared state.

### Alternatives

| Alternative | When preferable |
|---|---|
| `for` loop | Complex control flow, mutation, checked exceptions. |
| `Iterator` | Simple traversal, removal during iteration. |
| `Collection` methods | `addAll`, `removeAll`, `retainAll` for set operations. |
| `Arrays` / `Collections` utilities | Sorting, searching, filling. |
| Reactive streams | Asynchronous, backpressure-aware pipelines. |

---

## 8. Common Mistakes

### Beginner mistakes

**Mistake 1: Reusing a stream.**

```java
Stream<String> s = list.stream();
s.count();
s.count(); // IllegalStateException
```

**Mistake 2: Forgetting the terminal operation.**

```java
list.stream().filter(x -> x > 0); // does nothing
```

Intermediate operations are lazy. Without a terminal operation, nothing happens.

**Mistake 3: Using `forEach` to collect.**

```java
List<String> result = new ArrayList<>();
stream.forEach(result::add); // works but bad style and unsafe in parallel
```

Use `collect(Collectors.toList())`.

**Mistake 4: Modifying the source during a stream.**

```java
list.stream().forEach(list::remove); // ConcurrentModificationException or undefined
```

### Misconceptions

**Misconception: "Streams are always faster than loops."**

False. For small data or simple operations, loops can be faster due to lower overhead.

**Misconception: "Parallel streams are always faster."**

False. They add overhead and can be slower for small data, stateful operations, or I/O.

**Misconception: "Streams store data."**

False. Streams are views. They don’t store elements.

**Misconception: "A stream can be used like a collection."**

False. It’s consumed once and has no indexed access.

### Incorrect implementations

**Incorrect: side effects in `map`.**

```java
stream.map(x -> { list.add(x); return x; }); // bad: side effect in map
```

Use `peek` for debugging, `forEach` for terminal side effects, but avoid side effects in intermediate ops.

**Incorrect: stateful lambda in parallel.**

```java
List<Integer> result = new ArrayList<>();
IntStream.range(0, 1000).parallel().forEach(result::add); // race condition
```

Use a concurrent collector or `forEachOrdered` with a synchronized list.

**Incorrect: using `findFirst` in parallel when `findAny` is fine.**

`findFirst` forces ordering and reduces parallelism benefits.

### Subtle mistakes

**Mistake: `Collectors.toMap` with duplicate keys.**

```java
Map<String, Integer> map = list.stream()
    .collect(Collectors.toMap(Person::name, Person::age));
// throws IllegalStateException if two people have the same name
```

Provide a merge function:

```java
Collectors.toMap(Person::name, Person::age, (a, b) -> a)
```

**Mistake: relying on encounter order after `unordered()` or in parallel.**

Parallel streams may not preserve order unless you use ordered operations.

**Mistake: not closing I/O streams.**

```java
Files.lines(path).forEach(System.out::println); // file handle leak
```

Use try-with-resources.

---

## 9. Trade-offs

| Dimension | Stream API | Imperative Loop |
|---|---|---|
| **Readability** | High for data pipelines | High for complex control flow |
| **Composability** | Excellent | Poor |
| **Performance** | Good; overhead for small data | Often faster for small/simple |
| **Parallelism** | Easy to request | Manual and hard |
| **Memory** | Can buffer (sorted, distinct) | Depends |
| **Debugging** | Harder (lambdas, lazy) | Easier (step through) |
| **Mutability** | Discouraged | Natural |
| **Exception handling** | Awkward for checked exceptions | Natural |
| **Development cost** | Lower for data processing | Lower for simple loops |

### Advantages

- Declarative, concise.
- Composable.
- Easy parallelization.
- Rich aggregation vocabulary.
- Encourages immutability and pure functions.

### Disadvantages

- Debugging is harder.
- Overhead for small data.
- Checked exceptions are awkward.
- Parallel streams can be misused.
- Streams are consumed once.
- Stateful operations can hurt performance.

---

## 10. Edge Cases and Limitations

1. **Streams are single-use.** Reuse throws `IllegalStateException`.
2. **Infinite streams** require short-circuiting operations (`limit`, `findFirst`, `anyMatch`).
3. **Parallel + stateful operations** can be slow or incorrect.
4. **`forEach` in parallel** does not guarantee order; use `forEachOrdered`.
5. **`findFirst` in parallel** reduces parallelism; use `findAny` if order doesn’t matter.
6. **Checked exceptions** cannot be thrown from lambdas directly; wrap or use helper methods.
7. **`null` elements** can cause `NullPointerException` in some operations; filter them out first.
8. **I/O streams** (`Files.lines`, `BufferedReader.lines`) must be closed.
9. **Primitive streams** (`IntStream`, `LongStream`, `DoubleStream`) avoid boxing but have fewer operations.
10. **`Collectors.toMap`** throws on duplicate keys unless a merge function is provided.
11. **`sorted()`** buffers all elements; on infinite streams it never completes.
12. **`distinct()`** uses `equals`/`hashCode`; on large streams it uses memory.

---

## 11. Professional Perspective

What experienced engineers know that tutorials don’t:

**1. Streams are for data processing, not control flow.** If you need `break`, `continue`, multiple returns, or complex branching, use a loop.

**2. Parallel streams are not a free speedup.** Use them only for large, CPU-bound, stateless, splittable workloads. Measure.

**3. Avoid side effects in lambdas.** Streams are designed for pure functions. Side effects in `map` or `filter` lead to bugs, especially in parallel.

**4. `collect` is the workhorse.** Learn `Collectors.groupingBy`, `partitioningBy`, `toMap`, `joining`, `summingInt`, `averagingInt`, `mapping`, `reducing`.

**5. Prefer primitive streams** (`IntStream`, `LongStream`, `DoubleStream`) for numeric work to avoid boxing.

**6. Debugging streams is hard.** Use `peek` for inspection, but remove it in production. Break pipelines into smaller methods for testability.

**7. Streams can be closed.** If the source is closeable, use try-with-resources.

**8. Encounter order matters.** Parallel streams may not preserve it unless you use ordered operations.

**9. `Collectors.toMap` is a common source of duplicate-key exceptions.** Always consider a merge function.

**10. Don’t over-stream.** A simple `for` loop is often clearer and faster. Use streams when they add clarity or enable parallelism.

**11. The common Fork-Join pool is shared.** Blocking tasks in parallel streams can starve the pool. For blocking I/O, use a custom executor or avoid parallel streams.

**12. Stream API is not reactive.** It’s pull-based, synchronous, and lacks backpressure. For async, use `CompletableFuture` or reactive libraries.

---

## 12. Mental Model

**Mental model: The Lazy Assembly Line.**

A stream is an assembly line that doesn’t run until the terminal worker presses “Start.” Raw materials come from a source. Stations along the line are configured with lambdas: a filter station, a map station, a sorting station. Nothing moves until the terminal operation pulls items through. Some stations can stop the line early (short-circuiting). Some stations need to see all items before passing any (stateful). The line can be split into parallel lanes, but only if the stations and materials allow it.

**Re-explained with the model:**

A `Stream` is a lazy assembly line over a source. Intermediate operations configure stations; terminal operations start the line and produce a result. Laziness allows short-circuiting and infinite sources. Parallelism splits the line into lanes. The stream is consumed once; after the terminal operation, the line is gone.

---

## 13. Knowledge Check

Answer these in your own words. I’ll evaluate them.

**Basic:**

1. Is `Stream` a data structure? Why or why not?
2. What are the three parts of a stream pipeline?
3. What is the difference between an intermediate and a terminal operation?

**Why:**

4. Why are intermediate operations lazy?
5. Why can a stream be consumed only once?
6. Why are parallel streams not always faster?

**Prediction:**

7. What does this print?
   ```java
   List<String> list = List.of("a", "b", "c");
   Stream<String> s = list.stream().map(String::toUpperCase);
   System.out.println("Before");
   s.forEach(System.out::println);
   ```
8. What happens here?
   ```java
   Stream<Integer> s = Stream.iterate(1, n -> n + 1);
   List<Integer> first10 = s.limit(10).collect(Collectors.toList());
   System.out.println(first10);
   ```
9. What does this do?
   ```java
   Map<String, Integer> map = Stream.of("a", "b", "a")
       .collect(Collectors.toMap(w -> w, String::length));
   ```

**Debugging:**

10. A stream pipeline does nothing when run. What’s the likely cause?
11. A parallel stream produces incorrect results intermittently. What’s a likely cause?
12. `Collectors.toMap` throws `IllegalStateException`. Why?

**Scenario:**

13. You need to process a 10GB file line by line and count word frequencies. Would you use parallel streams? Why or why not?
14. You need to group employees by department and compute average salary. Which collectors do you use?
15. You need to find the first employee with a salary above 100k. Which terminal operation do you use?

---

## 14. Practice

### Level 1: Basic understanding

Given a `List<Integer>`, use a stream to produce a new `List<Integer>` containing only the even numbers, each multiplied by 10.

### Level 2: Implementation

Given a `List<String>`, use a stream to produce a `Map<Integer, List<String>>` grouping strings by their length.

### Level 3: Debugging

The following code is supposed to sum the lengths of all strings in a list, but it returns 0. Find and fix the bug:

```java
List<String> words = List.of("apple", "banana", "cherry");
int total = words.stream()
    .mapToInt(String::length)
    .sum();
System.out.println(total);
```

Actually, the code looks correct. What if `words` is empty? What if the stream is consumed elsewhere? Debug it.

### Level 4: Real-world scenario

You have a `List<Order>` where each `Order` has `customerId`, `amount`, and `status`. Write a stream pipeline that:

- Filters to `COMPLETED` orders.
- Groups by `customerId`.
- Computes total amount per customer.
- Returns a `Map<String, Double>` sorted by total descending.

Which operations do you use? Which are stateful? Would you use parallel? Why or why not?

### Level 5: Challenging/problem-solving

Implement a stream-based solution to find the top 3 most frequent words in a text, ignoring case and punctuation. Then implement it again using parallel streams. Compare the two. What are the challenges? How do you merge partial results?

---

## 15. Final Map

```
Generics + Lambdas + Functional Interfaces
                │
           Collections / Arrays / I/O
                │
            Stream API
                │
    ┌───────────┼───────────┬──────────────┐
    │           │           │              │
Intermediate  Terminal   Collectors   Parallel Streams
 operations   operations
    │           │           │              │
 filter       collect     groupingBy    Fork-Join
 map          forEach     partitioningBy Spliterator
 flatMap      reduce      toMap         commonPool
 distinct     count       joining
 sorted       anyMatch    summingInt
 limit        findFirst   averagingInt
 skip         toArray     mapping
 peek         max/min     reducing
```

**Prerequisites:** generics, lambdas, functional interfaces, collections, `Optional`.

**Stream API:** lazy, composable, single-use sequence processing.

**Related concepts:** `Collection`, `Iterator`, `Optional`, `Collectors`, `Spliterator`, `Fork-Join`.

**Higher-level concepts:** data pipelines, parallel processing, grouping/aggregation, reactive streams (different).

**Practical applications:** filtering, mapping, grouping, joining, aggregating, parallel data processing.

---



[[Java]]