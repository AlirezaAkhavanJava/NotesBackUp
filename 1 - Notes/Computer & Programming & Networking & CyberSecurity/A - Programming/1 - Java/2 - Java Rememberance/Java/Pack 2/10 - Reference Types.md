
# Reference Types — What Exactly Is Stored?

Yes, you've got it right. Let me make the picture precise, because there are a few layers of nuance worth knowing.

---

## The Core Answer

> **A reference type is stored in the Local Variable Array as a single slot containing a pointer (memory address) that points to an object on the Heap.**

That's it at the top level. But let's go deeper, because "heap address" has subtleties.

---

## What's Actually in the Slot?

```
Local Variable Array
┌────────────────────┐
│  slot 1:  0x7A3F10 │  ← this is the reference value
└────────────────────┘
              │
              ▼
        Heap at 0x7A3F10
        ┌──────────────────────────┐
        │  Object header           │
        │    - class pointer ──────┼──▶ Metaspace (Person.class)
        │    - hash / GC bits      │
        │  Fields                  │
        │    - name: 0x3B4C ───────┼──▶ Heap ("Bob" String)
        │    - age: 30             │
        └──────────────────────────┘
```

The slot holds **one value**: the address (or a compressed form of it) of the object's start in the heap.

---

## Three Nuances to Be Precise

### 1. It's not necessarily a *raw* memory address

On modern HotSpot JVMs, the value in the slot is usually an **oop** ("ordinary object pointer") — which may be:

- **A raw 64-bit address** → on 64-bit JVMs with compressed oops disabled
- **A 32-bit compressed reference** → on 64-bit JVMs with `-XX:+UseCompressedOops` (the default for heaps < 32 GB)
- **A 32-bit address** → on 32-bit JVMs

So "heap address" is correct conceptually, but the actual bits may be compressed, indirect, or tagged depending on the JVM implementation.

| JVM config | Reference size in slot |
|------------|----------------------|
| 32-bit JVM | 32 bits |
| 64-bit, compressed oops on | 32 bits (usually) |
| 64-bit, compressed oops off | 64 bits |

**Either way**, the slot is a **single slot** in the Local Variable Array (the JVM abstracts the difference away).

### 2. The reference points to the *start* of the object, not a field

When you have:

```java
Person p = new Person();
```

`p`'s slot holds the address of the **object header**. Fields are at fixed offsets from that address. So `p.age` means:

- Take the address in `p`'s slot
- Add the byte offset of the `age` field
- Read the int at that location

The reference doesn't point to a field — it points to the object's beginning.

### 3. The object itself may contain more references

A `Person` object on the heap might have a `name` field that is itself a reference:

