
# The `Object` Class and the `equals()` / `hashCode()` / `toString()` Contract

## Part 1 — The `Object` Class

`java.lang.Object` is the root of the Java class hierarchy. Every class implicitly extends `Object` (directly or indirectly). Even arrays and enums are `Object` subtypes.

Because of this, every object inherits these methods:

| Method | Purpose |
|---|---|
| `equals(Object)` | Logical equality |
| `hashCode()` | Hash value for hash-based collections |
| `toString()` | String representation |
| `getClass()` | Runtime class (reflection) |
| `clone()` | Shallow copy (protected) |
| `finalize()` | Deprecated; pre-GC cleanup |
| `notify()`, `notifyAll()`, `wait()` | Thread coordination |

The three you override most often are `equals`, `hashCode`, and `toString`. The first two form a **contract** that hash-based collections depend on.

---

## Part 2 — The `equals()` Contract

The `equals` method defines **logical equality**, not identity.

Default `Object.equals` is reference equality:

```java
public boolean equals(Object obj) {
    return this == obj;
}
```

### The five rules (from `Object` Javadoc)

An `equals` implementation must be:

1. **Reflexive** — `x.equals(x)` must return `true`.
2. **Symmetric** — `x.equals(y)` must return `true` if and only if `y.equals(x)` returns `true`.
3. **Transitive** — if `x.equals(y)` and `y.equals(z)`, then `x.equals(z)`.
4. **Consistent** — repeated calls with unchanged state must return the same result.
5. **Null-safe** — `x.equals(null)` must return `false`, never throw.

### Why each rule matters

**Reflexive:** Collections call `equals` to check containment. If `x.equals(x)` is false, `list.contains(x)` fails even when `x` is in the list.

**Symmetric:** If `a.equals(b)` is true but `b.equals(a)` is false, behavior depends on argument order. This silently breaks `Set`, `Map`, and `List` operations.

```java
// Broken symmetry example
class CaseInsensitiveString {
    private final String s;
    CaseInsensitiveString(String s) { this.s = s; }

    @Override
    public boolean equals(Object o) {
        if (o instanceof CaseInsensitiveString)
            return s.equalsIgnoreCase(((CaseInsensitiveString) o).s);
        if (o instanceof String)
            return s.equalsIgnoreCase((String) o); // one-way!
        return false;
    }
}
```

`cis.equals("hello")` is true, but `"hello".equals(cis)` is false. This violates symmetry.

**Transitive:** Inheritance often breaks transitivity. If `Point` and `ColorPoint` both override `equals`, you can get `a.equals(b)` true, `b.equals(c)` true, but `a.equals(c)` false.

**Consistent:** If `equals` depends on mutable state, changing that state changes equality. Objects used as `HashMap` keys must not change in ways that affect `equals`/`hashCode`.

**Null-safe:** `x.equals(null)` must return `false`. Using `instanceof` naturally handles this because `null instanceof T` is always `false`.

### A correct `equals` implementation

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;                        // reflexivity + fast path
    if (o == null || getClass() != o.getClass()) return false; // null-safe + type check
    Person person = (Person) o;
    return age == person.age &&
           Objects.equals(name, person.name);
}
```

Key points:
- `this == o` short-circuits identity.
- `o == null` handles null.
- `getClass() != o.getClass()` enforces symmetry and transitivity by requiring exact type.
- `instanceof` is an alternative but allows subclass equality, which can break symmetry/transitivity.
- `Objects.equals` handles null fields cleanly.

### `getClass()` vs `instanceof`

- `getClass()` — strict: only same exact class is equal. Safer for symmetry/transitivity.
- `instanceof` — allows subclasses to be equal to superclass instances. More flexible but dangerous if subclass adds state.

Use `getClass()` when subclasses add meaningful state. Use `instanceof` only when you control the hierarchy and can guarantee the contract holds.

---

## Part 3 — The `hashCode()` Contract

`hashCode` returns an `int` used by hash-based collections (`HashMap`, `HashSet`, `Hashtable`, `ConcurrentHashMap`).

Default `Object.hashCode` is typically derived from the object's memory address (implementation-dependent).

### The three rules

1. **Consistency during execution** — repeated calls on an unchanged object must return the same value.
2. **Equal objects must have equal hash codes** — if `x.equals(y)`, then `x.hashCode() == y.hashCode()`.
3. **Unequal objects may share a hash code** — collisions are allowed; they just cost performance.

Rule 2 is the one people break, and it silently corrupts collections. Rule 3 is not a requirement — it is a possibility.

### The critical asymmetry

- `equals` equal → `hashCode` **must** be equal.
- `hashCode` equal → `equals` **may** be false (collision).

So `hashCode` can be equal for unequal objects, but never the reverse.

### A correct `hashCode` implementation

```java
@Override
public int hashCode() {
    return Objects.hash(name, age);
}
```

Or manual:

```java
@Override
public int hashCode() {
    int result = name != null ? name.hashCode() : 0;
    result = 31 * result + age;
    return result;
}
```

`31` is used because it is an odd prime, and `31 * i == (i << 5) - i` is a fast JVM optimization.

---

## Part 4 — Why Breaking the Contract Corrupts `HashMap` / `HashSet`

Hash-based collections use a two-step lookup:

1. Compute `hashCode()` to find the **bucket**.
2. Use `equals()` to find the exact entry within that bucket.

If the contract is broken, these two steps disagree, and the collection silently misbehaves.

### Scenario 1 — Equal objects with different hash codes

```java
class Key {
    String id;
    Key(String id) { this.id = id; }

    @Override
    public boolean equals(Object o) {
        return o instanceof Key && ((Key) o).id.equals(id);
    }
    // no hashCode override — inherits identity hash
}

