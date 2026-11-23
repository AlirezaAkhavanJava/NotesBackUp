
Threads aren't one single kind of thing — "thread" means something different **depending on which layer of the system you're looking at**. There are threads the operating system schedules directly, and there are threads the JVM manages on top of those. Understanding the layers clears up a lot of confusion you'll hit later with virtual threads, thread pools, and why some "threads" are nearly free while others cost real memory.

## Kernel threads vs user threads

A **kernel thread** is a thread the operating system's scheduler actually knows about and puts on a CPU core. Creating one costs real resources — the OS allocates a kernel data structure, a stack, and has to context-switch it in and out of the CPU.

A **user thread** is a thread that exists only in user-space (your application/runtime), with no direct OS visibility. Early threading libraries multiplexed many user threads onto very few kernel threads themselves, entirely in userspace.

Java's classic `Thread` class is a thin wrapper that maps **one Java thread to one OS kernel thread**, 1:1. This is called the platform thread model.

```java
Thread t = new Thread(() -> System.out.println("I am a kernel-backed thread"));
t.start();
```

Every `new Thread()` here reserves an OS thread, with its own OS-level stack (typically ~1MB by default). That's why you can't casually spin up 100,000 of them — you'd exhaust OS resources before you exhaust CPU.

## Platform threads vs virtual threads

This is the big distinction as of modern Java (and the one most relevant to you on JDK 25).

**Platform threads** are exactly what's described above: a thin wrapper around a kernel thread, [^1]1:1. Expensive to create, limited in number (thousands, not millions), scheduled by the OS.

**Virtual threads** (JEP 444, standard since Java 21) are JVM-managed, lightweight threads that are _not_ 1:1 with kernel threads. The JVM schedules many virtual threads onto a much smaller pool of platform threads.

```java
Thread vt = Thread.ofVirtual().start(() -> {
    System.out.println("I am a virtual thread");
});
vt.join();
```

You can create millions of these without exhausting memory, because a virtual thread's stack lives on the heap and grows/shrinks dynamically, instead of reserving a fixed OS stack upfront.

[^2]The key mechanism: when a virtual thread does a **blocking** operation (I/O, `Thread.sleep`, blocking on a lock), the JVM _unmounts_ it from its underlying platform thread and parks it, freeing that platform thread to run a different virtual thread. When the blocking operation completes, the virtual thread gets _mounted_ back onto some available platform thread to continue. This is why virtual threads are built for blocking, I/O-heavy workloads (like handling thousands of concurrent HTTP requests), not for CPU-bound number crunching — CPU-bound work still needs an actual core, virtual or not.

## Carrier threads

The platform thread that a virtual thread is currently mounted on is called its **carrier thread**. Carrier threads come from a special `ForkJoinPool` the JVM manages internally for virtual threads (sized to the number of CPU cores by default).

A subtlety worth knowing: a virtual thread is _not_ pinned to the same carrier thread across its lifetime. It can run on carrier thread A, get unmounted during a blocking call, and later get remounted on carrier thread B. One consequence of this: if you use `synchronized` blocks inside a virtual thread, the virtual thread can get **pinned** to its carrier (it can't unmount mid-block), which defeats the scalability benefit. That's why `java.util.concurrent.locks.ReentrantLock` is preferred over `synchronized` in virtual-thread-heavy code.

```java
// Pins the carrier thread while inside the block — avoid in virtual-thread code
synchronized (lock) {
    blockingCall();
}

// Doesn't pin — releases the carrier thread while blocked
lock.lock();
try {
    blockingCall();
} finally {
    lock.unlock();
}
```

## Daemon threads vs user (non-daemon) threads

This is a different axis entirely — it's not about how the thread is implemented, it's about how it affects JVM shutdown. A **user thread** (in this specific sense, meaning non-daemon) keeps the JVM alive as long as it's running. A **daemon thread** does not — the JVM will exit once all non-daemon threads finish, killing any daemon threads still running, mid-task if necessary.

```java
Thread background = new Thread(() -> { /* housekeeping work */ });
background.setDaemon(true); // JVM won't wait on this one to exit
```

Virtual threads are always daemon threads — you cannot make a virtual thread non-daemon. That's a deliberate design choice, since virtual threads are meant to be created in huge numbers and discarded freely, not tracked individually for shutdown purposes.

## JVM thread pool threads

Worth naming since you'll run into the term constantly: a **pool thread** isn't a separate kind of thread at the OS or JVM level — it's just a platform (or virtual) thread that's managed by an `ExecutorService` and reused across tasks instead of being created and destroyed per task. The "type" here is really about lifecycle management, not about anything structurally different in the thread itself.



[[Threads]]

[^1]: "1:1" means a one-to-one mapping — each Java `Thread` object corresponds to exactly one kernel thread in the OS. Create one Java thread, the OS creates and schedules one matching kernel thread behind it. No sharing, no multiplexing.
	
	That's what makes platform threads expensive: the ratio is always 1:1, so 10,000 platform threads means 10,000 real kernel threads competing for OS resources.
	
	Virtual threads break this ratio — it becomes many-to-few: potentially millions of virtual threads can map onto just a handful of actual kernel/platform threads (the carrier threads), since they take turns mounting onto them instead of each needing a dedicated one.



[^2]: **Mounted** means a virtual thread is currently running on top of a carrier (platform) thread — its code is actually executing on a real OS thread right now.
	
	**Unmounted** means the virtual thread has been detached from any carrier thread. It still exists (its state is saved on the heap), but it isn't occupying a platform thread at all — it's just waiting, consuming no carrier.
	
	The transition happens automatically when a virtual thread hits a blocking call:
	
	```java
	Thread.ofVirtual().start(() -> {
	    System.out.println("mounted — running on a carrier");
	    someBlockingIOCall();              // JVM unmounts here
	    System.out.println("mounted again — maybe a different carrier");
	});
	```
	
	At `someBlockingIOCall()`, the JVM detects the block, saves the virtual thread's state, and detaches it from its carrier. That carrier thread is now free and gets handed off to run some _other_ virtual thread. Once the blocking call finishes, the JVM finds an available carrier and mounts the virtual thread back onto it to resume execution — not necessarily the same carrier as before.
	
	So mount/unmount is just the act of attaching/detaching a virtual thread to/from a real platform thread, done by the JVM scheduler, not by you.
