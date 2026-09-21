
---

**TCP (Transmission Control Protocol)** is a **connection-oriented, reliable, ordered, byte-stream transport-layer protocol** used to exchange data between applications over an IP network.

> TCP provides applications with a reliable communication channel, even though the underlying IP network itself does not guarantee delivery or ordering.

TCP operates at **Layer 4 — Transport Layer**.

---

# 1. Where TCP fits

A simplified networking stack:

```text
┌─────────────────────────────┐
│ Application                 │
│ HTTP, SSH, SMTP, etc.       │
├─────────────────────────────┤
│ Transport                   │
│ TCP / UDP                   │
├─────────────────────────────┤
│ Internet / Network          │
│ IP                          │
├─────────────────────────────┤
│ Data Link                   │
│ Ethernet / Wi-Fi            │
├─────────────────────────────┤
│ Physical                    │
│ Electrical / Light / Radio  │
└─────────────────────────────┘
```

For example, HTTPS commonly uses:

```text
HTTPS
  ↓
TLS
  ↓
TCP
  ↓
IP
  ↓
Ethernet / Wi-Fi
```

TCP's job is **not** to route packets. IP does that.

TCP's job is to make communication between applications **reliable and manageable**.

---

# 2. Why TCP exists

IP is fundamentally **best-effort**.

An IP packet can:

```text
      ┌──→ arrive
──────┤
      ├──→ arrive out of order
      ├──→ be duplicated
      └──→ be lost
```

IP itself doesn't provide a guarantee that the destination receives packets in the correct order.

TCP adds mechanisms above IP to deal with this.

```text
Application
     │
     │ reliable byte stream
     ▼
    TCP
     │
     │ IP packets may be lost/reordered
     ▼
    IP
     │
     ▼
   Network
```

---

# 3. Main characteristics of TCP

TCP provides several important properties.

### Connection-oriented

TCP establishes a logical connection before normal data transfer.

```text
Client ───── establish connection ───── Server
Client ─────── exchange data ────────── Server
Client ───────── close ──────────────── Server
```

### Reliable

TCP detects missing data and retransmits it.

### Ordered

Data is delivered to the application in the correct order.

### Full-duplex

Both sides can send data simultaneously.

```text
Client ─────────────────→ Server
Client ←───────────────── Server
```

### Byte-stream

TCP presents data as a **continuous stream of bytes**, not a collection of individual application messages.

### Flow control

TCP prevents a fast sender from overwhelming a slow receiver.

### Congestion control

TCP adjusts transmission according to network congestion.

---

# 4. TCP does not preserve application messages

This is one of the most important TCP concepts.

Suppose your application sends:

```text
"HELLO"
```

and then:

```text
"WORLD"
```

TCP sees:

```text
H E L L O W O R L D
```

as a **byte stream**.

It does not inherently know:

```text
Message 1 = HELLO
Message 2 = WORLD
```

The application protocol has to define message boundaries if it needs them.

For example, HTTP provides its own application-level structure.

---

# 5. TCP connection

A TCP connection is associated with two endpoints.

Example:

```text
Client                         Server
10.0.0.5:53142                 192.168.1.20:8080
    │                                │
    └──────── TCP connection ────────┘
```

The connection is identified using:

```text
Source IP
Source Port
Destination IP
Destination Port
```

For example:

```text
10.0.0.5:53142
        ↓
192.168.1.20:8080
```

This is often called the **TCP 4-tuple**.

---

# 6. Three-Way Handshake

Before exchanging normal TCP data, the client and server perform the **TCP three-way handshake**.

```text
Client                                  Server
  │                                       │
  │──── SYN ─────────────────────────────→│
  │                                       │
  │←─── SYN + ACK ────────────────────────│
  │                                       │
  │──── ACK ─────────────────────────────→│
  │                                       │
  │         Connection established        │
```

Let's examine it.

### Step 1 — SYN

Client sends:

```text
SYN
```

This means approximately:

> "I want to establish a TCP connection."

It also contains an initial sequence number.

---

### Step 2 — SYN-ACK

Server responds:

```text
SYN + ACK
```

Meaning:

```text
SYN → I also want to establish the connection.
ACK → I received your SYN.
```

---

### Step 3 — ACK

Client responds:

```text
ACK
```

Now both sides are ready.

```text
Client  ═══════════ TCP CONNECTION ═══════════  Server
```

---

# 7. Sequence Numbers

TCP uses **sequence numbers** to keep track of bytes.

Imagine the sender has:

```text
ABCDEFGHIJ
```

TCP can number the bytes conceptually:

```text
A B C D E F G H I J
1 2 3 4 5 6 7 8 9 10
```

The actual TCP numbering uses a sequence-number space rather than simply starting application data at `1`, but this model helps understand the idea.

Suppose the receiver receives:

```text
A B C D
```

and then:

```text
I J
```

TCP can recognize that:

```text
E F G H
```

are missing.

```text
A B C D [E F G H missing] I J
```

TCP can then request/recover the missing bytes through its reliability mechanisms.

---

# 8. Acknowledgements

