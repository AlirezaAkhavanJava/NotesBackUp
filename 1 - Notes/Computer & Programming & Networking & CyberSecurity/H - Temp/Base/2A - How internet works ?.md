
## Definition
The **Internet** is a global system of interconnected computer networks that exchange data using common rules called **protocols**, mainly **TCP/IP**. It is often called a **network of networks** because it links millions of smaller networks — home networks, company networks, mobile networks, data centers, and ISPs — into one worldwide system.

The Internet is **not** the same as the Web. The Internet is the infrastructure; the Web (HTTP/HTTPS) is one service that runs on top of it.

---

## Core Idea: Packet Switching
The Internet does not send an entire file or call as one continuous stream. Instead, it breaks data into small units called **packets**.

- Each packet has a **header** with source and destination addresses.
- Packets travel independently through the network.
- They may take different paths.
- The destination reassembles them into the original data.

This is called **packet switching**. It is efficient because many users can share the same links.

---

## Key Building Blocks

| Term | Definition |
|---|---|
| **Protocol** | A set of rules for communication, e.g. TCP, IP, HTTP, DNS. |
| **IP address** | A logical address for a device on a network, e.g. `192.168.1.1` or `2001:db8::1`. |
| **MAC address** | A hardware address used inside a local network link. |
| **Packet** | A small unit of data with a header and payload. |
| **Frame** | The Layer 2 envelope that carries a packet across a local link. |
| **Router** | A device that forwards packets between different networks using IP addresses. |
| **Switch** | A device that forwards frames inside a local network using MAC addresses. |
| **ISP** | Internet Service Provider — the company that connects you to the Internet. |
| **DNS** | Domain Name System — translates names like `example.com` into IP addresses. |
| **TCP** | Transmission Control Protocol — provides reliable, ordered delivery. |
| **UDP** | User Datagram Protocol — fast, connectionless, no delivery guarantee. |
| **HTTP/HTTPS** | Protocols used by the Web to request and send web pages. |
| **BGP** | Border Gateway Protocol — how large networks exchange routing information. |
| **NAT** | Network Address Translation — lets many devices share one public IP. |
| **DHCP** | Dynamically assigns IP addresses to devices. |

---

## How the Internet Works: Step by Step

### 1. Your device connects to a local network
Your phone or PC connects to a Wi-Fi router or mobile network. The router usually gives it a **private IP address** using **DHCP**.

### 2. Your ISP connects you to the Internet
Your home router connects to your **ISP**. The ISP assigns a public IP address or uses **NAT** to share one.

### 3. You request a website
You type `example.com`. Your device needs the IP address of that server.

### 4. DNS resolves the name
Your device asks a **DNS resolver** for the IP address of `example.com`. The resolver may query root, TLD, and authoritative DNS servers. It returns something like `93.184.216.34`.

### 5. A connection is established
For a web request, your device uses **TCP** to establish a connection with the server. This involves a **three-way handshake**:
- SYN
- SYN-ACK
- ACK

If HTTPS is used, **TLS** is also negotiated to encrypt the connection.

### 6. Data is broken into packets
Your HTTP request is split into packets. Each packet has:
- Source IP
- Destination IP
- Source port
- Destination port
- Sequence numbers
- Data

### 7. Routers forward the packets
Routers examine the destination IP address and forward each packet toward the destination. They use **routing tables** and protocols like **BGP** to decide the best path.

- Inside a LAN, **switches** use MAC addresses.
- Between networks, **routers** use IP addresses.

### 8. Packets cross many networks
They may travel through:
- Your ISP
- Backbone networks
- Internet Exchange Points (IXPs)
- Undersea fiber-optic cables
- Data centers

### 9. The destination receives and reassembles
The server receives the packets. TCP checks for loss, reorders them, and requests retransmission if needed. The original HTTP request is rebuilt.

### 10. The server responds
The server sends back an HTTP response, also as packets. Your device reassembles them and renders the web page.

---

## The Layered Model
The Internet is usually explained with the **TCP/IP model**:

| Layer | Purpose | Examples |
|---|---|---|
| **Application** | User services | HTTP, HTTPS, DNS, SMTP, FTP |
| **Transport** | End-to-end delivery | TCP, UDP |
| **Internet** | Addressing and routing | IP, ICMP, BGP |
| **Network Access / Link** | Local delivery | Ethernet, Wi-Fi, PPP |

Each layer adds its own header. This is called **encapsulation**.

Example:
`Data → TCP header → IP header → Ethernet header → bits on the wire`

---

## Who Owns and Runs the Internet?
No single person or company owns the Internet. It is:
- Built from many independent networks
- Connected by ISPs, backbone providers, and data centers
- Governed by shared standards from groups like **IETF**, **ICANN**, and **W3C**
- Coordinated through protocols, not a central controller

---

## In Short
The Internet works by:
1. Breaking data into **packets**
2. Addressing them with **IP addresses**
3. Routing them through **routers** and many networks
4. Using **TCP/IP** and other protocols
5. Reassembling them at the destination

It is a global, decentralized, packet-switched network of networks. The Web, email, video, and games all run on top of it.



[[Networking]]