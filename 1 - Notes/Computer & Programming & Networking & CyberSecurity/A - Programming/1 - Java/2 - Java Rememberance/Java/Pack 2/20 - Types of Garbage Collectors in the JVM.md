

## The core intuition before the list

Every collector you're about to see is solving the **exact same problem** from the last two tutorials — find unreachable objects starting from GC Roots, reclaim their memory — but each makes a **different trade-off** between three competing goals that can't all be maximized simultaneously:

```
THROUGHPUT      → how much total application work gets done, GC overhead minimized
LATENCY (pause time) → how long/often application threads get stopped for GC
FOOTPRINT (memory)     → how much extra memory the GC itself needs to do its job
```

**No collector wins at all three.** A collector optimized for minimum pause time (great for a responsive web server) typically sacrifices some throughput and uses more memory bookkeeping than one optimized purely for raw batch-processing speed. This tutorial goes through each collector Java has shipped, in roughly chronological/conceptual order, showing exactly which corner of that triangle each one optimizes for — and connects each one back to the mark-sweep-compact, generational, safepoint, and write-barrier mechanics from the last two tutorials.

---

## 1. Serial GC — the simplest possible collector

### How it works

**Uses exactly one thread to do all GC work** — marking, sweeping, and compacting — while **every application thread is fully stopped** for the entire duration.

```
Application threads: [running][running][running]
                                    │
                          Minor/Major GC needed
                                    ▼
Application threads: [PAUSED────────────────][running]
GC thread:                  [mark][sweep][compact]
```

Applies generational collection (young/old split, from the previous tutorial) using classic mark-sweep-compact for the old generation and a copying collector for the young generation.

### The trade-off

**Extremely simple, extremely low memory overhead** (no coordination structures needed for multiple GC threads) — but pauses scale directly with heap size, since one thread has to do everything alone. For a heap of any real size, pauses can become seconds long, completely unacceptable for anything interactive.

### When it's actually used

```bash
java -XX:+UseSerialGC MyApp
```

**Small heaps, single-CPU environments, or genuinely short-lived programs** where a GC pause of even a second or two is irrelevant — think small command-line utilities, small containerized microservices with tight memory limits, or embedded/constrained environments. The JVM actually **auto-selects Serial GC by default** when it detects it's running on a single CPU core with a small heap, since in that scenario, paying for multiple GC threads' coordination overhead would be pure waste.

---

## 2. Parallel GC (Throughput Collector)

### How it works

**Same fundamental algorithm as Serial GC (mark-sweep-compact, generational)** — but uses **multiple threads simultaneously** to do the marking/sweeping/compacting work during a pause, rather than just one.

```
Application threads: [PAUSED──────────][running]
GC threads:               [mark][mark][mark][mark]  ← MULTIPLE threads working in parallel during the pause
                              (all still stop-the-world — app threads are still fully paused)
```

**Important distinction worth being precise about:** "Parallel" here refers to the **GC's own internal work** being done by multiple threads simultaneously — it does **not** mean application threads keep running during collection. This is still a fully stop-the-world collector; it just finishes each pause faster by throwing more CPU cores at the actual GC work itself.

### The trade-off

**Maximizes throughput** — since the pause itself is shorter (multiple threads sharing the marking/sweeping work), and the collector spends comparatively little of its total CPU budget on coordination overhead, more of your total available CPU time across the program's whole lifetime goes toward actual application work rather than GC bookkeeping. But pauses, while shorter than Serial's, can still be substantial on large heaps — this collector doesn't prioritize minimizing any _individual_ pause, it prioritizes minimizing _total time spent paused_ across the whole run.

### When it's actually used

```bash
java -XX:+UseParallelGC MyApp
```

**Batch processing, data pipelines, scientific computing — anything where total job completion time matters far more than any individual pause being noticeable.** If nobody's sitting there waiting on a responsive UI/API during the run, and you just want the whole computation to finish as fast as possible, Parallel GC's willingness to trade occasional longer pauses for higher overall throughput is exactly the right trade-off.

---

## 3. CMS (Concurrent Mark Sweep) — historically important, now removed

### How it worked

The **first** mainstream JVM collector to attempt doing the bulk of its marking work **concurrently** — i.e., while application threads kept running — pausing only briefly at the start and end of a cycle (rather than for the entire mark phase).

```
Application threads: [running][BRIEF PAUSE][running (GC marking CONCURRENTLY)][BRIEF PAUSE][running]
```

