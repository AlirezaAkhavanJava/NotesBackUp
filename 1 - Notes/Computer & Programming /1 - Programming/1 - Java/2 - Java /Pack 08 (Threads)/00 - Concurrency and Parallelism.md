

**Concurrency** is about _dealing with many things at the same time_. It's a way of structuring your program so several tasks can be "in progress" together, even if only one of them is physically running at any given instant. Think of one cook who starts the rice, then chops vegetables while the rice cooks, then stirs the sauce. One person, many tasks moving forward.

**Parallelism** is about _doing many things at the same time, literally_. Two or more tasks are running at the exact same instant, on different hardware. That's two cooks, each chopping their own vegetables. Concurrency is about **structure** (how you organize work), and parallelism is about **execution** (how work physically runs). You can have one without the other, and the best programs often use both.

To really understand why we need them, we start with the machine.

![[614f7e89-dba1-4874-bcd3-070385fe9b22.png]]
---

## Part 1: How the hardware works

### The CPU executes one instruction stream per core

A CPU **core** is a tiny worker that does this, billions of times per second:

1. **Fetch** the next instruction from memory
2. **Decode** it (what does it ask for?)
3. **Execute** it (add numbers, compare, move data)
4. **Store** the result

One core follows **one stream of instructions** at a time. A 3 GHz core does roughly 3 billion of these cycles every second. That's very fast, and it matters for everything below.

### Why we got multiple cores

For decades, CPUs got faster by raising the clock speed. Around the mid-2000s that hit a wall: faster clocks made chips too hot and power-hungry. So manufacturers changed strategy: **instead of one faster worker, put several workers on one chip.** That's a multi-core CPU.

The catch: **extra cores do nothing for you unless your program is written to use them.** A single-threaded Java program runs on one core and leaves the others idle. That is the first big reason parallelism exists.

![[Pasted image 20261108122644.png]]

IBM Power4 CPU : The first commercially available multi-core microprocessor is generally considered to be the IBM POWER4, released in 2001.

---
### The memory hierarchy (the speed gap)

The CPU is extremely fast. Memory is much slower. So the hardware has layers:

|Layer|Approximate access time|Shared with|
|---|---|---|
|Registers|under 1 ns|just that core|
|L1 cache|about 1 ns|just that core|
|L2 cache|about 3–5 ns|usually that core|
|L3 cache|about 10–20 ns|all cores|
|RAM|about 60–100 ns|everyone|
|SSD|about 100,000 ns (0.1 ms)|everyone|
|Network call|about 1,000,000+ ns (1 ms and up)|everyone|

These numbers are rough, but the shape is what matters. A CPU cycle is about 0.3 ns. A network call that takes 1 ms is about **3 million cycles** of waiting.

---
### Two very important consequences

**Consequence 1: waiting is huge.** When your program asks the database or the network for something, the core would sit [^1]idle for millions of cycles. That's wasted power. It would be much smarter to let the core work on _something else_ while waiting. This is the main reason **concurrency** exists.

**Consequence 2: each core has its own private cache.** Imagine two cores, A and B, both working with a variable `count`:

```
Core A: L1 cache holds count = 5
Core B: L1 cache holds count = 5
RAM:    count = 5
```

Core A changes `count` to 6, but it may write that to its own cache first. Core B may keep reading its old copy, `5`, for a while. The hardware has protocols (cache coherence) to sync these copies, but they aren't instant, and compilers and CPUs also **reorder instructions** to run faster. This is why, in Java, one thread can fail to "see" another thread's change. This is the root of the **visibility** problem you'll meet later.

---
### Hyper-threading (SMT), briefly

One physical core can pretend to be two "logical" cores. When one instruction stream stalls (waiting for memory), the core quickly runs the other. It's not twice as fast, usually only 20–30% more throughput, but it helps use idle moments. When you see "8 cores, 16 threads" on a spec sheet, that's this.

---
### The operating system and threads

Your computer might run hundreds of programs but only has, say, 8 cores. The **operating system (OS)** solves this.

- A **process** is a running program, with its own private memory.
- A **thread** is a single stream of execution _inside_ a process. Threads of the same process **share the same heap memory**, but each thread has its **own stack** (local variables and method calls).
- The **scheduler** decides which thread runs on which core, and for how long.

![[1da170c4-be5f-4c71-a27a-ec5b9256037d.png]]

If there are more threads than cores, the scheduler uses **time slicing**: thread 1 runs for a few milliseconds, then gets paused, thread 2 runs, and so on. Switching is called a **context switch**: the OS saves one thread's state (registers, position in code) and loads another's. It happens so fast that everything _feels_ simultaneous.

Here's the key insight:

|Situation|What happens|
|---|---|
|1 core, 3 threads|Time slicing. Only one runs at a time, but all make progress. That's **concurrency without parallelism**.|
|4 cores, 4 threads|Each thread on its own core, truly simultaneous. That's **parallelism**.|
|4 cores, 20 threads|Both: 4 run in parallel, and the scheduler rotates through the rest.|

### So, why do we need them? (The two real reasons)

