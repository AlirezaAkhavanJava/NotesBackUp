

## What NIO is, and why it exists alongside `java.io`

**NIO** stands for **New I/O** — the `java.nio` package, introduced in Java 1.4 (with major expansion in Java 7, called "NIO.2"). It's a second, different way of doing I/O in Java, built around **buffers and channels** instead of the **stream** model you've been learning (`InputStream`/`OutputStream`/`Reader`/`Writer`).

### The problem NIO solves

Classic `java.io` streams are **simple but limited** in ways that matter for high-performance and highly-concurrent systems:

1. **Blocking by nature.** When you call `inputStream.read()`, that thread sits and waits until data arrives. If you're building a server handling 10,000 simultaneous connections the old way, you traditionally needed 10,000 threads (one per connection) — expensive in memory and context-switching overhead. _(Note: virtual threads, Java 21+, have since reduced this specific pain point for `java.io` too — mentioned later.)_
2. **One byte/char at a time, conceptually.** Even with buffering, the stream API's mental model is "give me the next piece" — it doesn't expose the underlying memory buffer to you directly for manipulation.
3. **No non-blocking option.** You can't ask a stream "is there data ready, without waiting?" — you either block until data arrives, or you don't read at all.
4. **File-system operations were weak.** Old `java.io.File` (which we covered) has clunky, inconsistent error handling (many methods just return `false` on failure instead of throwing a descriptive exception) and lacks things like symbolic link support, file watching, or fine-grained attribute access.

**NIO addresses all of this** — non-blocking I/O, direct buffer manipulation, and a genuinely better file-system API (`java.nio.file`).

---

## The two "sides" of NIO — know this split first

```
java.nio
│
├── java.nio.file          ← modern FILE SYSTEM API (Path, Files) — you'll use this CONSTANTLY
│
└── java.nio (buffers/channels/selectors) ← low-level, high-performance I/O — you'll use this RARELY,
                                              mostly for specific performance/concurrency needs
```

This split matters practically: **`java.nio.file`** (Part 1 below) is something you should default to for ordinary file work, replacing old `java.io.File` patterns. **Buffers/Channels/Selectors** (Part 2 below) are specialized tools for specific performance scenarios — not something you reach for by default.

---

# Part 1: `java.nio.file` — Modern File System API

## `Path` — the modern replacement for `File`

```java
import java.nio.file.Path;

Path path = Path.of("data.txt");                      // relative path
Path absolute = Path.of("/home/alireza/data.txt");    // absolute path
Path combined = Path.of("home", "alireza", "data.txt"); // built from parts
```

