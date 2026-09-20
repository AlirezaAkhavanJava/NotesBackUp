

The **Stream API** has several rules that explain how streams behave and how you should use them correctly.

## 1. A Stream does not store data

A `Stream` is **not a collection**.

It provides a pipeline for processing data from a source.

```java
List<String> names = List.of("Ali", "John", "Sara");

Stream<String> stream = names.stream();
```

Here:

```text
List
 │
 ▼
Stream
 │
 ▼
processing
```

The `List` owns the data. The `Stream` processes it.

---

## 2. A Stream has a source

Every stream originates from a **source**.

Common sources:

```java
list.stream();
set.stream();
Arrays.stream(array);
Stream.of("A", "B", "C");
```

Conceptually:

```text
SOURCE → STREAM PIPELINE → RESULT
```

---

## 3. Streams are lazy

**Intermediate operations are not executed immediately.**

```java
names.stream()
     .filter(name -> name.length() > 3);
```

Nothing actually happens yet.

Execution starts when you invoke a **terminal operation**:

```java
names.stream()
     .filter(name -> name.length() > 3)
     .forEach(System.out::println);
```

So:

```text
stream()
   ↓
filter()       ← lazy
   ↓
map()          ← lazy
   ↓
collect()      ← triggers execution
```

---

## 4. A Stream has intermediate operations

Intermediate operations transform or filter a stream and return **another Stream**.

Examples:

|Operation|Purpose|
|---|---|
|`filter()`|Keep elements satisfying a condition|
|`map()`|Transform elements|
|`flatMap()`|Flatten nested streams|
|`distinct()`|Remove duplicates|
|`sorted()`|Sort elements|
|`limit()`|Keep at most N elements|
|`skip()`|Skip N elements|
|`peek()`|Observe elements|

Example:

```java
names.stream()
     .filter(name -> name.length() > 3)
     .map(String::toUpperCase)
     .sorted();
```

All three are intermediate operations.

---

## 5. A Stream normally ends with a terminal operation

A **terminal operation** produces a result or side effect and consumes the stream.

Examples:

```java
collect()
forEach()
count()
reduce()
min()
max()
findFirst()
findAny()
anyMatch()
allMatch()
noneMatch()
```

Example:

```java
long count = names.stream()
        .filter(name -> name.length() > 3)
        .count();
```

---

# 6. A Stream can be consumed only once

This is one of the most important rules.

```java
Stream<String> stream = names.stream();

stream.count();

stream.forEach(System.out::println); // ERROR
```

After the terminal operation, the stream is **closed/consumed**.

If you need another operation, create another stream:

```java
names.stream().count();

names.stream().forEach(System.out::println);
```

Think:

```text
Stream
  ↓
terminal operation
  ↓
CONSUMED
  ↓
cannot reuse
```

---

## 7. Intermediate operations don't modify the source

Streams generally do not modify the collection they process.

```java
List<Integer> numbers = List.of(1, 2, 3, 4);

List<Integer> result = numbers.stream()
        .filter(n -> n % 2 == 0)
        .toList();
```

The original list remains:

```text
numbers = [1, 2, 3, 4]

result  = [2, 4]
```

The stream created a processing pipeline; it did not remove `1` and `3` from `numbers`.

---

## 8. A Stream pipeline is ordered

A pipeline executes operations in the order they appear.

```java
numbers.stream()
       .filter(n -> n > 10)
       .map(n -> n * 2)
       .limit(5)
       .toList();
```

Conceptually:

```text
source
  ↓
filter
  ↓
map
  ↓
limit
  ↓
toList
```

Changing the order can change the result and performance.

---

## 9. Intermediate operations are usually fused

The Stream implementation doesn't necessarily create a separate collection after every operation.

For example:

```java
numbers.stream()
       .filter(n -> n > 10)
       .map(n -> n * 2)
       .toList();
```

Conceptually, you can think of it as:

```text
element
   ↓
filter
   ↓
map
   ↓
next element
```

rather than:

```text
collection
 ↓
temporary collection
 ↓
temporary collection
 ↓
final collection
```

This is a major reason streams can be efficient.

---

## 10. Streams can be sequential or parallel

By default:

```java
numbers.stream()
```

creates a **sequential stream**.

You can create a parallel stream:

```java
numbers.parallelStream();
```

or:

```java
numbers.stream().parallel();
```

Conceptually:

