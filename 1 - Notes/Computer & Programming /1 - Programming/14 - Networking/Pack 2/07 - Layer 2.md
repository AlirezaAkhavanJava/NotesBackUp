
## Layer 2 — Data Link Layer

The **Data Link Layer (Layer 2)** is the second layer of the OSI model. It is responsible for **reliable communication between devices that are directly connected on the same local network link**.

A precise definition:

> **The Data Link Layer provides node-to-node delivery of data by organizing bits into frames and controlling how devices access and use the physical network medium.**

### What Layer 2 does

Layer 2 sits between:

```text
Layer 3 — Network
        ↓
Layer 2 — Data Link
        ↓
Layer 1 — Physical
```

It takes a **Layer 3 packet** and encapsulates it into a **frame**:

```text
Application data
       ↓
   Layer 4
     Segment
       ↓
   Layer 3
     Packet
       ↓
   Layer 2
     Frame
       ↓
   Layer 1
      Bits
```

The key concepts of Layer 2 are:

**1. Frames**

Layer 2's primary data unit is the **frame**.

A simplified Ethernet frame looks like:

```text
┌──────────────┬──────────────┬──────────┬────────┬───────┐
│ Destination  │ Source MAC   │  Type    │ Payload│ FCS   │
│    MAC       │   Address    │          │        │       │
└──────────────┴──────────────┴──────────┴────────┴───────┘
```

**2. MAC addresses**

Layer 2 commonly uses **MAC addresses** to identify network interfaces on the local network.

Example:

```text
PC A:  3C:52:82:AA:10:01
Router:3C:52:82:BB:20:05
```

This is different from an IP address.

```text
MAC address → Layer 2
IP address  → Layer 3
```

**3. Local delivery**

Layer 2 is concerned primarily with:

> "How do I deliver this frame to another device on this directly connected network?"

For example:

```text
PC A ─── Ethernet Switch ─── PC B
```

The Ethernet frames traveling between A and B are Layer 2.

### Devices associated with Layer 2

The classic Layer 2 device is a **network switch**.

A switch examines the **destination MAC address** and decides which physical port should receive the frame.

```text
          ┌── PC A
          │
PC B ── Switch ── PC C
          │
          └── PC D
```

The switch builds a **MAC address table**, essentially learning:

```text
MAC address         Port
-------------------------
AA:AA:AA:AA:AA:AA    1
BB:BB:BB:BB:BB:BB    2
CC:CC:CC:CC:CC:CC    3
```

### Important distinction

Layer 2 does **not** decide where traffic should go across the entire Internet.

That's primarily **Layer 3**.

For example:

```text
Your PC
  │
  │ Layer 2
  ▼
Home Router
  │
  │ Layer 3
  ▼
Internet
  │
  ▼
Web Server
```

Layer 2 handles the **local hop**.

Layer 3 handles **routing between different networks**.

### In programming terms

This is an important point given your previous question about whether OSI is a program:

**OSI Layer 2 is not a program.**

It is a **conceptual model** describing responsibilities that are implemented by many different pieces of software and hardware.

For example, on your Debian machine:

```text
Your Spring Boot application
        ↓
TCP
        ↓
IP
        ↓
Ethernet / Wi-Fi
        ↓
Network interface hardware
```

Your Java application doesn't implement "Layer 2" directly. The operating system, network drivers, NIC hardware, switches, and networking protocols collectively implement the behavior associated with Layer 2.

A good mental model is:

```text
Layer 7   What does the application want?
Layer 4   How should the data be transported?
Layer 3   Which network should it go through?
Layer 2   Which local device/interface gets this frame?
Layer 1   How are the bits physically transmitted?
```

**Layer 2 = frames + MAC addresses + local network delivery.**

---
**DLC = Data Link Control.**

It refers to the set of mechanisms/procedures used at **OSI Layer 2** to manage communication over a data link.

Typical DLC responsibilities include:

- **Framing** — organizing raw bits into frames.
    
- **Error detection/control** — detecting transmission errors and, depending on the protocol, handling retransmission.
    
- **Flow control** — preventing a fast sender from overwhelming a receiver.
    
- **Access control** — determining how devices share a common medium.
    

A useful distinction:

```text
Data Link Layer
├── LLC — Logical Link Control
└── MAC — Media Access Control
```

**DLC** is therefore more of a **general term for data-link control functions**, while **LLC** and **MAC** are standardized sublayers of IEEE's Layer 2 architecture.

For Ethernet specifically, **MAC is the part you'll encounter most directly**.


[[Networking]]