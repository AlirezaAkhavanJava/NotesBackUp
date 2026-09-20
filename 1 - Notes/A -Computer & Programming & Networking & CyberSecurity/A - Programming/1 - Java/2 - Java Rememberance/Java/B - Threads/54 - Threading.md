### Threading

**Threading** is the technique of dividing a program's execution into multiple **threads**, where each thread represents an independent path of execution that can run **concurrently** within the same process.

A **thread** is the smallest unit of execution that the operating system can schedule on a CPU.

### Simple mental model

Imagine a Java application:

```text
Process: MyApplication
│
├── Thread 1 → handle HTTP request
├── Thread 2 → read a file
├── Thread 3 → query PostgreSQL
└── Thread 4 → perform background work
```

Instead of having one execution path:

```text
Task A → Task B → Task C → Task D
```

you can have multiple execution paths:

```text
        ┌─ Thread 1 → Task A
Process ├─ Thread 2 → Task B
        ├─ Thread 3 → Task C
        └─ Thread 4 → Task D
```

### Important distinction

**Concurrency ≠ necessarily parallelism.**

- **Concurrency** → multiple tasks are in progress during overlapping periods.
    
- **Parallelism** → multiple tasks are **literally executing at the same time**, typically on different CPU cores.
    

For example, on your 4-core CPU, four threads can potentially execute in parallel:

```text
Core 1 → Thread A
Core 2 → Thread B
Core 3 → Thread C
Core 4 → Thread D
```

With only one core, the OS can rapidly switch between threads:

```text
A → B → A → C → B → A → ...
```

This creates concurrency, but not true parallel execution.

### In Java

Java provides the `Thread` abstraction:

```java
Thread thread = new Thread(() -> {
    System.out.println("Running in another thread");
});

thread.start();
```

`start()` tells the JVM to begin executing the thread independently. Calling `run()` directly does **not** create a new thread.

Modern Java also provides higher-level concurrency APIs such as:

```text
Thread
   ↓
ExecutorService
   ↓
Virtual Threads
   ↓
Structured Concurrency
```

So, at its core:

> **Threading = using multiple threads to allow different parts of a program to execute concurrently.**

[[Java]]