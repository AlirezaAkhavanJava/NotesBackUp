

Complete reference of `Thread`'s methods — instance methods and static methods, grouped by purpose.

---

## 1. Lifecycle control methods

### `start()`

Creates a new OS thread and begins executing `run()` on it.

```java
Thread t = new Thread(() -> System.out.println("Running"));
t.start(); // actually creates a new thread
```

**Can only be called once per `Thread` object** — calling it a second time throws `IllegalThreadStateException`.

### `run()`

Contains the code to execute. If called directly (not via `start()`), it just runs like a normal method — **no new thread is created.**

```java
Thread t = new Thread(() -> System.out.println("Hello"));
t.run(); // prints "Hello" on the CURRENT thread — no concurrency happened
```

### `join()`

Blocks the calling thread until the target thread finishes.

```java
Thread worker = new Thread(() -> {
    for (int i = 1; i <= 3; i++) System.out.println("Working: " + i);
});
worker.start();
worker.join(); // main thread waits here until worker is done
System.out.println("Worker finished");
```

### `join(long millis)`

Waits at most the given milliseconds, then continues regardless.

```java
worker.join(2000); // wait max 2 seconds for worker to finish
System.out.println("Continuing whether or not worker finished");
```

### `interrupt()`

Signals a thread that it should stop — sets its interrupt flag. Doesn't force-stop it.

```java
Thread t = new Thread(() -> {
    while (!Thread.currentThread().isInterrupted()) {
        // working...
    }
    System.out.println("Stopped due to interrupt");
});
t.start();
t.interrupt();
```

If the thread is blocked in `sleep()`/`wait()`/`join()` when interrupted, those methods throw `InterruptedException` immediately instead of waiting:

```java
Thread t = new Thread(() -> {
    try {
        Thread.sleep(10000);
    } catch (InterruptedException e) {
        System.out.println("Sleep interrupted early!");
    }
});
t.start();
t.interrupt(); // wakes it up immediately, throws InterruptedException inside
```

---

## 2. Static methods (act on the _current_ thread)

### `Thread.currentThread()`

Returns a reference to the thread executing this line of code right now.

```java
System.out.println(Thread.currentThread().getName()); // e.g. "main"
```

### `Thread.sleep(long millis)`

Pauses the **current** thread for the given time. Throws checked `InterruptedException`.

```java
System.out.println("Before sleep");
Thread.sleep(1000); // pauses for 1 second
System.out.println("After sleep");
```

### `Thread.sleep(long millis, int nanos)`

More precise sleep, with nanosecond adjustment (still not guaranteed to be exact — OS scheduling granularity applies).

```java
Thread.sleep(500, 500000); // ~500.5 ms
```

### `Thread.yield()`

A _hint_ to the scheduler that the current thread is willing to pause and let others run. Not guaranteed to do anything — purely advisory.

```java
Thread t = new Thread(() -> {
    for (int i = 0; i < 5; i++) {
        System.out.println("Iteration " + i);
        Thread.yield(); // suggest letting other threads run
    }
});
t.start();
```

### `Thread.onSpinWait()` (Java 9+)

A hint for tight busy-wait loops (e.g., waiting on a flag another thread will set), letting the CPU optimize/deprioritize slightly without a full sleep.

```java
while (!flag) {
    Thread.onSpinWait(); // hint: "I'm spin-waiting, optimize accordingly"
}
```

### `Thread.activeCount()`

Returns an estimate of the number of active threads in the current thread's thread group.

```java
System.out.println("Active threads: " + Thread.activeCount());
```

---

## 3. Naming and identity

### `setName(String name)` / `getName()`

```java
Thread t = new Thread(() -> {});
t.setName("Worker-1");
System.out.println(t.getName()); // Worker-1
```

Or set it directly in the constructor:

```java
Thread t = new Thread(() -> {}, "Worker-1");
```

### `getId()` (deprecated since Java 19 — use `threadId()` instead)

```java
System.out.println(t.getId()); // e.g. 14
```

### `threadId()` (Java 19+)

```java
System.out.println(t.threadId()); // preferred replacement for getId()
```

---

## 4. Priority

### `setPriority(int priority)` / `getPriority()`

A _hint_ to the scheduler (1 = `MIN_PRIORITY`, 5 = `NORM_PRIORITY` default, 10 = `MAX_PRIORITY`) — the OS ultimately decides, so behavior is platform-dependent and not something to rely on for correctness.

```java
Thread t = new Thread(() -> System.out.println("high priority task"));
t.setPriority(Thread.MAX_PRIORITY); // hint: prefer scheduling this sooner/more often
t.start();

System.out.println(t.getPriority());
```

---

## 5. State inspection

### `getState()`

Returns the thread's current lifecycle state.

```java
Thread t = new Thread(() -> {
    try { Thread.sleep(1000); } catch (InterruptedException e) {}
});
System.out.println(t.getState()); // NEW
t.start();
System.out.println(t.getState()); // RUNNABLE or TIMED_WAITING (depending on timing)
```

### `isAlive()`

`true` if the thread has been started and hasn't yet terminated.

```java
Thread t = new Thread(() -> {
    try { Thread.sleep(500); } catch (InterruptedException e) {}
});
t.start();
System.out.println(t.isAlive()); // true
t.join();
System.out.println(t.isAlive()); // false
```

### `isInterrupted()`

Checks (without clearing) whether the interrupt flag is set.

```java
Thread t = Thread.currentThread();
System.out.println(t.isInterrupted()); // false
t.interrupt();
System.out.println(t.isInterrupted()); // true
```

### `Thread.interrupted()` (static — checks AND clears the current thread's flag)

