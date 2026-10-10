
# Java Utility Classes — `Arrays`, `Collections`, and Friends

## Quick reference table

|Utility|Package|Operates on|Purpose|
|---|---|---|---|
|`Arrays`|`java.util`|arrays (`int[]`, `String[]`, etc.)|sort, search, fill, compare, convert arrays|
|`Arrays.asList()`|`java.util`|array → `List`|fixed-size list view backed by an array|
|`Collections`|`java.util`|`Collection`/`List`/`Set`/`Map`|sort, search, wrap, create immutable/synchronized collections|
|`List.of()` / `Set.of()` / `Map.of()`|`java.util` (static interface methods)|none in, `List`/`Set`/`Map` out|create small, immutable collections|
|`Objects`|`java.util`|any object|null-safe `equals`, `hashCode`, `requireNonNull`|
|`Comparator`|`java.util`|any type `T`|defines custom orderings, used for sorting|
|`Stream` (`.toList()`, `Collectors`)|`java.util.stream`|any `Stream<T>`|build collections from a processing pipeline|
|`Optional`|`java.util`|a single possibly-absent value|avoid `null`, chain safe operations|
|`Iterator` / `ListIterator`|`java.util`|any `Collection`|manual, controlled traversal + safe removal during iteration|
|`Collections.EMPTY_LIST` etc. (constants)|`java.util`|none|pre-built, reusable empty collection singletons|
|`EnumSet` / `EnumMap`|`java.util`|`enum` types|specialized, highly efficient Set/Map for enum values|
|`StringJoiner`|`java.util`|strings|builds delimited strings (like `String.join`, but more flexible)|

---

## 1. `Arrays` — utility class for arrays

**Definition:** a `final` class of `static` methods for operating on raw Java arrays — sorting, searching, filling, comparing, and converting them.

```java
import java.util.Arrays;

int[] nums = {5, 3, 8, 1};

Arrays.sort(nums);                          // sorts in place: [1, 3, 5, 8]
int index = Arrays.binarySearch(nums, 5);     // fast search on a SORTED array
int[] copy = Arrays.copyOf(nums, 6);           // copies, padding with 0s if longer
int[] range = Arrays.copyOfRange(nums, 1, 3);   // copies a sub-range
boolean equal = Arrays.equals(nums, copy);        // element-wise comparison (== compares references!)
System.out.println(Arrays.toString(nums));          // [1, 3, 5, 8] — readable printout
Arrays.fill(nums, 0);                                  // fills every element with 0
```

**Problem it solves:** raw arrays have almost no built-in methods of their own (no `.sort()`, no `.toString()` that prints contents) — `Arrays` centralizes all the common array operations you'd otherwise hand-write.

---

## 2. `Arrays.asList()` — bridging an array into a `List`

```java
String[] array = {"a", "b", "c"};
List<String> list = Arrays.asList(array);
```

**Important gotcha — this is a _fixed-size_ view, not a real resizable `List`:**

```java
List<String> list = Arrays.asList("a", "b", "c");
list.set(0, "z");     // OK — modifying existing elements is fine
list.add("d");          // UnsupportedOperationException — can't resize!
```

**Why:** `Arrays.asList()` returns a special, fixed-size `List` implementation **backed directly by the original array** — it's a _view_, not a copy. Changes to the list reflect back into the array, and vice versa, but the size can never change since the underlying array's size is fixed.

```java
String[] array = {"a", "b", "c"};
List<String> list = Arrays.asList(array);
array[0] = "z";
System.out.println(list.get(0)); // "z" — the list reflects the array's change!
```

**If you need a real, resizable list from an array:**

```java
List<String> mutable = new ArrayList<>(Arrays.asList(array)); // wraps it in a real ArrayList
```

---

## 3. `Collections` — utility class for `Collection` types

Already covered in depth in the "Collection API" tutorial — the recap: a `final` class of `static` methods operating on `List`/`Set`/`Map`/`Collection` in general.

```java
import java.util.Collections;

List<Integer> nums = new ArrayList<>(List.of(5, 3, 8, 1));

Collections.sort(nums);                    // [1, 3, 5, 8]
Collections.reverse(nums);                  // [8, 5, 3, 1]
Collections.shuffle(nums);                   // random order
Collections.max(nums);                        // 8
Collections.min(nums);                          // 1
Collections.frequency(nums, 5);                   // count of occurrences

List<String> readOnly = Collections.unmodifiableList(names);      // read-only VIEW
List<String> synced = Collections.synchronizedList(new ArrayList<>()); // thread-safe wrapper
List<String> empty = Collections.emptyList();                            // immutable, empty
```

---

