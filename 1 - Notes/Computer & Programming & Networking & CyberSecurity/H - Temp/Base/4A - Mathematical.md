# The Mathematics Behind Bits and Bytes

## 1. What Is a Number System?

A **number system** is a way of representing quantities using a set of digits and positional rules.

Humans normally use **decimal (base 10)**.

Decimal has 10 possible digits:

```text
0 1 2 3 4 5 6 7 8 9
```

Each position represents a power of 10:

```text
10³   10²   10¹   10⁰
1000  100   10    1
```

For example:

```text
583
```

means:

```text
5 × 100
+ 8 × 10
+ 3 × 1

= 500 + 80 + 3
= 583
```

Mathematically:

583=5(102)+8(101)+3(100)583 = 5(10^2) + 8(10^1) + 3(10^0)

This is called **positional notation**.

---

# 2. Why Does the Base Determine the Powers?

The base determines how many different digits are available.

In decimal:

```text
0 → 9
```

There are **10 possible symbols**.

The rightmost position represents:

100=110^0 = 1

The next position represents:

101=1010^1 = 10

The next:

102=10010^2 = 100

And so on.

Therefore:

```text
10⁰ = 1
10¹ = 10
10² = 100
10³ = 1000
```

The same principle works for every positional number system.

---

# 3. Binary Is Base 2

Binary has only two digits:

```text
0
1
```

Therefore binary is **base 2**.

Its positions are powers of 2:

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

For example:

```text
1011
```

has these positional values:

```text
2³  2²  2¹  2⁰
 8   4   2   1
```

Therefore:

10112=1(23)+0(22)+1(21)+1(20)1011_2 = 1(2^3)+0(2^2)+1(2^1)+1(2^0) =8+0+2+1=8+0+2+1 =11=11

So:

10112=1110\boxed{1011_2=11_{10}}

---

# 4. Why Does Binary Use Powers of 2?

A binary digit has exactly **two possible states**:

```text
0
1
```

You can think of a bit as a binary switch:

```text
OFF → 0
ON  → 1
```

One bit:

```text
0
1
```

has:

22

possible states.

Two bits:

```text
00
01
10
11
```

have:

2×2=22=42\times2=2^2=4

possible states.

Three bits:

```text
000
001
010
011
100
101
110
111
```

have:

2×2×2=23=82\times2\times2=2^3=8

possible states.

Therefore:

n bits=2n possible combinations\boxed{\text{n bits}=2^n\text{ possible combinations}}

The exponent simply represents **how many independent binary choices exist**.

---

# 5. Why Do We Multiply?

This comes from a fundamental counting principle.

Suppose you have:

- 2 choices of shirt
    
- 3 choices of pants
    

The number of possible combinations is:

2×3=62\times3=6

The same principle applies to bits.

Each bit has 2 possibilities:

```text
Bit 1 → 2 choices
Bit 2 → 2 choices
Bit 3 → 2 choices
```

Therefore:

2×2×2=82\times2\times2=8

or:

23=82^3=8

So:

> **The number of possible combinations is the product of the number of choices available at each position.**

---

# 6. Why Does `11111111` Equal 255?

An 8-bit number has these positions:

```text
Bit:     7   6   5   4   3   2   1   0
         ↓   ↓   ↓   ↓   ↓   ↓   ↓   ↓
Power:  2⁷ 2⁶ 2⁵ 2⁴ 2³ 2² 2¹ 2⁰
Value:  128 64 32 16  8  4  2  1
```

If every bit is `1`:

27+26+25+24+23+22+21+202^7+2^6+2^5+2^4+2^3+2^2+2^1+2^0

Therefore:

128+64+32+16+8+4+2+1=255128+64+32+16+8+4+2+1=255

So:

111111112=25510\boxed{11111111_2=255_{10}}

---

# 7. The Geometric Series Behind Binary

There is a mathematical shortcut.

Consider:

1+2+4+8+16+32+64+1281+2+4+8+16+32+64+128

This is a **geometric series**.

In general:

1+2+22+23+⋯+2n−11+2+2^2+2^3+\cdots+2^{n-1}

has the sum:

2n−1\boxed{2^n-1}

For 8 bits:

28−12^8-1 =256−1=256-1 =255=255

Therefore:

Maximum unsigned value with n bits=2n−1\boxed{\text{Maximum unsigned value with n bits}=2^n-1}

---

# 8. Why Does an 8-Bit Byte Have 256 Values?

A byte contains:

8 bits8\text{ bits}

Each bit has two possibilities.

Therefore:

28=2562^8=256

possible combinations.

Those combinations range from:

```text
00000000
```

to:

```text
11111111
```

Numerically:

```text
0
1
2
...
255
```

Therefore:

1 byte=8 bits=256 possible patterns\boxed{1\text{ byte}=8\text{ bits}=256\text{ possible patterns}}

---

# 9. Why Does the Rightmost Position Represent 2⁰?

This isn't a special computer rule.

It comes from positional notation.

In decimal:

```text
583
```

the positions are:

```text
10²  10¹  10⁰
100   10    1
```

The rightmost position represents:

100=110^0=1

Binary follows exactly the same rule:

```text
1011
```

has:

```text
2³  2²  2¹  2⁰
 8   4   2   1
```

So the exponent starts at zero because the rightmost position represents **one unit**.

