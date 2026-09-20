

Both implement `List<E>` (so they share every method from the last tutorial) — this covers what's **different**: their internal structure, methods unique to each, and when to pick one over the other.

---

## The core structural difference

```java
List<String> arrayList = new ArrayList<>();   // backed by a resizable ARRAY
List<String> linkedList = new LinkedList<>();  // backed by a doubly-linked list of NODES
```

### `ArrayList` internally

```
Internal array: [Alireza][Sara][Ali][  ][  ][  ]   ← extra empty slots reserved for growth
Index:              0       1     2    3    4   5
```

Elements sit in **contiguous memory**, accessed directly by computing a memory offset from the index — same principle as a raw Java array (`int[]`), just with automatic resizing logic layered on top.

### `LinkedList` internally

```
[Alireza] ⇄ [Sara] ⇄ [Ali] ⇄ [Reza]
   node        node    node    node
```

Each element is wrapped in a **node** containing the value plus pointers to the **previous** and **next** nodes (this is a **doubly**-linked list). There's no contiguous block of memory — nodes can live anywhere, connected purely through these pointers.

---

## `ArrayList` — definition and behavior

**Definition:** a `List` implementation backed by a **dynamically resizable array**. Optimized for **fast, direct index access**; less efficient for frequent insertions/removals in the middle or at the front.

### How resizing actually works (a detail unique to `ArrayList`)

```java
List<String> list = new ArrayList<>(); // starts with a small internal array (commonly capacity 10)
```

When the internal array fills up, `ArrayList` **allocates a new, larger array** (typically ~1.5x the old size) and **copies every element over** — this happens automatically and transparently, but it's real, occasional overhead.

```java
List<Integer> list = new ArrayList<>(1000); // pre-size the internal array to 1000
```

**`ensureCapacity(int)` and the constructor with an initial capacity** are `ArrayList`-specific — `LinkedList` has no equivalent concept, since it has no underlying array to size.

```java
ArrayList<String> list = new ArrayList<>();
list.ensureCapacity(500); // pre-allocate room for at least 500 elements, avoiding repeated resizing
```

**Why this matters practically:** if you know roughly how many elements you'll add ahead of time, pre-sizing avoids repeated internal array copying as the list grows — a genuine, measurable performance optimization for large lists built incrementally.

### `trimToSize()` — `ArrayList`-specific

```java
ArrayList<String> list = new ArrayList<>(1000);
list.add("only one item");
list.trimToSize(); // shrinks the internal array down to exactly fit current contents (size 1)
```

**Problem it solves:** if you pre-sized generously or removed many elements, the internal array might be holding onto far more capacity than needed, wasting memory. `trimToSize()` reclaims that.

---

## `LinkedList` — definition and behavior

**Definition:** a `List` implementation (and **also** a `Deque` implementation) backed by a **doubly-linked list of nodes**. Optimized for **fast insertion/removal at the beginning or end**; less efficient for random index access.

### `LinkedList` implements BOTH `List` and `Deque` — this is its defining extra feature

```java
LinkedList<String> list = new LinkedList<>();
```

Because it implements `Deque`, `LinkedList` gets **all** the stack/queue methods from the stack/queue tutorial, in addition to every `List` method:

```java
// Deque-specific methods, available on LinkedList but NOT on ArrayList:
list.addFirst("a");        // O(1) — insert at the front
list.addLast("b");          // O(1) — insert at the end
list.removeFirst();          // O(1) — remove from the front
list.removeLast();            // O(1) — remove from the end
list.peekFirst();              // look at front without removing
list.peekLast();                // look at back without removing
list.push("x");                  // stack-style push (adds to front)
list.pop();                        // stack-style pop (removes from front)
list.offer("y");                    // queue-style add (adds to end)
list.poll();                          // queue-style remove (removes from front)
```

```java
LinkedList<String> tasks = new LinkedList<>();
tasks.addLast("Task 1");
tasks.addLast("Task 2");
System.out.println(tasks.removeFirst()); // "Task 1" — using it as a Queue

tasks.push("Urgent Task");
System.out.println(tasks.peekFirst()); // "Urgent Task" — using it as a Stack
```

**This is `LinkedList`'s single biggest distinguishing feature:** `ArrayList` is _only_ a `List`; `LinkedList` is a `List` **and** a full `Deque`, meaning it can genuinely act as a stack or queue directly — though, as covered in the stack/queue tutorial, `ArrayDeque` is generally the **preferred** choice specifically for stack/queue use today, since it's faster and has less per-element memory overhead than `LinkedList`'s node-based structure.

