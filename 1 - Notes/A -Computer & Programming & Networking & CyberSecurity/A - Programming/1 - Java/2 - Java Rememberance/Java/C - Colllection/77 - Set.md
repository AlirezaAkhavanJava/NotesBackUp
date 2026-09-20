Before `Set` makes sense, you need a working understanding of these:

| Prerequisite                              | Why it matters                                                                                                                                                                                    |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Interfaces vs. implementations**        | `Set` is an interface. `HashSet`, `TreeSet`, `LinkedHashSet` are implementations. Confusing these causes most beginner errors.                                                                    |
| **`equals()` and `hashCode()` contracts** | `Set` is _defined_ by how it decides "is this element already present?" That decision rests entirely on `equals()` and `hashCode()`. If you don't understand these, `Set` will behave "randomly." |
| **The `Collection` interface**            | `Set` extends `Collection`. It inherits `add`, `remove`, `contains`, `size`, `iterator`, etc.                                                                                                     |
| **Big-O notation (basic)**                | To choose between `HashSet` and `TreeSet`, you need to know what O(1), O(log n), and O(n) mean.                                                                                                   |
| **Hashing (conceptual)**                  | A hash function maps an object to an integer. You don't need to implement one, but you need to know what it does.                                                                                 |
| **Comparable / Comparator**               | Required to understand `TreeSet`.                                                                                                                                                                 |
> A `Set` is a `Collection` that contains no pair of elements `e1` and `e2` such that `e1.equals(e2)`. It adds the stipulation that `add(e)` returns `false` if the set already contains `e`, and that the set contains at most one `null` element (for implementations that permit `null`).

## Definition

**`Set<E>`** is an interface in `java.util` that extends `Collection<E>`, representing a collection that **contains no duplicate elements**. It models the mathematical concept of a set — a group of distinct items where each item either belongs or doesn't; there's no notion of "the same item twice."

```java
public interface Set<E> extends Collection<E> { ... }
```

```java
Set<String> names = new HashSet<>();
```

Unlike `List`, `Set` does **not** extend with index-based methods — there's no `get(int index)`, no `set(int, E)` — because a set's elements aren't inherently ordered by position the way a list's are (though _some_ `Set` implementations do maintain a specific order, covered below).

---

## The problem `Set` solves

### `List` allows duplicates — sometimes that's exactly the problem

```java
List<String> tags = new ArrayList<>();
tags.add("java");
tags.add("spring");
tags.add("java"); // duplicate slips right in — List doesn't care
System.out.println(tags); // [java, spring, java]
System.out.println(tags.size()); // 3 — but really only 2 distinct tags
```

If your actual requirement is "track a collection of distinct things — no repeats allowed," using a `List` means **you** have to manually check for duplicates before every insertion:

```java
// The painful manual way, using a List
if (!tags.contains("java")) {
    tags.add("java"); // O(n) check every single time, and easy to forget
}
```

**`Set` solves this by making uniqueness a structural guarantee, enforced automatically, every time:**

```java
Set<String> tags = new HashSet<>();
tags.add("java");
tags.add("spring");
tags.add("java"); // silently ignored — already present
System.out.println(tags);      // [java, spring] — order not guaranteed for HashSet
System.out.println(tags.size()); // 2
```

`add()` returns `false` when the element was already present (rather than throwing an exception), letting you detect duplicates without extra code if you care to check:

```java
boolean wasNew = tags.add("java");
System.out.println(wasNew); // false — it was already there, nothing changed
```

### Fast membership testing — the second core problem `Set` solves

Beyond just preventing duplicates, `Set` implementations (specifically `HashSet`) solve a **performance** problem: checking "does this exist?" is `O(n)` on a `List` (must scan every element) but `O(1)` average on a `HashSet` (direct hash-based lookup) — this connects directly to the Big O tutorial's example of exactly this scenario.

```java
List<Integer> list = ...;    // 1,000,000 elements
Set<Integer> set = ...;        // same 1,000,000 elements

list.contains(999999); // O(n) — potentially scans all million elements
set.contains(999999);   // O(1) average — essentially instant, regardless of size
```

---

## Core features of `Set`

### 1. No duplicates — the defining feature

```java
Set<String> set = new HashSet<>();
set.add("Alireza");
set.add("Alireza");
set.add("Alireza");
System.out.println(set.size()); // 1 — no matter how many times you add the same value
```

