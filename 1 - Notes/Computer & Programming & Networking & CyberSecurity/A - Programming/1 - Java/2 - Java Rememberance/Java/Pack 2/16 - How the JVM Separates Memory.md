

The JVM doesn't get one giant block and hand it out — it carves memory into **distinct regions**, each with its own purpose, sizing, and management. Let me show you exactly how.

---

## The Big Picture

The JVM's memory comes from **two sources**:

1. **The OS process address space** (virtual memory given to the JVM process)
2. **The OS itself** (for native structures, thread stacks, etc.)

Within the JVM process, memory is divided into **logical regions**:

```
┌─────────────────────────────────────────────────────────────┐
│              JVM PROCESS (one OS process)                   │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              JAVA HEAP (shared by all threads)         │ │
│  │  ┌──────────┬──────────┬──────────┬──────────┐         │ │
│  │  │  Eden    │ Survivor │ Survivor │  Old Gen │         │ │
│  │  └──────────┴──────────┴──────────┴──────────┘         │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌────────────────────┐  ┌────────────────────────────────┐ │
│  │  METASPACE         │  │  CODE CACHE                    │ │
│  │  (class metadata)  │  │  (JIT-compiled code)           │ │
│  └────────────────────┘  └────────────────────────────────┘ │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Thread 1    │  │ Thread 2    │  │ Thread 3    │  ...     │
│  │ Stack       │  │ Stack       │  │ Stack       │          │
│  │ (private)   │  │ (private)   │  │ (private)   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  NATIVE MEMORY (direct buffers, JNI, internal structs) │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

Each region has its **own address range** within the process — but they're not necessarily contiguous, and modern JVMs don't always reserve everything up front.

---

## The Two Categories of Memory

### 1. JVM-Managed (logical regions)

| Region | Shared? | Managed by | Configurable? |
|--------|---------|------------|---------------|
| Heap | ✅ Shared | GC | `-Xms`, `-Xmx` |
| Metaspace | ✅ Shared | JVM | `-XX:MaxMetaspaceSize` |
| Code Cache | ✅ Shared | JVM | `-XX:ReservedCodeCacheSize` |
| Stack | ❌ Per thread | Call/return | `-Xss` |
| PC Register | ❌ Per thread | — | Not configurable |
| Native Method Stack | ❌ Per thread | — | Part of stack |

### 2. Native / OS-level

| Region | Purpose |
|--------|---------|
| Direct ByteBuffers | `ByteBuffer.allocateDirect()` — off-heap but JVM-managed |
| JNI memory | Native code allocations |
| Internal JVM structures | Thread metadata, GC tables, symbol tables |
| Memory-mapped files | `MappedByteBuffer` |

---

## How Address Space Is Assigned

### Virtual memory, not physical

The JVM deals in **virtual addresses**, not physical. The OS maps virtual pages to physical RAM (and can swap to disk).

When you pass `-Xmx4g`, the JVM **reserves** 4 GB of *virtual* address space for the heap — but doesn't necessarily commit (back with physical RAM) all at once.

```
Virtual Address Space (64-bit = huge)
┌──────────────────────────────────────────────┐
│  0x0000000000000000                          │
│  ...                                          │
│  ┌──────────────────────────────┐            │
│  │  Heap reservation (4 GB)     │  ← -Xmx     │
│  └──────────────────────────────┘            │
│  ┌──────────────────────────────┐            │
│  │  Metaspace reservation       │  ← -XX:MaxMetaspaceSize
│  └──────────────────────────────┘            │
│  ┌──────────────────────────────┐            │
│  │  Code Cache reservation      │            │
│  └──────────────────────────────┘            │
│  ...                                          │
│  ┌──────────────────────────────┐            │
│  │  Thread 1 stack (1 MB)       │  ← -Xss     │
│  └──────────────────────────────┘            │
│  ┌──────────────────────────────┐            │
│  │  Thread 2 stack (1 MB)       │            │
│  └──────────────────────────────┘            │
│  ...                                          │
│  0xFFFFFFFFFFFFFFFF                          │
└──────────────────────────────────────────────┘
```

Each region gets its own **non-overlapping virtual address range**. The OS enforces this — if the JVM tried to write outside a region, it would segfault.

---

## The Heap — A Contiguous Reserved Region

The heap is typically **one contiguous virtual address reservation** (though not required by spec):

```
Heap reservation (e.g., 4 GB virtual)
┌──────────────────────────────────────────────────────┐
│  Young Generation          │   Old Generation         │
│  ┌────────┬──────┬──────┐  │   ┌──────────────────┐   │
│  │  Eden  │ S0   │ S1   │  │   │  Tenured / Old   │   │
│  └────────┴──────┴──────┘  │   └──────────────────┘   │
│                                                       │
│  ← grows/shrinks within reservation →                │
└──────────────────────────────────────────────────────┘
```

- **`-Xms`** = initial committed size
- **`-Xmx`** = maximum reserved size
- GC moves objects within this region
- If heap tries to grow beyond `-Xmx` → `OutOfMemoryError: Java heap space`

The heap is **shared** — all threads allocate into it, and the GC manages it globally.

---

## Metaspace — Separate from the Heap

Since Java 8, class metadata lives in **Metaspace**, which is **not** part of the Java heap.

```
┌──────────────────────────────────────┐
│  Java Heap (-Xmx)                    │  ← object instances
└──────────────────────────────────────┘
┌──────────────────────────────────────┐
│  Metaspace (-XX:MaxMetaspaceSize)    │  ← class metadata
└──────────────────────────────────────┘
```

- **Metaspace is allocated in native memory** (via `malloc`/`mmap`)
- **Not garbage collected in the traditional sense** — classes are unloaded when their classloader is GC'd
- Grows dynamically by default (unlike old PermGen)
- Can be bounded with `-XX:MaxMetaspaceSize`

This separation means a class-heavy app can exhaust Metaspace without touching the heap, and vice versa.

---

## Code Cache — Another Separate Region

JIT-compiled machine code goes into the **Code Cache**:

- Separate from heap and Metaspace
- Bounded by `-XX:ReservedCodeCacheSize` (default ~240 MB on 64-bit)
- If full, JIT stops compiling (falls back to interpreter) — doesn't cause OOM directly
- Historically could cause performance cliff if exhausted

---

## Thread Stacks — Per-Thread, Private

Each thread gets its **own stack**, allocated at thread creation:

```
┌────────────────────────────────────────────┐
│  Thread 1                                  │
│  ┌──────────────────────────────────────┐  │
│  │  JVM Stack (1 MB)                    │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │ Frame: main()                  │  │  │
│  │  │ Frame: methodA()               │  │  │
│  │  │ Frame: methodB()               │  │  │
│  │  └────────────────────────────────┘  │  │
│  ├──────────────────────────────────────┤  │
│  │  PC Register                         │  │
│  ├──────────────────────────────────────┤  │
│  │  Native Method Stack                 │  │
│  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

