
# String.format() in Java

## What it is

`String.format()` builds a string by substituting values into a **format template** containing **format specifiers**.

```java
String s = String.format("Hello, %s! You are %d years old.", "Alice", 30);
// "Hello, Alice! You are 30 years old."
```

It's a static method that internally uses `java.util.Formatter`. The same syntax powers `System.out.printf(...)` and `PrintWriter.printf(...)`.

---

## Anatomy of a format specifier

```
%[argument_index$][flags][width][.precision]conversion
```

Example: `%1$-10.2f`

| Part | Meaning | Example piece |
|------|---------|---------------|
| `%` | Starts the specifier | `%` |
| `argument_index$` | Which argument (1-based) | `1$` |
| `flags` | Modifiers like `-`, `+`, `0`, `,` | `-` |
| `width` | Minimum characters | `10` |
| `.precision` | Digits after decimal / max chars | `.2` |
| `conversion` | Type character | `f` |

---

## Common conversions

| Conversion | Applies to | Example |
|------------|-----------|---------|
| `%s` | Any object (`toString()`) | `"hi"` |
| `%d` | Integer types (`byte`, `short`, `int`, `long`, `BigInteger`) | `42` |
| `%f` | Floating point (`float`, `double`, `BigDecimal`) | `3.14` |
| `%e` | Scientific notation | `3.14e+00` |
| `%x` / `%X` | Hexadecimal | `ff` / `FF` |
| `%o` | Octal | `77` |
| `%b` / `%B` | Boolean | `true` |
| `%c` | Character | `A` |
| `%n` | Platform line separator | `\n` on Unix |
| `%%` | Literal `%` | `%` |

> `%d` **does not accept** `double` or `float`. `%f` **does not accept** `int`. Mixing them throws `IllegalFormatConversionException`.

---

## Width and precision

```java
String.format("%5d", 42);       // "   42"   (right-aligned in width 5)
String.format("%-5d|", 42);     // "42   |"  (left-aligned via '-' flag)
String.format("%05d", 42);      // "00042"   (zero-padded)
String.format("%.2f", 3.14159); // "3.14"    (2 decimal places)
String.format("%8.2f", 3.14159);// "    3.14"
String.format("%.3s", "hello"); // "hel"     (truncate strings too)
```

---

## Useful flags

| Flag | Effect | Example |
|------|--------|---------|
| `-` | Left-justify | `%-6s` |
| `0` | Zero-pad numbers | `%05d` |
| `+` | Always show sign | `%+d` → `+42` |
| ` ` (space) | Leading space for positives | `% d` → ` 42` |
| `,` | Grouping separator | `%,d` → `1,234,567` |
| `(` | Negative numbers in parentheses | `%(d` → `(42)` |
| `#` | Alternate form (0x, 0 prefixes) | `%#x` → `0xff` |

```java
String.format("%,.2f", 1234567.891);   // "1,234,567.89"
String.format("%+d", 42);              // "+42"
String.format("%(d", -42);             // "(42)"
String.format("%#x", 255);             // "0xff"
```

---

## Positional arguments (argument index)

Reuse or reorder arguments with `n$`:

```java
String.format("%2$s %1$s", "World", "Hello");   // "Hello World"
String.format("%1$s %1$s", "ha");               // "ha ha"
```

Mixing positional and non-positional arguments in one format string throws an exception.

---

## Locale-aware formatting

`String.format` uses the default locale. `1,234.5` becomes `1.234,5` in German locale.

```java
String.format(Locale.US, "%,.2f", 1234.5);   // "1,234.50"
String.format(Locale.GERMANY, "%,.2f", 1234.5); // "1.234,50"
String.format(Locale.FRANCE, "%,.2f", 1234.5);  // "1 234,50"
```

**Always pass a Locale explicitly** for money, dates in user-facing strings, or when output is parsed by another system.

---

## A fuller example

```java
String name = "Widget";
int qty = 3;
double price = 4.5;

String receipt = String.format(
    "%-10s x%3d @ %6.2f = %8.2f",
    name, qty, price, qty * price
);
System.out.println(receipt);
```

Output:
```
Widget     x  3 @   4.50 =    13.50
```

---

## Common gotchas

1. **Missing/extra arguments** → `MissingFormatArgumentException` or `UnknownFormatConversionException`.
2. **Wrong type for conversion** → `IllegalFormatConversionException`.
3. **`%f` on an `int`** is illegal — convert first: `String.format("%.2f", (double) n)`.
4. **`null` with `%s`** prints `"null"` (safe); `null` with `%d`/`%f` throws.
5. **`%n` vs `\n`** — `%n` is platform-independent, prefer it in portable output.
6. **Bare `%`** in text must be escaped as `%%`.
7. **Performance**: for simple concatenation (2–3 values), `+` or `StringBuilder` is faster. `String.format` shines for readability with many placeholders and alignment.

