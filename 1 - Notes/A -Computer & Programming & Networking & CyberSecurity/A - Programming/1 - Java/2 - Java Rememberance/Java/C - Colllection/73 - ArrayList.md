


## Definition

**`ArrayList<E>`** is a class in `java.util` that implements `List<E>`, backed internally by a **dynamically resizable array**. It's the most commonly used general-purpose list implementation in Java — a growable alternative to raw Java arrays (`int[]`, `String[]`).

```java
List<String> names = new ArrayList<>();
```

---

## The problem `ArrayList` solves

### Raw arrays have a fixed size — chosen at creation, never changeable

```java
String[] names = new String[3]; // locked at exactly 3 slots, forever
names[0] = "Alireza";
names[1] = "Sara";
names[2] = "Ali";
// names[3] = "Reza"; // ArrayIndexOutOfBoundsException — no room, and no way to grow
```

If you don't know in advance exactly how many elements you'll need — which is true for the vast majority of real programs (user input, database query results, growing datasets) — a raw array is fundamentally the wrong tool. You'd have to manually create a new, bigger array and copy everything over yourself every time you run out of space.

```java
// The painful manual way, without ArrayList
String[] old = new String[3];
old[0] = "a"; old[1] = "b"; old[2] = "c";

String[] bigger = new String[6];         // manually create a larger array
System.arraycopy(old, 0, bigger, 0, old.length); // manually copy everything over
bigger[3] = "d";                              // now finally room for a new element
```

**`ArrayList` solves this by doing exactly that resizing-and-copying process automatically, internally, whenever needed** — you just call `.add()` and never think about capacity management yourself.

```java
List<String> names = new ArrayList<>();
names.add("a");
names.add("b");
names.add("c");
names.add("d"); // just works — ArrayList resizes itself behind the scenes
```

Raw arrays also lack any built-in insert/remove/search convenience — `ArrayList` (via the `List` interface) gives you all of that for free, as covered in the `List` methods tutorial.

---

## Core features of `ArrayList`

### 1. Ordered — maintains insertion order

Elements stay in the exact order you added them, and each has a fixed numeric index.

```java
List<String> list = new ArrayList<>();
list.add("Alireza");
list.add("Sara");
list.add("Ali");
System.out.println(list); // [Alireza, Sara, Ali] — always this order, until explicitly changed
```

**Important distinction: "ordered" does not mean "sorted."** `ArrayList` never automatically sorts anything — it simply preserves whatever order you inserted elements in. If you want sorted order, you must call `.sort()` yourself (or use `TreeSet`/`TreeMap` from the data structures tutorial, which sort automatically as a core feature).

```java
List<Integer> nums = new ArrayList<>(List.of(5, 1, 3));
System.out.println(nums); // [5, 1, 3] — insertion order, NOT sorted

nums.sort(null); // must explicitly ask for sorting
System.out.println(nums); // [1, 3, 5] — now sorted, but only because you asked
```

### 2. Allows duplicates

The same value can appear multiple times — `ArrayList` places no restriction on uniqueness.

```java
List<String> list = new ArrayList<>();
list.add("Alireza");
list.add("Alireza"); // perfectly fine — duplicates allowed
System.out.println(list); // [Alireza, Alireza]
System.out.println(list.size()); // 2
```

This contrasts directly with `Set` implementations (`HashSet`, `TreeSet`), which explicitly reject duplicates — if you need uniqueness enforced automatically, `ArrayList` is the wrong structure; use a `Set` instead.

### 3. Allows `null` elements

```java
List<String> list = new ArrayList<>();
list.add("Alireza");
list.add(null);       // perfectly legal
list.add("Sara");
System.out.println(list); // [Alireza, null, Sara]
System.out.println(list.contains(null)); // true
System.out.println(list.indexOf(null));   // 1
```

**Multiple `null`s are also allowed**, since duplicates in general are allowed:

```java
list.add(null);
list.add(null);
System.out.println(list); // [Alireza, null, Sara, null, null]
```

**Contrast:** some collections explicitly forbid `null` — most notably `TreeSet`/`TreeMap` (since they need to compare elements to sort them, and comparing against `null` throws `NullPointerException`), and any collection created via `List.of()`/`Set.of()`/`Map.of()` (the immutable factories from the earlier tutorial) also **reject `null` entirely**, throwing `NullPointerException` immediately on creation if you try:

```java
List<String> immutable = List.of("a", null, "c"); // NullPointerException — immediately, at creation
```

`ArrayList` has no such restriction — this is a genuine, specific feature worth knowing, since it's not universal across all Java collections.

### 4. Indexed access — random access by position

```java
List<String> list = new ArrayList<>(List.of("a", "b", "c"));
String second = list.get(1); // direct O(1) access, as covered in the ArrayList vs LinkedList tutorial
```

This is `ArrayList`'s defining performance strength — covered in depth in the last tutorial.

### 5. Dynamically resizable

```java
List<Integer> list = new ArrayList<>(); // starts small (commonly initial capacity 10, internally)
for (int i = 0; i < 1_000_000; i++) {
    list.add(i); // grows automatically as needed, no manual intervention
}
```

Internally: when the backing array fills up, `ArrayList` allocates a new array (~1.5x larger) and copies existing elements over — entirely transparent to your code, as covered in the previous tutorial's resizing explanation.

### 6. Not thread-safe

```java
List<String> list = new ArrayList<>(); // NOT safe for concurrent access from multiple threads
```