```java
if (Thread.interrupted()) { // checks the flag, then RESETS it to false
    System.out.println("Was interrupted — flag now cleared");
}
```

**Difference from `isInterrupted()`:** the static `Thread.interrupted()` clears the flag as a side effect; the instance method `isInterrupted()` does not. This distinction trips people up — use `isInterrupted()` when you just want to check without consuming the flag.

---

## 6. Daemon threads

### `setDaemon(boolean on)` / `isDaemon()`

Must be called **before** `start()`.

```java
Thread background = new Thread(() -> {
    while (true) {
        System.out.println("Cleaning cache...");
        try { Thread.sleep(5000); } catch (InterruptedException e) { break; }
    }
});
background.setDaemon(true); // JVM won't wait for this thread to exit
background.start();

System.out.println(background.isDaemon()); // true
```

If `background` were _not_ a daemon, the JVM would never exit while it's still looping — daemon threads let the JVM shut down without waiting for them.

---

## 7. Exception handling for uncaught exceptions

### `setUncaughtExceptionHandler(...)` / `getUncaughtExceptionHandler()`

By default, an uncaught exception in a thread just prints a stack trace to `System.err` and the thread dies silently otherwise. You can customize this:

```java
Thread t = new Thread(() -> {
    throw new RuntimeException("Something broke");
});

t.setUncaughtExceptionHandler((thread, exception) -> {
    System.out.println("Thread " + thread.getName() + " failed: " + exception.getMessage());
});

t.start();
```

### `Thread.setDefaultUncaughtExceptionHandler(...)` (static, applies JVM-wide)

```java
Thread.setDefaultUncaughtExceptionHandler((thread, exception) -> {
    System.out.println("Uncaught in " + thread.getName() + ": " + exception);
});
```

**Real-world use:** logging frameworks / monitoring tools commonly install a default handler so unexpected thread crashes get logged/reported instead of silently vanishing.

---

## 8. Thread groups (legacy — rarely used in modern code)

### `getThreadGroup()`

```java
Thread t = Thread.currentThread();
System.out.println(t.getThreadGroup().getName()); // e.g. "main"
```

`ThreadGroup` is an older organizational mechanism for grouping related threads — largely superseded by `ExecutorService` and modern concurrency utilities. Rarely used directly in modern code, included here for completeness.

---

## 9. Virtual thread specific (Java 21+)

### `Thread.ofVirtual()` / `Thread.ofPlatform()` — the modern builder API

```java
Thread virtualThread = Thread.ofVirtual()
    .name("virtual-worker")
    .start(() -> System.out.println("Running in a virtual thread"));

Thread platformThread = Thread.ofPlatform()
    .name("platform-worker")
    .start(() -> System.out.println("Running in a traditional OS-backed thread"));
```

### `Thread.startVirtualThread(Runnable)` — shortcut

```java
Thread vt = Thread.startVirtualThread(() -> System.out.println("Quick virtual thread"));
```

### `isVirtual()` (Java 21+)

```java
System.out.println(vt.isVirtual()); // true
System.out.println(Thread.currentThread().isVirtual()); // false, if on main
```

---

## Complete reference table

|Method|Static?|Purpose|
|---|---|---|
|`start()`|no|begin executing on a new thread|
|`run()`|no|the task's code (don't call directly for concurrency)|
|`join()` / `join(ms)`|no|wait for the thread to finish|
|`interrupt()`|no|request the thread stop|
|`isInterrupted()`|no|check interrupt flag (doesn't clear it)|
|`Thread.interrupted()`|yes|check AND clear the current thread's interrupt flag|
|`Thread.currentThread()`|yes|get a reference to the running thread|
|`Thread.sleep(ms)`|yes|pause the current thread|
|`Thread.yield()`|yes|hint: let other threads run|
|`Thread.onSpinWait()`|yes|hint for busy-wait loops|
|`setName()` / `getName()`|no|thread naming|
|`threadId()` (`getId()` deprecated)|no|unique thread identifier|
|`setPriority()` / `getPriority()`|no|scheduling hint (1–10)|
|`getState()`|no|current lifecycle state|
|`isAlive()`|no|started and not yet finished?|
|`setDaemon()` / `isDaemon()`|no|mark as background/daemon thread|
|`setUncaughtExceptionHandler()`|no|handle uncaught exceptions per-thread|
|`Thread.setDefaultUncaughtExceptionHandler()`|yes|JVM-wide default handler|
|`getThreadGroup()`|no|legacy grouping mechanism|
|`Thread.ofVirtual()` / `Thread.ofPlatform()`|yes|modern thread-builder API (Java 21+)|
|`Thread.startVirtualThread()`|yes|quick virtual thread creation (Java 21+)|
|`isVirtual()`|no|check if a thread is virtual (Java 21+)|

## A combined example using several together

```java
public class ThreadMethodsDemo {
    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> {
            System.out.println("Started: " + Thread.currentThread().getName());
            try {
                for (int i = 1; i <= 3; i++) {
                    System.out.println("Step " + i);
                    Thread.sleep(300);
                }
            } catch (InterruptedException e) {
                System.out.println("Interrupted during work!");
                Thread.currentThread().interrupt(); // restore flag
            }
        }, "Worker-Thread");

        worker.setPriority(Thread.NORM_PRIORITY);
        worker.setUncaughtExceptionHandler((t, e) -> System.out.println("Error in " + t.getName() + ": " + e));

        System.out.println("State before start: " + worker.getState()); // NEW
        worker.start();
        System.out.println("Is alive: " + worker.isAlive());              // true

        worker.join(1000); // wait up to 1s

        System.out.println("Final state: " + worker.getState());        // TERMINATED (likely, if finished)
    }
}
```


[[Java]]