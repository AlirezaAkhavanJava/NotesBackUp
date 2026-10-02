

The **Java Concurrent package** (`java.util.concurrent`), introduced in Java 5, provides a robust framework for building concurrent, thread-safe, and scalable applications. It offers high-level APIs for thread management, task execution, synchronization, and concurrent data structures, simplifying the complexities of multithreaded programming. The package is designed to improve performance and reliability in concurrent environments while reducing common threading issues like race conditions and deadlocks.

## Overview

- **Purpose**: Facilitates concurrent programming with abstractions for thread pools, task scheduling, synchronization, and thread-safe collections.
- **Key Features**:
    - **Thread Management**: Thread pools and executors for efficient thread reuse.
    - **Synchronization**: Advanced locking mechanisms and atomic operations.
    - **Concurrent Collections**: Thread-safe data structures optimized for concurrency.
    - **Task Abstraction**: Simplifies asynchronous task execution and coordination.
    - **Scalability**: Supports high-performance, scalable applications with minimal contention.
- **Use Cases**: Multithreaded applications, parallel task execution, thread-safe data sharing, and asynchronous processing.

## Key Interfaces

The `java.util.concurrent` package includes several core interfaces that define the behavior of concurrent constructs.

### 1. **Executor**

- **Purpose**: A simple interface for executing tasks asynchronously, decoupling task submission from execution.
- **Key Method**:
    - `void execute(Runnable command)`: Executes a task asynchronously.
- **Use Case**: Basis for thread pool execution, used by more advanced executor implementations.
- **Example**:

```java
Executor executor = Runnable::run;
executor.execute(() -> System.out.println("Task executed"));
```

### 2. **ExecutorService**

- **Purpose**: Extends `Executor` to manage a pool of threads and support task submission, shutdown, and future results.
- **Key Methods**:
    - `submit(Runnable task)`: Submits a task and returns a `Future`.
    - `submit(Callable<T> task)`: Submits a task that returns a value, returning a `Future<T>`.
    
    - `shutdown()`: Initiates graceful shutdown of the executor.
    
    - `awaitTermination(long timeout, TimeUnit unit)`: Waits for tasks to complete after shutdown.
    
    - `invokeAll(Collection<? extends Callable<T>> tasks)`: Executes all tasks and returns a list of `Future<T>`.
    
    - `invokeAny(Collection<? extends Callable<T>> tasks)`: Executes tasks and returns the result of one that completes.
    
- **Use Case**: Managing thread pools and task lifecycles.
- **Example**:

```java
ExecutorService executor = Executors.newFixedThreadPool(2);
Future<Integer> future = executor.submit(() -> 42);
System.out.println(future.get()); // Output: 42
executor.shutdown();
```

### 3. **ScheduledExecutorService**

- **Purpose**: Extends `ExecutorService` to support scheduled and periodic task execution.
- **Key Methods**:
    - `schedule(Runnable command, long delay, TimeUnit unit)`: Schedules a task to run after a delay.
    - `scheduleAtFixedRate(Runnable command, long initialDelay, long period, TimeUnit unit)`: Runs a task periodically with a fixed rate.
    - `scheduleWithFixedDelay(Runnable command, long initialDelay, long delay, TimeUnit unit)`: Runs a task with a fixed delay between executions.
- **Use Case**: Scheduling tasks for delayed or recurring execution.
- **Example**:

```java
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
scheduler.schedule(() -> System.out.println("Task ran"), 1, TimeUnit.SECONDS);
scheduler.shutdown();
```

### 4. **Future**

- **Purpose**: Represents the result of an asynchronous computation, allowing retrieval of results or cancellation.
- **Key Methods**:
    - `get()`: Blocks until the result is available or throws an exception.
    - `get(long timeout, TimeUnit unit)`: Blocks with a timeout.
    - `cancel(boolean mayInterruptIfRunning)`: Attempts to cancel the task.
    - `isDone()`: Checks if the task is complete.
    - `isCancelled()`: Checks if the task was cancelled.
- **Use Case**: Handling results of asynchronous tasks.
- **Example**:

```java
Future<String> future = Executors.newSingleThreadExecutor().submit(() -> "Result");
System.out.println(future.get()); // Output: Result
```

### 5. **CompletableFuture**

- **Purpose**: A powerful implementation of `Future` that supports asynchronous, non-blocking programming with chaining and composition.
- **Key Methods**:
    - `supplyAsync(Supplier<T> supplier)`: Runs a supplier asynchronously.
    - `runAsync(Runnable runnable)`: Runs a task asynchronously without a return value.
    - `thenApply(Function<T, U> fn)`: Chains a transformation on the result.
    - `thenAccept(Consumer<T> action)`: Consumes the result.
    - `thenCombine(CompletionStage<U> other, BiFunction<T, U, V> fn)`: Combines results of two futures.
    - `exceptionally(Function<Throwable, T> fn)`: Handles exceptions.
    - `complete(T value)`: Completes the future manually.