TCP uses **ACKs (acknowledgements)** to tell the sender what data has been successfully received.

Conceptually:

```text
Sender                       Receiver
  │                              │
  │──── bytes 1–100 ───────────→ │
  │                              │
  │←──── ACK 101 ────────────────│
  │                              │
```

`ACK 101` means approximately:

> "I have received everything through byte 100; the next byte I expect is 101."

This is called a **cumulative acknowledgement**.

---

# 9. Retransmission

Suppose a segment is lost:

```text
Sender                       Receiver
  │                              │
  │──── Segment 1 ─────────────→ │
  │──── Segment 2 ─────────────→ │
  │        X lost                │
  │──── Segment 3 ─────────────→ │
  │                              │
```

The receiver can indicate that it is still missing part of the stream.

The sender eventually retransmits the missing data:

```text
Sender                       Receiver
  │                              │
  │──── Segment 2 ─────────────→ │
  │                              │
```

TCP therefore gives applications a reliable stream even when the network loses individual packets.

---

# 10. Ordering

Packets don't necessarily arrive in the order they were sent.

```text
Sent:

1 ─────→
2 ─────→
3 ─────→
4 ─────→

Received:

3
1
4
2
```

TCP uses sequence numbers to reconstruct the correct stream:

```text
1 → 2 → 3 → 4
```

The application sees:

```text
1234
```

rather than:

```text
3142
```

---

# 11. TCP Segments

TCP does not directly send an infinite byte stream through IP.

The stream is divided into pieces called **TCP segments**.

Conceptually:

```text
Application data

AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        │
        ▼
┌──────────────┐
│ TCP Segment  │
│ Data         │
└──────────────┘
        │
        ▼
       IP
```

A TCP segment contains a **TCP header** followed by payload data.

Simplified:

```text
┌─────────────────────────────────────┐
│ TCP Header                          │
├─────────────────────────────────────┤
│ Application Data                   │
└─────────────────────────────────────┘
```

---

# 12. Important TCP header fields

A simplified TCP header contains fields such as:

```text
┌───────────────┬───────────────┐
│ Source Port   │ Dest. Port    │
├───────────────┴───────────────┤
│ Sequence Number                │
├───────────────────────────────┤
│ Acknowledgment Number          │
├───────────────┬───────────────┤
│ Header Length │ Flags         │
├───────────────┴───────────────┤
│ Window Size                    │
├───────────────────────────────┤
│ Checksum                       │
├───────────────────────────────┤
│ Urgent Pointer                 │
├───────────────────────────────┤
│ Options                        │
├───────────────────────────────┤
│ Data                           │
└────────────────────────────────┘
```

The most important fields to understand initially are:

```text
Source Port
Destination Port
Sequence Number
Acknowledgment Number
Flags
Window Size
Checksum
```

---

# 13. TCP Flags

TCP has control flags that indicate different states or actions.

Important ones include:

|Flag|Purpose|
|---|---|
|**SYN**|Start/synchronize a connection|
|**ACK**|Acknowledge received data/control information|
|**FIN**|Gracefully close a connection|
|**RST**|Immediately reset a connection|
|**PSH**|Request prompt delivery of buffered data to the application|
|**URG**|Indicates urgent pointer information|
|**ECE/CWR**|Used with Explicit Congestion Notification|

The most important early ones are:

```text
SYN → establish
ACK → acknowledge
FIN → close gracefully
RST → reset
```

---

# 14. TCP Connection Termination

TCP normally uses a **four-segment exchange** to close a connection because each direction is shut down independently.

Simplified:

```text
Client                                  Server
  │                                       │
  │──── FIN ─────────────────────────────→│
  │←─── ACK ──────────────────────────────│
  │                                       │
  │←─── FIN ──────────────────────────────│
  │──── ACK ─────────────────────────────→│
  │                                       │
  │         Connection closed             │
```

Why four?

Because TCP is **full-duplex**.

Closing the client's sending direction does not necessarily mean the server has finished sending its data.

---

# 15. TCP states

TCP connections move through defined states.

Common states include:

```text
CLOSED
  ↓
LISTEN
  ↓
SYN-SENT
  ↓
SYN-RECEIVED
  ↓
ESTABLISHED
  ↓
FIN-WAIT
  ↓
TIME-WAIT
  ↓
CLOSED
```

The most important state is:

```text
ESTABLISHED
```

which means the TCP connection is active and can exchange data.

On Linux, you can inspect TCP sockets with:

```bash
ss -t
```

or:

```bash
ss -tuln
```

For more detail:

```bash
ss -tan
```

Example:

```text
ESTAB  0  0  192.168.1.10:53142  192.168.1.20:8080
```

---

# 16. Flow Control

Imagine:

```text
Fast sender ─────────────────→ Slow receiver
```

If the sender transmits faster than the receiver can process or buffer data, the receiver could be overwhelmed.

TCP uses a **receive window** to communicate how much additional data the receiver is prepared to accept.

Conceptually:

```text
Receiver:

"I currently have room for 64 KB."

               ↓

Sender ─────── sends within that limit ───────→
```

