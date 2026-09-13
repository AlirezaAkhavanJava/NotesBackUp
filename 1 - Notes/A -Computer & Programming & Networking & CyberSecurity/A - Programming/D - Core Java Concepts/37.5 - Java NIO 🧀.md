
#### We use **Java NIO** for the following two main reasons:

1. **Non-blocking IO operation:** Java NIO performs non-blocking IO operations. This means that it reads the data whichever is ready. For instance, a thread can ask a channel to read the data from a buffer and the thread can go for other work during that period and continue again from the previous point where it has left. In the meantime, the reading operation is complete which increases the overall efficiency.

2. **Buffer oriented approach:** Java NIO's buffer oriented approach allows us to move forth and back in the buffer as we need. The data is read into a buffer and cached there. Whenever the data is required, it is further processed from the buffer.


| Feature         | **Java I/O**                                         | **Java NIO**                                                                 |
| --------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------- |
| **Model**       | Stream-oriented (one byte or char at a time)         | Buffer-oriented (data moves to/from buffers)                                 |
| **Blocking**    | Blocking I/O — each read/write waits until done      | Non-blocking I/O — threads can continue while waiting                        |
| **Channels**    | Not used                                             | Uses `Channel` for faster data transfer                                      |
| **Buffers**     | Uses streams directly                                | Uses `Buffer` (e.g. `ByteBuffer`, `CharBuffer`) to store data                |
| **Selectors**   | Not supported                                        | `Selector` allows one thread to monitor multiple channels (good for servers) |
| **Performance** | Simpler but slower for large-scale or concurrent I/O | Faster and scalable (used in servers, networking, etc.)                      |
| **When to use** | Small/simple apps, file read/write                   | High-performance, scalable apps (servers, chat apps, etc.)                   |

---

## **Buffer**


## What is a Buffer?

> A **Buffer** is a **block of memory** that stores data _temporarily_ while it’s being moved between your program and a channel (like a file or socket).

Think of it like a **storage box** that holds bytes before you use them or send them out.



##  Why Buffers?

In old `java.io`, you read/write **one byte at a time** via streams — slow and blocking.  
With NIO, you use **buffers** to read/write _chunks_ of data at once — faster and more flexible.



##  How it works

```
[File / Socket / Channel]  ⇄  [Buffer]  ⇄  [Your Code]
```

1. **Read**: Channel → Buffer → You process
    
2. **Write**: You fill Buffer → Channel writes it out
    



##  Main Buffer Types

All are subclasses of `java.nio.Buffer`.

|Type|Data stored|
|---|---|
|`ByteBuffer`|bytes (most common)|
|`CharBuffer`|chars|
|`IntBuffer`|ints|
|`FloatBuffer`|floats|
|`DoubleBuffer`|doubles|
|`LongBuffer`|longs|
|`ShortBuffer`|shorts|

> Usually you’ll just use **`ByteBuffer`**, since all I/O data is bytes anyway.



##  Key Buffer Properties

|Property|Meaning|
|---|---|
|`capacity`|Total size of the buffer (fixed at creation)|
|`position`|Where the next read/write happens|
|`limit`|How much data is “active” (can be read or written)|
|`mark()`|Saves a position so you can go back later|



##  Important Buffer Methods

|Method|Purpose|
|---|---|
|`put()`|Write data into buffer|
|`get()`|Read data from buffer|
|`flip()`|Switch from _writing mode_ → _reading mode_|
|`clear()`|Prepare buffer for new data (doesn’t erase it)|
|`rewind()`|Re-read data from start|
|`remaining()`|How much can still be read/written|



## Example

```java
ByteBuffer buffer = ByteBuffer.allocate(10); // capacity = 10 bytes

buffer.put((byte) 'A');
buffer.put((byte) 'B');

buffer.flip(); // switch to read mode

while (buffer.hasRemaining()) {
    System.out.print((char) buffer.get());
}
```

**Output:**

```
AB
```

 Explanation:

- `put()` stores bytes.
    
- `flip()` sets limit = current position, position = 0.
    
- `get()` reads bytes until position == limit.
    



##  Direct Buffers

You can allocate in **normal Java heap** or **off-heap (Direct)** memory:

```java
ByteBuffer direct = ByteBuffer.allocateDirect(1024);
```

Direct buffers:

- Faster for I/O (used by OS directly).
    
- Harder to manage (no garbage collector help).
    



##  Summary

|Concept|Description|
|---|---|
|Buffer|Temporary memory to hold data|
|Mode|Write mode (put) → flip() → Read mode (get)|
|Common type|`ByteBuffer`|
|Advanced|Direct buffers for performance|

---
## **Channel**

A **Channel** in Java NIO is basically a **connection to a data source or destination** — like a file, socket, or network — that lets you **read or write data through Buffers**.

### Simple definition:

> A **Channel** is like a two-way pipe between your program and the outside world.

