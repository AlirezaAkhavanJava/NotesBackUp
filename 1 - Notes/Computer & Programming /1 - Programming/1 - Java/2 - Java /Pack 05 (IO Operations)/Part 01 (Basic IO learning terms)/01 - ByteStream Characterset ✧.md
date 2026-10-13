
#### Bits have no meaning on their own

There’s actually no difference between “normal bits” and “character bits.” A bit is just a 0 or a 1, and a byte is just eight of them, like `01000001`. Whether that means the number 65, the letter `A`, or the brightness of a pixel depends entirely on who is reading it and what they agreed it means. Nothing in the bits themselves says “I’m a letter.”

A **character set** is that agreement for text: a big table that says “this character gets this number.” In Unicode, `A` is 65, `é` is 233, `你` is 20320, and `😀` is 128512. The table only assigns numbers to characters. It doesn’t say how to store those numbers as bytes.

The key thing about UTF-8 is that it’s variable length. `A` takes 1 byte, `é` takes 2, `你` takes 3, and `😀` takes 4 so the 8 bits in a byte stream aren’t “the character set.” A character might need one byte or several, and the charset is the rulebook for figuring out where one character ends and the next begins.

---
**Where the 16 bits come from**

When we say character streams work in 16 bits, that’s about Java’s own `char` type, which is 16 bits wide. It describes what’s inside your program, not what’s in the file. The file on disk is always bytes. A `Reader` sits on top of a byte stream and does the decoding for you, reading bytes, applying the charset rules, and handing you proper Java `char`s.


```java
byte[] bytes = "é".getBytes(StandardCharsets.UTF_8);
// bytes is [0xC3, 0xA9] — two bytes for one character

String right = new String(bytes, StandardCharsets.UTF_8);      // "é"
String wrong = new String(bytes, StandardCharsets.ISO_8859_1); // "Ã©"
```

Same two bytes, but a different rulebook gives different text. That garbled `Ã©` is a classic bug called _mojibake_, and it’s why you should name the charset explicitly when you create a reader:

```java
new InputStreamReader(new FileInputStream("data.txt"), StandardCharsets.UTF_8);
```


The analogy to hold onto is a codebook that both sides must share, and it breaks down in one place: there isn’t just one codebook. There are many encodings, and the reader has to guess or be told which one the writer used.

One last caveat: since `char` is only 16 bits, characters like `😀` don’t fit in a single `char`, and Java stores them as _two_ `char`s (a “surrogate pair”). 

---


[[Java]]
[[IO]]