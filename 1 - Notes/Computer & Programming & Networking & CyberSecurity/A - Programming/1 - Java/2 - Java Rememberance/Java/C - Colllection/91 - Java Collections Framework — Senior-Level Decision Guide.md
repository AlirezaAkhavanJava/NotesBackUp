


A complete reference for choosing, using, and reasoning about every major collection in Java.

---

## 1. Top-Level Taxonomy

```
Iterable
├── Collection
│   ├── List          (ordered, indexed, duplicates allowed)
│   ├── Set           (no duplicates)
│   │   └── SortedSet → NavigableSet
│   ├── Queue         (FIFO / processing order)
│   │   └── Deque     (double-ended)
│   └── BlockingQueue / BlockingDeque   (concurrent, blocking)
└── Map               (key → value, no duplicates by key)
    ├── SortedMap → NavigableMap
    └── ConcurrentMap
```

---

## 2. Definitions & Usage Guide — Every Collection

### LISTS (ordered, indexed, duplicates allowed)

| Class | Definition | Backing Structure | Best For |
|---|---|---|---|
| `ArrayList` | Resizable array | Array | Default list; random access, iteration |
| `LinkedList` | Doubly-linked list; also implements `Deque` | Linked nodes | Frequent add/remove at ends; rarely preferred |
| `Vector` | Legacy synchronized list | Array | Legacy only — avoid |
| `Stack` | Legacy LIFO stack extending `Vector` | Array | Legacy only — use `ArrayDeque` |
| `CopyOnWriteArrayList` | Thread-safe; snapshots on write | Array (copy per write) | Read-heavy concurrent lists |

### SETS (no duplicates)

| Class | Definition | Backing Structure | Best For |
|---|---|---|---|
| `HashSet` | Unordered set | Hash table | Default set |
| `LinkedHashSet` | Insertion-ordered set | Hash table + linked list | Set with predictable iteration |
| `TreeSet` | Sorted set (`NavigableSet`) | Red-Black Tree | Sorted / range queries |
| `EnumSet` | Bit-vector set of enum values | Bit vector | Fastest set for enums |
| `CopyOnWriteArraySet` | Thread-safe set | Copy-on-write array | Read-heavy concurrent sets |
| `ConcurrentSkipListSet` | Thread-safe sorted set | Skip list | Concurrent + sorted |

### QUEUES & DEQUES

| Class | Definition | Ordering | Best For |
|---|---|---|---|
| `ArrayDeque` | Resizable circular array deque | FIFO / LIFO | Default queue and stack |
| `LinkedList` | Doubly-linked deque | FIFO / LIFO | Only if you need null elements |
| `PriorityQueue` | Binary heap | Priority | Priority ordering, single thread |
| `PriorityBlockingQueue` | Thread-safe priority queue | Priority | Concurrent priority work |
| `ArrayBlockingQueue` | Bounded blocking queue | FIFO | Fixed-size producer/consumer |
| `LinkedBlockingQueue` | Optionally bounded blocking queue | FIFO | General concurrent queue |
| `LinkedBlockingDeque` | Bounded blocking deque | FIFO / LIFO | Concurrent double-ended work |
| `ConcurrentLinkedQueue` | Lock-free unbounded queue | FIFO | High-throughput concurrent queue |
| `ConcurrentLinkedDeque` | Lock-free unbounded deque | FIFO / LIFO | High-throughput concurrent deque |
| `DelayQueue` | Blocking queue with delays | Delay-based | Scheduled / retry queues |
| `SynchronousQueue` | Zero-capacity rendezvous queue | Hand-off | Direct producer→consumer hand-off |
| `LinkedTransferQueue` | Transfer + queue hybrid | FIFO | Advanced hand-off + buffering |

### MAPS (key → value, unique keys)

