# **What is an Array?**

An **array** is a **fixed-size**, **contiguous block of memory** that stores elements of the **same type**.

This is one of the simplest and fastest data structures.

---

# **1. Definition**

An array gives you:

- **Direct indexing** (random access)
    
- **O(1) read time**
    
- **Fixed length**
    
- **Continuous memory**
    

Example in Java:

```java
int[] nums = new int[5];
```

Memory layout is like:

```
| 0 | 0 | 0 | 0 | 0 |
```

Each slot is next to the other.

---

# **2. How indexing actually works (important)**

If the base address = `X`

Accessing `nums[i]` =

```
X + (i * size_of_element)
```

That's why it's **O(1)** — pure math, no traversal.


![[Pasted image 20251202083943.png]]


---

# **3. Components of an Array**

### **Index**

Starts from 0.

### **Size**

Fixed at creation time.

### **Elements**

Must all be the same type in static languages (Java, C).

---

# **4. Pros and Cons**

### ✔ **Pros**

- Very fast lookups: O(1)
    
- Memory efficient
    
- Ordered
    
- Good CPU cache locality (huge speed boost)
    

### ✘ **Cons**

- Fixed size
    
- Inserting in the middle is expensive (O(n))
    
- Deleting is expensive (O(n))
    
- Growing requires copying (in dynamic arrays)
    

---

# **5. Operations & Big-O**

|Operation|Time|
|---|---|
|Read by index|O(1)|
|Write by index|O(1)|
|Insert at end|O(1)* amortized|
|Insert at start|O(n)|
|Delete middle|O(n)|
|Search|O(n) unless sorted|

* For normal arrays. For ArrayList, it’s amortized O(1) because resizing occasionally copies everything.

---

# **6. Arrays vs ArrayList (important)**

### **Array**

- Low-level
    
- Fixed size
    
- Faster
    
- Manual resizing
    
- Primitive-friendly (`int[]`, `double[]`)
    

### **ArrayList**

- Built on top of an array
    
- Resizes automatically
    
- Stores objects (`Integer`, not `int`)
    
- Easier to work with
    

Example:

```java
ArrayList<Integer> list = new ArrayList<>();
```

Internally this is just:

```java
Object[] elementData;
```

---

# **7. Java Example**

```java
int[] arr = {10, 20, 30};

System.out.println(arr[1]); // 20

arr[1] = 99;

System.out.println(arr[1]); // 99
```

---

# **8. Real-world uses of arrays**

- All Java lists use arrays internally (ArrayList, etc.)
    
- JVM stores bytecode & constants in arrays
    
- Strings use char arrays internally (until Java 9 changed to byte[])
    

Most data structures are built _on_ arrays.

---


###### Tags : [[1 - DSA 🥭]]