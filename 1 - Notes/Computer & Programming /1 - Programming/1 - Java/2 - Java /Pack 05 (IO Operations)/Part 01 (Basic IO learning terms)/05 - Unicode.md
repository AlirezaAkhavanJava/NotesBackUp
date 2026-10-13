Let's start with the problem. A Java `char` is 16 bits, so it can hold [^1]65,536 different values (0 to 65,535). Unicode was designed with room for over a million code points, up to `U+10FFFF`. The first 65,536 of them, called the Basic Multilingual Plane (BMP), fit in one `char`. That covers English, accented letters, Chinese, Arabic, and most of what you'll ever type. Anything above that, like most emoji, some rare historic scripts, and some mathematical symbols, doesn't fit.

**The trick: two chars for one character**

Java (and UTF-16, the encoding behind its 16-bit `char`) handles this with a _surrogate pair_. The Unicode designers reserved a block of values that will never be assigned to real characters:

- `0xD800` to `0xDBFF`: **high surrogates** (the first half)
- `0xDC00` to `0xDFFF`: **low surrogates** (the second half)

For a big code point, you subtract `0x10000`, which leaves a 20-bit number. The top 10 bits go into a high surrogate (added to `0xD800`), and the bottom 10 bits go into a low surrogate (added to `0xDC00`). For 😀 (`U+1F600`) that works out to `0xD83D` followed by `0xDE00`. Those two `char`s together _are_ the emoji.

The analogy is a number too big for one display digit, so you spill into a second one. It breaks down in a useful way: each half carries a marker saying which half it is, because of the reserved ranges. If you land in the middle of a string, you can tell whether you're looking at a first half, a second half, or a normal character. That's what makes the scheme robust.

**What this does to your code**

Here's where the beginner trap lives:

```java
String s = "😀";

s.length();                        // 2  (two chars!)
s.charAt(0);                       // '\uD83D', half a character, meaningless alone
s.codePointCount(0, s.length());   // 1  (one actual character)
s.codePointAt(0);                  // 128512, the real Unicode number
```

`length()` counts `char`s, not characters. So `"Hi😀".length()` is 4, even though a human sees three things. If you loop with `charAt(i)`, you'll hand a lone surrogate to something that expects a full character, and you get garbage or `?` symbols. The fix is to work with _code points_ instead:

```java
s.codePoints().forEach(cp -> {
    System.out.println(cp + " takes " + Character.charCount(cp) + " char(s)");
});
```

`codePoints()` walks the string and stitches surrogate pairs back together for you. `Character.charCount(cp)` tells you whether a code point needs 1 or 2 `char`s.

**Why you'll care later**

Anything that slices or truncates text by `char` index can cut an emoji in half: a "first 10 characters" preview, a database column limit, a substring for display. When that happens, you get a broken symbol or an exception somewhere downstream. In a Spring Boot app handling user input (a chat or messaging app like your Family Inbox idea, where people love emoji), this really shows up.

Don't confuse this with the UTF-8 story from before. UTF-8 splits one character into 1 to 4 _bytes_ on disk. UTF-16 splits one character into 1 or 2 _16-bit chars_ in memory. Both are variable-length encodings of the same Unicode numbers, solving the same "doesn't fit in a fixed size" problem at different layers. When a `Reader` decodes a file, it's converting from the first style to the second.


[[Java]]
[[IO]]

[^1]: The key is that each bit can have 2 possible states: `0` or `1`. When you add more bits, the number of possible combinations multiplies, rather than adds.
	
	### 1. One byte (8 bits)
	
	Each bit has 2 possibilities, so:
	
	\[ 2^8 = 256 \]
	
	Values: `0` to `255`.
	
	### 2. Two bytes (16 bits)
	
	Two bytes contain 16 bits total:
	
	\[ 2^{16} = 65,536 \]
	
	Values: `0` to `65,535` if interpreted as unsigned.
	
	Why not \(256 + 256\)?
	
	Because the two bytes work together to form one 16-bit value. The first byte determines a group of 256 values, and the second byte selects a value within that group.
	
	For example:
	
	|First byte|Second byte|Combined unsigned value|
	|---|---|---|
	|`00000000`|`00000000`|0|
	|`00000000`|`00000001`|1|
	|`00000001`|`00000000`|256|
	|`11111111`|`11111111`|65,535|
	
	
	Remember: Adding bits multiplies the number of possible combinations by 2 for every additional bit. Therefore, \(n\) bits can represent \(2^n\) distinct bit patterns.

