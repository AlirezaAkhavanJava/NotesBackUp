# Local Variable Arrays — Exactly How Many, and What's Actually Stored

## The direct answer first, since you asked precisely

**One Local Variable Array (LVA) per stack frame.** Not one per stack, not one giant global array. Every single method call — every frame pushed onto every thread's stack — gets its **own, independent** local variable array, sized specifically for that one method.

```
Thread's stack:
┌─────────────────────────────┐
│  Frame: methodC()               │  ← has its OWN local variable array
│    Local Var Array: [slot0][slot1][slot2] │
├─────────────────────────────┤
│  Frame: methodB()               │  ← has a DIFFERENT, separate local variable array
│    Local Var Array: [slot0][slot1] │
├─────────────────────────────┤
│  Frame: methodA()               │  ← yet another, separate local variable array
│    Local Var Array: [slot0][slot1][slot2][slot3] │
└─────────────────────────────┘
```

Let's build this up properly, since the "how many" question only really makes sense once you see how a frame is actually constructed.

---

## Part 1: The core intuition

Think of the local variable array as **the notepad page itself**, not the notepad. In the earlier tutorial's analogy, I described the stack loosely as "a notepad" — the **Local Variable Array is the actual, literal page** you write on for one specific method call. When you call a method, the JVM tears off a **fresh, blank page sized exactly for that method's needs** and hands it to that invocation. When the method returns, that page is thrown away entirely — not reused, not shared, gone.

Call the same method **twice** (even recursively), and you get **two separate pages**, each with its own independent set of slots — this is precisely why recursion works correctly at all (each recursive call needs its own copy of the local variables, not a shared one).

---

## Part 2: Formal definition — what the JVM spec actually says

### The Local Variable Array is a fixed-size array of "slots," determined at compile time

```java
void example(int a, String b) {
    int c = 5;
    double d = 3.14;
}
```

When `javac` compiles this method, it computes **exactly how many slots this method's local variable array needs** — this number, called `max_locals`, is baked directly into the compiled `.class` file's bytecode for this method. It is **not** decided at runtime, and it does **not** grow or shrink dynamically.

```
Slot 0: a        (int parameter)
Slot 1: b        (String reference parameter)
Slot 2: c        (int local)
Slot 3: d        (double local — but wait, doubles need 2 slots! covered below)
```

**When the method is called, the JVM allocates an array of exactly this many slots**, as part of constructing the new stack frame — this is why I say "sized specifically for that method": a method with 3 locals gets a 3-slot array; a method with 20 locals gets a 20-slot array. Every method has its own `max_locals` value, computed independently by the compiler based on that method's own code.

### Instance methods get an extra, hidden first slot: `this`

```java
class User {
    void greet(String name) {
        System.out.println("Hello " + name);
    }
}
```

```
Slot 0: this      ← hidden, implicit — the User instance the method was called on
Slot 1: name        ← the actual parameter you wrote
```

**This is a genuinely important, often-overlooked detail:** every non-`static` method secretly receives `this` as slot 0 of its local variable array — it's not visible in your source code, but it's really there, occupying a real slot, which is exactly how `this.someField` inside an instance method knows which object's field to access. `static` methods have no `this`, so their parameters start at slot 0 instead.

```java
static void staticMethod(String name) {
    // Slot 0: name  ← no `this` here, since static methods aren't called ON an instance
}
```

---

## Part 3: Answering your "one giant array" question directly, with the mechanism proven

You asked whether it might be one array per stack, or one giant array for everything. Here's the concrete proof it's neither, using recursion — the clearest possible demonstration:

```java
int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}
```

Calling `factorial(3)`:

```
Frame for factorial(3):
  Local Var Array: [slot0: n=3]

    calls factorial(2) → NEW frame pushed, NEW array allocated:
    Frame for factorial(2):
      Local Var Array: [slot0: n=2]

        calls factorial(1) → ANOTHER new frame, ANOTHER new array:
        Frame for factorial(1):
          Local Var Array: [slot0: n=1]
          → returns 1, this frame is POPPED and DISCARDED entirely
      
      ← back in factorial(2)'s frame, its OWN array (slot0: n=2) is still fully intact
      → returns 2, this frame is popped

  ← back in factorial(3)'s frame, its OWN array (slot0: n=3) is still fully intact
  → returns 6
```

**If this were one giant shared array (or one array per stack, reused across calls), `n` would get overwritten with each recursive call, and this would produce garbage output.** The fact that `factorial(3)`'s `n` (which equals 3) is still correctly `3` by the time `factorial(2)` and `factorial(1)` have both been called, executed, and popped — proves definitively that each frame's local variable array is entirely separate, independent memory, not shared with any other frame, even for the exact same method.

---

## Part 4: What's actually stored in a slot — your second question, precisely

### Primitives: the actual value sits directly in the slot

```java
void method() {
    int x = 5;
}
```

```
Slot 0 (x): [ 00000000 00000000 00000000 00000101 ]   ← the literal bit pattern for 5, sitting right there
```

**No indirection, no pointer, nothing on the heap involved at all.** The slot itself physically contains the value. This is exactly consistent with what the previous tutorial told you about primitives — restated here at the slot-precision level.

### References: the slot holds a memory address (a pointer into the heap)

```java
void method() {
    User user = new User("Alireza");
}
```

```
Slot 0 (user): [ 0x7f3a2c10 ]   ← a memory ADDRESS, pointing into the heap
                    │
                    ▼
Heap:  0x7f3a2c10: [ User object: name → "Alireza" ]
```

