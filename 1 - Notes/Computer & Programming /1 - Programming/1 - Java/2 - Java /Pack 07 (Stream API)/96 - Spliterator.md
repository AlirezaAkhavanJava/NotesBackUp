


A **`Spliterator`** is a Java interface used to **traverse and potentially split a source of elements**.

The name comes from:

> **SPL**itting + i**TERATOR**

It is one of the mechanisms underneath the Java Stream API.

### Basic relationship

```text
Collection
    │
    ▼
Spliterator
    │
    ▼
Stream pipeline
    │
    ▼
Result
```

For example:

```java
List<Integer> numbers = List.of(10, 20, 30, 40);

Stream<Integer> stream = numbers.stream();
```

Conceptually, Java obtains a `Spliterator` from the `List`:

```java
Spliterator<Integer> spliterator =
        numbers.spliterator();
```

The `Spliterator` knows how to **traverse the elements** of the list.

---

### Why not just use `Iterator`?

An `Iterator` primarily does:

```text
element → element → element → element
```

A `Spliterator` can do that **and can split the work**:

```text
             [10,20,30,40,50,60]
                       │
                 trySplit()
                    /     \
                   /       \
            [10,20,30]   [40,50,60]
```

This splitting capability is important for **parallel streams**.

For example:

```java
numbers.parallelStream()
       .filter(...)
       .map(...)
       .toList();
```

The Stream framework can split the source into portions and potentially process those portions concurrently.

---

### The key distinction

`Spliterator` is **not the pipeline itself**.

It is closer to the **mechanism that provides/traverses the source elements**.

```text
             DATA SOURCE
                 │
                 ▼
            Spliterator
          /      │      \
         ▼       ▼       ▼
       10       20      30 ...
         \       │       /
          ▼      ▼      ▼
        Stream pipeline
              │
              ▼
            Result
```

So when you write:

```java
numbers.stream()
```

you're essentially asking Java to create a Stream over the elements supplied by the collection's traversal mechanism.




[[Java]]