---

## Alternatives you should know

| Approach | Since | Notes |
|----------|-------|-------|
| `String.format(...)` | Java 5 | The classic |
| `"%s".formatted(args)` | Java 15 | Same syntax, cleaner |
| `StringBuilder` | Java 5 | Fast, verbose |
| `String.join`, text blocks | Java 8/15 | For lists and multi-line |
| `MessageFormat` | Java 1.1 | `{0}` style, locale-aware dates/numbers, best for i18n |

```java
// Java 15+
String s = "Hello, %s!".formatted("Alice");
```

---

## Practice exercises

1. Format `1234567.891` as `1,234,567.891`.
2. Print a table of 5 names and scores, aligned to columns of width 12 and 5.
3. Print `255` as hex, octal, and binary (hint: `%x`, `%o`, `%s` + `Integer.toBinaryString`).
4. Format a duration `3672` seconds as `01:01:12` using `%02d`.
5. Use positional arguments to produce `"Bob scored 90, Alice scored 85"` from `("Alice", 85, "Bob", 90)`.

Try them and I'll review your answers — or ask about `MessageFormat` / date formatting (`%tY`, `%tF`) if you want to go deeper.

---
`String.format()` returns a `String`, so you can chain **any instance method of the `String` class that itself returns a `String`** (or a type you can further convert). Below is the complete list, organized by category, with visual code examples showing each one applied directly to the result of `String.format()`.

---

## 1. Case Conversion

| Method | Description |
|--------|-------------|
| `toLowerCase()` | Converts all characters to lower case (default locale). |
| `toLowerCase(Locale)` | Same, using the given locale. |
| `toUpperCase()` | Converts all characters to upper case (default locale). |
| `toUpperCase(Locale)` | Same, using the given locale. |

```java
// toLowerCase()
String msg = String.format("Hello %s", "WORLD").toLowerCase();
// "hello world"

// toUpperCase()
String code = String.format("id-%d", 42).toUpperCase();
// "ID-42"

// Locale-aware
String tr = String.format("Istanbul").toLowerCase(Locale.forLanguageTag("tr"));
// "ıstanbul" (dotless i)
```

---

## 2. Whitespace Removal

| Method | Description |
|--------|-------------|
| `trim()` | Removes leading/trailing chars ≤ U+0020. |
| `strip()` | Unicode-aware leading/trailing whitespace removal (Java 11+). |
| `stripLeading()` | Removes only leading whitespace. |
| `stripTrailing()` | Removes only trailing whitespace. |

```java
// trim()
String t1 = String.format("  %s  ", "hi").trim();
// "hi"

// strip()
String t2 = String.format("\u2003%s\u2003", "hi").strip();
// "hi" (em-space removed)

// stripLeading / stripTrailing
String t3 = String.format("  %s  ", "hi").stripLeading();   // "hi  "
String t4 = String.format("  %s  ", "hi").stripTrailing();  // "  hi"
```

---

## 3. Substring Extraction

| Method | Returns | Description |
|--------|---------|-------------|
| `substring(int begin)` | `String` | From `begin` to end. |
| `substring(int begin, int end)` | `String` | From `begin` to `end-1`. |
| `subSequence(int begin, int end)` | `CharSequence` | Similar, but returns `CharSequence` (call `.toString()` to chain further). |

```java
// substring(int)
String s1 = String.format("Hello %s", "World").substring(6);
// "World"

// substring(int, int)
String s2 = String.format("Hello %s", "World").substring(0, 5);
// "Hello"

// subSequence → needs toString() for further String chaining
String s3 = String.format("Hello %s", "World")
                    .subSequence(6, 11)
                    .toString();
// "World"
```

---

## 4. Replacement

| Method | Description |
|--------|-------------|
| `replace(char, char)` | Replaces every occurrence of a char. |
| `replace(CharSequence, CharSequence)` | Replaces every occurrence of a literal sequence. |
| `replaceAll(String regex, String replacement)` | Replaces every match of a regex. |
| `replaceFirst(String regex, String replacement)` | Replaces the first regex match. |

```java
// replace(char, char)
String r1 = String.format("a%sb", "x").replace('x', 'y');
// "ayb"

// replace(CharSequence, CharSequence)
String r2 = String.format("Hello %s", "World").replace("World", "Java");
// "Hello Java"

// replaceAll (regex)
String r3 = String.format("a1b2c3", "").replaceAll("\\d", "#");
// "a#b#c#"

// replaceFirst (regex)
String r4 = String.format("foo foo", "").replaceFirst("foo", "bar");
// "bar foo"
```

