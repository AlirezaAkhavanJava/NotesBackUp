
"Type of thread" can mean different things, because a thread can be classified from three angles. **How is it built?** (who owns and schedules it), **how does the JVM treat it when the program ends?** (daemon or not), and **what job does it do?** (your code, the JVM's housekeeping, a pool worker). A single thread has an answer for each angle. For example, a Tomcat request thread is a platform thread, a non-daemon thread, and a pool worker.

This lesson goes through the three angles in that order. It builds on your concurrency lesson (OS threads and cores), your `Thread` class lesson (daemon flag), your thread-creation lesson (pools and virtual threads) and your thread-management lesson (`ThreadFactory`).

## 1. By implementation: kernel threads and user threads

This is the operating-system view.

- A **kernel thread** is created and scheduled by the OS. The kernel knows it exists, gives it CPU time, and can run it on any core.
- A **user thread** is managed by a library or runtime inside your process. The kernel doesn't know it exists. It only sees the kernel thread(s) the runtime runs it on.

User threads have to be mapped onto kernel threads somehow. There are three classic models:

|Model|Mapping|Consequence|Example|
|---|---|---|---|
|Many-to-one|many user threads on **1** kernel thread|cheap, but one blocking call blocks all, and no use of multiple cores|old JVM "green threads"|
|One-to-one|each user thread on its **own** kernel thread|true parallelism, but each thread is costly|Java platform threads, Linux `pthread`|
|Many-to-many|many user threads on a **few** kernel threads|cheap and parallel|Java virtual threads, Go goroutines|

The 1:1 wrapper from your last question is the middle row. The next section shows the Java names for the middle and bottom rows.

## 2. In Java: platform threads and virtual threads

A **platform thread** is the ordinary Java thread, one-to-one with an OS thread. A **virtual thread** (Java 21+) is a thread managed by the JVM that is **not** tied to its own OS thread. The JVM runs many virtual threads on a small set of platform threads called **carrier threads**. When a virtual thread blocks (sleeping, waiting on I/O), the JVM unmounts it from its carrier, and the carrier runs another virtual thread.

Create each kind and look at them:

```java
public static void main(String[] args) throws InterruptedException {
    Runnable task = () -> System.out.println(Thread.currentThread());

    Thread platform = Thread.ofPlatform().name("plat-1").start(task);
    Thread virtual  = Thread.ofVirtual().name("virt-1").start(task);

    platform.join();
    virtual.join();
    System.out.println(platform.isVirtual() + " " + virtual.isVirtual());   // false true
}
```

Output (ids will differ):

```
Thread[#21,plat-1,5,main]
VirtualThread[#22,virt-1]/runnable@ForkJoinPool-1-worker-1
false true
```

The second line shows the whole design: the virtual thread is `runnable` _on_ `ForkJoinPool-1-worker-1`, which is a carrier, an ordinary platform thread.

||Platform thread|Virtual thread|
|---|---|---|
|Backed by|its own OS thread (1:1)|any carrier, many per carrier (M:N)|
|Stack|about 1 MB reserved up front|small, lives on the heap, grows and shrinks|
|Creation cost|a system call|an ordinary object allocation|
|Scheduled by|the OS|the JVM|
|Realistic count|thousands|millions|
|Daemon|your choice|always daemon|
|Priority|1 to 10 (a hint)|always 5. Changes are ignored|
|Pool them?|yes|no, one per task|
|Best for|CPU-bound work, long-lived workers|many tasks that mostly wait on I/O|

Virtual threads don't speed up CPU-bound work, because you are still limited by the number of cores. Their win is that waiting costs almost nothing.

## 3. By JVM exit behavior: user threads and daemon threads

The JVM stays alive while at least one **user (non-daemon)** thread is running. **Daemon** threads don't count: when the last user thread ends, the JVM exits and stops daemon threads abruptly.

```java
Thread t = new Thread(task);
t.setDaemon(true);   // must come before start()
t.start();
```

Facts to remember:

- A new thread **inherits** the daemon flag from the thread that creates it. `main` is a user thread, so threads you create are user threads by default.
- Pool threads are user threads, so a forgotten `shutdown()` keeps the JVM alive.
- Virtual threads are always daemon. If `main` ends first, they are cut off, so wait for them with `join()` or an executor.
- Never use daemon threads for work that must finish.

## 3. By job: who created the thread and why

Your program has more threads than the ones you wrote. This is the practical angle, because you meet it when reading logs and thread dumps. Run this to see what a plain program already has:

```java
Thread.getAllStackTraces().keySet().forEach(t ->
        System.out.println(t.getName() + "  daemon=" + t.isDaemon()));
```

|Thread name pattern|Created by|Notes|
|---|---|---|
|`main`|the JVM, to run `main()`|user thread|
|`Reference Handler`, `Finalizer`, `Common-Cleaner`, `Signal Dispatcher`|the JDK, for housekeeping|daemon, internal|
|`Thread-0`, `Thread-1`|you, with no name given|name them|
|`pool-1-thread-1`|`Executors` default factory|your pool workers|
|`ForkJoinPool.commonPool-worker-1`|the common pool|used by parallel streams and `CompletableFuture`|
|`ForkJoinPool-1-worker-1`|the virtual thread scheduler|carrier threads|
|`http-nio-8080-exec-1`|embedded Tomcat|one per active request|

The garbage collector and JIT compiler also run on threads, but those are **native JVM threads**. They don't show in the list above. They appear only in a full thread dump (`jcmd <pid> Thread.print`).

The habit this gives you: read the thread name in a log line or dump first. It tells you immediately which part of the system is running that code.

## Related concepts in one line each

- **Green threads:** the old JVM's many-to-one user threads, long removed. Virtual threads solve the same goal in a different way (many-to-many, with real parallelism).
- **Coroutines / goroutines:** the same idea as virtual threads in Kotlin and Go.
- **Hardware threads:** the logical CPUs the OS sees (SMT, "Hyper-Threading"). That is where `availableProcessors()` gets its number, and it is separate from software threads.

## What to carry into real code

1. A thread has three independent properties: implementation (platform or virtual), exit behavior (user or daemon), and job (yours, JVM's, pool's).
2. Platform means one OS thread each, so pool them. Virtual means one cheap thread per task.
3. Daemon is inherited, virtual threads are always daemon, and pool threads are not.
4. Thread names are your first debugging tool. Name your own threads.


[[Threads]]