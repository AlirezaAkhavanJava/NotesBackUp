

## Definition

**IO** stands for **Input/Output** — the general term for any exchange of data between a running program ("inside") and anything outside it: files, the console, network connections, memory buffers, other programs. In Java specifically, **`java.io`** is the core package containing the classes that implement this — which is the same thing we've been calling **"Java I/O"** throughout this whole conversation.

So to be precise about terminology:

|Term|What it refers to|
|---|---|
|**IO**|the general concept — any data exchange between a program and the outside world|
|**I/O**|same thing, just written with a slash (common shorthand, same meaning)|
|**`java.io`**|the specific Java _package_ containing the classes that implement IO|
|**Java IO / Java I/O**|informal name for "the java.io package and how Java handles IO"|

They all point to the same idea — you've already learned the substance of it across this conversation; this is just naming the umbrella term.

---

## What lives under `java.io`

```
java.io
│
├── Byte streams (binary data)
│   ├── InputStream / OutputStream        (abstract base classes)
│   ├── FileInputStream / FileOutputStream
│   ├── BufferedInputStream / BufferedOutputStream
│   └── ObjectInputStream / ObjectOutputStream   (serialization)
│
├── Character streams (text data)
│   ├── Reader / Writer                   (abstract base classes)
│   ├── FileReader / FileWriter
│   ├── BufferedReader / BufferedWriter
│   └── InputStreamReader / OutputStreamWriter  (bridges bytes ↔ characters)
│
├── File system access
│   └── File                               (represents a path — metadata, not content)
│
├── Console-specific
│   ├── System.in / System.out / System.err
│   └── Console
│
└── Exceptions
    ├── IOException                        (base checked exception for IO failures)
    └── FileNotFoundException, EOFException, etc.
```

Every one of these is something we've already covered individually — this is the map showing how they all relate as one package.

---

## The core idea, restated one more time

Everything in `java.io` exists to do exactly one job: **move data across the inside/outside boundary**, safely and consistently, regardless of what's on the other side (disk, keyboard, network, another JVM). The package is built around:

- **Streams** as the universal abstraction (sequential flow of data, in or out)
- **Two parallel hierarchies** — bytes (`InputStream`/`OutputStream`) vs. characters (`Reader`/`Writer`) — because binary data and text need fundamentally different handling (encoding)
- **Composability** — wrapping streams around streams (buffering, object serialization, character conversion) to add capabilities in layers
- **Checked exceptions** (`IOException`) — because crossing to "outside" is inherently unreliable (files can vanish, connections can drop), so Java forces you to acknowledge that risk at compile time

---

## `java.io` vs `java.nio` — worth knowing the boundary

Since we mentioned `java.nio` earlier as the "modern alternative": `java.io` is the **original, stream-based** IO model (Java 1.0) — simple, blocking, one-byte/character-at-a-time conceptually (even when buffered). `java.nio` ("New IO", added Java 1.4, expanded significantly since) is a **buffer-and-channel-based** model built for performance and non-blocking operations — better for large files, many simultaneous connections, or high-throughput servers.

```java
// java.io — classic stream style
try (BufferedReader reader = new BufferedReader(new FileReader("file.txt"))) {
    String line = reader.readLine();
}

// java.nio — buffer/channel style (often mixed with java.io conveniences)
byte[] data = Files.readAllBytes(Paths.get("file.txt"));
```

For everyday application code (and definitely for what you'll do in Spring Boot), `java.io`'s classes — plus `java.nio.file.Files` for convenience methods — cover the vast majority of real use cases. Full `java.nio` (channels, buffers, selectors) mainly matters when you're building something performance-critical at a low level, which is well beyond "basic console I/O" territory.

[[Java]]