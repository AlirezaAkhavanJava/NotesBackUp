

## 1. Creating a Thread — all the ways

### Way 1: Implement `Runnable`, pass to `Thread` (preferred)

```java
Runnable task = () -> System.out.println("Running on: " + Thread.currentThread().getName());
Thread thread = new Thread(task);
thread.start();
```

### Way 2: Extend `Thread` directly

```java
class MyThread extends Thread {
    @Override
    public void run() {
        System.out.println("Running on: " + getName());
    }
}

MyThread t = new MyThread();
t.start();
```

### Way 3: Anonymous class

```java
Thread thread = new Thread() {
    @Override
    public void run() {
        System.out.println("Anonymous thread running");
    }
};
thread.start();
```

### Way 4: Naming a thread

```java
Thread thread = new Thread(() -> System.out.println("Hi"), "Worker-1");
thread.start();
System.out.println(thread.getName()); // Worker-1
```

**Which to use:** `Runnable` + `Thread` (Way 1) is the standard modern approach — it separates "the task" from "the mechanism running it," and lets your task class extend something else if needed (Java has no multiple inheritance, so extending `Thread` uses up your one `extends`).

---

## 2. Starting, joining, and basic control

```java
Thread thread = new Thread(() -> {
    for (int i = 1; i <= 3; i++) {
        System.out.println("Working: " + i);
    }
});

thread.start();     // begins execution on a new thread
thread.join();       // BLOCKS the calling thread until `thread` finishes
System.out.println("Thread finished");
```

**`join()`** — makes the current thread wait for another thread to complete before continuing. Without it, `main()` might print "Thread finished" before the worker thread is even done.

```java
thread.join(2000); // wait at most 2000ms, then continue regardless
```

### Sleeping a thread

```java
Thread.sleep(1000); // pauses THIS thread for 1000ms (throws InterruptedException — checked)
```

```java
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // restore the interrupt flag — standard practice
}
```

### Checking thread state

```java
System.out.println(thread.getState());     // NEW, RUNNABLE, TERMINATED, etc.
System.out.println(thread.isAlive());        // true if started and not yet finished
System.out.println(thread.getId());            // unique thread ID
System.out.println(Thread.currentThread());     // reference to whichever thread runs this line
```

### Daemon threads

```java
Thread backgroundTask = new Thread(() -> { /* ... */ });
backgroundTask.setDaemon(true); // must be set BEFORE start()
backgroundTask.start();
```

**Daemon vs. normal (user) thread:** the JVM exits once all **non-daemon** threads finish — it doesn't wait for daemon threads. Use daemon threads for background housekeeping (e.g., a periodic cache cleaner) that shouldn't prevent the program from exiting.

### Interrupting a thread

```java
Thread thread = new Thread(() -> {
    while (!Thread.currentThread().isInterrupted()) {
        // do work
    }
    System.out.println("Stopped gracefully");
});
thread.start();
thread.interrupt(); // requests the thread to stop — it must check for this itself
```

**Important:** `interrupt()` doesn't forcibly kill a thread — it just sets a flag. Your running code must **check** `isInterrupted()` (or catch `InterruptedException` from a blocking call like `sleep()`) and choose to stop. This is the correct, safe way to stop a thread — Java deliberately has no safe "force kill" method.

---

## 3. Synchronization — coordinating threads that share data

### `synchronized` method

```java
class Counter {
    private int count = 0;
    public synchronized void increment() { count++; }
    public synchronized int get() { return count; }
}
```

### `synchronized` block (more granular — lock only what's needed)

```java
class Counter {
    private int count = 0;
    private final Object lock = new Object();

    void increment() {
        synchronized (lock) {
            count++;
        }
    }
}
```

### Waiting/notifying between threads

```java
class SharedBox {
    private String data;
    private boolean available = false;

    synchronized void put(String value) {
        data = value;
        available = true;
        notify();          // wake up a thread waiting on this object
    }

    synchronized String take() throws InterruptedException {
        while (!available) {
            wait();          // releases the lock, waits until notify() is called
        }
        available = false;
        return data;
    }
}
```

**Use case:** a classic producer-consumer setup — one thread produces data, another consumes it, `wait()`/`notify()` coordinate the handoff without busy-looping.

---

## 4. `ExecutorService` — why we need thread pools

Creating a raw `new Thread()` per task is expensive (each real OS thread costs memory and setup time) and gives you no control over how many run at once — spawn too many, and you overwhelm the CPU/OS with context-switching overhead instead of getting useful work done.

