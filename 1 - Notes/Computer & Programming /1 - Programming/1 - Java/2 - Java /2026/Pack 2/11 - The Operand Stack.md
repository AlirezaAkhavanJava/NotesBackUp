

You've now got the Local Variable Array clear. The **Operand Stack** is the other half of the frame. Let's go deep.

---

## What It Is

> The **Operand Stack** is a **LIFO (Last-In-First-Out)** workspace inside each frame where bytecode instructions **push** and **pop** values during execution.

It's where all the actual **computation happens**. The Local Variable Array **stores** variables; the Operand Stack **operates** on them.

---

## Where It Sits

```
┌──────────────────────────────────────┐
│           STACK FRAME                │
├──────────────────────────────────────┤
│   Local Variable Array               │  ← stores variables
│   [ slot0 | slot1 | slot2 | ... ]    │
├──────────────────────────────────────┤
│                                      │
│   Operand Stack                      │  ← computes with values
│   [ val | val | val | ... ]          │
│                                      │
├──────────────────────────────────────┤
│   Frame Data                         │
└──────────────────────────────────────┘
```

- **Same frame** as the Local Variable Array
- **Same thread's stack** — lives on the JVM Stack, not the heap
- **Fixed size** — decided at compile time, stored as `max_stack` in the `.class` file

---

## Key Properties

| Property | Detail |
|----------|--------|
| Structure | LIFO (stack) |
| Size | Fixed, computed by `javac`, stored as `max_stack` |
| Location | Inside the frame, on the thread's JVM Stack |
| Is it a Java object? | ❌ No — it's an internal JVM memory region |
| Holds | Same 9 types as locals: `int`, `long`, `float`, `double`, `reference`, `returnAddress` |
| Slot rules | Same as locals: 1 slot for most, **2 slots for `long`/`double`** |
| Visible to Java code? | ❌ No — completely hidden |

---

## Why a Stack (and Not Registers)?

The JVM is a **stack-based** virtual machine. Every operation follows this pattern:

```
pop operands → compute → push result
```

Example: `a + b`

```
1. push a          → operand stack: [a]
2. push b          → operand stack: [b, a]
3. iadd            → pop b, pop a, push (a+b) → operand stack: [a+b]
```

Contrast with a **register-based** VM (like Dalvik/ART on Android):

```
add r0, r1, r2     // r0 = r1 + r2
```

Stack-based is **simpler and more portable** but needs more instructions. Register-based is faster but more complex.

---

## The Full Instruction Cycle

Every JVM instruction interacts with the operand stack in one of these ways:

| Pattern | Example | Effect |
|---------|---------|--------|
| Push constant | `iconst_5` | Push 5 |
| Push local | `iload_1` | Copy slot 1 → push |
| Pop to local | `istore_2` | Pop → slot 2 |
| Pop 2, push 1 | `iadd` | Pop 2 ints, push sum |
| Pop 1, push 1 | `ineg` | Pop int, push negated |
| Pop 1, no push | `pop` | Discard top |
| Dup top | `dup` | Duplicate top value |
| Swap top 2 | `swap` | Exchange top two |
| Peek (no pop) | `if_icmpgt` | Read top 2 for comparison |

---

## Worked Example 1: Simple Arithmetic

```java
int c = a + b;
```

Bytecode:

```
iload_1     // push a
iload_2     // push b
iadd        // pop b, pop a, push (a+b)
istore_3    // pop result → slot 3
```

Operand Stack evolution:

| Instruction | Operand Stack (top → bottom) |
|-------------|------------------------------|
| (start) | `[]` |
| `iload_1` | `[a]` |
| `iload_2` | `[b, a]` |
| `iadd` | `[a+b]` |
| `istore_3` | `[]` |

---

## Worked Example 2: `long` Uses Two Slots

```java
long x = 10L;
long y = 20L;
long z = x + y;
```

Bytecode:

