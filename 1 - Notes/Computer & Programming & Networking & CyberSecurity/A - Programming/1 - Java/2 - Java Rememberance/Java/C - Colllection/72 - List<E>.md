

## Definition

**`List<E>`** is an interface in `java.util` that represents an **ordered collection of elements**, where each element has a specific **index** (position), and **duplicate elements are allowed**. It extends `Collection<E>`, adding index-based operations on top of the base `Collection` contract.

```java
public interface List<E> extends Collection<E> { ... }
```

**Key traits:**

- Elements maintain **insertion order** (unless you explicitly sort/reorder them)
- Accessible by **numeric index**, starting at `0`
- **Duplicates allowed** — the same value can appear multiple times
- Common implementations: `ArrayList` (array-backed, fast index access), `LinkedList` (node-backed, fast insert/remove at ends)

```java
List<String> names = new ArrayList<>(); // programming to the interface, using a concrete implementation
```

Below, every core method is defined and demonstrated, grouped by what they do.

---

## 1. Adding elements

### `add(E element)`

Appends the element to the **end** of the list. Returns `true` (per the `Collection` contract, though `List` always returns `true` here).

```java
List<String> names = new ArrayList<>();
names.add("Alireza");
names.add("Sara");
System.out.println(names); // [Alireza, Sara]
```

### `add(int index, E element)`

Inserts the element at a **specific position**, shifting existing elements at/after that index one place to the right.

```java
names.add(1, "Ali"); // insert "Ali" at index 1
System.out.println(names); // [Alireza, Ali, Sara]
```

**Cost:** `O(n)` for `ArrayList` (must shift elements), `O(1)` for `LinkedList` if inserting at a known node (but `O(n)` to _find_ that index first) — exactly the trade-off from the data structures tutorial.

### `addAll(Collection<? extends E> c)`

Appends every element from another collection, in that collection's iteration order.

```java
names.addAll(List.of("Reza", "Sam"));
System.out.println(names); // [Alireza, Ali, Sara, Reza, Sam]
```

### `addAll(int index, Collection<? extends E> c)`

Same as above, but inserts starting at a specific index instead of the end.

```java
names.addAll(1, List.of("X", "Y"));
System.out.println(names); // [Alireza, X, Y, Ali, Sara, Reza, Sam]
```

---

## 2. Accessing elements

### `get(int index)`

Returns the element at the given index. Throws `IndexOutOfBoundsException` if the index is invalid.

```java
String first = names.get(0);
System.out.println(first); // Alireza
```

```java
names.get(100); // IndexOutOfBoundsException — no such index
```

### `size()`

Returns the number of elements currently in the list.

```java
System.out.println(names.size()); // 7
```

### `isEmpty()`

Returns `true` if the list has zero elements.

```java
List<String> empty = new ArrayList<>();
System.out.println(empty.isEmpty()); // true
```

### `indexOf(Object o)`

Returns the index of the **first** occurrence of the given element, or `-1` if it's not present.

```java
System.out.println(names.indexOf("Sara")); // e.g. 4
System.out.println(names.indexOf("NotThere")); // -1
```

### `lastIndexOf(Object o)`

Same as `indexOf`, but returns the index of the **last** occurrence — useful when duplicates exist.

```java
List<String> withDupes = new ArrayList<>(List.of("a", "b", "a", "c"));
System.out.println(withDupes.indexOf("a"));      // 0
System.out.println(withDupes.lastIndexOf("a"));    // 2
```

### `contains(Object o)`

Returns `true` if the element exists anywhere in the list (uses `.equals()` for comparison).

```java
System.out.println(names.contains("Sara")); // true
```

**Cost:** `O(n)` for both `ArrayList` and `LinkedList` — must potentially scan every element, since a `List` has no hash-based shortcut (unlike `HashSet`/`HashMap`).

---

## 3. Modifying elements

### `set(int index, E element)`

**Replaces** the element at the given index with a new value, and returns the **old** value that was there.

```java
String old = names.set(0, "Alireza-Updated");
System.out.println(old);   // Alireza — the value that was replaced
System.out.println(names); // [Alireza-Updated, ...]
```

**Important distinction from `add(int, E)`:** `set()` **replaces** an existing element at that index (list size stays the same); `add(int, E)` **inserts** a new element, shifting everything after it (list size grows by one). This is a very common point of confusion.

---

## 4. Removing elements

### `remove(int index)`

Removes the element at the given index, shifts everything after it left by one, and returns the removed element.

```java
List<String> list = new ArrayList<>(List.of("a", "b", "c"));
String removed = list.remove(1); // removes index 1
System.out.println(removed); // "b"
System.out.println(list);      // [a, c]
```

### `remove(Object o)`

Removes the **first occurrence** of the given object (by `.equals()`), returns `true` if something was actually removed.

```java
List<String> list = new ArrayList<>(List.of("a", "b", "c"));
boolean wasRemoved = list.remove("b"); // removes BY VALUE, not index
System.out.println(wasRemoved); // true
System.out.println(list);         // [a, c]
```

**A classic trap — `remove(int)` vs `remove(Object)` with `Integer` lists:**