```text
Sequential:

A → B → C → D


Parallel:

A ─┐
B ─┤
C ─┤ → processing
D ─┘
```

Parallel streams should not automatically be assumed to be faster.

---

## 11. Avoid modifying shared state inside a stream

This is a common mistake:

```java
List<Integer> result = new ArrayList<>();

numbers.stream()
       .filter(n -> n > 10)
       .forEach(result::add);
```

It may appear fine for a sequential stream, but shared mutable state becomes especially dangerous with parallel streams.

Prefer:

```java
List<Integer> result = numbers.stream()
        .filter(n -> n > 10)
        .toList();
```

Streams work best with **stateless transformations**.

---

## 12. Intermediate operations should generally be stateless

Good:

```java
.map(n -> n * 2)
.filter(n -> n > 10)
```

These depend only on the current element.

Problematic:

```java
int counter = 0;

numbers.stream()
       .map(n -> {
           counter++;
           return n * 2;
       });
```

The lambda now depends on external mutable state.

This becomes particularly problematic with parallel streams.

---

## 13. Some operations are stateful

Not every intermediate operation can process an element completely independently.

For example:

```java
sorted()
distinct()
```

may need information about multiple elements.

Example:

```java
numbers.stream()
       .sorted()
       .toList();
```

`sorted()` must know enough about the entire stream to produce the correct ordering.

Common **stateful** operations:

```text
distinct()
sorted()
limit()
skip()
```

---

## 14. Short-circuiting operations can stop early

Some operations don't need to process the entire stream.

For example:

```java
boolean found = numbers.stream()
        .anyMatch(n -> n > 100);
```

Once a matching element is found, processing can stop.

Other short-circuiting operations include:

```java
findFirst()
findAny()
anyMatch()
allMatch()
noneMatch()
limit()
```

Conceptually:

```text
1 → 2 → 3 → 101 → STOP
            ↑
          match
```

This is another important part of stream performance.

---

# 15. `map()` should not be confused with `filter()`

### `filter()`

Decides **whether an element remains**.

```java
.filter(n -> n > 10)
```

```text
10 → ❌
20 → ✅
30 → ✅
```

### `map()`

Changes **what the element becomes**.

```java
.map(n -> n * 2)
```

```text
10 → 20
20 → 40
30 → 60
```

---

# 16. `map()` normally preserves the number of elements

```java
Stream.of(1, 2, 3)
      .map(n -> n * 10)
```

```text
1 → 10
2 → 20
3 → 30
```

3 elements in → 3 elements out.

`filter()` can reduce the number:

```text
1 → ❌
2 → 2
3 → ❌
```

`flatMap()` can change the number in either direction.

---

# 17. `flatMap()` converts nested structures into one stream

Example:

```java
List<List<Integer>> numbers = List.of(
        List.of(1, 2),
        List.of(3, 4)
);
```

Using:

```java
numbers.stream()
       .flatMap(List::stream)
       .toList();
```

Result:

```text
[1, 2, 3, 4]
```

Conceptually:

```text
Stream<List<Integer>>
        ↓
flatMap()
        ↓
Stream<Integer>
```

---

# 18. Don't use streams when a normal loop is clearer

Streams are a tool, not a requirement.

This:

```java
for (User user : users) {
    if (user.isActive()) {
        sendEmail(user);
    }
}
```

may be clearer than forcing everything into:

```java
users.stream()
     .filter(User::isActive)
     .forEach(this::sendEmail);
```

Especially when you have complicated control flow, debugging, mutation, or exception handling.

---

# The core Stream mental model

Remember this:

```text
             STREAM PIPELINE

SOURCE
  │
  ▼
stream()
  │
  ├── filter()   ← intermediate
  │
  ├── map()      ← intermediate
  │
  ├── sorted()   ← intermediate
  │
  └── limit()    ← intermediate
          │
          ▼
   TERMINAL OPERATION
          │
          ▼
       RESULT
```

And the **7 rules I'd memorize first** are:

1. **A Stream processes data; it doesn't store it.**
    
2. **A Stream has a source.**
    
3. **Intermediate operations are lazy.**
    
4. **A terminal operation triggers execution.**
    
5. **A Stream cannot normally be reused after a terminal operation.**
    
6. **Streams don't normally modify their source.**
    
7. **Prefer stateless operations and avoid shared mutable state.**
    

These rules form the foundation for understanding `filter`, `map`, `flatMap`, `reduce`, `collect`, `Optional`, and parallel streams.


[[Java]]