

## 1. `String` (java.lang)

**Immutable** sequence of characters. Every "modifying" method returns a **new** `String`.

### Most common methods (String → String, chainable)

```java
String s = "  Hello World  ";

// Case
s.toLowerCase();           // "  hello world  "
s.toUpperCase();           // "  HELLO WORLD  "
s.toLowerCase(Locale.ROOT);

// Trim / strip
s.trim();                  // "Hello World"
s.strip();                 // Unicode-aware
s.stripLeading();
s.stripTrailing();

// Substring
s.substring(2);            // "Hello World  "
s.substring(2, 7);         // "Hello"

// Replace
s.replace('l', 'L');       // "  HeLLo WorLd  "
s.replace("World", "Java");// "  Hello Java  "
s.replaceAll("\\s+", "_"); // "__Hello_World__"
s.replaceFirst("l", "L");  // "  HeLlo World  "

// Concat / repeat / indent
s.concat("!");             // "  Hello World  !"
"ab".repeat(3);            // "ababab"
"line1\nline2".indent(4);  // "    line1\n    line2\n"

// Transform (Java 12+)
s.transform(x -> x + "!"); // "  Hello World  !"

// Formatted (Java 15+)
"%s=%d".formatted("x", 1);// "x=1"

// intern
s.intern();
```

### Methods returning other types (chain ends)

```java
s.length();                    // int
s.charAt(0);                   // char
s.indexOf("World");            // int (8)
s.lastIndexOf('l');            // int
s.contains("World");           // boolean
s.startsWith("  ");            // boolean
s.endsWith("  ");              // boolean
s.isEmpty();                   // boolean
s.isBlank();                   // boolean (Java 11+)
s.equals("x");                 // boolean
s.equalsIgnoreCase("x");       // boolean
s.compareTo("x");              // int
s.split(",");                  // String[]
s.toCharArray();               // char[]
s.getBytes();                  // byte[]
s.lines();                     // Stream<String>
s.chars();                     // IntStream
```

### Visual chain

```java
String result = "  Hello World  "
        .strip()               // "Hello World"
        .toLowerCase()         // "hello world"
        .replace("world", "java") // "hello java"
        .repeat(2)             // "hello javahello java"
        .substring(0, 10)      // "hello java"
        .concat("!");          // "hello java!"
```

---

## 2. `STRING` (javax.print.DocFlavor)

**A constant**, not a class. Represents `"text/plain; charset=utf-16"`.

### Common methods (from its parent `DocFlavor`)

```java
DocFlavor.STRING        // constant: "text/plain; charset=utf-16"
DocFlavor.STRING.getMimeType();     // "text/plain; charset=utf-16"
DocFlavor.STRING.getMediaType();    // "text/plain"
DocFlavor.STRING.getEncoding();     // "utf-16"
DocFlavor.STRING.getRepresentationClassName(); // "java.lang.String"
```

### Usage

```java
DocPrintJob job = printer.createPrintJob();
Doc doc = new SimpleDoc("Hello Print", DocFlavor.STRING, null);
job.print(doc, null);
```

No chaining — it's a value object.

---

## 3. `Strings` (Pack1)

**Your custom class** — we don't have its source, but typically it looks like this:

```java
package Pack1;

public final class Strings {
    private Strings() {}

    public static boolean isNullOrEmpty(String s) {
        return s == null || s.isEmpty();
    }
    public static String capitalize(String s) {
        return (s == null || s.isEmpty()) ? s
             : Character.toUpperCase(s.charAt(0)) + s.substring(1).toLowerCase();
    }
    public static String reverse(String s) {
        return new StringBuilder(s).reverse().toString();
    }
    public static String defaultIfBlank(String s, String def) {
        return (s == null || s.isBlank()) ? def : s;
    }
    public static String join(String sep, Object... parts) {
        return String.join(sep, java.util.Arrays.stream(parts)
                .map(String::valueOf).toArray(String[]::new));
    }
}
```

### Chain example

```java
String out = Strings.defaultIfBlank(userInput, "Guest")
                    .transform(Strings::capitalize)
                    .concat("!");
// userInput=null  → "Guest!"
// userInput="bob" → "Bob!"
```

---

## 4. `StringBuffer` (java.lang)

**Mutable**, **thread-safe** (all methods `synchronized`). Legacy — replaced by `StringBuilder` except in multithreaded code.

### Common methods (return `StringBuffer` → chainable)

