

When two threads touch the same data at the same time, the result can be wrong in ways that are hard to reproduce. A **lock** is a gatekeeper: only the thread holding it may enter a protected section of code, and everyone else waits. This gives you _mutual exclusion_, which is the foundation of thread-safe code.

As for how many types there are: Java has no fixed number, because "type" can mean different things. In practice you will meet **four main lock tools** (`synchronized`, `ReentrantLock`, `ReentrantReadWriteLock`, `StampedLock`), plus several _properties_ a lock can have (fair, reentrant, optimistic, and so on). We'll go through both.

## The problem locks solve

```java
public class Counter {
    private int count = 0;

    public void increment() {
        count++;
    }
}
```

`count++` looks like one step, but it is really three: read the value, add one, write it back. If two threads run it together, both can read `5`, both write `6`, and one increment is lost. This is a **race condition**.

There is a second, quieter problem: **visibility**. Without proper coordination, one thread's write may stay in a CPU cache or register where another thread cannot see it. A lock fixes both problems. It makes the section run one thread at a time, and it guarantees that everything written before releasing the lock is visible to the next thread that acquires it.

## 1. `synchronized`: the built-in lock

Every Java object has a hidden lock called its **monitor** (also called an _intrinsic lock_). The `synchronized` keyword uses it.

```java
public class Counter {
    private int count = 0;

    public synchronized void increment() {
        count++;
    }

    public synchronized int get() {
        return count;
    }
}
```

On a method, `synchronized` locks on `this`. You can also lock a block, which is better because you protect only what needs protecting:

```java
private final Object lock = new Object();

public void increment() {
    // other work that needs no protection
    synchronized (lock) {
        count++;
    }
}
```

Three facts to remember:

- **Instance vs static.** A `synchronized` instance method locks on `this`. A `static synchronized` method locks on the `Class` object. These are two different locks, so they don't block each other.
- **Automatic release.** The lock is released when the block ends, even if an exception is thrown. You can't forget to unlock.
- **Reentrant.** A thread that already holds a lock can enter another `synchronized` section on the same lock without blocking itself. This matters when one synchronized method calls another:

```java
public synchronized void a() { b(); }   // holds the lock on 'this'
public synchronized void b() { }        // enters again, no deadlock
```

Prefer a private `lock` object over `synchronized(this)`. Otherwise outside code can also lock on your object and interfere with you.

### Where `synchronized` falls short

It is simple, but limited:

- A thread waiting for it **cannot give up**. There is no timeout, and it can't be interrupted while waiting.
- You **cannot try** the lock ("take it if free, otherwise do something else").
- There is **one kind of lock only**: readers block other readers.
- The lock scope must be a block or method, so you can't acquire in one method and release in another.

These limits are why `java.util.concurrent.locks` exists.

## 2. `ReentrantLock`: the flexible lock

`ReentrantLock` implements the `Lock` interface. It behaves like `synchronized`, but you control it manually.

```java
import java.util.concurrent.locks.*;

public class Counter {
    private final Lock lock = new ReentrantLock();
    private int count = 0;

    public void increment() {
        lock.lock();
        try {
            count++;
        } finally {
            lock.unlock();   // always in finally
        }
    }
}
```

The `try/finally` is not optional. Unlike `synchronized`, nothing releases the lock automatically. If an exception skips `unlock()`, every other thread waits forever.

What you gain over `synchronized`:

**`tryLock()`: don't wait if it's taken**

```java
if (lock.tryLock()) {
    try {
        // got it
    } finally {
        lock.unlock();
    }
} else {
    // do something else instead of waiting
}
```

**`tryLock(timeout, unit)`: wait, but only for so long**

```java
if (lock.tryLock(2, TimeUnit.SECONDS)) {
    try { /* work */ } finally { lock.unlock(); }
}
```

**`lockInterruptibly()`:** a waiting thread can be interrupted, so you can cancel stuck work.

**Fairness.** `new ReentrantLock(true)` hands the lock to the longest-waiting thread. The default (unfair) lets a newly arrived thread jump ahead, which is faster overall but can starve a waiting thread. Use fair mode only if starvation is a real concern.

**`Condition`:** a lock can have multiple wait/notify queues. `synchronized` gives you one (`wait`/`notify`). With a lock you can create several, for example `notFull` and `notEmpty` in a bounded buffer:

```java
Condition notEmpty = lock.newCondition();
// inside the locked section:
notEmpty.await();      // release the lock and wait
notEmpty.signal();     // wake one waiting thread
```

## 3. `ReentrantReadWriteLock`: many readers, one writer

Imagine a cache that is read thousands of times per second and updated rarely. With a normal lock, readers block each other for no reason, since reading doesn't change anything.

A read-write lock is really **two locks** that work together:

- **Read lock (shared):** many threads can hold it at once.
- **Write lock (exclusive):** only one thread can hold it, and no readers are allowed at the same time.

