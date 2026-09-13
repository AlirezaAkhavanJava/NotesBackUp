


You've been using `System.out.println()`, `System.in`, and similar pieces throughout this whole conversation without a formal definition of each part. Let's break down exactly what each piece _is_.

---

## `System` — a class, not an object

```java
System.out.println("Hello");
```

**`System`** is a **final class** in `java.lang` (so it's available automatically, no import needed) that acts as a gateway to system-level facilities — things your program needs from the _outside_ environment (again, that inside/outside boundary): the console, the current time, environment variables, memory management hints.

**Important:** `System` is never instantiated (you never write `new System()`). All its useful members are `static` — you access them directly through the class name. It exists purely as a **namespace/container** for these system-level pieces.

### Key static members of `System`

|Member|Type|What it is|
|---|---|---|
|`System.out`|`PrintStream`|the standard output stream (console)|
|`System.in`|`InputStream`|the standard input stream (keyboard)|
|`System.err`|`PrintStream`|the standard error stream (console, separate from `out`)|
|`System.currentTimeMillis()`|method|current time in milliseconds since Jan 1, 1970|
|`System.exit(int code)`|method|forcibly terminates the JVM|
|`System.arraycopy(...)`|method|fast, low-level array copying|
|`System.getenv()`|method|reads OS environment variables|

---

## `System.out` — a pre-made `PrintStream` object

```java
System.out.println("text");
```

**`out`** is a `public static final` **field** inside `System`, of type `PrintStream`. It's not a method — it's an object, already created and ready to use, that represents **standard output** (by default, your terminal/console).

This connects directly to everything we covered on I/O: `PrintStream` is a subclass of `OutputStream` (the byte-stream family) with extra convenience methods layered on top — specifically for writing readable text instead of raw bytes.

```
OutputStream (abstract, raw bytes)
    └── FilterOutputStream
           └── PrintStream  ← adds print()/println() convenience methods
```

### `println()` vs `print()` vs `printf()` — methods _on_ `PrintStream`

|Method|Behavior|
|---|---|
|`print(x)`|writes `x`, no line break after|
|`println(x)`|writes `x`, **then** a line break (`\n` or `\r\n` depending on OS)|
|`printf(format, args)`|writes formatted text (like C's `printf`) — e.g. `System.out.printf("Age: %d%n", 25);`|

```java
System.out.print("Hello ");
System.out.print("World");
// output: Hello World   (same line)

System.out.println("Hello");
System.out.println("World");
// output:
// Hello
// World          (separate lines)
```

`println()` is overloaded many times (`println(String)`, `println(int)`, `println(boolean)`, `println(Object)`, etc.) — that's why you can pass almost anything to it and it "just works": Java picks the matching overload, and for objects, it calls `.toString()` internally.

---

## `System.in` — a pre-made `InputStream` object

```java
Scanner scanner = new Scanner(System.in);
```

**`in`** is also a `public static final` field on `System`, but of type `InputStream` — the raw byte stream connected to **standard input** (by default, your keyboard). Unlike `out`, `in` has almost no convenience methods of its own (just the barebones `read()` we covered) — that's _why_ you wrap it in something like `Scanner` or `BufferedReader`, exactly as we discussed in the "ways to get user input" tutorial.

```
InputStream (abstract, raw bytes)
    └── System.in is an instance of some InputStream subclass
           (wrapped by Scanner / BufferedReader for usable text)
```

---

## `System.err` — the "other" output stream

```java
System.err.println("Something went wrong!");
```

Same type as `System.out` (`PrintStream`), but conventionally used for **error messages**, kept **separate** from normal output. This separation matters in real usage: command-line tools let you redirect them independently —

```bash
java MyApp > output.txt 2> errors.txt
```

— normal output goes to one file, errors to another, even though both came from the same program. This is why logging frameworks (and exception stack traces, by default) write to `System.err` rather than `System.out`.

---

## `PrintStream` — the class behind `out` and `err`

We've referenced it several times — here's the direct definition: **`PrintStream`** is a class (`java.io.PrintStream`) that wraps a raw `OutputStream` and adds:

- `print()` / `println()` / `printf()` convenience methods
- Automatic conversion of primitives/objects into printable text
- The option to auto-flush (push buffered output out immediately) on newlines

You can even create your own:

```java
PrintStream fileOut = new PrintStream(new FileOutputStream("log.txt"));
fileOut.println("This goes to a file instead of the console");
```

This is the exact decorator pattern we covered under Java I/O — `PrintStream` wraps whatever `OutputStream` you give it.

---

## `Scanner` — recap, now formally placed

```java
Scanner scanner = new Scanner(System.in);
```

**`Scanner`** (`java.util.Scanner`) is a class that wraps an input source (commonly `System.in`, but it can also wrap a `File`, a `String`, or any `InputStream`) and adds parsing — splitting input into tokens and converting them into typed values (`nextInt()`, `nextDouble()`, etc.), as covered in the previous tutorial.

---

## `String` — technically a class, not a primitive

```java
String name = "Alireza";
```

Worth defining precisely since it's used constantly: `String` is a **class** (not a primitive type like `int` or `boolean`), representing an **immutable** sequence of characters. "Immutable" means once created, a `String` object's content can never change — operations like `.toUpperCase()` don't modify the original, they return a **new** `String` object.

```java
String name = "alireza";
name.toUpperCase();          // does NOT change `name`
System.out.println(name);    // still prints: alireza

name = name.toUpperCase();   // must reassign to capture the new String
System.out.println(name);    // now prints: ALIREZA
```

---

## `Integer.parseInt()` — a static utility method

```java
int age = Integer.parseInt("25");
```

`Integer` is the **wrapper class** for the primitive `int` (every primitive has one: `Double` for `double`, `Boolean` for `boolean`, etc.). `parseInt()` is a `static` method on it that converts text (`String`) into a real `int` — this is exactly why, in the `BufferedReader` example earlier, you needed `Integer.parseInt(reader.readLine())` to turn the raw line of text into a usable number.

**Throws `NumberFormatException`** (unchecked, extends `RuntimeException`) if the string isn't a valid number:

```java
int x = Integer.parseInt("abc"); // throws NumberFormatException
```

---

## `Object` — the ultimate parent of everything

Briefly worth mentioning since it underpins a lot of what we've covered: every class in Java, whether you declare it or not, implicitly extends `Object`. This is _why_ `println(Object)` can accept literally anything — every object "is an" `Object` — and why every object automatically has methods like `.toString()`, `.equals()`, and `.hashCode()`, even if you never wrote them yourself (they have default implementations, which you routinely override for classes like `User`).

---

## Quick reference table

|Name|What it is|Package|
|---|---|---|
|`System`|class — gateway to system facilities|`java.lang`|
|`System.out`|field — a `PrintStream` for console output|`java.lang`|
|`System.in`|field — an `InputStream` for console input|`java.lang`|
|`System.err`|field — a `PrintStream` for console error output|`java.lang`|
|`PrintStream`|class — adds print/println/printf on top of `OutputStream`|`java.io`|
|`println()` / `print()` / `printf()`|methods — on `PrintStream`|`java.io`|
|`Scanner`|class — parses typed input from a source|`java.util`|
|`String`|class — immutable text|`java.lang`|
|`Integer` (and other wrapper classes)|class — object wrapper around a primitive, with utility methods like `parseInt()`|`java.lang`|
|`Object`|class — root of every class in Java|`java.lang`|

## Where this all clicks together

```java
Scanner scanner = new Scanner(System.in);   // System.in: InputStream field → wrapped by Scanner
System.out.print("Enter age: ");            // System.out: PrintStream field → print() method
String input = scanner.nextLine();          // Scanner reads text, returns a String object
int age = Integer.parseInt(input);          // Integer: wrapper class, parseInt(): static method
System.out.println("You are " + age);       // println(): PrintStream method, overloaded for any type
```

Every line here is a class or method we've now defined individually — this is genuinely the whole picture of "basic console I/O" in Java, just assembled from pieces you now know by name.


[[Java]]