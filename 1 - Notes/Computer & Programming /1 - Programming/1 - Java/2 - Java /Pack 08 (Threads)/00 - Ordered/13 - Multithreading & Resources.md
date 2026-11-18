

A **thread** is the smallest unit of execution within a process — one path of instructions executing independently. 
A **process** can contain multiple threads, and they all share that process's memory and resources, which is what lets them run concurrently without being separate programs. **Multithreading** is simply a process running more than one thread at once, so unrelated work (or work that can be split) progresses without each piece needing its own process.

```java
Runnable task = () -> System.out.println("running on: " + Thread.currentThread().getName());
new Thread(task, "worker-1").start();
new Thread(task, "worker-2").start();
```

Two `Thread` objects here, one process (the JVM), both sharing that process's heap.

### What "resources" means for a thread



Resources are the system components a thread actually consumes to do its work. Threads in the same process don't get their own private copy of everything — some things are shared, some are private per-thread:

**Shared across all threads in the process:**

- **Heap** — every object you allocate with `new` lives here, and any thread can reach any object on it (which is exactly why shared mutable state needs synchronization).
- **Code segment** — the compiled instructions/bytecode being executed; identical for every thread.
- **Open file handles, sockets, and other OS-level handles** the process holds — any thread can use them, so concurrent writes to the same file or socket need coordination.

**Private to each thread:**

- **Stack** — local variables, method call frames. This is why two threads calling the same method never see each other's local variables, even though they're running the same code.
- **Program counter** — tracks which instruction that specific thread is currently on.

**Contended, not owned:**

- **CPU time** — threads don't each get a dedicated core; the OS scheduler allocates CPU time across however many threads actually exist, time-slicing on fewer cores than threads.

### Why this matters practically

This heap/stack split is the whole reason race conditions exist specifically on heap data and never on local variables: a race condition is always two threads touching the _same_ heap-allocated object, never two threads stepping on each other's stacks — those are already isolated by construction. It's also why you size thread pools around CPU time (cores available) for compute-bound work, but around something else (I/O wait, external call latency) for I/O-bound work — the resource you're actually contending for differs, and `ExecutorService` pool sizing should track whichever one is the real bottleneck.




[[Threads]]