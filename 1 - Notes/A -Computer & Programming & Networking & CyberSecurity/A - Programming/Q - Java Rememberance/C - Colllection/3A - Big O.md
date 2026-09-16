
# Big O Notation

## Definition

**Big O notation** is a mathematical way of describing **how the performance (time or memory) of an algorithm/operation scales as the size of its input grows** — written as `O(...)`. It doesn't tell you exact running time (seconds, milliseconds) — it tells you the **growth pattern**: if you double the input size, does the work stay the same, double, quadruple, or explode?

You've already seen this notation used throughout the last two tutorials (`O(1)`, `O(n)`, `O(log n)`) without a full explanation — this is that explanation.

---

## Why this exists — the problem it solves

Two algorithms can both "work correctly" but perform wildly differently as data grows. Measuring in actual seconds is misleading — that depends on the specific CPU, current system load, programming language, JIT warmup, and countless other factors that have nothing to do with the algorithm itself.

**Big O solves this by abstracting away hardware/implementation details entirely**, and instead answers one focused question: _as the input size `n` grows toward infinity, how does the amount of work grow?_ This gives you a way to compare algorithms that's independent of any specific machine — a genuinely universal, portable way to reason about performance.

```java
// Both of these "work" — but how do they scale?

boolean containsLinear(List<Integer> list, int target) {
    for (int x : list) {              // check every element, one by one
        if (x == target) return true;
    }
    return false;
}

boolean containsHash(HashSet<Integer> set, int target) {
    return set.contains(target);       // hash lookup — nearly instant regardless of size
}
```

For a list of 10 items, both are basically instant — the difference is invisible. For a list of 10 million items, `containsLinear` might take a noticeable fraction of a second, while `containsHash` is still essentially instant. **Big O is the formal language for predicting and describing that gap before you ever run the code.**

---

## The core idea: `n` and "growth," not literal time

