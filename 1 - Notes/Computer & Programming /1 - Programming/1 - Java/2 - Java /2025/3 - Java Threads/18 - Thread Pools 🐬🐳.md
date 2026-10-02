

## 1. What is a Thread Pool?



A **thread pool** is a group of pre-created threads that are reused to execute tasks, avoiding the overhead of creating and destroying threads for each task. Think of it as a team of workers ready to handle jobs as they come, rather than hiring a new worker for every job.



Thread pools are part of Java’s `java.util.concurrent` package, ==managed by `ExecutorService` (an interface)== and implemented by classes like `ThreadPoolExecutor`. They queue tasks and assign them to available threads, improving efficiency for concurrent applications. 

![[0_qyXRe6yAbSUgIVpf.png]]


Thread pools manage thread lifecycle, task queuing, and resource allocation. They’re customizable (e.g., pool size, queue type) and support advanced features like task rejection policies and thread timeouts. Virtual threads (Java 21+) can also be used in thread pools for massive concurrency.

## 2. Why Use Thread Pools?



Creating threads directly is costly (time and memory). Thread pools reuse threads, reducing overhead and improving performance.



- **Efficiency**: Reusing threads saves CPU and memory compared to creating new ones.
- **Control**: Limits the number of active threads, preventing resource exhaustion.
- **Scalability**: Handles multiple tasks (e.g., web requests) without overwhelming the system.



Thread pools prevent thread explosion in high-concurrency apps (e.g., servers). They provide fine-grained control over thread behavior (e.g., timeouts, priorities) and integrate with async programming via `CompletableFuture`.

## 3. What Happens If You Don’t Use Thread Pools?


Without thread pools, you create a new thread for each task, which is slow and resource-intensive.



- **Performance Hit**: Thread creation/destruction overhead slows down apps.
- **Resource Exhaustion**: Too many threads can crash the JVM or OS due to memory or CPU limits.
- **Uncontrolled Execution**: No task queuing or thread limits, leading to unpredictable behavior.


Without thread pools, apps may face `OutOfMemoryError` (too many threads) or degraded performance under load. Thread pools mitigate this by reusing threads and managing task queues, ensuring stability and scalability.

## 4. When to Use Thread Pools?



Use thread pools when you have multiple tasks that can run concurrently, especially for I/O-bound (e.g., network calls) or CPU-bound (e.g., computations) operations.



- **I/O-Bound**: ==Web servers, file processing, or database queries where tasks wait for external resources.==
- **CPU-Bound**: Parallel processing (e.g., data analysis) on multi-core systems.
- **High-Concurrency Apps**: Web apps, APIs, or microservices handling many requests.


Use thread pools in server applications (e.g., Spring Boot’s embedded Tomcat) or batch processing. For I/O-heavy apps, combine with virtual threads for massive concurrency. Avoid for single, sequential tasks due to setup complexity.

## 5. How to Use Thread Pools?



Use the `Executors` class to create a thread pool via `ExecutorService`. Submit tasks (`Runnable` or `Callable`) to the pool, and shut it down when done.



Configure pool size, queue type, and rejection policies via `ThreadPoolExecutor`. Use `submit()` for tasks and `Future` for results. Always call `shutdown()` to clean up.



Customize `ThreadPoolExecutor` for specific needs (e.g., bounded queues, custom thread factories). Use `CompletableFuture` for async programming or virtual threads for high-concurrency I/O tasks.

