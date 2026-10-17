
# **1. What QuickSort _is_**

QuickSort is a **divide-and-conquer sorting algorithm** that sorts an array by:

1. Picking a **pivot** element.
    
2. **Partitioning** the array — putting smaller elements on the left, larger on the right.
    
3. Recursively sorting the left and right parts.
    

It’s fast, elegant, and widely used.

![[Pasted image 20251207081617.png]]

---

# **2. Core Components**

### **a) Pivot**

The pivot is the element used to split the array. Common choices:

- First element
    
- Last element
    
- Middle element
    
- Random element _(best in practice)_
    
- Median-of-three _(last + first + middle)_
    

### **b) Partition**

Partitioning rearranges the array so:

```
left side  <= pivot
pivot
right side >= pivot
```

Two famous partition methods:

- **Lomuto partition** (simple)
    
- **Hoare partition** (faster in practice)
    

---

# **3. Full Example (Lomuto method)**

Array:

```
[10, 7, 8, 9, 1, 5]
```

Pivot = last element = `5`

Partitioning steps:

- Compare each element with pivot
    
- Move smaller elements left
    

Result after partition:

```
[1, 5, 10, 7, 8, 9]
     ^
   pivot index = 1
```

Now recursively sort:

- Left: `[1]` → already sorted
    
- Right: `[10, 7, 8, 9]`  
    → pick pivot  
    → partition  
    → recurse  
    … until done.
    

---

# **4. Methods (One by One, Professional Explanation)**

### **partition(arr, low, high) — Lomuto**

```java
int partition(int[] arr, int low, int high) {
    int pivot = arr[high];   // choose last element
    int i = low - 1;

    for (int j = low; j < high; j++) {
        if (arr[j] <= pivot) {
            i++;
            swap(arr, i, j);
        }
    }

    swap(arr, i + 1, high);
    return i + 1;
}
```

### **quicksort(arr, low, high)**

```java
void quickSort(int[] arr, int low, int high) {
    if (low < high) {
        int pivotIndex = partition(arr, low, high);
        quickSort(arr, low, pivotIndex - 1);
        quickSort(arr, pivotIndex + 1, high);
    }
}
```

---

# **5. Advanced / Internal Behavior**

### **Time Complexity**

- **Best/Average:** O(n log n)
    
- **Worst (bad pivot):** O(n²)
    

Why?  
Because bad pivot splits like:

```
[everything] [nothing]
```

Recursive stack gets deep → quadratic.

### **Why QuickSort is fast in real world?**

- Amazing **cache locality**
    
- In-place (low memory usage)
    
- Partitioning is simple pointer arithmetic
    
- Median/random pivot avoids worst case
    

### **Tail-call elimination**

Good implementations recurse on smaller side first to reduce stack depth.

---

# **6. Full Working Java Code (clean + correct)**

```java
public class QuickSort {
    public static void main(String[] args) {
        int[] arr = {10, 7, 8, 9, 1, 5};
        quickSort(arr, 0, arr.length - 1);

        for (int x : arr) System.out.print(x + " ");
    }

    static void quickSort(int[] arr, int low, int high) {
        if (low < high) {
            int pi = partition(arr, low, high);
            quickSort(arr, low, pi - 1);
            quickSort(arr, pi + 1, high);
        }
    }

    static int partition(int[] arr, int low, int high) {
        int pivot = arr[high];
        int i = low - 1;

        for (int j = low; j < high; j++) {
            if (arr[j] <= pivot) {
                i++;
                swap(arr, i, j);
            }
        }

        swap(arr, i + 1, high);
        return i + 1;
    }

    static void swap(int[] arr, int a, int b) {
        int t = arr[a];
        arr[a] = arr[b];
        arr[b] = t;
    }
}
```



###### Tags : [[1 - DSA 🥭]]