`n` represents the size of the input (number of elements in a list, characters in a string, nodes in a tree — whatever's relevant). Big O describes the relationship between `n` and the number of operations required, **as `n` gets large**.

```
O(1)       → work stays constant, no matter how big n gets
O(log n)    → work grows very slowly as n grows
O(n)         → work grows directly proportional to n
O(n log n)    → work grows a bit faster than proportional
O(n²)          → work grows as the SQUARE of n
O(2ⁿ)             → work doubles with every additional element — explodes fast
```

---

## The common complexity classes, explained one at a time

### `O(1)` — Constant time

The operation takes the **same amount of work regardless of input size**.

```java
int getFirst(int[] arr) {
    return arr[0]; // always exactly one step, whether arr has 10 or 10 million elements
}
```

```java
map.get("key"); // HashMap lookup — O(1) average case
```

**Why:** array indexing computes a direct memory address from the index — no searching involved, so size doesn't matter.

---

### `O(log n)` — Logarithmic time

Work grows **very slowly** — each step eliminates a large portion of the remaining data (typically by half).

```java
// Binary search — repeatedly halves the search space
int binarySearch(int[] sortedArr, int target) {
    int low = 0, high = sortedArr.length - 1;
    while (low <= high) {
        int mid = (low + high) / 2;
        if (sortedArr[mid] == target) return mid;
        else if (sortedArr[mid] < target) low = mid + 1;
        else high = mid - 1;
    }
    return -1;
}
```

**Why `log n`:** for a sorted array of 1,000,000 elements, binary search needs at most **~20 comparisons** (since 2²⁰ ≈ 1,000,000) — doubling the array size to 2,000,000 adds only _one more_ comparison, not thousands more. This is why balanced trees (`TreeMap`/`TreeSet` from the data structures tutorial) offer `O(log n)` search — each step down the tree eliminates roughly half the remaining nodes.

---

### `O(n)` — Linear time

Work grows **directly proportional** to input size — double the input, double the work.

```java
boolean contains(List<Integer> list, int target) {
    for (int x : list) {         // must potentially check EVERY element
        if (x == target) return true;
    }
    return false;
}
```

This is exactly the `LinkedList.get(500000)` example from the data structures tutorial — walking through a linked list to reach a given position requires visiting every node before it, so time grows linearly with position.

---

### `O(n log n)` — Linearithmic time

Slightly worse than linear — typical of efficient, well-designed sorting algorithms.

```java
Collections.sort(list); // typically O(n log n) — e.g., a well-implemented merge sort/Timsort
```

**Why this specific shape:** efficient sorting algorithms generally work by repeatedly splitting the data in half (the `log n` part) and then doing linear-time work at each level of splitting (the `n` part) — combining into `n log n` overall. This is considered the practical "best you can generally do" for comparison-based sorting.

---

### `O(n²)` — Quadratic time

Work grows as the **square** of input size — a nested loop over the same data is the classic cause.

```java
boolean hasDuplicate(int[] arr) {
    for (int i = 0; i < arr.length; i++) {
        for (int j = 0; j < arr.length; j++) {   // nested loop over the SAME array
            if (i != j && arr[i] == arr[j]) return true;
        }
    }
    return false;
}
```

**Why it's dangerous:** doubling the input **quadruples** the work (2² = 4). An array of 1,000 elements needs ~1,000,000 comparisons; an array of 10,000 elements needs ~100,000,000 — this is exactly the kind of algorithm that "works fine in testing" (small data) and then becomes unusably slow in production (real-world data volumes).

---

### `O(2ⁿ)` — Exponential time (and worse)

Work **doubles with every additional element** — becomes unusable extremely quickly, even for modest input sizes.

```java
// Naive recursive Fibonacci — recomputes the same values repeatedly
int fib(int n) {
    if (n <= 1) return n;
    return fib(n - 1) + fib(n - 2); // branches into 2 calls, every single time
}
```

`fib(30)` is slow-ish; `fib(50)` would take an impractically long time — this is the shape where a small increase in input size causes a massive increase in work. Algorithms in this class are generally something you actively try to avoid or redesign (often via a different data structure — caching intermediate results, for instance).

---

## Visual comparison — how badly each scales

```
n = 10          n = 100         n = 1,000        n = 10,000
O(1)      →  1            1              1              1
O(log n)  →  ~3           ~7             ~10            ~13
O(n)      →  10           100            1,000          10,000
O(n log n)→  ~33          ~664           ~9,966         ~132,877
O(n²)     →  100          10,000         1,000,000      100,000,000
O(2ⁿ)     →  1,024        (astronomically large — effectively unusable)
```

This table makes the practical stakes concrete: at small `n`, almost everything is "fast enough" — the differences only become dramatic, and consequential, as `n` grows. This is exactly why performance bugs often only show up in production with real data volumes, not in small-scale testing.

---

## Best case, worst case, average case

Big O is often given for a specific scenario, since some algorithms perform differently depending on the actual arrangement of data, not just its size:

```java
map.get("key"); // O(1) AVERAGE case — but O(n) WORST case
                 // (if many keys hash to the same bucket — rare, but theoretically possible)
```

|Case|Meaning|
|---|---|
|**Best case**|the most favorable scenario (rarely the useful one to focus on)|
|**Average case**|typical, expected performance across realistic inputs|
|**Worst case**|the guaranteed upper bound, no matter how unlucky the input|

**In practice, Big O discussions usually mean worst case unless stated otherwise** — because it's the guarantee you can actually rely on, especially for anything user-facing or security-relevant (where an attacker might deliberately construct a worst-case input).

---

## Why constants and lower-order terms get dropped

```
An algorithm that does 3n + 100 operations is still just O(n) — NOT O(3n + 100)
```

**Why:** Big O describes the **growth trend**, not an exact operation count. As `n` gets sufficiently large, constants (`3`, `100`) become irrelevant compared to how `n` itself grows — an `O(n)` algorithm will always eventually outperform an `O(n²)` algorithm as `n` grows large enough, regardless of what constants are attached to either. This is also why `O(2n)` and `O(n)` are considered the "same" complexity class — both describe linear growth.

---

## Applying this directly to what you've already learned

|Structure/Operation|Big O|Why|
|---|---|---|
|`ArrayList.get(index)`|`O(1)`|direct memory address calculation|
|`ArrayList.add(0, x)` (insert at front)|`O(n)`|must shift every existing element over|
|`LinkedList.get(index)`|`O(n)`|must walk node-by-node from the start|
|`LinkedList.addFirst(x)`|`O(1)`|just adjusts a couple of pointers|
|`HashMap.get(key)`|`O(1)` average|hash function jumps near-directly to the bucket|
|`TreeMap.get(key)`|`O(log n)`|walks down a balanced tree, halving remaining nodes each step|
|Stack `push`/`pop` (`ArrayDeque`)|`O(1)`|operates only on one end|
|Queue `offer`/`poll` (`ArrayDeque`)|`O(1)`|operates on both ends, but each operation touches only one|
|`Collections.sort()`|`O(n log n)`|efficient comparison-based sort|
|Nested loop checking all pairs|`O(n²)`|every element compared against every other element|

This table is the direct payoff of everything from the last two tutorials — every "why `ArrayList` here, `LinkedList` there" and "why `HashMap` vs `TreeMap`" decision is really a Big O decision, now made explicit and precise.

---

## Summary

|Concept|Definition|
|---|---|
|**Big O notation**|describes how an algorithm's work scales as input size (`n`) grows, independent of hardware|
|**What it measures**|growth trend, not literal seconds — how work multiplies as `n` multiplies|
|**`O(1)`**|constant — same work regardless of size|
|**`O(log n)`**|grows very slowly — halving-based algorithms (binary search, balanced trees)|
|**`O(n)`**|grows proportionally — must touch every element once|
|**`O(n log n)`**|typical efficient sort performance|
|**`O(n²)`**|grows quadratically — nested loops over the same data|
|**`O(2ⁿ)`**|exponential — becomes unusable extremely quickly|
|**Worst/average/best case**|Big O can describe different scenarios; worst case is the most commonly cited, safest guarantee|

## Where this closes the loop

Big O is the formal vocabulary underlying every performance claim made across the data structures and stack/queue tutorials — "array access is fast," "linked list insertion at the front is fast, but index access is slow," "hash maps are fast for lookup" — these were all informal statements of Big O complexity classes. Now you have the actual notation and reasoning behind those claims, which is the standard language used in technical interviews, algorithm discussions, and any serious conversation about why one implementation was chosen over another.


[[Java]]