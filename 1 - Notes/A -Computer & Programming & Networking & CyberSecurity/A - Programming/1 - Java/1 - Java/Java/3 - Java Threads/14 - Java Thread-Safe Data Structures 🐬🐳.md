

### Purpose

- **Thread Safety**: Ensure safe concurrent access to shared data without race conditions.
- **Performance**: Optimize for high-concurrency scenarios, minimizing contention.
- **Scalability**: Support multi-threaded applications with efficient synchronization.

### Key Collections in java.util.concurrent

- **ConcurrentHashMap**: A thread-safe hash table with fine-grained locking for high concurrency.
- **CopyOnWriteArrayList**: A thread-safe list that creates a new copy for modifications, ideal for read-heavy scenarios.
- **ConcurrentLinkedQueue**: A thread-safe, non-blocking queue for FIFO operations.
- **BlockingQueue**: Interfaces like `ArrayBlockingQueue` and `LinkedBlockingQueue` for producer-consumer patterns.
- **ConcurrentSkipListMap/Set**: Thread-safe sorted map/set with concurrent access.

### Non-Thread-Safe Collections

- **ArrayList**: A dynamic array, not thread-safe, prone to race conditions in concurrent environments.
- **HashMap**: A hash table, not thread-safe, may corrupt under concurrent modifications.
- **LinkedList**: A doubly-linked list, not thread-safe, unsuitable for concurrent access.

### Why Thread-Safe Collections?

- Avoid manual synchronization (e.g., `synchronized` blocks or `ReentrantLock`), reducing complexity and errors.
- Optimize performance for specific concurrency patterns (e.g., read-heavy or write-heavy workloads).
- Ensure data consistency in multi-threaded applications.

---

## 1. ConcurrentHashMap

### Overview

- **Purpose**: A thread-safe implementation of `Map` that supports high concurrency with fine-grained locking.
- **Key Features**:
    - **Segmented Locking**: Divides the map into segments (Java 7) or uses lock-free techniques (Java 8+) for concurrent updates.
    - **Atomic Operations**: Methods like `putIfAbsent()`, `compute()`, and `merge()` are atomic.
    - **Null Handling**: Does not allow `null` keys or values.
    - **Iteration**: Weakly consistent iterators that reflect updates without throwing `ConcurrentModificationException`.

### Key Methods

- **Basic Operations**:
    - `V put(K key, V value)`: Adds or updates a key-value pair.
    - `V get(Object key)`: Retrieves the value for a key.
    - `V remove(Object key)`: Removes a key-value pair.
- **Atomic Operations**:
    - `V putIfAbsent(K key, V value)`: Adds a key-value pair if the key is absent.
    - `boolean replace(K key, V oldValue, V newValue)`: Replaces a value if the current value matches.
    - `V compute(K key, BiFunction<? super K, ? super V, ? extends V> remappingFunction)`: Atomically updates a value.
    - `V merge(K key, V value, BiFunction<? super V, ? super V, ? extends V> remappingFunction)`: Merges a value with an existing one.
- **Bulk Operations**:
    - `forEach(BiConsumer<? super K, ? super V> action)`: Iterates over entries.
    - `search(Function<? super K, ? extends U> searchFunction)`: Searches for a value.

### Example

```java
import java.util.concurrent.ConcurrentHashMap;

public class ConcurrentHashMapExample {
    public static void main(String[] args) throws InterruptedException {
        ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();

        Runnable task = () -> {
            for (int i = 0; i < 1000; i++) {
                map.compute("key", (k, v) -> v == null ? 1 : v + 1);
            }
        };

        Thread t1 = new Thread(task);
        Thread t2 = new Thread(task);
        t1.start();
        t2.start();
        t1.join();
        t2.join();

        System.out.println("Value: " + map.get("key")); // Output: 2000
    }
}
```

- **Use Case**: Thread-safe counter for tracking API request counts in a web server.

### Comparison with HashMap

- **Thread Safety**:
    - `HashMap`: Not thread-safe; concurrent modifications cause race conditions or corruption.
    - `ConcurrentHashMap`: Thread-safe with fine-grained locking or lock-free techniques.
