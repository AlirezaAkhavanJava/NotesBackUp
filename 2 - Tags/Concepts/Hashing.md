
**Hashing** in Java is the process of converting an object or value into a fixed-size integer called a **hash code**. That hash code is used by hash-based collections like `HashMap`, `HashSet`, `Hashtable`, and `ConcurrentHashMap` to quickly find, insert, and remove elements.

In Java, hashing is mainly built around two methods from `java.lang.Object`:

```java
int hashCode()
boolean equals(Object obj)
```

### 1. What `hashCode()` does

Every Java object has a `hashCode()` method. It returns an `int`.

```java
Object obj = new Object();
System.out.println(obj.hashCode());
```

By default, `Object.hashCode()` is typically based on the object’s identity, not its contents. So two different objects with the same field values usually have different hash codes unless you override `hashCode()`.

Example:

```java
public class User {
    private String name;
    private int age;

    // constructors, getters...
}
```

Without overriding `hashCode()`, two `User` objects with the same name and age are treated as different keys in a `HashMap`.

### 2. The `hashCode()` / `equals()` contract

This is the most important rule in Java hashing:

1. If two objects are equal according to `equals()`, they **must** have the same `hashCode()`.
2. If two objects have the same `hashCode()`, they are **not necessarily equal**.
3. If two objects are not equal, they can still have the same `hashCode()` — this is called a **hash collision**.
4. `hashCode()` should return the same value as long as the object is not modified.

So if you override `equals()`, you must also override `hashCode()`.

Example:

```java
import java.util.Objects;

public class User {
    private String name;
    private int age;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof User)) return false;
        User user = (User) o;
        return age == user.age && Objects.equals(name, user.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, age);
    }
}
```

Now two `User` objects with the same `name` and `age` will be equal and have the same hash code.

### 3. How hash-based collections use hashing

Take `HashMap` as an example.

When you do:

```java
Map<String, Integer> map = new HashMap<>();
map.put("apple", 10);
```

Java roughly does this:

1. Calls `"apple".hashCode()`.
2. Converts that hash code into an index for an internal array of buckets.
3. Stores the key-value pair in that bucket.
4. When you call `map.get("apple")`, it hashes `"apple"` again, finds the bucket, and then uses `equals()` to find the exact key.

So:

- `hashCode()` finds the general area / bucket.
- `equals()` identifies the exact key.

This is why both methods matter.

### 4. Collisions

A collision happens when two different keys produce the same hash code or map to the same bucket.

Example:

```java
"FB".hashCode() == "Ea".hashCode() // true in Java
```

They are different strings but have the same hash code.

Hash-based collections handle collisions:

- In older Java versions, `HashMap` used linked lists for colliding entries.
- Since Java 8, if a bucket becomes too large, it can be converted into a balanced tree to improve worst-case performance.
- Even with collisions, `equals()` ensures the correct key is found.

### 5. Example with `HashSet`

```java
Set<String> set = new HashSet<>();
set.add("java");
set.add("java");

System.out.println(set.size()); // 1
```

`HashSet` uses `hashCode()` and `equals()` to determine duplicates. Since both strings are equal, only one is stored.

### 6. Bad hash codes

A bad `hashCode()` implementation can cause many collisions, turning fast `O(1)` operations into slow `O(n)` operations.

Bad example:

```java
@Override
public int hashCode() {
    return 1; // every object goes into the same bucket
}
```

This is valid but terrible for performance.

Good hash codes:

- Are consistent with `equals()`
- Spread values evenly
- Are fast to compute
- Use the same fields as `equals()`

Java provides helpers:

```java
Objects.hash(field1, field2, field3);
Objects.equals(field1, other.field1);
Arrays.hashCode(array);
Arrays.equals(array1, array2);
```

### 7. Mutable keys are dangerous

If an object is used as a key in a `HashMap` and then you change a field that is part of `hashCode()` or `equals()`, the map may not find it anymore.

```java
Map<User, String> map = new HashMap<>();
User user = new User("Alice", 25);
map.put(user, "data");

user.setName("Bob"); // changes hashCode
map.get(user);       // may return null
```

So keys in hash-based collections should ideally be immutable.

### 8. Hashing vs cryptographic hashing

In Java, “hashing” can also mean cryptographic hashing, such as SHA-256:

```java
MessageDigest digest = MessageDigest.getInstance("SHA-256");
byte[] hash = digest.digest("hello".getBytes());
```

But when Java developers talk about hashing in collections, they usually mean `hashCode()` and hash-based data structures.

### 9. Relation to Lombok and records

If you use Lombok:

```java
@EqualsAndHashCode
public class User {
    private String name;
    private int age;
}
```

Lombok generates `equals()` and `hashCode()` for you.

Java `record` types also generate `equals()` and `hashCode()` automatically based on their components:

```java
record User(String name, int age) {}
```

### Summary

Hashing in Java is:

- Converting an object into an `int` via `hashCode()`
- Used by `HashMap`, `HashSet`, `Hashtable`, `ConcurrentHashMap`, etc.
- Works together with `equals()`
- Must follow the contract: equal objects must have equal hash codes
- Collisions are allowed and handled
- Bad or mutable hash codes can break collections and hurt performance

In short: **`hashCode()` finds the bucket, `equals()` finds the exact object.**




[[Java]]