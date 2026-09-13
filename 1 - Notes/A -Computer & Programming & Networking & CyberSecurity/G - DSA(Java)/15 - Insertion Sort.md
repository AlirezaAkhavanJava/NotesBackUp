

# **1. Definition**

**Insertion Sort** builds the final sorted array one element at a time.  
At each step, it **takes the next element** and **inserts** it into the correct position among the already-sorted part on the left.

Conceptually:  
**Left side = sorted**  
**Right side = unsorted**  
You pull items from the right and insert them into the left in the right place.


![[Pasted image 20251207080756.png]]

---

# **2. Core Components**

### **a. Key Element**

The element we want to insert into the sorted region.

### **b. Shifting**

Instead of swapping, Insertion Sort **shifts** larger elements to the right to make room.

### **c. Sorted Region Growth**

The sorted section grows by one each iteration.

---

# **3. Example**

Sort: `[7, 3, 5, 2]`

### **i = 1 → key = 3**

Sorted side: `[7]`  
Compare 3 with 7 → shift 7 → `[7, 7, 5, 2]`  
Insert 3 → `[3, 7, 5, 2]`

### **i = 2 → key = 5**

Sorted side: `[3, 7]`  
Compare 5 with 7 → shift 7 → `[3, 7, 7, 2]`  
Insert 5 → `[3, 5, 7, 2]`

### **i = 3 → key = 2**

Sorted side: `[3, 5, 7]`  
Compare 2 with 7 → shift  
Compare 2 with 5 → shift  
Compare 2 with 3 → shift  
Insert 2 → `[2, 3, 5, 7]`

Final: `[2, 3, 5, 7]`

---

# **4. Algorithm Workflow (Step by Step)**

1. Loop `i` from 1 to n−1
    
2. `key = arr[i]`
    
3. Compare `key` with elements to the left
    
4. Shift all larger elements one step right
    
5. Insert `key` into the hole created
    
6. Move to next element
    

---

# **5. Time & Space Complexity**

### **Time Complexity**

- Worst: **O(n²)**
    
- Average: **O(n²)**
    
- Best: **O(n)** when the array is already nearly sorted
    

### **Space**

- **O(1)** (in-place)
    

### **Why best = O(n)?**

Because each element only needs one comparison — no shifts.

---

# **6. Java Implementation (clean + correct)**

```java
public class InsertionSort {
    public static void insertionSort(int[] arr) {
        int n = arr.length;

        for (int i = 1; i < n; i++) {
            int key = arr[i];
            int j = i - 1;

            // Shift elements to the right
            while (j >= 0 && arr[j] > key) {
                arr[j + 1] = arr[j];
                j--;
            }

            // Insert key
            arr[j + 1] = key;
        }
    }
}
```

---

# **7. Advanced Professional Notes**

### ✔ Stable?

Yes — equal elements keep order because we only shift > key, not >= key.

### ✔ Faster than Bubble & Selection?

Usually **yes**, especially when:

- Data is almost sorted
    
- Small datasets
    
- Incremental updates (like inserting new items into an already-sorted array)
    

### ✔ Used in real systems?

Indirectly, yes:

- Merge Sort + Insertion Sort hybrid in Java’s TimSort
    
- QuickSort uses insertion sort when recursion reaches small partitions
    

Reason: Insertion Sort is **super fast on small or nearly sorted arrays**.

---



###### Tags : [[1 - DSA 🥭]]