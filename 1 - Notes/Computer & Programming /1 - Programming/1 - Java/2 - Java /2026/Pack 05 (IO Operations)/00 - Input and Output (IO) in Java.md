

**I/O** stands for **input and output**. It is the way a program moves data between itself and the outside world: files on disk, the keyboard and screen, network connections, and other programs. **Input** brings data into the program. **Output** sends data from the program to somewhere else.

Every program needs I/O. A program that cannot read or write data can compute results but cannot save them, receive a request, or show anything to a user.

## Why I/O needs special treatment

Inside the program, data lives in memory, which is fast and temporary. Outside the program, data lives in places like disks and networks. Those places are much slower than memory and the CPU, and they can fail. A disk can be full, a file can be missing, and a network connection can drop.

Because of this, Java treats I/O as a separate concern with its own rules:

- Operations can fail, so most I/O methods throw `IOException`, a **checked exception** that the compiler forces you to handle or declare.
- Outside resources such as file handles and sockets are limited, so they must be **closed** when you finish with them.
- Reading and writing one byte at a time is very slow, so I/O is usually **buffered**, meaning data moves in larger chunks.

## The central idea: streams

A **stream** is a sequence of data that flows in one direction, read or written in order. You do not need to know whether the data comes from a file, a network socket, or the keyboard. The code reads from the stream the same way.

Java splits streams into two families based on the unit of data:

|Family|Unit|Base classes|Use it for|
|---|---|---|---|
|Byte streams|8-bit bytes|`InputStream`, `OutputStream`|Anything: images, PDFs, zip files, any binary data|
|Character streams|16-bit chars, decoded with a charset|`Reader`, `Writer`|Text|

The rule is simple: use byte streams for raw data and character streams for text. Text stored as bytes must be decoded with a **charset** such as UTF-8 to become characters. Forgetting this step is the source of most garbled-text bugs.

Each family has concrete classes for each source. For example, `FileInputStream` reads bytes from a file, and `FileReader` reads characters from one.

## Wrapping streams: the decorator pattern

A basic stream reads one thing at a time. A **wrapper** (or decorator) adds a feature by holding another stream inside it and delegating to it. `BufferedReader` wraps a `Reader` and adds buffering and the `readLine` method. The same chain can be nested:

```java
BufferedReader reader = new BufferedReader(
        new InputStreamReader(new FileInputStream("notes.txt"), StandardCharsets.UTF_8));
```

Reading from the outside in:

1. `FileInputStream` reads raw bytes from the file.
2. `InputStreamReader` decodes those bytes into characters using UTF-8.
3. `BufferedReader` collects characters into a buffer and provides `readLine`.

Each layer does one job. You combine layers to get the features you need.

## Closing resources: try-with-resources

Streams hold operating system resources, so they must be closed, even if an exception occurs in the middle. The `try-with-resources` statement does this automatically for any object that implements `AutoCloseable`, which all streams do:

```java
try (BufferedReader reader = new BufferedReader(new FileReader("notes.txt"))) {
    System.out.println(reader.readLine());
}   // reader is closed here, whether or not an exception happened
```

Before Java 7, you had to write a `finally` block and close the stream by hand, which was error-prone. Use try-with-resources every time.

## Example 1: writing and reading text

Create a folder and save this as `TextIODemo.java`:

```java
import java.io.*;
import java.nio.charset.StandardCharsets;

public class TextIODemo {
    public static void main(String[] args) throws IOException {
        File file = new File("notes.txt");   // relative path: the current folder

        // Output: characters -> UTF-8 bytes -> file, buffered
        try (BufferedWriter writer = new BufferedWriter(
                new OutputStreamWriter(new FileOutputStream(file), StandardCharsets.UTF_8))) {
            writer.write("Field trip on Friday");
            writer.newLine();
            writer.write("Bring a lunch");
            writer.newLine();
        }

        // Input: file -> UTF-8 bytes -> characters, buffered, line by line
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(new FileInputStream(file), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {   // null means end of file
                System.out.println("read: " + line);
            }
        }
    }
}
```

Run it on Debian:

```bash
mkdir -p ~/java-lessons/io && cd ~/java-lessons/io
nano TextIODemo.java      # paste the code, save, exit
javac TextIODemo.java
java TextIODemo
cat notes.txt             # confirm the file on disk
```

What each part does:

- The output chain writes characters, which are encoded to UTF-8 bytes, then goes to the file. `newLine()` writes the platform's line separator.
- The input chain reverses the process. `readLine()` returns `null` at end of file, and the loop stops there.
- Both blocks use try-with-resources, so the files are closed before the program moves on. This is why the `cat` command shows complete contents.
- The charset is named explicitly. Without it, the program uses the platform default, and text written on one machine may read incorrectly on another.

## Example 2: copying raw bytes

Byte streams are the right tool for binary data, and they show the low-level read loop clearly. Save this as `CopyDemo.java`:

```java
import java.io.*;

public class CopyDemo {
    public static void main(String[] args) throws IOException {
        try (InputStream in = new FileInputStream("notes.txt");
             OutputStream out = new FileOutputStream("copy.txt")) {

            byte[] buffer = new byte[8192];        // move 8 KB per step
            int count;
            while ((count = in.read(buffer)) != -1) {   // -1 means end of stream
                out.write(buffer, 0, count);            // write only the bytes actually read
            }
        }
        System.out.println("copied");
    }
}
```

