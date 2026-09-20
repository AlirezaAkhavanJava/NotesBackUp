
## 1. Prerequisites

Before `Map` makes sense, you need:

| Prerequisite | Why it matters |
|---|---|
| **`Collection` interface** | `Map` is **not** a `Collection`. This is a critical distinction. `Map` is a separate hierarchy. |
| **`Set`** | `Map.keySet()` returns a `Set`. `HashSet` is backed by a `HashMap`. Understanding `Set` makes `Map` click. |
| **`equals()` / `hashCode()` contracts** | `HashMap` is *defined* by them. Keys must obey the contract. |
| **`Comparable` / `Comparator`** | Required for `TreeMap` and `TreeSet`. |
| **Generics** | `Map<K, V>` — two type parameters. You need to be comfortable with this. |
| **Big-O notation** | To choose between `HashMap`, `TreeMap`, and `LinkedHashMap`, you need complexity analysis. |
| **`Iterator` / `Iterable`** | Maps don't implement `Iterable`. You iterate their views (`keySet`, `values`, `entrySet`). |

### Dependency chain

```
Object
  ↑
equals() / hashCode() contract
  ↑
Map<K, V>
  ↑
├── HashMap
│     ↑
│     └── LinkedHashMap
├── TreeMap
├── Hashtable (legacy)
├── EnumMap
├── WeakHashMap
├── IdentityHashMap
├── ConcurrentHashMap
└── ConcurrentSkipListMap
```

**Critical distinction:** `Map` does **not** extend `Collection`. It's a separate root interface. The hierarchy is:

```
Iterable
  ↑
Collection
  ↑
├── List
├── Set
└── Queue
        (Map is NOT here)

Map  ← separate hierarchy
```

If you remember nothing else: `Map` is not a `Collection`. It's a collection-like structure, but it doesn't fit the `Collection` contract because it deals with key-value pairs, not individual elements.

---

## 2. The Problem

### What problem existed before `Map`?

Suppose you're writing a program that counts word frequencies in a document. You start with two parallel arrays:

```java
String[] words = ...;
int[] counts = new int[words.length];
```

To increment the count for a word, you'd have to:

1. Scan the `words` array to find the word.
2. If found, increment `counts[i]`.
3. If not found, add it to both arrays.

That's O(n) per lookup, O(n²) for n words. Unusable for a large document.

Or you could keep them sorted and binary search. That's O(log n) per lookup, but insertion requires shifting elements — O(n).

### Why was the problem difficult?

Because "associate a value with a key" is a fundamental operation that doesn't fit the `List`/`Set`/`Queue` model:

- A `List` is indexed by **position** (0, 1, 2, ...). You can't index by an arbitrary object.
- A `Set` stores elements but doesn't associate anything with them. `Set.contains(x)` answers "is x present?" but not "what's the value for x?"
- A `Queue` is about ordering, not association.

You need a structure where an **arbitrary key** maps to a **value**, with fast lookup, insertion, and deletion.

### Concrete example of the pain

```java
// Without Map: word frequency counting
String[] words = document.split("\\s+");
List<String> uniqueWords = new ArrayList<>();
List<Integer> counts = new ArrayList<>();

for (String word : words) {
    int index = uniqueWords.indexOf(word);  // O(n) scan
    if (index >= 0) {
        counts.set(index, counts.get(index) + 1);
    } else {
        uniqueWords.add(word);
        counts.add(1);
    }
}
// Total: O(n²) — for 1M words, ~500 billion operations. Unusable.
```

With a `HashMap`:

```java
Map<String, Integer> freq = new HashMap<>();
for (String word : words) {
    freq.merge(word, 1, Integer::sum);  // O(1) amortized
}
// Total: O(n)
```

That's the problem `Map` solves: **key-value association with sub-linear lookup**.

### The deeper problem: the associative array

In mathematics and computer science, this is the **associative array** or **dictionary** — a fundamental abstract data type. Every language has it:

| Language | Name |
|---|---|
| Java | `Map` |
| Python | `dict` |
| JavaScript | `Object` / `Map` |
| C++ | `std::map` / `std::unordered_map` |
| Ruby | `Hash` |
| Go | `map` |
| Rust | `HashMap` / `BTreeMap` |

Java's `Map` is the language's implementation of this universal concept.

---

## 3. The Core Idea

### Simple definition

A `Map` is an object that maps **keys** to **values**. A map cannot contain duplicate keys; each key can map to at most one value. It models the mathematical function: for each key, there's exactly one value.

### Intuitive explanation

Think of a **dictionary** (the book). You look up a word (the key) and find its definition (the value). You can't have two definitions for the same word in the same dictionary. You can add new words, remove words, or change a definition.

Or think of a **coat check** at a theater. You hand over your coat (value) and get a ticket (key). Later, you present the ticket and get your coat back. The ticket uniquely identifies your coat. Two people can't have the same ticket number.

### Precise technical definition

> A `Map` is an object that maps keys to values. A map cannot contain duplicate keys; each key can map to at most one value. The `Map` interface provides three collection views: a set of keys, a collection of values, and a set of key-value mappings.

From the Javadoc:

> "An object that maps keys to values. A map cannot contain duplicate keys; each key can map to at most one value. This interface takes the place of the Dictionary class, which was a totally abstract class rather than an interface."

### Key vocabulary

| Term | Meaning |
|---|---|
| **Key** | The object used to look up a value. Must be unique within the map. |
| **Value** | The object associated with a key. Can be duplicated across keys. |
| **Entry** | A key-value pair. Represented by `Map.Entry<K, V>`. |
| **Mapping** | The association from a key to a value. |
| **Collision** | When two different keys hash to the same bucket. |
| **Load factor** | The ratio of entries to buckets before resizing. Default 0.75. |
| **Capacity** | The number of buckets in the hash table. |
| **Rehashing** | Rebuilding the hash table when it grows. |
| **View** | A collection backed by the map (`keySet`, `values`, `entrySet`). |
| **Fail-fast** | Iterators throw `ConcurrentModificationException` if the map is structurally modified during iteration. |

### The three views

This is essential to understanding `Map`:

| View | Type | Contains | Supports removal? |
|---|---|---|---|
| `keySet()` | `Set<K>` | All keys | Yes — removes the entry |
| `values()` | `Collection<V>` | All values | Yes — removes the entry |
| `entrySet()` | `Set<Map.Entry<K, V>>` | All key-value pairs | Yes — removes the entry |

**These are views, not copies.** If you remove from `keySet()`, the entry is removed from the map. If the map changes, the views reflect it.

**You cannot add through a view.** `keySet().add(k)` throws `UnsupportedOperationException`. To add, you must use `put`.

---

## 4. How It Works

### The general mechanism

Every `Map` answers four questions:

1. **How do I find the value for a key?** (lookup strategy)
2. **How do I decide if two keys are the same?** (equality strategy)
3. **What order do I iterate in?** (iteration strategy)
4. **What happens when the map grows?** (resizing strategy)

Let's walk through `HashMap`, the most common.

### HashMap: step-by-step

`HashMap` is a hash table. Internally, it's an array of buckets. Each bucket is a linked list (or a red-black tree if the bucket grows large).

```
HashMap internals (simplified):

  Node[] table          // array of buckets
    │
    ├── table[0] ──► Node(key1, val1) ──► Node(key2, val2) ──► null
    ├── table[1] ──► null
    ├── table[2] ──► Node(key3, val3) ──► null
    └── ...

  Node {
      final int hash;
      final K key;
      V value;
      Node<K,V> next;
  }
```

**Putting an entry `(k, v)`:**

1. Compute `k.hashCode()`.
2. Spread the hash: `h = hash ^ (hash >>> 16)` — XOR high bits into low bits to reduce collisions.
3. Compute bucket index: `(table.length - 1) & h`.
4. Walk the bucket's linked list:
   - For each node, check `node.hash == h && (node.key == k || k.equals(node.key))`.
   - If a match is found, replace the value and return the old value.
5. If no match, append a new node at the end of the list.
6. If the bucket's list is too long (≥ 8 by default), convert it to a red-black tree for O(log n) worst-case lookup.
7. Increment size. If size > `capacity * loadFactor`, resize (double the table, rehash all entries).

**Getting the value for `k`:**

1. Compute hash, spread, find bucket.
2. Walk the bucket, comparing `hash` and `equals`.
3. Return the value if found, `null` otherwise.

**Removing `k`:**

1. Find the node (same as get).
2. Unlink it from the bucket.
3. Decrement size.
4. Return the removed value.

**Flow diagram:**

```
put(k, v)
  │
  ├─► if k == null: handle null key specially (bucket 0)
  │
  ├─► h = spread(k.hashCode())
  │
  ├─► index = (table.length - 1) & h
  │
  ├─► walk bucket[index]
  │     │
  │     ├─► found matching key? ──► replace value, return old
  │     │
  │     └─► not found
  │           │
  │           ├─► append new node
  │           ├─► size++
  │           └─► if size > threshold: resize()
  │
  └─► return null (no previous mapping)
```

### LinkedHashMap

Same as `HashMap`, but each node also has `before` and `after` pointers forming a doubly-linked list across all entries. This preserves **insertion order** (or **access order**, if constructed with `accessOrder = true`).

**Two modes:**

- **Insertion order** (default): entries iterate in the order they were inserted.
- **Access order**: entries iterate in the order they were last accessed. Used for LRU caches.

**LRU cache with `LinkedHashMap`:**

```java
Map<K, V> lru = new LinkedHashMap<>(capacity, 0.75f, true) {
    @Override
    protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > capacity;
    }
};
```

This is the classic one-liner LRU cache. The `accessOrder = true` flag moves entries to the end on access; `removeEldestEntry` evicts the least-recently-used.

### TreeMap

Backed by a red-black tree. Keys are stored in **sorted order** according to `Comparable` (natural ordering) or a `Comparator` supplied at construction.

- `put`, `get`, `remove`: O(log n).
- Iteration: in ascending key order.
- **Equality is determined by `compareTo()` returning 0**, not by `equals()`.
- Provides range operations: `headMap`, `tailMap`, `subMap`, `firstKey`, `lastKey`, `floorKey`, `ceilingKey`, `higherKey`, `lowerKey`.

