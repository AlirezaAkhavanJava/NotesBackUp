
# Inside a Stack Frame — What's Actually There

I need to gently correct a few assumptions first, then give you the accurate picture. The mental model you described (key/value pairs, "method name on top", references pointing to Method Area) is *close* but has some important inaccuracies.

## First — Correcting the Mental Model

| Your assumption | Reality |
|-----------------|---------|
| "Method name on top of frame" | ❌ There's no method name stored in the frame. The frame doesn't know its own name. |
| "Local variables as key/value pairs" | ❌ Locals are stored in a **fixed-size array indexed by slot number**, not a hash map. There are no "keys" at runtime. |
| "Object references point to Method Area" | ❌ Object references point to the **Heap**. What points to the Method Area (Metaspace) is a *class reference*. |
| Frames have a simple top-to-bottom layout | ⚠️ They have distinct *regions*, but the ordering and naming matter. |

Let me build it up properly.

## The Real Layout of a Stack Frame

```
┌──────────────────────────────────────┐
│           STACK FRAME                │
├──────────────────────────────────────┤
│                                      │
│   Local Variable Array               │  ← indexed by slot (0, 1, 2, ...)
│   [ slot0 | slot1 | slot2 | ... ]    │
│                                      │
├──────────────────────────────────────┤
│                                      │
│   Operand Stack                      │  ← LIFO workspace
│   [ val | val | val | ... ]          │
│                                      │
├──────────────────────────────────────┤
│                                      │
│   Frame Data                         │
│   - Reference to runtime constant    │
│     pool (points to Metaspace)       │
│   - Return address / PC              │
│   - Exception handler table ref      │
│   - (implementation-specific extras) │
│                                      │
└──────────────────────────────────────┘
```

There is **no "method name" field**. The JVM doesn't need it at runtime — the currently executing method is determined by which frame is on top and what the Program Counter (PC) register says.

## 1. Local Variable Array — Not a Map, an Array

This is the biggest correction. Locals are **not** stored as key/value pairs. They're stored in a **plain array of 32-bit slots**, accessed by **numeric index**.

```java
static int add(int a, int b) {
    int sum = a + b;
    return sum;
}
```

The Local Variable Array for this frame:

```
Index:   0        1        2
       ┌────────┬────────┬────────┐
       │   a    │   b    │  sum   │
       │ (int)  │ (int)  │ (int)  │
       └────────┴────────┴────────┘
```

- Variable names (`a`, `b`, `sum`) exist only in the `.class` file's **LocalVariableTable** (debug info) — **not** in the runtime frame.
- At runtime, bytecode refers to them as `iload_0`, `iload_1`, `istore_2`, etc.
- There is no lookup by name. It's just `array[index]`.

### How many slots does each type take?

| Type | Slots | Notes |
|------|-------|-------|
| `boolean`, `byte`, `char`, `short`, `int` | 1 | All promoted to int |
| `float` | 1 | |
| `long` | 2 | Takes two consecutive slots |
| `double` | 2 | Takes two consecutive slots |
| `reference` | 1 | Points to heap |
| `returnAddress` | 1 | Used internally |

### Slot 0 Special Case

- **Instance methods**: `slot 0` = `this` reference
- **Static methods**: `slot 0` = first parameter

```java
class Foo {
    void bar(int x, long y) { ... }
}
```

```
Static bar(int, long):        Instance bar(int, long):
┌──────┬──────┬──────┐        ┌──────┬──────┬──────┬──────┐
│  x   │  y(hi)│ y(lo)│        │ this │  x   │ y(hi)│ y(lo)│
│ idx0 │ idx1 │ idx2 │        │ idx0 │ idx1 │ idx2 │ idx3 │
└──────┴──────┴──────┘        └──────┴──────┴──────┴──────┘
```

Note the `long y` occupies **two slots** (idx 1 & 2 in static, idx 2 & 3 in instance).

## 2. Object References — Where Do They Point?

Your intuition was that references point to the **Method Area**. That's incorrect — they point to the **Heap**.

### What lives where:

```
┌─────────────────────────┐         ┌───────────────────────┐
│      JVM STACK          │         │        HEAP           │
│  (per thread)           │         │  (shared by threads)  │
│                         │         │                       │
│  Frame for main()       │         │   ┌───────────────┐   │
│  ┌───────────────────┐  │         │   │  Person obj   │   │
│  │ LocalVar Array    │  │         │   │  name: "Bob"  │   │
│  │ ┌───────────────┐ │  │         │   │  age: 30      │   │
│  │ │ p: 0x1A2F ────┼─┼──┼─────────┼──▶│               │   │
│  │ └───────────────┘ │  │         │   └───────────────┘   │
│  └───────────────────┘  │         │                       │
└─────────────────────────┘         └───────────────────────┘
                                             ▲
                                             │
                                    Class metadata
                                    (Person.class info)
                                             │
                                    ┌───────────────────────┐
                                    │    METASPACE          │
                                    │  (was Method Area)    │
                                    │  ┌─────────────────┐  │
                                    │  │ Person class    │  │
                                    │  │ - field layout  │  │
                                    │  │ - method table  │  │
                                    │  │ - constant pool │  │
                                    │  └─────────────────┘  │
                                    └───────────────────────┘
```

So:
- **Local variable holds a reference** → points to an **object on the Heap**
- **The object's header** contains a pointer → to its **class metadata in Metaspace**
- The frame itself also has a **direct reference to the runtime constant pool** (which lives in Metaspace) — used for resolving things like `ldc` constants and method calls

## 3. Frame Data — The "Hidden" Part

This region (not visible in Java code) contains:

| Item | Purpose |
|------|---------|
| **Return address / PC** | Where to resume execution in the caller after return |
| **Reference to runtime constant pool** | For the current class — used to resolve symbols at runtime |
| **Exception handler table ref** | To find matching catch blocks if an exception is thrown |
| **Saved registers** | Implementation-specific (e.g., saved frame pointer) |

This is what allows a method to return and the caller to continue correctly.

## 4. Putting It All Together — A Concrete Walkthrough

```java
class Person {
    String name;
    int age;
}

public class Demo {
    public static void main(String[] args) {
        Person p = new Person();   // p → heap object
        p.name = "Bob";
        p.age = 30;
        greet(p);                  // call
    }
    static void greet(Person person) {
        System.out.println("Hi " + person.name);
    }
}
```

### Frames while `greet()` is executing

```
Thread's JVM Stack
├── greet() frame  ← top
│   ├── LocalVar Array: [ person: 0x1A2F ]     ← copy of reference (slot 0, static)
│   ├── Operand Stack: (busy computing string concat)
│   └── Frame Data: PC=..., cpool ref → Metaspace
│
└── main() frame   ← suspended
    ├── LocalVar Array: [ args: 0x????, p: 0x1A2F ]
    ├── Operand Stack: empty (mid-call)
    └── Frame Data: PC=... (where to resume)
```

Heap:
```
0x1A2F → Person { name: 0x3B4C → "Bob", age: 30 }
```

Metaspace:
```
Person.class metadata, Demo.class metadata, constant pools, method bytecode...
```

Notice:
- The **reference value `0x1A2F` is copied** into `greet`'s local array — Java is pass-by-value, even for references.
- **Both** `p` (in main) and `person` (in greet) point to the **same heap object**.
- The **method name "greet" is nowhere in the frame**. The JVM knows it's executing `greet` because `greet`'s frame is on top and the PC points into `greet`'s bytecode.

## 5. Corrected Mental Model

| Concept | What it actually is |
|---------|---------------------|
| Local variables | Array of 32-bit slots, accessed by **index**, not name |
| Slots per variable | 1 for most; 2 for `long`/`double` |
| Slot 0 | `this` (instance) or first arg (static) |
| Object reference | Value in a slot → points to **Heap** |
| Object's class pointer | In the object header → points to **Metaspace** |
| Method name | **Not stored** in the frame at runtime |
| Operand stack | LIFO workspace within the frame |
| Frame data | Return PC, constant pool ref, exception table ref |
| Where locals live | On the **JVM Stack**, not the Heap (unless captured by a lambda/inner class) |

## 6. One More Caveat — "Escape Analysis"

The JIT compiler may **optimize away** some stack allocations:

- If an object never escapes a method, HotSpot can allocate it **on the stack** or in registers (scalar replacement).
- This is a JIT optimization, not a language guarantee. The **JVM spec** still says objects go on the heap.
- You can disable it with `-XX:-DoEscapeAnalysis`.

## TL;DR

- A frame is **not** a key/value map. Locals are a **flat array indexed by slot number**.
- Variable names exist only in debug info, not at runtime.
- Object references point to the **Heap**, not the Method Area.
- The object's header points to its **class metadata in Metaspace**.
- The frame has a **constant pool reference** for resolving symbols — that's the only thing directly linking to Metaspace.
- The **method name is not stored in the frame**; it's implicit from the call stack and PC.

So the corrected picture is: **Thread → Stack → Frame → [LocalVarArray | OperandStack | FrameData]**, with references bridging out to the shared Heap and Metaspace.

[[Java]]
