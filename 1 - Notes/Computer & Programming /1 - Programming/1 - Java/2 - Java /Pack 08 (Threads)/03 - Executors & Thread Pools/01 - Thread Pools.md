

Creating a thread is expensive, and uncontrolled thread creation can crash your application. A **thread pool** solves both problems: it keeps a fixed set of worker threads alive and feeds them tasks from a queue. You submit work; the pool decides which thread runs it and when. Almost every server-side Java application, including Spring Boot, runs on thread pools, so understanding them is essential.

## The problem: why not just `new Thread()`?

```java
for (int i = 0; i < 100_000; i++) {
    new Thread(() -> handleRequest()).start();
}
```

This looks fine but breaks in production for three reasons:

1. **Creation cost.** A platform thread is backed by an OS thread. Creating and destroying one takes real time, which is wasted if the task itself is short.
2. **Memory.** Each thread reserves a stack (often around 1 MB by default). 100,000 threads means roughly 100 GB of reserved stack space, and you will hit `OutOfMemoryError: unable to create native thread`.
3. **Context switching.** With far more threads than CPU cores, the OS spends more time switching between them than doing useful work.

A thread pool fixes this by **reusing** a limited number of threads and **queueing** the excess work.

## The core idea: three moving parts

- **Worker threads**: long-lived threads that loop, taking tasks and running them.
- **Task queue**: a waiting line holding tasks no worker is free to run yet.
- **Executor**: the object you submit tasks to. It owns the workers and the queue.

You describe _what_ to run (a `Runnable` or `Callable`). The pool decides _which thread_ and _when_.

## Your first pool: `ExecutorService`

```java
import java.util.concurrent.*;

public class Demo {
    public static void main(String[] args) {
        ExecutorService pool = Executors.newFixedThreadPool(3);

        for (int i = 1; i <= 6; i++) {
            int taskId = i;
            pool.submit(() -> {
                System.out.println("Task " + taskId + " on " + Thread.currentThread().getName());
            });
        }

        pool.shutdown();
    }
}
```

Six tasks, only three threads. Output will show names like `pool-1-thread-1`, `pool-1-thread-2`, `pool-1-thread-3` repeating, because threads are reused.

**Always call `shutdown()`.** Pool threads are non-daemon by default, so without it the JVM never exits.

```java
pool.shutdown();                          // stop accepting new tasks, finish queued ones
if (!pool.awaitTermination(30, TimeUnit.SECONDS)) {
    pool.shutdownNow();                   // interrupt running tasks, drop queued ones
}
```

## Getting results back: `Callable` and `Future`

`Runnable` returns nothing and cannot throw checked exceptions. `Callable<T>` returns a value and can throw.

```java
ExecutorService pool = Executors.newFixedThreadPool(2);

Future<Integer> future = pool.submit(() -> {
    Thread.sleep(1000);
    return 42;
});

System.out.println("Doing other work...");
Integer result = future.get();   // blocks until the result is ready
System.out.println(result);

pool.shutdown();
```

Key `Future` methods:

- `get()` blocks until done. If the task threw an exception, it comes back wrapped in an `ExecutionException`.
- `get(timeout, unit)` gives up waiting after a time limit.
- `isDone()` checks without blocking.
- `cancel(true)` attempts to cancel, interrupting the thread if it is running.

A common mistake: if you `submit()` a task and never call `get()`, any exception it throws is silently swallowed. With `execute()` (Runnable only), the exception reaches the thread's uncaught exception handler instead.

## The factory pools in `Executors`

|Factory method|Behavior|Best for|
|---|---|---|
|`newFixedThreadPool(n)`|Exactly `n` threads, unbounded queue|Steady, predictable load|
|`newCachedThreadPool()`|Creates threads as needed, reuses idle ones, idle threads die after 60 s|Many short-lived tasks|
|`newSingleThreadExecutor()`|One thread, tasks run strictly in order|Sequential processing|
|`newScheduledThreadPool(n)`|Runs tasks after a delay or periodically|Timers, polling|
|`newVirtualThreadPerTaskExecutor()`|One cheap virtual thread per task|Blocking I/O work (see below)|

