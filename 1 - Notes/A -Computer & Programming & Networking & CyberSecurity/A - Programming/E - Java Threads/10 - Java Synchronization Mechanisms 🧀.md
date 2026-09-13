
## Overview of Synchronization Mechanisms

### Purpose

- **Thread Safety**: Prevent race conditions when multiple threads access shared resources (e.g., counters, collections).
- **Data Consistency**: Ensure consistent state in shared objects.
- **Coordination**: Manage thread execution order to avoid conflicts.
### Key Concepts

- **Synchronized Keyword**: Used on methods or blocks to enforce mutual exclusion.
- **Monitors**: Logical constructs that manage lock acquisition and release.
- **Intrinsic Locks**: Object-specific locks used by `synchronized` (also called monitor locks).
- **Reentrant Locks**: Locks that allow a thread to reacquire the same lock without deadlocking.

>  Mutual exclusion (often shortened as mutex) is the principle that only one thread or process can access a shared resource at a time.

---
## 1. Synchronized Keyword

The `synchronized` keyword ensures that only one thread can execute a method or block at a time, using an **intrinsic lock** (monitor) associated with an object.

### Usage

- **Synchronized Methods**:
    - Applied to instance or static methods.
    - Locks the object instance (`this`) for instance methods or the class object (`ClassName.class`) for static methods.
- **Synchronized Blocks**:
    - Applied to a code block, locking a specific object.
    - Allows finer-grained control compared to synchronized methods.

### Syntax

- **Synchronized Method**:
    
    ```java
    public synchronized void method() {
        // Critical section
    }
    ```
    
- **Synchronized Block**:
    
    ```java
    synchronized (object) {
        // Critical section
    }
    ```
    

### How It Works

- When a thread enters a `synchronized` method or block, it acquires the intrinsic lock of the specified object.
- Other threads attempting to acquire the same lock are blocked until the lock is released.
- The lock is released when the thread exits the method or block (even if an exception occurs).

### Example: Synchronized Counter

```java
public class SynchronizedCounter {
    private int count = 0;

    // Synchronized method
    public synchronized void increment() {
        count++;
    }

    // Synchronized block
    public void incrementBlock() {
        synchronized (this) {
            count++;
        }
    }

    public int getCount() {
        return count;
    }

    public static void main(String[] args) throws InterruptedException {
        SynchronizedCounter counter = new SynchronizedCounter();
        Runnable task = () -> {
            for (int i = 0; i < 1000; i++) {
                counter.increment();
            }
        };

        Thread t1 = new Thread(task);
        Thread t2 = new Thread(task);
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        System.out.println("Count: " + counter.getCount()); // Output: 2000
    }
}
```

- **Use Case**: Thread-safe counter in a web server tracking requests.

### Where to Use

- **Shared Resources**: Protect shared data (e.g., counters, collections) from concurrent modification.
- **Simple Synchronization**: When coarse-grained locking is sufficient.
- **Critical Sections**: Ensure mutual exclusion in critical code sections.

### Why to Use

- **Simplicity**: Easy to implement compared to explicit locks.
- **Thread Safety**: Prevents race conditions without manual lock management.
- **Built-In**: Part of Java’s core language, no external dependencies.

---

## 2. Monitors

### Overview

- **Definition**: A monitor is a synchronization construct that ensures mutual exclusion and coordination between threads.
- **Implementation in Java**: Every object has an associated monitor (intrinsic lock) used by `synchronized`.
- **Key Features**:
    - **Mutual Exclusion**: Only one thread can hold the monitor at a time.
    - **Condition Variables**: Supports `wait()`, `notify()`, and `notifyAll()` for thread coordination.

### Key Methods (on `Object`)

- `void wait()`: Releases the monitor and puts the thread in the `WAITING` state until notified.
- `void wait(long timeout)`: Waits for a specified time.
- `void notify()`: Wakes one waiting thread holding the same monitor.
- `void notifyAll()`: Wakes all waiting threads holding the same monitor.
- **Note**: These methods must be called within a `synchronized` block or method, or an `IllegalMonitorStateException` is thrown.

### How Monitors Work

- A thread acquires the monitor (lock) when entering a `synchronized` section.
- If the thread calls `wait()`, it releases the monitor and waits.
- Another thread can acquire the monitor and call `notify()` or `notifyAll()` to wake waiting threads.
- The awakened thread reacquires the monitor before proceeding.

### Example: Producer-Consumer with Monitors

