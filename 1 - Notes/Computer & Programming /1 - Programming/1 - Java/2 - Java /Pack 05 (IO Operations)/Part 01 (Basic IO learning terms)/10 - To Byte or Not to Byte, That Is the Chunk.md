


Once you see these three layers, most Java IO confusion goes away. You'll know which class to reach for, and why your text sometimes turns into garbage like `ðŸ˜€`.

---

## The big picture

Reading data in Java is three separate jobs, each with its own tool:

|Layer|Question it answers|Tool|
|---|---|---|
|**Bytes**|What is the raw data?|`InputStream`|
|**Chunks**|How do I move it efficiently?|buffers, `BufferedInputStream`|
|**Characters**|What does it mean as text?|`Reader`, `InputStreamReader`|

Each layer sits on top of the one below it. You can mix and match them.

---

## Layer 1: Bytes (the raw material)

A **byte** is a number from 0 to 255. Every file, packet, and keystroke is made of them.

`InputStream` sees everything as a flat line of bytes. It doesn't know if those bytes are a photo, a song, or a sentence. That's a feature: because it makes no assumptions, one class works for files, sockets, and anything else.

```java
int b = in.read(); // one byte, as a number 0-255, or -1 at the end
```

Why does `read()` return an `int` and not a `byte`? Because a Java `byte` is signed (-128 to 127), so it has no spare value to mean "the end." An `int` can hold every byte value _and_ `-1`.

## Layer 2: Chunks (how bytes actually travel)

Reading one byte per call is slow. Each call may cost a trip to the operating system. So you read **chunks** instead:

```java
byte[] buffer = new byte[8192];   // a buffer: a small waiting area in memory
int n = in.read(buffer);          // fills up to 8192 bytes, returns how many it got
```

Two things to remember:

- `n` can be **less** than the buffer size. Only use `buffer[0..n)`.
- `n` is `-1` when the data has ended.

`BufferedInputStream` does this chunking for you. It reads big chunks from the source and hands bytes to you from memory.

The chunk is a performance trick. It doesn't change what the data _means_. The stream is still a flow of bytes. You're just scooping it with a bigger spoon.

## Layer 3: Characters (adding meaning)

Text is where bytes get interesting, because **one character can be several bytes**. The rule that turns bytes into characters is called a **charset** (or encoding). UTF-8 is the most common one.

Here's how UTF-8 stores a few characters:

|Character|Bytes in UTF-8|
|---|---|
|`A`|1|
|`é`|2|
|`€`|3|
|`😀`|4|

If you read a file with a plain `InputStream` and look at one byte, you might be looking at a _quarter_ of an emoji. That byte means nothing alone.

`Reader` solves this. An `InputStreamReader` is a **decoder**: it takes bytes, applies the charset rules, and gives you whole characters.

```java
try (Reader reader = new BufferedReader(
        new InputStreamReader(in, StandardCharsets.UTF_8))) {
    int ch;
    while ((ch = reader.read()) != -1) {
        // ch is a character, not a raw byte
    }
}
```

It also handles the awkward moment when a chunk ends halfway through an emoji. It keeps the leftover bytes and waits for the next chunk to finish the character.

> **A small twist.** Java's `char` is 16 bits, so the emoji 😀 becomes **two** `char` values (a _surrogate pair_) inside a `String`. One emoji means 4 UTF-8 bytes, 2 Java `char`s, and 1 _code point_. Use `str.codePointCount(...)` if you want to count what a human would call "one character."

---

## Putting the layers together

Reading a text file the sensible way uses all three:

```java
try (BufferedReader reader = Files.newBufferedReader(path, StandardCharsets.UTF_8)) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
}
```

Behind that one line, the file gives **bytes** (layer 1), which are read in **chunks** (layer 2), then decoded into **characters** (layer 3). You get to think at the top layer while the lower ones work quietly.

---

## Common traps

