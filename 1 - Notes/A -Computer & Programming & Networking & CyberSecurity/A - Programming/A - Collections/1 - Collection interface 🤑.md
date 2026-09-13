
The Collection interface is the root of the Java Collections Framework, defined in the [java.util package](https://www.geeksforgeeks.org/java/java-util-package-java/). It represents a group of individual objects as a single unit and provides basic operations for working with them.

- *Dynamic in Nature:* Collections can automatically grow or shrink in size, unlike arrays that have a fixed length.
- *Stores Homogeneous and Heterogeneous Objects:* Can hold same-type or different-type elements based on implementation.
- *Easy to Use:* Provides convenient methods such as add(), remove(), and clear() to manage elements effortlessly.
- *Efficient Traversal:* Allows easy access and processing of elements using loops or iterators

---

## Collection

The **Collection** interface in Java is the **root interface** of the entire **Collections Framework** (introduced in Java 1.2). It defines the basic contract that **all collection types** (except Map) must follow.

### Hierarchy Overview

![[Pasted image 20251222075046.png]]

### Key Points about `Collection<E>`

| Feature            | Description                                                                                       |
| ------------------ | ------------------------------------------------------------------------------------------------- |
| Extends            | `Iterable<E>` (so you can use **enhanced for-loop**)                                              |
| Type               | **Generic** since Java 5 (`Collection<E>`)                                                        |
| Duplicate elements | Allowed (except in subtypes like Set)                                                             |
| Order              | Not guaranteed (except in subtypes like List)                                                     |
| Null elements      | Usually allowed (except in some implementations like TreeSet)                                     |
| Thread-safety      | Not thread-safe by default (use `Collections.synchronizedCollection()` or concurrent collections) |

### Core Methods of `Collection<E>`

| Method Signature                              | Description                                                                 | Return Value |
|-----------------------------------------------|-----------------------------------------------------------------------------|--------------|
| `int size()`                                  | Number of elements                                                          | `int`        |
| `boolean isEmpty()`                           | True if collection has no elements                                          | `boolean`    |
| `boolean contains(Object o)`                  | True if collection contains the specified element                           | `boolean`    |
| `boolean containsAll(Collection<?> c)`        | True if collection contains all elements of the given collection            | `boolean`    |
| `Iterator<E> iterator()`                      | Returns an iterator over the elements                                       | `Iterator<E>`|
| `Object[] toArray()`                          | Returns array containing all elements                                       | `Object[]`   |
| `<T> T[] toArray(T[] a)`                      | Returns typed array containing all elements                                 | `T[]`        |
| `boolean add(E e)`                            | Adds element (optional operation)                                           | `boolean`    |
| `boolean remove(Object o)`                    | Removes one occurrence of the specified element                             | `boolean`    |
| `boolean removeAll(Collection<?> c)`          | Removes all elements that are also in the given collection                  | `boolean`    |
| `boolean retainAll(Collection<?> c)`          | Keeps only elements that are in the given collection                        | `boolean`    |
| `void clear()`                                | Removes all elements                                                        | `void`       |
| `boolean addAll(Collection<? extends E> c)`   | Adds all elements from the given collection                                 | `boolean`    |

### Commonly Used Implementations

| Interface    | Common Implementations                  | Ordered? | Allows Duplicates? | Allows `null`? |
|--------------|-----------------------------------------|----------|--------------------|----------------|
| **List**     | `ArrayList`, `LinkedList`, `Vector`     | Yes      | Yes                | Yes            |
| **Set**      | `HashSet`, `LinkedHashSet`, `TreeSet`   | No / Insertion / Sorted | No                 | Yes (except `TreeSet`) |
| **Queue**    | `LinkedList`, `PriorityQueue`, `ArrayDeque` | Yes (FIFO / priority) | Yes                | Yes (except `PriorityQueue`) |
| **Deque**    | `ArrayDeque`, `LinkedList`              | Yes (double-ended) | Yes                | Yes            |

### Example: Basic Usage

```java
import java.util.*;

public class CollectionExample {
    public static void main(String[] args) {
        // Most common way: use concrete class
        Collection<String> names = new ArrayList<>();

        // Add elements
        names.add("Alice");
        names.add("Bob");
        names.add("Charlie");
        names.add("Bob"); // duplicates allowed in List

        System.out.println("Size: " + names.size());            // 4
        System.out.println("Contains 'Bob': " + names.contains("Bob")); // true

        // Iterate using enhanced for-loop (because Collection extends Iterable)
        for (String name : names) {
            System.out.println(name);
        }

        // Remove
        names.remove("Bob"); // removes first occurrence

        // Convert to array
        String[] nameArray = names.toArray(new String[0]);

        // Clear all elements
        names.clear();
        System.out.println("Is empty? " + names.isEmpty()); // true
    }
}
```

### Important Notes / Common Pitfalls

| Situation                              | What happens                                                                 |
|----------------------------------------|------------------------------------------------------------------------------|
| Adding to unmodifiable collection      | `UnsupportedOperationException`                                              |
| Using `remove()` while iterating       | `ConcurrentModificationException` (use `Iterator.remove()` instead)          |
| `contains()` on custom objects         | Requires proper `equals()` and `hashCode()` (especially for HashSet/HashMap) |
| `TreeSet` / `TreeMap`                  | Requires elements to be `Comparable` or provide `Comparator`                 |
| `null` in `TreeSet`                    | `NullPointerException`                                                       |

### Summary Table

| Feature                  | List | Set | Queue | Deque |
|--------------------------|------|-----|-------|-------|
| Ordered                  | Yes  | No* | Yes   | Yes   |
| Duplicates               | Yes  | No  | Yes   | Yes   |
| Access by index          | Yes  | No  | No    | No    |
| Positional access        | Yes  | No  | No    | Yes   |
| Allows null              | Yes  | Yes* | Yes*  | Yes   |

(*except some special cases)

In short:  
**Collection** is the **most general interface** for holding multiple elements.  
If you need **order + duplicates** → use **List**  
If you need **uniqueness** → use **Set**  
If you need **FIFO / priority** → use **Queue** or **Deque**


###### Tags : [[1 - DSA 🥭]][[Java]]