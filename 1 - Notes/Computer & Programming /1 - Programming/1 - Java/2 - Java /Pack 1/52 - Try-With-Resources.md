
In **Java**, **try-with-resources** is a special form of `try` statement that **automatically closes resources** after you're done using them.

It is commonly used with resources such as files, streams, database connections, and scanners.

### Example

```java
try (Scanner scanner = new Scanner(new File("data.txt"))) {
    while (scanner.hasNextLine()) {
        System.out.println(scanner.nextLine());
    }
} catch (FileNotFoundException e) {
    System.out.println("File not found");
}
```

The important part is:

```java
try (Scanner scanner = ...) {
    // use scanner
}
```

When the `try` block finishes, Java automatically calls:

```java
scanner.close();
```

even if an exception occurs.

### Without try-with-resources

You'd normally have to close the resource yourself:

```java
Scanner scanner = null;

try {
    scanner = new Scanner(new File("data.txt"));
    // use scanner
} finally {
    if (scanner != null) {
        scanner.close();
    }
}
```

Try-with-resources makes this much cleaner.

**Rule:** The object declared inside `try (...)` must implement `AutoCloseable` (or `Closeable`).

So you can think of it as:

> **try-with-resources = try + automatic cleanup/closing of resources.**


In **modern Java, including JDK 25**, try-with-resources is still the standard mechanism for deterministic resource cleanup.

### Definition — JDK 25

> **Try-with-resources is a `try` statement that declares one or more `AutoCloseable` resources and guarantees that they are automatically closed when the `try` block exits.**

Basic syntax:

```java
try (Resource resource = createResource()) {
    // use resource
}
```

Example with `BufferedReader`:

```java
try (BufferedReader reader = Files.newBufferedReader(Path.of("data.txt"))) {
    String line = reader.readLine();
    System.out.println(line);
}
```

Conceptually, Java guarantees:

```java
reader.close();
```

when leaving the `try` block, including when an exception occurs.

### JDK 9+ / JDK 25 improvement

Modern Java also lets you use an **already-declared effectively-final variable**:

```java
BufferedReader reader =
        Files.newBufferedReader(Path.of("data.txt"));

try (reader) {
    System.out.println(reader.readLine());
}
```

This is important because older Java required the resource to be declared directly inside `try (...)`.

### Multiple resources

```java
try (
    InputStream in = Files.newInputStream(input);
    OutputStream out = Files.newOutputStream(output)
) {
    in.transferTo(out);
}
```

Resources are closed in **reverse order**:

```text
out.close()
in.close()
```

So, for JDK 25, the mental model is:

```text
try-with-resources
        ↓
resource implements AutoCloseable
        ↓
use resource
        ↓
try exits
        ↓
Java automatically calls close()
        ↓
even if an exception occurs
```

This is the modern Java way to handle **I/O streams, files, sockets, JDBC resources, etc.**


[[Java]]