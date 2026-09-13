

**Java I/O** (`java.io` package) is Java's core library for reading and writing data — to files, memory, network connections, or between programs. It provides the classes that let a program move data in ("input") and out ("output").

### The two main hierarchies

Java I/O is built around streams, split into two families based on what they handle:

**1. Byte streams** — for raw binary data

```
InputStream (abstract)          OutputStream (abstract)
├── FileInputStream             ├── FileOutputStream
├── ObjectInputStream           ├── ObjectOutputStream
├── BufferedInputStream         ├── BufferedOutputStream
└── ...                         └── ...
```

**2. Character streams** — for text (handles character encoding like UTF-8)

```
Reader (abstract)               Writer (abstract)
├── FileReader                  ├── FileWriter
├── BufferedReader              ├── BufferedWriter
└── ...                         └── ...
```

### The "decorator" pattern

Java I/O classes are designed to **wrap** one another, adding functionality layer by layer:

```java
ObjectOutputStream out = new ObjectOutputStream(
    new BufferedOutputStream(
        new FileOutputStream("user.ser")
    )
);
```

Here:

- `FileOutputStream` → opens the raw connection to the file (byte stream)
- `BufferedOutputStream` → wraps it to add buffering (fewer slow disk writes)
- `ObjectOutputStream` → wraps that to add the ability to write whole Java objects

Each layer adds a capability without changing the one underneath.

### How it connects to what we discussed

- **Byte stream** = the _category_ of I/O class (from `InputStream`/`OutputStream`)
- **Serialization** = a specific _use_ of byte streams — `ObjectOutputStream`/`ObjectInputStream` are byte stream classes specialized for converting objects to/from bytes

So the relationship is:

```
Java I/O (the whole framework)
   └── Byte Streams (InputStream/OutputStream family)
          └── ObjectOutputStream/ObjectInputStream (used for serialization)
```

### Modern alternative: java.nio

Since Java 7, there's also `java.nio` ("New I/O"), which offers non-blocking, buffer-based I/O and is generally faster for large files or many concurrent connections. Classes like `Files.readAllBytes()` or `Files.newInputStream()` are common in modern code:

```java
byte[] data = Files.readAllBytes(Paths.get("user.ser"));
```

### Where this shows up in Spring Boot

You'll rarely touch `java.io` streams directly in Spring Boot — Spring abstracts most of it (e.g., `MultipartFile` for uploads, `Resource` for reading files/classpath resources). But understanding these fundamentals helps when you're debugging file handling, working with `InputStreamResource`, or configuring things like `MultipartFile.getInputStream()`.

[[Java]]