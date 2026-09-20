

# **What is an ADT?**

**ADT = Abstract Data Type**

**Definition:**  
An ADT defines **what a data structure should do**, _not how it is implemented_.

It focuses on:

- The **operations**
    
- The **behavior**
    
- The **rules**
    

NOT on:

- Memory layout
    
- Implementation details
    
- Specific algorithms inside
    

---

# **1. Clean Explanation**

An ADT is like the **contract** or **specification**.

Example:  
A **Stack ADT** says:

- `push(x)`
    
- `pop()`
    
- `peek()`
    
- **LIFO** rule
    

But it does NOT say:

- Should we use an array?
    
- Or a linked list?
    
- Or some dynamic buffer?
    

That part is the _data structure implementation_.

---

# **2. ADT vs Data Structure (important difference)**

|ADT|Data Structure|
|---|---|
|Defines **behavior**|Provides **actual implementation**|
|"What it does"|"How it does it"|
|Example: Stack ADT|Example: Stack implemented with array|
|Language-independent|Language-specific code|

This separation is what lets you switch implementations easily.

---

# **3. Examples of ADTs**

Here are the major ADTs you must know:

### **Stack ADT**

- push(x)
    
- pop()
    
- peek()
    
- isEmpty()
    

### **Queue ADT**

- enqueue(x)
    
- dequeue()
    
- front()
    

### **List ADT**

- add(x)
    
- remove(i)
    
- get(i)
    

### **Map/Dictionary ADT**

- put(key, value)
    
- get(key)
    
- remove(key)
    

### **Set ADT**

- add(x)
    
- remove(x)
    
- contains(x)
    

These are **pure behaviors**, not storage methods.

---

# **4. Example with Java**

Java interfaces express ADTs well:

```java
public interface StackADT<T> {
    void push(T item);
    T pop();
    T peek();
    boolean isEmpty();
}
```

This is the **ADT**.

You can implement it with:

### Option A — Array

```java
class ArrayStack<T> implements StackADT<T> { ... }
```

### Option B — Linked List

```java
class LinkedListStack<T> implements StackADT<T> { ... }
```

Same ADT → different data structure → same behavior for the user.

---

# **5. Why ADTs matter (real truth)**

If you understand ADTs, you will:

- Understand DSA deeply
    
- Write cleaner abstractions
    
- Structure your code professionally
    
- Understand how Java Collections are designed
    
- Build frameworks and reusable components easier
    

It's foundational for **Spring**, **DB drivers**, **caches**, everything.

###### Tags : [[1 - DSA 🥭]]