**Critical limitation:** CMS did **not** compact the old generation — it only did mark-and-sweep (from the previous tutorial's algorithm section), leaving fragmentation behind over time. Eventually, badly fragmented old-gen memory could force a fallback to a full, uncompacted, stop-the-world collection anyway — genuinely undermining its own low-pause goal under sustained memory pressure.

### Status today

**CMS was deprecated in Java 9 and fully removed in Java 14.** It's included here specifically because you'll still encounter references to it in older tutorials, Stack Overflow answers, and legacy production systems — but it is **not available** in any JDK version you'd actually use today (including your Java 25 setup). G1 (next) was built specifically to be CMS's full replacement, solving the fragmentation problem CMS never fully addressed.

---

## 4. G1 (Garbage-First) — the long-standing modern default

Already referenced in your last two tutorials — here's the complete picture.

### How it works

**Divides the heap into many small, equal-sized regions** (typically 1-32MB each, chosen automatically based on heap size) rather than using a strictly contiguous young/old split. Each region is dynamically labeled Eden, Survivor, or Old as the collector sees fit — the generational concept still applies, it's just implemented with much finer granularity.

```
Heap divided into regions:
[Eden][Eden][Old][Survivor][Eden][Old][Eden][Old][Survivor][Eden]...
```

**The "Garbage-First" name comes from its core strategy:** during a collection, G1 doesn't necessarily collect the _entire_ young generation or _entire_ old generation — it tracks how much garbage each region contains, and **prioritizes collecting the regions with the most reclaimable garbage first**, since that gives the best "reclaimed memory per unit of pause time" ratio. This lets G1 offer a genuinely different guarantee than Parallel/Serial: you can configure a **target maximum pause time** (`-XX:MaxGCPauseMillis=200`), and G1 will try to select just enough regions to collect within that budget, rather than always doing an entire generation at once.

Uses the **write barriers and card table** mechanism from the previous tutorial extensively, since regions constantly reference each other across the old/young conceptual boundary now that it's no longer a simple contiguous split.

### The trade-off

**Balances throughput and latency reasonably well for most general-purpose applications** — genuinely the right "don't have to think hard about it" default for the vast majority of real-world server applications, which is exactly why it became, and largely remains, the JVM's default collector.

### When it's actually used

```bash
java -XX:+UseG1GC MyApp   # this has been the DEFAULT since Java 9 — you likely don't need to specify it explicitly
```

**The sensible default for most Spring Boot applications** — reasonably low pauses, reasonably high throughput, works well across a wide range of heap sizes without much manual tuning. This directly connects to the Java 26 tutorial's JEP 522 (G1 throughput improvement via reduced synchronization) and the mention that G1 is set to become the default across _all_ environments (superseding even Serial GC's small-heap auto-selection).

---

## 5. ZGC (Z Garbage Collector) — the modern low-latency specialist

Already referenced across your Java 21/25/26 tutorials — here's the full mechanical picture.

### How it works

**Does almost all of its work — marking, relocating (its term for compacting), and even reference updating — concurrently**, while application threads keep running, using an extremely short, largely **constant-time** stop-the-world pause regardless of heap size (typically sub-millisecond).

**The key mechanism that makes this possible: colored pointers and load barriers.** ZGC embeds extra metadata bits directly into unused portions of each object reference itself (the pointer literally carries information about the object's GC state — whether it's been marked, relocated, etc.). Combined with a **load barrier** (extra code inserted wherever your program reads a reference from a field), the JVM can detect, at the moment of access, if a reference is pointing to an object that's been relocated mid-collection — and transparently redirect to the object's new location, **without ever needing to pause the application thread to fix it up**.

```
Application thread reads a reference ──▶ Load barrier checks: "has this object moved?"
                                                        │
                                          if yes: silently follow to new location, fix the reference
                                          if no: proceed normally
                        (all of this happens WHILE other application threads keep running)
```

This is a genuinely different, more sophisticated mechanism than G1's card-table approach — it's specifically engineered to let compaction (which normally requires updating every reference to a moved object, as covered in the mark-compact section of the previous tutorial) happen concurrently, rather than needing a pause to safely rewrite pointers.

### Generational ZGC (Java 21+)

