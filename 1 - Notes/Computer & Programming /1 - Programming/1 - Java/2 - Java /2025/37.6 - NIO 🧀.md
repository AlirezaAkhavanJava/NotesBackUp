
# Java NIO (New I/O) – Complete Teaching Guide

> **NIO was introduced in Java 1.4** as a **faster, buffer-oriented, non-blocking I/O** alternative to traditional `java.io`.

---

## 1. What is Java NIO?

| Feature | Traditional `java.io` | **Java NIO (`java.nio`)** |
|--------|------------------------|----------------------------|
| **I/O Model** | Stream-oriented (byte/char) | Buffer-oriented |
| **Blocking** | Always blocking | Supports **non-blocking** |
| **Performance** | Slower (byte-by-byte) | Faster (bulk transfers) |
| **Scalability** | Poor (one thread per connection) | High (multiplexing via selectors) |
| **Channels** | No | Yes |
| **Buffers** | No | Yes |

> **NIO = Channels + Buffers + Selectors**

---

## 2. Core Components of Java NIO

### 1. **Buffers**
- A **container for data** (like an array).
- Used to **read from/write to** channels.
- Always **allocated with fixed size**.

#### Types of Buffers:
```java
ByteBuffer, CharBuffer, ShortBuffer, IntBuffer, LongBuffer, FloatBuffer, DoubleBuffer
```
> Most used: **`ByteBuffer`**

#### Buffer Properties (via `position`, `limit`, `capacity`)
| Property | Meaning |
|--------|-------|
| `capacity` | Total size (fixed) |
| `position` | Current read/write index |
| `limit` | End of readable/writable data |

```java
ByteBuffer buf = ByteBuffer.allocate(1024);
// capacity = 1024, position = 0, limit = 1024
```

#### Key Buffer Methods
| Method | Purpose |
|------|--------|
| `allocate(int)` | Direct heap allocation |
| `allocateDirect(int)` | Off-heap (OS-level, faster for I/O) |
| `put(byte)` / `put(byte[])` | Write data |
| `get()` / `get(byte[])` | Read data |
| `flip()` | Switch from write → read mode (`limit = position; position = 0`) |
| `rewind()` | Reset position to 0 (for re-reading) |
| `clear()` | Reset for reuse (does **not** erase data) |
| `mark()` / `reset()` | Save/restore position |

---

### 2. **Channels**
- A **channel** represents an open connection to a resource (file, socket).
- **Bidirectional** (read + write).
- Works **only with buffers**.

#### Common Channels
| Channel | Purpose |
|-------|--------|
| `FileChannel` | File I/O |
| `SocketChannel` | TCP client |
| `ServerSocketChannel` | TCP server |
| `DatagramChannel` | UDP |

> **Note**: `FileChannel` **cannot** be set to non-blocking mode.

#### Example: Reading from FileChannel
```java
FileChannel channel = new FileInputStream("data.txt").getChannel();
ByteBuffer buf = ByteBuffer.allocate(128);
int bytesRead = channel.read(buf); // reads into buffer
```

---

### 3. **Selectors**
- Enable **non-blocking I/O**.
- One thread can monitor **multiple channels**.
- Uses **multiplexing**.

#### Key Classes
- `Selector`
- `SelectionKey`
- `SelectableChannel`

#### SelectionKey Operations
| Constant | Meaning |
|--------|--------|
| `OP_READ` | Ready to read |
| `OP_WRITE` | Ready to write |
| `OP_CONNECT` | Connection ready |
| `OP_ACCEPT` | Accept incoming connection |

---

## 3. How NIO Works (Step-by-Step)

### Step 1: Create Buffer
```java
ByteBuffer buffer = ByteBuffer.allocate(256);
```

### Step 2: Write Data into Buffer
```java
buffer.put("Hello NIO".getBytes());
buffer.flip(); // Prepare for reading
```

### Step 3: Use Channel to Read/Write
```java
FileChannel channel = FileChannel.open(path, StandardOpenOption.WRITE);
channel.write(buffer);
```

---

## 4. File I/O with NIO

### Reading a File
```java
Path path = Paths.get("input.txt");
try (FileChannel channel = FileChannel.open(path)) {
    ByteBuffer buffer = ByteBuffer.allocate(1024);
    int bytesRead = channel.read(buffer);
    while (bytesRead != -1) {
        buffer.flip();
        while (buffer.hasRemaining()) {
            System.out.print((char) buffer.get());
        }
        buffer.clear();
        bytesRead = channel.read(buffer);
    }
}
```

