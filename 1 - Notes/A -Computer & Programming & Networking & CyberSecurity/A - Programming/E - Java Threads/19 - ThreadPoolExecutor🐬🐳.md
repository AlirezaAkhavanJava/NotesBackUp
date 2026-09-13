



### ThreadPoolExecutor

- **Purpose**: A flexible thread pool implementation for executing tasks concurrently, managing a pool of worker threads.
- **Use Case**: Running background tasks, handling HTTP requests, or processing batch jobs.
- **Key Features**:
    - Configurable pool size (core and maximum threads).
    - Task queue for pending tasks.
    - Rejection policies for handling overflow.
    - Lifecycle management (shutdown, termination).
- **Package**: `java.util.concurrent`.

### Future

- **Purpose**: Represents the result of an asynchronous computation, allowing retrieval of results or cancellation.
- **Use Case**: Tracking the outcome of tasks submitted to an executor.
- **Key Features**:
    - Retrieve results with blocking (`get`) or non-blocking (`isDone`).
    - Cancel tasks.
- **Package**: `java.util.concurrent`.

### CompletableFuture

- **Purpose**: A more powerful, flexible `Future` implementation for asynchronous programming with functional-style operations (Java 8+).
- **Use Case**: Chaining asynchronous tasks, handling callbacks, or combining results.
- **Key Features**:
    - Supports non-blocking callbacks (`thenApply`, `thenAccept`).
    - Combines multiple futures (`allOf`, `anyOf`).
    - Rich exception handling.
- **Package**: `java.util.concurrent`.

### Exception Handling

- Essential for robust concurrent applications to handle task failures, timeouts, and cancellations gracefully.

---

## 1. ThreadPoolExecutor

### Overview

- **Class**: `ThreadPoolExecutor` extends `AbstractExecutorService`, which implements `ExecutorService`, which extends `Executor`.
- **Purpose**: Manages a pool of threads to execute `Runnable` or `Callable` tasks, with configurable policies for thread creation, queuing, and rejection.
- **Key Concepts**:
    - **Core Pool Size**: Minimum number of threads kept alive.
    - **Maximum Pool Size**: Maximum threads allowed.
    - **Work Queue**: Holds tasks when all threads are busy (e.g., `LinkedBlockingQueue`).
    - **Thread Factory**: Creates new threads.
    - **RejectedExecutionHandler**: Handles tasks when the queue is full and no threads are available.

### Key Methods (Including Super Methods from ExecutorService and Executor)

- **From Executor Interface**:
    - `void execute(Runnable command)`: Executes a `Runnable` task asynchronously (no return value).
- **From ExecutorService Interface**:
    - `Future<?> submit(Runnable task)`: Submits a `Runnable`, returns a `Future` for tracking.
    - `<T> Future<T> submit(Callable<T> task)`: Submits a `Callable`, returns a `Future` for the result.
    - `<T> Future<T> submit(Runnable task, T result)`: Submits a `Runnable` with a specified result.
    - `void shutdown()`: Initiates orderly shutdown (no new tasks, completes existing ones).
    - `List<Runnable> shutdownNow()`: Attempts to stop all tasks, returns unexecuted tasks.
    - `boolean isShutdown()`: Checks if shutdown has been initiated.
    - `boolean isTerminated()`: Checks if all tasks have completed after shutdown.
    - `boolean awaitTermination(long timeout, TimeUnit unit)`: Waits for termination or timeout.
    - `<T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks)`: Executes all tasks, returns a list of `Future`s.
    - `<T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit)`: Executes all tasks with a timeout.
    - `<T> T invokeAny(Collection<? extends Callable<T>> tasks)`: Executes tasks, returns the result of one that completes.
    - `<T> T invokeAny(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit)`: Executes tasks with a timeout.
- **From AbstractExecutorService**:
    - Provides default implementations for `submit`, `invokeAll`, and `invokeAny`.
