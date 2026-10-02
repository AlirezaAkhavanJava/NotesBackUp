



---

## Overview of the Locks Package

### Purpose

- Provides **explicit locking** mechanisms for fine-grained control over thread synchronization.
- Offers alternatives to `synchronized` blocks, with features like **try-locks**, **timed locks**, **interruptible locks**, and **condition variables**.
- Designed for high-concurrency scenarios where traditional synchronization may cause contention or lack flexibility.
- Complements other concurrency utilities (e.g., `java.util.concurrent.atomic`, `ExecutorService`).

### Key Features

- **Explicit Locks**: Unlike implicit `synchronized` blocks, locks are acquired and released manually, allowing precise control.
- **Flexibility**: Supports non-blocking (`tryLock`), timed, and interruptible lock acquisition.
- **Condition Variables**: Enables complex thread coordination (e.g., producer-consumer patterns).
- **Fairness**: Optional fair locking to reduce starvation.
- **Thread-Safe**: All implementations are designed for concurrent access.

### When to Use

- **High-Contention Scenarios**: When `synchronized` blocks cause performance bottlenecks.
- **Complex Synchronization**: When you need condition-based waiting or timed locks.
- **Fine-Grained Control**: When locking specific code sections or multiple resources.
- **Avoiding Deadlocks**: When try-locks or interruptible locks can prevent deadlock scenarios.

---

## Key Interfaces and Classes

The `java.util.concurrent.locks` package includes interfaces and classes for locks, read-write locks, conditions, and stamped locks. Below are the primary components, their purposes, and key methods a legendary backend developer should master.

### 1. Lock Interface

- **Purpose**: Defines the basic locking operations, providing a more flexible alternative to `synchronized` blocks.
- **Use Case**: Thread-safe access to shared resources (e.g., counters, caches).
- **Key Methods**:
    - `void lock()`: Acquires the lock, blocking until available.
    - `void lockInterruptibly()`: Acquires the lock unless the thread is interrupted.
    - `boolean tryLock()`: Attempts to acquire the lock non-blocking; returns `true` if acquired.
    - `boolean tryLock(long time, TimeUnit unit)`: Attempts to acquire the lock within a timeout; returns `true` if acquired.
    - `void unlock()`: Releases the lock.
    - `Condition newCondition()`: Creates a `Condition` object for thread coordination.
- **Example**:

```java
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class LockExample {
    private final Lock lock = new ReentrantLock();
    private int counter = 0;

    public void increment() {
        lock.lock();
        try {
            counter++;
        } finally {
            lock.unlock(); // Always in finally to ensure release
        }
    }

    public static void main(String[] args) throws InterruptedException {
        LockExample example = new LockExample();
        Runnable task = () -> {
            for (int i = 0; i < 1000; i++) {
                example.increment();
            }
        };

        Thread t1 = new Thread(task);
        Thread t2 = new Thread(task);
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        System.out.println("Counter: " + example.counter); // Output: 2000
    }
}
```

- **Use Case**: Thread-safe counter in a web server.

### 2. ReentrantLock Class

- **Purpose**: A concrete implementation of `Lock`, supporting reentrant locking (a thread can acquire the same lock multiple times).
- **Use Case**: Fine-grained synchronization with fairness or interruptible locking.
- **Key Features**:
    - **Reentrancy**: A thread can re-acquire the lock without deadlocking.
    - **Fairness**: Optional fair mode (constructor: `ReentrantLock(boolean fair)`) ensures FIFO lock acquisition, reducing starvation.
    - **Interruptibility**: Supports `lockInterruptibly()` for interruptible locking.
- **Key Methods** (extends `Lock` methods):
    - `ReentrantLock()`: Creates a non-fair lock (default).
    - `ReentrantLock(boolean fair)`: Creates a lock with optional fairness.
    - `int getHoldCount()`: Returns the number of holds by the current thread (reentrancy count).
    - `boolean isHeldByCurrentThread()`: Checks if the lock is held by the current thread.
    - `boolean isLocked()`: Checks if the lock is held by any thread.
    - `int getQueueLength()`: Returns the number of threads waiting for the lock.
    - `Collection<Thread> getQueuedThreads()`: Returns threads waiting for the lock.
