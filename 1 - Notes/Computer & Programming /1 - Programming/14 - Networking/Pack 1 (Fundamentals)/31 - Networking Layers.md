



A **network layer** is a conceptual division of networking responsibilities.

Instead of treating networking as one huge process, we divide it into layers, where each layer handles a specific type of work.

For example, sending:

```text
"Hello"
```

from one computer to another involves many different problems:

```text
How is the data represented?
How do we identify the destination?
How do we route it?
How do we ensure delivery?
How do we physically transmit the bits?
```

Layers separate these responsibilities.

---

# 2. Why do we use layers?

Without layers, networking would be one enormous system where every component would need to understand everything else.

Instead:

```text
Application
     ↓
Transport
     ↓
Network
     ↓
Data Link
     ↓
Physical
```

Each layer:

1. **Provides services to the layer above it**
    
2. **Uses services from the layer below it**
    
3. **Has its own protocols and responsibilities**
    

This gives us **modularity**.

For example, HTTP doesn't need to know how an Ethernet cable electrically represents `0` and `1`.

---

# 3. The OSI Model

The **OSI (Open Systems Interconnection) model** is a conceptual model that divides networking into **7 layers**.

From highest to lowest:

```text
7. Application
8. Presentation
9. Session
10. Transport
11. Network
12. Data Link
13. Physical
```

Now let's define each.

---

# 4. Layer 7 — Application

**Definition:**  
The **Application layer** provides network functionality directly to applications and defines how applications communicate over a network.

Examples:

```text
HTTP
DNS
SMTP
SSH
FTP
```

For example, when your browser requests:

```text
GET /index.html
```

HTTP operates at the Application layer.

**Question it answers:**

> "What are the applications saying to each other?"

---

# 5. Layer 6 — Presentation

**Definition:**  
The **Presentation layer** is responsible for the **representation and transformation of data** so that communicating systems can understand it.

Typical responsibilities include:

- Data encoding
    
- Data serialization
    
- Encryption/decryption
    
- Compression/decompression
    
- Character representation
    

Examples:

```text
UTF-8
JSON
XML
JPEG
TLS-related data transformations
```

**Question it answers:**

> "How should this data be represented?"

---

# 6. Layer 5 — Session

**Definition:**  
The **Session layer** manages communication sessions between applications.

It conceptually handles things such as:

- Establishing a session
    
- Maintaining a session
    
- Synchronizing communication
    
- Closing a session
    
- Recovering/resuming communication
    

**Question it answers:**

> "How do we manage an ongoing conversation between applications?"

In modern TCP/IP networking, the OSI Session and Presentation layers aren't usually implemented as cleanly separated protocol layers.

---

# 7. Layer 4 — Transport

**Definition:**  
The **Transport layer** provides **end-to-end communication between applications/processes**.

Important protocols:

```text
TCP
UDP
```

It deals with things such as:

- Reliability
    
- Ordering
    
- Flow control
    
- Segmentation
    
- Multiplexing using **ports**
    
- Congestion control (TCP)
    

For example:

```text
192.168.1.10:50000
          │
          │ TCP
          ▼
142.250.x.x:443
```

Port `443` identifies the destination application/service.

**Question it answers:**

> "How should data be delivered between these applications?"

---

# 8. Layer 3 — Network

**Definition:**  
The **Network layer** is responsible for **logical addressing and routing packets between networks**.

The most important protocol is:

```text
IP
```

Example:

```text
192.168.1.10
       ↓
142.250.x.x
```

Routers primarily operate at this layer.

The Network layer determines the path packets can take:

```text
Computer
   ↓
Router A
   ↓
Router B
   ↓
Router C
   ↓
Server
```

**Question it answers:**

> "Where should this packet go, and how can it get there?"

---

# 9. Layer 2 — Data Link

**Definition:**  
The **Data Link layer** provides communication between devices over a **single local network link**.

Examples:

```text
Ethernet
Wi-Fi (802.11)
```

It deals with things such as:

- Frames
    
- MAC addresses
    
- Local delivery
    
- Error detection
    
- Media access
    

Example:

```text
PC
MAC: AA:AA:AA:AA:AA:AA
       │
       │ Ethernet frame
       ▼
Router
MAC: BB:BB:BB:BB:BB:BB
```

A switch primarily operates at Layer 2.

**Question it answers:**

> "How do I deliver this frame across this local network link?"

---

# 10. Layer 1 — Physical

**Definition:**  
The **Physical layer** is responsible for transmitting **raw bits as physical signals**.

Those signals can be:

```text
Electrical → copper Ethernet
Light      → fiber optic
Radio      → Wi-Fi
```

At this level, we're dealing with physical phenomena.

Conceptually:

```text
101101001010
     ↓
electrical / optical / radio signal
     ↓
physical medium
     ↓
receiver
     ↓
101101001010
```

**Question it answers:**

> "How do I physically transmit these bits?"

---

# 11. The complete picture

Suppose your Java application sends an HTTP request.

Conceptually:

```text
┌──────────────────────────┐
│ 7 Application            │ ← HTTP
├──────────────────────────┤
│ 6 Presentation           │ ← data representation
├──────────────────────────┤
│ 5 Session                │ ← session management
├──────────────────────────┤
│ 4 Transport              │ ← TCP
├──────────────────────────┤
│ 3 Network                │ ← IP
├──────────────────────────┤
│ 2 Data Link              │ ← Ethernet/Wi-Fi
├──────────────────────────┤
│ 1 Physical               │ ← electrical/radio/light
└──────────────────────────┘
```

The data travels **down the stack** on the sender:

```text
Application
    ↓
Presentation
    ↓
Session
    ↓
Transport
    ↓
Network
    ↓
Data Link
    ↓
Physical
```

and **up the stack** on the receiver:

```text
Physical
    ↓
Data Link
    ↓
Network
    ↓
Transport
    ↓
Session
    ↓
Presentation
    ↓
Application
```

### The most important layers for a backend developer

Focus especially on:

```text
Application → HTTP, DNS
Transport  → TCP, UDP, ports
Network    → IP, routing
Data Link  → Ethernet, Wi-Fi, MAC
Physical   → cables, signals, bandwidth
```

Those five will explain most of what you'll encounter when working with **Java, Spring Boot, HTTP servers, sockets, Docker, databases, and Linux networking**.


[[Networking]]