| Class | Definition | Ordering | Best For |
|---|---|---|---|
| `HashMap` | Hash table | None | Default map |
| `LinkedHashMap` | Hash table + linked list | Insertion/Access | Ordered iteration, LRU caches |
| `TreeMap` | Red-Black Tree | Sorted by key | Sorted keys, ranges |
| `Hashtable` | Legacy synchronized map | None | Legacy only — avoid |
| `ConcurrentHashMap` | Thread-safe hash map | None | Concurrent access |
| `ConcurrentSkipListMap` | Thread-safe sorted map | Sorted by key | Concurrent + sorted |
| `WeakHashMap` | Keys are weakly referenced | None | Caches that allow GC of keys |
| `IdentityHashMap` | Keys compared by `==` | None | Identity semantics (rare) |
| `EnumMap` | Array indexed by enum ordinal | Enum ordinal | Fastest map for enum keys |
| `Properties` | String→String map with I/O | None | Config files (legacy) |

### UTILITY CLASSES

| Class | Purpose |
|---|---|
| `Collections` | Static factory/wrapper methods: `sort`, `unmodifiableList`, `synchronizedMap`, `emptyList`, `singleton`, `binarySearch`, `shuffle`, `reverse`, `max`, `min`, `frequency` |
| `Arrays` | Array utilities: `asList`, `sort`, `binarySearch`, `copyOf`, `fill`, `equals`, `stream`, `toString`, `deepToString`, `parallelSort` |
| `Objects` | `requireNonNull`, `equals`, `hash`, `hashCode`, `toString`, `compare`, `isNull`, `nonNull` |
| `Comparator` | Functional interface + factory methods: `naturalOrder`, `reverseOrder`, `comparing`, `comparingInt`, `thenComparing`, `nullsFirst`, `nullsLast` |
| `Comparable` | Natural ordering contract via `compareTo` |
| `Iterable` / `Iterator` / `ListIterator` | Traversal |
| `Spliterator` | Parallel traversal |
| `Optional` | Null-safe container |
| `Collectors` | Stream aggregation |
| `Stream` / `IntStream` / `LongStream` / `DoubleStream` | Functional pipelines |

### RELATED PACKAGES

| Package | Key Classes | Purpose |
|---|---|---|
| `java.util.concurrent` | `ConcurrentHashMap`, `CopyOnWriteArrayList`, `BlockingQueue` impls, `ConcurrentSkipListMap`, `ConcurrentLinkedQueue`, `ExecutorService`, `ThreadPoolExecutor`, `Executors`, `ForkJoinPool` | Concurrency |
| `java.util.concurrent.atomic` | `AtomicInteger`, `AtomicLong`, `AtomicReference`, `LongAdder` | Lock-free counters |
| `java.util.concurrent.locks` | `ReentrantLock`, `ReadWriteLock`, `StampedLock` | Advanced locking |
| `java.util.stream` | `Stream`, `Collectors`, `IntStream` | Functional processing |
| `java.util.function` | `Function`, `Predicate`, `Supplier`, `Consumer`, `BiFunction` | Lambda support |
| `java.util` (misc) | `Optional`, `Objects`, `Arrays`, `Collections`, `Comparator` | General utilities |
| `java.util.concurrent` (queues) | Blocking queues | Producer/consumer |
| `java.util` (weak refs) | `WeakHashMap`, `WeakReference` | GC-friendly caches |
| `java.util` (enums) | `EnumSet`, `EnumMap` | Enum-optimized collections |

---

## 3. Master Decision Flowchart