---

## Method-by-method: same method, different performance

These methods exist on **both** (inherited from `List`), but their internal implementation — and therefore their speed — differs completely.

### `get(int index)`

```java
list.get(500); // ArrayList: O(1) — direct memory offset calculation
                 // LinkedList: O(n) — must walk node-by-node from the nearer end (start or end) to reach it
```

**`LinkedList`'s `get()` is smart about direction** — internally, it checks whether the index is closer to the start or the end, and walks from whichever is nearer, but it's still fundamentally `O(n)` in the worst case (middle of a large list).

### `add(E element)` — appending to the end

```java
list.add("new"); // ArrayList: O(1) amortized — usually just writes to the next free slot
                    //            (occasionally O(n) when a resize/copy is triggered)
                    // LinkedList: O(1) — always just attaches a new node at the tail, no resizing ever needed
```

### `add(int index, E element)` — inserting in the middle

```java
list.add(500, "new"); // ArrayList: O(n) — must shift every element after index 500 over by one
                         // LinkedList: O(n) to REACH index 500 (traversal), then O(1) to actually insert
```

**Important nuance:** `LinkedList`'s insertion is only truly `O(1)` if you're already positioned at that spot (e.g., via a `ListIterator`, walking as you go) — inserting "at index 500" cold still costs `O(n)` overall, just for a different reason (traversal, not shifting).

### `remove(int index)`

```java
list.remove(0); // ArrayList: O(n) — must shift every remaining element left by one
                   // LinkedList: O(1) if removing from a KNOWN node (e.g., via iterator);
                   //             O(n) if removing by index (must traverse to find it first)
```

### `contains(Object o)` / `indexOf(Object o)`

```java
list.contains("x"); // ArrayList: O(n) — linear scan
                       // LinkedList: O(n) — linear scan, same cost, just via node traversal instead of array indexing
```

