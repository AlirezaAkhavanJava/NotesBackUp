

You've been asking about `int` — now let's cover **every** type the JVM can store in a frame's Local Variable Array, and how each one behaves.

---

## The Complete Type List

The JVM specification defines exactly **9** types that can live in locals and the operand stack:

| Category | Types | Slot size | Stored directly or as reference? |
|----------|-------|-----------|----------------------------------|
| Integer | `boolean`, `byte`, `char`, `short`, `int` | 1 slot | Directly (as 32-bit int) |
| Float | `float` | 1 slot | Directly (as 32-bit IEEE 754) |
| Long | `long` | **2 slots** | Directly (as 64-bit) |
| Double | `double` | **2 slots** | Directly (as 64-bit IEEE 754) |
| Reference | objects, arrays, interfaces | 1 slot | As a **pointer** to the heap |
| Return address | internal (for `jsr`/`ret`) | 1 slot | Directly (legacy, rarely used) |

**That's it.** There is no `String`, no `Object`, no `Person` as a distinct type inside the frame. All objects — regardless of class — are stored as **references** (one slot).

---

## Category 1: All "Small Integers" Collapse to `int`

This surprises many people: `boolean`, `byte`, `char`, and `short` are **all stored as 32-bit ints** in the frame.

```java
void example(boolean flag, byte b, char c, short s, int i) {
    // ...
}
```

Layout:

```
Slot:  0        1        2        3        4
     ┌────────┬────────┬────────┬────────┬────────┐
     │ flag   │   b    │   c    │   s    │   i    │
     │ 1 slot │ 1 slot │ 1 slot │ 1 slot │ 1 slot │
     │ int    │ int    │ int    │ int    │ int    │
     └────────┴────────┴────────┴────────┴────────┘
```

Even though `boolean` conceptually needs 1 bit and `byte` needs 8 bits, the JVM promotes them all to `int` for simplicity.

Bytecode still uses type-specific instructions:
- `iload_0` → loads `flag` (as int)
- `iload_1` → loads `b` (as int)
- `iload_2` → loads `c` (as int)

But at the memory level, they're **identical** — all 32-bit slots.

### Why?

Because the JVM's execution engine only knows how to operate on 32-bit and 64-bit values. This is called the **"small types are widened"** rule.

---

## Category 2: `float` — One Slot, Different Bit Pattern

```java
void example(float f) { ... }
```

```
Slot:  0
     ┌────────┐
     │   f    │
     │ 1 slot │
     │ float  │  ← 32-bit IEEE 754 format
     └────────┘
```

- Occupies **1 slot** (same as `int`)
- Same 32 bits — but interpreted differently by `fload` vs `iload`
- Bytecode uses `fload_0`, `fstore_0`, etc.

---

## Category 3: `long` and `double` — Two Slots Each

These are the **only** types that take 2 slots.

```java
void example(long l, double d) { ... }
```

```
Slot:  0        1        2        3
     ┌────────┬────────┬────────┬────────┐
     │ l (hi) │ l (lo) │ d (hi) │ d (lo) │
     │   ← 2 slots →    │   ← 2 slots →   │
     └────────┴────────┴────────┴────────┘
```

- `long l` → slots 0 and 1
- `double d` → slots 2 and 3

Bytecode:
- `lload_0` → loads 64-bit long from slots 0-1
- `dload_2` → loads 64-bit double from slots 2-3

**Important gotcha:** you can't start a 2-slot value at the last slot. And the JVM spec technically allows implementations to store the two halves in either order, but in practice it's always big-endian-ish (hi then lo) on HotSpot.

---

## Category 4: References — One Slot, Points to Heap

**Every** object type — `String`, `Person`, `int[]`, `List<Foo>`, etc. — is stored as **one slot containing a pointer**.

```java
void example(String s, Person p, int[] arr) { ... }
```

```
Slot:  0        1        2
     ┌────────┬────────┬────────┐
     │   s    │   p    │  arr   │
     │ 1 slot │ 1 slot │ 1 slot │
     │ ref    │ ref    │ ref    │
     └────┬───┴────┬───┴────┬───┘
          │        │        │
          ▼        ▼        ▼
       ┌──────────────────────────┐
       │          HEAP            │
       │  String obj, Person obj, │
       │  int[] obj, ...          │
       └──────────────────────────┘
```

Key points:

- The **slot holds a pointer**, not the object itself
- The **object lives on the heap** (with header, fields, etc.)
- Bytecode uses `aload_0`, `astore_0`, etc. — "a" for "address/reference"
- The JVM doesn't care what class the object is — it's just a pointer

### Why one slot regardless of object size?

Because the slot holds a **pointer**, and pointers are a fixed size (32-bit on 32-bit JVMs, 64-bit on 64-bit JVMs — or 32-bit with compressed oops). The object's actual size is on the heap.

---

## Category 5: `returnAddress` — Legacy and Rare

Used only by the old `jsr`/`ret` instructions for implementing `finally` blocks in Java 1.5 and earlier. Modern compilers don't use it.

