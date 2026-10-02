
> `CompletableFuture` in the `java.util.concurrent` package enables asynchronous programming in Java, allowing you to compose and chain operations efficiently in multi-threaded applications like web servers or microservices. It provides a flexible way to handle asynchronous tasks, combine results, and manage exceptions. This document focuses on key `CompletableFuture` methods—`supplyAsync()`, `thenApply()`, `thenCombine()`, and `exceptionally()`—with concise explanations and practical examples for backend development.

---

## Overview of CompletableFuture

- **Purpose**: Represents a future result of an asynchronous computation, supporting chaining, composition, and exception handling.
- **Key Features**:
    - Non-blocking, asynchronous task execution.
    - Functional-style methods for composing operations.
    - Built-in exception handling.
- **Use Case**: Asynchronous API calls, parallel data processing, or task orchestration.

---

## Key Methods

### 1. supplyAsync()

- **Purpose**: Starts an asynchronous computation, returning a `CompletableFuture` with the result.
- **Signatures**:
    ```java
    static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier)
    static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier, Executor           executor)
    ```
- **Behavior**: Runs the `Supplier` in a thread pool (default: `ForkJoinPool.commonPool()` or a custom `Executor`).

### 2. thenApply()

- **Purpose**: Transforms the result of a `CompletableFuture` when it completes.
- **Signature**: `<U> CompletableFuture<U> thenApply(Function<? super T, ? extends U> fn)`
- **Behavior**: Applies the function to the result, returning a new `CompletableFuture`.

### 3. thenCombine()

- **Purpose**: Combines the results of two `CompletableFuture` instances.
- **Signature**: `<U,V> CompletableFuture<V> thenCombine(CompletionStage<? extends U> other, BiFunction<? super T, ? super U, ? extends V> fn)`
- **Behavior**: Waits for both futures to complete, then applies the `BiFunction` to their results.

### 4. exceptionally()

- **Purpose**: Handles exceptions in a `CompletableFuture` chain.
- **Signature**: `CompletableFuture<T> exceptionally(Function<Throwable, ? extends T> fn)`
- **Behavior**: Provides a fallback result if an exception occurs.

---

> By default, CompletableFuture uses the ForkJoinPool. commonPool() for executing tasks. However, **using a custom ExecutorService allows you to better manage threading, optimize resource usage, and handle specific requirements**

---

## Example: Basic CompletableFuture Usage

```java
import java.util.concurrent.*;

public class BasicCompletableFuture {
    public static void main(String[] args) throws Exception {
        // supplyAsync: Start async task
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(1000); } catch (InterruptedException e) {}
            return "Hello";
        });

        // thenApply: Transform result
        CompletableFuture<String> transformed = future.thenApply(s -> s + ", World!");

        // Get result
        System.out.println(transformed.get()); // Output: Hello, World!
    }
}
```

- **Use Case**: Transforming data from an async API call.

---

## Example: Combining Futures with thenCombine

```java
import java.util.concurrent.*;

public class CombineCompletableFuture {
    public static void main(String[] args) throws Exception {
        CompletableFuture<Integer> future1 = CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(1000); } catch (InterruptedException e) {}
            return 5;
        });

        CompletableFuture<Integer> future2 = CompletableFuture.supplyAsync(() -> {
            try { Thread.sleep(500); } catch (InterruptedException e) {}
            return 10;
        });

        // thenCombine: Combine results
        CompletableFuture<Integer> combined = future1.thenCombine(future2, (a, b) -> a + b);

        System.out.println("Sum: " + combined.get()); // Output: Sum: 15
    }
}
```

- **Use Case**: Aggregating results from multiple async tasks (e.g., fetching data from two services).

---

## Example: Exception Handling with exceptionally

```java
import java.util.concurrent.*;

public class ExceptionHandlingCompletableFuture {
    public static void main(String[] args) throws Exception {
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
            if (true) throw new RuntimeException("Task failed");
            return "Success";
        });

        // exceptionally: Handle exception
        CompletableFuture<String> handled = future.exceptionally(throwable -> "Fallback: " + throwable.getMessage());

        System.out.println(handled.get()); // Output: Fallback: java.lang.RuntimeException: Task failed
    }
}
```

