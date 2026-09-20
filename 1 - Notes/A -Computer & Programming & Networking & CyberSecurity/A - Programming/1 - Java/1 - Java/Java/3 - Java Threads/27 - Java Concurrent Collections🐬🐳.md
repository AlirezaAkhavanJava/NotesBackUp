
## Introduction

Java provides concurrent collections in the `java.util.concurrent` package. These collections are designed to handle multiple threads accessing and modifying them concurrently, ensuring thread safety without the need for explicit synchronization.

## Key Concurrent Collections

### 1. `ConcurrentHashMap`

A thread-safe variant of `HashMap`. Unlike `HashMap`, it allows concurrent reads and writes by partitioning the map into segments.

**Example:**

```java
import java.util.concurrent.ConcurrentHashMap;

public class Example {
    public static void main(String[] args) {
        ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();
        map.put("A", 1);
        map.put("B", 2);

        // Thread-safe iteration
        map.forEach((key, value) -> System.out.println(key + ":" + value));
    }
}
```

### Other Concurrent Map Implementations

- `ConcurrentSkipListMap`
    
    - A scalable concurrent `NavigableMap` implementation.
        
    - Maintains elements in sorted order.
        
    - Suitable for applications requiring concurrent access with sorted keys.
        

**Example:**

```java
import java.util.concurrent.ConcurrentSkipListMap;

public class Example {
    public static void main(String[] args) {
        ConcurrentSkipListMap<String, Integer> map = new ConcurrentSkipListMap<>();
        map.put("B", 2);
        map.put("A", 1);

        map.forEach((key, value) -> System.out.println(key + ":" + value)); // Sorted order
    }
}
```

- `ConcurrentMap` Interface
    
    - A base interface implemented by concurrent maps such as `ConcurrentHashMap` and `ConcurrentSkipListMap`.
        
    - Provides atomic operations like `putIfAbsent`, `remove(key, value)`, and `replace`.
        

**Example:**

```java
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class Example {
    public static void main(String[] args) {
        ConcurrentMap<String, Integer> map = new ConcurrentHashMap<>();
        map.putIfAbsent("A", 1);
        map.replace("A", 1, 2);

        map.forEach((key, value) -> System.out.println(key + ":" + value));
    }
}
```

### 2. `CopyOnWriteArrayList`

A thread-safe variant of `ArrayList`. It creates a new copy of the underlying array on each modification, making it ideal for lists with frequent reads and infrequent writes.

**Example:**

```java
import java.util.concurrent.CopyOnWriteArrayList;

public class Example {
    public static void main(String[] args) {
        CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();
        list.add("A");
        list.add("B");

        for (String item : list) {
            System.out.println(item);
        }
    }
}
```

### 3. `CopyOnWriteArraySet`

A thread-safe variant of `Set` backed by `CopyOnWriteArrayList`. It avoids duplicates and is ideal for read-heavy operations.

### 4. `ConcurrentLinkedQueue`

A thread-safe, non-blocking queue based on linked nodes. Suitable for high-throughput applications.

**Example:**

```java
import java.util.concurrent.ConcurrentLinkedQueue;

public class Example {
    public static void main(String[] args) {
        ConcurrentLinkedQueue<String> queue = new ConcurrentLinkedQueue<>();
        queue.add("A");
        queue.add("B");

        System.out.println(queue.poll()); // Retrieves and removes the head
    }
}
```

### 5. `BlockingQueue`

An interface for queues that support operations that wait for the queue to become non-empty when retrieving, and wait for space to become available when storing.

Common implementations:

- `ArrayBlockingQueue`
    
- `LinkedBlockingQueue`
    
- `PriorityBlockingQueue`
    

**Example:**

```java
import java.util.concurrent.ArrayBlockingQueue;

public class Example {
    public static void main(String[] args) throws InterruptedException {
        ArrayBlockingQueue<Integer> queue = new ArrayBlockingQueue<>(5);
        queue.put(1); // Blocks if full
        queue.put(2);

        System.out.println(queue.take()); // Blocks if empty
    }
}
```

## Summary

- Concurrent collections provide thread safety without manual synchronization.
    
- Choose the right collection based on read/write patterns:
    
    - `ConcurrentHashMap`, `ConcurrentSkipListMap` for key-value maps
        
    - `CopyOnWriteArrayList`/`Set` for mostly-read lists/sets
        
    - `ConcurrentLinkedQueue` for non-blocking queues
        
    - `BlockingQueue` for producer-consumer scenarios
        

These collections simplify multi-threaded programming in Java while maintaining performance.



[[44 - Threads 🧀]]