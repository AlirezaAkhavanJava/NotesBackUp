

## The full hierarchy diagram

```
                          Iterable<T>
                              │
                          Collection<E>
                    ┌─────────┼──────────┐
                    │         │          │
                 List<E>    Set<E>     Queue<E>
                    │         │          │
      ┌─────────────┤    ┌────┼────┐     │
      │             │    │    │    │     │
 ArrayList    LinkedList │  HashSet│   Deque<E>
      │           (also  │    │    │     │
      │          a Deque)│    │ LinkedHashSet
      │                  │    │              ┌──────┼──────┐
      │              SortedSet<E>            │      │      │
      │                  │                ArrayDeque│  LinkedList
Vector (legacy)       TreeSet             (also a   │ (also a List)
      │                                      Queue) │
   Stack (legacy)                                 PriorityQueue
                                                  (implements Queue,
                                                   not Deque)


                          Map<K,V>  ← SEPARATE hierarchy (NOT a Collection)
                    ┌──────────┼──────────┐
                    │          │          │
                HashMap   SortedMap<K,V>  │
                    │          │       LinkedHashMap
              LinkedHashMap  TreeMap    (insertion/access order)
             (also here,
              subtype of
              HashMap)
                    │
              Hashtable (legacy)
                    │
              Properties (legacy)
```

---

## Layer 1: The root interfaces

### `Iterable<T>`

**The absolute root.** Any class implementing this can be used in a for-each loop. Defines one method: `iterator()`.

```java
public interface Iterable<T> {
    Iterator<T> iterator();
}
```

**Why it matters:** this is _why_ `for (String s : list)` works — the for-each loop is just syntactic sugar over calling `.iterator()` and looping with `.hasNext()`/`.next()`.

### `Collection<E>`

**The root of "a group of objects."** Extends `Iterable`. Defines the baseline operations every collection type should support: `add()`, `remove()`, `size()`, `contains()`, `clear()`, `isEmpty()`.

```java
public interface Collection<E> extends Iterable<E> { ... }
```

Covered in full detail in the earlier "Collection API" tutorial — this is the interface `List`, `Set`, and `Queue` all build on.

---

## Layer 2: The three branches of `Collection`

### `List<E>`

**Ordered** collection — elements have a defined position (index), duplicates allowed.

```java
List<String> names = new ArrayList<>();
names.add("Alireza");
names.add("Sara");
names.add("Alireza"); // duplicates ARE allowed
System.out.println(names.get(0)); // access by index
```

**Key trait:** insertion order is preserved, and you can access any element directly by its numeric index.

### `Set<E>`

**No duplicates.** Adding an element that already exists (per `.equals()`) has no effect.

```java
Set<String> names = new HashSet<>();
names.add("Alireza");
names.add("Alireza"); // ignored — already present
System.out.println(names.size()); // 1
```

**Key trait:** models a mathematical "set" — uniqueness is the whole point.

### `Queue<E>`

**FIFO-oriented** collection — designed around adding at one end, removing from the other. Covered in depth in the stack/queue tutorial.

```java
Queue<String> queue = new ArrayDeque<>();
queue.offer("first");
queue.offer("second");
System.out.println(queue.poll()); // "first"
```

### `Deque<E>` (extends `Queue<E>`)

**Double-ended queue** — add/remove from _both_ ends. Can act as a `Queue` (FIFO) or a `Stack` (LIFO).

```java
Deque<Integer> deque = new ArrayDeque<>();
deque.addFirst(1);
deque.addLast(2);
```

---

## Layer 3: `List` implementations

### `ArrayList`

Backed by a **resizable array**. `O(1)` index access, `O(n)` insert/remove in the middle (must shift elements).

```java
List<String> list = new ArrayList<>();
list.add("a");
list.add("b");
System.out.println(list.get(0)); // fast — direct array index
```

**Use when:** you mostly read by index or add/remove at the end.

### `LinkedList` (implements both `List` AND `Deque`)

Backed by a **doubly-linked list** of nodes. `O(1)` insert/remove at either end, `O(n)` index access (must walk from start).

```java
LinkedList<String> list = new LinkedList<>();
list.addFirst("a"); // fast — no shifting needed
list.addLast("b");
```

