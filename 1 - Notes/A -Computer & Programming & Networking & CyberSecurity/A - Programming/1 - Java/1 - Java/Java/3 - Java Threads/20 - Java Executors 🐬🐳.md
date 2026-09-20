

## 1. What are Java Executors?



Executors are a part of Java’s `java.util.concurrent` package, introduced in Java 5, to simplify thread management. Think of them as a manager who assigns tasks to workers (threads) without you needing to hire (create) a new worker for each job. Instead of manually creating threads, Executors provide a high-level way to execute tasks concurrently.



The **Executor framework** abstracts thread creation and management. It uses **thread pools** (a group of reusable threads) to run tasks, reducing the overhead of creating threads repeatedly. This is critical for backend applications like web servers, where many tasks (e.g., user requests) run concurrently.



Executors decouple task submission from execution, allowing fine-tuned control over thread policies (e.g., pool size, task queuing). They support both **synchronous** and **asynchronous** task execution, integrate with modern Java features like virtual threads (Java 21+), and are essential for scalable backend systems like those built with Spring Boot.


### 🕐 **Synchronous**

- Tasks happen **one after another** (in sequence).
    
- Each task **waits** for the previous one to finish before starting.
    
- If one task is slow, everything else **waits**.
    

**Example (synchronous Java code):**

```java
System.out.println("Start");
 doTask(); // must finish before next line runs System.out.println("End");
```

Output:

```bash 
Start (task runs) End
```

---

### ⚡ **Asynchronous**

- Tasks can run **independently** or **in parallel**.
    
- The program **doesn’t wait** for one task to finish before moving to the next.
    
- Useful for I/O, network calls, or long operations.
    

**Example (asynchronous Java code using CompletableFuture):**

```java
System.out.println("Start");
CompletableFuture.runAsync(() -> doTask()); 
System.out.println("End");
```

Output:

```bash
Start End (task runs later)
```


## 2. Why Use Executors?

 

Creating threads directly (e.g., `new Thread()`) is slow and uses a lot of memory. Executors reuse threads, making your program faster and more efficient.



- **Efficiency**: Reusing threads reduces CPU and memory overhead.
- **Scalability**: Thread pools handle many tasks (e.g., thousands of web requests) without crashing.
- **Control**: You can limit the number of threads, manage task queues, and handle errors gracefully.



Executors are critical for backend servers (e.g., handling HTTP requests in a REST API). They prevent resource exhaustion, support async programming (via `CompletableFuture`), and integrate with frameworks like Spring Boot for task management. Without Executors, backend apps risk performance issues or crashes under heavy load.

## 3. How Executors Create Threads



Executors don’t always create new threads; they manage a pool of threads. You submit tasks (`Runnable` or `Callable`), and the Executor assigns them to available threads in the pool.



The `Executors` class provides factory methods to create different types of thread pools (e.g., fixed-size, cached). Each pool type decides how threads are created or reused. Tasks are queued if no threads are available.



Executors use a `ThreadFactory` to create threads when needed (e.g., when the pool grows). You can customize thread creation (e.g., set names, daemon status). For high-concurrency apps, virtual threads (Java 21+) allow Executors to manage millions of tasks with minimal overhead.

