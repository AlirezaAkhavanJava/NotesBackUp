
## 1. Prerequisites

Before `Queue` makes sense, you need:

| Prerequisite | Why it matters |
|---|---|
| **`Collection` interface** | `Queue` extends `Collection`. It inherits `add`, `remove`, `size`, `iterator`, etc., but *redefines* some of their contracts. |
| **`List` and `Set`** | You need to know what a `Queue` is *not*. A `Queue` is about ordering by *arrival* or *priority*, not by index or uniqueness. |
| **Generics** | `Queue<T>` — you'll see `Queue<Integer>`, `Queue<Task>`, etc. |
| **`Comparable` / `Comparator`** | Required for `PriorityQueue`. Without it, priority queues are meaningless. |
| **Basic complexity analysis** | To choose between `ArrayDeque`, `LinkedList`, and `PriorityQueue`, you need O(1), O(log n), O(n). |
| **`Iterable` / `Iterator`** | Queues are iterable, but iteration order is not always the dequeue order. This trips people up. |
| **Threading basics** | `BlockingQueue` and `ConcurrentLinkedQueue` only make sense if you understand producer/consumer problems. |

### Dependency chain

```
Collection
  ↑
Queue
  ↑
├── Deque (extends Queue)
│     ↑
│     ├── ArrayDeque
│     └── LinkedList
├── PriorityQueue
├── BlockingQueue
│     ↑
│     ├── ArrayBlockingQueue
│     ├── LinkedBlockingQueue
│     ├── PriorityBlockingQueue
│     ├── SynchronousQueue
│     └── DelayQueue
└── ConcurrentLinkedQueue
```

If `Collection` and generics are solid, you're ready.

---

## 2. The Problem

### What problem existed before `Queue`?

Suppose you're writing a simple task scheduler. Tasks arrive, and you want to process them **in the order they arrived**. You start with an `ArrayList<Task>`:

```java
List<Task> tasks = new ArrayList<>();
tasks.add(task);           // enqueue
Task next = tasks.remove(0); // dequeue — O(n)! shifts everything left
```

Two problems:

1. **`remove(0)` on an `ArrayList` is O(n)** — it shifts every remaining element left. For a queue with 1,000,000 tasks, each dequeue is a million-element copy.
2. **The API is wrong.** `List` has `add`, `get`, `remove(int)`, `remove(Object)`. Nothing in the type says "this is a queue." A new developer on the team sees `List<Task>` and might do `tasks.get(5)` or `tasks.add(0, task)`, breaking the FIFO invariant.

If you use a `LinkedList`, `remove(0)` is O(1), but you're still using a `List` API for a queue concept. There's no `enqueue`/`dequeue`; there's `addLast`/`removeFirst`. The abstraction is wrong.

### Why was the problem difficult?

Because "queue" is a *behavioral* contract, not just a data layout. A queue promises:

- Elements come out in a specific order (FIFO, LIFO, or priority).
- You only touch the ends (or the highest-priority element).
- You don't index into the middle.

A `List` doesn't enforce any of that. A `Set` is about uniqueness, not order. A `Map` is about key-value association. None of them model "wait in line."

### Concrete example of the pain

```java
// Producer/consumer with a List — broken
List<Task> queue = new ArrayList<>();

// Producer thread
queue.add(task);   // not thread-safe; may corrupt the list

// Consumer thread
if (!queue.isEmpty()) {
    Task t = queue.remove(0); // race condition: may throw IndexOutOfBounds
}
```

This is subtly, intermittently broken. The `isEmpty()` check and the `remove(0)` are not atomic. A `BlockingQueue` solves this with a single atomic `take()` that blocks when empty.

### What `Queue` gives you

- A **contract**: "I am a queue. I order elements this way."
- **Efficient end operations**: O(1) for `ArrayDeque` and `LinkedList`.
- **Specialized variants**: priority ordering (`PriorityQueue`), thread-safe blocking (`BlockingQueue`), concurrent non-blocking (`ConcurrentLinkedQueue`).
- **A clear API**: `offer`, `poll`, `peek` (and their throwing counterparts `add`, `remove`, `element`).

---

## 3. The Core Idea

### Simple definition

A `Queue` is a collection designed for holding elements prior to processing. Besides basic `Collection` operations, queues provide additional insertion, extraction, and inspection operations. Queues typically order elements in **FIFO** (first-in-first-out) order, but this is not required — `PriorityQueue` orders by priority, and `Deque` allows both ends.

### Intuitive explanation

Think of a **checkout line at a supermarket**. The first person in line is the first person served. You join at the back. You leave from the front. You can peek at who's next without removing them.

Now imagine variations:

- **Priority queue**: a hospital emergency room. The most critical patient is treated first, regardless of arrival time.
- **Deque (double-ended queue)**: a train car with doors at both ends. You can board or exit from either end.
- **Blocking queue**: a checkout line where the cashier *waits* until a customer arrives, and customers *wait* if the line is full.

