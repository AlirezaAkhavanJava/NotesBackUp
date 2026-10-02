
## Hashtable

### When to use it

**Almost never in new code.** Only consider it when:

- You are maintaining **legacy code** written before Java 5 that already depends on `Hashtable`
- You genuinely need a `Dictionary` superclass reference (extremely rare)
- You need a synchronized map and absolutely cannot add `java.util.concurrent` imports (virtually never)

### Problems it solves

| Problem | How Hashtable solves it |
|---|---|
| Fast key-value lookup | Hash-based O(1) average access |
| Thread-safe map access | Every method is `synchronized` |
| No duplicate keys | Keys are unique by contract |

### Problems it creates

- **Coarse-grained locking** — one lock for the whole table means threads block each other even when accessing different buckets
- **No nulls** — inconvenient and inconsistent with `HashMap`
- **Slow** — synchronization overhead even in single-threaded use
- **Legacy API** — `keys()`, `elements()`, `contains()` use outdated `Enumeration`
- **Compound operations are not atomic** — `if (!map.containsKey(k)) map.put(k, v);` is still a race condition

### Newer approach: `ConcurrentHashMap`

```java
// ❌ Old way — Hashtable
Hashtable<String, Integer> old = new Hashtable<>();
old.put("a", 1);

// ✅ Modern way — ConcurrentHashMap
ConcurrentHashMap<String, Integer> modern = new ConcurrentHashMap<>();
modern.put("a", 1);
modern.putIfAbsent("b", 2);        // atomic
modern.computeIfAbsent("c", k -> 3); // atomic
modern.merge("a", 10, Integer::sum); // atomic
```

| Feature | Hashtable | ConcurrentHashMap |
|---|---|---|
| Locking | Whole table | Per-bucket (fine-grained) |
| Read concurrency | Blocked by writes | Lock-free reads |
| Atomic compound ops | ❌ No | ✅ Yes (`putIfAbsent`, `compute`, `merge`) |
| Null support | ❌ | ❌ |
| Performance | Poor under contention | Excellent |
| Iteration | Fail-fast | Weakly consistent |

**Bottom line:** If you need a thread-safe map, use `ConcurrentHashMap`. If you don't, use `HashMap`. There is almost no reason to use `Hashtable` today.

---

## LinkedHashMap

### When to use it

Use `LinkedHashMap` when you need **both** fast key-based lookup **and** predictable iteration order:

1. **Insertion-ordered maps** — you want to iterate in the order keys were added
2. **LRU caches** — you want automatic eviction of least-recently-used entries
3. **Deterministic output** — JSON/XML serialization where field order matters
4. **Configuration maps** — preserving the order of properties as they were defined
5. **Access-ordered maps** — tracking which keys were recently used

### Problems it solves

| Problem | How LinkedHashMap solves it |
|---|---|
| HashMap has no iteration order | Maintains a doubly-linked list through entries |
| Need insertion-order iteration | Default mode preserves insertion order |
| Need access-order tracking | Constructor flag `accessOrder=true` reorders on `get()` |
| Need an LRU cache | Override `removeEldestEntry()` for automatic eviction |
| Need O(1) lookup + ordering | Hash table + linked list combined |

### Problems it creates

- **Not thread-safe** — concurrent modification corrupts the structure
- **More memory** — each entry stores `before`/`after` pointers
- **Slightly slower** than `HashMap` due to maintaining links
- **No concurrency support** — cannot be used safely across threads without external sync

### Newer approach: For ordered maps

There is **no direct concurrent replacement** for `LinkedHashMap` in the JDK. Your options depend on what you need:

**1. For thread-safe ordered maps (insertion order):**

```java
// Option A: Wrap with synchronization (simple, but coarse locking)
Map<String, Integer> syncOrdered = Collections.synchronizedMap(new LinkedHashMap<>());

// Option B: Use ConcurrentSkipListMap (sorted order, not insertion order)
ConcurrentSkipListMap<String, Integer> sorted = new ConcurrentSkipListMap<>();
```

**2. For LRU caches — modern alternatives:**

