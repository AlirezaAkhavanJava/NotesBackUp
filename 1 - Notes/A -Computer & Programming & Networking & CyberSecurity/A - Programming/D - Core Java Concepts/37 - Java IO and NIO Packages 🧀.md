# Java I/O and NIO Packages (`java.io` and `java.nio`)

The **Java I/O** (`java.io`) and **Java NIO** (`java.nio` and its subpackages) packages provide APIs for input and output operations in Java. The `java.io` package offers stream-based, blocking I/O for reading and writing data, while `java.nio` (New I/O, introduced in Java 1.4) provides non-blocking, buffer-oriented I/O with advanced features for scalability and performance. These packages are essential for file operations, network communication, and data streaming.

## Overview

- **Purpose**:
    - `java.io`: Provides stream-based I/O for reading/writing data (e.g., files, network sockets) with a focus on simplicity.
    - `java.nio`: Offers non-blocking I/O, buffer management, and channels for high-performance, scalable I/O operations.
- **Key Features**:
    - **java.io**: Blocking, stream-based (byte or character), sequential access.
    - **java.nio**: Non-blocking, buffer-based, channel-oriented, supports selectors for multiplexing I/O operations.
- **Use Cases**: File reading/writing, network communication, serialization, and asynchronous I/O.


---

![[Pasted image 20251127065745.png]]

## 1. Java I/O Package (`java.io`)

### Key Interfaces

#### 1. **InputStream**

- **Purpose**: Abstract class for reading bytes from a source (e.g., files, network).
- **Key Methods**:
    - `int read()`: Reads a single byte, returns -1 at end of stream.
    - `int read(byte[] b)`: Reads bytes into an array.
    - `int read(byte[] b, int off, int len)`: Reads up to `len` bytes into an array starting at `off`.
    - `skip(long n)`: Skips `n` bytes.
    - `close()`: Closes the stream and releases resources.
- **Use Case**: Reading raw bytes from files or sockets.
- **Example**:

```java
try (InputStream is = new FileInputStream("file.txt")) {
    int byteRead;
    while ((byteRead = is.read()) != -1) {
        System.out.print((char) byteRead);
    }
}
```

#### 2. **OutputStream**

- **Purpose**: Abstract class for writing bytes to a destination.
- **Key Methods**:
    - `write(int b)`: Writes a single byte.
    - `write(byte[] b)`: Writes an array of bytes.
    - `write(byte[] b, int off, int len)`: Writes `len` bytes from an array starting at `off`.
    - `flush()`: Flushes buffered output.
    - `close()`: Closes the stream.
- **Use Case**: Writing data to files or network streams.
- **Example**:

```java
try (OutputStream os = new FileOutputStream("output.txt")) {
    os.write("Hello".getBytes());
}
```

- **`FileInputStream`** reads **raw bytes** (8-bit values). It doesn’t know anything about characters or encoding.  
    When you do `(char) bytesRead`, you’re _manually_ converting raw bytes to characters — which only works correctly for simple encodings like ASCII. For UTF-8 or Unicode text, it can break or print garbage.
    
- **`FileReader`** is a **character stream** — it automatically decodes bytes into characters **based on the file’s charset** (default system encoding or one you specify).  
    So when you call `reader.read()`, it’s already giving you _characters_, not raw bytes.

#### 3. **Reader**

- **Purpose**: Abstract class for reading character streams.
- **Key Methods**:
    - `int read()`: Reads a single character.
    - `int read(char[] cbuf)`: Reads characters into an array.
    - `skip(long n)`: Skips `n` characters.
    - `close()`: Closes the reader.
- **Use Case**: Reading text data with proper character encoding.
- **Example**:

```java
try (Reader reader = new FileReader("file.txt")) {
    int charRead;
    while ((charRead = reader.read()) != -1) {
        System.out.print((char) charRead);
    }
}
```

#### 4. **Writer**

