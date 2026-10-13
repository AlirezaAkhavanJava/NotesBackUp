

The way to choose is to ask two questions in order: **what's on the other end?** (that picks the basic stream), and **what do I want to do with the data as it passes?** (that picks the wrappers). The first question is usually settled for you, because the resource tends to dictate the stream.

|Resource|Basic stream to use|Typical wrappers on top|
|---|---|---|
|Binary file (image, PDF, audio, zip)|`FileInputStream` / `FileOutputStream`|`BufferedInputStream` / `BufferedOutputStream`|
|Text file|`FileReader` / `FileWriter` (or `InputStreamReader` if you want to name the charset)|`BufferedReader` / `BufferedWriter`, or `PrintWriter` for `println`/`printf`|
|Keyboard / console input|`System.in` (already given to you)|`InputStreamReader`, then `BufferedReader`|
|Console output|`System.out` / `System.err` (already `PrintStream`s)|Nothing needed|
|Network socket|`socket.getInputStream()` / `getOutputStream()`|`Buffered...`; add `InputStreamReader` for text, or `Data...` for a binary protocol|
|Web address (URL)|`url.openStream()`|`InputStreamReader`, then `BufferedReader` for text|
|Byte array in memory|`ByteArrayInputStream` / `ByteArrayOutputStream`|Anything, since it behaves like any other byte pipe|
|String in memory|`StringReader` / `StringWriter`|`BufferedReader` if you want `readLine()`|
|Char array in memory|`CharArrayReader` / `CharArrayWriter`|Same as above|
|Another thread|`PipedInputStream` / `PipedOutputStream` (or `PipedReader` / `PipedWriter` for text)|Rarely needed|

Then there are the cases where the resource isn't a _place_ but a _format_. Here you pick a wrapper to match, and it goes around whichever basic stream reaches the data:

|What the data is|Wrapper to use|
|---|---|
|Gzip-compressed|`GZIPInputStream` / `GZIPOutputStream`|
|Zip archive|`ZipInputStream` / `ZipOutputStream`|
|Encrypted|`CipherInputStream` / `CipherOutputStream`|
|Java objects saved or sent as-is|`ObjectInputStream` / `ObjectOutputStream`|
|Ints, doubles, booleans in a fixed binary layout|`DataInputStream` / `DataOutputStream`|

The decision usually goes like this:

1. **Find your resource** in the first table. That gives you the basic stream.
2. **Is the content text?** If yes, you need a `Reader`/`Writer`, so add `InputStreamReader`/`OutputStreamWriter` (or use `FileReader`/`FileWriter`) and choose your charset. If it's raw bytes like an image, stay on the byte side.
3. **Add `Buffered...`** almost every time, because it's cheap and avoids the one-trip-per-byte problem.
4. **Add a format wrapper** only if the data is compressed, encrypted, or made of objects or primitives.

Here's that process applied to "read a gzipped text file line by line":

```java
BufferedReader in = new BufferedReader(
    new InputStreamReader(
        new GZIPInputStream(
            new FileInputStream("log.txt.gz")),
        StandardCharsets.UTF_8));
```

Read it from the inside out: the file is the resource, gzip is the format, `InputStreamReader` turns bytes into text, and `BufferedReader` gives you `readLine()`.

Think of each resource as having its own kind of plug and the streams as adapters. That analogy breaks down in two places. First, one resource isn't tied to one stream, since a file can be read as bytes, as text, or as objects, depending on what's _in_ it and what you stack on. Second, for the console and the network you never choose a basic stream, because Java hands you one (`System.in`, `socket.getInputStream()`), and your only job is deciding what to wrap around it.

One shortcut worth keeping in mind: for a small text or binary file you want all at once, skip the stream stacking entirely and use `Files.readString(path)`, `Files.readAllLines(path)`, or `Files.readAllBytes(path)`. Streams earn their place when the data is large, arrives gradually, or comes from something that isn't a file.


[[IO]]
[[Java]]