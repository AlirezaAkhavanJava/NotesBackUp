# Java IO — Complete Practical Guide (through JDK 25)

You already know the _concepts_ (streams, byte vs. character, buffering, try-with-resources, serialization). This tutorial focuses on **how IO is actually used in real programs** — the concrete tasks you'll actually write code for — organized by problem.

---

## 1. Reading a whole file at once (small/medium files)

### The problem

You have a config file, a small dataset, or a text file, and you just want its contents as a `String` or `byte[]` — no streaming needed.

### The solution

```java
import java.nio.file.*;

// As text
String content = Files.readString(Path.of("config.txt"));        // Java 11+

// As raw bytes
byte[] data = Files.readAllBytes(Path.of("image.png"));

// As a list of lines
List<String> lines = Files.readAllLines(Path.of("data.csv"));
```

**Why this is the right tool:** `Files` (from `java.nio.file`, but used constantly alongside `java.io`) does the open/read/close cycle in one call. No manual streams, no manual buffering, no manual exception-prone loops.

**Where you'll actually use this:** loading a small JSON/YAML config at app startup, reading a properties file, reading test fixture data.

**Watch out:** don't use this for large files (multi-GB) — it loads everything into memory at once, risking `OutOfMemoryError`. Use streaming (next section) instead.

---

## 2. Streaming a large file (line by line, or chunk by chunk)

### The problem

A log file, a large CSV, or a data export is too big to load entirely into memory. You need to process it piece-by-piece.

### The solution — line by line (text)

```java
try (BufferedReader reader = Files.newBufferedReader(Path.of("huge-log.txt"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        if (line.contains("ERROR")) {
            System.out.println(line);
        }
    }
} catch (IOException e) {
    System.out.println("Failed to read log: " + e.getMessage());
}
```

### Even more idiomatic — `Files.lines()` returns a `Stream<String>` (Java 8+)

```java
try (Stream<String> lines = Files.lines(Path.of("huge-log.txt"))) {
    long errorCount = lines.filter(line -> line.contains("ERROR")).count();
    System.out.println("Errors found: " + errorCount);
}
```

This connects your earlier lambda/stream knowledge directly to IO — `Files.lines()` gives you a lazy stream that reads one line at a time under the hood, so `filter`/`map`/`count` work without ever holding the whole file in memory.

**Real-world use case:** parsing server access logs, processing large CSV exports, scanning huge text datasets for a data pipeline.

### The solution — chunk by chunk (binary)

```java
try (InputStream in = new BufferedInputStream(new FileInputStream("large-video.mp4"));
     OutputStream out = new BufferedOutputStream(new FileOutputStream("copy.mp4"))) {
    byte[] buffer = new byte[8192];
    int bytesRead;
    while ((bytesRead = in.read(buffer)) != -1) {
        out.write(buffer, 0, bytesRead);
    }
}
```

**Or, since Java 9, the entire loop collapses to one line:**

```java
try (InputStream in = new FileInputStream("large-video.mp4");
     OutputStream out = new FileOutputStream("copy.mp4")) {
    in.transferTo(out);   // reads and writes internally, handles buffering
}
```

**Real-world use case:** copying uploaded files, streaming a large download to disk without holding it all in memory, piping data between two systems.

---

## 3. Writing to a file

### The problem

You need to save output — logs, generated reports, processed data — to disk.

### The solution

```java
import java.nio.file.*;

// Simple whole-content write (overwrites the file)
Files.writeString(Path.of("output.txt"), "Hello, Alireza!");

// Append instead of overwrite
Files.writeString(Path.of("output.txt"), "\nNew line", StandardOpenOption.APPEND);
```

### Streaming writes (building output incrementally)

```java
try (BufferedWriter writer = Files.newBufferedWriter(Path.of("report.txt"))) {
    for (int i = 1; i <= 1000; i++) {
        writer.write("Line " + i);
        writer.newLine();
    }
}
```

**Why `BufferedWriter` here and not just writing directly:** without buffering, each `write()` call could trigger a disk operation — writing 1000 lines individually would be far slower than batching them, exactly the buffering problem we covered earlier.

