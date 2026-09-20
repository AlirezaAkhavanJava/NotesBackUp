
**HashMap** is a class in the Java Collections Framework (`java.util` package) that implements the `Map` interface and represents a **hash table-based key-value store**. It maps unique keys to values, where each key can appear at most once. Internally, it uses an array of buckets and resolves collisions via **separate chaining** (linked lists, and since Java 8, balanced trees when a bucket grows large). `HashMap` provides **O(1) average time** for `get`, `put`, `remove`, and `containsKey`. It is **not thread-safe**, permits **one null key and multiple null values**, and its iteration order is **unordered** and not guaranteed. It is the default, general-purpose `Map` implementation in Java.

---
### Key Characteristics

- Implements `Map<K,V>`
- Backed by a hash table
- One null key allowed; multiple null values allowed
- Not synchronized / not thread-safe
- Unordered iteration
- O(1) average performance for basic operations
- Fail-fast iterators
- Default initial capacity: 16; default load factor: 0.75
- Resizes (doubles capacity) when entries exceed capacity × load factor

### Basic Example

```java
import java.util.HashMap;
import java.util.Map;

public class HashMapDemo {
    public static void main(String[] args) {
        HashMap<String, Integer> map = new HashMap<>();

        map.put("Apple", 10);
        map.put("Banana", 20);
        map.put(null, 0);          // null key allowed
        map.put("Cherry", null);   // null value allowed

        System.out.println(map.get("Apple"));  // 10
        System.out.println(map.get(null));     // 0

        // Iteration order is not guaranteed
        for (Map.Entry<String, Integer> entry : map.entrySet()) {
            System.out.println(entry.getKey() + " = " + entry.getValue());
        }
    }
}
```

### When to Use

- You need fast key-based lookup, insertion, and deletion
- You do not need sorted or insertion order
- You are working in a single-threaded environment (or will handle synchronization externally)
- You want the standard, general-purpose `Map` in Java

For thread-safe use, prefer `ConcurrentHashMap`. For insertion order, use `LinkedHashMap`. For sorted order, use `TreeMap`.


[[Java]]