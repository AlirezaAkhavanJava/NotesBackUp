

A thread is one path of execution inside a process. It is the unit the OS schedules onto a CPU core. In Java, the code you write always runs on some thread, and the `Thread` class is how you create and inspect them.

This tutorial answers three questions: what a thread carries with it, how Java's `Thread` object relates to the real thing, and what the two kinds of Java threads (platform and virtual) are underneath. These are the foundation for executors, locks and virtual-thread tuning later.

---

## What a thread carries with it

Suppose the OS pauses a thread in the middle of a method and resumes it milliseconds later. For the thread to continue as if nothing happened, three things must be preserved:

- **Program counter**: the bookmark saying which instruction comes next.
- **CPU registers**: the values the CPU was in the middle of working with.
- **Stack**: the chain of method calls that led here, plus each call's local variables.

Those three things are the thread's private state. A context switch is the OS saving them for one thread and loading them for another.

The stack is the one you touch directly as a programmer. Every method call pushes a **frame** holding that call's parameters and locals, and returning pops it. Because each thread has its own stack, a local variable can't be seen by another thread. There is one subtlety:

```java
void work(List<String> shared) {
    int local = 5;          // lives in this thread's stack, truly private
    shared.add("x");        // `shared` is a private reference to a heap object
}
```

The reference variable `shared` is private to this thread, but the list it points to is on the heap. If another thread holds a reference to the same list, they are touching the same object. "Locals are safe" is true for primitives and for objects that never escape the method, not for everything a local points at.

Stacks are finite. The default is about 1 MB per thread and can be changed with `-Xss`. Infinite or very deep recursion exhausts it:

```java
static void recurse() { recurse(); }

new Thread(() -> recurse(), "deep").start();
```

This throws `StackOverflowError` inside the thread named `deep`. Only that thread dies, and the rest of the application keeps running.

---

## The `Thread` object is not the thread

`new Thread(...)` creates an ordinary Java object on the heap. No execution path exists yet. The real thread is created only when you call `start()`, and it ends when its task finishes. The object is a **handle** you use to ask questions about the thread or give it instructions.

```java
public static void main(String[] args) throws InterruptedException {
    Thread t = new Thread(() -> {
        try { Thread.sleep(500); }
        catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    });

    System.out.println(t.getState());   // NEW: object exists, no thread yet
    t.start();
    Thread.sleep(100);
    System.out.println(t.getState());   // TIMED_WAITING: sleeping inside the task
    t.join();
    System.out.println(t.getState());   // TERMINATED: the thread is gone
}
```

Two consequences:

- A thread can only be started once. Calling `t.start()` again after it has begun throws `IllegalThreadStateException`. To run the work again, create a new `Thread`.
- After termination, the `Thread` object still exists as a plain object you can inspect, but there is nothing behind it anymore.

To find out which thread is running your code right now, use `Thread.currentThread()`. It returns the handle of whichever thread called it, which is why printing `Thread.currentThread().getName()` inside a task tells you where it ran.

---

## The six states Java reports

`getState()` returns one of six values:

|State|Meaning|
|---|---|
|`NEW`|created, `start()` not yet called|
|`RUNNABLE`|running, or ready and waiting for a core|
|`BLOCKED`|waiting to enter a `synchronized` block another thread holds|
|`WAITING`|waiting indefinitely for another thread to do something (`join()`, `Object.wait()`, `LockSupport.park()`)|
|`TIMED_WAITING`|the same, but with a deadline (`sleep`, `join(ms)`, timed waits)|
|`TERMINATED`|the task finished or threw|

A thread normally moves forward through `NEW → RUNNABLE`, bounces between `RUNNABLE` and the waiting states while it works, and ends at `TERMINATED`. When you debug a hung application, these labels in a thread dump tell you what each thread is stuck on.

---

## Two kinds of Java threads

**Platform threads** are the traditional kind. Each one is backed 1:1 by an OS thread, which the OS creates, schedules and gives a stack. That makes them relatively expensive: each reserves stack space, and you realistically get thousands, not millions.

```java
Thread p = Thread.ofPlatform().name("worker-1").start(() ->
        System.out.println(Thread.currentThread()));
```

**Virtual threads** are Java objects managed by the JVM, not by the OS. Their stack is stored in ordinary heap memory and grows and shrinks as needed, so each one costs very little. The JVM runs them on a small pool of platform threads called **carriers** (by default, one per core):

```text
Virtual threads:   v1   v2   v3   v4  ...  v100000
                    \   |    |   /
                     mounted on, one at a time
                    /             \
Carriers:     [ carrier-1 ]   [ carrier-2 ]  ...   (≈ one per core)
                    |               |
OS threads:      OS thread        OS thread
```

The key mechanism is **mounting and unmounting**. A virtual thread runs by being mounted on a carrier. When it hits a blocking operation (`Thread.sleep`, a socket read, waiting for a `java.util.concurrent` lock), the JVM saves its stack to the heap and unmounts it, and the carrier immediately picks up another virtual thread. When the awaited event happens, the virtual thread is mounted again, possibly on a different carrier. Nothing in your code changes: you write plain blocking code and the JVM stops it from tying up an OS thread.

You can see the effect directly:

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
        }   // close() waits for all submitted tasks

        System.out.println("took " + (System.currentTimeMillis() - start) + " ms");
    }
}
```

That `executor` starts a new virtual thread for each submitted task, and closing it waits for all of them. 100,000 threads each sleep for a second, and the whole program finishes in a few seconds. With 100,000 platform threads you would likely hit memory or thread-limit errors long before that.

Print the current thread inside a virtual thread and you'll see the carrier in its description:

```java
Thread.ofVirtual().start(() -> System.out.println(Thread.currentThread())).join();
// VirtualThread[#21]/runnable@ForkJoinPool-1-worker-1
```

Some rules specific to virtual threads:

- **Create one per task and never pool them.** A pool exists to ration an expensive resource, and virtual threads aren't expensive.
- **They are always daemon threads.** If `main` returns while they are still running, the JVM exits and drops them. Join them, or close the executor, as above.
- **They have no name by default.** `getName()` returns an empty string unless you set one with `Thread.ofVirtual().name("...")`.
- **They only help when threads spend time waiting.** CPU-bound work still needs cores, so a million virtual threads computing in a loop are no faster than a handful.
- **Everything about shared memory still applies.** They share the heap with every other thread in the process, so they need the same care.




[[Threads]]