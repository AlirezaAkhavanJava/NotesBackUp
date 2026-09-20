# Common Concurrency Issues in Java: Race Conditions, Deadlocks, Livelocks, and Starvation

Concurrency issues like **race conditions**, **deadlocks**, **livelocks**, and **starvation** can cause significant problems in multi-threaded Java applications, such as web servers or microservices. Identifying and debugging these issues is critical for ensuring reliability and performance. This document explains these issues, how to identify and debug them using tools like `jstack`, and provides practical examples with solutions.

---

## 1. Race Conditions

### Definition

- A **race condition** occurs when multiple threads access shared resources concurrently, and at least one thread modifies the resource, leading to unpredictable outcomes.
- **Cause**: Lack of proper synchronization (e.g., missing `synchronized` or locks).

### Symptoms

- Inconsistent or incorrect data (e.g., wrong counter values).
- Unexpected application behavior under concurrent load.

### Example

```java
public class RaceConditionExample {
    private int counter = 0;

    public void increment() {
        counter++; // Non-atomic: read, increment, write
    }

    public int getCounter() {
        return counter;
    }

    public static void main(String[] args) throws InterruptedException {
        RaceConditionExample example = new RaceConditionExample();
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
        System.out.println("Counter: " + example.getCounter()); // Expected: 2000, Actual: <= 2000
    }
}
```

- **Issue**: `counter++` is not atomic, causing lost updates due to concurrent modifications.

### Debugging with jstack

- **Steps**:
    1. Run the program and note inconsistent outputs.
    2. Use `jstack <pid>` to capture thread dumps (find PID with `jps` or `ps`).
    3. Look for threads in `RUNNABLE` state accessing the same resource without synchronization.
- **Indicators**: No direct indication in `jstack`, but inconsistent results suggest race conditions.

### Solution

- Use `synchronized`, `ReentrantLock`, or `AtomicInteger` for atomic updates.

```java
import java.util.concurrent.atomic.AtomicInteger;

public class FixedRaceCondition {
    private final AtomicInteger counter = new AtomicInteger(0);

    public void increment() {
        counter.incrementAndGet();
    }

    public int getCounter() {
        return counter.get();
    }

    public static void main(String[] args) throws InterruptedException {
        FixedRaceCondition example = new FixedRaceCondition();
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
        System.out.println("Counter: " + example.getCounter()); // Output: 2000
    }
}
```

### Where It Occurs

- Shared counters, collections, or state variables without synchronization.
- Example: Tracking API requests in a web server.

---

## 2. Deadlocks

### Definition

- A **deadlock** occurs when two or more threads are blocked forever, each waiting for a lock held by another.
- **Cause**: Circular dependency on locks (e.g., Thread A holds Lock 1 and waits for Lock 2, while Thread B holds Lock 2 and waits for Lock 1).

### Symptoms

- Application freezes or stops processing.
- Threads are stuck in `BLOCKED` or `WAITING` state.

### Example

```java
public class DeadlockExample {
    private final Object lock1 = new Object();
    private final Object lock2 = new Object();

    public void method1() {
        synchronized (lock1) {
            try { Thread.sleep(100); } catch (InterruptedException e) {}
            synchronized (lock2) {
                System.out.println("Method1 acquired both locks");
            }
        }
    }

    public void method2() {
        synchronized (lock2) {
            try { Thread.sleep(100); } catch (InterruptedException e) {}
            synchronized (lock1) {
                System.out.println("Method2 acquired both locks");
            }
        }
    }

    public static void main(String[] args) {
        DeadlockExample example = new DeadlockExample();
        Thread t1 = new Thread(example::method1);
        Thread t2 = new Thread(example::method2);
        t1.start();
        t2.start();
    }
}
```

- **Issue**: Thread 1 holds `lock1` and waits for `lock2`, while Thread 2 holds `lock2` and waits for `lock1`, causing a deadlock.

### Debugging with jstack

- **Steps**:
    1. Run `jps` to find the process ID (PID).
    2. Run `jstack <pid>` to generate a thread dump.
    3. Look for threads in `BLOCKED` state with a "waiting to lock" message, indicating a circular dependency.