**Uniqueness is determined by `.equals()` (and `.hashCode()`)** — not by reference identity (`==`). This matters for custom objects:

```java
class User {
    String name;
    User(String name) { this.name = name; }
    // if equals()/hashCode() are NOT overridden, each User object is considered
    // unique by default (based on memory reference), even with identical data!
}

Set<User> users = new HashSet<>();
users.add(new User("Alireza"));
users.add(new User("Alireza")); // considered a DIFFERENT user — added successfully!
System.out.println(users.size()); // 2 — NOT 1, because equals()/hashCode() weren't overridden
```

**This is a genuinely common source of bugs** — if you want two objects with the same _data_ to be treated as duplicates by a `Set`, you must override `equals()` and `hashCode()` on your class (as shown in the `Objects.equals()` example from the utility classes tutorial):

```java
class User {
    String name;
    User(String name) { this.name = name; }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof User other)) return false;
        return Objects.equals(this.name, other.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name);
    }
}

Set<User> users = new HashSet<>();
users.add(new User("Alireza"));
users.add(new User("Alireza")); // now correctly recognized as a duplicate
System.out.println(users.size()); // 1
```

### 2. `null` handling — varies by implementation

```java
Set<String> hashSet = new HashSet<>();
hashSet.add(null); // allowed — HashSet permits exactly ONE null element (since it's still just "a value" to hash)
System.out.println(hashSet.contains(null)); // true
```

```java
Set<String> treeSet = new TreeSet<>();
treeSet.add(null); // NullPointerException! — TreeSet must COMPARE elements to sort them, and comparing null fails
```

```java
Set<String> linkedHashSet = new LinkedHashSet<>();
linkedHashSet.add(null); // allowed, same as HashSet — it's a HashSet subtype
```

This directly echoes the `null`-handling differences flagged in the `ArrayList`/`List.of()` tutorials — behavior genuinely differs by implementation, and it's important to know which one you're using.

### 3. No index-based access

```java
Set<String> set = new HashSet<>(List.of("a", "b", "c"));
set.get(0); // COMPILE ERROR — Set has no get(int) method at all
```

This is a structural consequence of what a `Set` fundamentally _is_ — since uniqueness, not position, is the organizing principle, there's no guaranteed "5th element" concept the way a `List` has. (`TreeSet`, being sorted, has some position-adjacent methods like `first()`/`last()`, covered below — but no arbitrary index access.)

### 4. Ordering — varies dramatically by implementation

This is the single biggest differentiator between `Set` implementations, so it's worth its own focused comparison:

|Implementation|Order guarantee|
|---|---|
|`HashSet`|**none** — iteration order is essentially unpredictable, based on internal hash bucket placement|
|`LinkedHashSet`|**insertion order** — preserves the order elements were added|
|`TreeSet`|**sorted order** — always iterates in natural (or custom `Comparator`) order|

```java
Set<String> hash = new HashSet<>(List.of("banana", "apple", "cherry"));
System.out.println(hash); // order UNPREDICTABLE — e.g. [banana, cherry, apple], not insertion order

Set<String> linked = new LinkedHashSet<>(List.of("banana", "apple", "cherry"));
System.out.println(linked); // [banana, apple, cherry] — insertion order preserved

Set<String> tree = new TreeSet<>(List.of("banana", "apple", "cherry"));
System.out.println(tree); // [apple, banana, cherry] — always sorted
```

---

## The three implementations, with their distinct feature sets

### `HashSet` — the default choice

```java
Set<String> set = new HashSet<>();
```

- Backed by a **hash table** (technically, internally backed by a `HashMap` — each element is stored as a key, with a dummy value)
- `O(1)` average add/remove/contains
- **No ordering guarantee at all**
- Allows one `null`
- **Use when:** you just need uniqueness and fast lookup, and don't care about iteration order — this is the right default choice for most `Set` use cases

### `LinkedHashSet` — `HashSet` + predictable order

```java
Set<String> set = new LinkedHashSet<>();
```

- Same hash-table backing as `HashSet`, **plus** an internal doubly-linked list tracking insertion order
- Same `O(1)` average performance as `HashSet`, with a small constant overhead for maintaining the linked list
- Iterates in **insertion order**, always
- **Use when:** you need uniqueness, fast lookup, _and_ predictable, repeatable iteration order (e.g., displaying a deduplicated list to a user in the order they were encountered)

### `TreeSet` — sorted, at a performance cost

```java
Set<Integer> set = new TreeSet<>();
```

