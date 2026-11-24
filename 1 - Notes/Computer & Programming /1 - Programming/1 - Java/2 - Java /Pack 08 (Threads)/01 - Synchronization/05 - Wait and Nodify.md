

## The problem this solves

You already know `synchronized` prevents race conditions by letting only one thread into a critical section at a time. But that alone doesn't solve everything — sometimes a thread enters a `synchronized` block and discovers **it can't actually do anything yet**, because some condition isn't true (a queue is empty, a resource isn't ready, a buffer is full).

```java
synchronized void take() {
    while (queue.isEmpty()) {
        // ... now what? Can't proceed, but holding the lock and spinning wastes CPU
    }
}
```

If the thread just loops checking the condition repeatedly (**busy-waiting**), it burns CPU cycles doing nothing useful, and — worse — since it holds the lock the whole time, **no other thread can ever get in to change the condition** (e.g., add something to the queue). That's a self-inflicted deadlock.

**`wait()`/`notify()` solve this exact problem:** they let a thread say "I can't proceed right now — release the lock, and pause me until someone tells me the situation has changed," and let another thread say "I just changed something — wake up whoever was waiting."

---

## `wait()` — pausing and releasing the lock

```java
public final void wait() throws InterruptedException                  // wait forever
public final void wait(long timeoutMillis) throws InterruptedException  // wait, with timeout
```

`wait()` is a method on **every Java object** (defined on `Object`, not `Thread`) — because you call it on the _lock object_ you're waiting on, not on a `Thread`.

**Critical rule: `wait()` can only be called from inside a `synchronized` block/method on that same object** — calling it outside one throws `IllegalMonitorStateException`.

```java
class SharedBox {
    private String data;
    private boolean available = false;

    synchronized String take() throws InterruptedException {
        while (!available) {
            wait(); // releases the lock on `this`, pauses THIS thread, moves to WAITING
        }
        available = false;
        return data;
    }
}
```

**What `wait()` actually does, precisely:**

1. **Releases the lock** it currently holds (on the object `wait()` was called on) — this is the crucial part; without this, no other thread could ever get in to fix the condition.
2. Puts the thread into the **`WAITING`** state (or `TIMED_WAITING` if you passed a timeout) — exactly the state defined in the last tutorial.
3. The thread stays paused until another thread calls `notify()`/`notifyAll()` on that same object, the timeout (if any) expires, or the thread is interrupted.
4. When woken, the thread **must re-acquire the lock** before continuing — so it doesn't just resume instantly; it goes back to competing for the lock like anyone else trying to enter that `synchronized` section.

---

## `notify()` and `notifyAll()` — waking waiting threads

```java
public final void notify()      // wakes ONE waiting thread (arbitrary choice)
public final void notifyAll()    // wakes ALL waiting threads
```

Also methods on `Object`, also must be called from inside a `synchronized` block on the same object.

```java
class SharedBox {
    private String data;
    private boolean available = false;

    synchronized void put(String value) {
        data = value;
        available = true;
        notify(); // wake up ONE thread waiting in take()
    }
}
```

**`notify()` doesn't hand off the lock immediately** — it just moves a waiting thread from `WAITING` back into `RUNNABLE`, making it eligible to compete for the lock again. The notifying thread keeps running (and keeps the lock) until it exits its own `synchronized` block; only then can the newly-woken thread actually acquire the lock and continue from where `wait()` left off.

### Why `notify()` picks "an arbitrary" thread, and why that matters

If multiple threads are waiting on the same object, `notify()` wakes **exactly one**, and **you don't get to choose which one** — it's determined by the JVM's internal implementation, not something you control or should rely on.

### `notifyAll()` — the safer default

```java
synchronized void put(String value) {
    data = value;
    available = true;
    notifyAll(); // wake up EVERY thread waiting on this object
}
```

