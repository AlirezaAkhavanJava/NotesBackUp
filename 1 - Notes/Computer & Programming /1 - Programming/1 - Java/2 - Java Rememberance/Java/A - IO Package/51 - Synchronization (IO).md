
# Synchronization in I/O Operations — Java Edition

In Java, **I/O synchronization** means coordinating multiple threads (and sometimes multiple processes) that access the same I/O resource — a file, socket, channel, stream, buffer, or file position — so that:

- **Atomicity** is preserved: no thread interleaves in the middle of a critical I/O operation.
- **Ordering** is correct: writes/reads happen in the required sequence.
- **Visibility** is guaranteed: one thread's write is seen by another (Java Memory Model / happens-before).
- **Lifetime** is safe: buffers and streams aren't reused or closed while still in use.

Java gives you both **language-level** tools (`synchronized`, `volatile`) and **library-level** tools (`java.util.concurrent`, `java.nio`).

> **Key distinction:**  
> **Synchronous I/O** = the calling thread blocks until done (`InputStream.read()`).  
> **Asynchronous I/O** = the thread continues, completion is signaled later (`AsynchronousFileChannel`).  
> **Synchronization** = coordinating concurrent access so both are correct. They're related but different.

---

## 1. What problems do we have in Java?

### 1.1 Race conditions on shared streams
`InputStream`, `OutputStream`, `Reader`, `Writer` are **not thread-safe** (except a few like `PrintStream` which synchronizes internally, but even that has caveats).

```java
// Two threads writing to the same OutputStream
out.write("A".getBytes());
out.write("B".getBytes());
// Interleaving possible: "AB" or "BA" or corrupted bytes
```

### 1.2 Shared file position races
`RandomAccessFile`, `FileChannel`, and `FileInputStream`/`FileOutputStream` share a **file position** (a cursor). If two threads `read()`/`write()`, they fight over the cursor.

```java
// Thread A and B both call raf.read()
// Cursor moves unpredictably → both read wrong data
```

### 1.3 Buffer reuse before async I/O completes
With `AsynchronousFileChannel`, you pass a `ByteBuffer`. If you modify or reuse it before the completion handler fires, the channel reads/writes garbage.

```java
ByteBuffer buf = ByteBuffer.allocate(1024);
channel.read(buf, 0, buf, handler);
buf.clear(); // WRONG: channel may still be reading into buf
```

### 1.4 Lost updates / visibility problems
Without proper synchronization, a thread may see stale values due to CPU caching. The JMM (Java Memory Model) only guarantees visibility when there's a **happens-before** relationship (`synchronized`, `volatile`, `Atomic*`, `Lock`, `Executor` submission, etc.).

### 1.5 Deadlocks
Holding a lock while doing blocking I/O, then another thread holding another lock and waiting for the first.

```java
synchronized(lockA) {
    socketA.read(...);  // blocks
    synchronized(lockB) { ... }
}
// Another thread: synchronized(lockB) then waits for lockA → deadlock
```

### 1.6 Closing while in use
One thread calls `close()` while another is mid-`read()`. Result: `IOException: Stream closed`, or worse, corrupted state.

### 1.7 Interleaved output on sockets
Two threads writing to the same `Socket.getOutputStream()` can interleave bytes, corrupting a protocol frame.

### 1.8 Missed completions / lost wakeups
Manually implemented wait/notify with `wait()`/`notifyAll()` can lose signals if not guarded by a condition predicate.

### 1.9 Inter-process races
Two JVMs (or a JVM and another process) writing the same file without coordination.

---

## 2. Why do these problems happen?

- **Multiple threads** sharing the same I/O object.
- **Java Memory Model**: no automatic visibility; you must create happens-before edges.
- **Streams are stateful**: buffers, cursors, and internal state are not thread-safe.
- **Blocking I/O**: a thread can block indefinitely, holding locks.
- **Async I/O**: completion happens on another thread; buffer lifetime is your responsibility.
- **OS-level realities**: page cache, file position, socket send/receive buffers.
- **Multi-process access**: Java locks don't cross JVM boundaries unless you use file locks.

---

## 3. Solutions: the Java toolbox