- 1 slot
- Holds a bytecode address
- Essentially obsolete — you'll never see it in modern bytecode

---

## Complete Reference Table

| Java type | Slots | Stored as | Load instruction | Store instruction |
|-----------|-------|-----------|------------------|-------------------|
| `boolean` | 1 | int (0 or 1) | `iload` | `istore` |
| `byte` | 1 | int (sign-extended) | `iload` | `istore` |
| `char` | 1 | int (zero-extended) | `iload` | `istore` |
| `short` | 1 | int (sign-extended) | `iload` | `istore` |
| `int` | 1 | int | `iload` | `istore` |
| `float` | 1 | IEEE 754 32-bit | `fload` | `fstore` |
| `long` | **2** | 64-bit | `lload` | `lstore` |
| `double` | **2** | IEEE 754 64-bit | `dload` | `dstore` |
| any reference | 1 | heap pointer | `aload` | `astore` |
| `returnAddress` | 1 | bytecode address | (internal) | (internal) |

Notice the pattern in the instruction prefixes:

- `i` = int (covers boolean, byte, char, short, int)
- `l` = long
- `f` = float
- `d` = double
- `a` = address (reference)

---

## Worked Example: All Types Together

```java
class Example {
    void mix(boolean flag, byte b, char c, short s, int i,
             long l, float f, double d, String str) {
        // ...
    }
}
```

Slot assignment (instance method → slot 0 = `this`):

```
Slot:  0      1      2      3      4      5      6      7      8      9     10     11
     ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┐
     │ this │ flag │  b   │  c   │  s   │  i   │ l hi │ l lo │  f   │ d hi │ d lo │ str  │
     │ ref  │ int  │ int  │ int  │ int  │ int  │ ← 2 slots → │float │ ← 2 slots → │ ref  │
     └──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┘
```

`max_locals = 12`

Bytecode would access:
- `iload_1` → flag
- `iload_2` → b
- `lload_6` → l (slots 6-7)
- `fload_8` → f
- `dload_9` → d (slots 9-10)
- `aload_11` → str

---

## What About the Operand Stack?

The operand stack uses the **exact same type system**. Same rules apply:

- `int`, `float`, `reference` → 1 slot on the operand stack
- `long`, `double` → 2 slots on the operand stack

```java
long a = 100L;
long b = 200L;
long c = a + b;
```

Bytecode:

```
ldc2_w #2       // push 100L (2 slots)   → operand stack: [100L_hi, 100L_lo]
ldc2_w #3       // push 200L (2 slots)   → operand stack: [200L, 100L]
ladd            // pop 2 longs, push 1   → operand stack: [300L]
lstore_4        // pop into locals 4-5
```

Notice `ldc2_w` — the "2" and "w" (wide) indicate it pushes a **2-slot** value.

---

## What About Objects' Fields?

When you access `person.age`, the `int age` field is:

- **Stored inside the object on the heap**
- **Not** in the frame's Local Variable Array
- Only loaded into the operand stack temporarily when needed

```java
int x = person.age;
```

Bytecode:

```
aload_1                     // push person reference → operand stack: [ref]
getfield Person.age:I       // read heap field, push int → operand stack: [30]
istore_2                    // pop into local slot 2
```

So the field lives on the heap; the frame only holds a temporary copy when actively working with it.

---

## What About `null`?

`null` is a special reference value. It occupies **1 slot**, same as any reference.

```
┌────────┐
│  null  │   ← 1 slot, value 0 (all bits zero)
└────────┘
```

The JVM verifies you don't dereference it (that's what `NullPointerException` is).

---

## Summary of Key Rules

1. **All integral types smaller than `int` are widened to `int`** in the frame — `boolean`, `byte`, `char`, `short` all take 1 slot as 32-bit ints.
2. **`int` and `float` each take 1 slot.**
3. **`long` and `double` take 2 slots each** — the only 2-slot types.
4. **Every object type takes exactly 1 slot** — because only a *reference* is stored, not the object.
5. **The object itself always lives on the heap** — never in the frame.
6. **The operand stack follows the same rules** — 1 slot for most, 2 for `long`/`double`.
7. **Object fields live on the heap**, not in the frame — only loaded temporarily into the operand stack when accessed.

---

## TL;DR Table

| Type | Slots | Lives where |
|------|-------|-------------|
| `boolean`/`byte`/`char`/`short`/`int` | 1 | Directly in frame slot (as int) |
| `float` | 1 | Directly in frame slot |
| `long` | 2 | Directly in frame slots (as 64-bit) |
| `double` | 2 | Directly in frame slots (as 64-bit) |
| Any object reference | 1 | Pointer in frame slot → object on heap |
| Object's fields | — | On the heap inside the object |

So the frame doesn't distinguish "kinds of data" the way Java source does — it just sees **slots**, some holding raw values and some holding pointers. The *type* information comes from the **bytecode instructions**, not from the slot itself. That's the elegance of the JVM's design: one uniform storage model, with types enforced by the compiler and verifier.


[[Java]]