

## Definition

A **data structure** is a specific way of organizing, storing, and accessing data in memory so that certain operations (adding, removing, searching, sorting) can be done efficiently for a given use case. It's not about _what_ data you store — it's about _how_ it's arranged, and that arrangement determines how fast (or slow) different operations on it are.

This is a **computer science concept**, not a Java-specific one — every language has some version of this. In Java, most common data structures are provided ready-made through the **Collections Framework** you just learned (`ArrayList`, `HashMap`, `LinkedList`, etc.) — those classes are _implementations_ of well-known data structures.

---

## Why data structures matter — the core problem they solve

Different tasks need different trade-offs. Consider just "storing a bunch of items":

- If you mostly need **fast lookup by position** ("give me the 5th item"), one arrangement works best.
- If you mostly need **fast lookup by a key** ("give me the item named 'Alireza'"), a different arrangement works best.
- If you mostly need **fast insertion/removal at the front**, yet another arrangement works best.
- If you need items **always sorted**, yet another.

**No single data structure is fastest at everything** — each one makes deliberate trade-offs. Choosing the right one is choosing the right trade-off for what your program actually needs to do often.

```
Task: "store 1 million items, and constantly check if a given item exists"

Using a plain array/list → checking existence = scan through, up to 1,000,000 comparisons (slow)
Using a hash-based structure → checking existence = ~1 comparison (fast)
```

Same data, same fundamental task — wildly different performance, purely because of the _structure_ chosen to hold it.

---

## The two things every data structure is evaluated on

### 1. What operations it supports well

- Access by index?
- Access by key?
- Insert/remove at the beginning? End? Middle?
- Maintain sorted order automatically?
- Allow duplicates?

### 2. How fast each operation is — Big O notation

This is the standard way to describe data structure performance, in terms of how the time/work grows as the amount of data (`n`) grows:

|Notation|Meaning|Example|
|---|---|---|
|`O(1)`|constant time — same speed no matter how much data|array index access|
|`O(log n)`|grows slowly as data grows — very efficient|binary search, balanced tree operations|
|`O(n)`|grows proportionally with data size|scanning a list from start to end|
|`O(n log n)`|typical for efficient sorting algorithms|`Collections.sort()`|
|`O(n²)`|grows quickly — becomes slow for large data|naive nested-loop comparisons|

You'll see this notation constantly in data structure discussions — it's the standard vocabulary for comparing "how good" a structure is at a given operation, independent of any specific hardware.

---

## Categories of data structures

### Linear structures — data arranged in a sequence

|Structure|Shape|Good at|
|---|---|---|
|**Array**|fixed-size, contiguous memory|`O(1)` access by index|
|**List** (dynamic array)|resizable array|`O(1)` index access, `O(n)` insert/remove in the middle|
|**Linked List**|nodes, each pointing to the next|`O(1)` insert/remove at known position, `O(n)` access by index|
|**Stack**|last-in-first-out (LIFO)|`O(1)` push/pop from one end|
|**Queue**|first-in-first-out (FIFO)|`O(1)` add at back, remove from front|
|**Deque**|double-ended queue|`O(1)` add/remove from both ends|

### Hash-based structures — data organized by a computed key

|Structure|Shape|Good at|
|---|---|---|
|**Hash Table / Hash Map**|keys mapped to values via a hash function|`O(1)` average lookup/insert/delete by key|
|**Hash Set**|like a hash map, but only keys (no values)|`O(1)` average "does this exist?" check|

### Tree structures — hierarchical, branching data

|Structure|Shape|Good at|
|---|---|---|
|**Binary Tree**|each node has up to 2 children|hierarchical relationships|
|**Binary Search Tree (BST)**|binary tree, left < parent < right|`O(log n)` search, if balanced|
|**Balanced Tree** (Red-Black, AVL)|self-balancing BST|guaranteed `O(log n)` even in worst case|
|**Heap**|tree where each parent is smaller/larger than children|`O(log n)` insert, `O(1)` peek min/max|
|**Trie**|tree specialized for strings, shared prefixes|fast prefix search (autocomplete)|