**Why `notifyAll()` is usually preferred over `notify()`:** if multiple threads are waiting for _different_ conditions on the same object, `notify()` might wake the "wrong" one — a thread whose specific condition still isn't true, which then just goes back to `wait()` (correctly, if using the `while` loop pattern below) while the thread that _actually_ needed waking stays asleep. `notifyAll()` wakes everyone, and each one re-checks its own condition — safe, if slightly less efficient (some woken threads will immediately re-check and re-wait if their specific condition still isn't met).

**Rule of thumb:** use `notify()` only when you're certain all waiting threads are waiting for the exact same condition and any one of them can proceed; use `notifyAll()` whenever in doubt — it's always correct, just occasionally slightly wasteful.

---

## Why `wait()` must always be in a `while` loop, never an `if`

This is the single most important practical rule, and it's a very common source of bugs when people first learn this.

```java
// WRONG — using if
synchronized String take() throws InterruptedException {
    if (!available) {
        wait();
    }
    // BUG: after waking, we assume `available` is true — but is it, really?
    available = false;
    return data;
}
```

```java
// CORRECT — using while
synchronized String take() throws InterruptedException {
    while (!available) {
        wait();
    }
    // guaranteed: available IS true here, because we only exit the loop when it's true
    available = false;
    return data;
}
```

**Why this matters — two real reasons:**

1. **Spurious wakeups.** The JVM is technically _allowed_ to wake a waiting thread from `wait()` without any `notify()` call ever happening (a rare, platform-level quirk documented in the Java spec) — so you cannot assume "I was woken up" means "the condition is now true."
2. **`notifyAll()` wakes everyone, but the condition might get consumed by someone else first.** If three threads are all waiting in `take()` and `notifyAll()` wakes all of them, they all race to reacquire the lock — but only _one_ of them actually gets to run first, consumes the available data (`available = false`), and by the time the second woken thread gets the lock, the condition is false again. Without re-checking in a `while` loop, that second thread would incorrectly proceed as if data were still available.

**This is exactly why the `while` loop is non-negotiable** — it re-verifies the actual condition every single time the thread wakes up, regardless of _why_ it woke up.

---

## `BLOCKED` vs. `WAITING` — formally distinguishing them (tying to the last tutorial)

This is worth being precise about, since both involve a thread "not running," but for different reasons:

||`BLOCKED`|`WAITING` (or `TIMED_WAITING`)|
|---|---|---|
|Cause|trying to **enter** a `synchronized` block, another thread holds the lock|already **inside** a `synchronized` block, called `wait()` voluntarily|
|Who controls waking it|whoever currently holds the lock — automatically wakes it once they exit the block|requires an explicit `notify()`/`notifyAll()` call (or a timeout, or interrupt)|
|Thread's own choice?|No — it's just waiting its turn for a lock, involuntarily|Yes — the thread itself decided to pause via `wait()`|

```java
class Demo {
    synchronized void method() throws InterruptedException {
        System.out.println("Got the lock");
        wait(); // voluntarily gives up the lock, enters WAITING
    }
}
```

```java
Demo d = new Demo();

Thread t1 = new Thread(() -> {
    try { d.method(); } catch (InterruptedException e) {}
});
t1.start();
// t1 enters synchronized, calls wait() → releases lock, state becomes WAITING

Thread.sleep(100);

Thread t2 = new Thread(() -> {
    try { d.method(); } catch (InterruptedException e) {}
});
t2.start();
// t2 tries to enter the SAME synchronized method
// but t1 already released the lock via wait(), so t2 actually GETS the lock
// and t2 also calls wait() → also becomes WAITING
```

To actually see `BLOCKED`, you need a thread that holds the lock **without releasing it** (e.g., sleeping inside the block instead of calling `wait()`), while another thread tries to enter:

```java
class Demo {
    synchronized void method() throws InterruptedException {
        Thread.sleep(3000); // holds the lock the WHOLE time — doesn't release it like wait() would
    }
}

Demo d = new Demo();
Thread t1 = new Thread(() -> { try { d.method(); } catch (InterruptedException e) {} });
Thread t2 = new Thread(() -> { try { d.method(); } catch (InterruptedException e) {} });

t1.start();
Thread.sleep(100); // let t1 grab the lock first
t2.start();

Thread.sleep(100);
System.out.println(t2.getState()); // BLOCKED — waiting to acquire the lock t1 is holding
```