- **From ThreadPoolExecutor**:
    - **Constructors**:
        - `ThreadPoolExecutor(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue)`
        - `ThreadPoolExecutor(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue, ThreadFactory threadFactory)`
        - `ThreadPoolExecutor(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue, RejectedExecutionHandler handler)`
        - `ThreadPoolExecutor(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue, ThreadFactory threadFactory, RejectedExecutionHandler handler)`
    - **Configuration**:
        - `void setCorePoolSize(int corePoolSize)`: Sets the core pool size.
        - `int getCorePoolSize()`: Gets the core pool size.
        - `void setMaximumPoolSize(int maximumPoolSize)`: Sets the maximum pool size.
        - `int getMaximumPoolSize()`: Gets the maximum pool size.
        - `void setKeepAliveTime(long time, TimeUnit unit)`: Sets the time idle threads wait before termination.
        - `long getKeepAliveTime(TimeUnit unit)`: Gets the keep-alive time.
        - `void setThreadFactory(ThreadFactory threadFactory)`: Sets the thread factory.
        - `void setRejectedExecutionHandler(RejectedExecutionHandler handler)`: Sets the rejection handler.
        - `void allowCoreThreadTimeOut(boolean value)`: Allows core threads to time out.
    - **Monitoring**:
        - `int getPoolSize()`: Returns the current number of threads.
        - `int getActiveCount()`: Returns the number of active threads.
        - `long getTaskCount()`: Returns the total tasks submitted.
        - `long getCompletedTaskCount()`: Returns the number of completed tasks.
        - `BlockingQueue<Runnable> getQueue()`: Returns the work queue.
    - **Lifecycle**:
        - `void prestartCoreThread()`: Starts a core thread.
        - `int prestartAllCoreThreads()`: Starts all core threads.
        - `boolean isTerminating()`: Checks if the executor is shutting down but not yet terminated.
    - **Rejection Handlers**:
        - `ThreadPoolExecutor.AbortPolicy`: Throws `RejectedExecutionException` (default).
        - `ThreadPoolExecutor.CallerRunsPolicy`: Executes the task in the calling thread.
        - `ThreadPoolExecutor.DiscardPolicy`: Silently discards the task.
        - `ThreadPoolExecutor.DiscardOldestPolicy`: Discards the oldest unhandled task.

### Example

```java
import java.util.concurrent.*;

public class ThreadPoolExecutorExample {
    public static void main(String[] args) throws InterruptedException {
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
            2, // core pool size
            4, // max pool size
            60, TimeUnit.SECONDS, // keep-alive time
            new LinkedBlockingQueue<>(2), // work queue
            new ThreadPoolExecutor.CallerRunsPolicy() // rejection policy
        );

        // Submit tasks
        for (int i = 0; i < 6; i++) {
            final int taskId = i;
            executor.submit(() -> {
                System.out.println("Task " + taskId + " executed by " + Thread.currentThread().getName());
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {}
            });
        }

        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);
        System.out.println("Completed tasks: " + executor.getCompletedTaskCount());
    }
}
```

- **Use Case**: Handling HTTP requests in a web server with a bounded thread pool.

---

## 2. Future

### Overview

- **Interface**: `Future<V>` (from `java.util.concurrent`).
- **Purpose**: Represents the result of an asynchronous task, allowing retrieval, cancellation, or status checking.
- **Use Case**: Tracking task completion in an executor.

### Key Methods

- `boolean cancel(boolean mayInterruptIfRunning)`: Attempts to cancel the task; returns `true` if successful.
- `boolean isCancelled()`: Checks if the task was cancelled before completion.
- `boolean isDone()`: Checks if the task is completed (success, failure, or cancellation).
- `V get()`: Blocks until the result is available or throws an exception.
- `V get(long timeout, TimeUnit unit)`: Blocks until the result is available or the timeout expires.

### Example

```java
import java.util.concurrent.*;

public class FutureExample {
    public static void main(String[] args) throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        Future<Integer> future = executor.submit(() -> {
            Thread.sleep(1000);
            return 42;
        });

        System.out.println("Is Done? " + future.isDone()); // Output: false
        int result = future.get(); // Blocks until result
        System.out.println("Result: " + result); // Output: 42
        System.out.println("Is Done? " + future.isDone()); // Output: true

        executor.shutdown();
    }
}
```

- **Use Case**: Retrieving results from a database query executed asynchronously.

---

## 3. CompletableFuture

### Overview

- **Class**: `CompletableFuture<T>` implements `Future<T>` and `CompletionStage<T>` (Java 8+).
- **Purpose**: Provides a flexible, non-blocking way to handle asynchronous computations with functional-style operations.
- **Key Features**:
    - Supports chaining (`thenApply`, `thenCompose`).
    - Handles multiple futures (`allOf`, `anyOf`).
    - Rich exception handling (`exceptionally`, `handle`).
    - Manual completion (`complete`, `completeExceptionally`).

### Key Methods

#### Creation

