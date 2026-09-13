

You already know _what_ streams are and _why_ serialization exists. Here's how to actually use them well in real code — the patterns that separate working code from good code.

---

## 1. Always buffer — raw streams are slow

Every `read()`/`write()` call on a raw stream can trigger a system call (disk/network access), which is expensive. Wrapping in a `Buffered*` stream batches those into fewer, larger operations.

```java
// Bad — one system call per byte
InputStream in = new FileInputStream("data.txt");

// Good — reads in chunks internally, you still read byte-by-byte in code
InputStream in = new BufferedInputStream(new FileInputStream("data.txt"));
```

**Rule of thumb:** if you're wrapping a `File*Stream` directly and reading/writing in a loop, you're almost certainly missing a `Buffered*` layer.

---

## 2. Always use try-with-resources — no exceptions

Never manually call `close()`. Every stream you open goes in the try-with-resources parentheses, and if you're wrapping multiple layers, only the **outermost** stream needs to be there — closing it cascades down and closes everything it wraps.

```java
try (ObjectOutputStream out = new ObjectOutputStream(
        new BufferedOutputStream(new FileOutputStream("user.ser")))) {
    out.writeObject(user);
} // all three layers closed automatically, even on exception
```

If you need multiple independent resources, comma-separate them — they close in reverse order automatically:

```java
try (InputStream in = new FileInputStream("in.txt");
     OutputStream out = new FileOutputStream("out.txt")) {
    in.transferTo(out); // Java 9+, copies efficiently without manual loop
}
```

---

## 3. Don't reinvent copying/reading loops — the JDK already has them

You rarely need to hand-write a `read()`-into-buffer loop anymore:

```java
// Reading a whole file into memory
byte[] data = Files.readAllBytes(Paths.get("file.txt"));       // small files
String text = Files.readString(Paths.get("file.txt"));         // text, Java 11+

// Copying stream → stream
in.transferTo(out);                                             // Java 9+

// Copying with NIO (fastest for large files)
Files.copy(Paths.get("source.txt"), Paths.get("dest.txt"));
```

Hand-rolled `while ((bytesRead = in.read(buffer)) != -1)` loops are still correct, but reach for these first — less code, fewer off-by-one bugs.

---

## 4. Match the tool to the size of the data

This is the efficiency decision that matters most in practice:

|Data size|Approach|
|---|---|
|Small (fits comfortably in memory)|`Files.readAllBytes()` / `readString()` — simple, one call|
|Large / unknown size|Stream it — never load the whole thing into memory. Process chunk-by-chunk|
|Very large files, random access|`java.nio` (`FileChannel`, memory-mapped files) — avoids copying data through the JVM heap at all|

```java
// Bad for a 5GB file — OutOfMemoryError waiting to happen
byte[] data = Files.readAllBytes(Paths.get("huge-video.mp4"));

// Good — process in a bounded-memory stream
try (InputStream in = new BufferedInputStream(new FileInputStream("huge-video.mp4"))) {
    byte[] buffer = new byte[8192];
    int bytesRead;
    while ((bytesRead = in.read(buffer)) != -1) {
        process(buffer, bytesRead); // handle chunk, never hold the whole file
    }
}
```

---

## 5. Serialization: default `Serializable` is rarely what you want in real systems

This is the most important "efficient code" lesson for serialization specifically. Java's built-in binary serialization is:

- **Slow** compared to alternatives
- **Fragile** (`serialVersionUID` mismatches break things)
- **A security liability** if you ever deserialize data from an untrusted source (attacker-controlled bytes can trigger arbitrary code execution during the reflection-based reconstruction)

**In practice, on real projects:**

- REST APIs → Jackson (JSON), which Spring Boot wires up for you automatically. You'll almost never call `ObjectOutputStream` in a Spring Boot app.
- Caching (Redis, etc.) → often JSON or a binary format like Protobuf/Kryo, not raw Java serialization, specifically because it's faster and more version-tolerant.
- **Never deserialize `ObjectInputStream` data from an external/untrusted source.** If you must, look into `ObjectInputFilter` (Java 9+) to restrict which classes are allowed to be reconstructed.

So the "efficient" move is often: _know how native serialization works (which you now do), but don't reach for it by default_ — let Spring/Jackson handle the DTO ↔ JSON boundary, and reserve manual serialization for internal, trusted use cases (e.g., short-lived caches within your own system).

---

## 6. Design your classes to be serialization-friendly from the start

```java
public class User implements Serializable {
    private static final long serialVersionUID = 1L;  // always declare explicitly

    private String name;
    private transient String password;      // never persist secrets
    private transient Connection dbConnection; // never persist live resources

    // If a transient field needs to be restored after deserialization,
    // implement this — it's called automatically post-deserialize:
    private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
        in.defaultReadObject();
        this.password = fetchFromSecureStore(); // re-populate manually
    }
}
```

---

## 7. In Spring Boot specifically: lean on the abstractions, understand what's under them

You now know enough to recognize what Spring is doing when you see:

```java
@PostMapping("/upload")
public void upload(@RequestParam MultipartFile file) throws IOException {
    try (InputStream in = file.getInputStream()) {   // it's just an InputStream
        Files.copy(in, Paths.get("/uploads/" + file.getOriginalFilename()));
    }
}
```

```java
@GetMapping("/download")
public ResponseEntity<Resource> download() {
    Resource resource = new FileSystemResource("data.txt"); // wraps I/O access uniformly
    return ResponseEntity.ok(resource);
}
```

Both are just `InputStream`/`OutputStream`-based abstractions with Spring conveniences layered on. When something breaks (a stream not closing, a file upload silently truncating), you now have the mental model to debug it instead of treating it as a black box.

---

## Quick checklist for writing I/O code going forward

- [ ] Wrapped in `Buffered*`?
- [ ] Using try-with-resources, not manual `close()`?
- [ ] Using `Files.*` / `transferTo()` instead of a hand-written loop, where possible?
- [ ] Large data → streamed in chunks, not loaded fully into memory?
- [ ] Serializing → do I actually need Java's native serialization, or should this be JSON (Jackson)?
- [ ] If using `Serializable` → explicit `serialVersionUID`, `transient` on secrets/live resources?
- [ ] Never deserializing untrusted external data with raw `ObjectInputStream`?

That's the practical layer on top of everything we've covered — the "how experienced Java devs actually write this code" version.

[[Java]]