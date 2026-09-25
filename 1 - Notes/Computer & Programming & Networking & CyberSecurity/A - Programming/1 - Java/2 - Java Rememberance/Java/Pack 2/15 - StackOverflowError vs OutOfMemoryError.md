

Both are `Error` subclasses (not `Exception`), both signal memory exhaustion, but they mean **very different things** and come from **different memory regions**.

---

## The Quick Distinction

| Error | Region | Cause |
|-------|--------|-------|
| `StackOverflowError` | **Stack** (per thread) | Too many frames / too deep a call chain |
| `OutOfMemoryError` | **Heap** (or Metaspace, or native) | Too many live objects / too much memory requested |

---

## Class Hierarchy

```
java.lang.Object
└── java.lang.Throwable
    ├── java.lang.Exception
    │   └── (checked and unchecked exceptions)
    └── java.lang.Error
        ├── java.lang.StackOverflowError
        └── java.lang.OutOfMemoryError
```

Both extend `Error`, not `Exception`. This is a signal: **these are not normal conditions you're expected to catch and recover from.** They indicate a fundamental problem with the program or its configuration.

---

## 1. StackOverflowError

### What it is

Thrown when a thread's **call stack** exceeds its size limit — i.e., too many frames are pushed without being popped.

### Cause

Almost always **unbounded recursion**:

```java
public class Demo {
    static void recurse() {
        recurse();   // no base case
    }
    public static void main(String[] args) {
        recurse();   // boom
    }
}
```

Every call pushes a new frame. The thread's stack has a fixed size (`-Xss`, default ~512 KB – 1 MB). Once full, the JVM throws `StackOverflowError`.

### The error message

Usually just:

```
Exception in thread "main" java.lang.StackOverflowError
```

Sometimes with a stack trace showing the recursive method repeated thousands of times.

### Common causes

| Cause | Example |
|-------|---------|
| Missing base case | Recursion with no termination |
| Wrong base case | Condition never becomes true |
| Infinite mutual recursion | `a()` calls `b()` calls `a()` |
| Very deep legitimate recursion | Tree traversal of a huge unbalanced tree |
| Deep framework chains | Deeply nested proxies / interceptors |

### How to fix

- **Add or fix the base case**
- **Convert recursion to iteration** (use an explicit stack / loop)
- **Increase stack size** with `-Xss4m` (per thread) — a band-aid, not a cure
- **Use tail recursion** — but note: the JVM does **not** do tail-call optimization, so this doesn't help in Java

### Key properties

| Property | Value |
|----------|-------|
| Region | Stack |
| Scope | **Per thread** — one thread overflowing doesn't affect others |
| Recoverable? | Technically catchable, but the thread is usually in a bad state |
| Configurable via | `-Xss` (e.g., `-Xss2m`) |
| Deterministic? | Yes — same depth, same result |

---

## 2. OutOfMemoryError

### What it is

Thrown when the JVM **cannot allocate memory** — usually on the heap, but also in Metaspace, or for native structures.

### It's actually several distinct errors

`OutOfMemoryError` is a single class, but the JVM throws it with **different messages** indicating the specific region:

| Message | Region | Cause |
|---------|--------|-------|
| `Java heap space` | Heap | Too many live objects, heap full |
| `GC overhead limit exceeded` | Heap | GC spending >98% time but reclaiming <2% |
| `Metaspace` | Metaspace | Too many loaded classes |
| `Compressed class space` | Metaspace | Too many compressed class pointers |
| `unable to create new native thread` | Native | OS can't create more threads |
| `Requested array size exceeds VM limit` | Heap | Array too large for the JVM |
| `Direct buffer memory` | Native | Direct `ByteBuffer` allocation failed |
| `Map failed` | Native | mmap failure |

The message tells you **which region** is exhausted — this is critical for debugging.

---

### 2a. Heap OOM — `Java heap space`

The most common form:

```java
public class Demo {
    public static void main(String[] args) {
        List<byte[]> list = new ArrayList<>();
        while (true) {
            list.add(new byte[1_000_000]);   // 1 MB each
        }
    }
}
```

The list keeps growing, all byte arrays remain reachable, GC can't reclaim them → heap fills → OOM.

```
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
```

### Common causes

| Cause | Example |
|-------|---------|
| Memory leak | Growing collection never cleared |
| Caching without eviction | Unbounded `HashMap` cache |
| Loading too much data | Reading a huge file into memory |
| Heap too small | `-Xmx` set too low for the workload |
| Large object churn | Allocating faster than GC can reclaim |

### How to fix

- **Fix the leak** — remove stale references, use `WeakReference`, bound caches
- **Increase heap** with `-Xmx4g`
- **Tune GC** — different collector, different generations
- **Analyze with a heap dump** — `-XX:+HeapDumpOnOutOfMemoryError`, then Eclipse MAT / VisualVM

---

### 2b. GC Overhead Limit — `GC overhead limit exceeded`

A special case: GC is running constantly but reclaiming almost nothing.

```java
// Heap is ~98% full, GC runs, reclaims ~1%, repeats forever
```

The JVM detects this pathological state and throws OOM **before** the heap is completely full, as a fail-fast measure.