**Example: Basic Thread Pool**

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class BasicThreadPool {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newFixedThreadPool(2);

        Runnable task1 = () -> {
            for (int i = 0; i < 3; i++) {
                System.out.println("Task 1 on " + Thread.currentThread().getName() + ": " + i);
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        Runnable task2 = () -> {
            for (int i = 0; i < 3; i++) {
                System.out.println("Task 2 on " + Thread.currentThread().getName() + ": " + i);
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        executor.submit(task1);
        executor.submit(task2);
        executor.shutdown();
    }
}
```

**Explanation**: A fixed thread pool with two threads executes two tasks. Tasks queue if threads are busy. Obsidian highlights `ExecutorService` in blue and strings in green.

## 6. Thread Pool Types in `java.util.concurrent`


The `Executors` class provides factory methods for common thread pool types:

- `newFixedThreadPool(int n)`: Fixed number of threads.
- `newCachedThreadPool()`: Creates threads as needed, reuses idle ones.
- `newSingleThreadExecutor()`: One thread for all tasks.

>

- **Fixed Thread Pool**: Best for controlled concurrency (e.g., server apps).
- **Cached Thread Pool**: Good for short-lived tasks with unpredictable load.
- **Single Thread Executor**: Ensures sequential task execution.

> in newScheduledThreadPool you don't submit() you schecule();

- `newScheduledThreadPool(int n)`: For delayed or periodic tasks.
- `newWorkStealingPool()`: For parallel tasks (like Fork/Join).
- `newVirtualThreadPerTaskExecutor()` (Java 21+): For massive I/O-bound concurrency.

**Example: Cached Thread Pool**

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class CachedThreadPool {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newCachedThreadPool();

        for (int i = 0; i < 5; i++) {
            final int taskId = i;
            executor.submit(() -> {
                System.out.println("Task " + taskId + " on " + Thread.currentThread().getName());
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            });
        }
        executor.shutdown();
    }
}
```

**Explanation**: A cached thread pool creates threads for five tasks, reusing them as needed. Obsidian highlights `for` and `System.out` in distinct colors.


```java
import java.util.concurrent.*;

public class ScheduledThreadPoolExample {
    public static void main(String[] args) {
        // Create a scheduled thread pool with 2 threads
        ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);

        // 1. Run once after 3 seconds (like a single timer)
        scheduler.schedule(() -> {
            System.out.println("⏰ One-time task executed at " + System.currentTimeMillis());
        }, 3, TimeUnit.SECONDS);

        // 2. Run repeatedly every 2 seconds, starting after 1 second
        scheduler.scheduleAtFixedRate(() -> {
            System.out.println("🔄 Repeated task at " + System.currentTimeMillis());
        }, 1, 2, TimeUnit.SECONDS);

        // 3. Run repeatedly with delay between runs (start after 1 sec, then wait 2 sec after each run)
        scheduler.scheduleWithFixedDelay(() -> {
            System.out.println("🕒 Fixed-delay task at " + System.currentTimeMillis());
        }, 1, 2, TimeUnit.SECONDS);

        // Optional: stop everything after 10 seconds
        scheduler.schedule(() -> {
            System.out.println("✅ Shutting down...");
            scheduler.shutdown();
        }, 10, TimeUnit.SECONDS);
    }
}

```


## 7. Key Methods of `ExecutorService` and `ThreadPoolExecutor`



`ExecutorService` (interface) and `ThreadPoolExecutor` (implementation) provide methods to manage thread pools and tasks.



Key `ExecutorService` methods:

- `submit(Runnable task)`: Submits a task, returns a `Future`.
- `submit(Callable<T> task)`: Submits a task with a return value.
- `shutdown()`: Initiates graceful shutdown (no new tasks).
- `shutdownNow()`: Attempts immediate shutdown, cancels running tasks.
- `isShutdown()`: Checks if shutdown was initiated.
- `isTerminated()`: Checks if all tasks are done after shutdown.

Key `ThreadPoolExecutor` methods (extends `ExecutorService`):

- `setCorePoolSize(int size)`: Sets the number of core threads.
- `setMaximumPoolSize(int size)`: Sets the max number of threads.
- `getActiveCount()`: Returns number of active threads.
- `getQueue()`: Returns the task queue.
- `setThreadFactory(ThreadFactory factory)`: Customizes thread creation.



- `awaitTermination(long timeout, TimeUnit unit)`: Waits for tasks to finish after shutdown.
- `setRejectedExecutionHandler(RejectedExecutionHandler handler)`: Handles tasks rejected due to full queue or shutdown.
- `prestartAllCoreThreads()`: Starts all core threads immediately.
- `allowCoreThreadTimeOut(boolean value)`: Allows core threads to timeout if idle.

**Example: Custom ThreadPoolExecutor**

```java
import java.util.concurrent.*;

public class CustomThreadPool {
    public static void main(String[] args) throws InterruptedException {
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
            2, // Core pool size
            4, // Max pool size
            60, TimeUnit.SECONDS, // Idle timeout
            new LinkedBlockingQueue<>(3), // Queue capacity
            Executors.defaultThreadFactory(),
            new ThreadPoolExecutor.AbortPolicy() // Reject policy
        );

        for (int i = 0; i < 6; i++) {
            final int taskId = i;
            executor.submit(() -> {
                System.out.println("Task " + taskId + " on " + Thread.currentThread().getName());
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            });
        }

        System.out.println("Active threads: " + executor.getActiveCount());
        executor.shutdown();
        executor.awaitTermination(10, TimeUnit.SECONDS);
    }
}
```

**Explanation**: A custom `ThreadPoolExecutor` with two core threads, max four, and a queue for three tasks. Excess tasks trigger the rejection policy. Obsidian highlights `ThreadPoolExecutor` and numbers vividly.

## 8. Other Necessary Components



- **Tasks**: Use `Runnable` (no return) or `Callable` (returns a value).
- **Futures**: `Future` or `CompletableFuture` to track task results.
- **BlockingQueue**: Stores tasks when threads are busy (e.g., `LinkedBlockingQueue`).



- **ThreadFactory**: Customizes thread creation (e.g., naming, daemon status).
- **RejectedExecutionHandler**: Handles tasks when the pool is full (e.g., `AbortPolicy`, `CallerRunsPolicy`).
- **TimeUnit**: Specifies timeouts (e.g., `TimeUnit.SECONDS`).



- **Virtual Threads**: Use `Executors.newVirtualThreadPerTaskExecutor()` for I/O-bound tasks.
- **Monitoring**: Use `getPoolSize()`, `getCompletedTaskCount()` for pool metrics.
- **Spring Boot Integration**: Configure `ThreadPoolTaskExecutor` for async methods.

**Example: Virtual Thread Pool**

```java
import java.util.concurrent.Executors;

public class VirtualThreadPool {
    public static void main(String[] args) {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 5; i++) {
                final int taskId = i;
                executor.submit(() -> {
                    System.out.println("Task " + taskId + " on " + Thread.currentThread());
                    try {
                        Thread.sleep(100);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                });
            }
        }
    }
}
```

**Explanation**: A virtual thread pool handles tasks with minimal overhead, ideal for I/O-bound apps. Obsidian highlights `try` and `Thread` in bright colors.

## 9. Summary

- **Use Thread Pools For**: Concurrent tasks, server apps, or scalable systems.
- **Why**: Reduces thread creation overhead, controls resources, and improves performance.
- **How**: Use `ExecutorService` factory methods or customize `ThreadPoolExecutor`.
- **Don’t Skip**: Without thread pools, apps suffer from performance issues or crashes under load.
- **Key Classes/Interfaces**: `ExecutorService`, `ThreadPoolExecutor`, `Runnable`, `Callable`, `Future`, `CompletableFuture`.
- **Methods**: `submit()`, `shutdown()`, `setCorePoolSize()`, `awaitTermination()`.

Thread pools are essential for efficient, scalable Java applications, and the `java.util.concurrent` package provides robust tools to manage them effectively.



[[44 - Threads 🧀]]