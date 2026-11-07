

A **network protocol** is a defined set of rules that tells two or more systems **how to communicate**.

For example, if Computer A sends data to Computer B, they need agreed rules for:

- What does a message look like?
    
- Who sends first?
    
- How do we identify the destination?
    
- How do we know the message arrived?
    
- What if data is corrupted?
    
- What if data is lost?
    
- How fast can we send?
    
- How do we end the communication?
    

Without shared rules:

```text
Computer A                    Computer B

"Here's some data"  ────────→  ???

                              "What is this?"
```

With a protocol:

```text
Computer A                    Computer B

     PROTOCOL RULES
     ───────────────
     format
     addressing
     sequencing
     errors
     acknowledgements
     timing
     ───────────────

       "message"  ─────────→
                    understands it
```

So a protocol is essentially a **communication contract between machines**.

---

# 1. Protocols existed before the Internet

This is important.

The invention of protocols did **not** happen with TCP/IP.

As soon as computers started communicating, engineers needed protocols.

The history roughly looks like:

```text
Computers
    ↓
Computer communication
    ↓
Need rules
    ↓
Protocols
    ↓
Computer networks
    ↓
Packet switching
    ↓
ARPANET
    ↓
TCP/IP
    ↓
Internet
    ↓
HTTP
    ↓
Web
```

---

# 2. Early protocols

In the 1950s and 1960s, communication systems already had rules for exchanging information.

For example, a terminal might need to communicate with a mainframe:

```text
Terminal
   │
   │ "I want to send data"
   ▼
Mainframe
   │
   │ "OK"
   ▼
Terminal
   │
   │ data
   ▼
Mainframe
```

The exact sequence of signals and messages had to be specified.

These were communication protocols, even though they were nothing like HTTP or TCP.

---

# 3. Why protocols became much more important with networking

A single computer connected directly to another computer is relatively simple:

```text
A ───────── B
```

But now imagine:

```text
        B
       / \
      /   \
     A     D
      \   /
       \ /
        C
```

Now you have questions:

- Where should data go?
    
- How does A identify D?
    
- Which path should it use?
    
- What happens if C fails?
    
- How are multiple conversations separated?
    
- What if a packet arrives twice?
    
- What if packets arrive out of order?
    

You need **rules**.

That's where networking protocols become fundamental.

---

# 4. Protocols became layered

One of the most important ideas in networking history was:

> **Don't make one enormous protocol responsible for everything. Divide communication into layers, with each layer solving a particular problem.**

For example:

```text
Application
    │
    │ HTTP
    ▼
Transport
    │
    │ TCP
    ▼
Internet
    │
    │ IP
    ▼
Link
    │
    │ Ethernet / Wi-Fi
    ▼
Physical
    │
    │ electrical / optical / radio
    ▼
Medium
```

Each layer has a different responsibility.

---

# 5. A concrete example

When your browser accesses:

```text
https://example.com
```

many protocols cooperate.

### DNS

```text
"What IP address belongs to example.com?"
```

DNS answers that.

### IP

```text
"Where should these packets go?"
```

IP handles addressing and forwarding between networks.

### TCP

```text
"How do we reliably exchange this data?"
```

TCP provides reliable ordered delivery.

### TLS

```text
"How do we encrypt and authenticate this communication?"
```

TLS provides cryptographic security.

### HTTP

```text
"Give me /index.html"
```

HTTP defines the Web request/response semantics.

### Ethernet/Wi-Fi

```text
"How do I move these frames across this local network?"
```

The link-layer protocol handles local transmission.

So one request is actually a **stack of protocols**.

---

# 6. Who invented protocols?

There isn't one person who invented "the protocol."

Different protocols were created for different problems.

Some important milestones:

### 1960s — ARPANET protocols

ARPANET initially used the **NCP (Network Control Program)**.

It allowed hosts on ARPANET to communicate.

But NCP had a fundamental limitation:

> It was designed for communication within ARPANET rather than solving the general problem of connecting completely different networks.

---

# 7. TCP/IP

This led to the much more important idea of **internetworking**.

In the 1970s, **Vint Cerf** and **Robert Kahn** developed the architecture that became TCP/IP.

The key problem was:

```text
Packet network A
       │
       │
       ▼
   Gateway/router
       │
       │
       ▼
Packet network B
```