### EnumMap

A specialized `Map` for enum keys. Internally an array indexed by the enum's ordinal. Extremely fast and compact. Iteration is in enum declaration order. Cannot have `null` keys.

### ConcurrentHashMap

A thread-safe `HashMap`. In Java 8+, it uses CAS (compare-and-swap) operations and synchronized bins for updates, allowing high concurrency. Does **not** allow `null` keys or values. Iterators are weakly consistent (not fail-fast).

### Comparison table

| Implementation | Order | get/put | Null key | Null value | Thread-safe | Underlying structure |
|---|---|---|---|---|---|---|
| `HashMap` | None | O(1) avg | Yes (one) | Yes | No | Hash table |
| `LinkedHashMap` | Insertion/access | O(1) avg | Yes (one) | Yes | No | Hash table + linked list |
| `TreeMap` | Sorted | O(log n) | No | Yes | No | Red-black tree |
| `EnumMap` | Enum order | O(1) | No | Yes | No | Array |
| `Hashtable` | None | O(1) avg | No | No | Yes (legacy) | Hash table |
| `ConcurrentHashMap` | None | O(1) avg | No | No | Yes | Hash table + CAS |
| `ConcurrentSkipListMap` | Sorted | O(log n) | No | No | Yes | Skip list |
| `WeakHashMap` | None | O(1) avg | Yes | Yes | No | Hash table + weak refs |
| `IdentityHashMap` | None | O(1) avg | Yes | Yes | No | Hash table + `==` |

### Runtime behavior worth knowing

- **`HashMap` capacity is always a power of 2.** This lets it use `& (capacity - 1)` instead of `% capacity`.
- **`HashMap` resizes when size > capacity × load factor.** Default load factor 0.75. Resizing doubles capacity and rehashes all entries.
- **Java 8+ treeifies buckets** with ≥ 8 entries (and untreeifies at ≤ 6). This gives O(log n) worst-case lookup even with adversarial hash codes.
- **`HashMap` iteration order is unspecified** and can change between runs.
- **`LinkedHashMap` access order** is not thread-safe. Concurrent access can corrupt the linked list.
- **`TreeMap` is not thread-safe.** Use `ConcurrentSkipListMap` for concurrent sorted maps.
- **`ConcurrentHashMap` does not allow `null`.** This is deliberate — `null` would be ambiguous in a concurrent context.
- **`ConcurrentHashMap.size()` is an estimate** under concurrent modification. Use `mappingCount()` for a long estimate.

---

## 5. Relationships

### To its prerequisites

- **`equals()`/`hashCode()`**: `HashMap` is *defined* by them. Broken contract → lost entries.
- **`Comparable`/`Comparator`**: `TreeMap` is *defined* by them.
- **`Set`**: `keySet()` and `entrySet()` return `Set` views. `HashSet` is backed by `HashMap`. `TreeSet` is backed by `TreeMap`.

### Concepts that depend on `Map`

- **`Set`**: `HashSet` wraps `HashMap`; `TreeSet` wraps `TreeMap`; `LinkedHashSet` wraps `LinkedHashMap`.
- **Caching**: LRU caches use `LinkedHashMap`; concurrent caches use `ConcurrentHashMap`.
- **Memoization**: dynamic programming uses `Map` to store computed results.
- **Graph adjacency lists**: `Map<Node, List<Node>>`.
- **JSON/object models**: `Map<String, Object>` is the universal representation.
- **Dependency injection**: `Map<Class<?>, Object>` for service locators.
- **Database indexing**: B-tree indexes are conceptually `TreeMap`s.
- **Symbol tables**: compilers use `Map<String, Symbol>`.

### Similar concepts

- **`List`**: indexed by position. Use when order and duplicates matter, and keys are integers 0..n-1.
- **`Set`**: no values, only keys. Use when you only need membership.
- **`Queue`**: ordering, no association. Use for processing pipelines.
- **`Dictionary`**: legacy abstract class, replaced by `Map`.
- **`Properties`**: extends `Hashtable<Object, Object>`, used for config files.

### Commonly confused with

- **`Map` vs. `Set`**: A `Set` is like a `Map` with no values. `Set.add(x)` ≈ `Map.put(x, PRESENT)`.
- **`Map` vs. `List`**: A `List` is a `Map<Integer, T>` where keys are 0..n-1 and order matters.
- **`HashMap` vs. `Hashtable`**: `Hashtable` is legacy (Java 1.0), synchronized on every method, and rejects `null`. Use `HashMap` or `ConcurrentHashMap` instead.
- **`TreeMap` vs. `HashMap`**: `TreeMap` is sorted but slower (O(log n) vs. O(1)). Use `TreeMap` only when you need sorted iteration or range queries.
- **`ConcurrentHashMap` vs. `Collections.synchronizedMap`**: `ConcurrentHashMap` allows concurrent reads and writes; `synchronizedMap` locks the whole map on every operation.

### Higher-level concepts built on top of `Map`

