



## The Core Problem

Before TCP/IP became universal, each computer vendor built **its own complete, proprietary networking system**. A network built with IBM computers could not talk to a network built with DEC computers. It was like:

- One group spoke **only French**
- Another spoke **only Japanese**
- Another spoke **only Arabic**
- And there was **no translator**

Even worse: they used different cables, different connectors, different electrical signals, different addressing schemes, and different software. It wasn't just a language barrier — it was a **physical and cultural barrier** too.

---

## The "Languages" (Proprietary Protocol Suites)

Here are the major ones that existed before TCP/IP dominance:

| Vendor | Protocol Suite | Era | Used For |
|---|---|---|---|
| **IBM** | SNA (Systems Network Architecture) | 1974 | Mainframes, corporate networks |
| **DEC** | DECnet | 1975 | PDP/VAX minicomputers |
| **Xerox** | XNS (Xerox Network Systems) | 1970s | Early Ethernet networks |
| **Apple** | AppleTalk | 1985 | Macintosh networks |
| **Novell** | IPX/SPX | 1983 | PC local area networks |
| **Burroughs** | BNA | 1970s | Burroughs mainframes |
| **Honeywell** | DSA | 1970s | Honeywell systems |
| **Siemens** | TRANSDATA | 1970s | Siemens mainframes |
| **Telecom PTTs** | X.25 | 1976 | Public data networks |
| **ISO** | OSI | 1984 | International standard attempt |

Each one was a **complete stack** — from the physical cable all the way up to the application. They were not designed to interoperate.

---

## Visual: The Tower of Babel

```
+----------+  +----------+  +----------+  +----------+  +----------+
|   IBM    |  |   DEC    |  |  Apple   |  |  Novell  |  |  Xerox   |
|   SNA    |  |  DECnet  |  | AppleTalk|  | IPX/SPX  |  |   XNS    |
+----------+  +----------+  +----------+  +----------+  +----------+
     |              |              |              |              |
     |              |              |              |              |
  IBM cable     DEC cable     Apple cable    Ethernet      Ethernet
  (proprietary) (proprietary) (proprietary)  (but with     (but with
                                              IPX/SPX)      XNS)
     |              |              |              |              |
     v              v              v              v              v
  IBM host      DEC host      Macintosh      PC server     Xerox host

     X ---------- CANNOT TALK ---------- X
     X ---------- CANNOT TALK ---------- X
     X ---------- CANNOT TALK ---------- X
```

Every vertical stack is **self-contained**. There is no horizontal communication between them.

---

## What Each "Language" Looked Like

### 1. IBM SNA (Systems Network Architecture)

**Addressing:** Uses names like `NETID.SSCP.PU.LU`  
**Routing:** Controlled by a central mainframe (VTAM)  
**Physical:** Token Ring, SDLC, proprietary coax

**Example of SNA addressing:**
```
NETA.VM1.PU2.LU3
│    │   │   │
│    │   │   └── Logical Unit (application)
│    │   └────── Physical Unit (device)
│    └────────── System Services Control Point
└─────────────── Network ID
```

A DEC computer had no idea what this meant.

---

### 2. DECnet

**Addressing:** `Area.Node` format, e.g., `12.345`  
**Routing:** Hierarchical, DEC-specific  
**Physical:** Ethernet, but with DECnet framing

**Example:**
```
DECnet address: 12.345
  Area = 12
  Node = 345
```

An IBM mainframe could not route to `12.345`.

---

### 3. AppleTalk

**Addressing:** `Network.Node.Socket`, e.g., `5.12.254`  
**Routing:** LocalTalk, EtherTalk, TokenTalk  
**Physical:** LocalTalk (proprietary cabling), later Ethernet

**Example:**
```
AppleTalk address: 5.12.254
  Network = 5
  Node = 12
  Socket = 254
```

A Novell server could not understand this.

---

### 4. Novell IPX/SPX

