

---
# PriorityQueue

**PriorityQueue** is a class in the Java Collections Framework that implements the `Queue` interface and represents a **priority-based queue** backed by a **binary heap** data structure. Unlike a regular FIFO queue, elements in a `PriorityQueue` are ordered according to their **natural ordering** (via `Comparable`) or a **custom `Comparator`** supplied at construction time, so the element with the highest priority (smallest by default) is always at the head. It is **not thread-safe**, does **not permit null elements**, is **unbounded** (growing automatically as elements are added), and provides **O(log n)** time for insertion and removal and **O(1)** time for peeking at the head. Its iterator does **not** guarantee any particular order — only `poll()`, `remove()`, and `peek()` respect priority order.

---

# ArrayDeque

**ArrayDeque** is a class in the Java Collections Framework that implements the `Deque` interface and represents a **resizable, double-ended queue** backed by a **circular array**. It supports insertion and removal of elements at **both the front and the back** in **amortized O(1)** time, making it suitable for use as a **stack (LIFO)**, a **queue (FIFO)**, or a general **double-ended queue**. It is **not thread-safe**, does **not permit null elements**, has **no capacity restrictions** (it grows automatically), and is generally **faster and more memory-efficient** than both the legacy `Stack` class and `LinkedList` when used as a deque. Its capacity is always a power of two, and its iterators are **fail-fast**.

---

# PriorityBlockingQueue

## Definition

**PriorityBlockingQueue** is a class in the `java.util.concurrent` package that implements the `BlockingQueue` interface and represents an **unbounded, thread-safe, priority-based blocking queue**. Internally it is backed by a **binary heap** (the same structure as `PriorityQueue`) and orders elements either by their **natural ordering** (via `Comparable`) or by a **`Comparator`** supplied at construction. What makes it distinct from `PriorityQueue` is that it is **fully thread-safe** (using a single `ReentrantLock` for all operations), and it supports **blocking operations** — although, because it is *unbounded*, `put()` never blocks; only `take()` blocks when the queue is empty until an element becomes available. It **does not permit null elements**, guarantees that `iterator()` traverses elements in **no guaranteed order**, and provides **O(log n)** time for insertion and removal, with the head always being the least element per the queue's ordering.

## Key Characteristics

- **Thread-safe** — all operations are guarded by a single lock
- **Unbounded** — `put()` never blocks; the queue grows as needed
- **Blocking** — `take()` waits when empty; `poll(timeout)` supports timed waits
- **Priority-ordered** — smallest (or comparator-determined) element at head
- **No nulls** allowed
- **Weakly consistent** iterator (never throws `ConcurrentModificationException`)
- **O(log n)** insert/remove, **O(1)** peek
- Implements `BlockingQueue`, `Queue`, `Collection`, `Iterable`

## Common Methods

| Method | Description |
|--------|-------------|
| `put(E e)` | Inserts element (never blocks because unbounded) |
| `offer(E e)` | Inserts element, returns `true` |
| `offer(E e, long timeout, TimeUnit unit)` | Inserts with timeout (never blocks in practice) |
| `take()` | Retrieves and removes head, **blocking** if empty |
| `poll()` | Retrieves and removes head, or `null` if empty |
| `poll(long timeout, TimeUnit unit)` | Retrieves head, waiting up to timeout |
| `peek()` | Returns head without removing |
| `size()` | Returns number of elements |
| `drainTo(Collection c)` | Removes all elements into another collection |
| `comparator()` | Returns the comparator used, or `null` |

## Example — Producer / Consumer

```java
import java.util.concurrent.PriorityBlockingQueue;
import java.util.concurrent.BlockingQueue;

public class PriorityBQDemo {
    public static void main(String[] args) throws InterruptedException {
        BlockingQueue<Integer> queue = new PriorityBlockingQueue<>();

        // Producer thread
        Thread producer = new Thread(() -> {
            int[] values = {5, 1, 4, 2, 3};
            for (int v : values) {
                System.out.println("Producing: " + v);
                queue.put(v); // never blocks
                try { Thread.sleep(200); } catch (InterruptedException ignored) {}
            }
        });

        // Consumer thread
        Thread consumer = new Thread(() -> {
            try {
                for (int i = 0; i < 5; i++) {
                    Integer v = queue.take(); // blocks if empty
                    System.out.println("Consuming: " + v);
                }
            } catch (InterruptedException ignored) {}
        });

        producer.start();
        consumer.start();
        producer.join();
        consumer.join();
    }
}
```