**A thread pool solves this by maintaining a fixed, reusable set of worker threads.** You submit tasks; the pool assigns them to available threads and queues the rest — so you get controlled, efficient concurrency instead of unbounded thread creation.

```java
import java.util.concurrent.*;
```

### Creating a thread pool

```java
ExecutorService pool = Executors.newFixedThreadPool(4); // exactly 4 reusable threads
```

### Submitting tasks

```java
pool.submit(() -> System.out.println("Task running on " + Thread.currentThread().getName()));

pool.execute(() -> System.out.println("Also works with execute()")); // no return value at all
```

**`submit()` vs `execute()`:** `execute(Runnable)` (from the base `Executor` interface) fires a task with no way to get a result or catch exceptions cleanly. `submit()` (from `ExecutorService`) returns a `Future`, letting you retrieve a result or exception later — use `submit()` in almost all real code.

### Getting results back — `Future`

```java
Callable<Integer> task = () -> {
    Thread.sleep(1000);
    return 42;
};

Future<Integer> future = pool.submit(task);

System.out.println("Doing other work while task runs...");

Integer result = future.get(); // BLOCKS until the result is ready
System.out.println("Result: " + result);
```

```java
try {
    Integer result = future.get(2, TimeUnit.SECONDS); // wait at most 2 seconds
} catch (TimeoutException e) {
    System.out.println("Task took too long");
    future.cancel(true); // attempt to cancel/interrupt it
}
```

### Submitting many tasks and collecting all results

```java
List<Callable<Integer>> tasks = List.of(
    () -> compute(1),
    () -> compute(2),
    () -> compute(3)
);

List<Future<Integer>> futures = pool.invokeAll(tasks); // runs all, waits for all to finish

for (Future<Integer> f : futures) {
    System.out.println(f.get());
}
```

```java
// Get whichever finishes FIRST, ignore the rest
Integer firstResult = pool.invokeAny(tasks);
```

### Shutting down a pool — always required

```java
pool.shutdown();                              // stop accepting new tasks, finish existing ones
boolean finished = pool.awaitTermination(5, TimeUnit.SECONDS); // wait up to 5s for shutdown
if (!finished) {
    pool.shutdownNow();                          // force-stop remaining tasks
}
```

**Java 19+ convenience** — `ExecutorService` now implements `AutoCloseable`, so try-with-resources handles shutdown automatically:

```java
try (ExecutorService pool = Executors.newFixedThreadPool(4)) {
    pool.submit(() -> System.out.println("task"));
} // automatically shut down when the block exits
```