| Problem | Reason | Solution | Java API |
|---|---|---|---|
| Race on shared stream | Not thread-safe | Mutual exclusion | `synchronized`, `ReentrantLock` |
| Shared file position | Shared cursor | Per-thread position / positional read | `FileChannel.read(buf, pos)` |
| Buffer reuse in async I/O | Lifetime | Wait for completion before reuse | `Future.get()`, `CompletionHandler` |
| Visibility | JMM | happens-before | `volatile`, `Atomic*`, locks, `Executor` |
| Deadlock | Circular wait | Lock ordering, tryLock | `ReentrantLock.tryLock(timeout)` |
| Close during use | Lifetime | Refcount, coordination | `Phaser`, `CountDownLatch`, `ReadWriteLock` |
| Interleaved socket writes | No framing | Frame + lock | `synchronized`, `ReentrantLock`, single-writer thread |
| Inter-process | Separate JVMs | File locks | `FileChannel.lock()` / `FileLock` |
| Missed wakeups | Manual wait/notify | Use `Condition` with predicate | `ReentrantLock.newCondition()` |

### Core primitives

- **`synchronized`** — intrinsic lock, easiest, auto-released.
- **`volatile`** — visibility + ordering, no atomicity for compound ops.
- **`AtomicInteger`, `AtomicLong`, `AtomicReference`** — lock-free updates.
- **`ReentrantLock`** — explicit lock, `tryLock`, fairness, `Condition`.
- **`ReadWriteLock` / `StampedLock`** — many readers, one writer.
- **`Semaphore`** — limit concurrent access (e.g., max N connections).
- **`CountDownLatch` / `CyclicBarrier` / `Phaser`** — coordinate phases.
- **`BlockingQueue`** — producer/consumer between threads.
- **`ExecutorService` / `CompletableFuture`** — async orchestration with happens-before guarantees.
- **`FileChannel.lock()`** — OS-level file lock across processes.
- **`AsynchronousFileChannel` / `AsynchronousSocketChannel`** — true async I/O.
- **`java.nio.channels.Selector`** — single-threaded event loop for many channels.

---

## 4. How to achieve it: a method

1. **Identify the shared I/O resource.**  
   A `FileChannel`, a `Socket`, a `ByteBuffer`, a file path, a `RandomAccessFile`.

2. **Define the invariant.**  
   "Only one thread writes to this socket at a time."  
   "This buffer is not touched until the async read completes."  
   "File position is never shared; each thread uses positional reads."

3. **Find the critical sections.**  
   Where can two threads conflict? Where must ordering hold?

4. **Choose the right tool:**
   - Same JVM, blocking I/O → `synchronized` or `ReentrantLock`.
   - Need timeouts / fairness → `ReentrantLock`.
   - Many readers, few writers → `ReadWriteLock`.
   - Cross-process → `FileChannel.lock()`.
   - Async → `Future` / `CompletionHandler` / `CompletableFuture`.
   - Avoid shared state entirely → per-thread channels or positional I/O.

5. **Keep critical sections short.**  
   Never hold a lock while doing blocking I/O unless unavoidable. Prefer:
   - `FileChannel.read(ByteBuffer, long position)` — no shared cursor.
   - Per-thread `Socket` or connection pool.

6. **Define lock ordering.**  
   Always acquire locks in a global order.

7. **Create happens-before edges.**  
   Use `volatile`, `Atomic*`, `synchronized`, `Lock`, or `Executor` submission. Don't rely on "it usually works."

8. **Test.**  
   Stress tests, `ThreadSanitizer`-style tools (e.g., `jcstress` for JMM), `jstack` for deadlock detection.

---

## 5. How can I do it? (Concrete Java patterns)

### 5.1 Synchronizing access to a shared stream

```java
public class SafeFileWriter {
    private final OutputStream out;
    private final Object lock = new Object();

    public SafeFileWriter(OutputStream out) { this.out = out; }

    public void write(byte[] data) throws IOException {
        synchronized (lock) {
            out.write(data);
            out.flush();
        }
    }
}
```

Better: give each thread its own `OutputStream`, or use a single-writer thread with a `BlockingQueue`.

### 5.2 Single-writer thread with a queue (recommended for sockets)

```java
BlockingQueue<byte[]> queue = new LinkedBlockingQueue<>();
OutputStream out = socket.getOutputStream();

Thread writer = new Thread(() -> {
    try {
        while (true) {
            byte[] msg = queue.take();
            if (msg.length == 0) break; // poison pill
            out.write(msg);
            out.flush();
        }
    } catch (Exception e) { e.printStackTrace(); }
});
writer.start();

// Any thread:
queue.put(frame);  // thread-safe, no lock held during I/O
```

This eliminates the race entirely: **one writer, many producers**.

### 5.3 Positional reads — avoid shared file position

```java
try (FileChannel ch = FileChannel.open(path, READ)) {
    ByteBuffer buf = ByteBuffer.allocate(1024);
    long pos = 0;
    // read(buf, pos) does NOT move the channel's position
    ch.read(buf, pos);
}
```

Multiple threads can read the same `FileChannel` concurrently with positional reads.

### 5.4 Explicit lock with timeout (avoid deadlock)

