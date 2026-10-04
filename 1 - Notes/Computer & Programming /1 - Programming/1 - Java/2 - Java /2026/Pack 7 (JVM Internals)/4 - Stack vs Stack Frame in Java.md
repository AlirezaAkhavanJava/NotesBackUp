

## The Hierarchy

```
JVM Instance
│
├── Thread 1
│   └── JVM Stack (one per thread)
│       ├── Frame (method A)   ← top of stack
│       ├── Frame (method B)
│       └── Frame (method C)   ← bottom of stack
│
├── Thread 2
│   └── JVM Stack (one per thread)
│       ├── Frame (method X)
│       └── Frame (method Y)
│
└── Thread 3
    └── JVM Stack (one per thread)
        └── ...
```



| Question | Answer |
|----------|--------|
| Stack per thread? | ✅ **Yes** — each thread has its own JVM Stack |
| Stack frame per thread? | ❌ No — a thread has **many** frames |
| Stack frame per method? | ✅ **Yes** — one frame per method invocation |


---

## Stack vs Stack Frame — The Difference

### JVM Stack (a.k.a. "Java Virtual Machine Stack")
- **One per thread**
- Created when the thread starts
- Holds a sequence of **frames**
- Grows/shrinks as methods are called/returned
- Fixed or dynamic size (set via `-Xss`)
- Throws `StackOverflowError` if too deep, `OutOfMemoryError` if it can grow no further

### Stack Frame
- **One per method invocation**
- Created when a method is called, destroyed when it returns
- Contains:
  - **Local Variable Array** (parameters + locals)
  - **Operand Stack** 
  - **Reference to runtime constant pool**
  - **Return address / frame data**
- Pushed onto the thread's JVM Stack on call, popped on return

## Visual Analogy

Think of it like a **stack of plates**:

- **The JVM Stack** = the whole pile of plates (one pile per thread)
- **A Stack Frame** = a single plate (one plate per method call)

When you call a method → push a plate  
When the method returns → pop the plate

```
   ┌──────────────┐
   │  main()      │  ← bottom frame
   ├──────────────┤
   │  methodA()   │
   ├──────────────┤
   │  methodB()   │
   ├──────────────┤
   │  methodC()   │  ← top frame (currently executing)
   └──────────────┘
        ▲
        │
   This whole thing = one thread's JVM Stack
   Each row         = one Stack Frame
```

## Concrete Example

```java
public class Demo {
    public static void main(String[] args) {
        a();          // frame for main pushed
    }
    static void a() {
        b();          // frame for a pushed
    }
    static void b() {
        c();          // frame for b pushed
    }
    static void c() {
        // frame for c pushed
        // now we have 4 frames on this thread's stack
    }
}
```

At the deepest point, the **main thread's JVM Stack** looks like:

```
┌──────────────┐
│  c()  frame  │  ← top
├──────────────┤
│  b()  frame  │
├──────────────┤
│  a()  frame  │
├──────────────┤
│ main() frame │  ← bottom
└──────────────┘
```

## Why Per-Thread Stacks?

Because each thread executes independently. If stacks were shared:

- Two threads calling methods would collide
- Thread A's return address could be overwritten by Thread B
- No safe concurrency

So the JVM gives **each thread its own private stack** — this is what makes multithreading possible without locking every method call.

## Common Confusion: "Stack" and "Heap"

Don't confuse with the **Heap**:

| Region | Scope | Stores |
|--------|-------|--------|
| JVM Stack | Per thread | Frames (locals, operand stack, refs) |
| Heap | Shared by all threads | Objects, arrays, class instances |

Local variables on the stack often **hold references** to objects that live on the shared heap.

## Quick Reference Table

| Concept | Scope | Lifetime | Count |
|---------|-------|----------|-------|
| Heap | JVM-wide | Until GC | 1 per JVM |
| Method Area / Metaspace | JVM-wide | Until JVM exits | 1 per JVM |
| JVM Stack | Per thread | Thread lifetime | 1 per thread |
| Stack Frame | Per method call | Method execution | 1 per active method call |
| Operand Stack | Per frame | Method execution | 1 per frame |
| Local Variable Array | Per frame | Method execution | 1 per frame |

## TL;DR

> **Stack per thread ✅**  
> **Stack frame per method ✅**  
> **Stack per method ❌** (a method gets a *frame*, not its own stack)  
> **Stack frame per thread ❌** (a thread has *many* frames, not just one)

So the correct mental model is:

**Thread → has one Stack → Stack contains many Frames → each Frame belongs to one method call → each Frame has its own Operand Stack.**


[[Java]]