

## Overview of Java Thread Lifecycle

A Java thread progresses through several states during its lifecycle, as defined by the `Thread.State` enum. Understanding these states is essential for using thread control methods effectively.

```java 
//Iside the JDK : 
public static enum State {  
    NEW,  
    RUNNABLE,  
    BLOCKED,  
    WAITING,  
    TIMED_WAITING,  
    TERMINATED;  
}
```


### Thread States

1. **NEW**: The thread is created but not yet started (`new Thread()`).
2. **RUNNABLE**: The thread is executing or ready to execute (`start()` has been called).
3. **BLOCKED**: The thread is waiting for a monitor lock (e.g., entering a `synchronized` block).
4. **WAITING**: The thread is waiting indefinitely for another thread to perform an action (e.g., via `wait()`, `join()`, or `LockSupport.park()`).
5. **TIMED_WAITING**: The thread is waiting for a specified time (e.g., via `sleep()`, `wait(long)`, or `join(long)`).
6. **TERMINATED**: The thread has completed execution or been stopped.

### Lifecycle Flow

- **NEW → RUNNABLE**: Calling `start()` transitions the thread to `RUNNABLE`.
- **RUNNABLE → BLOCKED/WAITING/TIMED_WAITING**: Occurs due to synchronization, waiting, or sleeping.
- **BLOCKED/WAITING/TIMED_WAITING → RUNNABLE**: Occurs when the lock is acquired, signaled, or timeout expires.
- **RUNNABLE → TERMINATED**: When the `run()` method completes or an unhandled exception occurs.

---

## Key Thread Methods

Below are the key thread methods related to lifecycle management, their usage, and their significance. These methods are part of the `java.lang.Thread` class unless otherwise noted.

### 1. isAlive()

- **Purpose**: Checks if a thread is alive (i.e., in `RUNNABLE`, `BLOCKED`, `WAITING`, or `TIMED_WAITING` states).
- **Signature**: `boolean isAlive()`
- **Returns**: `true` if the thread has started and not yet terminated; `false` otherwise.
- **How to Use**:
    - Check thread status before performing operations like `join()` or accessing thread state.
    - Avoid calling methods that assume the thread is running if `isAlive()` returns `false`.
- **Where to Use**:
    - Monitoring thread status in a thread pool or task manager.
    - Ensuring a thread is active before sending it signals or waiting for it.
- **Why to Use**:
    - Prevents unnecessary operations on terminated threads.
    - Useful for *debugging or logging* thread activity.
- **Example**:

```java
public class IsAliveExample {
    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {}
        });
        System.out.println("Before start: " + worker.isAlive()); // Output: false
        worker.start();
        System.out.println("After start: " + worker.isAlive()); // Output: true
        worker.join();
        System.out.println("After termination: " + worker.isAlive()); // Output: false
    }
}
```

- **Use Case**: Checking if a background task thread is still running in a server.

### 2. join()

- **Purpose**: Causes the calling thread to wait for the target thread to terminate.
- **Signatures**:
    - `void join()`: Waits indefinitely.
    - `void join(long millis)`: Waits up to `millis` milliseconds.
    - `void join(long millis, int nanos)`: Waits up to `millis` milliseconds plus `nanos` nanoseconds.
- **Throws**: `InterruptedException` if the calling thread is interrupted.
- **How to Use**:
    - Call `join()` on a thread to ensure it completes before proceeding.
    - Use timed `join(long)` for bounded waiting.
    - Always handle `InterruptedException` and restore the interrupted state.
- **Where to Use**:
    - Coordinating task completion in multi-threaded applications.
    - Ensuring a worker thread finishes before the main thread processes results.
- **Why to Use**:
    - Simplifies thread synchronization by ensuring sequential execution.
    - Prevents premature access to results from incomplete threads.
- **Example**:

```java
public class JoinExample {
    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> {
            try {
                Thread.sleep(1000);
                System.out.println("Worker finished");
            } catch (InterruptedException e) {}
        });

        worker.start();
        System.out.println("Main waiting for worker");
        worker.join();
        System.out.println("Main proceeding after worker");
    }
}
```

- **Use Case**: Waiting for a database query thread to complete before processing results in a web server.

### 3. sleep()

- **Purpose**: Pauses the current thread for a specified time, moving it to `TIMED_WAITING`.
- **Signatures**:
    - `static void sleep(long millis)`: Sleeps for `millis` milliseconds.
    - `static void sleep(long millis, int nanos)`: Sleeps for `millis` milliseconds plus `nanos` nanoseconds.
- **Throws**: `InterruptedException` if the thread is interrupted.
- **How to Use**:
    - Call `Thread.sleep()` to introduce delays in a thread’s execution.
    - Use in loops or tasks to simulate processing time or polling.
    - Handle `InterruptedException` and consider restoring the interrupted state.
- **Where to Use**:
    - Simulating delays (e.g., in testing or rate-limiting).
    - Polling loops (though prefer `ScheduledExecutorService` for production).
- **Why to Use**:
    - Provides a simple way to pause execution without busy-waiting.
    - Useful for throttling or timing-dependent operations.
