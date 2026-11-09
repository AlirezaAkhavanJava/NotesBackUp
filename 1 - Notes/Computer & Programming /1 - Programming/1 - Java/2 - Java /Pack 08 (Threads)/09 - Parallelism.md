

## Definition

**Parallelism** is when multiple tasks are executed **at the literal same instant in time**, using multiple independent processing units (CPU cores). It requires genuine simultaneous execution — not just "in progress during overlapping time" (that's concurrency), but actually running _right now, together_.

You already got the core contrast in the last tutorial — this one goes deeper specifically into parallelism: what makes it possible, how Java gives you access to it, and the distinct problems it introduces.

---

## The problem parallelism solves

Concurrency solves "don't waste time waiting" — it helps when tasks spend time idle (waiting on I/O, a network response, a timer). But some tasks aren't waiting at all — they're **actively computing**, continuously, doing real CPU work: crunching numbers, processing large datasets, running complex calculations, resizing thousands of images.

For pure computation like that, concurrency alone doesn't help — if you only have one CPU core, switching between tasks doesn't make the total work finish any faster, since the core still has to do all the work sequentially, just interleaved.

**Parallelism solves this by genuinely splitting the work across multiple CPU cores, so the actual total time to finish is reduced** — because real, independent hardware is doing different pieces of the work simultaneously, not just taking turns.

```
Single core doing 4 units of pure computation work (concurrency doesn't help here):
Core 1: [Work 1][Work 2][Work 3][Work 4]   → total time = 4 units

4 cores doing the same 4 units of work IN PARALLEL:
Core 1: [Work 1]
Core 2: [Work 2]
Core 3: [Work 3]
Core 4: [Work 4]                            → total time = 1 unit
```

---

## The requirement: multiple cores (or processors)

This is the one hard requirement that distinguishes parallelism from concurrency: **you cannot achieve true parallelism on a single CPU core.** A single core, no matter how the OS schedules things, can only execute one instruction at a time. What looks like "simultaneous" execution on a single core is actually rapid switching (concurrency) — genuinely convincing, but not literally simultaneous.

Modern CPUs typically have multiple cores (4, 8, 16+), which is exactly what makes real parallelism achievable on ordinary hardware today.

```java
int cores = Runtime.getRuntime().availableProcessors();
System.out.println("Available cores: " + cores);
```

This is a genuinely useful line in real code — parallel task-splitting decisions often size themselves based on this number.

---

## How Java gives you parallelism

### 1. Parallel streams (Stream API — connects directly back to your earlier lambda/stream tutorial)

```java
List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

int sum = numbers.parallelStream()          // just .parallelStream() instead of .stream()!
    .mapToInt(n -> expensiveComputation(n))
    .sum();
```

**Problem it solves:** turns a sequential Stream API pipeline (which we covered — filter/map/reduce) into one that automatically splits the work across multiple cores, using a shared thread pool behind the scenes (the **ForkJoinPool**, specifically `ForkJoinPool.commonPool()`).

**When to actually use `parallelStream()`:** only for **CPU-intensive** work on a **large enough dataset** that the overhead of splitting/coordinating work across threads is worth it. For small datasets, or for I/O-bound work (network calls, file reads), `parallelStream()` often performs _worse_ than a regular sequential stream — the coordination overhead outweighs the benefit.

```java
// Good candidate — genuinely CPU-heavy, large dataset
List<Double> results = hugeListOfNumbers.parallelStream()
    .map(n -> complexMathOperation(n)) // real computation per element
    .toList();

// Bad candidate — small list, trivial work — overhead not worth it
List<Integer> tiny = List.of(1, 2, 3);
tiny.parallelStream().map(n -> n * 2).toList(); // slower than .stream() here, in practice
```

### 2. `ForkJoinPool` — the engine behind parallel streams, usable directly

```java
import java.util.concurrent.*;

ForkJoinPool pool = new ForkJoinPool(); // defaults to using all available cores

RecursiveTask<Integer> task = new RecursiveTask<>() {
    @Override
    protected Integer compute() {
        // split the problem into smaller sub-tasks, recursively,
        // and combine results — the "fork/join" pattern
        return 42; // simplified
    }
};

int result = pool.invoke(task);
```

**Problem it solves:** `ForkJoinPool` is designed specifically for **divide-and-conquer** parallel algorithms — split a big problem into smaller pieces recursively, solve each piece (possibly in parallel), then combine the results. This is a more advanced/manual tool than `parallelStream()` — you'd reach for `parallelStream()` first in almost all cases; raw `ForkJoinPool` usage is for genuinely custom parallel algorithms.

### 3. `ExecutorService` with a fixed thread pool sized to your cores

```java
int cores = Runtime.getRuntime().availableProcessors();
ExecutorService executor = Executors.newFixedThreadPool(cores);

List<Future<Integer>> futures = new ArrayList<>();
for (int i = 0; i < 100; i++) {
    int taskId = i;
    futures.add(executor.submit(() -> expensiveComputation(taskId)));
}

for (Future<Integer> future : futures) {
    System.out.println(future.get()); // blocks until that task's result is ready
}
executor.shutdown();
```

**Problem it solves:** gives you direct control over exactly how many threads run your CPU-bound tasks in parallel, rather than relying on `parallelStream()`'s shared default pool — useful when you want isolation from other parallel work happening elsewhere in the same JVM (since `parallelStream()` uses a **shared, global** pool by default, heavy use in one part of your app can slow down parallel streams elsewhere).

---

## Parallelism introduces the same shared-memory problems as concurrency — often worse

Since parallel tasks genuinely execute _simultaneously_ (not just interleaved), race conditions become **more frequent and more severe** — there's no moment where "only one thread is actually running," so any unsynchronized shared state is a real, constant risk, not just an occasional interleaving accident.

```java
// DANGEROUS in a parallel stream — shared mutable state, real simultaneous access
List<Integer> results = new ArrayList<>(); // NOT thread-safe!

numbers.parallelStream().forEach(n -> results.add(n * 2)); // race condition — corrupted list, lost elements

// CORRECT — let the Stream API handle combining results safely
List<Integer> results = numbers.parallelStream()
    .map(n -> n * 2)
    .toList(); // Stream API handles safe combination internally
```

**Rule:** avoid mutating shared external state from inside a parallel stream's lambda — let the Stream API's own collection/reduction operations (`toList()`, `collect()`, `sum()`) handle combining results safely. This is the single most common mistake when first using `parallelStream()`.

---

## When parallelism actually helps vs. when it doesn't

|Situation|Parallelism helps?|
|---|---|
|Large dataset, genuinely CPU-heavy computation per element|Yes — real benefit|
|Small dataset (a few dozen elements)|No — coordination overhead dominates|
|I/O-bound work (network calls, file reads, DB queries)|No — use concurrency (async/threads waiting on I/O), not parallelism; the CPU isn't the bottleneck|
|Work with heavy shared mutable state|Risky — race conditions, often needs redesign, not just adding `.parallel()`|
|Single-core environment (rare today, but relevant for constrained systems/containers)|No — no real parallelism is possible; forcing it just adds overhead|

This table is really the practical version of the concurrency-vs-parallelism distinction from before: **concurrency is for waiting; parallelism is for computing.** If your slow operation is "waiting for a database," you want concurrency (async, virtual threads). If your slow operation is "doing millions of floating-point calculations," you want parallelism (parallel streams, thread pools sized to cores).

---

## Summary

|Term|Core idea|Requires multiple cores?|Solves|
|---|---|---|---|
|**Concurrency**|tasks progressing during overlapping time|No|wasted idle/waiting time|
|**Parallelism**|tasks executing at the literal same instant|Yes|slow, heavy CPU computation|

|Java tool|Use for|
|---|---|
|`parallelStream()`|quick, declarative parallel processing of large collections, CPU-bound work|
|`ForkJoinPool`|custom divide-and-conquer parallel algorithms|
|`ExecutorService` (fixed pool sized to cores)|direct control over a dedicated pool for CPU-bound parallel tasks|
|Regular threads / virtual threads|concurrency (especially I/O-bound waiting), not necessarily parallelism|

## Where this fits with everything else you've learned

Parallelism is the piece that completes the picture from the last two tutorials: **threads** are the mechanism, **concurrency** is the general goal (don't waste time), and **parallelism** is the specific case of concurrency where you have real hardware (multiple cores) and real computational work to split across it. In a Spring Boot application, you'd reach for parallelism rarely and deliberately (e.g., processing a large batch job, an image-processing pipeline) — most of a typical web app's concurrency needs (handling many simultaneous requests, mostly waiting on databases/network calls) are solved by ordinary threads/virtual threads, not parallel streams.

[[Java]]