```java
import java.util.*;

public class ProducerConsumerMonitor {
    private final List<Integer> buffer = new ArrayList<>();
    private final int capacity = 5;

    public void produce(int item) throws InterruptedException {
        synchronized (buffer) {
            while (buffer.size() == capacity) {
                buffer.wait(); // Release monitor and wait
            }
            buffer.add(item);
            System.out.println("Produced: " + item);
            buffer.notifyAll(); // Wake consumers
        }
    }

    public int consume() throws InterruptedException {
        synchronized (buffer) {
            while (buffer.isEmpty()) {
                buffer.wait(); // Release monitor and wait
            }
            int item = buffer.remove(0);
            System.out.println("Consumed: " + item);
            buffer.notifyAll(); // Wake producers
            return item;
        }
    }

    public static void main(String[] args) {
        ProducerConsumerMonitor pc = new ProducerConsumerMonitor();
        Thread producer = new Thread(() -> {
            try {
                for (int i = 0; i < 5; i++) {
                    pc.produce(i);
                    Thread.sleep(500);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        Thread consumer = new Thread(() -> {
            try {
                for (int i = 0; i < 5; i++) {
                    pc.consume();
                    Thread.sleep(1000);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        producer.start();
        consumer.start();
    }
}
```

- **Use Case**: Thread-safe task queue in a microservice.

### Where to Use

- **Thread Coordination**: When threads need to wait for conditions (e.g., producer-consumer).
- **Shared Resource Access**: When mutual exclusion is needed for shared data.

### Why to Use

- **Built-In Mechanism**: Monitors are part of every Java object.
- **Coordination**: `wait()` and `notify()` enable complex thread interactions.
- **Reliability**: Ensures thread-safe access to critical sections.

---

## 3. Intrinsic Locks

### Overview

- **Definition**: Also called monitor locks, ==intrinsic locks are associated with every Java object and class==. They are used by `synchronized` to enforce mutual exclusion.
- **Key Points**:
    - **Each object has one intrinsic lock.**
    - ***For instance methods, the lock is on the object instance (`this`).***
    - ***For static methods, the lock is on the class object (`ClassName.class`).***
    - ***Intrinsic locks are reentrant (a thread can reacquire the same lock).***

### How It Works

- When a thread enters a `synchronized` method or block, it acquires the intrinsic lock.
- Other threads are blocked until the lock is released.
- The lock is automatically released when the thread exits the synchronized section or if an exception occurs.

### Example: Intrinsic Lock on Different Objects

```java
public class IntrinsicLockExample {
    private final Object lock1 = new Object();
    private final Object lock2 = new Object();
    private int count1 = 0;
    private int count2 = 0;

    public void incrementCounter1() {
        synchronized (lock1) {
            count1++;
        }
    }

    public void incrementCounter2() {
        synchronized (lock2) {
            count2++;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        IntrinsicLockExample example = new IntrinsicLockExample();
        Thread t1 = new Thread(() -> {
            for (int i = 0; i < 1000; i++) {
                example.incrementCounter1();
            }
        });
        Thread t2 = new Thread(() -> {
            for (int i = 0; i < 1000; i++) {
                example.incrementCounter2();
            }
        });
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        System.out.println("Count1: " + example.count1); // Output: 1000
        System.out.println("Count2: " + example.count2); // Output: 1000
    }
}
```

- **Use Case**: Independent counters in a multi-threaded application, using separate locks to reduce contention.

### Where to Use

- **Object-Specific Synchronization**: When different objects need independent locks.
- **Coarse-Grained Locking**: When protecting entire methods or large code sections.

### Why to Use

- **Simplicity**: No need to manage locks explicitly.
- **Automatic Release**: Locks are released on exceptions or block exit.
- **Reentrancy**: Supports recursive calls without deadlocks.

---

## 4. Reentrant Locks

### Overview

- **Definition**: A lock that allows a thread to reacquire it multiple times without deadlocking. Java’s intrinsic locks (used by `synchronized`) and `ReentrantLock` (from `java.util.concurrent.locks`) are reentrant.
- **Key Points**:
    - **Intrinsic Locks**: Automatically reentrant when used in `synchronized` methods/blocks.
    - **ReentrantLock**: An explicit lock class that supports reentrancy, fairness, and advanced features like interruptible locking.

### ReentrantLock (Explicit Alternative)

- **Class**: `java.util.concurrent.locks.ReentrantLock`
- **Key Methods**:
    - `void lock()`: Acquires the lock, blocking if necessary.
    - `void unlock()`: Releases the lock.
    - `boolean tryLock()`: Non-blocking lock acquisition.
    - `boolean tryLock(long time, TimeUnit unit)`: Timed lock acquisition.
    - `void lockInterruptibly()`: Acquires the lock unless interrupted.
    - ***`Condition newCondition()`: Creates a condition for coordination.***