### Precise technical definition

> A `Queue` is a `Collection` that provides ordered insertion and removal. It defines two sets of methods: one that throws exceptions on failure, and one that returns a special value (`null` or `false`).

The Javadoc:

> "A collection designed for holding elements prior to processing. Besides basic Collection operations, queues provide additional insertion, extraction, and inspection operations. Each of these methods exists in two forms: one throws an exception if the operation fails, the other returns a special value (either null or false, depending on the operation)."

### The two method families

This is the single most important table for `Queue`:

| Operation | Throws exception | Returns special value |
|---|---|---|
| **Insert** | `add(e)` | `offer(e)` |
| **Remove** | `remove()` | `poll()` |
| **Inspect** | `element()` | `peek()` |

**Why two families?** Because capacity-bounded queues exist. `ArrayBlockingQueue` has a fixed capacity. When full:

- `add(e)` throws `IllegalStateException`.
- `offer(e)` returns `false`.

When empty:

- `remove()` throws `NoSuchElementException`.
- `poll()` returns `null`.

**Rule of thumb:** prefer `offer`/`poll`/`peek` unless you *want* the exception. The special-value forms are safer in normal control flow.

### Key vocabulary

| Term | Meaning |
|---|---|
| **FIFO** | First-in-first-out. `ArrayDeque` used as a queue. |
| **LIFO** | Last-in-first-out. A stack. `ArrayDeque` used as a stack. |
| **Head** | The element that would be removed next. |
| **Tail** | The most recently added element (for FIFO). |
| **Deque** | Double-ended queue. Insert/remove at both ends. |
| **Blocking** | Operations that wait (block) until they can proceed. |
| **Bounded** | Has a maximum capacity. |
| **Unbounded** | Grows as needed (until OOM). |
| **Priority** | Ordering by a comparator, not arrival. |

---

## 4. How It Works

### The general mechanism

Every `Queue` answers three questions:

1. **Where do elements go in?** (insertion point)
2. **Where do elements come out?** (removal point)
3. **What determines the order?** (FIFO, LIFO, priority)

Let's walk through the major implementations.

### ArrayDeque — the workhorse

`ArrayDeque` is a resizable circular array. It's the default choice for both queue and stack usage.

```
Circular array (capacity 8, head=2, tail=6):

index:  0    1    2    3    4    5    6    7
      [   ][   ][ A ][ B ][ C ][ D ][   ][   ]
                ↑                   ↑
              head                tail

offerLast(E): place at tail, tail = (tail + 1) % capacity
pollFirst():  take from head, head = (head + 1) % capacity
```

**Why circular?** To reuse the array slots freed at the front. A naive array-based queue would shift elements on every dequeue (O(n)). The circular buffer makes both ends O(1) amortized.

**Adding an element (`offerLast`):**

1. Check if full. If full, resize (double the capacity, copy elements in order).
2. Place `e` at `tail`.
3. `tail = (tail + 1) % capacity`.
4. Increment size.

**Removing an element (`pollFirst`):**

1. If empty, return `null`.
2. Read `elements[head]`.
3. Null out the slot (to help GC).
4. `head = (head + 1) % capacity`.
5. Decrement size.
6. Return the element.

**Flow diagram:**

```
offerLast(e)
  │
  ├─► if full: resize()
  ├─► elements[tail] = e
  ├─► tail = (tail + 1) & (capacity - 1)   // capacity is power of 2
  └─► size++

pollFirst()
  │
  ├─► if empty: return null
  ├─► e = elements[head]
  ├─► elements[head] = null                // GC hint
  ├─► head = (head + 1) & (capacity - 1)
  ├─► size--
  └─► return e
```

**Key facts about `ArrayDeque`:**

- No capacity limit (grows dynamically).
- Not thread-safe.
- **Does not allow `null` elements** — this is deliberate. `null` is used as a sentinel by `poll`/`peek` to signal emptiness.
- O(1) amortized for `addFirst`, `addLast`, `pollFirst`, `pollLast`.
- O(1) for `peekFirst`, `peekLast`, `size`, `isEmpty`.
- O(n) for `contains`, `remove(Object)`, iteration.
- Iteration order is **head to tail** — which for a FIFO queue is the dequeue order. But for a stack usage, it's *not* the pop order.

### LinkedList — the legacy choice

`LinkedList` implements both `List` and `Deque`. It's a doubly-linked list. Each node has `prev`, `next`, `item`.

- `addLast`, `addFirst`, `pollFirst`, `pollLast` are O(1).
- Memory overhead: each element is a node object with three references. For large queues, this is significant.
- Historically used for queues before `ArrayDeque` existed (Java 6). **Today, `ArrayDeque` is almost always better** unless you need `List` operations too.

### PriorityQueue — the heap

`PriorityQueue` is a binary heap stored in an array. It orders elements by `Comparable` (natural ordering) or a `Comparator`.