- **Using `InputStream` for text.** You'll split multi-byte characters apart. Use a `Reader`.
- **Forgetting the charset.** `new InputStreamReader(in)` may use the machine's default charset, so the same code can behave differently on Debian and Windows. Always pass `StandardCharsets.UTF_8` explicitly.
- **Ignoring the return value of `read(buffer)`.** It may fill only part of the buffer.
- **Using `Reader` for binary data.** An image run through a charset decoder gets corrupted. Binary data stays on the byte side.

---

## A rule of thumb

Ask one question: _"Is this data text?"_

- **No** (image, zip, video, encrypted data): use `InputStream` or `OutputStream`, with a buffer.
- **Yes**: wrap the byte stream in a `Reader` or `Writer` with an explicit charset.

---

## Recap

- A stream's unit is the **byte**, and it has no idea what the bytes mean.
- Data moves in **chunks**, so read with buffers for speed.
- **Characters** are meaning added by a decoder, and one character can be several bytes.
- Always name your charset.

A good way to lock this in: write a small program that reads a file containing `😀` three ways. Use a raw `InputStream` and print each byte, then a `Reader` and print each `char`, then print the code point. Seeing 4, 2, and 1 side by side makes the layers feel real.

---
# Chunk vs byte: what's the difference?

**A chunk is not a different thing from bytes.** A chunk is just _a group of bytes_. Bytes are what flows. "Chunk" only describes how many bytes you grab in one `read` call.

Think of carrying groceries from a car. Each item is a byte. A chunk is one bag. You're moving the same groceries either way, but one trip per item is exhausting, while one trip per bag is easy.

---

## Showing a byte

One byte is a single number from 0 to 255. The letter `H` is the byte `72`, which is `01001000` in binary (8 bits). That's all a byte is.

## Showing a chunk

Take the text `Hi 😀`. In UTF-8 it is 7 bytes:

```
H    i    space   😀 (4 bytes)
48   69   20      F0 9F 98 80      (hex)
72   105  32      240 159 152 128  (decimal)
```

Now read it with a tiny buffer of 4 bytes, so you can see chunks clearly:

```java
byte[] buffer = new byte[4];
int n;
while ((n = in.read(buffer)) != -1) {
    System.out.println(n + " bytes: " + Arrays.toString(Arrays.copyOf(buffer, n)));
}
```

Output:

```
4 bytes: [72, 105, 32, -16]
3 bytes: [-97, -104, -128]
```

Notice three things:

- **Chunk 1** holds 4 bytes: `H`, `i`, space, and only the _first byte_ of the emoji.
- **Chunk 2** holds the other 3 emoji bytes.
- The negative numbers are Java's signed `byte` (240 shows as -16). Same bits, different display.

Chunks don't care about meaning. They cut the flow wherever the size runs out, even in the middle of an emoji. That's why `InputStreamReader` has to stitch those pieces back together.

---

## How many bytes should a chunk be?

You choose, but 4 KB to 8 KB (4096 to 8192 bytes) is the usual sweet spot. That matches how the world below you already moves data:

|Level|Typical unit|
|---|---|
|Disk|blocks of about 4 KB|
|Network (TCP/IP)|packets of up to about 1,500 bytes|
|`BufferedInputStream`|8 KB by default|

So even if you ask for one byte, the system underneath has usually fetched a whole block already.

## Is it slow?

**Moving bytes isn't slow. Asking for them is.** Each `read` call has a fixed cost, and with a raw `FileInputStream` it can mean a request to the operating system. The cost is per call, not per byte.

Reading a 1 MB file:

- **1 byte per call:** about 1,000,000 calls
- **8 KB per call:** about 128 calls

Same data, same bytes, thousands of times fewer calls. That's the whole benefit of chunks.

There is a limit, though. Past roughly 8 KB to 64 KB, bigger buffers barely help, and they use more memory. A 1 GB buffer would be silly.

---

## The one sentence to keep

**Bytes are what flows. A chunk is how many bytes you scoop per call, and the scoop size only affects speed, never meaning.**



[[IO]]