- **Features**:
    - **Fairness**: Optional fair mode (`new ReentrantLock(true)`) ensures FIFO lock acquisition.
    - **Reentrancy**: Tracks the number of holds by a thread (`getHoldCount()`).
    - **Flexibility**: Supports try-locks and interruptible locks.

---

- ***Blocking lock:** thread waits → guaranteed to enter critical section eventually.*
    
- ***Non-blocking lock:** thread doesn’t wait → can skip work or retry later.*
---
### Example: ReentrantLock with Conditions

```java
import java.util.concurrent.locks.*;

public class ReentrantLockExample {
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition condition = lock.newCondition();
    private int count = 0;

    public void increment() {
        lock.lock();
        try {
            count++;
            condition.signalAll(); // Notify waiting threads
        } finally {
            lock.unlock();
        }
    }

    public int waitForCount(int threshold) throws InterruptedException {
        lock.lock();
        try {
            while (count < threshold) {
                condition.await(); // Wait until condition is met
            }
            return count;
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        ReentrantLockExample example = new ReentrantLockExample();
        Thread t1 = new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                example.increment();
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        });
        Thread t2 = new Thread(() -> {
            try {
                System.out.println("Count reached: " + example.waitForCount(5));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        t2.start();
        t1.start();
        t1.join();
        t2.join();
    }
}
```

- **Use Case**: Coordinating threads in a backend system (e.g., waiting for a counter to reach a threshold).
---
**Reentrancy** in the context of locks means:

> A thread that **already holds a lock** can **acquire it again without getting blocked**.
---
### Reentrancy Example

```java
public class ReentrantExample {
    private final ReentrantLock lock = new ReentrantLock();

    public void outer() {
        lock.lock();
        try {
            System.out.println("Outer: Lock acquired, hold count: " + lock.getHoldCount());
            inner(); // Reentrant call
        } finally {
            lock.unlock();
        }
    }

    public void inner() {
        lock.lock();
        try {
            System.out.println("Inner: Lock acquired, hold count: " + lock.getHoldCount());
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) {
        ReentrantExample example = new ReentrantExample();
        example.outer();
        // Output:
        // Outer: Lock acquired, hold count: 1
        // Inner: Lock acquired, hold count: 2
    }
}
```

- **Use Case**: Recursive operations in a thread-safe manner.

### Where to Use

- **Intrinsic Locks**: Use with `synchronized` for simple, coarse-grained locking.
- **ReentrantLock**: Use for advanced features like fairness, try-locks, or multiple conditions.

### Why to Use

- **Reentrancy**: Prevents deadlocks in recursive or nested calls.
- **Flexibility**: `ReentrantLock` offers features not available with `synchronized` (e.g., timed locks).
- **Reliability**: Ensures thread-safe access to shared resources.

---

## Comparison: Synchronized vs. ReentrantLock

|Feature|Synchronized Keyword|ReentrantLock|
|---|---|---|
|**Lock Type**|Intrinsic lock (monitor)|Explicit lock|
|**Reentrancy**|Yes|Yes|
|**Ease of Use**|Simple, built-in|More complex, requires manual unlock|
|**Fairness**|No (non-fair by default)|Optional (`new ReentrantLock(true)`)|
|**Try-Lock**|Not supported|Supported (`tryLock()`)|
|**Timed Lock**|Not supported|Supported (`tryLock(time, unit)`)|
|**Interruptible Lock**|Not supported|Supported (`lockInterruptibly()`)|
|**Conditions**|Limited (`wait()`, `notify()`)|Multiple `Condition` objects|
|**Unlock on Exception**|Automatic|Manual (use `finally`)|

### When to Choose

- **Synchronized**: Use for simple synchronization with minimal overhead (e.g., protecting a single counter).
- **ReentrantLock**: Use for advanced scenarios requiring fairness, try-locks, or multiple conditions (e.g., complex coordination in a queue).

---

## Best Practices for Legendary Backend Developers

- **Use Synchronized for Simplicity**:
    - Prefer `synchronized` for straightforward thread safety (e.g., protecting a shared counter).
    - Example: `synchronized void increment() { count++; }`
- **Use Synchronized Blocks for Fine-Grained Locking**:
    - Lock on specific objects to reduce contention.
    - Example: `synchronized(lockObject) { ... }`
- **Use ReentrantLock for Advanced Features**:
    - Use for fairness, try-locks, or multiple conditions.
    - Example: `ReentrantLock` with `Condition` for producer-consumer.