- **Example**:

```java
import java.util.concurrent.locks.ReentrantLock;

public class ReentrantLockExample {
    private final ReentrantLock lock = new ReentrantLock(true); // Fair lock
    private int sharedResource = 0;

    public void accessResource() {
        lock.lock();
        try {
            sharedResource++;
            System.out.println(Thread.currentThread().getName() + " accessed resource: " + sharedResource);
        } finally {
            lock.unlock();
        }
    }
}
```

- **Use Case**: Fair access to a shared resource in a high-contention system.

### 3. Condition Interface

- **Purpose**: Enables thread coordination (waiting and signaling) on a lock, similar to `Object.wait()` and `notify()`.
- **Use Case**: Producer-consumer patterns, thread synchronization with conditions.
- **Key Methods**:
    - `void await()`: Causes the thread to wait until signaled or interrupted.
    - `boolean await(long time, TimeUnit unit)`: Waits for a specified time; returns `true` if signaled.
    - `void awaitUninterruptibly()`: Waits until signaled, ignoring interruptions.
    - `long awaitNanos(long nanosTimeout)`: Waits for a specified time in nanoseconds.
    - `void signal()`: Wakes up one waiting thread.
    - `void signalAll()`: Wakes up all waiting threads.
- **Example**:

```java
import java.util.concurrent.locks.*;

public class ProducerConsumerExample {
    private final Lock lock = new ReentrantLock();
    private final Condition notFull = lock.newCondition();
    private final Condition notEmpty = lock.newCondition();
    private final int[] buffer = new int[10];
    private int count = 0;

    public void produce(int item) throws InterruptedException {
        lock.lock();
        try {
            while (count == buffer.length) {
                notFull.await(); // Wait if buffer is full
            }
            buffer[count++] = item;
            notEmpty.signal(); // Signal consumers
        } finally {
            lock.unlock();
        }
    }

    public int consume() throws InterruptedException {
        lock.lock();
        try {
            while (count == 0) {
                notEmpty.await(); // Wait if buffer is empty
            }
            int item = buffer[--count];
            notFull.signal(); // Signal producers
            return item;
        } finally {
            lock.unlock();
        }
    }
}
```

- **Use Case**: Thread-safe producer-consumer queue.

### 4. ReadWriteLock Interface

- **Purpose**: Provides separate locks for reading and writing, allowing multiple readers but exclusive writers.
- **Use Case**: Read-heavy scenarios (e.g., caches, shared data structures).
- **Key Methods**:
    - `Lock readLock()`: Returns the lock for reading (shared).
    - `Lock writeLock()`: Returns the lock for writing (exclusive).
- **Example**:

```java
import java.util.concurrent.locks.*;

public class ReadWriteLockExample {
    private final ReadWriteLock rwLock = new ReentrantReadWriteLock();
    private final Lock readLock = rwLock.readLock();
    private final Lock writeLock = rwLock.writeLock();
    private int data = 0;

    public int readData() {
        readLock.lock();
        try {
            return data;
        } finally {
            readLock.unlock();
        }
    }

    public void writeData(int value) {
        writeLock.lock();
        try {
            data = value;
        } finally {
            writeLock.unlock();
        }
    }
}
```

- **Use Case**: Thread-safe cache with frequent reads and rare writes.

### 5. ReentrantReadWriteLock Class

- **Purpose**: A concrete implementation of `ReadWriteLock`, supporting reentrant read and write locks.
- **Use Case**: Concurrent access to shared data with read-write separation.
- **Key Features**:
    - **Read Lock**: Multiple threads can acquire the read lock simultaneously if no write lock is held.
    - **Write Lock**: Exclusive, only one thread can hold it.
    - **Fairness**: Optional fair mode (`ReentrantReadWriteLock(boolean fair)`).
    - **Reentrancy**: Supports reentrant locking for both read and write locks.