## 4. `List.of()` / `Set.of()` / `Map.of()` — modern immutable collection factories (Java 9+)

**Definition:** static factory methods **directly on the interfaces themselves** (`List`, `Set`, `Map`) that create small, genuinely **immutable** collections in one line.

```java
List<String> names = List.of("Alireza", "Sara", "Ali");
Set<Integer> numbers = Set.of(1, 2, 3);
Map<String, Integer> ages = Map.of("Alireza", 25, "Sara", 30);
```

**Immutable means fully immutable — unlike `Arrays.asList()`:**

```java
List<String> list = List.of("a", "b");
list.set(0, "z");   // UnsupportedOperationException
list.add("c");        // UnsupportedOperationException — cannot modify AT ALL
```

**Why prefer these over `Arrays.asList()` or `new ArrayList<>(...)`:** these are the modern, concise, genuinely-safe way to create fixed reference data (constants, test data, default values) — no accidental mutation possible, and far less verbose than the old `Collections.unmodifiableList(new ArrayList<>(...))` pattern.

**Also useful:** `Map.entry()` for building a map from pairs, and `Map.ofEntries()` for more than 10 entries (the varargs `Map.of()` is limited to 10 key-value pairs):

```java
Map<String, Integer> map = Map.ofEntries(
    Map.entry("a", 1),
    Map.entry("b", 2)
);
```

---

## 5. `Objects` — utility class for null-safe object operations

```java
import java.util.Objects;

Objects.equals(a, b);              // null-safe equals — no NullPointerException if either is null
Objects.hashCode(obj);               // null-safe hashCode — returns 0 for null
Objects.requireNonNull(obj);           // throws NullPointerException immediately if obj is null
Objects.requireNonNull(obj, "obj must not be null"); // with a custom message
Objects.isNull(obj);                     // true if obj is null
Objects.nonNull(obj);                     // true if obj is NOT null
Objects.toString(obj, "default");           // obj.toString(), or "default" if obj is null
```

**Problem it solves:** manually writing `a == null ? b == null : a.equals(b)` everywhere is verbose and error-prone. `Objects.equals()` does that safely, in one call — extremely common inside custom `equals()` implementations:

```java
@Override
public boolean equals(Object o) {
    if (!(o instanceof User other)) return false;
    return Objects.equals(this.name, other.name) && Objects.equals(this.email, other.email);
}
```

`Objects.requireNonNull()` is also a very common, idiomatic way to validate constructor/method arguments early:

```java
public User(String name) {
    this.name = Objects.requireNonNull(name, "name cannot be null");
}
```

---

## 6. `Comparator<T>` — defining custom sort orders

**Definition:** a **functional interface** (connects back to the lambda tutorial) representing a custom comparison rule between two objects of type `T` — used to control sorting without relying on a type's natural ordering (`Comparable`).

```java
List<String> names = new ArrayList<>(List.of("Charlie", "alice", "Bob"));

names.sort(Comparator.naturalOrder());              // default alphabetical
names.sort(Comparator.reverseOrder());                // reverse alphabetical
names.sort(String::compareToIgnoreCase);                // method reference — case-insensitive

names.sort(Comparator.comparing(String::length));         // sort by a derived value
names.sort(Comparator.comparing(String::length).thenComparing(Comparator.naturalOrder())); // multi-level sort
```

```java
List<User> users = ...;
users.sort(Comparator.comparing(User::getAge).reversed()); // sort by age, descending
```

**Difference from `Comparable`:** `Comparable<T>` (covered earlier) defines a type's **one, built-in** natural ordering (`compareTo()`, implemented on the class itself); `Comparator<T>` defines **any number of external, custom** orderings you can apply as needed, without modifying the class.

---

## 7. `Stream` collection-building methods — bridging streams back to collections

Since the Stream API tutorial covered processing, here's the collection-creation side specifically:

```java
List<String> list = stream.toList();                            // Java 16+, immutable
List<String> mutableList = stream.collect(Collectors.toList());   // mutable ArrayList
Set<String> set = stream.collect(Collectors.toSet());
Map<String, Integer> map = stream.collect(Collectors.toMap(s -> s, String::length));

String joined = stream.collect(Collectors.joining(", "));           // "a, b, c"
Map<Integer, List<String>> grouped = stream.collect(Collectors.groupingBy(String::length)); // group by a key
```

**Problem `Collectors` solves:** converting a processed `Stream` back into a concrete collection, with fine control over exactly _what kind_ of collection (list, set, map, grouped map) the results land in.

---

## 8. `Optional<T>` — avoiding `null`