```
ldc2_w #2     // push 10L (2 slots)
lstore_1      // pop into slots 1-2
ldc2_w #3     // push 20L (2 slots)
lstore_3      // pop into slots 3-4
lload_1       // push long from slots 1-2
lload_3       // push long from slots 3-4
ladd          // pop two longs, push one
lstore_5      // pop into slots 5-6
```

Operand Stack during `ladd`:

```
Before ladd:  [ 20L_hi, 20L_lo, 10L_hi, 10L_lo ]
               └─ 2 slots ─┘  └─ 2 slots ─┘
                        ▲              ▲
                        │              │
                   top of stack   just below top

After ladd:   [ 30L_hi, 30L_lo ]
```

`ladd` pops **two 64-bit values** (4 slots total) and pushes **one 64-bit value** (2 slots).

---

## Worked Example 3: Method Call

```java
int result = Math.max(10, 20);
```

Bytecode:

```
bipush 10                    // push 10
bipush 20                    // push 20
invokestatic Math.max:(II)I  // pop 2 args, push return
istore_1                     // pop result → slot 1
```

Operand Stack evolution:

| Instruction | Operand Stack |
|-------------|---------------|
| `bipush 10` | `[10]` |
| `bipush 20` | `[20, 10]` |
| `invokestatic` | `[20]` (return value) |
| `istore_1` | `[]` |

**Important:** `invokestatic` expects arguments on the operand stack **in order** (left to right). It pops them, passes them to the new frame's locals, executes the method, and pushes the return value back.

---

## The Operand Stack During a Method Call — Full Picture

When `foo()` calls `bar(1, 2)`:

```
Before invokestatic:
┌────────────────────────────────┐
│  Frame for foo()               │
│  ┌──────────────────────────┐  │
│  │ Local Var Array: ...     │  │
│  │ Operand Stack: [2, 1]    │  │  ← args pushed by foo
│  └──────────────────────────┘  │
└────────────────────────────────┘

After invokestatic pushes bar's frame:
┌────────────────────────────────┐
│  Frame for bar()               │  ← new frame on top
│  ┌──────────────────────────┐  │
│  │ Local Var Array: [1, 2]  │  │  ← args popped from foo's opstack
│  │ Operand Stack: []        │  │  ← starts empty
│  └──────────────────────────┘  │
├────────────────────────────────┤
│  Frame for foo()               │
│  ┌──────────────────────────┐  │
│  │ Local Var Array: ...     │  │
│  │ Operand Stack: []        │  │  ← emptied (args consumed)
│  └──────────────────────────┘  │
└────────────────────────────────┘
```

Key: **args flow from caller's operand stack → callee's local array.**

---

## Worked Example 4: Object Creation

```java
Person p = new Person();
```

Bytecode:

```
new #2              // allocate Person, push reference
dup                 // duplicate the reference
invokespecial #3    // call <init> (consumes one ref)
astore_1            // pop remaining ref → slot 1
```

Operand Stack evolution:

| Instruction | Operand Stack |
|-------------|---------------|
| `new #2` | `[ref]` |
| `dup` | `[ref, ref]` |
| `invokespecial` | `[ref]` (one consumed by `<init>`) |
| `astore_1` | `[]` |

Why `dup`? Because `<init>` needs a `this` reference to work on, but we also need to keep a reference to store into the local. `dup` copies it so both needs are satisfied.

---

## Worked Example 5: Field Access

```java
int age = person.age;
```

Bytecode:

```
aload_1                  // push person reference
getfield Person.age:I    // pop ref, push field value
istore_2                 // pop → slot 2
```

Operand Stack:

| Instruction | Operand Stack |
|-------------|---------------|
| `aload_1` | `[ref]` |
| `getfield` | `[30]` |
| `istore_2` | `[]` |

`getfield` **pops the object reference**, reads the field from the heap, and **pushes the field value**.

---

## The Operand Stack Is Ephemeral

Unlike locals, which persist for the method's lifetime, the operand stack is **transient**:

- Values are pushed, consumed, and gone
- At the end of the method, the operand stack must be **empty** (except for the return value)
- The verifier enforces this

