
These two methods are **closely connected in Java**, especially with `HashMap` and `HashSet`.

### `equals()` vs `hashCode()`

Think of them as answering two different questions:

```text
hashCode()
    ↓
"Which bucket should I look in?"

equals()
    ↓
"Is this actually the object/value I'm looking for?"
```

### Example

```java
String a = new String("Alireza");
String b = new String("Alireza");

System.out.println(a.equals(b));      // true
System.out.println(a.hashCode());     // same
System.out.println(b.hashCode());     // same
```

Why?

Because `a` and `b` represent the **same value**.

The Java contract says:

> If `a.equals(b)` is `true`, then `a.hashCode()` **must be equal to** `b.hashCode()`.

But the reverse is **not** guaranteed:

```text
same hashCode
    ↓
does NOT necessarily mean
    ↓
equals() == true
```

That's because of **hash collisions**.

---

### How `HashMap` uses both

Suppose:

```java
Map<String, Integer> map = new HashMap<>();

map.put("Alireza", 25);
```

Later:

```java
map.get("Alireza");
```

Conceptually:

```text
"Alireza"
    │
    ▼
hashCode()
    │
    ▼
find bucket
    │
    ▼
compare keys with equals()
    │
    ▼
"Alireza".equals("Alireza")
    │
    ▼
true
    │
    ▼
25
```

So:

**`hashCode()` gets you to the neighborhood.**  
**`equals()` identifies the exact house.**

---

### Why you usually override both

Suppose you create:

```java
class User {
    String username;

    User(String username) {
        this.username = username;
    }
}
```

If you want two `User` objects with the same username to be considered equal, you should implement **both**:

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof User user)) return false;

    return Objects.equals(username, user.username);
}

@Override
public int hashCode() {
    return Objects.hash(username);
}
```

Then:

```java
User a = new User("Alireza");
User b = new User("Alireza");

System.out.println(a.equals(b));      // true
System.out.println(a.hashCode() == b.hashCode()); // true
```

### The rule to memorize

```text
equals() == true
       ↓
hashCode() MUST be the same

hashCode() == same
       ↓
equals() MAY be true OR false
```

That's the core relationship between them.


[[Hashing]]