**Addressing:** `Network:Node:Socket` in hex, e.g., `00000001:00001A2B3C4D:0451`  
**Routing:** IPX (like IP but proprietary)  
**Physical:** Ethernet, Token Ring, ARCnet

**Example IPX packet:**
```
IPX Header:
  Checksum:     FFFF
  Length:       0030
  Transport:    00
  Packet Type:  01
  Dest Network: 00000001
  Dest Node:    00001A2B3C4D
  Dest Socket:  0451
  ...
```

IBM SNA could not read this.

---

### 5. X.25 (Telecom PTT Standard)

**Addressing:** X.121 addresses (up to 14 digits)  
**Routing:** Virtual circuits through telecom switches  
**Physical:** Leased lines, modems

**Example X.121 address:**
```
X.121: 31101234567890
  DCC = 311 (country code)
  ...
```

This was a **connection-oriented virtual circuit** — completely different from TCP/IP's datagram model.

---

### 6. OSI (The "International Standard")

**Addressing:** NSAP (Network Service Access Point) — up to 20 bytes  
**Routing:** IS-IS, ES-IS  
**Physical:** Any, but with OSI framing

**Example NSAP address:**
```
47.0005.80FFEE.00010000.ABCD.1234.5678
│   │    │      │        │    │    │
│   │    │      │        │    │    └── NSEL (selector)
│   │    │      │        │    └─────── System ID
│   │    │      │        └──────────── Area
│   │    │      └───────────────────── Domain
│   │    └──────────────────────────── Authority
│   └───────────────────────────────── AFI (Authority Format)
└───────────────────────────────────── Initial Domain Part
```

TCP/IP's 32-bit address `192.168.1.1` was **far simpler**.

---

## The Real-World Nightmare

Imagine a company in 1985 with:

- **IBM mainframe** for accounting (SNA)
- **DEC VAX** for engineering (DECnet)
- **Apple Macs** for design (AppleTalk)
- **Novell PCs** for office work (IPX/SPX)

```
+----------------+     +----------------+     +----------------+     +----------------+
|  IBM Mainframe |     |   DEC VAX      |     |  Apple Macs    |     |  Novell PCs    |
|     SNA        |     |   DECnet       |     |  AppleTalk     |     |  IPX/SPX       |
+----------------+     +----------------+     +----------------+     +----------------+
        |                      |                      |                      |
        |                      |                      |                      |
   IBM terminal           DEC terminal           Mac printer           PC file server
        |                      |                      |                      |
        v                      v                      v                      v
   [Accounting]           [Engineering]          [Design]              [Office]

   X ----- CANNOT SHARE FILES ----- X
   X ----- CANNOT SEND EMAIL ------ X
   X ----- CANNOT PRINT ACROSS ---- X
   X ----- CANNOT USE ONE NETWORK - X
```

To share data between them, you needed:
- **Gateways** (expensive, slow, limited)
- **Manual tape/disk transfer** (sneakernet)
- **Separate networks** (duplicate everything)

---

## How TCP/IP Fixed It

TCP/IP provided **one common language** that any computer could speak, regardless of vendor.

### The Key Ideas

| Problem | TCP/IP Solution |
|---|---|
| Different addressing | One IP address format (e.g., `192.168.1.1`) |
| Different routing | One routing model (IP routers) |
| Different transport | TCP and UDP for everyone |
| Different applications | Common protocols (HTTP, SMTP, DNS, FTP) |
| Vendor lock-in | Open, free, vendor-neutral |
| Complex standards | Simple, running code |

### Visual: TCP/IP as the Universal Translator