Scheduled example:

```java
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

scheduler.schedule(() -> System.out.println("Once, after 2s"), 2, TimeUnit.SECONDS);
scheduler.scheduleAtFixedRate(() -> System.out.println("Tick"), 0, 5, TimeUnit.SECONDS);
```

## What is really inside: `ThreadPoolExecutor`

Every factory above is a shortcut for `ThreadPoolExecutor`. To use pools well in production you must understand its constructor:

```java
ThreadPoolExecutor pool = new ThreadPoolExecutor(
    4,                                  // corePoolSize
    8,                                  // maximumPoolSize
    60, TimeUnit.SECONDS,               // keepAliveTime for extra threads
    new ArrayBlockingQueue<>(100),      // work queue (bounded!)
    Executors.defaultThreadFactory(),   // how threads are created
    new ThreadPoolExecutor.CallerRunsPolicy()  // what to do when saturated
);
```

### How a new task is handled (the order matters)

1. If fewer than `corePoolSize` threads exist, **start a new thread** for the task.
2. Otherwise, **put the task in the queue**.
3. If the queue is **full**, and fewer than `maximumPoolSize` threads exist, **start an extra thread**.
4. If the queue is full and the maximum is reached, the **rejection policy** runs.

The surprising part is step 2 versus 3: the pool prefers queueing over growing past the core size. Extra threads appear only when the queue is full. This is why an **unbounded** queue makes `maximumPoolSize` meaningless: the queue never fills, so the pool never grows beyond core.

### Rejection policies

When the pool is saturated, one of these runs:

- `AbortPolicy` (default): throws `RejectedExecutionException`.
- `CallerRunsPolicy`: the submitting thread runs the task itself. This naturally slows down producers, acting as backpressure.
- `DiscardPolicy`: silently drops the task.
- `DiscardOldestPolicy`: drops the oldest queued task and retries.

### Why the `Executors` shortcuts can be dangerous

- `newFixedThreadPool` and `newSingleThreadExecutor` use an **unbounded queue**. If tasks arrive faster than they finish, the queue grows until you run out of memory.
- `newCachedThreadPool` has an **unlimited maximum thread count**. A burst of slow tasks can create thousands of threads.

For production services, building a `ThreadPoolExecutor` with a **bounded queue** and a deliberate rejection policy is the safer choice.

## Choosing a pool size

The right size depends on what your tasks spend their time doing.

- **CPU-bound** (calculation, parsing, compression): threads are always busy, so more threads than cores only adds switching cost. Start with:
    
    `threads ≈ number of cores (+1)`
    
    ```java
    int cores = Runtime.getRuntime().availableProcessors();
    ```
    
- **I/O-bound** (database calls, HTTP calls, disk): threads spend most of their time waiting, so you can run more than the core count. A common estimate:
    
    `threads ≈ cores × (1 + waitTime / computeTime)`
    
    If a task waits 90 ms and computes for 10 ms, that is `cores × 10`.
    

These are starting points. Measure under real load and adjust.

Also, **don't mix slow and fast tasks in one pool.** If slow tasks occupy every thread, fast ones sit in the queue. Use separate pools per kind of work.

## Naming your threads

Default names like `pool-3-thread-2` are useless in logs and thread dumps. Provide a `ThreadFactory`:

```java
ThreadFactory factory = new ThreadFactory() {
    private final AtomicInteger counter = new AtomicInteger(1);

    @Override
    public Thread newThread(Runnable r) {
        Thread t = new Thread(r, "order-worker-" + counter.getAndIncrement());
        t.setDaemon(false);
        return t;
    }
};

ExecutorService pool = Executors.newFixedThreadPool(4, factory);
```

