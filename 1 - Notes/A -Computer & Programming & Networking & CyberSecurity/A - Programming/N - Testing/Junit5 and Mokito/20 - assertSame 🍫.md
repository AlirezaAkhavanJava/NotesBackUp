

`assertSame` checks that **two references point to the exact same object** — not just equal content.

---

### 🧠 Syntax

```java
assertSame(expectedObject, actualObject);
```

---

### 🧩 Example

```java
String a = "Hello";
String b = a;
String c = new String("Hello");

assertSame(a, b);  // ✅ same reference
assertNotSame(a, c); // ❌ different objects, even if content is equal
```

---

### 🧾 In short

- `assertEquals` → compares **values** (`a.equals(b)`)
    
- `assertSame` → compares **references** (`a == b`)
    

✅ Use `assertSame` when you expect both variables to **literally be the same object in memory**, not just have the same data.


##### Tags : [[1 - Junit 5 🥭]]