This is **flow control**.

The key concept is the **receiver window (`rwnd`)**.

---

# 17. Congestion Control

Flow control protects the **receiver**.

Congestion control protects the **network**.

Suppose many devices send huge amounts of traffic:

```text
PC ───┐
PC ───┤
PC ───┤
PC ───┼──→ Router ──→ Congested link
PC ───┤
PC ───┘
```

TCP dynamically adjusts how much data it puts into the network.

Important concepts include:

```text
Congestion Window (cwnd)
Slow Start
Congestion Avoidance
Fast Retransmit
Fast Recovery
```

The sender's effective amount of in-flight data is influenced by both receiver capacity and network congestion.

A simplified mental model is:

```text
Allowed in-flight data
        ≈
min(rwnd, cwnd)
```

---

# 18. TCP is connection-oriented, but not a physical connection

This is important.

When we say:

> "TCP establishes a connection"

we do **not** mean it creates a dedicated physical cable between the machines.

It creates **logical state at both TCP endpoints**.

```text
Client TCP state
      ↕
logical TCP connection
      ↕
Server TCP state
```

Packets may travel through many routers:

```text
Client
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

TCP still treats this as one logical end-to-end connection.

---

# 19. TCP and ports

TCP uses **port numbers** to identify applications/services.

For example:

```text
Client
10.0.0.5:53142
       │
       │ TCP
       ▼
Server
192.168.1.20:8080
```

TCP therefore connects:

```text
Application
    ↓
Port
    ↓
TCP connection
```

For your Spring Boot example:

```text
Browser
10.0.0.5:53142
       │
       │ TCP
       ▼
Spring Boot
192.168.1.20:8080
```

---

# 20. TCP and sockets

This connects directly to the socket concept you just learned.

A Java server might do:

```java
ServerSocket serverSocket = new ServerSocket(8080);
Socket socket = serverSocket.accept();
```

Conceptually:

```text
              Linux
                │
        ┌───────┴────────┐
        │                │
Listening socket     Connected socket
      :8080             :8080
        │                │
        │            TCP connection
        │                │
        └────────────────┘
```

The application interacts with a **socket**, while TCP handles:

```text
sequence numbers
ACKs
retransmission
ordering
flow control
congestion control
connection state
```

---

# 21. TCP vs UDP

|TCP|UDP|
|---|---|
|Connection-oriented|Connectionless|
|Reliable|Best-effort|
|Ordered|No ordering guarantee|
|Retransmission|No built-in retransmission|
|Flow control|Yes|
|Congestion control|Yes|
|Byte stream|Datagram-based|
|Larger protocol overhead|Smaller overhead|
|Common for HTTP, SSH, PostgreSQL|Common for DNS, streaming, games, VoIP|

Important:

> **TCP is not simply "better UDP."**

They provide different transport semantics for different application requirements.

---

# 22. TCP in a real HTTP request

Suppose you access:

```text
http://example.com
```

A simplified sequence is:

```text
1. DNS
   example.com
        ↓
   IP address

2. TCP handshake

Client                    Server
  │── SYN ───────────────→│
  │←─ SYN/ACK ────────────│
  │── ACK ───────────────→│

3. HTTP data

  │── HTTP Request ──────→│
  │←─ HTTP Response ──────│

4. TCP connection eventually closes
```

So HTTP doesn't have to implement reliability itself. It can rely on TCP.

---

# 23. Encapsulation

This is the full picture:

```text
Application Data
       │
       ▼
┌─────────────────────┐
│ TCP Header          │
│ TCP Payload         │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│ IP Header           │
│ TCP Segment         │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│ Ethernet Header     │
│ IP Packet           │
│ Ethernet Trailer    │
└─────────────────────┘
       │
       ▼
      Bits
       │
       ▼
 Transmission Medium
```

The terminology is:

```text
Application → Data
TCP         → Segment
IP          → Packet
Ethernet    → Frame
Physical    → Bits/signals
```

This terminology is worth memorizing.

---

# 24. The TCP mental model

Think of TCP as a **reliable transport layer between two applications**:

```text
Application A
     │
     ▼
   Socket
     │
     ▼
    TCP
     │
     │ reliable, ordered byte stream
     │
     ▼
    TCP
     │
     ▼
   Socket
     │
     ▼
Application B
```

TCP has five major responsibilities you should keep in your head:

```text
TCP
├── 1. Connection management
│      SYN / ACK / FIN
│
├── 2. Reliability
│      ACK / retransmission
│
├── 3. Ordering
│      sequence numbers
│
├── 4. Flow control
│      receiver window
│
└── 5. Congestion control
       congestion window
```

### Core definition

> **TCP is a Layer-4 transport protocol that establishes a logical connection between applications and provides a reliable, ordered, full-duplex byte stream over the inherently unreliable IP layer.**

For a Java/Spring backend developer, the next concepts that naturally follow TCP are **TCP segment structure → sequence/acknowledgment numbers → sliding window → TCP state machine → how Tomcat/Spring Boot sits on top of TCP**.


[[Networking]]