

**Thread management** is every decision about the threads in your application: how many exist, what they are called, how they report failures, and how they stop. In modern Java you rarely do this on individual `Thread` objects. You do it through **pools**, and the `Thread`-level tools (interruption, daemon flag, handlers) are the mechanisms the pools use underneath.

Earlier lessons gave you the pieces: the interrupt flag and daemon threads (`Thread` class lesson), `join` and a stoppable worker (lifecycle lesson), and pools with `ExecutorService` (thread-creation lesson). This lesson answers the next question: **how do those pieces behave when threads live inside a pool, and what silently goes wrong?**

---
## 1. Interruption: handling it correctly

The basics are unchanged: `interrupt()` sets a flag, and blocking calls (`sleep`, `wait`, `join`, `BlockingQueue.take()`) throw `InterruptedException` and **clear** that flag. Three things the basics didn't cover:

**An interrupt that arrives early is not lost.** If the flag is already set when a thread reaches `sleep()`, `sleep()` throws immediately.

**What you do in the `catch` depends on where you are:**

|Your situation|What to do|
|---|---|
|Your method can declare `throws InterruptedException`|Don't catch it. Let it propagate.|
|You're inside a `Runnable` (can't throw checked exceptions)|Restore the flag with `Thread.currentThread().interrupt()` and stop work.|
|You must release resources first|Do the cleanup in `finally`, then restore the flag.|

An empty `catch` is always wrong: the stop request disappears and the thread keeps running.

```java
String next(BlockingQueue<String> queue) throws InterruptedException {
    return queue.take();   // propagate: the caller decides what interruption means
}
```

**Not everything is interruptible.** Waiting to enter a `synchronized` block, or reading from a classic `java.io` socket, ignores `interrupt()`. Only the flag gets set. To stop such a thread you close the resource it is blocked on. NIO channels are the exception: interrupting a thread blocked on one closes the channel.

---
## 2. Stopping threads inside a pool

You don't hold the `Thread` objects of a pool, so you can't call `t.interrupt()`. You have two tools:

- `future.cancel(true)` interrupts the thread running that one task.
- `pool.shutdownNow()` interrupts **all** running tasks and returns the tasks that never started.

Both only _request_ a stop. The task must be written to respond, as in section 1. The proper shutdown sequence has three steps:

```java
static void stop(ExecutorService pool) throws InterruptedException {
    pool.shutdown();                                        // no new tasks; queued ones finish
    if (!pool.awaitTermination(10, TimeUnit.SECONDS)) {
        pool.shutdownNow();                                 // too slow: interrupt everything
        if (!pool.awaitTermination(5, TimeUnit.SECONDS)) {
            System.err.println("Pool did not terminate");   // a task ignores interrupts
        }
    }
}
```

Starting with `shutdownNow()` would kill work that was about to finish. Since Java 19, `ExecutorService` is `AutoCloseable`, and `close()` does the `shutdown()` + wait part for you in a try-with-resources.

A complete example, with a worker that cooperates:

```java
public class WorkerPool {
    public static void main(String[] args) throws InterruptedException {
        ExecutorService pool = Executors.newFixedThreadPool(2);

        pool.execute(() -> {
            try {
                while (!Thread.currentThread().isInterrupted()) {
                    System.out.println(Thread.currentThread().getName() + " working...");
                    Thread.sleep(1000);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            System.out.println(Thread.currentThread().getName() + " stopped");
        });

        Thread.sleep(3000);
        stop(pool);
    }
}
```

You'll see roughly three "working..." lines, then "stopped". There is no `running` flag: interruption alone is enough, and it also wakes the sleeping thread immediately.

## 3. Configuring the threads a pool creates: `ThreadFactory`

A pool creates its own threads, so you can't call `setName` or `setUncaughtExceptionHandler` on them directly. You pass a **`ThreadFactory`**, a one-method interface (`Thread newThread(Runnable r)`) that the pool calls whenever it needs a thread:

```java
AtomicInteger counter = new AtomicInteger(1);

ThreadFactory factory = r -> {
    Thread t = new Thread(r, "worker-" + counter.getAndIncrement());
    t.setUncaughtExceptionHandler((th, ex) ->
            System.err.println(th.getName() + " failed: " + ex));
    return t;
};

ExecutorService pool = Executors.newFixedThreadPool(2, factory);   // pass it at creation
```

Naming matters in practice. Thread names appear in logs and in thread dumps (`jcmd <pid> Thread.print` or `jstack <pid>`), and `pool-1-thread-3` tells you nothing when a production app hangs. On Java 21 the same thing can be written with the builder: `Thread.ofPlatform().name("worker-", 1).factory()`.

## 4. The uncaught-exception trap in pools

Your `Thread` class lesson showed that an uncaught exception kills only its own thread, and a handler lets you log it. Two rules:

- Set the handler **before `start()`**. Setting it inside the thread's own code after a `throw` is too late, because the throw already ended that code.
- In a pool, **it only fires for `execute()`**, not `submit()`:

```java
pool.execute(() -> { throw new IllegalStateException("A"); });   // handler runs: A is logged

Future<?> f = pool.submit(() -> { throw new IllegalStateException("B"); });
// nothing is printed. B is stored inside the Future.
try {
    f.get();
} catch (ExecutionException e) {
    System.err.println("Task failed: " + e.getCause());           // B shows up only here
}
```

`submit()` wraps your task in a `FutureTask` that catches every exception and keeps it. If you never call `get()`, the failure vanishes silently. For fire-and-forget tasks, use `execute()` or catch inside the task.

## 5. Daemon threads and pools

You know the rule from your `Thread` class lesson: the JVM exits when the last non-daemon thread ends. Pool threads are **non-daemon**, so a forgotten `shutdown()` keeps your program alive forever. You _can_ make pool threads daemon inside a `ThreadFactory` (`t.setDaemon(true)`), but then tasks can be cut off mid-way when `main` ends. Do it only for work you can afford to lose, such as metrics or monitoring. Never do it for work that must finish.

## 6. Priority, naming and `ThreadGroup`: what to ignore

- **Priority** (`setPriority`) is only a hint. Operating systems often ignore it. Don't build correctness on it.
- **`ThreadGroup`** is a legacy grouping mechanism. Its `activeCount()` is only an estimate, and pools replaced it. If you want to stop a set of threads, put them in one executor and `shutdownNow()` it.
- Always **name threads**. This is the one cheap habit here that pays off.

## 7. Where this shows up in Spring Boot

Embedded Tomcat handles each request on a pool thread. You tune it in `application.properties`:

|Property|Default|Meaning|
|---|---|---|
|`server.tomcat.threads.max`|200|Maximum request threads|
|`server.tomcat.threads.min-spare`|10|Threads kept ready|
|`server.tomcat.accept-count`|100|Connections queued when all threads are busy|

If all 200 threads are blocked on slow database calls, new requests queue and then get refused. That is the exact problem from your thread-creation lesson, and the reason virtual threads exist. In Spring Boot 3.2+, `spring.threads.virtual.enabled=true` switches request handling to them.

## Related concepts in one line each

- **`CompletableFuture`:** async tasks with exception handling built in (`exceptionally`, `handle`), so failures don't vanish like in section 4.
- **`ScheduledExecutorService`:** periodic tasks in a pool, instead of `sleep` loops.
- **`ThreadPoolExecutor`:** the class behind `Executors`, which lets you set queue size and a rejection policy directly.

## What to carry into real code

1. In a `Runnable`, restore the flag and stop. In a method that can throw, propagate. Never leave the `catch` empty.
2. Interrupts are requests. Tasks must check the flag or call interruptible methods, and blocked `synchronized` or classic socket reads need other fixes.
3. Shut pools down in three steps: `shutdown()`, `awaitTermination()`, then `shutdownNow()`.
4. Give pools a `ThreadFactory` with real names and a handler.
5. `submit()` swallows exceptions into the `Future`. Use `execute()` or call `get()`.
6. Pool threads are non-daemon, so always shut the pool down.
7. Ignore priorities and `ThreadGroup`.



[[Threads]]