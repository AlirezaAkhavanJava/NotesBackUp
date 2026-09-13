

The `java.util.concurrent` package provides advanced synchronization mechanisms for coordinating threads in multi-threaded applications, such as web servers or microservices. This document covers `ReentrantReadWriteLock` for read-heavy scenarios, `Semaphore`, `CountDownLatch`, `CyclicBarrier`, `Phaser` for thread coordination, and `Exchanger` for data exchange between threads, with concise explanations and practical examples.

---

## 1. ReentrantReadWriteLock

### Overview

- **Purpose**: A lock that separates read and write operations, allowing multiple threads to read concurrently but ensuring exclusive write access.
- **Key Features**:
    - **Read Lock**: Multiple threads can acquire for concurrent reads.
    - **Write Lock**: Exclusive, blocks all other read/write locks.
    - **Reentrant**: Threads can reacquire locks (read or write) without deadlocking.
- **Use Case**: Read-heavy scenarios (e.g., caching, shared configuration).

### Key Methods

- `ReentrantReadWriteLock()`: Creates a read-write lock.
- `Lock readLock()`: Returns the read lock.
- `Lock writeLock()`: Returns the write lock.
- `lock()`/`unlock()`: Acquires/releases the read or write lock.

### Example

```java
import java.util.concurrent.locks.*;

public class ReadWriteLockExample {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private int data = 0;

    public int readData() {
        rwLock.readLock().lock();
        try {
            return data;
        } finally {
            rwLock.readLock().unlock();
        }
    }

    public void writeData(int value) {
        rwLock.writeLock().lock();
        try {
            data = value;
        } finally {
            rwLock.writeLock().unlock();
        }
    }

    public static void main(String[] args) {
        ReadWriteLockExample example = new ReadWriteLockExample();
        Runnable reader = () -> {
            System.out.println(Thread.currentThread().getName() + " read: " + example.readData());
        };
        Runnable writer = () -> {
            example.writeData(42);
            System.out.println(Thread.currentThread().getName() + " wrote: 42");
        };

        Thread t1 = new Thread(reader);
        Thread t2 = new Thread(reader);
        Thread t3 = new Thread(writer);
        t1.start();
        t2.start();
        t3.start();
    }
}
```

- **Use Case**: Thread-safe cache with frequent reads and occasional writes.

### Where to Use

- Read-heavy systems where concurrent reads improve performance.
- Example: Shared configuration in a microservice.

---

## 2. Semaphore

### Overview

- **Purpose**: Controls access to a shared resource by limiting the number of concurrent threads.
- **Key Features**:
    - Maintains a count of permits.
    - Threads acquire permits to access resources; block if none available.
    - Supports fairness (FIFO) option.

### Key Methods

- `Semaphore(int permits)`: Creates a semaphore with a specified number of permits.
- `void acquire()`: Acquires a permit, blocking if none available.
- `void release()`: Releases a permit.
- `boolean tryAcquire()`: Non-blocking permit acquisition.
- `int availablePermits()`: Returns current available permits.

### Example

```java
import java.util.concurrent.*;

public class SemaphoreExample {
    private final Semaphore semaphore = new Semaphore(2); // 2 concurrent threads

    public void accessResource() {
        try {
            semaphore.acquire();
            System.out.println(Thread.currentThread().getName() + " accessing resource");
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            semaphore.release();
        }
    }

    public static void main(String[] args) {
        SemaphoreExample example = new SemaphoreExample();
        Runnable task = example::accessResource;
        for (int i = 0; i < 5; i++) {
            new Thread(task).start();
        }
    }
}
```

- **Use Case**: Limiting database connections in a server.

### Where to Use

- Limiting concurrent access to resources (e.g., connection pools).
- Example: Restricting API request handlers.

---

## 3. CountDownLatch

### Overview

- **Purpose**: Allows threads to wait until a set of operations (count) completes.
- **Key Features**:
    - Initializes with a count.
    - Threads wait until count reaches zero.
    - Non-reusable (one-time use).

### Key Methods

- `CountDownLatch(int count)`: Creates a latch with a specified count.
- `void countDown()`: Decrements the count.
- `void await()`: Blocks until count reaches zero.
- `boolean await(long timeout, TimeUnit unit)`: Waits with a timeout.

### Example

```java
import java.util.concurrent.*;

public class CountDownLatchExample {
    private final CountDownLatch latch = new CountDownLatch(3);

    public void task() {
        try {
            System.out.println(Thread.currentThread().getName() + " working");
            Thread.sleep(1000);
            latch.countDown();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public void waitForTasks() {
        try {
            latch.await();
            System.out.println("All tasks completed");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        CountDownLatchExample example = new CountDownLatchExample();
        for (int i = 0; i < 3; i++) {
            new Thread(example::task).start();
        }
        example.waitForTasks();
    }
}
```

- **Use Case**: Waiting for initialization tasks in a server startup.

