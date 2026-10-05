

## Part 1: The core intuition — two separate memory regions, one relationship

Before any diagrams, the mental model you need:

```
STACK  → where METHOD EXECUTION lives (one stack per thread)
HEAP    → where OBJECTS actually live (one heap, shared by ALL threads)

A stack variable never HOLDS an object.
A stack variable holds a REFERENCE — essentially an address — POINTING to an object on the heap.
```

Think of the stack as a notepad you scribble on while working, and the heap as a giant warehouse. When you write `User user = new User("Alireza")`, you're not putting the `User` object on your notepad — you're writing down the **warehouse aisle number** on your notepad, while the actual `User` object sits physically in the warehouse. The notepad page gets torn up and thrown away the moment you finish that particular task (method call); the warehouse item stays, potentially long after.

This is genuinely the foundational fact everything else in this tutorial builds on.

---

## Part 2: The stack — what a "stack frame" actually is

### Every thread gets its own stack

```java
Thread t = new Thread(() -> doWork()); // this thread gets its OWN separate stack
t.start();
```

This connects directly to your threads tutorials: each `Thread` (whether platform or virtual) has its own private call stack — this is exactly _why_ local variables are inherently thread-safe (no sharing) while heap objects are the ones you needed `synchronized`/`wait`/`notify` for.

### A stack frame is created per method call

```java
void methodA() {
    int x = 5;
    methodB();
}

void methodB() {
    int y = 10;
}
```

```
Stack (grows downward as calls happen):

┌─────────────────────┐
│  Frame: methodB()   │  ← pushed when methodB() is called
│  y = 10             │
├─────────────────────┤
│  Frame: methodA()   │  ← was already here
│  x = 5              │
├─────────────────────┤
│  Frame: main()      │  ← the very first frame
└─────────────────────┘
```

**Each frame contains:**

- **Local variables** (including method parameters and `this`, for instance methods)
- **The operand stack** (a scratch space the JVM uses for intermediate computation — you don't interact with this directly, but it's genuinely part of the frame)
- **A reference back to the constant pool** (for resolving symbolic references — details below)
- **A return address** — where execution resumes in the _calling_ frame once this method finishes

