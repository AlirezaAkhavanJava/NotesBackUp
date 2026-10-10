
In Java, there are several common ways to **create a `Stream`**. The important distinction is **where the stream gets its elements from**.

## 1. From a `Collection`

Probably the most common way.

```java
List<String> names = List.of("Alice", "Bob", "Charlie");

Stream<String> stream = names.stream();
```

### What happens?

The `List` already contains the data:

```text
List
 ├── Alice
 ├── Bob
 └── Charlie
       ↓
   .stream()
       ↓
 Stream<String>
       ↓
 filter → map → sorted → ...
```

The stream **doesn't contain a copy of the list**. It provides a pipeline for processing the collection's elements.

You can also create a parallel stream:

```java
Stream<String> stream = names.parallelStream();
```

---

# 2. From an Array

Use `Arrays.stream()`.

```java
String[] names = {"Alice", "Bob", "Charlie"};

Stream<String> stream = Arrays.stream(names);
```

For primitive arrays:

```java
int[] numbers = {1, 2, 3, 4, 5};

IntStream stream = Arrays.stream(numbers);
```

Notice the difference:

```java
Stream<Integer>    // objects
IntStream          // primitive int
LongStream         // primitive long
DoubleStream       // primitive double
```

---

# 3. Using `Stream.of()`

You can directly provide elements.

```java
Stream<String> stream =
        Stream.of("Alice", "Bob", "Charlie");
```

Conceptually:

```text
"Alice" ─┐
"Bob"   ─┼──→ Stream<String>
"Charlie"┘
```

You can also create a stream containing one object:

```java
Stream<String> stream = Stream.of("Alice");
```

Or an empty stream:

```java
Stream<String> stream = Stream.empty();
```

---

# 4. From `Stream.Builder`

Useful when you want to **construct a stream programmatically**.

```java
Stream.Builder<String> builder = Stream.builder();

builder.add("Alice");
builder.add("Bob");
builder.add("Charlie");

Stream<String> stream = builder.build();
```

Think of it as:

```text
Builder
   ↓
 add()
 add()
 add()
   ↓
 build()
   ↓
 Stream
```

This is less common in normal application code.

---

# 5. Using `Stream.iterate()`

Creates a stream based on a **repeated computation**.

```java
Stream<Integer> numbers =
        Stream.iterate(0, n -> n + 1);
```

This conceptually produces:

```text
0 → 1 → 2 → 3 → 4 → 5 → ...
```

This is an **infinite stream**.

Therefore, you normally limit it:

```java
Stream<Integer> numbers =
        Stream.iterate(0, n -> n + 1)
              .limit(5);
```

Result:

```text
0
1
2
3
4
```

There is also a three-argument form:

```java
Stream.iterate(
    0,
    n -> n < 10,
    n -> n + 1
);
```

Meaning:

```text
start:     0
condition: n < 10
next:      n + 1
```

---

# 6. Using `Stream.generate()`

Creates elements using a `Supplier`.

```java
Stream<Double> randomNumbers =
        Stream.generate(Math::random);
```

Conceptually:

```text
Supplier
   ↓
generate()
   ↓
0.42
0.17
0.91
0.33
...
```

Again, this is normally infinite:

```java
Stream<Double> randomNumbers =
        Stream.generate(Math::random)
              .limit(5);
```

`generate()` is useful when each element is produced independently.

For example:

```java
Stream<String> stream =
        Stream.generate(() -> "Hello")
              .limit(3);
```

Produces:

```text
Hello
Hello
Hello
```

---

# 7. From a File

Java provides `Files.lines()`.

```java
Stream<String> lines =
        Files.lines(Path.of("data.txt"));
```

If `data.txt` contains:

```text
Alice
Bob
Charlie
```

then the stream represents:

```text
"Alice"
   ↓
"Bob"
   ↓
"Charlie"
```

Very useful for processing large files because you don't necessarily need to load the entire file into memory at once.

Usually use it with try-with-resources:

```java
try (Stream<String> lines = Files.lines(Path.of("data.txt"))) {
    lines.forEach(System.out::println);
}
```

---

# 8. From a `Map`

A `Map` itself doesn't have `.stream()` because it isn't a `Collection`.

Instead, stream one of its views:

### Keys

```java
map.keySet().stream();
```

### Values

```java
map.values().stream();
```

### Entries

```java
map.entrySet().stream();
```

For example:

```java
Map<Integer, String> users = Map.of(
        1, "Alice",
        2, "Bob"
);

users.entrySet()
     .stream()
     .forEach(System.out::println);
```

---

# 9. From a `Spliterator`

A more advanced way:

```java
Spliterator<String> spliterator = ...;

Stream<String> stream =
        StreamSupport.stream(spliterator, false);
```

The second argument:

```java
false
```

means sequential.

```java
true
```

means parallel.

```java
StreamSupport.stream(spliterator, true);
```

This is mainly relevant when integrating custom data sources with the Stream API.

---

# 10. Primitive streams

Java has specialized streams for primitives:

```java
IntStream
LongStream
DoubleStream
```

You can create them directly:

```java
IntStream.range(0, 5);
```

Produces:

```text
0 1 2 3 4
```

Notice that `5` is excluded.

Or:

```java
IntStream.rangeClosed(0, 5);
```

Produces:

```text
0 1 2 3 4 5
```

---

# Complete picture

The major creation methods are:

|Source|Creation|Stream|
|---|---|---|
|`Collection`|`collection.stream()`|`Stream<T>`|
|`Collection`|`collection.parallelStream()`|`Stream<T>`|
|Array|`Arrays.stream(array)`|`Stream<T>` / primitive|
|Direct values|`Stream.of(...)`|`Stream<T>`|
|Empty|`Stream.empty()`|`Stream<T>`|
|Builder|`Stream.builder()`|`Stream<T>`|
|Generated sequence|`Stream.iterate(...)`|`Stream<T>`|
|Generated values|`Stream.generate(...)`|`Stream<T>`|
|File|`Files.lines(...)`|`Stream<String>`|
|Map keys|`map.keySet().stream()`|`Stream<K>`|
|Map values|`map.values().stream()`|`Stream<V>`|
|Map entries|`map.entrySet().stream()`|`Stream<Entry<K,V>>`|
|`Spliterator`|`StreamSupport.stream(...)`|`Stream<T>`|
|Integer range|`IntStream.range(...)`|`IntStream`|
|Long range|`LongStream.range(...)`|`LongStream`|
|Double values|`DoubleStream.of(...)`|`DoubleStream`|

## The key mental model

There isn't just **one place** a stream comes from.

A stream is a **processing abstraction over a source**:

```text
             SOURCE
                │
      ┌─────────┼─────────┐
      ↓         ↓         ↓
 Collection   Array    Generator
      │         │         │
      └─────────┼─────────┘
                ↓
             STREAM
                ↓
       ┌────────┼────────┐
       ↓        ↓        ↓
    filter     map     sorted
       │        │        │
       └────────┼────────┘
                ↓
           TERMINAL OP
                ↓
          result / side effect
```

So when you write:

```java
users.stream()
     .filter(user -> user.getAge() >= 18)
     .map(User::getName)
     .toList();
```

the **data source** is `users`.

`.stream()` doesn't magically create data. It creates a `Stream` that knows **how to traverse/process the elements supplied by that source**.


[[Java]]