1. **Waiting problem** (I/O: disk, network, database): the CPU is idle for millions of cycles. Fix: **concurrency**, so other work happens during the wait.
2. **Computing problem** (heavy math, image processing, big data): one core is the bottleneck while others sit idle. Fix: **parallelism**, so the work is split across cores.

Keep these two in mind. Everything in Java maps onto one of them.

---

## Part 2: Concurrency vs parallelism, side by side

||Concurrency|Parallelism|
|---|---|---|
|Core idea|Many tasks _in progress_|Many tasks _running at the same instant_|
|Needs multiple cores?|No|Yes|
|Main goal|Handle waiting well, stay responsive|Finish heavy computation faster|
|Typical example|A web server handling 1000 requests|Resizing 1000 images on 8 cores|
|Typical task type|I/O-bound|CPU-bound|
|Main difficulty|Coordinating shared state|Splitting work and combining results|

**How they work together:** a real server does both. Tomcat handles many requests concurrently (a pool of threads), and the OS spreads those threads across cores in parallel. Concurrency is the _design_, and parallelism is what the hardware _gives you_ when the design allows it.

---

## Part 3: Java

### Step 1: Creating a thread

```java
public class HelloThreads {
    public static void main(String[] args) throws InterruptedException {
        Runnable task = () -> {
            System.out.println("Hello from " + Thread.currentThread().getName());
        };

        Thread t1 = new Thread(task, "worker-1");
        Thread t2 = new Thread(task, "worker-2");

        t1.start();
        t2.start();

        t1.join();
        t2.join();
        System.out.println("Main is done");
    }
}
```

Line by line:

- `Runnable task = () -> {...}`: a `Runnable` is just "a piece of work to do." The lambda is that work.
- `new Thread(task, "worker-1")`: creates a thread object. It does **not** run yet.
- `t1.start()`: asks the OS to create a real thread and run the task. **Always `start()`, never `run()`.** Calling `run()` just runs the code on the current thread, with no concurrency at all.
- `t1.join()`: makes `main` wait until `t1` finishes.

Run it a few times. The order of the two "Hello" lines can change. **The scheduler decides, not you.** That unpredictability is the root of why concurrency is hard.

### Step 2: The danger, a race condition

```java
public class Counter {
    private int count = 0;

    public void increment() {
        count++;
    }

    public int get() { return count; }
}
```

`count++` looks like one step, but it's actually **three**:

```
1. READ  count from memory
2. ADD   1
3. WRITE the result back
```

Now two threads at once:

|Step|Thread A|Thread B|count in RAM|
|---|---|---|---|
|1|reads 5||5|
|2||reads 5|5|
|3|writes 6||6|
|4||writes 6|6|

Two increments happened, but the count went up by only 1. An update got **lost**. This is a **race condition**. It links back to the hardware: those reads and writes go through separate caches and aren't atomic.

### Step 3: Fixes, from simple to powerful

**`synchronized`: only one thread inside at a time**

```java
public synchronized void increment() {
    count++;
}
```

A `synchronized` method takes a lock on the object. Thread B must wait until Thread A leaves the method. `synchronized` also fixes **visibility**: when a thread releases the lock, its changes become visible to the next thread that takes it.

**`volatile`: visibility only**

```java
private volatile boolean running = true;
```

`volatile` forces every read and write to go to shared memory, not a stale cache copy. It solves **visibility**, but **not** atomicity. `volatile int count` with `count++` is still broken. It's perfect for simple flags like `running`.

**Atomic classes: lock-free and fast**

```java
private final AtomicInteger count = new AtomicInteger();

public void increment() {
    count.incrementAndGet();
}
```

This uses a CPU instruction called **compare-and-swap (CAS)**: "set the value to 6 _only if_ it is still 5." If another thread changed it first, retry. No lock needed.

**`ReentrantLock`: manual control**

```java
private final ReentrantLock lock = new ReentrantLock();

public void increment() {
    lock.lock();
    try {
        count++;
    } finally {
        lock.unlock();
    }
}
```

More flexible than `synchronized` (timeouts, fairness, try-lock). The `finally` is vital: if you forget to unlock, other threads wait forever.

### The three problems to always remember