```
Method start:  operand stack = []
Method middle: operand stack grows and shrinks as needed
Method return: operand stack = [returnValue]  (or [] for void)
```

---

## How Big Can It Get? — `max_stack`

`javac` computes the **maximum depth** the operand stack reaches during the method and records it in the `.class` file as `max_stack`.

```java
int a = 1 + 2 + 3 + 4;
```

Bytecode:

```
iconst_1     // [1]
iconst_2     // [2, 1]
iadd         // [3]
iconst_3     // [3, 3]
iadd         // [6]
iconst_4     // [4, 6]
iadd         // [10]
istore_1     // []
```

`max_stack` for this method = **2** (never more than 2 values on the stack at once).

If you write `(a + b) * (c + d)`:

```
iload_1   // [a]
iload_2   // [b, a]
iadd      // [a+b]
iload_3   // [c, a+b]
iload 4   // [d, c, a+b]
iadd      // [c+d, a+b]
imul      // [(a+b)*(c+d)]
```

`max_stack = 3`.

---

## What If You Exceed It?

The verifier checks that the operand stack never exceeds `max_stack`. If somehow it did at runtime, you'd get a `VerifyError` (during class loading) or the JVM could misbehave. But `javac` computes it correctly, so this essentially never happens with legitimate bytecode.

Contrast with the **call stack** depth — exceeding *that* gives `StackOverflowError`.

| Limit | Exceeded → |
|-------|-----------|
| `max_stack` (operand stack depth per frame) | `VerifyError` (usually at load time) |
| `max_locals` (locals per frame) | `VerifyError` |
| Call stack depth (number of frames) | `StackOverflowError` |

---

## Operand Stack vs Local Variable Array

| Aspect | Local Variable Array | Operand Stack |
|--------|----------------------|---------------|
| Purpose | **Store** variables | **Compute** with values |
| Access | Random (by index) | LIFO (only top) |
| Persistence | Whole method | Momentary |
| Named in bytecode | `iload_1`, `istore_2` | Implicit — every instruction uses it |
| Cleared between instructions? | No | Values come and go |
| Size attribute | `max_locals` | `max_stack` |

---

## Summary Diagram

```
Frame for method foo()
┌─────────────────────────────────────────────┐
│ Local Variable Array                        │
│ ┌──────┬──────┬──────┬──────┬──────┐        │
│ │ a=5  │ b=10 │ c=15 │ p=ref│ ...  │        │
│ └──────┴──────┴──────┴──┬───┴──────┘        │
│                          │                   │
│ Operand Stack            │ (ref points to    │
│ ┌──────┬──────┬──────┐  │  heap object)     │
│ │ 20   │ 15   │  5   │  │                   │
│ └──────┴──────┴──────┘  │                   │
│   ▲                      │                   │
│   │ top                  ▼                   │
│                    ┌─────────────────┐      │
│ Frame Data         │  HEAP           │      │
│  - PC              │  Person object  │      │
│  - cpool ref       │  ...            │      │
│  - exception table └─────────────────┘      │
└─────────────────────────────────────────────┘
```

---

## TL;DR

| Question | Answer |
|----------|--------|
| What is the Operand Stack? | A LIFO workspace inside each frame for computation |
| Where does it live? | Inside the frame, on the thread's JVM Stack |
| Is it a Java object? | ❌ No — internal JVM memory region |
| What does it hold? | Same 9 types as locals (1 or 2 slots each) |
| How is it sized? | Fixed, computed by `javac`, stored as `max_stack` |
| How do instructions use it? | Push/pop operands and results |
| Is it persistent? | No — values come and go per instruction |
| Does it point to the heap? | It can *hold* references that point to the heap, just like locals |
| What if you exceed it? | `VerifyError` (but `javac` prevents this) |

So: **the Local Variable Array stores; the Operand Stack computes.** Both live in the same frame, both use the same slot model, and both follow the same type rules — but they serve completely different roles.


[[Java]]