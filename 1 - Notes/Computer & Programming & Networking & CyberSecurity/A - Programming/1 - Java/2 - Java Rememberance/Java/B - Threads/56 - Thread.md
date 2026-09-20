
## Thread — Computer Science

A **thread** is the **smallest unit of execution that can be scheduled by the operating system**.

A thread represents a single **flow of instructions** being executed inside a process.

Think:

```text
Process
│
├── Thread 1 → instructions A → B → C
├── Thread 2 → instructions X → Y → Z
└── Thread 3 → instructions P → Q → R
```

The important relationship is:

> **Process = resource/isolation boundary**  
> **Thread = execution path**

### What does a thread have?

Each thread has its own execution state, including:

- **Program counter** — which instruction it is currently executing
    
- **CPU registers** — its current CPU state
    
- **Stack** — its method calls and local variables
    
- **Thread state** — running, waiting, blocked, etc.
    

But threads **within the same process share** resources such as:

- Heap
    
- Loaded program code
    
- Open resources/files
    
- Process address space
    

So:

```text
Process
│
├── Shared memory
│   ├── Code
│   └── Heap
│
├── Thread A
│   └── Own stack + CPU state
│
├── Thread B
│   └── Own stack + CPU state
│
└── Thread C
    └── Own stack + CPU state
```

---

# Thread in Java

In Java, a **`Thread` is an object representing a thread of execution managed by the JVM/OS**.

For example:

```java
Thread thread = new Thread(() -> {
    System.out.println("Hello from another thread");
});

thread.start();
```

When you call:

```java
thread.start();
```

Java asks the runtime to start a new thread of execution.

Conceptually:

```text
Java Process
│
├── main thread
│    └── main()
│
└── new thread
     └── lambda code
```

The new thread can execute concurrently with the `main` thread.

### Very important: `start()` vs `run()`

This:

```java
thread.start();
```

**starts a new thread.**

This:

```java
thread.run();
```

does **not** start a new thread. It simply calls `run()` like an ordinary method on the current thread.

```text
start()
  ↓
new execution path
  ↓
run()
```

versus:

```text
run()
  ↓
ordinary method call
  ↓
same thread
```

---

## Modern Java: Platform vs Virtual Threads

In modern Java, there are two important kinds of Java threads:

```text
Java Thread
│
├── Platform Thread
│     ↕
│   OS thread
│
└── Virtual Thread
      ↕
    JVM-managed execution
```

A **platform thread** is closely associated with an OS thread.

A **virtual thread**, introduced in Java 21, is much lighter and is managed by the JVM. Java can therefore create very large numbers of virtual threads, particularly useful for applications doing lots of blocking I/O.

For example:

```java
Thread.startVirtualThread(() -> {
    System.out.println("Hello");
});
```

The fundamental concept, however, remains the same:

> **A thread is an independent path of execution within a process.**

And this is the foundation for understanding **concurrency, parallelism, synchronization, locks, executors, futures, and virtual threads** in Java.


[[Java]]