- **Sample Output**:
    
    ```
    "Thread-1" #12 prio=5 os_prio=0 tid=0x... nid=0x... waiting for monitor entry [0x...]
       java.lang.Thread.State: BLOCKED (on object monitor)
          at DeadlockExample.method1(DeadlockExample.java:...)
          - waiting to lock <0x...> (a java.lang.Object)
          - locked <0x...> (a java.lang.Object)
    ```
    
    - Indicates Thread 1 is waiting for `lock2` while holding `lock1`.

### Solution

- **Consistent Lock Ordering**: Acquire locks in the same order across threads.
- **Timeouts**: Use `ReentrantLock.tryLock()` with timeouts to avoid indefinite waiting.

```java
public class FixedDeadlock {
    private final Object lock1 = new Object();
    private final Object lock2 = new Object();

    public void method1() {
        synchronized (lock1) {
            try { Thread.sleep(100); } catch (InterruptedException e) {}
            synchronized (lock2) {
                System.out.println("Method1 acquired both locks");
            }
        }
    }

    public void method2() {
        synchronized (lock1) { // Same order as method1
            try { Thread.sleep(100); } catch (InterruptedException e) {}
            synchronized (lock2) {
                System.out.println("Method2 acquired both locks");
            }
        }
    }

    public static void main(String[] args) {
        FixedDeadlock example = new FixedDeadlock();
        Thread t1 = new Thread(example::method1);
        Thread t2 = new Thread(example::method2);
        t1.start();
        t2.start();
    }
}
```

### Where It Occurs

- Nested `synchronized` blocks or locks with inconsistent ordering.
- Example: Resource allocation in a distributed system.

---

## 3. Livelocks

### Definition

- A **livelock** occurs when threads are actively running but unable to make progress due to repeatedly reacting to each other’s actions.
- **Cause**: Threads keep retrying or yielding in response to each other without resolving the conflict.

### Symptoms

- High CPU usage with no progress.
- Threads in `RUNNABLE` state but application stalls.

### Example

```java
public class LivelockExample {
    private boolean resource1Available = false;
    private boolean resource2Available = false;

    public void process1() {
        while (true) {
            if (!resource1Available) {
                System.out.println("Process1 waiting for resource1");
                try { Thread.sleep(100); } catch (InterruptedException e) {}
                resource2Available = true; // Yield resource2
                continue;
            }
            if (!resource2Available) {
                System.out.println("Process1 waiting for resource2");
                resource1Available = false; // Yield resource1
                continue;
            }
            System.out.println("Process1 completed");
            break;
        }
    }

    public void process2() {
        while (true) {
            if (!resource2Available) {
                System.out.println("Process2 waiting for resource2");
                try { Thread.sleep(100); } catch (InterruptedException e) {}
                resource1Available = true; // Yield resource1
                continue;
            }
            if (!resource1Available) {
                System.out.println("Process2 waiting for resource1");
                resource2Available = false; // Yield resource2
                continue;
            }
            System.out.println("Process2 completed");
            break;
        }
    }

    public static void main(String[] args) {
        LivelockExample example = new LivelockExample();
        Thread t1 = new Thread(example::process1);
        Thread t2 = new Thread(example::process2);
        t1.start();
        t2.start();
    }
}
```

- **Issue**: Both threads keep yielding resources to each other, preventing progress.

### Debugging with jstack

- **Steps**:
    1. Use `jstack <pid>` to capture thread dumps.
    2. Look for threads in `RUNNABLE` state with repetitive actions (e.g., looping without progress).
    3. Check logs for repeated patterns (e.g., "waiting for resource").
- **Indicators**: High CPU usage and threads in `RUNNABLE` state without completion.

### Solution

- **Random Backoff**: Introduce random delays to break the cycle.
- **Priority or Ordering**: Assign priorities or enforce a fixed order for resource acquisition.

```java
import java.util.Random;

public class FixedLivelock {
    private boolean resource1Available = false;
    private boolean resource2Available = false;
    private final Random random = new Random();

    public void process1() {
        while (true) {
            if (!resource1Available) {
                System.out.println("Process1 waiting for resource1");
                try { Thread.sleep(100 + random.nextInt(50)); } catch (InterruptedException e) {}
                resource2Available = true;
                continue;
            }
            if (!resource2Available) {
                System.out.println("Process1 waiting for resource2");
                resource1Available = false;
                continue;
            }
            System.out.println("Process1 completed");
            break;
        }
    }

    public void process2() {
        while (true) {
            if (!resource2Available) {
                System.out.println("Process2 waiting for resource2");
                try { Thread.sleep(100 + random.nextInt(50)); } catch (InterruptedException e) {}
                resource1Available = true;
                continue;
            }
            if (!resource1Available) {
                System.out.println("Process2 waiting for resource1");
                resource2Available = false;
                continue;
            }
            System.out.println("Process2 completed");
            break;
        }
    }

    public static void main(String[] args) {
        FixedLivelock example = new FixedLivelock();
        Thread t1 = new Thread(example::process1);
        Thread t2 = new Thread(example::process2);
        t1.start();
        t2.start();
    }
}
```

