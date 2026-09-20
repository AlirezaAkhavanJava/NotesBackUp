
# `parallelStream()` — Complete Definition

## Definition

**`parallelStream()`** is a method on `Collection<E>` (and `Stream` has an equivalent `.parallel()` conversion method) that returns a **`Stream`** configured to process its elements using **multiple threads simultaneously**, splitting the workload across the available CPU cores — implementing the parallelism concepts from the parallelism tutorial, applied directly to the Stream API you just finished reviewing.

```java
List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8);

int sum = numbers.parallelStream()
    .mapToInt(n -> n * n)
    .sum();
```

This connects the Stream API method reference you just read to the parallelism tutorial from earlier — every intermediate/terminal method covered there (`filter`, `map`, `reduce`, `collect`, etc.) works identically on a parallel stream; what changes is **how** the work gets distributed and executed underneath.

---

## `stream()` vs `parallelStream()` — the only difference

```java
Stream<Integer> sequential = numbers.stream();          // runs on ONE thread, in order
Stream<Integer> parallel = numbers.parallelStream();      // may run across MULTIPLE threads, order not guaranteed during processing
```

You can also convert either way explicitly:

```java
numbers.stream().parallel();     // sequential → parallel
numbers.parallelStream().sequential(); // parallel → sequential
```

**Every method signature is identical** — `filter()`, `map()`, `reduce()`, `collect()`, all work exactly the same way syntactically. The difference is purely in the **execution strategy** underneath.

---

## How it actually works — `ForkJoinPool`

This directly connects to the `ForkJoinPool` mentioned in the parallelism tutorial:

```
parallelStream() splits the data into chunks (using a "fork/join" divide-and-conquer strategy)
      │
      ▼
Each chunk processed on a separate thread, from ForkJoinPool.commonPool()
      │
      ▼
Results combined ("joined") back together into the final result
```

```java
int cores = Runtime.getRuntime().availableProcessors(); // the common pool defaults to using this many threads
```

By default, `parallelStream()` uses a **shared, JVM-wide thread pool** (`ForkJoinPool.commonPool()`) — the same pool every parallel stream in your entire application uses, unless you explicitly configure otherwise (covered below).

---

## A worked example showing actual parallel execution

```java
List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8);

numbers.parallelStream().forEach(n -> {
    System.out.println(n + " processed by " + Thread.currentThread().getName());
});
```

**Possible output** (order and thread assignment are NOT predictable — this is the exact non-determinism discussed in the concurrency tutorials):

```
3 processed by main
1 processed by ForkJoinPool.commonPool-worker-1
5 processed by ForkJoinPool.commonPool-worker-3
2 processed by ForkJoinPool.commonPool-worker-2
...
```

Notice **`main` itself participates** — the calling thread joins in as one of the workers, rather than sitting idle while only pool threads do the work.

---

## When `parallelStream()` genuinely helps — recap with more detail

This directly extends the "when parallelism helps" table from the parallelism tutorial, applied specifically to streams:

### Good candidate: large dataset, genuinely CPU-heavy work per element

```java
List<BigInteger> largeNumbers = generateMillionLargeNumbers();

List<BigInteger> primes = largeNumbers.parallelStream()
    .filter(BigIntegerUtils::isPrime) // expensive computation per element
    .toList();
```

Each element requires substantial, independent CPU work — exactly the divide-and-conquer scenario multiple cores genuinely help with.

### Bad candidate: small dataset

```java
List<Integer> tiny = List.of(1, 2, 3);
tiny.parallelStream().map(n -> n * 2).toList(); // SLOWER than .stream() here
```

**Why it's slower:** splitting the work across threads, coordinating them, and merging results all cost real overhead — for 3 elements doing trivial work, that coordination cost dwarfs any benefit. This is a direct, concrete instance of the parallelism tutorial's warning about coordination overhead outweighing benefit at small scale.

### Bad candidate: I/O-bound work

```java
List<String> urls = List.of(/* many URLs */);

// WRONG tool for this — parallelStream() is for CPU-bound work, not I/O waiting
List<String> responses = urls.parallelStream()
    .map(url -> fetchFromNetwork(url)) // blocked waiting on network, not computing
    .toList();
```

**Why this is the wrong tool:** as the concurrency tutorial explained, I/O-bound work spends most of its time **waiting**, not computing — that's a job for **concurrency** (async, or virtual threads), not **parallelism**. Using `parallelStream()` here ties up `ForkJoinPool` threads sitting blocked on network calls, which can starve the shared pool for _other_ parts of your application that need it for genuine CPU-bound parallel work.

---

## The critical danger: shared mutable state

This is the single most important practical warning, echoing the parallelism tutorial's core caution, now shown specifically in Stream API terms:

```java
// DANGEROUS — race condition, corrupted/incomplete results
List<Integer> results = new ArrayList<>(); // NOT thread-safe

numbers.parallelStream().forEach(n -> {
    results.add(n * 2); // multiple threads calling add() on the SAME ArrayList simultaneously
});

System.out.println(results.size()); // may be LESS than numbers.size() — lost updates!
```

