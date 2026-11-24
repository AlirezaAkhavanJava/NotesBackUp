

Concurrency issues are what happen when multiple threads touch shared state at the same time without enough coordination. You already have the vocabulary for the _problems_ — race conditions, deadlock, livelock, starvation, priority inversion — and `synchronized` as the first fix. What's missing is the rest of the toolbox: the tools that actually get used in real Spring Boot / Java code when `synchronized` alone isn't enough or is too blunt. That's what this covers — not more problem names, just the fixes that matter.

## 1. `volatile` — fixing visibility, not atomicity

A race condition isn't the only thing that goes wrong with shared variables. Even with no race at all, one thread can write a value and another thread can keep reading a **stale cached copy** forever, because the JVM/CPU caches variables per-thread (you've already seen L1/L2/L3 caching in your concurrency-vs-parallelism note). `volatile` fixes exactly that: it forces every read to go to main memory and every write to flush to main memory immediately.

```java
public class Worker extends Thread {
    private volatile boolean running = true;

    public void run() {
        while (running) {
            // do work
        }
    }

    public void stopWorker() {
        running = false; // guaranteed visible to the Worker thread
    }
}
```

Without `volatile` here, the JIT compiler is legally allowed to cache `running` in a register inside `run()` and never re-check main memory — the loop could spin forever even after `stopWorker()` runs.

**What `volatile` does NOT fix:** compound operations. `count++` is read-modify-write — three steps — and `volatile` only guarantees each individual read or write is visible, not that the three steps happen as one unit. Two threads can still both read `5`, both compute `6`, both write `6`, and you lose an increment. That's still a race condition. `volatile` is for flags and single-write status fields, not counters.

## 2. Atomic classes — fixing compound operations without locking

For the `count++` problem, `java.util.concurrent.atomic` gives you classes that make read-modify-write a single hardware-level operation, using something called **CAS (Compare-And-Swap)**: the CPU says "set this value to X, but only if it still equals the old value I last saw — otherwise, give me the new value and I'll retry."

```java
import java.util.concurrent.atomic.AtomicInteger;

public class RequestCounter {
    private final AtomicInteger count = new AtomicInteger(0);

    public int increment() {
        return count.incrementAndGet(); // atomic, no synchronized needed
    }
}
```

No lock is ever held — no thread ever blocks waiting. Under contention, a thread whose CAS fails just retries with the new value. This is why atomics scale better than `synchronized` under heavy concurrent access: there's no thread parking/waking overhead. Common ones: `AtomicInteger`, `AtomicLong`, `AtomicBoolean`, `AtomicReference<T>` (for swapping whole objects atomically).

## 3. `Lock` / `ReentrantLock` — when `synchronized` is too rigid

`synchronized` has two limits: you can't try to acquire it and back off if you fail, and you can't interrupt a thread that's stuck waiting for it. `java.util.concurrent.locks.ReentrantLock` fixes both, and is also the direct fix for **deadlock** from your hazards note — because it supports `tryLock()`.

```java
import java.util.concurrent.locks.ReentrantLock;

public class Account {
    private final ReentrantLock lock = new ReentrantLock();
    private int balance;

    public boolean withdraw(int amount) {
        if (lock.tryLock()) {           // don't block forever waiting
            try {
                if (balance >= amount) {
                    balance -= amount;
                    return true;
                }
                return false;
            } finally {
                lock.unlock();          // must unlock manually — no auto-release like synchronized
            }
        }
        return false; // couldn't get the lock right now, back off instead of deadlocking
    }
}
```

The `finally` block isn't optional here — forgetting it is the most common `ReentrantLock` bug, because unlike `synchronized`, there's no automatic release when the method exits.

**The actual deadlock fix** (two threads each holding one lock and waiting on the other's) isn't a special API — it's a rule: **always acquire locks in the same global order everywhere in your code.** If every thread locks Account A before Account B, a circular wait is structurally impossible. `tryLock()` with a timeout is the fallback when you can't guarantee ordering (e.g. the two resources are chosen at runtime):

```java
if (lockA.tryLock(500, TimeUnit.MILLISECONDS)) {
    try {
        if (lockB.tryLock(500, TimeUnit.MILLISECONDS)) {
            try { /* critical section */ }
            finally { lockB.unlock(); }
        }
    } finally { lockA.unlock(); }
}
```

There's also `ReadWriteLock` (`ReentrantReadWriteLock`): many threads can hold the **read** lock simultaneously, but the **write** lock is exclusive. This is the fix when a shared object is read constantly but written rarely — `synchronized` would block readers against each other for no reason.

## 4. Concurrent collections — fixing "I made my own synchronized wrapper"

A common anti-pattern is manually synchronizing every access to a `HashMap` or `ArrayList`. `java.util.concurrent` already has collections built for this with better internal locking (often lock-striping, where only part of the structure is locked at a time):

```java
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

Map<String, Integer> cache = new ConcurrentHashMap<>();       // safe concurrent reads/writes, no full-map lock
List<String> listeners = new CopyOnWriteArrayList<>();         // safe for frequent iteration, rare writes
BlockingQueue<Task> queue = new LinkedBlockingQueue<>();        // producer/consumer handoff between threads
```

- `ConcurrentHashMap`: the default fix for a shared map. Never `synchronized`-wrap a `HashMap` yourself.
- `CopyOnWriteArrayList`: good when you iterate far more often than you modify (e.g. a list of event listeners) — every write copies the whole backing array, so frequent writes are expensive.
- `BlockingQueue`: the standard way to hand work off between a producer thread and a consumer thread without manual `wait()`/`notify()` — `put()` blocks if full, `take()` blocks if empty.

## 5. Design-level fixes (the ones that prevent the problem instead of patching it)

These matter more than any API above:

- **Immutability** — an object with no setters and all-final fields can't have a race condition, because there's no "modify" step to race on. This is why DTOs/records are a safe default for passing data between threads.
- **Thread confinement** — don't share the object at all. `ThreadLocal<T>` gives each thread its own private copy instead of one shared instance:
    
    ```java
    private static final ThreadLocal<SimpleDateFormat> formatter =
        ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd"));
    ```
    
    (`SimpleDateFormat` isn't thread-safe; giving each thread its own avoids the problem entirely rather than synchronizing access.)
- **Minimize the shared mutable surface** — the less state threads actually share, the fewer hazards exist to fix. This is the real reason stateless Spring `@Service` beans are the default pattern: no shared mutable fields means no concurrency problem to solve in the first place.




[[Threads]]