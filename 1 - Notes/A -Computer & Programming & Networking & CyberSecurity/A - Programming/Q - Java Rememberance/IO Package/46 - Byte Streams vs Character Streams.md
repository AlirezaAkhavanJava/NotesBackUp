

You now know what each _is_. This is about **when and how to actually reach for each one** in real code.

---

## Quick definitions (recap, for context)

||Byte Stream|Character Stream|
|---|---|---|
|Base classes|`InputStream` / `OutputStream`|`Reader` / `Writer`|
|Moves|raw bytes|encoded text (characters)|
|Use for|any binary data|human-readable text|

---

## The decision rule (the one question that settles it)

**Ask: "Is this data meant to be read as text by a human, or is it arbitrary binary data?"**

```
Is the file/data fundamentally TEXT
(a .txt, .csv, .json, .log, .xml, source code)?
          │
     ┌────┴────┐
    YES          NO
     │            │
Character    Byte Stream
 Stream      (Reader/  (InputStream/
 Writer)      OutputStream)
```

That's really the entire decision. Everything else below is how to apply it correctly.

---

## When to use Byte Streams (`InputStream` / `OutputStream`)

### Use case 1: Any non-text file

Images, audio, video, PDFs, ZIP archives, executables — anything where the bytes don't represent readable characters at all.

```java
try (FileInputStream in = new FileInputStream("photo.jpg");
     FileOutputStream out = new FileOutputStream("photo-copy.jpg")) {
    in.transferTo(out);
}
```

**Why:** trying to read this with `FileReader` would attempt to decode binary image data as text characters — producing garbage and likely corrupting the data on write-back.

### Use case 2: Serialization

```java
try (ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream("user.ser"))) {
    out.writeObject(user);
}
```

**Why:** a serialized object's byte representation isn't text — it's a binary encoding of the object's structure. This is always byte streams, never character streams.

### Use case 3: You don't care about content, only about moving bytes efficiently

```java
try (InputStream in = new FileInputStream("any-file.dat");
     OutputStream out = new FileOutputStream("backup.dat")) {
    in.transferTo(out); // pure byte copy, content-agnostic
}
```

**Why:** for a raw file copy, you don't need to interpret the content as text at all — treating it as bytes is both correct and slightly more efficient (no encoding/decoding overhead).

### Use case 4: Network sockets, raw protocol data

```java
Socket socket = new Socket("example.com", 80);
InputStream in = socket.getInputStream();
OutputStream out = socket.getOutputStream();
```

**Why:** sockets deal in raw bytes by nature — the protocol data (HTTP headers, binary payloads) isn't guaranteed to be clean text, so the socket API gives you byte streams, and you decide if/how to interpret it as text afterward.

---

## When to use Character Streams (`Reader` / `Writer`)

### Use case 1: Reading/writing plain text files

```java
try (BufferedReader reader = new BufferedReader(new FileReader("notes.txt", StandardCharsets.UTF_8))) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
}
```

**Why:** `.txt` files are meant to be human-readable text — you want Java to correctly decode bytes into the right characters (handling accents, non-Latin scripts, etc.) automatically.

### Use case 2: Writing text where you're building it as `String`s

```java
try (BufferedWriter writer = new BufferedWriter(new FileWriter("report.txt", StandardCharsets.UTF_8))) {
    writer.write("Report generated on 2026-09-14");
    writer.newLine();
    writer.write("Status: Complete");
}
```

**Why:** `Writer.write(String)` takes a `String` directly — no manual `.getBytes()` conversion needed, which byte streams would require.

### Use case 3: Console input/output involving text (what you've been doing all along)

```java
BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
String name = reader.readLine();
```

**Why:** you want a line of human-typed text — character streams (via the `InputStreamReader` bridge over `System.in`) give you that directly, correctly decoded.

### Use case 4: Any structured text format — CSV, JSON, XML, config files, logs

```java
try (BufferedReader reader = Files.newBufferedReader(Path.of("data.csv"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        String[] fields = line.split(",");
    }
}
```

**Why:** these formats are text-based by definition — even though a JSON/XML _parser_ library might internally do more complex things, your starting point for reading the raw file content is still character streams.

---

## The bridge — when you need BOTH in the same flow

This happens whenever a byte-based source (a socket, `System.in`, a byte-oriented API) needs to be treated as text:

```java
InputStreamReader bridge = new InputStreamReader(System.in, StandardCharsets.UTF_8);
BufferedReader reader = new BufferedReader(bridge);
```

**When to use this pattern:** anytime your data source only gives you an `InputStream`/`OutputStream` (sockets, `System.in`, an HTTP response body), but you know the content is text and want to work with `String`s instead of raw bytes.

```java
// Example: reading text from an HTTP-style byte stream
InputStream rawResponse = connection.getInputStream(); // byte stream — HTTP is byte-based
BufferedReader textReader = new BufferedReader(new InputStreamReader(rawResponse, StandardCharsets.UTF_8));
String responseBody = textReader.lines().collect(Collectors.joining("\n"));
```