**Why shutdown matters:** an `ExecutorService`'s threads don't stop on their own — forgetting to shut one down leaves its threads running indefinitely, which can prevent your JVM from exiting at all (if they're not daemon threads).

---

## 5. Types of thread pools (`Executors` factory methods)

```java
ExecutorService fixed = Executors.newFixedThreadPool(4);
// Exactly N threads, always. Extra tasks QUEUE until a thread frees up.
// Use for: predictable, steady CPU-bound workloads.

ExecutorService cached = Executors.newCachedThreadPool();
// Creates threads AS NEEDED, reuses idle ones, removes threads idle >60s.
// Can grow unboundedly under heavy load!
// Use for: many short-lived tasks, bursty workloads.

ExecutorService single = Executors.newSingleThreadExecutor();
// Exactly ONE thread — tasks run one at a time, in submission order.
// Use for: tasks that must run sequentially, without needing raw synchronized code.

ScheduledExecutorService scheduled = Executors.newScheduledThreadPool(2);
// Like fixed pool, but supports delayed/repeating tasks (see below).

ExecutorService virtual = Executors.newVirtualThreadPerTaskExecutor(); // Java 21+
// Creates a NEW virtual thread per task — extremely cheap, can handle huge volumes.
// Use for: I/O-bound tasks (blocking calls, waiting) at massive scale.
```

### Custom pool — `ThreadPoolExecutor` directly, for full control

```java
ExecutorService custom = new ThreadPoolExecutor(
    2,                                  // core pool size — threads kept alive even when idle
    8,                                   // max pool size — upper limit under load
    60L, TimeUnit.SECONDS,                // idle timeout for extra threads beyond core size
    new LinkedBlockingQueue<>(100)          // task queue capacity
);
```

**When to use this instead of `Executors.newX()`:** when you need precise control over queue size (unbounded queues from `Executors` factory methods can hide memory problems under sustained overload), or a custom rejection policy for when the pool is saturated.

---

## 6. Scheduled tasks — running things later or repeatedly

```java
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

// Run ONCE, after a delay
scheduler.schedule(() -> System.out.println("Ran after 5 seconds"), 5, TimeUnit.SECONDS);

// Run repeatedly, with a FIXED delay between the END of one run and the START of the next
scheduler.scheduleWithFixedDelay(
    () -> System.out.println("Runs every 2s after previous finishes"),
    0, 2, TimeUnit.SECONDS
);

// Run repeatedly, at a FIXED RATE regardless of how long each run takes
scheduler.scheduleAtFixedRate(
    () -> System.out.println("Runs every 3s, by the clock"),
    0, 3, TimeUnit.SECONDS
);
```

**`scheduleWithFixedDelay` vs `scheduleAtFixedRate`:** fixed-delay waits N seconds _after each run finishes_ before starting the next; fixed-rate tries to start every N seconds _regardless_ of how long the previous run took (if a run takes longer than the interval, the next one starts immediately after).

**Use case:** periodic health checks, cache refresh jobs, polling a resource on a schedule — without needing a manual `Thread.sleep()` loop.

---

## 7. Choosing pool size — practical guidance

```java
int cores = Runtime.getRuntime().availableProcessors();
```

|Workload type|Suggested pool size|
|---|---|
|CPU-bound (heavy computation, little/no waiting)|roughly `cores` (or `cores + 1`) — more threads than cores just adds context-switch overhead|
|I/O-bound (waiting on DB, network, disk)|can be much larger than `cores`, since threads spend most time waiting, not computing — or better, use virtual threads|
|Mixed|somewhere in between, or split into separate pools per workload type|

```java
ExecutorService cpuBoundPool = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
ExecutorService ioBoundPool = Executors.newVirtualThreadPerTaskExecutor(); // Java 21+, scales naturally
```

---

## 8. Full worked example — processing tasks concurrently with a pool

```java
import java.util.concurrent.*;
import java.util.*;

public class ImageProcessor {

    public static void main(String[] args) throws InterruptedException, ExecutionException {
        List<String> images = List.of("img1.jpg", "img2.jpg", "img3.jpg", "img4.jpg");

        try (ExecutorService pool = Executors.newFixedThreadPool(2)) {

            List<Future<String>> futures = new ArrayList<>();
            for (String image : images) {
                futures.add(pool.submit(() -> processImage(image)));
            }

            for (Future<String> future : futures) {
                System.out.println(future.get()); // collect results as they complete
            }
        } // pool auto-shuts-down here (Java 19+ AutoCloseable)
    }

    static String processImage(String name) throws InterruptedException {
        Thread.sleep(500); // simulate work
        return name + " processed on " + Thread.currentThread().getName();
    }
}
```

---

## 9. `CompletableFuture` with a custom pool — combining async chaining and pool control

```java
ExecutorService pool = Executors.newFixedThreadPool(4);

CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> fetchUser(1), pool)       // runs on `pool`, not the default common pool
    .thenApplyAsync(user -> user.getName(), pool)
    .thenApply(String::toUpperCase);

future.thenAccept(System.out::println);
```

**Why pass `pool` explicitly:** without it, `CompletableFuture` uses a shared default pool (`ForkJoinPool.commonPool()`) — passing your own pool isolates this work from other parallel work happening elsewhere in the JVM (same reasoning as the `parallelStream()` isolation point from the parallelism tutorial).

---

## Quick reference — thread & thread pool toolkit

|Need|Tool|
|---|---|
|Run one task on its own thread|`new Thread(runnable).start()`|
|Wait for a thread to finish|`thread.join()`|
|Pause a thread|`Thread.sleep(ms)`|
|Stop a thread cooperatively|`thread.interrupt()` + check `isInterrupted()`|
|Protect shared mutable data|`synchronized`, `ReentrantLock`, or `java.util.concurrent.atomic.*`|
|Coordinate handoff between threads|`wait()` / `notify()`|
|Run many short tasks efficiently|`ExecutorService` (`newFixedThreadPool`, etc.)|
|Get a result back from a task|`Callable` + `submit()` → `Future`|
|Run all tasks, wait for all|`invokeAll()`|
|Run all tasks, take the first done|`invokeAny()`|
|Run something later / repeatedly|`ScheduledExecutorService`|
|Massive I/O-bound concurrency|`Executors.newVirtualThreadPerTaskExecutor()`|
|Chain async steps declaratively|`CompletableFuture`|
|Always clean up a pool|`shutdown()` + `awaitTermination()`, or try-with-resources (Java 19+)|

[[Java]]