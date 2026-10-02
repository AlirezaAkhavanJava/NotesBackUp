
This class provides a skeletal implementation of the Collection interface, to minimize the effort required to implement this interface.

To implement an unmodifiable collection, the programmer needs only to extend this class and provide implementations for the iterator and size methods. (The iterator returned by the iterator method must implement hasNext and next.)

To implement a modifiable collection, the programmer must additionally override this class's add method (which otherwise throws an UnsupportedOperationException), and the iterator returned by the iterator method must additionally implement its remove method.

The programmer should generally provide a void (no argument) and Collection constructor, as per the recommendation in the Collection interface specification.

The documentation for each non-abstract method in this class describes its implementation in detail. Each of these methods may be overridden if the collection being implemented admits a more efficient implementation.

This class is a member of the Java Collections Framework.


**`Collection`** is a **contract**.  
**`AbstractCollection`** is a **half-built machine** that helps you implement that contract.

Here’s the clean mental model:

`Collection<E>` is an **interface**. It says _what_ methods must exist (`add`, `remove`, `iterator`, `size`, etc.) but gives **no code**.

`AbstractCollection<E>` is an **abstract class** that **implements `Collection`** and provides **default implementations** for most methods, so you don’t have to write boilerplate.

Concrete difference, no fluff:

- `Collection` → _rules only_
    
- `AbstractCollection` → _rules + partial implementation_
    

What `AbstractCollection` gives you for free:

- `isEmpty()`
    
- `contains()`
    
- `toArray()`
    
- `remove(Object)`
    
- `clear()`
    
- `toString()`
    

What it **does not** give you:

- `size()`
    
- `iterator()`
    
- `add(E)` (optional)
    

If you extend `AbstractCollection`, you usually only implement:

```java
public int size();
public Iterator<E> iterator();
```

Tiny example:

```java
class MyCollection<E> extends AbstractCollection<E> {
    private final List<E> data = new ArrayList<>();

    @Override
    public Iterator<E> iterator() {
        return data.iterator();
    }

    @Override
    public int size() {
        return data.size();
    }
}
```

Why `AbstractCollection` exists:

- Avoids rewriting the same logic in every collection
    
- Ensures consistent behavior across the Collections Framework
    
- Makes creating custom collections sane
    

Reality check:

- You **cannot** extend both `AbstractCollection` and another class (single inheritance).
    
- If you just _use_ collections → you don’t care.
    
- If you _implement_ collections → `AbstractCollection` saves your sanity.
    

In short:  
**`Collection` defines the law. `AbstractCollection` enforces it with reusable code.**


###### Tags : [[1 - Collection interface 🤑]]