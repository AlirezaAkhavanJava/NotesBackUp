

## Definition

**Concurrency** is the property of a system where multiple tasks make progress **during overlapping periods of time**. It's the general concept; threads (which you just learned) are _one specific mechanism_ Java uses to achieve it.

Note the careful wording: concurrency doesn't necessarily mean tasks run **at the exact same instant** (that's a related but distinct idea called **parallelism**, covered below) — it means the system is structured to handle multiple tasks whose execution overlaps, even if a single CPU core is rapidly switching between them.

---

## The problem concurrency solves

Real programs constantly need to do things that don't finish instantly: read a file, wait for a network response, query a database, wait for user input. If a program did these things **one at a time, strictly sequentially**, it would waste enormous amounts of time just _waiting_ — for example, a web server handling one HTTP request fully (including waiting on a slow database query) before even looking at the next incoming request would be unusably slow with more than one user.

**Concurrency solves the "don't waste time waiting" problem** — while one task is waiting (for I/O, a timer, a lock), the system can make progress on other tasks instead of sitting idle.

```
Sequential (no concurrency):
Task A: [=====wait for DB=====][process]
Task B:                                  [=====wait for DB=====][process]
        (Task B doesn't even START until Task A fully finishes)

Concurrent:
Task A: [====wait for DB====][process]
Task B:      [====wait for DB====][process]
        (both are "in flight" during overlapping time)
```

---

## Concurrency vs. Parallelism — the distinction people often blur

This is genuinely important to get right:

||Concurrency|Parallelism|
|---|---|---|
|Definition|multiple tasks **in progress** during overlapping time|multiple tasks **executing at the literal same instant**|
|Requires multiple CPU cores?|No|Yes|
|Analogy|one chef switching between three dishes, making progress on all of them|three chefs, each cooking one dish, simultaneously|

**Concurrency can happen on a single CPU core** — the OS/JVM rapidly switches between tasks (called **context switching**), giving the _illusion_ of simultaneity even though, at any single instant, only one task is actually executing.

**Parallelism requires multiple cores**, each genuinely executing different work at the same instant.

```
Single core, concurrent (interleaved, not simultaneous):
Core 1: [Task A][Task B][Task A][Task B][Task A]...

Multiple cores, parallel (genuinely simultaneous):
Core 1: [Task A][Task A][Task A]...
Core 2: [Task B][Task B][Task B]...
```

**Parallelism is a subset of what concurrency makes possible** — if you have multiple cores, your concurrent tasks _can_ run in parallel; if you have one core, your concurrent tasks are still concurrent (progressing in overlapping time), just not literally parallel.

---

## Why this distinction matters practically

You don't need multiple CPU cores to benefit from concurrency. The earlier problem (a web server waiting on a slow database query) is solved by concurrency **even on a single core**, because the CPU isn't actually _doing_ anything useful while waiting on I/O anyway — switching to another task during that wait costs nothing real, whether or not you have extra cores.

This connects directly to the virtual threads discussion: virtual threads give you _massive concurrency_ (handling huge numbers of simultaneously in-progress tasks) without needing a matching number of CPU cores — because most of those tasks, at any given moment, are just _waiting_, not actively computing.

---

## How Java achieves concurrency — the mechanisms, tied together

You already know several of these individually; here's how they relate as "ways to achieve concurrency":

|Mechanism|What it is|
|---|---|
|**Threads**|multiple paths of execution within one process, sharing memory (covered last tutorial)|
|**Thread pools (`ExecutorService`)**|reusable, managed sets of threads for running many tasks efficiently|
|**Virtual threads** (Java 21+)|lightweight, JVM-managed threads enabling huge-scale concurrency|
|**`Selector`-based non-blocking I/O** (NIO)|one thread monitoring many I/O channels, avoiding blocking waits|
|**Asynchronous programming** (`CompletableFuture`, callbacks)|code structured to continue without blocking, notified on completion|
|**Reactive programming** (Project Reactor, Spring WebFlux)|a higher-level model built on async/non-blocking concepts|

All of these are **different tools solving the same underlying goal**: let the program make progress on multiple things without one slow operation blocking everything else.

---

## `CompletableFuture` — asynchronous concurrency without manual thread management

```java
import java.util.concurrent.CompletableFuture;

CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
    // runs on a separate thread (from a pool), doesn't block the caller
    return fetchDataFromSlowService();
});

future.thenAccept(result -> System.out.println("Got: " + result)); // runs when ready
System.out.println("This prints immediately, without waiting for the fetch");
```