(`AtomicInteger` is in `java.util.concurrent.atomic`.)

## Running many tasks at once

```java
List<Callable<String>> tasks = List.of(
    () -> "A",
    () -> "B",
    () -> "C"
);

List<Future<String>> results = pool.invokeAll(tasks);   // waits for all
String first = pool.invokeAny(tasks);                   // returns the first one to succeed
```

## Composing async work: `CompletableFuture`

`Future.get()` blocks. `CompletableFuture` lets you chain steps without blocking, and you should pass your own pool so you don't depend on the shared default one:

```java
ExecutorService ioPool = Executors.newFixedThreadPool(10);

CompletableFuture<String> result = CompletableFuture
    .supplyAsync(() -> fetchUser(1), ioPool)
    .thenApply(user -> user.toUpperCase())
    .exceptionally(ex -> "fallback");

System.out.println(result.join());
```

Without the second argument, `supplyAsync` uses `ForkJoinPool.commonPool()`, which is sized for CPU work and is shared across your whole JVM. Putting blocking I/O there can starve unrelated code.

## Virtual threads (the modern alternative)

Since Java 21, you can create **virtual threads**: very lightweight threads managed by the JVM instead of the OS. Blocking inside one is cheap because the JVM parks it and lets the underlying carrier thread do other work.

```java
try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < 10_000; i++) {
        executor.submit(() -> {
            Thread.sleep(1000);
            return "done";
        });
    }
}   // close() waits for tasks to finish
```

Two rules differ from classic pools:

- **Don't pool virtual threads.** They are cheap enough to create one per task. The "pool" idea exists to limit expensive threads, which virtual threads are not.
- **Still limit the resource, not the thread.** If you must cap concurrent database calls to 20, use a `Semaphore` around that call rather than a pool of 20 threads.

Virtual threads shine for blocking I/O. For CPU-bound work they give no benefit, and a fixed pool sized to your cores is still correct.

## Common pitfalls

- **Forgetting `shutdown()`**: the JVM hangs on exit.
- **Unbounded queues**: memory grows silently under load.
- **Swallowed exceptions**: tasks submitted with `submit()` hide their errors until you call `get()`. Wrap task bodies in try/catch with logging.
- **Deadlock from nested waits**: a task running in a pool that submits another task to the _same_ pool and blocks on its result can deadlock when all threads are occupied waiting.
- **`ThreadLocal` leaks**: worker threads live a long time, so values left in a `ThreadLocal` persist into the next task. Always `remove()` them when done.
- **Sharing mutable state** between tasks without synchronization: pools run things concurrently, so thread-safety is still your responsibility.

## In Spring Boot

Spring wraps this same machinery. A typical configuration:

```java
@Configuration
@EnableAsync
public class AsyncConfig {

    @Bean(name = "taskExecutor")
    public ThreadPoolTaskExecutor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(4);
        executor.setMaxPoolSize(8);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("async-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        executor.initialize();
        return executor;
    }
}
```

```java
@Service
public class ReportService {

    @Async("taskExecutor")
    public CompletableFuture<String> generate() {
        return CompletableFuture.completedFuture("report");
    }
}
```

The parameters map one-to-one to `ThreadPoolExecutor`: core size, max size, queue capacity, rejection policy. Spring Boot's embedded server (Tomcat) also uses a thread pool for incoming requests, which is why a slow request handler can exhaust it. Since Spring Boot 3.2, setting `spring.threads.virtual.enabled=true` switches request handling and async execution to virtual threads.

## Summary

A thread pool reuses a limited number of threads and queues extra work, protecting you from the cost and instability of creating threads freely. Use `ExecutorService` with `Callable`/`Future` for results, `ThreadPoolExecutor` directly when you need control over queue size and rejection, size the pool by whether work is CPU- or I/O-bound, and reach for virtual threads when your tasks mostly wait on blocking I/O.


[[Threads]]