Map<Key, String> map = new HashMap<>();
map.put(new Key("a"), "value");

System.out.println(map.get(new Key("a"))); // null!
```

Why:
- The two `Key` objects are `equals`.
- But they have different identity hash codes.
- They land in **different buckets**.
- `get` never finds the entry.

The map contains the entry, but you can never retrieve it with an equal key. This is a silent logic bug, not an exception.

### Scenario 2 — Mutable fields in `hashCode`

```java
Map<Person, String> map = new HashMap<>();
Person p = new Person("Alice", 30);
map.put(p, "engineer");

p.setName("Bob"); // changes hashCode
System.out.println(map.get(p)); // null!
```

Why:
- The entry was stored in the bucket for the old hash.
- After mutation, `hashCode` changes.
- Lookup computes the new hash and searches a different bucket.
- The entry is effectively lost.

Rule: **Never use mutable fields in `equals`/`hashCode` for objects used as keys.**

### Scenario 3 — Asymmetric `equals` in a `HashSet`

```java
Set<Object> set = new HashSet<>();
set.add("hello");
set.add(new CaseInsensitiveString("HELLO"));
```

Depending on hash codes and insertion order, the set may contain both, one, or behave inconsistently on `contains`. The set cannot reason about equality reliably.

### Scenario 4 — Inconsistent `equals` in `HashMap`

If `equals` returns different results across calls for the same unchanged objects, `HashMap.get` can return different values at different times. The map's internal invariants are violated, and you get nondeterministic behavior.

### What "silently corrupts" means

The collection does not throw. It does not warn. It simply:
- Fails to find entries that are present.
- Stores duplicate "equal" entries.
- Returns `null` from `get` for keys that were `put`.
- Produces different results across runs or JVM versions.

This is why `equals`/`hashCode` bugs are among the most expensive to debug.

---

## Part 5 — The `toString()` Contract

`toString` returns a string representation of the object.

Default: `ClassName@hexHashCode`, e.g. `Person@1b6d3586`.

### Rules (from `Object` Javadoc)

- Should return a concise but informative string.
- Should be readable by humans.
- Not required to be unique.
- Should not throw.
- Should not expose sensitive data (passwords, tokens).

### Why override it

- Logging and debugging.
- Error messages.
- Collection printing (`List.toString` calls each element's `toString`).
- IDE debuggers.

```java
@Override
public String toString() {
    return "Person{name='" + name + "', age=" + age + "}";
}
```

### Best practices

- Include class name and key fields.
- Avoid expensive computation.
- Avoid calling methods that can throw.
- Never include sensitive information.
- Keep it stable for tests if you assert on it.

---

## Part 6 — Records and Auto-Generated Methods

Java records automatically generate `equals`, `hashCode`, and `toString` based on components.

```java
record Point(int x, int y) {}
```

This gives:
- `equals` — all components equal, same type.
- `hashCode` — derived from all components.
- `toString` — `Point[x=1, y=2]`.

Records are ideal when you want value semantics without writing boilerplate. They are immutable, so the mutable-key problem disappears.

---

## Part 7 — Full Example: A Correct Value Class

```java
import java.util.Objects;

public final class Person {
    private final String name;
    private final int age;

    public Person(String name, int age) {
        this.name = Objects.requireNonNull(name);
        this.age = age;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Person person = (Person) o;
        return age == person.age && name.equals(person.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, age);
    }

    @Override
    public String toString() {
        return "Person{name='" + name + "', age=" + age + "}";
    }
}
```

This class:
- Is reflexive, symmetric, transitive, consistent, and null-safe.
- Has `hashCode` consistent with `equals`.
- Is immutable, so hash codes never change.
- Works correctly as a `HashMap` key and `HashSet` element.

---

## Part 8 — Checklist and Common Pitfalls

### Checklist when overriding `equals`
- [ ] Use `@Override`.
- [ ] Check `this == o` first.
- [ ] Check `null` and type.
- [ ] Compare all significant fields.
- [ ] Use `Objects.equals` for nullable fields.
- [ ] Keep it consistent with `hashCode`.

### Checklist when overriding `hashCode`
- [ ] Use the same fields as `equals`.
- [ ] Use `Objects.hash` or the `31 *` pattern.
- [ ] Never use mutable fields for keys.
- [ ] Keep it stable during object lifetime.

### Common pitfalls

| Pitfall | Consequence |
|---|---|
| Override `equals` but not `hashCode` | `HashMap`/`HashSet` lookups fail silently |
| Override `hashCode` but not `equals` | Collisions handled by `equals`, but unequal objects may be treated as equal if `equals` is identity |
| Use mutable fields in `hashCode` | Entries lost after mutation |
| Use `instanceof` with subclass state | Symmetry/transitivity broken |
| Make `equals` depend on external state | Inconsistent results |
| Throw from `equals`/`hashCode` | Collections crash |
| Include sensitive data in `toString` | Security leak in logs |

### The golden rule

> If `a.equals(b)` is true, then `a.hashCode()` must equal `b.hashCode()`.
> The reverse is not required.

---

## Quick Reference

| Method | Contract | Breaks what |
|---|---|---|
| `equals` | Reflexive, symmetric, transitive, consistent, null-safe | `Set`, `Map`, `List.contains` |
| `hashCode` | Consistent; equal objects → equal hashes | `HashMap`, `HashSet`, `Hashtable` |
| `toString` | Informative, non-throwing, safe | Logging, debugging, assertions |

The `equals`/`hashCode` contract is not optional etiquette — it is a structural requirement for Java's hash-based collections. Break it, and your data structures will lie to you without ever throwing an exception.


[[Java]]