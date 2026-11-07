
 This is the missing layer in the history: **what were computers actually communicating before the Web/Internet became what we know today?** And terms like _latency, bandwidth, throughput, packets, terminals,_ etc. came directly from these problems.

## 1. What were they sending?

Early computer networks were mostly sending **data needed to operate remote computers and systems**, not web pages.

For example:

```text
Terminal
   │
   │ "RUN REPORT 123"
   ▼
Mainframe
   │
   │ computes
   ▼
Terminal
   │
   │ "REPORT RESULTS..."
   ▼
User
```

The data could be:

- keyboard commands
    
- text
    
- numbers
    
- program instructions
    
- files
    
- database records
    
- scientific measurements
    
- radar information
    
- status/control information
    
- printer output
    
- later, email and other digital messages
    

The fundamental thing being transmitted was **bits**.

```text
01001000 01100101 01101100 01101100 01101111
```

Everything else—text, numbers, files, images—is an interpretation of those bits.

---

# 2. Mainframe terminals: the first important model

In the 1950s–60s, one major use was **remote access to a central computer**.

Imagine a university:

```text
                 Mainframe
              ┌─────────────┐
              │ CPU         │
              │ Memory      │
              │ Programs    │
              │ Database    │
              └──────┬──────┘
                     │
              communication line
                     │
        ┌────────────┼────────────┐
        ↓            ↓            ↓
    Terminal A   Terminal B   Terminal C
```

A student could type:

```text
RUN PROGRAM
```

The terminal sends the characters.

The mainframe processes them.

The result comes back.

This is an early form of **interactive computing**.

---

# 3. Why latency mattered

**Latency = the time between an action and the corresponding response.**

For networking, we often care about the time it takes for data to travel from one point to another.

Example:

```text
Computer A
   │
   │ request
   │ ────────────────→
   │                  │
   │              Computer B
   │                  │
   │ ←────────────────│
   │
   response
```

If this takes 50 ms:

> latency ≈ 50 ms

If it takes 500 ms:

> latency ≈ 500 ms

### Why did early systems care?

Imagine typing:

```text
A
```

and waiting half a second before seeing:

```text
A
```

Then:

```text
B
```

wait...

```text
B
```

Interactive computing becomes painful.

So networking researchers had to care about **response time** long before the Web.

---

# 4. Latency is not the same as speed

This distinction is extremely important.

Suppose we have:

```text
Connection A:
latency = 10 ms
bandwidth = 10 Mbps
```

and:

```text
Connection B:
latency = 100 ms
bandwidth = 1 Gbps
```

Connection B has much greater capacity, but its first response may take longer to arrive.

Think of them as different properties:

**Latency**

> How long does it take for something to travel?

**Bandwidth**

> How much data can the connection carry per unit of time?

---

# 5. Bandwidth

**Bandwidth** describes the capacity of a communication channel, commonly measured in bits per second.

Examples:

```text
1 kbps
56 kbps
10 Mbps
1 Gbps
100 Gbps
```

Be careful:

**bit ≠ byte**

```text
1 byte = 8 bits
```

So:

```text
100 Mbps
```

means:

```text
100 million bits/second
```

not 100 million bytes/second.

---

# 6. Why bandwidth became important

Early communication links were extremely limited.

Imagine you need to transmit:

```text
1 MB
```

over:

```text
56 kbps
```

The theoretical minimum transmission time is roughly:

```text
1 MB × 8 = 8 megabits

8,000,000 bits / 56,000 bits/s
≈ 143 seconds
```

So roughly **2.4 minutes**, before accounting for protocol overhead and other limitations.

Compare that with a modern gigabit connection:

```text
1 GB
```

can theoretically take around:

```text
8,000 megabits / 1,000 megabits/s
≈ 8 seconds
```

Real performance differs, but the principle is the same.

---

# 7. Throughput

**Throughput = the actual amount of data successfully transferred per unit of time.**

This is different from bandwidth.

Suppose your connection has:

```text
Bandwidth: 100 Mbps
```

but because of congestion, protocol overhead, errors, etc., you're actually getting:

```text
Throughput: 72 Mbps
```

So:

```text
Bandwidth = potential capacity
Throughput = actual achieved rate
```

---

# 8. Packet

Then we reach one of the most important ideas of networking.

Instead of treating a large message as one enormous continuous stream:

```text
HELLOTHISISALONGMESSAGE...
```

the network can divide it into smaller units:

```text
┌────────┐
│ packet │
├────────┤
│ packet │
├────────┤
│ packet │
├────────┤
│ packet │
└────────┘
```

A packet typically contains:

```text
┌──────────────┬─────────────────┐
│    Header    │     Payload     │
└──────────────┴─────────────────┘
```

The header contains networking information.

The payload contains part of the actual data.

---

# 9. Why packet switching appeared

