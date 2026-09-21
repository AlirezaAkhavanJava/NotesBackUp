
---

**ARP (Address Resolution Protocol)** is a network protocol used on **IPv4 local networks** to discover the **MAC address associated with a known IPv4 address**.

> **ARP answers:** “I know the IP address; which device on this local network has it, and what is its MAC address?”

---

## 1. Why ARP exists

Suppose your computer wants to send data to:

```text
IP: 192.168.1.20
```

IP works at the **Network layer (Layer 3)**, but Ethernet needs a **MAC address** to actually deliver the frame on the local network.

The computer therefore needs to discover:

```text
192.168.1.20 → AA:BB:CC:DD:EE:FF
```

ARP performs this mapping.

```text
IPv4 Address
     ↓
    ARP
     ↓
MAC Address
```

---

## 2. ARP operates on the local network

ARP is used to resolve an IPv4 address to a MAC address on the **same local Layer-2 network**.

For example:

```text
PC A
IP: 192.168.1.10

        Local Ethernet/LAN

PC B
IP: 192.168.1.20
MAC: AA:BB:CC:DD:EE:FF
```

PC A needs to know PC B's MAC.

It broadcasts an ARP request:

```text
"Who has 192.168.1.20?"
```

PC B responds:

```text
"192.168.1.20 is at AA:BB:CC:DD:EE:FF"
```

---

# 3. ARP Request

The request is normally sent as a **broadcast**.

Conceptually:

```text
PC A
192.168.1.10
    │
    │ ARP Request
    │ "Who has 192.168.1.20?"
    │
    ▼
Broadcast
    │
 ┌──┴───────────────┐
 ▼                  ▼
PC B               PC C
192.168.1.20       192.168.1.30
```

Every device on that Layer-2 broadcast domain can receive the request.

Only the device owning:

```text
192.168.1.20
```

should respond.

---

# 4. ARP Reply

PC B sends a reply back to PC A:

```text
192.168.1.20
       ↓
AA:BB:CC:DD:EE:FF
```

The sender can now construct an Ethernet frame:

```text
Destination MAC:
AA:BB:CC:DD:EE:FF
```

while the IP packet still has:

```text
Destination IP:
192.168.1.20
```

So you can think of the process as:

```text
IP packet
   │
   │ Need destination MAC
   ▼
   ARP
   │
   ▼
Ethernet frame
```

---

# 5. ARP Cache

A computer normally does **not** send an ARP request for every packet.

It keeps recently learned mappings in an **ARP cache**.

For example:

```text
192.168.1.1     → 00:11:22:33:44:55
192.168.1.20    → AA:BB:CC:DD:EE:FF
192.168.1.50    → 10:20:30:40:50:60
```

On Linux, you can inspect it with:

```bash
ip neigh
```

Example:

```text
192.168.1.1 dev enp3s0 lladdr 00:11:22:33:44:55 REACHABLE
192.168.1.20 dev enp3s0 lladdr aa:bb:cc:dd:ee:ff STALE
```

This is the modern Linux way to inspect the neighbor table.

You may also encounter:

```bash
arp -n
```

but `ip neigh` is preferred on modern Linux systems.

---

# 6. ARP and your router

Here's an important case.

Suppose your computer is:

```text
IP: 192.168.1.10
```

and you want to access:

```text
8.8.8.8
```

Your computer does **not** ARP for:

```text
8.8.8.8
```

because `8.8.8.8` is not on your local network.

Instead, it determines that the destination is remote and sends the frame to its **default gateway**.

For example:

```text
PC
192.168.1.10
    │
    │ Ethernet frame
    │ Destination MAC = router's MAC
    ▼
Router
192.168.1.1
    │
    ▼
Internet
    │
    ▼
8.8.8.8
```

ARP is therefore used to discover:

```text
192.168.1.1 → Router's MAC
```

not:

```text
8.8.8.8 → MAC
```

This distinction is fundamental.

---

# 7. ARP works between Layer 3 and Layer 2

A simplified stack:

```text
Application
     ↓
Transport
     ↓
IP              ← IPv4 address
     ↓
ARP             ← Resolve IPv4 → MAC
     ↓
Ethernet        ← MAC address
     ↓
Physical Network
```

ARP essentially helps connect **Layer 3 addressing** with **Layer 2 addressing**.

---

# 8. Example packet flow

Your computer:

```text
IP: 192.168.1.10
MAC: 11:11:11:11:11:11
```

Server on the same LAN:

```text
IP: 192.168.1.20
MAC: 22:22:22:22:22:22
```

Your application sends data.

### Step 1 — IP decides destination

```text
Source IP:      192.168.1.10
Destination IP: 192.168.1.20
```

### Step 2 — ARP discovers MAC

```text
192.168.1.20
      ↓
22:22:22:22:22:22
```

### Step 3 — Ethernet frame is built

```text
Source MAC:      11:11:11:11:11:11
Destination MAC: 22:22:22:22:22:22
```

Inside that frame is the IP packet:

```text
Ethernet Frame
└── IP Packet
    └── TCP/UDP Segment
        └── Application Data
```

---

# 9. ARP does not translate every IP address

A common misconception is:

> "ARP converts an IP address into a MAC address."

More precisely:

> **ARP resolves an IPv4 address to a MAC address within the local Layer-2 network.**

It doesn't globally map IP addresses to MAC addresses.

MAC addresses are fundamentally **local-link identifiers**.

Routers replace the Layer-2 frame as traffic moves between networks.

---

# 10. ARP packet

An ARP message contains information such as:

```text
Sender MAC address
Sender IPv4 address

Target MAC address
Target IPv4 address
```

A request might conceptually contain:

```text
Sender:
192.168.1.10
11:11:11:11:11:11

Target:
192.168.1.20
?????????????????
```

The reply fills in the missing MAC:

```text
192.168.1.20
22:22:22:22:22:22
```

---

# 11. ARP spoofing

Because ARP was designed without strong authentication, an attacker on the same LAN can send forged ARP information.

For example, the attacker may claim:

```text
192.168.1.1
     ↓
Attacker's MAC
```

instead of the real router MAC.

This can enable **ARP spoofing / ARP poisoning**, potentially allowing **man-in-the-middle attacks**.

This is one reason ARP is an important networking concept from a security perspective.

---

# 12. ARP vs DNS

Don't confuse these:

```text
DNS:
example.com
    ↓
IP address
```

```text
ARP:
192.168.1.20
    ↓
MAC address
```

So:

```text
Domain name → IP       = DNS
IPv4 → MAC             = ARP
```

---

# 13. One important modern distinction

**ARP is for IPv4.**

IPv6 does not use ARP. IPv6 uses **Neighbor Discovery Protocol (NDP)**, which operates using ICMPv6.

So:

```text
IPv4 → ARP
IPv6 → NDP
```

---

# Mental Model

Keep this chain in your head:

```text
        "Where is example.com?"
                 │
                DNS
                 ↓
           93.184.216.34
                 │
                 │ Is it local?
                 ↓
               Routing
                 │
        Local destination?
          /              \
        Yes               No
         │                 │
        ARP          ARP for gateway
         │                 │
         ↓                 ↓
   Destination MAC     Gateway MAC
         │                 │
         └────────┬────────┘
                  ↓
             Ethernet
                  ↓
               Network
```

The key relationship is:

> **IP tells the network where the packet should ultimately go; ARP helps the local network determine which MAC address should receive the next Ethernet frame.**


[[Networking]]