- **Purpose**: Abstract class for writing character streams.
- **Key Methods**:
    - `write(int c)`: Writes a single character.
    - `write(char[] cbuf)`: Writes an array of characters.
    - `write(String str)`: Writes a string.
    - `append(CharSequence csq)`: Appends a sequence of characters.
    - `flush()`: Flushes the stream.
    - `close()`: Closes the writer.
- **Use Case**: Writing text data to files or streams.
- **Example**:

```java
try (Writer writer = new FileWriter("output.txt")) {
    writer.write("Hello");
}
```

#### 5. **Serializable**

- **Purpose**: Marker interface enabling objects to be serialized (converted to a byte stream) and deserialized.
- **Use Case**: Persisting objects to files or sending over a network.
- **Example**:

```java
class MyClass implements Serializable {
    private String data;
}
```

### Key Classes

#### 1. **FileInputStream** / **FileOutputStream**

- **Purpose**: Reads/writes bytes from/to files.
- **Use Case**: Binary file operations.
- **Example**:

```java
try (FileInputStream fis = new FileInputStream("input.bin")) {
    byte[] buffer = new byte[1024];
    int bytesRead = fis.read(buffer);
}
```

#### 2. **FileReader** / **FileWriter**

- **Purpose**: Reads/writes characters from/to files.
- **Use Case**: Text file operations.
- **Example**:

```java
try (FileWriter writer = new FileWriter("output.txt")) {
    writer.write("Hello, World!");
}
```

#### 3. **BufferedInputStream** / **BufferedOutputStream**

- **Purpose**: Buffers byte input/output to reduce underlying system calls, improving performance.
- **Use Case**: Efficient reading/writing of large data.
- **Example**:

```java
try (BufferedInputStream bis = new BufferedInputStream(new FileInputStream("file.txt"))) {
    int byteRead;
    while ((byteRead = bis.read()) != -1) {
        System.out.print((char) byteRead);
    }
}
```

#### 4. **BufferedReader** / **BufferedWriter**

- **Purpose**: Buffers character input/output for efficient text processing.
- **Key Methods (BufferedReader)**:
    - `readLine()`: Reads a line of text.
- **Use Case**: Reading/writing text files line by line.
- **Example**:

```java
try (BufferedReader reader = new BufferedReader(new FileReader("file.txt"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
}
```

#### 5. **ObjectInputStream** / **ObjectOutputStream**

- **Purpose**: Reads/writes serialized objects.
- **Key Methods**:
    - `readObject()`: Reads an object.
    - `writeObject(Object obj)`: Writes an object.
- **Use Case**: Object serialization/deserialization.
- **Example**:

```java
try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("obj.dat"))) {
    oos.writeObject(new MyClass());
}
```

### Utility Classes

#### 1. **File**

- **Purpose**: Represents file and directory paths, providing file system operations.
- **Key Methods**:
    - `createNewFile()`: Creates a new file.
    - `delete()`: Deletes a file or directory.
    - `listFiles()`: Lists files in a directory.
    - `mkdir()`: Creates a directory.
    - `length()`: Returns the file size in bytes.
- **Use Case**: File system manipulation.
- **Example**:

```java
File file = new File("example.txt");
file.createNewFile();
```

#### 2. **Files** (technically in `java.nio.file`, but often used with `java.io`)

- **Purpose**: Utility methods for file and directory operations.
- **Key Methods**: (Covered in NIO section below)

-----