**Example: Basic Executor with Fixed Thread Pool**

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class BasicExecutor {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newFixedThreadPool(2); // 2 threads

        Runnable task1 = () -> {
            System.out.println("Task 1 running on " + Thread.currentThread().getName());
            try { Thread.sleep(1000); } catch (InterruptedException e) { e.printStackTrace(); }
        };

        Runnable task2 = () -> {
            System.out.println("Task 2 running on " + Thread.currentThread().getName());
            try { Thread.sleep(1000); } catch (InterruptedException e) { e.printStackTrace(); }
        };

        executor.submit(task1);
        executor.submit(task2);
        executor.shutdown();
    }
}
```

**Explanation**: A fixed thread pool with two threads runs two tasks. Obsidian highlights `ExecutorService` in blue and strings in green.

## 4. Key Classes and Interfaces for Executors

### Basics

The `java.util.concurrent` package provides classes and interfaces for Executors and thread creation:

- **Executor**: Basic interface for executing tasks.
- **ExecutorService**: Extends `Executor`, adds methods for managing tasks and shutdown.
- **Executors**: Utility class with factory methods to create thread pools.
- **ThreadPoolExecutor**: Core implementation for customizable thread pools.
- **ScheduledExecutorService**: For scheduling tasks (e.g., delayed or periodic).
- **ForkJoinPool**: For parallel, recursive tasks.

### Intermediate

- **Runnable**: Interface for tasks without return values.
- **Callable**: Interface for tasks that return a value or throw exceptions.
- **Future**: Represents a task’s result, retrieved later.
- **CompletableFuture**: Advanced async task handling (non-blocking).

### Advanced

- **ThreadFactory**: Customizes thread creation (e.g., naming, priority).
- **BlockingQueue**: Manages task queues (e.g., `LinkedBlockingQueue`).
- **RejectedExecutionHandler**: Handles tasks when the pool is full (e.g., `AbortPolicy`).
- **Virtual Threads** (Java 21+): Lightweight threads for massive concurrency, used with `Executors.newVirtualThreadPerTaskExecutor()`.

## 5. What Each Class/Interface Does

### Executor

- **Purpose**: Defines a single method, `execute(Runnable)`, to run tasks.
- **Use**: Rarely used directly; base for other interfaces.
- **When**: Use for simple, custom thread management (rare in backend apps).

### ExecutorService

- **Purpose**: Extends `Executor` with methods to submit tasks (`submit`), shut down (`shutdown`), and manage lifecycle.
- **Use**: Standard for thread pools in backend apps.
- **When**: Use for most concurrent tasks (e.g., web servers, batch processing).

### Executors

- **Purpose**: Factory class to create thread pools (`ExecutorService` or `ScheduledExecutorService`).
- **Use**: Simplifies thread pool creation (e.g., `newFixedThreadPool`).
- **When**: Use to quickly set up standard thread pools.

### ThreadPoolExecutor

- **Purpose**: Customizable thread pool implementation.
- **Use**: Fine-tune pool size, queue type, rejection policies.
- **When**: Use for advanced control in high-performance backend systems.

### ScheduledExecutorService

- **Purpose**: Extends `ExecutorService` for scheduling tasks (delayed or periodic).
- **Use**: Run tasks at specific times or intervals.
- **When**: Use for cron jobs, timers, or scheduled tasks in backend apps.

### ForkJoinPool

- **Purpose**: Specialized pool for parallel, divide-and-conquer tasks.
- **Use**: Splits tasks into subtasks (e.g., recursive algorithms).
- **When**: Use for CPU-bound tasks like data processing or sorting.

### ThreadFactory

- **Purpose**: Customizes thread creation (e.g., names, daemon status).
- **Use**: Pass to `ThreadPoolExecutor` for custom threads.
- **When**: Use in enterprise apps needing thread monitoring.

### CompletableFuture

- **Purpose**: Handles async tasks with non-blocking result processing.
- **Use**: Chain tasks or handle results without blocking.
- **When**: Use for async APIs or reactive programming in backends.

## 6. Key Methods of ExecutorService and ThreadPoolExecutor

### ExecutorService Methods

- `submit(Runnable task)`: Submits a task, returns a `Future`.
- `submit(Callable<T> task)`: Submits a task with a return value.
- `shutdown()`: Initiates graceful shutdown (no new tasks).
- `shutdownNow()`: Attempts immediate shutdown, cancels running tasks.
- `isShutdown()`: Checks if shutdown was initiated.
- `isTerminated()`: Checks if all tasks are done after shutdown.
- `awaitTermination(long timeout, TimeUnit unit)`: Waits for tasks to finish.

### ThreadPoolExecutor Methods

- `setCorePoolSize(int size)`: Sets number of core threads.
- `setMaximumPoolSize(int size)`: Sets max threads.
- `getActiveCount()`: Returns active thread count.
- `getQueue()`: Returns task queue.
- `setThreadFactory(ThreadFactory factory)`: Sets thread creation logic.
- `setRejectedExecutionHandler(RejectedExecutionHandler handler)`: Handles rejected tasks.
- `prestartAllCoreThreads()`: Starts all core threads.
- `allowCoreThreadTimeOut(boolean value)`: Allows core threads to timeout if idle.

**Example: Custom ThreadPoolExecutor**

```java
import java.util.concurrent.*;

public class CustomThreadPoolExecutor {
    public static void main(String[] args) throws InterruptedException {
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
            2, // Core pool size
            4, // Max pool size
            60, TimeUnit.SECONDS, // Idle timeout
            new LinkedBlockingQueue<>(3), // Queue for 3 tasks
            new ThreadFactory() { // Custom thread names
                int count = 0;
                @Override
                public Thread newThread(Runnable r) {
                    return new Thread(r, "Custom-Thread-" + count++);
                }
            },
            new ThreadPoolExecutor.AbortPolicy() // Reject excess tasks
        );

