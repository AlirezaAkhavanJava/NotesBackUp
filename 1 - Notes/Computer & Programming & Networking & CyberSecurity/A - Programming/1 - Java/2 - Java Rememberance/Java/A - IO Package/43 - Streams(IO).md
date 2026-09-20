## Java IO - Streams

**Java IO Streams** are a fundamental part of Java's input/output system that provide a way to read data from a source and write data to a destination. A stream represents a flow of data between your Java program and an external source/destination (like files, network connections, memory, etc.).

## Core Concept

A **stream** is an abstraction that represents a sequence of data elements made available over time. Think of it as a "pipe" through which data flows:
- **Input Stream**: Data flows **into** your program (reading)
- **Output Stream**: Data flows **out of** your program (writing)

## Types of Streams

### 1. **Byte Streams** (Handles raw binary data - 8-bit bytes)
- **Base classes**: `InputStream` and `OutputStream`
- Used for: Images, audio, video, PDFs, any binary data
- Examples: `FileInputStream`, `FileOutputStream`, `BufferedInputStream`

### 2. **Character Streams** (Handles text data - 16-bit Unicode characters)
- **Base classes**: `Reader` and `Writer`
- Used for: Text files, character data
- Examples: `FileReader`, `FileWriter`, `BufferedReader`

## Stream Hierarchy Overview

```
Byte Streams:
InputStream (abstract)
├── FileInputStream
├── ByteArrayInputStream
├── BufferedInputStream
├── DataInputStream
└── ObjectInputStream

OutputStream (abstract)
├── FileOutputStream
├── ByteArrayOutputStream
├── BufferedOutputStream
├── DataOutputStream
└── ObjectOutputStream

Character Streams:
Reader (abstract)
├── FileReader
├── BufferedReader
├── InputStreamReader
└── StringReader

Writer (abstract)
├── FileWriter
├── BufferedWriter
├── OutputStreamWriter
└── StringWriter
```

## Key Characteristics

| Feature | Description |
|---------|-------------|
| **Directional** | Streams are either input OR output, not both |
| **Sequential** | Data is read/written in order, one element at a time |
| **One-time** | Once consumed, data cannot be re-read (unless reset) |
| **Blocking** | I/O operations block until data is available |

## Common Operations

### Reading from a Stream:
```java
// Byte stream example
try (FileInputStream fis = new FileInputStream("file.txt")) {
    int data;
    while ((data = fis.read()) != -1) {
        System.out.print((char) data);
    }
}
```

### Writing to a Stream:
```java
// Character stream example
try (FileWriter fw = new FileWriter("output.txt")) {
    fw.write("Hello, World!");
}
```

## Stream Chaining/Decoration

Streams can be **wrapped** to add functionality:
```java
// Buffering + File reading
BufferedReader br = new BufferedReader(new FileReader("file.txt"));

// Data reading from file
DataInputStream dis = new DataInputStream(
    new BufferedInputStream(
        new FileInputStream("data.bin")
    )
);
```

## Important Distinction: Java IO vs Java 8 Streams

**Don't confuse** Java IO Streams with Java 8 Stream API:
- **Java IO Streams**: Handle I/O operations (files, network)
- **Java 8 Streams**: Handle collections processing (functional programming)

## Best Practices

1. **Always close streams** - Use try-with-resources
2. **Use buffered streams** for better performance
3. **Choose correct stream type** - byte vs character
4. **Handle exceptions** properly (IOException)
5. **Prefer NIO.2** (`java.nio.file`) for modern file operations

## Simple Example

```java
import java.io.*;

public class StreamExample {
    public static void main(String[] args) {
        // Writing to a file
        try (BufferedWriter writer = new BufferedWriter(
                new FileWriter("example.txt"))) {
            writer.write("Hello, Java IO Streams!");
        } catch (IOException e) {
            e.printStackTrace();
        }
        
        // Reading from a file
        try (BufferedReader reader = new BufferedReader(
                new FileReader("example.txt"))) {
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

## Summary

Java IO Streams provide a flexible, hierarchical mechanism for handling I/O operations. They abstract the complexity of reading/writing data from various sources, allowing you to focus on processing data rather than managing low-level I/O details.


[[Java]]