### Where It Occurs

- Polite resource allocation (e.g., threads yielding resources to each other).
- Example: Conflict resolution in distributed systems.

---

## 4. Starvation

### Definition

- **Starvation** occurs when a thread is unable to access a shared resource due to other threads monopolizing it.
- **Cause**: Unfair lock acquisition (e.g., non-fair locks) or high-priority threads dominating.

### Symptoms

- Some threads never make progress.
- Uneven task completion rates.

### Example

```java
import java.util.concurrent.locks.ReentrantLock;

public class StarvationExample {
    private final ReentrantLock lock = new ReentrantLock(false); // Non-fair lock

    public void task() {
        lock.lock();
        try {
            System.out.println(Thread.currentThread().getName() + " acquired lock");
            try { Thread.sleep(100); } catch (InterruptedException e) {}
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) {
        StarvationExample example = new StarvationExample();
        Runnable task = () -> {
            for (int i = 0; i < 10; i++) {
                example.task();
            }
        };

        Thread t1 = new Thread(task, "HighPriority");
        Thread t2 = new Thread(task, "LowPriority");
        t1.setPriority(Thread.MAX_PRIORITY);
        t2.setPriority(Thread.MIN_PRIORITY);
        t1.start();
        t2.start();
    }
}
```

- **Issue**: `LowPriority` thread may rarely acquire the lock due to `HighPriority` thread dominating.

### Debugging with jstack

- **Steps**:
    1. Run `jstack <pid>` to capture thread dumps.
    2. Look for threads in `WAITING` or `BLOCKED` state for extended periods.
    3. Check if some threads are consistently unable to acquire locks.
- **Indicators**: One thread in `RUNNABLE` state while others remain in `WAITING`.

### Solution

- **Fair Locks**: Use `ReentrantLock(true)` for FIFO lock acquisition.
- **Thread Pool**: Use `ExecutorService` to balance task execution.

```java
import java.util.concurrent.locks.ReentrantLock;

public class FixedStarvation {
    private final ReentrantLock lock = new ReentrantLock(true); // Fair lock

    public void task() {
        lock.lock();
        try {
            System.out.println(Thread.currentThread().getName() + " acquired lock");
            try { Thread.sleep(100); } catch (InterruptedException e) {}
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) {
        FixedStarvation example = new FixedStarvation();
        Runnable task = () -> {
            for (int i = 0; i < 10; i++) {
                example.task();
            }
        };

        Thread t1 = new Thread(task, "HighPriority");
        Thread t2 = new Thread(task, "LowPriority");
        t1.setPriority(Thread.MAX_PRIORITY);
        t2.setPriority(Thread.MIN_PRIORITY);
        t1.start();
        t2.start();
    }
}
```

### Where It Occurs

- Non-fair locks or thread pools with uneven priorities.
- Example: Resource-intensive threads in a server starving others.

---

## Debugging with jstack

### Steps to Use jstack

1. **Find PID**:
    - Run `jps` to list Java processes and their PIDs.
    - Alternatively, use `ps aux | grep java` on Unix-like systems.
2. **Capture Thread Dump**:
    - Run `jstack <pid>` to generate a thread dump.
    - Save output to a file: `jstack <pid> > dump.txt`.
3. **Analyze Dump**:
    - Look for thread states: `RUNNABLE`, `BLOCKED`, `WAITING`, `TIMED_WAITING`.
    - Identify locks held (`locked <0x...>`) and waited for (`waiting to lock <0x...>`).
    - Check for circular dependencies (deadlocks) or prolonged `WAITING` (starvation).
4. **Repeat Dumps**:
    - Take multiple dumps (e.g., every 5 seconds) to identify patterns (e.g., livelock cycles).
    - Example: `while true; do jstack <pid> >> dump.txt; sleep 5; done`

### Sample Thread Dump (Deadlock)

