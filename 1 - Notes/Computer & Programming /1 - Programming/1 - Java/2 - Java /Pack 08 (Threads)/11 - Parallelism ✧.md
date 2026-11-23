

Parallelism means multiple tasks running at the exact same instant, on multiple CPU cores — not just taking turns (that's concurrency), but genuinely simultaneous. 

Concurrency fixes wasted _waiting_ time (I/O, network, timers); 
parallelism fixes slow _computing_ time — crunching numbers, processing large datasets, anything that's actively using the CPU rather than idling on it. 

On a single core, splitting that kind of work into more threads doesn't make it finish faster — the core still does every unit of work one at a time, just interleaved. Only real, separate hardware cores running different pieces of work at once actually cuts the total time.

```java
int cores = Runtime.getRuntime().availableProcessors();
```

This is the one hard requirement: parallelism needs multiple cores. Modern CPUs have several (4, 8, 16+), which is what makes it practical — and `availableProcessors()` is a real line you'll use to size parallel work to the hardware it's running on.

### Getting parallelism in Java

**`parallelStream()`** — the default first choice. Same Stream API you already know, just splitting the pipeline across cores via the shared `ForkJoinPool.commonPool()`:

```java
int sum = numbers.parallelStream()
    .mapToInt(n -> expensiveComputation(n))
    .sum();
```

It only pays off for CPU-heavy work on large datasets — the coordination overhead can make it _slower_ than `.stream()` on small collections or I/O-bound work, where the CPU was never the bottleneck to begin with.

**`ForkJoinPool`** directly — the engine underneath `parallelStream()`, for when you need a custom divide-and-conquer algorithm instead of what the Stream API gives you:

```java
ForkJoinPool pool = new ForkJoinPool();
int result = pool.invoke(new RecursiveTask<Integer>() {
    protected Integer compute() { /* split, recurse, combine */ return 42; }
});
```

You'd reach for this far less often than `parallelStream()` — it's for genuinely custom algorithms, not everyday CPU-bound work.

**`ExecutorService`**, sized to core count — for when you want an isolated pool rather than sharing the common `ForkJoinPool` with the rest of the JVM:

```java
ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
```

### The cost: shared state gets more dangerous, not less

Because parallel tasks truly overlap in time, there's never a moment where only one thread is touching shared state — so unsynchronized mutation isn't an occasional accident, it's a constant risk:

```java
List<Integer> results = new ArrayList<>();
numbers.parallelStream().forEach(n -> results.add(n * 2)); // race condition — not thread-safe

List<Integer> results = numbers.parallelStream()
    .map(n -> n * 2)
    .toList(); // correct — let the Stream API combine results internally
```

The fix is almost never "add synchronization" — it's "don't mutate shared external state from inside the lambda" and let `toList()`/`collect()`/`sum()` do the combining.

### Summary

||Core idea|Needs multiple cores?|Fixes|
|---|---|---|---|
|Concurrency|tasks progress during overlapping time|No|wasted idle/waiting time|
|Parallelism|tasks execute at the literal same instant|Yes|slow CPU computation|

Threads are the mechanism, concurrency is the general goal, and parallelism is the specific case where you have real cores and real computation to split across them. In a typical Spring Boot app, most concurrency needs — handling many simultaneous requests, mostly waiting on a database — are solved by ordinary or virtual threads, not parallel streams; you reach for parallelism deliberately, for things like batch jobs or image processing.



[[Threads]]