```
Do you need key → value mapping?
├── YES → MAP
│   ├── Need thread safety?
│   │   ├── YES → ConcurrentHashMap (default)
│   │   │        ConcurrentSkipListMap (sorted)
│   │   │        WeakHashMap (GC keys)
│   │   └── NO → Need ordering?
│   │            ├── Sorted → TreeMap
│   │            ├── Insertion/Access → LinkedHashMap
│   │            ├── Enum keys → EnumMap
│   │            └── None → HashMap
│   └── (Legacy only → Hashtable)
│
└── NO → COLLECTION
    ├── Duplicates allowed?
    │   ├── YES → LIST
    │   │   ├── Thread-safe → CopyOnWriteArrayList
    │   │   ├── Random access dominant → ArrayList
    │   │   └── Add/remove at ends → ArrayDeque (not LinkedList)
    │   │
    │   └── NO → SET
    │       ├── Thread-safe?
    │       │   ├── YES → ConcurrentSkipListSet (sorted)
    │       │   │        CopyOnWriteArraySet (read-heavy)
    │       │   └── NO → Ordering?
    │       │            ├── Sorted → TreeSet
    │       │            ├── Insertion → LinkedHashSet
    │       │            ├── Enum values → EnumSet
    │       │            └── None → HashSet
    │       │
    │       └── Is it a queue/processing structure?
    │           ├── YES → QUEUE/DEQUE
    │           │   ├── Concurrent?
    │           │   │   ├── YES → Blocking? Bounded?
    │           │   │   │         ├── FIFO bounded → ArrayBlockingQueue
    │           │   │   │         ├── FIFO unbounded → LinkedBlockingQueue
    │           │   │   │         ├── Priority → PriorityBlockingQueue
    │           │   │   │         ├── Deque → LinkedBlockingDeque
    │           │   │   │         ├── Hand-off → SynchronousQueue
    │           │   │   │         └── Delayed → DelayQueue
    │           │   │   └── Lock-free → ConcurrentLinkedQueue / Deque
    │           │   └── Single-thread
    │           │       ├── FIFO/LIFO → ArrayDeque
    │           │       └── Priority → PriorityQueue
```

---

## 4. Rules Tables

### Rule 1 — Default choices

| Requirement | Default choice |
|---|---|
| List | `ArrayList` |
| Set | `HashSet` |
| Map | `HashMap` |
| Queue | `ArrayDeque` |
| Stack | `ArrayDeque` |
| Concurrent map | `ConcurrentHashMap` |
| Concurrent queue | `LinkedBlockingQueue` |
| Concurrent list | `CopyOnWriteArrayList` |
| Sorted set | `TreeSet` |
| Sorted map | `TreeMap` |
| Concurrent sorted map | `ConcurrentSkipListMap` |
| Enum set | `EnumSet` |
| Enum map | `EnumMap` |

### Rule 2 — Interface over implementation

```java
// ✅ Good
List<String> list = new ArrayList<>();
Map<String, Integer> map = new HashMap<>();

// ❌ Bad
ArrayList<String> list = new ArrayList<>();
HashMap<String, Integer> map = new HashMap<>();
```

### Rule 3 — Complexity cheat sheet

| Operation | ArrayList | LinkedList | HashSet | TreeSet | HashMap | TreeMap | ArrayDeque |
|---|---|---|---|---|---|---|---|
| `get(i)` | O(1) | O(n) | — | — | — | — | — |
| `add(end)` | O(1)* | O(1) | O(1)* | O(log n) | O(1)* | O(log n) | O(1)* |
| `add(index)` | O(n) | O(n) | — | — | — | — | — |
| `remove(index)` | O(n) | O(n) | — | — | — | — | — |
| `remove(obj)` | O(n) | O(n) | O(1)* | O(log n) | O(1)* | O(log n) | O(n) |
| `contains` | O(n) | O(n) | O(1)* | O(log n) | O(1)* | O(log n) | O(n) |
| `peek` | — | — | — | — | — | — | O(1) |
| `first/last` | O(1) | O(1) | — | O(log n) | — | O(log n) | O(1) |
| `subMap` | — | — | — | O(log n) | — | O(log n) | — |

`*` = amortized

### Rule 4 — Mutability wrappers

| Need | Use |
|---|---|
| Immutable | `List.of()`, `Map.of()`, `Set.of()`, `Collections.unmodifiableList()` |
| Synchronized | `Collections.synchronizedList()`, `synchronizedMap()` |
| Fixed-size | `Arrays.asList()` |
| Empty | `Collections.emptyList()`, `emptyMap()`, `emptySet()` |
| Single element | `Collections.singleton()`, `singletonList()`, `singletonMap()` |

### Rule 5 — Concurrency