```
"Thread-1" #12 prio=5 os_prio=0 tid=0x... nid=0x... waiting for monitor entry [0x...]
   java.lang.Thread.State: BLOCKED (on object monitor)
      at DeadlockExample.method1(DeadlockExample.java:...)
      - waiting to lock <0x...> (a java.lang.Object)
      - locked <0x...> (a java.lang.Object)

"Thread-2" #13 prio=5 os_prio=0 tid=0x... nid=0x... waiting for monitor entry [0x...]
   java.lang.Thread.State: BLOCKED (on object monitor)
      at DeadlockExample.method2(DeadlockExample.java:...)
      - waiting to lock <0x...> (a java.lang.Object)
      - locked <0x...> (a java.lang.Object)
```

### Other Tools

- **JVisualVM**: Monitor threads and detect deadlocks visually.
- **ThreadMXBean**: Programmatically detect deadlocks with `ManagementFactory.getThreadMXBean().findDeadlockedThreads()`.
- **Profilers**: Use tools like YourKit or VisualVM to analyze contention and performance.

---

## Best Practices

- **Avoid Race Conditions**:
    - Use `synchronized`, `ReentrantLock`, or `java.util.concurrent` collections (`ConcurrentHashMap`, `AtomicInteger`).
    - Example: Replace `int counter` with `AtomicInteger`.
- **Prevent Deadlocks**:
    - Enforce consistent lock ordering.
    - Use `tryLock()` with timeouts to avoid indefinite waiting.
- **Mitigate Livelocks**:
    - Introduce random delays or priorities to break cycles.
    - Example: `Thread.sleep(random.nextInt(50))`.
- **Avoid Starvation**:
    - Use fair locks (`ReentrantLock(true)`) or thread pools with balanced scheduling.
    - Avoid excessive thread priorities.
- **Use Thread-Safe Collections**:
    - Prefer `ConcurrentHashMap`, `CopyOnWriteArrayList`, or `BlockingQueue` over `Collections.synchronizedXXX`.
- **Monitor and Debug**:
    - Regularly capture thread dumps with `jstack` during testing.
    - Use logging to track lock acquisition and release.
- **Test Under Load**:
    - Simulate high concurrency to expose race conditions, deadlocks, or starvation.
    - Example: Use JMeter for load testing a web server.
- **Use Modern Concurrency**:
    - Leverage `ExecutorService`, `CompletableFuture`, or `ForkJoinPool` for managed concurrency.

---

## Practical Example: Thread-Safe Task Processor

```java
import java.util.concurrent.*;
import java.util.concurrent.locks.ReentrantLock;

public class TaskProcessor {
    private final ConcurrentHashMap<String, Integer> results = new ConcurrentHashMap<>();
    private final ReentrantLock lock = new ReentrantLock(true); // Fair lock
    private final ExecutorService executor = Executors.newFixedThreadPool(2);
    private volatile boolean running = true;

    public void processTask(String task) {
        lock.lock();
        try {
            results.compute(task, (k, v) -> v == null ? 1 : v + 1);
            System.out.println(Thread.currentThread().getName() + " processed " + task);
        } finally {
            lock.unlock();
        }
    }

    public void start() {
        executor.submit(() -> {
            while (running) {
                try {
                    processTask("Task-" + System.currentTimeMillis());
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        });
    }

    public void shutdown() throws InterruptedException {
        running = false;
        executor.shutdownNow();
        executor.awaitTermination(5, TimeUnit.SECONDS);
        System.out.println("Results: " + results);
    }

    public static void main(String[] args) throws InterruptedException {
        TaskProcessor processor = new TaskProcessor();
        processor.start();
        Thread.sleep(2000);
        processor.shutdown();
    }
}
```

- **Components**:
    - `ConcurrentHashMap`: Avoids race conditions for task results.
    - `ReentrantLock(true)`: Fair lock to prevent starvation.
    - `volatile boolean`: Ensures visibility of shutdown signal.
    - `ExecutorService`: Manages threads, prevents deadlocks/livelocks.
- **Use Case**: Processing tasks in a microservice with thread safety.

---

## Resources

- Java Concurrency: [java.util.concurrent](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/package-summary.html)
- jstack: [jstack Documentation](https://docs.oracle.com/en/java/javase/17/docs/specs/man/jstack.html)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)


[[44 - Threads 🧀]]