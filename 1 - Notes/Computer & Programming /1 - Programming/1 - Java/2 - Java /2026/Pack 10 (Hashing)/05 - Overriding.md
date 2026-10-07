
 **Overriding `equals()` and `hashCode()` means replacing the default behavior inherited from `Object` with behavior that matches what you consider “the same object.”**

### 1. The default behavior

Suppose:

```java
class User {
    String username;

    User(String username) {
        this.username = username;
    }
}
```

Then:

```java
User a = new User("Alireza");
User b = new User("Alireza");

System.out.println(a.equals(b)); // false
```

Even though both contain `"Alireza"`.

Why? Because `Object.equals()` essentially compares **object identity** by default:

```text
a ───────► User object #1
b ───────► User object #2

Different objects → false
```

---

### 2. Override `equals()`

You can define your own meaning of equality:

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;

    if (!(o instanceof User user))
        return false;

    return Objects.equals(username, user.username);
}
```

Now:

```java
User a = new User("Alireza");
User b = new User("Alireza");

a.equals(b); // true
```

You've told Java:

> Two `User`s are equal if their `username`s are equal.

---

### 3. Override `hashCode()` too

If you change the definition of equality, you **must make `hashCode()` consistent with it**:

```java
@Override
public int hashCode() {
    return Objects.hash(username);
}
```

Now:

```text
User("Alireza")
      │
      ├── equals() ───► equal
      │
      └── hashCode() ──► same hash
```

This is particularly important for:

```java
HashMap
HashSet
HashTable
```

### The professional rule

When you override:

```java
equals()
```

**you almost always need to override:**

```java
hashCode()
```

because Java's contract requires:

```text
a.equals(b) == true
        ↓
a.hashCode() == b.hashCode()
```

But:

```text
a.hashCode() == b.hashCode()
        ↓
does NOT guarantee
        ↓
a.equals(b) == true
```

That's the key relationship.



[[Hashing]]