- `static CompletableFuture<Void> runAsync(Runnable runnable)`: Runs a `Runnable` asynchronously (no return value).
- `static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier)`: Runs a `Supplier` asynchronously, returning a result.
- `static <U> CompletableFuture<U> runAsync(Runnable runnable, Executor executor)`: Uses a custom executor.
- `static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier, Executor executor)`: Uses a custom executor.
- `static CompletableFuture<Void> allOf(CompletableFuture<?>... cfs)`: Completes when all given futures complete.
- `static CompletableFuture<Object> anyOf(CompletableFuture<?>... cfs)`: Completes when any given future completes.

#### Chaining and Transformation

- `<U> CompletableFuture<U> thenApply(Function<? super T, ? extends U> fn)`: Applies a function to the result.
- `CompletableFuture<Void> thenAccept(Consumer<? super T> action)`: Consumes the result.
- `CompletableFuture<Void> thenRun(Runnable action)`: Runs an action after completion.
- `<U> CompletableFuture<U> thenCompose(Function<? super T, ? extends CompletionStage<U>> fn)`: Chains another `CompletableFuture`.
- `<U,V> CompletableFuture<V> thenCombine(CompletionStage<? extends U> other, BiFunction<? super T, ? super U, ? extends V> fn)`: Combines results of two futures.
- `<U> CompletableFuture<Void> thenAcceptBoth(CompletionStage<? extends U> other, BiConsumer<? super T, ? super U> action)`: Consumes results of two futures.

#### Exception Handling

- `CompletableFuture<T> exceptionally(Function<Throwable, ? extends T> fn)`: Handles exceptions by providing a fallback value.
- `<U> CompletableFuture<U> handle(BiFunction<? super T, Throwable, ? extends U> fn)`: Handles both result and exception.
- `CompletableFuture<T> whenComplete(BiConsumer<? super T, ? super Throwable> action)`: Executes an action on completion or exception.

#### Completion

- `boolean complete(T value)`: Completes the future with a value.
- `boolean completeExceptionally(Throwable ex)`: Completes the future with an exception.
- `void obtrudeValue(T value)`: Forces a value (rarely used).
- `void obtrudeException(Throwable ex)`: Forces an exception (rarely used).

#### Status and Cancellation

- `boolean isDone()`: Checks if the future is completed.
- `boolean isCancelled()`: Checks if the future was cancelled.
- `boolean isCompletedExceptionally()`: Checks if the future completed with an exception.
- `boolean cancel(boolean mayInterruptIfRunning)`: Attempts to cancel the future.
- `T get()`, `T get(long timeout, TimeUnit unit)`: Blocks until the result is available.
- `T join()`: Blocks until the result is available (like `get`, but throws unchecked exceptions).

#### Other

- `<U> CompletableFuture<U> thenApplyAsync(Function<? super T, ? extends U> fn)`: Asynchronous version of `thenApply`.
- `CompletableFuture<Void> thenAcceptAsync(Consumer<? super T> action)`: Asynchronous version of `thenAccept`.
- `CompletableFuture<Void> thenRunAsync(Runnable action)`: Asynchronous version of `thenRun`.
- `<U> CompletableFuture<U> thenComposeAsync(Function<? super T, ? extends CompletionStage<U>> fn)`: Asynchronous version of `thenCompose`.

### Focus: CompletableFuture.runAsync

- **Purpose**: Executes a `Runnable` asynchronously, returning a `CompletableFuture<Void>` for tracking completion.
- **Signatures**:
    - `static CompletableFuture<Void> runAsync(Runnable runnable)`: Uses the default `ForkJoinPool.commonPool()`.
    - `static CompletableFuture<Void> runAsync(Runnable runnable, Executor executor)`: Uses a custom executor.
- **Use Case**: Running background tasks without a return value (e.g., logging, notifications).

### Example

```java
import java.util.concurrent.*;

public class CompletableFutureExample {
    public static void main(String[] args) {
        ThreadPoolExecutor executor = new ThreadPoolExecutor(2, 4, 60, TimeUnit.SECONDS, new LinkedBlockingQueue<>());

        // runAsync example
        CompletableFuture<Void> future1 = CompletableFuture.runAsync(() -> {
            System.out.println("Running task in " + Thread.currentThread().getName());
        }, executor);

        // supplyAsync and chaining
        CompletableFuture<String> future2 = CompletableFuture.supplyAsync(() -> {
            return "Result";
        }, executor).thenApply(result -> result + " Processed")
                   .thenApply(String::toUpperCase);

        // Combining futures
        CompletableFuture<String> combined = future2.thenCombine(
            CompletableFuture.supplyAsync(() -> " Combined", executor),
            (s1, s2) -> s1 + s2
        );

        // Exception handling
        CompletableFuture<String> withError = CompletableFuture.supplyAsync(() -> {
            throw new RuntimeException("Task failed");
        }, executor).exceptionally(throwable -> "Recovered: " + throwable.getMessage());

        try {
            future1.join();
            System.out.println("Future2: " + future2.get()); // Output: RESULT PROCESSED
            System.out.println("Combined: " + combined.get()); // Output: RESULT PROCESSED Combined
            System.out.println("With Error: " + withError.get()); // Output: Recovered: Task failed
        } catch (Exception e) {
            e.printStackTrace();
        }

        executor.shutdown();
    }
}
```