>**[Java IO](https://www.geeksforgeeks.org/java/java-io-packag/)**(Input/Output) is used to perform read and write operations. The [java.io package](https://www.geeksforgeeks.org/java/java-io-packag/) contains all the classes required for input and output operation. Whereas, Java NIO (New IO) was introduced from JDK 4 to implement high-speed IO operations. It is an alternative to the standard IO API’s

## 2. Java NIO Package (`java.nio` and Subpackages)

The `java.nio` package and its subpackages (`java.nio.channels`, `java.nio.file`, etc.) provide non-blocking, buffer-oriented I/O with channels and selectors for scalability.

### Key Interfaces

#### 1. **Channel** (`java.nio.channels`)

- **Purpose**: Represents a connection to an I/O source (e.g., file, socket).
- **Subinterfaces**:
    - `ReadableByteChannel`: Reads bytes into a buffer.
    - `WritableByteChannel`: Writes bytes from a buffer.
    - `ScatteringByteChannel` / `GatheringByteChannel`: Reads/writes to/from multiple buffers.
- **Key Methods**:
    - `read(ByteBuffer dst)`: Reads data into a buffer.
    - `write(ByteBuffer src)`: Writes data from a buffer.
    - `close()`: Closes the channel.
- **Use Case**: Efficient data transfer for files or sockets.

#### 2. **SelectableChannel** (`java.nio.channels`)

- **Purpose**: A channel that supports non-blocking I/O and multiplexing with selectors.
- **Key Methods**:
    - `configureBlocking(boolean block)`: Sets blocking or non-blocking mode.
    - `register(Selector sel, int ops)`: Registers the channel with a selector.
- **Use Case**: Multiplexing multiple channels (e.g., in network servers).

#### 3. **Path** (`java.nio.file`)

- **Purpose**: Represents a file system path (replacement for `java.io.File`).
- **Key Methods**:
    - `getFileName()`: Returns the file name.
    - `getParent()`: Returns the parent directory.
    - `resolve(Path other)`: Resolves a path against this path.
    - `toFile()`: Converts to a `java.io.File`.
- **Use Case**: File system path manipulation.

### Key Classes

#### 1. **ByteBuffer** (`java.nio`)

- **Purpose**: A buffer for storing and manipulating bytes, used with channels.
- **Key Methods**:
    - `allocate(int capacity)`: Creates a buffer with the specified capacity.
    - `put(byte[] src)`: Writes bytes to the buffer.
    - `get()`: Reads bytes from the buffer.
    - `flip()`: Prepares the buffer for reading after writing.
    - `clear()`: Resets the buffer for reuse.
    - `position(int newPosition)`: Sets the buffer’s position.
- **Use Case**: Efficient data transfer between channels.
- **Example**:

```java
ByteBuffer buffer = ByteBuffer.allocate(1024);
buffer.put("Hello".getBytes());
buffer.flip();
while (buffer.hasRemaining()) {
    System.out.print((char) buffer.get());
}
```

#### 2. **FileChannel** (`java.nio.channels`)

- **Purpose**: A channel for reading/writing files.
- **Key Methods**:
    - `read(ByteBuffer dst)`: Reads data into a buffer.
    - `write(ByteBuffer src)`: Writes data from a buffer.
    - `transferTo(long position, long count, WritableByteChannel target)`: Transfers bytes to another channel.
- **Use Case**: High-performance file operations.
- **Example**:

```java
try (FileChannel channel = FileChannel.open(Paths.get("file.txt"), StandardOpenOption.READ)) {
    ByteBuffer buffer = ByteBuffer.allocate(1024);
    channel.read(buffer);
}
```

#### 3. **Selector** (`java.nio.channels`)

- **Purpose**: Multiplexes multiple channels for non-blocking I/O.
- **Key Methods**:
    - `open()`: Creates a selector.
    - `select()`: Blocks until at least one channel is ready.
    - `selectedKeys()`: Returns the set of ready channels.
- **Use Case**: Scalable network servers handling multiple connections.
- **Example**:

```java
Selector selector = Selector.open();
ServerSocketChannel channel = ServerSocketChannel.open();
channel.configureBlocking(false);
channel.register(selector, SelectionKey.OP_ACCEPT);
```

#### 4. **Paths** (`java.nio.file`)

- **Purpose**: Utility class for creating and manipulating `Path` objects.
- **Key Methods**:
    - `get(String first, String... more)`: Creates a `Path` from strings.
- **Use Case**: Simplifying path creation.

#### 5. **Files** (`java.nio.file`)

- **Purpose**: Utility class for file and directory operations.
- **Key Methods**:
    - `readAllBytes(Path path)`: Reads all bytes from a file.
    - `write(Path path, byte[] bytes, OpenOption... options)`: Writes bytes to a file.
    - `newBufferedReader(Path path, Charset cs)`: Creates a `BufferedReader` for a file.
    - `newBufferedWriter(Path path, Charset cs, OpenOption... options)`: Creates a `BufferedWriter`.
    - `copy(Path source, Path target, CopyOption... options)`: Copies a file.
    - `move(Path source, Path target, CopyOption... options)`: Moves a file.
    - `walk(Path start, FileVisitOption... options)`: Traverses a file tree.
- **Use Case**: Simplified file operations with modern APIs.
- **Example**:

```java
byte[] data = Files.readAllBytes(Paths.get("file.txt"));
Files.write(Paths.get("output.txt"), "Hello".getBytes());
```

### Utility Classes

#### 1. **Files** (`java.nio.file`)

- **Covered Above**: Provides static methods for file operations.

#### 2. **Paths** (`java.nio.file`)

- **Covered Above**: Creates `Path` objects.

#### 3. **StandardCharsets** (`java.nio.charset`)

- **Purpose**: Provides standard charset constants (e.g., UTF-8, US-ASCII).
- **Key Fields**:
    - `UTF_8`, `UTF_16`, `US_ASCII`, etc.
- **Use Case**: Specifying character encodings for text operations.
- **Example**:

```java
try (BufferedReader reader = Files.newBufferedReader(Paths.get("file.txt"), StandardCharsets.UTF_8)) {
    String line = reader.readLine();
}
```

## Example Combining I/O and NIO

```java
import java.io.*;
import java.nio.file.*;
import java.nio.channels.*;
import java.nio.ByteBuffer;

public class IOExample {
    public static void main(String[] args) throws IOException {
        // java.io: Write to a file using BufferedWriter
        try (BufferedWriter writer = new BufferedWriter(new FileWriter("output.txt"))) {
            writer.write("Hello, World!");
        }

        // java.nio: Read from a file using FileChannel
        try (FileChannel channel = FileChannel.open(Paths.get("output.txt"), StandardOpenOption.READ)) {
            ByteBuffer buffer = ByteBuffer.allocate(1024);
            channel.read(buffer);
            buffer.flip();
            System.out.println(new String(buffer.array(), 0, buffer.remaining()));
        }

        // java.nio.file: Copy a file
        Files.copy(Paths.get("output.txt"), Paths.get("copy.txt"), StandardCopyOption.REPLACE_EXISTING);
    }
}
```

## Benefits

- **java.io**:
    - Simple and intuitive for sequential I/O.
    - Wide range of stream and reader/writer classes.
    - Suitable for small-scale or text-based operations.
- **java.nio**:
    - High-performance, non-blocking I/O for scalability.
    - Buffer and channel abstractions optimize data transfer.
    - Advanced file operations with `Files` and `Path`.
- **Interoperability**: `java.nio.file` integrates with `java.io` (e.g., `Path.toFile()`).

## Limitations

- **java.io**:
    - Blocking I/O can be inefficient for high-concurrency scenarios.
    - Limited support for modern file system features.
- **java.nio**:
    - Steeper learning curve due to buffers and channels.
    - Non-blocking I/O requires careful design to handle readiness and selectors.
- **Complexity**: Combining I/O and NIO can lead to verbose code for simple tasks.

## Resources

- Oracle Documentation:
    - [java.io](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/io/package-summary.html)
    - [java.nio](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/nio/package-summary.html)
    - [java.nio.file](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/nio/file/package-summary.html)




##### Tags : [[Java Packages]]