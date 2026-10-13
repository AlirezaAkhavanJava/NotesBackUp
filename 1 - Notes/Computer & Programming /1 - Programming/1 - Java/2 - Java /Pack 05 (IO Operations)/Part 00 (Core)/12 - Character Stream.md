


## Definition

A **character stream** is the branch of Java I/O (`java.io`) built specifically to read and write **text** — sequences of characters — with automatic handling of **character encoding** (the rules for converting between bytes and human-readable characters, like UTF-8 or ASCII).

It's the direct counterpart to the byte stream family: rooted at `Reader` (reading) and `Writer` (writing), instead of `InputStream`/`OutputStream`.

```
Character Stream family
├── Reader   (abstract — reading characters IN)
└── Writer   (abstract — writing characters OUT)
```

---

## The problem it solves

You already know byte streams move raw bytes with **zero understanding of meaning**. That's exactly the problem for text: a byte is just a number (0–255), but _which character that number represents depends on an encoding scheme_.

For example, the byte value `195` might mean something entirely different in ASCII vs. UTF-8 vs. UTF-16 — especially for non-English characters (accents, non-Latin alphabets, emoji). If you read text using raw bytes and guess the encoding wrong, you get **corrupted, garbled text** (commonly called "mojibake").

```java
// Byte stream — YOU must manually decode bytes into characters
FileInputStream in = new FileInputStream("notes.txt");
byte[] bytes = in.readAllBytes();
String text = new String(bytes, StandardCharsets.UTF_8); // manual decoding step required
```

```java
// Character stream — decoding is handled FOR you
FileReader reader = new FileReader("notes.txt", StandardCharsets.UTF_8);
int ch = reader.read(); // already a character, no manual decoding needed
```

**Character streams solve the "bytes vs. actual readable text" problem** by baking encoding-awareness directly into the stream itself, so you work in terms of `char`/`String` the whole time, never touching raw bytes.

---

## The abstract base classes

```java
public abstract class Reader {
    public abstract int read() throws IOException;      // reads ONE character, or -1 at end
    public int read(char[] cbuf) throws IOException;      // reads MANY characters into a buffer
    public void close() throws IOException;
}

public abstract class Writer {
    public abstract void write(int c) throws IOException;      // writes ONE character
    public void write(String s) throws IOException;              // writes a whole String directly!
    public void close() throws IOException;
}
```

Notice `Writer` can take a `String` directly (`write(String s)`) — something `OutputStream` cannot do, since `OutputStream` only understands bytes, not Java's `String` type. This is a direct, practical advantage of character streams for text work.

**Package:** `java.io`

```java
import java.io.Reader;
import java.io.Writer;
```

---

## Concrete character stream classes

|Class|Direction|Connects to|
|---|---|---|
|`FileReader`|read|a text file on disk|
|`FileWriter`|write|a text file on disk|
|`BufferedReader`|read|wraps another `Reader`, adds buffering + `readLine()`|
|`BufferedWriter`|write|wraps another `Writer`, adds buffering + `newLine()`|
|`InputStreamReader`|read|**bridges** a byte stream into a character stream|
|`OutputStreamWriter`|write|**bridges** a character stream into a byte stream|
|`StringReader`|read|reads from a `String` already in memory|
|`StringWriter`|write|builds up a `String` in memory|

---

## The bridge classes — the most important detail to understand

`InputStreamReader` and `OutputStreamWriter` deserve special attention, because they explain something you've already used without a full explanation: `new InputStreamReader(System.in)`.

**The problem:** `System.in` is a byte stream (`InputStream`) — it only knows how to hand out raw bytes. But you want to read _text_ input from the keyboard. How do you get from "raw bytes" to "readable characters"?

**The solution — `InputStreamReader` is literally a converter/bridge:**

```java
InputStream byteStream = System.in;                          // raw bytes
Reader charStream = new InputStreamReader(byteStream);        // bridge: bytes → characters
BufferedReader reader = new BufferedReader(charStream);        // adds buffering + readLine()

String line = reader.readLine();
```

