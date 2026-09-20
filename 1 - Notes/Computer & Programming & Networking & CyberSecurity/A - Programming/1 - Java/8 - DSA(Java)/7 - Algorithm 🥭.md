


# **What is an Algorithm?**

An **algorithm** is a **precise, step-by-step procedure** to solve a problem.

It’s not code — it’s the _logic_ that code follows.

### Clean definition:

**Algorithm = finite sequence of well-defined steps that transforms input → output.**

---

# **1. Why Algorithms matter**

Algorithms let you:

- solve problems **efficiently**
    
- reduce **time complexity**
    
- reduce **memory usage**
    
- handle **large-scale data**
    
- write code that scales in production
    

Example:  
Sorting 1,000,000 items with a bad algorithm can take **minutes**.  
With a good algorithm: **milliseconds**.

---

# **2. Components of an Algorithm**

A correct algorithm has:

### ✔ **Input**

Data you start with.

### ✔ **Output**

Result after processing.

### ✔ **Steps**

Clear operations that always end (termination).

### ✔ **Correctness**

Always gives the right answer.

### ✔ **Efficiency**

Measured using **Big-O Notation**.

---

# **3. Examples of algorithms (must-know list)**

### **Sorting**

- Bubble Sort (slow)
    
- Merge Sort (O(n log n))
    
- Quick Sort (fast on average)
    
- Heap Sort
    

### **Searching**

- Linear search
    
- Binary search
    

### **Graph algorithms**

- BFS
    
- DFS
    
- Dijkstra
    
- Bellman-Ford
    
- Kruskal (MST)
    
- Prim (MST)
    

### **Dynamic Programming**

- Fibonacci (DP version)
    
- Knapsack
    
- Longest Common Subsequence
    

### **String algorithms**

- KMP
    
- Rabin-Karp
    

These are standard, need-to-know algorithms.

---

# **4. Small Example (simple algorithm)**

**Problem:** Find the largest number in an array.

### **Algorithm (in plain English):**

1. Assume the first element is the largest.
    
2. Loop through the array.
    
3. If you find a number greater than the current largest, update it.
    
4. After the loop ends, return the largest value.
    

### Implementation (Java):

```java
int findMax(int[] arr) {
    int max = arr[0];

    for (int num : arr) {
        if (num > max) max = num;
    }

    return max;
}
```

This is an algorithm implemented as code.

---

# **5. Big-O and Efficiency**

Algorithms are judged by how they scale.

Examples:

- Binary search → **O(log n)**
    
- Merge sort → **O(n log n)**
    
- Bubble sort → **O(n²)**
    
- BFS/DFS → **O(V + E)**
    
- Dijkstra → **O((V + E) log V)** with a heap
    

Understanding Big-O is crucial.

---

# **6. Real-world algorithm usage (backend)**

### **1. Database indexes**

B-trees, hash maps → algorithms everywhere.

### **2. Routing**

Shortest path → Dijkstra.

### **3. Authentication**

Hashing algorithms (BCrypt, SHA-256).

### **4. Load balancers**

Scheduling algorithms.

### **5. Caches**

Eviction algorithms (LRU, LFU).

### **6. Thread pools**

Task scheduling algorithms.

Basically, all complex backend systems rely on algorithms underneath.

---



###### Tags : [[1 - DSA 🥭]]