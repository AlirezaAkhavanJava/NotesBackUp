`StandardCharsets` is a Java utility class in `java.nio.charset` that provides constants for standard character encodings, such as UTF-8, UTF-16, and US-ASCII.

It helps you specify a character encoding explicitly instead of relying on the platform's default encoding.

### Example

```
import java.nio.charset.StandardCharsets;

String text = "Hello 😀";

// Convert characters into UTF-8 bytes
byte[] bytes = text.getBytes(StandardCharsets.UTF_8);

// Convert UTF-8 bytes back into a String
String decoded = new String(bytes, StandardCharsets.UTF_8);
```

### Common constants

|Constant|Encoding|
|---|---|
|`StandardCharsets.UTF_8`|UTF-8|
|`StandardCharsets.UTF_16`|UTF-16|
|`StandardCharsets.UTF_16BE`|UTF-16, big-endian|
|`StandardCharsets.UTF_16LE`|UTF-16, little-endian|
|`StandardCharsets.US_ASCII`|US-ASCII|
|`StandardCharsets.ISO_8859_1`|ISO-8859-1|

### Why does it matter?

When converting between text and bytes, Java needs to know the encoding.

```
byte[] data = "€".getBytes(StandardCharsets.UTF_8);
```

The euro sign occupies 3 bytes in UTF-8. Specifying `StandardCharsets.UTF_8` ensures Java uses that encoding consistently.

Remember: `StandardCharsets` is a class containing predefined `Charset` constants. It does not perform I/O itself; it specifies how characters are encoded into bytes and decoded back into characters.


[[Java]]
[[IO]]