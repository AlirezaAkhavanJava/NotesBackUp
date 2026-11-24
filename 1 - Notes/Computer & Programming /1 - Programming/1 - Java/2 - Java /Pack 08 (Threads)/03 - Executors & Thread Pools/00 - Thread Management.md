


You already know interruption, the daemon flag, and uncaught-exception handlers from your `Thread` class and control-methods lessons — all of that was shown on individual `Thread` objects. In real code, though, you rarely create `Thread` objects by hand. You work through a **pool**, and this lesson is specifically about what changes once your threads live inside one: how you ask a pool thread to stop, how you name and configure threads you never directly construct, and a couple of pool-specific traps that catch people off guard.

### Interruption: what the basics didn't cover

You know `interrupt()` sets a flag and that blocking calls throw `InterruptedException` while clearing it. Three extra things matter once you're writing real interruption-handling code:

An interrupt that arrives _before_ the thread reaches a blocking call isn't lost — if the flag is already set when the thread hits `sleep()`, it throws immediately rather than sleeping first.

What you should do with a caught `InterruptedException` depends on where you are:

|Your situation|What to do|
|---|---|
|Your method can declare `throws InterruptedException`|Don't catch it — let it propagate|
|You're inside a `Runnable` (can't throw checked exceptions)|Restore the flag and stop work|
|You need to release resources first|Clean up in `finally`, then restore the flag|

```java
String next(BlockingQueue<String> queue) throws InterruptedException {
    return queue.take(); // propagate — let the caller decide what interruption means here
}
```

And not everything responds to `interrupt()` at all. A thread waiting to enter a `synchronized` block, or blocked reading from a classic `java.io` socket, ignores it completely — only the flag gets set, nothing wakes up. To stop a thread stuck there, you close the resource it's blocked on instead. NIO channels are the one exception: interrupting a thread blocked on an NIO channel actually closes the channel.

### Stopping threads you don't hold a reference to

A pool owns its `Thread` objects, not you — so you can't call `.interrupt()` directly. Instead you have:

- `future.cancel(true)` — interrupts the one thread running that specific task
- `pool.shutdownNow()` — interrupts _every_ running task and hands back the ones that never started

Both are requests, not guarantees — the task still has to be written to notice the interrupt (as above). The standard way to shut a pool down cleanly is three steps: ask nicely, wait, then force it:

```java
static void stop(ExecutorService pool) throws InterruptedException {
    pool.shutdown();                                      // no new tasks; let queued ones finish
    if (!pool.awaitTermination(10, TimeUnit.SECONDS)) {
        pool.shutdownNow();                                // too slow — interrupt everything
        if (!pool.awaitTermination(5, TimeUnit.SECONDS)) {
            System.err.println("Pool did not terminate");  // some task is ignoring interrupts
        }
    }
}
```

Calling `shutdownNow()` straight away would kill work that was seconds from finishing — hence the wait first. Since Java 19, `ExecutorService` implements `AutoCloseable`, so `close()` does the `shutdown()` + wait for you inside a try-with-resources.

### Naming and configuring threads a pool creates: `ThreadFactory`

Since the pool builds its own threads, you can't call `setName()` on them after the fact. Instead you hand the pool a **`ThreadFactory`** — a one-method interface the pool calls every time it needs a new thread:

```java
AtomicInteger counter = new AtomicInteger(1);

ThreadFactory factory = r -> {
    Thread t = new Thread(r, "worker-" + counter.getAndIncrement());
    t.setUncaughtExceptionHandler((th, ex) -> System.err.println(th.getName() + " failed: " + ex));
    return t;
};

ExecutorService pool = Executors.newFixedThreadPool(2, factory);
```

This matters more than it sounds like: thread names show up in logs and in thread dumps (`jstack <pid>`), and `pool-1-thread-3` tells you nothing when a production app is hanging at 3am. On Java 21, the same thing can be built with `Thread.ofPlatform().name("worker-", 1).factory()`.

### The trap: `execute()` vs `submit()` swallow exceptions differently

This is the one that genuinely surprises people. An uncaught-exception handler set via a `ThreadFactory` **only fires for tasks run with `execute()`**:

```java
pool.execute(() -> { throw new IllegalStateException("A"); });
// handler runs, "A" gets logged

Future<?> f = pool.submit(() -> { throw new IllegalStateException("B"); });
// nothing is printed — the exception is stored inside the Future instead
try {
    f.get();
} catch (ExecutionException e) {
    System.err.println("Task failed: " + e.getCause()); // "B" only shows up here
}
```

`submit()` wraps your task in a `FutureTask`, which catches every exception and holds onto it rather than letting it propagate. If you never call `.get()` on that future, the failure disappears with no trace at all. For fire-and-forget work, either use `execute()`, or catch exceptions yourself inside the task.

### Daemon pool threads

Pool threads are **non-daemon** by default, which means a forgotten `shutdown()` keeps your whole program running indefinitely — an easy mistake since nothing errors, the process just never exits. You can make pool threads daemon through the `ThreadFactory` (`t.setDaemon(true)`), but then tasks can get cut off mid-execution if `main` ends first. Only do this for work you can genuinely afford to lose, like metrics collection — never for anything that must run to completion.

### What to ignore

`setPriority()` is a hint the OS is free to ignore — don't design around it. `ThreadGroup` is a legacy grouping mechanism whose `activeCount()` is only an estimate; pools have replaced its actual use case. If you want to stop a related set of threads, put them in one executor and `shutdownNow()` it.

### Where this shows up in Spring Boot

Embedded Tomcat handles each incoming request on a pool thread, tunable in `application.properties`:

|Property|Default|Meaning|
|---|---|---|
|`server.tomcat.threads.max`|200|Maximum request threads|
|`server.tomcat.threads.min-spare`|10|Threads kept ready and idle|
|`server.tomcat.accept-count`|100|Connections queued once all threads are busy|

If all 200 threads end up blocked on slow database calls, new requests queue up and eventually get refused outright — this is exactly why virtual threads exist. In Spring Boot 3.2+, setting `spring.threads.virtual.enabled=true` switches request handling over to them.


[[Threads]]