### Where to Use

- Synchronizing threads waiting for multiple tasks to complete.
- Example: Waiting for services to initialize before starting a microservice.

---

## 4. CyclicBarrier

### Overview

- **Purpose**: Allows a set of threads to wait until all reach a common barrier point before proceeding.
- **Key Features**:
    - Reusable (unlike `CountDownLatch`).
    - Optional barrier action executed when all threads reach the barrier.

### Key Methods

- `CyclicBarrier(int parties)`: Creates a barrier for a specified number of threads.
- `CyclicBarrier(int parties, Runnable barrierAction)`: Includes a barrier action.
- `int await()`: Waits until all parties reach the barrier.
- `int await(long timeout, TimeUnit unit)`: Waits with a timeout.
- `void reset()`: Resets the barrier.

### Example

```java
import java.util.concurrent.*;

public class CyclicBarrierExample {
    private final CyclicBarrier barrier = new CyclicBarrier(3, () -> System.out.println("Barrier reached, proceeding"));

    public void task() {
        try {
            System.out.println(Thread.currentThread().getName() + " preparing");
            Thread.sleep(1000);
            barrier.await();
            System.out.println(Thread.currentThread().getName() + " proceeding");
        } catch (InterruptedException | BrokenBarrierException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        CyclicBarrierExample example = new CyclicBarrierExample();
        for (int i = 0; i < 3; i++) {
            new Thread(example::task).start();
        }
    }
}
```

- **Use Case**: Coordinating parallel tasks that must sync at a point (e.g., batch processing).

### Where to Use

- Synchronizing threads at a common point for repeated cycles.
- Example: Parallel data processing with synchronization points.

---

## 5. Phaser

### Overview

- **Purpose**: A flexible, reusable barrier for dynamic thread coordination, supporting multiple phases.
- **Key Features**:
    - Supports dynamic addition/removal of threads.
    - Handles multiple phases of synchronization.
    - More flexible than `CyclicBarrier`.

### Key Methods

- `Phaser()`: Creates a phaser with zero registered parties.
- `int register()`: Registers a new party.
- `int arriveAndAwaitAdvance()`: Signals arrival and waits for others.
- `int arriveAndDeregister()`: Signals arrival and removes the party.
- `boolean isTerminated()`: Checks if the phaser is terminated.

### Example

```java
import java.util.concurrent.*;

public class PhaserExample {
    private final Phaser phaser = new Phaser(1); // Main thread registered

    public void task() {
        phaser.register();
        try {
            System.out.println(Thread.currentThread().getName() + " starting phase 0");
            Thread.sleep(1000);
            phaser.arriveAndAwaitAdvance(); // Phase 0 complete
            System.out.println(Thread.currentThread().getName() + " starting phase 1");
            Thread.sleep(1000);
            phaser.arriveAndDeregister(); // Phase 1 complete, deregister
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        PhaserExample example = new PhaserExample();
        for (int i = 0; i < 2; i++) {
            new Thread(example::task).start();
        }
        example.phaser.arriveAndAwaitAdvance(); // Main thread for phase 0
        System.out.println("Phase 0 complete");
        example.phaser.arriveAndAwaitAdvance(); // Main thread for phase 1
        System.out.println("Phase 1 complete");
    }
}
```

- **Use Case**: Multi-phase task coordination (e.g., iterative data processing).

### Where to Use

- Dynamic thread coordination with varying numbers of threads.
- Example: Phased simulations or workflows in a distributed system.

---

## 6. Exchanger

### Overview

- **Purpose**: Allows two threads to exchange objects at a synchronization point.
- **Key Features**:
    - Simple, two-thread data exchange.
    - Blocks until both threads reach the exchange point.

### Key Methods

- `Exchanger()`: Creates an exchanger.
- `V exchange(V x)`: Exchanges an object with another thread, blocking until the exchange occurs.
- `V exchange(V x, long timeout, TimeUnit unit)`: Exchanges with a timeout.

### Example

```java
import java.util.concurrent.*;

public class ExchangerExample {
    private final Exchanger<String> exchanger = new Exchanger<>();

    public void producer() {
        try {
            String data = "Data from Producer";
            String received = exchanger.exchange(data);
            System.out.println("Producer received: " + received);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public void consumer() {
        try {
            String data = "Data from Consumer";
            String received = exchanger.exchange(data);
            System.out.println("Consumer received: " + received);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public static void main(String[] args) {
        ExchangerExample example = new ExchangerExample();
        new Thread(example::producer).start();
        new Thread(example::consumer).start();
    }
}
```

- **Use Case**: Exchanging data between two threads (e.g., producer-consumer handoff).

### Where to Use

- Pairwise data exchange between threads.
- Example: Data transfer in a pipeline processing system.

---

## Best Practices

- **Use ReentrantReadWriteLock for Read-Heavy Scenarios**:
    - Prefer over `ReentrantLock` when reads outnumber writes.
    - Example: `rwLock.readLock().lock()` for concurrent reads.