```java
ReentrantLock lock = new ReentrantLock();

if (lock.tryLock(1, TimeUnit.SECONDS)) {
    try {
        // critical I/O section
    } finally {
        lock.unlock();
    }
} else {
    // handle timeout gracefully
}
```

### 5.5 `ReadWriteLock` for shared file metadata

```java
ReadWriteLock rw = new ReentrantReadWriteLock();

// Readers
rw.readLock().lock();
try { readMetadata(); } finally { rw.readLock().unlock(); }

// Writer
rw.writeLock().lock();
try { updateMetadata(); } finally { rw.writeLock().unlock(); }
```

### 5.6 Async I/O with proper buffer lifetime

```java
AsynchronousFileChannel ch = AsynchronousFileChannel.open(path, READ);

ByteBuffer buf = ByteBuffer.allocate(1024);
ch.read(buf, 0, buf, new CompletionHandler<Integer, ByteBuffer>() {
    @Override
    public void completed(Integer n, ByteBuffer b) {
        b.flip();
        // safe to use b here; do NOT touch it before this point
    }
    @Override
    public void failed(Throwable e, ByteBuffer b) { e.printStackTrace(); }
});
// Do not modify buf until completed() fires
```

Or with `Future`:

```java
Future<Integer> f = ch.read(buf, 0);
int n = f.get();   // blocks until done; happens-before edge established
buf.flip();
```

### 5.7 Cross-process file lock

```java
try (FileChannel ch = FileChannel.open(path, WRITE)) {
    FileLock lock = ch.lock(); // exclusive, blocks until acquired
    try {
        // write safely; other JVMs/processes respect the lock
    } finally {
        lock.release();
    }
}
```

Note: `FileLock` is **advisory** — it only works if other processes also use locks.

### 5.8 Inter-thread coordination with `CountDownLatch`

```java
CountDownLatch ioDone = new CountDownLatch(1);

executor.submit(() -> {
    try {
        performIo();
    } finally {
        ioDone.countDown();   // happens-before for awaiting thread
    }
});

ioDone.await();  // safe: everything before countDown() is visible
```

### 5.9 `CompletableFuture` for async pipelines

```java
CompletableFuture
    .supplyAsync(() -> readFile(path))
    .thenApply(this::parse)
    .thenAccept(this::writeResult)
    .exceptionally(ex -> { log(ex); return null; });
```

The `CompletableFuture` framework creates happens-before edges between stages.

### 5.10 Virtual threads (Java 21+)

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    executor.submit(() -> readFromSocket(socket1));
    executor.submit(() -> readFromSocket(socket2));
    // Thousands of blocking I/O tasks cheaply
}
```

Virtual threads make blocking I/O scalable, but **you still need synchronization** for shared resources.

### 5.11 Avoid the problem entirely

- **Per-thread resources**: each thread opens its own `FileChannel`, `Socket`, or `Connection`.
- **Immutable data**: pass copies instead of sharing buffers.
- **Connection pools**: `HikariCP`, `Apache Commons Pool`.
- **Channels with positional I/O**: no shared cursor.
- **Single-writer pattern**: queue + one consumer thread.

---

## 6. Practical checklist

- [ ] Which I/O object is shared? Stream? Channel? Buffer? Socket?
- [ ] Is it thread-safe? (Most `java.io` streams are **not**.)
- [ ] Can I avoid sharing it? (Per-thread channel, positional read, pool.)
- [ ] If shared, what is the invariant?
- [ ] Is the critical section short? Am I holding a lock during blocking I/O?
- [ ] Are there happens-before edges? (`volatile`, `Atomic*`, lock, `Executor`, `Future.get()`.)
- [ ] Is buffer lifetime respected for async I/O?
- [ ] Do I need cross-process locking? (`FileLock`)
- [ ] Is lock ordering consistent?
- [ ] Did I test with `jcstress`, stress tests, and `jstack`?

---

## 7. Mental model

Think of Java I/O synchronization as **three layers**:

1. **Language layer** — `synchronized`, `volatile`, JMM happens-before.
2. **Library layer** — `java.util.concurrent`, `Lock`, `Atomic*`, `CompletableFuture`, `BlockingQueue`.
3. **I/O layer** — `java.io` (mostly not thread-safe), `java.nio` (channels, positional I/O, async), `FileLock` (cross-process).

**Golden rule:**  
> If correctness depends on timing, you need synchronization.  
> If you can eliminate sharing (per-thread resources, positional I/O, single-writer queues), you eliminate the need for synchronization — which is even better.

Synchronization in Java I/O is not about adding `synchronized` everywhere; it's about **designing the I/O ownership model** so that concurrent access is either coordinated or impossible.


[[Java]]