---

# 10. Why Don't Computers Use Base 10?

Computers use binary because digital hardware naturally works with **two distinguishable states**.

Conceptually:

```text
LOW voltage  → 0
HIGH voltage → 1
```

Or:

```text
OFF → 0
ON  → 1
```

The real hardware is more sophisticated and uses voltage ranges, noise margins, transistors, and logic gates, but the abstraction is:

```text
Two physical states
       ↓
0 and 1
       ↓
Binary
       ↓
Base 2
```

Distinguishing two states reliably is much easier for digital electronic systems than reliably distinguishing many different states.

---

# 11. Why Powers of 2 Appear Everywhere in Computing

Once computers use binary, powers of 2 naturally appear everywhere.

### 8 bits

28=2562^8=256

### 16 bits

216=65,5362^{16}=65,536

### 32 bits

232=4,294,967,2962^{32}=4,294,967,296

### 64 bits

264=18,446,744,073,709,551,6162^{64}=18,446,744,073,709,551,616

This is why values such as:

```text
255
65535
4294967295
2³²
2⁶⁴
```

appear frequently in programming and computer architecture.

---

# 12. Signed Numbers

So far we've considered **unsigned** numbers.

For an 8-bit unsigned value:

0→2550\rightarrow255

because:

28=2562^8=256

possible patterns exist.

Signed integers need to represent negative numbers as well.

A common representation is **two's complement**.

For an 8-bit signed integer, the range is:

−27→27−1\boxed{-2^7\rightarrow2^7-1}

Therefore:

−128→127-128\rightarrow127

The total number of values is still:

128+128=256128+128=256

which is:

282^8

The same 256 bit patterns are simply interpreted differently.

---

# 13. Bits Represent Information

A bit can represent a binary choice:

```text
YES → 1
NO  → 0
```

One bit:

21=22^1=2

possible states.

Two bits:

22=42^2=4

Three bits:

23=82^3=8

Four bits:

24=162^4=16

And so on.

Therefore:

n bits=2n possible states\boxed{\text{n bits}=2^n\text{ possible states}}

Every additional bit **doubles** the number of possible states.

For example:

```text
7 bits  → 128 states
8 bits  → 256 states
9 bits  → 512 states
10 bits → 1024 states
```

---

# 14. Why This Matters for Memory

Suppose you have:

```text
8 bits
```

You have:

28=2562^8=256

possible patterns.

With 16 bits:

216=65,5362^{16}=65,536

possible patterns.

With 32 bits:

232=4,294,967,2962^{32}=4,294,967,296

possible patterns.

The amount of information that can be represented grows exponentially with the number of bits.

---

# 15. Binary and Networking

This mathematics directly connects to networking.

Suppose a network link has:

```text
100 Mbit/s
```

This means approximately:

```text
100,000,000 bits per second
```

Since:

8 bits=1 byte8\text{ bits}=1\text{ byte}

we can calculate:

100,000,000÷8=12,500,000100,000,000\div8 = 12,500,000

So:

100 Mbit/s≈12.5 MB/s\boxed{100\text{ Mbit/s}\approx12.5\text{ MB/s}}

The actual application throughput can be lower because of protocol overhead, congestion, hardware limitations, server limitations, etc.

---

# 16. Bits vs Bytes

Be careful about capitalization:

```text
b = bit
B = byte
```

Therefore:

```text
Mb = megabit
MB = megabyte

Gb = gigabit
GB = gigabyte
```

For example:

```text
100 Mb/s
```

means:

```text
100 megabits per second
```

while:

```text
100 MB/s
```

means:

```text
100 megabytes per second
```

Since:

1 byte=8 bits1\text{ byte}=8\text{ bits}

the difference is significant.

---

# 17. The Complete Mathematical Chain

The entire concept can be reduced to this:

```text
Digital hardware
       ↓
Two distinguishable states
       ↓
0 and 1
       ↓
Binary / base 2
       ↓
Each position is a power of 2
       ↓
Each bit provides 2 possible states
       ↓
n bits provide 2ⁿ possible states
```

Mathematically:

2×2×⋯×2=2n\boxed{ 2\times2\times\cdots\times2 = 2^n }

where `n` is the number of bits.

---

# 18. The Three Most Important Formulas

### Number of possible states

states=2n\boxed{\text{states}=2^n}

### Maximum unsigned value

max=2n−1\boxed{\text{max}=2^n-1}

### Byte

1 byte=8 bits\boxed{1\text{ byte}=8\text{ bits}}

For example:

8 bits8\text{ bits}

gives:

28=256 possible states2^8=256\text{ possible states}

and therefore:

0→2550\rightarrow255

---

# Mental Model

Don't memorize:

> "Binary uses powers of 2 because computers."

Instead remember:

```text
A bit has 2 possible states.
        ↓
Each new bit doubles the possibilities.
        ↓
n bits = 2ⁿ possibilities.
        ↓
Binary positions therefore use powers of 2.
```

That mathematical relationship is the foundation for understanding:

- Binary arithmetic
    
- Hexadecimal
    
- Bitwise operators
    
- IP addresses
    
- Subnet masks
    
- MAC addresses
    
- CPU integers
    
- Memory addressing
    
- File sizes
    
- Network bandwidth
    
- Character encoding
    
- Data representation
[[Networking]]