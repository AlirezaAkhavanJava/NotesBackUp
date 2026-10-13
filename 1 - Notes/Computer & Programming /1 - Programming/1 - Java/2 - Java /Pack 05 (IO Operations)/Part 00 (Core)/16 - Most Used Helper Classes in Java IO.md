

Java I/O is organized into two main packages: **`java.io`** (classic I/O) and **`java.nio`** (New I/O, since Java 7). Below are the most commonly used helper classes, grouped by purpose.

---

## 1. File & Path Abstraction

| Class | Package | Purpose |
|---|---|---|
| **`File`** | `java.io` | Represents file/directory path; create, delete, inspect |
| **`Path`** | `java.nio.file` | Modern interface representing a file path (replaces `File` for path ops) |
| **`Paths`** | `java.nio.file` | Factory class: `Paths.get("a/b.txt")` → `Path` |
| **`Files`** | `java.nio.file` | Static utility class: copy, move, delete, read, write, check attributes |

### Example — `Files` utility (most used)

```java
Path p = Paths.get("data.txt");

Files.exists(p);                          // check existence
Files.createFile(p);                      // create
Files.createDirectories(Paths.get("a/b"));// create nested dirs
Files.copy(p, Paths.get("copy.txt"));     // copy
Files.move(p, Paths.get("moved.txt"));    // move/rename
Files.delete(p);                          // delete
Files.deleteIfExists(p);                  // safe delete

// Read/write entire file (great for small files)
List<String> lines = Files.readAllLines(p);
Files.write(p, lines);
String content = Files.readString(p);     // Java 11+
Files.writeString(p, "Hello");            // Java 11+

// Attributes
long size = Files.size(p);
boolean isDir = Files.isDirectory(p);
```

---

## 2. Byte Streams (Binary Data)

| Class | Purpose |
|---|---|
| **`InputStream`** | Abstract base for reading bytes |
| **`OutputStream`** | Abstract base for writing bytes |
| **`FileInputStream`** | Read bytes from a file |
| **`FileOutputStream`** | Write bytes to a file |
| **`ByteArrayInputStream`** | Read from a byte array |
| **`ByteArrayOutputStream`** | Write to an in-memory byte array |
| **`BufferedInputStream`** | Adds buffering (faster reads) |
| **`BufferedOutputStream`** | Adds buffering (faster writes) |
| **`DataInputStream`** | Read primitives (`int`, `double`, `boolean`...) |
| **`DataOutputStream`** | Write primitives |
| **`ObjectInputStream`** | Deserialize objects |
| **`ObjectOutputStream`** | Serialize objects |
| **`PrintStream`** | Print formatted text (`System.out` is one) |

### Example — Buffered byte copy

```java
try (InputStream in = new BufferedInputStream(new FileInputStream("in.jpg"));
     OutputStream out = new BufferedOutputStream(new FileOutputStream("out.jpg"))) {
    byte[] buf = new byte[8192];
    int n;
    while ((n = in.read(buf)) != -1) {
        out.write(buf, 0, n);
    }
}
```

---

## 3. Character Streams (Text Data)

| Class | Purpose |
|---|---|
| **`Reader`** | Abstract base for reading characters |
| **`Writer`** | Abstract base for writing characters |
| **`FileReader`** | Read characters from a file |
| **`FileWriter`** | Write characters to a file |
| **`BufferedReader`** | Buffered reading + `readLine()` |
| **`BufferedWriter`** | Buffered writing + `newLine()` |
| **`InputStreamReader`** | Bridge: bytes → characters (with charset) |
| **`OutputStreamWriter`** | Bridge: characters → bytes |
| **`PrintWriter`** | Formatted text output (`println`, `printf`) |
| **`StringReader` / `StringWriter`** | In-memory character streams |
| **`CharArrayReader` / `CharArrayWriter`** | Char-array streams |

### Example — Line-by-line reading

```java
try (BufferedReader br = new BufferedReader(new FileReader("input.txt"))) {
    String line;
    while ((line = br.readLine()) != null) {
        System.out.println(line);
    }
}
```

### Example — PrintWriter

```java
try (PrintWriter pw = new PrintWriter(new FileWriter("out.txt"))) {
    pw.println("Hello");
    pw.printf("Value: %d%n", 42);
}
```