```
Min-heap (smallest at root):

            [1]
           /   \
         [3]   [2]
        /   \  /
      [7]  [4][5]

Array representation: [1, 3, 2, 7, 4, 5]
  parent(i) = (i - 1) / 2
  left(i)   = 2i + 1
  right(i)  = 2i + 2
```

**Adding an element (`offer`):**

1. Place `e` at the end of the array.
2. "Sift up": while `e` is smaller than its parent, swap them.
3. O(log n).

**Removing the head (`poll`):**

1. Save the root (smallest element).
2. Move the last element to the root.
3. "Sift down": repeatedly swap with the smaller child until the heap property is restored.
4. O(log n).

**Key facts about `PriorityQueue`:**

- **Not** FIFO. Order is by priority.
- `peek`/`poll` return the *smallest* element (min-heap).
- For a max-heap, use `Comparator.reverseOrder()`.
- Iteration order is **not** sorted. It's the internal array order. To get sorted order, repeatedly `poll`.
- Does not allow `null`.
- Not thread-safe. Use `PriorityBlockingQueue` for concurrent use.
- O(log n) for `offer` and `poll`; O(1) for `peek`.

### BlockingQueue — the concurrency primitive

`BlockingQueue` extends `Queue` with two additional behaviors:

- **Blocking insertion**: `put(e)` waits until space is available.
- **Blocking removal**: `take()` waits until an element is available.
- **Timed variants**: `offer(e, timeout, unit)`, `poll(timeout, unit)`.

| Operation | Throws | Special value | Blocks | Times out |
|---|---|---|---|---|
| Insert | `add(e)` | `offer(e)` | `put(e)` | `offer(e, t, u)` |
| Remove | `remove()` | `poll()` | `take()` | `poll(t, u)` |
| Inspect | `element()` | `peek()` | — | — |

Major implementations:

| Implementation | Bounded? | Order | Notes |
|---|---|---|---|
| `ArrayBlockingQueue` | Yes | FIFO | Fixed capacity, single lock (or fair lock). |
| `LinkedBlockingQueue` | Optional | FIFO | Default capacity `Integer.MAX_VALUE` (effectively unbounded). |
| `PriorityBlockingQueue` | No | Priority | Unbounded. |
| `SynchronousQueue` | Yes (0) | — | Each `put` waits for a `take`. Handoff. |
| `DelayQueue` | No | Delay | Elements become available after a delay. |

### ConcurrentLinkedQueue — non-blocking

A lock-free queue based on Michael-Scott algorithm. `offer`, `poll`, `peek` are O(1) and non-blocking. No `put`/`take` — it's unbounded and never blocks. Use when you want thread safety without blocking.

### Comparison table

| Implementation | Order | offer/poll | peek | Null | Bounded | Thread-safe |
|---|---|---|---|---|---|---|
| `ArrayDeque` | FIFO/LIFO | O(1) amortized | O(1) | No | No | No |
| `LinkedList` | FIFO/LIFO | O(1) | O(1) | Yes | No | No |
| `PriorityQueue` | Priority | O(log n) | O(1) | No | No | No |
| `ArrayBlockingQueue` | FIFO | O(1) | O(1) | No | Yes | Yes |
| `LinkedBlockingQueue` | FIFO | O(1) | O(1) | No | Optional | Yes |
| `PriorityBlockingQueue` | Priority | O(log n) | O(1) | No | No | Yes |
| `SynchronousQueue` | Handoff | O(1) | — | No | Yes (0) | Yes |
| `ConcurrentLinkedQueue` | FIFO | O(1) | O(1) | No | No | Yes |

### Runtime behavior worth knowing

- **`ArrayDeque` capacity is always a power of 2.** This lets it use `& (capacity - 1)` instead of `% capacity`, which is faster.
- **`ArrayDeque` grows by doubling.** If you know the expected size, you can't pre-size it — there's no capacity constructor. This is a known limitation.
- **`PriorityQueue` is not stable.** Equal-priority elements come out in arbitrary order.
- **`PriorityQueue` iteration is not sorted.** This is the #1 misconception.
- **`BlockingQueue` methods are atomic.** `put`/`take` handle all locking and waiting.
- **`ConcurrentLinkedQueue.size()` is O(n).** It's not maintained as a counter. Use `isEmpty()` instead of `size() == 0`.

---

## 5. Relationships

### To its prerequisites

- **`Collection`**: `Queue` inherits `add`, `remove`, `size`, `iterator`, `stream`, etc. It *redefines* `add` to throw on capacity exhaustion and adds `offer`, `poll`, `peek`.
- **`Comparable`/`Comparator`**: `PriorityQueue` is *defined* by them.
- **Threading**: `BlockingQueue` and `ConcurrentLinkedQueue` are *defined* by their concurrency semantics.

### Concepts that depend on `Queue`