When `methodB()` returns, its **entire frame is popped and discarded** — `y` simply ceases to exist, instantly, with zero cleanup cost (this is a key point we'll return to for garbage collection).

### This is exactly why `StackOverflowError` happens (from the exceptions tutorial)

```java
void recurse() {
    recurse(); // each call pushes ANOTHER frame, without ever popping any
}
```

```
Frame: recurse() #50000
Frame: recurse() #49999
Frame: recurse() #49998
...
Frame: recurse() #1
Frame: main()
```

Each stack has a **fixed maximum size** (configurable via `-Xss`) — infinite recursion keeps pushing frames until that boundary is hit, throwing `StackOverflowError` (from the `Error` hierarchy in the exceptions tutorial — unrecoverable, since the stack itself is now exhausted).

---

## Part 3: What actually sits inside a local variable slot

This is where we get precise about "reference," since that word gets used loosely.

### Case 1: primitives — the actual value sits directly in the stack frame

```java
void method() {
    int x = 5; // the literal bits representing 5 sit DIRECTLY in this stack frame slot
}
```

```
Stack frame:
┌──────────┐
│  x = 5   │   ← actual value, right here, no indirection at all
└──────────┘
```

No heap involvement whatsoever — primitives are entirely stack-resident (or, if they're fields of an object, they live directly inside that object's memory on the heap — more on this below).

### Case 2: object references — the stack holds a pointer, not the object

```java
void method() {
    User user = new User("Alireza"); // `user` is a REFERENCE variable
}
```

```
Stack frame:                          Heap:
┌───────────────────┐               ┌─────────────────────────┐
│ user = 0x7f3a2c10 │ ─────────────▶│ 0x7f3a2c10: User object │
└───────────────────┘               │   name: "Alireza"       │
	                                │   (+ object header)     │
                                    └─────────────────────────┘
```

**What's literally sitting in the `user` slot is a memory address** (in real JVM implementations, this is often an "oop" — ordinary object pointer — sometimes compressed to 32 bits even on a 64-bit JVM, a detail called "compressed oops," used specifically to save memory). The slot itself is small and fixed-size (essentially the size of a pointer) — regardless of how large or complex the actual `User` object is on the heap.

**This is why assignment between reference variables doesn't copy the object:**

```java
User a = new User("Alireza");
User b = a; // copies the ADDRESS, not the object
```

```
Stack:                                Heap:
┌────────────────┐                  ┌───────────────────┐
│ a = 0x7f3a2c10     │ ────┐              │ 0x7f3a2c10: User    │
│ b = 0x7f3a2c10     │ ────┴─────────▶│   name: "Alireza"       │
└────────────────┘                  └───────────────────┘
```

Both `a` and `b` now point to the **exact same** object — this is the direct mechanical explanation for why `a.setName("Sara")` also changes what `b` sees, something you've likely encountered as a surprise if you're used to value-type languages.

### Case 3: object fields, in turn, can hold references too

```java
class User {
    String name;      // reference field
    Address address;  // reference field, pointing to ANOTHER heap object
}
```

```
Heap:
┌─────────────────────────┐
│ User object (0x7f3a2c10)   │
│   name → 0x7f3a2c50 (String) │
│   address → 0x7f3a2d00 (Address) │
└─────────────────────────┘
                                    ┌────────────────────────┐
                                    │ Address object (0x7f3a2d00) │
                                    │   city → 0x7f3a2d40 (String) │
                                    └────────────────────────┘
```

**This is the key structural fact for garbage collection:** the heap is not a flat pile of isolated objects — it's a **graph**, where objects point to other objects, which point to other objects. A single stack variable can be the entry point to a huge, deeply nested web of connected heap objects.

---

## Part 4: The object header — what's actually stored with every heap object

Since you asked "what it looks like" — here's the concrete internal shape of a heap object (this connects directly to the marker interfaces tutorial and the Java 25 Compact Object Headers feature):

```
┌──────────────────────────────┐
│  Object Header                   │
│    - Mark Word (hash code, GC age, lock state, etc.) │
│    - Klass Pointer (which CLASS this object is an instance of) │
├──────────────────────────────┤
│  Instance Data                      │
│    - field values (primitives stored directly, references as pointers) │
├──────────────────────────────┤
│  Padding (alignment)                  │
└──────────────────────────────┘
```

- **Mark Word** — encodes things like the object's identity hash code, its "age" (how many GC cycles it's survived — critical for generational GC, covered below), and locking state (relevant to your `synchronized` tutorial — this is literally where the lock bit for an object lives)
- **Klass Pointer** — a pointer to metadata describing the object's **class** (its methods, its field layout) — this is what makes `getClass()`/`instanceof` (from your marker interfaces tutorial) possible at runtime

This header exists on **every single heap object**, which is exactly why the Java 25 "Compact Object Headers" feature (shrinking it from ~96-128 bits to 64 bits) mattered — it's overhead multiplied by every object you ever create.

---

## Part 5: Now — Garbage Collection. The core problem it solves

### The problem, stated precisely

```java
void method() {
    User user = new User("Alireza"); // heap object created
} // method returns — the STACK FRAME is popped, `user` the VARIABLE ceases to exist
```