| Access pattern | Choose |
|---|---|
| Read-only after publish | `Collections.unmodifiableMap()` |
| Read-heavy, rare writes | `CopyOnWriteArrayList/Set`, `ConcurrentHashMap` |
| Balanced read/write | `ConcurrentHashMap` |
| Sorted concurrent | `ConcurrentSkipListMap/Set` |
| Producer/consumer | `BlockingQueue` implementations |
| Lock-free | `ConcurrentLinkedQueue/Deque` |
| Counter | `LongAdder` > `AtomicLong` > `synchronized` |

### Rule 6 — Ordering

| Order | Use |
|---|---|
| None | `HashMap`, `HashSet` |
| Insertion | `LinkedHashMap`, `LinkedHashSet` |
| Access | `LinkedHashMap(cap, load, true)` |
| Sorted natural | `TreeMap`, `TreeSet` |
| Sorted custom | `TreeMap(Comparator)`, `TreeSet(Comparator)` |
| Enum order | `EnumMap`, `EnumSet` |

---

## 5. Problems Table & Guide

| Problem | Symptom | Cause | Fix |
|---|---|---|---|
| `ConcurrentModificationException` | Iterator fails during/after modification | Modifying while iterating | Use `iterator.remove()` or `removeIf()` |
| `NullPointerException` in `TreeMap`/`TreeSet` | Adding null key | Natural ordering can't compare null | Use `Comparator.nullsFirst()` |
| `ClassCastException` in `TreeMap` | Mixed key types | Non-comparable keys | Provide `Comparator` |
| `UnsupportedOperationException` | `add` on immutable | `List.of()` / `Arrays.asList()` | Wrap in `new ArrayList<>(...)` |
| Slow performance with `ArrayList` | Many `remove(0)` calls | O(n) shifting | Use `ArrayDeque` or `LinkedList` |
| Memory leak in cache | Map grows unbounded | Strong references | `WeakHashMap` or `Caffeine` |
| Race condition on `HashMap` | Corrupted map | Concurrent writes | `ConcurrentHashMap` |
| Poor concurrency on `Hashtable` | Threads blocked | Coarse lock | `ConcurrentHashMap` |
| Autoboxing overhead | Slow numeric maps | `Map<Integer, ...>` | Use specialized libraries (Fastutil, Eclipse Collections) |
| Wrong equality in `HashMap` keys | Duplicate logical keys | Missing `equals`/`hashCode` | Implement both correctly |
| LRU not working | Old entries not evicted | Wrong `accessOrder` | `new LinkedHashMap<>(cap, 0.75f, true)` |
| Sorting a `HashMap` | No order | HashMap unordered | Use `TreeMap` or sort entries |
| Iterator safety in concurrent map | Weakly consistent | Concurrent iteration | Acceptable; use `ConcurrentHashMap` |
| Deadlock with nested locks | Threads stuck | Lock ordering | Use `ConcurrentHashMap`, avoid nested sync |

---

## 6. Senior-Level Guide

### Design principles

1. **Program to interfaces** — declare `List`, `Map`, `Set`, `Queue`, not concrete types.
2. **Prefer immutability** — `List.of()`, `Map.of()`, `Set.of()` for constants.
3. **Choose by access pattern, not habit** — measure, don't guess.
4. **Prefer composition** — wrap or decorate rather than extend `HashMap`.
5. **Avoid legacy** — `Vector`, `Stack`, `Hashtable`, `Enumeration` are obsolete.
6. **Use `ConcurrentHashMap` over `synchronizedMap`** — better concurrency, atomic ops.
7. **Use `ArrayDeque` over `Stack` and `LinkedList`** — faster, cleaner.
8. **Use `EnumMap`/`EnumSet`** for enum keys — fastest and most memory-efficient.
9. **Use `Objects.equals`, `Objects.hash`** — null-safe, correct.
10. **Use `Comparator` factory methods** — `Comparator.comparing(...).thenComparing(...)`.

### Performance reasoning

- **ArrayList vs LinkedList** — ArrayList wins in almost every real workload due to cache locality.
- **HashMap vs TreeMap** — O(1) vs O(log n); only pay O(log n) when you need order/ranges.
- **HashSet vs TreeSet** — same trade-off as above.
- **ArrayDeque vs LinkedList** — ArrayDeque has better cache behavior and no node overhead.
- **ConcurrentHashMap vs Hashtable** — CHM allows concurrent reads and bucket-level writes.
- **LongAdder vs AtomicLong** — LongAdder scales better under contention.