- **Performance**:
    - `HashMap`: Faster for single-threaded applications due to no synchronization.
    - `ConcurrentHashMap`: Optimized for concurrent access, scales better under high concurrency.
- **Null Handling**:
    - `HashMap`: Allows `null` keys and values.
    - `ConcurrentHashMap`: Prohibits `null` keys and values.
- **Iteration**:
    - `HashMap`: Throws `ConcurrentModificationException` if modified during iteration.
    - `ConcurrentHashMap`: Weakly consistent iterators, safe for concurrent modifications.

### Where to Use

- **High-Concurrency Maps**: Caching, session management, or shared configurations.
- **Atomic Updates**: Scenarios requiring `putIfAbsent`, `compute`, or `merge`.
- **Read-Heavy Workloads**: Frequent reads with occasional writes.

### Why to Use

- **Scalability**: Efficient for multiple threads due to fine-grained locking.
- **Atomicity**: Built-in atomic operations reduce the need for external synchronization.
- **Safety**: Prevents data corruption without manual locks.

---

## 2. CopyOnWriteArrayList

### Overview

- **Purpose**: A thread-safe implementation of `List` that creates a new copy of the underlying array on each modification.
- **Key Features**:
    - **Copy-on-Write**: Modifications (e.g., `add`, `remove`) create a new array, leaving the old array unchanged for readers.
    - **Read Efficiency**: Reads are lock-free, ideal for read-heavy scenarios.
    - **Iteration**: Iterators reflect the state at creation time, safe from concurrent modifications.
    - **Memory Overhead**: Copies consume more memory, unsuitable for large lists or frequent writes.

### Key Methods

- **Basic Operations**:
    - `boolean add(E element)`: Adds an element, creating a new array copy.
    - `E get(int index)`: Retrieves an element (lock-free).
    - `E remove(int index)`: Removes an element, creating a new array copy.
- **Bulk Operations**:
    - `addAll(Collection<? extends E> c)`: Adds all elements from a collection.
    - `forEach(Consumer<? super E> action)`: Iterates over elements.
- **Iteration**:
    - `Iterator<E> iterator()`: Returns a snapshot iterator, unaffected by modifications.

### Example

```java
import java.util.concurrent.CopyOnWriteArrayList;

public class CopyOnWriteArrayListExample {
    public static void main(String[] args) throws InterruptedException {
        CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();

        Runnable writer = () -> {
            for (int i = 0; i < 100; i++) {
                list.add("Item-" + i);
            }
        };

        Runnable reader = () -> {
            for (String item : list) {
                System.out.println(Thread.currentThread().getName() + " read: " + item);
                try {
                    Thread.sleep(10);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        };

        Thread t1 = new Thread(writer);
        Thread t2 = new Thread(reader);
        t1.start();
        t2.start();
        t1.join();
        t2.join();

        System.out.println("List size: " + list.size()); // Output: 100
    }
}
```

- **Use Case**: Thread-safe list for event listeners in a notification system.

### Comparison with ArrayList

- **Thread Safety**:
    - `ArrayList`: Not thread-safe; concurrent modifications cause race conditions or `ConcurrentModificationException`.
    - `CopyOnWriteArrayList`: Thread-safe with copy-on-write semantics.
- **Performance**:
    - `ArrayList`: Faster for single-threaded applications and frequent modifications.
    - `CopyOnWriteArrayList`: Optimized for read-heavy scenarios, slow for frequent writes due to copying.
- **Memory**:
    - `ArrayList`: Lower memory usage, no copying.
    - `CopyOnWriteArrayList`: Higher memory usage due to array copies.
- **Iteration**:
    - `ArrayList`: Throws `ConcurrentModificationException` if modified during iteration.
    - `CopyOnWriteArrayList`: Snapshot iterators, safe for concurrent modifications.

### Where to Use

- **Read-Heavy Scenarios**: When reads vastly outnumber writes (e.g., event listeners, configuration lists).
- **Small Lists**: Due to memory overhead of copying.
- **Safe Iteration**: When iterators must be safe from concurrent modifications.

### Why to Use

- **Read Performance**: Lock-free reads for high concurrency.
- **Iterator Safety**: No `ConcurrentModificationException` during iteration.
- **Simplicity**: Thread safety without manual synchronization.