- **Key Methods** (extends `ReadWriteLock`):
    - `Lock readLock()`: Returns the read lock.
    - `Lock writeLock()`: Returns the write lock.
    - `int getReadLockCount()`: Returns the number of read locks held.
    - `int getWriteHoldCount()`: Returns the number of write lock holds by the current thread.
    - `boolean isWriteLocked()`: Checks if the write lock is held.
- **Example**:

```java
import java.util.concurrent.locks.*;

public class CacheExample {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private int cacheValue = 0;

    public int getCache() {
        rwLock.readLock().lock();
        try {
            return cacheValue;
        } finally {
            rwLock.readLock().unlock();
        }
    }

    public void updateCache(int value) {
        rwLock.writeLock().lock();
        try {
            cacheValue = value;
        } finally {
            rwLock.writeLock().unlock();
        }
    }
}
```

- **Use Case**: Thread-safe in-memory cache.

### 6. StampedLock Class

- **Purpose**: A non-reentrant lock with three modes: reading, writing, and optimistic reading, optimized for read-heavy scenarios.
- **Use Case**: High-performance read-write access with optimistic locking.
- **Key Features**:
    - **Write Lock**: Exclusive lock for writing.
    - **Read Lock**: Shared lock for reading.
    - **Optimistic Read**: Non-blocking read that validates consistency without locking.
    - **Non-Reentrant**: Does not support reentrancy (unlike `ReentrantLock`).
    - **Stamp**: Returns a stamp (long) for each lock acquisition, used for unlocking or validation.
- **Key Methods**:
    - `long writeLock()`: Acquires the write lock, returns a stamp.
    - `long readLock()`: Acquires the read lock, returns a stamp.
    - `long tryOptimisticRead()`: Attempts an optimistic read, returns a stamp.
    - `boolean validate(long stamp)`: Validates an optimistic read stamp.
    - `void unlock(long stamp)`: Releases a lock (read or write) using the stamp.
    - `void unlockRead(long stamp)`: Releases a read lock.
    - `void unlockWrite(long stamp)`: Releases a write lock.
    - `long tryConvertToWriteLock(long stamp)`: Converts a read or optimistic read to a write lock.
    - `long tryConvertToReadLock(long stamp)`: Converts a write or optimistic read to a read lock.
- **Example**:

```java
import java.util.concurrent.locks.StampedLock;

public class StampedLockExample {
    private final StampedLock lock = new StampedLock();
    private double x, y;

    public double getDistanceFromOrigin() {
        long stamp = lock.tryOptimisticRead();
        double currentX = x, currentY = y;
        if (lock.validate(stamp)) {
            return Math.sqrt(currentX * currentX + currentY * currentY);
        } else {
            stamp = lock.readLock();
            try {
                return Math.sqrt(x * x + y * y);
            } finally {
                lock.unlockRead(stamp);
            }
        }
    }

    public void move(double newX, double newY) {
        long stamp = lock.writeLock();
        try {
            x = newX;
            y = newY;
        } finally {
            lock.unlockWrite(stamp);
        }
    }
}
```

- **Use Case**: High-performance coordinate updates in a game server.

### 7. LockSupport Class

- **Purpose**: Provides low-level thread blocking and unblocking primitives, used internally by locks and other concurrency utilities.
- **Use Case**: Advanced concurrency control (rarely used directly by developers).
- **Key Methods**:
    - `static void park()`: Blocks the current thread until unparked or interrupted.
    - `static void parkNanos(long nanos)`: Blocks for a specified time.
    - `static void parkUntil(long deadline)`: Blocks until a deadline (epoch time).
    - `static void unpark(Thread thread)`: Unblocks a specific thread.