---

## 4. Scanner & Formatting

| Class | Purpose |
|---|---|
| **`Scanner`** | Parse primitives/strings from any input (file, console, string) |
| **`Formatter`** | printf-style formatting to any Appendable |
| **`StringTokenizer`** | Legacy tokenizer (prefer `String.split`) |

### Example — Scanner

```java
try (Scanner sc = new Scanner(new File("nums.txt"))) {
    while (sc.hasNextInt()) {
        System.out.println(sc.nextInt());
    }
}
```

---

## 5. Random Access & Serialization

| Class | Purpose |
|---|---|
| **`RandomAccessFile`** | Read/write at arbitrary positions (seek) |
| **`Serializable`** | Marker interface for object serialization |
| **`Externalizable`** | Custom serialization control |
| **`ObjectInputStream` / `ObjectOutputStream`** | Serialize/deserialize objects |

### Example — RandomAccessFile

```java
try (RandomAccessFile raf = new RandomAccessFile("data.bin", "rw")) {
    raf.seek(100);            // jump to byte 100
    raf.writeInt(42);
    raf.seek(100);
    int val = raf.readInt();  // 42
}
```

---

## 6. NIO.2 — Channels & Buffers

| Class | Purpose |
|---|---|
| **`FileChannel`** | Read/write file via channels (fast, supports locks, mmap) |
| **`ByteBuffer`** | Container for channel I/O |
| **`CharBuffer`, `IntBuffer`...** | Typed buffers |
| **`Selector`** | Multiplex multiple channels (networking) |
| **`WatchService`** | Watch directory for changes |

### Example — FileChannel copy

```java
try (FileChannel in = FileChannel.open(Paths.get("in.txt"), StandardOpenOption.READ);
     FileChannel out = FileChannel.open(Paths.get("out.txt"),
            StandardOpenOption.CREATE, StandardOpenOption.WRITE)) {
    in.transferTo(0, in.size(), out);
}
```

---

## 7. Special-Purpose Helpers

| Class | Purpose |
|---|---|
| **`PipedInputStream` / `PipedOutputStream`** | Communicate between threads |
| **`SequenceInputStream`** | Concatenate multiple input streams |
| **`PushbackInputStream` / `PushbackReader`** | Unread bytes/chars |
| **`StreamTokenizer`** | Parse tokens from a stream |
| **`Console`** | Read from system console (`System.console()`) |
| **`Properties`** | Load/store key-value config files |
| **`ZipInputStream` / `ZipOutputStream`** | Read/write ZIP archives |
| **`GZIPInputStream` / `GZIPOutputStream`** | GZIP compression |

### Example — Properties

```java
Properties props = new Properties();
try (InputStream in = Files.newInputStream(Paths.get("app.properties"))) {
    props.load(in);
}
String url = props.getProperty("db.url", "localhost");
```

---

## 8. Quick Decision Guide

| Task | Recommended Class |
|---|---|
| Read a small text file | `Files.readString()` / `Files.readAllLines()` |
| Read a large text file | `BufferedReader` + `FileReader` |
| Write text | `BufferedWriter` / `PrintWriter` / `Files.writeString()` |
| Copy binary file | `Files.copy()` or `BufferedInputStream` + `BufferedOutputStream` |
| Parse structured input | `Scanner` |
| Read/write primitives | `DataInputStream` / `DataOutputStream` |
| Save/load objects | `ObjectInputStream` / `ObjectOutputStream` |
| Random access | `RandomAccessFile` or `FileChannel` |
| Config file | `Properties` |
| Modern path ops | `Path`, `Paths`, `Files` |

---

## Key Takeaways

1. **Prefer NIO.2 (`Path`, `Files`)** for file operations — cleaner, more feature-rich, and better error handling than `File`.
2. **Always wrap streams with `Buffered*`** for performance when doing many small reads/writes.
3. **Use try-with-resources** — all these classes implement `AutoCloseable`.
4. **Character streams for text**, **byte streams for binary** — bridge with `InputStreamReader`/`OutputStreamWriter` and always specify a charset.
5. **`Scanner` and `Properties`** are the go-to helpers for parsing and configuration.

[[Java]]