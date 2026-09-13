
### **Binary Search**

- **Definition:** A search algorithm used on **sorted arrays** that repeatedly divides the search space in half to find the target element.
    
- **Requirement:** The array **must be sorted**.
    
![[Pasted image 20251202084754.png]]

---

### **How it works (Step by Step):**

1. Take the **middle element** of the array.
    
2. If it equals the target → **found**.
    
3. If the target is smaller → search in the **left half**.
    
4. If the target is larger → search in the **right half**.
    
5. Repeat until found or the search space is empty.
    

---

### **Example:**

Array: `[2, 4, 6, 8, 10, 12]`, Target: `8`

1. Middle element → `6` (index 2)  
    `8 > 6` → search right half `[8, 10, 12]`
    
2. Middle element → `10` (index 4)  
    `8 < 10` → search left half `[8]`
    
3. Middle element → `8` → **found!**
    

---

### **Complexity**

- **Time Complexity:** O(log n) ✅ (much faster than linear search for large arrays)
    
- **Space Complexity:**
    
    - Iterative → O(1)
        
    - Recursive → O(log n) (due to recursion stack)
        

---


###### Tags : [[1 - DSA 🥭]]