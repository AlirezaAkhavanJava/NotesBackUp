

A **thread** is an independent path of execution inside your program. Every Java program starts with one (`main`), and you can start more so that several pieces of code are in progress at the same time. Java gives you several ways to do that. They differ in two things: **who manages the threads** (you, a pool, or the JVM) and **what you get back** (nothing, or a result).

Everything rests on one separation: the **task** (the code to run) and the **thread** (the worker that runs it). You write the task, then choose how to run it. This builds on your concurrency vs parallelism lesson (tasks in progress vs tasks truly simultaneous on multiple cores) and your `Thread` class lesson (constructors, methods, lifecycle).

## 1. Task and thread: `Runnable` and `Thread`

`Runnable` is the task. It has one method, `void run()`, so a lambda works:

```java
Runnable task = () -> System.out.println("Running on " + Thread.currentThread().getName());

Thread t = new Thread(task, "worker-1");
t.start();   // new thread begins executing task.run()
t.join();    // main waits here until worker-1 finishes
```

You can also extend `Thread` and override `run()`, which fuses the task and the thread into one class:

```java
class MyThread extends Thread {
    @Override public void run() { System.out.println("Hi from " + getName()); }
}
new MyThread().start();
```

**Prefer `Runnable`.** A `Runnable` can run on a plain thread, a pool, or a virtual thread. A class that extends `Thread` can only be run as its own thread, so you can't hand it to a pool. The commonly quoted reason, "Java has single inheritance", is the weaker one.

---
### `start()` vs `run()`

```java
t.run();    // BUG: runs on the CURRENT thread. No new thread exists.
t.start();  // creates the thread, which then calls run()
```

`start()` can only be called once per `Thread` object. A second call throws `IllegalThreadStateException`.

### Shared state

If you pass one `Runnable` object to two threads, both threads execute that same object. Local variables are safe because each thread has its own stack. **Fields are shared.** If both threads modify a field, you have a race condition. The old note's example worked only because `i` was a local variable. Making shared state safe is a separate topic (synchronization, atomics).


A Platform Thread is the thread abstraction provided by the Java Virtual Machine (JVM), representing a traditional thread of execution that is typically backed by an actual OS Thread. An OS Thread (Operating System Thread) is a thread managed and scheduled by the operating system's kernel, which allocates CPU time to it, manages its execution state, and handles context switching. When you create a Java platform thread using `new Thread()`, the JVM generally maps it one-to-one to an OS thread, meaning each Java platform thread has its own corresponding OS thread. The JVM provides the Java-level API for creating, starting, and controlling the thread, while the operating system is responsible for actually scheduling it on CPU cores and executing its instructions.

---

## 2. Why raw threads don't scale: thread pools

A platform thread is a 1:1 wrapper around an OS thread. It reserves a stack (typically around 1 MB, configurable with `-Xss`) and costs a system call to create. Run `new Thread(...)` for 10,000 tasks and you get high memory use and heavy context switching.

A **thread pool** fixes this. A small, fixed set of worker threads pulls tasks from a queue and reuses itself. `ExecutorService` is the interface, and `Executors` has factory methods:

```java
ExecutorService pool = Executors.newFixedThreadPool(4);

for (int i = 1; i <= 8; i++) {
    int id = i;
    pool.submit(() -> System.out.println("Task " + id + " on " + Thread.currentThread().getName()));
}

pool.shutdown();
```

You'll see 8 tasks but only 4 thread names (`pool-1-thread-1` to `pool-1-thread-4`). The other tasks waited in the queue.

|Pool|Threads|Queue|Watch out for|
|---|---|---|---|
|`newFixedThreadPool(n)`|exactly n, kept alive|unbounded `LinkedBlockingQueue`|an overloaded app silently piles up tasks in memory|
|`newSingleThreadExecutor()`|1|unbounded `LinkedBlockingQueue`|tasks run strictly in order|
|`newCachedThreadPool()`|grows as needed, idle ones die after 60s|`SynchronousQueue` (no storage; hands the task straight to a free thread, or creates a new thread)|a flood of tasks creates a flood of threads|

### Shutting down

- `shutdown()` stops accepting new tasks and lets queued ones finish.
- `awaitTermination(timeout, unit)` blocks until everything is done.
- `shutdownNow()` interrupts running tasks and discards the queue.

Pool threads are non-daemon, so **if you never call `shutdown()`, your program never exits.**


### Pool size

For **CPU-bound** work, use about the number of cores (`Runtime.getRuntime().availableProcessors()`). More threads than cores only adds switching. For **blocking** work (database, network), you need more, because most threads are idle waiting. That problem is what virtual threads (section 5) solve.