### Memory reasoning

| Structure | Overhead per element |
|---|---|
| `ArrayList` | Reference (4/8 bytes) |
| `LinkedList` | Node (2 refs + header) |
| `HashMap` | Node (hash, key, value, next) |
| `LinkedHashMap` | Node + before/after refs |
| `TreeMap` | Entry (key, value, left, right, parent, color) |
| `ConcurrentHashMap` | Node + possibly tree bin |
| `EnumMap` | Array of values (very compact) |
| `EnumSet` | Bit vector (very compact) |

### Correctness rules

- Always implement `equals` and `hashCode` together.
- Use immutable keys in maps (String, Integer, enums).
- Don't mutate keys after insertion.
- Prefer `Comparator` over `Comparable` when natural order is ambiguous.
- Return empty collections, not null.
- Use `Optional` for nullable return values, not for fields.

### Concurrency rules

- Publish collections safely (`final`, `volatile`, or safe publication).
- Use `ConcurrentHashMap` atomic ops (`putIfAbsent`, `compute`, `merge`) — don't check-then-act.
- Use `BlockingQueue` for producer/consumer — don't hand-roll wait/notify.
- Use `CopyOnWriteArrayList` only for read-dominant workloads.
- Never iterate `ConcurrentHashMap` expecting a consistent snapshot.

### Serialization rules

- `ArrayList`, `HashMap`, etc. are `Serializable`; `List.of()` results are not.
- Custom comparators may not be serializable.
- Prefer explicit serialization (JSON, Protobuf) over Java serialization.

---

## 7. Utility Classes Guide

### `Collections`

```java
Collections.sort(list);
Collections.binarySearch(list, key);
Collections.reverse(list);
Collections.shuffle(list);
Collections.max(list);
Collections.min(list);
Collections.frequency(list, obj);
Collections.unmodifiableList(list);
Collections.synchronizedMap(map);
Collections.emptyList();
Collections.singletonList(x);
Collections.nCopies(n, x);
Collections.disjoint(a, b);
Collections.rotate(list, distance);
Collections.swap(list, i, j);
```

### `Arrays`

```java
Arrays.asList(1, 2, 3);
Arrays.sort(arr);
Arrays.parallelSort(arr);
Arrays.binarySearch(arr, key);
Arrays.copyOf(arr, newLen);
Arrays.copyOfRange(arr, from, to);
Arrays.fill(arr, value);
Arrays.equals(a, b);
Arrays.deepEquals(a, b);
Arrays.toString(arr);
Arrays.deepToString(arr);
Arrays.stream(arr);
Arrays.setAll(arr, i -> i * 2);
```

### `Objects`

```java
Objects.requireNonNull(obj, "msg");
Objects.equals(a, b);
Objects.hash(a, b, c);
Objects.hashCode(obj);
Objects.toString(obj, "default");
Objects.compare(a, b, comparator);
Objects.isNull(obj);
Objects.nonNull(obj);
```

### `Comparator`

```java
Comparator.naturalOrder();
Comparator.reverseOrder();
Comparator.comparing(Function);
Comparator.comparingInt(ToIntFunction);
Comparator.comparingLong(ToLongFunction);
Comparator.comparingDouble(ToDoubleFunction);
Comparator.nullsFirst(cmp);
Comparator.nullsLast(cmp);
cmp.thenComparing(other);
cmp.reversed();
```

### `Stream` / `Collectors`

```java
list.stream()
    .filter(x -> x > 0)
    .map(String::valueOf)
    .sorted()
    .distinct()
    .limit(10)
    .collect(Collectors.toList());

Collectors.toList(), toSet(), toMap(), groupingBy(), partitioningBy(),
joining(), counting(), summingInt(), averagingInt(), summarizingInt(),
reducing(), mapping(), flatMapping(), teeing()
```

### `Optional`

