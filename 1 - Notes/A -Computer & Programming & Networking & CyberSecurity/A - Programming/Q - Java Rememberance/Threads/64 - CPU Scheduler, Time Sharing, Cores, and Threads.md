


This steps back from Java specifically into the underlying **operating system / hardware concepts** that make everything you've learned about threads, concurrency, and parallelism actually work under the hood.

---

## 1. Cores — the physical hardware

**A core** is an independent physical processing unit inside a CPU chip, capable of executing instructions on its own. Older CPUs had a single core; modern CPUs almost always have multiple cores on one chip.

```
┌────────────────────────────────┐
│           CPU (chip)           │
│  ┌────────┐  ┌────────┐        │
│  │ Core 1 │  │ Core 2 │    ... │
│  └────────┘  └────────┘        │
└────────────────────────────────┘
```

**Each core can genuinely execute one instruction stream at a time, independently of other cores.** This is the actual hardware basis for parallelism from the last tutorial — 4 cores means 4 things can _literally_ happen at the same instant, not just be scheduled to feel that way.

```java
int cores = Runtime.getRuntime().availableProcessors();
```

That line, used throughout the last two tutorials, is asking the OS/JVM exactly this: "how many physical execution units do I actually have to work with?"

---

## 2. Threads (the OS-level meaning — distinct from Java's `Thread` class)

This is worth being precise about, since the word "thread" has been used in two related but distinct senses throughout this conversation:

||Meaning|
|---|---|
|**OS thread**|the operating system's actual unit of scheduling — a sequence of instructions the OS schedules onto a core|
|**Java `Thread` object**|a Java-level object that (traditionally) maps 1-to-1 onto one OS thread|

An **OS thread** is the smallest unit of execution the operating system's scheduler manages. Every process has at least one OS thread (the main one); a multi-threaded process (like your JVM running multiple `Thread`s) has several. Each OS thread has its own tiny bit of private data (a call stack, a program counter — "where am I in the code right now") but shares the process's memory with its siblings, exactly as covered in the process-vs-thread tutorial.

**The connection to Java `Thread`:** historically, `new Thread().start()` asked the OS to create one real OS thread, giving a strict 1:1 mapping. This is precisely _why_ traditional threads were "expensive" (each one consumes real OS-level resources) and why virtual threads (Java 21+) were introduced — they break this 1:1 mapping, letting many Java-level virtual threads share a much smaller pool of real OS threads.

**Some CPUs also support "hyper-threading" / SMT (simultaneous multithreading)** — a single physical core can present itself to the OS as **two logical threads**, sharing the core's execution resources but allowing some instruction-level overlap. This is why `availableProcessors()` on a hyper-threaded CPU often reports double the actual physical core count — it's counting logical threads the OS can schedule onto, not strictly physical cores.

---

## 3. The core problem: more threads than cores (almost always true)

A typical laptop might have 8 cores. But a running system easily has hundreds or thousands of OS threads active at once (every running program contributes some). **You cannot give every thread its own dedicated core** — there simply aren't enough cores to go around.

This is the exact hardware-level version of the concurrency-vs-parallelism gap from the last tutorial: with more threads than cores, **not every thread can be running in parallel at the same instant** — most of them, at any given moment, must be **waiting their turn**.

---

## 4. The CPU scheduler — solving that problem

**The CPU scheduler** is a component of the operating system's kernel whose job is: given more runnable threads than available cores, **decide which thread gets to run on which core, and for how long, right now.**

```
Cores available:  [Core 1] [Core 2]     ← only 2 cores
Runnable threads: T1  T2  T3  T4  T5     ← 5 threads want to run

Scheduler's job: pick which 2 of these 5 threads get a core RIGHT NOW,
                  and how long each gets before being swapped out
```

**How it decides (conceptually — the actual algorithms vary by OS):**

