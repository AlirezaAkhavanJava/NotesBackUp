
## Bandwidth

**Bandwidth** is the **maximum amount of data that can be transmitted through a network connection per unit of time**.

It is usually measured in:

- **bits per second (bit/s)**
    
- **Kbit/s**
    
- **Mbit/s**
    
- **Gbit/s**
    

### Example

Suppose your Internet connection has:

```text
Bandwidth = 100 Mbit/s
```

This means the connection can theoretically carry up to:

```text
100,000,000 bits/second
```

Since:

```text
8 bits = 1 byte
```

that's approximately:

```text
100 Mbit/s ÷ 8 = 12.5 MB/s
```

So **100 Mbit/s ≈ 12.5 MB/s** maximum theoretical data rate.

### Bandwidth vs Speed

People often use "Internet speed" to mean bandwidth, but technically:

|Concept|Meaning|
|---|---|
|**Bandwidth**|Maximum data-transfer capacity|
|**Throughput**|Actual data transferred|
|**Latency**|How long data takes to travel|
|**Jitter**|Variation in latency|
|**Packet loss**|Data packets that fail to reach their destination|

For example:

```text
Connection:
Bandwidth = 100 Mbit/s
Latency   = 20 ms
```

You can have **high bandwidth but high latency**. These are different properties.

### Simple analogy

Think of a network connection as a highway:

```text
Bandwidth
    ↓
Number of lanes

Throughput
    ↓
Actual cars traveling

Latency
    ↓
Time required to reach the destination
```

A **10-lane highway** has more capacity than a 1-lane highway, but that doesn't necessarily mean every car reaches the destination faster.

### In networking

For a server:

```text
Client
   │
   │  data
   ▼
[ Network ]
   │
   ▼
Server
```

Bandwidth determines **how much data the network link can carry**, while latency determines **how quickly packets can make the trip**.

**Key definition:**

> **Bandwidth = the maximum data-carrying capacity of a communication channel, measured in bits per second.**

---
The important thing is to stop thinking of bandwidth as a property of **the Internet as a whole**. It is a property of a **particular link/path/interface**, and the end-to-end transfer is limited by the weakest relevant part.

## 1. What determines bandwidth?

Bandwidth depends on several physical and technological factors:

|Factor|Effect|
|---|---|
|**Transmission medium**|Fiber generally supports much more capacity than copper|
|**Cable quality/category**|Better Ethernet cabling can support higher rates|
|**Signal frequency**|More usable spectrum can carry more information|
|**Network technology**|100 Mbps Ethernet, 1 Gbps Ethernet, 10 Gbps Ethernet, etc.|
|**Hardware**|NICs, routers, switches, modems, optical transceivers|
|**ISP/service plan**|Your ISP may limit your connection|
|**Distance**|Some technologies lose capacity/reliability over distance|
|**Network configuration**|Duplex, link negotiation, congestion control, etc.|
|**Shared capacity**|Many users/devices may share the same upstream resources|

At the physical level, you're essentially trying to transmit information by changing a signal:

```text
Computer
   │
   │ electrical / optical / radio signal
   ▼
Network medium
   │
   ▼
Other device
```

The characteristics of that signal and medium determine how much information can be encoded and transmitted.

---

# 2. Why can one connection have 100 Mbps and another 1 Gbps?

Imagine two Ethernet links:

```text
Link A
──────────────
100 Mbps


Link B
════════════════════════════════
1 Gbps
```

`1 Gbps` is:

```text
1,000 Mbps
```

So Link B has **10× the nominal bandwidth**.

This can happen because the links use different technologies, hardware, signaling, frequencies, numbers of channels/lanes, etc.

For example:

```text
Old Ethernet hardware
       ↓
100 Mbps

Gigabit Ethernet hardware
       ↓
1 Gbps

10 Gigabit Ethernet hardware
       ↓
10 Gbps
```

Bandwidth is therefore not some universal constant. It's an engineered property of the communication system.

---

# 3. The REALLY important concept: bottleneck

Suppose you have:

```text
PC
 │
 │ 1 Gbps
 ▼
Router
 │
 │ 100 Mbps
 ▼
ISP
 │
 │ 1 Gbps
 ▼
Internet
```

Your PC has a **1 Gbps** Ethernet connection.

Your router may also have a 1 Gbps LAN interface.

But the ISP connection is only:

```text
100 Mbps
```

Therefore, your Internet transfer cannot magically become 1 Gbps.

The path is effectively:

```text
1 Gbps → 100 Mbps → 1 Gbps
             ↑
          bottleneck
```

The **100 Mbps link is the bottleneck**.

A useful simplified model is:

```text
End-to-end capacity ≈ minimum capacity of the relevant path
```

So:

```text
1 Gbps
   ↓
500 Mbps
   ↓
100 Mbps   ← bottleneck
   ↓
1 Gbps

≈ 100 Mbps maximum
```

Real throughput will usually be somewhat lower due to protocol overhead and other factors.

---

# 4. Bigger bandwidth but still slow?

Absolutely.

This is one of the most important networking concepts.

Suppose you download something:

```text
Server
  │
  │ 10 Gbps
  ▼
Internet backbone
  │
  │ 10 Gbps
  ▼
ISP
  │
  │ 1 Gbps
  ▼
Router
  │
  │ 1 Gbps
  ▼
Your PC
```

Everything looks excellent.

But suppose the **server itself** can only send:

```text
50 Mbps
```

Then:

```text
Server:       50 Mbps
Internet:  10,000 Mbps
ISP:        1,000 Mbps
LAN:        1,000 Mbps
```

The bottleneck is:

```text
50 Mbps
```

So you might have a **1 Gbps Internet connection** but download from that particular server at only **50 Mbps**.

---

# 5. Bottlenecks can exist at many layers

Consider:

```text
Your PC
   │
   │ 1 Gbps
   ▼
Router
   │
   │ 1 Gbps
   ▼
ISP
   │
   │ 500 Mbps
   ▼
ISP backbone
   │
   │ 10 Gbps
   ▼
Destination ISP
   │
   │ 1 Gbps
   ▼
Server
   │
   │ application can only produce 100 Mbps
   ▼
Application
```

Here, the network might have enormous capacity, but the application is only producing data at:

```text
100 Mbps
```

So you get roughly that rate.

This is why **bandwidth ≠ actual transfer speed**.

---

# 6. Common bottleneck examples

### Example A — Ethernet bottleneck

Your computer:

```text
NIC = 1 Gbps
```

But you're connected through an old switch:

```text
Switch port = 100 Mbps
```

Result:

```text
PC ──1Gbps──> Switch ──100Mbps──> Router
                         ↑
                      bottleneck
```

---

### Example B — Wi-Fi bottleneck

Your Internet:

```text
1 Gbps
```

But your Wi-Fi connection is currently capable of only:

```text
150 Mbps
```

Then:

```text
Internet ──1Gbps──> Router ──150Mbps──> Laptop
                                  ↑
                               bottleneck
```

Your ISP isn't necessarily the problem.

---

### Example C — Server bottleneck

You have:

```text
1 Gbps Internet
```

but a server sends you data at:

```text
20 Mbps
```

Then:

```text
Your connection: 1,000 Mbps
Server:             20 Mbps
                     ↑
                 bottleneck
```

Increasing your Internet plan won't necessarily fix it.

---

### Example D — Multiple users

Suppose your router has a:

```text
1 Gbps
```

Internet connection.

Five machines are downloading simultaneously:

```text
             ┌── PC 1
             │
ISP ──1Gbps──┼── PC 2
             │
             ├── PC 3
             │
             ├── PC 4
             │
             └── PC 5
```

They share the available capacity.

If the traffic is evenly distributed, you might roughly see:

```text
1,000 / 5 = 200 Mbps each
```

But actual allocation depends on the traffic, protocols, QoS, congestion, and what the users are doing.

---

# 7. Bandwidth vs throughput

This distinction is extremely important.

### Bandwidth

The **capacity**:

```text
1 Gbps
```

### Throughput

What you're **actually achieving**:

```text
730 Mbps
```

For example:

```text
Link capacity
┌────────────────────────────────────────────┐
│                 1 Gbps                     │
└────────────────────────────────────────────┘
                    ↓
              actual traffic
┌───────────────────────────────┐
│          730 Mbps             │
└───────────────────────────────┘
```

Why isn't it exactly 1 Gbps?

Because networking has overhead and other limitations:

```text
Ethernet headers
IP headers
TCP headers
TCP behavior
packet loss
congestion
server limitations
router processing
etc.
```

---

# 8. A more accurate mental model

When data travels from A → B:

```text
A
│
│ 1 Gbps
▼
Router
│
│ 1 Gbps
▼
ISP
│
│ 500 Mbps
▼
Backbone
│
│ 10 Gbps
▼
Destination ISP
│
│ 1 Gbps
▼
Server
```

The important question isn't:

> "What's my bandwidth?"

Instead ask:

> **"What is the bandwidth of every relevant link between the sender and receiver, and which one is currently the bottleneck?"**

Conceptually:

```text
          ┌───────────────┐
          │     1 Gbps    │
          └───────────────┘
                  ↓
          ┌───────────────┐
          │     1 Gbps    │
          └───────────────┘
                  ↓
          ┌───────────────┐
          │    500 Mbps   │ ← bottleneck
          └───────────────┘
                  ↓
          ┌───────────────┐
          │    10 Gbps    │
          └───────────────┘
                  ↓
          ┌───────────────┐
          │     1 Gbps    │
          └───────────────┘
```

So the **500 Mbps link** limits that path.

---

## One more important distinction

There are actually **two different things** people often call a bottleneck:

**Capacity bottleneck:**

```text
100 Mbps link
```

The physical/logical link simply cannot carry more.

**Congestion bottleneck:**

```text
1 Gbps link
     ↓
currently 900 Mbps of traffic
     ↓
queue builds up
     ↓
packets wait/drop
```

The link is capable of 1 Gbps, but too much traffic is competing for it.

That leads directly into **packets, TCP, congestion control, queues, latency, and why bandwidth and latency are independent**—which is the next important layer of networking to understand.


[[Networking]]