- **Example**:

```java
public class SleepExample {
    public static void main(String[] args) {
        Thread timer = new Thread(() -> {
            for (int i = 5; i > 0; i--) {
                System.out.println("Countdown: " + i);
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        });
        timer.start();
    }
}
```

- **Use Case**: Implementing a rate-limited API client that pauses between requests.

### 4. yield()

- **Purpose**: Hints to the scheduler that the current thread is willing to yield its CPU time to other threads.
- **Signature**: `static void yield()`
- **How to Use**:
    - Call `Thread.yield()` in a CPU-intensive task to allow other threads to run.
    - No guarantee of yielding; depends on the JVM and OS scheduler.
- **Where to Use**:
    - In long-running computations to improve thread fairness.
    - Rarely used in modern applications (prefer thread pools or executors).
- **Why to Use**:
    - May improve responsiveness in CPU-bound tasks.
    - Lightweight way to encourage thread scheduling.
- **Limitations**:
    - Effect is platform-dependent and often negligible.
    - Not a reliable way to control thread scheduling.
- **Example**:

```java
public class YieldExample {
    public static void main(String[] args) {
        Thread worker = new Thread(() -> {
            for (int i = 0; i < 1000; i++) {
                System.out.println("Working...");
                Thread.yield(); // Hint to yield CPU
            }
        });
        worker.start();
    }
}
```

- **Use Case**: Yielding in a CPU-intensive task to allow other threads to run (rare in practice).

### 5. Other Important Thread Methods

- **start()**:
    - **Purpose**: Starts the thread, moving it to `RUNNABLE` and invoking `run()`.
    - **Signature**: `void start()`
    - **Throws**: `IllegalThreadStateException` if already started.
    - **How/Where/Why**: Call to begin thread execution; used to initiate tasks like background processing. Never call `run()` directly.
    - **Example**:
        
        ```java
        Thread t = new Thread(() -> System.out.println("Running"));
        t.start(); // Starts thread
        ```
        
- **interrupt()**:
    - **Purpose**: Signals the thread to interrupt, setting its interrupted status.
    - **Signature**: `void interrupt()`
    - **How/Where/Why**: Use to request a thread to stop or handle interruption (e.g., in `sleep` or `wait`). Check with `isInterrupted()` or handle `InterruptedException`.
    - **Example**:
        
        ```java
        Thread worker = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                System.out.println("Working...");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        });
        worker.start();
        Thread.sleep(3000);
        worker.interrupt();
        ```
        
    - **Use Case**: Gracefully stopping a background task in a server.
- **isInterrupted()**:
    - **Purpose**: Checks if the thread has been interrupted without clearing the status.
    - **Signature**: `boolean isInterrupted()`
    - **How/Where/Why**: Use in loops to check for interruption; safer than `interrupted()` for status checking.
- **static boolean interrupted()**:
    - **Purpose**: Checks and clears the interrupted status of the current thread.
    - **Signature**: `static boolean interrupted()`
    - **How/Where/Why**: Use sparingly in custom interruption logic; prefer `isInterrupted()` to avoid clearing status.
- **setPriority(int priority)** and `getPriority()`:
    - **Purpose**: Sets/gets the thread’s priority (1 to 10, default 5).
    - **Signatures**: `void setPriority(int newPriority)`, `int getPriority()`
    - **How/Where/Why**: Adjust thread scheduling priority; rarely used as modern JVMs and OS schedulers reduce its impact.
    - **Example**:
        
        ```java
        Thread t = new Thread();
        t.setPriority(Thread.MAX_PRIORITY); // Priority 10
        ```
        
    - **Use Case**: Prioritizing critical tasks (use cautiously, platform-dependent).
- **setDaemon(boolean on)** and `isDaemon()`:
    - **Purpose**: Marks a thread as a daemon (background) thread; daemon threads terminate when all non-daemon threads end.
    - **Signatures**: `void setDaemon(boolean on)`, `boolean isDaemon()`
    - **How/Where/Why**: Set before `start()`; use for background tasks like logging or monitoring.
    - **Example**:
        
        ```java
        Thread daemon = new Thread(() -> {
            while (true) {
                System.out.println("Monitoring...");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {}
            }
        });
        daemon.setDaemon(true);
        daemon.start();
        ```
        
    - **Use Case**: Background monitoring in a server.
- **getState()**:
    - **Purpose**: Returns the thread’s current state (`Thread.State`).
    - **Signature**: `Thread.State getState()`
    - **How/Where/Why**: Use for debugging or monitoring thread lifecycle.
    - **Example**:
        
        ```java
        Thread t = new Thread();
        System.out.println(t.getState()); // Output: NEW
        t.start();
        System.out.println(t.getState()); // Output: RUNNABLE
        ```
        