- **`Deque`**: extends `Queue`. Adds both-end operations.
- **`BlockingQueue`**: extends `Queue`. Adds blocking operations.
- **`TransferQueue`**: extends `BlockingQueue`. Adds `transfer(e)` which waits for a consumer.
- **`ExecutorService`**: internally uses a `BlockingQueue` for its task queue.
- **`ThreadPoolExecutor`**: takes a `BlockingQueue<Runnable>` in its constructor.
- **`ForkJoinPool`**: uses work-stealing deques.

### Similar concepts

- **`List`**: indexed, allows duplicates, access anywhere. Use when you need random access.
- **`Set`**: uniqueness, no order. Use when you need deduplication.
- **`Stack`**: LIFO. But `Stack` is a legacy class; use `ArrayDeque` or `Deque` instead.
- **`Deque`**: double-ended. Use when you need both ends.

### Commonly confused with

- **`Stack`**: `Stack` is a legacy `Vector` subclass. It's synchronized (slow) and has a confusing API (`push`/`pop`/`peek` but also `List` methods). **Use `ArrayDeque` for stacks.**
- **`LinkedList` as a queue**: works, but `ArrayDeque` is faster and uses less memory.
- **`PriorityQueue` as a sorted list**: it's not. Iteration is not sorted. If you need sorted iteration, use a `TreeSet` or sort a `List`.
- **`BlockingQueue` as a regular queue**: it works, but the blocking methods are the point. If you don't need blocking, use `ArrayDeque` or `ConcurrentLinkedQueue`.

### Higher-level concepts built on top of `Queue`

- **BFS (breadth-first search)**: uses a queue to track frontier nodes.
- **Task schedulers**: use priority queues.
- **Producer/consumer pipelines**: use blocking queues.
- **Message brokers**: use queues (RabbitMQ, Kafka are queue-like).
- **Rate limiters**: token bucket algorithms use queues.
- **Event loops**: use queues for pending events.
- **Work-stealing**: uses deques.

---

## 6. Examples

### Level 1: Beginner — basic FIFO

```java
Queue<String> line = new ArrayDeque<>();
line.offer("Alice");
line.offer("Bob");
line.offer("Charlie");

System.out.println(line.peek());   // Alice — inspect, no remove
System.out.println(line.poll());   // Alice — remove and return
System.out.println(line.poll());   // Bob
System.out.println(line.size());   // 1
System.out.println(line.poll());   // Charlie
System.out.println(line.poll());   // null — empty, no exception
```

**What to notice:** `offer`/`poll`/`peek` don't throw. `poll` on empty returns `null`. This is the safe, idiomatic pattern.

### Level 2: Real-world — BFS

```java
// Breadth-first search on a graph
Map<String, List<String>> graph = Map.of(
    "A", List.of("B", "C"),
    "B", List.of("D"),
    "C", List.of("D", "E"),
    "D", List.of("E"),
    "E", List.of()
);

Queue<String> frontier = new ArrayDeque<>();
Set<String> visited = new HashSet<>();

frontier.offer("A");
visited.add("A");

while (!frontier.isEmpty()) {
    String node = frontier.poll();
    System.out.println("Visiting: " + node);

    for (String neighbor : graph.get(node)) {
        if (visited.add(neighbor)) {   // add returns false if already present
            frontier.offer(neighbor);
        }
    }
}
// Output: A, B, C, D, E (level by level)
```

**What to notice:** the queue is the *entire* mechanism that makes BFS breadth-first. Swap it for a `Deque` used as a stack (`push`/`pop`) and you get DFS. The data structure *is* the algorithm here.

### Level 3: Practical programming — priority queue

```java
record Task(String name, int priority) {}

Queue<Task> tasks = new PriorityQueue<>(Comparator.comparingInt(Task::priority));

tasks.offer(new Task("low", 3));
tasks.offer(new Task("critical", 1));
tasks.offer(new Task("medium", 2));

while (!tasks.isEmpty()) {
    System.out.println(tasks.poll().name());
}
// Output: critical, medium, low
```

**What to notice:** `PriorityQueue` orders by the comparator, not by insertion. The *smallest* priority value comes out first (min-heap). For a max-heap, reverse the comparator.

### Level 4: Professional/production — producer/consumer with `BlockingQueue`

```java
BlockingQueue<Order> queue = new LinkedBlockingQueue<>(1000);

// Producer thread
Thread producer = new Thread(() -> {
    try {
        for (Order order : incomingOrders()) {
            queue.put(order);  // blocks if full
        }
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
});

// Consumer thread
Thread consumer = new Thread(() -> {
    try {
        while (true) {
            Order order = queue.take();  // blocks if empty
            process(order);
        }
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
});

producer.start();
consumer.start();
```

**What to notice:** `put` and `take` handle all the waiting and signaling. No explicit locks, no `wait`/`notify`, no `isEmpty` race conditions. This is the correct way to build a producer/consumer pipeline in Java.

### Level 5: Edge case — `PriorityQueue` iteration is not sorted

