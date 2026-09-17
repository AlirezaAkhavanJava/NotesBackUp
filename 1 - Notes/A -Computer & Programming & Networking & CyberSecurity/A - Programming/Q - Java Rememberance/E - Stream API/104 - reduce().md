


## Definition

**`reduce()`** is a **terminal operation** on the Stream API that combines all elements of a stream into a **single result**, by repeatedly applying a combining function — taking two values and producing one, over and over, until only one value remains.

```java
List<Integer> numbers = List.of(1, 2, 3, 4, 5);

int sum = numbers.stream().reduce(0, (a, b) -> a + b);
System.out.println(sum); // 15
```

You already met the _concept_ briefly in the lambda types tutorial (as an example use of `BinaryOperator`) — this is the full definition of the operation itself.

---

## The problem `reduce()` solves

You already know how to filter and transform a stream (`filter()`, `map()`) — but both of those still produce a **stream** or **collection** as output. Sometimes you don't want a collection back — you want a **single, combined value**: a total, a maximum, a concatenated string, a combined object.

```java
// The manual way, without reduce()
List<Integer> numbers = List.of(1, 2, 3, 4, 5);
int sum = 0;
for (int n : numbers) {
    sum += n; // manually accumulating, step by step
}
```

`reduce()` **solves this by expressing the same "combine everything into one value" pattern declaratively**, using the exact same philosophy as the rest of the Stream API — describing _what_ combination you want, not manually writing the accumulation loop yourself.

```java
int sum = numbers.stream().reduce(0, (a, b) -> a + b);
```

---

## The three overloads of `reduce()`

### 1. `reduce(BinaryOperator<T> accumulator)` — no starting value, returns `Optional<T>`

```java
Optional<Integer> sum = List.of(1, 2, 3, 4).stream()
    .reduce((a, b) -> a + b);

System.out.println(sum.get()); // 10
```

**Why it returns `Optional<T>`, not `T` directly:** if the stream is **empty**, there's no possible result to return — no starting value was given to fall back on. Wrapping the result in `Optional` (connecting directly to the `Optional` tutorial) makes that "might have no result" possibility explicit and safe, rather than throwing an exception or returning some arbitrary sentinel value.

```java
Optional<Integer> result = List.<Integer>of().stream()
    .reduce((a, b) -> a + b);

System.out.println(result.isPresent()); // false — empty stream, no result to give
```

### 2. `reduce(T identity, BinaryOperator<T> accumulator)` — with a starting value, returns `T` directly

```java
int sum = List.of(1, 2, 3, 4).stream()
    .reduce(0, (a, b) -> a + b); // 0 is the starting value ("identity")

System.out.println(sum); // 10
```

**Why this version returns `T` directly, not `Optional<T>`:** if the stream is empty, there's now always a sensible answer to give — the identity value itself.

```java
int sum = List.<Integer>of().stream()
    .reduce(0, (a, b) -> a + b);

System.out.println(sum); // 0 — the identity value, since there was nothing to combine
```

**What "identity" means here:** the identity value is one that, when combined with any element, doesn't change anything — `0` for addition (`x + 0 = x`), `1` for multiplication (`x * 1 = x`), `""` for string concatenation, an empty list for combining lists. Choosing the wrong identity silently produces the wrong result:

```java
int product = List.of(2, 3, 4).stream()
    .reduce(0, (a, b) -> a * b); // WRONG identity for multiplication!
System.out.println(product); // 0 — everything multiplied by 0 collapses to 0

int correctProduct = List.of(2, 3, 4).stream()
    .reduce(1, (a, b) -> a * b); // correct identity
System.out.println(correctProduct); // 24
```

### 3. `reduce(U identity, BiFunction<U,T,U> accumulator, BinaryOperator<U> combiner)` — for parallel streams, or type-changing reductions

```java
List<String> words = List.of("Hello", "World", "Java");

int totalLength = words.stream()
    .reduce(0,
        (partialSum, word) -> partialSum + word.length(), // combine an int accumulator with a String element
        (sum1, sum2) -> sum1 + sum2);                        // combine two int partial sums (needed for PARALLEL streams)

System.out.println(totalLength); // 14
```

**Why this three-argument version exists:** the accumulator type (`U`, here `int`) can be **different** from the stream's element type (`T`, here `String`) — the first two overloads require the accumulator and elements to be the same type. The third argument (`combiner`) is required because when this runs on a **parallel stream** (from the parallelism tutorial), the stream gets split across multiple threads, each producing its own partial result — the `combiner` tells Java how to merge those partial results back into one.

```java
// This would NOT compile with the simpler 2-argument reduce(), since
// the accumulator type (int) differs from the element type (String):
int totalLength = words.stream().reduce(0, (sum, word) -> sum + word.length()); // COMPILE ERROR
```