**Use when:** you frequently insert/remove at the beginning or end, rarely access by index.

### `Vector` (legacy)

Like `ArrayList`, but every method is `synchronized` (thread-safe, but slower). Predates the Collections Framework itself (Java 1.0).

```java
Vector<String> v = new Vector<>(); // rarely used in modern code
```

**Use when:** almost never in new code — prefer `ArrayList`, or `Collections.synchronizedList()`/`CopyOnWriteArrayList` if you specifically need thread safety.

### `Stack` (legacy, extends `Vector`)

A LIFO stack implementation — but discouraged (covered in the stack/queue tutorial) in favor of `ArrayDeque`.

```java
Stack<Integer> stack = new Stack<>(); // legacy — prefer ArrayDeque
```

---

## Layer 3: `Set` implementations

### `HashSet`

Backed by a **hash table**. No ordering guarantee. `O(1)` average add/remove/contains.

```java
Set<String> set = new HashSet<>();
set.add("banana");
set.add("apple");
System.out.println(set); // order NOT guaranteed — e.g. [banana, apple] or [apple, banana]
```

**Use when:** you just need uniqueness and fast lookup, and don't care about order.

### `LinkedHashSet` (extends `HashSet`)

Same as `HashSet`, but **preserves insertion order** via an internal linked list.

```java
Set<String> set = new LinkedHashSet<>();
set.add("banana");
set.add("apple");
System.out.println(set); // [banana, apple] — insertion order preserved
```

**Use when:** you need uniqueness _and_ predictable iteration order, with minimal extra cost over `HashSet`.

### `SortedSet<E>` (interface, extends `Set`)

Adds the guarantee that elements are always kept in **sorted order**, plus range-based methods (`first()`, `last()`, `headSet()`, `tailSet()`).

### `TreeSet` (implements `SortedSet`)

Backed by a **red-black tree** (a self-balancing binary search tree). `O(log n)` add/remove/contains, always iterates in sorted order.

```java
Set<Integer> set = new TreeSet<>();
set.add(5);
set.add(1);
set.add(3);
System.out.println(set); // [1, 3, 5] — always sorted
```

**Use when:** you need uniqueness _and_ sorted order, or range queries (`subSet()`, `higher()`, `lower()`).

---

## Layer 3: `Queue`/`Deque` implementations

### `ArrayDeque`

Backed by a **resizable array**, optimized for adding/removing at both ends. `O(1)` for all standard stack/queue operations. **The modern, preferred choice for both stacks and queues.**

```java
Deque<Integer> deque = new ArrayDeque<>();
deque.push(1);   // stack-style
deque.offer(2);   // queue-style
```

### `PriorityQueue` (implements `Queue`, NOT `Deque`)

Backed by a **heap**. Elements come out in priority order (natural ordering, or a custom `Comparator`), not insertion order.

```java
Queue<Integer> pq = new PriorityQueue<>();
pq.offer(5);
pq.offer(1);
System.out.println(pq.poll()); // 1 — smallest first, not insertion order
```

**Use when:** you need "always process the highest/lowest priority item next" — task scheduling, shortest-path algorithms.

---

## The separate hierarchy: `Map<K,V>`

**Important:** `Map` does **not** extend `Collection` — it's structurally different (key-value pairs, not single elements) and sits in its own parallel hierarchy, though it's still considered part of the overall Collections Framework.

### `Map<K,V>` (root interface)

```java
public interface Map<K,V> { ... } // NOT extending Collection
```

Defines `put()`, `get()`, `remove()`, `containsKey()`, `keySet()`, `values()`, `entrySet()`.

### `HashMap`

Backed by a **hash table**. No ordering guarantee. `O(1)` average put/get/remove.

```java
Map<String, Integer> map = new HashMap<>();
map.put("Alireza", 25);
System.out.println(map.get("Alireza")); // 25
```

**Use when:** general-purpose key-value storage, order doesn't matter.

### `LinkedHashMap` (extends `HashMap`)

Preserves insertion order (or optionally, access order — useful for building LRU caches).

