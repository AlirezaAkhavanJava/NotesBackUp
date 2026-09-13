# Java Locks and Conditions: ReentrantLock and Condition

`ReentrantLock` and `Condition` from the `java.util.concurrent.locks` package provide more control than the `synchronized` keyword for thread synchronization. `ReentrantLock` offers advanced locking features, while `Condition` enables precise thread signaling. This document explains their usage, key methods, and practical examples for backend applications, keeping it simple and concise.

---

## 1. ReentrantLock

### Overview

- **Purpose**: A flexible, explicit lock that supports reentrancy (a thread can reacquire the same lock), fairness, and interruptible locking.
- **Advantages Over synchronized**:
    - Fairness option (FIFO lock acquisition).
    - Try-locks (non-blocking or timed).
    - Interruptible locking.
    - Multiple conditions for signaling.

### Key Methods

- `void lock()`: Acquires the lock, blocking if necessary.
- `void unlock()`: Releases the lock (use in `finally` block).
- `boolean tryLock()`: Attempts to acquire the lock without blocking.
- `boolean tryLock(long time, TimeUnit unit)`: Attempts to acquire the lock with a timeout.
- `void lockInterruptibly()`: Acquires the lock unless interrupted.
- `Condition newCondition()`: Creates a condition for signaling.

### Example

```java
import java.util.concurrent.locks.*;

public class ReentrantLockExample {
    private final ReentrantLock lock = new ReentrantLock();
    private int count = 0;

    public void increment() {
        lock.lock();
        try {
            count++;
        } finally {
            lock.unlock();
        }
    }

    public int getCount() {
        lock.lock();
        try {
            return count;
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        ReentrantLockExample counter = new ReentrantLockExample();
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

- **Use Case**: Thread-safe counter for tracking requests in a web server.

### Where to Use

- When you need fairness, try-locks, or interruptible locking.
- When multiple conditions are required for thread coordination.
- Example: Managing shared resources in a microservice.

### Why to Use

- More flexible than `synchronized`.
- Supports advanced features like timed locks and fairness.
- Prevents deadlocks in recursive or complex scenarios.

---

## 2. Condition

### Overview

- **Purpose**: Enables thread signaling and waiting, similar to `Object.wait()` and `notify()`, but with more control.
- **Key Point**: Created via `ReentrantLock.newCondition()`; used with a `ReentrantLock`.

### Key Methods

- `void await()`: Releases the lock and waits until signaled (like `wait()`).
- `void signal()`: Wakes one waiting thread (like `notify()`).
- `void signalAll()`: Wakes all waiting threads (like `notifyAll()`).
- `boolean await(long time, TimeUnit unit)`: Waits with a timeout.

### Example: Producer-Consumer with ReentrantLock and Condition

```java
import java.util.concurrent.locks.*;
import java.util.*;

public class ProducerConsumerCondition {
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notFull = lock.newCondition();
    private final Condition notEmpty = lock.newCondition();
    private final List<Integer> buffer = new ArrayList<>();
    private final int capacity = 5;

    public void produce(int item) throws InterruptedException {
        lock.lock();
        try {
            while (buffer.size() == capacity) {
                notFull.await(); // Wait if buffer is full
            }
            buffer.add(item);
            System.out.println("Produced: " + item);
            notEmpty.signal(); // Signal consumers
        } finally {
            lock.unlock();
        }
    }

    public int consume() throws InterruptedException {
        lock.lock();
        try {
            while (buffer.isEmpty()) {
                notEmpty.await(); // Wait if buffer is empty
            }
            int item = buffer.remove(0);
            System.out.println("Consumed: " + item);
            notFull.signal(); // Signal producers
            return item;
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) {
        ProducerConsumerCondition pc = new ProducerConsumerCondition();
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

- **Use Case**: Task queue in a backend system with producer-consumer coordination.

### Where to Use

- When threads need to wait for specific conditions (e.g., buffer full/empty).
- When multiple conditions are needed for different signals.
- Example: Coordinating tasks in a thread pool.

### Why to Use

- More flexible than `wait()`/`notify()` with multiple conditions.
- Works with `ReentrantLock` for advanced locking scenarios.
- Supports interruptible and timed waiting.

---

## Best Practices

- **Always Unlock in Finally**: Call `lock.unlock()` in a `finally` block to prevent deadlocks.
    - Example: `lock.lock(); try { ... } finally { lock.unlock(); }`
- **Use Conditions for Coordination**: Use separate `Condition` objects (e.g., `notFull`, `notEmpty`) for clear signaling.
- **Prefer signalAll() Over signal()**: Ensures all waiting threads are notified, reducing missed signals.
- **Handle Interruptions**: Catch `InterruptedException` and restore the interrupted status.
    - Example: `catch (InterruptedException e) { Thread.currentThread().interrupt(); }`
- **Use Try-Locks for Flexibility**: Use `tryLock()` or `tryLock(time, unit)` to avoid blocking indefinitely.
- **Enable Fairness Sparingly**: Use `new ReentrantLock(true)` only when FIFO order is critical, as it increases overhead.
- **Combine with Concurrent Utilities**: Use `ReentrantLock` with `BlockingQueue` or `ConcurrentHashMap` for complex scenarios.

---

## Pros and Cons

### Pros

- **ReentrantLock**:
    - More flexible than `synchronized` (fairness, try-locks, interruptibility).
    - Supports multiple conditions for complex coordination.
    - Reentrant, preventing deadlocks in recursive calls.
- **Condition**:
    - Precise signaling with multiple conditions.
    - Supports timed and interruptible waiting.

### Cons

- **ReentrantLock**:
    - Requires manual unlocking, increasing complexity.
    - Higher overhead than `synchronized` for simple cases.
- **Condition**:
    - Must be used with `ReentrantLock`, adding setup complexity.
    - Risk of missed signals if `signal()` is used incorrectly.

---

## Resources

- ReentrantLock: [ReentrantLock API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/locks/ReentrantLock.html)
- Condition: [Condition API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/locks/Condition.html)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)


[[44 - Threads 🧀]]