The stack frame is gone instantly and cheaply. But **the `User` object itself is still sitting on the heap** — nobody explicitly told the heap to remove it. In a language like C (which you learned about in the I/O tutorials' historical comparisons), **you** would be responsible for calling `free()` on that memory yourself — and forgetting to is a **memory leak**; doing it too early or twice is a crash (a "dangling pointer" / "double free").

**Garbage collection solves this by automatically detecting which heap objects are no longer reachable from anywhere your running program could still access, and reclaiming their memory — without you ever calling anything like `free()`.**

### The core question GC has to answer

**"Is this object still reachable — can my program still get to it, starting from somewhere it's currently executing?"**

If **yes** → keep it, it might still be used.  
If **no** → nothing in the running program could possibly reach it anymore, so it's safe to destroy and reclaim its memory.

---

## Part 6: GC Roots — the actual starting points of that reachability question

### Definition

**A GC Root is a reference that is considered "alive" by definition, not because something else points to it** — it's a starting point the garbage collector begins tracing from, to determine what's reachable.

```
GC Roots  →  traced outward, following every reference chain  →  everything reachable = ALIVE
                                                                    everything NOT reached = GARBAGE
```

### What actually counts as a GC Root

|GC Root type|What it is|
|---|---|
|**Local variables in any currently active stack frame**|every reference variable sitting in any thread's stack, right now|
|**Active thread objects themselves**|a running `Thread` object is itself a root|
|**Static fields of loaded classes**|`static` fields live for the lifetime of the class, so they're always roots|
|**JNI references**|references held by native (non-Java) code calling into the JVM|
|**Objects used for synchronization**|anything currently the target of a `synchronized` block (connects to your `wait`/`notify` tutorial)|

**This is exactly why local stack variables matter so much to GC — they're literally the starting points of the entire reachability analysis.**

### Tracing reachability — a concrete example

```java
class User {
    Address address;
}

void method() {
    User user = new User();          // user → GC ROOT (local variable, active frame)
    user.address = new Address();       // Address object — reachable THROUGH user
}
// method returns — the frame is popped, `user` is no longer a GC root
```

```
While method() is executing:

GC Root: user (stack) ──▶ User object (heap) ──▶ Address object (heap)
                                              ↑
                                    reachable, therefore ALIVE

After method() returns:

(no GC root points to the User object anymore)

    User object (heap)  ──▶ Address object (heap)
       ↑ UNREACHABLE            ↑ UNREACHABLE (nothing points TO the User object anymore, so nothing can reach Address through it either)
```

**Both objects are now garbage** — even though `User` and `Address` still technically point to each other's neighborhood in memory, **neither is reachable from any GC Root anymore**, so both become eligible for collection.

### The crucial insight: reachability, not reference counting

```java
class Node {
    Node other;
}

Node a = new Node();
Node b = new Node();
a.other = b;
b.other = a; // a and b reference EACH OTHER

a = null;
b = null; // no LOCAL VARIABLE points to either anymore
```

```
Before nulling:
GC Root: a ──▶ Node A ⇄ Node B ◀── GC Root: b

After nulling:
        Node A ⇄ Node B
   (they still point to EACH OTHER, but no GC ROOT reaches either one)
```

**Both are garbage**, even though they still reference each other and their "reference count" (how many other objects point to them) is nonzero. **This is genuinely important and a common misconception** — some other languages/systems use simple reference counting (an object dies the instant its reference count hits zero), which **fails** on exactly this circular-reference scenario, since each object's count never actually reaches zero. Java's tracing-based GC (start from roots, follow pointers, see what you reach) handles circular references correctly, automatically, with no special case needed.

---

## Part 7: Garbage Collection algorithms — how the actual reclaiming works

### Mark and Sweep — the foundational algorithm

**Step 1 — Mark:** starting from every GC Root, trace every reachable reference, marking every object you touch as "alive."

```
GC Root ──▶ [MARK] Object A ──▶ [MARK] Object B
                                              
                Object C (unreached) — stays UNMARKED
```

**Step 2 — Sweep:** walk through the entire heap; any object **not** marked is garbage — its memory is reclaimed.

```
Heap before sweep: [A: marked] [B: marked] [C: unmarked] [D: marked] [E: unmarked]
Heap after sweep:   [A]         [B]         [ freed ]     [D]         [ freed ]
```

**The problem with plain mark-and-sweep:** it leaves **fragmentation** — freed memory is scattered in gaps between surviving objects, rather than one contiguous free block. This makes it harder to allocate a large new object later, even if the _total_ free memory would technically be enough.

### Mark-Compact — solving the fragmentation problem

After marking, instead of just freeing dead objects in place, **compact**: slide all surviving objects together, eliminating the gaps.

```
Before compact: [A: alive] [ gap ] [B: alive] [ gap ] [D: alive]
After compact:  [A: alive][B: alive][D: alive] [ ─── free space ─── ]
```

**Trade-off:** compaction means every surviving object's memory address can change — every reference pointing to it (in every stack frame, every other object's fields) must be **updated** to the new address. This is genuine extra work compared to plain sweep, but it keeps memory contiguous, which matters enormously for allocation speed (a contiguous free region means new allocation is just "bump a pointer forward," extremely cheap).