**Why this breaks:** `ArrayList.add()` isn't thread-safe (from the `ArrayList` tutorial) — when multiple threads call it simultaneously on the same list, you get exactly the race condition described in the concurrency tutorials: internal state gets corrupted, and elements can be silently lost.

**The correct approach — let the Stream API handle combining results internally:**

```java
List<Integer> results = numbers.parallelStream()
    .map(n -> n * 2)
    .toList(); // Stream API safely combines partial results from each thread internally
```

**Rule, restated from the parallelism tutorial:** never mutate shared external state from inside a parallel stream's lambda. Use the stream's own terminal operations (`toList()`, `collect()`, `reduce()`, `sum()`) to produce your result — they're specifically designed to combine parallel partial results safely.

---

## `reduce()` in parallel — why the 3-argument overload matters here specifically

This directly connects to the last tutorial's explanation of `reduce()`'s three overloads:

```java
// This works correctly in parallel, because addition is associative
// (order of combining doesn't affect the final result)
int sum = numbers.parallelStream().reduce(0, Integer::sum);
```

```java
// The 3-argument overload becomes necessary when accumulator type ≠ element type
int totalLength = words.parallelStream()
    .reduce(0,
        (partialSum, word) -> partialSum + word.length(), // combine accumulator with an element
        (sum1, sum2) -> sum1 + sum2);                        // combine two threads' partial sums — REQUIRED for parallel correctness
```

**Why the combiner argument specifically matters for parallel streams:** each thread processes its own chunk and produces its own partial accumulated value; the `combiner` function is what merges those independent partial results back into one final answer. Without it (i.e., using only the 2-argument overload when types genuinely differ), the parallel case would have no way to combine partial results — which is exactly why that overload doesn't compile for mismatched types in the first place.

**Important correctness requirement:** the accumulator/combiner functions must be **associative** — `(a op b) op c` must equal `a op (b op c)` — since parallel execution might combine partial results in any order. Addition and multiplication are associative; subtraction and division are not, and using them with `reduce()` on a parallel stream can silently produce wrong, order-dependent results.

```java
// DANGEROUS on a parallel stream — subtraction is NOT associative
int wrong = numbers.parallelStream().reduce(0, (a, b) -> a - b); // result may vary depending on execution order!
```

---

## Isolating parallel work from the shared common pool

Connecting directly to the concurrency tutorials' `ExecutorService`/`ForkJoinPool` content:

```java
ForkJoinPool customPool = new ForkJoinPool(4); // dedicated pool, isolated from the shared common pool

int result = customPool.submit(() ->
    numbers.parallelStream()
        .map(n -> n * n)
        .reduce(0, Integer::sum)
).get();

customPool.shutdown();
```

**Why you might want this:** since `parallelStream()` defaults to the JVM-wide shared `ForkJoinPool.commonPool()`, heavy parallel-stream usage in one part of a large application can starve or slow down parallel streams running elsewhere in the same JVM at the same time — submitting to your own dedicated pool isolates that specific workload, exactly the isolation concern raised for `CompletableFuture` in the threads/thread-pool tutorial.

---

## Ordering — `forEach()` vs `forEachOrdered()`

```java
numbers.parallelStream().forEach(System.out::println);          // order NOT guaranteed
numbers.parallelStream().forEachOrdered(System.out::println);     // order IS guaranteed — but loses much of the parallel benefit
```

**Why `forEachOrdered()` largely defeats the purpose:** enforcing encounter order across threads that finished at different times requires extra coordination — effectively serializing much of the work back together, which is exactly the kind of coordination overhead the parallelism tutorial warned reduces (or eliminates) the speed benefit.

---

## Summary

|Aspect|Detail|
|---|---|
|What it is|a `Stream` that processes elements across multiple threads|
|Created via|`collection.parallelStream()`, or `stream.parallel()`|
|Underlying mechanism|`ForkJoinPool.commonPool()` — shared JVM-wide by default|
|Best for|large datasets, genuinely CPU-heavy per-element work|
|Bad for|small datasets, I/O-bound work, non-associative reductions|
|Critical danger|mutating shared external state from within — causes race conditions|
|Safe pattern|let terminal ops (`toList()`, `collect()`, `reduce()`) combine results internally|
|Ordering|not guaranteed by default; `forEachOrdered()` restores it at a performance cost|
|Isolating from shared pool|submit through your own custom `ForkJoinPool`|

## Where this closes the loop

`parallelStream()` is the single feature that ties together nearly everything from the last several tutorials: it's the Stream API (previous tutorial) running on the parallelism/`ForkJoinPool` machinery (parallelism tutorial), subject to the exact same shared-mutable-state race-condition dangers as raw threads (concurrency tutorials), and its correctness for `reduce()` specifically depends on the functional-interface composition rules (`Function`/`BinaryOperator`) from the functional interface tutorials. Every concept from this entire conversation's arc — from basic I/O through threads, concurrency, collections, and streams — converges directly in this one method.


[[Java]]