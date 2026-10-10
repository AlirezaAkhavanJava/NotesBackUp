

## Part 1: The core intuition, rebuilt from scratch

You've seen Mark-and-Sweep mentioned twice now, at a high level. This is the full mechanical treatment — exactly how marking actually happens, what data structures are involved, and every edge case that makes real implementations far subtler than the two-sentence summary.

The name literally describes two sequential phases:

```
PHASE 1: MARK  — starting from GC Roots, find and label every reachable object
PHASE 2: SWEEP  — walk the entire heap; anything NOT labeled gets reclaimed
```

Think of it like a building fire marshal doing a headcount. **Mark phase:** starting from every known exit door (GC Roots), the marshal walks the building, and every person they physically encounter along a valid path gets a wristband. **Sweep phase:** afterward, someone walks through _every room in the entire building_, and anyone without a wristband is treated as not actually present — their space gets freed up. Critically, the marshal doesn't need a master list of everyone who's _supposed_ to be there — they discover who's alive purely by walking reachable paths.

---

## Part 2: The Mark phase, in full mechanical detail

### Step 1: Start with the root set

From the last two tutorials, you know precisely what constitutes a GC Root — local variable array slots (reference-typed, holding non-null values), static fields, active `Thread` objects, JNI references, synchronization targets. The mark phase begins by collecting **all of these, from every thread, at a safepoint**, into what's called the **root set**.

```java
class Node {
    Node next;
    String data;
}

Node a = new Node(); // GC Root: local var slot
Node b = new Node();
Node c = new Node();
a.next = b;
b.next = c;
```

```
Root set: { a }   (only `a` is a directly reachable local variable here)

Heap graph:
a ──▶ Node A ──(next)──▶ Node B ──(next)──▶ Node C
```

### Step 2: Traverse outward, marking each object as it's discovered

The collector needs a **worklist** (typically a stack or queue) to keep track of objects it has found but hasn't yet examined the _fields_ of.

```
Worklist: [ Node A ]   ← seeded with the root

Iteration 1:
  Pop Node A from worklist
  Mark Node A as "reachable" (flip a bit in its object header's Mark Word — from the
    object header tutorial — or record it in a separate bitmap, depending on JVM implementation)
  Examine Node A's fields: finds `next` → Node B
  Push Node B onto worklist

Worklist: [ Node B ]

Iteration 2:
  Pop Node B
  Mark Node B as reachable
  Examine Node B's fields: finds `next` → Node C
  Push Node C onto worklist

Worklist: [ Node C ]

Iteration 3:
  Pop Node C
  Mark Node C as reachable
  Examine Node C's fields: `next` is null — nothing more to push

Worklist: [ ]   ← empty, mark phase for this root is DONE
```

**Every object connected, by any chain of references, to any GC Root eventually gets marked.** This is precisely the graph-traversal algorithm from the previous tutorial, now shown at the level of an actual worklist data structure — genuinely just a graph search (specifically, this is either a depth-first or breadth-first traversal, depending on whether the worklist is implemented as a stack or a queue; real JVMs use variations of both depending on the specific collector).

### Where does the "mark" actually get stored?

This connects directly to the object header tutorial. There are two common real implementation approaches:

**Option A — a bit in the object's own header (Mark Word):**

```
Object header before marking: [ Mark Word: unmarked | Klass Pointer ]
Object header after marking:   [ Mark Word: MARKED     | Klass Pointer ]
```

**Option B — a separate bitmap, external to the objects themselves:**

```
Heap addresses:     0x1000  0x1008  0x1010  0x1018  ...
Separate mark bitmap:  1       0       1       0     ...   (one bit per object-sized chunk of heap)
```

**Modern collectors (including G1 and ZGC/Shenandoah, from the last tutorial) generally prefer the separate bitmap approach** — it avoids modifying the object's own memory during marking (which matters for concurrent collectors, since writing into an object's header while an application thread might be reading it simultaneously is exactly the kind of race condition your concurrency tutorials warned about), and it keeps mark data compactly grouped together, which is more cache-friendly to scan during the sweep phase.

---

## Part 3: Handling cycles — why the worklist approach doesn't loop forever

This is a genuinely important detail the naive description glosses over.

```java
class Node {
    Node other;
}

Node a = new Node();
Node b = new Node();
a.other = b;
b.other = a; // CYCLE — a points to b, b points back to a
```

