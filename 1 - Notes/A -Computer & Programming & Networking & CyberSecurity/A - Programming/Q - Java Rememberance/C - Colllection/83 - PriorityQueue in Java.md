
## PriorityQueue in Java

**PriorityQueue** is a class in the Java Collections Framework that implements a **queue** where elements are processed based on **priority** rather than insertion order. It's backed by a **binary heap** data structure.

```java
public class PriorityQueue<E> extends AbstractQueue<E>
    implements Serializable
```

---

### Key Characteristics

- **Not FIFO** — elements are ordered by priority
- **Min-heap by default** — smallest element (natural ordering) at the head
- **No null elements** allowed
- **Not thread-safe** (use `PriorityBlockingQueue` for concurrency)
- **Unbounded** but has internal capacity that grows automatically
- **O(log n)** for add/remove, **O(1)** for peek
- **Iteration order is NOT guaranteed** to be sorted

---

### How It Works Internally

PriorityQueue uses a **binary heap** stored in an array:

```
        [1]           ← head (min)
       /   \
     [3]   [2]
     / \   /
   [7] [4] [5]

Array representation: [1, 3, 2, 7, 4, 5]
```

- **Parent** at index `i` → children at `2i+1` and `2i+2`
- Heap property: parent ≤ children (for min-heap)
- `add()` and `poll()` restore heap property in O(log n)

---

### Basic Example

```java
PriorityQueue<Integer> pq = new PriorityQueue<>();

pq.add(50);
pq.add(10);
pq.add(30);
pq.add(20);

System.out.println(pq.peek());  // 10 (smallest)
System.out.println(pq.poll());  // 10 (removed)
System.out.println(pq.poll());  // 20
System.out.println(pq.poll());  // 30
System.out.println(pq.poll());  // 50
```

---

### Common Methods

| Method | Description |
|--------|-------------|
| `add(E e)` / `offer(E e)` | Inserts element |
| `poll()` | Removes and returns the head (min) |
| `peek()` | Returns head without removing |
| `remove(Object o)` | Removes specific element |
| `size()` | Number of elements |
| `isEmpty()` | Checks if empty |
| `clear()` | Removes all elements |
| `contains(Object o)` | Checks existence |
| `iterator()` | Returns iterator (⚠️ not sorted) |

---

### Max-Heap with Comparator

By default, `PriorityQueue` is a **min-heap**. To make it a **max-heap**, pass a comparator:

```java
// Max-heap
PriorityQueue<Integer> maxPQ = new PriorityQueue<>(Comparator.reverseOrder());
maxPQ.add(50);
maxPQ.add(10);
maxPQ.add(30);

System.out.println(maxPQ.poll()); // 50
System.out.println(maxPQ.poll()); // 30
System.out.println(maxPQ.poll()); // 10
```

---

### Custom Objects

```java
class Task {
    String name;
    int priority;
    
    Task(String name, int priority) {
        this.name = name;
        this.priority = priority;
    }
}

// Lower priority number = higher priority
PriorityQueue<Task> tasks = new PriorityQueue<>(
    Comparator.comparingInt(t -> t.priority)
);

tasks.add(new Task("Email", 3));
tasks.add(new Task("Bug fix", 1));
tasks.add(new Task("Meeting", 2));

while (!tasks.isEmpty()) {
    System.out.println(tasks.poll().name);
}
// Output: Bug fix, Meeting, Email
```

---

### Iteration Gotcha

```java
PriorityQueue<Integer> pq = new PriorityQueue<>();
pq.addAll(Arrays.asList(50, 10, 30, 20));

// ⚠️ Does NOT print in sorted order!
for (int n : pq) {
    System.out.print(n + " ");  // e.g., 10 20 30 50 (order not guaranteed)
}

// ✅ To get sorted order, poll repeatedly
while (!pq.isEmpty()) {
    System.out.print(pq.poll() + " "); // 10 20 30 50
}
```

The iterator traverses the underlying **array**, not the heap order. Only `poll()` returns elements in priority order.

---

## ArrayDeque in Java

**ArrayDeque** (short for "Array Double-Ended Queue") is a resizable array implementation of the `Deque` interface, supporting element insertion and removal at **both ends**.

```java
public class ArrayDeque<E> extends AbstractCollection<E>
    implements Deque<E>, Cloneable, Serializable
```

---

### Key Characteristics

- **Double-ended** — add/remove from both front and back
- **No capacity restrictions** — grows as needed
- **No null elements** allowed
- **Not thread-safe**
- **Faster than `Stack`** (when used as a stack) and **faster than `LinkedList`** (when used as a queue)
- **O(1) amortized** for add/remove at both ends
- **Not thread-safe**

---

### How It Works Internally

ArrayDeque uses a **circular array** with head and tail pointers:

```
    head              tail
      ↓                ↓
[ ][A][B][C][D][E][ ][ ]
  ↑                    ↑
wrap-around when reaching array end
```

- Default initial capacity: **16**
- Capacity always a **power of 2** (for fast modulo via bitmask)
- Grows by doubling when full

---

### Basic Example

```java
ArrayDeque<String> deque = new ArrayDeque<>();

// Add to both ends
deque.addFirst("B");
deque.addFirst("A");    // front
deque.addLast("C");
deque.addLast("D");     // back

System.out.println(deque); // [A, B, C, D]

// Remove from both ends
System.out.println(deque.removeFirst()); // A
System.out.println(deque.removeLast());  // D
System.out.println(deque);               // [B, C]
```

---

### Common Methods

**Add operations:**

| Method | Description |
|--------|-------------|
| `addFirst(E e)` | Add to front (throws if fails) |
| `addLast(E e)` | Add to back (throws if fails) |
| `offerFirst(E e)` | Add to front (returns false if fails) |
| `offerLast(E e)` | Add to back (returns false if fails) |
| `push(E e)` | Same as `addFirst()` (stack) |
| `add(E e)` | Same as `addLast()` |

