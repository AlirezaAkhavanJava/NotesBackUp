


## Definition

A **byte stream** is the branch of Java I/O (`java.io`) built specifically to read and write **raw bytes (8-bit units)** — as opposed to the **character stream** branch (`Reader`/`Writer`), which reads and writes text with character-encoding awareness.

"Byte stream" isn't one class — it's the name for the entire family of classes rooted at `InputStream` (reading) and `OutputStream` (writing), which we've already been using throughout this conversation (`FileInputStream`, `FileOutputStream`, `ObjectOutputStream`, `System.in`/`System.out`, etc.).

```
Byte Stream family
├── InputStream   (abstract — reading bytes IN)
└── OutputStream  (abstract — writing bytes OUT)
```

---

## The problem it solves

Computers ultimately store and transmit **everything** as bytes — text, images, audio, serialized objects, network packets. But not everything is _text_. An image file has no "characters" in it; a serialized object has no meaningful character encoding at all — it's just structured binary data.

If Java only had text-based I/O, you'd have no correct way to read/write:

- Images, audio, video files
- Compiled binaries, ZIP files
- Serialized Java objects (`ObjectOutputStream`)
- Any raw network data that isn't text

**Byte streams solve this by working at the lowest common level — raw bytes — with zero assumptions about meaning or encoding.** This makes them universal: they can move _any_ kind of data, because they never try to interpret it as text.

---

## The abstract base classes

```java
public abstract class InputStream {
    public abstract int read() throws IOException;     // reads ONE byte (0–255), or -1 at end
    public int read(byte[] b) throws IOException;        // reads MANY bytes into a buffer
    public void close() throws IOException;
}

public abstract class OutputStream {
    public abstract void write(int b) throws IOException; // writes ONE byte
    public void write(byte[] b) throws IOException;         // writes MANY bytes
    public void close() throws IOException;
}
```

These are **abstract** — you never use `InputStream`/`OutputStream` directly. They just define the contract ("something that hands out/accepts bytes"). Real work happens in their concrete subclasses.

**Package:** `java.io`

```java
import java.io.InputStream;
import java.io.OutputStream;
```

---

## Concrete byte stream classes (the ones you actually use)

|Class|Direction|Connects to|
|---|---|---|
|`FileInputStream`|read|a file on disk|
|`FileOutputStream`|write|a file on disk|
|`ByteArrayInputStream`|read|a `byte[]` already in memory|
|`ByteArrayOutputStream`|write|builds up a `byte[]` in memory|
|`ObjectInputStream`|read|reconstructs Java objects (deserialization)|
|`ObjectOutputStream`|write|serializes Java objects|
|`BufferedInputStream`|read|wraps another stream, adds buffering|
|`BufferedOutputStream`|write|wraps another stream, adds buffering|
|`System.in`|read|keyboard/console (an `InputStream` instance)|
|`System.out` / `System.err`|write|console (technically `PrintStream`, a subclass of `FilterOutputStream` → `OutputStream`)|

All of these ultimately extend `InputStream` or `OutputStream` — which is exactly why they can all be **wrapped around each other** (the decorator pattern we covered):

```java
ObjectOutputStream out = new ObjectOutputStream(
    new BufferedOutputStream(
        new FileOutputStream("data.ser")
    )
);
```

Each layer is a byte stream, wrapping another byte stream, adding one capability at a time.

---

## Byte stream vs. character stream — the line that defines "byte stream" precisely

||Byte Stream|Character Stream|
|---|---|---|
|Base classes|`InputStream` / `OutputStream`|`Reader` / `Writer`|
|Unit of data|raw byte (0–255)|character (handles encoding — UTF-8, etc.)|
|Use for|any binary data — images, audio, serialized objects, or text you don't care to decode|specifically text, where encoding matters|
|Example|`FileInputStream`|`FileReader`|

If you're unsure which to use: **byte streams work for literally anything** (including text — you'd just need to manually decode bytes into a `String` using something like `new String(bytes, StandardCharsets.UTF_8)`). Character streams are a convenience layer _specifically_ for text, so Java handles that decoding for you.

---

## A minimal example, byte stream only

```java
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

try (FileInputStream in = new FileInputStream("photo.jpg");
     FileOutputStream out = new FileOutputStream("photo-copy.jpg")) {

    byte[] buffer = new byte[1024];
    int bytesRead;
    while ((bytesRead = in.read(buffer)) != -1) {
        out.write(buffer, 0, bytesRead);
    }

} catch (IOException e) {
    System.out.println("Copy failed: " + e.getMessage());
}
```

Notice `.jpg` — an image file, pure binary, no "text" concept at all. This is exactly the case where byte streams are the _only_ correct choice; `FileReader`/`FileWriter` would corrupt this data by trying to interpret bytes as characters.

---

## Where byte streams show up in what we've already covered

- **`ObjectOutputStream`/`ObjectInputStream`** (serialization) — byte streams, because a serialized object is binary data, not text.
- **`System.in`** — a byte stream (raw `InputStream`), which is _why_ you need to wrap it in a `Scanner` or `InputStreamReader` to get usable text out of it.
- **`FileInputStream`/`FileOutputStream`** — the byte-stream pair for general file access, usable for any file type.

## One-line summary

**A byte stream is Java's low-level, universal I/O mechanism for moving raw binary data — the right choice whenever you're not specifically dealing with human-readable text, or when you want full control without any encoding assumptions.**


[[Java]]