```
Heap
┌─────────────────────────────┐
│  Person @ 0x7A3F10          │
│  ┌───────────────────────┐  │
│  │ header → Person.class │  │
│  │ name: 0x3B4C ─────────┼──┼──▶ "Bob" String object (also on heap)
│  │ age:  30              │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

So references can form **chains**: local slot → object → its fields → more objects, all on the heap, with only the first reference in the frame.

---

## What the Reference Does *Not* Point To

To correct the earlier misconception you had:

| Target | Correct? |
|--------|----------|
| Heap object | ✅ Yes |
| Method Area / Metaspace | ❌ No — that's where the *class metadata* lives; the object's header points there, but the local slot does not |
| Another stack frame | ❌ No |
| The operand stack | ❌ No |

The local slot → **Heap**. Full stop. The heap object's header → Metaspace (for class info). Two different hops.

---

## Flow of a Reference Through the JVM

```java
Person p = new Person();
```

Bytecode:

```
new #2              // allocate Person on heap, push reference onto operand stack
dup                 // duplicate reference (one for the field init, one to keep)
invokespecial #3    // call <init>, consumes one reference
astore_1            // pop the remaining reference into local slot 1
```

Step by step:

1. `new` → JVM allocates a `Person` object on the **Heap**, pushes a **reference** onto the operand stack
2. `astore_1` → that reference is **copied** from the operand stack into **slot 1** of the Local Variable Array
3. From now on, `p` is just that slot's value — a pointer to the heap object

So the reference **flows through the operand stack** first, then lands in the local slot. It's just a value being moved around.

---

## What Happens on Assignment?

```java
Person p = new Person();
Person q = p;     // copy the reference
```

Bytecode for `q = p`:

```
aload_1     // push reference from slot 1 onto operand stack
astore_2    // pop it into slot 2
```

Now **both slots hold the same address**:

```
Slot 1: 0x7A3F10 ─┐
Slot 2: 0x7A3F10 ─┴──▶ same Person object on heap
```

This is why:

```java
q.name = "Alice";
System.out.println(p.name);  // prints "Alice" !
```

Both `p` and `q` point to the **same object** — no object was copied, only the reference.

---

## Pass-by-Value of References

Java passes references **by value** — the reference itself is copied, not the object:

```java
void modify(Person x) {
    x.name = "Bob";    // affects caller's object (same reference)
    x = new Person();  // only changes local slot — caller unaffected
}
```

When `modify(p)` is called:

1. The reference in `p`'s slot is **copied** into `modify`'s local slot 0
2. Both slots point to the **same heap object**
3. If `modify` mutates the object → caller sees it (shared object)
4. If `modify` reassigns `x` → only `modify`'s slot changes (caller's slot untouched)

This is why Java is often described as "pass-by-value of references" — the reference is the value.

---

## Null References

A reference slot can hold `null` — a special value (all zero bits in most implementations):

```
┌────────────────┐
│  slot: null    │  ← no valid heap address
└────────────────┘
```

- Taking a field of `null` → `NullPointerException` (JVM detects the zero/invalid pointer)
- Comparing to `null` → `ifnull` / `ifnonnull` bytecodes

---

## Special References

The JVM has a few special reference types used internally:

| Kind | What it points to |
|------|-------------------|
| Ordinary object (`oop`) | A normal heap object |
| Array (`objArrayOop`) | A heap array object |
| Instance class (`instanceKlass`) | Class metadata in Metaspace (internal, not a Java reference) |
| Method (`methodOop`) | Compiled method metadata (internal) |

But from **Java code's perspective**, there's only one kind of reference — the one in your local slot that points to a heap object or array.

---

## Summary Diagram

```
STACK (per thread)                          HEAP (shared)
┌───────────────────────────────┐           ┌─────────────────────┐
│ Frame for method foo()        │           │                     │
│ ┌───────────────────────────┐ │           │   Person @ 0x7A3F10 │
│ │ Local Variable Array      │ │           │   ┌───────────────┐ │
│ │ ┌────────┬──────────────┐ │ │           │   │ header        │ │
│ │ │ slot 0 │ slot 1       │ │ │           │   │ name: 0x3B4C  │ │
│ │ │ this   │ 0x7A3F10 ────┼─┼─┼───────────┼──▶│ age:  30      │ │
│ │ └────────┴──────────────┘ │ │           │   └───────────────┘ │
│ └───────────────────────────┘ │           │                     │
└───────────────────────────────┘           └─────────────────────┘
                                                      │
                                                      │ (header's class ptr)
                                                      ▼
                                            ┌─────────────────────┐
                                            │ METASPACE           │
                                            │  Person.class info  │
                                            └─────────────────────┘
```

- **Slot value** = heap address (possibly compressed)
- **Slot points to** = object start on heap
- **Object header points to** = class metadata in Metaspace
- **Frame data also holds** = reference to runtime constant pool (separate from object references)

---

## TL;DR

| Question | Answer |
|----------|--------|
| What does a reference slot hold? | A single value — a pointer (address) to a heap object |
| Does it point to the heap? | ✅ Yes |
| Does it point to Metaspace/Method Area? | ❌ No — that's the object's header's job |
| How big is the reference in the slot? | Usually 32 or 64 bits, but always **1 slot** in the array |
| What if it's `null`? | The slot holds a special "no object" value (usually all zeros) |
| Are two references to the same object duplicated? | ❌ No — they hold the *same address*, pointing to one heap object |

So: **yes — a reference type is a heap address stored in one slot of the frame's Local Variable Array.**


[[Java]]