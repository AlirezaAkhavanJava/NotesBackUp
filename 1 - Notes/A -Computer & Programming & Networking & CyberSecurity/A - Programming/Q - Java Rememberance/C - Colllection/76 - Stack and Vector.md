



**Both are legacy classes from Java 1.0 (1996)** — they still exist, still work, still compile and run fine, but **modern Java code should avoid both** in favor of newer alternatives. They're not removed (Java maintains strict backward compatibility), but you'll rarely see them recommended in code written today. Let's define each, understand why they exist, and see exactly what replaced them.

---

## `Vector<E>`

### Definition

**`Vector<E>`** is a class implementing `List<E>`, backed by a **resizable array** — structurally almost identical to `ArrayList`. The key difference: **every method on `Vector` is `synchronized`**, making it thread-safe by default.

```java
Vector<String> vector = new Vector<>();
vector.add("Alireza");
vector.add("Sara");
```

```java
public class Vector<E> extends AbstractList<E>
    implements List<E>, RandomAccess, Cloneable, Serializable { ... }
```

### The problem it originally solved

`Vector` predates the entire Collections Framework — it existed in **Java 1.0**, before `ArrayList` even existed (introduced in Java 1.2, alongside the Collections Framework as a whole). At the time, `Vector` was simply *the* resizable-array list implementation available, and since early Java's concurrency model made thread-safety a default concern, every method was `synchronized` from the start.

### Why it fell out of favor

When the Collections Framework arrived in Java 1.2, `ArrayList` was introduced as `Vector`'s spiritual successor — structurally the same idea (resizable array), but **without** built-in synchronization.

```java
List<String> list = new ArrayList<>(); // NOT synchronized
```

**Why removing synchronization was actually the right call for most cases:** synchronization has real performance overhead, and the vast majority of `List` usage happens **within a single thread** — paying that locking cost on every single `add()`/`get()` call, even when no other thread will ever touch the list, is pure waste.

```java
// Every single call here acquires and releases a lock — even in single-threaded code
Vector<String> v = new Vector<>();
for (int i = 0; i < 1_000_000; i++) {
    v.add("item"); // synchronized overhead, 1,000,000 times, for NO benefit if single-threaded
}
```

### Another problem: `Vector`'s synchronization doesn't even fully solve concurrency

This is worth understanding precisely — `Vector` being "thread-safe" only means **individual method calls** are atomic. **Compound operations** (check-then-act sequences) are still race-prone, exactly like the race conditions covered in the concurrency tutorials:

```java
Vector<String> v = new Vector<>();
v.add("a");

// Still NOT safe, even with Vector, across multiple threads:
if (!v.isEmpty()) {          // Thread A checks: not empty
    v.remove(0);                // Thread B could remove it FIRST, between these two calls
}
```

So `Vector` gives a **false sense of complete thread-safety** while actually only protecting individual calls — a genuinely misleading property that contributed to it falling out of favor once better alternatives existed.

### Modern replacement

```java
List<String> list = new ArrayList<>();                          // single-threaded (the default choice)
List<String> synced = Collections.synchronizedList(new ArrayList<>()); // explicit synchronization, same caveats as Vector though
List<String> concurrent = new CopyOnWriteArrayList<>();               // java.util.concurrent — genuinely better for concurrent read-heavy use
```