```java
List<Integer> nums = new ArrayList<>(List.of(10, 20, 30));
nums.remove(1);        // calls remove(int index) — removes the element AT index 1 → removes 20
nums.remove(Integer.valueOf(1)); // calls remove(Object) — removes the VALUE 1 (not present, no-op)
```

Since `int` auto-boxes to `Integer`, Java has to pick between the two overloaded `remove()` methods — a bare `int` literal always resolves to `remove(int index)`, **not** `remove(Object)`. This is a genuinely common source of bugs with `List<Integer>` specifically.

### `removeAll(Collection<?> c)`

Removes every element that also appears in the given collection.

```java
List<String> list = new ArrayList<>(List.of("a", "b", "c", "d"));
list.removeAll(List.of("b", "d"));
System.out.println(list); // [a, c]
```

### `removeIf(Predicate<? super E> filter)` (Java 8+)

Removes every element matching a given condition — connects directly to the `Predicate` functional interface from the lambda tutorial.

```java
List<Integer> numbers = new ArrayList<>(List.of(1, 2, 3, 4, 5, 6));
numbers.removeIf(n -> n % 2 == 0); // remove all even numbers
System.out.println(numbers); // [1, 3, 5]
```

**Why this is preferred over manual removal in a loop:** manually removing elements while iterating with a for-each loop throws `ConcurrentModificationException` (as covered in the Iterator tutorial) — `removeIf()` handles this safely and concisely internally.

### `retainAll(Collection<?> c)`

**Keeps only** the elements that also appear in the given collection — removes everything else (essentially an intersection operation).

```java
List<String> list = new ArrayList<>(List.of("a", "b", "c", "d"));
list.retainAll(List.of("b", "d", "z"));
System.out.println(list); // [b, d]
```

### `clear()`

Removes **all** elements, leaving an empty list.

```java
list.clear();
System.out.println(list); // []
System.out.println(list.isEmpty()); // true
```

---

## 5. Searching and checking

### `containsAll(Collection<?> c)`

Returns `true` only if **every** element in the given collection is also present in this list.

```java
List<String> list = List.of("a", "b", "c", "d");
System.out.println(list.containsAll(List.of("a", "c")));   // true
System.out.println(list.containsAll(List.of("a", "z")));    // false — "z" isn't present
```

---

## 6. Sorting and ordering

### `sort(Comparator<? super E> c)` (Java 8+)

Sorts the list **in place**, according to the given `Comparator` (or `null` for natural ordering, if elements implement `Comparable`).

```java
List<Integer> numbers = new ArrayList<>(List.of(5, 3, 8, 1));
numbers.sort(null); // natural ordering
System.out.println(numbers); // [1, 3, 5, 8]

List<String> names = new ArrayList<>(List.of("Charlie", "alice", "Bob"));
names.sort(String.CASE_INSENSITIVE_ORDER);
System.out.println(names); // [alice, Bob, Charlie]
```

This connects directly to the `Comparator` tutorial — `list.sort(comparator)` is the instance-method equivalent of `Collections.sort(list, comparator)`.

### `reversed()` (Java 21+)

Returns a **reversed view** of the list — a genuinely recent addition.

```java
List<Integer> numbers = List.of(1, 2, 3);
List<Integer> reversed = numbers.reversed();
System.out.println(reversed); // [3, 2, 1]
```

---

## 7. Extracting portions

### `subList(int fromIndex, int toIndex)`

Returns a **view** (not a copy!) of the portion of the list between `fromIndex` (inclusive) and `toIndex` (exclusive).

```java
List<String> list = new ArrayList<>(List.of("a", "b", "c", "d", "e"));
List<String> sub = list.subList(1, 4);
System.out.println(sub); // [b, c, d]
```

**Important — it's a live view, backed by the original list:**

```java
sub.set(0, "Z"); // modifies the SUBLIST...
System.out.println(list); // [a, Z, c, d, e] — ...and the ORIGINAL list changes too!
```

This is the same "view, not copy" concept from `Arrays.asList()` — useful to know, since it can cause unexpected side effects if you assume `subList()` gives you an independent copy.

---

## 8. Conversion

### `toArray()`

Converts the list into an `Object[]` array.

```java
List<String> list = List.of("a", "b", "c");
Object[] array = list.toArray();
```

### `toArray(T[] a)`

Converts into a properly-typed array — the common, practical form.

```java
String[] array = list.toArray(new String[0]);
System.out.println(Arrays.toString(array)); // [a, b, c]
```

### `toArray(IntFunction<T[]> generator)` (Java 11+)

A cleaner, method-reference-friendly version:

```java
String[] array = list.toArray(String[]::new);
```

---

## 9. Iteration

### `iterator()`

Returns an `Iterator<E>` for manual traversal (covered in the last tutorial — safe removal during iteration).

```java
Iterator<String> it = list.iterator();
while (it.hasNext()) {
    System.out.println(it.next());
}
```

### `listIterator()` / `listIterator(int index)`

Returns a `ListIterator<E>` — supports **backward** traversal, in-place `set()`, and starting from a specific position.

