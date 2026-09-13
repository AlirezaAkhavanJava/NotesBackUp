Resizable-array implementation of the List interface. Implements all optional list operations, and permits all elements, including null. In addition to implementing the List interface, this class provides methods to manipulate the size of the array that is used internally to store the list. (This class is roughly equivalent to Vector, except that it is unsynchronized.)


The size, isEmpty, get, set, getFirst, getLast, removeLast, iterator, listIterator, and reversed operations run in constant time. The add, and addLast operations runs in amortized constant time, that is, adding n elements requires O(n) time. All of the other operations run in linear time (roughly speaking). The constant factor is low compared to that for the LinkedList implementation.


Each ArrayList instance has a capacity. The capacity is the size of the array used to store the elements in the list. It is always at least as large as the list size. As elements are added to an ArrayList, its capacity grows automatically. The details of the growth policy are not specified beyond the fact that adding an element has constant amortized time cost.



![[ray-so-export 2.png]]

An application can increase the capacity of an ArrayList instance before adding a large number of elements using the ensureCapacity operation. This may reduce the amount of incremental reallocation


Note that this implementation is not synchronized. If multiple threads access an ArrayList instance concurrently, and at least one of the threads modifies the list structurally, it must be synchronized externally. (A structural modification is any operation that adds or deletes one or more elements, or explicitly resizes the backing array; merely setting the value of an element is not a structural modification.) This is typically accomplished by synchronizing on some object that naturally encapsulates the list. If no such object exists, the list should be "wrapped" using the *Collections.synchronizedList* method. This is best done at creation time, to prevent accidental unsynchronized access to the list:

```java 
List list = Collections.synchronizedList(new ArrayList(...));
```


The iterators returned by this class's iterator and listIterator methods are fail-fast: if the list is structurally modified at any time after the iterator is created, in any way except through the iterator's own remove or add methods, the iterator will throw a ConcurrentModificationException. Thus, in the face of concurrent modification, the iterator fails quickly and cleanly, rather than risking arbitrary, non-deterministic behavior at an undetermined time in the future.



Note that the fail-fast behavior of an iterator cannot be guaranteed as it is, generally speaking, impossible to make any hard guarantees in the presence of unsynchronized concurrent modification. Fail-fast iterators throw *ConcurrentModificationException* on a best-effort basis. Therefore, it would be wrong to write a program that depended on this exception for its correctness: the fail-fast behavior of iterators should be used only to detect bugs.

---

`ArrayList` has **three public constructors** in Java:

1. `ArrayList()`  
    Creates an empty list with **default initial capacity (10)**.
    
2. `ArrayList(int initialCapacity)`  
    Creates an empty list with a **specified initial capacity**.  
    Used for performance when you know roughly how many elements you’ll add.
    
3. `ArrayList(Collection<? extends E> c)`  
    Creates a list **initialized with elements from another collection**, in encounter order.


![[ray-so-export (1) 2.png]]


---

## How it works internaly

**`ArrayList` internally is a resizable array.**  
Specifically, it wraps an `Object[]` called `elementData`.

![[ray-so-export (2) 2.png]]

Here’s the mental model.

**Storage**

- Elements are stored in a plain array: `Object[] elementData`
    
- Index-based access is direct: `elementData[i]` → **O(1)**
    

**Adding elements**

- When you call `add(e)`:
    
    - If there’s space → put `e` at `elementData[size]`
        
    - If full → **grow the array**
        
- Growth rule:  
    New capacity ≈ `oldCapacity + (oldCapacity >> 1)` → **1.5× growth**
    
- Old array is copied into a new, bigger one (costly but amortized)
    
![[ray-so-export (3) 1.png]]

**Removing elements**

- Removing by index shifts all elements to the left
    
- Uses `System.arraycopy`
    
- Cost: **O(n)** in the worst case
    

**Size vs Capacity**

- `size` → number of actual elements
    
- `capacity` → length of the internal array
    
- Capacity can be larger than size
    

**Random access**

- `get(index)` and `set(index)` are **O(1)**
    
- That’s why `ArrayList` beats `LinkedList` for reads
    

**Nulls & duplicates**

- Allowed
    
- Stored exactly like any other object reference
    

**Fail-fast behavior**

- Structural modification during iteration → `ConcurrentModificationException`
    
- Controlled by `modCount`
    

**Memory note**

- Uses more memory than needed sometimes
    
- Call `trimToSize()` if you want to shrink capacity
    

Think of `ArrayList` as:

> “An array that occasionally panics, buys a bigger house, and moves everything.”

Efficient for reads, decent for appends, bad for frequent inserts/removals in the middle.

---

Here’s a **clean table mapping `ArrayList` methods to their underlying DSA behavior and time complexity**. No fluff, just mechanics.

|Method|What it does internally|Data Structure Action|Time Complexity|
|---|---|---|---|
|`add(E e)`|Adds at end; may resize array|Append to array|**O(1)** amortized|
|`add(int i, E e)`|Shifts elements right|Array shift|**O(n)**|
|`get(int i)`|Direct index access|Array lookup|**O(1)**|
|`set(int i, E e)`|Replace value at index|Array write|**O(1)**|
|`remove(int i)`|Shifts elements left|Array shift|**O(n)**|
|`remove(Object o)`|Search + shift|Linear search + shift|**O(n)**|
|`contains(Object o)`|Linear scan|Linear search|**O(n)**|
|`indexOf(Object o)`|Linear scan from start|Linear search|**O(n)**|
|`lastIndexOf(Object o)`|Linear scan from end|Reverse linear search|**O(n)**|
|`size()`|Returns stored counter|Constant lookup|**O(1)**|
|`isEmpty()`|`size == 0` check|Constant check|**O(1)**|
|`clear()`|Nulls array slots|Bulk null assignment|**O(n)**|
|`toArray()`|Copies elements|Array copy|**O(n)**|
|`ensureCapacity(int)`|Resize if needed|Array reallocation|**O(n)** (if resize)|
|`trimToSize()`|Shrinks array to size|Array reallocation|**O(n)**|
|`iterator()`|Creates fail-fast iterator|Cursor over array|**O(1)**|
|`sort(Comparator)`|TimSort|Hybrid merge sort|**O(n log n)**|

**Key takeaway (DSA lens):**

- `ArrayList` = **Dynamic Array**
    
- Fast reads (`O(1)`), slow middle operations (`O(n)`)
    
- Growth cost is hidden via **amortized analysis**
    

Use it when **index access dominates**.  
Avoid it when **insert/remove in the middle dominates**.


### Tags : [[1 - Collection interface 🤑]]