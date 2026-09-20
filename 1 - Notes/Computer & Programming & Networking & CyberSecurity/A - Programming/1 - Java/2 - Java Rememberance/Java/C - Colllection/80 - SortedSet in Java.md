
## SortedSet in Java

**SortedSet** is an interface in the Java Collections Framework that extends the `Set` interface. It guarantees that its elements are maintained in **ascending (sorted) order** according to either their natural ordering or a custom `Comparator` provided at creation time.

```java
public interface SortedSet<E> extends Set<E>
```

### Key Characteristics

- **No duplicates** (inherited from `Set`)
- **Sorted order** maintained automatically
- **Navigation methods** for finding elements based on position
- **Range-view operations** for getting subsets

### Key Methods (beyond Set)

| Method | Description |
|--------|-------------|
| `first()` | Returns the first (lowest) element |
| `last()` | Returns the last (highest) element |
| `headSet(E toElement)` | Returns elements strictly less than `toElement` |
| `tailSet(E fromElement)` | Returns elements greater than or equal to `fromElement` |
| `subSet(E from, E to)` | Returns elements in range `[from, to)` |
| `comparator()` | Returns the comparator used, or `null` for natural ordering |
| `spliterator()` | Returns a spliterator over elements |

---

## TreeSet in Java

**TreeSet** is the primary concrete implementation of `SortedSet` (and `NavigableSet`). It's backed by a **Red-Black Tree** (a self-balancing binary search tree), which is why it maintains sorted order.

```java
public class TreeSet<E> extends AbstractSet<E>
    implements NavigableSet<E>, Cloneable, Serializable
```

### Key Characteristics

- **Sorted automatically** in ascending order
- **No duplicates**
- **Not thread-safe** (use `Collections.synchronizedSortedSet()` for thread safety)
- **Does not allow null** elements (throws `NullPointerException`)
- **O(log n)** time for add, remove, and contains operations
- **Iteration is in sorted order**

---

## Example Usage

### Basic TreeSet

```java
TreeSet<Integer> numbers = new TreeSet<>();
numbers.add(5);
numbers.add(2);
numbers.add(8);
numbers.add(1);
numbers.add(2); // duplicate - ignored

System.out.println(numbers); // [1, 2, 5, 8] - sorted automatically
```

### SortedSet Reference

```java
SortedSet<String> names = new TreeSet<>();
names.add("Charlie");
names.add("Alice");
names.add("Bob");

System.out.println(names);        // [Alice, Bob, Charlie]
System.out.println(names.first()); // Alice
System.out.println(names.last());  // Charlie
```

### Navigation Methods

```java
TreeSet<Integer> set = new TreeSet<>();
set.add(10);
set.add(20);
set.add(30);
set.add(40);
set.add(50);

System.out.println(set.headSet(30));   // [10, 20]
System.out.println(set.tailSet(30));   // [30, 40, 50]
System.out.println(set.subSet(20, 40)); // [20, 30]

// NavigableSet-specific methods
System.out.println(set.floor(35));    // 30 (greatest ≤ 35)
System.out.println(set.ceiling(35));  // 40 (least ≥ 35)
System.out.println(set.lower(30));    // 20 (strictly less)
System.out.println(set.higher(30));   // 40 (strictly greater)
System.out.println(set.pollFirst());  // 10 (removes & returns first)
System.out.println(set.pollLast());   // 50 (removes & returns last)
```

### Custom Comparator

```java
// Sort in descending order
TreeSet<Integer> descending = new TreeSet<>(Comparator.reverseOrder());
descending.add(5);
descending.add(2);
descending.add(8);

System.out.println(descending); // [8, 5, 2]

// Sort strings by length
TreeSet<String> byLength = new TreeSet<>(Comparator.comparingInt(String::length));
byLength.add("apple");
byLength.add("hi");
byLength.add("banana");

System.out.println(byLength); // [hi, apple, banana]
```

---

## SortedSet vs TreeSet vs HashSet

| Feature | HashSet | TreeSet (SortedSet) |
|---------|---------|---------------------|
| Ordering | Unordered | Sorted (natural or custom) |
| Underlying structure | Hash table | Red-Black Tree |
| Time complexity (add/remove/contains) | O(1) average | O(log n) |
| Null elements | Allowed (one null) | Not allowed |
| Implements | `Set` | `SortedSet`, `NavigableSet` |
| Range/navigation methods | No | Yes |
| Performance | Faster for basic ops | Slower but sorted |

---

## When to Use TreeSet

✅ **Use TreeSet when:**
- You need elements in **sorted order** automatically
- You need **range queries** (subSet, headSet, tailSet)
- You need **navigation** (floor, ceiling, higher, lower)
- You need to find **min/max** quickly

❌ **Avoid TreeSet when:**
- You don't need sorting (use `HashSet` — it's faster)
- You need thread safety (use `ConcurrentSkipListSet`)
- You need to store `null` elements

---

## Practical Example: Leaderboard

```java
public class Leaderboard {
    private TreeSet<Integer> scores = new TreeSet<>(Comparator.reverseOrder());

    public void addScore(int score) {
        scores.add(score);
    }

    public int getTopScore() {
        return scores.first(); // highest score
    }

    public SortedSet<Integer> getTopN(int n) {
        // Get top N scores
        return scores.headSet(scores.first() - 1, true) instanceof SortedSet
            ? new TreeSet<>(scores).headSet(scores.first() - 1, true) // simplified
            : null;
    }

    public static void main(String[] args) {
        Leaderboard lb = new Leaderboard();
        lb.addScore(100);
        lb.addScore(250);
        lb.addScore(175);
        lb.addScore(300);

        System.out.println("Top score: " + lb.getTopScore()); // 300
    }
}
```

---

## Summary

- **SortedSet** = interface guaranteeing sorted elements with navigation methods
- **TreeSet** = concrete class implementing `SortedSet` (and `NavigableSet`) using a Red-Black Tree
- **O(log n)** operations due to tree structure
- Perfect for scenarios needing **sorted data, ranges, or navigation queries**


[[Java]]