- **setUncaughtExceptionHandler(Thread.UncaughtExceptionHandler eh)**:
    - **Purpose**: Sets a handler for uncaught exceptions in the thread.
    - **Signature**: `void setUncaughtExceptionHandler(Thread.UncaughtExceptionHandler eh)`
    - **How/Where/Why**: Use to log or handle uncaught exceptions in threads.
    - **Example**:
        
        ```java
        Thread t = new Thread(() -> {
            throw new RuntimeException("Error");
        });
        t.setUncaughtExceptionHandler((thread, ex) -> System.err.println("Exception in " + thread.getName() + ": " + ex));
        t.start();
        ```
        

---

## Practical Example: Thread Lifecycle in a Backend Task Manager

Below is an example of a thread-based task manager using lifecycle methods for a backend application.

```java
import java.util.concurrent.*;

public class TaskManager {
    private final Thread worker;
    private volatile boolean running = true;

    public TaskManager() {
        worker = new Thread(() -> {
            while (running && !Thread.currentThread().isInterrupted()) {
                try {
                    System.out.println("Processing task...");
                    Thread.sleep(1000); // Simulate work
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    System.out.println("Worker interrupted");
                    break;
                }
            }
            System.out.println("Worker terminated");
        });
        worker.setUncaughtExceptionHandler((t, e) -> System.err.println("Error in " + t.getName() + ": " + e));
        worker.setDaemon(true); // Background thread
    }

    public void start() {
        System.out.println("Worker state: " + worker.getState()); // NEW
        worker.start();
        System.out.println("Worker alive: " + worker.isAlive()); // true
    }

    public void stop() throws InterruptedException {
        running = false;
        worker.interrupt();
        worker.join(2000); // Wait up to 2 seconds
        System.out.println("Worker state: " + worker.getState()); // TERMINATED
    }

    public static void main(String[] args) throws InterruptedException {
        TaskManager manager = new TaskManager();
        manager.start();
        Thread.sleep(3000);
        manager.stop();
    }
}
```

- **Components**:
    - `start()`: Initiates the worker thread.
    - `sleep()`: Simulates task processing with delays.
    - `interrupt()`: Signals the worker to stop.
    - `join()`: Ensures the worker terminates before shutdown.
    - `isAlive()` and `getState()`: Monitor thread status.
    - `setUncaughtExceptionHandler`: Handles unexpected errors.
    - `setDaemon`: Ensures the thread terminates with the main application.
- **Use Case**: Managing background tasks (e.g., polling a queue) in a microservice.

---

## Best Practices for Legendary Backend Developers

- **Use Thread Pools Over Raw Threads**:
    - Prefer `ExecutorService` (e.g., `ThreadPoolExecutor`) for managing threads instead of creating raw `Thread` instances.
    - Example: Use `Executors.newFixedThreadPool(n)` for controlled concurrency.
- **Handle Interruptions Properly**:
    - Always catch `InterruptedException` and restore the interrupted state (`Thread.currentThread().interrupt()`).
    - Use `isInterrupted()` in loops to check for interruption.
- **Use join() for Coordination**:
    - Call `join()` to ensure dependent tasks complete in order.
    - Use timed `join(long)` to avoid indefinite waiting.
- **Avoid Overusing sleep()**:
    - Use `ScheduledExecutorService` for scheduled tasks instead of `sleep()` in production.
    - Example: `Executors.newScheduledThreadPool(n).scheduleAtFixedRate(...)`.
- **Use yield() Sparingly**:
    - Rarely effective in modern JVMs; prefer thread pool tuning or `ExecutorService` for scheduling.
- **Monitor Thread State**:
    - Use `isAlive()` and `getState()` for debugging or monitoring.
    - Log thread states in production for diagnostics.
- **Handle Exceptions**:
    - Set an `UncaughtExceptionHandler` to log uncaught exceptions.
    - Use `CompletableFuture` for robust asynchronous exception handling.
- **Daemon Threads**:
    - Use `setDaemon(true)` for non-critical background tasks (e.g., logging, monitoring).
    - Set before calling `start()`.
- **Thread Priority**:
    - Avoid relying on `setPriority` as it’s platform-dependent; use thread pool configurations instead.
- **Combine with Modern Concurrency**:
    - Use `ThreadPoolExecutor`, `Future`, or `CompletableFuture` for production-grade concurrency.
    - Example: Replace `sleep` and `join` with `CompletableFuture.supplyAsync` for asynchronous tasks.

---

## Benefits

- **Control**: Methods like `join`, `sleep`, and `interrupt` provide precise thread coordination.
- **Monitoring**: `isAlive` and `getState` enable thread status tracking.
- **Flexibility**: `yield` and `setPriority` offer (limited) scheduling control.
- **Error Handling**: `setUncaughtExceptionHandler` ensures robust error management.

## Limitations

- **Raw Threads**: Managing raw threads is error-prone; prefer `ExecutorService` for scalability.
- **yield()**: Unreliable due to JVM and OS scheduler variations.
- **sleep()**: Inefficient for scheduling; use `ScheduledExecutorService` instead.
- **interrupt()**: Requires cooperative handling; not all threads respond to interruption.
- **Priority**: Limited impact in modern JVMs.

## Resources

- Java Thread API: [Thread Documentation](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/Thread.html)
- Java Concurrency: [java.util.concurrent](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/package-summary.html)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)

[[44 - Threads 🧀]]