- **Private** — no other thread can access it
- **Fixed size** — set by `-Xss` (default 512 KB – 1 MB)
- **Allocated at thread creation** — not dynamically grown
- **Freed when thread terminates**
- Total stack memory = `number_of_threads × stack_size`

This is why too many threads → OOM (`unable to create new native thread`): each thread needs its own stack, and the OS has limits.

---

## The PC Register — Per Thread

Each thread has its own **Program Counter** register:

- Holds the address of the currently executing bytecode instruction
- One per thread (so each thread has an independent execution point)
- Not really "memory" in the addressable sense — it's a CPU register

---

## Native Method Stack — Per Thread

For native (JNI) method calls, each thread has a **native method stack**:

- Separate from the JVM stack
- Holds frames for C/C++ methods called via JNI
- Size typically tied to `-Xss`
- Managed by the OS/native ABI, not the JVM

---

## How the Regions Are Actually Allocated

### Heap and Metaspace: `mmap` reservations

On modern HotSpot, at JVM startup:

```
1. JVM reserves virtual address space for heap via mmap(PROT_NONE)
2. As heap grows, commits pages via mprotect(PROT_READ|WRITE)
3. Metaspace is allocated in chunks via mmap as classes load
4. Code Cache is reserved as a separate mmap region
5. Each thread stack is mmap'd at thread creation
```

