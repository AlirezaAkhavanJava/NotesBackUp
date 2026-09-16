# Part 1: Race Conditions

## The Problem

Remember: threads share the same memory. That sounds convenient, but it creates a dangerous trap.

Imagine a **shared bank account balance = 100**, and two threads both want to add 10 to it at the _same_ time.

To do "balance = balance + 10", the computer secretly does **3 steps**, not one:

1. **Read** the current balance (100)
2. **Add** 10 to it (110)
3. **Write** the new value back (110)

If two threads do this at the exact same time, their steps can **interleave** (mix together) in a bad order, and one update can get **lost**. Let me show you.

![[Pasted image 20260913125138.png]]


Both threads read 100 _before_ either one wrote back the new value, so both computed 110 in their own head. The second write just overwrites the first one — one whole `+10` vanishes. This bug is called a **race condition**: the correctness of the result depends on which thread happens to "win the race" and run first, which is unpredictable.

## The Solution

We need a way to say: "only one thread may do this read-add-write sequence at a time — everyone else has to wait their turn."

In Java, the simplest tool for this is the **`synchronized`** keyword:

```java
public synchronized void deposit(int amount) {
    balance = balance + amount; // only one thread can be inside here at a time
}
```

Think of it like a **single-key bathroom**. Only whoever holds the key can go in. Everyone else lines up outside and waits until the key is returned.

## Types of Solutions (from simple to advanced)

- **`synchronized` keyword** — locks a method or block of code; simplest option, but can slow things down since threads wait in line.
- **`Lock` objects** (`ReentrantLock`) — like `synchronized`, but more flexible (e.g. you can try to get the lock and give up if it takes too long).
- **Atomic classes** (`AtomicInteger`, `AtomicLong`) — special variables built to safely do read-add-write in _one_ uninterruptible step, without needing a lock at all. Fastest option for simple counters.
- **Concurrent collections** (`ConcurrentHashMap`, etc.) — pre-built thread-safe versions of common data structures, so you don't have to add your own locks.

---

# Part 2: Thread Pools

## The Problem

Say your Spring Boot app creates a **brand new thread for every single incoming web request**. That sounds fine... until 10,000 users hit your API at once.

Creating a thread isn't free — it costs memory and setup time (the OS has to allocate space for its stack, register it, etc.). If you make one thread per request:

- You could run out of memory
- The OS spends more time managing threads than doing actual work
- The whole server can slow to a crawl or crash

This is like a restaurant **hiring a brand new waiter for every single customer, then firing them the moment that customer leaves** — hugely wasteful.

## The Solution: Thread Pools

![[Pasted image 20260913125105.png]]

A **thread pool** is a fixed, reusable group of worker threads that sit ready, waiting to pick up tasks from a queue. When a task finishes, the thread doesn't die — it just goes back to the pool and grabs the _next_ task waiting in line.New tasks (4, 5, 6) pile up in the **queue** while the fixed pool of workers is busy. The moment a worker finishes its current task, it grabs the next one from the queue — no new thread creation needed, just reuse.

## Types of Thread Pools in Java

Java gives you an `ExecutorService` to manage pools, with a few ready-made flavors:

- **Fixed thread pool** — a set number of threads, always (e.g. exactly 10 workers, no more, no less). Good when you want predictable, controlled resource usage.
- **Cached thread pool** — creates new threads as needed, but reuses idle ones, and shrinks when idle for too long. Good for lots of short-lived tasks.
- **Single thread executor** — just one worker thread, running tasks one after another in order. Good when tasks must run strictly sequentially but you still want them off the main thread.
- **Scheduled thread pool** — runs tasks after a delay, or repeatedly on a schedule (like a cron job).

Example of creating a fixed pool in plain Java:

```java
ExecutorService pool = Executors.newFixedThreadPool(4); // 4 workers
pool.submit(() -> System.out.println("Task running"));
```

## Why this matters for Spring Boot

You'll rarely create thread pools by hand in Spring Boot — it manages one for you automatically for incoming HTTP requests (built on **Tomcat's** thread pool by default). But you'll configure and tune it directly when you:

- Use **`@Async`** to run a method on a separate thread from a pool you define
- Set properties like `server.tomcat.threads.max` to control how many simultaneous requests your app can truly _process at once_ (versus just queue up)
- Build background job processing (e.g. sending emails without making the user wait)



[[Java]] 