`CopyOnWriteArrayList` (covered in the concurrency tutorials' toolkit list) is the real modern answer for a thread-safe list — it copies the entire underlying array on every write, making reads extremely fast and safe without locking, ideal for read-heavy, write-rare concurrent scenarios (e.g., a list of event listeners).

---

## `Stack<E>`

### Definition

**`Stack<E>`** is a class implementing a LIFO stack, but implemented by **extending `Vector`** — meaning it inherits every one of `Vector`'s array-backed, synchronized `List` methods, plus adds stack-specific methods (`push`, `pop`, `peek`).

```java
public class Stack<E> extends Vector<E> { ... }
```

```java
Stack<Integer> stack = new Stack<>();
stack.push(1);
stack.push(2);
System.out.println(stack.pop()); // 2
System.out.println(stack.peek()); // 1
```

### The problem with `Stack`'s design — it's architecturally awkward

This is the real issue, beyond just inheriting `Vector`'s synchronization overhead: **`Stack extends Vector`, which means `Stack` inherits ALL of `Vector`'s `List` methods too** — including ones that completely violate what a stack is supposed to be.

```java
Stack<Integer> stack = new Stack<>();
stack.push(1);
stack.push(2);
stack.push(3);

stack.add(0, 99);        // inserts at the BOTTOM — breaks the LIFO contract entirely!
stack.get(1);               // random index access — a "real" stack shouldn't allow this at all
stack.remove(0);              // removes from the bottom — again, violates LIFO
```

A properly designed stack should **only** expose push/pop/peek-style operations — allowing arbitrary index access and insertion defeats the entire purpose of the abstraction. This is a genuine, well-known design flaw: `Stack` was built by **inheritance** (`extends Vector`) rather than by wrapping/restricting behavior, so it leaks capabilities it shouldn't have.

### Modern replacement — `Deque` (specifically `ArrayDeque`)

This is exactly what the stack/queue tutorial already told you, now with the full architectural reasoning behind it:

```java
Deque<Integer> stack = new ArrayDeque<>();
stack.push(1);
stack.push(2);
stack.push(3);
System.out.println(stack.pop()); // 3
```

**Why `ArrayDeque` is strictly better as a stack:**
1. **No inherited baggage** — `ArrayDeque` doesn't extend some unrelated legacy class; it's purpose-built.
2. **No synchronization overhead** — not synchronized by default, like `ArrayList`, appropriate for the common single-threaded case.
3. **Faster** — `Vector`/`Stack`'s synchronized methods have real overhead `ArrayDeque` doesn't carry.
4. **The official Java documentation itself recommends `ArrayDeque` over `Stack`** for stack usage — this isn't just community consensus, it's stated directly in the JDK's own class documentation.

---

## Are they *actually* still used today?

### They're still fully supported and functional

```java
Stack<Integer> s = new Stack<>();   // compiles, runs, works exactly as documented
Vector<String> v = new Vector<>();   // same — fully functional
```

Java **never removes** classes from the standard library once released, specifically to guarantee that old code compiled against any past JDK version keeps working indefinitely (this is Java's famous backward-compatibility commitment). So neither class is "deprecated" in the formal `@Deprecated` sense — they simply aren't the *recommended* choice anymore.

### Where you might genuinely still encounter them

- **Legacy codebases** — large, older enterprise Java systems (banking, government, long-lived infrastructure) that predate the Collections Framework or `ArrayDeque`'s introduction often still contain `Vector`/`Stack` usage that's never been refactored, simply because "it still works" and touching old, stable code carries risk.
- **Educational material** (including some older textbooks/courses) that hasn't been updated to reflect modern best practice — `Stack` in particular is still commonly taught as a first introduction to the stack data structure concept, even though `ArrayDeque` would be the better real-world choice.
- **APIs that specifically require `Vector`/`Stack`** for historical reasons — rare, but some very old libraries' method signatures were written against these types directly.

### In new code you write today

**You should not use `Vector` or `Stack`.** Every real capability they offer has a better modern equivalent:

| Need | Legacy | Modern |
|---|---|---|
| General-purpose resizable list | `Vector` | `ArrayList` |
| Thread-safe list | `Vector` | `CopyOnWriteArrayList`, or `Collections.synchronizedList()` |
| Stack (LIFO) | `Stack` | `ArrayDeque` |

---

## Summary

| Aspect | `Vector` | `Stack` |
|---|---|---|
| What it is | synchronized, array-backed `List` | LIFO stack, built by extending `Vector` |
| Introduced | Java 1.0 (pre-Collections Framework) | Java 1.0 |
| Core problem | unnecessary synchronization overhead for typical single-threaded use; false sense of full thread-safety | inherits `Vector`'s overhead AND exposes non-stack operations (`add(index)`, `get(index)`) that break the LIFO abstraction |
| Still functional? | Yes — fully supported | Yes — fully supported |
| Recommended for new code? | **No** | **No** |
| Modern replacement | `ArrayList` (single-threaded) or `CopyOnWriteArrayList` (concurrent) | `ArrayDeque` |
| Where you might still see it | legacy codebases, older educational material | legacy codebases, older educational material/tutorials |

## Where this fits with everything you've learned

This closes a loop from several earlier tutorials at once: the Collections Framework hierarchy tutorial listed both as "legacy," the stack/queue tutorial already told you to prefer `ArrayDeque`, and the concurrency tutorials explained *why* unconditional synchronization (as `Vector` does) is often the wrong default. `Stack extends Vector` is also a genuinely good real-world cautionary example for object-oriented design generally — inheriting from a class to "reuse code" can leak unwanted capabilities (here, arbitrary list access breaking a stack's LIFO contract) in a way that composition/wrapping (which `ArrayDeque` effectively achieves by being purpose-built) avoids.


[[Java]]