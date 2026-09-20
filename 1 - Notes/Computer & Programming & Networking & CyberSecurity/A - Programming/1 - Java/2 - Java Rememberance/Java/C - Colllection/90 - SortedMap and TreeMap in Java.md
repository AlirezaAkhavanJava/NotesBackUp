


**SortedMap** is an interface in the Java Collections Framework (`java.util` package) that extends the `Map` interface and guarantees that its entries are maintained in **ascending key order**, either by the keys' **natural ordering** (via `Comparable`) or by a **`Comparator`** supplied at creation time. It adds **navigation methods** that exploit this ordering — such as `firstKey()`, `lastKey()`, `headMap()`, `tailMap()`, and `subMap()` — allowing range queries and ordered traversal. A `SortedMap` does **not permit duplicate keys**, and its iteration order (over keys, values, or entries) is always in **sorted key order**.

### Key Characteristics

- Extends `Map<K,V>`
- Keys are always sorted (natural or custom comparator)
- No duplicate keys
- Provides range-view and endpoint operations
- Iteration is in sorted key order
- Does not permit `null` keys if natural ordering is used (a `Comparator` may allow it, depending on implementation)

### Key Methods (beyond Map)

| Method | Description |
|--------|-------------|
| `firstKey()` | Returns the lowest key |
| `lastKey()` | Returns the highest key |
| `headMap(K toKey)` | View of entries with keys strictly less than `toKey` |
| `tailMap(K fromKey)` | View of entries with keys ≥ `fromKey` |
| `subMap(K from, K to)` | View of entries in range `[from, to)` |
| `comparator()` | Returns the comparator used, or `null` for natural ordering |

---

# TreeMap in Java

**TreeMap** is the primary concrete implementation of the `SortedMap` (and `NavigableMap`) interfaces. It is backed by a **Red-Black Tree** — a self-balancing binary search tree — which is why it keeps keys sorted at all times. Every insertion, deletion, and lookup runs in **O(log n)** time, and iteration is always in ascending key order. `TreeMap` is **not thread-safe**, does **not permit null keys** (when natural ordering is used), and provides a rich set of **navigation methods** such as `floorKey()`, `ceilingKey()`, `higherKey()`, `lowerKey()`, `pollFirstEntry()`, and `pollLastEntry()`.

### Key Characteristics

- Implements `NavigableMap<K,V>`, `SortedMap<K,V>`
- Backed by a Red-Black Tree
- Keys always sorted
- O(log n) for `get`, `put`, `remove`, `containsKey`
- Not thread-safe
- No `null` keys (natural ordering); `null` values allowed
- Fail-fast iterators
- Iteration in ascending key order

### Basic Example

```java
import java.util.TreeMap;
import java.util.SortedMap;
import java.util.Map;

public class TreeMapDemo {
    public static void main(String[] args) {
        TreeMap<String, Integer> map = new TreeMap<>();

        map.put("Banana", 20);
        map.put("Apple", 10);
        map.put("Cherry", 30);
        map.put("Date", 40);

        // Iterates in sorted (alphabetical) key order
        for (Map.Entry<String, Integer> entry : map.entrySet()) {
            System.out.println(entry.getKey() + " = " + entry.getValue());
        }
        // Output:
        // Apple = 10
        // Banana = 20
        // Cherry = 30
        // Date = 40
    }
}
```

### Navigation Example

```java
TreeMap<Integer, String> map = new TreeMap<>();
map.put(10, "A");
map.put(20, "B");
map.put(30, "C");
map.put(40, "D");
map.put(50, "E");

System.out.println(map.firstKey());       // 10
System.out.println(map.lastKey());        // 50
System.out.println(map.floorKey(35));     // 30  (greatest key ≤ 35)
System.out.println(map.ceilingKey(35));   // 40  (least key ≥ 35)
System.out.println(map.lowerKey(30));     // 20  (strictly less than 30)
System.out.println(map.higherKey(30));    // 40  (strictly greater than 30)
System.out.println(map.headMap(30));      // {10=A, 20=B}
System.out.println(map.tailMap(30));      // {30=C, 40=D, 50=E}
System.out.println(map.subMap(20, 40));   // {20=B, 30=C}
```

### Custom Comparator Example

```java
// Sort keys in descending order
TreeMap<Integer, String> map = new TreeMap<>(Comparator.reverseOrder());
map.put(10, "A");
map.put(30, "C");
map.put(20, "B");

System.out.println(map); // {30=C, 20=B, 10=A}

// Sort strings by length
TreeMap<String, Integer> byLength = new TreeMap<>(Comparator.comparingInt(String::length));
byLength.put("apple", 1);
byLength.put("hi", 2);
byLength.put("banana", 3);

System.out.println(byLength); // {hi=2, apple=1, banana=3}
```

---

# What Problems Do They Solve?

| Problem | How SortedMap / TreeMap solves it |
|---------|-----------------------------------|
| Need keys in sorted order | Red-Black tree keeps keys ordered automatically |
| Need range queries (`between X and Y`) | `subMap`, `headMap`, `tailMap` |
| Need nearest key (`floor`, `ceiling`) | Navigation methods |
| Need min/max key quickly | `firstKey()`, `lastKey()` in O(log n) |
| Need deterministic iteration order | Always sorted by key |
| Need an ordered dictionary / index | Sorted key-value mapping |

