

## ARPANET

**ARPANET (Advanced Research Projects Agency Network)** was an early computer network created in the **late 1960s** by the U.S. **ARPA** (later DARPA). It is widely regarded as a major predecessor of the modern Internet.

The important thing is **why ARPANET mattered**.

### 1. Before ARPANET

Computers were mostly isolated:

```text
Computer A        Computer B        Computer C
    │                 │                 │
    X                 X                 X
```

There wasn't a general-purpose network connecting them.

ARPA wanted researchers at different institutions to be able to share computing resources and communicate.

### 2. ARPANET used packet switching

Instead of creating one dedicated connection:

```text
A ═══════════════════════ B
```

data could be broken into packets:

```text
A
│
├── Packet 1 ──┐
├── Packet 2 ──┼── network ──→ B
├── Packet 3 ──┤
└── Packet 4 ──┘
```

This was heavily influenced by the packet-switching research of **Paul Baran** and **Donald Davies**.

### 3. First ARPANET connection

In **October 1969**, the first ARPANET connection was established between:

```text
UCLA ───────── SRI
```

The first attempted message was:

```text
LOGIN
```

But the system crashed after:

```text
LO
```

So historically, the first message successfully sent over ARPANET was essentially **"LO"**.

### 4. ARPANET → Internet

ARPANET itself wasn't the Internet as we know it.

The evolution was roughly:

```text
Packet-switching research
        ↓
     ARPANET
        ↓
TCP/IP developed
        ↓
ARPANET adopts TCP/IP
        ↓
Multiple networks interconnected
        ↓
        Internet
```

A particularly important date is **January 1, 1983**, when ARPANET transitioned to **TCP/IP**.

That transition is often called the **"flag day"** of the Internet.

### The key concept

Don't memorize:

> "ARPANET = Internet."

Instead remember:

> **ARPANET was an early packet-switched network that became one of the major foundations from which the modern Internet developed.**

And this connects directly to what you just asked about:

**packet → packet switching → ARPANET → TCP/IP → Internet → HTTP/Web**.


[[Networking]]