

A thread is one path of execution inside a process, and it's the unit the OS schedules onto a CPU core. Every line of Java you write runs on some thread, and the `Thread` class is how you create threads and inspect them. This lesson covers what a thread keeps track of, what the `Thread` object actually is, the six states Java reports, and the difference between platform and virtual threads.

## What a thread keeps track of

When the OS pauses a thread mid-method and resumes it later, the thread must pick up exactly where it stopped. To make that possible, each thread keeps three things private:

- **Program counter:** the address of the next instruction to run.
- **CPU registers:** the values the CPU was working with.
- **Stack:** the chain of method calls, with each call's parameters and local variables.

A **context switch** is the OS saving these three for one thread and loading them for another.

The stack is the part you control directly. Each method call pushes a frame, and returning pops it. Local variables live in that frame, so another thread can't see them:

```java
void work(List<String> shared) {
    int local = 5;      // in this thread's stack; no other thread can see it
    shared.add("x");    // `shared` is a local reference, but the list lives on the heap
}
```

The reference `shared` is private to the thread, but the list it points to is a heap object. If another thread holds the same list, both threads are changing one object. Locals are private, but the objects they point to may not be.

Each thread's stack has a fixed size, about 1 MB by default, adjustable with `-Xss`. Unbounded recursion runs out of space:

```java
static void recurse() { recurse(); }

new Thread(() -> recurse(), "deep").start();
```

The thread named `deep` dies with a `StackOverflowError`, and the rest of the application keeps running.

## The `Thread` object is a handle

`new Thread(task)` creates an ordinary object on the heap. No thread exists yet. The OS-level thread begins only when you call `start()`, and it ends when its task finishes. The object lets you query and control that thread:

```java
Thread t = new Thread(() -> {
    try { Thread.sleep(500); }
    catch (InterruptedException e) { Thread.currentThread().interrupt(); }
});

System.out.println(t.getState());  // NEW: object exists, no thread yet
t.start();
Thread.sleep(100);
System.out.println(t.getState());  // TIMED_WAITING: sleeping inside the task
t.join();
System.out.println(t.getState());  // TERMINATED: the thread has finished
```

Two rules follow from this:

- A thread can be started only once. A second `start()` throws `IllegalThreadStateException`. To run the work again, create a new `Thread`.
- `Thread.currentThread()` returns the handle of the thread executing the current code. Printing its name inside a task shows which thread ran it.

## The six states

`getState()` returns one of these values:

|State|Meaning|
|---|---|
|`NEW`|Created, `start()` not yet called|
|`RUNNABLE`|Running, or ready and waiting for a core|
|`BLOCKED`|Waiting to enter a `synchronized` block that another thread holds|
|`WAITING`|Waiting with no deadline, for example in `join()` or `Object.wait()`|
|`TIMED_WAITING`|Waiting with a deadline, for example in `sleep` or `join(ms)`|
|`TERMINATED`|The task finished or threw an exception|

A thread normally goes `NEW → RUNNABLE`, moves between `RUNNABLE` and the waiting states as it works, and ends at `TERMINATED`. In a thread dump, these labels show what each thread is stuck on.

## Platform threads vs. virtual threads

**Platform threads** map one-to-one to OS threads. The OS creates and schedules them, and each reserves its own stack. They are expensive, so you can realistically run thousands, not millions.

```java
Thread.ofPlatform().name("worker-1").start(() ->
        System.out.println(Thread.currentThread()));
```

**Virtual threads** are managed by the JVM. Their stacks live on the heap, grow as needed, and cost very little. The JVM runs them on a small set of platform threads called **carriers**, usually one per core:

```text
Virtual threads:   v1   v2   v3   v4  ...  v100000
                    \   |    |   /
                 mounted on carriers, one at a time
                    /             \
Carriers:     [ carrier-1 ]   [ carrier-2 ]   (≈ one per core)
                    |               |
OS threads:      OS thread       OS thread
```

A virtual thread runs while **mounted** on a carrier. When it reaches a blocking operation such as `Thread.sleep`, a socket read, or waiting on a `java.util.concurrent` lock, the JVM saves its stack to the heap and **unmounts** it. The carrier then picks up another virtual thread. When the wait ends, the thread is mounted again, possibly on a different carrier. You write ordinary blocking code, and the JVM keeps it from tying up an OS thread while it waits.

Here's the effect in practice:

```java
import java.time.Duration;
import java.util.concurrent.Executors;
import java.util.stream.IntStream;

public class Many {
    public static void main(String[] args) {
        long start = System.currentTimeMillis();

        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            IntStream.range(0, 100_000).forEach(i ->
                executor.submit(() -> {
                    Thread.sleep(Duration.ofSeconds(1));
                    return i;
                }));
        }   // close() waits for every submitted task

        System.out.println("took " + (System.currentTimeMillis() - start) + " ms");
    }
}
```

`newVirtualThreadPerTaskExecutor()` starts a new virtual thread for each submitted task. Each one sleeps for a second, so 100,000 sleeping tasks finish in a few seconds. The `try` block closes the executor, and closing waits for all tasks to complete. Try the same with 100,000 platform threads and you will likely hit memory limits first.

Some rules for virtual threads:

- **Create one per task and don't pool them.** Pools exist to ration expensive resources, and virtual threads aren't expensive.
- **They always run as daemon threads.** If `main` returns while they're still running, the JVM exits. Join them or close the executor, as above.
- **They're unnamed by default.** `getName()` returns an empty string unless you set a name with `Thread.ofVirtual().name("...")`.
- **They help only when tasks wait.** CPU-bound work still needs cores, so a million virtual threads doing arithmetic are no faster than a few.
- **Shared-memory rules still apply.** Virtual threads share the heap like any other thread, so they need the same synchronization.

[[Threads]]