**Problem it solves vs. `File`:** `Path` is a richer, more consistent representation of a filesystem location, with better support for resolving relative paths, normalizing (`..`/`.` segments), and cross-platform correctness (handles `/` vs `\` differences between OS automatically).

```java
Path p = Path.of("folder/../data.txt");
System.out.println(p.normalize());   // data.txt — resolves the ".." automatically

Path base = Path.of("/home/alireza");
Path resolved = base.resolve("documents/file.txt");
System.out.println(resolved);        // /home/alireza/documents/file.txt
```

**When to use `Path` instead of `File`:** always, in new code. `File` still exists for backward compatibility, but `Path` + `Files` (below) is the modern standard, and virtually every modern Java library/framework (including Spring) expects `Path` in newer APIs.

---

## `Files` — the utility class for actually doing things with a `Path`

We used several of these already in the earlier "IO in practice" tutorial — here they are organized and complete.

### Reading

```java
String text = Files.readString(path);                 // whole file as String (Java 11+)
byte[] bytes = Files.readAllBytes(path);               // whole file as bytes
List<String> lines = Files.readAllLines(path);          // whole file as list of lines

try (Stream<String> lines = Files.lines(path)) {         // LAZY line stream — for big files
    lines.forEach(System.out::println);
}

try (BufferedReader reader = Files.newBufferedReader(path)) { // classic stream-style reading
    // ...
}
```

### Writing

```java
Files.writeString(path, "Hello, Alireza!");                                 // Java 11+
Files.write(path, List.of("line1", "line2"));                                 // list of lines
Files.writeString(path, "\nappended", StandardOpenOption.APPEND);              // append mode

try (BufferedWriter writer = Files.newBufferedWriter(path)) {                 // classic stream-style
    writer.write("text");
}
```

### File/directory management

```java
Files.exists(path);
Files.notExists(path);
Files.isDirectory(path);
Files.isRegularFile(path);
Files.size(path);                              // size in bytes

Files.createFile(path);                        // creates an empty file
Files.createDirectory(path);                    // creates ONE directory (fails if parents missing)
Files.createDirectories(path);                   // creates ALL missing parent directories too

Files.copy(source, dest, StandardCopyOption.REPLACE_EXISTING);
Files.move(source, dest, StandardCopyOption.REPLACE_EXISTING);
Files.delete(path);                              // throws if missing
Files.deleteIfExists(path);                       // safe no-op if missing
```

### Listing/walking directories

```java
try (Stream<Path> entries = Files.list(dirPath)) {       // ONE level deep
    entries.forEach(System.out::println);
}

try (Stream<Path> entries = Files.walk(dirPath)) {         // RECURSIVE, all levels
    entries.filter(Files::isRegularFile)
           .filter(p -> p.toString().endsWith(".log"))
           .forEach(System.out::println);
}

// Java 8+, find with a matching condition, recursive
try (Stream<Path> found = Files.find(dirPath, Integer.MAX_VALUE,
        (p, attrs) -> attrs.isRegularFile() && p.toString().endsWith(".txt"))) {
    found.forEach(System.out::println);
}
```

### File attributes/metadata (richer than old `File`)

```java
BasicFileAttributes attrs = Files.readAttributes(path, BasicFileAttributes.class);
System.out.println("Created: " + attrs.creationTime());
System.out.println("Last modified: " + attrs.lastModifiedTime());
System.out.println("Size: " + attrs.size());
System.out.println("Is symbolic link: " + attrs.isSymbolicLink());
```

**Why this matters vs. old `File`:** `File.lastModified()` returns a raw `long` (milliseconds), poorly typed and easy to misuse. `Files.readAttributes` gives you proper, richer typed metadata in one call, including things `File` can't easily expose at all (creation time, symbolic link detection).

---

## When to use `java.nio.file` (`Path`/`Files`) — practically, always

|Task|Use|
|---|---|
|Any new code touching the filesystem|`Path` + `Files`, not `java.io.File`|
|Reading a config file|`Files.readString()`|
|Processing a big log file|`Files.lines()`|
|Copying/moving/deleting files|`Files.copy/move/delete`|
|Listing or searching a directory tree|`Files.list/walk/find`|
|Getting file metadata|`Files.readAttributes`|

**Bottom line:** for regular file-handling code (which is 95% of what you'll ever need to do), `java.nio.file` has fully replaced old `java.io.File`-based patterns as the recommended approach. You'll still use `java.io`'s `InputStream`/`OutputStream`/`Reader`/`Writer` classes themselves for actual streaming reads/writes (as `Files.newBufferedReader()` returns a regular `BufferedReader`!) — NIO didn't replace streams, it replaced the _file-system access_ layer around them.

---

## `WatchService` — watching a directory for changes (Java 7+)

**Problem it solves:** you want to react automatically when files are created/modified/deleted in a directory (e.g., a config-reload feature, a file-processing pipeline watching for new uploads) — without manually polling the directory in a loop.

```java
import java.nio.file.*;

WatchService watchService = FileSystems.getDefault().newWatchService();
Path dir = Path.of("watched-folder");
dir.register(watchService, StandardWatchEventKinds.ENTRY_CREATE, StandardWatchEventKinds.ENTRY_MODIFY);

while (true) {
    WatchKey key = watchService.take(); // blocks until an event occurs
    for (WatchEvent<?> event : key.pollEvents()) {
        System.out.println(event.kind() + ": " + event.context());
    }
    key.reset();
}
```

**When to use it:** file-watching features — auto-reloading configuration, triggering a pipeline when a new file lands in a "drop folder," development tools that rebuild on file changes.

---

# Part 2: Buffers, Channels, Selectors — Low-Level High-Performance NIO

This is the part of NIO that's genuinely different in _model_, not just API — and genuinely more complex. Use this only when you have an actual performance or concurrency need that streams can't meet.

## `Buffer` — a container you read/write directly, with a position you control

```java
import java.nio.ByteBuffer;

ByteBuffer buffer = ByteBuffer.allocate(1024); // a 1024-byte buffer in memory
```

**Problem it solves:** streams hide their internal buffering from you. NIO's `Buffer` exposes the buffer directly — you can write into it, flip it, read from it, and reuse it, giving you fine control that matters for high-throughput code.

**Core buffer concepts — position, limit, capacity:**

```java
ByteBuffer buffer = ByteBuffer.allocate(10);

buffer.put((byte) 65);   // write a byte — position advances
buffer.put((byte) 66);

buffer.flip();             // switch from "writing mode" to "reading mode"
                            // (limit = current position, position = 0)

while (buffer.hasRemaining()) {
    System.out.println((char) buffer.get()); // reads: A, B
}

buffer.clear();            // reset for writing again
```

This `put → flip → get → clear` cycle is the defining pattern of buffer usage — genuinely unlike anything in `java.io`, and the most common source of bugs for people new to NIO (forgetting to `flip()` before reading is the #1 mistake).

## `Channel` — the NIO equivalent of a stream, but bidirectional and buffer-based

```java
import java.nio.channels.FileChannel;
import java.nio.file.*;

try (FileChannel channel = FileChannel.open(Path.of("data.txt"), StandardOpenOption.READ)) {
    ByteBuffer buffer = ByteBuffer.allocate(1024);
    int bytesRead = channel.read(buffer); // reads INTO the buffer

    buffer.flip();
    while (buffer.hasRemaining()) {
        System.out.print((char) buffer.get());
    }
}
```

**Key difference from a stream:** a `Channel` can be **read and written** through the same object (a `FileChannel` supports both), and it always transfers data through a `Buffer` — there's no `read()`-one-byte-at-a-time equivalent; you're always working with a chunk in memory.

**When to use `FileChannel` directly:** rarely for typical application code — mostly for:

- **Memory-mapped file access** (below) — extremely fast for large-file random access
- **File locking** (`channel.lock()`) — coordinating access across processes
- **Very high-throughput file copying** (`channel.transferTo()`), though `Files.copy()` / `InputStream.transferTo()` already cover most needs at the application level

## Memory-mapped files — mapping a file directly into memory

```java
try (FileChannel channel = FileChannel.open(Path.of("huge-file.dat"), StandardOpenOption.READ)) {
    MappedByteBuffer mappedBuffer = channel.map(FileChannel.MapMode.READ_ONLY, 0, channel.size());
    byte firstByte = mappedBuffer.get(0);       // direct memory access, no explicit read() call
    byte lastByte = mappedBuffer.get((int) channel.size() - 1);
}
```

**Problem it solves:** for very large files where you need **random access** (jumping to arbitrary positions, not sequential reading), memory-mapping lets the OS handle paging the file in and out of memory efficiently, and you access it like an in-memory array — no explicit `read()` calls, no buffering logic of your own.

**When to use it:** large binary file formats needing random access (databases, large data files with an index), very large files where sequential streaming isn't the access pattern you need. **Not** for ordinary sequential file reading/writing — that's what `java.io`/`Files.lines()` are for, and they're simpler.

## `Selector` — non-blocking, single-thread-many-connections I/O

```java
import java.nio.channels.*;

Selector selector = Selector.open();
ServerSocketChannel serverChannel = ServerSocketChannel.open();
serverChannel.bind(new InetSocketAddress(8080));
serverChannel.configureBlocking(false);
serverChannel.register(selector, SelectionKey.OP_ACCEPT);

while (true) {
    selector.select(); // blocks until AT LEAST ONE channel is ready
    Set<SelectionKey> keys = selector.selectedKeys();
    for (SelectionKey key : keys) {
        if (key.isAcceptable()) {
            // handle new connection
        } else if (key.isReadable()) {
            // handle incoming data — won't block, data is known to be ready
        }
    }
    keys.clear();
}
```

**Problem it solves:** this is the core answer to "10,000 connections without 10,000 threads." A single thread can monitor many channels at once via a `Selector`, and only act on the ones that actually have data ready — no thread sits blocked waiting on any single connection.

**When to use it:** building a custom high-concurrency network server from scratch. **In practice, you'll almost never write this yourself** — frameworks like Netty, or Spring's reactive stack (`WebFlux`), already implement this pattern internally. Knowing it exists helps you understand _why_ those frameworks are fast, even if you never write raw `Selector` code yourself.

---

## Asynchronous I/O — `AsynchronousFileChannel` / `AsynchronousSocketChannel` (Java 7+)

```java
AsynchronousFileChannel channel = AsynchronousFileChannel.open(Path.of("data.txt"), StandardOpenOption.READ);
ByteBuffer buffer = ByteBuffer.allocate(1024);

channel.read(buffer, 0, buffer, new CompletionHandler<Integer, ByteBuffer>() {
    @Override
    public void completed(Integer result, ByteBuffer attachment) {
        System.out.println("Read " + result + " bytes");
    }
    @Override
    public void failed(Throwable exc, ByteBuffer attachment) {
        System.out.println("Read failed: " + exc.getMessage());
    }
});
```

**Problem it solves:** lets you issue a read/write and get **notified via callback** when it completes, instead of blocking _or_ manually polling with a `Selector`. This is a further evolution beyond `Selector`-based non-blocking I/O.

**When to use it:** specialized async I/O scenarios. In modern Spring applications, you'd typically use `WebFlux`/reactive streams (built on Netty, which uses these lower-level mechanisms internally) rather than writing this directly.

---

## Decision table: java.io streams vs java.nio.file vs NIO channels/buffers/selectors

|Task|Recommended tool|
|---|---|
|Read/write a text or small-medium binary file|`Files.readString/writeString`, or `java.io` streams via `Files.newBufferedReader/Writer`|
|Stream a large file line-by-line|`Files.lines()`|
|Copy/move/delete files, list directories|`Files` methods|
|Console I/O|`System.in`/`System.out` + `Scanner`/`BufferedReader`|
|Watch a directory for file changes|`WatchService`|
|Random access into a huge binary file|`FileChannel` + `MappedByteBuffer`|
|Build a custom high-concurrency server|`Selector` (or better: use Netty/Spring WebFlux)|
|Simple sequential network client (HTTP calls)|`java.net.http.HttpClient` (built on NIO internally, simple blocking-style API for you)|

---

## Recent JDK developments relevant to this choice (up to JDK 25)

**Virtual threads (Java 21+, finalized)** meaningfully change this whole calculus for application-level code: the traditional reason to reach for raw NIO Selectors (avoiding one-OS-thread-per-connection) is now largely solved by running ordinary **blocking** `java.io`/`java.net` code on virtual threads instead — the JVM parks the lightweight virtual thread instead of blocking a real OS thread, so you get the scalability benefit of NIO's non-blocking model while writing simple, readable blocking-style code. This is a genuinely significant shift: **for most new server-side Java code today, you don't need to write raw NIO Selector code at all** — write normal blocking `java.io` code, run it on virtual threads, and get comparable scalability. Low-level `Selector`/`Channel` code is now mostly relevant inside framework internals (Netty, etc.) rather than typical application code.

---

## Summary — the practical takeaway

1. **For everyday file operations:** always use `java.nio.file`'s `Path` + `Files` — it has replaced `java.io.File` as the standard.
2. **For actual reading/writing content:** you'll still often end up using `java.io`'s `BufferedReader`/`BufferedWriter`/streams — `Files` methods frequently just hand you one of these, or a convenience method wrapping the same idea.
3. **For raw `Buffer`/`Channel`/`Selector` NIO:** reserve this for genuine low-level performance needs (memory-mapped large files, custom high-concurrency servers) — it's real, it's powerful, but it's not the default tool for typical application code, and with virtual threads now available, the concurrency motivation for it has weakened for most use cases.
4. **In Spring Boot specifically:** you'll mostly interact with `Path`/`Files` (for local file handling — uploads, exports) and never touch raw NIO buffers/channels/selectors yourself — Spring's underlying server (Tomcat/Netty) handles that layer for you.

[[Java]]