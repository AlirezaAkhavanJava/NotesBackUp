

**Modulation** is the process of **changing a physical signal (called a carrier) in a controlled way to encode information onto it**.

In networking/telecommunications:

> **Digital data → modulation → physical signal → transmission**

At the receiver:

> **physical signal → demodulation → digital data**

That's why **modem** comes from **MOdulator + DEModulator**.

### 1. Why do we need modulation?

A computer has data as bits:

```text
101101001011...
```

But a communication medium doesn't transmit abstract `0` and `1`. It carries a **physical signal**:

- electrical voltage on copper
    
- light on fiber
    
- electromagnetic waves through air
    
- electrical/audio-frequency signals over telephone lines
    

So we need a way to represent our data using a physical signal.

Modulation provides that representation.

---

### 2. The carrier

A **carrier wave** is a signal whose properties we deliberately modify to encode information.

For example, imagine a carrier:

```text
~~~~~~~~~~~~~~~
```

We can encode information by changing properties of this wave.

The three classic forms are:

### Amplitude modulation

Change the **amplitude** (strength):

```text
~~~~ ~~~~ ~~~~~~~~ ~~~~ 
```

Higher/lower amplitude represents different information.

### Frequency modulation

Change the **frequency**:

```text
~~~~~~ ~~~~ ~~ ~~~~~~~~ 
```

More cycles per second vs fewer cycles per second.

### Phase modulation

Change the **phase** — effectively shifting where the waveform's cycle begins.

Modern digital communications combine these techniques in sophisticated ways.

---

### 3. Digital modulation

For computer networking, we're usually interested in **digital modulation**.

Instead of directly transmitting:

```text
0 1 1 0 1 0
```

we map groups of bits to signal states.

For example, conceptually:

```text
00 → signal state A
01 → signal state B
10 → signal state C
11 → signal state D
```

Now **one signal symbol carries 2 bits**.

This is the basic idea behind techniques such as:

- ASK — Amplitude Shift Keying
    
- FSK — Frequency Shift Keying
    
- PSK — Phase Shift Keying
    
- QAM — Quadrature Amplitude Modulation
    

QAM is particularly important in modern communications.

---

### 4. Example: modem

With dial-up:

```text
Computer
   │
   │ digital bits
   ▼
 Modem
   │
   │ modulation
   ▼
Telephone line
   │
   │ physical signal
   ▼
 ISP modem
   │
   │ demodulation
   ▼
Digital bits
```

So when you heard the characteristic dial-up modem sounds, you were essentially hearing **modulated signals being exchanged between two modems**.

---

### 5. Important distinction

Don't think:

> modulation = converting digital to analog

That's too simplistic.

Modulation is fundamentally:

> **encoding information by varying properties of a carrier signal.**

The signal can be represented in different physical forms, and modern communications can use sophisticated digital modulation schemes.

For example, Wi-Fi uses modulation too:

```text
bits
 ↓
digital modulation
 ↓
radio-frequency signal
 ↓
antenna
 ↓
air
```

The receiving antenna/radio performs the reverse process.

---

### Mental model

```text
INFORMATION
    ↓
   bits
    ↓
MODULATION
    ↓
physical signal
    ↓
communication medium
    ↓
physical signal
    ↓
DEMODULATION
    ↓
   bits
    ↓
INFORMATION
```

This is the fundamental bridge between **computer data** and the **physical world**.

And this is why modulation is foundational to **telephones, modems, Wi-Fi, cellular networks, radio, and many other communication systems**.



---
 **A modem performs modulation and demodulation.** And your intuition is correct: the computer deals with **bits**, while the modem turns those bits into a **physical signal** that can travel through the communication medium.

The important distinction is:

> **Bits are information. A signal is the physical representation carrying that information.**

### What actually happens

Suppose your computer wants to send:

```text
10110010
```

The computer doesn't send literal abstract `1`s and `0`s through the telephone line.

Instead:

```text
Computer
   │
   │ 10110010  ← bits
   ▼
Modem
   │
   │ modulation
   ▼
Physical signal
   │
   │ ~~~~~~~~
   ▼
Telephone line
```

The modem has electronics that generate a **carrier signal** and modify it according to the bits.

For a simplified example, imagine:

```text
bit 0 → lower frequency
bit 1 → higher frequency
```

Then:

```text
10110010
 ↓
high low high high low low high low
 ↓
physical waveform
```

The receiving modem observes that waveform:

```text
Telephone line
      │
      ▼
   Modem
      │
      │ demodulation
      ▼
   10110010
      │
      ▼
   Computer
```

### But here's the key correction

The modem isn't simply doing:

```text
1 → electricity
0 → no electricity
```

That's **not what modulation generally means**.

It's manipulating properties of a signal:

```text
          carrier
             ↓
      ~~~~~~~~~~~~~~~
             ↓
   change its properties
             ↓
 amplitude / frequency / phase
             ↓
      encode the bits
```

For example, with **FSK (Frequency Shift Keying)**:

```text
0 → ~~~ ~~~ ~~~ ~~~
1 → ~~~~~ ~~~~~ ~~~~~
```

Different frequencies represent different symbols.

With modern modulation such as **QAM**, both amplitude and phase are changed, allowing many bits to be represented by each symbol.

### So what does "modem" literally mean?

```text
MOdem
  = MOdulator + DEModulator
```

**Modulator:**

```text
bits → physical signal
```

**Demodulator:**

```text
physical signal → bits
```

And that's exactly how we bridge these two worlds:

```text
DIGITAL WORLD                  PHYSICAL WORLD

Computer                       Telephone / radio / fiber
   │                                   ▲
   │ bits                              │
   ▼                                   │
 Modulator ─────── physical signal ────┤
   │                                   │
   │                                   │
   └──────────── Demodulator ──────────┘
```

One subtle point: **fiber optics also uses modulation**, even though the physical signal is light rather than an electrical telephone signal. The underlying idea is the same: **encode information into a physical signal.**

[[Networking]]