**Sample output** (consumption order is by priority, not arrival):
```
Producing: 5
Producing: 1
Consuming: 1
Producing: 4
Consuming: 2
Producing: 2
Consuming: 3
Producing: 3
Consuming: 4
Consuming: 5
```

## Example — Custom Comparator (Max-Heap Behavior)

```java
PriorityBlockingQueue<Integer> maxQueue =
        new PriorityBlockingQueue<>(11, Comparator.reverseOrder());

maxQueue.put(10);
maxQueue.put(30);
maxQueue.put(20);

System.out.println(maxQueue.take()); // 30
System.out.println(maxQueue.take()); // 20
System.out.println(maxQueue.take()); // 10
```

## When to Use

- Multi-threaded **producer–consumer** scenarios where elements must be processed by priority
- **Task schedulers** where higher-priority tasks must be picked up first
- **Event processing pipelines** requiring concurrent, priority-ordered handling
- Any case where you'd use `PriorityQueue` but need thread safety and blocking semantics

---

# LinkedBlockingDeque

## Definition

**LinkedBlockingDeque** is a class in the `java.util.concurrent` package that implements the `BlockingDeque` interface and represents an **optionally-bounded, thread-safe, double-ended blocking queue** backed by a **doubly-linked list**. It supports insertion and removal of elements at **both ends** (front and back) with **blocking operations** — `putFirst`/`putLast` block when the deque is full (if a capacity is set), and `takeFirst`/`takeLast` block when the deque is empty. Because it uses a **doubly-linked list**, elements are stored in nodes with `prev`/`next` pointers, and the deque can be constructed with a fixed capacity (to act as a bounded buffer) or left unbounded. It **does not permit null elements**, is **fully thread-safe** (using a separate lock for each end, giving better concurrency than a single-lock design), and provides **O(1)** time for insertion and removal at either end. Its iterators are **weakly consistent**.

## Key Characteristics

- **Thread-safe** — two locks (one per end) allow concurrent access from both ends
- **Double-ended** — supports FIFO, LIFO, and deque usage
- **Optionally bounded** — can be created with a fixed capacity; blocks when full
- **Blocking** — `put*` blocks when full, `take*` blocks when empty
- **Backed by a doubly-linked list** (each element stored in a node)
- **No nulls** allowed
- **Weakly consistent** iterators (never throw `ConcurrentModificationException`)
- **O(1)** insert/remove at either end
- Implements `BlockingDeque`, `BlockingQueue`, `Deque`, `Queue`, `Collection`

## Common Methods

**Insertion (blocking):**

| Method | Description |
|--------|-------------|
| `putFirst(E e)` | Inserts at front, blocking if full |
| `putLast(E e)` | Inserts at back, blocking if full |
| `offerFirst(E e)` | Inserts at front, returns `false` if full |
| `offerLast(E e)` | Inserts at back, returns `false` if full |
| `offerFirst(E e, long timeout, TimeUnit unit)` | Timed insert at front |
| `offerLast(E e, long timeout, TimeUnit unit)` | Timed insert at back |
| `addFirst(E e)` / `addLast(E e)` | Throws if full |

**Removal (blocking):**

| Method | Description |
|--------|-------------|
| `takeFirst()` | Removes from front, blocking if empty |
| `takeLast()` | Removes from back, blocking if empty |
| `pollFirst()` / `pollLast()` | Removes or returns `null` if empty |
| `pollFirst(long timeout, TimeUnit unit)` | Timed removal from front |
| `pollLast(long timeout, TimeUnit unit)` | Timed removal from back |
| `removeFirst()` / `removeLast()` | Throws if empty |

**Peek:**

| Method | Description |
|--------|-------------|
| `peekFirst()` | Returns front without removing |
| `peekLast()` | Returns back without removing |
| `getFirst()` / `getLast()` | Throws if empty |

