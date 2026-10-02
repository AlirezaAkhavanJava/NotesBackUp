

A **Stream** in the Java Stream API is an abstraction for **processing a sequence of elements through a pipeline of operations**.

It was introduced in **Java 8** in `java.util.stream`.

The important idea is:

> **A Stream does not store data. It processes data coming from a source.**

For example:

```java
List<String> names = List.of("Ali", "John", "Sara", "Mike");

names.stream()
     .filter(name -> name.length() > 3)
     .map(String::toUpperCase)
     .forEach(System.out::println);
```

Conceptually:

```text
List
 │
 ▼
Stream
 │
 ├── filter()
 │
 ├── map()
 │
 └── forEach()
       │
       ▼
     output
```

---

# 1. Stream vs Collection

This distinction is fundamental.

### Collection

A `Collection` **stores data**:

```java
List<Integer> numbers = List.of(1, 2, 3, 4, 5);
```

It answers:

> "What data do I have?"

### Stream

A `Stream` **processes data**:

```java
numbers.stream()
       .filter(n -> n % 2 == 0)
       .forEach(System.out::println);
```

It answers:

> "What do I want to do with this data?"

So:

```text
Collection → data
Stream     → computation over data
```

---

# 2. A Stream has a Source

A Stream normally starts from some **source**.

For example:

```java
List<Integer> numbers = List.of(1, 2, 3, 4);

Stream<Integer> stream = numbers.stream();
```

The source is the `List`.

Other sources can include:

```java
Set
Map
Array
Files
Generated values
Another Stream
```

Examples:

```java
Arrays.stream(array);
```

```java
Stream.of(1, 2, 3, 4);
```

```java
IntStream.range(0, 10);
```

---

# 3. Stream Pipeline

A Stream is usually used as a **pipeline**:

```text
SOURCE
  ↓
INTERMEDIATE OPERATIONS
  ↓
INTERMEDIATE OPERATIONS
  ↓
TERMINAL OPERATION
```

Example:

```java
List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6);

numbers.stream()
       .filter(n -> n % 2 == 0)
       .map(n -> n * 10)
       .forEach(System.out::println);
```

Pipeline:

```text
1 2 3 4 5 6
      ↓
    filter
      ↓
   2 4 6
      ↓
     map
      ↓
  20 40 60
      ↓
   forEach
```

---

# 4. Intermediate Operations

Intermediate operations **transform a Stream into another Stream**.

Common ones:

|Operation|Purpose|
|---|---|
|`filter()`|Keep elements matching a condition|
|`map()`|Transform each element|
|`flatMap()`|Flatten nested structures|
|`distinct()`|Remove duplicates|
|`sorted()`|Sort elements|
|`limit()`|Keep first N|
|`skip()`|Skip first N|
|`peek()`|Observe elements|

Example:

```java
numbers.stream()
       .filter(n -> n > 10)
       .map(n -> n * 2)
       .distinct()
       .sorted();
```

Notice something important:

**Nothing necessarily happens yet.**

These operations are generally **lazy**.

---

# 5. Terminal Operations

A terminal operation **ends the Stream pipeline**.

Examples:

```java
forEach()
collect()
toList()
count()
reduce()
findFirst()
findAny()
anyMatch()
allMatch()
noneMatch()
min()
max()
```

Example:

```java
List<Integer> result =
        numbers.stream()
               .filter(n -> n % 2 == 0)
               .map(n -> n * 10)
               .toList();
```

Here:

```text
stream()
   ↓
filter()
   ↓
map()
   ↓
toList()   ← terminal operation
```

`toList()` causes the pipeline to actually execute.

---

# 6. Streams Are Lazy

This is one of the most important concepts.

Consider:

```java
numbers.stream()
       .filter(n -> {
           System.out.println("Filtering " + n);
           return n > 2;
       });
```

You won't see the filtering output merely from creating this pipeline.

Why?

Because there is **no terminal operation**.

Add:

```java
numbers.stream()
       .filter(n -> {
           System.out.println("Filtering " + n);
           return n > 2;
       })
       .toList();
```

Now the pipeline executes.

Think:

```text
stream()
filter()
map()
        ↓
   "recipe"
        ↓
terminal operation
        ↓
   EXECUTION
```

---

# 7. Streams Don't Modify the Source

Given:

```java
List<Integer> numbers = List.of(1, 2, 3, 4);
```

You can do:

```java
List<Integer> result =
        numbers.stream()
               .map(n -> n * 10)
               .toList();
```

You now have:

```text
numbers → [1, 2, 3, 4]

result  → [10, 20, 30, 40]
```

The Stream didn't transform the original `List`.

---

# 8. A Stream Is Usually Single-Use

Once a terminal operation has consumed a Stream, you shouldn't reuse it.

```java
Stream<Integer> stream = numbers.stream();

stream.count();

stream.forEach(System.out::println); // IllegalStateException
```

A Stream represents a **one-time traversal/computation pipeline**.

If you need another operation:

```java
numbers.stream().count();

numbers.stream().forEach(System.out::println);
```

Create another Stream.

---

# 9. Stream Is Not a Data Structure

This distinction is extremely important:

```java
List<Integer>
```

is a data structure.

```java
Stream<Integer>
```

is **not** a data structure.

A Stream doesn't normally contain its own collection of elements.

Instead:

```text
Collection
    │
    │ provides elements
    ▼
 Stream
    │
    │ processes elements
    ▼
 Result
```

---

# 10. Streams Can Be Infinite

A Stream doesn't necessarily have a fixed number of elements.

For example:

```java
Stream.iterate(0, n -> n + 1)
```

Conceptually:

```text
0 → 1 → 2 → 3 → 4 → 5 → ...
```

You can limit it:

```java
Stream.iterate(0, n -> n + 1)
       .limit(10)
       .forEach(System.out::println);
```

This is another reason a Stream isn't simply a collection.

---

# 11. Streams Can Be Parallel

Java also supports parallel streams:

```java
numbers.parallelStream()
       .filter(...)
       .map(...)
       .toList();
```

This allows the Stream pipeline to potentially process elements using multiple threads.

There are important performance and thread-safety considerations here, though. **Parallel streams are not automatically faster.**

---

# 12. The Three Main Parts

For learning the Stream API, remember this model:

```text
             STREAM PIPELINE

        ┌─────────────────┐
        │      SOURCE     │
        │                 │
        │ List / Set /    │
        │ Array / etc.    │
        └────────┬────────┘
                 │
                 ▼
        ┌─────────────────┐
        │  INTERMEDIATE   │
        │   OPERATIONS    │
        │                 │
        │ filter          │
        │ map             │
        │ sorted          │
        │ distinct        │
        │ flatMap         │
        └────────┬────────┘
                 │
                 ▼
        ┌─────────────────┐
        │    TERMINAL     │
        │    OPERATION    │
        │                 │
        │ collect         │
        │ toList          │
        │ reduce          │
        │ count           │
        │ forEach         │
        └────────┬────────┘
                 │
                 ▼
               RESULT
```

### The mental model

**Collection = "I have data."**

**Stream = "I want to process that data."**

And:

```java
source
    .stream()
    .intermediateOperation()
    .intermediateOperation()
    .terminalOperation();
```

For example:

```java
List<String> result =
        users.stream()
             .filter(user -> user.getAge() >= 18)
             .map(User::getUserName)
             .sorted()
             .toList();
```

This means:

> Take users → keep adults → extract usernames → sort them → produce a `List`.

That's the core of the **Java Stream API**.



[[Java]]