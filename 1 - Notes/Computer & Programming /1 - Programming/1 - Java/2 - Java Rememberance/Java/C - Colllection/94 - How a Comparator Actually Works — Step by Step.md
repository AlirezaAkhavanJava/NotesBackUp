

## 1. The Core Idea: Sorting Is Just Repeated Comparisons

A comparison-based sort never "looks at" the whole array at once. It only ever asks one question, over and over:

> "Between these **two** elements, which comes first?"

That single question is the comparator. Everything else is bookkeeping.

---

## 2. Trace a Real Example by Hand

Array: `[5, 2, 9, 1]`
Comparator: natural numeric order → `compare(a,b) = a - b`

### Insertion sort (simplest to trace)

```
Start:  [5 | 2, 9, 1]        (left of | is "sorted so far")

Insert 2:
  compare(2, 5) → 2-5 = -3  (negative → 2 < 5, so 2 goes before 5)
  [2, 5 | 9, 1]

Insert 9:
  compare(9, 5) → 9-5 = +4  (positive → 9 > 5, stop)
  [2, 5, 9 | 1]

Insert 1:
  compare(1, 9) → -8        (1 < 9, shift 9 right)
  compare(1, 5) → -4        (1 < 5, shift 5 right)
  compare(1, 2) → -1        (1 < 2, shift 2 right)
  [1, 2, 5, 9]
```

The sort never compares `1` against `9` "as numbers" in any special way — it just calls your comparator and reads the **sign** of the result.

**That's the whole trick.** The sort only cares about the sign: negative, zero, or positive.

---

## 3. What the Return Value Means (and What the Sort Does With It)

| `compare(a, b)` returns | Meaning | Sort's action |
|---|---|---|
| **negative** | `a` < `b` | `a` should come **before** `b` |
| **zero** | `a` == `b` | order between them doesn't matter (stable sorts keep original) |
| **positive** | `a` > `b` | `a` should come **after** `b` |

The actual numeric value (`-3`, `+4`, `100`) is **irrelevant** — only its sign matters. `a - b` works for ints precisely because the sign of the subtraction encodes the order.

⚠️ **Overflow trap:** `a - b` breaks for large ints. `Integer.MAX_VALUE - (-1)` overflows to a negative number, so the comparator lies. That's why Java recommends `Integer.compare(a, b)` instead.

---

## 4. How a Real Sort Algorithm Drives the Comparator

### Merge sort
1. Split array in half, recursively.
2. To merge two sorted halves, repeatedly:
   ```
   compare(left[i], right[j])
   → negative: take left[i],  i++
   → positive: take right[j], j++
   → zero:     take left[i] (stability), i++
   ```
3. Each comparison decides which of the two "next candidates" gets appended.

### Quicksort
1. Pick a pivot.
2. Partition: for each element `x`, call `compare(x, pivot)`.
   - negative → left side
   - positive → right side
3. Recurse on both sides.

### Timsort (Java/Python)
1. Scan for already-sorted runs using `compare`.
2. Extend short runs with insertion sort.
3. Merge runs with the same two-pointer logic as merge sort, but with "galloping" — once one side wins repeatedly, it binary-searches how many more it can take, skipping comparisons.

In every case, the algorithm is a **decision tree**: each `compare` call steers the flow.

---

## 5. Why It Must Be Consistent (the Contract, Concretely)

Suppose `compare` is broken:

```java
// Broken: compares by first digit only
compare(19, 25) → 1 < 2 → negative   (19 "before" 25) ✓
compare(25, 31) → 2 < 3 → negative   (25 "before" 31) ✓
compare(19, 31) → 1 < 3 → negative   (19 "before" 31) ✓
// Looks fine... but:
compare(21, 19) → 2 > 1 → positive   (21 "after" 19)
compare(19, 21) → 1 < 2 → negative   (19 "before" 21) ✓
// Transitivity breaks on other triples, e.g.:
compare(19, 12) → 1 == 1 → 0        (equal?!)
compare(12, 15) → 1 == 1 → 0        (equal?!)
compare(19, 15) → 1 == 1 → 0        (equal?!)
```

Now the sort has no consistent order to follow. Merge sort might place `19` before `12` in one merge and after it in another. Java detects this and throws:

```
java.lang.IllegalArgumentException:
Comparison method violates its general contract!
```

The properties (antisymmetry, transitivity, reflexivity) aren't academic — they're what guarantee the algorithm terminates with a **single, coherent** order.

---

## 6. Chained Comparators — How `thenComparing` Works Internally

```java
Comparator<Person> c =
    Comparator.comparingInt(Person::age)
              .thenComparing(Person::name);
```

Under the hood, `thenComparing` builds a **composite comparator** roughly like:

```java
(a, b) -> {
    int r = first.compare(a, b);   // compare by age
    if (r != 0) return r;          // age differs → done
    return second.compare(a, b);   // age equal → compare by name
}
```

So it's just **sequential fallback**: run comparator 1; if it says "equal", run comparator 2; if that says "equal", run comparator 3; etc. This is how multi-key sorting (`ORDER BY age, name`) is implemented in one pass.

---

## 7. Full Concrete Trace — Composite Comparator

People: `[(Alice, 30), (Bob, 25), (Carol, 30)]`
Comparator: by age, then by name.

```
Sort begins (merge sort style, simplified):

compare(Alice30, Bob25):
  age: compare(30, 25) → +5  (positive)
  → Alice > Bob, so Bob comes first

compare(Alice30, Carol30):
  age: compare(30, 30) → 0
  fall through to name: compare("Alice", "Carol") → negative
  → Alice < Carol, so Alice comes first

Final: [Bob25, Alice30, Carol30]
```

Notice: the *first* comparison short-circuits. The name comparator is only called when ages tie. That's the efficiency win of chaining.

---

## 8. The Mental Model

Think of the comparator as a **referee**:

- The sort algorithm is a **tournament organizer** that keeps asking the referee: "Who wins between these two?"
- The referee never sees the whole bracket — only the two players in front of them.
- As long as the referee is **consistent** (same answer every time, no contradictions), the organizer can build a valid ranking.
- If the referee contradicts themselves, the bracket becomes impossible to build → error.

---

## TL;DR

> A comparator works by being **called repeatedly, pairwise**, by a sorting algorithm. Each call returns a sign (negative / zero / positive), and the algorithm uses that sign to decide which element goes first. The algorithm itself is a decision tree steered entirely by those signs. Chained comparators are just sequential fallbacks: if the first says "equal", try the next. The comparator must be consistent (antisymmetric, transitive) or the sort produces garbage or throws.


[[Java]]