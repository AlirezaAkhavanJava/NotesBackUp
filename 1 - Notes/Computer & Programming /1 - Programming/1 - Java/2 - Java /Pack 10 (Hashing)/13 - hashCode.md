
# `hashCode()`: quality, not just correctness

You already know the contract (equal objects must have equal hash codes), so this lesson covers what the contract doesn't say: **what makes a hash code good, and how it goes wrong in practice.**

## The core intuition

Think of a **postal sorting center**. The [^1]ZIP code doesn't find the house. It only decides which local post office the letter goes to, and the carrier there checks the street address (that's `equals()`).

The ZIP system is **correct** as long as the same address always gets the same ZIP. It is **useful** only if letters spread across many post offices. If every letter in the country got ZIP `00001`, delivery would still be correct, but one office would drown.

That is the whole lesson. The contract only guarantees **correctness**. **Speed depends on how well the codes spread out**, and Java never checks that for you.

## The story

Your ticket is `PERF-318`: _"MapCache lookups get slower the more tiles we load."_ You check out `perf-318-tile-cache` and open `Tile.java`. The hash came in with commit `4e1a9c7`, "simple hash":

```java
final class Tile {
    final int x, y;
    Tile(int x, int y) { this.x = x; this.y = y; }

    @Override public boolean equals(Object o) {
        return o instanceof Tile t && x == t.x && y == t.y;
    }
    @Override public int hashCode() { return x + y; }   // equal tiles -> equal hash. Contract satisfied.
}
```

Every test is green, and by the contract the code is correct. But the profiler on a 1,000 × 1,000 grid shows `HashMap.getNode` dominating the flame graph. You write a quick check in `HashCheck.java`:

```java
Set<Integer> distinct = new HashSet<>();
for (int x = 0; x < 1000; x++)
    for (int y = 0; y < 1000; y++)
        distinct.add(new Tile(x, y).hashCode());
System.out.println(distinct.size());   // 1999
```

That's **1,000,000 tiles sharing 1,999 hash codes**, so about 500 tiles pile into each bucket. The hash obeyed the contract perfectly and was still terrible.

You try the usual fix, the 31 formula (`31 * x + y`, same as `Objects.hash(x, y)`). The count rises to about 31,969, which is 16 times better, but still around 31 tiles per code. **The surprise: the 31 isn't magic.** It works for strings because characters are small and varied. Here `y` ranges up to 999, so `(x, y+31)` and `(x+1, y)` produce the same value.

Your decision: the multiplier must be **larger than the range of the field it separates**, so you write:

```java
@Override public int hashCode() { return x * 1_000_003 + y; }   // 1,000,000 distinct codes
```

The distinct count is now 1,000,000, and the flame graph flattens. You add a comment explaining why the constant isn't 31, so nobody "cleans it up" in code review.

## Formal detail: what makes a hash good

`hashCode()` has no formal requirement about distribution, but the performance of every hash structure depends on these properties:

|Property|Meaning|
|---|---|
|**Deterministic**|Same fields give the same code (the contract)|
|**Uniform**|Codes spread evenly across all 2³² values|
|**Avalanche**|A tiny change in input (`y` goes from 5 to 6) produces a very different output|
|**Cheap**|It's called on every `get`, `put`, `contains`, so it must be fast|

**Pigeonhole principle:** there are only 4.29 billion possible `int` values, so collisions are mathematically unavoidable for large domains. Your goal isn't zero collisions, it's **even spreading**.

The most common mistakes are the ones in your ticket: **`x + y` or `x ^ y`** are symmetric, so `(1,2)` and `(2,1)` always collide. They also produce narrow ranges, and XOR of two equal values gives 0.

## How the built-in types compute theirs

|Type|`hashCode()`|
|---|---|
|`Integer`, `Short`, `Byte`, `Character`|the value itself|
|`Long`|`(int)(v ^ (v >>> 32))`, high and low halves folded together|
|`Double`|takes the 64 raw bits, then the same fold as `Long`|
|`Boolean`|`1231` for true, `1237` for false|
|`List`|`31 * h + element.hashCode()` over the elements, starting from 1|
|`Set`|the **sum** of element hashes, so order doesn't matter|
|`Map`|the sum of each entry's `key.hashCode() ^ value.hashCode()`|
|**Enum**|**identity-based** (see gotchas)|
|**Array**|**identity-based** (see gotchas)|

For your own fields, use the static helpers (`Double.hashCode(d)`, `Long.hashCode(l)`, `Boolean.hashCode(b)`) instead of boxing.

## Writing your own: edge cases

- **`Objects.hash(...)` has a cost.** It's a varargs call, so it allocates an array and boxes any primitives on every call. Fine in normal code, but in a hot path write the formula by hand.
- **`Objects.hash(x)` is not `x.hashCode()`.** It's `31 + x.hashCode()`, because it starts its running total at 1. Never mix the two styles for the same field.
- **Using fewer fields than `equals()` is legal.** `hashCode()` can use only `id` while `equals()` checks five fields, and it stays correct. It just spreads less well. The reverse (using a field `equals()` ignores) breaks the contract.
- **Expensive hashes can be cached.** For an immutable class with many fields, store the result in a private `int` field after the first call, like `String` does.

## Gotchas

**1. Enum and array hashes change between runs.** `Enum.hashCode()` and array `hashCode()` use the identity hash, which differs on every JVM start. A `HashMap` with enum keys can iterate in a different order each run, which is a classic "flaky test" cause. Use `EnumMap` for enum keys, and `Arrays.hashCode(arr)` instead of `arr.hashCode()`. Never use an array as a map key, because two arrays with the same contents are different keys.

**2. Never persist or send a hash code.** Only a few types (like `String`) have a documented formula. Don't save `hashCode()` in a database, use it for sharding across machines, or compare it across services. Systems that partition data use their own fixed hash functions.

**3. Negative values break your own bucket math.** If you ever compute a bucket by hand, `hash % n` can be negative, and the "fix" `Math.abs(hash) % n` fails for `Integer.MIN_VALUE`, because `Math.abs` of that value is still negative. Use `Math.floorMod(hash, n)`.

**4. Attackers can craft collisions.** The string formula is simple enough that `"Aa"` and `"BB"` both hash to `2112` (`65*31+97` and `66*31+66`). Because of how the polynomial works, you can concatenate those blocks to generate thousands of different strings with **the same hash**. Sending those as request parameters or JSON keys once let attackers crush servers (**hash flooding**). Java 8's tree buckets reduced the damage by turning long chains into trees, which we'll cover in the `HashMap` internals lesson.

## Definitions

- **Collision:** two different objects with the same hash code (or landing in the same bucket).
- **Distribution:** how evenly the codes spread across the possible values.
- **Avalanche effect:** small input changes causing large output changes.
- **Pigeonhole principle:** more possible inputs than outputs means collisions are guaranteed.
- **Hash flooding:** deliberately sending colliding keys to degrade a hash table to linear speed.

## Quick recap

- The contract guarantees **correctness**, never **speed**. Speed comes from how evenly the hashes spread.
- `x + y` and `x ^ y` are symmetric and narrow, so they're bad. The 31 formula isn't universal either: the multiplier should exceed the range of the field it separates.
- `Objects.hash` allocates and boxes, and `Objects.hash(x) != x.hashCode()`.
- Enum and array hashes are identity-based, so they change per run. Don't persist, share or shard on `hashCode()`.
- Compute buckets with `Math.floorMod`, never `%` or `Math.abs`.




[[Hashing]]

[^1]: A **ZIP code** is a numerical code used by postal services to identify a specific geographic area for mail delivery.
