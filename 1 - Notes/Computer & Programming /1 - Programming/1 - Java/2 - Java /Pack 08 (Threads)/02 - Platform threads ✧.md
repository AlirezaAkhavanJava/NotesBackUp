

A **platform thread** is the normal kind of Java thread, created with `new Thread(...)`. Java doesn't run it by itself. It asks the operating system for a real thread and uses that. The paragraph was dense because it packs four separate ideas into three sentences. We'll take them one at a time.

## 1. "A 1:1 wrapper around an OS thread"

Each Java `Thread` object is connected to exactly one thread in the operating system's kernel.

```
Thread object (Java heap)  <--1:1-->  OS thread (kernel)  -->  its own stack
```

- The `Thread` object is the Java-side handle (your `Thread` class lesson).
- The OS thread is the real thing that runs on a CPU core.
- The OS scheduler decides which thread runs next, and Java has no say in it.

"1:1" means one Java thread to one OS thread, never shared. This is the key difference from virtual threads, where many Java threads share a few OS threads.

## 2. "It reserves a stack (typically around 1 MB)"

Every thread needs its **own call stack**. The stack holds the local variables and the chain of method calls the thread is currently inside. Two threads can't share one, because they are in different methods at the same moment.

On a 64-bit JVM the default stack size is about 1 MB. You can change it:

```bash
java -Xss512k -jar app.jar     # 512 KB stack per thread
```

Be precise about "reserves": the JVM reserves that **address space** up front, but the OS hands out real RAM only as the stack grows. So 10,000 threads do not always use 10 GB of RAM. They _reserve_ about 10 GB of address space and use real memory in proportion to how deep their calls go, plus kernel bookkeeping per thread. A smaller `-Xss` lets more threads fit, but a deep recursion then throws `StackOverflowError` sooner.

## 3. "Costs a system call to create"

`start()` is not a cheap object allocation. The JVM must ask the kernel to create a thread (on Linux, through `pthread_create`, which ends in a `clone` system call). The kernel then allocates its internal thread structures and maps the stack. That takes on the order of tens of microseconds.

One thread: unnoticeable. 10,000 short tasks, each with its own new thread: the creation cost can be larger than the task itself.

## 4. "Heavy context switching"

Your machine has maybe 8 cores. If 10,000 threads want to run, the OS has to rotate them on and off those cores. Each **context switch**:

1. saves the running thread's CPU registers,
2. loads the next thread's registers and stack,
3. leaves the CPU caches full of the _previous_ thread's data (your hardware lesson on caches), so the next thread starts slow.

Time spent switching is time not spent running your code. More runnable threads than cores means more switching and less real work.

One accuracy note: threads that are sleeping or blocked cost memory but not switching, because the scheduler skips them. Heavy switching comes from many threads that are _runnable at once_.

## Seeing it yourself

```java
for (int i = 0; i < 10_000; i++) {
    new Thread(() -> doWork()).start();      // 10,000 OS threads
}
```

```java
ExecutorService pool = Executors.newFixedThreadPool(8);
for (int i = 0; i < 10_000; i++) {
    pool.submit(() -> doWork());             // 8 threads, 10,000 tasks
}
pool.shutdown();
```

The second version creates 8 threads once and reuses them. If you push the first version far enough with sleeping threads, Java eventually fails with `java.lang.OutOfMemoryError: unable to create native thread`. On Debian you can watch the thread count of a running process with `ps -o nlwp= -p <pid>`, and `ulimit -u` shows the per-user thread limit.

## The paragraph again, in plain terms

Every `new Thread(...).start()` makes the operating system build a real thread. That costs time (a system call), memory (a reserved stack of about 1 MB), and scheduler work (switching among all runnable threads). Creating thousands of them means paying all three costs thousands of times. That is why you reuse a small number of threads (a pool), or use virtual threads, which don't have a 1:1 OS thread behind them.



[[Threads]]