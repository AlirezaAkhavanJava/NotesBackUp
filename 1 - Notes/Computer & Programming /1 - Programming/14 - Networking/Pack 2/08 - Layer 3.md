
# Layer 3 — Network Layer

## 1. Why it exists

Imagine two computers connected to the same network:

```text
Computer A ─────── Switch ─────── Computer B
```

They can communicate directly because they are on the same local network.

But now:

```text
Computer A
    │
    ▼
Router 1
    │
    ▼
Router 2
    │
    ▼
Router 3
    │
    ▼
Computer B
```

The computers are no longer directly connected.

We need a system that answers:

> **"Where is the destination, and which path should this packet take to get there?"**

That is the primary job of **OSI Layer 3, the Network Layer**.

Without Layer 3:

- Networks could not be interconnected in the way the Internet requires.
    
- Routers would have no Layer-3 addressing system such as IP.
    
- A packet would not have a standardized destination address that routers can use.
    
- Communication would be limited to local networks or require completely different mechanisms.
    

The most important Layer-3 protocol today is **IP (Internet Protocol)**.

There are two major versions:

- **IPv4**
    
- **IPv6**
    

For now, we'll concentrate primarily on IPv4 because it makes the mechanics easier to see.

---

# 2. Mental model

### Everyday analogy: postal system

Think about sending a letter.

```text
You
 │
 │ Letter
 ▼
Local Post Office
 │
 ▼
Regional Post Office
 │
 ▼
Another Regional Post Office
 │
 ▼
Destination Post Office
 │
 ▼
Recipient
```

Your letter needs an **address**.

For example:

```text
123 Main Street
New York, NY
```

The postal system uses that address to determine where the letter needs to go.

IP does something conceptually similar:

```text
Computer A
10.0.0.10
   │
   ▼
Router
10.0.0.1
   │
   ▼
Router
192.168.1.1
   │
   ▼
Computer B
192.168.1.20
```

The IP address identifies the destination.

Routers examine the destination IP and decide:

> "Where should I send this packet next?"

### The basic Layer-3 model

```text
             Layer 3
        ┌────────────────┐
        │  IP Packet     │
        │                │
        │ Source IP      │
        │ Destination IP │
        │ Data           │
        └────────────────┘
                 │
                 ▼
             Router
                 │
        Routing decision
                 │
       ┌─────────┴─────────┐
       ▼                   ▼
   Interface A          Interface B
```

The important idea is:

> **Layer 3 provides logical addressing and routing between networks.**

### Where the analogy breaks

Postal addresses are designed for humans and physical locations.

IP addresses are designed for computers and networks.

Also, a router doesn't literally "read the entire address and find the best road" like a human postal worker. It performs a lookup in a **routing table** using defined algorithms and rules.

---

# 3. Core mechanics — beginner level

Let's build a concrete example.

Suppose your computer has:

```text
IP address:     192.168.1.10
Subnet mask:    255.255.255.0
Default gateway: 192.168.1.1
```

You want to communicate with:

```text
Server: 8.8.8.8
```

Your computer asks:

> Is `8.8.8.8` on my local network?

No.

Therefore:

> I need to send this packet to my router.

The router is:

```text
192.168.1.1
```

So the simplified journey is:

```text
Your PC
192.168.1.10
     │
     │ IP packet
     │ Destination: 8.8.8.8
     ▼
Router
192.168.1.1
     │
     ▼
ISP Router
     │
     ▼
Internet routers
     │
     ▼
8.8.8.8
```

Each router makes another routing decision.

### Important distinction

The destination IP generally stays:

```text
8.8.8.8
```

while the packet travels through the network.

But the **Layer-2 address** used to deliver the packet to the next device can change at every hop.

This is one of the most important distinctions between Layer 2 and Layer 3.

---

## What is a router?

A **router** is a device that forwards packets between different networks.

For example:

```text
Network A
192.168.1.0/24
       │
       │
    Router
       │
       │
Network B
10.0.0.0/24
```

The router connects these two networks.

Its routing table might contain something conceptually like:

```text
Destination       Next Hop
192.168.1.0/24    directly connected
10.0.0.0/24       192.168.1.2
0.0.0.0/0         ISP
```

When the router receives:

```text
Destination: 10.0.0.50
```

it searches its routing table and determines where to forward it.

---

# 4. How it works internally — intermediate level

Now we go underneath the simple model.

## IPv4 packet

Layer 3 doesn't simply contain:

```text
source IP
destination IP
data
```

An IPv4 packet has a structured header.

Simplified:

```text
┌──────────────────────────────────────────────┐
│              IPv4 Header                     │
├──────────────┬───────────────────────────────┤
│ Version      │ IHL                           │
├──────────────┼───────────────────────────────┤
│ DSCP/ECN     │ Total Length                  │
├──────────────┼───────────────────────────────┤
│ Identification / Flags / Fragment Offset     │
├──────────────┬───────────────────────────────┤
│ TTL          │ Protocol │ Header Checksum    │
├──────────────────────────────────────────────┤
│ Source IP Address                            │
├──────────────────────────────────────────────┤
│ Destination IP Address                       │
├──────────────────────────────────────────────┤
│ Options (optional)                           │
├──────────────────────────────────────────────┤
│ Payload                                      │
└──────────────────────────────────────────────┘
```

Some important fields:

### Version

For IPv4:

```text
4
```

This tells the receiver:

> This is an IPv4 packet.

### Source Address

For example:

```text
192.168.1.10
```

### Destination Address

For example:

```text
8.8.8.8
```

### TTL

**TTL = Time To Live.**

It limits how many routers a packet can pass through.

For example:

```text
TTL = 64
```

A router forwards the packet and decreases TTL:

```text
64 → 63 → 62 → 61 → ...
```

If it reaches:

```text
TTL = 0
```

the packet is discarded.

This prevents a routing loop from allowing packets to circulate forever.

For example:

```text
Router A
   ↓
Router B
   ↓
Router C
   ↓
Router A
   ↓
Router B
   ↓
...
```

TTL eventually kills the packet.

### Protocol

This tells IP what protocol is contained inside the IP payload.

For example:

```text
6  → TCP
17 → UDP
1  → ICMP
```

So you can conceptually have:

```text
Ethernet
   │
   ▼
IPv4
   │
   ├── TCP
   │     └── HTTP
   │
   └── UDP
         └── DNS
```

This is an extremely important concept because protocols are layered.

---

## IP doesn't guarantee delivery

This is one of the biggest things to understand.

IP is fundamentally a **best-effort, connectionless packet-delivery protocol**.

It does not itself guarantee:

- delivery
    
- ordering
    
- retransmission
    
- duplicate prevention
    
- reliable communication
    

For example:

```text
Computer A
    │
    │ Packet #1
    ▼
   Router
    X
    │
    └── packet lost
```

IP doesn't automatically say:

> "Oh no, packet #1 was lost. I'll resend it."

That's where higher-level protocols can help.

For example, TCP provides reliable byte-stream delivery above IP:

```text
Application
    │
   HTTP
    │
   TCP
    │
   IP
    │
Ethernet
```

UDP, on the other hand, doesn't provide TCP's reliability mechanisms.

---

## Where Layer 3 sits

The traditional OSI model:

```text
7  Application
6  Presentation
5  Session
4  Transport
3  Network       ← YOU ARE HERE
2  Data Link
1  Physical
```

A typical modern Internet stack looks more like:

```text
HTTP
 │
TCP / UDP
 │
IP
 │
Ethernet / Wi-Fi
 │
Physical transmission
```

The OSI model is primarily a **conceptual model**. The Internet does not literally implement seven independent OSI layers.

For Layer 3, the practical protocol you should think about first is:

```text
IP
```

---

# 5. Hands-on

Let's look at Layer 3 on your Debian machine.

## Find your IP addresses

Run:

```bash
ip addr
```

You'll see something similar to:

```text
2: enp3s0:
    inet 192.168.1.20/24
```

The important part is:

```text
192.168.1.20/24
```

This means your interface has an IPv4 address of:

```text
192.168.1.20
```

The `/24` describes the network prefix.

We'll study subnetting deeply later.

---

## Find your routing table

Run:

```bash
ip route
```

You might see:

```text
default via 192.168.1.1 dev enp3s0
192.168.1.0/24 dev enp3s0 proto kernel scope link src 192.168.1.20
```

Read it conceptually as:

```text
Destination             Where to send it

default                 → 192.168.1.1
192.168.1.0/24          → directly through enp3s0
```

The `default` route is particularly important.

It means:

> "For destinations I don't have a more specific route for, send the packet to this gateway."

---

## See the path to a destination

Run:

```bash
traceroute 8.8.8.8
```

If `traceroute` isn't installed:

```bash
sudo apt install traceroute
```

You may see something like:

```text
1  192.168.1.1
2  10.20.0.1
3  203.0.113.1
4  ...
...
```

This gives you a view of the Layer-3 hops between your computer and the destination.

Each hop is generally a router responding to the mechanism traceroute uses.

---

## `ping`

Try:

```bash
ping -c 4 8.8.8.8
```

Example:

```text
64 bytes from 8.8.8.8:
icmp_seq=1 ttl=117 time=25.4 ms
```

Here:

```text
icmp_seq=1
```

is the ICMP sequence number.

```text
ttl=117
```

is the received packet's TTL.

```text
time=25.4 ms
```

is the measured round-trip time.

`ping` uses **ICMP**, which operates alongside IP at the network layer.

---

# Java connection

Your Java program doesn't normally construct IP headers itself.

For example:

```java
var socket = new Socket("example.com", 443);
```

Conceptually:

```text
Java application
       │
       ▼
Socket API
       │
       ▼
TCP
       │
       ▼
IP
       │
       ▼
Ethernet / Wi-Fi
       │
       ▼
Network
```

Your Java program says:

> Connect me to `example.com` on TCP port `443`.

The operating system's networking stack handles the lower-level work.

This is an important boundary:

```text
Your Java code
      ↓
Operating System
      ↓
TCP/IP stack
      ↓
Network hardware
```

You don't normally write:

```java
setDestinationIp(...)
setTTL(...)
constructEthernetFrame(...)
```

The OS networking stack does that for ordinary applications.

---

# 6. Advanced level

## Routing

At the heart of Layer 3 is **routing**.

A router maintains a **routing table**.

Conceptually:

```text
Destination       Next hop
──────────────────────────────
10.0.0.0/8        Router A
172.16.0.0/12     Router B
192.168.1.0/24    Local
0.0.0.0/0         ISP
```

A router compares the destination IP against its routes.

An important rule is:

> **Longest prefix match wins.**

For example:

```text
10.0.0.0/8
10.20.0.0/16
10.20.30.0/24
```

For:

```text
10.20.30.50
```

the `/24` route is more specific than `/16` or `/8`, so it wins.

This is fundamental to Internet routing.

---

## Routing protocols

Routers don't necessarily receive all routes manually.

Large networks use **routing protocols**.

Important examples:

- **OSPF** — commonly used inside an organization.
    
- **BGP** — the major routing protocol connecting autonomous systems across the Internet.
    
- **IS-IS** — widely used in some large service-provider networks.
    

The Internet is essentially a gigantic collection of interconnected networks.

---

## NAT

Your home network may look like:

```text
Laptop       192.168.1.20
Phone        192.168.1.21
Desktop      192.168.1.22
                  │
                  ▼
              Router
                  │
                  ▼
            Public Internet
```

Those private addresses aren't normally globally routable on the public Internet.

Your router can perform **NAT — Network Address Translation**.

Conceptually:

```text
192.168.1.20:52341
       ↓
Public-IP:43120
       ↓
Internet
```

The router keeps track of the translation so replies can return to the correct machine.

NAT is extremely common in IPv4 networks.

---

## IPv6

IPv4 has a major limitation:

```text
32-bit addresses
```

IPv6 uses:

```text
128-bit addresses
```

For example:

```text
2001:db8:1234:5678::10
```

IPv6 was designed with vastly larger address space and other architectural changes.

You'll eventually want to understand:

```text
IPv4
  ↓
CIDR
  ↓
Subnetting
  ↓
NAT
  ↓
IPv6
```

---

## Security

Layer 3 is a major security boundary.

Examples include:

- IP filtering
    
- firewalls
    
- routing attacks
    
- IP spoofing
    
- ICMP abuse
    
- route hijacking
    
- DDoS
    
- packet filtering
    
- network segmentation
    

For example, an attacker can forge a source IP address in some circumstances:

```text
Fake source:
10.0.0.50

Destination:
Server
```

This is **IP spoofing**.

A network can use filtering rules to reject traffic that should not legitimately arrive from particular source networks.

---

## Modern Internet: QUIC and HTTP/3

Don't confuse Layer 3 with the entire Internet stack.

Modern traffic may look like:

```text
HTTP/3
   │
 QUIC
   │
 UDP
   │
 IP
   │
 Ethernet/Wi-Fi
```

QUIC operates above UDP while providing features traditionally associated with transport protocols.

So Layer 3 hasn't disappeared.

It's still underneath these newer protocols.

---

# 7. Edge cases and gotchas

### 1. IP address ≠ MAC address

IP:

```text
192.168.1.20
```

is Layer 3.

MAC:

```text
aa:bb:cc:dd:ee:ff
```

is associated with Layer 2.

They solve different problems.

---

### 2. Routers don't normally forward Ethernet frames unchanged

Suppose:

```text
PC → Router → Router → Server
```

At each Layer-3 hop, the Layer-2 frame is normally rebuilt for the next link.

Conceptually:

```text
PC
 │
 │ Frame A
 ▼
Router
 │
 │ Frame B
 ▼
Router
 │
 │ Frame C
 ▼
Server
```

But the IP destination can remain the final destination.

This is one of the most important Layer-2 vs Layer-3 relationships.

---

### 3. `ping` does not test "the Internet"

A failed ping doesn't necessarily mean:

> "The Internet is broken."

ICMP may be blocked by a firewall.

The destination might be alive while refusing ICMP.

---

### 4. TTL isn't exactly "time"

Despite its name, modern IPv4 TTL effectively behaves as a **hop limit**.

Each router normally decrements it by one.

IPv6 calls the equivalent field:

```text
Hop Limit
```

which is a more accurate name.

---

### 5. IP doesn't mean "Internet"

IP is a protocol for internetworking.

You can have IP communication entirely inside a private network:

```text
10.0.0.10
   ↕
10.0.0.20
```

The Internet is a massive network of interconnected IP networks, but IP itself isn't synonymous with the public Internet.

---

# 8. Connections

You now have the basic map:

```text
                 Application
                     │
              HTTP / DNS / SSH
                     │
                     ▼
                Transport
                     │
                 TCP / UDP
                     │
                     ▼
                 Network
                     │
                    IP
                     │
                     ▼
                Data Link
                     │
              Ethernet / Wi-Fi
                     │
                     ▼
                 Physical
```

Layer 3 connects several concepts you'll need next:

```text
Layer 2
   │
   ├── MAC addresses
   ├── Ethernet
   └── ARP
        │
        ▼
Layer 3
   │
   ├── IP addresses
   ├── subnetting
   ├── routing
   ├── routers
   └── ICMP
        │
        ▼
Layer 4
   │
   ├── TCP
   ├── UDP
   └── ports
        │
        ▼
Layer 7
   │
   ├── HTTP
   ├── DNS
   └── SSH
```

### Recommended next concepts

Since you're learning from zero, I recommend:

**Layer 3 → IPv4 addressing → subnet masks/CIDR → subnetting → default gateway → routing tables → ARP → ICMP → TCP (Layer 4).**

The most natural immediate next step is **IPv4 addressing and subnet masks**, because you cannot properly understand routing until you understand what an IP address actually represents.






[[Networking]]