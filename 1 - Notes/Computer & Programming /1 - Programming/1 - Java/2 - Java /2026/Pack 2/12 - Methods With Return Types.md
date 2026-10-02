
## The Core Rule

> **A method must leave exactly one value on its operand stack at the moment of return — the return value — or nothing at all for `void`.**

The return instruction pops that value, discards the frame, and pushes the value onto the **caller's** operand stack.

---

## The Return Instructions

The JVM has **6** return instructions, one per return type:

| Instruction | Return type | Slots popped | Example |
|-------------|-------------|--------------|---------|
| `ireturn` | `int` (and `boolean`, `byte`, `char`, `short`) | 1 | `return 5;` |
| `lreturn` | `long` | 2 | `return 10L;` |
| `freturn` | `float` | 1 | `return 1.5f;` |
| `dreturn` | `double` | 2 | `return 3.14;` |
| `areturn` | any reference type | 1 | `return "hi";` / `return p;` |
| `return` | `void` | 0 | `return;` |

Note the pattern: same prefixes as load/store (`i`, `l`, `f`, `d`, `a`), plus bare `return` for void.

---

## The Full Lifecycle of a Return

When a method returns:

1. **Value is pushed** onto the returning method's operand stack (by preceding instructions)
2. **Return instruction executes** — pops the value off the operand stack
3. **Frame is destroyed** — locals, operand stack, frame data all discarded
4. **Caller's frame becomes active** again
5. **Return value is pushed** onto the **caller's** operand stack
6. **Execution resumes** in the caller at the return address

---

## Example 1: `int` Return

```java
static int add(int a, int b) {
    return a + b;
}
```

Bytecode:

```
iload_0     // push a
iload_1     // push b
iadd        // pop b, pop a, push (a+b)
ireturn     // pop result, return it to caller
```

Operand Stack in `add()`'s frame:

| Instruction | Operand Stack |
|-------------|---------------|
| (start) | `[]` |
| `iload_0` | `[a]` |
| `iload_1` | `[b, a]` |
| `iadd` | `[a+b]` |
| `ireturn` | pops `a+b`, frame destroyed |

---

## Example 2: `void` Return

```java
static void greet() {
    System.out.println("Hi");
}
```

Bytecode:

```
getstatic System.out
ldc "Hi"
invokevirtual println:(Ljava/lang/String;)V
return                 // no value to pop
```

The `return` instruction:
- Pops nothing
- Destroys the frame
- Pushes nothing onto the caller's operand stack

---

## Example 3: `long` Return (2 Slots)

```java
static long big() {
    return 10000000000L;
}
```

Bytecode:

```
ldc2_w #2     // push long (2 slots) onto operand stack
lreturn       // pop 2 slots, return to caller
```

Operand Stack:

| Instruction | Operand Stack |
|-------------|---------------|
| `ldc2_w #2` | `[10000000000L_hi, 10000000000L_lo]` |
| `lreturn` | pops both slots, frame destroyed |

The caller receives a **2-slot long** on its operand stack.

---

## Example 4: Reference Return

```java
static Person create() {
    return new Person();
}
```

Bytecode:

```
new #2                // allocate Person, push ref
dup                   // duplicate ref
invokespecial #3      // call <init> (consumes one ref)
areturn               // pop ref, return it
```

Operand Stack:

| Instruction | Operand Stack |
|-------------|---------------|
| `new #2` | `[ref]` |
| `dup` | `[ref, ref]` |
| `invokespecial` | `[ref]` |
| `areturn` | pops ref, frame destroyed |

The reference is handed back to the caller — pointing at the same heap object.

---

## What the Caller Sees

When `main()` does:

```java
int sum = add(3, 4);
```

Bytecode for the caller:

```
iconst_3                // push 3
iconst_4                // push 4
invokestatic add:(II)I  // pop args, call add, PUSH RETURN VALUE
istore_1                // pop return value → slot 1
```

Caller's operand stack:

| Instruction | Operand Stack |
|-------------|---------------|
| `iconst_3` | `[3]` |
| `iconst_4` | `[4, 3]` |
| `invokestatic` | `[7]` ← return value pushed by `add` |
| `istore_1` | `[]` |

**Key insight:** From the caller's perspective, `invokestatic` behaves like a **single instruction** that:
- pops the arguments
- runs the whole method (in a new frame)
- pushes the return value

The caller doesn't see the frames come and go — just the argument → result transformation.

---

## The Symmetry: Args In, Result Out

Every method call follows this pattern:

```
CALLER'S OPERAND STACK
    │
    │  push args (in order)
    ▼
invokestatic / invokevirtual / ...
    │  pop args
    │  create new frame, args go into locals
    │  run method
    │  method pushes return value, hits *return
    │  frame destroyed, return value handed back
    ▼
CALLER'S OPERAND STACK
    │  return value now on top
    ▼
continue with next instruction
```

**Arguments flow:** caller's operand stack → callee's local array  
**Return value flows:** callee's operand stack → caller's operand stack

---

## Deep Example: Nested Calls

```java
int result = add(mul(2, 3), mul(4, 5));
```

Bytecode:

```
iconst_2                        // push 2
iconst_3                        // push 3
invokestatic mul:(II)I          // → 6
iconst_4                        // push 4
iconst_5                        // push 5
invokestatic mul:(II)I          // → 20
invokestatic add:(II)I          // → 26
istore_1
```

Operand Stack in caller's frame:

| Instruction | Operand Stack |
|-------------|---------------|
| `iconst_2` | `[2]` |
| `iconst_3` | `[3, 2]` |
| `invokestatic mul` | `[6]` |
| `iconst_4` | `[4, 6]` |
| `iconst_5` | `[5, 4, 6]` |
| `invokestatic mul` | `[20, 6]` |
| `invokestatic add` | `[26]` |
| `istore_1` | `[]` |

Notice how the first result (`6`) **sits on the caller's operand stack** while the second call runs. It's not lost — it's parked on the stack, waiting to be consumed by `add`.

This is why `max_stack` matters: the caller's operand stack must be large enough to hold intermediate values across calls.

---

## Return Value and `max_stack`

The return value occupies slots on the **caller's** operand stack, so `javac` must account for it when computing the caller's `max_stack`.

```java
long x = getLong() + getLong();
```

After each `invokestatic`, a **2-slot long** appears on the caller's stack:

```
invokestatic getLong    // [long1_hi, long1_lo]         (2 slots)
invokestatic getLong    // [long2_hi, long2_lo, long1...] (4 slots)
ladd                    // [sum_hi, sum_lo]              (2 slots)
```

So `max_stack` for the caller must be **at least 4**.

---

## What About the Returning Frame's Operand Stack?

At the moment of return, the method's operand stack must contain **exactly** the return value (or be empty for `void`). The verifier enforces this.

```java
static int bad() {
    int x = 5;
    int y = 10;     // operand stack: [] after storing both
    // no return statement — compile error in Java, but imagine:
    return x;       // must push x, then ireturn
}
```

Bytecode must be:

```
...
iload_1     // push x
ireturn     // pop x, return
```

If the method tried to return with extra junk on the stack, the verifier would reject the class.

---

## Summary Diagram

```
BEFORE add(3, 4) CALL:

main() frame
┌──────────────────────────────┐
│ Operand Stack: [4, 3]        │  ← args pushed
└──────────────────────────────┘

DURING add() EXECUTION:

add() frame                    ← top
┌──────────────────────────────┐
│ Locals: [a=3, b=4]           │
│ Operand Stack: [7]           │  ← result before ireturn
└──────────────────────────────┘
main() frame                   ← suspended
┌──────────────────────────────┐
│ Operand Stack: []            │  ← args consumed
└──────────────────────────────┘

AFTER add() RETURNS:

main() frame                   ← active again
┌──────────────────────────────┐
│ Operand Stack: [7]           │  ← return value pushed
└──────────────────────────────┘
```

---

## Return Type vs Stack Slot Summary

| Return type | Return instruction | Slots popped from callee | Slots pushed to caller |
|-------------|-------------------|--------------------------|------------------------|
| `void` | `return` | 0 | 0 |
| `boolean` | `ireturn` | 1 | 1 |
| `byte` | `ireturn` | 1 | 1 |
| `char` | `ireturn` | 1 | 1 |
| `short` | `ireturn` | 1 | 1 |
| `int` | `ireturn` | 1 | 1 |
| `float` | `freturn` | 1 | 1 |
| `long` | `lreturn` | 2 | 2 |
| `double` | `dreturn` | 2 | 2 |
| Any reference | `areturn` | 1 | 1 |

The symmetry is exact: **what the callee pops = what the caller receives.**

---

## Special Case: Constructors

Constructors (`<init>`) have **no return value** — not even `void` in the bytecode sense. They end with `return`.

```java
class Person {
    Person() { }
}
```

Bytecode:

```
aload_0                     // push this
invokespecial Object.<init> // call super constructor
return                      // void return
```

But they're invoked with `invokespecial`, and the **reference to the new object** is managed by the caller (using `dup` before `invokespecial`, as we saw earlier).

---

## Special Case: `synchronized` Methods

A `synchronized` method's return is wrapped by the JVM:

1. Method executes normally
2. On return, the JVM **releases the monitor** (lock)
3. Then the value is returned to caller

The bytecode doesn't show this — it's implicit in the method's `ACC_SYNCHRONIZED` flag.

---

## TL;DR

| Question | Answer |
|----------|--------|
| What must be on the operand stack at return? | Exactly the return value (0 slots for `void`) |
| Which instruction returns? | `ireturn`, `lreturn`, `freturn`, `dreturn`, `areturn`, or `return` |
| Where does the return value go? | Onto the **caller's** operand stack |
| What happens to the callee's frame? | Destroyed — locals, operand stack, all gone |
| How does the caller resume? | At the return address stored in the callee's frame data |
| How does this affect `max_stack`? | Caller must have room for the return value (1 or 2 slots) |
| Are reference returns special? | No — just a 1-slot reference handed back to the caller |
| Can a method return with extra junk on the stack? | ❌ No — verifier rejects it |

So: **methods communicate results through the operand stack.** Arguments go in via the caller's stack → callee's locals; return values come out via the callee's stack → caller's stack. The frame is the transient context, and the operand stack is the channel through which data flows in and out.


[[Java]]