**Real-world use case:** writing application logs (though in practice you'd use a logging framework like SLF4J/Logback, which internally does exactly this), generating CSV/report exports, writing processed data back to disk.

---

## 4. Copying, moving, deleting files — `Files` utility methods

### The problem

Basic filesystem operations (copy, move, delete, check existence) shouldn't require manual streams at all.

### The solution

```java
Path source = Path.of("original.txt");
Path dest = Path.of("backup.txt");

Files.copy(source, dest, StandardCopyOption.REPLACE_EXISTING);
Files.move(source, dest, StandardCopyOption.REPLACE_EXISTING);
Files.delete(source);                       // throws if it doesn't exist
Files.deleteIfExists(source);                // safe no-op if missing

boolean exists = Files.exists(dest);
long size = Files.size(dest);
boolean isDirectory = Files.isDirectory(dest);
```

**Real-world use case:** file management utilities, backup scripts, cleanup jobs, build tools.

**Directory operations:**

```java
Files.createDirectories(Path.of("output/reports/2026"));  // creates all missing parent dirs

try (Stream<Path> files = Files.list(Path.of("output"))) {
    files.forEach(System.out::println);      // list directory contents
}

try (Stream<Path> files = Files.walk(Path.of("output"))) {  // recursive
    files.filter(Files::isRegularFile)
         .filter(p -> p.toString().endsWith(".log"))
         .forEach(System.out::println);
}
```

---

## 5. Reading resources bundled inside your application (classpath resources)

### The problem

You have a file that ships _inside_ your JAR (a default config, a template, a lookup table) — not a loose file on the user's disk. `FileInputStream`/`Files` won't find it, because it's packaged inside your application's own classpath, not a normal filesystem path.

### The solution

```java
try (InputStream in = MyClass.class.getResourceAsStream("/templates/email.txt")) {
    if (in == null) {
        throw new IllegalStateException("Resource not found");
    }
    String content = new String(in.readAllBytes(), StandardCharsets.UTF_8);
}
```

**Why this is different:** `getResourceAsStream()` looks inside the compiled classpath (your `.jar`), not the OS filesystem. This is _the_ correct way to bundle static files with your app so they work identically whether you run from an IDE or a packaged JAR.

**Real-world use case:** default configuration templates, static lookup data (country codes, translations), email templates — anything that should ship _with_ the app rather than be provided externally.

**Where this matters in Spring Boot:** Spring's `ClassPathResource` and `@Value("classpath:...")` are built on exactly this mechanism — reading files bundled inside your `src/main/resources` folder.

---

## 6. Reading structured data — CSV/properties/JSON (real parsing)

### The problem

Raw line-by-line text reading gets you strings — but real programs need structured data (key-value pairs, columns, objects).

### `.properties` files — built-in support

```java
Properties props = new Properties();
try (InputStream in = new FileInputStream("app.properties")) {
    props.load(in);
}
String dbUrl = props.getProperty("db.url");
```

**Real-world use case:** simple config files (`.properties` is a genuine Java standard, still used under the hood by Spring Boot's own configuration system).

### CSV — no built-in parser, but common pattern

```java
try (BufferedReader reader = Files.newBufferedReader(Path.of("users.csv"))) {
    String header = reader.readLine(); // skip header row
    String line;
    while ((line = reader.readLine()) != null) {
        String[] fields = line.split(",");
        System.out.println("Name: " + fields[0] + ", Age: " + fields[1]);
    }
}
```

**Caveat worth knowing:** naive `split(",")` breaks on quoted fields containing commas (`"Smith, John",25`). For real CSV work, use a library (Apache Commons CSV, OpenCSV) rather than hand-parsing — this is a classic "looks simple, has hidden edge cases" trap.

### JSON — Java has no built-in JSON library

Unlike `.properties`, Java's standard library has **no** native JSON support. This is exactly why Spring Boot bundles **Jackson** — you'll use `ObjectMapper` (Jackson) for this, not raw `java.io`:

```java
ObjectMapper mapper = new ObjectMapper();
User user = mapper.readValue(new File("user.json"), User.class);  // deserialize
mapper.writeValue(new File("out.json"), user);                     // serialize
```

Under the hood, Jackson still uses `java.io` streams to actually read/write the bytes — it's a layer _on top of_ everything you've learned, not a replacement for it.

---

## 7. Network IO — reading from a URL

### The problem

Sometimes "outside" isn't a file — it's another server.

### The solution

```java
import java.net.URI;
import java.net.http.*;

HttpClient client = HttpClient.newHttpClient();
HttpRequest request = HttpRequest.newBuilder()
    .uri(URI.create("https://api.example.com/data"))
    .build();

HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
System.out.println(response.body());
```

This is the modern approach (`java.net.http.HttpClient`, standardized since Java 11) — it internally still deals with `InputStream`s (you can request `BodyHandlers.ofInputStream()` instead of `ofString()` for streaming large responses), but gives you a much higher-level, purpose-built API than raw socket IO.

**Real-world use case:** calling external REST APIs, downloading files, webhook consumers — though in a Spring Boot app, you'd typically use Spring's `RestClient`/`WebClient` instead, which wraps this same idea with more framework integration.

---

## 8. Exception handling patterns specific to IO (applying what we covered earlier)

### The standard real-world pattern

```java
public String loadConfig(String path) {
    try {
        return Files.readString(Path.of(path));
    } catch (NoSuchFileException e) {
        throw new ConfigurationException("Config file not found: " + path, e);
    } catch (IOException e) {
        throw new ConfigurationException("Failed to read config: " + path, e);
    }
}
```

This applies the exception-chaining pattern from earlier: catch the low-level `IOException`, wrap it in a meaningful domain exception (`ConfigurationException`), and preserve the original cause.

### Handling "file might not exist" gracefully (instead of exception-driven control flow)

```java
Path configPath = Path.of("custom-config.txt");
String config = Files.exists(configPath)
    ? Files.readString(configPath)
    : loadDefaultConfig();
```

**Rule of thumb:** check-then-act (`Files.exists()` first) is fine for expected, common cases. Relying on catching `NoSuchFileException` is fine too — Java's IO exceptions are specific enough to make this a legitimate pattern, unlike, say, using exceptions for normal loop termination.

---

## 9. Recent JDK changes relevant to IO (up to JDK 25)

- **`InputStream.transferTo(OutputStream)`** (Java 9) — covered above; the standard way to copy stream-to-stream without a manual loop.
- **`Files.readString()` / `Files.writeString()`** (Java 11) — replaced the older, clunkier `Files.readAllBytes()` + manual `new String(bytes, charset)` pattern for text files.
- **`InputStream.readAllBytes()` / `readNBytes()`** (Java 9/11) — read an entire stream into a `byte[]` in one call, without a manual buffer loop.
- **Text blocks** (Java 15+, finalized) — while not IO itself, frequently paired with file-writing code for readable multi-line content:
    
    ```java
    String template = """    Dear %s,    Your order has shipped.    """;Files.writeString(Path.of("email.txt"), template.formatted("Alireza"));
    ```
    
- **Virtual threads** (Java 21+, finalized in Project Loom) — don't change the `java.io` API itself, but change its _performance characteristics_ dramatically: traditional blocking IO (`InputStream.read()`, `Socket` reads) used to be expensive to do at scale because each blocking call tied up a full OS thread. With virtual threads, you can now write plain, blocking-style `java.io` code (the exact patterns in this whole tutorial) handling thousands of concurrent connections cheaply — the JVM parks the lightweight virtual thread instead of blocking a real OS thread. This is a big deal for server-side Java (including Spring Boot, which has virtual-thread support) because it means the _simple, readable_ blocking IO style you've been learning is now also the _scalable_ style, without needing complex async/reactive code.
- **Foreign Function & Memory API** (finalized Java 22) — mostly for native interop (calling C libraries), not typical application IO, but worth knowing it exists if you ever need to read memory-mapped native data structures directly.

---

## 10. Full worked example — a realistic small program

Putting several of these together — a program that reads a CSV of users, filters them, and writes a filtered report:

```java
import java.nio.file.*;
import java.util.List;
import java.util.stream.*;

public class UserReportGenerator {

    public static void main(String[] args) {
        Path input = Path.of("users.csv");
        Path output = Path.of("adults-report.txt");

        try (Stream<String> lines = Files.lines(input)) {
            List<String> report = lines
                .skip(1) // skip header
                .map(line -> line.split(","))
                .filter(fields -> Integer.parseInt(fields[1].trim()) >= 18)
                .map(fields -> fields[0] + " is an adult")
                .toList();

            Files.write(output, report); // writes list of lines, one per line

            System.out.println("Report written: " + report.size() + " entries");

        } catch (NoSuchFileException e) {
            System.err.println("Input file not found: " + input);
        } catch (IOException e) {
            System.err.println("Failed to process file: " + e.getMessage());
        }
    }
}
```

This one program uses: `Files.lines()` (streaming read), lambdas/streams (from earlier), `Integer.parseInt()`, `Files.write()`, and proper exception handling with specific-then-general `catch` ordering — essentially everything from this whole conversation, applied together.

---

## Summary: problem → solution map

|Problem|Solution|
|---|---|
|Read a small file fully|`Files.readString()` / `readAllBytes()`|
|Process a huge file without loading it all|`Files.lines()`, `BufferedReader.readLine()` loop, or chunked `InputStream.read()`|
|Write text to a file|`Files.writeString()` or `BufferedWriter`|
|Copy a file/stream efficiently|`Files.copy()` or `InputStream.transferTo()`|
|File/directory management|`Files.exists/delete/move/createDirectories/walk`|
|Read a file bundled inside your app|`Class.getResourceAsStream()`|
|Read simple key-value config|`Properties`|
|Read/write JSON|Jackson's `ObjectMapper` (not raw `java.io`)|
|Call a remote server|`java.net.http.HttpClient`|
|Handle IO failures meaningfully|catch specific `IOException` subtypes, wrap in domain exceptions|
|Scale blocking IO to many concurrent connections|virtual threads (Java 21+) — same code, better scalability|

You now have the full arc: the _concepts_ (streams, buffering, byte vs. character) from earlier in this conversation, plus the _concrete tools_ (`Files.*`, `transferTo`, `HttpClient`) real programs actually reach for — which is the gap between "understanding IO" and "writing IO code in an actual job."

[[Java]]