Unlike old `InputStream` or `OutputStream`, which can only go one direction at a time, most channels are **bidirectional** — they can both read and write.

### How it works

```
[ File / Socket / Device ]
            ↑
         Channel
            ↓
         Buffer
            ↓
        Your code
```

The **Channel** moves bytes between the file/network and the **Buffer** — not directly to your code.


### Common Channel types

| Channel Type              | Used For                         |
| ------------------------- | -------------------------------- |
| `FileChannel`             | File I/O (read/write files)      |
| `SocketChannel`           | TCP client connections           |
| `ServerSocketChannel`     | TCP servers (accept connections) |
| `DatagramChannel`         | UDP communication                |
| `AsynchronousFileChannel` | Async file I/O (NIO.2)           |


###  Example

```java
FileChannel channel = FileChannel.open(Path.of("data.txt"));
ByteBuffer buffer = ByteBuffer.allocate(1024);
channel.read(buffer);
buffer.flip();
System.out.println(new String(buffer.array(), 0, buffer.limit()));
channel.close();
```

Here:

- `FileChannel` = the pipe to `data.txt`
    
- `Buffer` = temporary memory for data
    
- Your code = processes what’s inside the buffer
    


###  Key points

- Channels can **read/write simultaneously** (unlike streams).
    
- They work with **buffers**, not directly with bytes/chars.
    
- Some can be **non-blocking** (e.g., `SocketChannel`).
    
- They’re **faster** and **closer to the OS level** than streams.
    


**In short:**

> A **Channel** is a high-performance, bidirectional data pipeline between your Java program and something external — files, sockets, or network connections.

---


## **Selector**

A **Selector** in Java NIO is an object that lets **one thread handle multiple channels** (like sockets) efficiently.

### Key idea

Normally, each socket connection blocks a thread while waiting for data.  
With a selector, one thread can **watch many channels** and get notified when any of them is ready for I/O (read, write, accept, or connect).

### How it works

1. Channels are set to **non-blocking** mode.
    
2. Each channel is **registered** with the selector for certain operations (like `OP_READ`).
    
3. The selector **waits** until one or more channels are ready.
    
4. When a channel is ready, the selector tells you which one — then you handle it.
    

### Benefits

- Uses fewer threads and less memory.
    
- Ideal for **servers** that handle many clients (like chat or HTTP servers).
    
- Avoids blocking and thread-per-client overhead.
    

### Analogy

Think of a selector as a **security guard** watching many doors (channels).  
When any door has activity (data ready, connection incoming), the guard alerts you — you don’t waste time checking every door constantly.

### 1. What a Selector does

A **Selector** monitors many channels and tells you _which ones are ready_ for I/O (read, write, connect, accept).  
Instead of one thread per connection, one thread can handle hundreds of channels.



### 2. How it works conceptually

```
Thread → Selector → multiple Channels
```

- You register channels with the selector.
    
- The selector waits (using `select()`).
    
- When a channel is ready (e.g., new client or incoming data), you handle it.
    



### 3. Key classes and methods

|Component|Role|
|---|---|
|`Selector.open()`|Creates a new selector|
|`channel.configureBlocking(false)`|Required for non-blocking mode|
|`channel.register(selector, ops)`|Registers channel for operations (e.g. `OP_READ`, `OP_WRITE`, `OP_ACCEPT`)|
|`selector.select()`|Blocks until something is ready|
|`selector.selectedKeys()`|Returns the ready channels|



### 4. Example: simple server

```java
import java.net.*;
import java.nio.*;
import java.nio.channels.*;
import java.util.*;

public class SelectorDemo {
    public static void main(String[] args) throws Exception {
        Selector selector = Selector.open();
        ServerSocketChannel server = ServerSocketChannel.open();
        server.bind(new InetSocketAddress(5000));
        server.configureBlocking(false);
        server.register(selector, SelectionKey.OP_ACCEPT);

        System.out.println("Server started...");

        while (true) {
            selector.select();
            Set<SelectionKey> keys = selector.selectedKeys();
            Iterator<SelectionKey> it = keys.iterator();

            while (it.hasNext()) {
                SelectionKey key = it.next();
                it.remove();

                if (key.isAcceptable()) {
                    SocketChannel client = server.accept();
                    client.configureBlocking(false);
                    client.register(selector, SelectionKey.OP_READ);
                    System.out.println("New client connected");
                }

                if (key.isReadable()) {
                    SocketChannel client = (SocketChannel) key.channel();
                    ByteBuffer buffer = ByteBuffer.allocate(256);
                    int read = client.read(buffer);
                    if (read == -1) client.close();
                    else {
                        buffer.flip();
                        System.out.println("Received: " + new String(buffer.array(), 0, buffer.limit()));
                    }
                }
            }
        }
    }
}
```



### 5. Key points

- **Non-blocking mode is mandatory.**
    
- A single thread can handle thousands of channels efficiently.
    
