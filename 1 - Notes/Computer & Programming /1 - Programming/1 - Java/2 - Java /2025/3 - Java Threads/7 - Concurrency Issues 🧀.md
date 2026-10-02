In the context of Java multithreading, **race conditions**, **deadlocks**, and other concurrency issues like **livelocks**, **starvation**, and **priority inversion** are critical problems that arise when multiple threads access shared resources without proper synchronization. Below, I’ll define each issue, explain their causes, provide examples, and discuss prevention strategies, tying them to Java’s thread lifecycle, synchronization, and locks.

---

### 1. Race Condition
**Definition**: A race condition occurs when multiple threads access and modify a shared resource concurrently, and the outcome depends on the unpredictable order of thread execution, leading to inconsistent or incorrect results.

> *Two thread load a resource at the same time , (same amount) then they do operation on that same value and set to new value , the problem is (EX : incrementing ) the both access to a value (Ex 4) then both get same value (Ex 4) then they do operation (Ex 4 ++) and both set the same value to the resource (EX 5) so we lose some values (Ex desired amount was 6 not 5)*

- **Cause**: Lack of proper synchronization when accessing shared resources (e.g., variables, objects).
- **Thread Lifecycle Impact**: Occurs in the **RUNNABLE** state when threads execute concurrently without coordination.
- **Example**:
  ```java
  public class Counter {
      private int count = 0;
      public void increment() {
          count++; // Not thread-safe: read-modify-write operation
      }
      public int getCount() {
          return count;
      }
  }
  ```
  If two threads call `increment()` simultaneously, they may read the same `count` value, increment it, and write back, resulting in lost updates (e.g., `count` increases by 1 instead of 2).

- **Prevention**:
  - Use **synchronized** methods or blocks:
    ```java
    public synchronized void increment() {
        count++;
    }
    ```
  - Use explicit locks (`ReentrantLock`):
    ```java
    private final ReentrantLock lock = new ReentrantLock();
    public void increment() {
        lock.lock();
        try {
            count++;
        } finally {
            lock.unlock();
        }
    }
    ```
  - Use atomic classes (e.g., `AtomicInteger`):
    ```java
    import java.util.concurrent.atomic.AtomicInteger;
    public class Counter {
        private AtomicInteger count = new AtomicInteger(0);
        public void increment() {
            count.incrementAndGet();
        }
    }
    ```
  - Use higher-level concurrent utilities like `ConcurrentHashMap` or `ExecutorService`.

---

### 2. Deadlock
**Definition**: A deadlock occurs when two or more threads are blocked forever, each waiting for a resource (e.g., lock) that another thread holds, creating a circular dependency.

- **Cause**: Improper lock acquisition order or nested locks without a consistent acquisition strategy.
- **Thread Lifecycle Impact**: Threads enter the **BLOCKED** state, waiting to acquire a lock, and remain stuck indefinitely.
- **Example**:
  ```java
  public class DeadlockDemo {
      private final Object lock1 = new Object();
      private final Object lock2 = new Object();
      public void method1() {
          synchronized(lock1) {
              try { Thread.sleep(100); } catch (InterruptedException e) {}
              synchronized(lock2) {
                  System.out.println("Method 1");
              }
          }
      }
      public void method2() {
          synchronized(lock2) {
              try { Thread.sleep(100); } catch (InterruptedException e) {}
              synchronized(lock1) {
                  System.out.println("Method 2");
              }
          }
      }
  }
  ```
  If Thread A calls `method1` (acquires `lock1`, waits for `lock2`) and Thread B calls `method2` (acquires `lock2`, waits for `lock1`), a deadlock occurs.

- **Prevention**:
  - **Consistent Lock Ordering**: Always acquire locks in the same order:
    ```java
    public void method1() {
        synchronized(lock1) {
            synchronized(lock2) {
                System.out.println("Method 1");
            }
        }
    }
    public void method2() {
        synchronized(lock1) { // Same order as method1
            synchronized(lock2) {
                System.out.println("Method 2");
            }
        }
    }
    ```
  - **Timeout with Locks**: Use `tryLock()` with `ReentrantLock` to avoid indefinite waiting:
    ```java
    import java.util.concurrent.locks.ReentrantLock;
    public class DeadlockAvoidance {
        private final ReentrantLock lock1 = new ReentrantLock();
        private final ReentrantLock lock2 = new ReentrantLock();
        public void method1() {
            if (lock1.tryLock()) {
                try {
                    if (lock2.tryLock()) {
                        try {
                            System.out.println("Method 1");
                        } finally {
                            lock2.unlock();
                        }
                    }
                } finally {
                    lock1.unlock();
                }
            }
        }
    }
    ```
  - **Avoid Nested Locks**: Minimize acquiring multiple locks when possible.
  - **Use Higher-Level Constructs**: Prefer `java.util.concurrent` utilities to reduce manual lock management.
  - **Deadlock Detection**: Use tools like JConsole or ThreadMXBean to detect deadlocks.