```java
StringBuffer sb = new StringBuffer("Hello");

sb.append(" World")        // "Hello World"
  .append(123)             // "Hello World123"
  .append('!')             // "Hello World123!"
  .append(true);           // "Hello World123!true"

sb.insert(5, ",");         // "Hello, World123!true"
sb.replace(0, 5, "Hi");    // "Hi, World123!true"
sb.delete(0, 3);           // ", World123!true"
sb.deleteCharAt(0);        // " World123!true"
sb.reverse();              // "eurt!321dlroW "
sb.setCharAt(0, 'X');      // "Xurt!321dlroW "
sb.setLength(3);           // "Xur"
```

### Return types

```java
sb.length();               // int
sb.charAt(0);              // char
sb.indexOf("x");           // int
sb.capacity();             // int (buffer size, not length)
sb.toString();             // String ← final conversion
sb.substring(0,2);         // String ← not StringBuffer
```

### Chain

```java
String s = new StringBuffer()
        .append("user=").append("alice")
        .append("&role=").append("admin")
        .reverse()
        .toString();
// "nimda=srol&ecila=resu"
```

---

## 5. `StringBuilder` (java.lang)

Same API as `StringBuffer`, but **not synchronized** → **faster**. Use this by default.

### Common methods (return `StringBuilder` → chainable)

```java
StringBuilder sb = new StringBuilder("Hello");

sb.append(" World")        // "Hello World"
  .append(123)
  .append('!')
  .append(true)
  .insert(5, ",")
  .replace(0, 5, "Hi")
  .delete(0, 3)
  .deleteCharAt(0)
  .reverse()
  .setCharAt(0, 'X');
```

### Return types

```java
sb.length();               // int
sb.charAt(0);              // char
sb.indexOf("x");           // int
sb.capacity();             // int
sb.toString();             // String ← final
sb.substring(0,2);         // String
```

### Real-world chain

```java
String csv = new StringBuilder()
        .append("id,name,score").append(System.lineSeparator())
        .append(1).append(',').append("Alice").append(',').append(95).append(System.lineSeparator())
        .append(2).append(',').append("Bob").append(',').append(88)
        .toString();
```

---

## 6. `StringIndexOutOfBoundsException` (java.lang)

Runtime exception thrown when `String`/`StringBuilder` receives a bad index.

### How to trigger

```java
"abc".charAt(5);           // throws
"abc".substring(0, 10);    // throws
"abc".substring(-1);       // throws
new StringBuilder("ab").insert(10, "x"); // throws
```

### How to catch

```java
try {
    char c = text.charAt(index);
} catch (StringIndexOutOfBoundsException e) {
    System.out.println("Bad index: " + e.getMessage()); // "String index out of range: 5"
}
```

### Common methods

```java
e.getMessage();   // "String index out of range: N"
e.getCause();     // null
```

No chaining — it's an exception.

---

## 7. `StringJoiner` (java.util)

Builds a delimiter-separated string with optional prefix/suffix. Used by `Collectors.joining()`.

### Common methods (return `StringJoiner` → chainable)

```java
StringJoiner sj = new StringJoiner(", ", "[", "]");

sj.add("a")        // "[a]"
  .add("b")        // "[a, b]"
  .add("c");       // "[a, b, c]"

sj.setEmptyValue("empty");   // StringJoiner
sj.merge(new StringJoiner(",").add("x").add("y")); // "[a, b, c, x, y]"
```

### Return types

```java
sj.length();       // int
sj.toString();     // String ← final
```

### Chain

```java
String query = new StringJoiner(" AND ", "WHERE ", "")
        .add("age > 18")
        .add("country = 'UK'")
        .add("active = true")
        .toString();
// "WHERE age > 18 AND country = 'UK' AND active = true"
```

### With streams

```java
String joined = List.of("a","b","c").stream()
        .collect(java.util.stream.Collectors.joining(", ", "[", "]"));
// "[a, b, c]"
```

---

## 8. `StringTokenizer` (java.util)

**Legacy** tokenizer (Java 1.0). Splits by a fixed set of delimiter chars. Prefer `String.split` or `Scanner`.

### Common methods

```java
StringTokenizer st = new StringTokenizer("a,b,c", ",");

st.hasMoreTokens();      // boolean
st.nextToken();          // "a"
st.countTokens();        // 3
st.nextToken(",");       // "b" (alternate delimiter)
```

### Full example

```java
StringTokenizer st = new StringTokenizer("apple,banana;cherry", ",;");
while (st.hasMoreTokens()) {
    System.out.println(st.nextToken());
}
// apple
// banana
// cherry
```

**No chain** — it's an iterator, not a builder.

**Modern replacement:**

```java
Arrays.stream("apple,banana;cherry".split("[,;]"))
      .forEach(System.out::println);
```

---

## 9. `StringConcatException` (java.lang.invoke)