- Backed by a **red-black tree** (a self-balancing binary search tree, as covered in the data structures tutorial)
- `O(log n)` add/remove/contains — slower than the hash-based options, but still efficient
- Always iterates in **sorted order** (natural ordering via `Comparable`, or a custom `Comparator` supplied at creation)
- Does **not** allow `null`
- Implements `SortedSet<E>` (and further, `NavigableSet<E>`), adding extra methods:

```java
TreeSet<Integer> set = new TreeSet<>(List.of(5, 1, 8, 3));
System.out.println(set.first());        // 1 — smallest element
System.out.println(set.last());           // 8 — largest element
System.out.println(set.higher(3));          // 5 — smallest element STRICTLY greater than 3
System.out.println(set.lower(5));            // 3 — largest element STRICTLY less than 5
System.out.println(set.ceiling(4));            // 5 — smallest element >= 4
System.out.println(set.floor(4));               // 3 — largest element <= 4
System.out.println(set.headSet(5));               // [1, 3] — elements less than 5
System.out.println(set.tailSet(5));                // [5, 8] — elements >= 5
```

**Use when:** you need uniqueness _and_ sorted order, or you need range-based queries (everything above/below/between certain values) — capabilities none of the other `Set` implementations offer at all.

---

## Common `Set`-specific operations — set algebra

Since `Set` models mathematical sets, it naturally supports set operations, using the `Collection` methods from the earlier tutorial in a specific way:

```java
Set<Integer> a = new HashSet<>(Set.of(1, 2, 3, 4));
Set<Integer> b = new HashSet<>(Set.of(3, 4, 5, 6));

// Union — combine everything
Set<Integer> union = new HashSet<>(a);
union.addAll(b);
System.out.println(union); // [1, 2, 3, 4, 5, 6]

// Intersection — only what's in BOTH
Set<Integer> intersection = new HashSet<>(a);
intersection.retainAll(b);
System.out.println(intersection); // [3, 4]

// Difference — what's in `a` but NOT in `b`
Set<Integer> difference = new HashSet<>(a);
difference.removeAll(b);
System.out.println(difference); // [1, 2]
```

This is a genuinely practical, common real-world use of `retainAll()`/`removeAll()`/`addAll()` — mathematical set operations, expressed directly through `Collection`'s bulk methods.

---

## Creating sets — factory methods

```java
Set<String> mutable = new HashSet<>();
Set<String> fromCollection = new HashSet<>(List.of("a", "b", "c")); // copies elements in, dedupes automatically
Set<String> immutable = Set.of("a", "b", "c");                        // immutable, Java 9+ (no duplicates allowed in the args themselves — throws IllegalArgumentException if you pass duplicates)
```

```java
Set<String> dup = Set.of("a", "a"); // IllegalArgumentException — Set.of() explicitly rejects duplicate arguments
```

**Worth noting:** unlike `HashSet.add()` (which silently ignores a duplicate `add()` call), `Set.of()` actively **throws** if you pass duplicate values in the initial argument list — a stricter, fail-fast behavior appropriate for a factory method meant to catch mistakes immediately.

---

## Summary table

|Feature|`Set` (general)|`HashSet`|`LinkedHashSet`|`TreeSet`|
|---|---|---|---|---|
|Duplicates|never allowed|never allowed|never allowed|never allowed|
|Order|interface makes no guarantee|none/unpredictable|insertion order|sorted order|
|`null` allowed|depends on implementation|yes (one)|yes (one)|**no**|
|Index access|none|none|none|none (but has `first()`/`last()`/range methods)|
|Typical performance|—|`O(1)` average|`O(1)` average|`O(log n)`|
|Backing structure|—|hash table|hash table + linked list|red-black tree|
|Extra capabilities|—|—|—|`first/last/higher/lower/headSet/tailSet`|

---

## Where this fits with everything you've learned

`Set` is a direct, concrete application of the Collections hierarchy tutorial's structure and the data structures/Big O tutorials' trade-off reasoning: the three implementations are literally the hash table, hash table + linked list, and red-black tree examples from those tutorials, now shown as real usable classes with genuinely different guarantees. The `equals()`/`hashCode()` requirement for custom objects also connects directly back to the marker-interface and `Objects` utility discussions — `Set` is where that requirement becomes practically unavoidable, since uniqueness checking is `Set`'s entire reason for existing.



[[Java]]
[[1 - Collection interface 🤑]]
