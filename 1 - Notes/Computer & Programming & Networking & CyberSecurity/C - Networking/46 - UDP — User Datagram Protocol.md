

**UDP (User Datagram Protocol)** is a **connectionless transport-layer protocol** that sends independent **datagrams** between applications without establishing a TCP-style connection.

> **UDP provides a lightweight way to send data with minimal protocol overhead, but it does not guarantee delivery, ordering, or retransmission.**

UDP operates at **Layer 4 — Transport Layer**.

---

# 1. Where UDP fits

```text
┌─────────────────────────────┐
│ Application                 │
│ DNS, DHCP, games, etc.      │
├─────────────────────────────┤
│ Transport                   │
│ TCP / UDP                   │
├─────────────────────────────┤
│ Network                     │
│ IP                          │
├─────────────────────────────┤
│ Data Link                   │
│ Ethernet / Wi-Fi            │
├─────────────────────────────┤
│ Physical                    │
│ Electrical / Light / Radio  │
└─────────────────────────────┘
```

For example:

```text
DNS
 ↓
UDP
 ↓
IP
 ↓
Ethernet / Wi-Fi
```

UDP provides the transport-layer mechanism between the application and IP.

---

# 2. Why UDP exists

TCP provides many mechanisms:

```text
Connection establishment
Ordering
Acknowledgements
Retransmission
Flow control
Congestion control
```

Those mechanisms are useful, but they also introduce overhead and potentially delay.

UDP takes a much simpler approach:

```text
Application
     │
     ▼
    UDP
     │
     ▼
    IP
     │
     ▼
 Network
```

The application essentially says:

> "Send this datagram to that destination."

UDP does not first establish a TCP-style connection.

---

# 3. UDP is connectionless

TCP:

```text
Client                    Server
  │                         │
  │──── SYN ───────────────→│
  │←── SYN/ACK ─────────────│
  │──── ACK ───────────────→│
  │                         │
  │     Connection          │
```

UDP:

```text
Client                    Server
  │                         │
  │──── UDP Datagram ──────→│
  │                         │
```

There is no three-way handshake.

This makes UDP suitable for applications where avoiding connection-establishment overhead is useful.

---

# 4. UDP Datagram

UDP divides application data into **datagrams**.

A simplified UDP datagram:

```text
┌────────────────────────────┐
│ UDP Header                 │
├────────────────────────────┤
│ Application Data           │
└────────────────────────────┘
```

UDP has a very small header: **8 bytes**.

It contains four fields:

```text
┌─────────────────┬─────────────────┐
│ Source Port     │ Destination Port│
├─────────────────┼─────────────────┤
│ Length          │ Checksum        │
└─────────────────┴─────────────────┘
```

Compared with TCP's much larger and more feature-rich header, this is one reason UDP has low protocol overhead.

---

# 5. UDP Ports

Like TCP, UDP uses **port numbers** to identify application endpoints.

For example:

```text
Client
192.168.1.10:53000
      │
      │ UDP
      ▼
Server
192.168.1.20:53
```

Port `53` is commonly used by DNS.

The transport endpoint is therefore:

```text
IP + UDP port
```

For example:

```text
192.168.1.20:53
```

---

# 6. No built-in reliability

Suppose the sender transmits:

```text
A
B
C
D
```

UDP might result in the receiver seeing:

```text
A
C
D
```

because:

```text
B ─────── X lost
```

UDP does not automatically retransmit `B`.

TCP:

```text
A B [C lost] D
        ↓
    retransmit
        ↓
A B C D
```

UDP:

```text
A B [C lost] D
        ↓
No built-in retransmission
```

If reliability is required, **the application or a higher-level protocol must implement it**.

---

# 7. No ordering guarantee

Suppose the sender sends:

```text
Datagram 1
Datagram 2
Datagram 3
```

The network could deliver them as:

```text
3
1
2
```

UDP does not reorder them for the application.

TCP uses sequence numbers to reconstruct an ordered byte stream; UDP does not provide that mechanism.

---

# 8. UDP preserves datagram boundaries

This is a major difference from TCP.

Suppose an application sends:

```text
"HELLO"
```

and then:

```text
"WORLD"
```

UDP treats them as **two separate datagrams**:

```text
┌────────────┐
│ HELLO      │
└────────────┘

┌────────────┐
│ WORLD      │
└────────────┘
```

The receiver receives those datagrams separately.

TCP instead gives the application a byte stream:

```text
HELLOWORLD
```

TCP does not inherently know where `"HELLO"` ends and `"WORLD"` begins.

---

# 9. UDP does not guarantee delivery

The basic mental model is:

```text
send()
  │
  ▼
UDP
  │
  ▼
IP
  │
  ▼
Network
  │
  ├──→ delivered
  ├──→ lost
  ├──→ delayed
  └──→ potentially duplicated/reordered
```

UDP itself does not provide a guarantee that the destination application receives the datagram.

