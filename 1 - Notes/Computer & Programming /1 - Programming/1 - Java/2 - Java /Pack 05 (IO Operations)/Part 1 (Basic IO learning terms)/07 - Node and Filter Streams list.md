
### Node : 

|Data source|Byte stream|Character stream|
|---|---|---|
|File|`FileInputStream` / `FileOutputStream`|`FileReader` / `FileWriter`|
|Array in memory|`ByteArrayInputStream` / `ByteArrayOutputStream`|`CharArrayReader` / `CharArrayWriter`|
|String in memory|(none)|`StringReader` / `StringWriter`|
|Between threads|`PipedInputStream` / `PipedOutputStream`|`PipedReader` / `PipedWriter`|

The pattern is that the character side mirrors the byte side, with `Reader`/`Writer` in place of `InputStream`/`OutputStream`. The one gap is strings. A `String` is already text, so there's no byte-level version of it, and `StringReader` and `StringWriter` exist purely on the character side. In practice they're handy for testing code that expects a `Reader` without needing a real file.

There are also some node streams you don't create with `new`. They're handed to you by something else:

- `System.in`, `System.out`, and `System.err` are the console's byte streams.
- `socket.getInputStream()` and `socket.getOutputStream()` give you the network pipe.
- `Files.newInputStream(path)` and `url.openStream()` hand you a ready-made stream for a file or a web address.

All of these are byte streams, because the network and the console deal in raw bytes.

The one place the picture gets blurry is `InputStreamReader` and `OutputStreamWriter`. They're technically wrappers, since you give them a byte stream, but their whole job is to be the **bridge** from the byte world to the character world. That's where you pick your charset. In fact, `FileReader` is basically a shortcut for `new InputStreamReader(new FileInputStream(...))`. So when you need to read text from a socket or from `System.in`, you take the byte stream you were given and wrap it in an `InputStreamReader`:

```java
Reader reader = new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8);
```

The analogy breaks down a little here, because the character side doesn't connect to the outside world directly. Underneath, every character stream on a file or network is sitting on bytes, and the `Reader` is doing the decoding on top of them. The two families are really "bytes" and "bytes plus decoding."

---
### Filter

the wrappers on each side, matched by what they add. This time the two sides don't mirror each other as neatly, so I'll group by ability.

|Ability added|Byte stream wrapper|Character stream wrapper|
|---|---|---|
|Buffering|`BufferedInputStream` / `BufferedOutputStream`|`BufferedReader` / `BufferedWriter`|
|Primitive types (int, double, boolean)|`DataInputStream` / `DataOutputStream`|(none)|
|Whole Java objects|`ObjectInputStream` / `ObjectOutputStream`|(none)|
|Pushing data back to re-read it|`PushbackInputStream`|`PushbackReader`|
|Line numbers|`LineNumberInputStream` (deprecated)|`LineNumberReader`|
|Formatted text output|`PrintStream`|`PrintWriter`|
|Sequencing several streams into one|`SequenceInputStream`|(none)|
|Bytes to characters (the bridge)|(n/a)|`InputStreamReader` / `OutputStreamWriter`|

Beyond these, there are wrappers that change the _format_ of the bytes as they pass through:

- `GZIPInputStream` / `GZIPOutputStream`: compress and decompress with gzip.
- `ZipInputStream` / `ZipOutputStream`: read and write zip archives.
- `CipherInputStream` / `CipherOutputStream`: encrypt and decrypt.
- `DigestInputStream` / `DigestOutputStream`: compute a checksum or hash as the data goes by.

These are all byte-side only, because compression and encryption work on raw bytes. If you want text out of a gzipped file, you stack them: a `BufferedReader` around an `InputStreamReader` around a `GZIPInputStream` around a `FileInputStream`. That four-layer stack is the decorator pattern at its most typical.

A few notes so the table doesn't mislead you:

**`BufferedReader` is the one you'll use most.** It's the only common way to read text line by line, with `readLine()`. Likewise `PrintWriter` gives you `println()` and `printf()` for writing text, and `PrintStream` is what `System.out` actually is, which is why `System.out.println` works.

**Strictly speaking, `ObjectInputStream` and `DataInputStream` are wrappers by design but not "filter streams" by class.** Only some of these literally extend `FilterInputStream` or `FilterOutputStream` (the `Buffered...`, `Data...`, `Pushback...`, and `Print...` byte streams do). `ObjectInputStream` doesn't, even though it wraps another stream and behaves just like one. The textbook term "filter stream" and the actual class hierarchy don't line up perfectly, so don't be surprised if a book draws the line slightly differently than I did.

**`LineNumberInputStream` is deprecated** because it mixed up bytes and characters. Use `LineNumberReader` instead.

The analogy of adapters on a hose holds up well here. Where it breaks down is the character side: it has far fewer wrappers because most of the interesting byte-level jobs (compression, encryption, object serialization) happen _before_ decoding to text. So character wrappers mostly handle convenience, like buffering and line reading, while the byte side does the heavy transformations.



[[Java]]
[[IO]]