---

## 5. Case-Insensitive & Literal Matching (chaining after format)

These methods return `String` when used in combination with other methods, but note: `equalsIgnoreCase`, `contains`, `startsWith`, `endsWith` return `boolean`, so they terminate the chain. Only methods that **return a `String`** are chainable.

---

## 6. Padding & Repetition (Java 11+)

| Method | Description |
|--------|-------------|
| `repeat(int count)` | Repeats the string `count` times. |
| `indent(int n)` | Adds/removes indentation and normalizes line endings (Java 12+). |

```java
// repeat
String line = String.format("%s", "=").repeat(20);
// "===================="

// indent
String block = String.format("line1%nline2").indent(4);
// "    line1\n    line2\n"
```

---

## 7. Transformation & Formatting (Java 12+/15+)

| Method | Description |
|--------|-------------|
| `transform(Function<String, R>)` | Applies a function to the string (Java 12+). |
| `formatted(Object... args)` | Uses the string as a format template (Java 15+). |

```java
// transform — chain any function
String tr = String.format("Hello %s", "World")
                  .transform(s -> s + "!");
// "Hello World!"

// formatted — reuse the formatted string as a new template
String fmt = String.format("Value: %d", 42).formatted();
// "Value: 42"
```

---

## 8. Interning

| Method | Description |
|--------|-------------|
| `intern()` | Returns a canonical representation from the string pool. |

```java
String i1 = String.format("Hello %s", "World").intern();
// "Hello World" (pooled)
```

---

## 9. Conversion to String (already a String)

| Method | Description |
|--------|-------------|
| `toString()` | Returns the string itself (inherited from `Object`). |

```java
String ts = String.format("Hi %s", "there").toString();
// "Hi there"
```

---

## 10. Methods That Return Non-String (chain ends or continues differently)

These methods **cannot** be followed by another `String` method unless you convert first.

| Method | Return type | How to continue chaining |
|--------|-------------|--------------------------|
| `split(String regex)` | `String[]` | Use `Arrays.stream(...)` or index into array. |
| `lines()` | `Stream<String>` | Use stream operations. |
| `chars()` | `IntStream` | Use stream operations. |
| `codePoints()` | `IntStream` | Use stream operations. |
| `getBytes()` | `byte[]` | Convert via `new String(bytes)` if needed. |
| `toCharArray()` | `char[]` | Convert via `new String(charArray)` if needed. |
| `subSequence(int,int)` | `CharSequence` | Call `.toString()` to get back to `String`. |

---

## 11. Complete Quick-Reference Table (String → String)

| Method | Signature | Since |
|--------|-----------|-------|
| `concat` | `String concat(String str)` | 1.0 |
| `replace` | `String replace(char old, char new)` | 1.5 |
| `replace` | `String replace(CharSequence, CharSequence)` | 1.5 |
| `replaceAll` | `String replaceAll(String regex, String repl)` | 1.4 |
| `replaceFirst` | `String replaceFirst(String regex, String repl)` | 1.4 |
| `substring` | `String substring(int begin)` | 1.0 |
| `substring` | `String substring(int begin, int end)` | 1.0 |
| `toLowerCase` | `String toLowerCase()` | 1.0 |
| `toLowerCase` | `String toLowerCase(Locale)` | 1.1 |
| `toUpperCase` | `String toUpperCase()` | 1.0 |
| `toUpperCase` | `String toUpperCase(Locale)` | 1.1 |
| `trim` | `String trim()` | 1.0 |
| `strip` | `String strip()` | 11 |
| `stripLeading` | `String stripLeading()` | 11 |
| `stripTrailing` | `String stripTrailing()` | 11 |
| `intern` | `String intern()` | 1.0 |
| `repeat` | `String repeat(int count)` | 11 |
| `indent` | `String indent(int n)` | 12 |
| `transform` | `<R> R transform(Function<String,R>)` | 12 |
| `formatted` | `String formatted(Object... args)` | 15 |
| `toString` | `String toString()` | 1.0 |

---

## Visual Chain Example (Putting It All Together)

```java
String result = String.format("  Hello %s!  ", "WORLD")
                      .trim()                 // "Hello WORLD!"
                      .toLowerCase()          // "hello world!"
                      .replace("world", "java") // "hello java!"
                      .repeat(2)              // "hello java!hello java!"
                      .substring(0, 12);      // "hello java!"

System.out.println(result); // "hello java!"
```

---

## Key Takeaway

Because `String.format()` is **static**, chaining starts with the returned `String`. Any **instance method** of `String` that returns a `String` can be chained. If a method returns `String[]`, `Stream`, `int`, `boolean`, etc., the chain stops (or you must convert the result back to a `String` first).

[[Java]]