Run it with `javac CopyDemo.java && java CopyDemo`, then compare the files with `cmp notes.txt copy.txt`. No output means they are identical.

What this demonstrates:

- `read(buffer)` fills the array and returns how many bytes it placed there. It is not always the full array size.
- `write(buffer, 0, count)` writes only the first `count` bytes. Writing the whole buffer would copy stale data at the end of the last chunk.
- The loop checks for `-1`, not for `0`. Zero can occur legitimately in some streams, and `-1` is the only end-of-stream signal.

## Example 3: the modern way, `java.nio.file`

For most file tasks, the `Files` and `Path` classes (Java 7 onward, with convenient methods added in 11) are shorter and clearer than the stream chains above. Save this as `NioDemo.java`:

```java
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.List;

public class NioDemo {
    public static void main(String[] args) throws IOException {
        Path path = Path.of("notes.txt");

        // Append a line, creating the file if it does not exist
        Files.writeString(path, "Parent evening on Thursday\n",
                StandardCharsets.UTF_8,
                StandardOpenOption.CREATE, StandardOpenOption.APPEND);

        // Read the whole file as one String
        String everything = Files.readString(path, StandardCharsets.UTF_8);
        System.out.println(everything);

        // Read the file as a list of lines
        List<String> lines = Files.readAllLines(path, StandardCharsets.UTF_8);
        System.out.println("line count: " + lines.size());
    }
}
```

What it shows:

- `Path.of` describes a location. It does not open anything. Operations on the path do the actual I/O.
- `Files.writeString` and `Files.readString` open, transfer, and close the file in one call, so there is no resource to forget.
- `StandardOpenOption` controls the behavior. Here `APPEND` adds to the end instead of overwriting.

Use `Files.readString` and `Files.readAllLines` only for files that fit comfortably in memory. For large files, read lazily with `Files.lines(path)`, and close the returned stream with try-with-resources, because it holds the file open.

## Console input and output

The console is also a stream. `System.out` is a `PrintStream`, which is an `OutputStream` with convenient print methods. `System.in` is an `InputStream` connected to the keyboard. `Scanner` wraps it to read typed values:

```java
import java.util.Scanner;

public class ConsoleDemo {
    public static void main(String[] args) {
        try (Scanner in = new Scanner(System.in)) {
            System.out.print("Your name: ");
            String name = in.nextLine();
            System.out.println("Hello, " + name);
        }
    }
}
```

`Scanner` is convenient for simple input. For heavy parsing or performance-sensitive input, `BufferedReader` is the usual choice.

## Blocking, and why it matters

Classic `java.io` operations are **blocking**. When a thread calls `read` and no data is available yet, the thread waits. That is fine for a command-line tool, but a server that handles many clients cannot afford one waiting thread per connection.

`java.nio` provides **channels**, **buffers**, and **selectors**, which allow one thread to watch many connections and act only when data is ready. Spring Boot's embedded Tomcat uses this kind of NIO internally, and Spring WebFlux is built on non-blocking I/O. You do not need to write NIO code to use Spring, but knowing that blocking I/O holds a thread is important when you think about performance under load.

## Where you will see I/O in Spring Boot

Spring hides most of the stream plumbing, but it is always there underneath:

- **Reading configuration.** `application.properties` and `application.yml` are read as streams and bound to your classes, the same binding idea from the first lesson.
- **Request bodies.** `@RequestBody` reads the incoming HTTP body, which is an `InputStream` at the servlet level, and converts it to a Java object.
- **File uploads.** `MultipartFile` gives you the uploaded data, and you can call `getInputStream()` or `transferTo(path)` to save it.
- **Resources.** Spring's `Resource` abstraction loads files from the classpath or the filesystem through the same I/O classes.

## Pitfalls to avoid

- **Not closing a stream.** The file stays locked, the operating system runs out of handles, and data written through a buffered stream may never reach the disk. Always use try-with-resources.
- **Ignoring the charset.** Different machines use different defaults. Specify UTF-8 explicitly when reading or writing text.
- **Reading a huge file into memory.** `readString` on a multi-gigabyte file can crash the program with an out-of-memory error. Stream it line by line instead.
- **Assuming `read` fills the buffer.** It returns how many bytes it actually read. Always use that count.
- **Swallowing `IOException`.** An empty `catch` hides a failed write, and the data is lost without any warning.
- **Forgetting to flush.** A `BufferedWriter` holds data in memory until it is flushed or closed. Closing it with try-with-resources handles this for you.

## How you'll use this

Most day-to-day Java code uses `Files` and `Path` for file work, `Scanner` or `BufferedReader` for console input, and streams only when you handle binary data or network connections. In Spring Boot, you will rarely open a stream yourself, but you will often receive one, and you need to know that it must be read, that it may fail, and that it should not be left open.

For Family Inbox, a feature that imports a school's CSV list of families would use `Files.lines` to process the file one row at a time, with UTF-8 specified so that names with accents are read correctly.




[[Java]]