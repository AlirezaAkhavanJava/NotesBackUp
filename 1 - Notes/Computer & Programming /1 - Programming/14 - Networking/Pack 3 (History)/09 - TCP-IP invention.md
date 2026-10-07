

# TCP/IP — why it was invented

**TCP/IP is a suite of networking protocols designed to allow different networks and different kinds of computers to communicate with each other.**

The key word is **inter-networking**.

ARPANET had already demonstrated packet switching, but there was a fundamental limitation:

> **ARPANET was one network. The real problem was connecting many independent networks together.**

This is where TCP/IP came from. ([Internet Society](https://www.internetsociety.org/internet/history-internet/brief-history-internet/?utm_source=chatgpt.com "A Brief History of the Internet - Internet Society"))

---

# 1. The problem

Imagine we have three completely different packet networks:

```text
        Network A
       ARPANET
          │
          │
       [Gateway]
          │
          │
     ┌────┴────┐
     │         │
 Network B   Network C
 Packet      Satellite
 Radio       Network
```

Each network might have its own:

- hardware
    
- packet format
    
- addressing
    
- limitations
    
- transmission technology
    
- internal protocols
    

The question was:

> **How can a computer on Network A communicate with a computer on Network C without requiring the networks themselves to become identical?**

That was the fundamental problem.

DARPA explicitly started an **Internetting** research program in 1973 to solve this problem: interconnect different packet-switched networks transparently. ([Internet Society](https://www.internetsociety.org/internet/history-internet/brief-history-internet-related-networks/?utm_source=chatgpt.com "History of the Internet & Related Networks - Internet Society"))

---

# 2. Who invented TCP/IP?

The two names you should remember are:

### Robert "Bob" Kahn

Kahn was working at **DARPA** and had been heavily involved in ARPANET's architecture.

He developed the important **architectural idea**:

> Individual networks should be allowed to operate independently, while gateways connect them together.

### Vint Cerf

Cerf was at **Stanford University** and had experience with the existing ARPANET **NCP** protocol.

In 1973, Kahn asked Cerf to work with him on the detailed design of the new protocol. ([Internet Society](https://www.internetsociety.org/internet/history-internet/brief-history-internet/?utm_source=chatgpt.com "A Brief History of the Internet - Internet Society"))

So:

```text
Robert Kahn
    │
    │ architecture
    │
    ├──────────────┐
    │              │
    ▼              ▼
Vint Cerf ── detailed protocol design
    │
    ▼
TCP/IP
```

They published the foundational paper:

**"A Protocol for Packet Network Intercommunication"** in 1974. ([Internet Society](https://www.internetsociety.org/internet/history-internet/brief-history-internet/?utm_source=chatgpt.com "A Brief History of the Internet - Internet Society"))

It is therefore more accurate to say **Cerf and Kahn co-designed TCP/IP**, rather than claiming one person invented it alone.

---

# 3. What did TCP/IP actually solve?

This is the important part.

## Problem #1 — Different networks couldn't easily communicate

Before Internetting:

```text
Network A ── A's protocol ──┐
                            X
Network B ── B's protocol ──┘
```

TCP/IP introduced a common **internetworking layer**:

```text
Network A
    │
    │
   IP
    │
 [Router]
    │
    │
   IP
    │
Network B
```

The individual networks didn't need to become identical.

That is an enormous design decision.

---

# 4. Problem #2 — What happens when packets disappear?

Packet networks aren't perfect.

A packet can:

```text
Source
  │
  ├── P1 ───────────────→ Destination ✓
  │
  ├── P2 ──────X           lost
  │
  └── P3 ───────────────→ Destination ✓
```

Something needed to detect that data was missing and, when appropriate, recover it.

That's one of **TCP's** jobs.

Conceptually:

```text
Sender                         Receiver

P1 ──────────────────────────→
P2 ─────────── X

P3 ──────────────────────────→

       "I didn't receive P2"

       ←──── retransmit ─────

P2 ──────────────────────────→
```

TCP provides mechanisms including acknowledgements, retransmission, sequencing and flow control. ([Internet Society](https://www.internetsociety.org/internet/history-internet/brief-history-internet/?utm_source=chatgpt.com "A Brief History of the Internet - Internet Society"))

---

# 5. Problem #3 — How do we know where a packet goes?

You need addressing.

Imagine:

```text
Computer A
     │
     │ packet
     ▼
  Router 1
     │
     ▼
  Router 2
     │
     ▼
Computer B
```

The network needs to know:

> Where is Computer B?

That's the job of **IP**.

IP provides addressing and packet forwarding between networks.

So conceptually:

```text
IP
│
├── "Who is the destination?"
├── addressing
└── forwarding packets
```

while:

```text
TCP
│
├── Did the data arrive?
├── Is it in the correct order?
├── Should something be retransmitted?
├── How fast should we send?
└── flow/reliability control
```

This distinction is **extremely important**.

---

# 6. The genius of the design: don't make the networks identical

This was one of the foundational ideas.

Suppose:

```text
        ARPANET
           │
           │
        Router
           │
     ┌─────┴─────┐
     │           │
 Satellite     Radio
 Network       Network
```

TCP/IP doesn't say:

> "Every network must use the same underlying technology."

Instead:

> **"We'll define a common internetworking protocol above them."**

So:

```text
              TCP
               │
               ▼
              IP
               │
      ┌────────┼────────┐
      ▼        ▼        ▼
   Ethernet  Wi-Fi   Satellite
```

That's why the Internet can connect wildly different technologies.

This is the **"network of networks"** idea.

---

# 7. Why is it called TCP/IP?

Originally, the design was essentially a single protocol called **TCP**.

But during development, an important architectural separation emerged.

They realized two different problems should be handled separately:

```text
TCP
│
└── reliable host-to-host transport

IP
│
└── addressing + forwarding packets
```

So TCP and IP became separate protocols.

Later, **UDP** was introduced for applications that didn't need TCP's reliability mechanisms. ([Internet Society](https://www.internetsociety.org/internet/history-internet/brief-history-internet/?utm_source=chatgpt.com "A Brief History of the Internet - Internet Society"))

That's why today we have:

```text
Application
    │
    ├── HTTP
    ├── DNS
    ├── SSH
    └── ...
    │
   TCP / UDP
    │
   IP
    │
 Ethernet / Wi-Fi / ...
```

---

# 8. How was TCP/IP actually developed?

It wasn't just a theoretical document.

They had to **implement and test it**.

DARPA funded implementations involving organizations including Stanford, BBN and University College London. Multiple independent implementations were eventually able to communicate with one another. ([Internet Society](https://www.internetsociety.org/internet/history-internet/brief-history-internet/?utm_source=chatgpt.com "A Brief History of the Internet - Internet Society"))

The architecture was tested across different networks.

One famous milestone was a **1977 demonstration** involving multiple networks communicating using the emerging Internet architecture.

The point was essentially:

```text
Network A
    │
    ▼
   IP
    │
 Network B
    │
    ▼
   IP
    │
 Network C
```

The networks could remain independent while the hosts communicated as though they were part of one larger system.

---

# 9. What happened to ARPANET's old protocol?

Before TCP/IP, ARPANET used **NCP — Network Control Protocol**.

Eventually:

```text
ARPANET
   │
   │ NCP
   ▼
limited internetworking
```

became:

```text
ARPANET
   │
   │ TCP/IP
   ▼
Internet architecture
```

On **January 1, 1983**, ARPANET officially transitioned from NCP to TCP/IP. This is one of the most important dates in Internet history. ([Internet Society](https://www.internetsociety.org/internet/history-internet/brief-history-internet/?utm_source=chatgpt.com "A Brief History of the Internet - Internet Society"))

---

# 10. The entire evolution

Now connect everything you've been learning:

```text
1960s
Packet Switching
      │
      ▼
1969
ARPANET
      │
      │
      │ Problem:
      │ "How do we connect
      │  different networks?"
      ▼
1973
Internetting Project
      │
      ├── Robert Kahn
      │
      └── Vint Cerf
              │
              ▼
        TCP/IP design
              │
              ▼
        implementations
              │
              ▼
1983
ARPANET → TCP/IP
              │
              ▼
      Network of networks
              │
              ▼
          INTERNET
```

## The mental model I want you to keep

There were **three different problems**, solved progressively:

```text
1. How can we efficiently move data?
        ↓
   PACKET SWITCHING

2. How can computers communicate over a packet network?
        ↓
       ARPANET

3. How can DIFFERENT packet networks communicate?
        ↓
       TCP/IP
```

And within TCP/IP:

```text
IP  = "Where should this packet go?"
TCP = "How do we reliably deliver this data?"
```

That last distinction is the foundation you'll need when we get into **OSI/TCP-IP layers, ports, sockets, TCP handshake, IP addresses, routing, HTTP, and what actually happens when you run `curl https://google.com`**.


[[Networking]]