---

## 3. ConcurrentLinkedQueue

### Overview

- **Purpose**: A thread-safe, non-blocking queue implementing `Queue` with FIFO order.
- **Key Features**:
    - **Lock-Free**: Uses atomic operations (e.g., CAS) for concurrent access.
    - **Unbounded**: No fixed capacity, grows dynamically.
    - **Non-Blocking**: Methods like `offer` and `poll` do not block.

### Key Methods

- `boolean offer(E e)`: Adds an element (non-blocking, always returns `true` for unbounded queue).
- `E poll()`: Retrieves and removes the head (returns `null` if empty).
- `E peek()`: Retrieves the head without removing it (returns `null` if empty).
- `boolean isEmpty()`: Checks if the queue is empty.
- `int size()`: Returns the queue size (may be inaccurate under concurrency).

### Example

```java
import java.util.concurrent.ConcurrentLinkedQueue;

public class ConcurrentLinkedQueueExample {
    public static void main(String[] args) throws InterruptedException {
        ConcurrentLinkedQueue<String> queue = new ConcurrentLinkedQueue<>();

        Runnable producer = () -> {
            for (int i = 0; i < 100; i++) {
                queue.offer("Task-" + i);
            }
        };

        Runnable consumer = () -> {
            while (!queue.isEmpty()) {
                String task = queue.poll();
                if (task != null) {
                    System.out.println("Consumed: " + task);
                }
            }
        };

        Thread t1 = new Thread(producer);
        Thread t2 = new Thread(consumer);
        t1.start();
        t2.start();
        t1.join();
        t2.join();
    }
}
```

- **Use Case**: Task queue for asynchronous processing in a microservice.

### Comparison with LinkedList

- **Thread Safety**:
    - `LinkedList`: Not thread-safe; requires external synchronization.
    - `ConcurrentLinkedQueue`: Thread-safe with lock-free operations.
- **Performance**:
    - `LinkedList`: Faster for single-threaded applications.
    - `ConcurrentLinkedQueue`: Optimized for concurrent, non-blocking access.
- **Blocking**:
    - `LinkedList`: No built-in blocking operations.
    - `ConcurrentLinkedQueue`: Non-blocking, suitable for high-throughput scenarios.

### Where to Use

- **Non-Blocking Queues**: When blocking is undesirable (e.g., high-throughput task queues).
- **Unbounded Queues**: When dynamic growth is needed.

### Why to Use

- **Performance**: Lock-free operations reduce contention.
- **Scalability**: Efficient for multiple producers and consumers.
- **Simplicity**: No need for manual synchronization.

---

## 4. BlockingQueue (ArrayBlockingQueue, LinkedBlockingQueue)

### Overview

- **Purpose**: A thread-safe queue interface with blocking operations for producer-consumer patterns.
- **Implementations**:
    - **ArrayBlockingQueue**: Bounded queue with a fixed capacity.
    - **LinkedBlockingQueue**: Optionally bounded queue (default unbounded).
- **Key Features**:
    - **Blocking Operations**: `put` and `take` block until space or elements are available.
    - **Non-Blocking Operations**: `offer` and `poll` for non-blocking access.
    - **Bounded/Unbounded**: `ArrayBlockingQueue` is bounded; `LinkedBlockingQueue` can be unbounded.

### Key Methods

- `void put(E e)`: Adds an element, blocking if the queue is full.
- `E take()`: Retrieves and removes the head, blocking if the queue is empty.
- `boolean offer(E e)`: Adds an element (returns `false` if full).
- `E poll()`: Retrieves and removes the head (returns `null` if empty).
- `boolean offer(E e, long timeout, TimeUnit unit)`: Timed offer.
- `E poll(long timeout, TimeUnit unit)`: Timed poll.

### Example