As covered in your Java 21 tutorial: applies the young/old generational split (from the previous tutorial's "most objects die young" hypothesis) on top of this already-concurrent architecture — collecting the young generation far more frequently, at even lower cost, while still keeping the old generation's collection concurrent too.

### The trade-off

**Pause times are extremely low and largely independent of heap size** — genuinely capable of handling multi-terabyte heaps with sub-millisecond pauses. The cost: **higher memory overhead** (colored pointers and the bookkeeping needed for concurrent relocation require extra space) and **somewhat lower raw throughput** than Parallel/G1, since load barriers add a small but real cost to every single reference read, everywhere in your running application, all the time — not just during GC pauses.

### When it's actually used

```bash
java -XX:+UseZGC MyApp
```

**Latency-critical applications** — high-frequency trading systems, real-time services, applications with strict SLA requirements on response time consistency, or genuinely huge heaps where even G1's pause times would be unacceptable.

---

## 6. Shenandoah — a comparable low-latency alternative to ZGC

### How it works

**Conceptually very similar goal to ZGC** (concurrent marking, concurrent compaction/relocation, minimal pause times) but developed independently (originally by Red Hat) using a somewhat different technical mechanism — primarily **forwarding pointers** stored in each object's header (connecting directly to the Mark Word discussed in the object header section of the earlier tutorial) rather than ZGC's colored-pointer approach, combined with its own barrier mechanism to keep application threads correctly redirected during concurrent relocation.

### The trade-off

**Very similar overall profile to ZGC** — extremely low, largely heap-size-independent pause times, at a similar cost in extra memory overhead and per-access barrier cost. The two collectors are genuine alternatives solving the same problem with different internal engineering — the practical choice between them often comes down to specific workload benchmarking rather than one being categorically better.

### When it's actually used

```bash
java -XX:+UseShenandoahGC MyApp
```

Same use cases as ZGC — latency-critical systems. Also gained the same **generational** treatment (Generational Shenandoah, finalized in Java 26, from your Java 26 tutorial) for the same reasons.

---

## 7. Epsilon GC — the "do-nothing" collector

### How it works

**Allocates memory, and never collects anything at all.** Genuinely, literally: no marking, no sweeping, no tracing, nothing. Once the heap fills up, the application simply crashes with `OutOfMemoryError` (from your exceptions tutorial).

```bash
java -XX:+UnlockExperimentalVMOptions -XX:+UseEpsilonGC MyApp
```

### Why this exists at all — a genuinely reasonable use case

Two real, legitimate purposes:

1. **Performance testing/benchmarking** — if you want to measure your _application's_ raw performance without any GC-related noise interfering with your measurements, running with zero GC overhead gives you a clean baseline to compare against.
2. **Extremely short-lived programs with a known, bounded memory footprint** — if you know precisely that a program will finish and exit well before it could possibly exhaust available heap memory (certain serverless/function-as-a-service workloads, for instance), paying any GC overhead at all is pure waste — you can simply let it allocate freely and exit before it would ever need collection.

This is a genuinely instructive collector to know about conceptually, even though you'd essentially never use it for anything resembling a normal Spring Boot application — it makes the "GC exists to solve a real problem, and here's what happens if you simply opt out of solving it" point very concretely.

---

## Comparison table — the throughput/latency/footprint triangle, made explicit

|Collector|Pause time|Throughput|Memory overhead|Concurrent w/ app threads?|Status/default|
|---|---|---|---|---|---|
|**Serial**|High (scales with heap)|Low|Very low|No|Auto-selected for small/single-core|
|**Parallel**|Medium-high|**Highest**|Low|No|Good for batch jobs|
|**CMS**|Was low-ish|Medium|Medium|Partially (marking only)|**Removed** (Java 14)|
|**G1**|Low-medium, configurable target|Good|Medium|Partially|**Default since Java 9**|
|**ZGC**|**Very low**, ~heap-size-independent|Medium|Higher|Yes, extensively|Opt-in; latency-critical use|
|**Shenandoah**|**Very low**, similar to ZGC|Medium|Higher|Yes, extensively|Opt-in; latency-critical use|
|**Epsilon**|None (never collects)|N/A — no GC cost at all|None|N/A|Testing/benchmarking only|

---

## How to actually choose — practical guidance for you

Given that you're heading toward Spring Boot development specifically:

```
Default (do nothing, let the JVM decide) → G1, in almost all realistic cases → correct choice for learning and most real apps

If you later deploy something with strict low-latency requirements (a real-time API,
something genuinely sensitive to occasional pause spikes) → consider ZGC

If you're running a batch job / data processing pipeline with no interactive users waiting → Parallel GC

Serial/Epsilon → essentially never relevant to Spring Boot work specifically
```

**In practice, for the vast majority of your Spring Boot learning and early projects, you'll never explicitly choose a GC at all** — G1's default behavior is genuinely good enough that manual GC tuning is something you'd only reach for once you have a real, measured performance problem in a production system, backed by actual GC logs showing pause times are genuinely hurting you — never as a speculative "let me optimize this upfront" step.

## Where this closes the loop

Every collector in this tutorial is a different answer to the exact same mechanical questions the last two tutorials established: how to find GC Roots in stack frames, how to trace reachability through the heap graph, whether/how to compact and update references afterward, and how (or whether) to coordinate with running application threads via safepoints and barriers. Serial and Parallel are the "simple, stop-the-world" answers; G1 refines that with region-based prioritization; ZGC and Shenandoah push concurrency to its logical extreme using colored pointers/forwarding pointers and load barriers specifically to avoid needing a pause even for compaction; and Epsilon exists purely to prove, by omission, that all of this machinery exists to solve one real, unavoidable problem — memory you allocate but never explicitly free.


[[Java]]