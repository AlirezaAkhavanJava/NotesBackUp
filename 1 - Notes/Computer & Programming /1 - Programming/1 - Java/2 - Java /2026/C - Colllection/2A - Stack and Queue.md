

## The core distinction

Both **Stack** and **Queue** are **linear data structures** that restrict _how_ you can add and remove elements — unlike a `List`, where you can insert/access anywhere, a stack and queue each only let you interact with specific ends. The restriction is exactly what makes them useful: fewer options means simpler, faster, more predictable behavior for the specific access pattern they model.

```
Stack: LIFO — Last In, First Out
Queue: FIFO — First In, First Out
```

---

## Stack — LIFO (Last In, First Out)

### Definition

A **stack** is a data structure where elements are added and removed from the **same end**, called the "top." The most recently added element is always the first one removed.

**Real-world analogy:** a stack of plates — you put a new plate on top, and when you take one off, you take the top one (the most recently placed one), not the bottom.

```
Push 1 → [1]
Push 2 → [1, 2]
Push 3 → [1, 2, 3]
Pop    → returns 3 → [1, 2]
Pop    → returns 2 → [1]
```

### Core operations

|Operation|Meaning|Big O|
|---|---|---|
|`push(item)`|add to the top|`O(1)`|
|`pop()`|remove and return the top item|`O(1)`|
|`peek()`|look at the top item without removing it|`O(1)`|
|`isEmpty()`|check if the stack has no elements|`O(1)`|

### Using a stack in Java

Java's old `Stack` class exists, but is **legacy and discouraged** — it extends `Vector` (an old, synchronized, slower list class), which is unnecessary overhead for typical single-threaded use.

```java
// Old way — avoid in new code
Stack<Integer> stack = new java.util.Stack<>();
```

**The modern, recommended approach — use `Deque` (specifically `ArrayDeque`) as a stack:**

```java
import java.util.Deque;
import java.util.ArrayDeque;

Deque<Integer> stack = new ArrayDeque<>();

stack.push(1);
stack.push(2);
stack.push(3);

System.out.println(stack.peek()); // 3 — top element, not removed
System.out.println(stack.pop());   // 3 — removed and returned
System.out.println(stack.pop());    // 2
System.out.println(stack);           // [1]
```

**Why `ArrayDeque` over `Stack`:** `Deque` (double-ended queue) naturally supports adding/removing from either end, so it works perfectly as a stack (`push`/`pop` at one end) _or_ a queue (add at one end, remove from the other) — and `ArrayDeque` is faster and not needlessly synchronized, unlike the legacy `Stack` class.

### Real-world use cases

```java
// Undo functionality — most recent action is undone first
Deque<String> undoHistory = new ArrayDeque<>();
undoHistory.push("Typed 'Hello'");
undoHistory.push("Typed 'Hello World'");
undoHistory.push("Deleted 'World'");

String lastAction = undoHistory.pop(); // "Deleted 'World'" — undo the MOST RECENT action first
```

```java
// Checking balanced parentheses — a classic stack algorithm
boolean isBalanced(String expr) {
    Deque<Character> stack = new ArrayDeque<>();
    for (char c : expr.toCharArray()) {
        if (c == '(') {
            stack.push(c);
        } else if (c == ')') {
            if (stack.isEmpty()) return false; // closing with nothing open
            stack.pop();
        }
    }
    return stack.isEmpty(); // balanced only if everything opened was also closed
}
```

**Other real uses:** the "call stack" itself (method calls, including recursion) is literally a stack; browser back-button history; parsing expressions (calculators, compilers).

---

## Queue — FIFO (First In, First Out)

### Definition

A **queue** is a data structure where elements are added at one end (the "back"/"tail") and removed from the other end (the "front"/"head"). The first element added is always the first one removed.

**Real-world analogy:** a line at a coffee shop — the first person in line is served first; new people join at the back.

```
Enqueue 1 → [1]
Enqueue 2 → [1, 2]
Enqueue 3 → [1, 2, 3]
Dequeue    → returns 1 → [2, 3]
Dequeue    → returns 2 → [3]
```

### Core operations

|Operation|Meaning|Big O|
|---|---|---|
|`offer(item)` / `add(item)`|add to the back|`O(1)`|
|`poll()` / `remove()`|remove and return the front item|`O(1)`|
|`peek()` / `element()`|look at the front item without removing it|`O(1)`|
|`isEmpty()`|check if the queue has no elements|`O(1)`|

**`add`/`remove`/`element` throw exceptions on failure (e.g., removing from an empty queue); `offer`/`poll`/`peek` return `null`/`false` instead — prefer `offer`/`poll`/`peek` for safer, exception-free handling of edge cases.**

### Using a queue in Java