### The key insight that leads to generational GC: most objects die young

This is an empirically observed pattern across essentially all real programs — the **"weak generational hypothesis"**: the vast majority of objects become garbage very shortly after creation (a local variable in a short method, a temporary string built during one calculation), while a small minority live for a very long time (caches, singleton services, long-lived configuration objects).

**Generational GC exploits this directly** by splitting the heap into regions based on object age, and collecting them differently:

```
┌─────────────────────────────────────┐
│  YOUNG GENERATION                       │  ← new objects born here; collected FREQUENTLY, cheaply
│    ┌──────┐  ┌───────┐  ┌───────┐         │
│    │ Eden │  │ Sur. 0  │  │ Sur. 1  │         │
│    └──────┘  └───────┘  └───────┘         │
├─────────────────────────────────────┤
│  OLD GENERATION (Tenured)                 │  ← long-lived objects end up here; collected RARELY, more expensively
└─────────────────────────────────────┘
```

**How an object moves through this:**

1. **New objects are allocated in Eden** (part of the young generation).
2. When Eden fills up, a **minor GC** runs — only scanning the (small) young generation, tracing from GC Roots. Surviving objects move to a **Survivor space**, and their "age" counter (from the object header's Mark Word, mentioned earlier) increments.
3. Objects bouncing between Survivor spaces that reach a certain age threshold get **promoted** to the Old Generation.
4. The Old Generation is collected far less often, via a **major/full GC**, since scanning it is more expensive (it's typically much larger).

**Why this is a genuine performance win:** because most objects die young (the hypothesis above), minor GCs — which only need to scan the small young generation — can reclaim the **vast majority** of garbage very cheaply and frequently, while the expensive full-heap scan (major GC) happens rarely, since relatively few objects survive long enough to need it.

```java
void processRequest() {
    String temp = "processing..."; // dies almost immediately — perfect young-gen candidate, cheap to collect
}

static Cache globalCache = new Cache(); // lives for the WHOLE APPLICATION — promoted to old gen, rarely re-scanned
```

---

## Part 8: Modern collectors — connecting to what you already know from the JDK version tutorials

This directly ties back to the ZGC/Shenandoah mentions from your Java 21/25/26 tutorials — now you have the conceptual foundation to understand _what_ those collectors are actually doing differently.

### G1 (Garbage-First) — the long-standing default

Divides the heap into many small, equal-sized **regions** (not strictly one contiguous young/old split) and prioritizes collecting the regions with the **most garbage first** — hence "Garbage-First." Aims for predictable, bounded pause times rather than absolute minimum pauses.

### ZGC / Shenandoah — the low-pause-time collectors

These do the vast majority of their marking and compaction work **concurrently**, while your application threads keep running — rather than fully "stopping the world" (pausing every application thread) for the whole GC cycle, as older collectors largely did. This connects directly to what "Generational ZGC" (Java 21) and "Generational Shenandoah" (Java 26) actually added: applying the young/old generational split you now understand to these already-low-pause collectors, since even a concurrent collector benefits from not having to scan long-lived objects as often.

### "Stop-the-world" — a term worth defining precisely now

**A stop-the-world pause is a period where the JVM suspends every single application thread** so that garbage collection can safely trace and move objects without an application thread simultaneously mutating a reference mid-trace (which would corrupt the collector's view of the object graph — a genuine race condition, exactly the kind covered in your concurrency tutorials, just between application threads and the GC itself). The entire multi-decade trend in GC design (Serial → Parallel → G1 → ZGC/Shenandoah) has been steadily shrinking how long, and how often, these pauses need to happen.

---

## Part 9: Putting the whole picture together — one end-to-end trace

```java
class Address {
    String city;
    Address(String city) { this.city = city; }
}

class User {
    String name;
    Address address;
    User(String name, Address address) {
        this.name = name;
        this.address = address;
    }
}

void createUser() {
    Address addr = new Address("Tehran");     // (1)
    User user = new User("Alireza", addr);      // (2)
    addr = null;                                    // (3)
} // (4) method returns
```

**Step by step:**

**(1)** `addr` (a GC Root — local variable, active frame) points to a new `Address` object on the heap.

**(2)** `user` (also a GC Root) points to a new `User` object, whose `address` field **also** points to that same `Address` object. The `Address` object is now reachable **two ways**: directly via `addr`, and indirectly via `user.address`.

**(3)** `addr = null` removes the _direct_ path — but the `Address` object is **still reachable** via `user.address`, so it's still alive. This is a direct, concrete illustration of why reachability tracing (not simple "does any single variable point to it") is the correct model.

**(4)** `createUser()` returns — the entire stack frame is popped. **Both `user` and `addr` cease to exist as GC Roots simultaneously.** Now:

```
No GC Root reaches User object → UNREACHABLE
No GC Root reaches Address object (nothing reaches it directly, and the thing that reached it indirectly — User — is itself now unreachable) → UNREACHABLE
```

Both objects become garbage **at the same moment** — the next time a GC cycle runs (likely a young-gen minor GC, since both objects are freshly created and short-lived, exactly the weak generational hypothesis in action), the collector traces from the current GC Roots, finds neither object reachable, and reclaims both.

---

## Summary — the full chain, stated as one sentence each

|Concept|One-line definition|
|---|---|
|**Stack frame**|per-method-call memory holding local variables + bookkeeping, pushed/popped automatically|
|**Reference variable**|a stack slot (or object field) holding a heap memory address, not the object itself|
|**Heap**|shared memory region where all objects actually live, organized as a graph via references|
|**Object header**|per-object metadata (mark word + class pointer) prepended to every heap object|
|**GC Root**|a reference considered inherently "alive" — the starting point for reachability tracing (active locals, statics, running threads, etc.)|
|**Reachability**|an object is alive if some chain of references, starting from a GC Root, reaches it|
|**Mark-and-sweep**|trace reachable objects from roots (mark), then reclaim everything unmarked (sweep)|
|**Compaction**|slide survivors together after sweeping, eliminating fragmentation, at the cost of updating references|
|**Generational GC**|exploits "most objects die young" by collecting a small young generation frequently/cheaply, and a large old generation rarely|
|**Stop-the-world pause**|application threads suspended so GC can safely trace/move objects without racing against live mutation|

## Where this connects to everything else you've learned

This tutorial is genuinely the layer _underneath_ almost everything covered across this entire conversation: it's why the concurrency tutorials' synchronization matters (the Mark Word literally holds lock state); it's the mechanical reason `ArrayList` vs `LinkedList`'s memory overhead (node pointers) matters for GC scanning cost; it's why the object header discussion from the marker interfaces tutorial and the Java 25 Compact Object Headers feature exist at all; and it directly explains _why_ `StackOverflowError` and `OutOfMemoryError` (from the exceptions tutorial) are fundamentally different failures — one is the stack running out of frame space, the other is the heap running out of GC-reclaimable room.

[[Java]]