- **Use Case**: Handling errors in async API calls.

---

## Practical Example: Async Task Processor

```java
import java.util.concurrent.*;
import java.util.*;

public class AsyncTaskProcessor {
    private final ExecutorService executor = Executors.newFixedThreadPool(4);

    public CompletableFuture<List<Integer>> processTasksAsync(List<Integer> inputs) {
        // Create async tasks
        List<CompletableFuture<Integer>> futures = inputs.stream()
            .map(input -> CompletableFuture.supplyAsync(() -> {
                try { Thread.sleep(500); } catch (InterruptedException e) {}
                if (input < 0) throw new IllegalArgumentException("Negative input: " + input);
                return input * 2;
            }, executor))
            .map(future -> future.thenApply(result -> result + 1))
            .map(future -> future.exceptionally(throwable -> 0))
            .toList();

        // Combine results
        return CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
            .thenApply(v -> futures.stream()
                .map(f -> f.join()) // Non-blocking join
                .toList());
    }

    public void shutdown() throws InterruptedException {
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);
    }

    public static void main(String[] args) throws Exception {
        AsyncTaskProcessor processor = new AsyncTaskProcessor();
        List<Integer> inputs = Arrays.asList(1, 2, -3, 4);
        CompletableFuture<List<Integer>> result = processor.processTasksAsync(inputs);
        System.out.println("Results: " + result.get()); // Output: Results: [3, 5, 0, 9]
        processor.shutdown();
    }
}
```

- **Components**:
    - `supplyAsync`: Runs tasks asynchronously in a thread pool.
    - `thenApply`: Transforms each task result.
    - `exceptionally`: Handles errors (e.g., negative inputs).
    - `thenCombine` (implicit via `allOf`): Combines results.
- **Use Case**: Processing multiple tasks in parallel (e.g., batch processing in a microservice).

---

## Best Practices

- **Use supplyAsync with Custom Executor**: Specify an `Executor` for controlled thread management.
    - Example: `supplyAsync(task, Executors.newFixedThreadPool(4))`.
- **Chain Operations with thenApply**: Transform results without blocking.
    - Example: `future.thenApply(x -> x * 2)`.
- **Combine Futures with thenCombine**: Aggregate results from multiple async tasks.
    - Example: `future1.thenCombine(future2, (a, b) -> a + b)`.
- **Handle Exceptions with exceptionally**: Provide fallbacks for errors.
    - Example: `future.exceptionally(t -> defaultValue)`.
- **Use allOf for Multiple Futures**: Wait for multiple tasks to complete.
    - Example: `CompletableFuture.allOf(future1, future2)`.
- **Avoid Blocking Unnecessarily**: Use `thenApply`, `thenCompose`, or `thenCombine` instead of `get()` where possible.
- **Shutdown Executors**: Call `shutdown()` and `awaitTermination()` to clean up resources.
- **Handle Timeouts**: Use `orTimeout(long timeout, TimeUnit unit)` or `completeOnTimeout(T value, long timeout, TimeUnit unit)` for timeouts.

---

## Pros and Cons

### Pros

- **Non-Blocking**: Enables asynchronous, responsive applications.
- **Composability**: Chains operations with functional-style methods.
- **Exception Handling**: Built-in mechanisms like `exceptionally`.
- **Flexibility**: Supports custom executors and complex workflows.

### Cons

- **Complexity**: Chaining and error handling can be verbose.
- **Resource Management**: Requires careful executor shutdown.
- **Blocking Risk**: Misuse of `get()` can block threads.
- **Learning Curve**: Requires understanding of async programming concepts.

---

## Resources

- CompletableFuture: [CompletableFuture API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CompletableFuture.html)
- Java Concurrency: [java.util.concurrent](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/package-summary.html)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)


[[44 - Threads 🧀]]