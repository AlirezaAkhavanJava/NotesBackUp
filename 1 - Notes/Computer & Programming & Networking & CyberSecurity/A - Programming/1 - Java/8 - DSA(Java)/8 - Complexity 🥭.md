

# **1. Time Complexity**

Time complexity measures **how the runtime of an algorithm grows** as the input size (**n**) increases.

It does NOT measure actual seconds.  
It measures **growth rate**.

### Example:

- O(1) → constant time
    
- O(log n) → logarithmic
    
- O(n) → linear
    
- O(n log n)
    
- O(n²)
    
- O(2ⁿ)
    
- O(n!)
    

### Why it matters:

You predict if your code will **scale** or **die under load**.

---

# **2. Space Complexity**

Space complexity measures **how much extra memory an algorithm uses**, relative to input size.

Includes:

- Variables
    
- Data structures created
    
- Recursion stack
    
- Buffers
    

### Example:

- O(1) → constant memory
    
- O(n) → memory grows linearly with input
    
- O(n²) → huge memory usage
    

### Why it matters:

In backend and low-level systems, memory determines:

- performance
    
- how many requests you can handle
    
- if your service crashes or not
    

---

# **3. Simple Example (searching an array)**

### **Linear Search**

```java
int find(int[] arr, int target) {
    for (int i : arr)
        if (i == target) return i;
    return -1;
}
```

### **Time Complexity**

O(n)  
— you might scan the whole array

### **Space Complexity**

O(1)  
— uses one variable, no extra memory

---

# **4. Another Example (recursion)**

### Example: factorial

```java
int fact(int n) {
    if (n == 1) return 1;
    return n * fact(n - 1);
}
```

### **Time Complexity**

O(n)

### **Space Complexity**

O(n)  
— recursion stack frames add up

---

# **5. Big-O Rules (you must memorize these)**

### **Rule 1: Drop constants**

O(2n) → O(n)  
O(n + 10) → O(n)

### **Rule 2: Worst case dominates**

O(n² + n) → O(n²)

### **Rule 3: Loops multiply**

```java
for (...)         // n
  for (...)       // n
    → O(n²)
```

### **Rule 4: Sequential operations add**

```java
loop → O(n)
loop → O(n)
total → O(n + n) = O(n)
```

### **Rule 5: Divide & conquer reduces time**

Example: binary search  
Each step cuts data in half → O(log n)

---

# **6. Real-World Backend Examples**

### **1. HashMap lookup**

Time: O(1) average  
Space: O(n)

### **2. Sorting a large list**

Time: O(n log n)  
Space: depends on algorithm (merge sort uses O(n), heapsort uses O(1))

### **3. BFS (graph)**

Time: O(V + E)  
Space: O(V) (queue + visited)

### **4. Spring Boot request handling**

Thread pool → queue → scheduling  
Algorithms everywhere.

---


###### Tags : [[1 - DSA 🥭]]