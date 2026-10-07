
[The equals hashCode Contract - Java Programming](https://www.youtube.com/watch?v=8cI6cqASR98)

## The core intuition

Imagine a huge wall of numbered lockers. To store a coat for "Alireza", you don't search every locker for an empty one. You run his name through a formula that outputs a locker number, say 7, and put the coat there. To retrieve it later, you run the same formula and go straight to locker 7.

That formula is a **hash function**. It turns any object into a number, so you can jump directly to where it should live instead of searching. This is why `HashMap` and `HashSet` give you roughly **O(1)** lookups instead of O(n).

## The technical version

**Hashing** = mapping data of arbitrary size to a fixed-size integer (the _hash code_).

In Java, every object has this method, inherited from `Object`:

```java
public int hashCode()
```

```java
String s = "hello";
System.out.println(s.hashCode()); // 99162322 (always the same for "hello")
```

Every `HashMap` is backed by an array of **buckets**. Here is what happens on `map.put(key, value)`:

1. Call `key.hashCode()` to get an int.
2. Spread the bits (HashMap does `h ^ (h >>> 16)`, so high bits influence the result too).
3. Compute the bucket index: `index = (n - 1) & hash`, where `n` is the array length (always a power of 2, so this is a fast modulo).
4. Place the entry in that bucket.

`get(key)` repeats steps 1 to 3, then looks inside that bucket.

```java
Map<String, Integer> ages = new HashMap<>();
ages.put("Alireza", 25);
System.out.println(ages.get("Alireza")); // jumps straight to the right bucket
```

## Collisions: the unavoidable problem

There are about 4 billion possible `int` values but infinitely many possible objects, so two different keys will sometimes land in the same bucket. That's a **collision**. Java handles it like this:

- Entries in the same bucket form a **linked list**.
- `get()` finds the bucket via the hash, then walks the list calling **`equals()`** to find the real match.
- Since Java 8, if a bucket grows beyond **8 entries** (and the table has at least 64 buckets), the list converts to a **red-black tree**, so worst case drops from O(n) to O(log n).

So the two methods have distinct jobs:

|Method|Job|
|---|---|
|`hashCode()`|"Which bucket?" (fast, narrows the search)|
|`equals()`|"Which entry in that bucket is truly the same key?"|

## The hashCode/equals contract

This is the most important rule in Java hashing:

> If `a.equals(b)` is true, then `a.hashCode() == b.hashCode()` **must** be true.

The reverse is not required. Equal hash codes don't imply equal objects, because collisions are allowed.

Breaking the contract is the classic bug:

```java
class User {
    String name;
    User(String name) { this.name = name; }

    @Override
    public boolean equals(Object o) {
        return o instanceof User u && name.equals(u.name);
    }
    // forgot hashCode()!
}

Map<User, String> map = new HashMap<>();
map.put(new User("Ali"), "admin");
System.out.println(map.get(new User("Ali"))); // null
```

Both keys are "equal", but without an overridden `hashCode()`, `Object` uses the identity-based default, so the two objects hash to different buckets and `get` never even looks in the right place.

The fix:

```java
@Override
public int hashCode() {
    return Objects.hash(name); // combine all fields used in equals()
}
```

Or skip the boilerplate with a **record**, which generates both methods correctly:

```java
record User(String name) {}
```

## Nuances and gotchas

- **Never mutate a key after inserting it.** If a field used in `hashCode()` changes, the object now hashes to a different bucket than where it's stored, and it becomes effectively unfindable (a silent memory leak). This is why `String` and `Integer` (immutable) are ideal keys.
- **A good hash function distributes evenly.** `return 1;` is technically valid, but every key collides, degrading the map to a list/tree.
- **`String.hashCode()` is cached** inside the String object after the first computation, which is part of why strings are great keys. It's computed as `s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]`.
- **Resizing:** when entries exceed `capacity * 0.75` (the _load factor_), the table doubles and every entry is redistributed (_rehashing_). If you know the size upfront, `new HashMap<>(expectedSize)` avoids repeated resizes.
- **`HashSet` is just a `HashMap`** under the hood, using your elements as keys.
- **Iteration order isn't guaranteed** in `HashMap`, because order follows bucket positions. Use `LinkedHashMap` for insertion order or `TreeMap` for sorted order.
- **Null keys:** `HashMap` allows one `null` key (hash 0); `Hashtable` and `ConcurrentHashMap` don't.

## Don't confuse it with cryptographic hashing

The same word means something different in security. `hashCode()` is a fast, non-secure, 32-bit hash for data structures. Cryptographic hashes (SHA-256, bcrypt, Argon2) are designed to be irreversible and collision-resistant, used for passwords and integrity checks:

```java
MessageDigest md = MessageDigest.getInstance("SHA-256");
byte[] digest = md.digest("hello".getBytes(StandardCharsets.UTF_8));
```

In Spring Boot you'll meet this second kind via `BCryptPasswordEncoder` for storing passwords. Never use `hashCode()` for anything security-related.

## Quick recap

- A hash function maps an object to an int, which picks a bucket.
- `hashCode()` finds the bucket; `equals()` confirms the match.
- Collisions are normal and handled with lists, then trees.
- Always override `hashCode()` and `equals()` together, using the same fields, and keep keys immutable.

[[Hashing]]