        for (int i = 0; i < 6; i++) {
            final int taskId = i;
            executor.submit(() -> {
                System.out.println("Task " + taskId + " on " + Thread.currentThread().getName());
                try { Thread.sleep(1000); } catch (InterruptedException e) { e.printStackTrace(); }
            });
        }

        System.out.println("Active threads: " + executor.getActiveCount());
        executor.shutdown();
        executor.awaitTermination(10, TimeUnit.SECONDS);
    }
}
```

**Explanation**: A custom `ThreadPoolExecutor` with two core threads, max four, and a queue for three tasks. Custom thread names are set via `ThreadFactory`. Obsidian highlights `ThreadPoolExecutor` in blue and numbers in orange.

## 7. Thread Creation Methods via Executors

### Fixed Thread Pool

- **Method**: `Executors.newFixedThreadPool(int n)`
- **How**: Creates a pool with `n` threads. Tasks queue if all threads are busy.
- **When**: Use for controlled concurrency (e.g., web servers with limited threads).
- **Why**: Prevents resource exhaustion; ideal for backend apps with steady load.

**Example**

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class FixedThreadPool {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        for (int i = 0; i < 5; i++) {
            final int taskId = i;
            executor.submit(() -> {
                System.out.println("Task " + taskId + " on " + Thread.currentThread().getName());
                try { Thread.sleep(1000); } catch (InterruptedException e) { e.printStackTrace(); }
            });
        }
        executor.shutdown();
    }
}
```

**Explanation**: Five tasks run on two threads; extra tasks queue. Obsidian highlights `for` and strings vividly.

### Cached Thread Pool

- **Method**: `Executors.newCachedThreadPool()`
- **How**: Creates threads as needed; reuses idle threads (60-second timeout).
- **When**: Use for short-lived, unpredictable tasks.
- **Why**: Flexible for variable workloads but risks thread explosion if tasks are long-running.

**Example**

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
                try { Thread.sleep(100); } catch (InterruptedException e) { e.printStackTrace(); }
            });
        }
        executor.shutdown();
    }
}
```

**Explanation**: Threads are created as needed and reused. Obsidian highlights `ExecutorService` in blue.

### Single Thread Executor

- **Method**: `Executors.newSingleThreadExecutor()`
- **How**: Uses one thread for all tasks, executing them sequentially.
- **When**: Use for tasks needing strict order (e.g., logging).
- **Why**: Simplifies sequential task execution without concurrency issues.

**Example**

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SingleThreadExecutor {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        for (int i = 0; i < 3; i++) {
            final int taskId = i;
            executor.submit(() -> {
                System.out.println("Task " + taskId + " on " + Thread.currentThread().getName());
                try { Thread.sleep(100); } catch (InterruptedException e) { e.printStackTrace(); }
            });
        }
        executor.shutdown();
    }
}
```

**Explanation**: Tasks run one at a time on a single thread. Obsidian highlights `submit` in blue.

### Scheduled Thread Pool

- **Method**: `Executors.newScheduledThreadPool(int n)`
- **How**: Schedules tasks for delayed or periodic execution.
- **When**: Use for cron jobs or timed tasks (e.g., cleanup).
- **Why**: Simplifies scheduling in backend systems.

**Example**

```java
import java.util.concurrent.*;

public class ScheduledThreadPool {
    public static void main(String[] args) {
        ScheduledExecutorService executor = Executors.newScheduledThreadPool(2);
        Runnable task = () -> System.out.println("Task on " + Thread.currentThread().getName());
        executor.scheduleAtFixedRate(task, 1, 2, TimeUnit.SECONDS); // Run every 2 seconds
        try { Thread.sleep(6000); } catch (InterruptedException e) { e.printStackTrace(); }
        executor.shutdown();
    }
}
```

**Explanation**: A task runs every 2 seconds after a 1-second delay. Obsidian highlights `scheduleAtFixedRate` in blue.

### Virtual Thread Per Task Executor (Java 21+)

- **Method**: `Executors.newVirtualThreadPerTaskExecutor()`
- **How**: Creates a virtual thread per task, ideal for I/O-bound tasks.
- **When**: Use for high-concurrency backend apps (e.g., web servers).
- **Why**: Scales to millions of tasks with low overhead.

**Example**

```java
import java.util.concurrent.Executors;

public class VirtualThreadExecutor {
    public static void main(String[] args) {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < 3; i++) {
                final int taskId = i;
                executor.submit(() -> {
                    System.out.println("Task " + taskId + " on " + Thread.currentThread());
                    try { Thread.sleep(100); } catch (InterruptedException e) { e.printStackTrace(); }
                });
            }
        }
    }
}
```