```java
Queue<Integer> pq = new PriorityQueue<>();
pq.addAll(List.of(5, 1, 4, 2, 3));

System.out.println(pq);          // [1, 2, 4, 5, 3] — NOT sorted!
System.out.println(pq.poll());   // 1 — smallest
System.out.println(pq.poll());   // 2
System.out.println(pq.poll());   // 3
System.out.println(pq.poll());   // 4
System.out.println(pq.poll());   // 5

// To get sorted iteration, you must drain the queue:
List<Integer> sorted = new ArrayList<>();
while (!pq.isEmpty()) sorted.add(pq.poll());
```

**What to notice:** `PriorityQueue`'s iterator returns elements in the internal array order, which is a valid heap but not sorted. Only `poll` guarantees sorted removal. This is a classic production bug when someone logs `pq.toString()` expecting sorted output.

**Another edge case: mutating elements in a `PriorityQueue`.**

```java
class MutableTask implements Comparable<MutableTask> {
    int priority;
    MutableTask(int p) { this.priority = p; }
    public int compareTo(MutableTask o) { return Integer.compare(priority, o.priority); }
}

PriorityQueue<MutableTask> pq = new PriorityQueue<>();
MutableTask t = new MutableTask(5);
pq.add(t);
t.priority = 1;   // mutate after insertion
System.out.println(pq.poll().priority);  // 5, not 1 — heap is corrupted
```

**What to notice:** if you mutate an element's priority after adding it, the heap property is violated. The queue doesn't know. This is the `PriorityQueue` equivalent of mutating a `HashSet` element. **Never mutate elements in a priority queue.** Remove, mutate, re-add.

---

## 7. How to Use It

### Common usage patterns

```java
// FIFO queue
Queue<T> q = new ArrayDeque<>();
q.offer(x);
T next = q.poll();

// Stack (LIFO) — use Deque, not Stack
Deque<T> stack = new ArrayDeque<>();
stack.push(x);      // addFirst
T top = stack.pop(); // removeFirst

// Priority queue
Queue<T> pq = new PriorityQueue<>(comparator);

// Bounded blocking queue
BlockingQueue<T> bq = new ArrayBlockingQueue<>(capacity);

// Unbounded concurrent queue
Queue<T> clq = new ConcurrentLinkedQueue<>();

// Work queue with deduplication
Queue<T> work = new ArrayDeque<>();
Set<T> seen = new HashSet<>();
if (seen.add(item)) work.offer(item);
```

### Best practices

- **Use `ArrayDeque` for queues and stacks.** It's faster than `LinkedList` and `Stack`.
- **Prefer `offer`/`poll`/`peek`** over `add`/`remove`/`element` unless you explicitly want exceptions.
- **Never use `Stack`.** It's legacy. Use `ArrayDeque`.
- **Never use `LinkedList` as a queue** unless you also need `List` operations. `ArrayDeque` is better.
- **Use `PriorityQueue` only when you need priority ordering.** If you need sorted iteration, use a `TreeSet` or sort a `List`.
- **For producer/consumer, use `BlockingQueue`.** Don't hand-roll with `wait`/`notify`.
- **Handle `InterruptedException` properly.** Restore the interrupt flag (`Thread.currentThread().interrupt()`) if you can't propagate it.
- **Use `isEmpty()` not `size() == 0`** for `ConcurrentLinkedQueue`.
- **Pre-size `ArrayBlockingQueue` and `LinkedBlockingQueue`** if you know the expected load.
- **Document your comparator** for `PriorityQueue` — especially its behavior on ties.

### When to choose `Queue`

- You need FIFO ordering.
- You need LIFO ordering (use `Deque`).
- You need priority ordering.
- You need producer/consumer coordination.
- You're implementing BFS, scheduling, or buffering.

### When to avoid `Queue`

- You need random access → `List`.
- You need uniqueness → `Set`.
- You need key-value lookup → `Map`.
- You need sorted iteration → `TreeSet` or sorted `List`.
- You need to insert/remove in the middle → `List` or `LinkedList`.

### Alternatives and when they're preferable

| Alternative | When to prefer |
|---|---|
| `List` | Random access, indexing, insertion in middle. |
| `Set` | Uniqueness, membership testing. |
| `Deque` | Both-end operations; stack; work-stealing. |
| `BlockingQueue` | Producer/consumer with backpressure. |
| `ConcurrentLinkedQueue` | Non-blocking concurrent FIFO. |
| `TreeSet` | Sorted set with O(log n) operations. |
| `PriorityQueue` | Priority-based processing. |

---

## 8. Common Mistakes

### Beginner mistakes

**Mistake 1: Using `Stack` instead of `ArrayDeque`.**

```java
Stack<Integer> stack = new Stack<>();  // legacy, synchronized, slow
```

*Why it's wrong:* `Stack` extends `Vector`, which is synchronized on every operation. It's slow, and it exposes `List` methods that let you violate stack semantics (`insertElementAt`, `get`, etc.). Use `ArrayDeque`.

**Mistake 2: Using `LinkedList` as a queue.**

