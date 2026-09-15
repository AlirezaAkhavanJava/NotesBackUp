

## 1. Thread Priority

### Definition

**Thread priority** is an integer value (1–10) attached to a `Thread` object that acts as a **hint** to the CPU scheduler about how much preference this thread should get relative to others when multiple threads are competing for CPU time. It does **not** guarantee execution order or timing — it's advisory, and the actual effect depends entirely on the underlying OS scheduler.

```java
Thread.MIN_PRIORITY   // 1
Thread.NORM_PRIORITY   // 5 (default for every new thread, unless changed)
Thread.MAX_PRIORITY     // 10
```

### Setting and getting priority

```java
Thread t = new Thread(() -> System.out.println("Task running"));
t.setPriority(Thread.MAX_PRIORITY); // hint: prefer this thread when scheduling
t.start();

System.out.println(t.getPriority()); // 10
```

### Where priority comes from — child threads inherit their parent's priority by default

```java
System.out.println(Thread.currentThread().getPriority()); // typically 5 (NORM_PRIORITY)

Thread child = new Thread(() -> {
    System.out.println(Thread.currentThread().getPriority()); // inherits 5 from the thread that created it
});
child.start();
```

### Why priority is unreliable in practice

```java
Thread low = new Thread(() -> {
    for (int i = 0; i < 5; i++) System.out.println("LOW: " + i);
});
Thread high = new Thread(() -> {
    for (int i = 0; i < 5; i++) System.out.println("HIGH: " + i);
});

low.setPriority(Thread.MIN_PRIORITY);
high.setPriority(Thread.MAX_PRIORITY);

low.start();
high.start();
```

You might _expect_ `HIGH` to consistently print first/more often — but in practice, output ordering is still largely unpredictable. This connects directly back to the CPU scheduler tutorial: Java priority is just one hint among many factors the **OS-level scheduler** actually uses, and different operating systems map Java's 1–10 scale to their own native priority systems differently (some OSes have far fewer priority levels than 10, causing several Java priorities to collapse into the same effective OS priority).

**Practical takeaway:** don't rely on thread priority for correctness or guaranteed ordering — if you need one task to definitely happen before another, use proper coordination (`join()`, `wait()`/`notify()`, or higher-level tools like `CompletableFuture` chaining), not priority. Priority is, at best, a mild performance-tuning hint for CPU-bound scenarios with genuine resource contention — rarely used in typical application code.

---

## 2. Thread Sleep

### Definition

**`Thread.sleep(long millis)`** pauses the **currently executing thread** for at least the specified number of milliseconds, **without consuming CPU time** during that pause and **without releasing any locks it holds**.

```java
public static void main(String[] args) throws InterruptedException {
    System.out.println("Before sleep: " + System.currentTimeMillis());
    Thread.sleep(2000); // pause for 2 seconds
    System.out.println("After sleep: " + System.currentTimeMillis());
}
```

It's a **static** method — it always affects whichever thread is executing that line, never a thread you don't control:

```java
Thread t = new Thread(() -> {
    try {
        Thread.sleep(1000); // pauses THIS worker thread, not main
        System.out.println("Worker resumed");
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
});
t.start();
System.out.println("Main continues immediately"); // doesn't wait for t's sleep
```

### Why it throws a checked exception

```java
Thread.sleep(1000); // COMPILE ERROR without handling InterruptedException
```

```java
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // standard practice — restore the flag
}
```

**Why:** as covered in the thread-methods tutorial, if another thread calls `.interrupt()` on a sleeping thread, the sleep is cut short immediately and `InterruptedException` is thrown right there — this is a genuinely expected outcome (not a bug), so Java forces you to handle it, following the checked-exception philosophy from the exceptions tutorial ("this can happen in normal operation, acknowledge it").

### `sleep` relative to the scheduler — connecting to the CPU scheduler tutorial

When a thread sleeps, it moves out of the `RUNNABLE` state into `TIMED_WAITING` — it stops competing for CPU time entirely during that period, exactly like the "blocked" state described in the scheduler tutorial. This is _why_ sleeping doesn't burn CPU cycles the way a busy-wait loop (`while (condition) {}`) would.

