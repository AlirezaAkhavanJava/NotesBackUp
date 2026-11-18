

Big O notation is how we describe the growth rate of an algorithm's running time or memory use as the input size gets larger. It doesn't measure wall-clock seconds — it measures how the cost _scales_. When you say an algorithm is O(n), you're saying: if the input doubles, the work roughly doubles too. When you say O(n²), doubling the input roughly quadruples the work. Big O ignores hardware speed, constant factors, and small inputs, and focuses purely on the shape of the curve as n → ∞.

The reason this matters in practice: two algorithms might both "work" on a test case of 10 items, but one scales fine to 10 million items and the other grinds to a halt. Big O is the tool that lets you predict which is which _before_ you run it on real data.


### The core idea: upper bound on growth

Formally, O(g(n)) means "this function's growth is bounded above by g(n), for large enough n, ignoring constants." If an algorithm does `3n + 7` operations, we say it's O(n) — we drop the constant `3` and the `+7`, because as n grows huge, those stop mattering. If it does `n² + 100n`, we say O(n²), because the n² term dominates once n is large enough.

```java
void printAll(int[] arr) {       // O(n)
    for (int x : arr) {
        System.out.println(x);
    }
}

void printAllPairs(int[] arr) {  // O(n²)
    for (int x : arr) {
        for (int y : arr) {
            System.out.println(x + ", " + y);
        }
    }
}
```

`printAll` does one pass — n operations. `printAllPairs` does a pass inside a pass — n operations for every one of n outer iterations, so n × n = n². Doubling the array size doubles the first method's work and quadruples the second's.

### The common growth rates, smallest to largest

These are the ones you'll see constantly, so it's worth knowing them by name and by shape:

- **O(1) — constant.** Same cost no matter how big the input is.
- **O(log n) — logarithmic.** Cost grows very slowly; each doubling of input adds roughly one fixed unit of work.
- **O(n) — linear.** Cost grows directly with input size.
- **O(n log n) — linearithmic.** Slightly worse than linear; typical of efficient sorting.
- **O(n²) — quadratic.** Cost grows with the square of input size; typical of naive nested loops.
- **O(2ⁿ) — exponential.** Cost doubles with every additional input element; gets unusable fast.

```java
int getFirst(int[] arr) {                 // O(1)
    return arr[0];
}

int binarySearch(int[] sortedArr, int target) {  // O(log n)
    int lo = 0, hi = sortedArr.length - 1;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (sortedArr[mid] == target) return mid;
        if (sortedArr[mid] < target) lo = mid + 1;
        else hi = mid - 1;
    }
    return -1;
}
```

`binarySearch` is O(log n) because each iteration throws away half the remaining search space. Starting from, say, 1024 elements, you'd need at most 10 iterations (2¹⁰ = 1024) to narrow down to one — compare that to a linear scan, which could need all 1024.

### Why we drop constants and lower-order terms

Say a function's exact operation count is `5n² + 3n + 20`. As n grows large:

|n|5n² (dominant term)|3n + 20 (rest)|
|---|---|---|
|10|500|50|
|1,000|5,000,000|3,020|
|1,000,000|5,000,000,000,000|3,000,020|

The gap between the dominant term and everything else widens enormously as n grows. By the time n is in the millions, the `3n + 20` part is noise. That's why Big O states only the dominant term: O(n²). This is also why an O(n) algorithm with a big constant factor (say, `100n`) can still be _worse in practice_ for small inputs than an O(n²) one with a tiny constant (`0.01n²`) — but Big O is about the asymptote, the behavior as n keeps growing, not about any one specific n.

### Best, worst, and average case

Big O by itself describes one _scenario_ of an algorithm's behavior — usually people mean the worst case unless stated otherwise, but an algorithm can have different complexities for different cases. Linear search through an array for a target value:

```java
int linearSearch(int[] arr, int target) {
    for (int i = 0; i < arr.length; i++) {
        if (arr[i] == target) return i;
    }
    return -1;
}
```

- **Best case:** the target is `arr[0]` — one comparison, O(1).
- **Worst case:** the target is last, or absent entirely — n comparisons, O(n).
- **Average case:** roughly n/2 comparisons, still O(n) once you drop the constant.

When people quote a single Big O for an algorithm without qualification, they almost always mean the worst case, because that's the guarantee you can actually rely on.

### Space complexity

Everything above was about _time_, but Big O applies the same way to memory. An algorithm that allocates a new array the same size as its input is O(n) space. One that only uses a few variables regardless of input size is O(1) space.

```java
int[] doubleAll(int[] arr) {      // O(n) time, O(n) space — new array of size n
    int[] result = new int[arr.length];
    for (int i = 0; i < arr.length; i++) {
        result[i] = arr[i] * 2;
    }
    return result;
}

void doubleInPlace(int[] arr) {   // O(n) time, O(1) space — no new array
    for (int i = 0; i < arr.length; i++) {
        arr[i] *= 2;
    }
}
```

Both methods are O(n) in time — one pass over n elements either way. But `doubleAll` needs extra memory proportional to the input, while `doubleInPlace` reuses the existing array and needs only a fixed, constant amount of extra space (the loop counter). This time-versus-space trade-off comes up constantly: you can often make something faster by using more memory, or use less memory at the cost of more time.

### A quick note on related notations

Big O (`O`) is the one you'll use 95% of the time, and it describes an _upper bound_ — "at most this bad." There are two siblings worth knowing exist: **Big Omega (`Ω`)**, which describes a _lower bound_ ("at least this good"), and **Big Theta (`Θ`)**, which means the upper and lower bounds match — the algorithm's growth is _tightly_ that rate, both best and worst case behaving the same way. In everyday conversation, when someone says "this is O(n log n)," they often really mean Θ(n log n) — that it's tightly bound at that rate — but they say "Big O" because it's the term everyone defaults to.



[[Java]]