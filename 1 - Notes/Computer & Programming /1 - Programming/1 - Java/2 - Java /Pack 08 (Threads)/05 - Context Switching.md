


When you write `new Thread(...).start()`, Java hands the thread to the operating system. What actually happens next is a hardware story with three parts. **Context switching** is how one core runs many threads in turn. **Cache coherence** is how many cores see the same memory. **Hyperthreading** is how one core squeezes in a second thread. Together they explain why 10,000 threads are expensive, why shared variables are slow, and why some Java code gives wrong answers.

This builds on your concurrency vs parallelism lesson (cores, caches), your thread lifecycle lesson (`RUNNABLE`, `WAITING`...) and the platform-thread cost question. Here we go inside the hardware.

## 1. Context switching

A **context switch** is when the OS stops running thread A on a core and starts running thread B on that same core.

A thread's **context** is its CPU state: the program counter (which instruction is next), the stack pointer, the general-purpose registers and the flags. The switch does this:

1. Save A's registers into a kernel structure in memory.
2. Load B's registers from its structure.
3. Resume B exactly where it stopped.

Notice what is _not_ copied: stacks and variables. A's local variables sit in A's stack memory, untouched. B's stack pointer just starts pointing at B's stack.

### Two kinds of switch

|Kind|Cause|Java thread states involved|
|---|---|---|
|**Voluntary**|The thread can't continue and gives up the core|`sleep`, `join`, `wait`, lock waits, blocking I/O|
|**Involuntary**|The OS takes the core away (time slice used up, or a higher-priority thread is ready)|a `RUNNABLE` thread when there are more runnable threads than cores|

### The real cost

The register save and load takes a few microseconds. The bigger cost is **indirect**: thread B's data is not in the core's L1/L2 caches (they hold A's data), so B starts slowly with cache misses until its working set is loaded. Switching between threads of the same process is cheaper than between processes, because the memory mapping stays the same.

### See it on your machine

Run this, which creates 4× more busy threads than you have logical cores:

```java
public class Spin {
    public static void main(String[] args) {
        int n = Runtime.getRuntime().availableProcessors() * 4;
        for (int i = 0; i < n; i++) {
            new Thread(() -> { long x = 0; while (true) x++; }, "spin-" + i).start();
        }
    }
}
```

In another terminal:

```bash
vmstat 1                          # the "cs" column = context switches per second, system-wide
pidstat -wt -p <pid> 1            # per thread (install with: sudo apt install sysstat)
```

In `pidstat`, `cswch/s` is voluntary and `nvcswch/s` is involuntary. The spinning threads show high **involuntary** counts: they never block, so the OS keeps forcibly rotating them. Replace the loop body with `Thread.sleep(10)` and you'll see **voluntary** switches instead.

## 2. Many threads, few cores

Each core runs **exactly one thread at a time**, whether it's 4 cores or 32. Each core has its own **run queue** of threads waiting for it. When a time slice ends, the OS picks the next thread from that queue.

So how can a machine have thousands of threads? Because only some of them are in a run queue:

|Thread state|On a core?|In a run queue?|CPU cost|
|---|---|---|---|
|Running|yes|no|the core itself|
|`RUNNABLE`, waiting for a core|no|yes|causes switching|
|`BLOCKED` / `WAITING` / `TIMED_WAITING`|no|**no**|memory only|

A 32-core machine runs 32 threads at the same instant. Thousands of threads work only when most are waiting. If thousands are `RUNNABLE` at once, you get the heavy switching from your earlier question.

## 3. Many cores, one memory: caches and coherence

Each core has fast private caches, and all cores share the bigger, slower ones. Typical layout, with rough latencies:

|Level|Scope|Rough latency|
|---|---|---|
|L1|private per core|about 1 ns|
|L2|usually private per core|about 3 to 4 ns|
|L3|shared by cores (on one chip or chiplet)|about 10 to 20 ns|
|RAM|everyone|about 60 to 100 ns|

Caches store memory in **cache lines** (64 bytes). Here is the problem: the same line can sit in several cores' L1 caches. If core A writes to it, core B's copy is now stale. The **coherence protocol** (MESI and variants) prevents that. Each cached line is `Modified`, `Exclusive`, `Shared` or `Invalid`. When A writes a line, every other core's copy is marked **Invalid**. When B next reads it, it must fetch the fresh line from A's cache or from L3.

That fetch is the "inter-core communication" cost. It is automatic and invisible to your code, but it is slower than a normal cache hit. The practical rule: **data that many threads write is expensive; data that threads only read, or that each thread owns, is cheap.**

## 4. Coherent caches do not make Java code correct

The hardware keeps caches in agreement, so you might expect every thread to see every write immediately. It doesn't, for two reasons. The compiler may keep a variable in a register, and the CPU buffers and reorders writes. Classic bug:

```java
class Worker {
    private boolean stop = false;            // BUG

    void run() {
        while (!stop) { /* work */ }         // may loop forever: stop can be read once and cached
    }
    void requestStop() { stop = true; }
}
```

The fix is `private volatile boolean stop`. `volatile`, `synchronized`, locks, `start()` and `join()` all create **happens-before** guarantees that make one thread's writes visible to another. This is the Java Memory Model, and it is the core of your next lesson on synchronization.

Two more facts that clear up the old example:

- `count++` is three steps (read, add, write), not one. Two threads can read the same value and lose an update.
- A lock fixes that by giving **mutual exclusion plus visibility**. Locks themselves are built on atomic CPU instructions (compare-and-swap), and those rely on cache coherence to work.

## 5. Hyperthreading (SMT)

A **hyperthreaded** core presents itself as **two logical cores**. It duplicates the registers (each logical core has its own architectural state) but **shares** the execution units and the L1/L2 caches.

When one thread stalls, usually waiting on memory after a cache miss, the core executes instructions from the other thread in the same units. No OS context switch is involved, because the interleaving happens in hardware, cycle by cycle.

What that means in practice:

- A 4-core CPU with hyperthreading shows **8 logical CPUs**. The OS schedules 8 threads at once, but you don't get 8 cores of speed.
- The gain is **workload-dependent**, commonly between 0% and 30% for CPU-bound code. Code that already keeps the execution units busy gains almost nothing.
- It has nothing to do with I/O. A thread blocked on I/O is not runnable, so the question never arises.
- `Runtime.getRuntime().availableProcessors()` returns the **logical** count. A fixed pool for CPU-bound work sized to it can oversubscribe the physical cores, so measure.

Check yours with `lscpu`: look at `Thread(s) per core` (2 means hyperthreading) and `Core(s) per socket`.

## Related concepts in one line each

- **False sharing:** two threads write _different_ variables that happen to sit in the **same cache line**, so coherence bounces the line between cores and slows both.
- **Virtual thread switching:** the JVM switches virtual threads by swapping stack objects on a carrier, with no kernel involvement, which is why it is far cheaper than an OS context switch.
- **Thread affinity:** pinning a thread to a core (Linux `taskset`). Java has no built-in API for it.
- **NUMA:** on multi-socket machines, memory attached to another socket is slower to reach.

## What to carry into real code

1. A context switch saves registers, not stacks. Its real cost is the cold cache afterward.
2. Switching only happens for threads that want to run. Waiting threads are free in CPU terms.
3. Written-to shared data pays a coherence cost. Prefer data each thread owns.
4. Coherent hardware caches do not mean visible writes in Java. Use `volatile`, locks or atomics.
5. `availableProcessors()` counts logical cores, and hyperthreading helps memory-stalled code, not I/O.

[[Threads]]