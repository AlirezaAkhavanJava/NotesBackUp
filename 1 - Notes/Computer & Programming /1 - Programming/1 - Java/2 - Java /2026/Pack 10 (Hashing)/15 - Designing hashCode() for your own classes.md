
`hashCode()` is a method defined on `java.lang.Object` that returns an `int` summarizing an object's state. Hash-based collections (`HashMap`, `HashSet`, `LinkedHashMap`, `ConcurrentHashMap`) use that number to decide where to store and where to look for an object.

**Why it exists**

Searching a `List` for an element means calling `equals()` on elements one by one, which is O(n). A hash-based collection avoids that by turning the key into a number, using the number to pick a bucket (an index in an internal array), and only comparing objects inside that one bucket. That is what makes `HashMap.get()` O(1) on average.

The default `Object.hashCode()` is based on object identity, not on field values. So if you write your own class:

```java
class Point {
    final int x, y;
    Point(int x, int y) { this.x = x; this.y = y; }
}

Set<Point> set = new HashSet<>();
set.add(new Point(1, 2));
System.out.println(set.contains(new Point(1, 2))); // false
```

Two points with identical values are different objects with different identity hashes, so the lookup goes to the wrong bucket and never finds the match. Overriding `equals()` alone doesn't fix it either, because the lookup still lands in the wrong bucket before `equals()` is ever called. You need both.

**The contract**

Three rules, from the `Object` documentation:

1. If the fields used by `equals()` don't change, `hashCode()` must return the same value every time within one run of the program.
2. If `a.equals(b)` is true, then `a.hashCode() == b.hashCode()` must be true. This is the rule that breaks things when violated.
3. If `a.equals(b)` is false, the hashes are allowed to be equal (a collision), but the fewer collisions, the faster your collections.

The direction of rule 2 matters. Equal objects must have equal hashes, but equal hashes say nothing about equality. That is why a bucket lookup is always two steps: compare hashes, then confirm with `equals()`.

**How HashMap actually uses the number**

Roughly, in `HashMap.get(key)`:

```java
int h = key.hashCode();
h = h ^ (h >>> 16);              // spread high bits into low bits
int index = (table.length - 1) & h;   // pick bucket
// walk the bucket, for each entry: hash equal && (same reference || key.equals(entryKey))
```

Since the index uses only the low bits (table length is a power of two), a poor hash that only varies in high bits would pile everything into a few buckets. The `h ^ (h >>> 16)` step mitigates that, but it can't rescue a badly designed `hashCode()`. If every object returns the same value, all entries land in one bucket and you're back to O(n) (Java 8+ converts long buckets into balanced trees when keys are `Comparable`, which limits the damage to O(log n), but you shouldn't rely on it).

**Designing it**

The rule of design: use the same fields as `equals()`, or a subset of them. Never a field that `equals()` ignores, otherwise two equal objects could get different hashes (breaking rule 2). Using a subset is legal but produces more collisions.

The classic manual recipe combines fields with a multiplier:

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Point p)) return false;
    return x == p.x && y == p.y;
}

@Override
public int hashCode() {
    int result = Integer.hashCode(x);
    result = 31 * result + Integer.hashCode(y);
    return result;
}
```

Why multiply by 31 at each step? Without a multiplier, `x + y` makes `Point(1,2)` and `Point(2,1)` collide. Multiplying makes the position of each field matter. 31 is an odd prime, which spreads values well, and the JVM can compute `31 * i` as `(i << 5) - i`, a shift and a subtraction. Nothing magical, just a long-standing convention.

Per-type handling for the fields:

- primitives: use the wrapper's static method (`Integer.hashCode(i)`, `Long.hashCode(l)`, `Double.hashCode(d)`, `Boolean.hashCode(b)`)
- object references: `Objects.hashCode(ref)`, which returns 0 for null instead of throwing `NullPointerException`
- arrays: `Arrays.hashCode(arr)`, or `Arrays.deepHashCode(arr)` for nested arrays. Calling `arr.hashCode()` directly gives the identity hash, a common mistake.

In practice you'll mostly use the shortcut:

```java
@Override
public int hashCode() {
    return Objects.hash(name, age, email);
}
```

`Objects.hash(...)` does the 31-multiplication internally. The trade-off is that it creates a varargs array and boxes primitives on each call. That is fine for normal code, but for a hot path, like a key used millions of times per second, write it out manually.

You often don't need to write it at all. A record generates both methods from its components:

```java
record Point(int x, int y) {}   // equals() and hashCode() included
```

IDEs can generate them too (IntelliJ: Alt+Insert), and Lombok's `@EqualsAndHashCode` does the same by annotation.

**The mutable-field trap**

The hash is computed when you insert the object. If you later change a field that feeds the hash, the object is still sitting in its old bucket:

```java
Point p = new Point(1, 2);   // imagine x, y are non-final here
Set<Point> set = new HashSet<>();
set.add(p);
p.x = 99;
set.contains(p);   // false: lookup goes to the bucket for the new hash
```

The object is still in the set but effectively unreachable. This is why keys in maps and sets should be immutable (`String`, `Integer` and records behave this way), and why the fields feeding `hashCode()` should ideally be `final`.

A good exercise: write a small `Employee` class with `id`, `name` and a `List<String> skills`, implement `equals()` and `hashCode()` by hand, and test it in a `HashSet`. Then deliberately remove `hashCode()`, and then make a field non-final and mutate it, so you see both failures yourself.

One related piece we haven't touched: designing `equals()` and `hashCode()` for JPA entities in Spring Boot, where the usual advice above (use all fields) is actually wrong, because of generated IDs and lazy proxies. That is worth its own question once you reach Spring Data JPA.

[Watch this ](https://www.youtube.com/watch?v=BxkH-unIZHo)
[[Hashing]]