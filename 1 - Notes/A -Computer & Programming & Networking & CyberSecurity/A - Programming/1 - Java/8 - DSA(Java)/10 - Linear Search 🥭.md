

### **1. Definition**

Linear search is the simplest search algorithm. It checks **each element of a list one by one** until it finds the target element or reaches the end of the list.

- **Also called:** Sequential search
    
- **Use case:** Small or unsorted lists
    
![[Pasted image 20251202084805.png]]

---

### **2. How it works (conceptually)**

1. Start from the first element of the array/list.
    
2. Compare it with the target value.
    
3. If it matches → return the position (index).
    
4. If it doesn’t → move to the next element.
    
5. Repeat until the element is found or the list ends.
    

---

### **3. Example (Array)**

Suppose we have:  
`arr = [5, 3, 7, 1, 9]` and we want to find `7`.

- Step 1: Compare `5` → not 7
    
- Step 2: Compare `3` → not 7
    
- Step 3: Compare `7` → **found! index = 2**
    

---

### **4. Pseudocode**

```js
function linearSearch(arr, target):
    for i from 0 to length(arr)-1:
        if arr[i] == target:
            return i
    return -1  // not found

```

---

### **5. Complexity**

- **Time Complexity:**
    
    - Best case: O(1) → element is first
        
    - Worst case: O(n) → element is last or not present
        
    - Average case: O(n/2) ≈ O(n)
        
- **Space Complexity:** O(1) → only variables for iteration
    

---

### **6. Java Example**


```java
public class LinearSearch {
    public static int linearSearch(int[] arr, int target) {
        for (int i = 0; i < arr.length; i++) {
            if (arr[i] == target) {
                return i; // found
            }
        }
        return -1; // not found
    }

    public static void main(String[] args) {
        int[] numbers = {5, 3, 7, 1, 9};
        int target = 7;
        int index = linearSearch(numbers, target);
        System.out.println("Index: " + index); // Output: Index: 2
    }
}

```

---

Linear search is 🐐 **easy to implement** but not efficient for large datasets—there, binary search or hash-based search is better.


###### Tags : [[1 - DSA 🥭]]