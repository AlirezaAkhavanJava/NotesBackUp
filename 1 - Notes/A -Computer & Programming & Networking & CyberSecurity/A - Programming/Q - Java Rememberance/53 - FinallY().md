Think of a **resource** as something your Java program opens that represents an external thing the program is interacting with.

### What is an "open resource"?

Consider a file:

```
BufferedReader reader =
        Files.newBufferedReader(Path.of("data.txt"));
```

When this runs, Java asks the operating system to **open the file**.

Conceptually:

```
Java program
     |
     v
Operating System
     |
     v
data.txt
```

The OS creates/allocates things needed to maintain that connection, such as a **file descriptor**.

So the `reader` is now an **open resource**.

You can use it:

```
reader.readLine();
reader.readLine();
reader.readLine();
```

### What does "close" mean?

Eventually you're finished with the file.

```
reader.close();
```

Closing means:

> "I don't need this external resource anymore. Release the underlying OS/system resources associated with it."

After closing:

```
Java program
     |
     X
Operating System
     |
     X
data.txt
```

The Java object may still exist in memory, but its underlying external resource is no longer available through it.

For example:

```
reader.close();

reader.readLine(); // ❌ typically throws IOException
```

---

# Why do we need to close resources?

Because these resources are **limited system resources**.

Imagine:

```
for (int i = 0; i < 1_000_000; i++) {
    BufferedReader reader =
        Files.newBufferedReader(Path.of("data.txt"));

    // use it
}
```

If you never close them, you can accumulate open file descriptors:

```
open file #1
open file #2
open file #3
...
open file #10000
...
```

Eventually the operating system can say:

```
Too many open files
```

So closing is **resource management**, not simply "destroying an object."

---

# Now: what is `finally`?

`finally` is a block that Java executes when leaving a `try`/`catch` structure, generally whether an exception occurred or not.

Example:

```
BufferedReader reader = null;

try {
    reader = Files.newBufferedReader(Path.of("data.txt"));

    System.out.println(reader.readLine());

} catch (IOException e) {
    System.out.println("Something went wrong");

} finally {
    if (reader != null) {
        reader.close();
    }
}
```

The important idea is:

```
try
 ↓
use resource
 ↓
exception? ─── yes ──→ catch
       │
       no
       │
       └──────────────┐
                      ↓
                   finally
                      ↓
                 close resource
```

The `finally` block was traditionally used to guarantee cleanup.

---

# Then try-with-resources

Java created a cleaner mechanism:

```
try (BufferedReader reader =
         Files.newBufferedReader(Path.of("data.txt"))) {

    System.out.println(reader.readLine());
}
```

Java automatically handles the closing.

Conceptually, this is roughly equivalent to:

```
BufferedReader reader =
        Files.newBufferedReader(Path.of("data.txt"));

try {
    System.out.println(reader.readLine());

} finally {
    reader.close();
}
```

So:

```
try-with-resources
        ↓
open resource
        ↓
use resource
        ↓
leave try block
        ↓
automatically close resource
```

---

# What exactly counts as a resource?

In Java, a resource used by try-with-resources must implement:

```
AutoCloseable
```

For example:

```
FileInputStream
FileOutputStream
BufferedReader
BufferedWriter
Scanner
Socket
Database Connection
PreparedStatement
ResultSet
```

They represent things that need some form of cleanup.

### The key distinction

Don't think:

> "Open = Java object exists."

Think:

> **Open = the Java object currently owns/uses an external resource.**

For example:

```
FileInputStream stream =
        new FileInputStream("data.txt");
```

The `FileInputStream` object is a Java object **and** it represents an open OS file.

After:

```
stream.close();
```

the Java object can still exist:

```
Java object:        EXISTS ✅
Underlying file:    CLOSED ✅
```

That's an extremely important distinction.

**Object lifetime ≠ resource lifetime.**

And that's precisely why Java has `try-with-resources`: it manages the **resource lifetime** automatically.

[[Java]]