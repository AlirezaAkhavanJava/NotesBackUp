

Virtual threads, introduced in Java 21 via **Project Loom**, provide a lightweight, scalable threading model for high-throughput applications like web servers and microservices. They simplify concurrent programming compared to traditional platform threads and integrate with structured concurrency mechanisms like `StructuredTaskScope`. This document explains virtual threads, how to use `Thread.ofVirtual().start()`, `StructuredTaskScope` for structured concurrency, and their differences from platform threads, with concise examples tailored for backend development.

---

## Virtual Threads

### Overview

- **Purpose**: Lightweight threads managed by the JVM, not the OS, enabling millions of threads for high-concurrency tasks.
- **Key Features**:
    - **Lightweight**: Minimal memory overhead (kilobytes vs. megabytes for platform threads).
    - **Scalable**: Supports millions of threads, ideal for high-throughput apps.
    - **Non-Blocking**: Virtual threads yield on blocking operations (e.g., I/O), improving resource utilization.
    - **Compatibility**: Work with existing Java APIs (e.g., `synchronized`, `ThreadLocal`).

### Key Methods

- `Thread.ofVirtual()`: Creates a virtual thread builder.
- `Thread.Builder start(Runnable task)`: Starts a virtual thread for the given task.
- `Thread.currentThread().isVirtual()`: Checks if the current thread is virtual.

### Example

```java
public class VirtualThreadExample {
    public static void main(String[] args) throws InterruptedException {
        Runnable task = () -> {
            System.out.println("Running on " + Thread.currentThread());
            try { Thread.sleep(1000); } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        };

        // Start virtual threads
        Thread vThread1 = Thread.ofVirtual().start(task);
        Thread vThread2 = Thread.ofVirtual().start(task);

        vThread1.join();
        vThread2.join();
    }
}
```

- **Explanation**: Creates and runs two virtual threads, each executing a task that sleeps for 1 second.
- **Use Case**: Handling thousands of concurrent requests in a web server.

### Where to Use

- High-concurrency tasks (e.g., HTTP request handling, async I/O).
- Applications with many short-lived tasks.

---

## StructuredTaskScope (Structured Concurrency)

### Overview

- **Purpose**: Provides a structured way to manage a group of subtasks, ensuring they complete or fail together.
- **Key Features**:
    - Simplifies task coordination and cancellation.
    - Supports policies like `ShutdownOnFailure` and `ShutdownOnSuccess`.
    - Ensures resources are cleaned up when tasks complete or fail.
- **Status**: Preview feature in Java 21, incubated in `jdk.incubator.concurrent`.

### Key Methods

- `StructuredTaskScope()`: Creates a task scope.
- `<T> Future<T> fork(Callable<? extends T> task)`: Forks a subtask, returning a `Future`.
- `void join()`: Waits for all subtasks to complete or fail.
- `void shutdown()`: Cancels all running subtasks.
- `StructuredTaskScope.ShutdownOnFailure`: Cancels subtasks if one fails.
- `StructuredTaskScope.ShutdownOnSuccess<T>`: Cancels subtasks after one succeeds.

### Example

```java
import jdk.incubator.concurrent.*;

public class StructuredTaskScopeExample {
    public static void main(String[] args) throws Exception {
        try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
            // Fork subtasks
            Future<String> task1 = scope.fork(() -> {
                Thread.sleep(1000);
                return "Result from task 1";
            });
            Future<String> task2 = scope.fork(() -> {
                Thread.sleep(500);
                throw new RuntimeException("Task 2 failed");
            });

            scope.join(); // Wait for completion
            scope.throwIfFailed(); // Throw if any task failed

            System.out.println(task1.resultNow());
        } catch (ExecutionException e) {
            System.out.println("Error: " + e.getCause().getMessage());
        }
    }
}
```

- **Explanation**: Forks two subtasks; if one fails, `ShutdownOnFailure` cancels others, and `throwIfFailed` propagates the exception.
- **Use Case**: Coordinating parallel API calls in a microservice.

### Where to Use

- Coordinating multiple dependent tasks (e.g., fetching data from multiple services).
- Ensuring clean resource cleanup in concurrent workflows.

---

## Virtual Threads vs. Platform Threads