```java
Thread t = new Thread(() -> {
    try { Thread.sleep(5000); } catch (InterruptedException e) {}
});
t.start();
System.out.println(t.getState()); // RUNNABLE or TIMED_WAITING, depending on exact timing
```

### `sleep` does NOT release locks — an important gotcha

```java
class Resource {
    synchronized void doWork() throws InterruptedException {
        System.out.println("Holding lock, now sleeping...");
        Thread.sleep(3000);       // lock is STILL held during this entire sleep!
        System.out.println("Done sleeping, releasing lock");
    }
}
```

If another thread tries to enter a `synchronized` block on the same object during that sleep, it will **block for the full 3 seconds**, because `sleep()` (unlike `wait()`) does not give up the lock it's holding. This is a common source of accidental performance bottlenecks — sleeping inside a `synchronized` block holds up every other thread waiting on that same lock, even though the sleeping thread isn't doing any real work.

**Fix:** avoid sleeping while holding a lock, if other threads need that lock during the wait:

```java
class Resource {
    void doWork() throws InterruptedException {
        Thread.sleep(3000);           // sleep OUTSIDE the synchronized block
        synchronized (this) {
            System.out.println("Now doing the actual protected work");
        }
    }
}
```

### `sleep(0)` and very short sleeps

```java
Thread.sleep(0); // legal, but essentially a no-op / very brief pause — rarely useful
```

### Practical real-world uses of `sleep`

```java
// 1. Polling loop — checking a condition periodically without busy-waiting
while (!isReady()) {
    Thread.sleep(500); // check every 500ms instead of constantly spinning
}
```

```java
// 2. Simulating delay / rate limiting in demos or retry logic
for (int attempt = 1; attempt <= 3; attempt++) {
    try {
        callExternalService();
        break;
    } catch (Exception e) {
        System.out.println("Retrying in 2s...");
        Thread.sleep(2000);
    }
}
```

**Important caveat for real production retry/polling logic:** `Thread.sleep()` in a loop like this **blocks an entire OS thread** doing nothing useful — fine for simple scripts or low-concurrency code, but wasteful at scale (ties up a real, limited OS thread resource, as covered in the CPU scheduler tutorial). In high-concurrency systems, this is exactly the kind of blocking wait that virtual threads (Java 21+) make much cheaper, or that reactive/async approaches (`CompletableFuture`, scheduled executors) avoid entirely by not tying up a thread while waiting.

### `TimeUnit.sleep()` — a more readable alternative

```java
import java.util.concurrent.TimeUnit;

TimeUnit.SECONDS.sleep(2);   // clearer than Thread.sleep(2000)
TimeUnit.MILLISECONDS.sleep(500);
```

Functionally identical to `Thread.sleep()` underneath, just more readable when the unit isn't milliseconds — a small but genuinely common style preference in real code.

---

## Priority vs Sleep — how they relate

||Thread Priority|`Thread.sleep()`|
|---|---|---|
|What it does|hints scheduling preference between competing threads|pauses the current thread for a fixed duration|
|Guarantees?|none — advisory only|guarantees _at least_ the given duration (can be longer, never shorter)|
|Affects the scheduler how|influences which RUNNABLE thread gets picked next|removes the thread from RUNNABLE entirely, into TIMED_WAITING|
|Releases locks held?|n/a|No — this is a common source of bugs|
|Typical real use|rare — mild performance tuning|common — polling, delays, retry logic, simulating work in demos|

## Where this fits with everything else

Both connect directly back to the CPU scheduler tutorial: **priority** is a scheduling-decision hint for threads that _are_ competing for a core (`RUNNABLE`); **sleep** removes a thread from that competition entirely for a fixed period (`TIMED_WAITING`), which is exactly why sleeping threads consume no CPU. And the "sleep doesn't release locks" gotcha is a direct, practical instance of the "context switching can happen mid-operation" idea from the same tutorial — the scheduler doesn't know or care that your sleeping thread is holding a lock; it just knows that thread isn't runnable right now, and everything waiting on that lock simply waits longer.


[[Java]]