




A **core** is an independent execution unit on a CPU chip. Each core runs one instruction stream at a time, separately from the others. Four cores can run four threads at the same instant, which is the hardware basis for parallelism.

```java
int cores = Runtime.getRuntime().availableProcessors();
```

This asks the JVM how many logical processors the OS exposes. On a CPU with hyper-threading (SMT), one physical core can appear as two logical processors, so this number can be double the physical core count. Hyper-threaded logical processors share one core's execution units, so they don't give you full parallelism.

![[66ea8029-9b6c-4b0f-8d7e-4bfdf086cbbd.png]]
## Two meanings of "thread"

The word "thread" has two related meanings:

|Term|Meaning|
|---|---|
|**OS thread**|The OS's unit of scheduling: an instruction sequence that the scheduler places on a core|
|**Java `Thread`**|A Java object that, traditionally, is backed by one OS thread|

Historically, `new Thread().start()` asked the OS for one real thread, a strict one-to-one mapping. OS threads consume real kernel resources, which is why creating thousands of them is expensive. Virtual threads (Java 21+) break this mapping: many virtual threads share a small pool of OS threads.

## The scheduler and time slicing

A typical machine has far more runnable threads than cores, so most threads must wait their turn. The **CPU scheduler**, part of the OS kernel, decides which threads run on which cores and for how long.

Most schedulers use **time slicing**. Each runnable thread gets a short slice of CPU time, often a few milliseconds, then the scheduler pauses it and runs the next one:

```js
Core 1 with 3 threads competing:

[ T1 ][ T2 ][ T3 ][ T1 ][ T2 ][ T3 ][ T1 ] ...
```

Each slice is so short that all three threads appear to run at once, even though the core runs only one at any instant. This is how a single core supports concurrency.

**Preemptive** scheduling, used by Linux, Windows, and macOS, lets the OS pause a running thread at any time, whether or not it's ready to stop. The older **cooperative** model required a thread to give up the CPU voluntarily, so one misbehaving task could freeze the system. Preemption is why one runaway thread can't monopolize a core.

Java can hint at priority with `thread.setPriority(Thread.MAX_PRIORITY)`, but the OS makes the final decision, and many systems ignore the hint.

## Context switches cost time

Each switch between threads is a **context switch**. The scheduler saves the paused thread's state (register values, program counter, and stack pointer, which record where it was) and loads the next thread's saved state. This work produces no application progress, so it's overhead.

Context switches explain two practical rules:

- Too many threads for too few cores wastes time on switching, which is why thread pools are sized near the core count for CPU-bound work.
- A switch can happen between any two machine instructions. `count++` is really read, add, and write, so another thread can run between those steps. That's the root of race conditions.

## Blocked threads don't use the CPU

A thread waiting for I/O, a `sleep`, or a lock is **blocked** and doesn't compete for CPU time. The scheduler gives its core to other runnable threads until the wait ends. This is why concurrency helps even on one core: a thread waiting on a slow database query costs nothing while it waits.

This is also the mechanism virtual threads use. When a virtual thread blocks, the JVM unmounts it from its carrier OS thread, so that OS thread can run other virtual threads rather than sit idle.

## The full path from code to core

```text
Your code:        new Thread(task).start()
        |
JVM:              creates an OS thread (or a virtual thread on a carrier)
        |
OS:               the thread becomes runnable and joins the scheduler's pool
        |
Scheduler:        picks a core and a time slice, context-switching as needed
        |
Core:             executes the thread's instructions during its slice
```

## How this connects to what you've learned

- **Concurrency** works on one core because of time slicing.
- **Parallelism** needs multiple cores, since only separate cores run instructions at the same instant.
- **Race conditions** happen because a context switch can land in the middle of an operation like `count++`.
- **Thread pools** limit the number of threads, which limits switching overhead.
- **Virtual threads** avoid tying up OS threads while they wait, leaving the real scheduler to handle only threads that have work to do.

[[Threads]]
