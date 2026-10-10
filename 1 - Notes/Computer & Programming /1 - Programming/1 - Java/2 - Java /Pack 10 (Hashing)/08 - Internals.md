
 The important thing is to separate **`equals()` itself** from **how `HashMap`/`HashSet` use `equals()` and `hashCode()`**.

## 1. `equals()` internally

At the top of the Java hierarchy, `Object` provides:

```java
public boolean equals(Object obj) {
    return this == obj;
}
```

Conceptually, that's **reference identity**:

```text
a ──────┐
        ├── same object? → true
b ──────┘
```

So:

```java
User a = new User("Alireza");
User b = new User("Alireza");

a.equals(b); // false
```

because:

```text
a != b
```

They are two different objects in memory.

When you override `equals()`, **you replace that definition**:

```java
@Override
public boolean equals(Object obj) {
    User other = (User) obj;

    return this.username.equals(other.username);
}
```

Now you're saying:

```text
same username → equal
```

---

# 2. `hashCode()` internally

`hashCode()` returns an `int`:

```java
public native int hashCode();
```

For classes that don't override it, the JVM provides an identity-based hash value. The exact relationship between that value and the object's memory address is **JVM implementation-specific**—don't think of it simply as "the memory address."

When you override it, **you decide how the object's state produces the hash**.

For example:

```java
@Override
public int hashCode() {
    return username.hashCode();
}
```

So:

```text
User("Alireza")
       ↓
username.hashCode()
       ↓
     123456
```

---

# 3. Where it becomes interesting: `HashMap`

Suppose:

```java
Map<String, Integer> map = new HashMap<>();

map.put("Alireza", 25);
```

A simplified model of what happens internally:

```text
"Alireza"
    │
    ▼
hashCode()
    │
    ▼
hash value
    │
    ▼
HashMap transforms hash
    │
    ▼
bucket index
    │
    ▼
┌───────────────┐
│ bucket #5     │
│               │
│ "Alireza" →25 │
└───────────────┘
```

The hash is used to **locate a bucket**.

---

# 4. Then `equals()` enters the picture

Imagine another key produces the **same bucket**.

```text
Key A ──hash──► bucket 5
Key B ──hash──► bucket 5
```

This is a **collision**.

Java can't say:

> "Same bucket = same key."

Instead, it checks equality:

```text
hashCode()
    ↓
same bucket
    ↓
equals()
    ↓
Are these actually the same key?
```

So conceptually:

```java
if (hash1 == hash2 && key1.equals(key2)) {
    // same key
}
```

The real `HashMap` implementation is more optimized and has additional checks, but that's the correct mental model.

---

# 5. Example with a collision

Imagine:

```text
"ABC" → hash 100
"XYZ" → hash 100
```

Both go into the same bucket:

```text
Bucket 4

┌──────────────────┐
│ "ABC" → 10       │
│ "XYZ" → 20       │
└──────────────────┘
```

Now:

```java
map.get("XYZ");
```

Java roughly does:

```text
"XYZ"
  ↓
hashCode() → 100
  ↓
bucket 4
  ↓
compare keys
  ↓
"ABC".equals("XYZ") → false
  ↓
"XYZ".equals("XYZ") → true
  ↓
return 20
```

That's why **both methods are necessary**.

---

# 6. The complete mental model

```text
                 HashMap
                    │
             get("Alireza")
                    │
                    ▼
              hashCode()
                    │
                    ▼
              hash processing
                    │
                    ▼
               bucket index
                    │
                    ▼
             ┌─────────────┐
             │   Bucket    │
             │             │
             │ Entry       │
             │ Entry       │
             │ Entry       │
             └─────────────┘
                    │
                    ▼
                 equals()
                    │
             ┌──────┴──────┐
             │             │
           false         true
             │             │
         next entry      FOUND
                           │
                           ▼
                          value
```

### The simplest way to remember it

**`hashCode()` → WHERE should I look?**

**`equals()` → IS this the thing I'm looking for?**

And this is why overriding only one of them can break `HashMap`/`HashSet` behavior.


[[Hashing]]