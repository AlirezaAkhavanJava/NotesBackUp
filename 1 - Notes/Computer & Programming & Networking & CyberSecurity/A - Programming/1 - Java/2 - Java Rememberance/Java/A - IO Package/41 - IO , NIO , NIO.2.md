
# Java I/O Complete Guide: IO, NIO, and NIO.2

A comprehensive journey from traditional blocking I/O to modern asynchronous file handling in Java.

---

## 📚 Table of Contents

1. [Overview & Evolution](#overview)
2. [Part 1: Java IO (java.io)](#part-1-java-io)
3. [Part 2: Java NIO (java.nio)](#part-2-java-nio)
4. [Part 3: Java NIO.2 (java.nio.file)](#part-3-java-nio2)
5. [Comparison Matrix](#comparison)
6. [Decision Guide](#decision-guide)

---

<a name="overview"></a>
## 🎯 Overview & Evolution

```
Java 1.0 (1996)          Java 1.4 (2002)          Java 7 (2011)
     │                        │                        │
     ▼                        ▼                        ▼
┌─────────┐            ┌─────────────┐          ┌──────────────┐
│ java.io │───────────▶│  java.nio   │─────────▶│ java.nio.file│
│  (IO)   │            │   (NIO)     │          │   (NIO.2)    │
└─────────┘            └─────────────┘          └──────────────┘
Stream-based           Buffer + Channel         Path + Files
Blocking               Non-blocking             Asynchronous
```

**The Story:**
- **IO**: Simple, stream-based, blocking — good for small, simple tasks
- **NIO**: Buffer + Channel model, non-blocking — good for scalable servers
- **NIO.2**: Modern file API, async I/O — the modern standard

---

<a name="part-1-java-io"></a>
# 📦 Part 1: Java IO (`java.io`)

## 🔷 Definition

**Java IO** is the original I/O API based on **streams** — a sequence of data flowing from a source to a destination. Every operation **blocks** until data is available.

> 💡 **Analogy:** Think of a water pipe. Water (data) flows in one direction. You must wait for water to arrive before you can use it.

---

## 🧱 Core Concepts

### 1. Streams — The Foundation

Two fundamental types:

| Type | Direction | Base Classes | Purpose |
|------|-----------|--------------|---------|
| **Byte Streams** | Raw bytes | `InputStream`, `OutputStream` | Binary data (images, files) |
| **Character Streams** | Text chars | `Reader`, `Writer` | Text data (UTF-8 handling) |

```
┌─────────────────────────────────────────────────────┐
│                    STREAM HIERARCHY                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│   InputStream ────▶ FileInputStream                 │
│       │             ByteArrayInputStream            │
│       │             BufferedInputStream             │
│       │             DataInputStream                 │
│       │                                             │
│   OutputStream ───▶ FileOutputStream                │
│       │             BufferedOutputStream            │
│       │                                             │
│   Reader ─────────▶ FileReader                      │
│       │             BufferedReader                  │
│       │                                             │
│   Writer ─────────▶ FileWriter                      │
│                     BufferedWriter                  │
└─────────────────────────────────────────────────────┘
```

---

### 2. Helper Classes & Definitions

#### 📌 `File`
> Represents a file or directory path. **Not** the actual file content — just an abstract pathname.

```java
File file = new File("data.txt");
file.exists();      // Does it exist?
file.createNewFile(); // Create it
file.length();      // Size in bytes
file.isDirectory(); // Is it a folder?
file.listFiles();   // List children
```

#### 📌 `FileInputStream` / `FileOutputStream`
> Reads/writes **raw bytes** from/to files.

#### 📌 `FileReader` / `FileWriter`
> Reads/writes **characters** (handles encoding).

#### 📌 `BufferedReader` / `BufferedWriter`
> Wraps another reader/writer to add a **memory buffer** — dramatically improves performance by reducing disk hits.

#### 📌 `DataInputStream` / `DataOutputStream`
> Reads/writes **primitives** (int, double, boolean) in a portable binary format.

#### 📌 `ObjectInputStream` / `ObjectOutputStream`
> **Serializes/deserializes** Java objects.

---

## 📘 Basic Usage

### Example 1: Read a File Line by Line

```java
import java.io.*;

public class BasicRead {
    public static void main(String[] args) {
        try (BufferedReader reader = new BufferedReader(new FileReader("hello.txt"))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

### Example 2: Write to a File

```java
try (BufferedWriter writer = new BufferedWriter(new FileWriter("output.txt"))) {
    writer.write("Hello, World!");
    writer.newLine();
    writer.write("Second line");
} catch (IOException e) {
    e.printStackTrace();
}
```

### Example 3: Copy a File (Byte by Byte)

```java
try (InputStream in = new FileInputStream("src.jpg");
     OutputStream out = new FileOutputStream("copy.jpg")) {
    byte[] buffer = new byte[4096];
    int bytesRead;
    while ((bytesRead = in.read(buffer)) != -1) {
        out.write(buffer, 0, bytesRead);
    }
}
```

---

## 🚀 Advanced Usage

### Example 4: Serialization

```java
class Person implements Serializable {
    private static final long serialVersionUID = 1L;
    String name;
    int age;
    // constructor, getters...
}

// Save object
try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("person.ser"))) {
    oos.writeObject(new Person("Alice", 30));
}

// Load object
try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream("person.ser"))) {
    Person p = (Person) ois.readObject();
}
```

### Example 5: Reading Primitive Types

```java
try (DataOutputStream dos = new DataOutputStream(new FileOutputStream("data.bin"))) {
    dos.writeInt(42);
    dos.writeDouble(3.14);
    dos.writeUTF("Hello");
}
```

---

## ⚠️ Common Problems

| Problem | Description | Solution |
|---------|-------------|----------|
| **Resource leaks** | Forgetting to close streams | Use try-with-resources |
| **Slow reads** | Unbuffered I/O hits disk each call | Wrap in `BufferedReader`/`BufferedOutputStream` |
| **Encoding issues** | Default charset mismatch | Explicitly specify `StandardCharsets.UTF_8` |
| **Blocking** | Thread waits during I/O | Use NIO for non-blocking needs |
| **`File` is outdated** | No support for symlinks, permissions | Use NIO.2 `Path` |

### 🐛 The Classic Bug

```java
// ❌ BAD: leaks if exception occurs
FileInputStream in = new FileInputStream("file.txt");
in.read(); // throws?
in.close(); // never reached!
```

```java
// ✅ GOOD: auto-closed
try (FileInputStream in = new FileInputStream("file.txt")) {
    in.read();
}
```

---

<a name="part-2-java-nio"></a>
# 📦 Part 2: Java NIO (`java.nio`)

## 🔷 Definition

**Java NIO (New I/O)** is a buffer-and-channel-based I/O API supporting **non-blocking** operations and **selector-based** multiplexing, designed for high-performance scalable servers.

> 💡 **Analogy:** Instead of one water pipe, think of a **train station**. Trains (channels) move on tracks, cargo (buffers) is loaded/unloaded, and a station master (selector) directs which train moves next.

---

## 🧱 Core Concepts

### 1. The Three Pillars

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   CHANNEL    │───▶│    BUFFER    │    │   SELECTOR   │
│              │    │              │    │              │
│ Bidirectional│    │ Data holder  │    │ Multiplexer  │
│ Read + Write │    │ Fixed size   │    │ 1 thread →   │
│              │    │              │    │ N channels   │
└──────────────┘    └──────────────┘    └──────────────┘
```

---

### 2. Helper Classes & Definitions

#### 📌 `ByteBuffer` (and other Buffers)
> A **fixed-size container** for data. Has `position`, `limit`, and `capacity`.

```
   capacity = 10
   ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
   │ H │ e │ l │ l │ o │   │   │   │   │   │
   └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
     ▲                       ▲               ▲
   position=5              limit=10       capacity=10
```

**Key methods:**
- `put(byte)` — write at position, advance position
- `get()` — read at position, advance position
- `flip()` — switch write → read mode (limit=position, position=0)
- `clear()` — reset for writing
- `rewind()` — re-read from start

#### 📌 `Channel`
> A **bidirectional** connection to an I/O source. Unlike streams, a channel can read AND write.

| Channel | Purpose |
|---------|---------|
| `FileChannel` | File I/O (blocking only) |
| `SocketChannel` | TCP client connection |
| `ServerSocketChannel` | TCP server listener |
| `DatagramChannel` | UDP |

#### 📌 `Selector`
> A **multiplexer** that lets one thread monitor many channels for readiness.

#### 📌 `Charset`
> Encodes/decodes bytes ↔ characters (e.g., UTF-8, ISO-8859-1).

---

## 📘 Basic Usage

### Example 1: Reading a File with NIO

```java
import java.nio.*;
import java.nio.channels.*;
import java.nio.file.*;

public class NioRead {
    public static void main(String[] args) throws Exception {
        try (FileChannel channel = FileChannel.open(Paths.get("hello.txt"))) {
            ByteBuffer buffer = ByteBuffer.allocate(1024);
            
            while (channel.read(buffer) != -1) {
                buffer.flip();               // switch to read mode
                while (buffer.hasRemaining()) {
                    System.out.print((char) buffer.get());
                }
                buffer.clear();              // switch to write mode
            }
        }
    }
}
```

### Example 2: Writing with NIO

```java
try (FileChannel channel = FileChannel.open(
        Paths.get("out.txt"),
        StandardOpenOption.CREATE, StandardOpenOption.WRITE)) {
    
    ByteBuffer buffer = ByteBuffer.wrap("Hello NIO!".getBytes());
    channel.write(buffer);
}
```

---

## 🚀 Advanced Usage

### Example 3: Non-Blocking Echo Server with Selector

```java
import java.nio.*;
import java.nio.channels.*;
import java.net.*;
import java.util.*;

public class EchoServer {
    public static void main(String[] args) throws Exception {
        ServerSocketChannel server = ServerSocketChannel.open();
        server.bind(new InetSocketAddress(8080));
        server.configureBlocking(false);
        
        Selector selector = Selector.open();
        server.register(selector, SelectionKey.OP_ACCEPT);
        
        System.out.println("Server listening on 8080...");
        
        while (true) {
            selector.select();  // blocks until a channel is ready
            Set<SelectionKey> keys = selector.selectedKeys();
            Iterator<SelectionKey> it = keys.iterator();
            
            while (it.hasNext()) {
                SelectionKey key = it.next();
                it.remove();
                
                if (key.isAcceptable()) {
                    SocketChannel client = server.accept();
                    client.configureBlocking(false);
                    client.register(selector, SelectionKey.OP_READ);
                    System.out.println("Client connected: " + client.getRemoteAddress());
                }
                else if (key.isReadable()) {
                    SocketChannel client = (SocketChannel) key.channel();
                    ByteBuffer buffer = ByteBuffer.allocate(256);
                    int read = client.read(buffer);
                    
                    if (read == -1) {
                        client.close();
                        continue;
                    }
                    
                    buffer.flip();
                    client.write(buffer);  // echo back
                }
            }
        }
    }
}
```

### Example 4: Memory-Mapped Files (Blazing Fast)

```java
try (FileChannel channel = FileChannel.open(
        Paths.get("large.dat"),
        StandardOpenOption.READ,
        StandardOpenOption.WRITE)) {
    
    MappedByteBuffer mapped = channel.map(
        FileChannel.MapMode.READ_WRITE, 0, channel.size());
    
    // Access like an array — OS handles paging
    mapped.put(0, (byte) 'X');
    byte b = mapped.get(100);
}
```

> ⚡ **Why fast?** The OS maps the file directly into memory. No explicit read/write calls needed.

---

## ⚠️ Common Problems

| Problem | Description | Solution |
|---------|-------------|----------|
| **Forgetting `flip()`** | Reads fail — position at end | Always `flip()` before reading |
| **Buffer overflow** | `BufferOverflowException` | Check `remaining()` or use larger buffer |
| **`FileChannel` can't be non-blocking** | Only sockets support non-blocking | Use async (NIO.2) for files |
| **Byte↔Char confusion** | `(char) buffer.get()` fails for UTF-8 | Use `CharsetDecoder` |
| **Forgetting `clear()`** | Buffer fills up | Call `clear()` after consuming |
| **Selector complexity** | Bugs in key handling | Use frameworks (Netty) for production |

### 🐛 The Classic Bug

```java
// ❌ BAD: forgot flip()
channel.read(buffer);
System.out.println(buffer.get()); // reads garbage at position=end
```

```java
// ✅ GOOD
channel.read(buffer);
buffer.flip();
while (buffer.hasRemaining()) System.out.print((char) buffer.get());
```

---

<a name="part-3-java-nio2"></a>
# 📦 Part 3: Java NIO.2 (`java.nio.file`)

## 🔷 Definition

**Java NIO.2** (introduced in Java 7 as JSR-203) is a comprehensive file-system API that adds `Path`, `Files`, `WatchService`, and **asynchronous channels** (`AsynchronousFileChannel`, `AsynchronousSocketChannel`) to the NIO family.

> 💡 **Analogy:** NIO.2 is the **modern filing cabinet**. NIO gave you tools; NIO.2 gives you a fully organized office with labels, folders, metadata, and a notification system.

---

## 🧱 Core Concepts

### 1. Key Improvements

```
┌─────────────────────────────────────────────────┐
│              NIO.2 ENHANCEMENTS                 │
├─────────────────────────────────────────────────┤
│  ✅ Path API (better than File)                 │
│  ✅ Files utility class (100+ methods)          │
│  ✅ Asynchronous I/O (true async, not just NB)  │
│  ✅ WatchService (file system events)           │
│  ✅ File attributes (permissions, owner, ACL)   │
│  ✅ Symbolic link support                       │
│  ✅ FileVisitor for recursive walks             │
└─────────────────────────────────────────────────┘
```

---

### 2. Helper Classes & Definitions

#### 📌 `Path`
> An **immutable** representation of a file system location. Replaces `File`.

```java
Path p = Paths.get("/home/user/docs/report.txt");
p.getFileName();      // report.txt
p.getParent();        // /home/user/docs
p.getRoot();          // /
p.toAbsolutePath();   // full path
p.normalize();        // removes . and ..
p.resolve("other");   // appends
p.relativize(other);  // relative path between
```

#### 📌 `Paths`
> Factory for `Path` objects. `Paths.get("a", "b", "c")`.

#### 📌 `Files`
> Static utility class with 100+ operations — copy, move, delete, read, write, walk.

#### 📌 `FileSystem`
> Abstraction of a file system (allows ZIP, in-memory, custom FS).

#### 📌 `WatchService`
> Notifies you when files/folders **change** (create, modify, delete).

#### 📌 `FileVisitor` / `SimpleFileVisitor`
> Callback for recursive directory traversal.

#### 📌 `AsynchronousFileChannel`
> File channel with **callback-based** or **Future-based** async reads/writes.

#### 📌 `AsynchronousSocketChannel` / `AsynchronousServerSocketChannel`
> True async network I/O — no selector needed.

#### 📌 `BasicFileAttributes`
> Metadata: creation time, last modified, size, type.

---

## 📘 Basic Usage

### Example 1: Reading & Writing Files (One-Liners!)

```java
import java.nio.file.*;
import java.util.List;

// Read entire file as String
String content = Files.readString(Paths.get("hello.txt"));  // Java 11+

// Read all lines
List<String> lines = Files.readAllLines(Paths.get("hello.txt"));

// Read all bytes
byte[] bytes = Files.readAllBytes(Paths.get("image.png"));

// Write String
Files.writeString(Paths.get("out.txt"), "Hello NIO.2!");   // Java 11+

// Write lines
Files.write(Paths.get("out.txt"), lines);

// Append
Files.writeString(Paths.get("log.txt"), "new entry\n",
        StandardOpenOption.CREATE, StandardOpenOption.APPEND);
```

### Example 2: Path Manipulation

```java
Path base = Paths.get("/home/user");
Path file = base.resolve("docs").resolve("notes.txt");
// /home/user/docs/notes.txt

Path normalized = Paths.get("/home/./user/../user/docs").normalize();
// /home/user/docs

Path relative = base.relativize(file);
// docs/notes.txt
```

---

## 🚀 Advanced Usage

### Example 3: File Attributes

```java
Path path = Paths.get("important.txt");
BasicFileAttributes attrs = Files.readAttributes(path, BasicFileAttributes.class);

System.out.println("Created: " + attrs.creationTime());
System.out.println("Modified: " + attrs.lastModifiedTime());
System.out.println("Size: " + attrs.size());
System.out.println("Is dir: " + attrs.isDirectory());
System.out.println("Is symlink: " + attrs.isSymbolicLink());
```

### Example 4: Recursive Directory Walk

```java
Path start = Paths.get("/home/user/project");

Files.walkFileTree(start, new SimpleFileVisitor<Path>() {
    @Override
    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
        if (file.toString().endsWith(".java")) {
            System.out.println("Java file: " + file);
        }
        return FileVisitResult.CONTINUE;
    }
    
    @Override
    public FileVisitResult visitFileFailed(Path file, IOException exc) {
        System.err.println("Cannot access: " + file);
        return FileVisitResult.CONTINUE;
    }
});
```

**Stream-based alternative:**

```java
try (Stream<Path> stream = Files.walk(start)) {
    stream.filter(p -> p.toString().endsWith(".java"))
          .forEach(System.out::println);
}
```

### Example 5: Watching a Directory

```java
WatchService watcher = FileSystems.getDefault().newWatchService();
Path dir = Paths.get("/home/user/watched");
dir.register(watcher,
    StandardWatchEventKinds.ENTRY_CREATE,
    StandardWatchEventKinds.ENTRY_MODIFY,
    StandardWatchEventKinds.ENTRY_DELETE);

while (true) {
    WatchKey key = watcher.take();  // blocks
    for (WatchEvent<?> event : key.pollEvents()) {
        System.out.printf("%s: %s%n", event.kind().name(), event.context());
    }
    key.reset();  // re-arm
}
```

> ⚡ **Real-world use:** Live-reload dev servers, log monitors, file sync tools.

### Example 6: Asynchronous File Read (Callback Style)

```java
Path path = Paths.get("bigfile.dat");
AsynchronousFileChannel channel = AsynchronousFileChannel.open(path);

ByteBuffer buffer = ByteBuffer.allocate(1024);

channel.read(buffer, 0, buffer, new CompletionHandler<Integer, ByteBuffer>() {
    @Override
    public void completed(Integer bytesRead, ByteBuffer attachment) {
        attachment.flip();
        System.out.println("Read " + bytesRead + " bytes");
        attachment.clear();
    }
    
    @Override
    public void failed(Throwable exc, ByteBuffer attachment) {
        exc.printStackTrace();
    }
});

// Main thread continues immediately — no blocking!
Thread.sleep(1000);  // wait for demo
```

### Example 7: Asynchronous File Read (Future Style)

```java
AsynchronousFileChannel channel = AsynchronousFileChannel.open(path);
ByteBuffer buffer = ByteBuffer.allocate(1024);

Future<Integer> result = channel.read(buffer, 0);

// ... do other work ...

int bytesRead = result.get();  // blocks only when needed
```

### Example 8: Asynchronous Socket Server

```java
AsynchronousServerSocketChannel server =
    AsynchronousServerSocketChannel.open().bind(new InetSocketAddress(8080));

server.accept(null, new CompletionHandler<AsynchronousSocketChannel, Void>() {
    @Override
    public void completed(AsynchronousSocketChannel client, Void att) {
        server.accept(null, this);  // accept next
        
        ByteBuffer buf = ByteBuffer.allocate(1024);
        client.read(buf, buf, new CompletionHandler<Integer, ByteBuffer>() {
            @Override
            public void completed(Integer n, ByteBuffer b) {
                b.flip();
                client.write(b, b, new CompletionHandler<Integer, ByteBuffer>() {
                    @Override public void completed(Integer n, ByteBuffer b) { /* echo done */ }
                    @Override public void failed(Throwable e, ByteBuffer b) { e.printStackTrace(); }
                });
            }
            @Override public void failed(Throwable e, ByteBuffer b) { e.printStackTrace(); }
        });
    }
    @Override
    public void failed(Throwable exc, Void att) { exc.printStackTrace(); }
});

Thread.sleep(Long.MAX_VALUE);  // keep alive
```

---

## ⚠️ Common Problems

| Problem | Description | Solution |
|---------|-------------|----------|
| **`NoSuchFileException`** | File doesn't exist | Check `Files.exists()` first |
| **`FileAlreadyExistsException`** | Copy to existing file | Use `REPLACE_EXISTING` option |
| **`DirectoryNotEmptyException`** | Deleting non-empty dir | Delete children first, or use `Files.walk` |
| **Symlink confusion** | Following vs. not following links | Use `LinkOption.NOFOLLOW_LINKS` |
| **Watcher overflow** | Too many events | Handle `OVERFLOW` event, rescan |
| **Async channel closes early** | Main thread exits | Keep a reference / use `Thread.sleep` / executor |
| **Cross-filesystem move** | `Files.move` fails | Falls back to copy + delete |
| **Path separator issues** | `/` vs `\` | Use `File.separator` or `Path` API |

### 🐛 The Classic Bug

```java
// ❌ BAD: watcher loses events if you don't reset
WatchKey key = watcher.take();
process(key.pollEvents());
// forgot key.reset() — no more events!
```

```java
// ✅ GOOD
WatchKey key = watcher.take();
try {
    process(key.pollEvents());
} finally {
    key.reset();
}
```

---

<a name="comparison"></a>
# 📊 Comparison Matrix

| Feature | **IO** | **NIO** | **NIO.2** |
|---------|--------|---------|-----------|
| **Since** | Java 1.0 | Java 1.4 | Java 7 |
| **Package** | `java.io` | `java.nio` | `java.nio.file` |
| **Model** | Stream | Buffer + Channel | Path + Async |
| **Blocking** | Always | Optional | Optional (true async) |
| **Direction** | Unidirectional | Bidirectional | Bidirectional |
| **Selector** | ❌ | ✅ | ✅ |
| **Path API** | `File` (limited) | `File` (limited) | `Path` (rich) |
| **File utilities** | Manual | Manual | `Files` (100+) |
| **Async I/O** | ❌ | ❌ | ✅ |
| **WatchService** | ❌ | ❌ | ✅ |
| **Attributes** | ❌ | ❌ | ✅ |
| **Symlinks** | ❌ | ❌ | ✅ |
| **Memory-mapped** | ❌ | ✅ | ✅ |
| **Best for** | Simple I/O | Scalable servers | Everything modern |

---

<a name="decision-guide"></a>
# 🧭 Decision Guide

```
                    What are you doing?
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
    Simple file         Many network       Modern file
    read/write?         connections?       operations?
        │                   │                   │
        ▼                   ▼                   ▼
    Use IO with         Use NIO            Use NIO.2
    try-with-           Selector /         Path + Files
    resources           Netty              + Watch/Async
```

### 🎯 Quick Rules

- **Just need to read a config file?** → NIO.2 (`Files.readString`)
- **Building a chat server with 10k users?** → NIO + Selector (or Netty)
- **Watching a directory for changes?** → NIO.2 `WatchService`
- **Processing 10GB log file?** → NIO `FileChannel` + memory-mapped buffer
- **Legacy code maintenance?** → Java IO (but wrap in buffers!)

### 📌 Golden Rules

1. **Always use try-with-resources** — no exceptions.
2. **Always buffer** your streams/buffers.
3. **Always specify charset** — never rely on defaults.
4. **Prefer NIO.2 `Path`/`Files`** for new code.
5. **Never block on async channels** without reason.

---

## 🎓 Summary

```
┌────────────────────────────────────────────────────────────┐
│                     THE BIG PICTURE                        │
├────────────────────────────────────────────────────────────┤
│                                                            │
│   IO      = Stream + Blocking      → simple, legacy        │
│   NIO     = Buffer + Channel       → scalable, complex     │
│   NIO.2   = Path + Async + Watch   → modern, comprehensive │
│                                                            │
│   Modern Java code SHOULD use NIO.2 for files,             │
│   NIO for network servers, and IO only for legacy.         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

You now have a complete mental map from the simplest `FileReader` to the most advanced `AsynchronousServerSocketChannel`. Happy I/O! 🚀


[[Java]]