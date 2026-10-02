

---

## Overview of Thread Management

Thread management in Java involves controlling thread execution, coordinating their lifecycle, and handling interruptions and errors. Key aspects include:

- **Interruptions**: Using `interrupt()`, `isInterrupted()`, and `InterruptedException` to signal and handle thread termination or interruption gracefully.


- **Daemon Threads**: Background threads that terminate when all non-daemon threads end, useful for non-critical tasks like monitoring or logging.


- **Other Techniques**: Setting thread priorities, handling uncaught exceptions, and using modern concurrency utilities (`ExecutorService`, `CompletableFuture`) for robust thread management.

### Goals

- Ensure threads respond to interruptions for graceful shutdown.
- Use daemon threads for background tasks that should not prevent JVM termination.
- Apply thread management techniques to improve scalability and reliability in concurrent systems.

---

### *What is Thread Management?*

*It’s about **controlling threads** in your app:*

- *How they’re created 🐣*
    
- *How many exist 🐑*
    
- *How long they live ⏳*
    
- *When they die 💀*
    

*If you don’t manage threads → chaos: too many goats (threads) eating all the hay (CPU/memory).*

---

### *Why not just `new Thread()` everywhere?*

*Bad idea 🐐💀:*

- *Each thread = heavy (takes memory stack + OS resources).*
    
- *If you spawn 1,000, your app may crash.*
    
- *You lose control: can’t easily kill them or reuse them.*
    

---

### *Proper Thread Management in Java 🐐✅*

1. ***Thread Pools (`ExecutorService`)***
    
    - *Instead of creating a new goat every time, keep a herd (pool).*
        
    - *Threads are reused.*
        
    - *Example:*
        
    
    ```java
    ExecutorService executor = Executors.newFixedThreadPool(10);  executor.submit(() -> {     System.out.println("Goat thread working!"); });  executor.shutdown();
    ```
    
    - *Limits to 10 threads → safe & efficient.*
        
2. ***Types of pools***
    
    - *`newFixedThreadPool(n)` → fixed number of threads.*
        
    - *`newCachedThreadPool()` → creates threads as needed, reuses idle ones.*
        
    - *`newSingleThreadExecutor()` → one goat only.*
        
    - *`newScheduledThreadPool(n)` → run tasks with delay/periodically.*
        
3. ***Future & CompletableFuture***
    
    - *Let threads run tasks and return results later.*
        
    - *Great for async programming.*
        
4. ***Spring Boot thread management***
    
    - *Tomcat/Jetty/Undertow use a built-in thread pool for handling web requests.*
        
    - *You can tune max threads, min threads, queue sizes in `application.properties`.*
        


### *Key Goals of Thread Management 🐐*

- *Prevent too many goats (threads) → OOM errors.*
    
- *Reuse goats instead of hiring new ones.*
    
- *Give goats clear tasks, and clean them up when done.*
    
- *Avoid deadlocks & starvation by careful design.*
    

---

*🐐 Translation:*  
***Thread management = don’t let your goats multiply uncontrolled. Use a fenced herd (pool) and make them work efficiently.***

---
### *What is an interruption?*

- *A thread in Java may be told: **“Hey goat, stop what you’re doing, or at least check if you should stop.”***
    
- *This is done by calling `thread.interrupt()`.*
    
- *It doesn’t kill the thread (Java isn’t that rude). Instead, it sets an **interrupted flag** 🏳️.*
    

---

### How to handle it properly 🐐✅

1. **Check the flag**
    
    ```java
    while (!Thread.currentThread().isInterrupted()) {     // do work }
    ```
    
    - The goat keeps working until someone sets the “interrupted” flag.
        
2. **Catching `InterruptedException`**
    
    - Some blocking calls (like `sleep`, `wait`, `join`) will throw `InterruptedException` if interrupted.
        
    - You must **handle it**: either clean up and exit, or re-set the flag.
