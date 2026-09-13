
Date : 2025-09-04


This document explains **arrays** and **multi-dimensional arrays** in Java with examples.

---

## 1. Arrays in Java

### Characteristics

- Fixed-size data structure.
    
- Stores elements of the **same type**.
    
- Index starts from `0`.
    
- Can be **primitive** or **reference types**.
    

### Declaration

```java
int[] arr1;         // preferred
int arr2[];         // valid but less common
```

### Initialization

```java
arr1 = new int[5];              // size 5, default 0
int[] arr3 = {1, 2, 3, 4, 5};   // inline initialization
```

### Accessing Elements

```java
arr3[0] = 10;       // assign
System.out.println(arr3[0]); // 10
```

### Iterating

```java
// Traditional for-loop
for (int i = 0; i < arr3.length; i++) {
    System.out.println(arr3[i]);
}

// Enhanced for-loop
for (int val : arr3) {
    System.out.println(val);
}
```

### Common Operations

- `Arrays.toString(arr)` → Convert to string.
    
- `Arrays.sort(arr)` → Sort array.
    
- `Arrays.copyOf(arr, newLength)` → Copy array.
    
- `Arrays.equals(arr1, arr2)` → Compare arrays.
    

---

## 2. Multi-Dimensional Arrays

### 2D Array Declaration

```java
int[][] matrix = new int[3][3];
int[][] matrix2 = { {1, 2, 3}, {4, 5, 6}, {7, 8, 9} };
```

### Accessing Elements

```java
matrix[0][1] = 10;
System.out.println(matrix2[1][2]); // 6
```

### Iterating 2D Arrays

```java
for (int i = 0; i < matrix2.length; i++) {
    for (int j = 0; j < matrix2[i].length; j++) {
        System.out.print(matrix2[i][j] + " ");
    }
    System.out.println();
}
```

### Jagged Arrays

- Arrays with rows of **different lengths**.
    

```java
int[][] jagged = new int[3][];
jagged[0] = new int[2];
jagged[1] = new int[4];
jagged[2] = new int[3];
```

---

## 3. Common Methods from `Arrays` Class

```java
import java.util.Arrays;

Arrays.sort(arr);                // Sort
Arrays.binarySearch(arr, key);   // Search
Arrays.fill(arr, 0);             // Fill
Arrays.equals(arr1, arr2);       // Compare
Arrays.copyOf(arr, newLength);   // Copy
```

---

## Summary

- **Array** → fixed-size, same-type elements.
    
- **Multi-dimensional array** → arrays of arrays (2D, 3D, etc.).
    
- **Jagged arrays** → rows with different lengths.
    
- Use **`Arrays` utility class** for common operations.


##### *Tags : [[Java]]