- **Caches** (LRU, TTL, weak-reference).
- **Memoization** in dynamic programming.
- **Graph algorithms**: adjacency lists, visited maps, distance maps.
- **Counters and histograms**: `Map<K, Integer>`.
- **Inverted indexes**: search engines use `Map<term, List<documentId>>`.
- **Configuration management**: `Map<String, String>`.
- **State machines**: `Map<State, Map<Event, State>>`.

---

## 6. Examples

### Level 1: Beginner — basic put/get

```java
Map<String, Integer> ages = new HashMap<>();
ages.put("Alice", 30);
ages.put("Bob", 25);
ages.put("Alice", 31);  // overwrites

System.out.println(ages.get("Alice"));   // 31
System.out.println(ages.get("Charlie")); // null
System.out.println(ages.size());         // 2
System.out.println(ages.containsKey("Bob"));    // true
System.out.println(ages.containsValue(25));     // true
```

**What to notice:** `put` on an existing key overwrites and returns the old value. `get` on a missing key returns `null` (not an exception). `containsKey` and `containsValue` are separate operations.

### Level 2: Real-world — word frequency

```java
String text = "the quick brown fox jumps over the lazy dog the fox";
String[] words = text.split("\\s+");

Map<String, Integer> freq = new HashMap<>();
for (String word : words) {
    freq.merge(word, 1, Integer::sum);
}

System.out.println(freq.get("the"));   // 3
System.out.println(freq.get("fox"));   // 2
System.out.println(freq.get("dog"));   // 1

// Iterate entries
for (Map.Entry<String, Integer> e : freq.entrySet()) {
    System.out.println(e.getKey() + " -> " + e.getValue());
}
```

**What to notice:** `merge` is the idiomatic way to count. It's cleaner than `get`/`put` and handles the first occurrence. Always iterate `entrySet()` when you need both key and value — it's one lookup, not two.

### Level 3: Practical programming — grouping

```java
record Person(String name, String city) {}

List<Person> people = List.of(
    new Person("Alice", "NYC"),
    new Person("Bob", "LA"),
    new Person("Charlie", "NYC"),
    new Person("Diana", "LA"),
    new Person("Eve", "NYC")
);

Map<String, List<Person>> byCity = new HashMap<>();
for (Person p : people) {
    byCity.computeIfAbsent(p.city(), k -> new ArrayList<>()).add(p);
}

System.out.println(byCity.get("NYC").size());  // 3
System.out.println(byCity.get("LA").size());   // 2
```

**What to notice:** `computeIfAbsent` is the idiomatic way to build multimaps (maps of lists). It creates the list only if absent. The equivalent stream version is `Collectors.groupingBy`.

**Stream version:**

```java
Map<String, List<Person>> byCity = people.stream()
    .collect(Collectors.groupingBy(Person::city));
```

### Level 4: Professional/production — LRU cache

```java
public class LRUCache<K, V> extends LinkedHashMap<K, V> {
    private final int capacity;

    public LRUCache(int capacity) {
        super(capacity, 0.75f, true);  // access order = true
        this.capacity = capacity;
    }

    @Override
    protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > capacity;
    }
}

// Usage
LRUCache<String, String> cache = new LRUCache<>(3);
cache.put("a", "1");
cache.put("b", "2");
cache.put("c", "3");
cache.get("a");           // "a" is now most-recently used
cache.put("d", "4");      // evicts "b" (least recently used)
System.out.println(cache.keySet());  // [c, a, d] or [a, c, d] depending on order
```

**What to notice:** `LinkedHashMap` with `accessOrder = true` moves an entry to the end of the linked list on every `get` or `put`. Overriding `removeEldestEntry` gives you an LRU cache in ~10 lines. This is a classic interview question and a real production pattern.

### Level 5: Edge case — mutable keys

```java
class Key {
    int id;
    Key(int id) { this.id = id; }
    @Override public boolean equals(Object o) {
        return o instanceof Key && ((Key) o).id == id;
    }
    @Override public int hashCode() { return id; }
    @Override public String toString() { return "Key(" + id + ")"; }
}

Map<Key, String> map = new HashMap<>();
Key k = new Key(1);
map.put(k, "value");
System.out.println(map.get(k));        // "value"
System.out.println(map.get(new Key(1))); // "value"

k.id = 2;  // mutate the key after insertion
System.out.println(map.get(k));        // null!
System.out.println(map.get(new Key(1))); // null!
System.out.println(map.get(new Key(2))); // null!

// The entry is still in the map, but unreachable:
System.out.println(map.size());        // 1
System.out.println(map);               // {Key(2)=value} — but get(Key(2)) returns null
```

**What to notice:** mutating a key after insertion changes its `hashCode()`, so the map can no longer find it. The entry is effectively **lost** — it's still in the map, but no lookup can reach it. This is the `HashMap` equivalent of mutating a `HashSet` element. **Keys must be immutable** (or at least immutable in the fields used by `equals()`/`hashCode()`).

**Another edge case: `null` keys and values in `HashMap`.**