```
Worklist: [ a ]

Iteration 1: pop a, MARK a, examine fields → finds b, push b
Worklist: [ b ]

Iteration 2: pop b, MARK b, examine fields → finds a...
  CHECK: is `a` already marked? YES → do NOT push it again
Worklist: [ ]   ← done, no infinite loop
```

**The critical safeguard: before pushing an object onto the worklist, the algorithm checks if it's already marked.** If it is, it's skipped entirely — this is exactly what prevents the algorithm from looping forever on cyclic structures, and it's also what makes marking's total work genuinely bounded: **each reachable object gets marked and examined at most once**, no matter how many other objects point to it or how many cycles exist in the graph.

---

## Part 4: The Sweep phase, in full mechanical detail

### The naive version — walk the entire heap, linearly

```
Heap (a contiguous region of memory, objects packed one after another):

[Node A: MARKED][Node B: MARKED][Node D: unmarked][Node C: MARKED][Node E: unmarked]
```

```
Sweep pointer starts at the beginning of the heap, walks forward object by object:

Position 1: Node A → marked → KEEP, unset the mark bit for the NEXT cycle, move on
Position 2: Node B → marked → KEEP, unset mark bit
Position 3: Node D → UNMARKED → this memory is now FREE, add it to a free list
Position 4: Node C → marked → KEEP, unset mark bit
Position 5: Node E → UNMARKED → FREE, add to free list
```

