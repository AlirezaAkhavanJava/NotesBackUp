


## 1. Mental model

A byte stream is a **one-way pipe of bytes**. You pour bytes in at one end or take them out at the other, one after another, without knowing or caring what is at the far end.

```
Source (file, socket, memory) ──bytes──▶ InputStream  ──▶ your code
your code ──▶ OutputStream ──bytes──▶ Destination (file, socket, memory)
```

This is why the earlier serialization code worked identically for a file and a network socket. `ObjectOutputStream` only needs _some_ `OutputStream`, and the destination is a detail.

Three properties define a stream:

1. **Sequential.** You read in order. There is no "go back" unless the stream supports it (`mark`/`reset`).
2. **One direction.** `InputStream` only reads, `OutputStream` only writes.
3. **Raw bytes.** A stream has no idea about text, objects, or JSON. Meaning is added by whatever you wrap around it.

## 2. The two base classes

Everything in Java byte I/O extends one of these (both in `java.io`):

```java
abstract class InputStream  { abstract int read() throws IOException; ... }
abstract class OutputStream { abstract void write(int b) throws IOException; ... }
```

Common concrete streams, by what they connect to:

|Destination or source|Input|Output|
|---|---|---|
|File|`FileInputStream`|`FileOutputStream`|
|Memory (a `byte[]`)|`ByteArrayInputStream`|`ByteArrayOutputStream`|
|Network socket|`socket.getInputStream()`|`socket.getOutputStream()`|
|HTTP request/response (Servlet)|`request.getInputStream()`|`response.getOutputStream()`|

## 3. The core operations

```java
try (InputStream in = new FileInputStream("photo.jpg");
     OutputStream out = new FileOutputStream("copy.jpg")) {

    byte[] buffer = new byte[8192];
    int n;
    while ((n = in.read(buffer)) != -1) {   // -1 means end of stream
        out.write(buffer, 0, n);            // write only the n bytes actually read
    }
}
```

Facts you must know here:

- `read()` returns an **`int` from 0 to 255**, or **-1** for end of stream. It returns `int` rather than `byte` precisely so that -1 can't be confused with the valid byte `0xFF` (which is -1 as a signed `byte`).
- `read(byte[])` returns **how many bytes were actually read**, which can be less than the array size. Ignoring `n` and writing the whole buffer corrupts the last chunk. This is the most common beginner bug.
- Reading one byte at a time from a file is very slow, because each call may hit the OS. Read in chunks.

Modern shortcuts so you don't write that loop:

```java
byte[] all = in.readAllBytes();   // fine for small data, dangerous for huge files
in.transferTo(out);               // copies everything, does the loop for you
Files.copy(Path.of("a.jpg"), Path.of("b.jpg"));   // NIO, simplest for files
```

## 4. Decorators: how streams gain powers

A raw `FileInputStream` can only give bytes. Extra abilities come from **wrapping** one stream in another, so each layer adds one feature. This is the **decorator pattern**.

```java
var out = new ObjectOutputStream(            // 3. objects  -> bytes
              new BufferedOutputStream(      // 2. batches small writes
                  new FileOutputStream("p.ser")));  // 1. bytes -> file
```

|Wrapper|What it adds|
|---|---|
|`BufferedInputStream/OutputStream`|An in-memory buffer, so fewer slow system calls|
|`DataInputStream/OutputStream`|`writeInt`, `writeUTF`, `readDouble`... (primitives as bytes)|
|`ObjectInputStream/OutputStream`|Whole objects (Java serialization)|
|`GZIPOutputStream` / `GZIPInputStream`|Compression|
|`CipherOutputStream`|Encryption|

Data flows through the layers in order, so you can stack compression and encryption on top of serialization with no change to the code at either end. Rule: **a wrapper must be closed last-to-first, but closing the outermost one closes everything inside it**, so you only close the outer one (try-with-resources does this).

## 5. Byte streams vs character streams

Bytes are not text. Text needs a **charset** (an agreement on which bytes mean which characters).