|Problem|Meaning|Tool|
|---|---|---|
|**Atomicity**|An operation must not be cut in the middle|`synchronized`, `Atomic*`, locks|
|**Visibility**|One thread's write must be seen by others|`volatile`, `synchronized`|
|**Ordering**|The CPU/compiler may reorder instructions|`volatile`, `synchronized` (the Java Memory Model's _happens-before_ rules)|

And one more danger: **deadlock**. Thread A holds lock 1 and waits for lock 2, while Thread B holds lock 2 and waits for lock 1. Both wait forever. The usual fix is to always take locks in the same order.

### Step 4: Thread pools (don't create threads by hand)

Creating a thread is expensive (the OS must allocate a stack, about 1 MB by default). So instead we keep a **pool** of reusable threads:

```java
ExecutorService pool = Executors.newFixedThreadPool(4);

for (int i = 0; i < 10; i++) {
    int id = i;
    pool.submit(() -> {
        System.out.println("Task " + id + " on " + Thread.currentThread().getName());
    });
}

pool.shutdown();
```

- `newFixedThreadPool(4)`: 4 workers.
- `submit(...)`: puts a task in a queue. A free worker picks it up.
- `shutdown()`: stops accepting new tasks and lets the pool exit once the queue is done. Forgetting it keeps your program alive.

**How big should the pool be?** Here the hardware lesson pays off:

|Task type|Pool size|Why|
|---|---|---|
|**CPU-bound** (math, compression)|about the number of cores (`Runtime.getRuntime().availableProcessors()`)|More threads than cores only adds context-switch overhead|
|**I/O-bound** (DB, HTTP calls)|Larger, often many times the cores|Most threads are just waiting, so more can overlap|

### Step 5: Concurrency in action: waiting without blocking

`CompletableFuture` lets you start work and combine results without freezing the caller:

```java
CompletableFuture<String> user  = CompletableFuture.supplyAsync(() -> fetchUser());
CompletableFuture<String> order = CompletableFuture.supplyAsync(() -> fetchOrders());

String result = user.thenCombine(order, (u, o) -> u + " has " + o).join();
```

- `supplyAsync(...)`: runs the call on a pool thread and returns immediately.
- Both calls start right away, so if each takes 200 ms, the total is about 200 ms instead of 400 ms.
- `thenCombine`: when both finish, merge their results.
- `join()`: wait for the final answer.

This is the "waiting problem" fixed.

### Step 6: Parallelism in action: splitting computation

```java
long sum = LongStream.rangeClosed(1, 100_000_000)
                     .parallel()
                     .sum();
```

`.parallel()` splits the range into chunks and processes them on multiple cores using the **ForkJoinPool**. The idea behind it is **fork/join**:

```
          [1 ... 100M]
           /         \
   [1...50M]       [50M...100M]     <- fork (split)
    /     \          /      \
  ...     ...      ...      ...
    \     /          \      /
   partial sums combine -> total   <- join (merge)
```

Use it only when:

- the work is **CPU-heavy** (not waiting on I/O),
- the data is **large** enough to be worth splitting,
- tasks are **independent** (no shared mutable state).

For tiny lists, splitting costs more than it saves.

### Step 7: Virtual threads (Java 21+)

Normal ("platform") threads map 1:1 to OS threads, so you can only have a few thousand. **Virtual threads** are very cheap, managed by the JVM, and you can have _millions_. When a virtual thread blocks on I/O, the JVM parks it and reuses the real thread for another one.

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < 10_000; i++) {
        executor.submit(() -> callSlowService());
    }
}
```

This gives you concurrency for I/O-heavy code in simple, blocking-style code. It does **not** make CPU-heavy work faster, because you still only have as many cores as you have.

---

## Part 4: How they work together (the big picture)

Imagine a Spring Boot endpoint that gets a request, calls two services, then crunches some data:

![[6b9c526f-69b8-4b83-acd1-d6cdfa5e6250.png]]

- **Concurrency** keeps the app responsive and hides waiting.
- **Parallelism** uses the extra cores for heavy computing.
- The scheduler and hardware decide what actually runs in parallel.

Since you already learned Spring: **singleton beans are shared by all request threads at once**, so a singleton with a mutable field (like a plain `int count`) has exactly the race condition from Step 2. Keep singleton beans stateless, or use thread-safe types.

---

## Short summaries of related concepts

- **Amdahl's Law:** parallelism has a ceiling. If 20% of your program can't be parallelized, the best possible speedup is 5x, even with infinite cores.
- **Thread safety:** code is thread-safe if it behaves correctly when called from many threads at once. Immutable objects are always safe.
- **Concurrent collections:** `ConcurrentHashMap` and `CopyOnWriteArrayList` are built for multi-threaded use. Plain `HashMap` is **not** safe across threads.
- **Async vs reactive:** async means "start now, get the result later." Reactive (Spring WebFlux) pushes this further, using few threads and event-driven pipelines.
- **Blocking vs non-blocking:** a blocking call parks the thread until it's done. Non-blocking returns immediately and notifies you later.

---

## Quick recap

1. Cores run one instruction stream each; multi-core exists because clocks hit a heat wall.
2. Memory and I/O are far slower than the CPU, so cores would idle. **Concurrency** fills that gap.
3. Heavy computation needs many cores at once. **Parallelism** provides that.
4. Threads share heap memory, so you must handle **atomicity, visibility, and ordering**.
5. In Java: use **thread pools**, `CompletableFuture` for waiting, **parallel streams / ForkJoin** for computing, **virtual threads** for lots of I/O tasks.
6. Real systems use both together.




[[Java]]

[^1]: Idle means that a CPU core is not executing useful instructions for your program because it is waiting for an external operation, such as a database query or network response, to complete. The core is available to execute other tasks, but your current thread cannot continue until the required data arrives. Essentially, the CPU is waiting rather than actively processing your program's next instructions.