**The slot itself is small and fixed-size** — on most real JVM implementations, a reference slot is essentially the size of a machine word (or a compressed 32-bit oop, on a 64-bit JVM using "compressed oops," mentioned in the previous tutorial) — **regardless of how large the actual object it points to is**. Whether `User` has 2 fields or 200 fields, the slot holding its reference is exactly the same fixed size, because the slot only ever stores the _address_, never the object's actual data.

### A crucial, precise detail: `long` and `double` take **two** slots, not one

```java
void method() {
    int a = 1;      // 1 slot
    long b = 2L;      // 2 slots!
    double c = 3.0;     // 2 slots!
    int d = 4;             // 1 slot
}
```

```
Slot 0: a
Slot 1-2: b     ← long occupies TWO consecutive slots
Slot 3-4: c       ← double ALSO occupies two consecutive slots
Slot 5: d
```

**Why:** every other primitive (`int`, `short`, `byte`, `char`, `boolean`, `float`) and every reference fits comfortably in a single 32-bit slot. But `long` and `double` are **64-bit** values — twice the size of a standard slot — so the JVM spec has them consume **two adjacent slots** to hold their full value. This is a real, specified detail of the JVM's bytecode format, not an implementation quirk — you can verify it yourself by disassembling compiled bytecode with `javap -v`.

---

## Part 5: The Local Variable Array vs. the Operand Stack — a distinction worth being precise about

I mentioned the operand stack briefly in the last tutorial — here's exactly how it relates to the local variable array, since they're both part of a frame but serve very different roles.

```java
int add(int a, int b) {
    return a + b;
}
```

Compiled bytecode (simplified, conceptually):

```
iload_0        // PUSH the value from local var slot 0 (a) onto the operand stack
iload_1        // PUSH the value from local var slot 1 (b) onto the operand stack
iadd           // POP both values off the operand stack, add them, PUSH the result back
ireturn        // POP the result off the operand stack, return it
```

```
Frame:
┌────────────────────────────┐
│  Local Variable Array          │   ← named, indexed storage: "slot 0 is a", "slot 1 is b"
│    [0: a=3] [1: b=4]              │
├────────────────────────────┤
│  Operand Stack                    │   ← a genuine LIFO stack, used for computing expressions
│    (during iadd: push 3, push 4, pop both, push 7) │
└────────────────────────────┘
```

**The distinction that matters:** the local variable array is **random-access, indexed storage** (you can jump directly to "slot 3" at any time) — it's how you _hold onto_ values across multiple bytecode instructions. The operand stack is a genuine **push/pop-only stack** — it's the JVM's actual scratch space for evaluating expressions, one instruction at a time, and it gets emptied and refilled constantly as a method executes. Every arithmetic operation, every method call's arguments, every intermediate computed value passes through the operand stack — but only things you actually assign to a named local variable get copied into the local variable array's indexed slots.

---

## Part 6: Slot reuse within one method — scope matters

This is a genuine nuance worth knowing, connecting to how `max_locals` gets computed efficiently rather than wastefully.

```java
void method() {
    {
        int x = 5; // uses slot 1 (slot 0 reserved for `this`, if instance method)
    } // x's SCOPE ends here
    {
        String y = "hello"; // can REUSE slot 1 — since x is no longer in scope, its slot is free
    }
}
```

**The compiler is smart about this:** since `x` and `y` are never simultaneously in scope, the compiler can safely assign them to the **same slot number** — there's no correctness issue, because bytecode instructions only ever reference `x` while it's genuinely in scope, and only ever reference `y` while _it's_ in scope. This keeps `max_locals` smaller than it would be if every distinct variable name always got its own permanent slot for the method's entire duration, regardless of scoping — a real, deliberate compiler optimization.

---

## Part 7: Connecting this directly back to GC Roots — closing the loop with the last tutorial

This is genuinely the missing precision piece from the previous tutorial's GC Roots section — now you can state it exactly:

**A "local variable in an active stack frame" (a GC Root) is, precisely, any reference-typed slot in that frame's Local Variable Array that currently holds a non-null heap address.**

```java
void method() {
    User user = new User("Alireza"); // Local Var Array slot 1: holds a heap address → this slot IS a GC Root
    int count = 5;                       // Local Var Array slot 2: holds a primitive value → NOT a GC root candidate at all, since it holds no address
}
```

When the garbage collector scans a thread's stack to find its GC Roots, it is, at the precise mechanical level, **walking every active frame's Local Variable Array, and for each slot the JVM knows (from the compiled bytecode's type information) is reference-typed, checking what heap address (if any) it currently holds** — those addresses are exactly the starting points for the reachability trace described in the previous tutorial.

---

## Summary — answering your two questions directly, one more time

|Your question|Precise answer|
|---|---|
|One array per stack frame, per stack, or one giant array?|**One array per stack frame.** Every method invocation gets its own fresh, independently-sized array; frames are never shared, even across recursive calls to the same method; there is no global/shared array of any kind.|
|Where is the value vs. the reference stored?|**Primitives:** the actual bit-pattern value sits directly inside the slot. **References:** the slot holds a heap memory address (a pointer); the actual object data lives separately, out on the heap. `long`/`double` are the one exception, needing two adjacent slots instead of one, since they're 64-bit values in a 32-bit-slot system.|

## Where this fits with everything you've learned

This is the precise, slot-level mechanics underneath the "stack frame holds local variables" statement from the previous tutorial — you now know it's not just "variables live in the frame" but specifically **an indexed array of fixed-size slots, sized per-method at compile time, holding either raw values or heap addresses depending on the variable's type**. This also directly explains something from way back in the threads tutorials: since each thread has its own stack, and each stack frame has its own private local variable array, **local variables are never shared between threads by construction** — there's no array anywhere for two threads to race over, which is exactly why all the race-condition/synchronization concerns from the concurrency tutorials were specifically about **heap-resident, shared object state**, never about local variables themselves.

[[Java]]