```java
import java.util.concurrent.ArrayBlockingQueue;

public class BlockingQueueExample {
    public static void main(String[] args) throws InterruptedException {
        ArrayBlockingQueue<String> queue = new ArrayBlockingQueue<>(5);

        Thread producer = new Thread(() -> {
            try {
                for (int i = 0; i < 10; i++) {
                    queue.put("Task-" + i);
                    System.out.println("Produced: Task-" + i);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        Thread consumer = new Thread(() -> {
            try {
                for (int i = 0; i < 10; i++) {
                    String task = queue.take();
                    System.out.println("Consumed: " + task);
                    Thread.sleep(500);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        producer.start();
        consumer.start();
        producer.join();
        consumer.join();
    }
}
```

- **Use Case**: Producer-consumer task queue in a web server.

### Comparison with ArrayList/LinkedList

- **Thread Safety**:
    - `ArrayList`/`LinkedList`: Not thread-safe; requires external synchronization.
    - `BlockingQueue`: Thread-safe with built-in blocking operations.
- **Blocking**:
    - `ArrayList`/`LinkedList`: No blocking support.
    - `BlockingQueue`: Supports blocking `put` and `take` for coordination.
- **Performance**:
    - `ArrayList`/`LinkedList`: Faster for single-threaded applications.
    - `BlockingQueue`: Optimized for concurrent producer-consumer scenarios.

### Where to Use

- **Producer-Consumer**: Task queues, message passing.
- **Bounded Queues**: `ArrayBlockingQueue` for resource-constrained systems.
- **Thread Coordination**: When blocking operations are needed.

### Why to Use

- **Coordination**: Built-in blocking simplifies producer-consumer patterns.
- **Thread Safety**: Safe for multiple producers and consumers.
- **Bounded Control**: Prevents resource exhaustion with fixed capacity.

---

## 5. ConcurrentSkipListMap/Set

### Overview

- **Purpose**: Thread-safe, sorted map (`ConcurrentSkipListMap`) and set (`ConcurrentSkipListSet`) based on a skip list data structure.
- **Key Features**:
    - **Sorted**: Maintains elements in natural or custom order.
    - **Concurrent**: Supports concurrent reads and writes with fine-grained locking.
    - **Navigable**: Supports operations like `ceilingKey`, `floorKey`, and sub-maps.

### Key Methods (ConcurrentSkipListMap)

- `V put(K key, V value)`: Adds or updates a key-value pair.
- `V get(Object key)`: Retrieves a value.
- `NavigableSet<K> keySet()`: Returns a navigable set of keys.
- `K ceilingKey(K key)`: Returns the least key greater than or equal to the given key.
- `K floorKey(K key)`: Returns the greatest key less than or equal to the given key.

### Example

```java
import java.util.concurrent.ConcurrentSkipListMap;

public class ConcurrentSkipListMapExample {
    public static void main(String[] args) throws InterruptedException {
        ConcurrentSkipListMap<Integer, String> map = new ConcurrentSkipListMap<>();

        Runnable task = () -> {
            for (int i = 0; i < 100; i++) {
                map.put(i, "Value-" + i);
            }
        };

        Thread t1 = new Thread(task);
        Thread t2 = new Thread(() -> {
            for (Integer key : map.keySet()) {
                System.out.println("Key: " + key + ", Value: " + map.get(key));
            }
        });

        t1.start();
        t2.start();
        t1.join();
        t2.join();
    }
}
```

- **Use Case**: Sorted key-value store for concurrent access in a leaderboard system.

### Comparison with TreeMap/TreeSet

- **Thread Safety**:
    - `TreeMap`/`TreeSet`: Not thread-safe; requires external synchronization.
    - `ConcurrentSkipListMap`/`Set`: Thread-safe with concurrent access.
- **Performance**:
    - `TreeMap`/`TreeSet`: Faster for single-threaded applications.
    - `ConcurrentSkipListMap`/`Set`: Optimized for concurrent, sorted access.
- **Iteration**:
    - `TreeMap`/`TreeSet`: Throws `ConcurrentModificationException` if modified during iteration.
    - `ConcurrentSkipListMap`/`Set`: Weakly consistent iterators.

### Where to Use

- **Sorted Data**: When order is required (e.g., leaderboards, priority queues).
- **Concurrent Access**: When multiple threads need to read/write sorted data.

### Why to Use

- **Order Preservation**: Maintains sorted order with concurrent access.
- **Scalability**: Efficient for concurrent reads and writes.
- **Navigable Operations**: Supports advanced queries like `ceilingKey`.

