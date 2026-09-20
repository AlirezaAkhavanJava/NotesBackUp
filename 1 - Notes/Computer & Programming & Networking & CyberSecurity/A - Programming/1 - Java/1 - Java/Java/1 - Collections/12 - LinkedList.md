
LinkedList is a part of the Java Collection Framework and is present in the [java.util package](https://www.geeksforgeeks.org/java/java-util-package-java/). It implements a* doubly-linked list data structure* where elements are not stored in contiguous memory. Each node contains three parts: the data, a reference to the next node, and a reference to the previous node.

- ***Dynamic Size:*** LinkedList grows or shrinks dynamically at runtime.
- ***Maintains Insertion Order:*** Elements are stored in the order they are added.
- ***Allows Duplicates:*** Duplicate elements are allowed.
- ***Not Synchronized:*** By default, LinkedList is not thread-safe. To make Thread-safe use of Collections.synchronizedList().
- ***Efficient Insertion/Deletion:*** Adding or removing elements at the beginning or middle is faster compared to ArrayList.


> A doubly linked list is a more complex data structure than a singly linked list, but it offers several advantages. The main advantage of a doubly linked list is that it allows for efficient traversal of the list in both directions. This is because each node in the list contains a pointer to the previous node and a pointer to the next node. This allows for quick and easy insertion and deletion of nodes from the list, as well as efficient traversal of the list in both directions.


Doubly-linked list implementation of the List and Deque interfaces. Implements all optional list operations, and permits all elements (including null).
All of the operations perform as could be expected for a doubly-linked list. Operations that index into the list will traverse the list from the beginning or the end, whichever is closer to the specified index.

---

Note that this implementation is not synchronized. If multiple threads access a linked list concurrently, and at least one of the threads modifies the list structurally, it must be synchronized externally. (A structural modification is any operation that adds or deletes one or more elements; merely setting the value of an element is not a structural modification.) This is typically accomplished by synchronizing on some object that naturally encapsulates the list. If no such object exists, the list should be "wrapped" using the Collections.synchronizedList method. This is best done at creation time, to prevent accidental unsynchronized access to the list:

![[ray-so-export (8).png]]

The iterators returned by this class's iterator and listIterator methods are fail-fast: if the list is structurally modified at any time after the iterator is created, in any way except through the Iterator's own remove or add methods, the iterator will throw a ConcurrentModificationException. Thus, in the face of concurrent modification, the iterator fails quickly and cleanly, rather than risking arbitrary, non-deterministic behavior at an undetermined time in the future.

Note that the fail-fast behavior of an iterator cannot be guaranteed as it is, generally speaking, impossible to make any hard guarantees in the presence of unsynchronized concurrent modification. Fail-fast iterators throw ConcurrentModificationException on a best-effort basis. Therefore, it would be wrong to write a program that depended on this exception for its correctness: the fail-fast behavior of iterators should be used only to detect bugs.


##### Tags : [[1 - Collection interface 🤑]]