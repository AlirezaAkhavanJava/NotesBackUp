
A **sorted array** is simply an array where the elements are arranged in **increasing or decreasing order**.

Example (ascending):

```
[1, 3, 5, 7, 9]
```

Example (descending):

```
[9, 7, 5, 3, 1]
```

That’s all — but the consequences are **huge** in algorithms.

---

# **1. Why sorted arrays matter**

Once an array is sorted:

### ✔ Searching becomes much faster

You can use **Binary Search** → O(log n)

### ✔ Many algorithms become possible

- Merge Sort
    
- Two-pointer technique
    
- Binary search variations
    
- Efficient duplicate removal
    
- Efficient range queries
    

### ✔ Less work to detect patterns

Easier to:

- find min/max
    
- find duplicates
    
- find missing numbers
    
- do frequency analysis
    

---

# **2. Example of Binary Search on sorted array**

```java
int binarySearch(int[] arr, int target) {
    int left = 0, right = arr.length - 1;

    while (left <= right) {
        int mid = (left + right) / 2;

        if (arr[mid] == target) return mid;
        else if (arr[mid] < target) left = mid + 1;
        else right = mid - 1;
    }
    return -1;
}
```

### Time complexity:

- **O(log n)** because the array is sorted.
    

---

# **3. Insertions are expensive**

If you want to insert into the correct place:

- You shift elements → **O(n)**
    

Example:

```
[1, 3, 4, 8]
Insert 5 → shifts 8 → O(n)
```

---

# **4. Deletions are expensive**

Removing element also shifts → **O(n)**.

---

# **5. When sorted arrays are used in real systems**

- Database indexes (B-trees)
    
- Search engines
    
- Caches
    
- Binary search utilities
    
- Merging sorted logs
    
- Time-series data
    
- Leaderboards
    

---

# **6. Summary**

✔ Sorted array → ordered  
✔ Enables binary search (O(log n))  
✔ Great for reading/searching  
✘ Bad for insert/delete operations



###### Tags : [[1 - DSA 🥭]]