### Problems they create

- **O(log n)** operations instead of O(1) — slower than `HashMap` for pure lookup
- **Not thread-safe** — concurrent access corrupts the tree
- **No null keys** with natural ordering — throws `NullPointerException`
- **Keys must be comparable** — otherwise `ClassCastException` at runtime

### Solutions to those problems

| Problem | Solution |
|---------|----------|
| Slower than HashMap | Use `HashMap` when you don't need ordering |
| Not thread-safe | Use `ConcurrentSkipListMap` for concurrent sorted maps |
| No null keys | Wrap null with a sentinel object or use `Comparator.nullsFirst()` |
| Keys must be Comparable | Provide a custom `Comparator` at construction |
| Need insertion order instead of sorted | Use `LinkedHashMap` |

---

# Example — Solving a Real Problem

### Problem: Ranked leaderboard with range queries

You need to store player scores and quickly answer:
- Who has the highest score?
- Which players scored between 100 and 200?

```java
import java.util.TreeMap;

public class Leaderboard {
    private final TreeMap<Integer, String> scores = new TreeMap<>();

    public void addScore(int score, String player) {
        scores.put(score, player);
    }

    public String topScorer() {
        return scores.lastEntry().getValue(); // O(log n)
    }

    public String lowestScorer() {
        return scores.firstEntry().getValue(); // O(log n)
    }

    public TreeMap<Integer, String> between(int low, int high) {
        return new TreeMap<>(scores.subMap(low, true, high, true)); // inclusive
    }

    public static void main(String[] args) {
        Leaderboard lb = new Leaderboard();
        lb.addScore(150, "Alice");
        lb.addScore(220, "Bob");
        lb.addScore(180, "Charlie");
        lb.addScore(120, "Dave");

        System.out.println("Top: " + lb.topScorer());       // Bob
        System.out.println("Lowest: " + lb.lowestScorer()); // Dave
        System.out.println("100-200: " + lb.between(100, 200));
        // {120=Dave, 150=Alice, 180=Charlie}
    }
}
```

### Problem: Word frequency in sorted order

Count word occurrences and print them alphabetically.

```java
import java.util.TreeMap;

String text = "the quick brown fox jumps over the lazy dog the fox";
TreeMap<String, Integer> freq = new TreeMap<>();

for (String word : text.split(" ")) {
    freq.merge(word, 1, Integer::sum);
}

System.out.println(freq);
// {brown=1, dog=1, fox=2, jumps=1, lazy=1, over=1, quick=1, the=3}
```

### Problem: Thread-safe sorted map

`TreeMap` is not thread-safe. Solution: `ConcurrentSkipListMap`.

```java
import java.util.concurrent.ConcurrentSkipListMap;

ConcurrentSkipListMap<String, Integer> map = new ConcurrentSkipListMap<>();
map.put("Banana", 20);
map.put("Apple", 10);
map.put("Cherry", 30);

System.out.println(map.firstKey()); // Apple
// Safe for concurrent reads/writes — no external synchronization needed
```

---

# When to Use TreeMap

✅ **Use `TreeMap` when:**

- You need **keys sorted at all times**
- You need **range queries** (`subMap`, `headMap`, `tailMap`)
- You need **nearest-key navigation** (`floorKey`, `ceilingKey`, `higherKey`, `lowerKey`)
- You need fast access to the **min/max key**
- You need **deterministic, sorted iteration order**
- You are building ordered indexes, leaderboards, or interval structures

❌ **Avoid `TreeMap` when:**

- You only need fast lookup and don't care about order → use `HashMap`
- You need insertion order → use `LinkedHashMap`
- You need thread safety → use `ConcurrentSkipListMap`
- You need maximum performance and O(1) lookup → use `HashMap`

---

# Comparison Table

| Feature | HashMap | LinkedHashMap | TreeMap |
|---------|---------|---------------|---------|
| Ordering | None | Insertion/Access | Sorted by key |
| Underlying structure | Hash table | Hash table + linked list | Red-Black Tree |
| `get`/`put`/`remove` | O(1) avg | O(1) avg | O(log n) |
| Null keys | 1 allowed | 1 allowed | Not allowed (natural order) |
| Null values | Allowed | Allowed | Allowed |
| Range queries | ❌ | ❌ | ✅ |
| Navigation methods | ❌ | ❌ | ✅ |
| Thread-safe | ❌ | ❌ | ❌ |
| Concurrent alternative | `ConcurrentHashMap` | None (use sync) | `ConcurrentSkipListMap` |
| Best for | General lookup | Ordered iteration | Sorted keys + ranges |

---

# Summary

- **SortedMap** — interface guaranteeing **sorted keys** with range and navigation methods.
- **TreeMap** — concrete Red-Black Tree implementation of `SortedMap`/`NavigableMap` with **O(log n)** operations.
- They solve: **sorted iteration, range queries, nearest-key lookups, min/max access**.
- Problems they introduce: **slower than HashMap, not thread-safe, no null keys, keys must be comparable**.
- Solutions: use `HashMap` when ordering is not needed; `LinkedHashMap` for insertion order; `ConcurrentSkipListMap` for concurrency; custom `Comparator` for non-`Comparable` keys.
- **Use `TreeMap`** whenever **sorted keys, ranges, or navigation** matter — otherwise stick with `HashMap`.


[[Java]]