**Resulting free list** (the sweep phase's actual output — a data structure the allocator will use for future `new` calls):

```
Free list: [ address of Node D's old space, size=X ] → [ address of Node E's old space, size=Y ]
```

### Why unmarked objects don't need any "destruction" step

This is worth being explicit about, since people sometimes expect garbage collection to involve something like calling a destructor. **Sweeping an unmarked object doesn't run any code on it at all** — there's no cleanup method invoked, no fields zeroed out individually. The object's memory is simply **relabeled as available**, added to a free-space bookkeeping structure, ready to be handed out again by a future allocation. This is precisely why Java has no destructors in the C++ sense — `finalize()` existed at one point for similar-sounding purposes but is now deprecated (removed pathway) specifically because tying real cleanup logic to sweep timing, which is inherently unpredictable, causes more problems than it solves.

### Resetting marks for the next cycle

Notice above that sweeping also **unmarks** surviving objects as it passes them (`KEEP, unset mark bit`) — this is necessary because the mark bit needs to be back at "unmarked" before the _next_ GC cycle's mark phase begins, otherwise every object would appear permanently reachable regardless of actual reachability. (In bitmap-based implementations, this is often handled more efficiently by simply swapping between two alternating bitmaps each cycle, rather than explicitly clearing bits one by one — but conceptually, the reset still has to happen somehow.)

---

## Part 5: The genuine cost — fragmentation, made concrete

This was mentioned in the earlier tutorial; here's exactly why it's a real, measurable problem.

```
After several sweep cycles, the heap looks like:

[Live][ FREE 40 bytes ][Live][ FREE 12 bytes ][Live][ FREE 8 bytes ][Live]
```

**Total free memory: 60 bytes. But the largest single contiguous free block is only 40 bytes.**

```java
byte[] bigArray = new byte[50]; // needs 50 CONTIGUOUS bytes
```

**This allocation fails — `OutOfMemoryError` — even though the heap technically has 60 free bytes total.** Plain mark-and-sweep, with no compaction step, degrades over repeated cycles into exactly this scattered, unusable state — this is the concrete, mechanical reason mark-**compact** (covered in the previous tutorial) and generational copying collectors exist as refinements: fragmentation isn't a theoretical concern, it's a directly demonstrable failure mode of pure mark-and-sweep used on its own, long-term.

---

## Part 6: Allocation strategy interacts directly with fragmentation

### Free-list allocation — how `new` actually finds space, post-sweep

Once sweep produces a free list, future allocations need a strategy for picking _which_ free block to use:

**First-fit:** use the first free block in the list that's big enough.

```
Free list: [40 bytes] → [12 bytes] → [8 bytes]
Need 10 bytes → uses the 40-byte block (first one that fits), leaving a 30-byte remainder block
```

**Best-fit:** search the whole list, use the smallest block that's still big enough.

```
Need 10 bytes → uses the 12-byte block (tightest fit), leaving only a 2-byte remainder — likely too small to ever be useful again
```

**The trade-off:** first-fit is faster to compute but leaves larger leftover fragments over time; best-fit minimizes waste per-allocation but can actually **worsen overall fragmentation** by scattering many tiny, practically useless leftover slivers throughout the heap. Neither strategy solves fragmentation fundamentally — they just trade off _how_ badly it accumulates, which is exactly why real modern collectors lean toward compaction or copying instead of relying purely on clever free-list management.

---

## Part 7: Tri-color marking — the refinement that makes _concurrent_ mark-and-sweep possible

This is the genuinely advanced piece that directly explains how ZGC/Shenandoah/G1 (from the previous tutorial) can mark **concurrently**, while application threads keep running and keep mutating the object graph mid-trace.

### The problem with naive marking done concurrently

```java
// GC thread is mid-trace, has marked `a` but not yet reached `b`
// Meanwhile, an APPLICATION thread runs this, concurrently:
a.next = null;       // application thread severs the OLD path
someRoot.ref = b;     // application thread creates a NEW path to b, from a DIFFERENT root the GC already finished scanning
```

If the GC already finished examining `someRoot` before the application thread added this new reference, and the GC hasn't yet reached `b` through `a` (because the application thread just deleted that path), **the GC could conclude `b` is unreachable and incorrectly reclaim a still-live object** — a genuinely serious correctness bug, not just a performance issue.

### The tri-color abstraction — a formal model for reasoning about this

Every object during marking is conceptually one of three colors:

```
WHITE  → not yet examined; assumed garbage, UNTIL proven otherwise
GRAY    → examined, marked reachable, but its OWN fields haven't been scanned yet (still "on the worklist")
BLACK    → examined AND all its fields have been fully scanned (fully processed, done)
```

```
Start: everything is WHITE
Root gets colored GRAY, added to the worklist
While worklist is non-empty:
    pop a GRAY object
    color it BLACK
    for each of its reference fields: if the target is WHITE, color it GRAY and add to worklist
End of mark phase: everything still WHITE is genuinely unreachable garbage
```

### The invariant that must never be violated

**The "strong tricolor invariant": a BLACK object must never point directly to a WHITE object.** If this invariant holds throughout the entire concurrent mark phase, correctness is guaranteed — the sweep phase can trust that WHITE really does mean garbage. Your earlier example violated this exact invariant: `a` had already gone BLACK (GC finished examining it, or at least the root pointing toward it had been fully processed) while `b` was still WHITE, and then a black object's neighborhood got mutated in a way that would let a white object slip through undetected.

### The fix — this is precisely why write barriers exist

You already met write barriers in the generational-GC card-table context — here's their **second**, equally important job: during **concurrent** marking, a write barrier is triggered any time application code writes a reference into an object's field, and it can enforce the tricolor invariant by immediately re-coloring the target gray if needed (this specific technique is called a "Yuasa" or "Dijkstra" style barrier, depending on exactly which side of the write it intercepts).

```java
blackObject.field = whiteObject; // application thread does this WHILE GC is mid-mark

// The write barrier intercepts this write and says:
// "wait — I'm about to create a black→white edge, which breaks the invariant"
// → immediately marks whiteObject as GRAY, pushing it back onto the GC's worklist
```

**This is the exact mechanism that makes concurrent mark-and-sweep (and by extension, concurrent mark-compact, which is what ZGC/Shenandoah/G1 actually use in practice) safe to run alongside live application threads** — every single reference write that could threaten correctness gets intercepted and corrected in real time, at the cost of a small amount of overhead on every reference assignment, everywhere in your program, all the time (directly explaining the previous tutorial's note that ZGC's barriers add real, constant per-access cost, not just during pauses).

---

## Part 8: Complexity — how expensive is Mark-and-Sweep, precisely?

```
MARK phase:  O(L)    where L = number of LIVE (reachable) objects
                       — each live object is visited exactly once, as shown in Part 3

SWEEP phase: O(H)    where H = total size of the HEAP (every slot must be walked,
                       whether it's live or garbage, to find out which is which)
```

**This is a genuinely important, often-overlooked characteristic: sweep's cost depends on the _total heap size_, not on how much garbage there actually is.** A heap that's 99% live objects and only 1% garbage still requires a full linear walk of the entire heap during sweep — you can't skip over the live parts, because you don't know in advance where they are without checking each one's mark bit. This is precisely _why_ generational collectors are such a meaningful win: restricting the "sweep-equivalent" work (in a copying young-gen collector, this is actually a _copy_ step rather than a literal sweep, but the same total-region-size cost principle applies) to just the young generation, rather than the entire heap, directly attacks this exact cost characteristic.

---

## Part 9: Mark-Sweep vs. Copying Collection — a related algorithm worth distinguishing precisely

Since your young-generation discussion in the earlier tutorial mentioned "copying," here's the precise contrast with mark-and-sweep, since they're often confused:

```
MARK-AND-SWEEP: objects stay in PLACE. Garbage becomes free space, scattered in gaps.
                Requires: a mark phase + a full-heap sweep phase.

COPYING:        LIVE objects are copied to a completely different region (e.g., Eden → Survivor).
                The OLD region is then considered entirely free, all at once, no sweep needed at all.
```

```
Eden (before):  [Live A][Garbage][Live B][Garbage][Live C]

Copying collection:
  → trace from roots, copy Live A, Live B, Live C to Survivor space (compacting them tightly as you go)
  → Survivor (after): [Live A][Live B][Live C]
  → Eden is now considered ENTIRELY free — the whole region gets reset, no sweep step needed
```

**Why copying is often preferred specifically for the young generation:** since (per the weak generational hypothesis) most objects in Eden are garbage, copying's cost is proportional to how much survives (typically a _small_ fraction) — whereas mark-and-sweep's sweep phase cost is proportional to the _entire_ region's size regardless of survival rate. For a region where you expect 90%+ garbage, copying only the small surviving fraction is dramatically cheaper than sweeping the whole thing, and you get compaction (no fragmentation) as a completely free side effect of the copy. **The trade-off:** copying needs a spare destination region at least as large as what might survive (hence Survivor spaces being separate, reserved regions), which is memory overhead mark-and-sweep in place doesn't require.

This is exactly why real JVMs use **different algorithms for different generations** — a copying collector for the young generation (small, high-garbage-ratio, cheap to over-provision spare space for) and mark-sweep-**compact** for the old generation (large, low-garbage-ratio, where copying's spare-space requirement would be prohibitively expensive).

---

## Summary — the complete mental model, restated

|Concept|Definition|
|---|---|
|**Mark phase**|graph traversal from GC Roots, using a worklist, marking every reachable object exactly once (cycles handled by checking "already marked" before re-adding to the worklist)|
|**Sweep phase**|linear walk of the _entire_ heap; unmarked objects' space becomes free, added to a free list; marked objects have their mark bit reset for the next cycle|
|**Fragmentation**|sweep's fundamental weakness — freed memory is scattered, potentially preventing large allocations even with sufficient total free space|
|**Tri-color marking**|white/gray/black abstraction formalizing "not yet reached / reached but not fully scanned / fully scanned," making concurrent marking's correctness provable|
|**Write barrier (marking role)**|intercepts reference writes during concurrent marking to preserve the black-can't-point-to-white invariant, preventing live objects from being missed|
|**Mark-and-sweep vs. copying**|sweep leaves live objects in place (cost ∝ total region size); copying relocates live objects elsewhere (cost ∝ survivor count), trading memory overhead for both compaction and lower cost on high-garbage regions|

## Where this closes the loop entirely

Mark-and-sweep is the literal algorithmic foundation underneath every single collector from the last tutorial — Serial and Parallel run it essentially as described here, stop-the-world, no concurrency concerns; G1 runs it region-by-region with card-table-assisted roots; ZGC and Shenandoah run a **concurrent, tri-color-based** version specifically engineered around the write-barrier invariant just explained, which is precisely what lets them mark (and, via their colored-pointer/forwarding-pointer mechanisms, even relocate) without stopping your application threads for more than a few sub-millisecond safepoint pauses. Every diagram and mechanic across all three of these GC tutorials — stack frames, GC Roots, safepoints, generations, write barriers, and now the mark/sweep algorithm itself — is genuinely the complete, real internal architecture of how the JVM manages memory underneath every Java program you'll ever run, including every Spring Boot application you build going forward.


[[Java]]