|Feature|Virtual Threads|Platform Threads|
|---|---|---|
|**Managed By**|JVM (lightweight)|OS (heavyweight)|
|**Memory Overhead**|Kilobytes (~1KB stack)|Megabytes (~1MB stack)|
|**Scalability**|Millions of threads|Thousands (OS-limited)|
|**Creation Cost**|Low (fast creation)|High (OS thread creation)|
|**Blocking Behavior**|Yields on I/O (non-blocking)|Blocks OS thread|
|**Use Case**|High-throughput, I/O-bound tasks|CPU-bound or legacy tasks|
|**Thread Pool**|Rarely needed (use directly)|Required for scalability (e.g., `ExecutorService`)|

### Key Differences

- **Performance**: Virtual threads are ideal for I/O-bound tasks (e.g., HTTP requests) due to low overhead and yielding on blocking operations.
- **Thread Pools**: Virtual threads reduce the need for thread pools, as millions can be created directly.
- **Compatibility**: Virtual threads work with existing synchronization mechanisms (`synchronized`, `ReentrantLock`), but some APIs (e.g., `ThreadLocal`) may need careful handling in high-thread-count scenarios.

---

## Practical Example: High-Throughput Request Handler

```java
import jdk.incubator.concurrent.*;
import java.util.concurrent.*;

public class RequestHandler {
    public String processRequest(int id) {
        try {
            Thread.sleep(500); // Simulate I/O
            if (id == 3) throw new RuntimeException("Request " + id + " failed");
            return "Result " + id;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return "Interrupted";
        }
    }

    public void handleRequests(int count) throws Exception {
        try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
            Future<String>[] futures = new Future[count];
            // Fork virtual threads for each request
            for (int i = 0; i < count; i++) {
                final int id = i;
                futures[i] = scope.fork(() -> processRequest(id));
            }

            scope.join();
            scope.throwIfFailed();

            for (Future<String> future : futures) {
                System.out.println(future.resultNow());
            }
        }
    }

    public static void main(String[] args) throws Exception {
        RequestHandler handler = new RequestHandler();
        try {
            handler.handleRequests(5);
        } catch (ExecutionException e) {
            System.out.println("Error: " + e.getCause().getMessage());
        }
    }
}
```

- **Components**:
    - **Virtual Threads**: Implicitly used by `StructuredTaskScope` for task execution.
    - **StructuredTaskScope.ShutdownOnFailure**: Cancels tasks if one fails.
    - **Use Case**: Handling multiple HTTP requests concurrently in a web server.

---

## Best Practices

- **Use Virtual Threads for I/O-Bound Tasks**:
    - Create virtual threads directly with `Thread.ofVirtual().start()` for simplicity.
    - Example: `Thread.ofVirtual().start(task)`.
- **Leverage StructuredTaskScope for Coordination**:
    - Use `ShutdownOnFailure` or `ShutdownOnSuccess` for robust task management.
    - Example: `new StructuredTaskScope.ShutdownOnFailure()`.
- **Avoid ThreadLocal Overuse**:
    - Virtual threads create many instances; use sparingly to avoid memory issues.
    - Example: Prefer request-scoped objects over `ThreadLocal`.
- **Handle Exceptions**:
    - Use `throwIfFailed()` or `exceptionally()` to manage task failures.
    - Example: `scope.throwIfFailed()`.
- **Close StructuredTaskScope**:
    - Use try-with-resources to ensure cleanup.
    - Example: `try (var scope = new StructuredTaskScope()) { ... }`.
- **Test Scalability**:
    - Simulate high concurrency to verify virtual thread performance.
    - Example: Use JMeter for load testing.
- **Monitor Performance**:
    - Use tools like JVisualVM to observe virtual thread behavior.

---

## Pros and Cons

### Pros

- **Virtual Threads**:
    - Scalable for millions of concurrent tasks.
    - Low memory and creation overhead.
    - Simplifies I/O-bound concurrency.
- **StructuredTaskScope**:
    - Structured, safe task coordination.
    - Automatic cancellation on failure or success.
    - Resource cleanup with try-with-resources.

### Cons

- **Virtual Threads**:
    - Preview features (Java 21) may change.
    - Not ideal for CPU-bound tasks (use platform threads or `ForkJoinPool`).
- **StructuredTaskScope**:
    - Incubator API, requires `--enable-preview`.
    - Learning curve for structured concurrency.
- **General**:
    - `ThreadLocal` can lead to memory issues with many virtual threads.
    - Debugging millions of threads can be complex.

---

## Resources

- Virtual Threads: [JEP 444: Virtual Threads](https://openjdk.org/jeps/444)
- StructuredTaskScope: [JEP 453: Structured Concurrency](https://openjdk.org/jeps/453)
- Project Loom: [Project Loom](https://openjdk.org/projects/loom/)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)

##### Tags : [[44 - Threads 🧀]]