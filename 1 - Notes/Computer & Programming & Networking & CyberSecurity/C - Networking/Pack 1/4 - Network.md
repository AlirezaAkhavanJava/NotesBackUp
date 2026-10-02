
# Networks, Types of Networks & The Internet

---

## 1. What is a Network?

A **network** is a collection of **two or more devices (nodes)** connected together through a **communication medium** (wired or wireless) to **share resources, exchange data, and communicate**.

### Key Characteristics:
- **Nodes**: Devices like computers, phones, printers, servers, routers.
- **Links**: Physical (cables, fiber) or wireless (Wi-Fi, radio, satellite) connections.
- **Protocols**: Rules that govern communication (TCP/IP, HTTP, Ethernet).
- **Purpose**: Resource sharing, communication, centralized management, and data exchange.

### What Problems Do Networks Solve?
| Problem | How Networks Solve It |
|---------|----------------------|
| Resource duplication | Share printers, files, storage |
| Isolation | Enable communication between devices |
| Data silos | Centralize data on servers |
| Manual work | Automate via remote access |
| Cost | Share internet, licenses, hardware |
| Scalability | Add devices without replacing infrastructure |

### Key Network Components:
- **End devices (hosts)**: PCs, phones, servers
- **Intermediary devices**: Switches, routers, firewalls, access points
- **Media**: Copper, fiber, wireless
- **Services**: DNS, DHCP, email, web, file sharing

---

## 2. Types of Networks (by Scale/Geographic Scope)

### 2.1 PAN — Personal Area Network
- **Definition**: A network of devices within an individual's personal workspace, typically within ~10 meters.
- **Examples**: Bluetooth headphones to phone, smartwatch to phone, USB tethering.
- **Range**: ~1–10 meters
- **Owner**: Single person
- **Technologies**: Bluetooth, NFC, USB, Zigbee, Infrared

### 2.2 LAN — Local Area Network
- **Definition**: A network connecting devices within a limited area such as a home, office, school, or single building.
- **Examples**: Home Wi-Fi, office Ethernet, school computer lab.
- **Range**: Up to ~1 km
- **Owner**: Single organization/individual
- **Technologies**: Ethernet, Wi-Fi (802.11), switches
- **Speed**: 100 Mbps – 100 Gbps

### 2.3 WLAN — Wireless Local Area Network
- **Definition**: A LAN that uses wireless (Wi-Fi) instead of cables for connectivity.
- **Examples**: Home Wi-Fi network, café Wi-Fi, campus wireless.
- **Range**: ~30–100 meters per access point
- **Technologies**: Wi-Fi (802.11a/b/g/n/ac/ax), Bluetooth (sometimes)

### 2.4 CAN — Campus Area Network
- **Definition**: A network spanning multiple LANs within a limited geographic area like a university campus or corporate headquarters.
- **Examples**: University campus network, hospital complex.
- **Range**: ~1–5 km
- **Owner**: Single large organization

### 2.5 MAN — Metropolitan Area Network
- **Definition**: A network covering a city or metropolitan region, larger than a LAN but smaller than a WAN.
- **Examples**: City-wide ISP network, cable TV network, municipal Wi-Fi.
- **Range**: ~5–50 km
- **Owner**: ISP, government, large corporation
- **Technologies**: Fiber optic, microwave, WiMAX

### 2.6 WAN — Wide Area Network
- **Definition**: A network spanning large geographic areas such as countries, continents, or the globe.
- **Examples**: The Internet, corporate networks connecting branch offices.
- **Range**: Country / continent / global
- **Owner**: Multiple organizations, ISPs, telecoms
- **Technologies**: MPLS, leased lines, satellite, fiber backbones

### 2.7 SAN — Storage Area Network
- **Definition**: A dedicated high-speed network that provides block-level storage access to servers.
- **Examples**: Data center storage arrays, enterprise backup systems.
- **Range**: Data center / building
- **Technologies**: Fibre Channel, iSCSI, FCoE
- **Purpose**: Centralized, high-performance storage

### 2.8 VPN — Virtual Private Network
- **Definition**: A logical network built on top of a public network (usually the Internet) that provides secure, encrypted communication.
- **Examples**: Remote worker accessing office network, corporate site-to-site links.
- **Range**: Anywhere (logical, not physical)
- **Technologies**: IPSec, OpenVPN, WireGuard, SSL/TLS

### 2.9 EPN — Enterprise Private Network
- **Definition**: A network built and owned by a single enterprise to interconnect its various sites.
- **Examples**: Bank branch network, retail chain network.
- **Range**: Organization-wide

### 2.10 Internetwork (Internetwork / Internet)
- **Definition**: A network of networks — multiple networks connected via routers.
- **Examples**: The Internet, corporate intranets.
- **Range**: Global

---

## 3. Types of Networks (by Architecture / Relationship)

### 3.1 Client-Server Network
- **Definition**: Centralized model where dedicated **servers** provide resources/services, and **clients** request them.
- **Examples**: Web servers, email servers, file servers.
- **Pros**: Centralized management, security, scalability.
- **Cons**: Single point of failure, cost.