**Remove operations:**

| Method | Description |
|--------|-------------|
| `removeFirst()` | Remove from front (throws if empty) |
| `removeLast()` | Remove from back (throws if empty) |
| `pollFirst()` | Remove from front (returns null if empty) |
| `pollLast()` | Remove from back (returns null if empty) |
| `pop()` | Same as `removeFirst()` (stack) |
| `poll()` | Same as `pollFirst()` |

**Peek operations:**

| Method | Description |
|--------|-------------|
| `peekFirst()` | View front (null if empty) |
| `peekLast()` | View back (null if empty) |
| `getFirst()` | View front (throws if empty) |
| `getLast()` | View back (throws if empty) |
| `peek()` | Same as `peekFirst()` |

---

### Using ArrayDeque as a Stack (LIFO)

```java
ArrayDeque<Integer> stack = new ArrayDeque<>();

stack.push(1);
stack.push(2);
stack.push(3);

System.out.println(stack.pop()); // 3
System.out.println(stack.pop()); // 2
System.out.println(stack.pop()); // 1
```

**Better than `Stack` class** — `Stack` is synchronized (slow) and legacy.

---

### Using ArrayDeque as a Queue (FIFO)

```java
ArrayDeque<String> queue = new ArrayDeque<>();

queue.offer("First");
queue.offer("Second");
queue.offer("Third");

System.out.println(queue.poll()); // First
System.out.println(queue.poll()); // Second
System.out.println(queue.poll()); // Third
```

**Better than `LinkedList`** — ArrayDeque is faster and uses less memory.

---

### ArrayDeque vs LinkedList (as Deque)

| Feature | ArrayDeque | LinkedList |
|---------|-----------|------------|
| Underlying structure | Circular array | Doubly-linked list |
| Memory per element | Lower (no node overhead) | Higher (pointers) |
| Cache locality | Excellent | Poor |
| Speed (add/remove ends) | Faster | Slower |
| Null elements | ❌ Not allowed | ✅ Allowed |
| Random access | ❌ No | ❌ No (O(n)) |
| Preferred? | ✅ Yes for Deque | Only if null needed |

---

### PriorityQueue vs ArrayDeque

| Feature | PriorityQueue | ArrayDeque |
|---------|---------------|------------|
| Ordering | Priority (heap) | Insertion order (ends) |
| Access pattern | Min/max only | Both ends |
| Use as stack/queue | ❌ No | ✅ Both |
| Insert/remove complexity | O(log n) | O(1) amortized |
| Peek complexity | O(1) (min only) | O(1) (both ends) |
| Null elements | ❌ No | ❌ No |
| Thread-safe | ❌ No | ❌ No |

---

### Practical Examples

**PriorityQueue — Task Scheduler:**
```java
class Task implements Comparable<Task> {
    String name;
    int priority;
    
    Task(String name, int priority) {
        this.name = name;
        this.priority = priority;
    }
    
    public int compareTo(Task other) {
        return Integer.compare(this.priority, other.priority);
    }
}

PriorityQueue<Task> scheduler = new PriorityQueue<>();
scheduler.offer(new Task("Low prio", 5));
scheduler.offer(new Task("Critical", 1));
scheduler.offer(new Task("Medium", 3));

while (!scheduler.isEmpty()) {
    System.out.println(scheduler.poll().name);
}
// Output: Critical, Medium, Low prio
```

**ArrayDeque — Palindrome Checker:**
```java
public static boolean isPalindrome(String s) {
    ArrayDeque<Character> deque = new ArrayDeque<>();
    for (char c : s.toLowerCase().toCharArray()) {
        if (Character.isLetterOrDigit(c)) {
            deque.addLast(c);
        }
    }
    while (deque.size() > 1) {
        if (!deque.removeFirst().equals(deque.removeLast())) {
            return false;
        }
    }
    return true;
}

System.out.println(isPalindrome("A man a plan a canal Panama")); // true
```

**ArrayDeque — Sliding Window Maximum:**
```java
public static int[] maxSlidingWindow(int[] nums, int k) {
    ArrayDeque<Integer> deque = new ArrayDeque<>(); // stores indices
    int[] result = new int[nums.length - k + 1];
    
    for (int i = 0; i < nums.length; i++) {
        // Remove indices outside window
        while (!deque.isEmpty() && deque.peekFirst() < i - k + 1) {
            deque.pollFirst();
        }
        // Remove smaller elements
        while (!deque.isEmpty() && nums[deque.peekLast()] < nums[i]) {
            deque.pollLast();
        }
        deque.offerLast(i);
        
        if (i >= k - 1) {
            result[i - k + 1] = nums[deque.peekFirst()];
        }
    }
    return result;
}
```

---

## Summary

### PriorityQueue
- **Heap-based** queue ordered by priority
- **Min-heap by default** (use `Comparator.reverseOrder()` for max-heap)
- **O(log n)** insert/remove, **O(1)** peek
- **Iterator is NOT sorted** — only `poll()` respects order
- **No nulls** allowed
- Use for: task scheduling, Dijkstra's algorithm, k-smallest/largest problems

### ArrayDeque
- **Resizable circular array** implementation of `Deque`
- **Double-ended** — add/remove at both front and back in **O(1)**
- **No nulls** allowed
- **Faster than `Stack` and `LinkedList`** for stack/queue use cases
- Use for: stack, queue, deque, sliding window, palindrome, BFS/DFS traversal

Both are **not thread-safe** — for concurrent use, prefer `PriorityBlockingQueue` or `LinkedBlockingDeque`.


[[Java]]