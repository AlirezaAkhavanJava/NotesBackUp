In Java, `wait` and `notify` are methods used for **inter-thread communication** in multithreaded programming. They are part of the `Object` class and are used to coordinate actions between threads, typically in the context of a **monitor** (synchronized block or method). These methods help manage thread synchronization and prevent issues like race conditions or deadlocks. Below is a detailed explanation of each:

### 1. **`wait` Method**
The `wait` method is used to make a thread **pause its execution** and release the monitor (lock) it holds, allowing other threads to acquire the lock and proceed. The thread remains in a **waiting state** until it is notified by another thread or a specific condition is met.

#### Key Points:
- **Declared in**: `java.lang.Object`
- **Syntax**:
  ```java
  public final void wait() throws InterruptedException
  public final void wait(long timeout) throws InterruptedException
  public final void wait(long timeout, int nanos) throws InterruptedException
  ```
- **Usage**: Must be called from within a **synchronized block** or **synchronized method** on the object whose monitor is held.
- **Behavior**:
  - The thread releases the lock on the object and enters a waiting state.
  - The thread waits until it is **notified** (via `notify` or `notifyAll`) by another thread or until the specified timeout (if provided) expires.
  - After being notified, the thread moves to the **runnable state** but must reacquire the lock before continuing execution.
- **Throws**: `IllegalMonitorStateException` if the calling thread does not own the monitor (i.e., not in a synchronized block).

#### Example:
```java
synchronized (obj) {
    try {
        obj.wait(); // Thread releases lock and waits
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
}
```

### 2. **`notify` Method**
The `notify` method is used to **wake up a single thread** that is waiting on the same object's monitor. If multiple threads are waiting, only one is chosen (arbitrarily) to be awakened.

#### Key Points:
- **Declared in**: `java.lang.Object`
- **Syntax**:
  ```java
  public final void notify()
  ```
- **Usage**: Must be called from within a **synchronized block** or **synchronized method** on the object whose monitor is held.
- **Behavior**:
  - Wakes up one thread that is waiting on the object's monitor (via `wait`).
  - The awakened thread does not immediately resume execution; it must wait to reacquire the lock after the notifying thread releases it.
- **Throws**: `IllegalMonitorStateException` if the calling thread does not own the monitor.

#### Example:
```java
synchronized (obj) {
    obj.notify(); // Wakes up one waiting thread
}
```

### 3. **`notifyAll` Method**
The `notifyAll` method is similar to `notify`, but it **wakes up all threads** that are waiting on the same object's monitor.

#### Key Points:
- **Declared in**: `java.lang.Object`
- **Syntax**:
  ```java
  public final void notifyAll()
  ```
- **Usage**: Like `notify`, it must be called within a synchronized block or method.
- **Behavior**:
  - Wakes up all threads waiting on the object's monitor.
  - Each awakened thread competes to reacquire the lock, and only one thread proceeds at a time.
- **Throws**: `IllegalMonitorStateException` if the calling thread does not own the monitor.

#### Example:
```java
synchronized (obj) {
    obj.notifyAll(); // Wakes up all waiting threads
}
```

### Example: Producer-Consumer Problem
Here's a practical example demonstrating `wait` and `notify` in a producer-consumer scenario:

```java
class SharedBuffer {
    int data;
    boolean available = false;

    public synchronized void produce(int value) {
        while (available) { // Wait if buffer is full
            try {
                wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        data = value;
        available = true;
        System.out.println("Produced: " + data);
        notify(); // Notify consumer
    }

    public synchronized int consume() {
        while (!available) { // Wait if buffer is empty
            try {
                wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        available = false;
        System.out.println("Consumed: " + data);
        notify(); // Notify producer
        return data;
    }
}

public class Main {
    public static void main(String[] args) {
        SharedBuffer buffer = new SharedBuffer();

        // Producer thread
        new Thread(() -> {
            for (int i = 1; i <= 5; i++) {
                buffer.produce(i);
            }
        }).start();

        // Consumer thread
        new Thread(() -> {
            for (int i = 1; i <= 5; i++) {
                buffer.consume();
            }
        }).start();
    }
}
```

#### Explanation of Example:
- The `SharedBuffer` class uses a boolean flag (`available`) to indicate whether data is available.
- The `produce` method waits if the buffer is full (`available` is true) and notifies the consumer after producing data.
- The `consume` method waits if the buffer is empty (`available` is false) and notifies the producer after consuming data.
- Both methods are synchronized to ensure thread safety.

### Key Differences Between `notify` and `notifyAll`:
- **`notify`**: Wakes up one arbitrary thread waiting on the monitor. Useful when you know only one thread needs to proceed.
- **`notifyAll`**: Wakes up all waiting threads, allowing them to compete for the lock. Useful when multiple threads might need to check conditions (e.g., in complex scenarios where threads wait for different conditions).

### Important Notes:
- Always call `wait`, `notify`, or `notifyAll` within a **synchronized block** or **method** to avoid `IllegalMonitorStateException`.
- Use `wait` in a **loop** (checking a condition) to handle **spurious wakeups** (where a thread wakes up without being notified).
- These methods are low-level and can be error-prone. In modern Java, higher-level concurrency utilities like `java.util.concurrent` classes (e.g., `Lock`, `Condition`, `BlockingQueue`) are often preferred for thread coordination.

[[44 - Threads 🧀]]