||Byte streams|Character streams|
|---|---|---|
|Base classes|`InputStream` / `OutputStream`|`Reader` / `Writer`|
|Unit|`byte`|`char`|
|Use for|Images, ZIPs, serialized objects, network protocols|Text|

The bridge between them is explicit:

```java
var reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8));
```

`InputStreamReader` turns bytes into characters using the charset you give it. This links to Jackson: JSON is text, but over HTTP it travels as UTF-8 bytes, and Jackson accepts either form:

```java
mapper.writeValue(outputStream, dto);         // writes UTF-8 bytes directly
PersonDto p = mapper.readValue(inputStream, PersonDto.class);
```

Passing the stream directly is better than building a `String` first, because Jackson handles the encoding and avoids an extra copy.

## 6. Seeing serialized bytes for real

`ByteArrayOutputStream` is a stream whose destination is just memory, so you can inspect what serialization really produces. It also confirms the earlier claim about the `AC ED 00 05` header:

```java
var bos = new ByteArrayOutputStream();
try (var oos = new ObjectOutputStream(bos)) {
    oos.writeObject(new Person("Alice", 25));
}
byte[] bytes = bos.toByteArray();
System.out.println(HexFormat.of().formatHex(bytes));   // starts with aced0005
```

Reading them back uses `ByteArrayInputStream`:

```java
try (var ois = new ObjectInputStream(new ByteArrayInputStream(bytes))) {
    Person copy = (Person) ois.readObject();
}
```

This round trip through memory is also the "deep copy" trick mentioned earlier: serialize into a `byte[]`, deserialize, and you get a fully independent object graph.

## 7. Gotchas and edge cases

1. **Always close streams.** An unclosed `FileOutputStream` leaks a file handle. An unclosed network stream can hold a connection open. Use try-with-resources every time.
2. **Always flush before you stop.** Buffered output may still sit in memory. `close()` flushes for you, but if you keep a connection open (a socket), you must call `flush()` yourself or the other side waits forever for bytes that never left.
3. **A stream is single-use.** After you read it to the end, it's empty. You can't read an HTTP request body twice without caching it.
4. **Blocking reads.** On a socket, `read()` waits until data arrives. A silent peer freezes your thread. Production code sets timeouts.
5. **Byte order (endianness).** `DataOutputStream.writeInt` writes **big-endian** (the network standard). A C or Go program on x86 uses little-endian natively, so a protocol must state the order explicitly.
6. **`ObjectOutputStream` remembers.** It keeps references to every object it wrote, so a long-lived stream writing many objects leaks memory, and a re-sent _modified_ object may be sent as a back-reference to the old version. Call `reset()` between logically separate writes.
7. **Mixing `Reader` and `InputStream` on one source** can lose bytes, because the reader buffers ahead. Decide once which layer owns the stream.
8. **`readAllBytes()` on untrusted input** is a denial-of-service risk, because someone can send a gigabyte. Limit the size.
9. **Never read an `ObjectInputStream` from an untrusted source** without a filter, as covered in the security section of the notes.
10. **Platform default charset:** from Java 18, UTF-8 is the default everywhere, including Debian, but being explicit (`StandardCharsets.UTF_8`) avoids surprises.

## 8. Where this sits in the bigger picture

```
Your object ──Jackson/serialization──▶ bytes ──OutputStream──▶ file / socket / HTTP response
```

- Serialization decides **what the bytes mean**.
- The stream decides **where the bytes go**.

Spring Boot hides the stream: when you return a DTO, Jackson writes to the response's `OutputStream`. You see streams directly when handling **file uploads and downloads** (`InputStream` from `MultipartFile`, `StreamingResponseBody` for large downloads), which is the most common place you'll meet them in a Spring Boot project.

## 9. Summary

- A byte stream is a sequential, one-way pipe of raw bytes, and `InputStream`/`OutputStream` are its two base types.
- `read()` gives 0 to 255 or -1, and `read(byte[])` returns a count you must respect.
- Features come from wrapping streams (buffering, data types, objects, compression, encryption).
- Bytes become text only through a charset, via `Reader`/`Writer`.
- Always use try-with-resources, and flush when you keep a stream open.




[[Serialization]]