They're **separate mmap regions** — the OS guarantees they don't overlap.

### Some regions are contiguous, some aren't

- **Heap**: typically one contiguous reservation (for simplicity and GC)
- **Metaspace**: allocated in chunks (Chunked allocation)
- **Code Cache**: one contiguous reservation
- **Thread stacks**: each is its own mmap region

---

## Do They Have "Fixed Addresses"?

**No** — the JVM asks the OS for memory and gets whatever addresses the OS provides. The regions are:

- **Non-overlapping** (enforced by OS)
- **Independently sized**
- **Dynamically placed** (addresses vary per run — ASLR)

They are **logically separated** by the JVM, not physically fixed to specific addresses.

---

## Address Space Layout — Conceptual

```
64-bit Virtual Address Space (simplified)

High addresses (kernel)
────────────────────────────────
        Stack (grows down)        ← thread stacks live here typically
────────────────────────────────
        (unmapped / libraries)
────────────────────────────────
        Heap reservation          ← -Xmx
────────────────────────────────
        Metaspace reservation     ← -XX:MaxMetaspaceSize
────────────────────────────────
        Code Cache reservation
────────────────────────────────
        Native / direct buffers
────────────────────────────────
        JVM internal structures
────────────────────────────────
        Executable / libraries
────────────────────────────────
Low addresses
```

Actual placement varies by OS, architecture, and ASLR — but each region occupies a **distinct, non-overlapping range**.

---

## What About "Off-Heap" Memory?

`ByteBuffer.allocateDirect()` allocates memory **outside the heap**:

```java
ByteBuffer buf = ByteBuffer.allocateDirect(1024 * 1024);
```

- Allocated in **native memory** (via `malloc` or `mmap`)
- Not scanned by GC
- Freed when the `ByteBuffer` object is GC'd (via a `Cleaner`)
- Bounded by `-XX:MaxDirectMemorySize` (defaults to `-Xmx`)
- If exhausted → `OutOfMemoryError: Direct buffer memory`

This is another "region" — but managed partly by the JVM and partly by the OS.

---

## Summary Table

| Region | Shared/Private | Allocation | Address space | Managed by |
|--------|---------------|------------|---------------|------------|
| Heap | Shared | `mmap` reservation | Contiguous (usually) | GC |
| Metaspace | Shared | Chunked `mmap` | Non-contiguous chunks | JVM |
| Code Cache | Shared | `mmap` reservation | Contiguous | JVM/JIT |
| Thread stacks | Private | `mmap` per thread | Separate mmap regions | Call/return |
| PC Register | Private | CPU register | N/A | Hardware |
| Native Method Stack | Private | Part of thread stack | Separate | OS/native |
| Direct Buffers | Shared | `malloc`/`mmap` | Non-contiguous | JVM + Cleaner |
| Native structures | Shared | `malloc` | Non-contiguous | JVM internals |

---

## TL;DR

| Question | Answer |
|----------|--------|
| Does the JVM get one big block? | ❌ No — it gets **multiple separate regions** from the OS |
| Are the regions contiguous? | Heap and Code Cache: usually. Metaspace/stacks: not necessarily |
| Do they have fixed addresses? | ❌ No — the OS decides (with ASLR). Regions are non-overlapping |
| How are they separated? | Separate `mmap` reservations / allocations, enforced by the OS |
| Is the heap shared? | ✅ Yes — all threads allocate into it |
| Are stacks shared? | ❌ No — each thread has its own private stack |
| Is Metaspace part of the heap? | ❌ No — it's separate native memory |
| Can one region's exhaustion affect others? | Not directly — but total process memory is shared |
| Configurable? | ✅ Each region has its own flags (`-Xmx`, `-Xss`, `-XX:MaxMetaspaceSize`, etc.) |

So: **the JVM requests several separate memory regions from the OS at startup and as needed.** Each has its own address range, its own size limits, and its own management strategy. They don't overlap, and exhausting one gives a region-specific error. That's the JVM's memory separation model.


[[Java]]