If multiple threads add/remove from the same `ArrayList` simultaneously without external synchronization, you get race conditions (exactly the kind covered in the concurrency tutorials) — potentially corrupted internal state, lost elements, or `ConcurrentModificationException`.

**If you need thread safety:**

```java
List<String> synced = Collections.synchronizedList(new ArrayList<>()); // wraps with synchronized methods
List<String> concurrent = new CopyOnWriteArrayList<>(); // java.util.concurrent — optimized for many reads, few writes
```

This connects directly to the concurrency tutorials — `ArrayList` deliberately trades away thread-safety for speed, since most use cases are single-threaded, and forcing synchronization overhead on everyone would be wasteful.

### 7. Fail-fast iteration

```java
List<String> list = new ArrayList<>(List.of("a", "b", "c"));

for (String item : list) {
    list.add("d"); // ConcurrentModificationException — thrown on the NEXT iteration attempt
}
```

**Definition of "fail-fast":** if the list is **structurally modified** (elements added/removed, not just replaced via `set()`) while being iterated — other than through the iterator's own `remove()` method — Java detects this and throws `ConcurrentModificationException` immediately, rather than allowing silently corrupted or unpredictable iteration behavior.

```java
Iterator<String> it = list.iterator();
while (it.hasNext()) {
    String item = it.next();
    if (item.equals("b")) {
        it.remove(); // SAFE — this is the one sanctioned way to modify during iteration
    }
}
```

This directly reinforces the `Iterator`/`removeIf()` content from the earlier `List` methods tutorial — `ArrayList` is exactly the kind of list where this rule applies and matters in practice.

### 8. Implements `RandomAccess` (a marker interface!)

```java
public class ArrayList<E> implements List<E>, RandomAccess, Cloneable, Serializable { ... }
```

Remember **marker interfaces** from the earlier tutorial (`Serializable`, `Cloneable`)? `RandomAccess` is another one — an **empty interface** that signals "this list supports fast, `O(1)` random access by index." `LinkedList` does **not** implement `RandomAccess`, since its `get(index)` is `O(n)`.

**Why this matters practically:** some algorithms check for this marker to decide _how_ to iterate most efficiently:

```java
if (list instanceof RandomAccess) {
    // safe to loop with a plain indexed for-loop — get(i) is fast
    for (int i = 0; i < list.size(); i++) {
        process(list.get(i));
    }
} else {
    // better to use an Iterator instead — get(i) would be slow here
    for (Object item : list) {
        process(item);
    }
}
```

This is a real, if somewhat advanced, example of a marker interface being used exactly the way the earlier marker-interface tutorial described — as a cheap `instanceof` check that changes behavior, with zero methods actually being called on it.

### 9. Implements `Cloneable`

```java
ArrayList<String> original = new ArrayList<>(List.of("a", "b"));
ArrayList<String> copy = (ArrayList<String>) original.clone(); // shallow copy
```

**Shallow copy** — the new list is a separate list object, but if it contains references to mutable objects, those inner objects are still shared between both lists (not deeply duplicated). This connects back to the `Cloneable` marker interface example from the marker interfaces tutorial.

### 10. Implements `Serializable`

```java
public class ArrayList<E> implements ..., Serializable { ... }
```

An `ArrayList` (whose elements are also `Serializable`) can be serialized directly with `ObjectOutputStream`, exactly as covered in the serialization tutorials — this is _why_ `ArrayList` objects can be written to files, sent over networks, or stored in distributed caches without any extra work.

---

## Constructors — the different ways to create one

```java
List<String> empty = new ArrayList<>();                     // empty, default initial capacity
List<Integer> presized = new ArrayList<>(1000);                // empty, but pre-sized for 1000 elements
List<String> fromCollection = new ArrayList<>(List.of("a", "b")); // copies elements from another collection
```

---

## Summary table — `ArrayList` at a glance

|Feature|`ArrayList` behavior|
|---|---|
|Backing structure|resizable array|
|Order|preserves insertion order (NOT sorted automatically)|
|Duplicates|allowed|
|`null` elements|allowed (including multiple)|
|Index-based access|yes — `O(1)`, fast|
|Thread-safe|No — needs external synchronization if shared across threads|
|Iteration behavior|fail-fast — throws `ConcurrentModificationException` on unsafe concurrent modification|
|Implements `RandomAccess`|Yes — signals fast indexed access|
|Implements `Cloneable`|Yes — supports shallow `.clone()`|
|Implements `Serializable`|Yes — can be serialized directly|
|Resizing|automatic, transparent (grows ~1.5x when full)|
|Best at|index access, appending, iteration|
|Weak at|inserting/removing in the middle or front (`O(n)`, shifting required)|

---

## Where this fits with everything you've learned

Every feature here is a direct application of earlier tutorials: **allows `null`/duplicates** connects to how `Set`/`TreeSet` deliberately differ; **not thread-safe** connects to the concurrency tutorials and their `ConcurrentHashMap`/`CopyOnWriteArrayList` alternatives; **fail-fast iteration** connects to the `Iterator`/`ConcurrentModificationException` content; **`RandomAccess`/`Cloneable`/`Serializable`** connect directly back to the marker interfaces tutorial, showing three real, concrete examples of that exact pattern in one class. `ArrayList` is, in a real sense, a synthesis point where nearly everything covered in this conversation about generics, interfaces, Big O, and marker interfaces comes together in one practical, everyday class.


[[Java]]