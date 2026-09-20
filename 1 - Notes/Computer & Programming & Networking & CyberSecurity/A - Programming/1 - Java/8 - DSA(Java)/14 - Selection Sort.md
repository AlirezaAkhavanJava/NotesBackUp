


# **1. Definition**

**Selection Sort** is a simple sorting algorithm that repeatedly finds the **minimum element** from the unsorted part of the array and places it at its correct position at the beginning.

Core idea:  
**Find the smallest → put it in front → shrink the unsorted region.**

![[Pasted image 20251206083159.png]]

---

# **2. Core Components**

### **a. Minimum Search**

Scan the remaining unsorted portion to find the smallest value.

### **b. Swap**

Swap the smallest element with the first element of the unsorted region.

### **c. Unsorted Region Shrinks**

After each iteration, the sorted portion grows by 1 from the left.

---

# **3. Example**

Sort: `[7, 3, 5, 2]`

### **Pass 1: i = 0**

- Scan `[7, 3, 5, 2]` → min is **2** at index 3
    
- Swap with index 0  
    → `[2, 3, 5, 7]`
    

### **Pass 2: i = 1**

- Scan `[3, 5, 7]` → min is **3** at index 1
    
- Already in place → no swap
    

### **Pass 3: i = 2**

- Scan `[5, 7]` → min is **5**  
    → no swap
    

### **Pass 4: i = 3**

- Only one element left → done
    

Final result: `[2, 3, 5, 7]`

---

# **4. Algorithm Workflow (Step by Step)**

1. Loop `i` from 0 to `n-1`
    
2. Set `minIndex = i`
    
3. Loop `j` from `i+1` to `n-1`
    
    - If `arr[j] < arr[minIndex]`, update `minIndex = j`
        
4. After inner loop finishes:
    
    - If `minIndex != i`, swap `arr[i]` and `arr[minIndex]`
        
5. Sorted region grows at the front
    

---

# **5. Time & Space Complexity**

### **Time**

- Worst: **O(n²)**
    
- Average: **O(n²)**
    
- Best: **O(n²)** (even if already sorted — still must scan)
    

### **Space**

- **O(1)** (in-place)
    

---

# **6. Java Implementation (clean and correct)**

```java
public class SelectionSort {
    public static void selectionSort(int[] arr) {
        int n = arr.length;

        for (int i = 0; i < n - 1; i++) {
            int minIndex = i;

            // Find the smallest element in the unsorted part
            for (int j = i + 1; j < n; j++) {
                if (arr[j] < arr[minIndex]) {
                    minIndex = j;
                }
            }

            // Swap if needed
            if (minIndex != i) {
                int temp = arr[i];
                arr[i] = arr[minIndex];
                arr[minIndex] = temp;
            }
        }
    }
}
```

---

# **7. Advanced Professional Notes**

### ✔ Stable?

**No.**  
Selection sort is not stable by default because swapping may reorder equal elements.

### ✔ In-place?

Yes — only constant memory.

### ✔ Better than Bubble Sort?

In general, **yes**:

- Bubble Sort can do up to ~n² swaps
    
- Selection Sort does at most **n swaps**, so it's faster on hardware where swaps are expensive
    

### ✔ When useful?

- Very small arrays
    
- Situations where **memory writes must be minimized**
    
- Teaching basic sorting concepts
    

---


###### Tags : [[1 - DSA 🥭]]