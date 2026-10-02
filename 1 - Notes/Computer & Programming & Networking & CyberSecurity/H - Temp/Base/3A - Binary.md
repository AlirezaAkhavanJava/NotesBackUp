
# Binary — from the ground up

## 1. What is binary?

**Binary** is a number system that uses only **two symbols**:

```text
0
1
```

It is called **base-2** because there are two possible digits.

Humans normally use **decimal**, which is base-10:

```text
0 1 2 3 4 5 6 7 8 9
```

Computers use binary because digital electronic circuits can reliably represent two states:

```text
OFF → 0
ON  → 1
```

So binary is the mathematical representation of information using two states.

---

# 2. What is a bit?

A **bit** (binary digit) is the smallest unit of binary information.

A bit can contain exactly one of two values:

```text
0 or 1
```

For example:

```text
101101
```

contains **6 bits**.

```text
1 0 1 1 0 1
↑ ↑ ↑ ↑ ↑ ↑
6 bits
```

---

# 3. Why does binary work?

A computer contains enormous numbers of electronic components that can distinguish between physical states.

For example, conceptually:

```text
Voltage
   │
   ├── Low  → 0
   │
   └── High → 1
```

The actual hardware is more complicated, but the fundamental idea is that digital electronics represent information using distinguishable states.

This is why binary is so important to computing.

---

# 4. Binary place values

This is the most important concept to understand.

Decimal uses powers of **10**:

```text
10⁰ = 1
10¹ = 10
10² = 100
10³ = 1000
```

Binary uses powers of **2**:

```text
2⁰ = 1
2¹ = 2
2² = 4
2³ = 8
2⁴ = 16
2⁵ = 32
2⁶ = 64
2⁷ = 128
```

So:

```text
Binary:

128  64  32  16  8  4  2  1
 ↓    ↓   ↓   ↓   ↓  ↓  ↓  ↓
 2⁷  2⁶ 2⁵ 2⁴ 2³ 2² 2¹ 2⁰
```

Each position represents a power of 2.

---

# 5. Convert binary → decimal

Take:

```text
1011
```

Write the place values:

```text
8  4  2  1
↓  ↓  ↓  ↓
1  0  1  1
```

Now multiply each bit by its place value:

```text
1 × 8 = 8
0 × 4 = 0
1 × 2 = 2
1 × 1 = 1
```

Add them:

```text
8 + 0 + 2 + 1 = 11
```

Therefore:

```text
1011₂ = 11₁₀
```

The subscripts indicate the number bases.

---

# 6. Convert decimal → binary

Let's convert:

```text
13
```

Find which powers of 2 make 13:

```text
8 + 4 + 1 = 13
```

Therefore:

```text
8  4  2  1
1  1  0  1
```

So:

```text
13₁₀ = 1101₂
```

---

# 7. The binary counting system

Decimal counting:

```text
0
1
2
3
4
5
6
7
8
9
10
```

Binary counting:

```text
Decimal    Binary

0          0000
1          0001
2          0010
3          0011
4          0100
5          0101
6          0110
7          0111
8          1000
9          1001
10         1010
11         1011
12         1100
13         1101
14         1110
15         1111
```

Notice what happens after:

```text
0111
```

There is no binary digit `8`.

So we carry:

```text
0111
+   1
-----
1000
```

Exactly like decimal:

```text
999
+  1
----
1000
```

---

# 8. Bits and bytes

A **byte** is normally:

```text
8 bits
```

Therefore:

```text
1 byte = 8 bits
```

Example:

```text
10110010
```

is one byte.

An 8-bit unsigned value can represent:

```text
00000000 → 0
11111111 → 255
```

So:

```text
1 byte → 256 possible values
```

because:

```text
2⁸ = 256
```

---

# 9. Why 8 bits gives 256 values

Each bit has two possibilities:

```text
bit 1 → 2 possibilities
bit 2 → 2 possibilities
...
bit 8 → 2 possibilities
```

Therefore:

```text
2 × 2 × 2 × 2 × 2 × 2 × 2 × 2

= 2⁸

= 256
```

This generalizes:

```text
n bits → 2ⁿ possible combinations
```

Examples:

|Bits|Possible values|
|--:|--:|
|1|2|
|2|4|
|4|16|
|8|256|
|16|65,536|
|32|4,294,967,296|
|64|18,446,744,073,709,551,616|

This principle is fundamental to computer science.

---

# 10. Binary isn't just numbers

Computers ultimately store information as bits.

For example, the letter:

```text
A
```

can be represented using ASCII as:

```text
01000001
```

And:

```text
B
```

is:

```text
01000010
```

So:

```text
01000001 01000010
```

can represent:

```text
AB
```

The bits themselves don't inherently mean "A" or "B".

A **representation/encoding system** tells us how to interpret them.

---

# 11. Binary and networking

This connects directly to what we've been discussing.

When you send data over a network:

```text
Java application
      ↓
HTTP
      ↓
TCP
      ↓
IP
      ↓
Ethernet
      ↓
Physical medium
```

Eventually, the information has to be represented as bits:

```text
1011001010010110...
```

At the physical layer, those bits are represented by physical signals:

```text
Bits
 ↓
Electrical signals
or
Radio signals
or
Light
```

For example, an Ethernet connection might physically transmit signals corresponding to sequences of bits.

So the hierarchy is roughly:

```text
Human information
       ↓
Characters / numbers / data
       ↓
Bytes
       ↓
Bits
       ↓
Physical signals
       ↓
Network medium
```

---

# 12. Binary and bandwidth

Now our previous discussion becomes much clearer.

Suppose a network link has:

```text
100 Mbit/s
```

That means approximately:

```text
100,000,000 bits
```

can be transmitted per second under the stated link rate.

Because:

```text
8 bits = 1 byte
```

we can calculate:

```text
100,000,000 ÷ 8
= 12,500,000 bytes/s
≈ 12.5 MB/s
```

That's why network bandwidth is normally expressed in **bits per second**, while file sizes are commonly expressed in **bytes**.

---

# 13. Binary prefixes

Be careful with these.

Networking commonly uses decimal prefixes:

```text
1 kbit = 1,000 bits
1 Mbit = 1,000,000 bits
1 Gbit = 1,000,000,000 bits
```

Computer memory historically often uses powers of 2:

```text
1 KiB = 1,024 bytes
1 MiB = 1,048,576 bytes
1 GiB = 1,073,741,824 bytes
```

The `i` in `KiB`, `MiB`, `GiB` means **binary prefix**.

---

# 14. The mental model

Think of binary as a system of switches:

```text
        128 64 32 16 8 4 2 1
         │  │  │  │ │ │ │ │
        [1][0][1][0][1][1][0][1]
```

Each position is either:

```text
OFF → 0
ON  → 1
```

For this example:

```text
128 + 32 + 8 + 4 + 1
= 173
```

Therefore:

```text
10101101₂ = 173₁₀
```

### The core rules to remember

```text
Binary = base 2
Bit = 0 or 1
Byte = 8 bits
n bits = 2ⁿ possible combinations
Binary positions = powers of 2
```

Once these are solid, the next useful step is **hexadecimal**, because you'll see binary and hex constantly in networking, IP addresses, MAC addresses, memory addresses, permissions, colors, and low-level programming.


[[Networking]]