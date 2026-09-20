In Java, **synchronization** and **locks** are mechanisms to manage concurrent access to shared resources in a multithreaded environment, ensuring thread safety and preventing issues like race conditions, data corruption, or inconsistent states. Below is a concise yet comprehensive explanation of synchronization and locks, including their purpose, mechanisms, and key differences.

---
### Synchronization in Java
**Synchronization** ensures that only one thread can execute a specific block of code or method (critical section) at a time, ==preventing concurrent modifications to shared resources.== Java provides two primary ways to achieve synchronization:

1. **Synchronized Methods**  
   - A method declared with the `synchronized` keyword ensures that only one thread can execute it at a time for a given object (or class, if static).
   - **Mechanism**: Uses the intrinsic lock (monitor) associated with the object (for instance methods) or the class (for static methods).
   - **Syntax**:
     ```java
     public synchronized void synchronizedMethod() {
         // Critical section
     }
     ```
   - **Lock Scope**: 
     - Instance method: Locks the object instance (`this`).
     - Static method: Locks the `Class` object.
   - **Example**:
     ```java
     public class Counter {
         private int count = 0;
         public synchronized void increment() {
             count++;
         }
         public int getCount() {
             return count;
         }
     }
     ```

2. **Synchronized Blocks**  
   - A finer-grained approach where only a specific block of code is synchronized, reducing the scope of the lock.
   - **Mechanism**: Requires an object to act as the lock (monitor). All threads must acquire this lock to execute the block.
   - **Syntax**:
     ```java
     public void method() {
         synchronized(lockObject) {
             // Critical section
         }
     }
     ```
   - **Example**:
     ```java
     public class Counter {
         private int count = 0;
         private final Object lock = new Object();
         public void increment() {
             synchronized(lock) {
                 count++;
             }
         }
     }
     ```
   - **Advantage**: Reduces lock contention by limiting the synchronized code, improving performance.

### Locks in Java
The `java.util.concurrent.locks` package (introduced in Java 5) provides explicit lock mechanisms, offering more flexibility and control than intrinsic locks used in synchronization. The primary interface is `Lock`, with `ReentrantLock` being the most commonly used implementation.

1. **ReentrantLock**  
   - A `ReentrantLock` is a lock that can be acquired and released explicitly, supporting reentrancy (a thread can acquire the same lock multiple times without deadlocking).
   - **Key Features**:
     - **Explicit Locking**: Use `lock()` to acquire and `unlock()` to release.
     - **Try-Lock**: `tryLock()` allows attempting to acquire the lock without blocking, or with a timeout (`tryLock(long time, TimeUnit unit)`).
     - **Fairness**: Can be configured as fair (FIFO order for waiting threads) via `new ReentrantLock(true)`.
     - **Condition Variables**: Supports multiple `Condition` objects for fine-grained thread coordination.
   - **Example**:
     ```java
     import java.util.concurrent.locks.ReentrantLock;
     public class Counter {
         private int count = 0;
         private final ReentrantLock lock = new ReentrantLock();
         public void increment() {
             lock.lock();
             try {
                 count++;
             } finally {
                 lock.unlock();
             }
         }
     }
     ```
   - **Key Point**: Always use `try-finally` to ensure `unlock()` is called, preventing deadlocks.

2. **ReadWriteLock**  
   - A `ReadWriteLock` (e.g., `ReentrantReadWriteLock`) allows multiple threads to read a resource concurrently but ensures exclusive access for writing.
   - **Use Case**: Optimizes performance when reads are frequent, and writes are rare.
   - **Example**:
     ```java
     import java.util.concurrent.locks.ReentrantReadWriteLock;
     public class SharedData {
         private int data = 0;
         private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
         public void read() {
             rwLock.readLock().lock();
             try {
                 System.out.println("Read: " + data);
             } finally {
                 rwLock.readLock().unlock();
             }
         }
         public void write(int value) {
             rwLock.writeLock().lock();
             try {
                 data = value;
             } finally {
                 rwLock.writeLock().unlock();
             }
         }
     }
     ```

### Synchronization vs. Locks
| Feature                  | Synchronized (Intrinsic Locks) | Locks (Explicit Locks) |
|-------------------------|-------------------------------|-------------------------|
| **Mechanism**           | Uses object’s intrinsic monitor | Explicit `Lock` objects (e.g., `ReentrantLock`) |
| **Granularity**         | Method or block level          | Fine-grained, explicit control |
| **Flexibility**         | Limited (no timeout, fairness) | Advanced features (tryLock, fairness, conditions) |
| **Performance**         | Simpler but may have contention | Better for complex scenarios |
| **Error Handling**      | Automatic lock release        | Manual (requires `unlock()` in `finally`) |
| **Read/Write Separation**| Not supported                | Supported via `ReadWriteLock` |
| **Usage Complexity**    | Easier to use                 | More complex, error-prone if misused |

### Thread Lifecycle Context
- **BLOCKED State**: A thread enters the **BLOCKED** state when waiting to acquire an intrinsic lock (synchronized) or an explicit lock (e.g., `ReentrantLock`).
- **WAITING/TIMED_WAITING**: Using `Lock` with `Condition` (via `await()` or `await(long, TimeUnit)`) or `Object.wait()` in synchronized blocks can put a thread in these states.
- **Example with Condition**:
  ```java
  ReentrantLock lock = new ReentrantLock();
  Condition condition = lock.newCondition();
  public void await() throws InterruptedException {
      lock.lock();
      try {
          condition.await(); // Moves thread to WAITING
      } finally {
          lock.unlock();
      }
  }
  public void signal() {
      lock.lock();
      try {
          condition.signal(); // Notifies waiting thread
      } finally {
          lock.unlock();
      }
  }
  ```

### Best Practices
1. **Minimize Lock Scope**: Use synchronized blocks or explicit locks over small critical sections to reduce contention.
2. **Avoid Nested Locks**: Minimize acquiring multiple locks to prevent deadlocks.
3. **Use `try-finally` with Locks**: Ensure `unlock()` is called to avoid deadlocks.
4. **Prefer Higher-Level Constructs**: For complex scenarios, consider `java.util.concurrent` classes like `ConcurrentHashMap` or `ExecutorService` instead of low-level locks.
5. **Understand Performance**: `ReentrantLock` can outperform synchronized in high-contention scenarios due to features like fairness or try-lock.
6. **Thread Safety**: Always ensure shared resources are properly synchronized to avoid race conditions.

### Summary
- **Synchronization** uses intrinsic locks (`synchronized` keyword) to ensure thread-safe access to critical sections, suitable for simpler use cases.
- **Locks** (`ReentrantLock`, `ReadWriteLock`) provide explicit, flexible control with advanced features like fairness, timeouts, and read/write separation, ideal for complex concurrency needs.
- Both mechanisms tie into the thread lifecycle by influencing states like **BLOCKED**, **WAITING**, and **TIMED_WAITING**, ensuring safe multithreaded execution.

[[44 - Threads 🧀]]