

A **byte stream** is a sequence of raw bytes (8-bit units) used to read or write data — as opposed to characters/text.

### Why it matters

Computers ultimately store and transmit everything as bytes — whether it's a text file, an image, a serialized object, or a network packet. A byte stream is the low-level channel for moving that raw binary data in or out of a program.

### Byte streams vs character streams (Java-specific)

Java's I/O library has two parallel hierarchies:

||Byte Stream|Character Stream|
|---|---|---|
|Base classes|`InputStream` / `OutputStream`|`Reader` / `Writer`|
|Works with|raw bytes (`byte[]`)|characters (text, handles encoding like UTF-8)|
|Used for|images, audio, serialized objects, any binary data|text files, strings|

**Byte stream example:**

```java
FileInputStream in = new FileInputStream("photo.jpg");
int data = in.read(); // reads one byte at a time
```

**Character stream example:**

```java
FileReader reader = new FileReader("notes.txt");
int ch = reader.read(); // reads one character at a time, handles encoding
```

### Connection to serialization

When you serialize an object with `ObjectOutputStream`, it converts the object into a **byte stream** — that's literally what `writeObject()` produces. That's why `ObjectOutputStream` extends `OutputStream`, not `Writer`: serialized data is binary, not text.

```java
ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream("user.ser"));
```

`FileOutputStream` is the byte stream that writes to `user.ser`; `ObjectOutputStream` wraps it to add the ability to write whole objects instead of raw bytes one at a time.


[[Java]]