- **Use Case**: Asynchronous processing of API requests with error recovery.

---

## 4. Exception Handling

### ThreadPoolExecutor

- **Challenges**:
    - Uncaught exceptions in `Runnable` tasks are silently swallowed.
    - `Callable` tasks propagate exceptions via `Future.get()`.
- **Strategies**:
    - **Wrap Tasks**: Use a try-catch block in the task to handle exceptions.
    - **Custom ThreadFactory**: Set an `UncaughtExceptionHandler` to log exceptions.
    - **Future.get()**: Catch `ExecutionException` or `InterruptedException`.
    - **AfterExecute Hook**: Override `ThreadPoolExecutor.afterExecute(Runnable, Throwable)` to handle exceptions.
- **Example**:

```java
import java.util.concurrent.*;

public class ThreadPoolExceptionExample extends ThreadPoolExecutor {
    public ThreadPoolExceptionExample() {
        super(2, 4, 60, TimeUnit.SECONDS, new LinkedBlockingQueue<>());
    }

    @Override
    protected void afterExecute(Runnable r, Throwable t) {
        if (t != null) {
            System.err.println("Uncaught exception: " + t);
        }
    }

    public static void main(String[] args) throws Exception {
        ThreadPoolExceptionExample executor = new ThreadPoolExceptionExample();
        executor.submit(() -> {
            throw new RuntimeException("Task error");
        });
        executor.shutdown();
    }
}
```

### Future

- **Challenges**:
    - Exceptions are thrown when calling `get()` (`ExecutionException` wraps the original exception).
    - `InterruptedException` if the thread is interrupted while waiting.
- **Strategies**:
    - Catch `ExecutionException` and `InterruptedException` in `get()`.
    - Check `isDone()` or `isCancelled()` before calling `get()`.
- **Example**:

```java
Future<Integer> future = Executors.newFixedThreadPool(1).submit(() -> {
    throw new RuntimeException("Task failed");
});
try {
    future.get(); // Throws ExecutionException
} catch (ExecutionException e) {
    System.err.println("Task exception: " + e.getCause());
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // Restore interrupted state
}
```

### CompletableFuture

- **Challenges**:
    - Exceptions in asynchronous tasks can be handled in the pipeline.
    - Unhandled exceptions may terminate the future abnormally.
- **Strategies**:
    - Use `exceptionally(Function<Throwable, T>)` to provide a fallback.
    - Use `handle(BiFunction<T, Throwable, U>)` to process both results and exceptions.
    - Use `whenComplete(BiConsumer<T, Throwable>)` for logging or cleanup.
    - Catch exceptions in `get()` or `join()` for synchronous access.
- **Example**:

```java
CompletableFuture.supplyAsync(() -> {
    throw new RuntimeException("Async error");
}).exceptionally(throwable -> "Recovered").whenComplete((result, ex) -> {
    if (ex != null) {
        System.err.println("Error occurred: " + ex);
    } else {
        System.out.println("Result: " + result);
    }
}).join(); // Output: Result: Recovered
```

---

## Best Practices for Legendary Backend Developers

- **ThreadPoolExecutor**:
    - **Tune Pool Size**: Set `corePoolSize` and `maximumPoolSize` based on workload (e.g., CPU-bound vs. I/O-bound).
    - **Choose Work Queue**: Use `LinkedBlockingQueue` for bounded queues, `SynchronousQueue` for direct handoff.
    - **Handle Rejections**: Use `CallerRunsPolicy` for backpressure or custom handlers for logging.
    - **Shutdown Gracefully**: Call `shutdown()` and `awaitTermination` to ensure clean termination.
    - **Monitor**: Use `getActiveCount`, `getTaskCount` for monitoring thread usage.
- **Future**:
    - Use for simple asynchronous tasks with result retrieval.
    - Always handle `ExecutionException` and `InterruptedException` in `get()`.
    - Avoid blocking (`get()`) in performance-critical paths; use `CompletableFuture` instead.