---
## 3. Getting a result: `Callable` and `Future`

`Runnable` returns nothing and cannot throw checked exceptions. `Callable<V>` returns a `V` and may throw. Submitting one gives you a `Future<V>`, which is a handle to a result that doesn't exist yet:

```java
ExecutorService pool = Executors.newFixedThreadPool(2);

Callable<Integer> sum = () -> {
    int s = 0;
    for (int i = 1; i <= 5; i++) s += i;
    return s;
};

Future<Integer> future = pool.submit(sum);   // returns immediately
// ...main can do other work here...
int result = future.get();                   // blocks until the task finishes

pool.shutdown();
```

What `Future` gives you:

- `get()` blocks until done. `get(timeout, unit)` gives up after a limit.
- `isDone()` checks without blocking. `cancel(true)` tries to stop the task.
- If the task threw, `get()` throws `ExecutionException`, and the real exception is `e.getCause()`.

Calling `get()` right after `submit()` gives you no concurrency, because you just wait. Submit several tasks first, then collect the results.

For chaining steps without blocking, there is `CompletableFuture`, which deserves its own lesson.

---
## 4. Splitting one big job: Fork/Join

This one has a different goal. It is **parallelism**: one large CPU-bound job is split recursively into pieces that run on multiple cores. You write a `RecursiveTask<T>` (returns a result) or `RecursiveAction` (returns nothing):

```java
class SumTask extends RecursiveTask<Long> {
    private static final int THRESHOLD = 1_000;
    private final int[] data;
    private final int start, end;

    SumTask(int[] data, int start, int end) {
        this.data = data; this.start = start; this.end = end;
    }

    @Override
    protected Long compute() {
        if (end - start <= THRESHOLD) {          // small enough: just do it
            long sum = 0;
            for (int i = start; i < end; i++) sum += data[i];
            return sum;
        }
        int mid = (start + end) / 2;
        SumTask left  = new SumTask(data, start, mid);
        SumTask right = new SumTask(data, mid, end);
        left.fork();                              // schedule left on another worker
        return right.compute() + left.join();     // do right ourselves, then wait for left
    }
}

long total = ForkJoinPool.commonPool().invoke(new SumTask(data, 0, data.length));
```

How it works:

- `compute()` either solves a small piece directly or splits it in two.
- `fork()` queues a subtask. `join()` waits for its result.
- We compute one half ourselves instead of forking both, so the current thread does useful work instead of just waiting.
- **Work stealing**: an idle worker takes tasks from a busy worker's queue, which keeps all cores busy.
- The threshold matters. Too small and splitting costs more than the work. Thousands of elements is a reasonable start.
- Don't call `shutdown()` on the common pool. It has no effect.

**Use it only for CPU-bound work.** If subtasks block on I/O, workers sit idle and your cores are wasted. Parallel streams (`list.parallelStream()`) run on this same common pool.

## 5. Cheap threads for waiting: virtual threads (Java 21+)

Section 2 ended with a problem: tasks that mostly wait on I/O each tie up an expensive OS thread. A **virtual thread** is a thread managed by the JVM instead of the OS. It costs a few KB, its stack lives on the heap, and the JVM runs it on a small pool of real "carrier" threads. When a virtual thread hits a blocking call, the JVM unmounts it and the carrier runs another one. You write plain blocking code and still scale to very large numbers of concurrent tasks.

```java
import java.util.concurrent.Executors;

try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < 10_000; i++) {
        executor.submit(() -> {
            Thread.sleep(1000);   // blocking is fine here
            return null;
        });
    }
}   // close() waits for all tasks (Java 19+)
```

Without the executor, use `Thread.startVirtualThread(task)` or `Thread.ofVirtual().start(task)`.

Rules:

- **One virtual thread per task. Never pool them.** They are cheap on purpose.
- They don't speed up CPU-bound work. You are still limited by the number of cores.
- In Java 21, blocking inside a `synchronized` block pins the carrier thread and loses the benefit. This was fixed in Java 24.
- In Spring Boot 3.2+, `spring.threads.virtual.enabled=true` makes request handling use virtual threads.

## Which one do you use?

|Situation|Use|
|---|---|
|Learning, or a single quick background task|`Thread` + `Runnable`|
|Many tasks, CPU-bound, no result needed|Fixed thread pool, sized to cores|
|Many tasks, you need results or exceptions back|`Callable` + `Future`|
|One big divide-and-conquer computation|Fork/Join|
|Many tasks that mostly wait on I/O (Java 21+)|Virtual threads|



[[Threads]]