**No difference here** — neither structure has a shortcut for searching by value (that's what `HashSet`/`HashMap` are for, from the data structures tutorial).

---

## Side-by-side performance table

|Operation|`ArrayList`|`LinkedList`|
|---|---|---|
|`get(index)` / `set(index, val)`|`O(1)`|`O(n)`|
|`add(element)` (append to end)|`O(1)` amortized|`O(1)`|
|`add(0, element)` (insert at front)|`O(n)` — shifts everything|`O(1)`|
|`add(index, element)` (middle)|`O(n)` — shifting|`O(n)` — traversal to find position|
|`remove(index)`|`O(n)` — shifting|`O(n)` — traversal (or `O(1)` if already positioned via iterator)|
|`removeFirst()` / `removeLast()`|not available directly (must use `remove(0)`/`remove(size-1)`, both `O(n)`/`O(1)`)|`O(1)` — native `Deque` methods|
|`contains(element)`|`O(n)`|`O(n)`|
|Memory per element|just the element itself (compact array slot)|element + 2 pointers (prev/next) — real overhead|
|Iteration (`for-each`/`iterator()`)|very fast — sequential memory access, cache-friendly|slower — following pointers scattered in memory (less cache-friendly)|

**The memory/cache detail is worth calling out:** because `ArrayList` stores elements in one contiguous memory block, iterating over it is significantly faster in practice than `LinkedList` (even where both are technically `O(n)`) — modern CPUs are heavily optimized for sequential memory access ("cache locality"), and `LinkedList`'s scattered nodes work against that. This is a real, measurable practical difference beyond what Big O alone captures.

---

## `LinkedList`-only convenience: descending iteration

```java
LinkedList<String> list = new LinkedList<>(List.of("a", "b", "c"));

Iterator<String> descending = list.descendingIterator(); // ArrayList has NO equivalent method
while (descending.hasNext()) {
    System.out.println(descending.next()); // c, b, a
}
```

`descendingIterator()` is a `Deque` method, so it's available on `LinkedList` but not on `ArrayList` (which only implements `List`, not `Deque`).

---

## When to choose which — practical decision guide

### Choose `ArrayList` when:

```java
List<User> users = new ArrayList<>();
// Reading by index frequently, mostly appending to the end
for (int i = 0; i < users.size(); i++) {
    process(users.get(i)); // O(1) each time — fast
}
users.add(newUser); // appending — O(1) amortized
```

- You mostly **read** (by index or by iterating)
- You mostly **add/remove at the end**
- You want **best iteration performance** and **lower memory overhead**
- **This is the correct default choice for the vast majority of real-world code** — reach for `ArrayList` unless you have a specific reason not to

### Choose `LinkedList` when:

```java
LinkedList<Task> taskQueue = new LinkedList<>();
taskQueue.addFirst(urgentTask); // frequent insertions at the FRONT
taskQueue.addLast(normalTask);
Task next = taskQueue.removeFirst(); // frequent removals from the FRONT
```

- You frequently insert/remove at the **beginning**, or **both ends**
- You're implementing something that's naturally a **queue or deque pattern** and specifically want `List` methods available too
- **In practice, even here, `ArrayDeque` is usually the better choice** (covered in the stack/queue tutorial) — faster, less memory overhead, and doesn't carry `LinkedList`'s awkward `O(n)` index access if you ever need it. Genuine reasons to pick `LinkedList` specifically (over `ArrayDeque`) are fairly rare in modern code.

### The honest, practical rule of thumb

```
Default to ArrayList.
Only reach for LinkedList if you've profiled/reasoned through a specific
access pattern (heavy front-insertion/removal) that ArrayList handles poorly —
and even then, consider ArrayDeque first if you don't actually need List's
index-based access.
```

This mirrors real-world Java practice: `ArrayList` is overwhelmingly the more commonly used implementation, precisely because most code reads more than it inserts-in-the-middle, and cache-friendly contiguous memory usually wins in practice even in scenarios that look "even" on paper by Big O alone.

---

## Complete example showing the practical difference

```java
import java.util.*;

public class ListComparisonDemo {
    public static void main(String[] args) {
        int n = 100_000;

        List<Integer> arrayList = new ArrayList<>();
        List<Integer> linkedList = new LinkedList<>();

        // Appending to the end — both reasonably fast
        long start = System.nanoTime();
        for (int i = 0; i < n; i++) arrayList.add(i);
        System.out.println("ArrayList append: " + (System.nanoTime() - start) / 1_000_000 + "ms");

        start = System.nanoTime();
        for (int i = 0; i < n; i++) linkedList.add(i);
        System.out.println("LinkedList append: " + (System.nanoTime() - start) / 1_000_000 + "ms");

        // Random access by index — ArrayList wins dramatically
        start = System.nanoTime();
        for (int i = 0; i < 1000; i++) arrayList.get(n / 2);
        System.out.println("ArrayList get(middle): " + (System.nanoTime() - start) / 1_000_000 + "ms");

        start = System.nanoTime();
        for (int i = 0; i < 1000; i++) linkedList.get(n / 2); // MUCH slower — walks halfway through the list, 1000 times
        System.out.println("LinkedList get(middle): " + (System.nanoTime() - start) / 1_000_000 + "ms");

        // Insert/remove at the front — LinkedList wins dramatically
        start = System.nanoTime();
        for (int i = 0; i < 10_000; i++) arrayList.add(0, i); // O(n) shift, every time
        System.out.println("ArrayList add(0): " + (System.nanoTime() - start) / 1_000_000 + "ms");

        start = System.nanoTime();
        for (int i = 0; i < 10_000; i++) linkedList.addFirst(i); // O(1), every time
        System.out.println("LinkedList addFirst: " + (System.nanoTime() - start) / 1_000_000 + "ms");
    }
}
```

Running this makes the theoretical Big O differences from the earlier tutorial concretely visible — `ArrayList.get()` and `LinkedList.addFirst()` will each be dramatically faster than their counterpart, in exactly the direction predicted by their underlying data structure.

---

## Summary

|Aspect|`ArrayList`|`LinkedList`|
|---|---|---|
|Backed by|resizable array|doubly-linked nodes|
|Implements|`List`|`List` **and** `Deque`|
|Fast at|index access, appending, iteration|front/back insertion & removal|
|Slow at|inserting/removing in the middle or front|index access|
|Unique methods|`ensureCapacity()`, `trimToSize()`|`addFirst/Last`, `removeFirst/Last`, `push/pop`, `offer/poll`, `descendingIterator()`|
|Memory overhead|low (just elements)|higher (element + 2 pointers per node)|
|Cache performance|excellent (contiguous memory)|poor (scattered nodes)|
|Default/common choice|**Yes — almost always start here**|rare; consider `ArrayDeque` first for stack/queue needs|



[[Java]]