**Explanation**: Virtual threads handle tasks with minimal overhead. Obsidian highlights `try` and `Thread` in bright colors.

### Fork/Join Pool

- **Method**: `Executors.newWorkStealingPool()`
- **How**: Uses work-stealing for parallel, recursive tasks.
- **When**: Use for CPU-bound, divide-and-conquer tasks (e.g., sorting).
- **Why**: Optimizes multi-core CPU usage.

**Example**

```java
import java.util.concurrent.*;

public class ForkJoinExecutor extends RecursiveTask<Integer> {
    private final int[] array;
    private final int start, end;
    private static final int THRESHOLD = 5;

    public ForkJoinExecutor(int[] array, int start, int end) {
        this.array = array;
        this.start = start;
        this.end = end;
    }

    @Override
    protected Integer compute() {
        if (end - start <= THRESHOLD) {
            int sum = 0;
            for (int i = start; i < end; i++) sum += array[i];
            return sum;
        } else {
            int mid = start + (end - start) / 2;
            ForkJoinExecutor left = new ForkJoinExecutor(array, start, mid);
            ForkJoinExecutor right = new ForkJoinExecutor(array, mid, end);
            left.fork();
            return right.compute() + left.join();
        }
    }

    public static void main(String[] args) {
        int[] array = {1, 2, 3, 4, 5, 6, 7, 8};
        ForkJoinPool pool = Executors.newWorkStealingPool();
        int sum = pool.invoke(new ForkJoinExecutor(array, 0, array.length));
        System.out.println("Sum: " + sum);
        pool.shutdown();
    }
}
```

**Explanation**: Splits an array sum task into parallel subtasks. Obsidian highlights `compute` and `int` vividly.

## 8. When to Use What?

- **Fixed Thread Pool**: Use for backend servers (e.g., REST APIs) with predictable load.
- **Cached Thread Pool**: Use for short, unpredictable tasks (e.g., lightweight API calls).
- **Single Thread Executor**: Use for sequential tasks (e.g., logging, event processing).
- **Scheduled Thread Pool**: Use for timed tasks (e.g., daily backups).
- **Virtual Thread Executor**: Use for I/O-bound, high-concurrency apps (e.g., microservices).
- **Fork/Join Pool**: Use for CPU-bound, recursive tasks (e.g., data processing).

## 9. What a Backend Developer Should Know

- **Thread Safety**: Use `synchronized`, `ReentrantLock`, or atomic classes to avoid race conditions.
- **Task Types**: Use `Runnable` for simple tasks, `Callable` for tasks with results, `CompletableFuture` for async chaining.
- **Shutdown**: Always call `shutdown()` or `shutdownNow()` to avoid resource leaks.
- **Monitoring**: Use `getActiveCount()`, `getPoolSize()` to monitor pool health.
- **Spring Boot Integration**: Configure `ThreadPoolTaskExecutor` for async methods (`@Async`).
- **Virtual Threads**: Leverage for modern, high-concurrency backends (Java 21+).
- **Error Handling**: Use `RejectedExecutionHandler` and try-catch for robust apps.

**Example: Spring Boot with Executors**

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;

@SpringBootApplication
@EnableAsync
public class SpringExecutorApp {
    public static void main(String[] args) {
        SpringApplication.run(SpringExecutorApp.class, args);
    }

    @Bean
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("BackendThread-");
        executor.initialize();
        return executor;
    }

    @Async
    public CompletableFuture<String> handleRequest() {
        System.out.println("Handling request on " + Thread.currentThread().getName());
        try { Thread.sleep(1000); } catch (InterruptedException e) { e.printStackTrace(); }
        return CompletableFuture.completedFuture("Request processed");
    }
}
```

**Explanation**: Spring Boot uses a custom `ThreadPoolTaskExecutor` for async tasks. Obsidian highlights `@Async` in purple and `CompletableFuture` in blue.

## 10. Summary

- **Executors**: Simplify thread management with thread pools.
- **Classes**: `ExecutorService`, `ThreadPoolExecutor`, `ScheduledExecutorService`, `ForkJoinPool`.
- **Methods**: `submit()`, `shutdown()`, `schedule()`, `setCorePoolSize()`.
- **When**: Use for backend apps (e.g., APIs, servers) to handle concurrent tasks efficiently.
- **Why**: Improves performance, scalability, and resource management.
- **Backend Must-Knows**: Thread safety, shutdown, monitoring, and integration with Spring Boot or virtual threads.

Executors are a cornerstone of modern Java backend development, enabling robust, scalable applications.



[[44 - Threads 🧀]]