```java
Map<String, String> map = new HashMap<>();
map.put(null, "null key");       // allowed
map.put("key", null);            // allowed
System.out.println(map.get(null));    // "null key"
System.out.println(map.get("key"));   // null — ambiguous!
System.out.println(map.containsKey("key"));  // true
System.out.println(map.containsValue(null)); // true
```

**What to notice:** `get` returns `null` both when the key is absent and when the value is `null`. Use `containsKey` to distinguish. This ambiguity is why `ConcurrentHashMap` forbids `null`.

**Another edge case: `computeIfAbsent` with a function that modifies the map.**

```java
Map<String, List<String>> map = new HashMap<>();
map.computeIfAbsent("a", k -> {
    map.put("b", List.of("x"));  // modifying the map inside the lambda
    return new ArrayList<>();
});
// ConcurrentModificationException or undefined behavior
```

**What to notice:** modifying the map inside a `computeIfAbsent` lambda is undefined behavior. Don't do it.

---

## 7. How to Use It

### Common usage patterns

```java
// Basic put/get
map.put(k, v);
V val = map.get(k);

// Get with default
V val = map.getOrDefault(k, defaultValue);

// Insert only if absent
map.putIfAbsent(k, v);

// Compute if absent (multimap building)
map.computeIfAbsent(k, key -> new ArrayList<>()).add(item);

// Compute (replace or create)
map.compute(k, (key, oldVal) -> oldVal == null ? 1 : oldVal + 1);

// Merge (counter pattern)
map.merge(k, 1, Integer::sum);

// Replace
map.replace(k, newV);
map.replace(k, oldV, newV);  // only if current value equals oldV

// Remove
map.remove(k);
map.remove(k, v);  // only if current value equals v

// Iterate
for (Map.Entry<K, V> e : map.entrySet()) { ... }
map.forEach((k, v) -> { ... });

// Views
Set<K> keys = map.keySet();
Collection<V> values = map.values();
Set<Map.Entry<K, V>> entries = map.entrySet();

// Streams
map.entrySet().stream()
    .filter(e -> e.getValue() > 10)
    .map(Map.Entry::getKey)
    .collect(Collectors.toList());
```

### Best practices

- **Program to the interface**: `Map<K, V> m = new HashMap<>();`.
- **Use `entrySet()` for iteration** when you need both key and value. `keySet()` + `get` is two lookups.
- **Use `merge`, `compute`, `computeIfAbsent`, `putIfAbsent`** instead of `get`/`put` sequences. They're atomic and cleaner.
- **Make keys immutable.** Or at least immutable in the fields used by `equals()`/`hashCode()`.
- **Pre-size `HashMap`** if you know the expected size: `new HashMap<>(expectedSize / 0.75f + 1)`.
- **Use `LinkedHashMap` for LRU caches** (with `accessOrder = true`).
- **Use `EnumMap` for enum keys** — it's dramatically faster and smaller.
- **Use `TreeMap` only when you need sorted iteration or range queries.**
- **Use `ConcurrentHashMap` for concurrent access**, not `Collections.synchronizedMap`.
- **Don't use `Hashtable`** — it's legacy. Use `HashMap` or `ConcurrentHashMap`.
- **Override `equals()` and `hashCode()`** for custom keys. Use `Objects.hash()` and `Objects.equals()`.

### When to choose `Map`

- You need key-value association.
- You need fast lookup by key.
- You need to count, group, or index.
- You need caching or memoization.
- You need a symbol table or registry.

### When to avoid `Map`

- You only need membership testing → `Set`.
- You need indexed access → `List`.
- You need ordering by insertion and no keys → `Queue` or `List`.
- You have a fixed, small set of keys → consider fields or an enum.

### Alternatives and when they're preferable

| Alternative | When to prefer |
|---|---|
| `Set` | Only membership, no values. |
| `List` | Indexed access, order, duplicates. |
| `Queue` | Processing order, no association. |
| `EnumMap` | Keys are enum constants. |
| `ConcurrentHashMap` | Concurrent access. |
| `TreeMap` | Sorted keys, range queries. |
| `LinkedHashMap` | Insertion/access order, LRU. |
| `WeakHashMap` | Keys should be garbage-collected when unreferenced. |
| `IdentityHashMap` | Keys compared by `==`, not `equals()`. |

---

## 8. Common Mistakes

### Beginner mistakes

**Mistake 1: Using `get()` and checking for `null` instead of `containsKey()`.**

```java
if (map.get(key) != null) { ... }  // WRONG if null values are allowed
```

*Why it's wrong:* if the map allows `null` values, `get` returns `null` both for absent keys and for keys mapped to `null`. Use `containsKey`.

**Mistake 2: Iterating `keySet()` and calling `get()`.**

```java
for (K key : map.keySet()) {
    V value = map.get(key);  // second lookup — O(1) but wasteful
}
```

*Why it's suboptimal:* `entrySet()` gives you both in one lookup. Use it.

**Mistake 3: Forgetting to override `hashCode()` when overriding `equals()`.**

Covered in the `Set` lesson. Same bug, same fix.

**Mistake 4: Using a mutable object as a key.**

Covered in Level 5. The entry becomes unreachable.

### Misconceptions

**Misconception: "`HashMap` preserves insertion order."**