- Great for chat servers, games, proxies, or any high-traffic network app.
    



### 6. Typical operations

|Constant|Meaning|
|---|---|
|`OP_ACCEPT`|Ready to accept a new connection|
|`OP_CONNECT`|Connection established|
|`OP_READ`|Ready to read data|
|`OP_WRITE`|Ready to write data|

---



## 1. **Files & Paths (NIO.2 – Most Common Day-to-Day Use)**

**Package:** `java.nio.file`

**Classes:** `Path`, `Files`, `FileSystems`

### How it’s used

- Replaces `java.io.File` with more modern, flexible API.
    
- Handles reading/writing files, directories, and metadata.
    
- Supports **walking directories**, **moving/copying files**, **checking attributes**, etc.
    

### Example

```java
Path path = Path.of("example.txt");
Files.writeString(path, "Hello NIO!");
String content = Files.readString(path);
```

### Scenarios

- Reading/writing configuration or log files.
    
- Traversing directories to process multiple files (e.g., batch image processing).
    
- Checking file attributes (size, permissions) in server or desktop apps.
    

> **Why it’s common:** Almost every backend or desktop app deals with files, and this API is simpler, safer, and faster than old `File`/`FileInputStream`.

---

## 2. **Buffers & Channels (Core NIO – Common in Networking/Performance Tasks)**

**Packages:** `java.nio`, `java.nio.channels`

**Key Classes:** `ByteBuffer`, `FileChannel`, `SocketChannel`, `ServerSocketChannel`

### How it’s used

- `Buffer` = temporary memory for read/write operations.
    
- `Channel` = connection to file, socket, or device.
    
- All read/write happens **through buffers**, not directly.
    

### Example

```java
FileChannel channel = FileChannel.open(Path.of("data.txt"));
ByteBuffer buffer = ByteBuffer.allocate(1024);
channel.read(buffer);
buffer.flip();
System.out.println(new String(buffer.array(), 0, buffer.limit()));
channel.close();
```

### Scenarios

- Efficient reading/writing large files.
    
- Network communication using TCP sockets.
    
- Situations requiring **manual memory control** or **high performance**.
    

> **Common in day-to-day job:** Reading/writing large files, logging, or network services. Most developers deal with `FileChannel` + `ByteBuffer` regularly.

---

## 3. **Selectors (Intermediate – Networking / Server-Side Apps)**

**Package:** `java.nio.channels`

**Classes:** `Selector`, `SelectionKey`

### How it’s used

- Allows **one thread to manage many channels**.
    
- Channels must be **non-blocking**.
    
- Selector alerts which channels are ready for `READ`, `WRITE`, `ACCEPT`, or `CONNECT`.
    

### Example Scenario

- A chat server handling hundreds of clients with **one thread**.
    
- A high-performance HTTP server that avoids thread-per-connection overhead.
    

### Typical pattern

1. Open a `Selector`.
    
2. Configure channels to non-blocking mode.
    
3. Register channels with operations of interest.
    
4. Loop: `selector.select()` → check ready channels → handle I/O.
    

> **Why used in real jobs:** For scalable server-side apps (network-heavy) where threads are expensive.

---

## 4. **Asynchronous Channels (Advanced – High-Performance / Non-Blocking I/O)**

**Package:** `java.nio.channels`

**Classes:** `AsynchronousFileChannel`, `AsynchronousSocketChannel`

### How it’s used

- Non-blocking I/O with **callback handlers** (`CompletionHandler`).
    
- Ideal for **high-throughput servers** or **file I/O without blocking threads**.
    

### Example Scenario

- File upload service handling thousands of concurrent uploads.
    
- Non-blocking socket communication in a real-time multiplayer game.
    

### Why this is advanced

- Requires event-driven programming.
    
- Less intuitive than synchronous I/O.
    

---

## 5. **Memory-Mapped Files (Advanced – Very High Performance)**

**Class:** `FileChannel.map()`

### How it’s used

- Maps file contents directly into memory.
    
- Access large files like in-memory arrays.
    

### Example Scenario

- Processing **multi-GB log files** or **large datasets** efficiently.
    
- Used in performance-critical applications (finance, game engines, big data).
    

---

## ✅ Summary of Usage by Frequency in Jobs

|Use Case|Package / Classes|When to Use|
|---|---|---|
|File handling / configuration / logs|`java.nio.file.Path`, `Files`|Daily backend, desktop, utility scripts|
|Reading/writing large files|`FileChannel`, `ByteBuffer`|Medium/high I/O tasks|
|Networking servers (multiple clients)|`Selector`, `SocketChannel`|Scalable servers, chat, proxy, TCP apps|
|Async I/O|`AsynchronousFileChannel`, `AsynchronousSocketChannel`|High-throughput, non-blocking services|
|Memory-mapped files|`FileChannel.map()`|Huge datasets, high-performance tasks|

---

### Tags : [[Java]]