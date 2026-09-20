# Java Executors and Thread Pools Guide

## Overview

In Java, an `Executor` or `ExecutorService` is **not a thread itself**. It is an **abstraction for managing threads**. Instead of creating threads manually, you submit tasks to an executor, which decides how to run them using threads from a pool.

---

## 1. Creating Threads Directly

```java
Runnable task = () -> System.out.println("Running task");
Thread thread = new Thread(task);
thread.start();
```

- Creates **one thread** directly.
    
- You manage the thread yourself.
    
- Task runs independently.
    

---

## 2. Using Executors (Thread Pools)

Executors allow you to **submit tasks without managing threads directly**.

### 2.1 Single Thread Executor

```java
ExecutorService service = Executors.newSingleThreadExecutor();
service.submit(() -> System.out.println("Task 1"));
service.submit(() -> System.out.println("Task 2"));
```

- Pool contains **exactly 1 thread**.
    
- Tasks run **sequentially**.
    
- Useful when tasks must execute one at a time.
    

### 2.2 Fixed Thread Pool

```java
ExecutorService service = Executors.newFixedThreadPool(5);
for (int i = 0; i < 10; i++) {
    int id = i;
    service.submit(() -> System.out.println("Task " + id));
}
```

- Pool has **n threads** (5 in this case).
    
- Executes **up to n tasks concurrently**.
    
- Excess tasks wait in a queue.
    

### 2.3 Cached Thread Pool

```java
ExecutorService service = Executors.newCachedThreadPool();
for (int i = 0; i < 5; i++) {
    service.submit(() -> System.out.println("Task running"));
}
```

- Creates **new threads as needed**.
    
- Reuses idle threads if available.
    
- Idle threads are terminated after 60 seconds.
    

### 2.4 Scheduled Thread Pool

```java
ScheduledExecutorService service = Executors.newScheduledThreadPool(3);
service.schedule(() -> System.out.println("Delayed task"), 5, TimeUnit.SECONDS);
```

- Useful for **delayed or periodic tasks**.
    
- Pool size determines concurrency.
    

### 2.5 Work Stealing Pool

```java
ExecutorService service = Executors.newWorkStealingPool();
```

- Designed for **parallel tasks**, like Fork/Join.
    
- Threads steal tasks from each other to maximize CPU utilization.
    

### 2.6 Virtual Thread per Task Executor (Java 21+)

```java
ExecutorService service = Executors.newVirtualThreadPerTaskExecutor();
service.submit(() -> System.out.println("Virtual thread task"));
```

- For **massive I/O-bound concurrency**.
    
- Each task runs in its own **lightweight virtual thread**.
    
- Scales to thousands of concurrent tasks efficiently.
    

---

## Key Points

|Executor Type|Threads|Task Behavior|
|---|---|---|
|SingleThreadExecutor|1|Sequential execution|
|FixedThreadPool(n)|n|Up to n concurrent tasks, rest queued|
|CachedThreadPool|Dynamic|Tasks get their own threads if idle threads unavailable|
|ScheduledThreadPool(n)|n|Executes delayed or periodic tasks|
|WorkStealingPool|Dynamic|Threads steal tasks for parallel execution|
|VirtualThreadPerTaskExecutor|Virtual|Each task gets a virtual thread, massive concurrency|

**Summary:**

- `Thread` → direct, manual thread management.
    
- `ExecutorService` → abstracts thread management, handles pools, queuing, and reuse.
    
- Using executors is **safer, more efficient, and scalable** for real applications.


##### *Tags : [[44 - Threads 🧀]]