```java
`try {Thread.sleep(1000); 
		} catch (InterruptedException e) {     Thread.currentThread().interrupt(); // restore flag     
		System.out.println("Goat interrupted, stopping work.");     
		return; // exit gracefully }`
```
    
3. **Don’t swallow it**
    
    - Bad 🐐:
        
        `catch (InterruptedException e) {     // ignore }`
        
        Now the thread ignores the signal and keeps eating hay → rude & buggy.
        
4. **Cooperative cancellation**
    
    - Interruption is a polite request. The goat (thread) decides:
        
        - Clean up
            
        - Save progress
            
        - Exit gracefully
            

---

### Why it matters in web apps 🐐

- Threads might be interrupted when:
    
    - A request is cancelled by the client.
        
    - The app/server is shutting down.
        
- Proper handling = free resources, stop wasting CPU, don’t leave half-chewed hay.
    

---

*🐐 Translation:*  
***Handling interruptions = teaching your goat to stop gracefully when asked, instead of running forever like a stubborn beast.**


---
## 1. Handling Interruptions

Interruption is a cooperative mechanism in Java to signal a thread to stop or perform cleanup. Threads must check their interrupted status or handle `InterruptedException` to respond appropriately.

### Key Methods

- **interrupt()**:
    - **Purpose**: Signals a thread to interrupt, setting its interrupted status to `true`.
    - **Signature**: `void interrupt()` (instance method of `Thread`).
    - **Behavior**:
        - If the thread is blocked in `sleep()`, `wait()`, `join()`, or `Lock.lockInterruptibly()`, it throws `InterruptedException` and clears the interrupted status.
        - If the thread is running, it sets the interrupted status, which must be checked with `isInterrupted()`.
    - **Use Case**: Requesting a thread to stop (e.g., during application shutdown).
- **isInterrupted()**:
    - **Purpose**: Checks if a thread has been interrupted without clearing the status.
    - **Signature**: `boolean isInterrupted()` (instance method of `Thread`).
    - **Use Case**: Polling in loops to detect interruption.
- **Thread.interrupted()**:
    - **Purpose**: Checks and clears the interrupted status of the current thread.
    - **Signature**: `static boolean interrupted()`.
    - **Use Case**: Rarely used; prefer `isInterrupted()` to avoid clearing the status unintentionally.
- **InterruptedException**:
    - **Purpose**: Thrown when a thread is interrupted while blocked (e.g., in `sleep()`, `wait()`, or `BlockingQueue.take()`).
    - **Handling**: Catch and either restore the interrupted status (`Thread.currentThread().interrupt()`) or perform cleanup.

---
- `interrupt()` = polite knock on the door** 🐐🚪
    
    - *Sets the **interrupted flag** of the thread.*
        
    - *Doesn’t automatically kill the thread.*
        
- ***Thread must check the flag** (`isInterrupted()`) **or hit a method that throws `InterruptedException`** (like `sleep`, `wait`, `join`) to actually stop.*
---
### How to Use Interruptions

- **Call `interrupt()`**: Signal a thread to stop (e.g., during shutdown).
- **Check `isInterrupted()`**: In long-running loops to exit gracefully.
- **Handle `InterruptedException`**:
    - Restore the interrupted status for downstream checks.
    - Perform cleanup or exit the thread.
- **Avoid Swallowing Interruptions**: Always handle `InterruptedException` explicitly to respect the interruption signal.

### Where to Use

- **Graceful Shutdown**: Interrupt threads during application shutdown (e.g., stopping background tasks in a server).
- **Task Cancellation**: Cancel long-running tasks in a thread pool.
- **Timeout Handling**: Interrupt threads that exceed a time limit.

### Why to Use

- **Cooperative Termination**: Allows threads to clean up resources before exiting.
- **Robustness**: Prevents threads from running indefinitely during shutdown.
- **Standard Practice**: Aligns with Java’s concurrency model for predictable behavior.

### Example: Interruption Handling

```java
public class InterruptionExample {
    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                try {
                    System.out.println("Working...");
                    Thread.sleep(1000); // Simulates work
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt(); // Restore interrupted status
                    System.out.println("Worker interrupted, exiting");
                    break;
                }
            }
            System.out.println("Worker terminated");
        });

        worker.start();
        Thread.sleep(3000); // Let it run for 3 seconds
        worker.interrupt(); // Signal interruption
        worker.join(); // Wait for termination
        System.out.println("Main thread done");
    }
}
```

- **Output**:
    
    ```
    Working...
    Working...
    Working...
    Worker interrupted, exiting
    Worker terminated
    Main thread done
    ```
    
- **Use Case**: Stopping a background task (e.g., polling a queue) during server shutdown.

---

## 2. Daemon Threads

### Overview

- **Definition**: Daemon threads are background threads that terminate automatically when all non-daemon threads (user threads) finish. The JVM exits when no user threads are running, regardless of daemon thread state.
- **Purpose**: ==Run non-critical background tasks (e.g., logging, monitoring, cleanup).==
- **Key Method**:
    - `setDaemon(boolean on)`: Marks a thread as daemon (`true`) or user (`false`); must be called before `start()`.
    - `boolean isDaemon()`: Checks if a thread is a daemon.
- **Signature**:
    - `void setDaemon(boolean on)`
    - `boolean isDaemon()`

### How to Use

- Set `setDaemon(true)` before calling `start()` on a thread.
- Use for tasks that should not prevent JVM termination (e.g., logging, metrics collection).
- Ensure daemon threads do not hold critical resources that require cleanup.

### Where to Use

- **Monitoring**: Background tasks like health checks or metrics reporting.
- **Logging**: Asynchronous logging to avoid blocking the main application.
- **Cleanup**: Periodic cleanup tasks that can be safely aborted.

### Why to Use

- **Automatic Termination**: Daemon threads stop when the application exits, simplifying shutdown.
- **Non-Critical Tasks**: Ideal for tasks that don’t require completion guarantees.
- **Resource Efficiency**: Prevents the JVM from hanging due to lingering threads.

### Example: Daemon Thread

```java
public class DaemonThreadExample {
    public static void main(String[] args) throws InterruptedException {
        Thread daemon = new Thread(() -> {
            while (true) {
                try {
                    System.out.println("Daemon monitoring...");
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        });
        daemon.setDaemon(true); // Mark as daemon
        daemon.start();

        Thread user = new Thread(() -> {
            try {
                System.out.println("User thread working...");
                Thread.sleep(3000);
                System.out.println("User thread done");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        user.start();
        user.join(); // JVM exits after user thread finishes, terminating daemon
        System.out.println("Main thread done");
    }
}
```

- **Output**:
    
    ```
    Daemon monitoring...
    User thread working...
    Daemon monitoring...
    Daemon monitoring...
    User thread done
    Main thread done
    ```
    
- **Note**: The daemon thread stops when the main and user threads terminate, as the JVM exits.
- **Use Case**: Background monitoring in a web server that stops when the application shuts down.

---

## 3. Other Thread Management Techniques

### Thread Priority

- **Methods**:
    - `void setPriority(int newPriority)`: Sets thread priority (1 to 10, `Thread.MIN_PRIORITY` to `Thread.MAX_PRIORITY`, default `Thread.NORM_PRIORITY`=5).
    - `int getPriority()`: Gets the current priority.
- **How/Where/Why**:
    - Adjust priority to influence scheduling (e.g., prioritize critical tasks).
    - Rarely used due to platform-dependent behavior; modern JVMs and OS schedulers often ignore priorities.
    - Use Case: Prioritizing a critical task in a resource-constrained system (use cautiously).
- **Example**:

```java
Thread t = new Thread(() -> System.out.println("High-priority task"));
t.setPriority(Thread.MAX_PRIORITY);
t.start();
```

### Uncaught Exception Handler

- **Methods**:
    - `void setUncaughtExceptionHandler(Thread.UncaughtExceptionHandler eh)`: Sets a handler for uncaught exceptions.
    - `static void setDefaultUncaughtExceptionHandler(Thread.UncaughtExceptionHandler eh)`: Sets a default handler for all threads.
- **How/Where/Why**:
    - Log or handle uncaught exceptions to prevent silent thread termination.
    - Use Case: Logging errors in a background task.
- **Example**:

```java
Thread t = new Thread(() -> { throw new RuntimeException("Error"); });
t.setUncaughtExceptionHandler((thread, ex) -> System.err.println("Error in " + thread.getName() + ": " + ex));
t.start();

 //-------------------------------------------------------------------
 
 Thread t = new Thread({
   throw new RuntimeException("Error");
   Thread.currentThread().setUncaughtExceptionHandler();
   //and so on you should do it here 
 });


```

### Thread Naming

- **Methods**:
    - `void setName(String name)`: Sets the thread’s name.
    - `String getName()`: Gets the thread’s name.
- **How/Where/Why**:
    - Name threads for easier debugging and monitoring.
    - Use Case: Identifying threads in logs or profilers.
- **Example**:

```java
Thread t = new Thread(() -> System.out.println("Task"));
t.setName("Task-Thread");
t.start();
```

### Thread Group

- **Class**: `ThreadGroup`
- **Methods**:
    - `ThreadGroup(String name)`: Creates a thread group.
    - `int activeCount()`: Returns the number of active threads in the group.
    - `void interrupt()`: Interrupts all threads in the group.
- **How/Where/Why**:
    - Group related threads for bulk operations (e.g., interruption).
    - Use Case: Managing a set of worker threads in a server.
- **Example**:

```java
ThreadGroup group = new ThreadGroup("WorkerGroup");
Thread t = new Thread(group, () -> {
    try {
        Thread.sleep(1000);
    } catch (InterruptedException e) {}
});
t.start();
group.interrupt();
```

### Modern Concurrency Utilities

- **ExecutorService**:
    - Use `ThreadPoolExecutor` or `Executors` for thread management instead of raw threads.
    - Methods: `submit`, `shutdown`, `shutdownNow`, `awaitTermination`.
    - Use Case: Managing a pool of worker threads for tasks.
- **CompletableFuture**:
    - Use for asynchronous, non-blocking task management.
    - Methods: `supplyAsync`, `runAsync`, `thenApply`, `exceptionally`.
    - Use Case: Chaining asynchronous operations in a microservice.
- **ScheduledExecutorService**:
    - Use for scheduled or periodic tasks instead of `Thread.sleep()`.
    - Methods: `schedule`, `scheduleAtFixedRate`, `scheduleWithFixedDelay`.
    - Use Case: Periodic health checks in a server.

### Example: Thread Pool with Interruption

```java
import java.util.concurrent.*;

public class ThreadPoolExample {
    public static void main(String[] args) throws InterruptedException {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        ThreadFactory factory = r -> {
            Thread t = new Thread(r);
            t.setName("Worker-" + t.getId());
            t.setUncaughtExceptionHandler((thread, ex) -> System.err.println("Error in " + thread.getName() + ": " + ex));
            return t;
        };
        ((ThreadPoolExecutor) executor).setThreadFactory(factory);

        executor.submit(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                try {
                    System.out.println(Thread.currentThread().getName() + " working...");
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    System.out.println(Thread.currentThread().getName() + " interrupted");
                    break;
                }
            }
        });

        Thread.sleep(3000);
        executor.shutdownNow(); // Interrupt all tasks
        executor.awaitTermination(5, TimeUnit.SECONDS);
    }
}
```

- **Use Case**: Managing worker threads in a thread pool with interruption support.

---

## Experimentation: Daemon Threads and Interruptions

To demonstrate thread management, let’s experiment with a system combining daemon threads, interruptions, and other techniques.

```java
import java.util.concurrent.*;

public class ThreadManagementExperiment {
    private final ExecutorService executor = Executors.newFixedThreadPool(2);
    private volatile boolean running = true;

    public void start() {
        // Daemon thread for monitoring
        Thread monitor = new Thread(() -> {
            while (true) {
                try {
                    System.out.println("Daemon monitor: System running");
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    System.out.println("Daemon monitor interrupted");
                    break;
                }
            }
        });
        monitor.setDaemon(true);
        monitor.setName("Monitor-Thread");
        monitor.start();

        // Worker tasks in thread pool
        executor.submit(() -> {
            while (running && !Thread.currentThread().isInterrupted()) {
                try {
                    System.out.println(Thread.currentThread().getName() + " processing task...");
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    System.out.println(Thread.currentThread().getName() + " interrupted");
                    break;
                }
            }
        });
    }

    public void shutdown() throws InterruptedException {
        running = false;
        executor.shutdownNow(); // Interrupt worker threads
        executor.awaitTermination(5, TimeUnit.SECONDS);
        // Daemon thread terminates automatically when JVM exits
    }

    public static void main(String[] args) throws InterruptedException {
        ThreadManagementExperiment system = new ThreadManagementExperiment();
        system.start();
        Thread.sleep(3000); // Run for 3 seconds
        system.shutdown();
        System.out.println("System shutdown complete");
    }
}
```

- **Components**:
    - **Daemon Thread**: Monitors the system, terminates automatically on JVM exit.
    - **ExecutorService**: Manages worker threads with interruption handling.
    - **Interruption**: Uses `shutdownNow()` to interrupt workers and `InterruptedException` handling for cleanup.
    - **Thread Naming**: Improves debugging with named threads.
- **Output** (example):
    
    ```
    Daemon monitor: System running
    pool-1-thread-1 processing task...
    Daemon monitor: System running
    pool-1-thread-1 processing task...
    Daemon monitor: System running
    pool-1-thread-1 interrupted
    System shutdown complete
    ```
    
- **Use Case**: A backend system with a monitoring daemon and interruptible worker threads.

---

## Best Practices for Legendary Backend Developers

- **Handle Interruptions Gracefully**:
    - Always catch `InterruptedException` and restore the interrupted status (`Thread.currentThread().interrupt()`).
    - Check `isInterrupted()` in loops to exit cleanly.
    - Use `shutdownNow()` for thread pools to interrupt tasks during shutdown.
- **Use Daemon Threads for Non-Critical Tasks**:
    - Mark threads as daemon for background tasks (e.g., logging, monitoring).
    - Set `setDaemon(true)` before `start()`; cannot change after starting.
- **Prefer ExecutorService Over Raw Threads**:
    - Use `ThreadPoolExecutor` or `Executors` for thread management.
    - Configure pool size, queue, and rejection policies based on workload.
- **Avoid Thread Priorities**:
    - Priorities are platform-dependent and often ignored; rely on thread pool tuning instead.
- **Set Uncaught Exception Handlers**:
    - Use `setUncaughtExceptionHandler` to log errors and prevent silent failures.
    - Set a default handler for thread pools via `ThreadFactory`.
- **Monitor Threads**:
    - Use `Thread.getState()`, `isAlive()`, or thread pool metrics (`getActiveCount`) for monitoring.
    - Log thread names for easier debugging.
- **Combine with Modern Concurrency**:
    - Use `CompletableFuture` for non-blocking, asynchronous workflows.
    - Use `ScheduledExecutorService` for periodic tasks instead of `sleep()`.
- **Test Interruption Handling**:
    - Simulate interruptions in tests to ensure threads respond correctly.
    - Use tools like JUnit with timeouts or `ExecutorService` shutdown.

---

## Pros and Cons of Thread Management Techniques

### Pros

- **Interruptions**:
    - Enables graceful shutdown and task cancellation.
    - Standard mechanism for cooperative thread termination.
- **Daemon Threads**:
    - Simplifies cleanup for non-critical tasks.
    - Prevents JVM from hanging due to background threads.
- **Other Techniques**:
    - Thread naming and exception handlers improve debugging and reliability.
    - `ExecutorService` and `CompletableFuture` provide scalable, high-level concurrency.

### Cons

- **Interruptions**:
    - Requires cooperative handling; threads must check `isInterrupted()` or catch `InterruptedException`.
    - Swallowing `InterruptedException` can lead to unresponsive threads.
- **Daemon Threads**:
    - Not suitable for critical tasks requiring completion.
    - No guarantee of cleanup before termination.
- **Other Techniques**:
    - Thread priorities are unreliable and platform-dependent.
    - Raw threads are error-prone; prefer thread pools for production.
    - Complex thread management can lead to deadlocks or contention if mishandled.

---

## Resources

- Java Thread API: [Thread Documentation](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/Thread.html)
- Java Concurrency: [java.util.concurrent](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/package-summary.html)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)

##### Tags : [[44 - Threads 🧀]]