
Think of an **I/O stream as a pipe** between your Java program and something outside the program.

```text
RESOURCE  ──────>  INPUT STREAM  ──────>  Java Program
Java Program ─────> OUTPUT STREAM ──────>  DESTINATION
```

### What is a resource?

A **resource** is the thing your program gets data **from**.

Common examples:

|Resource|Example|
|---|---|
|File|`users.txt`|
|Keyboard|User typing into terminal|
|Network connection|Data received from a server|
|Database|Rows returned by PostgreSQL|
|Memory|A `byte[]` or `String`|
|Another program|Output of another process|

For example:

```java
FileInputStream input = new FileInputStream("users.txt");
```

Here:

```text
users.txt
    ↓
FileInputStream
    ↓
Java program
```

`users.txt` is the **resource**.

---

### What is a destination?

A **destination** is where your program sends data **to**.

Common destinations:

|Destination|Example|
|---|---|
|File|`output.txt`|
|Terminal|`System.out`|
|Network connection|Sending data to a server|
|Database|Sending SQL/data|
|Memory|`ByteArrayOutputStream`|
|Another program|Sending input to its stdin|

Example:

```java
FileOutputStream output = new FileOutputStream("output.txt");

output.write("Hello".getBytes());
```

The flow is:

```text
Java program
     ↓
FileOutputStream
     ↓
output.txt
```

`output.txt` is the **destination**.

---

### The important distinction

**Input and output are relative to your program.**

If your Java program reads a file:

```text
file → Java
```

the file is the **input resource**.

If your Java program writes to that file:

```text
Java → file
```

the file is the **output destination**.

The same physical thing can therefore be either one.

### In Java terminology

You can mentally map them like this:

```text
INPUT
Resource ──→ InputStream/Reader ──→ Your program


OUTPUT
Your program ──→ OutputStream/Writer ──→ Destination
```

And the big distinction is:

- **`InputStream` / `OutputStream`** → raw **bytes**
    
- **`Reader` / `Writer`** → **characters/text**
    

So when Java documentation says something like _"an input stream reads data from a source"_ and _"an output stream writes data to a destination"_, **source/resource and destination are deliberately generic**. They could be a file, socket, keyboard, memory buffer, etc.

[[Java]]