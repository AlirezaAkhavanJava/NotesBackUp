
# The `Object` Class and `Cloneable` — Full Methods, `clone()`, and the Cloneable Contract

`java.lang.Object` is the root of the Java class hierarchy. Every class inherits its methods, whether you use them or not. This guide covers **all** `Object` methods, then goes deep on `clone()` and the `Cloneable` interface — the most misunderstood part of the API.


## Part 1 — Complete `Object` Method Reference

| Method | Signature | Final? | Overridable? | Purpose |
|---|---|---|---|---|
| `clone()` | `protected Object clone() throws CloneNotSupportedException` | No | Yes | Creates a copy of the object |
| `equals(Object)` | `public boolean equals(Object obj)` | No | Yes | Logical equality |
| `finalize()` | `protected void finalize() throws Throwable` | No | Yes (deprecated) | Pre-GC cleanup hook |
| `getClass()` | `public final Class<?> getClass()` | **Yes** | **No** | Returns runtime class |
| `hashCode()` | `public int hashCode()` | No | Yes | Hash value for hash collections |
| `notify()` | `public final void notify()` | **Yes** | **No** | Wakes one waiting thread |
| `notifyAll()` | `public final void notifyAll()` | **Yes** | **No** | Wakes all waiting threads |
| `toString()` | `public String toString()` | No | Yes | String representation |
| `wait()` | `public final void wait() throws InterruptedException` | **Yes** | **No** | Waits until notified |
| `wait(long)` | `public final void wait(long timeout) throws InterruptedException` | **Yes** | **No** | Waits with timeout |
| `wait(long, int)` | `public final void wait(long timeout, int nanos) throws InterruptedException` | **Yes** | **No** | Waits with nanosecond precision |

The **five thread-coordination methods** (`wait` ×3, `notify`, `notifyAll`) are `final` and cannot be overridden. The **three identity methods** (`getClass`, `notify`, `notifyAll`) are also `final`. Everything else is overridable.


## Part 2 — `getClass()`

Returns the **runtime `Class` object** of the instance. It is `final`, so it cannot be overridden.

```java
String s = "hello";
Class<?> c = s.getClass(); // class java.lang.String
```

**`getClass()` vs `instanceof`**:
- `getClass()` is **exact** — a subclass instance will not match the superclass.
- `instanceof` is **hierarchical** — a subclass instance matches its superclass.

```java
Base b = new Base();
Base s = new Sub();
System.out.println(b.getClass() == s.getClass()); // false
System.out.println(s instanceof Base);             // true
```

This distinction matters in `equals()`: using `getClass()` enforces exact-type equality, preventing symmetry violations when subclasses add state. Using `instanceof` allows subclass equality but requires careful reasoning about the contract.

`getClass()` is also the entry point to **reflection** — inspecting fields, methods, annotations, and constructors at runtime.


## Part 3 — The `Cloneable` Interface

`Cloneable` is a **marker interface** — it declares no methods.

```java
public interface Cloneable { }
```

Its sole purpose is to signal to `Object.clone()` that field-for-field copying is **legal** for that class.

Key rules from the Javadoc:
- A class implements `Cloneable` to indicate to `Object.clone()` that it is legal to make a field-for-field copy of instances of that class.
- Invoking `Object.clone()` on an instance that does **not** implement `Cloneable` results in `CloneNotSupportedException`.
- `Cloneable` **does not contain** the `clone` method. Implementing the interface alone does not give you a usable `clone` — you must override `Object.clone()` and make it `public`.
- **All arrays are considered to implement `Cloneable`**, even though this is not visible in the type system.

By convention, classes that implement `Cloneable` should override `Object.clone()` (which is `protected`) with a `public` method.

This is why `Cloneable` is often called a **broken** or **flawed** API: it is an empty interface that requires you to override a method from a different class, and the contract is weak and difficult to get right.


## Part 4 — `Object.clone()` Deep Dive

### The native implementation

`Object.clone()` is a `native` method — it is implemented in the JVM, not in Java code.

```java
protected native Object clone() throws CloneNotSupportedException;
```

### What it does

1. **Checks `Cloneable`**: If the object’s class does not implement `Cloneable`, it throws `CloneNotSupportedException`.
2. **Allocates a new instance**: Creates a new object of the **same runtime class** as the original.
3. **Copies fields by assignment**: Each field of the new object is initialized with the exact contents of the corresponding field of the original, **as if by assignment**. The contents of the fields are **not themselves cloned**.

This is a **shallow copy**. Primitive fields are copied by value. Reference fields are copied by reference — the clone and the original share the same referenced objects.

### The shallow copy problem

```java
class Person implements Cloneable {
    String name;
    Address address; // mutable reference

    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone(); // shallow copy
    }
}
```

After cloning:
- `clone.name` refers to the **same String** (Strings are immutable, so this is safe).
- `clone.address` refers to the **same Address object**. Mutating one affects both.

To achieve a true independent copy, you need a **deep copy**: recursively clone mutable referenced objects.

### Deep copy pattern

The Javadoc explicitly states the convention:

> By convention, the object returned by this method should be independent of this object (which is being cloned). To achieve this independence, it may be necessary to modify one or more fields of the object returned by `super.clone` before returning it. Typically, this means copying any mutable objects that comprise the internal "deep structure" of the object being cloned and replacing the references to these objects with references to the copies.

```java
class Person implements Cloneable {
    String name;
    Address address;

    @Override
    public Person clone() throws CloneNotSupportedException {
        Person cloned = (Person) super.clone(); // shallow copy first
        cloned.address = (Address) address.clone(); // deep copy mutable field
        return cloned;
    }
}
```

The `Address` class must also implement `Cloneable` and override `clone()`.