```java
Optional.of(x);
Optional.ofNullable(x);
Optional.empty();
opt.orElse(defaultVal);
opt.orElseGet(Supplier);
opt.orElseThrow(Supplier);
opt.map(Function);
opt.flatMap(Function);
opt.filter(Predicate);
opt.ifPresent(Consumer);
opt.isPresent();
```

---

## 8. Related Packages Guide

### `java.util.concurrent`

```java
// Maps
ConcurrentHashMap<K, V>
ConcurrentSkipListMap<K, V>

// Sets
ConcurrentSkipListSet<E>
CopyOnWriteArraySet<E>

// Lists
CopyOnWriteArrayList<E>

// Queues
ArrayBlockingQueue, LinkedBlockingQueue, PriorityBlockingQueue,
LinkedBlockingDeque, SynchronousQueue, DelayQueue, LinkedTransferQueue,
ConcurrentLinkedQueue, ConcurrentLinkedDeque

// Executors
ExecutorService, ScheduledExecutorService, Executors, ThreadPoolExecutor,
ForkJoinPool, CompletableFuture
```

### `java.util.concurrent.atomic`

```java
AtomicInteger, AtomicLong, AtomicBoolean, AtomicReference
LongAdder, LongAccumulator, DoubleAdder
AtomicIntegerArray, AtomicReferenceArray
```

### `java.util.concurrent.locks`

```java
ReentrantLock
ReentrantReadWriteLock
StampedLock
Condition
```

### `java.util.stream`

```java
Stream<T>, IntStream, LongStream, DoubleStream
Collectors, StreamSupport
```

### `java.util.function`

```java
Function, BiFunction, UnaryOperator, BinaryOperator
Predicate, BiPredicate
Supplier, Consumer, BiConsumer
```

---

## 9. Quick Reference — "Which do I use?"

| Situation | Use |
|---|---|
| General list | `ArrayList` |
| General set | `HashSet` |
| General map | `HashMap` |
| General queue | `ArrayDeque` |
| General stack | `ArrayDeque` |
| Ordered set | `LinkedHashSet` |
| Ordered map | `LinkedHashMap` |
| Sorted set | `TreeSet` |
| Sorted map | `TreeMap` |
| LRU cache | `LinkedHashMap(access=true)` or Caffeine |
| Priority processing | `PriorityQueue` |
| Concurrent map | `ConcurrentHashMap` |
| Concurrent sorted map | `ConcurrentSkipListMap` |
| Concurrent list | `CopyOnWriteArrayList` |
| Concurrent set | `CopyOnWriteArraySet` |
| Concurrent queue | `LinkedBlockingQueue` |
| Bounded queue | `ArrayBlockingQueue` |
| Concurrent priority | `PriorityBlockingQueue` |
| Concurrent deque | `LinkedBlockingDeque` |
| Hand-off | `SynchronousQueue` |
| Delayed tasks | `DelayQueue` |
| Enum keys/values | `EnumMap`, `EnumSet` |
| GC-friendly cache | `WeakHashMap` |
| Immutable | `List.of`, `Map.of`, `Set.of` |
| Fixed-size list | `Arrays.asList` |

---

## 10. Final Senior Summary

- **Default trio**: `ArrayList`, `HashMap`, `HashSet`.
- **Ordered trio**: `LinkedHashSet`, `LinkedHashMap`, `ArrayDeque`.
- **Sorted pair**: `TreeSet`, `TreeMap` — pay O(log n) for order.
- **Concurrent core**: `ConcurrentHashMap`, `CopyOnWriteArrayList`, `LinkedBlockingQueue`.
- **Enum optimized**: `EnumSet`, `EnumMap`.
- **Legacy — avoid**: `Vector`, `Stack`, `Hashtable`, `Enumeration`.
- **Utilities**: `Collections`, `Arrays`, `Objects`, `Comparator`, `Optional`.
- **Functional**: `Stream`, `Collectors`, `java.util.function`.
- **Choose by access pattern** (indexed? keyed? ordered? concurrent?) — not by habit.
- **Program to interfaces**, prefer immutability, and reason about complexity, memory, and concurrency.


[[Java]]