```java
Queue<T> q = new LinkedList<>();  // works, but ArrayDeque is better
```

*Why it's suboptimal:* `LinkedList` allocates a node object per element. `ArrayDeque` uses a single array. For a queue of 1M elements, `LinkedList` uses ~3x the memory and is slower due to cache misses.

**Mistake 3: Calling `poll()` and using the result without checking for `null`.**

```java
String s = queue.poll();
System.out.println(s.length());  // NPE if empty
```

*Why it's wrong:* `poll` returns `null` on empty. Either check for `null` or use `remove()` if you want an exception on empty.

**Mistake 4: Assuming `PriorityQueue` iteration is sorted.**

Covered in Level 5. This is the #1 `PriorityQueue` bug.

### Misconceptions

**Misconception: "`ArrayDeque` allows `null`."**

False. `ArrayDeque` explicitly rejects `null` with `NullPointerException`. This is because `null` is used as a sentinel in `poll`/`peek`. If you need `null` in a queue (rare), use `LinkedList`.

**Misconception: "`PriorityQueue` is stable."**

False. Equal-priority elements come out in arbitrary order. If you need stability, add a sequence number to your comparator.

**Misconception: "`BlockingQueue` is always better than `ArrayDeque`."**

False. `BlockingQueue` has locking overhead. If you don't need thread safety or blocking, `ArrayDeque` is faster.

**Misconception: "`Queue` is always FIFO."**

False. `PriorityQueue` is not FIFO. `Deque` can be LIFO. The `Queue` interface only specifies "ordered," not "FIFO."

### Incorrect implementations

**Incorrect: hand-rolling a producer/consumer with `wait`/`notify`.**

```java
// DON'T DO THIS
synchronized (queue) {
    while (queue.isEmpty()) queue.wait();
    return queue.remove(0);
}
```

*Why it's wrong:* easy to get wrong (missed `notify`, spurious wakeups, deadlocks, fairness). Use `BlockingQueue`.

**Incorrect: using `PriorityQueue` with a comparator that can return 0 for distinct elements.**

```java
Queue<Task> pq = new PriorityQueue<>(Comparator.comparing(Task::priority));
// Two tasks with the same priority are "equal" to the heap — order is arbitrary
```

*Why it matters:* if you need deterministic tie-breaking, add a secondary comparator.

### Subtle mistakes experienced developers make

**Mistake: mutating elements in a `PriorityQueue`.**

Covered in Level 5. The heap is corrupted. Remove, mutate, re-add.

**Mistake: using `ConcurrentLinkedQueue.size()` in a hot loop.**

```java
while (queue.size() > 0) { ... }  // O(n) per call!
```

*Why it's wrong:* `ConcurrentLinkedQueue.size()` traverses the entire queue. Use `isEmpty()` (O(1)).

**Mistake: ignoring `InterruptedException`.**

```java
try {
    queue.take();
} catch (InterruptedException e) {
    // swallow — BAD
}
```

*Why it's wrong:* swallowing interrupts breaks cancellation. Restore the flag or propagate.

**Mistake: using `PriorityQueue` for a bounded top-K without a size check.**

```java
PriorityQueue<Integer> topK = new PriorityQueue<>();
for (int x : stream) {
    topK.offer(x);  // grows unbounded!
}
```

*Why it's wrong:* if you want the top K, you need to `poll()` when size exceeds K. Otherwise you're storing the whole stream.

**Mistake: assuming `ArrayBlockingQueue` with `fair = true` is always better.**

```java
new ArrayBlockingQueue<>(1000, true);  // fair lock
```

*Why it's a trade-off:* fairness prevents starvation but reduces throughput. Only use it when starvation is a real concern.

---

## 9. Trade-offs

| Dimension | `ArrayDeque` | `LinkedList` | `PriorityQueue` | `BlockingQueue` | `ConcurrentLinkedQueue` |
|---|---|---|---|---|---|
| **offer/poll** | O(1) amortized | O(1) | O(log n) | O(1) | O(1) |
| **peek** | O(1) | O(1) | O(1) | O(1) | O(1) |
| **Memory** | Low (array) | High (nodes) | Low (array) | Moderate | Moderate |
| **Order** | FIFO/LIFO | FIFO/LIFO | Priority | FIFO/Priority | FIFO |
| **Thread-safe** | No | No | No | Yes | Yes |
| **Blocking** | No | No | No | Yes | No |
| **Null** | No | Yes | No | No | No |
| **Bounded** | No | No | No | Optional | No |
| **Complexity** | Low | Low | Moderate | Moderate | Moderate |
| **Best for** | General queue/stack | List + queue hybrid | Priority processing | Producer/consumer | Lock-free FIFO |

### Advantages of `Queue`

- Clear contract for ordered processing.
- Efficient end operations (O(1) for most).
- Rich variants for different needs.
- `BlockingQueue` solves producer/consumer cleanly.

### Disadvantages

