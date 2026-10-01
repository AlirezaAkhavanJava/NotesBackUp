
# Parsing vs. Formatting — the two directions

**parsing** is `String → primitive/wrapper`. The opposite direction is usually called **formatting** (or **string conversion / serialization to text**). Java gives you several tools for each.

---

## The two directions at a glance

```
String  ──parse──►  int / double / boolean / ...      (String → value)
value   ──toString/valueOf/format──►  String          (value → String)
```

| Direction | Typical API | Example |
|-----------|-------------|---------|
| **Parsing** (text → value) | `Integer.parseInt`, `Double.parseDouble`, `Boolean.parseBoolean`, ... | `int n = Integer.parseInt("42");` |
| **Reverse** (value → text) | `String.valueOf`, `Integer.toString`, `String.format`, `"" + n` | `String s = String.valueOf(42);` |

---

## 1. Parsing: String → value

Each wrapper class has a `parseXxx` static method (and a `valueOf` variant that returns the wrapper).

| Target type | Parse method | Returns |
|-------------|--------------|---------|
| `int` | `Integer.parseInt(String)` | `int` |
| `int` (radix) | `Integer.parseInt(String, int radix)` | `int` |
| `long` | `Long.parseLong(String)` | `long` |
| `short` | `Short.parseShort(String)` | `short` |
| `byte` | `Byte.parseByte(String)` | `byte` |
| `double` | `Double.parseDouble(String)` | `double` |
| `float` | `Float.parseFloat(String)` | `float` |
| `boolean` | `Boolean.parseBoolean(String)` | `boolean` |
| `char` | *(no parse — use `charAt(0)`)* | — |
| `BigInteger` | `new BigInteger(String)` | `BigInteger` |
| `BigDecimal` | `new BigDecimal(String)` | `BigDecimal` |

```java
int     i = Integer.parseInt("42");           // 42
int     h = Integer.parseInt("2A", 16);       // 42 (hex)
long    l = Long.parseLong("9999999999");     // 9999999999L
double  d = Double.parseDouble("3.14");       // 3.14
boolean b = Boolean.parseBoolean("true");     // true
```

**Wrapper-returning variants** (`valueOf`) — useful when you need an object (e.g. for generics, `Optional`, collections):

```java
Integer   io = Integer.valueOf("42");         // Integer (cached for -128..127)
Double    dobj = Double.valueOf("3.14");      // Double
Boolean   bobj = Boolean.valueOf("true");     // Boolean
BigInteger bi = new BigInteger("12345678901234567890");
```

**Parsing rules & gotchas:**

- `parseInt` throws `NumberFormatException` on bad input — **always** guard or catch.
- Leading/trailing whitespace is **not** allowed: `" 42 "` fails. Use `.trim()` first.
- `parseBoolean` never throws — anything other than `"true"` (case-insensitive) is `false`.
- `parseInt` accepts `+`/`-` but not `,` or `_`; `parseDouble` accepts `1e9`, `NaN`, `Infinity`.
- Locale matters for decimals only in `NumberFormat`, not `parseDouble` (which always uses `.`).

```java
try {
    int n = Integer.parseInt(input.trim());
} catch (NumberFormatException e) {
    // handle bad input
}
```

---

## 2. The reverse: value → String

### A. `String.valueOf(...)` — the universal one

Overloaded for every primitive, `char[]`, and `Object` (`null` → `"null"`, no NPE).

```java
String s1 = String.valueOf(42);        // "42"
String s2 = String.valueOf(3.14);      // "3.14"
String s3 = String.valueOf(true);      // "true"
String s4 = String.valueOf('A');       // "A"
String s5 = String.valueOf(new char[]{'h','i'}); // "hi"
String s6 = String.valueOf((Object) null);       // "null"
```

### B. `Xxx.toString(...)` — the per-type one

```java
String s1 = Integer.toString(42);            // "42"
String s2 = Integer.toString(42, 16);        // "2a"  (radix)
String s3 = Integer.toHexString(255);        // "ff"
String s4 = Integer.toOctalString(255);      // "377"
String s5 = Integer.toBinaryString(255);     // "11111111"
String s6 = Long.toString(9999999999L);      // "9999999999"
String s7 = Double.toString(3.14);           // "3.14"
String s8 = Boolean.toString(true);          // "true"
String s9 = Character.toString('A');         // "A"
```