- **Use Semaphore for Resource Limiting**:
    - Limit concurrent access to fixed resources (e.g., database connections).
    - Example: `Semaphore(10)` for 10 concurrent connections.
- **Use CountDownLatch for One-Time Coordination**:
    - Wait for multiple tasks to complete once.
    - Example: `CountDownLatch(3)` for 3 initialization tasks.
- **Use CyclicBarrier for Repeated Synchronization**:
    - Coordinate threads at fixed points in cycles.
    - Example: `CyclicBarrier(3)` for parallel processing rounds.
- **Use Phaser for Dynamic Phases**:
    - Handle varying thread counts or multi-phase tasks.
    - Example: `phaser.register()` for dynamic thread addition.
- **Use Exchanger for Simple Data Handoff**:
    - Exchange data between exactly two threads.
    - Example: `exchanger.exchange(data)` for producer-consumer.
- **Handle Interruptions**:
    - Catch `InterruptedException` and restore interrupted status.
    - Example: `catch (InterruptedException e) { Thread.currentThread().interrupt(); }`
- **Avoid Overuse of Locks**:
    - Prefer `java.util.concurrent` collections (`ConcurrentHashMap`) for thread-safe data access.

---

## Pros and Cons

### Pros

- **ReentrantReadWriteLock**: High concurrency for read-heavy workloads.
- **Semaphore**: Simple resource limiting without complex locking.
- **CountDownLatch**: Easy one-time task coordination.
- **CyclicBarrier**: Reusable for repeated synchronization points.
- **Phaser**: Flexible for dynamic thread counts and phases.
- **Exchanger**: Efficient for pairwise data exchange.

### Cons

- **ReentrantReadWriteLock**: More complex than `synchronized`; requires manual unlocking.
- **Semaphore**: Can lead to starvation if not fair.
- **CountDownLatch**: Non-reusable; requires new instances for repeated use.
- **CyclicBarrier**: Fixed thread count; less flexible than `Phaser`.
- **Phaser**: Complex API for simple use cases.
- **Exchanger**: Limited to two threads; blocking nature can cause delays.

---

## Practical Example: Coordinated Task System

```java
import java.util.concurrent.*;
import java.util.*;

public class CoordinatedTaskSystem {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private final Semaphore semaphore = new Semaphore(2);
    private final CountDownLatch latch = new CountDownLatch(2);
    private final CyclicBarrier barrier = new CyclicBarrier(2);
    private final Phaser phaser = new Phaser(1);
    private final Exchanger<String> exchanger = new Exchanger<>();
    private final List<Integer> results = new ArrayList<>();

    public void processTask(int taskId) {
        try {
            semaphore.acquire();
            phaser.register();
            System.out.println("Task " + taskId + " acquired semaphore");

            // Phase 1: Process
            rwLock.writeLock().lock();
            try {
                results.add(taskId);
                System.out.println("Task " + taskId + " added result");
            } finally {
                rwLock.writeLock().unlock();
            }
            barrier.await();

            // Phase 2: Exchange data
            String data = exchanger.exchange("Task " + taskId + " data");
            System.out.println("Task " + taskId + " received: " + data);

            latch.countDown();
            phaser.arriveAndDeregister();
        } catch (InterruptedException | BrokenBarrierException e) {
            Thread.currentThread().interrupt();
        } finally {
            semaphore.release();
        }
    }

    public void waitForCompletion() throws InterruptedException {
        latch.await();
        phaser.arriveAndAwaitAdvance();
        rwLock.readLock().lock();
        try {
            System.out.println("Results: " + results);
        } finally {
            rwLock.readLock().unlock();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        CoordinatedTaskSystem system = new CoordinatedTaskSystem();
        new Thread(() -> system.processTask(1)).start();
        new Thread(() -> system.processTask(2)).start();
        system.waitForCompletion();
    }
}
```

- **Components**:
    - `ReentrantReadWriteLock`: Thread-safe result list updates.
    - `Semaphore`: Limits concurrent tasks to 2.
    - `CountDownLatch`: Waits for tasks to complete.
    - `CyclicBarrier`: Synchronizes tasks at a barrier.
    - `Phaser`: Manages phased execution.
    - `Exchanger`: Exchanges data between tasks.
- **Use Case**: Coordinated task processing in a microservice.

---

## Resources

- ReentrantReadWriteLock: [ReentrantReadWriteLock API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/locks/ReentrantReadWriteLock.html)
- Semaphore: [Semaphore API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Semaphore.html)
- CountDownLatch: [CountDownLatch API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CountDownLatch.html)
- CyclicBarrier: [CyclicBarrier API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CyclicBarrier.html)
- Phaser: [Phaser API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Phaser.html)
- Exchanger: [Exchanger API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Exchanger.html)


[[44 - Threads 🧀]]