---

## Comparison: Thread-Safe vs. Non-Thread-Safe Collections

|Feature|Non-Thread-Safe (ArrayList, HashMap)|Thread-Safe (ConcurrentHashMap, CopyOnWriteArrayList, etc.)|
|---|---|---|
|**Thread Safety**|No; requires external synchronization|Yes; built-in thread safety|
|**Performance**|Faster in single-threaded scenarios|Optimized for concurrency, may be slower for single-threaded|
|**Iteration**|Throws `ConcurrentModificationException`|Safe, weakly consistent iterators|
|**Memory Overhead**|Lower|Higher (e.g., copying in `CopyOnWriteArrayList`)|
|**Use Case**|Single-threaded applications|Multi-threaded, high-concurrency applications|

### Synchronized Collections (Alternative)

- **Collections.synchronizedXXX**:
    - Wrappers like `Collections.synchronizedList(ArrayList)` or `Collections.synchronizedMap(HashMap)` add synchronization.
    - **Drawback**: Coarse-grained locking (entire collection locked), poor scalability compared to `ConcurrentHashMap` or `CopyOnWriteArrayList`.
    - **Use Case**: When retrofitting legacy code, but prefer `java.util.concurrent` collections for new code.

---

## Best Practices for Legendary Backend Developers

- **Choose the Right Collection**:
    - Use `ConcurrentHashMap` for key-value stores with high concurrency.
    - Use `CopyOnWriteArrayList` for read-heavy lists with infrequent modifications.
    - Use `BlockingQueue` (`ArrayBlockingQueue`, `LinkedBlockingQueue`) for producer-consumer patterns.
    - Use `ConcurrentLinkedQueue` for non-blocking, unbounded queues.
    - Use `ConcurrentSkipListMap`/`Set` for sorted, concurrent data.
- **Avoid Non-Thread-Safe Collections in Concurrent Code**:
    - Never use `ArrayList` or `HashMap` without synchronization in multi-threaded environments.
    - Example: Replace `HashMap` with `ConcurrentHashMap` for thread safety.
- **Minimize Contention**:
    - Use `ConcurrentHashMap` for fine-grained locking instead of `Collections.synchronizedMap`.
    - Use `CopyOnWriteArrayList` only for read-heavy scenarios due to copy overhead.
- **Handle Exceptions**:
    - Catch `InterruptedException` in `BlockingQueue` operations and restore the interrupted status.
    - Example: `catch (InterruptedException e) { Thread.currentThread().interrupt(); }`
- **Optimize for Workload**:
    - For read-heavy workloads, prefer `CopyOnWriteArrayList` or `ConcurrentHashMap`.
    - For write-heavy workloads, consider `ConcurrentHashMap` or external synchronization.
- **Use Atomic Operations**:
    - Leverage `ConcurrentHashMap`’s `compute`, `merge`, or `putIfAbsent` for atomic updates.
    - Example: `map.compute(key, (k, v) -> v == null ? 1 : v + 1);`
- **Safe Iteration**:
    - Use `forEach` or iterators with `ConcurrentHashMap` and `CopyOnWriteArrayList` for safe concurrent iteration.
- **Monitor Performance**:
    - Profile collection performance under load using tools like JVisualVM.
    - Tune queue sizes (e.g., `ArrayBlockingQueue` capacity) for resource constraints.
- **Combine with Modern Concurrency**:
    - Use `ExecutorService` with `BlockingQueue` for producer-consumer patterns.
    - Use `CompletableFuture` with thread-safe collections for asynchronous workflows.

---

## Practical Example: Thread-Safe Task Processing System

Below is a task processing system using `ConcurrentHashMap`, `CopyOnWriteArrayList`, and `ArrayBlockingQueue` to manage tasks in a backend application.

