

## Definition

A hash code is an `int` value returned by `hashCode()`. It is **data, not a reference**. It doesn't point to the object, to a memory location, or to a bucket. It is a number computed from the object, and nobody can follow it back to anything.

The pointers in a `HashMap` live somewhere else, and seeing where makes the whole mechanism clear.

## Where the pointers actually are

Inside a `HashMap` there are two layers:

```java
Node<K,V>[] table;          // the bucket array

static class Node<K,V> {
    final int hash;         // the cached hash code
    final K key;            // a REFERENCE to the key object
    V value;                // a REFERENCE to the value object
    Node<K,V> next;         // a REFERENCE to the next node in the same bucket
}
```

The real references are `table[i]` (pointing to a `Node`), `key`, `value` and `next`. The `int hash` sitting in the node is just a number kept for speed, so that resizing and comparisons don't have to call `hashCode()` again.

So the flow is:

1. `key.hashCode()` gives a plain number.
2. `(table.length - 1) & spread(hash)` turns that number into an array index.
3. `table[index]` is a real reference, which leads to a `Node`, which holds the reference to your key and value.

The hash code is only an input to step 2. It is never dereferenced.

## Example 1: a hash is computed from state, so it says nothing about location

```java
record Point(int x, int y) {}

Point a = new Point(1, 2);
Point b = new Point(1, 2);

System.out.println(a.hashCode() == b.hashCode());                 // true
System.out.println(a == b);                                       // false
System.out.println(System.identityHashCode(a)
                == System.identityHashCode(b));                   // false (almost certainly)
```

`a` and `b` are two different objects at two different places on the heap, yet they share a hash code, because the hash comes from field values. If the hash were an address, equal-valued objects could never share it. The last line shows the identity hash, which is a separate number that does differ per object.

## Example 2: turning a hash into a bucket yourself

This reproduces the index calculation `HashMap` does (default table size 16):

```java
static int bucketIndex(Object key, int tableSize) {
    int h = key.hashCode();
    h = h ^ (h >>> 16);              // spread: mix high bits into low bits
    return (tableSize - 1) & h;      // keep only the low bits
}

System.out.println(bucketIndex(1, 16));    // 1
System.out.println(bucketIndex(16, 16));   // 0
System.out.println(bucketIndex(17, 16));   // 1
System.out.println(bucketIndex(33, 16));   // 1
```

`Integer.hashCode()` returns the int itself, so keys 1, 17 and 33 have three different hashes, but with 16 buckets only the low four bits survive the `&`. All three land in bucket 1. That is a **bucket collision**: different hash codes, same bucket. It is normal and unavoidable, and `equals()` sorts it out inside the bucket.

## Example 3: same hash, different objects

```java
System.out.println("Aa".hashCode());   // 2112
System.out.println("BB".hashCode());   // 2112
System.out.println("Aa".equals("BB")); // false
```

This is a **hash collision**: two unequal objects with the identical number. It proves that the number can't identify an object. If you were handed `2112`, you couldn't say whether it came from `"Aa"`, `"BB"` or something else. That is also why the contract only works in one direction: equal objects must have equal hashes, but equal hashes don't imply equal objects.

## Example 4: the default hash and why it looks like an address

```java
Object o = new Object();
System.out.println(o);                                  // java.lang.Object@1b6d3586
System.out.println(Integer.toHexString(o.hashCode()));  // 1b6d3586
```

The default `toString()` is `getClass().getName() + "@" + Integer.toHexString(hashCode())`. The text after `@` is the hash code in hexadecimal, which is why it resembles a memory address. It isn't one:

- In modern HotSpot, the identity hash is generated pseudo-randomly the first time `hashCode()` is called, then stored in the object's header.
- It must stay constant for the object's whole life (contract rule 1), but the garbage collector moves objects around the heap. An address-based hash would change on every move, so an address can't be used.

## Mental checklist

|Thing|What it is|Changes when...|
|---|---|---|
|Object|The data on the heap|GC moves it (address changes)|
|Hash code|An `int` computed from fields (or assigned once, for identity hash)|Fields used by `hashCode()` change|
|Bucket index|`(n - 1) & spread(hash)`|The table resizes|
|`table[i]`, `Node.key`, `Node.next`|The real references|You insert or remove entries|




[[Hashing]]