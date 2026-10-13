# File Class in Java

The `File` class in Java (part of `java.io` package) is an abstract representation of file and directory pathnames. It provides methods to create, delete, inspect, and manipulate files and directories — but **not** to read or write their contents (that's handled by streams/readers).

## Declaration

```java
public class File extends Object implements Serializable, Comparable<File>
```

## Constructors

| Constructor | Description |
|---|---|
| `File(String pathname)` | Creates a File from a path string |
| `File(String parent, String child)` | Creates a File from parent path + child name |
| `File(File parent, String child)` | Creates a File from parent File + child name |
| `File(URI uri)` | Creates a File from a `file:` URI |

## Common Methods

### Inspection
- `boolean exists()` — checks if file/directory exists
- `boolean isFile()` — checks if it's a file
- `boolean isDirectory()` — checks if it's a directory
- `boolean canRead()` / `canWrite()` / `canExecute()`
- `String getName()` — returns file/directory name
- `String getPath()` — returns path as string
- `String getAbsolutePath()` — returns absolute path
- `String getParent()` — returns parent path
- `long length()` — returns size in bytes
- `long lastModified()` — returns last modified timestamp
- `String[] list()` — lists directory contents
- `File[] listFiles()` — lists directory contents as File objects

### Manipulation
- `boolean createNewFile()` — creates an empty file
- `boolean mkdir()` — creates a directory
- `boolean mkdirs()` — creates directory including parents
- `boolean delete()` — deletes file/directory
- `boolean renameTo(File dest)` — renames file
- `boolean setReadOnly()` — marks read-only
- `boolean setLastModified(long time)`
- `boolean setWritable(boolean)`, `setReadable(boolean)`, `setExecutable(boolean)`

## Example

```java
import java.io.File;
import java.io.IOException;

public class FileDemo {
    public static void main(String[] args) {
        // Create a File object (does NOT create actual file)
        File file = new File("example.txt");

        try {
            // Create the physical file
            if (file.createNewFile()) {
                System.out.println("File created: " + file.getName());
            } else {
                System.out.println("File already exists.");
            }

            // Basic info
            System.out.println("Path: " + file.getAbsolutePath());
            System.out.println("Exists: " + file.exists());
            System.out.println("Is File: " + file.isFile());
            System.out.println("Size: " + file.length() + " bytes");
            System.out.println("Readable: " + file.canRead());
            System.out.println("Writable: " + file.canWrite());

        } catch (IOException e) {
            System.out.println("Error: " + e.getMessage());
        }
    }
}
```

## Working with Directories

```java
File dir = new File("myFolder");
if (dir.mkdir()) {
    System.out.println("Directory created");
}

// Nested directories
File nested = new File("a/b/c");
nested.mkdirs();   // creates all parent dirs

// List contents
File[] files = dir.listFiles();
if (files != null) {
    for (File f : files) {
        System.out.println(f.getName() + " - " + f.length());
    }
}
```

## Important Notes

1. **`File` is just a path abstraction** — `new File("x.txt")` doesn't touch the disk. Only methods like `createNewFile()`, `mkdir()`, `delete()` do.
2. **Platform-dependent separators** — Use `File.separator` or `Paths.get(...)` instead of hardcoded `/` or `\`.
3. **`delete()` limitations** — Can't delete non-empty directories; use `Files.delete()` or delete contents first.
4. **Modern alternative** — Since Java 7, prefer **`java.nio.file.Path`** and **`Files`** for more robust file handling.

## Related Classes

- `FileReader` / `FileWriter` — character streams
- `FileInputStream` / `FileOutputStream` — byte streams
- `RandomAccessFile` — read/write at any position
- `Files` / `Paths` (NIO.2) — modern file API
---
# `File` vs `Files` in Java

Both deal with file system operations, but they belong to different APIs and have very different roles.

| Aspect | `java.io.File` | `java.nio.file.Files` |
|---|---|---|
| **Type** | Class (concrete) | Final utility class (static methods only) |
| **Since** | Java 1.0 | Java 7 (NIO.2) |
| **Represents** | A path *and* an abstraction of a file/directory | *Operations* on paths — never instantiated |
| **Companion** | — | `Path` / `Paths` (represent the path) |
| **Error handling** | Returns `boolean` / `null` (silent failures) | Throws `IOException` (explicit) |
| **Instantiation** | `new File("a.txt")` | Cannot instantiate; use `Files.xxx(...)` |

> **Key mental model:**
> `File` = **the "thing"** (a path object with methods).
> `Files` = **the "toolbox"** (static helpers that operate on `Path` objects).

---

## 1. The Core Difference

```java
// OLD — java.io.File : object represents the path
File f = new File("data.txt");
boolean ok = f.createNewFile();   // returns false on failure — why? no idea.
f.delete();                       // returns false silently if it fails.

// NEW — java.nio.file : Path represents the path, Files does the work
Path p = Paths.get("data.txt");
Files.createFile(p);              // throws IOException with a reason
Files.delete(p);                  // throws NoSuchFileException / DirectoryNotEmptyException
```

`Path` is the modern replacement for `File` as a **path representation**.  
`Files` is the modern replacement for **File's operation methods**.

---

## 2. Feature Comparison

| Operation | `File` | `Files` |
|---|---|---|
| Create file | `createNewFile()` | `Files.createFile(path)` |
| Create dir | `mkdir()` / `mkdirs()` | `Files.createDirectory()` / `Files.createDirectories()` |
| Delete | `delete()` | `Files.delete()` / `Files.deleteIfExists()` |
| Copy | ❌ (manual) | `Files.copy(src, dst, options)` |
| Move/rename | `renameTo()` (unreliable) | `Files.move(src, dst, options)` |
| Read all text | ❌ (need streams) | `Files.readString()` / `Files.readAllLines()` |
| Write text | ❌ (need streams) | `Files.writeString()` / `Files.write()` |
| Read bytes | ❌ | `Files.readAllBytes()` |
| Size | `length()` | `Files.size(path)` |
| Exists | `exists()` | `Files.exists(path)` |
| Is directory | `isDirectory()` | `Files.isDirectory(path)` |
| Last modified | `lastModified()` | `Files.getLastModifiedTime(path)` |
| Set permissions | `setReadable/Writable/Executable` | `Files.setPosixFilePermissions(...)` |
| Symbolic links | ❌ (limited) | `Files.createSymbolicLink()`, `Files.readSymbolicLink()` |
| Walk directory tree | ❌ | `Files.walk()`, `Files.walkFileTree()` |
| Watch for changes | ❌ | `WatchService` + `Files` |
| Temp files | `createTempFile()` | `Files.createTempFile()` |
| Attributes | basic only | `Files.readAttributes()` (full POSIX/DOS) |
| Atomic operations | ❌ | `Files.move(..., ATOMIC_MOVE)` |

---

## 3. Side-by-Side Examples

### Creating and deleting

```java
// File
File f = new File("test.txt");
if (!f.exists()) {
    f.createNewFile();     // throws IOException, returns boolean
}
f.delete();                // returns false if it failed — no reason given

// Files
Path p = Paths.get("test.txt");
Files.createFile(p);       // throws FileAlreadyExistsException, IOException
Files.deleteIfExists(p);   // throws IOException with specific cause
```

### Reading a text file

```java
// File — must chain streams manually
StringBuilder sb = new StringBuilder();
try (BufferedReader br = new BufferedReader(new FileReader("a.txt"))) {
    String line;
    while ((line = br.readLine()) != null) sb.append(line).append("\n");
}

// Files — one line (Java 11+)
String content = Files.readString(Paths.get("a.txt"));

// Java 7/8
List<String> lines = Files.readAllLines(Paths.get("a.txt"));
```

### Copying a file

```java
// File — manual stream copy
try (InputStream in = new FileInputStream("a.txt");
     OutputStream out = new FileOutputStream("b.txt")) {
    byte[] buf = new byte[8192];
    int n;
    while ((n = in.read(buf)) != -1) out.write(buf, 0, n);
}

// Files — one call
Files.copy(Paths.get("a.txt"), Paths.get("b.txt"),
           StandardCopyOption.REPLACE_EXISTING);
```

### Listing a directory

```java
// File
File[] files = new File(".").listFiles();

// Files — returns a Stream<Path>
try (Stream<Path> stream = Files.list(Paths.get("."))) {
    stream.filter(Files::isRegularFile)
          .forEach(System.out::println);
}
```

---

## 4. When to Use Which

### ✅ Use `Files` + `Path` (preferred, modern)
- All new code (Java 7+).
- When you need to **copy, move, read, write** files.
- When you need **precise error messages** (`IOException` with cause).
- When working with **symbolic links, permissions, attributes**.
- When you need **directory walking** or **streams of paths**.

### ⚠️ Use `File` (legacy / interop)
- When an API **requires a `File`** (e.g., old libraries, `FileInputStream`, `FileWriter`, `JFileChooser`).
- When maintaining **legacy code**.
- Rarely for new code — even then, convert with `path.toFile()` / `file.toPath()`.

### Bridging between them

```java
File file = new File("a.txt");
Path path = file.toPath();       // File → Path

Path p = Paths.get("b.txt");
File f = p.toFile();             // Path → File
```

---

## 5. Error Handling — The Biggest Difference

`File` methods return booleans and give you **no clue why** they failed:

```java
File f = new File("/root/secret.txt");
if (!f.delete()) {
    // failed — but why? Permission? Not found? Locked? Unknown.
}
```

`Files` throws specific exceptions:

```java
try {
    Files.delete(Paths.get("/root/secret.txt"));
} catch (NoSuchFileException e) {
    System.out.println("File doesn't exist");
} catch (DirectoryNotEmptyException e) {
    System.out.println("Directory not empty");
} catch (AccessDeniedException e) {
    System.out.println("Permission denied");
} catch (IOException e) {
    System.out.println("Other I/O error: " + e.getMessage());
}
```

This alone makes `Files` far better for production code.

---

## 6. Summary Table

| Question | Answer |
|---|---|
| Which represents a path? | **`Path`** (modern), `File` (legacy) |
| Which performs operations? | **`Files`** |
| Which is a static utility class? | **`Files`** |
| Which throws checked exceptions? | **`Files`** |
| Which should new code use? | **`Path` + `Files`** |
| Which is still needed for old APIs? | **`File`** |
| Can they be converted? | Yes: `file.toPath()` / `path.toFile()` |

---

## Key Takeaway

- **`File`** = old class that mixes *path representation* + *operations*, with silent failure modes.
- **`Path`** = new interface for *path representation*.
- **`Files`** = new static utility class for *all operations on `Path`*.

**Rule of thumb:** In new code use `Path` + `Files`. Fall back to `File` only when a legacy API forces you to.

[[Java]]