```java
import java.util.concurrent.*;
import java.util.*;

public class TaskProcessingSystem {
    private final ConcurrentHashMap<String, Integer> taskResults = new ConcurrentHashMap<>();
    private final CopyOnWriteArrayList<String> taskLog = new CopyOnWriteArrayList<>();
    private final ArrayBlockingQueue<String> taskQueue = new ArrayBlockingQueue<>(10);
    private final ExecutorService executor = Executors.newFixedThreadPool(4);
    private volatile boolean running = true;

    public void start() {
        // Producer
        executor.submit(() -> {
            try {
                for (int i = 0; i < 20; i++) {
                    String task = "Task-" + i;
                    taskQueue.put(task);
                    taskLog.add("Produced: " + task);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        // Consumers
        for (int i = 0; i < 3; i++) {
            executor.submit(() -> {
                while (running && !Thread.currentThread().isInterrupted()) {
                    try {
                        String task = taskQueue.take();
                        taskResults.compute(task, (k, v) -> v == null ? 1 : v + 1);
                        taskLog.add("Consumed: " + task + " by " + Thread.currentThread().getName());
                        Thread.sleep(500);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            });
        }

        // Log reader
        executor.submit(() -> {
            for (String log : taskLog) {
                System.out.println("Log: " + log);
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        });
    }

    public void shutdown() throws InterruptedException {
        running = false;
        executor.shutdownNow();
        executor.awaitTermination(5, TimeUnit.SECONDS);
        System.out.println("Results: " + taskResults);
    }

    public static void main(String[] args) throws InterruptedException {
        TaskProcessingSystem system = new TaskProcessingSystem();
        system.start();
        Thread.sleep(3000);
        system.shutdown();
    }
}
```

- **Components**:
    - **ConcurrentHashMap**: Tracks task processing counts with atomic updates.
    - **CopyOnWriteArrayList**: Logs task events, safe for concurrent reads.
    - **ArrayBlockingQueue**: Manages task queue with blocking operations.
    - **ExecutorService**: Manages producer and consumer threads.
- **Use Case**: Asynchronous task processing in a microservice with logging and result tracking.

---

## Pros and Cons

### Pros

- **Thread Safety**:
    - All `java.util.concurrent` collections are safe for concurrent access.
    - Example: `ConcurrentHashMap` avoids race conditions without external locks.
- **Performance**:
    - Fine-grained locking (`ConcurrentHashMap`) or copy-on-write (`CopyOnWriteArrayList`) optimizes for concurrency.
    - Lock-free operations (`ConcurrentLinkedQueue`) reduce contention.
- **Ease of Use**:
    - Built-in thread safety eliminates manual synchronization.
    - Example: `BlockingQueue` simplifies producer-consumer patterns.
- **Scalability**:
    - Designed for multi-threaded environments, scales with thread count.
    - Example: `ConcurrentHashMap` supports high-concurrency caching.
- **Atomic Operations**:
    - Methods like `compute` and `putIfAbsent` ensure atomic updates.
    - Example: `map.compute(key, (k, v) -> v + 1)` for thread-safe counters.

### Cons

- **Overhead**:
    - Thread-safe collections have higher overhead than non-thread-safe ones in single-threaded scenarios.
    - Example: `CopyOnWriteArrayList` copies arrays on modification, increasing memory usage.
- **Complexity**:
    - Choosing the right collection requires understanding workload (read-heavy vs. write-heavy).
    - Example: `CopyOnWriteArrayList` is inefficient for frequent writes.
- **Weak Consistency**:
    - Iterators are weakly consistent, may not reflect the latest state.
    - Example: `ConcurrentHashMap` iterator may miss recent updates.
- **Resource Usage**:
    - Bounded queues (`ArrayBlockingQueue`) may block or reject tasks if full.
    - Unbounded queues (`LinkedBlockingQueue`) may consume excessive memory.
- **Null Restrictions**:
    - `ConcurrentHashMap` and `ConcurrentSkipListMap` do not allow `null` keys/values.

---

## Resources

- Java Concurrent Collections: [java.util.concurrent](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/package-summary.html)
- ConcurrentHashMap: [ConcurrentHashMap API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/ConcurrentHashMap.html)
- CopyOnWriteArrayList: [CopyOnWriteArrayList API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CopyOnWriteArrayList.html)
- Java Concurrency in Practice: [Java Concurrency in Practice](https://jcip.net/)

###### Tags : [[44 - Threads 🧀]]