---

### *What is a Deadlock?*

*In programming (multithreading):*

- *A **deadlock** happens when two (or more) threads are waiting for each other’s resources, and none can continue.*
    
- *Result = they’re stuck forever.*
    

---

### *The 4 Goat Conditions for Deadlock 🐐 (must ALL happen)*

1. ***Mutual Exclusion***
    
    - *Only one goat can eat the hay (resource) at a time.*
        
2. ***Hold and Wait***
    
    - *A goat holds one haystack while waiting for another.*
        
3. ***No Preemption***
    
    - *You can’t snatch hay from another goat — must wait until it’s done.*
        
4. ***Circular Wait***
    
    - *Goat A waits for Goat B’s hay, Goat B waits for Goat A’s hay → infinite loop.*


---

### 3. Livelock
**Definition**: A livelock occurs when threads are unable to make progress because they continuously react to each other’s actions, often by releasing and reacquiring locks, without resolving the conflict.

- **Cause**: Threads attempt to resolve a conflict (e.g., by backing off and retrying) in a way that perpetuates the issue.
- **Thread Lifecycle Impact**: Threads remain in the **RUNNABLE** state, actively executing but not progressing.
- **Example**: Two threads try to acquire two locks but release their own lock and retry if they can’t get the second lock, repeating indefinitely:
  ```java
  public class LivelockDemo {
      private final ReentrantLock lock1 = new ReentrantLock();
      private final ReentrantLock lock2 = new ReentrantLock();
      public void method1() {
          while (true) {
              if (lock1.tryLock()) {
                  if (!lock2.tryLock()) {
                      lock1.unlock(); // Back off
                      continue;
                  }
                  try {
                      System.out.println("Method 1");
                  } finally {
                      lock2.unlock();
                      lock1.unlock();
                  }
                  break;
              }
          }
      }
      public void method2() {
          while (true) {
              if (lock2.tryLock()) {
                  if (!lock1.tryLock()) {
                      lock2.unlock(); // Back off
                      continue;
                  }
                  try {
                      System.out.println("Method 2");
                  } finally {
                      lock1.unlock();
                      lock2.unlock();
                  }
                  break;
              }
          }
      }
  }
  ```

- **Prevention**:
  - **Randomized Backoff**: Introduce randomness in retry logic to break cyclic patterns.
  - **Consistent Lock Ordering**: Similar to deadlock prevention, ensure a fixed lock acquisition order.
  - **Timeouts**: Use `tryLock(long time, TimeUnit unit)` to limit retry attempts.
  - **Simplify Logic**: Avoid complex retry mechanisms that lead to livelocks.

---

### 4. Starvation
**Definition**: Starvation occurs when a thread is perpetually denied access to a shared resource or CPU time due to higher-priority threads or unfair lock scheduling.

- **Cause**: Threads with lower priority or unfair lock policies (e.g., non-fair `ReentrantLock`) prevent a thread from progressing.
- **Thread Lifecycle Impact**: The thread remains in **RUNNABLE** or **BLOCKED**, unable to execute its critical section.
- **Example**: A low-priority thread tries to acquire a lock but is constantly preempted by higher-priority threads.

- **Prevention**:
  - **Fair Locks**: Use `ReentrantLock(true)` to enforce fair (FIFO) lock acquisition:
    ```java
    private final ReentrantLock fairLock = new ReentrantLock(true);
    ```
  - **Adjust Thread Priorities**: Use `Thread.setPriority()` cautiously, ensuring no thread is perpetually ignored (note: priorities are platform-dependent).
  - **Use Concurrent Utilities**: Structures like `ConcurrentHashMap` or `ExecutorService` manage fairness internally.
  - **Monitor Thread Behavior**: Use profiling tools to detect starved threads.

---

### 5. Priority Inversion
**Definition**: Priority inversion occurs when a low-priority thread holding a resource prevents a higher-priority thread from executing, effectively inverting their priorities.