### Covariant return types

Modern Java allows you to change the return type of `clone()` to a subclass of `Object`. This eliminates the cast for callers:

```java
@Override
public Person clone() throws CloneNotSupportedException {
    return (Person) super.clone();
}
```

The JVM supports covariant return types for overridden methods.

### The `super.clone()` chain

The convention is that every `clone()` implementation should start by calling `super.clone()`. If every class in the hierarchy follows this convention, `x.clone().getClass() == x.getClass()` will hold.

If a class in the chain breaks the convention, the clone may be of the wrong runtime type. This is one of the weaknesses of the cloning contract.

### Cloning arrays

Arrays have built-in cloning support. You do not need to implement `Cloneable`:

```java
int[] original = {1, 2, 3};
int[] copy = original.clone(); // shallow copy of array contents
```

For arrays of objects, the clone is shallow — the array structure is copied, but the element references point to the same objects.


## Part 5 — `finalize()`

`finalize()` is called by the garbage collector **once**, when the GC determines there are no more references to the object.

```java
protected void finalize() throws Throwable { }
```

**Problems with `finalize()`**:
- No guarantee **when** it will run (or if it will run at all before JVM exit).
- Can **resurrect** the object by creating new references, preventing collection.
- Called at most **once** — if resurrection occurs, a second GC will not call it again.
- Performance overhead on GC.
- **Deprecated since Java 9** and marked for removal.

**Modern replacement**: `java.lang.ref.Cleaner` (Java 9+) or explicit resource management via `AutoCloseable` and try-with-resources.

Do not rely on `finalize()` for releasing critical resources like files or sockets. Use `try-with-resources` instead.


## Part 6 — `wait()`, `notify()`, `notifyAll()`

These are the **monitor methods** for inter-thread communication. They must be called while holding the object’s intrinsic lock (`synchronized` block).

| Method | Behavior |
|---|---|
| `wait()` | Suspends current thread until another thread calls `notify()` or `notifyAll()` on the same monitor |
| `wait(long)` | Same, but returns after `timeout` milliseconds even if not notified |
| `wait(long, int)` | Same, with additional nanosecond precision |
| `notify()` | Wakes **one** arbitrarily chosen thread waiting on the monitor |
| `notifyAll()` | Wakes **all** threads waiting on the monitor |

All five are `final` — they cannot be overridden.

**Critical rule**: Always call `wait()` inside a loop that re-checks the condition. Spurious wakeups are permitted by the JVM:

```java
synchronized (lock) {
    while (!condition) {
        lock.wait();
    }
    // proceed
}
```

These methods are low-level primitives. Modern Java code typically uses `java.util.concurrent` classes (`ReentrantLock`, `Condition`, `BlockingQueue`, `CountDownLatch`) instead of raw `wait`/`notify`.


## Part 7 — Recap: `equals()` / `hashCode()` Contract

These were covered in detail previously, but the essentials for completeness:

### `equals()` rules
1. **Reflexive** — `x.equals(x)` is `true`.
2. **Symmetric** — `x.equals(y)` iff `y.equals(x)`.
3. **Transitive** — if `x.equals(y)` and `y.equals(z)`, then `x.equals(z)`.
4. **Consistent** — repeated calls with unchanged state return the same result.
5. **Null-safe** — `x.equals(null)` returns `false`.

### `hashCode()` rules
1. Consistent during execution.
2. If `x.equals(y)`, then `x.hashCode() == y.hashCode()`.
3. Unequal objects **may** share a hash code (collisions are allowed).

Breaking rule 2 silently corrupts `HashMap` and `HashSet`: entries become unreachable because they are stored in the wrong bucket.

### The `toString()` contract
- Should be concise, informative, and non-throwing.
- Default: `ClassName@hexHashCode`.
- Never include sensitive data (passwords, tokens).
- Used by logging, debugging, and collection printing.


## Part 8 — Cloning Alternatives

Because `Cloneable`/`clone()` is widely considered broken (Effective Java Item 13 advises against it), consider these alternatives:

### Copy constructor
```java
public Person(Person other) {
    this.name = other.name;
    this.address = new Address(other.address); // deep copy
}
```
Explicit, type-safe, no exceptions, no marker interface.

### Static factory method
```java
public static Person copyOf(Person other) {
    return new Person(other.name, new Address(other.address));
}
```

### Records (Java 16+)
Records automatically provide value-based `equals`, `hashCode`, and `toString`, eliminating the need for manual cloning in value-semantics scenarios.

### Serialization-based deep copy
Not recommended for general use — slow, fragile, and requires `Serializable`.

### `Cloneable` is acceptable when:
- You control the entire class hierarchy.
- All mutable fields are properly deep-copied.
- You follow the `super.clone()` convention consistently.
- You document the depth of the clone.


## Quick Reference Summary

| `Object` Method | Key Point |
|---|---|
| `clone()` | Shallow copy by default; requires `Cloneable`; override and make `public` |
| `equals()` | Logical equality; must be reflexive, symmetric, transitive, consistent, null-safe |
| `finalize()` | Deprecated; unreliable; use `Cleaner` or `AutoCloseable` instead |
| `getClass()` | Final; exact runtime type; entry point to reflection |
| `hashCode()` | Must be consistent with `equals`; breaks hash collections if violated |
| `notify()` / `notifyAll()` | Final; monitor methods; wake waiting threads |
| `toString()` | Override for debugging and logging; never include secrets |
| `wait()` | Final; monitor methods; always call in a condition loop |

The `Object` class is small in surface area but foundational in impact. The `clone()`/`Cloneable` mechanism is the most fragile part of the API — prefer copy constructors or factory methods for new code.


[[Java]]