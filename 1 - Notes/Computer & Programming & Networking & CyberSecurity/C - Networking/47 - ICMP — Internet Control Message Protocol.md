
---
**ICMP (Internet Control Message Protocol)** is a **network-layer protocol used by hosts and routers to send control, diagnostic, and error information about IP communication**.

> ICMP does not normally carry application data. It communicates information about the **IP network itself**.

ICMP is associated with **Layer 3 — Network Layer**.

---

## 1. Where ICMP fits

```text
┌─────────────────────────────┐
│ Application                 │
│ HTTP, SSH, DNS, ...         │
├─────────────────────────────┤
│ Transport                   │
│ TCP / UDP                   │
├─────────────────────────────┤
│ Network                     │
│ IP + ICMP                   │
├─────────────────────────────┤
│ Data Link                   │
│ Ethernet / Wi-Fi            │
├─────────────────────────────┤
│ Physical                    │
│ Electrical / Light / Radio  │
└─────────────────────────────┘
```

ICMP is carried **inside IP packets**.

For IPv4:

```text
Ethernet
   ↓
IP
   ↓
ICMP
```

For IPv6:

```text
Ethernet
   ↓
IPv6
   ↓
ICMPv6
```

---

# 2. Why do we need ICMP?

IP is mainly concerned with **addressing and forwarding packets**.

But networks also need a way to communicate conditions such as:

```text
"The destination cannot be reached."

"The packet's lifetime expired."

"Here is diagnostic information."

"Your packet needs different handling."
```

ICMP provides that mechanism.

Think of it as a **control/feedback channel for IP networking**.

---

# 3. ICMP is not TCP or UDP

This distinction is important:

```text
TCP → Transport protocol
UDP → Transport protocol
ICMP → Network/control protocol
```

ICMP does **not** use TCP or UDP.

Instead:

```text
IP
 └── ICMP
```

For IPv4, the IP header identifies ICMP using:

```text
Protocol = 1
```

For IPv6, ICMPv6 uses a different IP next-header value.

---

# 4. ICMP message structure

A simplified ICMP message looks like:

```text
┌──────────────────────────┐
│ Type                     │
├──────────────────────────┤
│ Code                     │
├──────────────────────────┤
│ Checksum                 │
├──────────────────────────┤
│ Message-specific data    │
└──────────────────────────┘
```

The most important fields initially are:

### Type

Defines the general kind of ICMP message.

### Code

Provides more specific information about the type.

For example:

```text
Type = Destination Unreachable
Code = Port Unreachable
```

Together they give a more precise meaning.

---

# 5. ICMP Destination Unreachable

Suppose your machine sends a packet toward a destination that cannot be reached.

A router or host may send an ICMP message back:

```text
Your PC                       Router
  │                              │
  │──── IP packet ──────────────→│
  │                              │
  │              cannot forward │
  │                              │
  │←── ICMP Destination          │
  │    Unreachable               │
```

The ICMP message can indicate different reasons, such as:

```text
Network unreachable
Host unreachable
Port unreachable
```

The exact available codes depend on the ICMP version/type.

---

# 6. `ping` uses ICMP

This is probably the most famous use of ICMP.

When you run:

```bash
ping 192.168.1.1
```

your system normally sends an **ICMP Echo Request**.

```text
PC                              Router
 │                                  │
 │──── ICMP Echo Request ──────────→│
 │                                  │
 │←─── ICMP Echo Reply ─────────────│
 │                                  │
```

If you receive the reply, your machine has evidence that the destination was able to receive and respond to the ICMP request.

Example:

```text
64 bytes from 192.168.1.1:
icmp_seq=1 ttl=64 time=0.812 ms
```

The `time` value is approximately the round-trip time.

---

# 7. Echo Request and Echo Reply

Two important ICMP message types for IPv4 are:

```text
Type 8  → Echo Request
Type 0  → Echo Reply
```

So:

```text
ping
  ↓
ICMP Echo Request
  ↓
Destination
  ↓
ICMP Echo Reply
```

`ping` is therefore **not testing TCP or UDP connectivity**.

It is testing ICMP echo communication.

---

# 8. ICMP and `traceroute`

ICMP also plays an important role in network path diagnostics.

A simplified path:

```text
PC
 │
 ▼
Router A
 │
 ▼
Router B
 │
 ▼
Router C
 │
 ▼
Server
```

`traceroute` can exploit the **TTL (Time To Live)** field in IPv4.

Suppose the packet is sent with:

```text
TTL = 1
```

The first router decrements it:

```text
1 → 0
```

The router discards the packet and can send back:

```text
ICMP Time Exceeded
```

Then the sender learns:

```text
Hop 1 = Router A
```

Next:

```text
TTL = 2
```

Router A:

```text
2 → 1
```

Router B:

```text
1 → 0
```

Router B sends an ICMP Time Exceeded message.

Now:

```text
Hop 1 = Router A
Hop 2 = Router B
```

And so on.

Conceptually:

```text
TTL 1
PC ─────→ Router A
          │
          └── ICMP Time Exceeded ──→ PC

TTL 2
PC ─────→ Router A ─────→ Router B
                         │
                         └── ICMP Time Exceeded ──→ PC
```

This is one of the most useful demonstrations of ICMP in practice.

---

# 9. ICMP does not guarantee delivery

Another important point:

> **ICMP itself is not a reliable transport mechanism.**

There is no TCP-style:

```text
ACK
Retransmission
Ordered byte stream
Connection establishment
```

