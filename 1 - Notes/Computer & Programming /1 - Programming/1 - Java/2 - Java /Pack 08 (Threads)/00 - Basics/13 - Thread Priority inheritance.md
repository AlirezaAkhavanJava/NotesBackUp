

A thread created inside another thread inherits its creator's priority by default, not `NORM_PRIORITY` automatically:

```java
System.out.println(Thread.currentThread().getPriority()); // say, 5

Thread child = new Thread(() -> {
    System.out.println(Thread.currentThread().getPriority()); // 5 — inherited, not reset
});
child.start();
```

If you spawn threads from inside a thread you already bumped to `MAX_PRIORITY`, every thread it spawns starts at `MAX_PRIORITY` too, unless you explicitly override it.

## `Thread.sleep()` doesn't release locks it's holding

This is the actual gotcha worth knowing. `sleep()` pauses the thread but keeps every lock that thread currently holds — unlike `wait()`, which gives the lock up while waiting.

```java
class Resource {
    synchronized void doWork() throws InterruptedException {
        System.out.println("Holding lock, now sleeping...");
        Thread.sleep(3000); // lock is still held for the full 3 seconds
        System.out.println("Done sleeping, releasing lock");
    }
}
```

Any other thread trying to enter a `synchronized` block on that same object blocks for the full 3 seconds — not because it's doing real work, but because the scheduler has no concept of "this thread is just napping, let others in." It only knows the thread isn't runnable, and the lock stays owned until it wakes up and exits the block.

**Fix:** never sleep while holding a lock other threads actually need:

```java
class Resource {
    void doWork() throws InterruptedException {
        Thread.sleep(3000);           // sleep BEFORE acquiring the lock
        synchronized (this) {
            System.out.println("Now doing the actual protected work");
        }
    }
}
```

## Why `sleep()` forces you to handle a checked exception

`Thread.sleep(1000)` won't compile without a `try/catch` for `InterruptedException`. That's deliberate: if another thread calls `.interrupt()` on a sleeping thread, the sleep ends immediately and throws right there. That's expected behavior, not a malfunction — same reasoning as any checked exception: "this can legitimately happen, so acknowledge it."

```java
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // re-set the flag you just consumed, don't swallow it
}
```

Calling `Thread.currentThread().interrupt()` inside the catch matters: catching `InterruptedException` automatically clears the thread's interrupted status, so if you don't restore it, any code further up the call stack that checks `isInterrupted()` will wrongly see "not interrupted."

## `TimeUnit.sleep()` — same thing, more readable

```java
import java.util.concurrent.TimeUnit;

TimeUnit.SECONDS.sleep(2);
TimeUnit.MILLISECONDS.sleep(500);
```

Functionally identical to `Thread.sleep()`; it just reads better when the duration isn't naturally in milliseconds.

## The real cost of `sleep()` in loops, at scale

```java
while (!isReady()) {
    Thread.sleep(500); // polling
}
```

This works, but every sleeping thread here is a full OS thread sitting idle, doing nothing but occupying a limited resource — it's not "free" the way it might look. At low concurrency that's irrelevant. At high concurrency it's exactly the kind of blocking wait that virtual threads (Java 21+) are built to make cheap, since a blocked virtual thread doesn't pin a real OS thread the way a blocked platform thread does — and it's also why reactive/async styles (`CompletableFuture`, scheduled executors) exist: they avoid holding a thread hostage while waiting at all.


[[Threads]]