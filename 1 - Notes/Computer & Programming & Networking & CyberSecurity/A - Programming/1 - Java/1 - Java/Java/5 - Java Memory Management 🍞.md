Date : 2025-09-04


This document explains the **Java memory model**, JVM memory areas, and the **String pool**.

---

## 1. JVM Memory Areas

When a Java program runs, JVM divides memory into several runtime areas:

### a) Method Area (a.k.a. Metaspace in Java 8+)

- Stores **class structures**: metadata, method bytecode, static variables.
    
- Shared among all threads.
    

### b) Heap

- Stores **objects** and **instance variables**.
    
- Shared among all threads.
    
- Managed by **Garbage Collector (GC)**.
    
- Divided into:
    
    - **Young Generation** → newly created objects.
        
        - Eden Space → new objects.
            
        - Survivor Spaces (S0, S1) → surviving objects from GC.
            
    - **Old Generation (Tenured)** → long-lived objects.
        
![[Pasted image 20260104094354.png]]
### c) Stack

- Each thread has its own stack.
    
- Stores **local variables, method calls, references**.
    
- Last-In-First-Out (LIFO).
    

### d) Program Counter (PC) Register

- Holds the address of the **current instruction** being executed for each thread.
    

### e) Native Method Stack

- Used for native (non-Java, e.g., C/C++) method execution.
    

---

## 2. String Pool

### What is String Pool?

- A special area inside the **Heap (in Method Area before Java 7, Heap after Java 7)**.
    
- Stores **string literals** to save memory.
    
- Example:
    

```java
String s1 = "Hello";
String s2 = "Hello";
System.out.println(s1 == s2); // true (same reference from pool)
```

### String Creation

- **String literal** → stored in pool.
    
- **`new String("Hello")`** → ==creates new object in heap (not pooled).==
    

### Interning

- ==`intern()` method forces a string into the pool.==
    

```java
String s1 = new String("Java");
String s2 = s1.intern();
String s3 = "Java";
System.out.println(s2 == s3); // true
```

---

## 3. Garbage Collection (GC)

- GC automatically removes unused objects from heap.
    
- Uses algorithms like **Mark-Sweep, Copying, Generational GC**.
    
- Finalization before GC is rare (via `finalize()`, now deprecated).
    

---

## 4. Memory Leaks in Java

- Even with GC, memory leaks can occur if:
    
    - Objects are still **referenced but not needed**.
        
    - Example: Large collections holding unused objects.
        

---

## 5. Escape Analysis & Stack Allocation (JIT Optimization)

- JVM can optimize object allocation.
    
- Small, short-lived objects may be allocated on the **stack** instead of the heap.
    

---

## 6. Summary

- **Heap** → Objects & String pool.
    
- **Stack** → Method calls, local variables.
    
- **Method Area** → Class structures, static data.
    
- **PC Register & Native Method Stack** → Low-level execution.
    
- **String Pool** → Avoids duplicate string objects, saves memory.
    

Understanding the memory model is crucial for **performance tuning, avoiding memory leaks, and writing efficient Java applications**.


##### *Tags : [[Java]]