### Graph structures — arbitrary, non-hierarchical connections

|Structure|Shape|Good at|
|---|---|---|
|**Graph**|nodes connected by edges, any pattern|modeling networks, relationships, routes|

---

## How this maps to Java's Collections Framework

This is the direct payoff — every data structure category above has a real Java class implementing it:

|Data structure concept|Java implementation|
|---|---|
|Dynamic array|`ArrayList`|
|Linked list|`LinkedList`|
|Stack|`ArrayDeque` (used as a stack), or legacy `Stack`|
|Queue|`ArrayDeque`, `LinkedList` (both implement `Queue`)|
|Hash table (key→value)|`HashMap`|
|Hash table (key only)|`HashSet`|
|Self-balancing tree (sorted map)|`TreeMap` (red-black tree internally)|
|Self-balancing tree (sorted set)|`TreeSet`|
|Insertion-ordered hash table|`LinkedHashMap` / `LinkedHashSet`|
|Heap (priority-ordered)|`PriorityQueue`|

**This is exactly why Java gives you multiple `List` implementations (`ArrayList` vs `LinkedList`), multiple `Set` implementations (`HashSet` vs `TreeSet`), and multiple `Map` implementations (`HashMap` vs `TreeMap` vs `LinkedHashMap`)** — they're not redundant; each is a different underlying data structure, with different performance trade-offs, all exposed through the same shared interface (`List`, `Set`, `Map`) so your code can swap between them easily.

```java
List<String> fast_index_access = new ArrayList<>();   // backed by an ARRAY
List<String> fast_insert_remove = new LinkedList<>();  // backed by a LINKED LIST

Map<String, Integer> fast_lookup = new HashMap<>();     // backed by a HASH TABLE
Map<String, Integer> sorted = new TreeMap<>();            // backed by a BALANCED TREE
```

---

## A concrete example of why the choice matters

```java
List<Integer> arrayList = new ArrayList<>();
List<Integer> linkedList = new LinkedList<>();

// Fill both with 1,000,000 elements...

arrayList.get(500000);      // O(1) — jumps directly to that memory position
linkedList.get(500000);      // O(n) — must walk through 500,000 nodes one by one!

linkedList.addFirst(1);       // O(1) — just adjusts pointers at the front
arrayList.add(0, 1);           // O(n) — must SHIFT every existing element over by one!
```

**Same interface (`List`), same data, opposite performance characteristics** — purely because of the underlying data structure. This is the entire reason "which data structure should I use" is a real, consequential engineering decision, not a stylistic one.

---

## Summary

|Aspect|Definition|
|---|---|
|**Data structure**|a way of organizing data in memory to make certain operations efficient|
|**Why it matters**|different structures trade off speed differently across operations (access, insert, delete, search)|
|**How it's measured**|Big O notation — how operation cost scales with data size|
|**Categories**|linear (array, list, stack, queue), hash-based (hash map/set), tree-based (BST, heap, trie), graph|
|**In Java**|the Collections Framework's various implementing classes (`ArrayList`, `HashMap`, `TreeSet`, etc.) are concrete data structures, all unified under shared interfaces (`List`, `Map`, `Set`)|

## Where this fits with what you already know

This is the missing conceptual layer underneath the Collection API tutorial: `Collection`/`List`/`Set`/`Map` are **interfaces** describing _what_ you can do; the actual classes (`ArrayList`, `HashMap`, `TreeSet`...) are **data structures** describing _how_ it's done underneath, and that "how" is what determines real-world performance. Understanding data structures is what lets you pick `ArrayList` vs `LinkedList`, or `HashMap` vs `TreeMap`, deliberately — based on which operations your specific program actually needs to be fast — rather than picking one arbitrarily.

[[Java]]