---

## How `reduce()` actually works, step by step

```java
List.of(1, 2, 3, 4).stream().reduce(0, (a, b) -> a + b);
```

```
Start:        acc = 0
Step 1:  acc = (0, 1) → 0 + 1 = 1
Step 2:  acc = (1, 2) → 1 + 2 = 3
Step 3:  acc = (3, 3) → 3 + 3 = 6
Step 4:  acc = (6, 4) → 6 + 4 = 10
Result: 10
```

Each step takes the **accumulated result so far** and the **next element**, combines them using your lambda, and that becomes the new accumulated result — continuing until every element has been folded in.

---

## Common real-world examples

### Sum

```java
int total = numbers.stream().reduce(0, Integer::sum); // using the method reference from the earlier tutorial!
```

### Maximum / minimum

```java
Optional<Integer> max = numbers.stream().reduce(Integer::max);
Optional<Integer> min = numbers.stream().reduce(Integer::min);
```

(In practice, `Stream` also has dedicated `max()`/`min()` methods taking a `Comparator` — often clearer for this specific case than raw `reduce()`, but `reduce()` can express the same thing.)

### String concatenation

```java
String combined = List.of("Hello", " ", "World").stream()
    .reduce("", (a, b) -> a + b);
System.out.println(combined); // "Hello World"
```

(Again, `Collectors.joining()` — from the utility classes tutorial — is the more idiomatic tool specifically for joining strings; this is shown to illustrate `reduce()`'s generality.)

### Combining custom objects

```java
class ShoppingCart {
    double total;
    ShoppingCart(double total) { this.total = total; }
    ShoppingCart combine(ShoppingCart other) {
        return new ShoppingCart(this.total + other.total);
    }
}

List<ShoppingCart> carts = List.of(new ShoppingCart(10), new ShoppingCart(25), new ShoppingCart(5));

ShoppingCart merged = carts.stream()
    .reduce(new ShoppingCart(0), ShoppingCart::combine);

System.out.println(merged.total); // 40.0
```

This is where `reduce()` genuinely earns its place over a dedicated method — combining arbitrary custom objects has no built-in shortcut the way sum/max/join do.

---

## `reduce()` vs. `Collectors` — when to use which

```java
// reduce() — combining into a single VALUE (a number, a merged object)
int sum = numbers.stream().reduce(0, Integer::sum);

// collect() with Collectors — building into a COLLECTION or complex structure
List<Integer> doubled = numbers.stream().map(n -> n * 2).toList();
Map<String, Integer> lengths = names.stream().collect(Collectors.toMap(n -> n, String::length));
```

**The practical rule:** if the JDK already provides a dedicated method or `Collectors` factory for what you're doing (`sum()`, `max()`, `count()`, `Collectors.joining()`, `Collectors.toList()`), **prefer that** — it's more readable and often better optimized. Reach for raw `reduce()` when you're combining values in a genuinely custom way that has no built-in equivalent — like the `ShoppingCart` merge example above.

---

## Connecting to the functional interfaces you already know

```java
reduce(BinaryOperator<T> accumulator)                                  // BinaryOperator<T> — same-type combiner
reduce(T identity, BinaryOperator<T> accumulator)                       // same
reduce(U identity, BiFunction<U,T,U> accumulator, BinaryOperator<U> combiner) // BiFunction + BinaryOperator
```

This is exactly why the earlier `Function`/`Predicate` tutorials matter here — `reduce()`'s signature is built entirely out of the functional interfaces you've already learned (`BinaryOperator<T>`, which itself is a specialization of `BiFunction<T,T,T>`, as covered in the lambda types tutorial).

---

## Summary table

|Overload|Signature|Returns|Use when|
|---|---|---|---|
|1-arg|`reduce(BinaryOperator<T>)`|`Optional<T>`|no natural starting value; stream might be empty|
|2-arg|`reduce(T identity, BinaryOperator<T>)`|`T`|you have a sensible starting/identity value|
|3-arg|`reduce(U identity, BiFunction<U,T,U>, BinaryOperator<U>)`|`U`|accumulator type differs from element type, or need parallel-safe combining|

## Where this fits with everything you've learned

`reduce()` is the direct generalization of `Stream.sum()`/`count()`/`Collectors.joining()` — those are all specific, named cases of the same underlying "combine everything into one value" pattern `reduce()` expresses generically. It's also a genuinely good, concrete illustration of the concurrency/parallelism tutorial's "shared mutable state" warning: the 3-argument overload's `combiner` exists **specifically** because parallel streams split work across threads (from the parallelism tutorial), and `reduce()`'s functional, no-shared-mutable-state design is exactly _why_ it can be safely parallelized — unlike a hand-written accumulator loop, which would need explicit synchronization to be thread-safe.


[[Java]]