False. `HashMap` order is unspecified. Use `LinkedHashMap` for insertion order.

**Misconception: "`TreeMap` uses `equals()` to compare keys."**

False. `TreeMap` uses `compareTo()` (or `Comparator.compare()`). If `compareTo` returns 0 for two keys that are not `equals()`, they're treated as the same key.

**Misconception: "`ConcurrentHashMap` allows `null`."**

False. `ConcurrentHashMap` rejects `null` keys and values with `NullPointerException`. This is deliberate — `null` would be ambiguous in a concurrent context.

**Misconception: "`Hashtable` is the thread-safe version of `HashMap`."**

Technically true but misleading. `Hashtable` locks the entire map on every operation. `ConcurrentHashMap` is far more scalable. Use `ConcurrentHashMap`.

**Misconception: "`map.keySet()` returns a copy."**

False. It returns a **view**. Changes to the map are reflected in the view, and removal through the view removes from the map.

### Incorrect implementations

**Incorrect: using `==` instead of `equals()` in a custom key's `equals()`.**

```java
@Override
public boolean equals(Object o) {
    return this.id == ((Key) o).id;  // WRONG for String id
}
```

*Why it's wrong:* `==` compares references. Use `.equals()`.

**Incorrect: using a `List` as a key and mutating it.**

Same as mutable keys above. The entry becomes unreachable.

### Subtle mistakes experienced developers make

**Mistake: `computeIfAbsent` returning `null`.**

```java
map.computeIfAbsent(k, key -> null);  // does NOT insert a mapping
```

*Why it matters:* if the function returns `null`, no mapping is recorded. This is sometimes desired, sometimes a bug.

**Mistake: `merge` with a `null` value.**

```java
map.merge(k, null, Integer::sum);  // NPE
```

*Why it's wrong:* `merge` throws NPE if the value is `null`. Use `put` if you need `null` values.

**Mistake: relying on `HashMap` iteration order in tests.**

```java
assertEquals("{a=1, b=2}", map.toString());  // flaky!
```

*Why it's wrong:* iteration order is unspecified. Use `LinkedHashMap` or compare entries as a set.

**Mistake: using `HashMap` in a multi-threaded context.**

```java
Map<K, V> shared = new HashMap<>();
// multiple threads put/get — corrupted map, infinite loops in Java 7, lost updates
```

*Why it's wrong:* `HashMap` is not thread-safe. Use `ConcurrentHashMap`. In Java 7, concurrent `put` could cause an infinite loop in `resize`. In Java 8+, you get lost updates and corrupted state.

**Mistake: using `ConcurrentHashMap` and assuming compound operations are atomic.**

```java
if (!map.containsKey(k)) {
    map.put(k, v);  // NOT atomic — race condition
}
```

*Why it's wrong:* `containsKey` and `put` are individually atomic, but the combination is not. Use `putIfAbsent` or `computeIfAbsent`.

**Mistake: `Collections.synchronizedMap` and iterating without synchronizing.**

```java
Map<K, V> sync = Collections.synchronizedMap(new HashMap<>());
for (K key : sync.keySet()) { ... }  // NOT thread-safe — must synchronize on the map
```

*Why it's wrong:* `synchronizedMap` makes individual operations atomic, but iteration requires manual synchronization on the map. Use `ConcurrentHashMap` instead.

---

## 9. Trade-offs

| Dimension | `HashMap` | `LinkedHashMap` | `TreeMap` | `EnumMap` | `ConcurrentHashMap` |
|---|---|---|---|---|---|
| **get/put** | O(1) avg | O(1) avg | O(log n) | O(1) | O(1) avg |
| **Memory** | Moderate | Higher (links) | Higher (tree) | Very low | Moderate |
| **Order** | None | Insertion/access | Sorted | Enum order | None |
| **Null key** | Yes (one) | Yes (one) | No | No | No |
| **Null value** | Yes | Yes | Yes | Yes | No |
| **Thread-safe** | No | No | No | No | Yes |
| **Range queries** | No | No | Yes | No | No |
| **Complexity** | Low | Low | Moderate | Low | Moderate |
| **Best for** | General purpose | LRU, order | Sorted keys | Enum keys | Concurrency |

### Advantages of `Map`

- Fast key-value lookup.
- Rich API for atomic updates (`merge`, `compute`, `putIfAbsent`).
- Multiple implementations for different needs.
- Views allow flexible iteration.

### Disadvantages

- No duplicate keys.
- Keys must be immutable (or stable).
- `HashMap` is not thread-safe.
- Iteration order is unspecified for `HashMap`.
- Memory overhead compared to arrays.

---

## 10. Edge Cases and Limitations

1. **Mutable keys** — covered above. The entry becomes unreachable.

2. **`null` keys and values** — `HashMap` allows one `null` key and any number of `null` values. `ConcurrentHashMap`, `TreeMap`, and `Hashtable` reject `null`.

3. **`get` returning `null`** — ambiguous between "absent" and "mapped to null." Use `containsKey`.

4. **`TreeMap` with inconsistent `compareTo`/`equals`** — can treat distinct keys as the same, or vice versa.