Runtime exception thrown if the JVM cannot bootstrap a `StringConcatFactory` call site (e.g., malformed recipe, null argument to a non-nullable slot, or too many arguments).

### Methods

```java
e.getMessage();   // details about the failed bootstrap
e.getCause();     // usually a BootstrapMethodError
```

### Typical trigger (rare)

```java
// Normally never seen; shows up if you call StringConcatFactory
// with an invalid recipe or a null into a primitive slot.
```

No chaining.

---

## 10. `StringConcatFactory` (java.lang.invoke)

The class the compiler targets when you write `"a" + b + "c"`. It creates a `CallSite` that builds the concatenated string. Not usually called by hand.

### Common static methods

```java
StringConcatFactory.makeConcat(MethodHandles.Lookup, String, MethodType);
StringConcatFactory.makeConcatWithConstants(Lookup, String, MethodType, String recipe, Object... constants);
```

### Signature of a generated method (what the compiler produces)

```java
// Source:
String s = "Hello " + name + "!";
// Compiled to something like:
invokedynamic #N  // makeConcatWithConstants:(Ljava/lang/String;)Ljava/lang/String;
//   recipe: "Hello \u0001!"
```

### Manual call (advanced)

```java
CallSite cs = StringConcatFactory.makeConcatWithConstants(
    MethodHandles.lookup(),
    "concat",
    MethodType.methodType(String.class, String.class),
    "Hello \u0001!",
    new Object[0]
);
MethodHandle mh = cs.getTarget();
String out = (String) mh.invokeExact("World"); // "Hello World!"
```

No chaining — it's a factory.

---

## 11. `StringEntry` (java.lang.classfile.constantpool)

Part of the **Java 21 Class-File API**. Represents a `CONSTANT_String` entry in a `.class` file's constant pool. Used only when writing bytecode analyzers/compilers.

### Common methods

```java
StringEntry entry = ...;
entry.utf8();          // Utf8Entry → actual bytes
entry.stringValue();   // String → the resolved value
entry.constantValue(); // String
```

### Typical usage (parse a class file)

```java
byte[] bytes = Files.readAllBytes(Path.of("Foo.class"));
ClassModel cm = ClassFile.of().parse(bytes);
cm.constantPool().entries().stream()
  .filter(e -> e instanceof StringEntry)
  .map(e -> ((StringEntry) e).stringValue())
  .forEach(System.out::println);
```

No chaining — it's a model class.

---

## 12. `StringCharacterIterator` (java.text)

Bi-directional iterator over a `String`. Used by `Format`, `Collator`, `BreakIterator`.

### Common methods

```java
StringCharacterIterator it = new StringCharacterIterator("Hello");

it.first();        // 'H'  (index 0)
it.last();         // 'o'  (index 4)
it.current();      // 'o'
it.next();         // returns DONE ('\uFFFF')
it.previous();     // 'o'
it.setIndex(1);    // 'e'
it.getIndex();     // int
it.getBeginIndex();// 0
it.getEndIndex();  // 5
it.clone();        // StringCharacterIterator
```

### Forward iteration

```java
StringCharacterIterator it = new StringCharacterIterator("Hello");
for (char c = it.first(); c != CharacterIterator.DONE; c = it.next()) {
    System.out.print(c + " ");
}
// H e l l o
```

### Backward iteration

```java
for (char c = it.last(); c != CharacterIterator.DONE; c = it.previous()) {
    System.out.print(c + " ");
}
// o l l e H
```

### Chain

```java
char lastChar = new StringCharacterIterator("Hello World").last();
// 'd'
```

---

## Quick comparison: which "string builder" to use?

| Class | Mutable? | Thread-safe? | Since | When to use |
|-------|----------|--------------|-------|-------------|
| `String` | ✗ | ✓ (immutable) | 1.0 | Default; small text |
| `StringBuilder` | ✓ | ✗ | 1.5 | Loops, most cases |
| `StringBuffer` | ✓ | ✓ | 1.0 | Shared across threads (rare) |
| `StringJoiner` | ✓ | ✗ | 1.8 | Delimited lists, streams |
| `StringTokenizer` | — | — | 1.0 | Legacy; avoid |

---

## Master chain example (uses many)

```java
String report = new StringBuilder()
        .append(new StringJoiner(", ")
                .add("Alice").add("Bob").add("Carol"))
        .append(" | ")
        .append("Total: ")
        .append(3)
        .toString()
        .toUpperCase()
        .replace("|", "→")
        .concat(" ✔");
// "ALICE, BOB, CAROL → TOTAL: 3 ✔"
```





[[Java]]