



### **1. Definition**

**Big O Notation** is a way to **describe how fast an algorithm grows** as the input size increases.

- It measures **time complexity** (how long it takes) or **space complexity** (how much memory it uses).
    
- Focuses on the **upper bound**—the worst-case scenario.
    

Think of it as:

> “As the input `n` grows, how does the algorithm’s cost grow?”

![[Pasted image 20251203084858.png]]

---

### **2. Why it matters**

- Lets you compare algorithms **without running them**.
    
- Helps pick the **most efficient solution** for large datasets.
    

---

### **3. Common Big O Classes**

|Big O|Name|Growth|Example|
|---|---|---|---|
|O(1)|Constant|Doesn’t depend on input|Accessing `arr[5]`|
|O(log n)|Logarithmic|Grows slowly|Binary search|
|O(n)|Linear|Grows proportionally|Linear search|
|O(n log n)|Linearithmic|Grows faster than linear|Merge sort, Quick sort|
|O(n²)|Quadratic|Grows with square|Bubble sort, nested loops|
|O(2ⁿ)|Exponential|Doubles with each input|Recursive Fibonacci|
|O(n!)|Factorial|Insane growth|Travelling Salesman brute-force|
![[Pasted image 20251203085029.png]]


---

### **4. Examples**

**Linear search:**

- Checks every element → O(n)
    

**Binary search:**

- Halves the search space each step → O(log n)
    

**Bubble sort:**

- Nested loops → O(n²)
    

---

### **5. How to calculate**

- Look at loops:
    
    ```java
    for (int i = 0; i < n; i++) {        // O(n)
        for (int j = 0; j < n; j++) {    // O(n)
            // work
        }
    }
    // Total: O(n*n) = O(n²)
    ```
    
- Ignore constants: O(2n) → O(n)
    
- Keep **largest term only**: O(n² + n) → O(n²)
    

---

### **6. Quick rules**

1. **Nested loops multiply** → O(n*m)
    
2. **Consecutive loops add** → O(n + m)
    
3. **Recursion halves** → often O(log n)
    

---




###### Tags : [[1 - DSA 🥭]]