Different networks could have different:

- hardware
    
- technologies
    
- speeds
    
- packet sizes
    
- internal protocols
    

TCP/IP created a common internetworking layer so they could communicate.

This is the origin of the modern idea:

> **A network of networks.**

---

# 8. The crucial separation: IP vs TCP

Originally the design was more unified, but it eventually became separated into distinct responsibilities.

### IP

**Internet Protocol**

Responsible primarily for:

```text
Addressing
+
Packet forwarding
```

Example:

```text
192.168.1.10
```

or IPv6:

```text
2001:db8::1
```

IP basically answers:

> "Where should this packet go?"

---

### TCP

**Transmission Control Protocol**

Responsible for reliable transport.

It deals with things such as:

```text
sequence numbers
acknowledgements
retransmission
ordering
flow control
congestion control
```

TCP essentially answers:

> "How can these two endpoints reliably exchange a stream of data?"

---

# 9. Then came application protocols

Once TCP/IP provided a general network foundation, applications could build on top of it.

Examples:

```text
1980s
│
├── DNS
├── SMTP
├── FTP
├── Telnet
│
1990s
│
├── HTTP
├── HTTPS
│
2000s+
│
├── SSH
├── Web APIs
├── REST-style APIs
├── WebSocket
...
```

Each protocol solves a particular communication problem.

For example:

**SMTP**

> How do mail servers exchange email?

**FTP**

> How do systems transfer files?

**DNS**

> How do we map human-readable names to network information?

**HTTP**

> How does a client request and receive Web resources?

---

# 10. Protocols aren't necessarily "software"

This is another important distinction.

A protocol is primarily a **specification/ruleset**.

An implementation is the actual software/hardware that follows those rules.

For example:

```text
HTTP specification
       ↓
Browser implementation
       ↓
HTTP request
```

Your browser implements HTTP.

Similarly:

```text
TCP specification
       ↓
Linux kernel TCP implementation
       ↓
Network communication
```

On your Debian system, Linux contains implementations of many networking protocols.

You don't install "TCP" as an ordinary application.

The operating system implements it.

---

# 11. Protocols need standards

Imagine I create:

> Alireza Network Protocol 1.0

and you create:

> Bob Network Protocol 1.0

We can't communicate unless we agree on the same rules.

That's why Internet protocols became standardized.

Organizations such as the **IETF** publish specifications called **RFCs (Requests for Comments)**.

For example, protocols such as:

- IP
    
- TCP
    
- DNS
    
- HTTP
    

have formal specifications.

The important historical principle is:

> **Open, documented protocols allowed independently developed computers and networks to interoperate.**

That is a huge reason the Internet could grow beyond one organization's network.

---

# 12. The deeper historical progression

The story now looks like this:

```text
1940s
  │
  │ computers
  ▼
1950s
  │
  │ mainframes + terminals
  ▼
1960s
  │
  │ networking research
  │ packet switching
  ▼
1969
  │
  │ ARPANET
  ▼
1970s
  │
  │ problem:
  │ "How do different networks communicate?"
  │
  │ TCP/IP
  ▼
1983
  │
  │ ARPANET adopts TCP/IP
  ▼
1980s
  │
  │ DNS, SMTP, FTP, etc.
  ▼
1990s
  │
  │ HTTP + HTML + URL
  ▼
Web
```

And this is the key mental model:

```text
PHYSICAL WORLD
    │
    │ copper / fiber / radio
    ▼
LINK PROTOCOL
    │
    │ Ethernet / Wi-Fi
    ▼
IP
    │
    │ addressing + routing
    ▼
TCP / UDP / QUIC
    │
    │ transport
    ▼
APPLICATION PROTOCOL
    │
    │ HTTP / DNS / SMTP / SSH
    ▼
APPLICATION
    │
    ├── Browser
    ├── Email
    ├── SSH client
    └── Your Spring Boot application
```

So when you eventually write:

```java
@GetMapping("/tasks")
public List<Task> getTasks() {
    ...
}
```

your Spring application is sitting **at the top of a protocol stack that took decades of networking research to develop**.

That's the historical reason protocols exist: **once computers stopped being isolated machines, humans needed standardized rules that allowed independently built machines, networks, and applications to communicate reliably.**


[[Networking]]