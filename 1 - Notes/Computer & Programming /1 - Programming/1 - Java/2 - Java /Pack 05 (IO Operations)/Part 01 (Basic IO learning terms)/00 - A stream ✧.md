### What it is ? 

A stream really is a pipe between your program and some data source (or destination), and the best part is that your code doesn’t need to care what’s on the other end. A file, a network socket, a byte array in memory, the keyboard: they all look the same to you. You just read from it or write to it.

---
### Mental model : 

Think of the stream as the pipe itself rather than a go-between that makes decisions. Data flows through it in one direction: an `InputStream` brings data _into_ your program, an `OutputStream` carries data _out_. Because the pipe is one-way and sequential, you generally can’t jump around in it. You read byte after byte, in order. (That’s a real limitation, and it’s why ***RandomAccessFile***exists for when you need to ***jump to a position***.)

**Streams aren’t quite “the fast approach.”** They’re the _simple and uniform_ approach, which is a different thing. Plain streams can actually be slow if you use them naively, [^1]because reading one byte at a time means one trip to the disk or network per byte. That’s why Java lets you wrap streams in each other:

```java
try (InputStream in = new BufferedInputStream(new FileInputStream("data.txt"))) {
    int b;
    while ((b = in.read()) != -1) {
        // process the byte
    }
}
```

> Here `BufferedInputStream` grabs a big chunk at once and hands it to you a piece at a time, so you stop paying for a trip on every byte. This wrapping idea (pipes snapped onto pipes) is called the **decorator pattern**, and it’s the thing that makes Java’s I/O design feel flexible once it clicks. Each layer adds one ability: buffering, decompression, encryption, converting bytes to text.


---
### Byte Stream , Character Stream

The analogy breaks down in one place: a real pipe doesn’t care what’s flowing through it, but Java streams come in two families. **Byte streams** (`InputStream`/`OutputStream`) (8-bit bytes) move raw bytes, and **character streams** (`Reader`/`Writer`) (16-bit bytes) move text and handle encoding for you. Pick the wrong family for your data, say reading an image with a `Reader`, and you’ll corrupt it.

> In Java, there are two main I/O families:
> - Byte streams (InputStream, OutputStream): Handle raw binary data, such as images, PDFs, and audio files.
> - Character streams (Reader, Writer): Handle text data, converting bytes into characters using a character encoding.


---
### NIO is more powerful
[[07 - Java NIO]]
> NIO (java.nio), with channels and buffers, which is more powerful and can do non-blocking I/O, and there’s the convenient Files class (Files.readString(...), Files.readAllLines(...)) which is usually the easiest of all for small files. A good rule of thumb: use Files for quick whole-file jobs, streams when you’re processing data piece by piece, and NIO channels when you’re getting into high-performance or server territory. That last one is very much a “senior-level” topic, so it’ll matter for your Spring Boot journey later.

---
### Stream is not Stream API

Java I/O streams (`InputStream` and friends) are a completely different thing from the **Stream API** (`list.stream().filter(...)`), which processes collections. They share a name and nothing else, and mixing them up is a very common beginner trap.

---
 Java IO works at the byte level, and the smallest unit you can read or write directly is one byte (8 bits). There's no built-in way to read or write a single bit.

**The two families**

- **Byte streams** (`InputStream` / `OutputStream`) deal in raw bytes. `read()` hands you one byte, returned as an `int` from 0 to 255 (or -1 at the end of the stream).
- **Character streams** (`Reader` / `Writer`) deal in characters. Under the hood they still read bytes, but they decode them into text using a charset like UTF-8. That's why a single character can take more than one byte.

So even when you read text, the data underneath is still moving byte by byte. The `Reader` just does the decoding for you.

**Why not bits?**

Hardware, files, and network protocols all organize data in bytes, so that's the natural unit. Reading one bit at a time would also be painfully slow.

**What if you need individual bits?**

You read a byte and pick it apart yourself using bitwise operators:

```java
int b = in.read();              // one byte, e.g. 0b10110010
boolean thirdBit = (b & 0b100) != 0;   // check one bit
int highNibble = (b >> 4) & 0x0F;      // extract the top 4 bits
```

To write bits, you do the reverse: collect bits into a byte using shifts and `|`, then write that byte out. Compression and encoding formats (like Huffman coding) do exactly this, often wrapped in a small helper class such as a `BitInputStream` / `BitOutputStream`.

**One practical note:** reading a single byte per call is also slow, because each call can hit the disk or network. That's why we usually wrap streams in `BufferedInputStream` / `BufferedOutputStream`, or read into a `byte[]` array in chunks.

[[IO]]
[[Java]]

[^1]: The expensive part is not the disk itself. It’s the call into the operating system.
	
	When you call `read()` on a plain `FileInputStream`, Java has to leave your program and ask the operating system for that byte. That jump is called a _system call_, and it costs far more than normal Java code. Doing it millions of times adds up fast.
	
	The operating system is usually smarter than a physical disk trip per byte, though. It tends to load a whole block of the file into memory ahead of time, so most of your single-byte requests are answered from memory. The slowness comes from crossing into the OS over and over, not from the disk spinning each time. Network sockets work the same way: the OS collects incoming data, and your program picks it up in small bites.