- **Cause**: A low-priority thread holds a lock needed by a high-priority thread, and an intermediate-priority thread preempts the low-priority thread.
- **Thread Lifecycle Impact**: The high-priority thread is **BLOCKED**, waiting for the low-priority thread to release the lock.
- **Example**: Thread A (low priority) holds a lock, Thread C (high priority) waits for it, but Thread B (medium priority) keeps running, delaying Thread A.

- **Prevention**:
  - **Priority Inheritance**: Use locks that support priority inheritance (not directly supported in Java but can be approximated with fair locks).
  - **Avoid Long-Lived Locks**: Minimize the time a low-priority thread holds a lock.
  - **Use Fair Locks**: `ReentrantLock(true)` ensures FIFO scheduling, reducing inversion risks.
  - **Minimize Priority Differences**: Avoid relying heavily on thread priorities.

---

### Other Concurrency Issues
- **Data Corruption**: Occurs due to race conditions when threads overwrite shared data inconsistently. Prevent with synchronization, locks, or atomic operations.
- **Thread Interference**: Similar to race conditions, where interleaved thread execution leads to incorrect results. Prevent with proper synchronization.
- **Memory Consistency Errors**: Threads see stale or inconsistent values of shared variables due to caching or reordering. Prevent using `volatile`, synchronized blocks, or atomic classes.
- **Over-Synchronization**: Excessive use of locks can reduce performance and scalability. Use fine-grained locks or lock-free data structures (e.g., `ConcurrentLinkedQueue`).

---

### Thread Lifecycle Context
- **Race Condition**: Occurs in **RUNNABLE** when threads access shared resources without synchronization.
- **Deadlock**: Threads stuck in **BLOCKED**, waiting for locks in a circular dependency.
- **Livelock**: Threads in **RUNNABLE**, actively retrying but not progressing.
- **Starvation**: Threads in **RUNNABLE** or **BLOCKED**, unable to acquire resources due to contention.
- **Priority Inversion**: High-priority thread in **BLOCKED**, waiting for a low-priority thread in **RUNNABLE** or **BLOCKED**.

---

### Prevention Summary
1. **Use Synchronization Wisely**:
   - Synchronized methods/blocks for simple cases.
   - Explicit locks (`ReentrantLock`, `ReadWriteLock`) for complex scenarios.
2. **Leverage Atomic Classes**: Use `java.util.concurrent.atomic` (e.g., `AtomicInteger`) for lock-free operations.
3. **Adopt Concurrent Utilities**: Use `ConcurrentHashMap`, `CopyOnWriteArrayList`, or `ExecutorService` to avoid manual synchronization.
4. **Ensure Lock Ordering**: Prevent deadlocks and livelocks with consistent lock acquisition.
5. **Monitor and Debug**: Use tools like JVisualVM, JConsole, or ThreadMXBean to detect concurrency issues.
6. **Test Thoroughly**: Simulate high-contention scenarios to uncover race conditions or deadlocks.

---

### Example: Avoiding Common Issues
```java
import java.util.concurrent.locks.ReentrantLock;
public class SafeCounter {
    private int count = 0;
    private final ReentrantLock lock = new ReentrantLock(true); // Fair lock
    public void increment() {
        if (lock.tryLock()) { // Avoid deadlock with tryLock
            try {
                count++; // Synchronized access
            } finally {
                lock.unlock();
            }
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
}
```
This example uses a fair `ReentrantLock` with `tryLock` to prevent deadlocks and ensure thread-safe increments.

---

### Summary
- **Race Conditions**: Prevent with synchronization, locks, or atomic operations.
- **Deadlocks**: Avoid with consistent lock ordering, timeouts, or higher-level constructs.
- **Livelocks**: Use randomized backoff or fixed lock ordering.
- **Starvation**: Use fair locks or balanced thread priorities.
- **Priority Inversion**: Minimize lock duration and avoid heavy reliance on priorities.
By understanding these issues and applying proper synchronization/lock strategies, you can write robust, thread-safe Java applications.



#### Notes : 
In Java, a **`synchronized` block** ensures that **only one thread at a time** can execute the code inside it for the given lock object.

Example:

```java
 synchronized (lock1) {     // critical section }
```

### What happens:

1. The thread tries to **acquire the monitor lock** of `lock1`.
    
2. If no other thread holds it → it enters the block.
    
3. If another thread already holds it → it **waits (blocks)** until the lock is released.
    
4. When the thread exits the block, it **releases the lock**, allowing others to enter.
    

### Why it matters:

- Prevents **race conditions** (two threads changing shared data at the same time).
    
- But if two threads each hold one lock and wait for the other → you get a **deadlock** (like in my example).

[[44 - Threads 🧀]]