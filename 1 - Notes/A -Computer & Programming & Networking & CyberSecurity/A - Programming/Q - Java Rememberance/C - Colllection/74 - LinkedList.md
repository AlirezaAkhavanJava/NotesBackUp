

## Definition

**`LinkedList<E>`** is a class in `java.util` that implements **both** `List<E>` and `Deque<E>`, backed internally by a **doubly-linked list of nodes** — each element is wrapped in a node containing a reference to the previous node and the next node, rather than sitting in a contiguous array.

```java
List<String> names = new LinkedList<>();
Deque<String> stack = new LinkedList<>(); // same class, used as a Deque instead
```

```java
public class LinkedList<E> extends AbstractSequentialList<E>
    implements List<E>, Deque<E>, Cloneable, Serializable { ... }
```

---

## The problem `LinkedList` solves

### `ArrayList`'s weakness: inserting/removing at the front (or middle) is expensive

As covered in the `ArrayList` tutorial, `ArrayList` stores elements in **contiguous memory**. That's exactly why inserting or removing near the front is costly — every element after the insertion/removal point has to physically shift over in memory.

```java
List<String> list = new ArrayList<>(List.of("b", "c", "d", "e"));
list.add(0, "a"); // must shift EVERY existing element one position to the right — O(n)
```

For a list of a million elements, inserting at the front means physically moving nearly a million elements in memory, every single time. If your program does this **repeatedly** (a queue of incoming tasks, a history log where new entries go at the front), this becomes a genuine performance problem.

### `LinkedList` solves this by never needing to shift anything

Since elements are connected by **pointers**, not physical array position, inserting at the front is just a matter of creating one new node and updating a couple of pointers — nothing else in the structure needs to move at all.

```java
LinkedList<String> list = new LinkedList<>(List.of("b", "c", "d", "e"));
list.addFirst("a"); // O(1) — just rewires a couple of pointers, no shifting
```

```
Before: [b] ⇄ [c] ⇄ [d] ⇄ [e]
After:  [a] ⇄ [b] ⇄ [c] ⇄ [d] ⇄ [e]
          ↑ just one new node, linked in — everything else untouched
```

**This is the core problem `LinkedList` exists to solve: efficient insertion and removal at the ends (or at a known position), at the cost of losing fast random-access by index.**

---

## Core features of `LinkedList`

### 1. Ordered — maintains insertion order

Same as `ArrayList`, elements are kept in the sequence they were added (or explicitly reordered), each conceptually having a position — though there's no true "index" stored anywhere; positions are only reachable by walking the chain of nodes.

```java
LinkedList<String> list = new LinkedList<>();
list.add("Alireza");
list.add("Sara");
System.out.println(list); // [Alireza, Sara] — insertion order
```

**Not automatically sorted**, exactly like `ArrayList` — you must explicitly call `.sort()` if you want sorted order.

```java
LinkedList<Integer> nums = new LinkedList<>(List.of(5, 1, 3));
nums.sort(null);
System.out.println(nums); // [1, 3, 5]
```

### 2. Allows duplicates

```java
LinkedList<String> list = new LinkedList<>();
list.add("Alireza");
list.add("Alireza"); // fine — duplicates allowed, same as ArrayList
System.out.println(list); // [Alireza, Alireza]
```

Same behavior as `ArrayList` here — `List` in general permits duplicates; it's `Set` implementations that forbid them.

### 3. Allows `null` elements

```java
LinkedList<String> list = new LinkedList<>();
list.add("Alireza");
list.add(null);      // perfectly legal
list.add("Sara");
System.out.println(list); // [Alireza, null, Sara]
```

**Worth noting a genuine subtlety here that doesn't apply to `ArrayList`:** because `LinkedList` also implements `Deque`, and some `Deque` methods use `null` as a special "nothing here" sentinel return value...

```java
LinkedList<String> empty = new LinkedList<>();
String result = empty.peekFirst(); // returns null — meaning "the deque is empty"
```

...you can get genuine ambiguity if you also store `null` as an actual element: `peekFirst()` returning `null` could mean either "the list is empty" **or** "the first element genuinely is `null`." This is a real, documented gotcha specific to using `LinkedList`/`Deque` with `null` elements — `ArrayList` has no such ambiguity since it has no equivalent "empty sentinel" methods.

### 4. No index-based fast access — must traverse

```java
LinkedList<String> list = new LinkedList<>(List.of("a", "b", "c", "d", "e"));
String middle = list.get(2); // O(n) — walks node by node from whichever end is closer
```

This is `LinkedList`'s core trade-off, covered in depth in the last tutorial — it does **not** implement `RandomAccess` (the marker interface from `ArrayList`'s tutorial), precisely because index access here is genuinely slow, unlike `ArrayList`.

```java
System.out.println(list instanceof RandomAccess); // false — LinkedList does NOT implement this marker
```

### 5. Fast insertion/removal at both ends — via `Deque`

This is `LinkedList`'s headline feature, and it's the direct payoff of the doubly-linked structure:

```java
LinkedList<String> list = new LinkedList<>();
list.addFirst("a");   // O(1)
list.addLast("z");     // O(1)
list.removeFirst();     // O(1)
list.removeLast();       // O(1)
```

None of these are available on `ArrayList` directly with the same guaranteed performance — `ArrayList`'s equivalent (`add(0, x)` / `remove(0)`) is `O(n)`.

### 6. Dual identity — works as `List`, `Stack`, or `Queue`

Because `LinkedList` implements `Deque`, it inherits every method from the stack/queue tutorial:

```java
// As a Queue (FIFO)
Queue<String> queue = new LinkedList<>();
queue.offer("first");
queue.offer("second");
System.out.println(queue.poll()); // "first"

// As a Stack (LIFO)
Deque<String> stack = new LinkedList<>();
stack.push("first");
stack.push("second");
System.out.println(stack.pop()); // "second"
```

`ArrayList` has **no** such dual identity — it's purely a `List`, nothing else. This is `LinkedList`'s most structurally distinctive feature compared to `ArrayList`.

### 7. `descendingIterator()` — backward traversal

```java
LinkedList<String> list = new LinkedList<>(List.of("a", "b", "c"));
Iterator<String> reverse = list.descendingIterator();
while (reverse.hasNext()) {
    System.out.println(reverse.next()); // c, b, a
}
```

A `Deque`-specific method, unavailable on `ArrayList` (which would require `Collections.reverse()` or manual index-based backward looping instead).

### 8. Not thread-safe

```java
List<String> list = new LinkedList<>(); // NOT safe for concurrent access, same caveat as ArrayList
```

Same situation as `ArrayList` — no built-in synchronization. If you need thread safety:

```java
List<String> synced = Collections.synchronizedList(new LinkedList<>());
```

Or, more commonly in real concurrent code, reach for a purpose-built concurrent structure like `ConcurrentLinkedDeque` or `LinkedBlockingDeque` (`java.util.concurrent`), which are specifically designed for safe concurrent producer-consumer patterns — directly connecting to the concurrency tutorials.

### 9. Fail-fast iteration

Same behavior as `ArrayList` — structural modification during a for-each loop (other than via the iterator's own `remove()`) throws `ConcurrentModificationException`.

```java
LinkedList<String> list = new LinkedList<>(List.of("a", "b", "c"));
for (String item : list) {
    list.add("d"); // ConcurrentModificationException
}
```

### 10. Implements `Cloneable` and `Serializable`

```java
LinkedList<String> original = new LinkedList<>(List.of("a", "b"));
LinkedList<String> copy = (LinkedList<String>) original.clone(); // shallow copy
```

Same as `ArrayList` — both marker interfaces are present, working exactly as described in the marker interfaces tutorial.

### 11. Higher memory overhead per element

This is a genuine structural cost, not a "feature" in the positive sense, but worth stating explicitly since it's a real trade-off:

```
ArrayList element storage:  just the value, in a compact array slot
LinkedList element storage: the value + a reference to the previous node + a reference to the next node
```

Each `LinkedList` node carries **two extra object references** beyond the actual data — for a list of primitives-turned-`Integer` objects, this overhead can be substantial relative to the useful data being stored. This is exactly why `ArrayList`'s cache-friendly, compact memory layout tends to win in practice for many workloads, even ones that look favorable to `LinkedList` on paper.

---

## Constructors

```java
List<String> empty = new LinkedList<>();                         // empty
List<String> fromCollection = new LinkedList<>(List.of("a", "b")); // copies elements in
```

**Note:** unlike `ArrayList`, there's **no constructor accepting an initial capacity** — `LinkedList` has no underlying array to pre-size in the first place, since nodes are allocated individually as needed. This absence itself is informative about the structural difference between the two.

---

## Summary table — `LinkedList` at a glance

|Feature|`LinkedList` behavior|
|---|---|
|Backing structure|doubly-linked list of nodes|
|Order|preserves insertion order (NOT sorted automatically)|
|Duplicates|allowed|
|`null` elements|allowed (but ambiguous with `Deque`'s null-as-empty-signal methods)|
|Index-based access|yes, but `O(n)` — slow|
|Insert/remove at front/back|`O(1)` — its core strength|
|Implements `Deque`/`Queue`/Stack-style ops|Yes — unique to `LinkedList` among `List` implementations|
|Thread-safe|No — same caveat as `ArrayList`|
|Iteration behavior|fail-fast, same as `ArrayList`|
|Implements `RandomAccess`|**No** — signals slow indexed access|
|Implements `Cloneable`|Yes|
|Implements `Serializable`|Yes|
|Memory overhead|higher — each element carries 2 extra pointer references|
|Best at|insertion/removal at the ends, or at a known position via iterator|
|Weak at|index access, and raw iteration speed (less cache-friendly than `ArrayList`)|

---

## Direct comparison to `ArrayList` — the features that differ

|Feature|`ArrayList`|`LinkedList`|
|---|---|---|
|`RandomAccess` marker|Yes|No|
|Implements `Deque`|No|Yes|
|`ensureCapacity()` / `trimToSize()`|Yes|N/A — no array to manage|
|Initial-capacity constructor|Yes|No|
|`descendingIterator()`|No|Yes|
|`addFirst`/`addLast`/`push`/`pop`/`offer`/`poll`|No|Yes|
|Fast index access|Yes|No|
|Fast front insertion/removal|No|Yes|
|Memory per element|lower|higher|

---

## Where this fits with everything you've learned

`LinkedList` is a direct, practical embodiment of the data structures tutorial's core message: **no single structure wins at everything** — it deliberately trades away `ArrayList`'s fast index access to gain fast front/back operations, exactly the kind of trade-off the Big O tutorial was built to help you reason about. Its dual `List`/`Deque` identity also ties directly back to the stack/queue tutorial — though as noted there, `ArrayDeque` is now generally preferred _specifically_ for stack/queue use cases, leaving `LinkedList` most useful today in the narrower case where you genuinely need both `List`-style access _and_ efficient operations at the ends within the same object.


[[Java]]