- No random access.
- No uniqueness (use `Set` if needed).
- `PriorityQueue` iteration is not sorted.
- Thread safety requires choosing the right implementation.
- `ArrayDeque` has no capacity constructor (can't pre-size).

---

## 10. Edge Cases and Limitations

1. **`ArrayDeque` rejects `null`** — `offer(null)` throws NPE. This is by design.

2. **`PriorityQueue` is not stable** — equal elements come out in arbitrary order.

3. **`PriorityQueue` iteration is not sorted** — only `poll` is ordered.

4. **Mutating elements in `PriorityQueue`** — corrupts the heap. Remove, mutate, re-add.

5. **`ConcurrentLinkedQueue.size()` is O(n)** — use `isEmpty()`.

6. **`BlockingQueue.put`/`take` can block forever** — use timed variants if you need a timeout.

7. **`InterruptedException`** — must be handled; don't swallow it.

8. **`SynchronousQueue` has zero capacity** — every `put` waits for a `take`. Useful for handoff, not buffering.

9. **`DelayQueue` elements must implement `Delayed`** — `poll` returns `null` until the delay expires.

10. **`ArrayDeque` grows by doubling** — if you add 10M elements one by one, you'll do ~24 resizes. There's no pre-sizing constructor.

11. **`PriorityQueue` with a comparator inconsistent with `equals()`** — allowed, but can confuse. The queue uses `compareTo`, not `equals`.

12. **`BlockingQueue` fairness** — `ArrayBlockingQueue(capacity, true)` gives FIFO fairness for waiting threads, at a throughput cost.

---

## 11. Professional Perspective

What experienced engineers know that tutorials don't:

**1. `ArrayDeque` is the default.** If you need a queue or stack and you're not crossing threads, use `ArrayDeque`. It's faster and more memory-efficient than `LinkedList` and `Stack`.

**2. `BlockingQueue` is the correct producer/consumer primitive.** Don't hand-roll with `wait`/`notify`. `LinkedBlockingQueue` is the default choice; `ArrayBlockingQueue` when you need a hard bound; `SynchronousQueue` for handoff; `PriorityBlockingQueue` for priority.

**3. Backpressure matters.** An unbounded queue (`LinkedBlockingQueue` default, `ConcurrentLinkedQueue`) can grow until OOM under load. Bounded queues (`ArrayBlockingQueue`) apply backpressure. In production, prefer bounded queues and handle rejection.

**4. `ThreadPoolExecutor` takes a `BlockingQueue`.** Understanding `Queue` is understanding thread pools. The queue type determines the pool's behavior: `LinkedBlockingQueue` → unbounded queue, `SynchronousQueue` → direct handoff, `ArrayBlockingQueue` → bounded with backpressure.

**5. `PriorityQueue` is for top-K, scheduling, and Dijkstra.** It's not a sorted list. For sorted iteration, drain it or use a `TreeSet`.

**6. `ConcurrentLinkedQueue` is lock-free but not blocking.** It's great for high-throughput, non-blocking scenarios. But it has no backpressure — it grows unbounded. Use `BlockingQueue` when you need to slow producers.

**7. Queue choice is a design decision, not a detail.** FIFO vs. priority vs. LIFO changes the semantics of your system. BFS vs. DFS, fair vs. unfair scheduling, backpressure vs. unbounded buffering — these are architectural choices.

**8. `Deque` is more useful than `Queue`.** Most of the time you want `Deque` (both ends). `Queue` is the narrower interface. Use `Deque` for stacks, work-stealing, and sliding windows.

**9. Monitor queue depth.** In production, queue size is a key metric. A growing queue means producers outpace consumers. A shrinking queue means consumers are idle. Both are problems.

**10. `ArrayDeque` is not thread-safe, but `ConcurrentLinkedDeque` is.** If you need a concurrent deque, use `ConcurrentLinkedDeque`. If you need a blocking deque, use `LinkedBlockingDeque`.

---

## 12. Mental Model

**Mental model: The Conveyor Belt with a Rule.**

Imagine a conveyor belt. Items enter at one end and exit at the other. The *rule* determines which item exits next:

- **FIFO**: the item that's been on the belt longest exits first.
- **LIFO**: the item that just arrived exits first (a stack).
- **Priority**: the most important item exits first, regardless of when it arrived.

The belt has two ends (a `Deque`). You can add or remove from either end. Some belts have a maximum length (bounded). Some belts *stop* when full or empty (blocking). Some belts are shared by many workers (concurrent).

The key insight: **a queue is defined by its removal rule, not its storage.** The storage (array, linked list, heap) is an implementation detail. The rule is the contract.

**Re-explained with the model:**

A `Queue` is a conveyor belt with a rule for which item exits next. `ArrayDeque` is a fast circular belt with FIFO or LIFO rules. `PriorityQueue` is a belt that always ejects the highest-priority item, using a heap to find it quickly. `BlockingQueue` is a belt that stops when full or empty, coordinating producers and consumers. The rule determines the behavior; the implementation determines the performance.

---

## 13. Knowledge Check

Answer these in your own words. I'll evaluate them and correct misunderstandings. Don't look up answers first.

**Basic:**

1. What are the two method families in `Queue`? Give an example of each for insertion, removal, and inspection.
2. Name three implementations of `Queue` and one key difference between them.
3. Does `ArrayDeque` allow `null`? Why or why not?

**Why:**

4. Why does `Queue` have both `add`/`offer` and `remove`/`poll`?
5. Why is `PriorityQueue` iteration not sorted?
6. Why is `ArrayDeque` preferred over `LinkedList` for queues?

**Prediction:**

7. What does this print?
   ```java
   Queue<Integer> q = new PriorityQueue<>();
   q.addAll(List.of(3, 1, 4, 1, 5, 9, 2, 6));
   System.out.println(q);
   System.out.println(q.poll());
   System.out.println(q.poll());
   ```
8. What happens here?
   ```java
   Deque<String> d = new ArrayDeque<>();
   d.push("a");
   d.push("b");
   d.push("c");
   System.out.println(d.pop());
   System.out.println(d.pop());
   ```
9. What does this do?
   ```java
   BlockingQueue<String> bq = new SynchronousQueue<>();
   bq.offer("x");
   System.out.println(bq.size());
   ```

**Debugging:**

10. A `PriorityQueue<Task>` is used to schedule tasks. Tasks with the same priority come out in a different order each run. Why?
11. A `ConcurrentLinkedQueue` is used in a hot loop with `size() > 0` as the condition. Performance is terrible. Why?
12. A `BlockingQueue.take()` call is interrupted, but the catch block is empty. What's the bug?

**Scenario:**

13. You need to process 1M URLs with a pool of 10 worker threads. URLs arrive continuously. Which queue do you use and why?
14. You need to implement Dijkstra's algorithm. Which queue do you use and why?
15. You need a stack for a recursive-descent parser. Which class do you use and why?

---

## 14. Practice

### Level 1: Basic understanding

Write a method that takes a `Queue<Integer>` and returns a new `Queue<Integer>` with the elements reversed. Do not use any other data structure except one additional `Queue`.

### Level 2: Implementation

Implement a `Queue<T>` using two stacks (`Deque<T>`). Analyze the amortized time complexity of `offer` and `poll`.

### Level 3: Debugging

The following code is supposed to print tasks in priority order, but it prints them in arbitrary order. Find and fix the bug:

```java
Queue<Task> tasks = new PriorityQueue<>();
tasks.add(new Task("low", 3));
tasks.add(new Task("critical", 1));
tasks.add(new Task("medium", 2));

for (Task t : tasks) {
    System.out.println(t.name());
}

record Task(String name, int priority) {}
```

### Level 4: Real-world scenario

You're building a job scheduler. Jobs have:

- A priority (1–10).
- A submission time.
- A maximum retry count.

Requirements:

- Higher-priority jobs run first.
- Among equal priorities, earlier-submitted jobs run first (FIFO).
- Failed jobs are retried up to their max retry count, with a delay of 5 seconds.
- The scheduler must be thread-safe and bounded.

Design the data structures. Which `Queue` implementation(s) do you use? How do you handle the delay? How do you handle retries? What are the edge cases?

### Level 5: Challenging/problem-solving

Implement a **sliding window maximum** using a `Deque`. Given an array of integers and a window size `k`, return an array where each element is the maximum of the corresponding window.

Example: `nums = [1, 3, -1, -3, 5, 3, 6, 7]`, `k = 3` → `[3, 3, 5, 5, 6, 7]`.

Analyze the time and space complexity. Why is `Deque` the right data structure here?

---

## 15. Final Map

```
                    Collection
                        │
                      Queue
                        │
        ┌───────────────┼───────────────┬──────────────────┐
        │               │               │                  │
     Deque         PriorityQueue   BlockingQueue   ConcurrentLinkedQueue
        │               │               │
   ┌────┴────┐          │        ┌──────┼──────┬──────────┐
   │         │          │        │      │      │          │
ArrayDeque LinkedList  (heap)  Array  Linked  Priority  Synchronous
                              Blocking Blocking Blocking  Queue
                                        │
                                   DelayQueue
                                        │
                                   TransferQueue
```

**Prerequisites:** `Collection`, generics, `Comparable`/`Comparator`, complexity analysis, threading basics.

**`Queue`:** a `Collection` with ordered insertion and removal. FIFO by default, but priority and LIFO are possible.

**Related concepts:** `Deque`, `Stack`, `List`, `BlockingQueue`, `ConcurrentLinkedQueue`.

**Higher-level concepts:** BFS, Dijkstra, task scheduling, producer/consumer, thread pools, message brokers, event loops.

**Practical applications:** BFS, job queues, thread pools, rate limiting, buffering, work-stealing, sliding windows.

---




[[Java]]