```java
ListIterator<String> lit = list.listIterator();
while (lit.hasNext()) {
    String item = lit.next();
    if (item.equals("b")) lit.set("B"); // replace in place, safely
}
```

### `forEach(Consumer<? super E> action)` (Java 8+, from `Iterable`)

Applies an action to every element — connects to the `Consumer` functional interface.

```java
list.forEach(item -> System.out.println("Item: " + item));
list.forEach(System.out::println); // method reference form
```

### `stream()` / `parallelStream()` (from `Collection`)

Returns a `Stream<E>` for the processing-pipeline style covered in the Streams tutorial.

```java
List<String> upper = list.stream()
    .map(String::toUpperCase)
    .toList();
```

---

## 10. Equality and hashing

### `equals(Object o)`

Two `List`s are equal if they contain the **same elements, in the same order** — regardless of the concrete implementation class.

```java
List<String> a = new ArrayList<>(List.of("x", "y"));
List<String> b = new LinkedList<>(List.of("x", "y"));
System.out.println(a.equals(b)); // true — same elements, same order, even though different implementations
```

### `hashCode()`

Computed based on the elements' hash codes and order — two equal lists (per `equals()`) always produce the same `hashCode()`, which matters if you ever use a `List` as a key in a `HashMap` (unusual, but valid).

---

## 11. Creating lists — factory methods (from earlier tutorial, recapped here)

```java
List<String> empty = new ArrayList<>();                    // empty, mutable
List<String> withInitial = new ArrayList<>(List.of("a", "b")); // mutable, pre-filled
List<String> immutable = List.of("a", "b", "c");                // fully immutable
List<String> fixedSize = Arrays.asList("a", "b", "c");             // fixed-size view over an array
```

---

## Complete method reference table

|Method|Category|Returns|What it does|
|---|---|---|---|
|`add(E)`|add|`boolean`|appends to end|
|`add(int, E)`|add|`void`|inserts at index, shifts right|
|`addAll(Collection)`|add|`boolean`|appends all elements|
|`addAll(int, Collection)`|add|`boolean`|inserts all at index|
|`get(int)`|access|`E`|returns element at index|
|`size()`|access|`int`|number of elements|
|`isEmpty()`|access|`boolean`|true if size is 0|
|`indexOf(Object)`|access|`int`|first index of element, or -1|
|`lastIndexOf(Object)`|access|`int`|last index of element, or -1|
|`contains(Object)`|access|`boolean`|true if element exists|
|`set(int, E)`|modify|`E`|replaces element, returns old value|
|`remove(int)`|remove|`E`|removes by index, returns removed value|
|`remove(Object)`|remove|`boolean`|removes first matching value|
|`removeAll(Collection)`|remove|`boolean`|removes all matching elements|
|`removeIf(Predicate)`|remove|`boolean`|removes all matching a condition|
|`retainAll(Collection)`|remove|`boolean`|keeps only matching elements|
|`clear()`|remove|`void`|removes everything|
|`containsAll(Collection)`|search|`boolean`|true if all given elements are present|
|`sort(Comparator)`|order|`void`|sorts in place|
|`reversed()`|order|`List<E>`|returns a reversed view (Java 21+)|
|`subList(int, int)`|extract|`List<E>`|live view of a portion|
|`toArray()`|convert|`Object[]`|converts to array|
|`toArray(T[])`|convert|`T[]`|converts to typed array|
|`iterator()`|iterate|`Iterator<E>`|manual traversal|
|`listIterator()`|iterate|`ListIterator<E>`|bidirectional traversal|
|`forEach(Consumer)`|iterate|`void`|applies action to each element|
|`stream()`|iterate|`Stream<E>`|processing pipeline|
|`equals(Object)`|compare|`boolean`|same elements, same order|
|`hashCode()`|compare|`int`|consistent with equals|

---

## A combined, realistic example

```java
import java.util.*;

public class ListDemo {
    public static void main(String[] args) {
        List<String> team = new ArrayList<>();

        team.add("Alireza");
        team.add("Sara");
        team.add("Ali");
        team.add(1, "Reza"); // insert at position 1

        System.out.println(team); // [Alireza, Reza, Sara, Ali]

        team.set(0, "Alireza-Lead"); // replace, doesn't shift anything

        team.removeIf(name -> name.length() < 4); // remove short names

        team.sort(Comparator.naturalOrder());

        System.out.println("Final team: " + team);
        System.out.println("Contains Sara? " + team.contains("Sara"));
        System.out.println("Index of Sara: " + team.indexOf("Sara"));

        List<String> firstTwo = team.subList(0, Math.min(2, team.size()));
        System.out.println("First two: " + firstTwo);
    }
}
```

## Where this connects to everything else

Every method here operates with the Big O costs discussed in the data structures tutorial — `get()`/`set()` are `O(1)` on `ArrayList` but `O(n)` on `LinkedList`; `add(int, E)`/`remove(int)` are `O(n)` on `ArrayList` (shifting) but potentially `O(1)` on `LinkedList` if you're already positioned there via a `ListIterator`. Knowing the method _and_ which implementation you're using together tells you the real performance characteristics of your code — exactly the kind of decision the Collections hierarchy and Big O tutorials were building toward.


[[Java]]