---

## Practical decision table

|Situation|Use|Class example|
|---|---|---|
|Copying an image/video/binary file|Byte stream|`FileInputStream` / `FileOutputStream`|
|Reading a `.txt` / `.csv` / `.log` file|Character stream|`FileReader` / `BufferedReader`|
|Serializing a Java object|Byte stream|`ObjectOutputStream`|
|Reading keyboard input|Character stream (via bridge)|`BufferedReader(new InputStreamReader(System.in))`|
|Downloading a file from a URL (unknown type)|Byte stream|`InputStream` from `HttpResponse`/`URLConnection`|
|Downloading and displaying an HTML/JSON response|Character stream (via bridge)|`InputStreamReader` wrapping the response's `InputStream`|
|Writing a generated report/log file|Character stream|`FileWriter` / `BufferedWriter`|
|Sending raw bytes over a network socket|Byte stream|`Socket.getOutputStream()`|
|Copying any file when content type doesn't matter|Byte stream|`InputStream.transferTo(OutputStream)`|

---

## How to use them — the standard patterns, side by side

### Reading — byte stream pattern

```java
try (InputStream in = new BufferedInputStream(new FileInputStream("file.bin"))) {
    byte[] buffer = new byte[4096];
    int bytesRead;
    while ((bytesRead = in.read(buffer)) != -1) {
        process(buffer, bytesRead); // handle raw bytes
    }
}
```

### Reading — character stream pattern

```java
try (BufferedReader reader = new BufferedReader(new FileReader("file.txt", StandardCharsets.UTF_8))) {
    String line;
    while ((line = reader.readLine()) != null) {
        process(line); // handle text, line by line
    }
}
```

### Writing — byte stream pattern

```java
try (OutputStream out = new BufferedOutputStream(new FileOutputStream("file.bin"))) {
    out.write(byteArray);
}
```

### Writing — character stream pattern

```java
try (BufferedWriter writer = new BufferedWriter(new FileWriter("file.txt", StandardCharsets.UTF_8))) {
    writer.write("some text");
    writer.newLine();
}
```

Notice the **shape is identical** in both cases (open → buffer → loop or write → close via try-with-resources) — only the unit of data (`byte`/`byte[]` vs `char`/`String`) and the class names differ. Once you know one pattern, you know both.

---

## Common mistakes when choosing between them

### Mistake 1: Using `FileReader` on a binary file

```java
FileReader reader = new FileReader("image.jpg"); // WRONG
```

This will attempt to decode raw image bytes as text characters — producing garbage, and any modification/write-back will **corrupt the file**, since not every byte sequence maps to a valid character in a given encoding.

### Mistake 2: Using `FileInputStream` and manually decoding text yourself, when `FileReader` already does it

```java
// Unnecessarily manual
FileInputStream in = new FileInputStream("notes.txt");
byte[] bytes = in.readAllBytes();
String text = new String(bytes, StandardCharsets.UTF_8);
```

```java
// Simpler — let the character stream handle decoding
String text = Files.readString(Path.of("notes.txt")); // uses character stream internally
```

Not _wrong_, just needless extra work — if you know it's text upfront, character streams (or the `Files.*` convenience methods, which use them internally) save you the manual conversion step.

### Mistake 3: Forgetting to specify an encoding, relying on platform default

```java
FileReader reader = new FileReader("notes.txt"); // uses platform default charset — risky
```

On one machine this might default to UTF-8, on another to something else — causing subtly different (or broken) output for non-ASCII text. **Always pass `StandardCharsets.UTF_8` (or whatever encoding you actually need) explicitly.**

### Mistake 4: Mixing raw byte writes with text writes on the same stream inconsistently

```java
FileOutputStream out = new FileOutputStream("file.txt");
out.write("Hello".getBytes());  // fine, but verbose/manual
```

If you find yourself calling `.getBytes()` / `new String(bytes, charset)` repeatedly around a byte stream just to handle text, that's the signal you should be using a character stream (`FileWriter`/`FileReader`) instead — it's doing that conversion for you, correctly, every time.

---

## Summary — the rule to keep

1. **Binary data (images, audio, serialized objects, unknown/arbitrary content) → byte streams (`InputStream`/`OutputStream`).**
2. **Text (files, console, JSON/XML/CSV source, logs) → character streams (`Reader`/`Writer`).**
3. **When a byte-based source needs to be treated as text (sockets, `System.in`, HTTP bodies) → bridge with `InputStreamReader`/`OutputStreamWriter`.**
4. **Always wrap in `Buffered*` for performance, and always use try-with-resources.**
5. **Always specify encoding explicitly for character streams — never rely on the platform default.**

This is the complete practical answer to "which one do I reach for" — apply the text-vs-binary question first, and the rest (which specific class, whether you need a bridge) follows directly from that answer.


[[Java]]