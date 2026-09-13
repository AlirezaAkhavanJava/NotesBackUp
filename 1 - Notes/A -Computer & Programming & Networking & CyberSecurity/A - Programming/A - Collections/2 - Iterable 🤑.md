
Implementing this interface allows an object to be the target of the enhanced for statement (sometimes called the "for-each loop" statement).

**`Iterable`** is a Java interface that means _“this thing can be iterated over.”_  
If a class implements `Iterable`, you can loop through it with a **for-each loop**.

At its core, `Iterable<T>` has **one job**: provide an `Iterator<T>`.

```java
public interface Iterable<T> {
    Iterator<T> iterator();
}
```

That’s it. No magic. Just a promise.

What this unlocks:

```java
for (T item : iterableObject) {
    // do stuff
}
```

Under the hood, Java quietly does:

```java
Iterator<T> it = iterableObject.iterator();
while (it.hasNext()) {
    T item = it.next();
}
```

Key distinctions (important, often confused):

- **Iterable** → _can be iterated_
    
- **Iterator** → _does the actual walking_
    
- **Collection** → extends `Iterable` (so all collections are iterable)
    
- **Stream** → not `Iterable` (single-use, different philosophy)
    

Why it exists philosophically:  
`Iterable` separates **data structure** from **traversal logic**. The object owns its data; the iterator owns the movement. Clean, boring, powerful.

---

# Iterator

**`Iterator`** is the little machine that _walks through_ a collection, one element at a time.  
If `Iterable` says _“you may walk here”_, `Iterator` is the legs.

Core definition:

```java
public interface Iterator<E> {
    boolean hasNext();
    E next();
    default void remove();
}
```

How iteration actually happens:

```java
Iterator<String> it = list.iterator();

while (it.hasNext()) {
    String value = it.next();
}
```

That’s the real loop. The `for-each` syntax just hides this machinery.

What each method truly means:

- `hasNext()` → _Is there another element?_
    
- `next()` → _Give me the next element and move forward_
    
- `remove()` → _Remove the last returned element_ (optional, not always supported)
    

Important truths (people mess these up):

- Calling `next()` **without** `hasNext()` risks `NoSuchElementException`
    
- You must call `next()` **before** `remove()`
    
- `Iterator` is **one-way** (no going back)
    
- Structural modification outside the iterator → **ConcurrentModificationException**
    

Iterator vs friends:

- `Iterator` → forward-only
    
- `ListIterator` → forward + backward (lists only)
    
- `Enumeration` → ancient, ignore unless maintaining fossils
    

Why this design exists:  
It enforces **safe traversal** while allowing collections to change themselves correctly. Java would rather crash loudly than let silent corruption happen. Good instinct.

Mental model:  
Collection = bookshelf  
Iterator = your finger moving book by book  
Changing the shelf while the finger moves = Java slaps your hand

---

### Methods

The **`Iterator`** interface in Java is used to traverse collections, one element at a time. It provides a way to loop through elements without exposing the underlying structure. Here’s a breakdown of its methods:

---

### **1. Core Methods**

1. **`boolean hasNext()`**
    
    - Returns `true` if there are more elements to iterate over.
        
    - Example:
        
        ```java
        Iterator<String> it = list.iterator();
        while (it.hasNext()) {
            System.out.println(it.next());
        }
        ```
        
2. **`E next()`**
    
    - Returns the next element in the iteration.
        
    - Throws `NoSuchElementException` if no more elements are available.
        
3. **`void remove()`**
    
    - Removes the last element returned by `next()` from the underlying collection.
        
    - Can only be called once per call to `next()`.
        
    - Throws `IllegalStateException` if `next()` hasn’t been called yet.
        

---

### **4. Java 8+ Default Methods**

`Iterator` got a few new default methods in Java 8:

1. **`forEachRemaining(Consumer<? super E> action)`**
    
    - Performs the given action on each remaining element until all are processed or an exception occurs.
        
    - Example:
        
        ```java
        iterator.forEachRemaining(System.out::println);
        ```
        

---

**Summary Table:**

|Method|Purpose|
|---|---|
|`hasNext()`|Checks if more elements exist|
|`next()`|Returns the next element|
|`remove()`|Removes last returned element|
|`forEachRemaining()`|Performs an action on remaining elements|

---


###### Tags : [[1 - Collection interface 🤑]]