```
+----------+  +----------+  +----------+  +----------+  +----------+
|   IBM    |  |   DEC    |  |  Apple   |  |  Novell  |  |  Xerox   |
|   SNA    |  |  DECnet  |  | AppleTalk|  | IPX/SPX  |  |   XNS    |
+----------+  +----------+  +----------+  +----------+  +----------+
     |              |              |              |              |
     |              |              |              |              |
     +--------------+--------------+--------------+--------------+
                              |
                              v
                    +-------------------+
                    |      TCP/IP       |
                    |  (Common Language)|
                    +-------------------+
                    |  Application      |  HTTP, SMTP, DNS, FTP
                    |  Transport        |  TCP, UDP
                    |  Internet         |  IP (IPv4/IPv6)
                    |  Network Access   |  Ethernet, Wi-Fi
                    +-------------------+
                              |
                              v
                    +-------------------+
                    |   One Global      |
                    |   Internet        |
                    +-------------------+
```

### Before vs After

**Before (1985):**
```
IBM ---X--- DEC ---X--- Apple ---X--- Novell
```

**After (1995):**
```
IBM -------- DEC -------- Apple -------- Novell
  \           |            |            /
   \          |            |           /
    \         |            |          /
     +--------+------------+---------+
              |
         [ TCP/IP Network ]
              |
         [ The Internet ]
```

---

## Concrete Example: Sending a File

### Before TCP/IP (IBM to DEC)

1. IBM user creates file on SNA system.
2. File is in EBCDIC format (IBM character encoding).
3. To send to DEC, need an **SNA-to-DECnet gateway**.
4. Gateway translates SNA LU 6.2 to DECnet task-to-task.
5. File format must be converted (EBCDIC to ASCII).
6. Often fails due to incompatibilities.

**Success rate:** Low. **Speed:** Slow. **Cost:** High.

### After TCP/IP (Any to Any)

1. IBM user creates file.
2. File is sent via **FTP** (File Transfer Protocol) over TCP/IP.
3. Any computer with TCP/IP can receive it.
4. Format is standardized (binary or ASCII mode).
5. Works between IBM, DEC, Apple, Novell, Sun, HP, etc.

**Success rate:** High. **Speed:** Fast. **Cost:** Free.

---

## The "Language" Analogy in Full

| Concept | Human Language Analogy | Networking Equivalent |
|---|---|---|
| Different languages | French, Japanese, Arabic | SNA, DECnet, AppleTalk, IPX/SPX |
| No common translator | No one speaks all languages | No gateway or gateway is limited |
| Different alphabets | Latin, Kanji, Arabic script | EBCDIC vs ASCII, different frame formats |
| Different grammar | SVO vs SOV word order | Connection-oriented vs connectionless |
| Different customs | Bow vs handshake vs kiss | Different handshake protocols |
| **TCP/IP** | **English as lingua franca** | **Common protocol for all** |
| **Routers** | **Translators at the UN** | **Devices that forward packets between networks** |
| **The Internet** | **The United Nations** | **Global network where all can communicate** |

---

## Why This Mattered

Without a common language:

- **No global internet** — only isolated corporate networks
- **No email between companies** — only internal mail
- **No web** — only proprietary information systems
- **Vendor lock-in** — buy everything from one company or nothing works
- **Slow innovation** — each vendor reinvents everything

With TCP/IP:

- **Global internet** — anyone can connect to anyone
- **Email, web, file sharing** — across all vendors
- **Competition** — buy best-of-breed from different vendors
- **Fast innovation** — build on a common platform
- **The web, social media, cloud, streaming** — all possible

---

## Summary

| Aspect | Before TCP/IP | After TCP/IP |
|---|---|---|
| Languages | Many proprietary protocol suites | One common suite |
| Interoperability | Almost none | Universal |
| Addressing | Vendor-specific | IP addresses for all |
| Routing | Proprietary | IP routing |
| Cost | Expensive, per-vendor | Free, open |
| Result | Islands of automation | One global internet |

**The "different languages" were real, complete, incompatible networking systems built by IBM, DEC, Apple, Novell, Xerox, and telecom companies.** TCP/IP became the **Esperanto of networking** — not because it was the most elegant, but because it was **open, free, simple, and already working**. It gave every computer, regardless of maker, a way to speak the same language.


[[Networking]]