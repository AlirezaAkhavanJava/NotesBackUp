

# Concurrency Problems: Races, Deadlocks and Friends

Concurrency problems are what goes wrong when threads share mutable state or locks. They come in two families. **Safety** problems give you **wrong results** (race conditions, memory-visibility bugs). **Liveness** problems make the program **stop making progress** (deadlock, livelock, starvation). Priority inversion is a scheduling problem that looks like a liveness problem.

This builds on your lifecycle lesson (`BLOCKED` vs `WAITING`), your thread-management lesson (pools, interruption) and your cache-coherence lesson, where you saw that coherence keeps one memory location consistent but does **not** order operations. That gap is why the first two problems exist.

## 1. Race conditions

A **race condition** is when the result depends on the unpredictable timing of threads. The classic cause is `count++`. It looks like one step, but it is three: **read** `count`, **add** 1, **write** it back.

|Step|Thread A|Thread B|`count` in memory|
|---|---|---|---|
|1|reads 4||4|
|2||reads 4|4|
|3|computes 5|computes 5|4|
|4|writes 5|writes 5|**5** (should be 6)|

One update was **lost**. You can see it happen:

```java
class Counter {
    private int count = 0;
    void increment() { count++; }
    int get()        { return count; }
}

Counter c = new Counter();
Runnable work = () -> { for (int i = 0; i < 100_000; i++) c.increment(); };

Thread a = new Thread(work), b = new Thread(work);
a.start(); b.start();
a.join();  b.join();
System.out.println(c.get());   // usually less than 200000
```

There is a second shape of race, the **check-then-act**:

```java
if (!map.containsKey(key)) {     // thread A and B both pass this check
    map.put(key, value);         // both insert, and one overwrites the other
}
```

The fixes, from simplest to most flexible:

|Tool|Use it when|
|---|---|
|`AtomicInteger` / `AtomicLong`|one counter or flag. Uses one atomic CPU instruction|
|`synchronized`|a few fields must change together|
|`ReentrantLock`|you need `tryLock`, timeouts, fairness or interruptible waits|
|`ConcurrentHashMap.computeIfAbsent`|atomic check-then-act on a map|

## 2. Memory visibility: the other wrong-result bug

Even without a race, one thread's write may **not be seen** by another. CPUs buffer writes and reorder instructions, and the JIT compiler may reorder or hoist reads (this is the coherence-vs-ordering gap from your last lesson).

```java
private boolean running = true;          // bug

void loop() { while (running) { /* work */ } }   // may never see running = false
void stop() { running = false; }
```

`loop()` may spin forever. The fix is `volatile`:

```java
private volatile boolean running = true;
```

**`volatile` gives visibility and ordering, but not atomicity.** A `volatile int count` with `count++` is still racy. `synchronized`, locks and atomics give you both properties.

## 3. How `synchronized` works

```java
synchronized (lock) {
    // critical section
}
```

1. The thread tries to take the **monitor lock** of the `lock` object.
2. If it's free, the thread enters. If another thread holds it, this thread goes to `BLOCKED`.
3. On leaving the block, **including by an exception**, the lock is released.

Things worth knowing:

- **Exclusion and visibility:** everything done inside the block is visible to the next thread that takes the same lock. Reads of shared fields need the lock too, otherwise they can see stale values.
- **It's reentrant:** a thread holding the lock can enter it again.
- **Which lock?** A `synchronized` instance method locks `this`, a `static synchronized` method locks the `Class` object. For private state, a `private final Object lock = new Object();` keeps outsiders from locking it.

## 4. Deadlock

A **deadlock** is when two or more threads wait forever, each holding something another needs. It requires **all four** of these conditions:

|Condition|In Java|Break it by|
|---|---|---|
|Mutual exclusion|a lock only allows one holder|lock-free or immutable data (rarely practical)|
|Hold and wait|holds lock 1 while waiting for lock 2|take locks together, or back off|
|No preemption|you can't take a lock away|`tryLock` with a timeout, then release|
|Circular wait|A waits for B, B waits for A|**one global lock order**|

The classic case:

```java
final Object a = new Object(), b = new Object();

Thread t1 = new Thread(() -> {
    synchronized (a) { pause(100); synchronized (b) { System.out.println("T1 done"); } }
}, "T1");
Thread t2 = new Thread(() -> {
    synchronized (b) { pause(100); synchronized (a) { System.out.println("T2 done"); } }
}, "T2");
t1.start(); t2.start();      // hangs forever. Neither "done" line prints
```

(`pause` is the small sleep helper from your lifecycle lesson.) T1 holds `a` and wants `b`, T2 holds `b` and wants `a`. Both sit in `BLOCKED`. The fix is the same lock order in both threads: **a, then b**.

If you prefer timeouts, do it with a result the caller can act on:

```java
static boolean runWithBoth(ReentrantLock first, ReentrantLock second, Runnable action)
        throws InterruptedException {
    if (first.tryLock(50, TimeUnit.MILLISECONDS)) {
        try {
            if (second.tryLock(50, TimeUnit.MILLISECONDS)) {
                try { action.run(); return true; }
                finally { second.unlock(); }
            }
        } finally { first.unlock(); }
    }
    return false;    // the caller decides: retry later, or report failure
}
```

Returning `false` matters. It makes the failure visible instead of silently dropping the work.

**Detecting a deadlock:**

```bash
jcmd <pid> Thread.print      # look for "Found one Java-level deadlock"
```

```java
long[] ids = ManagementFactory.getThreadMXBean().findDeadlockedThreads();   // null if none
```

## 5. Livelock

In a **livelock**, threads are not blocked. They are `RUNNABLE`, busy, and still make no progress, because each keeps reacting to the other. A typical cause is the retry above done **symmetrically**: both threads fail `tryLock`, both release, both retry at the same moment, over and over. You see **high CPU and no progress**, where a deadlock shows idle CPU.

The fixes are a **random backoff** and a fixed lock order:

```java
Thread.sleep(ThreadLocalRandom.current().nextInt(10, 50));   // different wait each time
```

In real code a perfect lockstep rarely lasts long, so livelocks usually appear as a retry loop that burns CPU for a surprisingly long time.

## 6. Starvation

**Starvation** is when a thread can't get what it needs, such as a lock or CPU time, while others keep getting it. In Java the usual causes are:

- **Unfair locks.** `synchronized` and the default `ReentrantLock` let a thread that arrives _just now_ take the lock ahead of waiting threads ("barging").
- **Readers starving writers** with a `ReadWriteLock` when readers keep coming.
- **A pool exhausted by long tasks**, so short ones wait.
- Priorities, rarely (section 7 explains why).

`new ReentrantLock(true)` gives a roughly first-come-first-served lock. The price is lower throughput, and remember that the untimed `tryLock()` still barges.

### The starvation that bites in real apps: pool deadlock

```java
ExecutorService pool = Executors.newFixedThreadPool(1);

Future<String> outer = pool.submit(() -> {
    Future<String> inner = pool.submit(() -> "inner");   // queued: the only thread is busy
    return inner.get();                                  // outer waits for inner forever
});
outer.get();    // hangs
```

The only worker is running `outer`, so `inner` can never start. Bigger pools only hide it. The real fixes are to avoid blocking on a `Future` from inside a pool task, to use a separate pool for the inner work, or to chain with `CompletableFuture`.

## 7. Priority inversion

In priority inversion, a low-priority thread L holds a lock that a high-priority thread H needs. A medium-priority thread M keeps preempting L, so L never releases the lock and H effectively waits for M. Real-time operating systems solve this with **priority inheritance** (L temporarily runs at H's priority).

In Java:

- There is **no priority inheritance**, and fair locks don't approximate it.
- Java priorities are only hints, and HotSpot on Linux **ignores them by default**.
- So the textbook version rarely appears in backend code. The practical rule is to **not use priorities** and to keep critical sections short.

## 8. All five side by side

|Problem|Family|Thread state|Symptom|Main fix|
|---|---|---|---|---|
|Race condition|safety|`RUNNABLE`|wrong results, varies run to run|atomics, `synchronized`, locks|
|Visibility bug|safety|`RUNNABLE`|stale values, loops that never stop|`volatile`, locks, atomics|
|Deadlock|liveness|`BLOCKED` / `WAITING`|hang, **idle** CPU|global lock order, timed `tryLock`|
|Livelock|liveness|`RUNNABLE`|no progress, **busy** CPU|random backoff, lock order|
|Starvation|liveness|any|one thread never gets its turn|fair locks, separate pools|
|Priority inversion|scheduling|`BLOCKED` (high priority)|high-priority work delayed|no priorities, short locks|

## The counter, done right

```java
class SafeCounter {
    private final AtomicInteger count = new AtomicInteger();
    void increment() { count.incrementAndGet(); }
    int get()        { return count.get(); }
}
```

If you must use a lock, use `lock()` inside a `try/finally`, never `tryLock()` without handling failure.

## Related concepts in one line each

- **Immutable objects:** nothing can change, so nothing can race. The safest design when possible.
- **`ConcurrentHashMap.computeIfAbsent`:** does a check-then-act atomically.
- **Happens-before (Java Memory Model):** the formal rules for what one thread is guaranteed to see of another. This is a good next lesson.

## What to carry into real code

1. `count++` is three steps. Use an atomic or a lock.
2. Reads of shared data need the same protection as writes. `volatile` fixes visibility only, not atomicity.
3. Prevent deadlock with **one fixed lock order**, and treat `tryLock` failure as a result you must handle.
4. Never block on a `Future` from inside the pool that runs it.
5. Don't rely on thread priorities.
6. When a program hangs, run `jcmd <pid> Thread.print` first. It tells you whether it's a deadlock.

[[Threads]]