- **Example**:

```java
import java.util.concurrent.locks.LockSupport;

public class LockSupportExample {
    public static void main(String[] args) {
        Thread t = new Thread(() -> {
            System.out.println("Thread parked");
            LockSupport.park();
            System.out.println("Thread unparked");
        });
        t.start();

        try {
            Thread.sleep(1000);
            LockSupport.unpark(t);
        } catch (InterruptedException e) {}
    }
}
```

- **Use Case**: Custom synchronization mechanisms (e.g., implementing custom locks).

---

## Key Concepts for Legendary Backend Developers

### Reentrancy

- **Definition**: A thread can acquire the same lock multiple times without deadlocking.
- **Supported By**: `ReentrantLock`, `ReentrantReadWriteLock`.
- **Not Supported By**: `StampedLock` (non-reentrant, requires careful use).

### Fairness

- **Definition**: Ensures threads acquire locks in the order they requested (FIFO), reducing starvation.
- **Supported By**: `ReentrantLock` and `ReentrantReadWriteLock` with `fair=true`.
- **Trade-Off**: Fairness reduces throughput due to increased overhead.

### Optimistic Locking (StampedLock)

- **How It Works**: `tryOptimisticRead` allows non-blocking reads, validated with `validate(stamp)`.
- **Advantages**: High performance for read-heavy scenarios.
- **Challenges**: Requires fallback to read/write locks if validation fails.

### Conditions

- **Purpose**: Replaces `Object.wait()`/`notify()` with more flexible coordination.
- **Use Case**: Producer-consumer, thread synchronization with multiple conditions.
- **Best Practice**: Use multiple `Condition` objects for complex scenarios (e.g., separate conditions for full/empty in a queue).

### Interruptible Locks

- **Definition**: Allows a thread to be interrupted while waiting for a lock (`lockInterruptibly`).
- **Supported By**: `ReentrantLock`, `ReentrantReadWriteLock`.
- **Use Case**: Graceful shutdown in concurrent systems.

### Try-Locks

- **Definition**: Non-blocking (`tryLock()`) or timed (`tryLock(time, unit)`) lock acquisition.
- **Use Case**: Avoiding deadlocks or timeouts in resource contention.

---

## Practical Example: Thread-Safe Resource Manager

Below is a thread-safe resource manager using multiple lock types, suitable for a backend application.

```java
import java.util.concurrent.locks.*;
import java.util.*;

public class ResourceManager {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private final Lock readLock = rwLock.readLock();
    private final Lock writeLock = rwLock.writeLock();
    private final Map<String, String> resources = new HashMap<>();
    private final StampedLock stampedLock = new StampedLock();
    private double balance;

    // Read resource (ReadWriteLock)
    public String getResource(String key) {
        readLock.lock();
        try {
            return resources.getOrDefault(key, "Not found");
        } finally {
            readLock.unlock();
        }
    }

    // Write resource (ReadWriteLock)
    public void putResource(String key, String value) {
        writeLock.lock();
        try {
            resources.put(key, value);
        } finally {
            writeLock.unlock();
        }
    }

    // Optimistic read for balance (StampedLock)
    public double getBalance() {
        long stamp = stampedLock.tryOptimisticRead();
        double currentBalance = balance;
        if (stampedLock.validate(stamp)) {
            return currentBalance;
        }
        stamp = stampedLock.readLock();
        try {
            return balance;
        } finally {
            stampedLock.unlockRead(stamp);
        }
    }

    // Update balance (StampedLock)
    public void updateBalance(double delta) {
        long stamp = stampedLock.writeLock();
        try {
            balance += delta;
        } finally {
            stampedLock.unlockWrite(stamp);
        }
    }

    // Producer-consumer with Condition
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition condition = lock.newCondition();
    private boolean resourceAvailable = false;

    public void produceResource() throws InterruptedException {
        lock.lock();
        try {
            resourceAvailable = true;
            condition.signalAll();
        } finally {
            lock.unlock();
        }
    }

    public void consumeResource() throws InterruptedException {
        lock.lock();
        try {
            while (!resourceAvailable) {
                condition.await();
            }
            resourceAvailable = false;
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        ResourceManager manager = new ResourceManager();
        manager.putResource("key1", "value1");
        System.out.println("Resource: " + manager.getResource("key1")); // Output: value1

        manager.updateBalance(100.0);
        System.out.println("Balance: " + manager.getBalance()); // Output: 100.0

        new Thread(() -> {
            try {
                manager.produceResource();
            } catch (InterruptedException e) {}
        }).start();

        new Thread(() -> {
            try {
                manager.consumeResource();
                System.out.println("Resource consumed");
            } catch (InterruptedException e) {}
        }).start();
    }
}
```

