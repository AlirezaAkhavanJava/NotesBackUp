

**Bubble Sort – Definition**

**Bubble Sort** is a simple, comparison-based sorting algorithm that repeatedly steps through the list, compares adjacent elements, and swaps them if they are in the wrong order. The process repeats until no more swaps are needed, which means the list is fully sorted.

> The name "bubble sort" comes from the way larger (or smaller) elements gradually **bubble up** to their correct position at the end of the array with each pass — just like bubbles rising to the surface.

### How it works (step by step)
1. Start from the beginning of the array.
2. Compare each pair of adjacent elements.
3. If they are in the wrong order → swap them.
4. Move one position forward and repeat.
5. After one full pass, the largest (or smallest) element is guaranteed to be at the end.
6. Repeat the process for the remaining unsorted portion (n-1 elements, then n-2, etc.).
7. Stop when a pass completes with no swaps (optimized version) or after n-1 passes.

### Key Characteristics
| Property                  | Value                              |
|---------------------------|------------------------------------|
| Time Complexity (Worst/Average) | **O(n²)**                        |
| Time Complexity (Best)    | **O(n)** – only with optimization  |
| Space Complexity          | **O(1)** – in-place algorithm      |
| Stable?                   | Yes                                |
| Adaptive?                 | Yes (can be made O(n) when nearly sorted) |
| Best for                  | Small arrays or educational purposes |

### Example
```
Original: [64, 34, 25, 12, 22, 11, 90]

After Pass 1: [34, 25, 12, 22, 11, 64, 90]  ← 90 bubbled to end
After Pass 2: [25, 12, 22, 11, 34, 64, 90]  ← 64 bubbled
...
Final:        [11, 12, 22, 25, 34, 64, 90]
```

In short: **Bubble Sort is easy to understand and implement, but very slow for large datasets.** It's mainly used for learning or when the input is almost already sorted (with the optimized version).


###### Tags : [[1 - DSA 🥭]]