- **CompletableFuture**:
    - Use `runAsync` for tasks without results, `supplyAsync` for tasks with results.
    - Chain operations with `thenApply`, `thenCompose`, or `thenCombine` for complex workflows.
    - Use `exceptionally` or `handle` for robust error handling.
    - Prefer `join()` over `get()` for unchecked exceptions in non-blocking code.
    - Use custom executors (`runAsync(runnable, executor)`) for fine-grained control.
- **Exception Handling**:
    - Wrap task logic in try-catch to handle exceptions locally.
    - Use `ThreadPoolExecutor.afterExecute` for centralized exception handling.
    - Use `CompletableFuture`’s `exceptionally` or `handle` for asynchronous error recovery.
    - Restore interrupted state when catching `InterruptedException`.
- **Performance**:
    - Avoid oversized thread pools (leads to resource exhaustion).
    - Use `CompletableFuture.allOf` for parallel task execution.
    - Benchmark custom executors vs. `ForkJoinPool.commonPool()` for `CompletableFuture`.
- **Thread Safety**:
    - Ensure tasks are stateless or thread-safe to avoid race conditions.
    - Use `CompletableFuture` for non-blocking workflows instead of `Future.get()`.

---

## Practical Example: Asynchronous API Processor

Below is an example of a thread-safe API processor using `ThreadPoolExecutor`, `Future`, and `CompletableFuture` with exception handling.

```java
import java.util.*;
import java.util.concurrent.*;

public class ApiProcessor {
    private final ThreadPoolExecutor executor = new ThreadPoolExecutor(
        2, 4, 60, TimeUnit.SECONDS, new LinkedBlockingQueue<>(10),
        new ThreadPoolExecutor.CallerRunsPolicy()
    );

    public CompletableFuture<String> processRequest(String input) {
        return CompletableFuture.supplyAsync(() -> {
            // Simulate API call
            try {
                Thread.sleep(1000);
                if (input == null) throw new IllegalArgumentException("Null input");
                return "Processed: " + input;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Interrupted", e);
            }
        }, executor).exceptionally(throwable -> "Error: " + throwable.getMessage());
    }

    public Future<Integer> computeResult(int value) {
        return executor.submit(() -> {
            if (value < 0) throw new IllegalArgumentException("Negative value");
            return value * 2;
        });
    }

    public static void main(String[] args) throws Exception {
        ApiProcessor processor = new ApiProcessor();

        // CompletableFuture example
        List<CompletableFuture<String>> futures = Arrays.asList(
            processor.processRequest("Task1"),
            processor.processRequest(null), // Will trigger exception
            processor.processRequest("Task2")
        );

        CompletableFuture<Void> all = CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]));
        all.thenRun(() -> futures.forEach(f -> System.out.println(f.join())));
        // Output: Processed: Task1
        //         Error: Null input
        //         Processed: Task2

        // Future example
        Future<Integer> future = processor.computeResult(-1);
        try {
            System.out.println("Result: " + future.get());
        } catch (ExecutionException e) {
            System.err.println("Future error: " + e.getCause());
        }

        processor.executor.shutdown();
        processor.executor.awaitTermination(5, TimeUnit.SECONDS);
    }
}
```

- **Components**:
    - `ThreadPoolExecutor`: Manages a thread pool for task execution.
    - `Future`: Tracks results of a computation.
    - `CompletableFuture`: Handles asynchronous API processing with error recovery.
- **Use Case**: Asynchronous request processing in a REST API server.

---

## Benefits

- **ThreadPoolExecutor**: Efficient thread management, configurable policies.
- **Future**: Simple tracking of asynchronous task results.
- **CompletableFuture**: Non-blocking, functional-style asynchronous programming with rich error handling.
- **Scalability**: Suitable for high-throughput backend systems.

## Limitations

- **ThreadPoolExecutor**: Requires careful tuning to avoid resource exhaustion or contention.
- **Future**: Limited flexibility (blocking `get()`, no chaining).
- **CompletableFuture**: Complex pipelines can be hard to debug.
- **Exception Handling**: Requires explicit handling to avoid silent failures.

## Resources

- Java Concurrency: [java.util.concurrent](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/package-summary.html)
- ThreadPoolExecutor: [ThreadPoolExecutor API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/ThreadPoolExecutor.html)
- CompletableFuture: [CompletableFuture API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CompletableFuture.html)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)

[[44 - Threads 🧀]]