Disable with `-XX:-UseGCOverheadLimit` (not recommended — you'll just get `Java heap space` later).

---

### 2c. Metaspace OOM — `Metaspace`

Metaspace (replaced PermGen in Java 8) holds **class metadata** — the runtime representation of every loaded class.

```java
// Generate classes at runtime (e.g., via reflection, proxies, bytecode libs)
while (true) {
    // create and load new classes dynamically
}
```

Too many loaded classes → Metaspace fills → OOM.

```
Exception in thread "main" java.lang.OutOfMemoryError: Metaspace
```

### Common causes

| Cause | Example |
|-------|---------|
| Classloader leak | Redeploying apps without unloading old classloaders |
| Dynamic proxy explosion | Generating a new proxy class per request |
| Bytecode generation | CGLIB, ASM, Javassist creating classes unbounded |
| Script engines | Groovy, Nashorn, JShell compiling scripts to classes |

### How to fix

- **Fix classloader leaks** — a common issue in app servers
- **Cache generated classes** instead of regenerating
- **Increase Metaspace** with `-XX:MaxMetaspaceSize=512m`
- **Analyze with** `jcmd <pid> GC.class_stats` or heap dump

---

### 2d. Unable to Create Native Thread

```java
while (true) {
    new Thread(() -> { /* ... */ }).start();
}
```

Each thread needs:

- A JVM stack (~512 KB – 1 MB by default)
- Native OS thread structures
- Kernel resources

Eventually the OS refuses to create more → OOM.

```
Exception in thread "main" java.lang.OutOfMemoryError: unable to create new native thread
```

### Common causes

| Cause | Example |
|-------|---------|
| Thread leak | Creating threads without limiting/joining |
| Thread pool misconfiguration | Unbounded `Executors.newCachedThreadPool()` |
| OS thread limit | `ulimit -u` reached |
| Memory pressure | Not enough RAM for stack allocation |

### How to fix

- **Use bounded thread pools** — `newFixedThreadPool(n)` instead of cached
- **Check for thread leaks** — `jstack <pid>` to see thread count
- **Increase OS limits** — `ulimit -u`
- **Reduce stack size** if threads are numerous — `-Xss256k`

---

## Side-by-Side Comparison

| Aspect | StackOverflowError | OutOfMemoryError |
|--------|--------------------|--------------------|
| Class | `java.lang.StackOverflowError` | `java.lang.OutOfMemoryError` |
| Region | Stack (per thread) | Heap, Metaspace, or Native |
| Cause | Too many frames | Too much memory allocated |
| Trigger | Deep recursion | Memory leak, huge allocation, config |
| Scope | **Per thread** | **Whole JVM** |
| Affects other threads? | No | Yes — all threads share the heap |
| Configurable via | `-Xss` | `-Xmx`, `-XX:MaxMetaspaceSize`, etc. |
| Typical message | (none, or stack trace) | `Java heap space`, `Metaspace`, etc. |
| Usually recoverable? | Rarely | Rarely |
| Common fix | Fix recursion | Fix leak / increase memory |

---

## Can You Catch Them?

Technically **yes** — both are `Throwable`s:

```java
try {
    recurse();
} catch (StackOverflowError e) {
    System.out.println("Recursion too deep");
}
```

But **you usually shouldn't**. Reasons:

- The JVM may be in an **inconsistent state** after the error
- Other threads may have been affected (for OOM)
- Catching OOM often just delays the inevitable
- Logging frameworks may themselves allocate memory and fail

There are edge cases where catching is useful:

- **Isolating a failing task** in a worker thread
- **Graceful shutdown** — logging, cleanup, saving state
- **Supervisor patterns** — a watchdog thread survives while workers die

But **the main thread should not continue** as if nothing happened.

---

## How They Interact

OOM and SOE are independent — they come from different regions:

```
Thread 1's Stack        Thread 2's Stack        Heap (shared)
┌──────────────┐        ┌──────────────┐        ┌────────────────┐
│ frame        │        │ frame        │        │ objects        │
│ frame        │        │ frame        │        │ objects        │
│ ...          │        │ ...          │        │ ...            │
│ TOO DEEP →   │        │              │        │ TOO MANY →     │
│ StackOverflow│        │              │        │ OutOfMemory    │
└──────────────┘        └──────────────┘        └────────────────┘
   per thread              per thread              shared by all
```

You can have a healthy heap and still get `StackOverflowError` (deep recursion with small objects).

You can have a healthy stack and still get `OutOfMemoryError` (shallow calls but massive allocation).

---

## Debugging Tips

### For StackOverflowError

```bash
# See the recursive method in the stack trace
# Increase stack size temporarily
java -Xss4m MyApp
```

Look for the repeated frame in the stack trace — that's your culprit.

### For OutOfMemoryError

```bash
# Capture a heap dump automatically on OOM
java -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/dump.hprof MyApp

# Analyze with jmap, jhat, Eclipse MAT, VisualVM

# Monitor memory at runtime
jcmd <pid> GC.heap_info
jstat -gc <pid> 1000
```

For thread-related OOM:

```bash
jstack <pid>          # count threads
jcmd <pid> Thread.print
```

---

## Summary

```
StackOverflowError
├── Region: Stack (per thread)
├── Cause: Deep/infinite recursion
├── Fix:   Base case, iteration, -Xss
└── Scope: One thread

OutOfMemoryError
├── Region: Heap / Metaspace / Native
├── Cause: Leak, huge allocation, config
├── Fix:   Fix leak, -Xmx, tune GC
├── Scope: Whole JVM
└── Variants:
    ├── Java heap space
    ├── GC overhead limit exceeded
    ├── Metaspace
    ├── unable to create new native thread
    └── ...
```

**One-line takeaway:**

> `StackOverflowError` = **too many frames on one thread's stack** (usually recursion).  
> `OutOfMemoryError` = **not enough memory in a shared region** (heap, Metaspace, or native) — with a message telling you which.


[[Java]]