```
System.in (InputStream, bytes)
      │
      ▼
InputStreamReader   ← decodes bytes into characters using an encoding (default: UTF-8)
      │
      ▼
BufferedReader       ← adds efficient line-by-line reading
      │
      ▼
   String line
```

This is the exact chain of wrapping (decorator pattern again) that explains _why_ `BufferedReader` needs an `InputStreamReader` in the middle when wrapping `System.in` — it's crossing from the byte-stream world into the character-stream world, and `InputStreamReader` is the bridge that does that crossing.

**`OutputStreamWriter` does the same thing in reverse** — converts characters you write back into bytes for an underlying `OutputStream`:

```java
Writer writer = new OutputStreamWriter(System.out); // characters → bytes, written to console
writer.write("Hello");
writer.flush();
```

(In practice you'd just use `System.out.println()` directly for console output — this is shown purely to illustrate the bridge mechanism.)

---

## Encoding — the thing character streams handle for you

```java
FileReader reader = new FileReader("notes.txt", StandardCharsets.UTF_8); // explicit encoding
```

If you don't specify an encoding, Java uses the **platform default charset**, which can differ between operating systems/configurations — a classic source of "works on my machine" bugs when text files contain non-ASCII characters (accented letters, non-English scripts). Since Java 11, most character-stream constructors let you pass a `Charset` explicitly (like `StandardCharsets.UTF_8` above) — **always specify it explicitly in real code**, rather than relying on the platform default, for predictable, portable behavior.

---

## Byte stream vs. character stream — full comparison

||Byte Stream|Character Stream|
|---|---|---|
|Base classes|`InputStream` / `OutputStream`|`Reader` / `Writer`|
|Unit|raw byte (0–255)|character (decoded per an encoding)|
|Encoding awareness|none — you decode manually if needed|built in|
|Can write a `String` directly?|no — must convert to `byte[]` first|yes — `write(String)`|
|Best for|images, audio, serialized objects, any binary data|text files, console text, any human-readable content|
|Example class|`FileInputStream`|`FileReader`|

---

## Practical example — reading and writing a text file with character streams

```java
import java.io.*;
import java.nio.charset.StandardCharsets;

// Writing text
try (Writer writer = new FileWriter("greeting.txt", StandardCharsets.UTF_8)) {
    writer.write("Hello, Alireza! Café résumé naïve.");  // non-ASCII chars handled correctly
}

// Reading text back
try (BufferedReader reader = new BufferedReader(
        new FileReader("greeting.txt", StandardCharsets.UTF_8))) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
} catch (IOException e) {
    System.out.println("Failed to read: " + e.getMessage());
}
```

If you'd used `FileInputStream`/`FileOutputStream` (byte streams) here instead, `Café résumé naïve` risks becoming garbled on read unless you manually and correctly handled the byte-to-character decoding yourself — character streams remove that entire risk.

---

## Where this connects to everything else we've covered

- `BufferedReader` wrapping `InputStreamReader` wrapping `System.in` — the exact chain used in the "ways to get user input" tutorial — now fully explained.
- `Files.readString()` / `Files.newBufferedReader()` (from the `java.nio.file` IO tutorial) — these are convenience methods that use character streams (with UTF-8 by default) internally, sparing you from manually building the `InputStreamReader`/`FileReader` chain yourself.
- `Reader`/`Writer` don't have anything analogous to `ObjectInputStream`/`ObjectOutputStream` — serialization is inherently binary, which is exactly why serialization stays firmly in the byte-stream world, never the character-stream world.

## One-line summary

**A character stream is Java's encoding-aware I/O mechanism for text — use `Reader`/`Writer` (and their subclasses like `FileReader`/`BufferedReader`) whenever you're working with human-readable text and want Java to handle byte-to-character conversion correctly for you.**


[[Java]]