---

## Full producer-consumer example — everything together

```java
class SharedBox {
    private String data;
    private boolean available = false;

    synchronized void put(String value) throws InterruptedException {
        while (available) {         // wait if there's already unconsumed data
            wait();
        }
        data = value;
        available = true;
        System.out.println("Produced: " + value);
        notifyAll();                 // wake up any waiting consumer
    }

    synchronized String take() throws InterruptedException {
        while (!available) {          // wait if there's nothing to consume yet
            wait();
        }
        available = false;
        System.out.println("Consumed: " + data);
        notifyAll();                   // wake up any waiting producer
        return data;
    }
}

public class ProducerConsumerDemo {
    public static void main(String[] args) {
        SharedBox box = new SharedBox();

        Thread producer = new Thread(() -> {
            try {
                for (int i = 1; i <= 5; i++) {
                    box.put("Item-" + i);
                }
            } catch (InterruptedException e) {}
        });

        Thread consumer = new Thread(() -> {
            try {
                for (int i = 1; i <= 5; i++) {
                    box.take();
                }
            } catch (InterruptedException e) {}
        });

        producer.start();
        consumer.start();
    }
}
```

This one class demonstrates every concept in this tutorial: both methods use `while` (not `if`), both use `notifyAll()` (safe default), and the two threads naturally alternate between `RUNNABLE` and `WAITING` as they coordinate through the shared lock on `box`.

---

## The modern alternative — `java.util.concurrent` tools that replace manual `wait()`/`notify()`

Raw `wait()`/`notify()` is genuinely tricky to get right (the `while`-loop rule, choosing `notify()` vs `notifyAll()`, `IllegalMonitorStateException` pitfalls) — in real production code, you'd typically reach for higher-level tools instead:

```java
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

BlockingQueue<String> queue = new LinkedBlockingQueue<>();

// Producer
queue.put("Item-1"); // blocks automatically if the queue is full (bounded queue)

// Consumer
String item = queue.take(); // blocks automatically if the queue is empty
```

**`BlockingQueue`** implements the _exact_ producer-consumer pattern from the example above internally, using `wait()`/`notify()`-equivalent mechanics under the hood — but you never have to write the `while` loop, the locking, or the notify calls yourself. This is the practical takeaway: **understanding `wait()`/`notify()` explains what's happening inside these higher-level tools**, even though you'll rarely write raw `wait()`/`notify()` code in modern applications.

---

## Summary

|Concept|Definition|
|---|---|
|`wait()`|pauses the current thread, releases the lock, moves to `WAITING`/`TIMED_WAITING` — must be called inside `synchronized`|
|`notify()`|wakes one arbitrary thread waiting on this object — must be called inside `synchronized`|
|`notifyAll()`|wakes all threads waiting on this object — the safer default|
|`BLOCKED`|involuntary — waiting to **acquire** a lock someone else holds|
|`WAITING`/`TIMED_WAITING`|voluntary — a thread called `wait()` itself, releasing the lock, waiting for `notify()` (or timeout)|
|`while` loop around `wait()`|mandatory — protects against spurious wakeups and races between multiple woken threads|
|`BlockingQueue` and similar|modern, safer alternative that wraps this exact pattern internally|

## Where this closes the loop

This tutorial completes the concurrency arc you've been building: **`synchronized`** protects shared data from races; **`BLOCKED`** is what happens when a thread can't get that protection immediately; **`wait()`/`notify()`** let threads coordinate _around_ a condition without wasting CPU or holding the lock hostage while waiting; and **`WAITING`/`TIMED_WAITING`** are the formal states that make this coordination visible and debuggable — exactly the mechanism that lets two threads (or many) work together safely and efficiently on shared data.

[[Java]]