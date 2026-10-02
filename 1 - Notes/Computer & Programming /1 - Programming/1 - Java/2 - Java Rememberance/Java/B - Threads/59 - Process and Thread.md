


## The core definitions

**A process** is an instance of a running program — an independent unit of execution with its **own private memory space**, given its own resources by the operating system (memory, file handles, etc.).

**A thread** is a single path of execution **within** a process — a process can contain one or more threads, and all threads within the same process **share that process's memory space**.

```
┌─────────────────────────────────────┐
│            Process                  │  ← e.g. your running Java app (the JVM)
│  ┌──────────┐  ┌──────────┐         │
│  │ Thread 1  │  │ Thread 2  │  ...  │  ← share the SAME memory
│  └──────────┘  └──────────┘         │
│                                     │
│   Private memory (heap, etc.)       │
└─────────────────────────────────────┘
```

---

## The problem processes solve

Going back to the "inside/outside" idea from earlier: **a process is the boundary that makes "inside" meaningful in the first place.** Each process is isolated — one process cannot directly read or corrupt another process's memory. This isolation solves:

- **Stability:** if one program crashes, it doesn't take down other running programs (your browser crashing doesn't crash your terminal).
- **Security:** one program can't snoop on or tamper with another program's private data just by existing alongside it.
- **Resource accounting:** the OS can track and limit how much memory/CPU each process uses independently.

**The cost:** processes are **expensive** to create and switch between. Starting a new process means the OS allocates a whole new memory space, and communicating between two processes (since they can't share memory directly) requires special mechanisms — files, network sockets, pipes — because that data has to cross a real "inside vs outside" boundary, exactly like the I/O you've already learned.

---

## The problem threads solve

If you want a program to do **multiple things at once**, you have two choices: run multiple processes (expensive, isolated, hard to share data) or run multiple **threads within one process** (cheap, share data directly, fast to create).

**Threads solve the "I need concurrency, but process isolation is overkill" problem.** Since threads share the same memory space, they can:

- Communicate instantly (just read/write the same variables — no file/socket needed)
- Be created and destroyed much faster than processes
- Let the OS/JVM interleave their execution, or run them truly in parallel on multiple CPU cores

**The cost:** because threads **share** memory, they can interfere with each other if not coordinated properly — this is the source of an entire category of bugs (race conditions, deadlocks) that don't exist with fully isolated processes.

---

## Side-by-side comparison

||Process|Thread|
|---|---|---|
|Memory|own private memory space|shares memory with other threads in the same process|
|Creation cost|expensive (OS allocates a whole new address space)|cheap (lightweight, shares existing memory)|
|Communication|needs IPC — files, sockets, pipes|direct — shared variables|
|Isolation|one crashing doesn't affect others|one thread crashing (uncaught exception) can affect the whole process|
|Example|your JVM itself is one process|multiple threads running inside that one JVM|

---

## Threads in Java

### Creating a thread — two ways

**1. Extending `Thread`**

```java
class MyTask extends Thread {
    @Override
    public void run() {
        System.out.println("Running in: " + Thread.currentThread().getName());
    }
}

MyTask task = new MyTask();
task.start();   // starts a NEW thread, which then calls run()
```

**2. Implementing `Runnable` (preferred — connects to what you learned about functional interfaces)**

```java
Runnable task = () -> System.out.println("Running in: " + Thread.currentThread().getName());
Thread thread = new Thread(task);
thread.start();
```

Remember `Runnable` from the lambda tutorial? This is exactly why it exists — `Runnable` is a functional interface (`void run()`, no args, no return) built specifically to represent "a task a thread can execute."

**Critical distinction — `start()` vs `run()`:**

```java
task.run();     // WRONG if you want concurrency — just calls run() normally, on the CURRENT thread
task.start();   // RIGHT — creates a NEW thread, and THAT thread calls run()
```

Calling `.run()` directly doesn't create any new thread at all — it just runs the method like any normal method call, on whichever thread called it. This is a very common beginner mistake.

---

## A basic multi-threaded example

```java
public class ThreadDemo {
    public static void main(String[] args) {
        Runnable printNumbers = () -> {
            for (int i = 1; i <= 5; i++) {
                System.out.println(Thread.currentThread().getName() + ": " + i);
            }
        };

        Thread t1 = new Thread(printNumbers, "Thread-A");
        Thread t2 = new Thread(printNumbers, "Thread-B");

        t1.start();
        t2.start();
    }
}
```

Output order is **not guaranteed** — the OS/JVM scheduler interleaves the two threads, so you might see `Thread-A: 1`, `Thread-B: 1`, `Thread-A: 2`... in unpredictable order. This unpredictability is fundamental to concurrency, not a bug.

---

## The problem shared memory creates: race conditions

```java
class Counter {
    private int count = 0;
    void increment() { count++; } // NOT thread-safe!
    int getCount() { return count; }
}

Counter counter = new Counter();
Runnable task = () -> {
    for (int i = 0; i < 1000; i++) counter.increment();
};

Thread t1 = new Thread(task);
Thread t2 = new Thread(task);
t1.start();
t2.start();
t1.join();
t2.join();

System.out.println(counter.getCount()); // often NOT 2000! (e.g. 1847)
```

**Why:** `count++` isn't one atomic operation — it's read, add one, write back, three separate steps. If two threads interleave those steps, updates can get lost (both read the same value before either writes back). This is a **race condition** — the exact kind of bug that's impossible between separate processes (they don't share memory to race over) but very possible between threads.