### 3.2 Peer-to-Peer (P2P) Network
- **Definition**: Decentralized model where all devices are **equal** and can act as both client and server.
- **Examples**: BitTorrent, Windows Workgroup, blockchain.
- **Pros**: Simple, cheap, no central dependency.
- **Cons**: Weak security, hard to manage at scale.

### 3.3 Hybrid Network
- **Definition**: Combines client-server and P2P characteristics.
- **Examples**: Most modern enterprise networks.

---

## 4. Types of Networks (by Topology)

| Topology | Definition | Pros | Cons |
|----------|-----------|------|------|
| **Bus** | All devices share a single backbone cable | Simple, cheap | Single point of failure, collisions |
| **Star** | All devices connect to a central hub/switch | Easy to manage, fault isolation | Hub is single point of failure |
| **Ring** | Devices connected in a closed loop | Predictable performance | One break can disrupt loop |
| **Mesh** | Every device connects to every other | Highly redundant | Expensive, complex |
| **Tree** | Hierarchical star networks | Scalable, structured | Root dependency |
| **Hybrid** | Combination of topologies | Flexible | Complex |

---

## 5. What is the Internet?

### Definition:
The **Internet** is a **global system of interconnected computer networks** that uses the **TCP/IP protocol suite** to link billions of devices worldwide. It is a **network of networks** — a massive **internetwork** that enables communication, information sharing, and services across the globe.

### Key Characteristics:
- **Decentralized**: No single owner or central control.
- **Packet-switched**: Data is broken into packets and routed independently.
- **TCP/IP-based**: Uses standardized protocols for communication.
- **Scalable**: Grows continuously without central coordination.
- **Open**: Anyone can connect following standards.

### How the Internet Works (Simplified):
1. **Your device** connects to a **local network** (home/office).
2. **Router** connects your LAN to your **ISP** (Internet Service Provider).
3. **ISP** connects to **backbone networks** (fiber, undersea cables).
4. **Routers** forward packets hop-by-hop using **IP addresses**.
5. **DNS** translates domain names (e.g., google.com) to IP addresses.
6. **Destination server** responds, and data travels back the same way.

### Key Components of the Internet:
| Component | Role |
|-----------|------|
| **ISP** | Provides internet access to end users |
| **IXP** (Internet Exchange Point) | Where ISPs interconnect and exchange traffic |
| **Backbone** | High-capacity core networks (fiber, undersea cables) |
| **DNS** | Translates domain names to IP addresses |
| **Routers** | Direct traffic between networks |
| **Servers** | Host websites, email, apps, data |
| **Protocols** | TCP, IP, HTTP, HTTPS, DNS, BGP, etc. |

### Key Internet Protocols:
| Protocol | Purpose |
|----------|---------|
| **IP** | Addressing and routing packets |
| **TCP** | Reliable, ordered delivery |
| **UDP** | Fast, connectionless delivery |
| **HTTP/HTTPS** | Web browsing |
| **DNS** | Name resolution |
| **SMTP/IMAP/POP3** | Email |
| **BGP** | Routing between ISPs (the "glue" of the internet) |
| **DHCP** | Automatic IP assignment |

### Internet vs. World Wide Web (WWW):
| Internet | World Wide Web |
|----------|----------------|
| The **infrastructure** (networks, routers, cables) | A **service** running on the internet |
| Connects billions of devices | Connects documents/pages via hyperlinks |
| Includes email, VoIP, gaming, etc. | Only HTTP/HTTPS-based content |
| Existed before the Web (1969) | Invented in 1989 by Tim Berners-Lee |

### What Problems Does the Internet Solve?
| Problem | How the Internet Solves It |
|---------|---------------------------|
| Geographic isolation | Global instant communication |
| Information access | Anyone can access knowledge |
| Resource sharing | Cloud computing, remote servers |
| Commerce | E-commerce, online banking |
| Collaboration | Video calls, shared documents |
| Entertainment | Streaming, gaming, social media |
| Innovation | Platform for apps, IoT, AI |

---

## 6. Summary Table — Network Types at a Glance

| Type | Full Name | Scope | Example |
|------|-----------|-------|---------|
| PAN | Personal Area Network | ~10 m | Bluetooth earbuds |
| LAN | Local Area Network | Building | Home Wi-Fi |
| WLAN | Wireless LAN | Building (wireless) | Office Wi-Fi |
| CAN | Campus Area Network | Campus | University network |
| MAN | Metropolitan Area Network | City | City ISP |
| WAN | Wide Area Network | Country/Global | Corporate branches |
| SAN | Storage Area Network | Data center | Enterprise storage |
| VPN | Virtual Private Network | Anywhere (logical) | Remote work access |
| Internet | Interconnected networks | Global | The Internet itself |

---

## Final Takeaway

- A **network** connects devices to share resources and communicate.
- **Types of networks** are classified by **scale** (PAN → LAN → MAN → WAN), **architecture** (client-server, P2P), and **topology** (star, mesh, etc.).
- The **Internet** is the ultimate **network of networks** — a global, decentralized, packet-switched system built on **TCP/IP** that connects billions of devices and enables virtually all modern digital services.

**In one line**: *Networks connect devices locally; the Internet connects networks globally.*


[[Networking]]