- **Priority** — some threads (e.g., handling user input, or explicitly marked high-priority) get preference
- **Fairness** — avoid one thread hogging a core forever while others starve (this is literally the "starvation" problem from the concurrency tutorial — it's a scheduler-level concept, not just an application-level bug)
- **Time slicing** — give each thread a small slice of time, then switch to another (covered next)

Java lets you _hint_ at priority, though the OS ultimately decides:

```java
thread.setPriority(Thread.MAX_PRIORITY); // hint only — OS scheduler has final say
```

---

## 5. Time sharing (time slicing) — how one core serves many threads

**Time sharing** (also called **time slicing**) is the scheduling technique where the OS gives each runnable thread a small, fixed slice of CPU time (often just a few milliseconds — called a **quantum**), then forcibly pauses it and switches to the next thread in line, cycling through repeatedly.

```
Core 1 timeline (single core, 3 threads competing):

[ T1 ][ T2 ][ T3 ][ T1 ][ T2 ][ T3 ][ T1 ]...
  5ms   5ms   5ms   5ms   5ms   5ms   5ms
```

Each slice is so short, and switching so fast, that from a human's perspective, it **looks like** all three threads are running simultaneously — even though, on a single core, only one is _actually_ executing at any given instant. **This is exactly the mechanism that makes concurrency possible even on a single core**, which is the key distinction from the concurrency/parallelism tutorial made concrete: time sharing is _how_ a single core fakes simultaneity.

### Context switching — the cost of time sharing

Every time the scheduler swaps one thread out for another, it performs a **context switch**: saving the paused thread's exact state (register values, program counter, stack pointer — literally "where it was, so it can resume later") and loading the next thread's saved state.

```
Thread A running → [SAVE A's state] → [LOAD B's state] → Thread B running
                         ↑ this saving/loading itself takes real time — pure overhead
```

**Why this matters practically:** context switches aren't free — they cost real CPU cycles that produce no actual application progress. This is _precisely_ why having far more threads than cores hurts performance (excessive switching overhead, each thread getting tiny slices), and why the "thread pool sized roughly to core count" guidance from the last tutorial exists for CPU-bound work — minimizing unnecessary context switches while still using every core.

---

## 6. Preemptive vs. cooperative scheduling

Modern OS schedulers (including what the JVM runs on — Linux, Windows, macOS) are **preemptive**: the scheduler can forcibly pause a running thread at any time (when its time slice ends, or a higher-priority thread needs to run), whether or not that thread is "ready" to be paused. The thread doesn't get a say.

This contrasts with older **cooperative** scheduling, where a running task had to voluntarily yield control — a single misbehaving task could freeze the whole system by never yielding. Preemptive scheduling is what makes modern multitasking robust — one runaway thread can't monopolize a core forever.

---

## 7. Blocking — why time sharing isn't the only story

When a thread is **blocked** — waiting on I/O (a file read, a network response), waiting on `Thread.sleep()`, or waiting to acquire a lock (`synchronized`) — it's **not competing for CPU time at all**. The scheduler simply doesn't give it any core time until whatever it's waiting for becomes ready; that core is immediately free for other runnable threads.

```
Thread states, relative to the scheduler:

RUNNABLE  → actively competing for a core's time slice
RUNNING    → currently executing ON a core, right now
BLOCKED/WAITING → NOT competing at all — parked until its condition is met
```

This connects directly back to _why_ concurrency helps even without parallelism: a thread waiting on a slow database query isn't "wasting" a core by sitting there — the scheduler simply runs _other_ threads during that wait, and the waiting thread costs nothing until it's ready again. This is also the exact mechanism virtual threads exploit — when a virtual thread blocks on I/O, the JVM detaches it from its underlying OS thread entirely, freeing that OS thread for other virtual threads, rather than leaving an expensive OS thread sitting idle.

---

## 8. Putting it all together — the full stack, top to bottom

```
Your Java code:
    Thread t = new Thread(() -> doWork());
    t.start();
              │
              ▼
JVM: creates (traditionally) one real OS thread for it
              │
              ▼
Operating System: OS thread is now "runnable" — added to the scheduler's pool
              │
              ▼
CPU Scheduler: decides WHEN and on WHICH CORE this thread actually gets to run,
                using time-sharing (time slices) if there are more runnable
                threads than cores, performing context switches as needed
              │
              ▼
Core: physically executes the thread's instructions during its allotted time slice
```

---

## Summary table

|Concept|Definition|
|---|---|
|**Core**|a physical, independent execution unit on a CPU chip — literal hardware|
|**OS thread**|the OS's unit of scheduling — an independent instruction sequence, scheduled onto a core|
|**CPU scheduler**|the OS kernel component deciding which thread runs on which core, and for how long|
|**Time sharing / time slicing**|giving each thread a short slice of core time, then switching — creates the illusion of simultaneity on limited cores|
|**Context switch**|the (costly) act of saving one thread's state and loading another's during a switch|
|**Preemptive scheduling**|the OS can forcibly pause any thread, ensuring fairness and responsiveness|
|**Blocked/waiting thread**|not competing for scheduler time at all — parked until its condition is met, freeing the core for others|

## How this closes the loop on everything you've learned

- **Concurrency** is possible even on one core _because of_ time sharing — this tutorial is the literal mechanism behind that earlier definition.
- **Parallelism** requires multiple cores _because_ only genuinely separate physical cores can execute instructions at the same instant — no amount of clever scheduling on one core produces that.
- **Race conditions** exist because the scheduler can pause a thread **mid-operation** (context switch happening between, say, reading and writing a shared variable) — which is exactly why `count++` (read, add, write — three real steps) can be interrupted partway through by another thread.
- **Thread pools** exist partly to avoid excessive context-switching overhead — too many threads competing for too few cores means the scheduler spends more time switching than any thread spends doing real work.
- **Virtual threads** work by decoupling from this whole traditional OS-scheduling picture for the _blocked/waiting_ case — letting the JVM itself manage huge numbers of lightweight threads, handing off to real OS threads (and thus the real CPU scheduler) only when there's actual work to do.


[[Java]]