## Java NIO Package Definition

**Java NIO (New Input/Output)** is a collection of Java programming language APIs that offer features for intensive I/O operations. Introduced in Java 1.4 (2002) under the `java.nio` package, it provides an alternative to the standard Java I/O API (`java.io`).

## Core Components

The Java NIO package consists of several key subpackages and components:

### 1. **Main Packages**
- `java.nio` - Core NIO functionality
- `java.nio.channels` - Channel and Selector APIs
- `java.nio.charset` - Character encoding/decoding
- `java.nio.file` - File system operations (added in Java 7)
- `java.nio.file.attribute` - File attribute access

### 2. **Key Abstractions**

#### **Channels**
- Bidirectional communication pipes (unlike streams)
- Can read and write simultaneously
- Examples: `FileChannel`, `SocketChannel`, `ServerSocketChannel`, `DatagramChannel`

#### **Buffers**
- Containers for data
- Work with channels for reading/writing
- Types: `ByteBuffer`, `CharBuffer`, `IntBuffer`, `FloatBuffer`, etc.

#### **Selectors**
- Enable single-threaded management of multiple channels
- Used for scalable network applications
- Non-blocking I/O operations

#### **Paths and Files**
- Modern file system API
- `Path` interface represents file system paths
- `Files` utility class for file operations

## Key Features

### **1. Non-blocking I/O**
```java
// Traditional I/O (blocking)
InputStream in = socket.getInputStream();
int data = in.read(); // Blocks until data available

// NIO (non-blocking)
SocketChannel channel = SocketChannel.open();
channel.configureBlocking(false);
int bytesRead = channel.read(buffer); // Returns immediately
```

### **2. Buffer-oriented**
```java
// NIO reads/writes through buffers
ByteBuffer buffer = ByteBuffer.allocate(1024);
channel.read(buffer);
buffer.flip(); // Switch from write to read mode
```

### **3. Selector-based multiplexing**
```java
Selector selector = Selector.open();
channel.register(selector, SelectionKey.OP_READ);
selector.select(); // Blocks until channels are ready
```

## Common Use Cases

1. **High-performance servers** - Handling thousands of connections
2. **File operations** - Memory-mapped files, file locking
3. **Network programming** - Scalable client/server applications
4. **Asynchronous I/O** - Non-blocking operations

## Example: Reading a File with NIO

```java
import java.nio.file.*;
import java.nio.channels.*;
import java.nio.ByteBuffer;

// Modern approach (Java 7+)
Path path = Paths.get("file.txt");
List<String> lines = Files.readAllLines(path);

// Traditional NIO approach
FileChannel channel = FileChannel.open(path);
ByteBuffer buffer = ByteBuffer.allocate(1024);
channel.read(buffer);
```

## NIO vs Traditional I/O

| Aspect | Traditional I/O | NIO |
|--------|----------------|-----|
| **Orientation** | Stream-oriented | Buffer-oriented |
| **Blocking** | Blocking | Non-blocking available |
| **Selectors** | Not available | Yes |
| **Performance** | Lower for many connections | Better scalability |
| **Complexity** | Simpler | More complex |

## NIO.2 (Java 7+)

Added significant enhancements:
- `java.nio.file` package
- Path API
- Asynchronous I/O (`AsynchronousFileChannel`, `AsynchronousSocketChannel`)
- WatchService for file system monitoring
- File attribute support

Java NIO is essential for building scalable, high-performance applications, particularly in server-side and network programming scenarios.
[[Java]]