5. **`HashMap` resize** — O(n) but amortized O(1). Pre-size if you know the expected size.

6. **`HashMap` treeification** — buckets with ≥ 8 entries become red-black trees. This protects against hash collisions but adds overhead.

7. **`ConcurrentHashMap` size is an estimate** — use `mappingCount()` for a long estimate.

8. **`ConcurrentHashMap` iterators are weakly consistent** — they don't throw `ConcurrentModificationException`, but they may or may not reflect concurrent modifications.

9. **`LinkedHashMap` access order is not thread-safe** — concurrent `get` can corrupt the linked list.

10. **`WeakHashMap` entries can disappear** — if a key is only referenced by the map, it can be garbage-collected. Use for caches, not for persistent data.

11. **`IdentityHashMap` uses `==`** — not `equals()`. Useful for topology-preserving object graph traversal, not for normal maps.

12. **`EnumMap` requires an enum class** — `new EnumMap<>(MyEnum.class)`. Cannot be used with non-enum keys.

---

## 11. Professional Perspective

What experienced engineers know that tutorials don't:

**1. `Map` is the most-used collection in real code.** Lists and sets are common, but maps are everywhere: caches, indexes, counters, registries, configs, graphs. Master `Map` and you master most of the Collections Framework.

**2. `HashMap` is the default; `LinkedHashMap` is underused.** When you need deterministic iteration (tests, logging, reproducibility), `LinkedHashMap` costs almost nothing extra. Use it.

**3. `merge` and `computeIfAbsent` are the modern API.** Stop writing `if (map.containsKey(k)) { map.put(k, map.get(k) + 1); }`. Write `map.merge(k, 1, Integer::sum)`. It's cleaner, atomic, and less error-prone.

**4. `ConcurrentHashMap` is not just "thread-safe HashMap."** It has different semantics: no `null`, weakly consistent iterators, atomic compound operations (`putIfAbsent`, `computeIfAbsent`, `merge`). Use these to avoid race conditions.

**5. `HashMap` iteration order is a production hazard.** Tests that depend on it are flaky. Logs that depend on it are non-reproducible. Use `LinkedHashMap` or `TreeMap` when order matters.

**6. Pre-sizing matters at scale.** Building a `HashMap` of 10M entries without pre-sizing causes ~24 resizes. Pre-size it.

**7. Keys must be immutable.** This is the #1 `HashMap` bug in production. Make your keys `record`s or use `String`/`Integer`. Never use a mutable object as a key unless you're certain it won't change.

**8. `TreeMap` is for range queries, not just sorting.** If you only need sorted iteration, sort a `List` at the end. `TreeMap` earns its keep when you need `subMap`, `headMap`, `tailMap`, `floorKey`, `ceilingKey`, `higherKey`, `lowerKey`.

**9. `EnumMap` is a hidden gem.** If your keys are enum constants, `EnumMap` is typically 5–10x faster and uses a fraction of the memory. Use it.

**10. `Map` views are powerful but dangerous.** `keySet()`, `values()`, and `entrySet()` are views, not copies. Removing through a view removes from the map. Adding through a view throws. Understand the semantics.

**11. `Map.of` and `Map.ofEntries` create immutable maps.** Use them for constants and small fixed maps. They reject `null` and duplicate keys at construction.

**12. `Map.Entry` is a first-class object.** Use `Map.Entry.comparingByKey()` and `comparingByValue()` for sorting. Use `entry.setValue()` to modify a value during iteration (supported by `HashMap`, not by `Map.of`).

**13. `computeIfAbsent` is not always faster.** For `ConcurrentHashMap`, it holds a bin lock during the computation. If the computation is expensive, use `get` first, then `putIfAbsent`.

**14. `HashMap` memory footprint is significant.** Each entry is a `Node` object (~32 bytes) plus the key and value. For 1M entries, that's ~32MB just for the nodes. Consider `fastutil` or `Eclipse Collections` for primitive maps.

---

## 12. Mental Model

**Mental model: The Coat Check with a Rulebook.**

Imagine a coat check. You hand over your coat (value) and get a ticket (key). The clerk files your coat based on the ticket number.

- **The ticket (key)** must be unique. Two people can't have the same ticket.
- **The coat (value)** can be anything. Multiple people can have identical coats.
- **The clerk's rulebook (`equals()`/`hashCode()`)** determines how tickets are filed and matched.
- **The filing system (`HashMap` vs. `TreeMap` vs. `LinkedHashMap`)** determines how fast the clerk finds your coat and in what order they're stored.
- **If you change your ticket number after handing over your coat (mutable key)**, the clerk can't find your coat anymore. It's still there, but unreachable.

**Re-explained with the model:**

A `Map` is a coat check with a rulebook. Keys are tickets, values are coats. The rulebook (`equals()`/`hashCode()` or `compareTo()`) determines how tickets are matched. The filing system (hash table, tree, linked list) determines performance and iteration order. Keys must be immutable, or the clerk loses track of the coats.

---

## 13. Knowledge Check

Answer these in your own words. I'll evaluate them and correct misunderstandings. Don't look up answers first.

**Basic:**

