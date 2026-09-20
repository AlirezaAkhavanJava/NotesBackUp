
## LinkedHashSet in Java

**LinkedHashSet** is a concrete class in the Java Collections Framework that combines the features of both `HashSet` and `LinkedList`. It extends `HashSet` and implements the `Set` interface, maintaining a **doubly-linked list** running through all its entries to preserve **insertion order**.

```java
public class LinkedHashSet<E> extends HashSet<E>
    implements Set<E>, Cloneable, Serializable
```

---

## Key Characteristics

- **Insertion order preserved** — elements iterate in the order they were added
- **No duplicates** (inherited from `Set`)
- **Allows one null element**
- **Not thread-safe** (use `Collections.synchronizedSet()` if needed)
- **Slightly slower than HashSet** due to maintaining the linked list
- **O(1) average time** for add, remove, and contains operations

---

## How It Works Internally

LinkedHashSet is backed by a **hash table + doubly-linked list**:

```
Hash Table (for fast lookup)
     ↓
[ bucket 0 ] → entry → entry
[ bucket 1 ] → entry
[ bucket 2 ] → entry → entry

Doubly-linked list (for ordering)
head ↔ entryA ↔ entryB ↔ entryC ↔ entryD ↔ tail
```

- The **hash table** provides O(1) lookup
- The **linked list** maintains insertion order during iteration

---

## Basic Example

```java
LinkedHashSet<String> fruits = new LinkedHashSet<>();
fruits.add("Banana");
fruits.add("Apple");
fruits.add("Mango");
fruits.add("Apple");   // duplicate - ignored
fruits.add("Cherry");

System.out.println(fruits);
// Output: [Banana, Apple, Mango, Cherry]  ← insertion order preserved
```

**Compare with HashSet** (which would print in unpredictable order):
```java
HashSet<String> hashSet = new HashSet<>(fruits);
System.out.println(hashSet); 
// Output: [Apple, Cherry, Banana, Mango]  ← no guaranteed order
```

---

## Key Methods

LinkedHashSet inherits all methods from `HashSet` and `Set`:

| Method | Description |
|--------|-------------|
| `add(E e)` | Adds element if not already present |
| `remove(Object o)` | Removes the specified element |
| `contains(Object o)` | Checks if element exists |
| `size()` | Returns number of elements |
| `isEmpty()` | Checks if set is empty |
| `clear()` | Removes all elements |
| `iterator()` | Returns iterator in insertion order |
| `spliterator()` | Returns spliterator (late-binding) |

---

## Constructors

```java
// 1. Default constructor
LinkedHashSet<String> set1 = new LinkedHashSet<>();

// 2. With initial capacity
LinkedHashSet<String> set2 = new LinkedHashSet<>(20);

// 3. With initial capacity and load factor
LinkedHashSet<String> set3 = new LinkedHashSet<>(20, 0.75f);

// 4. From another collection (preserves that collection's iteration order)
List<String> list = Arrays.asList("C", "A", "B");
LinkedHashSet<String> set4 = new LinkedHashSet<>(list);
System.out.println(set4); // [C, A, B]

// 5. With initial capacity + load factor + accessOrder (package-private, for LinkedHashMap)
```

---

## Iteration Order Example

```java
LinkedHashSet<Integer> numbers = new LinkedHashSet<>();
numbers.add(50);
numbers.add(10);
numbers.add(30);
numbers.add(20);
numbers.add(40);

// Iterates in insertion order, NOT sorted order
for (int n : numbers) {
    System.out.print(n + " ");
}
// Output: 50 10 30 20 40
```

---

## LinkedHashSet vs HashSet vs TreeSet

| Feature | HashSet | LinkedHashSet | TreeSet |
|---------|---------|---------------|---------|
| Ordering | None | Insertion order | Sorted order |
| Underlying structure | Hash table | Hash table + Linked list | Red-Black Tree |
| Add/Remove/Contains | O(1) avg | O(1) avg | O(log n) |
| Null elements | One null allowed | One null allowed | Not allowed |
| Iteration speed | Fastest | Slightly slower than HashSet | Slowest |
| Memory usage | Lowest | Higher (stores links) | Medium |
| Implements | `Set` | `Set` | `SortedSet`, `NavigableSet` |

---

## Practical Use Cases

### 1. Removing Duplicates While Preserving Order

```java
List<String> withDuplicates = Arrays.asList("apple", "banana", "apple", "cherry", "banana");
LinkedHashSet<String> unique = new LinkedHashSet<>(withDuplicates);

System.out.println(unique); // [apple, banana, cherry]
```

### 2. LRU-style Cache (using LinkedHashMap internally)

```java
// LinkedHashSet is commonly used when order of insertion matters
public class RecentFiles {
    private LinkedHashSet<String> recent = new LinkedHashSet<>();
    private static final int MAX = 5;

    public void openFile(String file) {
        recent.remove(file);      // remove if exists (to reinsert at end)
        recent.add(file);         // add to end (most recent)
        if (recent.size() > MAX) {
            Iterator<String> it = recent.iterator();
            it.next();
            it.remove();          // remove oldest
        }
    }

    public void printRecent() {
        System.out.println(recent); // in order of opening
    }

    public static void main(String[] args) {
        RecentFiles rf = new RecentFiles();
        rf.openFile("a.txt");
        rf.openFile("b.txt");
        rf.openFile("c.txt");
        rf.openFile("a.txt"); // moved to end
        rf.printRecent();     // [b.txt, c.txt, a.txt]
    }
}
```

### 3. Preserving Order in JSON/CSV Output

```java
LinkedHashSet<String> columns = new LinkedHashSet<>();
columns.add("id");
columns.add("name");
columns.add("email");
// When serialized, columns appear in this exact order
```

---

## Thread-Safe Alternative

```java
Set<String> syncSet = Collections.synchronizedSet(new LinkedHashSet<>());

// Or for concurrent access:
Set<String> concurrentSet = ConcurrentHashMap.newKeySet();
// Note: ConcurrentHashMap.newKeySet() does NOT preserve insertion order
```

For a **thread-safe, insertion-ordered** set, you'd need external synchronization or a custom implementation.

---

## Summary

- **LinkedHashSet** = `HashSet` + **insertion order preservation** via a doubly-linked list
- Extends `HashSet`, implements `Set`
- **O(1)** average performance for basic operations (same as HashSet)
- **Predictable iteration order** — always in the order elements were inserted
- **Trade-off**: slightly more memory and marginally slower than `HashSet` because of the linked list
- **Use when**: you need uniqueness **and** predictable, insertion-based iteration order
- **Don't use when**: you need sorted order (use `TreeSet`) or maximum performance with no ordering requirement (use `HashSet`)


[[Java]]