### C. `String.format(...)` — when you want layout/width/precision

```java
String s = String.format("%05d", 42);        // "00042"
String s2 = String.format("%.2f", 3.14159);  // "3.14"
String s3 = String.format("%,d", 1234567);   // "1,234,567"
```

### D. Concatenation with `""` — quick and dirty

```java
String s = "" + 42;            // "42"
String s2 = "n=" + 42 + "!";   // "n=42!"
```

Works, but slower in loops and easy to get precedence wrong. Prefer `String.valueOf` or `format`.

### E. `StringBuilder.append(...)` — best inside loops

```java
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 3; i++) sb.append(i).append(',');
String s = sb.toString();      // "0,1,2,"
```

### F. `Objects.toString(...)` — null-safe with a default

```java
String s = Objects.toString(someObj, "N/A"); // "N/A" if null
```

---

## 3. Symmetry table (parse ↔ reverse)

| Type | Parse (String → value) | Reverse (value → String) |
|------|------------------------|--------------------------|
| `int` | `Integer.parseInt("42")` | `Integer.toString(42)` / `String.valueOf(42)` |
| `int` (hex) | `Integer.parseInt("2a", 16)` | `Integer.toHexString(42)` |
| `long` | `Long.parseLong("42")` | `Long.toString(42L)` |
| `double` | `Double.parseDouble("3.14")` | `Double.toString(3.14)` |
| `boolean` | `Boolean.parseBoolean("true")` | `Boolean.toString(true)` |
| `char` | `s.charAt(0)` | `Character.toString('A')` |
| `BigInteger` | `new BigInteger("123")` | `bi.toString()` |
| `BigDecimal` | `new BigDecimal("1.5")` | `bd.toString()` |

---

## 4. Locale-aware versions (both directions)

When the text comes from or goes to a user, use `NumberFormat` — it handles grouping separators and decimal commas.

```java
// value → String (locale-aware)
NumberFormat nf = NumberFormat.getInstance(Locale.GERMANY);
String s = nf.format(1234.5);        // "1.234,5"

// String → value (locale-aware)
Number n = nf.parse("1.234,5");      // 1234.5
double d = n.doubleValue();
```

`DecimalFormat` gives you a pattern:

```java
DecimalFormat df = new DecimalFormat("#,##0.00");
String s = df.format(1234.5);        // "1,234.50"
```

---

## 5. Round-trip example

```java
// value → text
int n = 255;
String hex  = Integer.toHexString(n);        // "ff"
String dec  = String.valueOf(n);             // "255"
String fmt  = String.format("0x%02X", n);    // "0xFF"

// text → value (back again)
int back1 = Integer.parseInt(hex, 16);       // 255
int back2 = Integer.parseInt(dec);           // 255
int back3 = Integer.decode("0xFF");          // 255  (handles 0x, 0, #)
```

---

## 6. Quick decision guide

| Situation | Use |
|-----------|-----|
| Simple `int → String` | `Integer.toString(n)` |
| Any type → String, null-safe | `String.valueOf(x)` |
| Layout / width / precision | `String.format(...)` |
| Inside a loop building text | `StringBuilder.append(...)` |
| User-facing numbers (locale) | `NumberFormat` / `DecimalFormat` |
| String → int, simple | `Integer.parseInt(s)` |
| String → int, with radix | `Integer.parseInt(s, radix)` |
| String → int, tolerant of `0x`/`0` prefixes | `Integer.decode(s)` |
| String → number, locale-aware | `NumberFormat.parse(s)` |
| String → object, may be null | `Optional` + try/catch, or `NumberUtils` (Apache) |

---

## TL;DR

- **Parsing** = `String → value` → `parseInt`, `parseDouble`, `parseBoolean`, `valueOf`, `new BigDecimal(...)`.
- **The reverse** = `value → String` → `String.valueOf`, `Integer.toString`, `toHexString`, `String.format`, `NumberFormat.format`, `StringBuilder.append`, or `"" + n`.
- For **user-facing** text, always go through `NumberFormat`/`DecimalFormat` so commas and decimal points match the locale.
- Wrap parsing in `try/catch` for `NumberFormatException` — there is no silent failure mode.


[[Java]]