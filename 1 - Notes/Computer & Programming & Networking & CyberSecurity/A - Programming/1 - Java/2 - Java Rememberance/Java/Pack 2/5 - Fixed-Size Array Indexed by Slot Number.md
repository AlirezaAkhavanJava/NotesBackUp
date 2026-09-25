

This phrase describes how the **Local Variable Array** inside a stack frame is structured. Let's unpack each part.

## Breaking Down the Phrase

| Phrase | Meaning |
|--------|---------|
| **Array** | A contiguous block of memory, accessed by numeric index |
| **Fixed-size** | The length is decided at **compile time** and never changes during the method's execution |
| **Indexed by slot number** | You access elements by position (`0`, `1`, `2`, ...), not by name |
| **Slot** | A single 32-bit storage unit in the array |

## What Is a "Slot"?

A **slot** is the basic unit of storage in the Local Variable Array. In the JVM spec, each slot is **32 bits (4 bytes)** wide.

Most JVM implementations use a slot as:

```
┌────────────────┐
│   32 bits      │   ← one slot
│  (4 bytes)     │
└────────────────┘
```

But some values need **two slots** (64 bits) because they don't fit in 32 bits.

## "Fixed-Size" — What Does That Mean?

The size of the Local Variable Array is **computed by `javac` at compile time** and stored in the `.class` file as the `max_locals` attribute of the method.

```java
static int add(int a, int b) {
    int sum = a + b;
    return sum;
}
```

Compiled: `max_locals = 3` (a, b, sum — each 1 slot)

This number **never changes** at runtime. When the JVM creates the frame, it allocates exactly `max_locals` slots. No growing, no shrinking.

### Compare with a dynamic structure

| Feature | Fixed-size array (Locals) | Dynamic structure (e.g., ArrayList) |
|---------|---------------------------|-------------------------------------|
| Size known | At compile time | At runtime |
| Can grow | ❌ No | ✅ Yes |
| Lookup by name | ❌ No — by index | Depends |
| Lookup by index | ✅ O(1) | ✅ O(1) |
| Memory | Allocated once | Reallocated as needed |

## "Indexed by Slot Number" — What Does That Mean?

Each variable occupies one or more **consecutive slots**, and bytecode refers to them by their **numeric index**.

```java
static void example(int x, long y, String s) {
    // ...
}
```

Layout in the Local Variable Array:

```
Slot:    0        1        2        3
       ┌────────┬────────┬────────┬────────┐
       │   x    │  y hi  │  y lo  │   s    │
       │ (int)  │ (long) │ (long) │ (ref)  │
       │ 1 slot │   2 slots       │ 1 slot │
       └────────┴────────┴────────┴────────┘
```

- `x` → slot `0`
- `y` → slots `1` and `2` (because `long` = 64 bits = 2 slots)
- `s` → slot `3`

Bytecode accesses them by **index**, not name:

```
iload_0       // load x from slot 0
lload_1       // load y from slots 1-2
aload_3       // load s from slot 3
```

## Why Index, Not Name?

Because **at runtime, names don't exist**. The JVM was designed this way for:

1. **Speed** — `array[3]` is a single memory offset, no lookup needed
2. **Simplicity** — no symbol table, no hash map, no string comparison
3. **Compactness** — bytecode stores a single byte (`iload_3`) instead of a string

The variable names (`x`, `y`, `s`) live only in the **LocalVariableTable** — an optional debug attribute in the `.class` file. You can strip it with `javac -g:none` and the program runs identically.

## A Concrete Analogy

Think of a **coat check room** with numbered hooks:

```
Hook 0: [ coat A ]
Hook 1: [ coat B ]
Hook 2: [ coat C ]
Hook 3: [ coat D ]
```

- The room has exactly **4 hooks** (fixed-size) — decided when the room was built
- You don't say "give me Bob's coat" — you say "give me the coat on **hook 2**"
- Some coats are bulkier and take two hooks (like `long`/`double`)
- The number of hooks is set when the method is compiled, never changes

## Example: How `javac` Assigns Slots

```java
class Calculator {
    int compute(int a, double b) {
        int c = a + 1;
        double d = b * 2;
        return c;
    }
}
```

Slot assignment (instance method, so slot 0 = `this`):

```
Slot 0: this        (reference, 1 slot)
Slot 1: a           (int, 1 slot)
Slot 2: b (hi)      (double, 2 slots)
Slot 3: b (lo)
Slot 4: c           (int, 1 slot)
Slot 5: d (hi)      (double, 2 slots)
Slot 6: d (lo)
```

`max_locals = 7`

Even though `c` and `d` are declared later, the compiler may reuse slots after a variable goes out of scope — but the **total** is still fixed at 7.

## Slot Reuse (An Optimization)

The compiler can reuse slots when variables no longer overlap in scope:

```java
static void f() {
    { int x = 1; }   // x uses slot 0
    { int y = 2; }   // y can reuse slot 0
}
```

`max_locals = 1`, not 2. But still **fixed** — the size doesn't change at runtime.

## Contrast: What It Is NOT

| Not this | Why |
|----------|-----|
| A `HashMap<String, Object>` | No keys, no hashing, no string names |
| A `List` that grows | Fixed size, allocated once per frame |
| A symbol table | Names are compile-time only |
| A dynamically-resized array | `max_locals` is fixed in the `.class` file |

## Summary

> **"A fixed-size array indexed by slot number"** means: the Local Variable Array is a contiguous block of 32-bit slots, whose total length (`max_locals`) is baked into the class file at compile time, and each variable is read/written by its numeric position (slot index), not by name.

This is why bytecode looks like `iload_0`, `istore_3`, `aload_2` — those trailing numbers are **slot indices** into that fixed-size array.


[[Java]]