- **Always Unlock in Finally**:
    - For `ReentrantLock`, call `unlock()` in a `finally` block to prevent deadlocks.
    - Example: `lock.lock(); try { ... } finally { lock.unlock(); }`
- **Avoid Nested Locks**:
    - Minimize nested `synchronized` blocks or `ReentrantLock` calls to prevent deadlocks.
    - Use consistent lock ordering if necessary.
- **Use notifyAll() Over notify()**:
    - `notifyAll()` wakes all waiting threads, reducing the risk of missed signals.
    - Example: Use in producer-consumer to ensure all consumers are notified.
- **Handle InterruptedException**:
    - Restore the interrupted status (`Thread.currentThread().interrupt()`) when catching `InterruptedException`.
    - Example: `catch (InterruptedException e) { Thread.currentThread().interrupt(); }`
- **Minimize Contention**:
    - Use separate locks for independent resources to reduce contention.
    - Example: Use multiple `ReentrantLock` instances for different counters.
- **Consider Higher-Level Concurrency**:
    - Use `java.util.concurrent` utilities (e.g., `BlockingQueue`, `ConcurrentHashMap`) for complex scenarios.
    - Example: Replace `synchronized` with `BlockingQueue` for producer-consumer.
- **Monitor and Debug**:
    - Use tools like JVisualVM to monitor lock contention.
    - Log lock acquisition/release for debugging in production.

---

## Practical Example: Thread-Safe Resource Manager

Below is a thread-safe resource manager combining `synchronized`, monitors, and `ReentrantLock` for a backend system.

```java
import java.util.concurrent.locks.*;
import java.util.*;

public class ResourceManager {
    private final Map<String, String> resources = new HashMap<>();
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition resourceAdded = lock.newCondition();
    private int resourceCount = 0;

    // Synchronized method for simple access
    public synchronized void addResource(String key, String value) {
        resources.put(key, value);
        resourceCount++;
        notifyAll(); // Wake waiting threads
    }

    // ReentrantLock for conditional waiting
    public String waitForResources(int minCount) throws InterruptedException {
        lock.lock();
        try {
            while (resourceCount < minCount) {
                resourceAdded.await(); // Wait for resources
            }
            return resources.toString();
        } finally {
            lock.unlock();
        }
    }

    // Synchronized block for fine-grained access
    public String getResource(String key) {
        synchronized (resources) {
            return resources.getOrDefault(key, "Not found");
        }
    }

    public static void main(String[] args) throws InterruptedException {
        ResourceManager manager = new ResourceManager();
        Thread producer = new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                manager.addResource("key" + i, "value" + i);
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        });

        Thread consumer = new Thread(() -> {
            try {
                System.out.println("Resources: " + manager.waitForResources(5));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        producer.start();
        consumer.start();
        producer.join();
        consumer.join();
        System.out.println("Resource key1: " + manager.getResource("key1")); // Output: value1
    }
}
```

- **Components**:
    - **Synchronized Method**: `addResource` uses `synchronized` for simplicity.
    - **ReentrantLock with Condition**: `waitForResources` uses `ReentrantLock` for conditional waiting.
    - **Synchronized Block**: `getResource` uses a block for fine-grained locking.
- **Use Case**: Managing shared resources in a microservice with thread-safe access and coordination.

---

## Pros and Cons

### Pros

- **Synchronized Keyword**:
    - Simple to use, no manual lock management.
    - Automatic lock release on exceptions.
    - Built-in reentrancy.
- **Monitors**:
    - Enables thread coordination with `wait()` and `notify()`.
    - Integrated with every Java object.
- **Intrinsic Locks**:
    - No external dependencies, part of the JVM.
    - Supports reentrancy for recursive calls.
- **ReentrantLock**:
    - Flexible with try-locks, fairness, and multiple conditions.
    - Interruptible locking for responsive shutdown.

### Cons

- **Synchronized Keyword**:
    - Coarse-grained, may lead to contention.
    - No support for try-locks or fairness.
    - Limited to one monitor per object.
- **Monitors**:
    - Risk of missed signals if `notify()` is used incorrectly.
    - Must be used within `synchronized` blocks, or `IllegalMonitorStateException` occurs.
- **Intrinsic Locks**:
    - No advanced features like timed locks or interruptibility.
    - Can cause deadlocks if not managed properly.
- **ReentrantLock**:
    - Requires manual unlocking, increasing complexity.
    - More overhead than `synchronized` for simple cases.
    - Risk of forgetting `unlock()` in `finally`.

---

## Resources

- Java Synchronization: [Thread Synchronization](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/Object.html)
- ReentrantLock: [ReentrantLock API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/locks/ReentrantLock.html)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)


[[44 - Threads 🧀]]