1. Does `Map` extend `Collection`? Why or why not?
2. Name three implementations of `Map` and one key difference between them.
3. What are the three views of a `Map`? What does each contain?

**Why:**

4. Why does `HashMap` require `hashCode()` to be consistent with `equals()`?
5. Why does `ConcurrentHashMap` reject `null` keys and values?
6. Why is `LinkedHashMap` with `accessOrder = true` useful for LRU caches?

**Prediction:**

7. What does this print?
   ```java
   Map<String, Integer> m = new HashMap<>();
   m.put("a", 1);
   m.put("b", 2);
   m.put("a", 3);
   System.out.println(m.size());
   System.out.println(m.get("a"));
   System.out.println(m.get("c"));
   ```
8. What happens here?
   ```java
   Map<Key, String> m = new HashMap<>();
   Key k = new Key(1);
   m.put(k, "value");
   k.id = 2;
   System.out.println(m.get(k));
   System.out.println(m.get(new Key(1)));
   System.out.println(m.get(new Key(2)));
   ```
9. What does this do?
   ```java
   Map<String, List<String>> m = new HashMap<>();
   m.computeIfAbsent("a", k -> new ArrayList<>()).add("x");
   m.computeIfAbsent("a", k -> new ArrayList<>()).add("y");
   System.out.println(m.get("a"));
   ```

**Debugging:**

10. A `HashMap<String, Integer>` has two entries with the same key. How is this possible? (Hint: it's not.)
11. A `ConcurrentHashMap` is used with `containsKey` followed by `put`. Under load, entries are lost. Why?
12. A `TreeMap<Foo, Bar>` throws `ClassCastException` on `put`. Why?

**Scenario:**

13. You need to count the occurrences of each word in a 10GB file. Which `Map` implementation do you use? How do you handle memory?
14. You need a cache that evicts the least-recently-used entry when full. Which `Map` implementation do you use? How?
15. You need a thread-safe map that supports sorted iteration. What are your options?

---

## 14. Practice

### Level 1: Basic understanding

Write a method that takes a `List<String>` and returns a `Map<String, Integer>` counting the occurrences of each string.

### Level 2: Implementation

Implement a `Map<K, V>` using only arrays (no `HashMap`, no `TreeMap`). Support `put`, `get`, `remove`, and `size`. What's the time complexity? What are the limitations?

### Level 3: Debugging

The following code is supposed to count words, but it prints `1` for every word. Find and fix the bug:

```java
Map<String, Integer> freq = new HashMap<>();
for (String word : words) {
    if (freq.containsKey(word)) {
        freq.put(word, freq.get(word) + 1);
    } else {
        freq.put(word, 1);
    }
}
System.out.println(freq);
```

Actually, the code looks correct. What if the bug is elsewhere? Consider: what if `words` contains duplicates but they're not `equals()`? What if `word` is mutated? What if the map is cleared between iterations? Debug it.

### Level 4: Real-world scenario

You're building an in-memory cache for a web service. Requirements:

- Maximum 10,000 entries.
- LRU eviction.
- Thread-safe.
- Entries expire after 5 minutes.
- `get` should be O(1).

Design the data structure(s). Which `Map` implementation(s) do you use? How do you handle expiration? How do you handle concurrency? What are the trade-offs?

### Level 5: Challenging/problem-solving

Implement a **bidirectional map** (`BiMap<K, V>`) that supports:

- `put(K, V)` — inserts a key-value pair.
- `get(K)` — returns the value for a key.
- `getKey(V)` — returns the key for a value.
- `remove(K)` — removes the pair.
- Both keys and values must be unique.

You may use any standard library data structures. Analyze the time and space complexity. What happens if you `put` a key that already exists with a different value? What if you `put` a value that already exists with a different key?

---

## 15. Final Map

```
                    Object
                      │
          equals() / hashCode() contract
                      │
                    Map<K, V>  ← NOT a Collection
                      │
      ┌───────────────┼───────────────┬──────────────┬─────────────────┐
      │               │               │              │                 │
   HashMap      LinkedHashMap      TreeMap        EnumMap      ConcurrentHashMap
      │               │               │              │                 │
   hash table     hash table      red-black       array          hash table
                  + linked list      tree                          + CAS
      │               │               │
      └───────────────┴───────────────┘
                      │
              Views: keySet(), values(), entrySet()
                      │
         Higher-level concepts:
         - LRU cache (LinkedHashMap)
         - Memoization
         - Graph adjacency lists
         - Inverted indexes
         - Counters/histograms
         - Configuration
         - Symbol tables
         - ConcurrentSkipListMap
```

**Prerequisites:** `Object`, `equals()`/`hashCode()`, generics, `Comparable`/`Comparator`, complexity analysis.

**`Map`:** an object mapping keys to values. No duplicate keys. Not a `Collection`.

**Related concepts:** `Set` (keys are a set), `List` (indexed map), `Queue` (ordered collection), `Dictionary` (legacy).

**Higher-level concepts:** caches, memoization, graph algorithms, indexes, counters, configs, symbol tables.

**Practical applications:** word frequency, grouping, caching, indexing, dependency injection, state machines, JSON models.



[[Java]]