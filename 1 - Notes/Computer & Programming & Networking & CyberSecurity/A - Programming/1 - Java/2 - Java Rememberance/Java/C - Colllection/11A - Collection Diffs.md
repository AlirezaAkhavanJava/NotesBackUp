
The important thing is to understand **the hierarchy first**, then compare the concrete implementations.

Java Collections Framework has two main branches:

```text
                    Iterable
                       │
                   Collection
          ┌────────────┼─────────────┐
          │            │             │
         List          Set          Queue
          │            │             │
          │       ┌────┴────┐       Deque
          │       │         │         │
          │   SortedSet  NavigableSet │
          │                          │
       ArrayList                    ...
       LinkedList

                    Map          ← separate hierarchy
                     │
                SortedMap
                     │
                NavigableMap
```

Modern Java also has the **Sequenced** interfaces (`SequencedCollection`, `SequencedSet`, `SequencedMap`), introduced in Java 21 and present in Java 25. ([Oracle Docs](https://docs.oracle.com/en/java/javase/26/core/java-core-libraries-developer-guide.pdf?utm_source=chatgpt.com "Core Libraries"))

## 1. Core interfaces

|Interface|Stores|Duplicates|Ordering|Indexed access|Main idea|
|---|---|--:|---|--:|---|
|`Collection<E>`|Elements|Depends|Depends|❌|Root of most collections|
|`List<E>`|Elements|✅|Ordered|✅|Sequence of elements|
|`Set<E>`|Elements|❌|Depends|❌|Unique elements|
|`SortedSet<E>`|Elements|❌|Sorted|❌|Sorted unique elements|
|`NavigableSet<E>`|Elements|❌|Sorted + navigation|❌|Sorted set + `floor`, `ceiling`, etc.|
|`Queue<E>`|Elements|Usually ✅|Usually FIFO|❌|Elements waiting for processing|
|`Deque<E>`|Elements|Usually ✅|Both ends|❌|Double-ended queue / stack|
|`Map<K,V>`|Key → value|Keys ❌|Depends|❌|Lookup by key|
|`SortedMap<K,V>`|Key → value|Keys ❌|Sorted by key|❌|Sorted map|
|`NavigableMap<K,V>`|Key → value|Keys ❌|Sorted + navigation|❌|Sorted map + navigation|

`Map` is **not** a subtype of `Collection`; it is a separate hierarchy. ([Oracle Docs](https://docs.oracle.com/javase/tutorial/collections/interfaces/index.html?utm_source=chatgpt.com "Lesson: Interfaces (The Java™ Tutorials > Collections)"))

---

# 2. `List` implementations

|Class|Internal idea|Order|Duplicates|`get(i)`|Insert/remove middle|Best use|
|---|---|---|--:|--:|--:|---|
|`ArrayList`|Dynamic array|Insertion|✅|**Fast O(1)**|O(n)|General-purpose list|
|`LinkedList`|Doubly linked list|Insertion|✅|O(n)|O(1)*|Specialized deque/list|
|`Vector`|Synchronized dynamic array|Insertion|✅|O(1)|O(n)|Legacy code|
|`Stack`|Legacy `Vector` stack|Insertion|✅|O(1)|—|**Avoid; use `Deque`**|
|`CopyOnWriteArrayList`|Copy-on-write array|Insertion|✅|O(1)|**Expensive**|Many reads, few writes|

* `LinkedList` insertion/removal is O(1) **once you already have the node/iterator position**. Finding that position may cost O(n).

`ArrayList` is generally the default `List`; Oracle describes it as the common general-purpose implementation. ([Oracle Docs](https://docs.oracle.com/javase/tutorial/collections/implementations/?utm_source=chatgpt.com "Lesson: Implementations (The Java™ Tutorials > Collections)"))

### `ArrayList` vs `LinkedList`

```text
ArrayList
    [A][B][C][D][E]
     ↑
 contiguous-ish array storage
```

Excellent:

```java
list.get(500);       // O(1)
list.set(500, x);    // O(1)
```

Potentially expensive:

```java
list.add(0, x);      // O(n)
list.remove(0);      // O(n)
```

---

```text
LinkedList

A ↔ B ↔ C ↔ D ↔ E
```

Good at operations at the ends:

```java
list.addFirst(x);
list.addLast(x);

list.removeFirst();
list.removeLast();
```

But:

```java
list.get(500);       // O(n)
```

So **don't choose `LinkedList` simply because "linked lists have fast insertion."** In real Java applications, `ArrayList` is usually the better default.

---

# 3. `Set` implementations

|Class|Structure|Duplicates|Order|Typical basic operation|Sorted?|
|---|---|--:|---|---|--:|
|`HashSet`|Hash table|❌|No guaranteed encounter order|O(1) average|❌|
|`LinkedHashSet`|Hash table + linked structure|❌|**Insertion order**|O(1) average|❌|
|`TreeSet`|Red-black tree|❌|**Sorted**|O(log n)|✅|
|`EnumSet`|Bit-vector-like specialized structure|❌|Enum declaration order|Very fast|Specialized|
|`CopyOnWriteArraySet`|Copy-on-write array|❌|Insertion/encounter semantics|Read-heavy|❌|

The three fundamental general-purpose implementations are `HashSet`, `LinkedHashSet`, and `TreeSet`. ([Oracle Docs](https://docs.oracle.com/javase/tutorial/collections/interfaces/set.html?utm_source=chatgpt.com "The Set Interface (The Java™ Tutorials > Collections > Interfaces)"))

### The mental model

```text
HashSet
    uniqueness
    +
    fast lookup
    -
    no ordering guarantee
```

```text
LinkedHashSet
    uniqueness
    +
    fast lookup
    +
    insertion order
```

```text
TreeSet
    uniqueness
    +
    sorted order
    +
    navigation
    -
    O(log n) operations
```

Example:

```java
Set<Integer> a = new HashSet<>();
Set<Integer> b = new LinkedHashSet<>();
Set<Integer> c = new TreeSet<>();
```

Given:

```text
5, 1, 3, 2, 4
```

Conceptually:

```text
HashSet       → unspecified encounter order
LinkedHashSet → 5 1 3 2 4
TreeSet       → 1 2 3 4 5
```

---

# 4. `Queue` and `Deque`

|Class|Interface(s)|Order|Main behavior|Typical use|
|---|---|---|---|---|
|`PriorityQueue`|`Queue`|Priority|Smallest/highest-priority element at head depending on comparator|Scheduling, algorithms|
|`ArrayDeque`|`Deque`|End-based|Add/remove from both ends|Stack + queue|
|`LinkedList`|`List`, `Deque`, `Queue`|Insertion|Both ends|Specialized cases|
|`ConcurrentLinkedQueue`|`Queue`|FIFO|Lock-free/concurrent|Multi-threaded queues|
|`ArrayBlockingQueue`|`BlockingQueue`|FIFO|Bounded blocking queue|Producer/consumer|
|`LinkedBlockingQueue`|`BlockingQueue`|FIFO|Optionally bounded blocking queue|Producer/consumer|
|`PriorityBlockingQueue`|`BlockingQueue`|Priority|Thread-safe priority queue|Concurrent scheduling|

Java's `Queue` API explicitly distinguishes insertion/extraction/inspection operations and provides exception-returning and special-value-returning forms. ([Oracle Docs](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Queue.html?utm_source=chatgpt.com "Queue (Java SE 25 & JDK 25)"))

---

# 5. `Deque` — extremely important

`Deque` means:

> **Double Ended Queue**

It supports both ends:

```text
             Deque
        ┌──────┴──────┐
        ↓             ↓
      FRONT          BACK

 addFirst()       addLast()
 removeFirst()    removeLast()
 peekFirst()      peekLast()
```

`Deque` can therefore behave as either:

```text
Queue (FIFO)

A → B → C

removeFirst() → A
```

or:

```text
Stack (LIFO)

A
B
C

removeFirst() → C
```

Oracle's Java 25 API defines `Deque` as extending both `Queue` and `SequencedCollection`. ([Oracle Docs](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Deque.html?utm_source=chatgpt.com "Deque (Java SE 25 & JDK 25)"))

### Modern recommendation

Instead of:

```java
Stack<Integer> stack = new Stack<>();
```

use:

```java
Deque<Integer> stack = new ArrayDeque<>();
```

---

# 6. `Map` implementations

This is one of the most important tables to memorize.

|Class|Structure|Key duplicates|Ordering|Typical operations|Sorted?|
|---|---|--:|---|---|--:|
|`HashMap`|Hash table|❌|No guaranteed encounter order|O(1) average|❌|
|`LinkedHashMap`|Hash table + linked structure|❌|**Insertion/access order**|O(1) average|❌|
|`TreeMap`|Red-black tree|❌|**Sorted by key**|O(log n)|✅|
|`Hashtable`|Legacy synchronized hash table|❌|No guaranteed order|O(1) average|❌|
|`ConcurrentHashMap`|Concurrent hash-based map|❌|No guaranteed order|O(1) average|❌|
|`WeakHashMap`|Weak-reference-based keys|❌|No guaranteed order|Hash-based|❌|
|`IdentityHashMap`|Identity comparison|❌*|No guaranteed order|Hash-based|❌|
|`EnumMap`|Specialized enum-key map|❌|Enum order|Very fast|❌|

* `IdentityHashMap` uses reference identity (`==`) rather than ordinary `equals()` semantics for keys.

---

# 7. `HashMap` vs `LinkedHashMap` vs `TreeMap`

This is the key distinction:

```text
HashMap

     FAST
      │
      ↓
 key → value
 key → value
 key → value

No ordering guarantee
```

```text
LinkedHashMap

     FAST
      │
      ↓
 key → value
 key → value
 key → value

Maintains encounter order
```

```text
TreeMap

       SORTED
          │
          ↓
       Red-black
          tree

key → value
key → value
key → value
```

### Example

```java
Map<Integer, String> map = new HashMap<>();
```

Use when you primarily need:

```java
map.get(id);
map.put(id, user);
map.containsKey(id);
```

---

```java
Map<Integer, String> map = new LinkedHashMap<>();
```

Use when you need:

```text
fast hash lookup
+
predictable iteration order
```

`LinkedHashMap` maintains a doubly linked list through entries, normally giving insertion order; it can also be configured for access-order behavior. ([Oracle Docs](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/LinkedHashMap.html?utm_source=chatgpt.com "LinkedHashMap (Java SE 25 & JDK 25)"))

---

```java
Map<Integer, String> map = new TreeMap<>();
```

Use when you need:

```java
map.firstKey();
map.lastKey();
map.floorKey(x);
map.ceilingKey(x);
```

because the keys are maintained in sorted order.

---

# 8. Modern Java: Sequenced Collections

This is something older Java tutorials often completely miss.

Java's newer hierarchy includes:

```text
SequencedCollection
       │
   ┌───┴────────┐
   │            │
  List         Deque
```

and:

```text
SequencedSet
      │
   Set
      │
 LinkedHashSet
```

and:

```text
SequencedMap
      │
    Map
      │
 LinkedHashMap
```

Java 25's API reflects these relationships. ([Oracle Docs](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Deque.html?utm_source=chatgpt.com "Deque (Java SE 25 & JDK 25)"))

This gives APIs such as:

```java
getFirst()
getLast()
addFirst()
addLast()
removeFirst()
removeLast()
reversed()
```

depending on the interface.

This was added to make **encounter order** a first-class concept in the Collections Framework.

---

# 9. Immutable / unmodifiable collections

Modern Java also gives factory methods:

```java
List.of(...)
Set.of(...)
Map.of(...)
```

Example:

```java
List<String> names =
        List.of("Alice", "Bob", "Charlie");
```

You cannot modify it:

```java
names.add("Dave"); // UnsupportedOperationException
```

There are also:

```java
List.copyOf(...)
Set.copyOf(...)
Map.copyOf(...)
```

These are different from ordinary mutable implementations such as `ArrayList` and `HashMap`.

---

# 10. Concurrent collections

These matter when multiple threads access a collection.

|Class|Main purpose|
|---|---|
|`ConcurrentHashMap`|Concurrent map|
|`ConcurrentLinkedQueue`|Concurrent non-blocking queue|
|`ConcurrentLinkedDeque`|Concurrent non-blocking deque|
|`CopyOnWriteArrayList`|Read-heavy concurrent list|
|`CopyOnWriteArraySet`|Read-heavy concurrent set|
|`BlockingQueue` implementations|Producer/consumer|
|`BlockingDeque` implementations|Blocking double-ended queue|

Don't confuse:

```java
HashMap
```

with:

```java
ConcurrentHashMap
```

`HashMap` is not generally safe for unsynchronized concurrent mutation.

---

# 11. The "which one do I choose?" table

|Requirement|Usually choose|
|---|---|
|General list|`ArrayList`|
|Unique values|`HashSet`|
|Unique + insertion order|`LinkedHashSet`|
|Unique + sorted|`TreeSet`|
|General key/value lookup|`HashMap`|
|Key/value + insertion order|`LinkedHashMap`|
|Key/value + sorted keys|`TreeMap`|
|Queue|`ArrayDeque` / appropriate `Queue`|
|Stack|`ArrayDeque`|
|Priority-based processing|`PriorityQueue`|
|Thread-safe map|`ConcurrentHashMap`|
|Producer/consumer|`BlockingQueue` implementation|
|Lots of concurrent reads, rare writes|`CopyOnWriteArrayList`|
|Enum keys|`EnumMap`|
|Enum values as a set|`EnumSet`|

Oracle's general-purpose implementation guidance similarly identifies `ArrayList`, `HashSet`, and `HashMap` as the common defaults, with `ArrayDeque` as a general-purpose deque. ([Oracle Docs](https://docs.oracle.com/javase/tutorial/collections/implementations/?utm_source=chatgpt.com "Lesson: Implementations (The Java™ Tutorials > Collections)"))

---

# 12. The most important differences to memorize

Think in **four dimensions**:

### `List`

```text
ORDERED
INDEXED
DUPLICATES ALLOWED
```

### `Set`

```text
UNIQUE
NO INDEX
ORDER DEPENDS ON IMPLEMENTATION
```

### `Queue`

```text
PROCESSING ORDER
HEAD / TAIL
```

### `Deque`

```text
BOTH ENDS
QUEUE + STACK
```

### `Map`

```text
KEY → VALUE
UNIQUE KEYS
NOT A Collection
```

Then the implementations become much easier:

```text
                Fast lookup       Ordered       Sorted

HashMap             ✓                ✗             ✗
LinkedHashMap       ✓                ✓             ✗
TreeMap             O(log n)         ✓             ✓

HashSet             ✓                ✗             ✗
LinkedHashSet       ✓                ✓             ✗
TreeSet             O(log n)         ✓             ✓

ArrayList            ✓*               ✓             ✗
LinkedList           ✗                ✓             ✗
```

`ArrayList`'s "fast lookup" is specifically **indexed lookup**, not arbitrary value lookup; searching by value is still O(n).

## The hierarchy worth putting in your notes

```text
java.lang.Iterable
        │
        ▼
java.util.Collection
        │
        ├── List
        │    ├── ArrayList
        │    ├── LinkedList
        │    ├── Vector
        │    └── CopyOnWriteArrayList
        │
        ├── Set
        │    ├── HashSet
        │    ├── LinkedHashSet
        │    ├── SortedSet
        │    │     └── TreeSet
        │    └── EnumSet
        │
        └── Queue
             ├── Deque
             │    ├── ArrayDeque
             │    └── LinkedList
             │
             └── PriorityQueue


java.util.Map
        │
        ├── HashMap
        │    └── LinkedHashMap
        │
        ├── SortedMap
        │    └── TreeMap
        │
        ├── ConcurrentHashMap
        ├── EnumMap
        ├── WeakHashMap
        └── Hashtable
```

The big conceptual point is: **interfaces describe the behavior you need; concrete classes determine how that behavior is implemented.** That's why professional Java code commonly looks like:

```java
List<User> users = new ArrayList<>();

Set<String> permissions = new HashSet<>();

Map<Long, User> usersById = new HashMap<>();

Deque<Task> tasks = new ArrayDeque<>();
```

rather than declaring everything directly as the implementation type.


[[Java]]