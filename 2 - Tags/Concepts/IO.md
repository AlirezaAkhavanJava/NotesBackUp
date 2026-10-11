

## Core intuition

Every program is an island floating in memory. To be useful, it needs to exchange data with the outside world: reading a file, getting keyboard input, sending data over a network, printing to a console. **I/O is the bridge between your program's memory and everything else.** In Java, this bridge is built almost entirely around one mental model:

> **A stream is an ordered sequence of bytes flowing between your program and a data source/sink.**

Think of it like a river: you don't "own" the whole river, you dip in and pull out water (read) or pour water in (write), one chunk at a time. Once a byte floats past, it's gone — streams are largely **one-directional and sequential**.

## The technical landscape

### 1. Byte streams vs. Character streams

Java splits the world in two:

| | Byte streams | Character streams |
|---|---|---|
| Unit of data | 8-bit bytes | 16-bit UTF-16 chars |
| Abstract classes | `InputStream` / `OutputStream` | `Reader` / `Writer` |
| Use for | Images, audio, PDFs, network data, serialization | Text files, console, text over the wire |

Root classes:

```java
InputStream  is = new FileInputStream("photo.png");   // raw bytes
Reader       r  = new FileReader("notes.txt");        // chars (uses default charset!)
```

Why two hierarchies? Java's `char` is 16-bit (UTF-16), but files on disk are bytes. Something must convert bytes→chars, and that "something" is a **charset/decoder**. Character streams handle encoding for you; byte streams don't care about encoding at all.

### 2. Streams vs. Readers — the real design insight

Java's I/O is the **Decorator pattern** in action. Basic streams do one thing (read bytes from a file). You wrap them in decorators to add behavior:

```java
try (BufferedReader br = new BufferedReader(new FileReader("data.txt"))) {
    String line;
    while ((line = br.readLine()) != null) {
        System.out.println(line);
    }
}
```

Here `BufferedReader` wraps `FileReader` and adds buffering + line reading. Other common decorators:

- `BufferedInputStream` / `BufferedReader` — **always use buffering**; unbuffered reads hit the OS for every few bytes, which is catastrophically slow.
- `DataInputStream` / `DataOutputStream` — read/write primitives (`readInt`, `writeDouble`) portably.
- `ObjectInputStream` / `ObjectOutputStream` — **serialization** (turn objects into byte streams).
- `InputStreamReader` — the adapter that converts a byte stream into a character stream with an explicit charset: `new InputStreamReader(new FileInputStream(f), StandardCharsets.UTF_8)`.
- `PrintWriter` — convenient text output with `println` methods.

### 3. NIO (New I/O, `java.nio`, Java 1.4) and NIO.2 (`java.nio.file`, Java 7)

Classic I/O is **blocking and stream-based**: when you call `read()`, your thread freezes until data arrives. NIO introduced:

- **Channels & Buffers** — instead of a stream pulling bytes one by one, a `Channel` reads a chunk into a `Buffer` that you then drain. Enables bulk operations.
- **Selectors** — one thread can monitor many channels (the foundation of non-blocking servers like Netty).
- **NIO.2 `Path` / `Files`** (the API you should actually use today):

```java
Path p = Paths.get("data.txt");
String content = Files.readString(p);            // Java 11+ 
List<String> lines = Files.readAllLines(p);       // whole file into memory
Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
```

### 4. `System.in`, `System.out`, `System.err`

The console streams you use daily:

```java
System.out.println("hello");   // PrintStream (bytes, not a Writer!)
Scanner sc = new Scanner(System.in);
String name = sc.nextLine();
```

Notable quirk: `System.out` is a byte-based `PrintStream`, which is why console output can mangle non-ASCII characters depending on platform encoding — a classic source of "why is my UTF-8 text garbled" bugs.

## Nuances & gotchas

1. **Always close your streams** — leaked file handles exhaust OS resources. Use try-with-resources (shown above); it's the idiomatic way and handles nested closers.

2. **Always specify a charset explicitly.** `new FileReader(f)` uses the platform default charset, so code that works on your machine may corrupt text on a server. Prefer `Files.newBufferedReader(path, StandardCharsets.UTF_8)`.

3. **Checked exceptions.** I/O methods throw `IOException` (checked), forcing you to handle failure — files disappear, disks fill, networks drop.

4. **Buffering matters.** `read()` per byte from a `FileInputStream` = a system call per byte. Wrap in `BufferedInputStream` (or use `Files` methods, which buffer internally).

5. **Serialization is not an API contract.** `Serializable` is fragile (class changes break it), not secure against crafted input, and has been a source of serious vulnerabilities — modern Java (since 9) warns against using it for new code; prefer JSON/ProtoBuf.

6. **Blocking vs. non-blocking.** Classic `java.io` = blocking (one thread per connection, fine for files); NIO selectors = multiplexing (many connections per thread, needed for high-scale servers). Frameworks like Netty wrap this for you.

## Rule of thumb for modern code

- Reading/writing whole files → `Files.readString`, `Files.write`, `Files.lines` (streams, lazy!)
- Text stream processing → `BufferedReader`/`PrintWriter` with explicit UTF-8
- Binary data → `BufferedInputStream`/`BufferedOutputStream`, or `Files.newInputStream`
- Network servers at scale → look at NIO selectors or just use Netty
- Never touch `FileReader`/`FileWriter` if you care about portability

**In one sentence:** Java I/O is the stream-based (later channel/buffer-based) machinery centered on `java.io`, `java.nio`, and `java.nio.file`, designed to move bytes and characters between your program and the outside world — and 90% of real-world pain in it comes from buffering, charsets, and forgetting to close resources.


[[Java]]