```java
Optional<String> maybeValue = Optional.of("Alireza");     // definitely non-null
Optional<String> maybeEmpty = Optional.empty();              // explicitly absent
Optional<String> maybeNull = Optional.ofNullable(getName());  // might be null, wrapped safely

String value = maybeValue.orElse("default");                 // unwrap, or fallback
maybeValue.ifPresent(v -> System.out.println(v));               // act only if present
Optional<Integer> length = maybeValue.map(String::length);       // transform if present
```

**Problem it solves:** makes "this might not have a value" an explicit, visible part of a method's return type — instead of silently returning `null` and relying on the caller to remember to check, forcing that possibility to be handled deliberately.

---

## 9. `Iterator<E>` / `ListIterator<E>` — manual, controlled traversal

```java
List<String> list = new ArrayList<>(List.of("a", "b", "c"));
Iterator<String> it = list.iterator();

while (it.hasNext()) {
    String item = it.next();
    if (item.equals("b")) {
        it.remove(); // SAFE removal during iteration
    }
}
```

**Problem it solves:** removing from a `List` while using a for-each loop throws `ConcurrentModificationException` — the collection detects it was structurally modified mid-iteration. `Iterator.remove()` is the one safe way to remove elements _while_ iterating.

```java
// This throws ConcurrentModificationException:
for (String item : list) {
    if (item.equals("b")) list.remove(item); // WRONG — modifying during for-each
}
```

`ListIterator<E>` extends `Iterator` with backward traversal and in-place `set()`/`add()`:

```java
ListIterator<String> lit = list.listIterator();
while (lit.hasNext()) {
    String item = lit.next();
    lit.set(item.toUpperCase()); // replace the current element in place
}
```

---

## 10. `EnumSet` / `EnumMap` — specialized collections for enums

```java
enum Day { MON, TUE, WED, THU, FRI, SAT, SUN }

EnumSet<Day> weekdays = EnumSet.of(Day.MON, Day.TUE, Day.WED, Day.THU, Day.FRI);
EnumSet<Day> weekend = EnumSet.complementOf(weekdays); // everything NOT in weekdays

EnumMap<Day, String> schedule = new EnumMap<>(Day.class);
schedule.put(Day.MON, "Gym");
```

**Problem it solves:** `HashSet<Day>`/`HashMap<Day, X>` would work, but `EnumSet`/`EnumMap` are internally implemented using **bit vectors** (since an `enum`'s possible values are fixed and known), making them **dramatically faster and more memory-efficient** than their general-purpose hash-based equivalents — specifically for enum keys.

---

## 11. `StringJoiner` — building delimited strings

```java
StringJoiner joiner = new StringJoiner(", ", "[", "]"); // delimiter, prefix, suffix
joiner.add("Alireza").add("Sara").add("Ali");
System.out.println(joiner); // [Alireza, Sara, Ali]
```

**Simpler alternative for the common case — `String.join()`:**

```java
String result = String.join(", ", "Alireza", "Sara", "Ali"); // "Alireza, Sara, Ali"
String fromList = String.join(", ", someList);                 // works with a List<String> too
```

**When to use `StringJoiner` over `String.join()`:** when you need a prefix/suffix wrapping the whole thing (like `[...]` above), or when building the string incrementally across a loop rather than having all pieces upfront.

---

## Summary — when to reach for each

|Need|Tool|
|---|---|
|Sort/search/fill/copy a raw array|`Arrays`|
|Turn an array into a `List` (fixed-size view)|`Arrays.asList()`|
|Sort/search/wrap/synchronize a `Collection`|`Collections`|
|Create a small, truly immutable collection|`List.of()` / `Set.of()` / `Map.of()`|
|Null-safe equals/hashCode/validation|`Objects`|
|Custom sort order (not the type's natural one)|`Comparator`|
|Build a collection from a stream pipeline|`Collectors` (`toList`, `toSet`, `toMap`, `groupingBy`)|
|Represent "might not have a value"|`Optional`|
|Safely remove elements while iterating|`Iterator`|
|Highly efficient Set/Map keyed by an enum|`EnumSet` / `EnumMap`|
|Build a delimited string, especially incrementally|`StringJoiner` (or `String.join()` for the simple case)|

## Where this fits with everything else

This table rounds out the full picture from the Collections Framework and data structures tutorials: `Collection`/`Map`/`List`/`Set` (interfaces) and their implementations (`ArrayList`, `HashMap`, etc.) are the actual **data structures**; `Arrays`, `Collections`, `Objects`, `Comparator`, and the rest are the **static utility toolkits** that operate _on_ those structures — the exact same "interface vs. utility class" pattern you first saw with `System`/`Files` in the I/O tutorials, applied consistently across the entire Java standard library.


[[Java]]