**Stack/Queue convenience:**

| Method | Description |
|--------|-------------|
| `push(E e)` | Same as `addFirst` (stack) |
| `pop()` | Same as `removeFirst` (stack) |
| `add(E e)` | Same as `addLast` |
| `take()` | Same as `takeFirst` |
| `put(E e)` | Same as `putLast` |

## Example — Producer / Consumer with Bounded Buffer

```java
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.BlockingDeque;

public class LinkedBQDemo {
    public static void main(String[] args) throws InterruptedException {
        // Bounded deque with capacity 3
        BlockingDeque<Integer> deque = new LinkedBlockingDeque<>(3);

        Thread producer = new Thread(() -> {
            try {
                for (int i = 1; i <= 6; i++) {
                    deque.putLast(i); // blocks when full
                    System.out.println("Produced: " + i);
                }
            } catch (InterruptedException ignored) {}
        });

        Thread consumer = new Thread(() -> {
            try {
                for (int i = 0; i < 6; i++) {
                    Thread.sleep(400);
                    Integer v = deque.takeFirst(); // blocks when empty
                    System.out.println("Consumed: " + v);
                }
            } catch (InterruptedException ignored) {}
        });

        producer.start();
        consumer.start();
        producer.join();
        consumer.join();
    }
}
```

**Behavior:** The producer fills the deque to capacity 3, then blocks on `putLast` until the consumer removes items, demonstrating the **bounded-buffer** semantics.

## Example — Using as a Work-Stealing Deque

```java
LinkedBlockingDeque<String> deque = new LinkedBlockingDeque<>();

// Add tasks
deque.putLast("Task1");
deque.putLast("Task2");
deque.putLast("Task3");

// Worker steals from the back (LIFO for cache locality)
System.out.println(deque.takeLast()); // Task3
System.out.println(deque.takeLast()); // Task2
System.out.println(deque.takeLast()); // Task1
```

## Example — Timed Offer (Non-Blocking with Timeout)

```java
LinkedBlockingDeque<Integer> deque = new LinkedBlockingDeque<>(2);
deque.offerLast(1);
deque.offerLast(2);

// Queue is full — wait up to 1 second
boolean added = deque.offerLast(3, 1, TimeUnit.SECONDS);
System.out.println(added); // false (still full after timeout)
```

## When to Use

- **Bounded producer–consumer** buffers where back-pressure is desired
- **Work-stealing** algorithms (workers steal from the opposite end)
- **High-concurrency deque** scenarios — the two-lock design reduces contention
- Any case where you'd use `ArrayDeque` but need **thread safety** and **blocking**
- Replacing `LinkedBlockingQueue` when you also need **double-ended access**

---

# Quick Comparison

| Feature | PriorityQueue | ArrayDeque | PriorityBlockingQueue | LinkedBlockingDeque |
|---------|---------------|------------|----------------------|---------------------|
| Package | `java.util` | `java.util` | `java.util.concurrent` | `java.util.concurrent` |
| Thread-safe | ❌ | ❌ | ✅ | ✅ |
| Blocking | ❌ | ❌ | ✅ (`take`) | ✅ (`put`/`take`) |
| Bounded | Unbounded | Unbounded | Unbounded | Optionally bounded |
| Ordering | Priority (heap) | Insertion order | Priority (heap) | Insertion order (ends) |
| Double-ended | ❌ | ✅ | ❌ | ✅ |
| Allows nulls | ❌ | ❌ | ❌ | ❌ |
| Backing structure | Binary heap (array) | Circular array | Binary heap (array) | Doubly-linked list |
| Insert/remove | O(log n) | O(1) | O(log n) | O(1) |
| Peek | O(1) | O(1) | O(1) | O(1) |
| Iterator order | Not guaranteed | Insertion order | Not guaranteed | Insertion order |
| Locking | None | None | Single lock | Two locks (one per end) |
| Best for | Priority tasks (single thread) | Stack/queue/deque (single thread) | Priority tasks (multi-threaded) | Bounded deque (multi-threaded) |


[[Java]]