**Problem it solves:** manually creating and coordinating raw `Thread` objects for every async task is verbose and error-prone. `CompletableFuture` (Java 8+) lets you express "do this, then when it's done, do that" declaratively — connecting directly to the functional interfaces (`Supplier`, `Function`, `Consumer`) you learned earlier, since `CompletableFuture`'s methods (`thenApply`, `thenAccept`, `supplyAsync`) all take exactly those.

```java
CompletableFuture.supplyAsync(() -> fetchUser(id))       // Supplier<User>
    .thenApply(user -> user.getName())                      // Function<User, String>
    .thenAccept(name -> System.out.println("Name: " + name)); // Consumer<String>
```

---

## The core problems that come _with_ concurrency

Concurrency isn't free — it introduces its own class of problems, some of which you already saw with threads:

|Problem|What it is|
|---|---|
|**Race condition**|two tasks access shared data at the same time, producing incorrect results (covered last tutorial)|
|**Deadlock**|two or more tasks each wait forever for a resource the other holds — neither can proceed|
|**Starvation**|a task never gets the resources/CPU time it needs, because others keep getting priority|
|**Livelock**|tasks keep changing state in response to each other, but neither makes real progress|

### Deadlock — a concrete example

```java
Object lockA = new Object();
Object lockB = new Object();

// Thread 1
synchronized (lockA) {
    synchronized (lockB) { /* ... */ }
}

// Thread 2 (running concurrently)
synchronized (lockB) {
    synchronized (lockA) { /* ... */ }
}
```

If Thread 1 grabs `lockA` and Thread 2 grabs `lockB` at nearly the same moment, Thread 1 then waits forever for `lockB` (held by Thread 2), while Thread 2 waits forever for `lockA` (held by Thread 1). Neither can ever proceed. **Fix:** always acquire locks in a consistent, agreed-upon order across all threads.

---

## Java's `java.util.concurrent` package — the toolkit for handling this safely

Rather than hand-rolling `synchronized` blocks everywhere (error-prone, as shown above), Java provides higher-level, safer concurrency utilities:

```java
import java.util.concurrent.atomic.AtomicInteger;

AtomicInteger counter = new AtomicInteger(0);
counter.incrementAndGet(); // thread-safe increment, no synchronized needed
```

```java
import java.util.concurrent.ConcurrentHashMap;

ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>(); // thread-safe map, no manual locking
```

```java
import java.util.concurrent.locks.ReentrantLock;

ReentrantLock lock = new ReentrantLock();
lock.lock();
try {
    // critical section
} finally {
    lock.unlock(); // always unlock in a finally, or a crash leaves it locked forever
}
```

**Problem these solve:** raw `synchronized` is correct but crude — it can be a performance bottleneck (only one thread at a time, even for reads), and manual lock management is easy to get wrong (forgetting to unlock, wrong lock order → deadlock). `java.util.concurrent`'s classes (`AtomicInteger`, `ConcurrentHashMap`, `ReentrantLock`, and many more) provide well-tested, more efficient, purpose-built tools for common concurrent-access patterns.

---

## Summary

|Term|Meaning|
|---|---|
|**Concurrency**|multiple tasks progressing during overlapping time — doesn't require multiple cores|
|**Parallelism**|multiple tasks executing at the literal same instant — requires multiple cores|
|**Thread**|Java's basic unit for achieving concurrency within one process|
|**Race condition**|bug from unsynchronized concurrent access to shared data|
|**Deadlock**|tasks stuck forever, each waiting on a resource the other holds|
|**`synchronized`**|basic mechanism to prevent race conditions, one thread at a time|
|**`java.util.concurrent`**|Java's toolkit of higher-level, safer concurrency primitives|
|**`CompletableFuture`**|declarative async programming, avoiding manual thread coordination|
|**Virtual threads**|massive, cheap concurrency without matching real OS thread/core counts|

## Where this lands in Spring Boot

Every Spring Boot web application is inherently concurrent by design — it handles many simultaneous HTTP requests, historically by giving each request its own thread from a pool (Tomcat's thread pool). Understanding concurrency (and its problems — race conditions especially) directly explains why, for example, a `@Service` bean holding mutable instance state shared across requests is dangerous (multiple request threads could race on it), and why Spring encourages stateless beans, or explicit thread-safety (`ConcurrentHashMap`, atomic types) when state genuinely must be shared.

[[Java]]