ICMP messages can themselves be lost.

So:

```text
ICMP
 ≠ reliable transport protocol
```

It is primarily a control and diagnostic mechanism.

---

# 10. ICMP is carried inside IP

This is worth visualizing carefully.

Suppose you run:

```bash
ping 8.8.8.8
```

The structure is approximately:

```text
┌──────────────────────────────┐
│ Ethernet Frame               │
│                              │
│  ┌────────────────────────┐  │
│  │ IPv4 Packet            │  │
│  │                        │  │
│  │  ┌──────────────────┐  │  │
│  │  │ ICMP Message     │  │  │
│  │  └──────────────────┘  │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

So the encapsulation is:

```text
Ethernet
   ↓
IP
   ↓
ICMP
```

Compare that with a normal web request:

```text
Ethernet
   ↓
IP
   ↓
TCP
   ↓
TLS
   ↓
HTTP
```

---

# 11. ICMP Error Messages

Some ICMP messages report errors related to IP traffic.

For example:

```text
Sender
  │
  │ IP packet
  ▼
Router
  │
  │ cannot deliver
  ▼
ICMP error
  │
  ▼
Sender
```

Common concepts include:

### Destination Unreachable

The destination or service cannot be reached.

### Time Exceeded

The packet's TTL/hop limit expired.

This is used by traceroute.

### Parameter Problem

The IP packet contains an invalid or problematic field.

---

# 12. ICMP and UDP

ICMP can also report problems related to UDP traffic.

For example:

```text
Client
192.168.1.10:50000
      │
      │ UDP → port 9999
      ▼
Server
```

If nothing is listening on UDP port `9999`, the destination may respond with:

```text
ICMP Destination Unreachable
    Code: Port Unreachable
```

Conceptually:

```text
UDP packet
    │
    ▼
No application listening
    │
    ▼
ICMP Port Unreachable
    │
    ▼
Client
```

So ICMP can provide feedback about problems encountered by other IP-based traffic.

---

# 13. ICMP vs ARP

These two are easy to confuse because both are involved in networking diagnostics.

### ARP

```text
IPv4 address
     ↓
    ARP
     ↓
MAC address
```

Used to resolve an IPv4 address to a local-link MAC address.

### ICMP

```text
IP network
     ↓
   ICMP
     ↓
Control / diagnostic / error information
```

For example:

```text
ARP → "Who has 192.168.1.20?"

ICMP → "Destination unreachable."

ICMP → "Echo reply."

ICMP → "TTL expired."
```

---

# 14. ICMP vs TCP vs UDP

|Property|TCP|UDP|ICMP|
|---|---|---|---|
|Layer|4|4|3|
|Main purpose|Reliable transport|Datagram transport|IP control/diagnostics|
|Uses ports|Yes|Yes|No|
|Connection|Yes|No|No TCP-style connection|
|Application data transport|Yes|Yes|Generally no|
|Reliability|Yes|No|No|
|Example|HTTP, SSH|DNS, QUIC|ping, traceroute|

---

# 15. ICMP and security

ICMP is useful, but firewalls can restrict it.

For example, a network might allow:

```text
TCP 443 → allowed
TCP 22  → blocked
ICMP     → filtered
```

Therefore:

```bash
ping example.com
```

failing does **not automatically mean**:

> "The server is down."

The host may simply:

- block ICMP,
    
- filter it with a firewall,
    
- rate-limit it,
    
- or not respond to that particular ICMP message.
    

This is an important networking troubleshooting principle.

---

# 16. ICMPv4 vs ICMPv6

For IPv4:

```text
IPv4
 ↓
ICMP
```

For IPv6:

```text
IPv6
 ↓
ICMPv6
```

ICMPv6 is particularly important to IPv6 networking because it supports functionality related to **Neighbor Discovery**, router discovery, address configuration, and other IPv6 control mechanisms.

---

# 17. Linux examples

### Ping

```bash
ping 192.168.1.1
```

### IPv6 ping

```bash
ping -6 2001:db8::1
```

### Traceroute

Depending on your setup:

```bash
traceroute example.com
```

or:

```bash
tracepath example.com
```

You can also inspect traffic directly with tools such as:

```bash
sudo tcpdump -i enp3s0 icmp
```

Then run:

```bash
ping 192.168.1.1
```

You can observe the ICMP Echo Request and Echo Reply packets on the interface.

---

# 18. TCP/UDP/ICMP in one picture

This is the networking model worth keeping:

```text
                 APPLICATION
                     │
          ┌──────────┴──────────┐
          │                     │
         HTTP                  DNS
          │                     │
          ▼                     ▼
         TCP                   UDP
          │                     │
          └──────────┬──────────┘
                     │
                     ▼
                    IP
                     │
             ┌───────┴────────┐
             │                │
            ARP              ICMP
             │                │
             ▼                ▼
          MAC/local       IP control/
          resolution      diagnostics
             │
             ▼
        Ethernet/Wi-Fi
```

More precisely, ARP and ICMP serve different purposes:

```text
ARP:
IPv4 → MAC on local link

ICMP:
IP control/error/diagnostic messaging

TCP:
Reliable byte-stream transport

UDP:
Connectionless datagram transport
```

## Core definition

> **ICMP is a Layer-3 protocol that allows IP hosts and routers to exchange control, error, and diagnostic information, with common examples including `ping` (Echo Request/Reply) and `traceroute` (Time Exceeded messages).**

[[Networking]]