- **Use Case**: Asynchronous workflows, reactive programming, and task orchestration.
- **Example**:

```java
CompletableFuture.supplyAsync(() -> "Hello")
    .thenApply(String::toUpperCase)
    .thenAccept(System.out::println); // Output: HELLO
```

### 6. **BlockingQueue**

- **Purpose**: A queue interface that supports blocking operations for thread-safe producer-consumer patterns.
- **Key Methods**:
    - `put(E e)`: Adds an element, blocking if the queue is full.
    - `take()`: Retrieves and removes an element, blocking if the queue is empty.
    - `offer(E e, long timeout, TimeUnit unit)`: Adds an element with a timeout.
    - `poll(long timeout, TimeUnit unit)`: Retrieves an element with a timeout.
- **Use Case**: Thread-safe data exchange between producers and consumers.
- **Implementations**: `ArrayBlockingQueue`, `LinkedBlockingQueue`, `PriorityBlockingQueue`.

### 7. **ConcurrentMap<K, V>**

- **Purpose**: Extends `Map` to provide thread-safe operations for key-value mappings.
- **Key Methods**:
    - `putIfAbsent(K key, V value)`: Adds a key-value pair if the key is absent.
    - `replace(K key, V oldValue, V newValue)`: Replaces a value if the current value matches.
    - `computeIfAbsent(K key, Function<K, V> mappingFunction)`: Computes a value if absent.
- **Use Case**: Thread-safe map operations without explicit locking.
- **Implementations**: `ConcurrentHashMap`.

## Key Classes

The package includes utility and implementation classes for concurrency.

### 1. **Executors**

- **Purpose**: A utility class providing factory methods for creating `ExecutorService` and `ScheduledExecutorService` instances.
- **Key Static Methods**:
    - `newFixedThreadPool(int nThreads)`: Creates a thread pool with a fixed number of threads.
    - `newCachedThreadPool()`: Creates a thread pool that creates threads as needed and reuses idle threads.
    - `newSingleThreadExecutor()`: Creates an executor with a single thread.
    - `newScheduledThreadPool(int corePoolSize)`: Creates a thread pool for scheduled tasks.
    - `callable(Runnable task, T result)`: Converts a `Runnable` to a `Callable`.
- **Use Case**: Simplifying thread pool creation.
- **Example**:

```java
ExecutorService executor = Executors.newFixedThreadPool(2);
executor.submit(() -> System.out.println("Task"));
executor.shutdown();
```

### 2. **ConcurrentHashMap<K, V>**

- **Purpose**: A thread-safe implementation of `ConcurrentMap` with high concurrency performance.
- **Key Features**:
    - Lock-free reads and fine-grained locking for writes.
    - Supports concurrent updates without external synchronization.
- **Key Methods**: (In addition to `ConcurrentMap` methods)
    - `forEach(BiConsumer<? super K, ? super V> action)`: Performs an action for each entry.
    - `search(Function<Map.Entry<K, V>, U> searchFunction)`: Searches for a result across entries.
- **Use Case**: High-performance, thread-safe key-value storage.
- **Example**:

```java
ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();
map.putIfAbsent("key", 1);
System.out.println(map.get("key")); // Output: 1
```

### 3. **CopyOnWriteArrayList**

- **Purpose**: A thread-safe `List` that creates a new copy of the underlying array for each modification.
- **Key Features**:
    - Ideal for read-heavy scenarios where writes are rare.
    - Iterators reflect the state at creation time (snapshot semantics).
- **Use Case**: Thread-safe lists with frequent iteration and infrequent modifications.
- **Example**:

```java
CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();
list.add("Item");
list.forEach(System.out::println); // Output: Item
```

### 4. **ArrayBlockingQueue**

- **Purpose**: A bounded, thread-safe queue with a fixed capacity, implementing `BlockingQueue`.
- **Key Features**:
    - Blocks on `put` when full and `take` when empty.
    - FIFO ordering.
- **Use Case**: Producer-consumer scenarios with fixed-size buffers.
- **Example**:

```java
BlockingQueue<String> queue = new ArrayBlockingQueue<>(2);
queue.put("Task1");
System.out.println(queue.take()); // Output: Task1
```

### 5. **LinkedBlockingQueue**

- **Purpose**: An optionally bounded, thread-safe queue based on linked nodes, implementing `BlockingQueue`.
- **Key Features**:
    - Supports unbounded or bounded configurations.
    - FIFO ordering.
- **Use Case**: Flexible queue for producer-consumer patterns.
- **Example**:

```java
BlockingQueue<String> queue = new LinkedBlockingQueue<>();
queue.offer("Task");
```

### 6. **CountDownLatch**

- **Purpose**: A synchronization aid that allows threads to wait until a set of operations completes.
- **Key Methods**:
    - `countDown()`: Decrements the latch count.
    - `await()`: Blocks until the count reaches zero.
    - `await(long timeout, TimeUnit unit)`: Waits with a timeout.
- **Use Case**: Coordinating task completion across threads.
- **Example**:

```java
CountDownLatch latch = new CountDownLatch(2);
new Thread(() -> { latch.countDown(); }).start();
new Thread(() -> { latch.countDown(); }).start();
latch.await(); // Waits until count is 0
System.out.println("Tasks complete");
```

### 7. **CyclicBarrier**

- **Purpose**: A synchronization aid that allows a set of threads to wait until all reach a common barrier point.
- **Key Methods**:
    - `await()`: Waits until all parties reach the barrier.
    - `await(long timeout, TimeUnit unit)`: Waits with a timeout.
- **Use Case**: Coordinating threads that must proceed together.
- **Example**:

```java
CyclicBarrier barrier = new CyclicBarrier(2);
new Thread(() -> { try { barrier.await(); System.out.println("Passed"); } catch (Exception e) {} }).start();
new Thread(() -> { try { barrier.await(); System.out.println("Passed"); } catch (Exception e) {} }).start();
```

### 8. **Semaphore**

- **Purpose**: Controls access to a shared resource by maintaining a set of permits.
- **Key Methods**:
    - `acquire()`: Acquires a permit, blocking if none are available.
    - `release()`: Releases a permit.
    - `tryAcquire()`: Attempts to acquire a permit without blocking.
- **Use Case**: Limiting concurrent access to resources.
- **Example**:

```java
Semaphore semaphore = new Semaphore(2);
semaphore.acquire();
try { System.out.println("Access granted"); } finally { semaphore.release(); }
```

## Utility Classes

The package includes utility classes for common concurrency patterns.

### 1. **Executors**

- **Covered Above**: Factory methods for creating thread pools and executors.
- **Additional Utility**:
    - `defaultThreadFactory()`: Creates a default thread factory.
    - `unconfigurableExecutorService(ExecutorService executor)`: Wraps an executor to prevent configuration changes.

### 2. **TimeUnit**

- **Purpose**: Represents time durations in various units (e.g., seconds, milliseconds).
- **Key Methods**:
    - `toMillis(long duration)`: Converts duration to milliseconds.
    - `sleep(long timeout)`: Sleeps for the specified duration.
    - `convert(long sourceDuration, TimeUnit sourceUnit)`: Converts between units.
- **Use Case**: Standardizing time-based operations in concurrent APIs.
- **Example**:

```java
TimeUnit.SECONDS.sleep(1); // Sleeps for 1 second
```

### 3. **ConcurrentLinkedQueue**

- **Purpose**: An unbounded, thread-safe queue based on linked nodes, implementing `Queue`.
- **Key Features**:
    - Lock-free, non-blocking operations.
    - FIFO ordering.
- **Use Case**: High-throughput, thread-safe queuing.
- **Example**:

```java
ConcurrentLinkedQueue<String> queue = new ConcurrentLinkedQueue<>();
queue.offer("Task");
System.out.println(queue.poll()); // Output: Task
```

## Example Combining Multiple Components

```java
import java.util.concurrent.*;
import java.util.Arrays;

public class ConcurrentExample {
    public static void main(String[] args) throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();
        CountDownLatch latch = new CountDownLatch(2);

        // Submit tasks
        executor.submit(() -> {
            map.put("A", 1);
            latch.countDown();
        });
        executor.submit(() -> {
            map.put("B", 2);
            latch.countDown();
        });

        latch.await(); // Wait for tasks to complete
        System.out.println(map); // Output: {A=1, B=2}
        executor.shutdown();
    }
}
```

## Benefits

- **Simplified Concurrency**: High-level APIs reduce manual thread management.
- **Thread Safety**: Concurrent collections and synchronization aids prevent race conditions.
- **Scalability**: Thread pools and lock-free structures optimize performance.
- **Flexibility**: Supports both synchronous and asynchronous programming models.

## Limitations

- **Complexity**: Concurrent programming requires understanding of threading issues (e.g., deadlocks, starvation).
- **Overhead**: Thread pools and synchronization mechanisms may introduce overhead for simple tasks.
- **Debugging**: Harder to debug due to non-deterministic thread behavior.

## Resources

- Oracle Documentation: [java.util.concurrent](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/package-summary.html)














##### Tags : [[44 - Threads 🧀]]