```java
import java.util.Queue;
import java.util.LinkedList;

Queue<String> queue = new LinkedList<>(); // LinkedList implements Queue

queue.offer("Alireza");
queue.offer("Sara");
queue.offer("Ali");

System.out.println(queue.peek()); // Alireza — front, not removed
System.out.println(queue.poll());  // Alireza — removed and returned
System.out.println(queue.poll());   // Sara
System.out.println(queue);            // [Ali]
```

**`ArrayDeque` also works as a `Queue`** (and is generally preferred over `LinkedList` for this — better performance, no per-node object overhead):

```java
Queue<String> queue = new ArrayDeque<>();
queue.offer("Alireza");
queue.offer("Sara");
System.out.println(queue.poll()); // Alireza
```

### Real-world use cases

```java
// Task processing — process requests in the order they arrived
Queue<String> taskQueue = new ArrayDeque<>();
taskQueue.offer("Process order #1");
taskQueue.offer("Process order #2");
taskQueue.offer("Process order #3");

while (!taskQueue.isEmpty()) {
    String task = taskQueue.poll();
    System.out.println("Handling: " + task); // handled in the order they were added
}
```

**Other real uses:** printer job queues, request handling in servers, breadth-first search (BFS) in graphs/trees, `BlockingQueue` for producer-consumer threading (covered in the concurrency tutorials — this is a queue with built-in thread coordination).

---

## `Deque` — the double-ended queue that covers both

Since `Deque` supports adding/removing from **either** end, it's genuinely the most flexible and commonly recommended structure — capable of acting as a stack, a queue, or both at once.

```java
Deque<Integer> deque = new ArrayDeque<>();

deque.addFirst(1);    // add to front
deque.addLast(2);      // add to back
deque.offerFirst(0);    // add to front (safe version)
deque.offerLast(3);      // add to back (safe version)

System.out.println(deque); // [0, 1, 2, 3]

deque.pollFirst(); // removes from front → 0
deque.pollLast();   // removes from back → 3
```

|Deque method|Acts like|
|---|---|
|`push()` / `pop()` / `peek()`|Stack (all operate on the front)|
|`offer()` / `poll()` / `peek()`|Queue (offer adds to back, poll/peek read from front)|
|`addFirst()` / `addLast()` / `removeFirst()` / `removeLast()`|explicit double-ended control|

---

## Priority Queue — a queue ordered by priority instead of insertion order

Worth mentioning since it's a genuinely common variant: **`PriorityQueue`** is a queue where elements come out in **priority order** (smallest/largest first, based on natural ordering or a `Comparator`), not insertion order — technically implemented with a **heap** data structure underneath (mentioned in the last tutorial).

```java
import java.util.PriorityQueue;

PriorityQueue<Integer> pq = new PriorityQueue<>();
pq.offer(5);
pq.offer(1);
pq.offer(3);

System.out.println(pq.poll()); // 1 — smallest first, NOT insertion order
System.out.println(pq.poll()); // 3
System.out.println(pq.poll()); // 5
```

**Real-world use:** task scheduling by priority, Dijkstra's shortest-path algorithm, "always process the most urgent item next."

---

## Side-by-side comparison

||Stack|Queue|
|---|---|---|
|Order|LIFO — last in, first out|FIFO — first in, first out|
|Add operation|`push()`|`offer()` / `add()`|
|Remove operation|`pop()`|`poll()` / `remove()`|
|Peek operation|`peek()` (top)|`peek()` (front)|
|Java interface|`Deque` (modern)|`Queue`|
|Recommended implementation|`ArrayDeque`|`ArrayDeque` (or `LinkedList`)|
|Real-world analogy|stack of plates|line at a store|
|Common use cases|undo history, recursion/call stack, expression parsing|task processing, request handling, BFS|

---

## Summary

|Concept|Definition|
|---|---|
|**Stack**|LIFO structure — add/remove from the same end ("top")|
|**Queue**|FIFO structure — add at back, remove from front|
|**`Deque`**|double-ended queue — can act as either a stack or a queue|
|**`PriorityQueue`**|queue ordered by priority, not insertion order — backed by a heap|
|**Modern Java practice**|use `ArrayDeque` for both stacks and queues — avoid legacy `Stack`|

## Where this connects to what you already know

Stack and Queue are concrete examples of the "linear structures" category from the last tutorial, and they're a direct, practical illustration of _why_ data structure choice matters: both could technically be implemented with an `ArrayList` (removing from the end is `O(1)`, but removing from the front is `O(n)` — a shift every time), but `ArrayDeque`'s internal design makes **both ends** `O(1)`, which is exactly the performance guarantee a proper stack/queue implementation needs to actually deliver on its contract.

[[Java]]