### Writing to a File
```java
String data = "Hello from Java NIO!";
ByteBuffer buffer = ByteBuffer.allocate(1024);
buffer.put(data.getBytes());
buffer.flip();

try (FileChannel channel = FileChannel.open(
        Paths.get("output.txt"),
        StandardOpenOption.CREATE, StandardOpenOption.WRITE)) {
    channel.write(buffer);
}
```

---

## 5. Non-Blocking Server with NIO

### Simple Echo Server (Non-blocking)
```java
Selector selector = Selector.open();
ServerSocketChannel server = ServerSocketChannel.open();
server.bind(new InetSocketAddress(8080));
server.configureBlocking(false);
server.register(selector, SelectionKey.OP_ACCEPT);

while (true) {
    selector.select(); // blocks until something happens
    Set<SelectionKey> keys = selector.selectedKeys();
    Iterator<SelectionKey> it = keys.iterator();

    while (it.hasNext()) {
        SelectionKey key = it.next();

        if (key.isAcceptable()) {
            SocketChannel client = server.accept();
            client.configureBlocking(false);
            client.register(selector, SelectionKey.OP_READ);
            System.out.println("Client connected");

        } else if (key.isReadable()) {
            SocketChannel client = (SocketChannel) key.channel();
            ByteBuffer buffer = ByteBuffer.allocate(256);
            int bytesRead = client.read(buffer);

            if (bytesRead == -1) {
                client.close();
            } else {
                buffer.flip();
                client.write(buffer); // echo back
                buffer.clear();
            }
        }
        it.remove();
    }
}
```

---

## 6. Key Advantages of NIO

| Advantage | Explanation |
|--------|-----------|
| **Performance** | Bulk transfers via buffers |
| **Scalability** | One thread handles thousands of connections |
| **Non-blocking** | No thread waits idly |
| **Memory Efficient** | Direct buffers reduce copying |

---

## 7. NIO vs Traditional I/O – Comparison Table

| Feature | `java.io` | `java.nio` |
|-------|----------|-----------|
| Orientation | Stream | Buffer |
| Blocking | Yes | Optional |
| Thread per connection | Yes | No (Selector) |
| Speed | Slow | Fast |
| File locking | Limited | Full support |
| Scatter/Gather | No | Yes |

---

## 8. Important Classes Summary

| Package | Class | Role |
|--------|------|-----|
| `java.nio` | `ByteBuffer` | Core buffer |
| `java.nio.channels` | `FileChannel` | File access |
| `java.nio.channels` | `SocketChannel` | TCP client |
| `java.nio.channels` | `ServerSocketChannel` | TCP server |
| `java.nio.channels` | `Selector` | Non-blocking I/O |
| `java.nio.file` | `Paths`, `Files` | Modern file ops |

---

## 9. Best Practices

1. **Always `flip()`** buffer after writing, before reading.
2. **Use `try-with-resources`** for channels.
3. **Prefer `allocateDirect()`** for heavy I/O.
4. **Call `it.remove()`** after processing selected keys.
5. **Never use `FileChannel` in non-blocking mode**.

---

## 10. Common Interview Questions

| Question | Answer |
|--------|-------|
| Difference between `flip()` and `clear()`? | `flip()`: limit = position, position = 0 (for reading). `clear()`: position = 0, limit = capacity (for writing). |
| Can `FileChannel` be non-blocking? | **No**. Only network channels can. |
| What is `Selector`? | Monitors multiple channels for I/O events. |
| What is `Direct Buffer`? | Memory outside JVM heap → faster native I/O. |

---

## Final Tips to Master NIO

1. **Practice file read/write** using `FileChannel` + `ByteBuffer`.
2. **Build a non-blocking echo server**.
3. **Use `Paths.get()` and `Files` API** (NIO.2).
4. **Visualize buffer states** (position, limit, capacity).

---

## Bonus: NIO.2 (Java 7+)

- `java.nio.file` package
- `Path`, `Files`, `FileSystem`
- Asynchronous I/O: `AsynchronousFileChannel`

```java
Path path = Paths.get("file.txt");
List<String> lines = Files.readAllLines(path);
Files.write(path, "New line".getBytes(), StandardOpenOption.APPEND);
```

---

# Summary

> **Java NIO = High-performance, scalable, non-blocking I/O using:**
> - **Buffers** (data containers)
> - **Channels** (connections)
> - **Selectors** (event multiplexing)

Perfect for **servers, file processing, real-time apps**.

---


### Tags : [[Java]]