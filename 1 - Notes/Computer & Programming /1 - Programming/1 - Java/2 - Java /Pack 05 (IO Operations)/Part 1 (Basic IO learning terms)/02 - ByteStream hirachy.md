Here's an hierarchy for Java ByteStreams:

```
                          InputStream
                               |
        ┌──────────────────────┼──────────────────────┐
        |                      |                      |
   ByteArrayInputStream   FileInputStream    FilterInputStream
        |                      |                      |
        |                      |        ┌─────────────┼─────────────┐
        |                      |        |             |             |
        |                      |  BufferedInputStream  DataInputStream
        |                      |        |
        |                      |  PushbackInputStream
        |                      |
        |                 ObjectInputStream
        |                      |
        |              SequenceInputStream
        |
   PipedInputStream

                          OutputStream
                               |
        ┌──────────────────────┼──────────────────────┐
        |                      |                      |
  ByteArrayOutputStream  FileOutputStream   FilterOutputStream
        |                      |                      |
        |                      |        ┌─────────────┼─────────────┐
        |                      |        |             |             |
        |                      |  BufferedOutputStream DataOutputStream
        |                      |        |
        |                      |  PrintStream
        |                      |
        |                 ObjectOutputStream
        |
   PipedOutputStream
```

**Key Points:**

- **InputStream/OutputStream**: Abstract base classes for all byte streams
- **FileInputStream/FileOutputStream**: Read/write bytes from/to files
- **ByteArrayInputStream/ByteArrayOutputStream**: Read/write from byte arrays in memory
- **BufferedInputStream/BufferedOutputStream**: Add buffering for efficiency
- **DataInputStream/DataOutputStream**: Read/write primitive Java data types
- **ObjectInputStream/ObjectOutputStream**: Serialize/deserialize Java objects
- **PrintStream**: Convenient printing methods (System.out is a PrintStream)
- **PipedInputStream/PipedOutputStream**: Communication between threads
- **SequenceInputStream**: Concatenate multiple input streams
- **PushbackInputStream**: Allows reading and "unreading" bytes
- **FilterInputStream/FilterOutputStream**: Base classes for decorator streams

**Common Decorator Pattern Usage:**
```java
// Example: Buffered + Data stream
DataInputStream dis = new DataInputStream(
    new BufferedInputStream(
        new FileInputStream("data.bin")
    )
);
```

This hierarchy shows how Java's byte stream classes are organized, with the decorator pattern allowing streams to be layered for added functionality.

---
Here's an ASCII diagram showing the **helper classes** associated with Java ByteStreams (the classes that support, wrap, or work alongside the core stream classes):

```
                    ┌─────────────────────────────────────┐
                    │     HELPER CLASSES FOR BYTE STREAMS │
                    └─────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                          File System Helpers                         │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   File              - Abstract pathname representation               │
│   Files             - Static utility methods (NIO.2)                 │
│   Paths             - Factory for Path objects                       │
│   Path              - File system path (NIO.2)                       │
│   FileDescriptor    - Handle to open file/handle                     │
│   RandomAccessFile  - Read/write at any position (not a stream)      │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                       Encoding / Charset Helpers                     │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Charset           - Named character encoding (UTF-8, etc.)         │
│   CharsetDecoder    - Bytes → Characters                             │
│   CharsetEncoder    - Characters → Bytes                             │
│   StandardCharsets  - Predefined charset constants                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    Bridge Helpers (Byte ↔ Char)                      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   InputStreamReader    - InputStream  → Reader  (bytes → chars)      │
│   OutputStreamWriter   - OutputStream → Writer  (chars → bytes)      │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                          NIO Buffer Helpers                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ByteBuffer        - Buffer for byte data (NIO)                     │
│   Channels          - Utility for channel/stream conversions         │
│   ReadableByteChannel / WritableByteChannel                          │
│   FileChannel       - Channel-based file I/O                         │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    Exception / Error Helpers                         │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IOException           - Base checked I/O exception                 │
│   FileNotFoundException - File doesn't exist / can't open            │
│   EOFException          - Unexpected end of stream                   │
│   InterruptedIOException - I/O interrupted (e.g., timeout)           │
│   UncheckedIOException  - Wraps IOException (for lambdas)            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                      Utility / Convenience Helpers                   │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   System.in / System.out / System.err  - Predefined streams          │
│   IOUtils (Apache Commons)             - read/write/copy helpers     │
│   ByteStreams (Guava)                  - Static stream utilities     │
│   Files.copy / Files.newInputStream    - NIO.2 convenience methods   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Categorised quick reference:**

| Category | Helper Classes |
|----------|---------------|
| **File handling** | `File`, `Files`, `Path`, `Paths`, `FileDescriptor`, `RandomAccessFile` |
| **Encoding** | `Charset`, `CharsetDecoder`, `CharsetEncoder`, `StandardCharsets` |
| **Byte↔Char bridges** | `InputStreamReader`, `OutputStreamWriter` |
| **NIO buffers/channels** | `ByteBuffer`, `FileChannel`, `Channels` |
| **Exceptions** | `IOException`, `FileNotFoundException`, `EOFException`, `UncheckedIOException` |
| **Global streams** | `System.in`, `System.out`, `System.err` |
| **Third-party utilities** | `IOUtils` (Commons IO), `ByteStreams` (Guava) |

**Common patterns you'll see:**

```java
// Files helper (NIO.2)
try (InputStream in = Files.newInputStream(Paths.get("file.bin"))) { ... }

// Byte ↔ Char bridge
BufferedReader reader = new BufferedReader(
    new InputStreamReader(new FileInputStream("file.txt"), StandardCharsets.UTF_8)
);

// Guava helper
byte[] data = ByteStreams.toByteArray(inputStream);

// Commons IO helper
IOUtils.copy(inputStream, outputStream);
```

These helpers don't extend `InputStream`/`OutputStream` themselves — they exist to **support**, **convert**, **wrap**, or **simplify** working with byte streams.

[[IO]]
[[Java]]