```java
// ❌ Old way — LinkedHashMap with removeEldestEntry
public class LRUCache<K, V> extends LinkedHashMap<K, V> {
    private final int capacity;
    public LRUCache(int capacity) {
        super(capacity, 0.75f, true);
        this.capacity = capacity;
    }
    @Override
    protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > capacity;
    }
}

// ✅ Modern way — Caffeine (high-performance, thread-safe)
Cache<String, Integer> cache = Caffeine.newBuilder()
    .maximumSize(100)
    .expireAfterAccess(10, TimeUnit.MINUTES)
    .build();

cache.put("key", 1);
Integer value = cache.getIfPresent("key");

// ✅ Modern way — Guava Cache
Cache<String, Integer> guavaCache = CacheBuilder.newBuilder()
    .maximumSize(100)
    .expireAfterAccess(10, TimeUnit.MINUTES)
    .build();
```

**3. For concurrent + insertion-ordered maps (custom):**

```java
// No JDK built-in — use ConcurrentHashMap + ConcurrentLinkedQueue for order
// Or use a third-party library like Eclipse Collections or Caffeine
```

### Comparison of map implementations

| Feature | HashMap | LinkedHashMap | TreeMap | ConcurrentHashMap | ConcurrentSkipListMap |
|---|---|---|---|---|---|
| Ordering | None | Insertion/Access | Sorted | None | Sorted |
| Thread-safe | ❌ | ❌ | ❌ | ✅ | ✅ |
| Null keys | ✅ 1 | ✅ 1 | ❌ | ❌ | ❌ |
| Null values | ✅ | ✅ | ✅ | ❌ | ❌ |
| Lookup | O(1) | O(1) | O(log n) | O(1) | O(log n) |
| LRU support | ❌ | ✅ | ❌ | ❌ | ❌ |
| Iteration order | Random | Predictable | Sorted | Weakly consistent | Sorted |

---

## What Problems Do They Solve — Summary

### Hashtable's original purpose

In Java 1.0, there was no Collections Framework. `Hashtable` was the only built-in key-value store, and it was synchronized because early Java emphasized thread safety. It solved:

- Storing and retrieving data by key
- Thread-safe access in multi-threaded environments

### Hashtable's modern replacement

`ConcurrentHashMap` solves the same problems **better**:

- Fine-grained locking → much higher concurrency
- Atomic compound operations → correct multi-threaded logic
- Lock-free reads → faster under read-heavy workloads

### LinkedHashMap's purpose

`HashMap` gives you O(1) lookup but no order. `LinkedList` gives you order but O(n) lookup. `LinkedHashMap` gives you **both**:

- O(1) lookup via hash table
- Predictable iteration via linked list
- Optional access-order tracking via constructor flag
- LRU eviction via `removeEldestEntry()`

### LinkedHashMap's modern replacement

For **LRU caching specifically**, dedicated caching libraries (Caffeine, Guava) are far better:

- Thread-safe
- Time-based expiration
- Size-based eviction
- Statistics and monitoring
- Better performance under concurrency

For **ordered maps in concurrent code**, there is no perfect JDK replacement — you either accept sorted order (`ConcurrentSkipListMap`) or use external synchronization.

---

## Decision Guide

```
Do you need a thread-safe map?
├── Yes → ConcurrentHashMap (or ConcurrentSkipListMap if sorted)
└── No → Do you need ordering?
         ├── No → HashMap
         └── Yes → What kind of ordering?
                  ├── Insertion/access order → LinkedHashMap
                  ├── Sorted order → TreeMap
                  └── LRU cache → Caffeine / Guava (or LinkedHashMap for simple cases)

Are you maintaining legacy code?
└── Yes → Hashtable might be present; migrate to ConcurrentHashMap when possible
```

---

## Final Takeaway

| Class | Use it? | Modern alternative |
|---|---|---|
| `Hashtable` | ❌ Avoid in new code | `ConcurrentHashMap` |
| `LinkedHashMap` | ✅ Still relevant | Caffeine/Guava for caches; no direct JDK replacement for ordered concurrent maps |

- **Hashtable** is a legacy class with a better modern replacement (`ConcurrentHashMap`). Its only remaining value is in old codebases.
- **LinkedHashMap** is still widely used and relevant for ordered maps and simple LRU caches. For production-grade caching under concurrency, use **Caffeine** or **Guava Cache**.
- The general trend is toward **fine-grained concurrency**, **atomic compound operations**, and **specialized libraries** rather than monolithic synchronized collections.


[[Java]]