### The fix — synchronization

```java
class Counter {
    private int count = 0;
    synchronized void increment() { count++; } // now thread-safe
    int getCount() { return count; }
}
```

`synchronized` ensures only one thread can execute `increment()` at a time on a given object — solving the race condition by removing the possibility of interleaving on that critical section.

---

## `Thread` lifecycle states

```
NEW → RUNNABLE → (BLOCKED / WAITING / TIMED_WAITING) → TERMINATED
```

|State|Meaning|
|---|---|
|`NEW`|created, `start()` not yet called|
|`RUNNABLE`|eligible to run (may or may not be actually executing right now)|
|`BLOCKED`|waiting to acquire a lock (e.g., waiting to enter a `synchronized` block another thread holds)|
|`WAITING` / `TIMED_WAITING`|paused, waiting for a condition or a timeout (`Thread.sleep()`, `wait()`)|
|`TERMINATED`|finished executing|

```java
Thread t = new Thread(() -> System.out.println("running"));
System.out.println(t.getState()); // NEW
t.start();
System.out.println(t.getState()); // RUNNABLE (or already TERMINATED if it finished fast)
```

---

## The modern, preferred way — thread pools (`ExecutorService`)

Creating raw `Thread` objects directly, as shown above, is rarely done in real production code — it's expensive to create many threads, and managing their lifecycle manually is error-prone. The standard approach is a **thread pool**, which reuses a fixed set of threads across many tasks:

```java
import java.util.concurrent.*;

ExecutorService executor = Executors.newFixedThreadPool(4); // pool of 4 reusable threads

for (int i = 0; i < 10; i++) {
    int taskId = i;
    executor.submit(() -> {
        System.out.println("Task " + taskId + " on " + Thread.currentThread().getName());
    });
}

executor.shutdown(); // stop accepting new tasks, let submitted ones finish
```

**Problem this solves:** submitting 10 tasks to a pool of 4 threads reuses those 4 threads across all 10 tasks, instead of creating (and destroying) 10 separate `Thread` objects — much cheaper, and gives you control over how much concurrency you actually want.

---

## Virtual threads (Java 21+, finalized) — the recent, major change

We mentioned this earlier in the IO tutorials — worth defining properly here since it's directly about threads:

```java
Thread.startVirtualThread(() -> {
    System.out.println("Running in a virtual thread: " + Thread.currentThread());
});

// or via an executor
try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < 10_000; i++) {
        int taskId = i;
        executor.submit(() -> System.out.println("Task " + taskId));
    }
}
```

**Problem it solves:** traditional Java threads map **one-to-one to OS threads**, which are heavyweight (each takes real OS resources — you typically can't run more than a few thousand at once without serious overhead). This was the entire reason NIO's `Selector`/non-blocking model existed — to avoid needing one OS thread per connection.

**Virtual threads** are lightweight threads **managed by the JVM itself**, not directly mapped one-to-one to OS threads — the JVM can run **millions** of them, only consuming a real OS thread while a virtual thread is actually doing active work; when it blocks (e.g., waiting on I/O), the JVM "parks" it and frees the underlying OS thread for other virtual threads to use.

**Why this matters practically:** you can now write simple, blocking-style code (`Thread.sleep()`, normal `InputStream.read()`, blocking database calls) and still get massive concurrency — without needing complex reactive/async programming models or manual `Selector` code. This is exactly the shift mentioned in the NIO tutorial: virtual threads reduce the practical need to reach for raw non-blocking NIO in ordinary application code.

---

## Where this connects to Spring Boot

Spring Boot (since Spring Framework 6 / Boot 3.2+) has built-in support for running request-handling on virtual threads (`spring.threads.virtual.enabled=true`) — meaning a traditional, simple, blocking-style Spring MVC controller can now handle very high concurrent request loads without needing to switch to the more complex reactive `WebFlux` model. Understanding process vs. thread, and the race-condition/synchronization concepts above, directly explains _why_ this feature matters and what problem it's solving under the hood.

---

## Summary table

|Concept|Definition|Problem it solves|
|---|---|---|
|Process|an independent running program instance, own memory|isolation, stability, security between separate programs|
|Thread|a path of execution within a process, shared memory|cheap concurrency within one program|
|Race condition|bug from unsynchronized shared-memory access|— (this is the problem, not the solution)|
|`synchronized`|locks a block/method to one thread at a time|fixes race conditions|
|`ExecutorService` / thread pool|reusable, managed set of threads|avoids the cost of creating/destroying threads per task|
|Virtual threads (Java 21+)|JVM-managed lightweight threads, not 1:1 with OS threads|massive concurrency with simple, blocking-style code|


[[Java]]