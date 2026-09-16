## Hashtable

**Hashtable** is a legacy class in the Java Collections Framework that implements the `Map` interface and represents a **thread-safe, hash-based key-value store**. It was introduced in Java 1.0, before the Collections Framework existed, and extends the obsolete `Dictionary` class. Every method in `Hashtable` is `synchronized`, making it safe for use by multiple threads, but this coarse-grained locking makes it slower than modern alternatives. It **does not permit null keys or null values** — attempting to store or retrieve a null throws a `NullPointerException`. It provides **O(1) average time** for `get`, `put`, `remove`, and `containsKey`, and its iteration order is **unordered** and not guaranteed.

---
## LinkedHashMap

**LinkedHashMap** is a concrete class in the Java Collections Framework that extends `HashMap` and implements the `Map` interface. It combines the fast lookup of a hash table with a **doubly-linked list** that runs through all its entries, giving it **predictable iteration order**. By default, iteration follows **insertion order** (the order in which keys were added), but it can be configured to follow **access order** (the order in which keys were last accessed) by passing `true` to a special constructor. It is **not thread-safe**, **allows one null key and multiple null values**, and provides **O(1) average time** for basic operations. Its main use cases are preserving order in maps and building **LRU (Least Recently Used) caches** by overriding `removeEldestEntry`.

---

## Key Differences

| Feature | Hashtable | LinkedHashMap |
|---------|-----------|---------------|
| Package | `java.util` | `java.util` |
| Introduced | Java 1.0 | Java 1.4 |
| Thread-safe | ✅ Yes (all methods synchronized) | ❌ No |
| Null keys/values | ❌ Not allowed | ✅ One null key, many null values |
| Iteration order | Unordered | Insertion order (or access order) |
| Performance | Slower (due to synchronization) | Faster (no synchronization) |
| Underlying structure | Hash table | Hash table + doubly-linked list |
| Extends | `Dictionary` | `HashMap` |
| Use case | Legacy thread-safe maps | Ordered maps, LRU caches |
| Modern alternative | `ConcurrentHashMap` | `ConcurrentHashMap` (no order) or `Collections.synchronizedMap` |

---

## Examples

### Hashtable

```java
import java.util.Hashtable;

public class HashtableDemo {
    public static void main(String[] args) {
        Hashtable<String, Integer> table = new Hashtable<>();
        table.put("Apple", 10);
        table.put("Banana", 20);
        table.put("Cherry", 30);

        // table.put(null, 5);      // ❌ NullPointerException
        // table.put("Grape", null); // ❌ NullPointerException

        System.out.println(table.get("Banana")); // 20
        System.out.println(table.containsKey("Apple")); // true

        // Iteration order is not guaranteed
        for (var entry : table.entrySet()) {
            System.out.println(entry.getKey() + " = " + entry.getValue());
        }
    }
}
```

### LinkedHashMap — Insertion Order (default)

```java
import java.util.LinkedHashMap;
import java.util.Map;

public class LinkedHashMapDemo {
    public static void main(String[] args) {
        LinkedHashMap<String, Integer> map = new LinkedHashMap<>();
        map.put("Banana", 3);
        map.put("Apple", 5);
        map.put("Cherry", 7);

        // Iterates in insertion order
        for (Map.Entry<String, Integer> entry : map.entrySet()) {
            System.out.println(entry.getKey() + " = " + entry.getValue());
        }
        // Output:
        // Banana = 3
        // Apple = 5
        // Cherry = 7
    }
}
```

### LinkedHashMap — Access Order & LRU Cache

```java
import java.util.LinkedHashMap;
import java.util.Map;

public class LRUCache<K, V> extends LinkedHashMap<K, V> {
    private final int capacity;

    public LRUCache(int capacity) {
        super(capacity, 0.75f, true); // true = access order
        this.capacity = capacity;
    }

    @Override
    protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > capacity; // remove oldest when over capacity
    }

    public static void main(String[] args) {
        LRUCache<String, Integer> cache = new LRUCache<>(3);
        cache.put("A", 1);
        cache.put("B", 2);
        cache.put("C", 3);
        cache.get("A");        // access A, moves it to most-recently-used
        cache.put("D", 4);     // evicts B (least recently used)

        System.out.println(cache); // {C=3, A=1, D=4}
    }
}
```

---

## Summary

- **Hashtable**: legacy, thread-safe, no nulls, unordered, slow due to full synchronization. Prefer `ConcurrentHashMap` for concurrent use, or `HashMap` for single-threaded use.
- **LinkedHashMap**: modern, not thread-safe, allows nulls, preserves insertion or access order, ideal for ordered maps and LRU caches. Extends `HashMap` and adds a linked list for ordering.
[[Java]]