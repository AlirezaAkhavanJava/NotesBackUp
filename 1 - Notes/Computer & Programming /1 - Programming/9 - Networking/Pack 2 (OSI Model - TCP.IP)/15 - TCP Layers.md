
## TCP/IP Model Layers (4-Layer View)

TCP/IP is usually described as a **4-layer model**. Some textbooks split the bottom layer into two, making a **5-layer model** for teaching.

```
+--------------------------------------------------------------+
| 4. APPLICATION LAYER                                         |
|    HTTP, HTTPS, DNS, SMTP, FTP, SSH, DHCP, SNMP              |
+--------------------------------------------------------------+
| 3. TRANSPORT LAYER                                           |
|    TCP, UDP, SCTP                                            |
+--------------------------------------------------------------+
| 2. INTERNET LAYER                                            |
|    IP (IPv4/IPv6), ICMP, IGMP, routing protocols             |
+--------------------------------------------------------------+
| 1. NETWORK ACCESS / LINK LAYER                               |
|    Ethernet, Wi-Fi, ARP, PPP, MAC, physical transmission     |
+--------------------------------------------------------------+
```

---

## 1. Network Access Layer  
**Also called:** Link Layer, Network Interface Layer, or Data Link + Physical Layer

**What it does:**
- Handles the physical connection between devices on the same local network.
- Converts data into frames and then into electrical, radio, or optical signals.
- Uses **MAC addresses** to identify devices on a local network.
- Detects some errors in frames.
- Defines how devices share the same physical medium.

**Examples/protocols:**
- Ethernet
- Wi-Fi (IEEE 802.11)
- ARP
- PPP
- MAC addressing
- Network interface cards (NICs), cables, switches

**Data unit:** Frame / bits

---

## 2. Internet Layer  
**Also called:** Network Layer

**What it does:**
- Provides **logical addressing** using IP addresses.
- Routes packets from source to destination across multiple networks.
- Decides the best path through routers.
- Does **not** guarantee delivery — it is “best effort.”

**Examples/protocols:**
- IP (IPv4, IPv6)
- ICMP (ping, error messages)
- IGMP
- Routing protocols: OSPF, BGP, RIP

**Data unit:** Packet / IP datagram

---

## 3. Transport Layer

**What it does:**
- Provides end-to-end communication between applications on different devices.
- Uses **port numbers** to identify services like HTTP (80), HTTPS (443), DNS (53).
- Can provide reliability, ordering, and error recovery.

**Main protocols:**
- **TCP** — reliable, connection-oriented, ordered, error-checked.
- **UDP** — fast, connectionless, no delivery guarantee.
- **SCTP** — less common, message-oriented.

**Data unit:**
- TCP: Segment
- UDP: Datagram

---

## 4. Application Layer

**What it does:**
- The layer closest to the user.
- Defines protocols for specific applications and services.
- Handles things like web browsing, email, file transfer, domain name resolution, and remote login.

**Examples/protocols:**
- HTTP / HTTPS — web
- DNS — domain name resolution
- SMTP / IMAP / POP3 — email
- FTP / SFTP — file transfer
- SSH / Telnet — remote access
- DHCP — automatic IP configuration
- SNMP — network management

**Data unit:** Data / message

---

## Encapsulation Diagram

As data moves down the layers, each layer adds its own header.

```
Application Layer
   [ HTTP Data ]
        |
        v
Transport Layer
   [ TCP Header ][ HTTP Data ]  = Segment
        |
        v
Internet Layer
   [ IP Header ][ TCP Header ][ HTTP Data ]  = Packet
        |
        v
Network Access Layer
   [ Frame Header ][ IP Packet ][ Frame Trailer ]  = Frame
        |
        v
   0101010101010101  -> bits on the wire / Wi-Fi / fiber
```

At the receiving device, the process reverses: each layer removes its header and passes the data up.

---

## End-to-End Visual Example

```
Host A                                                        Host B
+------------------+                                  +------------------+
|  Application     |   HTTP request                   |  Application     |
+------------------+                                  +------------------+
|  Transport       |   TCP segment                    |  Transport       |
+------------------+                                  +------------------+
|  Internet        |   IP packet                      |  Internet        |
+------------------+                                  +------------------+
|  Network Access  |   Ethernet/Wi-Fi frame           |  Network Access  |
+------------------+                                  +------------------+
         |                                                     ^
         v                                                     |
     [Switch] ---- [Router] ---- [Router] ---- [Switch] --------+
```

---

## TCP/IP 4-Layer vs 5-Layer vs OSI

| TCP/IP 4-Layer | TCP/IP 5-Layer | OSI 7-Layer |
|---|---|---|
| Application | Application | Application, Presentation, Session |
| Transport | Transport | Transport |
| Internet | Network | Network |
| Network Access | Data Link | Data Link |
| Network Access | Physical | Physical |

In short:  
**Application** = what the user/app wants.  
**Transport** = how to deliver it reliably or quickly.  
**Internet** = where to send it across networks.  
**Network Access** = how to put it on the wire or wireless medium.


[[Networking]]