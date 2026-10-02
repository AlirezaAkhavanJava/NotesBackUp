The List interface in Java extends the Collection interface and is part of the [java.util package](https://www.geeksforgeeks.org/java/java-util-package-java/). 
It is used to store ordered collections where duplicates are allowed and elements can be accessed by their index.

- Maintains insertion order
- Allows duplicate elements
- Supports null elements (implementation dependent)
- Supports bidirectional traversal using ListIterator

> *Bidirectional traversal* means you can move through a sequence in both directions:  
forward _and_ backward.

The List interface provides *four methods for positional (indexed) access* to list elements. 
Lists (like Java arrays) are zero based. 
Note that these operations may execute in time proportional to the index value for some implementations (the LinkedList class, for example). 
Thus, iterating over the elements in a list is typically preferable to indexing through it if the caller does not know the implementation.

> Zero-based means the first element lives at index 0, not 1.

---

The List interface provides a special iterator, called a ListIterator, that allows element insertion and replacement, and bidirectional access in addition to the normal operations that the Iterator interface provides. A method is provided to obtain a list iterator that starts at a specified position in the list.

![[ray-so-export 3.png]]

---
The List interface provides two methods to search for a specified object. From a performance standpoint, these methods should be used with caution. In many implementations they will perform costly linear searches. [[10 - Linear Search 🥭]]

![[ray-so-export (1).png]]

The List interface provides two methods to efficiently insert and remove multiple elements at an arbitrary point in the list.

![[ray-so-export (2).png]]


Some list implementations have restrictions on the elements that they may contain.
For example, some implementations prohibit null elements, and some have restrictions on the types of their elements. Attempting to add an ineligible element throws an unchecked exception, typically *NullPointerException* or *ClassCastException* .

Attempting to query the presence of an ineligible element may throw an exception, or it may simply return false; some implementations will exhibit the former behavior and some will exhibit the latter. More generally, attempting an operation on an ineligible element whose completion would not result in the insertion of an ineligible element into the list may throw an exception or it may succeed, at the option of the implementation. Such exceptions are marked as "optional" in the specification for this interface

---
### Unmodifiable Lists

> `List.of` and `List.copyOf` are both factory methods introduced in Java 9 to create immutable lists, but they have slightly different purposes.

The List.of and List.copyOf static factory methods provide a convenient way to create unmodifiable lists. The List instances created by these methods have the following characteristics:

- They are unmodifiable. Elements cannot be added, removed, or replaced. Calling any mutator method on the List will always cause *UnsupportedOperationException* or *ConcurrentModificationException* to be thrown. However, if the contained elements are themselves mutable, this may cause the List's contents to appear to change.

- They disallow null elements. Attempts to create them with null elements result in NullPointerException.

- The order of elements in the list is the same as the order of the provided arguments, or of the elements in the provided array.

- They are serializable if all elements are serializable.

- The lists and their subList views implement the *RandomAccess* interface.

- They are value-based. Programmers should treat instances that are equal as interchangeable and should not use them for synchronization, or unpredictable behavior may occur. For example, in a future release, synchronization may fail. Callers should make no assumptions about the identity of the returned instances. Factories are free to create new instances or reuse existing ones.

> [!RandomAccess Interface]
> Marker interface used by List implementations to indicate that they support fast (generally constant time) random access. The primary purpose of this interface is to allow generic algorithms to alter their behavior to provide good performance when applied to either random or sequential access lists.
> The best algorithms for manipulating random access lists (such as ArrayList) can produce quadratic behavior when applied to sequential access lists (such as LinkedList). Generic list algorithms are encouraged to check whether the given list is an instanceof this interface before applying an algorithm that would provide poor performance if it were applied to a sequential access list, and to alter their behavior if necessary to guarantee acceptable performance.

---
## RandomAccess

`RandomAccess` is a **marker interface** in Java. That means it has **no methods**—it just **marks a class** to tell you something about how it works.

### *Why it exists*

Some lists are fast at `get(i)` (like `ArrayList`), some are slow (like `LinkedList`).

- `ArrayList` implements `RandomAccess` → `get(i)` is **O(1)**.
    
- `LinkedList` **does not** → `get(i)` is **O(n)**.
    

This allows **algorithms to adapt**:


![[ray-so-export 1.png]]



##### Tags : [[1 - Collection interface 🤑]]