This is why UDP is often described as **best-effort transport**.

---

# 10. UDP is still not "uncontrolled"

It is easy to misunderstand UDP as:

> "UDP just throws packets onto the network."

Not exactly.

UDP still provides important transport-layer functionality:

```text
Source port
Destination port
Length
Checksum
```

And the OS still handles:

```text
Socket management
IP routing
Network-interface transmission
Buffering
```

UDP simply provides fewer transport mechanisms than TCP.

---

# 11. UDP communication

A UDP server can be modeled as:

```text
              UDP Server
                  │
             Port 53
                  │
        ┌─────────┼─────────┐
        │         │         │
        ▼         ▼         ▼
     Client A  Client B  Client C
```

Unlike a TCP server, there isn't necessarily a separate established TCP connection/socket state for each sender.

The server can receive datagrams from many clients through the same UDP socket.

---

# 12. UDP in Java

Java provides:

```java
DatagramSocket
DatagramPacket
```

A simplified receiver:

```java
DatagramSocket socket = new DatagramSocket(8080);

byte[] buffer = new byte[1024];

DatagramPacket packet =
        new DatagramPacket(buffer, buffer.length);

socket.receive(packet);
```

Conceptually:

```text
Network
   │
   ▼
 UDP datagram
   │
   ▼
DatagramSocket
   │
   ▼
DatagramPacket
   │
   ▼
Java application
```

---

# 13. UDP vs TCP

|TCP|UDP|
|---|---|
|Connection-oriented|Connectionless|
|Reliable|Best-effort|
|Ordered|No ordering guarantee|
|Retransmission|No built-in retransmission|
|Byte stream|Datagram-oriented|
|Flow control|Yes|
|Congestion control|Yes|
|Larger overhead|Small 8-byte UDP header|
|Handshake|Yes|

A useful comparison:

```text
TCP
Application
   ↓
"Make sure the stream arrives correctly."
   ↓
TCP
```

```text
UDP
Application
   ↓
"Send this datagram."
   ↓
UDP
```

---

# 14. Where UDP is useful

UDP is particularly useful when **low overhead, low latency, or datagram semantics** are important.

Examples include:

### DNS

Traditional DNS queries commonly use UDP.

```text
Client ── UDP ──→ DNS Server
```

### Online games

Some real-time game traffic can use UDP because an old update may become useless after a newer update arrives.

For example:

```text
Player position:

100,200
101,201
102,202
103,203
```

If `101,201` is lost, receiving the newer position may be more useful than waiting for retransmission.

### Real-time audio/video

In real-time communication, waiting for retransmission can sometimes be worse than losing a small piece of data.

### DHCP

DHCP uses UDP because a host can need to communicate before it has a normal IP configuration.

### QUIC

**QUIC** runs over UDP and implements many advanced transport mechanisms above UDP, including reliability and congestion control.

So an important lesson is:

> **UDP does not mean the application cannot be reliable. It means UDP itself does not provide TCP-style reliability.**

---

# 15. UDP and QUIC

Modern networking makes this distinction especially interesting.

Traditional HTTPS:

```text
HTTP
 ↓
TLS
 ↓
TCP
 ↓
IP
```

HTTP/3:

```text
HTTP/3
   ↓
 QUIC
   ↓
 UDP
   ↓
 IP
```

QUIC uses UDP as its underlying transport substrate but implements sophisticated features itself.

So:

```text
UDP
 ↓
QUIC
 ↓
HTTP/3
```

is perfectly possible.

---

# 16. UDP and sockets

From your previous topic:

```text
TCP:
Socket
  ↓
TCP connection
  ↓
Remote socket
```

UDP:

```text
Socket
  ↓
UDP datagram
  ↓
Remote endpoint
```

A UDP socket can send to different destinations without establishing a separate TCP-style connection for each one.

---

# 17. Encapsulation

When a UDP application sends data:

```text
Application Data
       │
       ▼
┌─────────────────────┐
│ UDP Header          │
│ UDP Data            │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│ IP Header           │
│ UDP Datagram        │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│ Ethernet Header     │
│ IP Packet           │
│ Ethernet Trailer    │
└─────────────────────┘
```

Terminology:

```text
Application → Data
UDP         → Datagram
IP          → Packet
Ethernet    → Frame
Physical    → Bits/signals
```

---

# 18. The key conceptual difference

The best way to remember TCP vs UDP is not:

> TCP = good, UDP = bad.

Instead:

```text
TCP
 │
 ├── reliability
 ├── ordering
 ├── retransmission
 ├── flow control
 └── congestion control
```

versus:

```text
UDP
 │
 ├── minimal overhead
 ├── datagram boundaries
 ├── no handshake
 └── application controls additional behavior
```

### Core definition

> **UDP is a connectionless Layer-4 protocol that transports independent datagrams between application endpoints with minimal overhead, while leaving reliability, ordering, retransmission, and other higher-level behavior to the application or another protocol.**


[[Networking]]