```java
public class Cache {
    private final Map<String, String> data = new HashMap<>();
    private final ReadWriteLock rw = new ReentrantReadWriteLock();

    public String get(String key) {
        rw.readLock().lock();
        try {
            return data.get(key);
        } finally {
            rw.readLock().unlock();
        }
    }

    public void put(String key, String value) {
        rw.writeLock().lock();
        try {
            data.put(key, value);
        } finally {
            rw.writeLock().unlock();
        }
    }
}
```

This pays off only when reads clearly outnumber writes and the read section does enough work to matter. For tiny critical sections, the extra bookkeeping can make it slower than a plain lock.

One trap: you **cannot upgrade** a read lock to a write lock. If a thread holds the read lock and asks for the write lock, it deadlocks itself. You can _downgrade_ (take the write lock, then the read lock, then release the write lock), but not the other way around.

## 4. `StampedLock`: the optimistic lock

`StampedLock` adds a third mode to the read/write idea: the **optimistic read**. The thinking is: "Nobody is probably writing right now. Let me read without locking anything, then check afterward whether a write happened. If it did, retry the safe way."

```java
public class Point {
    private final StampedLock sl = new StampedLock();
    private double x, y;

    public void move(double dx, double dy) {
        long stamp = sl.writeLock();
        try {
            x += dx;
            y += dy;
        } finally {
            sl.unlockWrite(stamp);
        }
    }

    public double distanceFromOrigin() {
        long stamp = sl.tryOptimisticRead();   // no lock taken
        double cx = x, cy = y;                 // read into locals
        if (!sl.validate(stamp)) {             // did a write happen meanwhile?
            stamp = sl.readLock();             // fall back to a real read lock
            try {
                cx = x;
                cy = y;
            } finally {
                sl.unlockRead(stamp);
            }
        }
        return Math.sqrt(cx * cx + cy * cy);
    }
}
```

Every lock call returns a **stamp** (a `long`) that you pass back when unlocking or validating. Two warnings:

- It is **not reentrant**. Locking it twice from the same thread deadlocks.
- It has **no `Condition` support**, and it is easier to misuse. Use it only for read-heavy code where you've measured a benefit.

## The other way to classify locks

The four tools above are _implementations_. The terms below describe _properties_, and one lock can have several of them.

|Property|Meaning|Example|
|---|---|---|
|**Reentrant**|The same thread can re-acquire a lock it holds|`synchronized`, `ReentrantLock`|
|**Exclusive**|One holder at a time|Write lock, `synchronized`|
|**Shared**|Many holders at once|Read lock|
|**Fair / Unfair**|Waiting threads served in order, or not|`new ReentrantLock(true)`|
|**Pessimistic**|Assume conflict will happen, so lock first|`synchronized`, `ReentrantLock`|
|**Optimistic**|Assume no conflict, check afterward, retry if wrong|`StampedLock` optimistic read, atomics|

The last row connects to **lock-free** programming. Classes such as `AtomicInteger` use a CPU instruction called _compare-and-swap_ (CAS): "set this to 6 only if it is still 5." If another thread changed it, the operation fails and you retry. No thread ever blocks:

```java
AtomicInteger count = new AtomicInteger();
count.incrementAndGet();   // thread-safe, no lock
```

For a single counter or flag, this is simpler and usually faster than any lock. Locks are for protecting a _group_ of operations or several variables that must change together.

## The danger: deadlock

Locks create a new problem. If two threads each hold a lock the other needs, both wait forever:

```java
// Thread 1                      // Thread 2
synchronized (A) {               synchronized (B) {
    synchronized (B) { ... }         synchronized (A) { ... }
}                                }
```

Thread 1 holds A and waits for B. Thread 2 holds B and waits for A. Nothing ever moves. Two practical defenses:

- **Always acquire multiple locks in the same global order.** If everyone takes A then B, the circular wait cannot happen.
- **Use `tryLock` with a timeout**, so a thread eventually gives up, releases what it holds, and retries.

Related problems you may hear about:

- **Starvation:** a thread never gets the lock because others keep winning (fair locks help).
- **Livelock:** threads keep reacting to each other and never make progress.
- **Lock contention:** many threads fighting over one lock, so your "parallel" code runs effectively one thread at a time. Hold locks for as short a time as possible, and never do slow work (network calls, disk I/O) while holding one.

## Which one should you use?

Go from simplest to most powerful:

1. **Atomic classes** for a single counter or flag.
2. **`synchronized`** for ordinary protection of shared state. It's short, safe, and automatically released. In JDK 25 it also plays well with virtual threads, so no special care is needed.
3. **`ReentrantLock`** when you need `tryLock`, timeouts, interruptibility, fairness, or multiple conditions.
4. **`ReentrantReadWriteLock`** when reads dominate writes and reads are not trivially tiny.
5. **`StampedLock`** only for proven, measured read-heavy hot spots.

A good habit: if you can avoid sharing mutable data in the first place (immutable objects, thread-confined data, concurrent collections like `ConcurrentHashMap`), you need no lock at all.


[[Threads]]