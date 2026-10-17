
# ✅ **1. What Merge Sort _Is_**

**Merge Sort** is a **Divide and Conquer** sorting algorithm.

- It **divides** the array into halves until each piece has 1 element.
    
- Then it **merges** those pieces back in sorted order.
    

It is **stable**, **uses extra memory**, and gives **O(n log n)** performance every time — best, average, worst.

![[Pasted image 20251211080749.png]]

---

# ✅ **2. Core Components**

Merge sort has two major operations:

### **A) Divide**

Split the array into two halves:

- left = arr[0…mid]
    
- right = arr[mid+1…end]
    

### **B) Merge**

Combine two sorted arrays into one sorted array by comparing elements one by one.

---

# ✅ **3. Visual Example (Step-by-step)**

Sort: `[8, 3, 5, 4, 7, 6, 1, 2]`

### **Divide Phase**

```
[8 3 5 4 7 6 1 2]
         |
   ---------------
   |             |
[8 3 5 4]     [7 6 1 2]

[8 3] [5 4]   [7 6] [1 2]

[8] [3] [5] [4] [7] [6] [1] [2]
```

### **Merge Phase**

```
[8] + [3] -> [3 8]
[5] + [4] -> [4 5]
[7] + [6] -> [6 7]
[1] + [2] -> [1 2]

Now merge again:
[3 8] + [4 5] -> [3 4 5 8]
[6 7] + [1 2] -> [1 2 6 7]

Finally:
[3 4 5 8] + [1 2 6 7]
= [1 2 3 4 5 6 7 8]
```

---

# ✅ **4. Merge Sort Workflow (Algorithm)**

### **Function: mergeSort(arr)**

1. If array length ≤ 1: return it
    
2. Find midpoint
    
3. Divide → left = mergeSort(left), right = mergeSort(right)
    
4. Merge left + right
    
5. Return merged array
    

### **Function: merge(left, right)**

1. Create empty output array
    
2. Use two pointers: i (left), j (right)
    
3. Compare left[i] and right[j]
    
4. Push smaller into output
    
5. Move pointer forward
    
6. Append remaining elements
    
7. Return output
    

---

# ✅ **5. Java Example (Clean + DSA style)**

### **merge sort**

```java
public void mergeSort(int[] arr) {
    if (arr.length <= 1) return;

    int mid = arr.length / 2;
    int[] left = Arrays.copyOfRange(arr, 0, mid);
    int[] right = Arrays.copyOfRange(arr, mid, arr.length);

    mergeSort(left);
    mergeSort(right);

    merge(arr, left, right);
}
```

### **merge operation**

```java
private void merge(int[] arr, int[] left, int[] right) {
    int i = 0, j = 0, k = 0;

    while (i < left.length && j < right.length) {
        if (left[i] <= right[j]) {
            arr[k++] = left[i++];
        } else {
            arr[k++] = right[j++];
        }
    }

    while (i < left.length) arr[k++] = left[i++];
    while (j < right.length) arr[k++] = right[j++];
}
```

---

# ✅ **6. Time & Space Complexity**

|Case|Time|
|---|---|
|Best|O(n log n)|
|Average|O(n log n)|
|Worst|O(n log n)|

### **Space Complexity: O(n)**

Because merge needs extra arrays.

---

# ✅ **7. Professional/Advanced Notes**

- **Stable:** yes
    
- **Out-of-place:** yes
    
- **Good for linked lists:** no extra memory needed; merge is cheap
    
- **Bad for memory-restricted systems** due to O(n) extra space
    
- **Merge Sort is used internally in Java for Object arrays (TimSort)**, not for primitives.
    

---


##### Tags : [[1 - DSA 🥭]]