This became extremely important in the 1960s.

Imagine several computers:

```text
A ──┐
B ──┼── Network link ── D
C ──┘
```

Computer A might have nothing to send for 10 seconds.

Then suddenly it needs to send a lot.

Computer B does the same.

Computer C does the same.

A dedicated circuit wastes capacity when the sender is idle.

Packet switching allows them to **share the network dynamically**.

This was one of the foundational ideas behind ARPANET.

---

# 10. Error detection

Physical communication isn't perfect.

Signals can become corrupted.

Suppose the sender transmits:

```text
10110110
```

but the receiver gets:

```text
10100110
```

Something went wrong.

Networks therefore developed mechanisms for detecting errors.

One important concept is the **checksum**.

The sender calculates information from the data:

```text
data → checksum
```

and sends both.

The receiver calculates the checksum again.

If they don't match:

```text
received data
      ↓
checksum doesn't match
      ↓
possible corruption
```

Then higher-level protocols can decide what to do.

---

# 11. Retransmission

Suppose packet #7 disappears:

```text
Sender

1 → 2 → 3 → 4 → 5 → 6 → X → 8 → 9

                    packet 7 lost
```

A reliable protocol can detect that packet #7 wasn't received and request/recover it.

This eventually becomes one of TCP's major responsibilities.

```text
TCP
 ├── sequence numbers
 ├── acknowledgements
 ├── retransmission
 ├── flow control
 └── congestion control
```

But **TCP came later**. These networking problems existed before TCP/IP.

---

# 12. Flow control

Imagine:

```text
Fast computer
      │
      │ 10,000 packets/s
      ▼
Slow computer
      │
      │ can process only
      │ 1,000 packets/s
```

The receiver can become overwhelmed.

**Flow control** means regulating transmission so the sender doesn't overwhelm the receiver.

This problem became especially important as computers of different capabilities communicated.

---

# 13. Congestion

Now imagine:

```text
Computer A ─┐
Computer B ─┤
Computer C ─┼──→ bottleneck → destination
Computer D ─┘
```

The network itself can become overloaded.

That's **congestion**.

Packets begin waiting in queues:

```text
             ┌──────────────┐
A ──────────→│              │
B ──────────→│    QUEUE     │──→
C ──────────→│              │
D ──────────→│              │
             └──────────────┘
```

This increases latency and can eventually cause packet loss.

Modern TCP has **congestion control** specifically to deal with this.

---

# 14. The historical evolution of these problems

This is the useful timeline:

```text
1950s
│
├── Remote computer communication
├── Mainframes
├── Terminals
│
│ Problem:
│ "How do I communicate with a remote computer?"
│
▼
1960s
│
├── Computer networking research
├── Packet switching
│
│ Problems:
│ "How do multiple computers share a network?"
│ "What happens when packets are lost?"
│
▼
1969
│
├── ARPANET
│
│ Problems become larger:
│ latency
│ bandwidth
│ packet loss
│ routing
│ reliability
│
▼
1970s
│
├── Internetworking research
├── TCP/IP
│
│ Problems:
│ "How do completely different networks
│ communicate with one another?"
│
▼
1983
│
├── ARPANET adopts TCP/IP
│
▼
1980s
│
├── DNS
├── More networks
├── Email
│
▼
1990s
│
├── World Wide Web
├── Browsers
├── Commercial Internet
│
▼
2000s
│
├── Broadband
├── Web applications
├── AJAX
│
▼
2010s+
│
├── Smartphones
├── Cloud
├── IoT
├── Edge
```

---

# 15. One more term: RTT

You'll encounter this constantly in networking.

**RTT = Round-Trip Time.**

It's approximately:

> Time for a packet to travel from A → B and for a response/acknowledgement to return B → A.

```text
A                         B
│                         │
│────── request ─────────>│
│                         │
│<──── response ──────────│
│                         │

        ← RTT →
```

For example:

```text
ping google.com
```

might show:

```text
time=20 ms
```

That is approximately the round-trip latency.

This is why `ping` is such a useful networking tool.

---

# The mental model

When you study networking, keep these separate:

```text
LATENCY
How long does communication take?

BANDWIDTH
How much data can the link theoretically carry?

THROUGHPUT
How much data are we actually transferring?

PACKET
A unit of data sent through a packet-switched network.

PACKET LOSS
A packet never reaches its destination.

ERROR
Data arrives corrupted.

FLOW CONTROL
Don't overwhelm the receiver.

CONGESTION CONTROL
Don't overwhelm the network.

RTT
Time for a round trip.
```

And historically, these weren't arbitrary terms invented for textbooks.

**They are names for real engineering problems that appeared as soon as humans started making computers communicate.**

That is why understanding the history makes TCP/IP much easier: **TCP is essentially a sophisticated answer to several of these old problems.**


[[Networking]]