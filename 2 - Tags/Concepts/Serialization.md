# Serialization in Java

**Core intuition first:** Serialization is Java's built-in mechanism for converting a live object in memory into a stream of bytes — so you can save it to disk, send it over a network, or stash it in a cache — and then reconstruct the exact same object later. Think of it as freezing an object into a byte-pattern and thawing it back out, like a molecular teleporter: the object must survive the trip intact.

```java
// Serialize
try (ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream("user.ser"))) {
    out.writeObject(user);
}

// Deserialize
try (ObjectInputStream in = new ObjectInputStream(new FileInputStream("user.ser"))) {
    User restored = (User) in.readObject();
}
```

---

## 1. The Contract: `Serializable`

A class participates by implementing `java.io.Serializable`. Critically, **it has zero methods** — it's a *marker interface*. Its only job is to give the JVM permission:

```java
public class User implements Serializable {
    private static final long serialVersionUID = 1L;

    private String name;
    private transient String password;   // excluded from serialization
    private int age;
}
```

**Why is it marker-based?** Java chose opt-in via interface rather than, say, serializing every object automatically, because serialization has security and correctness consequences (see section 5). The marker forces the developer to make an explicit decision.

**What actually gets serialized?**
- Instance fields (non-`static`, non-`transient`)
- The object's entire object graph — if `User` holds an `Address`, the `Address` is serialized too (and *it* must also be `Serializable`)
- `static` fields are excluded — they belong to the class, not the instance
- `transient` fields are skipped — useful for derived data, secrets, or non-serializable resources (sockets, streams, database connections)

---

## 2. `serialVersionUID` — the version fingerprint

Every serializable class has an implicit `serialVersionUID` hash computed from its structure. During deserialization, the JVM compares the stored UID against the current class's UID. Mismatch → `InvalidClassException`.

```java
private static final long serialVersionUID = 1L;  // explicit = YOU control compatibility
```

**Why declare it explicitly?** If you omit it, the compiler computes one from your class structure. Add a field, and the computed UID changes — suddenly old serialized files refuse to load even for trivial changes. An explicit UID means: "I take responsibility for compatibility; only bump this when I make breaking changes."

Nuances:
- Same UID + different fields = deserialization proceeds; **missing fields get default values, unknown new fields are ignored**. This is how "version tolerance" works.
- Changing a field's *type* or removing a field that's still present in the data breaks compatibility regardless of UID.

---

## 3. Customizing the process

If the default byte-format doesn't work (e.g., you want to encrypt a field, or reconstruct a `transient` field from other data), define hooks:

```java
private void writeObject(ObjectOutputStream out) throws IOException {
    out.defaultWriteObject();              // normal fields
    out.writeObject(encrypt(password));    // handle transient manually
}

private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
    in.defaultReadObject();
    this.password = decrypt((String) in.readObject());
}
```

There's also `readResolve()` / `writeReplace()` — return a different object during (de)serialization. This is how `enum` singletons and `BigDecimal`'s canonical form survive serialization. It matters for **deserialization-based attacks** on singletons: without `readResolve()`, reflection/serialization can create a second instance of your singleton.

---

## 4. Alternatives worth knowing

Java native serialization is *convenient but rarely the best choice* in modern systems:

| Approach | Pros | Cons |
|---|---|---|
| Java native serialization | Zero boilerplate, preserves object graph | Verbose format, slow, Java-only, fragile to class changes, security risk |
| JSON (Jackson/Gson) | Human-readable, language-agnostic, version-tolerant | No native support for complex object graphs, type info must be added (`@class` etc.) |
| Protocol Buffers / Avro | Compact, fast, schema-evolution designed | Requires schema definitions, codegen |
| Externalizable | Full manual control over format | You write all the logic |

**Why JSON/Protobuf usually win:** Java serialization bakes in the fully-qualified class name and exact field layout, tightly coupling your storage format to your class hierarchy. Renaming a package breaks old data. Schema-based formats decouple them.

---

## 5. The security gotcha (important!)

Deserializing untrusted data is dangerous. The byte stream encodes *class names to instantiate*. Crafted streams can trigger code execution in `readObject` methods of classes on your classpath (the "Java deserialization attack" — exploited in WebLogic, Apache Commons, etc. via gadgets).

Rules of thumb:
- **Never deserialize data you don't fully trust**
- Prefer JSON/Protobuf for external-facing boundaries
- If you must: use `ObjectInputFilter` (JEP 290, Java 9+) to whitelist allowed classes:

```java
ObjectInputFilter filter = ObjectInputFilter.Config.createFilter("com.myapp.*;java.base/*;!*");
ois.setObjectInputFilter(filter);
```

---

## 6. Edge cases & gotchas checklist

- **Inheritance:** If a superclass isn't `Serializable`, its state is lost — but it *must* have a no-arg constructor, which gets called during deserialization (unlike the serializable subclass, which bypasses constructors entirely).
- **Serialization bypasses constructors** — class invariants enforced in constructors aren't re-checked. Use `readObject` validation.
- **Circular references are fine** — the format handles back-references, no `StackOverflowError`.
- **`transient` on collections of non-serializable types** — the field must be `transient`, or the whole write fails.
- **Thread safety:** streams are not thread-safe; don't share `ObjectOutputStream` across threads without synchronization.
- **`Optional`, lambdas:** `Optional` is serializable, but lambdas generally aren't (can't control `serialVersionUID` of a synthetic class).

---

**Bottom line:** Serialization is the quick, zero-effort path for short-lived persistence (sessions, caches, RMI-style internals). For durable storage or cross-system communication, use schema-based formats — they're safer, faster, and evolve gracefully. Keep native serialization where its convenience outweighs its coupling: same-JVM caching and internal boundaries.


[[Java]]
[[Spring Framework]]