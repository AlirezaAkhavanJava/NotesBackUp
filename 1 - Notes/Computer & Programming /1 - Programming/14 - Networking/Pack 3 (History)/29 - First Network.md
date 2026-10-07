
If we go **before the Internet and before the Web**, and ask:

> **What was the first time computers were connected to each other?**

we need to be careful, because there wasn't one single “first computer network.” There were several milestones.

## 1. First computer-to-computer communication

The earliest computers were mostly **standalone machines**:

```text
Computer A        Computer B
┌─────────┐       ┌─────────┐
│   CPU   │       │   CPU   │
│ Memory  │       │ Memory  │
│ Storage │       │ Storage │
└─────────┘       └─────────┘
```

To move information between them, you might physically carry punched cards, magnetic tape, etc.

The next idea was:

```text
Computer A ─────────── Computer B
              cable
```

Now the computers could exchange information directly.

---

# 2. One important early example: SAGE

In the 1950s, the U.S. **SAGE (Semi-Automatic Ground Environment)** air-defense system connected computers and radar stations over a large communications network.

SAGE

It wasn't the Internet and wasn't a general-purpose computer network like today's Internet.

But it demonstrated something fundamental:

> **Computers could communicate with remote computers and equipment over communication networks.**

SAGE used telephone-line communications and modems.

```text
Radar
  ↓
Communication network
  ↓
SAGE computer
  ↓
Other SAGE systems
```

This is also historically important because it helped drive development of early modems.

---

# 3. Then came computers connected locally

Another major step was connecting computers within the **same location**.

This eventually became what we call a **LAN — Local Area Network**.

For example:

```text
        ┌───────────┐
        │ Computer A│
        └─────┬─────┘
              │
        ┌─────┴─────┐
        │   Network │
        └─────┬─────┘
              │
       ┌──────┴──────┐
       │             │
 Computer B      Computer C
```

But again, there wasn't one single invention called “the first LAN.”

Different systems experimented with computer networking during the 1960s.

---

# 4. The really important breakthrough: packet switching

This is where our previous story connects.

Researchers realized:

> Instead of establishing a dedicated communication circuit for every computer conversation, we can divide data into packets and let many computers share the network.

That gives us:

```text
Computer A ─┐
Computer B ─┼──→ Network ──→ Computer D
Computer C ─┘
```

Packets from different computers can share the same links.

This idea was developed independently by **Paul Baran** at RAND and **Donald Davies** at the UK National Physical Laboratory during the 1960s.

Davies called the units **packets**.

---

# 5. ARPANET: the major early computer network

Then came **ARPANET**.

In 1969:

```text
UCLA
 │
 │
 ▼
SRI
```

Those computers communicated over a packet-switched network.

The first ARPANET nodes were:

- UCLA
    
- Stanford Research Institute (SRI)
    
- UC Santa Barbara
    
- University of Utah
    

By 1969, these sites were interconnected.

This is one of the most important moments in computer-network history.

But remember:

> **ARPANET was not the first instance of computers communicating.**

It was a major milestone in creating a **large-scale packet-switched computer network**.

---

# 6. Then the problem became bigger

Once you can connect computers:

```text
A ─── B ─── C
```

you naturally want:

```text
Network A ─── Network B ─── Network C
```

And now we have the problem of **internetworking**.

Different networks might use different technologies.

So researchers developed **TCP/IP**, whose fundamental purpose was:

> Allow independent networks to communicate with one another.

That gives:

```text
Network A
   │
   │
 TCP/IP
   │
Network B
   │
   │
 TCP/IP
   │
Network C
```

That's where the concept of a **network of networks** comes from.

Eventually:

**ARPANET + other networks + TCP/IP + many independent networks → Internet**

---

# The timeline you should keep in your head

```text
1950s
│
├── Computers communicate with remote systems
│
├── SAGE
│
▼
1960s
│
├── Computer networking research
│
├── Packet switching
│
▼
1969
│
├── ARPANET
│
├── UCLA ↔ SRI
│
▼
1970s
│
├── More networks
│
├── TCP/IP development
│
▼
1983
│
├── ARPANET adopts TCP/IP
│
▼
1980s–1990s
│
├── Many independent networks
├── DNS
├── Commercial networks
│
▼
Internet
│
▼
1990
│
└── World Wide Web
```

So the hierarchy is:

**Computer communication → computer networks → packet-switched networks → ARPANET → internetworking/TCP-IP → Internet → Web**

And this distinction is crucial:

> **The Web came very late. The Internet itself also came after decades of computer-network development.**

The next interesting question is actually **“What did the very first computer networks physically look like — what cable, what hardware, and how did one computer actually send a bit to another?”** That's the layer underneath all of this.


[[Networking]]