```java
Map<String, Integer> map = new LinkedHashMap<>();
map.put("b", 2);
map.put("a", 1);
System.out.println(map); // {b=2, a=1} — insertion order preserved
```

### `SortedMap<K,V>` (interface, extends `Map`)

Guarantees keys are kept in sorted order, plus range methods.

### `TreeMap` (implements `SortedMap`)

Backed by a **red-black tree**. `O(log n)` operations, always iterates by sorted key order.

```java
Map<String, Integer> map = new TreeMap<>();
map.put("banana", 2);
map.put("apple", 1);
System.out.println(map); // {apple=1, banana=2} — sorted by key
```

### `Hashtable` (legacy, extends `Dictionary`, implements `Map`)

Like `HashMap`, but `synchronized` (thread-safe, slower). Predates the Collections Framework.

```java
Hashtable<String, Integer> table = new Hashtable<>(); // legacy — prefer HashMap or ConcurrentHashMap
```

### `Properties` (legacy, extends `Hashtable`)

Specialized `String`-to-`String` map, historically used for config files (`.properties` files, covered in the IO tutorials).

```java
Properties props = new Properties();
props.setProperty("db.url", "localhost");
```

---

## Quick summary table — every class, its structure, and its guarantee

|Class|Implements|Backed by|Ordering|Key trait|
|---|---|---|---|---|
|`ArrayList`|`List`|resizable array|insertion order|fast index access|
|`LinkedList`|`List`, `Deque`|doubly-linked list|insertion order|fast insert/remove at ends|
|`Vector`|`List`|resizable array|insertion order|legacy, synchronized|
|`Stack`|`List` (via `Vector`)|resizable array|insertion order|legacy, use `ArrayDeque` instead|
|`HashSet`|`Set`|hash table|none|fast uniqueness check|
|`LinkedHashSet`|`Set`|hash table + linked list|insertion order|uniqueness + order|
|`TreeSet`|`Set`, `SortedSet`|red-black tree|sorted|uniqueness + sorted order|
|`ArrayDeque`|`Deque`, `Queue`|resizable array|insertion order|modern stack/queue choice|
|`PriorityQueue`|`Queue`|heap|priority order|always returns min/max next|
|`HashMap`|`Map`|hash table|none|fast key-value lookup|
|`LinkedHashMap`|`Map`|hash table + linked list|insertion/access order|lookup + order (LRU caches)|
|`TreeMap`|`Map`, `SortedMap`|red-black tree|sorted by key|lookup + sorted order|
|`Hashtable`|`Map`|hash table|none|legacy, synchronized|
|`Properties`|`Map` (via `Hashtable`)|hash table|none|String config key-value pairs|

---

## Choosing the right implementation — decision guide

```
Need a List?
  ├── Mostly index access, add/remove at the end? → ArrayList
  └── Mostly add/remove at the beginning/middle?   → LinkedList

Need a Set?
  ├── Just uniqueness, no order needed?     → HashSet
  ├── Uniqueness + insertion order?          → LinkedHashSet
  └── Uniqueness + sorted order?              → TreeSet

Need a Map?
  ├── Just key-value lookup, no order?      → HashMap
  ├── Lookup + insertion/access order?       → LinkedHashMap
  └── Lookup + sorted by key?                 → TreeMap

Need a Stack or Queue?
  ├── Standard LIFO or FIFO?                → ArrayDeque
  └── Priority-ordered processing?           → PriorityQueue

Need thread-safety?
  → java.util.concurrent versions instead: ConcurrentHashMap,
    CopyOnWriteArrayList, BlockingQueue (see the concurrency tutorial)
```

---

## How this ties everything together

This hierarchy is the concrete map of every concept from the last several tutorials: `Collection`/`Map` are the **interfaces** (the "what"), each implementation is a **data structure** (the "how" — array, linked list, hash table, red-black tree, heap), and the choice between siblings (`ArrayList` vs `LinkedList`, `HashMap` vs `TreeMap`) is a **Big O trade-off** decision, exactly as covered in those tutorials. Every box in this diagram is something you now have the vocabulary to reason about — not just "what it's called," but _why_ it exists as a distinct choice rather than being redundant with its siblings.

[[Java]]