- **Components**:
    - `ReentrantReadWriteLock`: Manages read/write access to a resource map.
    - `StampedLock`: Handles high-performance balance updates with optimistic reads.
    - `ReentrantLock` with `Condition`: Implements a producer-consumer pattern.
- **Use Case**: Thread-safe resource management in a microservice.

---

## Best Practices for Legendary Backend Developers

- **Choose the Right Lock**:
    - Use `ReentrantLock` for general-purpose locking with reentrancy or fairness.
    - Use `ReentrantReadWriteLock` for read-heavy scenarios with occasional writes.
    - Use `StampedLock` for high-performance, read-heavy systems with optimistic locking.
    - Use `Condition` for complex thread coordination (e.g., producer-consumer).
- **Minimize Lock Contention**:
    - Prefer `tryLock` or `tryLock(time, unit)` to avoid blocking indefinitely.
    - Use `StampedLock` for optimistic reads in read-heavy scenarios.
    - Enable fairness only when necessary (reduces throughput).
- **Ensure Proper Unlocking**:
    - Always release locks in a `finally` block to prevent deadlocks.
    - Example: `lock.lock(); try { ... } finally { lock.unlock(); }`
- **Handle Interruptions**:
    - Use `lockInterruptibly` for threads that need to respond to interruptions.
    - Catch `InterruptedException` and restore the interrupted state if needed.
- **Avoid Deadlocks**:
    - Acquire locks in a consistent order across threads.
    - Use `tryLock` to avoid indefinite waiting.
- **Performance Tuning**:
    - Benchmark `ReentrantLock` vs. `synchronized` for your use case.
    - Use `StampedLock` for read-heavy scenarios to reduce contention.
    - Avoid overusing fairness due to performance overhead.
- **Thread Safety**:
    - Combine locks with atomic variables or concurrent collections for complex state management.
    - Example: Use `ConcurrentHashMap` with `ReentrantLock` for mixed access patterns.
- **Debugging**:
    - Use `getQueueLength` or `getQueuedThreads` to monitor contention.
    - Log lock acquisition/release for tracing in production.

---

## Benefits

- **Flexibility**: More control than `synchronized` (e.g., try-locks, conditions).
- **Performance**: `ReadWriteLock` and `StampedLock` optimize read-heavy scenarios.
- **Scalability**: Fine-grained locking reduces contention in high-concurrency systems.
- **Coordination**: `Condition` supports complex thread interactions.

## Limitations

- **Complexity**: Requires manual lock management (vs. implicit `synchronized`).
- **Deadlock Risk**: Incorrect usage (e.g., forgetting `unlock`) can cause deadlocks.
- **Non-Reentrant StampedLock**: Requires careful handling to avoid errors.
- **Overhead**: Fairness and conditions add overhead compared to simple locks.

## Resources

- Java Locks Package: [java.util.concurrent.locks](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/locks/package-summary.html)
- Java Concurrency: [Java Concurrency in Practice](https://jcip.net/)
- StampedLock Guide: [Java 8 StampedLock](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/locks/StampedLock.html)

[[44 - Threads 🧀]]